import '../../../core/models/base_model.dart';

/// Blueprint §5.5: Recipe — Output Product, Expected Yield %, ingredients per batch size.
/// DB columns: id, name, category, ingredients (jsonb), instructions, yield_qty, yield_unit,
/// cost_per_unit, is_active, created_at, updated_at, output_product_id, expected_yield_pct,
/// batch_size_kg, cook_time_minutes, created_by.
class Recipe extends BaseModel {
  final String name;
  /// DB column: instructions (description content maps here).
  final String? instructions;
  final String? category;
  final int servings;
  final int? prepTimeMinutes;
  final int? cookTimeMinutes;
  final String? difficulty;
  final bool isActive;
  /// Blueprint: Output Product (e.g. Boerewors Traditional)
  final String? outputProductId;
  /// Blueprint: Expected Yield % (e.g. 95 = 5% loss)
  final double expectedYieldPct;
  /// Blueprint: Ingredient quantities are per this batch size (e.g. 10 kg)
  final double batchSizeKg;
  final String? createdBy;

  const Recipe({
    required super.id,
    required this.name,
    this.instructions,
    this.category,
    this.servings = 1,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    this.difficulty,
    this.isActive = true,
    this.outputProductId,
    this.expectedYieldPct = 100,
    this.batchSizeKg = 1,
    this.createdBy,
    super.createdAt,
    super.updatedAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'instructions': instructions,
      'category': category,
      'cook_time_minutes': cookTimeMinutes,
      'is_active': isActive,
      'output_product_id': outputProductId,
      'expected_yield_pct': expectedYieldPct,
      'batch_size_kg': batchSizeKg,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      instructions: json['instructions'] as String? ?? json['description'] as String?,
      category: json['category'] as String?,
      servings: (json['servings'] as num?)?.toInt() ?? 1,
      prepTimeMinutes: (json['prep_time_minutes'] as num?)?.toInt(),
      cookTimeMinutes: (json['cook_time_minutes'] as num?)?.toInt(),
      difficulty: json['difficulty'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      outputProductId: json['output_product_id'] as String?,
      expectedYieldPct: (json['expected_yield_pct'] as num?)?.toDouble() ?? 100,
      batchSizeKg: (json['batch_size_kg'] as num?)?.toDouble() ?? 1,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  bool validate() => name.trim().isNotEmpty;

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (name.trim().isEmpty) errors.add('Recipe name is required');
    if (expectedYieldPct <= 0 || expectedYieldPct > 100) {
      errors.add('Expected yield % must be between 0 and 100');
    }
    if (batchSizeKg <= 0) errors.add('Batch size must be positive');
    return errors;
  }
}
