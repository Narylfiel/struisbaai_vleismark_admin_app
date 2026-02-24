import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import '../../inventory/services/inventory_repository.dart';
import '../../../core/models/stock_movement.dart';
import '../models/production_batch.dart';
import '../models/production_batch_ingredient.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';
import 'recipe_repository.dart';

/// Blueprint §5.5: Production batches — input → output; deduct ingredients, add output product.
class ProductionBatchRepository {
  final SupabaseClient _client;
  final RecipeRepository _recipeRepo;
  final InventoryRepository _inventoryRepo;

  ProductionBatchRepository({
    SupabaseClient? client,
    RecipeRepository? recipeRepo,
    InventoryRepository? inventoryRepo,
  })  : _client = client ?? SupabaseService.client,
        _recipeRepo = recipeRepo ?? RecipeRepository(client: client),
        _inventoryRepo = inventoryRepo ?? InventoryRepository(client: client);

  Future<List<ProductionBatch>> getBatches({String? status}) async {
    var q = _client.from('production_batches').select();
    if (status != null && status.isNotEmpty) {
      q = q.eq('status', status);
    }
    final list = await q.order('created_at', ascending: false);
    return (list as List)
        .map((e) => ProductionBatch.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProductionBatch?> getBatch(String id) async {
    final row = await _client
        .from('production_batches')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return ProductionBatch.fromJson(row as Map<String, dynamic>);
  }

  /// Start a batch: create batch + batch_ingredients from recipe (scaled by planned qty / batch_size_kg).
  /// DB has no batch_number column; do not include it in insert.
  Future<ProductionBatch> createBatch({
    required String recipeId,
    required int plannedQuantity,
    required String? outputProductId,
    String? performedBy,
  }) async {
    final recipe = await _recipeRepo.getRecipe(recipeId);
    if (recipe == null) throw ArgumentError('Recipe not found: $recipeId');
    final outProductId = outputProductId ?? recipe.outputProductId;
    if (outProductId == null || outProductId.isEmpty) {
      throw ArgumentError('Recipe has no output product; set output_product_id');
    }
    final ingredients = await _recipeRepo.getIngredientsByRecipe(recipeId);
    final scale = plannedQuantity / (recipe.batchSizeKg > 0 ? recipe.batchSizeKg : 1);

    // DB columns: batch_date (NOT NULL), recipe_id, qty_produced, unit, cost_total, notes, status, output_product_id. No batch_number.
    final batchData = {
      'batch_date': DateTime.now().toIso8601String().substring(0, 10),
      'recipe_id': recipeId,
      'qty_produced': plannedQuantity,
      'output_product_id': outProductId,
      'status': 'pending',
      'notes': null,
    };
    final batchRow = await _client
        .from('production_batches')
        .insert(batchData)
        .select()
        .single();
    final batch = ProductionBatch.fromJson(batchRow as Map<String, dynamic>);

    for (final ing in ingredients) {
      final plannedQty = (ing.quantity * scale).toDouble();
      await _client.from('production_batch_ingredients').insert({
        'batch_id': batch.id,
        'ingredient_id': ing.id,
        'planned_quantity': plannedQty,
        'actual_quantity': null,
      });
    }
    return batch;
  }

  Future<List<ProductionBatchIngredient>> getBatchIngredients(String batchId) async {
    final list = await _client
        .from('production_batch_ingredients')
        .select()
        .eq('batch_id', batchId);
    return (list as List)
        .map((e) => ProductionBatchIngredient.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProductionBatch> startBatch(String batchId, String startedBy) async {
    // DB has no started_at, started_by — only status
    final response = await _client
        .from('production_batches')
        .update({'status': 'in_progress'})
        .eq('id', batchId)
        .select()
        .single();
    return ProductionBatch.fromJson(response as Map<String, dynamic>);
  }

  /// Complete batch: update actuals, deduct ingredients, add each output product to stock.
  /// outputs: list of {inventory_item_id, qty_produced, unit, notes?}
  Future<ProductionBatch> completeBatch({
    required String batchId,
    required Map<String, double> actualQuantitiesByIngredientId,
    required List<Map<String, dynamic>> outputs,
    required String completedBy,
    num? costTotal,
  }) async {
    final batch = await getBatch(batchId);
    if (batch == null) throw ArgumentError('Batch not found: $batchId');
    if (batch.status == ProductionBatchStatus.complete) {
      throw StateError('Batch already completed');
    }
    if (outputs.isEmpty) throw ArgumentError('At least one output product required');

    final batchIngredients = await getBatchIngredients(batchId);
    for (final bi in batchIngredients) {
      final actualQty = actualQuantitiesByIngredientId[bi.ingredientId] ?? bi.plannedQuantity;
      await _client
          .from('production_batch_ingredients')
          .update({
            'actual_quantity': actualQty,
            'used_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bi.id);
    }

    // Deduct ingredients from inventory
    for (final bi in batchIngredients) {
      final actualQty = actualQuantitiesByIngredientId[bi.ingredientId] ?? bi.plannedQuantity;
      if (actualQty <= 0) continue;
      final ri = await _recipeRepo.getIngredient(bi.ingredientId);
      if (ri?.inventoryItemId != null && ri!.inventoryItemId!.isNotEmpty) {
        await _inventoryRepo.recordMovement(
          itemId: ri.inventoryItemId!,
          movementType: MovementType.out,
          quantity: actualQty,
          referenceType: 'production',
          referenceId: batchId,
          performedBy: completedBy,
          notes: 'Production batch ${batch.batchNumber}',
        );
      }
    }

    double totalQty = 0;
    for (final out in outputs) {
      final itemId = out['inventory_item_id'] as String?;
      final qty = (out['qty_produced'] as num?)?.toDouble();
      final unit = out['unit'] as String? ?? 'kg';
      final notes = out['notes'] as String?;
      if (itemId == null || itemId.isEmpty || qty == null || qty <= 0) continue;
      totalQty += qty;

      await _client.from('production_batch_outputs').insert({
        'batch_id': batchId,
        'inventory_item_id': itemId,
        'qty_produced': qty,
        'unit': unit,
        'notes': notes,
      });

      await _inventoryRepo.recordMovement(
        itemId: itemId,
        movementType: MovementType.production,
        quantity: qty,
        referenceType: 'production',
        referenceId: batchId,
        performedBy: completedBy,
        notes: 'Production batch ${batch.batchNumber}',
      );
    }

    // DB columns: status (CHECK: pending, in_progress, complete), cost_total, qty_produced. No actual_quantity, completed_at, completed_by.
    final updateData = <String, dynamic>{
      'status': 'complete',
      'qty_produced': totalQty,
    };
    if (costTotal != null) updateData['cost_total'] = costTotal;

    final response = await _client
        .from('production_batches')
        .update(updateData)
        .eq('id', batchId)
        .select()
        .single();
    return ProductionBatch.fromJson(response as Map<String, dynamic>);
  }

  Future<ProductionBatch> cancelBatch(String batchId) async {
    // DB status CHECK allows only: pending, in_progress, complete — no 'cancelled'. Leave batch status unchanged.
    final batch = await getBatch(batchId);
    if (batch == null) throw ArgumentError('Batch not found: $batchId');
    return batch;
  }
}
