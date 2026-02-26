import 'package:supabase_flutter/supabase_flutter.dart';
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

  /// Record a stock movement and update item stock.
  /// For types that reduce stock (waste, donation, sponsorship, out, staff_meal): decrement current_stock.
  /// For freezer: optional — if inventory has stock_on_hand_fresh/frozen, caller can pass metadata.markdown_pct.
  /// For in/production: increment current_stock.
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
    final row = {
      'item_id': itemId,
      'movement_type': movementType.dbValue,
      'quantity': quantity,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'location_from': locationFromId,
      'location_to': locationToId,
      'staff_id': performedBy,
      'notes': notes,
      'metadata': metadata,
    };
    final response = await _client
        .from('stock_movements')
        .insert(row)
        .select()
        .single();
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

    // Update inventory_items stock: use current_stock if present; else no-op (caller may update fresh/frozen separately)
    await _applyStockChange(
      itemId: itemId,
      movementType: movementType,
      quantity: quantity,
      metadata: metadata,
    );
    return movement;
  }

  /// Apply stock level change for a movement (current_stock column).
  Future<void> _applyStockChange({
    required String itemId,
    required MovementType movementType,
    required double quantity,
    Map<String, dynamic>? metadata,
  }) async {
    // Check if inventory_items has current_stock (003 RPC uses it)
    final item = await _client
        .from('inventory_items')
        .select('id, current_stock, stock_on_hand_fresh, stock_on_hand_frozen')
        .eq('id', itemId)
        .maybeSingle();
    if (item == null) return;

    final hasCurrentStock = item.containsKey('current_stock');
    final hasFreshFrozen =
        item.containsKey('stock_on_hand_fresh') &&
            item.containsKey('stock_on_hand_frozen');

    if (movementType == MovementType.freezer && hasFreshFrozen) {
      // Move to freezer: reduce fresh, increase frozen (same total)
      final fresh = (item['stock_on_hand_fresh'] as num?)?.toDouble() ?? 0;
      final frozen = (item['stock_on_hand_frozen'] as num?)?.toDouble() ?? 0;
      final pct = (metadata?['markdown_pct'] as num?)?.toDouble() ?? 100.0;
      final moveQty = quantity * (pct / 100).clamp(0.0, 1.0);
      await _client.from('inventory_items').update({
        'stock_on_hand_fresh': (fresh - moveQty).clamp(0.0, double.infinity),
        'stock_on_hand_frozen': frozen + moveQty,
      }).eq('id', itemId);
      return;
    }

    if (quantity == 0) return;
    if (movementType.reducesStock) {
      if (hasCurrentStock) {
        final cur = (item['current_stock'] as num?)?.toDouble() ?? 0;
        await _client.from('inventory_items').update({
          'current_stock': (cur - quantity).clamp(0.0, double.infinity),
        }).eq('id', itemId);
      } else if (hasFreshFrozen) {
        final fresh = (item['stock_on_hand_fresh'] as num?)?.toDouble() ?? 0;
        final deduct = quantity > fresh ? fresh : quantity;
        await _client.from('inventory_items').update({
          'stock_on_hand_fresh': (fresh - deduct).clamp(0.0, double.infinity),
        }).eq('id', itemId);
      }
    } else if (movementType.increasesStock) {
      if (hasCurrentStock) {
        final cur = (item['current_stock'] as num?)?.toDouble() ?? 0;
        await _client.from('inventory_items').update({
          'current_stock': cur + quantity,
        }).eq('id', itemId);
      } else if (hasFreshFrozen) {
        final fresh = (item['stock_on_hand_fresh'] as num?)?.toDouble() ?? 0;
        await _client.from('inventory_items').update({
          'stock_on_hand_fresh': fresh + quantity,
        }).eq('id', itemId);
      }
    }
    // transfer: total unchanged; location-level handled by caller or separate table
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
      'quantity': variance.abs(),
      'staff_id': performedBy,
      'notes': notes ?? 'Stock take: was $cur, set to $actualQuantity',
      'metadata': {'previous': cur, 'actual': actualQuantity},
    };
    final response = await _client
        .from('stock_movements')
        .insert(row)
        .select()
        .single();

    // C1: Adjustment updates current_stock only (never fresh/frozen).
    if (item.containsKey('current_stock')) {
      await _client.from('inventory_items').update({
        'current_stock': actualQuantity,
      }).eq('id', itemId);
    }

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
