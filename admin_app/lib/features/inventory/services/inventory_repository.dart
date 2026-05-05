import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/config/edge_pipeline_config.dart';
import 'package:admin_app/core/services/edge_pipeline_client.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/audit_service.dart';
import '../../../core/models/stock_movement.dart';

/// Blueprint §4.5: Stock lifecycle — every stock change MUST create a movement record;
/// stock levels must update correctly.
/// Uses stock_movements + inventory_items (current_stock or stock_on_hand_fresh/frozen).
class InventoryRepository {
  final SupabaseClient _client;

  InventoryRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Record a stock movement and rely on DB trigger as stock authority.
  /// Quantity is normalized to trigger semantics:
  /// - reducing movements: negative
  /// - increasing movements: positive
  /// - adjustment: caller-provided signed delta
  /// - transfer: zero net stock effect
  /// performedBy must be profile UUID (staff).
  Future<StockMovement> recordMovement({
    required String itemId,
    required MovementType movementType,
    required double quantity,
    double? unitCost,
    String? referenceType,
    String? referenceId,
    String? locationFromId,
    String? locationToId,
    required String performedBy,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    if (quantity < 0 || (quantity == 0 && movementType != MovementType.adjustment)) {
      throw ArgumentError('Quantity must be non-negative (0 only for adjustment)');
    }

    // Idempotency for referenced movements: avoid duplicate stock application.
    if ((referenceType ?? '').isNotEmpty && (referenceId ?? '').isNotEmpty) {
      final existing = await _client
          .from('stock_movements')
          .select()
          .eq('item_id', itemId)
          .eq('movement_type', movementType.dbValue)
          .eq('reference_type', referenceType!)
          .eq('reference_id', referenceId!)
          .limit(1);
      if ((existing as List).isNotEmpty) {
        return StockMovement.fromJson(
          Map<String, dynamic>.from(existing.first as Map),
        );
      }
    }

    var dbQuantity = quantity;
    if (movementType == MovementType.transfer) {
      dbQuantity = 0.0;
    } else if (movementType == MovementType.adjustment) {
      dbQuantity = quantity;
    } else if (movementType.reducesStock) {
      dbQuantity = -quantity;
    } else if (movementType.increasesStock) {
      dbQuantity = quantity;
    }

    final allowNegative = metadata?['allow_negative'] == true;
    if (!allowNegative &&
        (movementType.reducesStock || movementType == MovementType.adjustment)) {
      final item = await _client
          .from('inventory_items')
          .select('current_stock')
          .eq('id', itemId)
          .maybeSingle();
      final current = (item?['current_stock'] as num?)?.toDouble() ?? 0.0;
      final projected = current + dbQuantity;
      if (projected < -0.0001) {
        throw StateError(
          'Insufficient stock: movement would reduce item below zero. '
          'Set metadata.allow_negative=true only when explicitly intended.',
        );
      }
    }

    final row = {
      'item_id': itemId,
      'movement_type': movementType.dbValue,
      'quantity': dbQuantity,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'location_from': locationFromId,
      'location_to': locationToId,
      'staff_id': performedBy,
      'notes': notes,
      'metadata': metadata,
    };
    dynamic response;
    if (EdgePipelineConfig.canUseEdgePipeline) {
      debugPrint('[EDGE] Calling stock_adjust');
      try {
        final res = await EdgePipelineClient.instance.stockAdjust(movement: row);
        response = res['movement'];
      } catch (e) {
        debugPrint('[EDGE] Failed: stock_adjust — $e');
        rethrow;
      }
    } else {
      response = await _client
          .from('stock_movements')
          .insert(row)
          .select()
          .single();
    }
    final movement = StockMovement.fromJson(response as Map<String, dynamic>);

    // Get product name for audit log
    final item = await _client
        .from('inventory_items')
        .select('name')
        .eq('id', itemId)
        .maybeSingle();
    final productName = item?['name'] ?? 'Unknown Product';

    // Audit log - stock movement
    await AuditService.log(
      action: 'UPDATE',
      module: 'Inventory',
      description: 'Stock movement: ${movementType.dbValue} - ${quantity.toStringAsFixed(2)} x $productName${notes != null ? " ($notes)" : ""}',
      entityType: 'StockMovement',
      entityId: movement.id,
    );
    return movement;
  }

  /// Stock-take adjustment: set item stock to actual count; record adjustment movement with variance in notes.
  Future<StockMovement> adjustStock({
    required String itemId,
    required double actualQuantity,
    required String performedBy,
    String? notes,
  }) async {
    final item = await _client
        .from('inventory_items')
        .select('id, name, current_stock, stock_on_hand_fresh, stock_on_hand_frozen')
        .eq('id', itemId)
        .single();
    
    // Get product name for audit
    final productName = item['name'] ?? 'Unknown Product';
    
    // C1: Single source of truth — use current_stock only for previous value.
    final cur = (item['current_stock'] as num?)?.toDouble() ?? 0;
    final variance = actualQuantity - cur;
    if (variance == 0) {
      // Still record zero-quantity adjustment for audit
      final movement = await recordMovement(
        itemId: itemId,
        movementType: MovementType.adjustment,
        quantity: 0,
        performedBy: performedBy,
        notes: notes ?? 'Stock take: no change ($actualQuantity)',
        metadata: {'previous': cur, 'actual': actualQuantity},
      );
      
      // Audit log - stock adjustment (zero variance)
      await AuditService.log(
        action: 'UPDATE',
        module: 'Inventory',
        description: 'Stock adjustment: $productName - no change ($actualQuantity)',
        entityType: 'StockMovement',
        entityId: movement.id,
      );
      
      return movement;
    }
    final row = {
      'item_id': itemId,
      'movement_type': 'adjustment',
      'quantity': variance, // signed: positive if actual > system, negative if actual < system
      'staff_id': performedBy,
      'notes': notes ?? 'Stock take: was $cur, set to $actualQuantity',
      'metadata': {'previous': cur, 'actual': actualQuantity},
    };
    dynamic response;
    if (EdgePipelineConfig.canUseEdgePipeline) {
      debugPrint('[EDGE] Calling stock_adjust');
      try {
        final res = await EdgePipelineClient.instance.stockAdjust(movement: row);
        response = res['movement'];
      } catch (e) {
        debugPrint('[EDGE] Failed: stock_adjust — $e');
        rethrow;
      }
    } else {
      response = await _client
          .from('stock_movements')
          .insert(row)
          .select()
          .single();
    }
    // NOTE: Do NOT manually update current_stock or stock_on_hand_fresh here.
    // The Supabase trigger on_stock_movement_insert handles all stock level
    // updates automatically on INSERT. Manual update here would cause a
    // double-write race condition.

    final movement = StockMovement.fromJson(response as Map<String, dynamic>);
    
    // Audit log - stock adjustment
    await AuditService.log(
      action: 'UPDATE',
      module: 'Inventory',
      description: 'Stock adjustment: $productName - ${variance > 0 ? "+" : ""}${variance.toStringAsFixed(2)} (${cur.toStringAsFixed(2)} → ${actualQuantity.toStringAsFixed(2)})',
      entityType: 'StockMovement',
      entityId: movement.id,
    );

    return movement;
  }

  /// Transfer between locations: record one transfer movement; total on-hand unchanged.
  /// If inventory has location-level stock, caller can call recordMovement twice (out from A, in to B) or use a single transfer row.
  Future<StockMovement> transferStock({
    required String itemId,
    required double quantity,
    required String locationFromId,
    required String locationToId,
    required String performedBy,
    String? notes,
  }) async {
    // Get product name for audit
    final item = await _client
        .from('inventory_items')
        .select('name')
        .eq('id', itemId)
        .maybeSingle();
    final productName = item?['name'] ?? 'Unknown Product';
    
    final movement = await recordMovement(
      itemId: itemId,
      movementType: MovementType.transfer,
      quantity: quantity,
      locationFromId: locationFromId,
      locationToId: locationToId,
      performedBy: performedBy,
      notes: notes,
    );
    
    // Audit log - stock transfer
    await AuditService.log(
      action: 'UPDATE',
      module: 'Inventory',
      description: 'Stock transferred: ${quantity.toStringAsFixed(2)} x $productName between locations',
      entityType: 'StockMovement',
      entityId: movement.id,
    );
    
    return movement;
  }

  /// Movement history for a product (item_id).
  Future<List<StockMovement>> getMovementHistory(String itemId, {int limit = 100}) async {
    final response = await _client
        .from('stock_movements')
        .select()
        .eq('item_id', itemId)
        .order('created_at', ascending: false)
        .limit(limit);
    final list = List<Map<String, dynamic>>.from(response);
    return list.map((e) => StockMovement.fromJson(e)).toList();
  }
}
