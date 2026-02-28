import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/audit_service.dart';
import 'package:admin_app/features/customers/models/customer_recipe.dart';

/// Result of a CSV bulk import of customer recipes.
class CsvImportResult {
  final int successCount;
  final int skipCount;
  final List<String> errors;

  const CsvImportResult({
    required this.successCount,
    required this.skipCount,
    required this.errors,
  });
}

/// Repository for the Customer Recipe Library.
/// Identity: uses [profiles] for created_by (admin users who manage content).
/// Completely separate from production RecipeRepository.
class CustomerRecipeRepository {
  final SupabaseClient _client;

  CustomerRecipeRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  // ═══════════════════════════════════════════════════════════
  // RECIPES
  // ═══════════════════════════════════════════════════════════

  /// List recipes. 
  /// [publishedOnly] = true for customer-facing (draft hidden).
  /// [publishedOnly] = false for admin view (all statuses).
  Future<List<CustomerRecipe>> getRecipes({bool publishedOnly = false}) async {
    try {
      var query = _client
          .from('customer_recipes')
          .select('''
            id, title, description, serving_size,
            prep_time_minutes, cook_time_minutes,
            status, created_by, created_at, updated_at,
            customer_recipe_images(id, image_url, sort_order, is_primary)
          ''');

      if (publishedOnly) {
        query = query.eq('status', 'published');
      }

      final response = await query.order('title');
      return (response as List<dynamic>)
          .map((r) => CustomerRecipe.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      debugPrint('CustomerRecipeRepository.getRecipes failed: $e');
      debugPrint(stack.toString());
      return [];
    }
  }

  /// Fetch a single recipe with all related data (ingredients, steps, images, categories).
  Future<CustomerRecipe?> getRecipeDetail(String recipeId) async {
    try {
      final response = await _client
          .from('customer_recipes')
          .select('''
            id, title, description, serving_size,
            prep_time_minutes, cook_time_minutes,
            status, created_by, created_at, updated_at,
            customer_recipe_ingredients(
              id, recipe_id, ingredient_text, is_optional, sort_order
            ),
            customer_recipe_steps(
              id, recipe_id, step_number, instruction_text
            ),
            customer_recipe_images(
              id, recipe_id, image_url, sort_order, is_primary, created_at
            ),
            customer_recipe_category_assignments(
              id, option_id,
              customer_recipe_category_options(
                id, type_id, name, sort_order, is_active, created_at
              )
            )
          ''')
          .eq('id', recipeId)
          .single();

      final recipe = CustomerRecipe.fromJson(response);

      // Sort ingredients and steps after parsing
      final sortedIngredients = List<CustomerRecipeIngredient>.from(
          recipe.ingredients)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final sortedSteps = List<CustomerRecipeStep>.from(recipe.steps)
        ..sort((a, b) => a.stepNumber.compareTo(b.stepNumber));
      final sortedImages = List<CustomerRecipeImage>.from(recipe.images)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      return recipe.copyWith(
        ingredients: sortedIngredients,
        steps: sortedSteps,
        images: sortedImages,
      );
    } catch (e, stack) {
      debugPrint('CustomerRecipeRepository.getRecipeDetail failed: $e');
      debugPrint(stack.toString());
      return null;
    }
  }

  /// Create a new recipe with ingredients, steps, and category assignments.
  /// Returns the created recipe id.
  Future<String> createRecipe({
    required String title,
    String? description,
    required int servingSize,
    required int prepTimeMinutes,
    required int cookTimeMinutes,
    required String status,
    required String createdBy,
    required List<String> ingredientLines,
    required List<bool> ingredientOptional,
    required List<String> stepInstructions,
    required List<String> selectedOptionIds,
  }) async {
    try {
      // 1. Insert recipe header
      final recipeResponse = await _client
          .from('customer_recipes')
          .insert({
            'title': title,
            'description': description,
            'serving_size': servingSize,
            'prep_time_minutes': prepTimeMinutes,
            'cook_time_minutes': cookTimeMinutes,
            'status': status,
            'created_by': createdBy,
          })
          .select('id')
          .single();

      final recipeId = recipeResponse['id'] as String;

      // 2. Insert ingredients
      if (ingredientLines.isNotEmpty) {
        final ingredients = <Map<String, dynamic>>[];
        for (int i = 0; i < ingredientLines.length; i++) {
          final text = ingredientLines[i].trim();
          if (text.isEmpty) continue;
          ingredients.add({
            'recipe_id': recipeId,
            'ingredient_text': text,
            'is_optional': i < ingredientOptional.length
                ? ingredientOptional[i]
                : false,
            'sort_order': i,
          });
        }
        if (ingredients.isNotEmpty) {
          await _client.from('customer_recipe_ingredients').insert(ingredients);
        }
      }

      // 3. Insert steps
      if (stepInstructions.isNotEmpty) {
        final steps = <Map<String, dynamic>>[];
        int stepNum = 1;
        for (final text in stepInstructions) {
          final trimmed = text.trim();
          if (trimmed.isEmpty) continue;
          steps.add({
            'recipe_id': recipeId,
            'step_number': stepNum++,
            'instruction_text': trimmed,
          });
        }
        if (steps.isNotEmpty) {
          await _client.from('customer_recipe_steps').insert(steps);
        }
      }

      // 4. Insert category assignments
      if (selectedOptionIds.isNotEmpty) {
        final assignments = selectedOptionIds
            .map((optId) => {
                  'recipe_id': recipeId,
                  'option_id': optId,
                })
            .toList();
        await _client
            .from('customer_recipe_category_assignments')
            .insert(assignments);
      }

      // 5. Audit
      await AuditService.log(
        action: 'CREATE',
        module: 'Customers',
        description: 'Created customer recipe: $title (status: $status)',
        entityType: 'customer_recipes',
        entityId: recipeId,
      );

      return recipeId;
    } catch (e, stack) {
      debugPrint('CustomerRecipeRepository.createRecipe failed: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  /// Bulk import recipes from CSV. Owner/manager only.
  /// Returns success count, skip count (empty title or no matching categories), and row-level errors.
  Future<CsvImportResult> importFromCsv({
    required String csvContent,
    required String importedBy,
  }) async {
    int successCount = 0;
    int skipCount = 0;
    final errors = <String>[];

    final types = await getCategoryTypes(activeOnly: false);
    final optionNameLowerToId = <String, String>{};
    for (final t in types) {
      for (final o in t.options) {
        optionNameLowerToId[o.name.trim().toLowerCase()] = o.id;
      }
    }

    List<List<dynamic>> rows;
    try {
      rows = const CsvToListConverter().convert(csvContent);
    } catch (e) {
      return CsvImportResult(
        successCount: 0,
        skipCount: 0,
        errors: ['Invalid CSV: $e'],
      );
    }
    if (rows.isEmpty) {
      return const CsvImportResult(successCount: 0, skipCount: 0, errors: []);
    }

    final header = rows[0].map((c) => (c as String?).toString().trim().toLowerCase()).toList();
    int idx(String name) {
      final i = header.indexOf(name);
      return i >= 0 ? i : -1;
    }
    final iTitle = idx('title');
    final iDesc = idx('description');
    final iServing = idx('serving_size');
    final iPrep = idx('prep_time_minutes');
    final iCook = idx('cook_time_minutes');
    final iStatus = idx('status');
    final iIngredients = idx('ingredients');
    final iSteps = idx('steps');
    final iImageUrls = idx('image_urls');
    final iCategories = idx('categories');
    if (iTitle < 0) {
      return CsvImportResult(
        successCount: 0,
        skipCount: 0,
        errors: ['CSV must have a "title" column.'],
      );
    }

    for (int r = 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.isEmpty) continue;
      String cell(int i) => (i >= 0 && i < row.length) ? (row[i] as String?).toString().trim() : '';

      final title = cell(iTitle);
      if (title.isEmpty) {
        skipCount++;
        continue;
      }

      final categoryNames = (iCategories >= 0 ? cell(iCategories) : '').split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      final selectedOptionIds = <String>[];
      for (final name in categoryNames) {
        final id = optionNameLowerToId[name.toLowerCase()];
        if (id != null) selectedOptionIds.add(id);
      }

      try {
        final servingSize = int.tryParse(iServing >= 0 ? cell(iServing) : '') ?? 4;
        final prepTime = int.tryParse(iPrep >= 0 ? cell(iPrep) : '') ?? 0;
        final cookTime = int.tryParse(iCook >= 0 ? cell(iCook) : '') ?? 0;
        var status = (iStatus >= 0 ? cell(iStatus) : '').toLowerCase();
        if (status != 'published' && status != 'draft') status = 'draft';

        final ingredientStr = iIngredients >= 0 ? cell(iIngredients) : '';
        final ingredientLines = <String>[];
        final ingredientOptional = <bool>[];
        for (final part in ingredientStr.split('|')) {
          final t = part.trim();
          if (t.isEmpty) continue;
          final optional = t.toLowerCase().endsWith('(optional)');
          final text = optional ? t.substring(0, t.length - '(optional)'.length).trim() : t;
          ingredientLines.add(text);
          ingredientOptional.add(optional);
        }

        final stepStr = iSteps >= 0 ? cell(iSteps) : '';
        final stepInstructions = stepStr.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

        final recipeId = await createRecipe(
          title: title,
          description: iDesc >= 0 ? cell(iDesc) : null,
          servingSize: servingSize,
          prepTimeMinutes: prepTime,
          cookTimeMinutes: cookTime,
          status: status,
          createdBy: importedBy,
          ingredientLines: ingredientLines,
          ingredientOptional: ingredientOptional,
          stepInstructions: stepInstructions,
          selectedOptionIds: selectedOptionIds,
        );

        final urlsStr = iImageUrls >= 0 ? cell(iImageUrls) : '';
        final urls = urlsStr.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        for (int i = 0; i < urls.length; i++) {
          await _client.from('customer_recipe_images').insert({
            'recipe_id': recipeId,
            'image_url': urls[i],
            'sort_order': i,
            'is_primary': i == 0,
          });
        }
        successCount++;
      } catch (e) {
        errors.add('Row ${r + 1} ("$title"): $e');
      }
    }

    return CsvImportResult(
      successCount: successCount,
      skipCount: skipCount,
      errors: errors,
    );
  }

  /// Update recipe header + replace ingredients, steps, and category assignments.
  Future<void> updateRecipe({
    required String recipeId,
    required String title,
    String? description,
    required int servingSize,
    required int prepTimeMinutes,
    required int cookTimeMinutes,
    required String status,
    required String updatedBy,
    required List<String> ingredientLines,
    required List<bool> ingredientOptional,
    required List<String> stepInstructions,
    required List<String> selectedOptionIds,
  }) async {
    try {
      // 1. Update recipe header
      await _client.from('customer_recipes').update({
        'title': title,
        'description': description,
        'serving_size': servingSize,
        'prep_time_minutes': prepTimeMinutes,
        'cook_time_minutes': cookTimeMinutes,
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', recipeId);

      // 2. Replace ingredients (delete + re-insert)
      await _client
          .from('customer_recipe_ingredients')
          .delete()
          .eq('recipe_id', recipeId);

      if (ingredientLines.isNotEmpty) {
        final ingredients = <Map<String, dynamic>>[];
        for (int i = 0; i < ingredientLines.length; i++) {
          final text = ingredientLines[i].trim();
          if (text.isEmpty) continue;
          ingredients.add({
            'recipe_id': recipeId,
            'ingredient_text': text,
            'is_optional': i < ingredientOptional.length
                ? ingredientOptional[i]
                : false,
            'sort_order': i,
          });
        }
        if (ingredients.isNotEmpty) {
          await _client.from('customer_recipe_ingredients').insert(ingredients);
        }
      }

      // 3. Replace steps (delete + re-insert)
      await _client
          .from('customer_recipe_steps')
          .delete()
          .eq('recipe_id', recipeId);

      if (stepInstructions.isNotEmpty) {
        final steps = <Map<String, dynamic>>[];
        int stepNum = 1;
        for (final text in stepInstructions) {
          final trimmed = text.trim();
          if (trimmed.isEmpty) continue;
          steps.add({
            'recipe_id': recipeId,
            'step_number': stepNum++,
            'instruction_text': trimmed,
          });
        }
        if (steps.isNotEmpty) {
          await _client.from('customer_recipe_steps').insert(steps);
        }
      }

      // 4. Replace category assignments (delete + re-insert)
      await _client
          .from('customer_recipe_category_assignments')
          .delete()
          .eq('recipe_id', recipeId);

      if (selectedOptionIds.isNotEmpty) {
        final assignments = selectedOptionIds
            .map((optId) => {
                  'recipe_id': recipeId,
                  'option_id': optId,
                })
            .toList();
        await _client
            .from('customer_recipe_category_assignments')
            .insert(assignments);
      }

      // 5. Audit
      await AuditService.log(
        action: 'UPDATE',
        module: 'Customers',
        description: 'Updated customer recipe: $title (status: $status)',
        entityType: 'customer_recipes',
        entityId: recipeId,
      );
    } catch (e, stack) {
      debugPrint('CustomerRecipeRepository.updateRecipe failed: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  /// Toggle status between draft and published.
  Future<void> setRecipeStatus({
    required String recipeId,
    required String status,
    required String updatedBy,
    required String title,
  }) async {
    try {
      await _client.from('customer_recipes').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', recipeId);

      await AuditService.log(
        action: 'UPDATE',
        module: 'Customers',
        description: 'Recipe "$title" status set to $status',
        entityType: 'customer_recipes',
        entityId: recipeId,
      );
    } catch (e, stack) {
      debugPrint('CustomerRecipeRepository.setRecipeStatus failed: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  /// Hard delete a recipe. Cascades to ingredients, steps, images, assignments.
  Future<void> deleteRecipe({
    required String recipeId,
    required String deletedBy,
    required String title,
  }) async {
    try {
      // Images: delete from storage first
      final images = await _client
          .from('customer_recipe_images')
          .select('image_url')
          .eq('recipe_id', recipeId);

      for (final img in images as List<dynamic>) {
        final url = img['image_url'] as String?;
        if (url != null && url.isNotEmpty) {
          try {
            final path = _storagePathFromUrl(url);
            if (path != null) {
              await _client.storage.from('recipe-images').remove([path]);
            }
          } catch (imgErr) {
            debugPrint('Image delete warning (non-fatal): $imgErr');
          }
        }
      }

      // Delete recipe row — cascades to all child tables
      await _client.from('customer_recipes').delete().eq('id', recipeId);

      await AuditService.log(
        action: 'DELETE',
        module: 'Customers',
        description: 'Deleted customer recipe: $title',
        entityType: 'customer_recipes',
        entityId: recipeId,
      );
    } catch (e, stack) {
      debugPrint('CustomerRecipeRepository.deleteRecipe failed: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // IMAGES
  // ═══════════════════════════════════════════════════════════

  /// Upload an image file to Supabase Storage and insert the row.
  /// Returns the public URL.
  Future<String> uploadRecipeImage({
    required String recipeId,
    required File imageFile,
    required bool isPrimary,
    required int sortOrder,
  }) async {
    try {
      final ext = imageFile.path.split('.').last.toLowerCase();
      final fileName =
          '${recipeId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final storagePath = 'recipes/$fileName';

      await _client.storage.from('recipe-images').upload(
            storagePath,
            imageFile,
            fileOptions: const FileOptions(upsert: false),
          );

      final publicUrl = _client.storage
          .from('recipe-images')
          .getPublicUrl(storagePath);

      // If this is primary, clear existing primary flag first
      if (isPrimary) {
        await _client
            .from('customer_recipe_images')
            .update({'is_primary': false}).eq('recipe_id', recipeId);
      }

      await _client.from('customer_recipe_images').insert({
        'recipe_id': recipeId,
        'image_url': publicUrl,
        'sort_order': sortOrder,
        'is_primary': isPrimary,
      });

      return publicUrl;
    } catch (e, stack) {
      debugPrint('CustomerRecipeRepository.uploadRecipeImage failed: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  /// Delete a single image from storage and remove its row.
  Future<void> deleteRecipeImage({
    required String imageId,
    required String imageUrl,
  }) async {
    try {
      final path = _storagePathFromUrl(imageUrl);
      if (path != null) {
        await _client.storage.from('recipe-images').remove([path]);
      }
      await _client
          .from('customer_recipe_images')
          .delete()
          .eq('id', imageId);
    } catch (e, stack) {
      debugPrint('CustomerRecipeRepository.deleteRecipeImage failed: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  /// Set a specific image as primary.
  Future<void> setPrimaryImage({
    required String recipeId,
    required String imageId,
  }) async {
    try {
      await _client
          .from('customer_recipe_images')
          .update({'is_primary': false}).eq('recipe_id', recipeId);
      await _client
          .from('customer_recipe_images')
          .update({'is_primary': true}).eq('id', imageId);
    } catch (e, stack) {
      debugPrint('CustomerRecipeRepository.setPrimaryImage failed: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CATEGORY TYPES
  // ═══════════════════════════════════════════════════════════

  /// Fetch all category types with their options nested.
  Future<List<CustomerRecipeCategoryType>> getCategoryTypes({
    bool activeOnly = false,
  }) async {
    try {
      var query = _client.from('customer_recipe_category_types').select('''
            id, name, sort_order, is_active, created_at, updated_at,
            options:customer_recipe_category_options(
              id, type_id, name, sort_order, is_active, created_at
            )
          ''');

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('sort_order');

      return (response as List<dynamic>).map((t) {
        final map = t as Map<String, dynamic>;
        // Rename nested key to match fromJson expectation
        return CustomerRecipeCategoryType.fromJson({
          ...map,
          'options': (map['options'] as List<dynamic>?)
                  ?.where((o) => !activeOnly || o['is_active'] == true)
                  .toList() ??
              [],
        });
      }).toList();
    } catch (e, stack) {
      debugPrint('CustomerRecipeRepository.getCategoryTypes failed: $e');
      debugPrint(stack.toString());
      return [];
    }
  }

  Future<void> createCategoryType({
    required String name,
    required int sortOrder,
  }) async {
    try {
      await _client.from('customer_recipe_category_types').insert({
        'name': name.trim(),
        'sort_order': sortOrder,
        'is_active': true,
      });
    } catch (e, stack) {
      debugPrint('CustomerRecipeRepository.createCategoryType failed: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  Future<void> updateCategoryType({
    required String typeId,
    required String name,
    required int sortOrder,
    required bool isActive,
  }) async {
    try {
      await _client.from('customer_recipe_category_types').update({
        'name': name.trim(),
        'sort_order': sortOrder,
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', typeId);
    } catch (e, stack) {
      debugPrint('CustomerRecipeRepository.updateCategoryType failed: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  /// Delete a category type. Will cascade-delete all options under it.
  /// Assignments referencing those options are also cascade-deleted.
  Future<void> deleteCategoryType(String typeId) async {
    try {
      await _client
          .from('customer_recipe_category_types')
          .delete()
          .eq('id', typeId);
    } catch (e, stack) {
      debugPrint('CustomerRecipeRepository.deleteCategoryType failed: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CATEGORY OPTIONS
  // ═══════════════════════════════════════════════════════════

  Future<void> createCategoryOption({
    required String typeId,
    required String name,
    required int sortOrder,
  }) async {
    try {
      await _client.from('customer_recipe_category_options').insert({
        'type_id': typeId,
        'name': name.trim(),
        'sort_order': sortOrder,
        'is_active': true,
      });
    } catch (e, stack) {
      debugPrint('CustomerRecipeRepository.createCategoryOption failed: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  Future<void> updateCategoryOption({
    required String optionId,
    required String name,
    required int sortOrder,
    required bool isActive,
  }) async {
    try {
      await _client.from('customer_recipe_category_options').update({
        'name': name.trim(),
        'sort_order': sortOrder,
        'is_active': isActive,
      }).eq('id', optionId);
    } catch (e, stack) {
      debugPrint('CustomerRecipeRepository.updateCategoryOption failed: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  /// Delete a category option. Cascade removes all assignments using it.
  Future<void> deleteCategoryOption(String optionId) async {
    try {
      await _client
          .from('customer_recipe_category_options')
          .delete()
          .eq('id', optionId);
    } catch (e, stack) {
      debugPrint('CustomerRecipeRepository.deleteCategoryOption failed: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════

  /// Extract Supabase Storage path from a public URL.
  /// e.g. https://xxx.supabase.co/storage/v1/object/public/recipe-images/recipes/abc.jpg
  /// → recipes/abc.jpg
  String? _storagePathFromUrl(String url) {
    try {
      const marker = '/recipe-images/';
      final idx = url.indexOf(marker);
      if (idx == -1) return null;
      return url.substring(idx + marker.length);
    } catch (_) {
      return null;
    }
  }
}