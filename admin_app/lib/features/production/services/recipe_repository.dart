import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';

/// Blueprint §5.5: Recipes and recipe ingredients. CRUD only.
class RecipeRepository {
  final SupabaseClient _client;

  RecipeRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  Future<List<Recipe>> getRecipes({bool activeOnly = false}) async {
    var q = _client.from('recipes').select();
    if (activeOnly) {
      q = q.eq('is_active', true);
    }
    final list = await q.order('name');
    return (list as List)
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Recipe?> getRecipe(String id) async {
    final row = await _client
        .from('recipes')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return Recipe.fromJson(row as Map<String, dynamic>);
  }

  Future<Recipe> createRecipe(Recipe recipe) async {
    final data = Map<String, dynamic>.from(recipe.toJson())
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');
    final response = await _client
        .from('recipes')
        .insert(data)
        .select()
        .single();
    return Recipe.fromJson(response as Map<String, dynamic>);
  }

  Future<Recipe> updateRecipe(Recipe recipe) async {
    final data = Map<String, dynamic>.from(recipe.toJson())
      ..remove('id')
      ..remove('created_at');
    final response = await _client
        .from('recipes')
        .update(data)
        .eq('id', recipe.id)
        .select()
        .single();
    return Recipe.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteRecipe(String id) async {
    // 1. Find all recipe_ingredient ids
    final ingRows = await _client
        .from('recipe_ingredients')
        .select('id')
        .eq('recipe_id', id);
    final ingIds = (ingRows as List)
        .map((r) => r['id'] as String)
        .toList();

    // 2. Delete production_batch_ingredients referencing these ingredient ids
    if (ingIds.isNotEmpty) {
      await _client
          .from('production_batch_ingredients')
          .delete()
          .inFilter('ingredient_id', ingIds);
    }

    // 3. Null out recipe_id on dryer_batches (preserve dryer history)
    await _client
        .from('dryer_batches')
        .update({'recipe_id': null})
        .eq('recipe_id', id);

    // 4. Null out recipe_id on production_batches (preserve batch history)
    await _client
        .from('production_batches')
        .update({'recipe_id': null})
        .eq('recipe_id', id);

    // 5. Delete recipe_ingredients
    await _client
        .from('recipe_ingredients')
        .delete()
        .eq('recipe_id', id);

    // 6. Delete recipe
    await _client
        .from('recipes')
        .delete()
        .eq('id', id);
  }

  Future<List<RecipeIngredient>> getIngredientsByRecipe(String recipeId) async {
    final list = await _client
        .from('recipe_ingredients')
        .select()
        .eq('recipe_id', recipeId)
        .order('sort_order')
        .order('ingredient_name');
    return (list as List)
        .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RecipeIngredient?> getIngredient(String id) async {
    final row = await _client
        .from('recipe_ingredients')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return RecipeIngredient.fromJson(row as Map<String, dynamic>);
  }

  Future<RecipeIngredient> createIngredient(RecipeIngredient ingredient) async {
    final data = Map<String, dynamic>.from(ingredient.toJson())
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');
    final response = await _client
        .from('recipe_ingredients')
        .insert(data)
        .select()
        .single();
    return RecipeIngredient.fromJson(response as Map<String, dynamic>);
  }

  Future<RecipeIngredient> updateIngredient(RecipeIngredient ingredient) async {
    final data = Map<String, dynamic>.from(ingredient.toJson())
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');
    final response = await _client
        .from('recipe_ingredients')
        .update(data)
        .eq('id', ingredient.id)
        .select()
        .single();
    return RecipeIngredient.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteIngredient(String id) async {
    await _client.from('recipe_ingredients').delete().eq('id', id);
  }
}
