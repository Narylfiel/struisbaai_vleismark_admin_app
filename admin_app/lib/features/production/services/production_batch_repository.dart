import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/audit_service.dart';
import '../../inventory/services/inventory_repository.dart';
import '../../../core/models/stock_movement.dart';
import '../models/production_batch.dart';
import '../models/production_batch_ingredient.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';
import 'recipe_repository.dart';
import '../services/dryer_batch_repository.dart';
import '../models/dryer_batch.dart';
import '../models/dryer_batch_ingredient.dart';

/// Blueprint §5.5: Production batches — input → output; deduct ingredients, add output product.
class ProductionBatchRepository {
  final SupabaseClient _client;
  final RecipeRepository _recipeRepo;
  final InventoryRepository _inventoryRepo;
  final DryerBatchRepository _dryerRepo;

  ProductionBatchRepository({
    SupabaseClient? client,
    RecipeRepository? recipeRepo,
    InventoryRepository? inventoryRepo,
    DryerBatchRepository? dryerRepo,
  })  : _client = client ?? SupabaseService.client,
        _recipeRepo = recipeRepo ?? RecipeRepository(client: client),
        _inventoryRepo = inventoryRepo ?? InventoryRepository(client: client),
        _dryerRepo = dryerRepo ?? DryerBatchRepository();

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

  /// Split a completed/in-progress batch into output products.
  /// Each split consumes kg from the parent batch output.
  /// Each split recipe may add extra ingredients (e.g. casings).
  /// Each split outputs its own product to inventory.
  /// If split recipe.goesToDryer == true, auto-creates dryer batch.
  Future<List<ProductionBatch>> splitBatch({
    required String parentBatchId,
    required List<Map<String, dynamic>> splits,
    required String performedBy,
  }) async {
    final parent = await getBatch(parentBatchId);
    if (parent == null) throw ArgumentError('Parent batch not found');

    // Mark parent as split parent
    await _client
        .from('production_batches')
        .update({'is_split_parent': true})
        .eq('id', parentBatchId);

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final created = <ProductionBatch>[];

    for (final split in splits) {
      final recipeId = split['recipe_id'] as String?;
      final qty = (split['qty_produced'] as num?)?.toDouble();
      final notes = split['notes'] as String?;
      if (recipeId == null || recipeId.isEmpty || qty == null || qty <= 0) continue;

      final recipe = await _recipeRepo.getRecipe(recipeId);
      if (recipe == null) continue;
      final outProductId = recipe.outputProductId;
      if (outProductId == null || outProductId.isEmpty) continue;

      // Create the split batch record
      final batchData = {
        'batch_date': today,
        'recipe_id': recipeId,
        'qty_produced': qty,
        'status': 'complete',
        'parent_batch_id': parentBatchId,
        'output_product_id': outProductId,
        'notes': notes,
      };
      final row = await _client
          .from('production_batches')
          .insert(batchData)
          .select()
          .single();
      final splitBatch = ProductionBatch.fromJson(row as Map<String, dynamic>);
      created.add(splitBatch);

      // Add output product to inventory
      await _inventoryRepo.recordMovement(
        itemId: outProductId,
        movementType: MovementType.production,
        quantity: qty,
        referenceType: 'production',
        referenceId: splitBatch.id,
        performedBy: performedBy,
        notes: 'Split from batch ${parent.batchNumber}',
      );

      // Handle extra ingredients for this split (e.g. casings for sausage)
      // Extra ingredients come from the split recipe but only items NOT in the parent recipe
      final splitIngredients = await _recipeRepo.getIngredientsByRecipe(recipeId);
      final parentIngredients = await _recipeRepo.getIngredientsByRecipe(parent.recipeId);
      final parentItemIds = parentIngredients
          .map((i) => i.inventoryItemId)
          .where((id) => id != null)
          .toSet();

      final scale = qty / (recipe.batchSizeKg > 0 ? recipe.batchSizeKg : 1);

      for (final ing in splitIngredients) {
        // Only deduct ingredients NOT already in parent recipe (extra items like casings)
        if (parentItemIds.contains(ing.inventoryItemId)) continue;
        if (ing.inventoryItemId == null || ing.inventoryItemId!.isEmpty) continue;
        final scaledQty = ing.quantity * scale;
        if (scaledQty <= 0) continue;

        await _inventoryRepo.recordMovement(
          itemId: ing.inventoryItemId!,
          movementType: MovementType.out,
          quantity: scaledQty,
          referenceType: 'production',
          referenceId: splitBatch.id,
          performedBy: performedBy,
          notes: 'Split batch ${splitBatch.batchNumber} — extra ingredient',
        );
      }

      // Auto-create dryer batch if split recipe requires it
      try {
        if (recipe.goesToDryer == true &&
            recipe.dryerOutputProductId != null &&
            recipe.dryerOutputProductId!.isNotEmpty) {
          final plannedHours = (recipe.prepTimeMinutes ?? 0) > 0
              ? (recipe.prepTimeMinutes ?? 0) / 60.0
              : null;
          await _dryerRepo.createBatch(
            productName: recipe.name,
            inputWeightKg: qty,
            dryerType: _dryerTypeFromCategory(recipe.category),
            plannedHours: plannedHours,
            inputProductId: outProductId,
            outputProductId: recipe.dryerOutputProductId,
            recipeId: recipe.id,
            performedBy: performedBy,
            deductInputNow: true,
            productionBatchId: splitBatch.id,
          );
        }
      } catch (_) {}
    }

    await AuditService.log(
      action: 'UPDATE',
      module: 'Production',
      description: 'Batch ${parent.batchNumber} split into ${created.length} outputs',
      entityType: 'ProductionBatch',
      entityId: parentBatchId,
    );

    return created;
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

  /// Start a batch: create batch, scale ingredients, deduct from inventory immediately.
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
      throw ArgumentError('Recipe has no output product. Set output_product_id on recipe.');
    }
    final ingredients = await _recipeRepo.getIngredientsByRecipe(recipeId);
    final scale = plannedQuantity / (recipe.batchSizeKg > 0 ? recipe.batchSizeKg : 1);

