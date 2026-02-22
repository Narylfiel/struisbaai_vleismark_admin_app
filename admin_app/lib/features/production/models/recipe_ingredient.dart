import '../../../core/models/base_model.dart';

/// Blueprint §5.5: Recipe ingredient — per batch (e.g. Beef Mince 5.0 kg per 10kg batch).
class RecipeIngredient extends BaseModel {
  final String recipeId;
  final String? inventoryItemId;
  final String ingredientName;
  final double quantity;
  final String unit;
  final int sortOrder;
  final bool isOptional;
  final String? notes;

  const RecipeIngredient({
    required super.id,
    required this.recipeId,
    this.inventoryItemId,
    required this.ingredientName,
    required this.quantity,
    required this.unit,
    this.sortOrder = 0,
    this.isOptional = false,
    this.notes,
    super.createdAt,
    super.updatedAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'inventory_item_id': inventoryItemId,
      'ingredient_name': ingredientName,
      'quantity': quantity,
      'unit': unit,
      'sort_order': sortOrder,
      'is_optional': isOptional,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      id: json['id'] as String,
      recipeId: json['recipe_id'] as String? ?? '',
      inventoryItemId: json['inventory_item_id'] as String?,
      ingredientName: json['ingredient_name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? 'kg',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isOptional: json['is_optional'] as bool? ?? false,
      notes: json['notes'] as String?,
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
      recipeId.isNotEmpty &&
      ingredientName.trim().isNotEmpty &&
      quantity >= 0 &&
      unit.trim().isNotEmpty;

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (recipeId.isEmpty) errors.add('Recipe is required');
    if (ingredientName.trim().isEmpty) errors.add('Ingredient name is required');
    if (quantity < 0) errors.add('Quantity must be non-negative');
    if (unit.trim().isEmpty) errors.add('Unit is required');
    return errors;
  }
}
