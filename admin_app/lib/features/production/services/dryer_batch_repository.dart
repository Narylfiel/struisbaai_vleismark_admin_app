import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/audit_service.dart';
import '../../inventory/services/inventory_repository.dart';
import '../../../core/models/stock_movement.dart';
import '../models/dryer_batch.dart';
import '../models/dryer_batch_ingredient.dart';

/// Blueprint §5.6: Dryer batches — Biltong/Droewors/Chilli Bites; weight loss tracking; deduct raw, add output.
class DryerBatchRepository {
  final SupabaseClient _client;
  final InventoryRepository _inventoryRepo;

  DryerBatchRepository({
    SupabaseClient? client,
    InventoryRepository? inventoryRepo,
  })  : _client = client ?? SupabaseService.client,
        _inventoryRepo = inventoryRepo ?? InventoryRepository(client: client);

  Future<List<DryerBatch>> getBatches({String? status}) async {
    var q = _client.from('dryer_batches').select();
    if (status != null && status.isNotEmpty) {
      q = q.eq('status', status);
    }
    // Order by id only (batch_number/started_at may not exist in some DBs); sort in Dart below
    final list = await q.order('id', ascending: false);
    final batches = (list as List)
        .map((e) => DryerBatch.fromJson(e as Map<String, dynamic>))
        .toList();
    // Sort by startedAt in case DB only has start_date (no started_at column yet)
    batches.sort((a, b) {
      final at = a.startedAt ?? DateTime(0);
      final bt = b.startedAt ?? DateTime(0);
      return bt.compareTo(at);
    });
    return batches;
  }

  Future<DryerBatch?> getBatch(String id) async {
    final row = await _client
        .from('dryer_batches')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return DryerBatch.fromJson(row as Map<String, dynamic>);
  }

  Future<String> _nextBatchNumber() async {
    final prefix = 'DB-${DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '')}-';
    try {
      final list = await _client
          .from('dryer_batches')
          .select('batch_number')
          .like('batch_number', '$prefix%')
          .order('batch_number', ascending: false)
          .limit(1);
      if (list.isEmpty) return '${prefix}001';
      final last = list.first['batch_number'] as String? ?? '';
      final numPart = last.length > prefix.length
          ? int.tryParse(last.substring(prefix.length)) ?? 0
          : 0;
      return '$prefix${(numPart + 1).toString().padLeft(3, '0')}';
    } catch (_) {
      return '${prefix}${DateTime.now().millisecondsSinceEpoch % 1000}';
    }
  }

  /// Load dryer: create batch (status drying), deduct raw material stock.
  Future<DryerBatch> createBatch({
    String? batchNumber,
    required String productName,
    required double inputWeightKg,
    required String dryerType,
    double? kwhPerHour,
    double? plannedHours,
    String? inputProductId,
    String? outputProductId,
    String? recipeId,
    String? productionBatchId,
    String? processedBy,
    String? notes,
    List<DryerBatchIngredient>? ingredients,
    bool deductInputNow = true,
    String? performedBy,
  }) async {
    if (outputProductId == null || outputProductId.isEmpty) {
      throw ArgumentError(
        'A dryer batch cannot be created without an output product. Link a finished product to the recipe first.',
      );
    }
    final batchNum = (batchNumber == null || batchNumber.isEmpty) ? await _nextBatchNumber() : batchNumber;
    final now = DateTime.now().toIso8601String();
    // DB columns: weight_in, status, started_at, loaded_at, kwh_per_hour, planned_hours, ...
    final data = {
      'batch_number': batchNum,
      'weight_in': inputWeightKg,
      'status': 'drying',
      'started_at': now,
      'loaded_at': now,
      'kwh_per_hour': kwhPerHour ?? 2.5,
      if (plannedHours != null && plannedHours > 0) 'planned_hours': plannedHours,
      'input_product_id': inputProductId?.isEmpty == true ? null : inputProductId,
      'output_product_id': outputProductId?.isEmpty == true ? null : outputProductId,
      if (recipeId != null && recipeId.isNotEmpty) 'recipe_id': recipeId,
      if (productionBatchId != null && productionBatchId.isNotEmpty) 'production_batch_id': productionBatchId,
      'notes': notes,
    };
    final row = await _client
        .from('dryer_batches')
        .insert(data)
        .select()
        .single();
    final batch = DryerBatch.fromJson(row as Map<String, dynamic>);

    if (ingredients != null && ingredients.isNotEmpty) {
      for (final ing in ingredients) {
        await _client.from('dryer_batch_ingredients').insert({
          'batch_id': batch.id,
          'inventory_item_id': ing.inventoryItemId,
          'quantity_used': ing.quantityUsed,
          'added_at': DateTime.now().toIso8601String(),
        });
        if (deductInputNow && ing.quantityUsed > 0) {
          await _inventoryRepo.recordMovement(
            itemId: ing.inventoryItemId,
            movementType: MovementType.out,
            quantity: ing.quantityUsed,
            referenceType: 'production',
            referenceId: batch.id,
            performedBy: (performedBy != null && performedBy.isNotEmpty) 
                ? performedBy 
                : (processedBy != null && processedBy.isNotEmpty ? processedBy : 'SYSTEM'),
            notes: 'Dryer batch ${batch.batchNumber}',
          );
        }
      }
    }

    if (deductInputNow &&
        inputProductId != null &&
        inputProductId.isNotEmpty &&
        inputWeightKg > 0) {
      await _inventoryRepo.recordMovement(
        itemId: inputProductId,
        movementType: MovementType.out,
        quantity: inputWeightKg,
        referenceType: 'production',
        referenceId: batch.id,
        performedBy: (performedBy != null && performedBy.isNotEmpty) 
            ? performedBy 
            : (processedBy != null && processedBy.isNotEmpty ? processedBy : 'SYSTEM'),
        notes: 'Dryer batch ${batch.batchNumber}',
      );
    }
    final updated = await getBatch(batch.id);
    return updated ?? batch;
  }

