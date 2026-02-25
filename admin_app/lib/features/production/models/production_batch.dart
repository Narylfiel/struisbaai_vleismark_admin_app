import '../../../core/models/base_model.dart';

/// Blueprint §5.5: Production batch — input → output tracking; deduct ingredients, add output product.
/// DB CHECK: pending, in_progress, complete (no cancelled).
enum ProductionBatchStatus {
  pending,
  inProgress,
  complete,
}

extension ProductionBatchStatusExt on ProductionBatchStatus {
  String get dbValue {
    switch (this) {
      case ProductionBatchStatus.pending:
        return 'pending';
      case ProductionBatchStatus.inProgress:
        return 'in_progress';
      case ProductionBatchStatus.complete:
        return 'complete';
    }
  }

  /// User-friendly label for UI (DB value is lowercase/snake_case).
  String get displayLabel {
    switch (this) {
      case ProductionBatchStatus.pending:
        return 'Pending';
      case ProductionBatchStatus.inProgress:
        return 'In progress';
      case ProductionBatchStatus.complete:
        return 'Complete';
    }
  }

  static ProductionBatchStatus fromDb(String? value) {
    switch (value) {
      case 'pending':
        return ProductionBatchStatus.pending;
      case 'in_progress':
        return ProductionBatchStatus.inProgress;
      case 'complete':
        return ProductionBatchStatus.complete;
      default:
        return ProductionBatchStatus.pending;
    }
  }
}

class ProductionBatch extends BaseModel {
  /// Display label: DB has no batch_number column; use id (first 8 chars).
  String get batchNumber => 'Batch #${id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase()}';
  final String recipeId;
  final int plannedQuantity;
  final int? actualQuantity;
  final ProductionBatchStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? startedBy;
  final String? completedBy;
  final String? notes;
  /// Output product to add on completion (from recipe)
  final String? outputProductId;
  /// Parent batch when this batch is a split child.
  final String? parentBatchId;
  /// Note describing the split (e.g. output product per split).
  final String? splitNote;

  const ProductionBatch({
    required super.id,
    required this.recipeId,
    required this.plannedQuantity,
    this.actualQuantity,
    this.status = ProductionBatchStatus.pending,
    this.startedAt,
    this.completedAt,
    this.startedBy,
    this.completedBy,
    this.notes,
    this.outputProductId,
    this.parentBatchId,
    this.splitNote,
    super.createdAt,
    super.updatedAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'planned_quantity': plannedQuantity,
      'actual_quantity': actualQuantity,
      'status': status.dbValue,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'started_by': startedBy,
      'completed_by': completedBy,
      'notes': notes,
      'output_product_id': outputProductId,
      if (parentBatchId != null) 'parent_batch_id': parentBatchId,
      if (splitNote != null) 'split_note': splitNote,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory ProductionBatch.fromJson(Map<String, dynamic> json) {
    return ProductionBatch(
      id: json['id'] as String,
      recipeId: json['recipe_id'] as String? ?? '',
      plannedQuantity: ((json['planned_quantity'] ?? json['qty_produced']) as num?)?.toInt() ?? 0,
      actualQuantity: (json['actual_quantity'] as num?)?.toInt(),
      status: ProductionBatchStatusExt.fromDb(json['status'] as String?),
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      startedBy: json['started_by'] as String?,
      completedBy: json['completed_by'] as String?,
      notes: json['notes'] as String?,
      outputProductId: json['output_product_id'] as String?,
      parentBatchId: json['parent_batch_id'] as String?,
      splitNote: json['split_note'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  bool validate() => recipeId.isNotEmpty && plannedQuantity > 0;

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (recipeId.isEmpty) errors.add('Recipe is required');
    if (plannedQuantity <= 0) errors.add('Planned quantity must be positive');
    return errors;
  }
}
