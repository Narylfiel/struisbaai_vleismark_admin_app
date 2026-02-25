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

  /// Soft delete: set is_active = false (recipes table has is_active).
  Future<void> deleteRecipe(String id) async {
    await _client.from('recipes').update({'is_active': false}).eq('id', id);
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
