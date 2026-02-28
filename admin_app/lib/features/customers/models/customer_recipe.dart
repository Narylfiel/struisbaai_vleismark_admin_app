/// Models for the Customer Recipe Library feature.
/// These are meal/cooking recipes for the customer loyalty app.
/// Completely separate from [Recipe] in features/production/.

// ─────────────────────────────────────────────
// Category Type (e.g. "Meal Type", "Cuisine")
// ─────────────────────────────────────────────
class CustomerRecipeCategoryType {
  final String id;
  final String name;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Loaded separately — options under this type
  final List<CustomerRecipeCategoryOption> options;

  const CustomerRecipeCategoryType({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.options = const [],
  });

  factory CustomerRecipeCategoryType.fromJson(Map<String, dynamic> json) {
    return CustomerRecipeCategoryType(
      id: json['id'] as String,
      name: json['name'] as String,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      options: (json['options'] as List<dynamic>?)
              ?.map((o) => CustomerRecipeCategoryOption.fromJson(
                  o as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'sort_order': sortOrder,
        'is_active': isActive,
      };

  CustomerRecipeCategoryType copyWith({
    String? name,
    int? sortOrder,
    bool? isActive,
    List<CustomerRecipeCategoryOption>? options,
  }) {
    return CustomerRecipeCategoryType(
      id: id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      options: options ?? this.options,
    );
  }
}

// ─────────────────────────────────────────────
// Category Option (e.g. "Beef" under "Meat Type")
// ─────────────────────────────────────────────
class CustomerRecipeCategoryOption {
  final String id;
  final String typeId;
  final String name;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;

  const CustomerRecipeCategoryOption({
    required this.id,
    required this.typeId,
    required this.name,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
  });

  factory CustomerRecipeCategoryOption.fromJson(Map<String, dynamic> json) {
    return CustomerRecipeCategoryOption(
      id: json['id'] as String,
      typeId: json['type_id'] as String,
      name: json['name'] as String,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'type_id': typeId,
        'name': name,
        'sort_order': sortOrder,
        'is_active': isActive,
      };
}

// ─────────────────────────────────────────────
// Ingredient row (freetext)
// ─────────────────────────────────────────────
class CustomerRecipeIngredient {
  final String id;
  final String recipeId;
  final String ingredientText;
  final bool isOptional;
  final int sortOrder;

  const CustomerRecipeIngredient({
    required this.id,
    required this.recipeId,
    required this.ingredientText,
    required this.isOptional,
    required this.sortOrder,
  });

  factory CustomerRecipeIngredient.fromJson(Map<String, dynamic> json) {
    return CustomerRecipeIngredient(
      id: json['id'] as String,
      recipeId: json['recipe_id'] as String,
      ingredientText: json['ingredient_text'] as String,
      isOptional: json['is_optional'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'recipe_id': recipeId,
        'ingredient_text': ingredientText,
        'is_optional': isOptional,
        'sort_order': sortOrder,
      };
}

// ─────────────────────────────────────────────
// Step row (numbered instruction)
// ─────────────────────────────────────────────
class CustomerRecipeStep {
  final String id;
  final String recipeId;
  final int stepNumber;
  final String instructionText;

  const CustomerRecipeStep({
    required this.id,
    required this.recipeId,
    required this.stepNumber,
    required this.instructionText,
  });

  factory CustomerRecipeStep.fromJson(Map<String, dynamic> json) {
    return CustomerRecipeStep(
      id: json['id'] as String,
      recipeId: json['recipe_id'] as String,
      stepNumber: (json['step_number'] as num).toInt(),
      instructionText: json['instruction_text'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'recipe_id': recipeId,
        'step_number': stepNumber,
        'instruction_text': instructionText,
      };
}

// ─────────────────────────────────────────────
// Image row
// ─────────────────────────────────────────────
class CustomerRecipeImage {
  final String id;
  final String recipeId;
  final String imageUrl;
  final int sortOrder;
  final bool isPrimary;
  final DateTime createdAt;

  const CustomerRecipeImage({
    required this.id,
    required this.recipeId,
    required this.imageUrl,
    required this.sortOrder,
    required this.isPrimary,
    required this.createdAt,
  });

  factory CustomerRecipeImage.fromJson(Map<String, dynamic> json) {
    return CustomerRecipeImage(
      id: json['id'] as String,
      recipeId: json['recipe_id'] as String,
      imageUrl: json['image_url'] as String,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isPrimary: json['is_primary'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'recipe_id': recipeId,
        'image_url': imageUrl,
        'sort_order': sortOrder,
        'is_primary': isPrimary,
      };
}

// ─────────────────────────────────────────────
// Main CustomerRecipe model
// ─────────────────────────────────────────────
class CustomerRecipe {
  final String id;
  final String title;
  final String? description;
  final int servingSize;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final String status; // 'draft' | 'published'
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Loaded with full detail fetch
  final List<CustomerRecipeIngredient> ingredients;
  final List<CustomerRecipeStep> steps;
  final List<CustomerRecipeImage> images;
  final List<CustomerRecipeCategoryOption> categoryAssignments;

  const CustomerRecipe({
    required this.id,
    required this.title,
    this.description,
    required this.servingSize,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.status,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.ingredients = const [],
    this.steps = const [],
    this.images = const [],
    this.categoryAssignments = const [],
  });

  bool get isPublished => status == 'published';
  bool get isDraft => status == 'draft';

  /// Primary image URL or null
  String? get primaryImageUrl {
    if (images.isEmpty) return null;
    final primary = images.where((i) => i.isPrimary).toList();
    if (primary.isNotEmpty) return primary.first.imageUrl;
    return images.first.imageUrl;
  }

  /// All assigned option IDs (for pre-selecting in form)
  List<String> get assignedOptionIds =>
      categoryAssignments.map((a) => a.id).toList();

  factory CustomerRecipe.fromJson(Map<String, dynamic> json) {
    return CustomerRecipe(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      servingSize: (json['serving_size'] as num?)?.toInt() ?? 4,
      prepTimeMinutes: (json['prep_time_minutes'] as num?)?.toInt() ?? 0,
      cookTimeMinutes: (json['cook_time_minutes'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'draft',
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      ingredients: (json['customer_recipe_ingredients'] as List<dynamic>?)
              ?.map((i) => CustomerRecipeIngredient.fromJson(
                  i as Map<String, dynamic>))
              .toList() ??
          [],
      steps: (json['customer_recipe_steps'] as List<dynamic>?)
              ?.map((s) =>
                  CustomerRecipeStep.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      images: (json['customer_recipe_images'] as List<dynamic>?)
              ?.map((img) =>
                  CustomerRecipeImage.fromJson(img as Map<String, dynamic>))
              .toList() ??
          [],
      categoryAssignments:
          (json['customer_recipe_category_assignments'] as List<dynamic>?)
                  ?.map((a) {
                    final opt = a['customer_recipe_category_options'];
                    if (opt == null) return null;
                    return CustomerRecipeCategoryOption.fromJson(
                        opt as Map<String, dynamic>);
                  })
                  .whereType<CustomerRecipeCategoryOption>()
                  .toList() ??
              [],
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'serving_size': servingSize,
        'prep_time_minutes': prepTimeMinutes,
        'cook_time_minutes': cookTimeMinutes,
        'status': status,
        'created_by': createdBy,
      };

  CustomerRecipe copyWith({
    String? title,
    String? description,
    int? servingSize,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    String? status,
    List<CustomerRecipeIngredient>? ingredients,
    List<CustomerRecipeStep>? steps,
    List<CustomerRecipeImage>? images,
    List<CustomerRecipeCategoryOption>? categoryAssignments,
  }) {
    return CustomerRecipe(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      servingSize: servingSize ?? this.servingSize,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      status: status ?? this.status,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      images: images ?? this.images,
      categoryAssignments: categoryAssignments ?? this.categoryAssignments,
    );
  }
}