    final batchData = {
      'batch_date': DateTime.now().toIso8601String().substring(0, 10),
      'recipe_id': recipeId,
      'qty_produced': plannedQuantity,
      'output_product_id': outProductId,
      'status': 'in_progress',
      'notes': null,
    };
    final batchRow = await _client
        .from('production_batches')
        .insert(batchData)
        .select()
        .single();
    final batch = ProductionBatch.fromJson(batchRow as Map<String, dynamic>);

    // Create batch ingredients + deduct from inventory immediately
    for (final ing in ingredients) {
      final plannedQty = (ing.quantity * scale).toDouble();
      await _client.from('production_batch_ingredients').insert({
        'batch_id': batch.id,
        'ingredient_id': ing.id,
        'planned_quantity': plannedQty,
        'actual_quantity': null,
      });
      if (ing.inventoryItemId != null && ing.inventoryItemId!.isNotEmpty && plannedQty > 0) {
        await _inventoryRepo.recordMovement(
          itemId: ing.inventoryItemId!,
          movementType: MovementType.out,
          quantity: plannedQty,
          referenceType: 'production',
          referenceId: batch.id,
          performedBy: performedBy ?? 'SYSTEM',
          notes: 'Batch ${batch.batchNumber} started',
        );
      }
    }

    await AuditService.log(
      action: 'CREATE',
      module: 'Production',
      description: 'Production batch started: ${batch.batchNumber} — ${recipe.name} ${plannedQuantity}kg',
      entityType: 'ProductionBatch',
      entityId: batch.id,
    );

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

  /// Complete batch: add output product to inventory.
  /// Ingredients already deducted on start.
  /// If recipe.goesToDryer == true, auto-creates a dryer batch.
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
    if (batch.status == ProductionBatchStatus.cancelled) {
      throw StateError('Cannot complete a cancelled batch');
    }
    if (outputs.isEmpty) throw ArgumentError('At least one output product required');

    // Update actual quantities on batch ingredients (for records only — stock already deducted)
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

    double totalQty = 0;
    String outputProductNames = '';

