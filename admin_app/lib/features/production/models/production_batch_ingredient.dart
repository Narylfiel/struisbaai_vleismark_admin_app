import '../../../core/models/base_model.dart';

/// Blueprint §5.5: Production batch ingredient — planned vs actual quantity used.
class ProductionBatchIngredient extends BaseModel {
  final String batchId;
  /// References recipe_ingredients(id)
  final String ingredientId;
  final double plannedQuantity;
  final double? actualQuantity;
  final DateTime? usedAt;

  const ProductionBatchIngredient({
    required super.id,
    required this.batchId,
    required this.ingredientId,
    required this.plannedQuantity,
    this.actualQuantity,
    this.usedAt,
    super.createdAt,
    super.updatedAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_id': batchId,
      'ingredient_id': ingredientId,
      'planned_quantity': plannedQuantity,
      'actual_quantity': actualQuantity,
      'used_at': usedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory ProductionBatchIngredient.fromJson(Map<String, dynamic> json) {
    return ProductionBatchIngredient(
      id: json['id'] as String,
      batchId: json['batch_id'] as String? ?? '',
      ingredientId: json['ingredient_id'] as String? ?? '',
      plannedQuantity: (json['planned_quantity'] as num?)?.toDouble() ?? 0,
      actualQuantity: (json['actual_quantity'] as num?)?.toDouble(),
      usedAt: json['used_at'] != null
          ? DateTime.tryParse(json['used_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  bool validate() =>
      batchId.isNotEmpty && ingredientId.isNotEmpty && plannedQuantity >= 0;

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (batchId.isEmpty) errors.add('Batch is required');
    if (ingredientId.isEmpty) errors.add('Ingredient is required');
    if (plannedQuantity < 0) errors.add('Planned quantity must be non-negative');
    return errors;
  }
}