  Future<List<DryerBatchIngredient>> getBatchIngredients(String batchId) async {
    final list = await _client
        .from('dryer_batch_ingredients')
        .select()
        .eq('batch_id', batchId);
    return (list as List)
        .map((e) => DryerBatchIngredient.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Weigh out: set output weight, add finished product stock, status completed. Records completed_at, kwh_per_hour, electricity_cost.
  /// Cost formula: dryingHours = (completed_at - loaded_at) in hours; kWh = dryingHours × kwhPerHour; cost = kWh × electricityRate.
  /// kW is power only — never divide/multiply time by kW except as: kWh = hours × kW.
  Future<DryerBatch> completeBatch({
    required String batchId,
    required double outputWeightKg,
    required String completedBy,
    double kwhPerHour = 2.5,
    required double electricityRate,
  }) async {
    final batch = await getBatch(batchId);
    if (batch == null) throw ArgumentError('Batch not found: $batchId');
    if (batch.status == DryerBatchStatus.complete) {
      throw StateError('Batch already completed');
    }
    final loadedAt = batch.loadedAt ?? batch.startedAt;
    // Actual elapsed time in hours (completed_at - loaded_at); time never involves kW.
    final dryingHours = loadedAt != null
        ? (DateTime.now().difference(loadedAt).inMinutes / 60.0)
        : 0.0;
    final kWh = dryingHours * kwhPerHour;
    final electricityCost = kWh * electricityRate;
    final electricityCostRounded = (electricityCost * 100).round() / 100;

    final outputProductId = batch.outputProductId;
    String outputProductName = 'Unknown Product';
    if (outputProductId != null && outputProductId.isNotEmpty && outputWeightKg > 0) {
      // Get product name for audit
      final item = await _client
          .from('inventory_items')
          .select('name')
          .eq('id', outputProductId)
          .maybeSingle();
      outputProductName = item?['name'] ?? outputProductName;
      
      await _inventoryRepo.recordMovement(
        itemId: outputProductId,
        movementType: MovementType.production,
        quantity: outputWeightKg,
        referenceType: 'production',
        referenceId: batchId,
        performedBy: completedBy,
        notes: 'Dryer batch ${batch.batchNumber} weigh out',
      );
    }
    final response = await _client
        .from('dryer_batches')
        .update({
          'weight_out': outputWeightKg,
          'status': 'complete',
          'completed_at': DateTime.now().toIso8601String(),
          'kwh_per_hour': kwhPerHour,
          'electricity_cost': electricityCostRounded,
        })
        .eq('id', batchId)
        .select()
        .single();
    
    // Audit log - dryer batch completed
    await AuditService.log(
      action: 'UPDATE',
      module: 'Production',
      description: 'Dryer batch completed: ${batch.batchNumber} - $outputProductName ${outputWeightKg.toStringAsFixed(2)}kg',
      entityType: 'DryerBatch',
      entityId: batchId,
    );
    
    return DryerBatch.fromJson(response as Map<String, dynamic>);
  }

  Future<DryerBatch> cancelBatch(String batchId) async {
    // DB status CHECK allows only: loading, drying, complete — no 'cancelled'. Leave batch status unchanged.
    final batch = await getBatch(batchId);
    if (batch == null) throw ArgumentError('Batch not found: $batchId');
    return batch;
  }

  /// Hard delete: dryer_batch_ingredients first, then dryer_batches (no is_active flag).
  Future<void> deleteBatch(String batchId) async {
    await _client.from('dryer_batch_ingredients').delete().eq('batch_id', batchId);
    await _client.from('dryer_batches').delete().eq('id', batchId);
  }
}
