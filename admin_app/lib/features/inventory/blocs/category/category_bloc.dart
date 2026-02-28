import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/error_handler.dart';
import '../../models/category.dart';
import 'category_event.dart';
import 'category_state.dart';

/// BLoC for managing category operations
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final SupabaseService _supabaseService;

  CategoryBloc(this._supabaseService) : super(const CategoryLoading()) {
    on<LoadCategories>(_onLoadCategories);
    on<CreateCategory>(_onCreateCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);
    on<ReorderCategories>(_onReorderCategories);
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      emit(const CategoryLoading());

      // Only active categories (column is 'active'); after soft delete, LoadCategories() refreshes and deleted item disappears.
      final response = await SupabaseService.client
          .from('categories')
          .select()
          .eq('active', true)
          .order('parent_id', ascending: true)
          .order('sort_order', ascending: true)
          .order('name');

      final categories = (response as List)
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();

      emit(CategoryLoaded(categories));
    } catch (e) {
      emit(CategoryError(ErrorHandler.friendlyMessage(e)));
    }
  }

  Future<void> _onCreateCategory(
    CreateCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      final categoryData = event.category.toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('updated_at');

      await SupabaseService.client
          .from('categories')
          .insert(categoryData);

      emit(const CategoryOperationSuccess('Category created successfully'));
      add(const LoadCategories());
    } catch (e) {
      emit(CategoryError(ErrorHandler.friendlyMessage(e)));
    }
  }

  Future<void> _onUpdateCategory(
    UpdateCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      final categoryData = event.category.toJson()
        ..remove('created_at')
        ..remove('updated_at');

      await SupabaseService.client
          .from('categories')
          .update(categoryData)
          .eq('id', event.category.id);

      emit(const CategoryOperationSuccess('Category updated successfully'));
      add(const LoadCategories());
    } catch (e) {
      emit(CategoryError(ErrorHandler.friendlyMessage(e)));
    }
  }

  Future<void> _onDeleteCategory(
    DeleteCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      // Cannot delete if any products use this category
      final list = await SupabaseService.client
          .from('inventory_items')
          .select('id')
          .eq('category_id', event.categoryId);
      final count = (list as List).length;
      if (count > 0) {
        emit(CategoryError('Cannot delete — $count products use this category'));
        return;
      }
      // Soft delete: set active = false (categories table uses 'active' column)
      await SupabaseService.client
          .from('categories')
          .update({'active': false})
          .eq('id', event.categoryId);

      emit(const CategoryOperationSuccess('Deleted'));
      add(const LoadCategories());
    } catch (e) {
      emit(CategoryError(ErrorHandler.friendlyMessage(e)));
    }
  }

  Future<void> _onReorderCategories(
    ReorderCategories event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      // Update sort orders in batch
      for (int i = 0; i < event.categories.length; i++) {
        final category = event.categories[i];
        await SupabaseService.client
            .from('categories')
            .update({'sort_order': i + 1})
            .eq('id', category.id);
      }

      emit(const CategoryOperationSuccess('Categories reordered successfully'));
      add(const LoadCategories());
    } catch (e) {
      emit(CategoryError(ErrorHandler.friendlyMessage(e)));
    }
  }
}