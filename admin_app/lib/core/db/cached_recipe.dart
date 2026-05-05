import 'package:isar/isar.dart';

part 'cached_recipe.g.dart';

@collection
class CachedRecipe {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String recipeId;

  late String name;
  String? category;
  late double yieldQty;
  String? yieldUnit;
  late double costPerUnit;
  late bool isActive;
  String? ingredients; // JSON
  String? instructions;
  late DateTime cachedAt;

  CachedRecipe();

  factory CachedRecipe.fromSupabase(Map<String, dynamic> row) {
    final c = CachedRecipe();
    c.recipeId = row['id']?.toString() ?? '';
    c.name = row['name']?.toString() ?? '';
    c.category = row['category']?.toString();
    c.yieldQty = (row['yield_qty'] as num?)?.toDouble() ?? 0;
    c.yieldUnit = row['yield_unit']?.toString();
    c.costPerUnit = (row['cost_per_unit'] as num?)?.toDouble() ?? 0;
    c.isActive = row['is_active'] == true || row['is_active'] == 'true';
    c.ingredients = row['ingredients'] != null ? (row['ingredients'] is String ? row['ingredients'] as String? : null) ?? row['ingredients'].toString() : null;
    c.instructions = row['instructions']?.toString();
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  Map<String, dynamic> toMap() => {
        'id': recipeId,
        'name': name,
        'category': category,
        'yield_qty': yieldQty,
        'yield_unit': yieldUnit,
        'cost_per_unit': costPerUnit,
        'is_active': isActive,
        'ingredients': ingredients,
        'instructions': instructions,
      };
}
