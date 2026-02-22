import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';
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
    String? inputProductId,
    String? outputProductId,
    String? recipeId,
    String? processedBy,
    String? notes,
    List<DryerBatchIngredient>? ingredients,
    bool deductInputNow = true,
    String? performedBy,
  }) async {
    final batchNum = (batchNumber == null || batchNumber.isEmpty) ? await _nextBatchNumber() : batchNumber;
    final data = {
      'batch_number': batchNum,
      'product_name': productName,
      'input_weight_kg': inputWeightKg,
      'dryer_type': dryerType,
      'status': 'drying',
      'started_at': DateTime.now().toIso8601String(),
      'input_product_id': inputProductId,
      'output_product_id': outputProductId,
      'recipe_id': recipeId,
      'processed_by': processedBy,
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
            performedBy: performedBy ?? processedBy ?? '',
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
        performedBy: performedBy ?? processedBy ?? '',
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

  /// Weigh out: set output weight, add finished product stock, status completed.
  Future<DryerBatch> completeBatch({
    required String batchId,
    required double outputWeightKg,
    required String completedBy,
  }) async {
    final batch = await getBatch(batchId);
    if (batch == null) throw ArgumentError('Batch not found: $batchId');
    if (batch.status == DryerBatchStatus.completed) {
      throw StateError('Batch already completed');
    }
    final outputProductId = batch.outputProductId;
    if (outputProductId != null && outputProductId.isNotEmpty && outputWeightKg > 0) {
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
          'output_weight_kg': outputWeightKg,
          'status': 'completed',
          'completed_at': DateTime.now().toIso8601String(),
          'processed_by': completedBy,
        })
        .eq('id', batchId)
        .select()
        .single();
    return DryerBatch.fromJson(response as Map<String, dynamic>);
  }

  Future<DryerBatch> cancelBatch(String batchId) async {
    final response = await _client
        .from('dryer_batches')
        .update({'status': 'cancelled'})
        .eq('id', batchId)
        .select()
        .single();
    return DryerBatch.fromJson(response as Map<String, dynamic>);
  }
}