    for (final out in outputs) {
      final itemId = out['inventory_item_id'] as String?;
      final qty = (out['qty_produced'] as num?)?.toDouble();
      final unit = out['unit'] as String? ?? 'kg';
      final notes = out['notes'] as String?;
      if (itemId == null || itemId.isEmpty || qty == null || qty <= 0) continue;
      totalQty += qty;

      final item = await _client
          .from('inventory_items')
          .select('name')
          .eq('id', itemId)
          .maybeSingle();
      if (outputProductNames.isNotEmpty) outputProductNames += ', ';
      outputProductNames += item?['name'] ?? 'Unknown';

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
        notes: 'Production batch ${batch.batchNumber} output',
      );
    }

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

    await AuditService.log(
      action: 'UPDATE',
      module: 'Production',
      description: 'Production batch completed: ${batch.batchNumber} — ${totalQty.toStringAsFixed(2)}kg → $outputProductNames',
      entityType: 'ProductionBatch',
      entityId: batchId,
    );

    // Auto-create dryer batch if recipe requires it
    try {
      final recipe = await _recipeRepo.getRecipe(batch.recipeId);
      if (recipe != null &&
          recipe.goesToDryer == true &&
          recipe.dryerOutputProductId != null &&
          recipe.dryerOutputProductId!.isNotEmpty &&
          totalQty > 0) {
        final plannedHours = (recipe.prepTimeMinutes ?? 0) > 0
            ? (recipe.prepTimeMinutes ?? 0) / 60.0
            : null;
        await _dryerRepo.createBatch(
          productName: recipe.name,
          inputWeightKg: totalQty,
          dryerType: _dryerTypeFromCategory(recipe.category),
          plannedHours: plannedHours,
          inputProductId: batch.outputProductId,
          outputProductId: recipe.dryerOutputProductId,
          recipeId: recipe.id,
          performedBy: completedBy,
          deductInputNow: true,
          productionBatchId: batch.id,
        );
      }
    } catch (e) {
      // Auto-dryer creation failure must not fail the batch completion
      await AuditService.log(
        action: 'ERROR',
        module: 'Production',
        description: 'Auto-dryer creation failed for batch ${batch.batchNumber}: $e',
        entityType: 'ProductionBatch',
        entityId: batchId,
      );
    }

    return ProductionBatch.fromJson(response as Map<String, dynamic>);
  }

  String _dryerTypeFromCategory(String? category) {
    if (category == null) return 'other';
    final c = category.toLowerCase();
    if (c.contains('biltong')) return 'biltong';
    if (c.contains('droewors') || c.contains('drywors')) return 'droewors';
    if (c.contains('chilli')) return 'chilli_bites';
    if (c.contains('jerky')) return 'jerky';
    return 'other';
  }

  /// Cancel batch: reverse all ingredient deductions back to inventory.
  Future<ProductionBatch> cancelBatch(String batchId, String cancelledBy) async {
    final batch = await getBatch(batchId);
    if (batch == null) throw ArgumentError('Batch not found: $batchId');
    if (batch.status == ProductionBatchStatus.complete) {
      throw StateError('Cannot cancel a completed batch');
    }
    if (batch.status == ProductionBatchStatus.cancelled) {
      throw StateError('Batch already cancelled');
    }

    final batchIngredients = await getBatchIngredients(batchId);
    for (final bi in batchIngredients) {
      final ri = await _recipeRepo.getIngredient(bi.ingredientId);
      if (ri?.inventoryItemId != null && ri!.inventoryItemId!.isNotEmpty) {
        final qtyToReturn = bi.actualQuantity ?? bi.plannedQuantity;
        if (qtyToReturn > 0) {
          await _inventoryRepo.recordMovement(
            itemId: ri.inventoryItemId!,
            movementType: MovementType.adjustment,
            quantity: qtyToReturn,
            referenceType: 'production',
            referenceId: batchId,
            performedBy: cancelledBy,
            notes: 'Batch ${batch.batchNumber} cancelled — stock returned',
          );
        }
      }
    }

    final response = await _client
        .from('production_batches')
        .update({'status': 'cancelled'})
        .eq('id', batchId)
        .select()
        .single();

    await AuditService.log(
      action: 'UPDATE',
      module: 'Production',
      description: 'Production batch cancelled: ${batch.batchNumber} — ingredients returned to stock',
      entityType: 'ProductionBatch',
      entityId: batchId,
    );

    return ProductionBatch.fromJson(response as Map<String, dynamic>);
  }

  /// Returns true if any batch has parent_batch_id == batchId.
  Future<bool> hasChildBatches(String batchId) async {
    final list = await _client
        .from('production_batches')
        .select('id')
        .eq('parent_batch_id', batchId)
        .limit(1);
    return (list as List).isNotEmpty;
  }

  /// Delete batch with full stock reversal.
  /// Reverses ingredient deductions, output additions, and linked dryer batch.
  Future<void> deleteBatch(String batchId) async {
    final batch = await getBatch(batchId);
    if (batch == null) throw ArgumentError('Batch not found: $batchId');

    final hasChildren = await hasChildBatches(batchId);
    if (hasChildren) {
      throw StateError('Cannot delete — this batch has splits. Delete splits first.');
    }

    // Reverse ingredient stock movements if batch was started
    if (batch.status == ProductionBatchStatus.inProgress ||
        batch.status == ProductionBatchStatus.complete) {
      final batchIngredients = await getBatchIngredients(batchId);
      for (final bi in batchIngredients) {
        final ri = await _recipeRepo.getIngredient(bi.ingredientId);
        if (ri?.inventoryItemId != null && ri!.inventoryItemId!.isNotEmpty) {
          final qtyToReturn = bi.actualQuantity ?? bi.plannedQuantity;
          if (qtyToReturn > 0) {
            await _inventoryRepo.recordMovement(
              itemId: ri.inventoryItemId!,
              movementType: MovementType.adjustment,
              quantity: qtyToReturn,
              referenceType: 'production',
              referenceId: batchId,
              performedBy: 'SYSTEM',
              notes: 'Batch ${batch.batchNumber} deleted — ingredient returned',
            );
          }
        }
      }
    }

    // Reverse output stock if batch was completed
    if (batch.status == ProductionBatchStatus.complete) {
      final outputs = await _client
          .from('production_batch_outputs')
          .select()
          .eq('batch_id', batchId);
      for (final out in outputs as List) {
        final itemId = out['inventory_item_id'] as String?;
        final qty = (out['qty_produced'] as num?)?.toDouble() ?? 0;
        if (itemId != null && itemId.isNotEmpty && qty > 0) {
          await _inventoryRepo.recordMovement(
            itemId: itemId,
            movementType: MovementType.out,
            quantity: qty,
            referenceType: 'production',
            referenceId: batchId,
            performedBy: 'SYSTEM',
            notes: 'Batch ${batch.batchNumber} deleted — output reversed',
          );
        }
      }
    }

    // Find and delete linked dryer batch
    final dryerBatches = await _client
        .from('dryer_batches')
        .select()
        .eq('production_batch_id', batchId);
    for (final db in dryerBatches as List) {
      final dryerBatchId = db['id'] as String;
      final dryerStatus = db['status'] as String? ?? '';
      final inputProductId = db['input_product_id'] as String?;
      final inputWeight = (db['weight_in'] as num?)?.toDouble() ?? 0;
      final outputProductId = db['output_product_id'] as String?;
      final outputWeight = (db['weight_out'] as num?)?.toDouble() ?? 0;

      // Reverse dryer input deduction
      if (inputProductId != null && inputProductId.isNotEmpty && inputWeight > 0) {
        await _inventoryRepo.recordMovement(
          itemId: inputProductId,
          movementType: MovementType.adjustment,
          quantity: inputWeight,
          referenceType: 'production',
          referenceId: dryerBatchId,
          performedBy: 'SYSTEM',
          notes: 'Dryer batch deleted with production batch ${batch.batchNumber}',
        );
      }

      // Reverse dryer output if completed
      if (dryerStatus == 'complete' &&
          outputProductId != null &&
          outputProductId.isNotEmpty &&
          outputWeight > 0) {
        await _inventoryRepo.recordMovement(
          itemId: outputProductId,
          movementType: MovementType.out,
          quantity: outputWeight,
          referenceType: 'production',
          referenceId: dryerBatchId,
          performedBy: 'SYSTEM',
          notes: 'Dryer batch deleted — output reversed',
        );
      }

      // Delete dryer batch records
      await _client
          .from('dryer_batch_ingredients')
          .delete()
          .eq('batch_id', dryerBatchId);
      await _client
          .from('dryer_batches')
          .delete()
          .eq('id', dryerBatchId);
    }

    // Delete production batch records
    await _client
        .from('production_batch_ingredients')
        .delete()
        .eq('batch_id', batchId);
    await _client
        .from('production_batch_outputs')
        .delete()
        .eq('batch_id', batchId);
    await _client
        .from('production_batches')
        .delete()
        .eq('id', batchId);

    await AuditService.log(
      action: 'DELETE',
      module: 'Production',
      description: 'Production batch deleted with stock reversal: ${batch.batchNumber}',
      entityType: 'ProductionBatch',
      entityId: batchId,
    );
  }

  /// Edit batch ingredient quantities and/or output qty with stock adjustment.
  /// Calculates diff between old and new quantities and adjusts inventory accordingly.
  Future<ProductionBatch> editBatch({
    required String batchId,
    required Map<String, double> newIngredientQtys,
    required List<Map<String, dynamic>> newOutputs,
    String? editedBy,
    num? costTotal,
  }) async {
    final batch = await getBatch(batchId);
    if (batch == null) throw ArgumentError('Batch not found: $batchId');
    if (batch.status == ProductionBatchStatus.cancelled) {
      throw StateError('Cannot edit a cancelled batch');
    }

    final performer = editedBy ?? 'SYSTEM';

    // Adjust ingredient stock differences
    final batchIngredients = await getBatchIngredients(batchId);
    for (final bi in batchIngredients) {
      final newQty = newIngredientQtys[bi.ingredientId];
      if (newQty == null) continue;
      final oldQty = bi.actualQuantity ?? bi.plannedQuantity;
      final diff = newQty - oldQty;

      final ri = await _recipeRepo.getIngredient(bi.ingredientId);
      if (ri?.inventoryItemId == null || ri!.inventoryItemId!.isEmpty) continue;

      if (diff > 0) {
        // Used more — deduct extra
        await _inventoryRepo.recordMovement(
          itemId: ri.inventoryItemId!,
          movementType: MovementType.out,
          quantity: diff,
          referenceType: 'production',
          referenceId: batchId,
          performedBy: performer,
          notes: 'Batch ${batch.batchNumber} edited — extra deduction',
        );
      } else if (diff < 0) {
        // Used less — return difference
        await _inventoryRepo.recordMovement(
          itemId: ri.inventoryItemId!,
          movementType: MovementType.adjustment,
          quantity: diff.abs(),
          referenceType: 'production',
          referenceId: batchId,
          performedBy: performer,
          notes: 'Batch ${batch.batchNumber} edited — stock returned',
        );
      }

      // Update the batch ingredient record
      await _client
          .from('production_batch_ingredients')
          .update({
            'actual_quantity': newQty,
            'used_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bi.id);
    }

    // If complete, adjust output stock differences
    if (batch.status == ProductionBatchStatus.complete && newOutputs.isNotEmpty) {
      final oldOutputs = await _client
          .from('production_batch_outputs')
          .select()
          .eq('batch_id', batchId);

      // Reverse all old outputs
      for (final out in oldOutputs as List) {
        final itemId = out['inventory_item_id'] as String?;
        final qty = (out['qty_produced'] as num?)?.toDouble() ?? 0;
        if (itemId != null && itemId.isNotEmpty && qty > 0) {
          await _inventoryRepo.recordMovement(
            itemId: itemId,
            movementType: MovementType.out,
            quantity: qty,
            referenceType: 'production',
            referenceId: batchId,
            performedBy: performer,
            notes: 'Batch ${batch.batchNumber} edit — old output reversed',
          );
        }
      }

      // Delete old output records
      await _client
          .from('production_batch_outputs')
          .delete()
          .eq('batch_id', batchId);

      // Insert new outputs and add to stock
      double totalQty = 0;
      for (final out in newOutputs) {
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
          performedBy: performer,
          notes: 'Batch ${batch.batchNumber} edit — updated output',
        );
      }

      // Update batch qty
      final updateData = <String, dynamic>{'qty_produced': totalQty};
      if (costTotal != null) updateData['cost_total'] = costTotal;
      await _client
          .from('production_batches')
          .update(updateData)
          .eq('id', batchId);
    }

    await AuditService.log(
      action: 'UPDATE',
      module: 'Production',
      description: 'Production batch edited with stock adjustment: ${batch.batchNumber}',
      entityType: 'ProductionBatch',
      entityId: batchId,
    );

    return await getBatch(batchId) ?? batch;
  }
}
