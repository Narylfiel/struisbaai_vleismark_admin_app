import 'package:isar/isar.dart';

part 'cached_production_batch.g.dart';

/// Isar collection for production batches cached for offline list view.
@collection
class CachedProductionBatch {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String batchId;

  String? batchNumber;
  String? recipeId;
  String? recipeName;
  double? plannedQuantity;
  double? actualQuantity;
  late String status;
  DateTime? startedAt;
  DateTime? completedAt;
  String? startedBy;
  String? completedBy;
  String? outputProductId;
  String? outputProductName;
  String? notes;
  String? parentBatchId;
  String? splitNote;
  late bool isSplitParent;
  DateTime? createdAt;
  DateTime? updatedAt;
  late DateTime cachedAt;

  CachedProductionBatch();

  /// From Supabase production_batches row (with optional recipe/product names from lookups).
  factory CachedProductionBatch.fromSupabase(
    Map<String, dynamic> row, {
    String? recipeName,
    String? outputProductName,
  }) {
    final c = CachedProductionBatch();
    final bid = row['id']?.toString() ?? '';
    c.batchId = bid;
    c.batchNumber = bid.length >= 8 ? 'Batch #${bid.substring(0, 8).toUpperCase()}' : 'Batch #${bid.toUpperCase()}';
    c.recipeId = row['recipe_id']?.toString();
    c.recipeName = recipeName;
    c.plannedQuantity = (row['planned_quantity'] ?? row['qty_produced'] as num?)?.toDouble();
    c.actualQuantity = (row['actual_quantity'] as num?)?.toDouble();
    c.status = row['status']?.toString() ?? 'pending';
    c.startedAt = row['started_at'] != null ? DateTime.tryParse(row['started_at'] as String) : null;
    c.completedAt = row['completed_at'] != null ? DateTime.tryParse(row['completed_at'] as String) : null;
    c.startedBy = row['started_by']?.toString();
    c.completedBy = row['completed_by']?.toString();
    c.outputProductId = row['output_product_id']?.toString();
    c.outputProductName = outputProductName;
    c.notes = row['notes']?.toString();
    c.parentBatchId = row['parent_batch_id']?.toString();
    c.splitNote = row['split_note']?.toString();
    c.isSplitParent = row['is_split_parent'] == true;
    c.createdAt = row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null;
    c.updatedAt = row['updated_at'] != null ? DateTime.tryParse(row['updated_at'] as String) : null;
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  /// To map compatible with ProductionBatch.fromJson (for list screen).
  Map<String, dynamic> toBatchMap() => {
        'id': batchId,
        'recipe_id': recipeId,
        'planned_quantity': plannedQuantity?.toInt() ?? 0,
        'actual_quantity': actualQuantity?.toInt(),
        'status': status,
        'started_at': startedAt?.toUtc().toIso8601String(),
        'completed_at': completedAt?.toUtc().toIso8601String(),
        'started_by': startedBy,
        'completed_by': completedBy,
        'notes': notes,
        'output_product_id': outputProductId,
        'parent_batch_id': parentBatchId,
        'split_note': splitNote,
        'is_split_parent': isSplitParent,
        'created_at': createdAt?.toUtc().toIso8601String(),
        'updated_at': updatedAt?.toUtc().toIso8601String(),
      };
}
