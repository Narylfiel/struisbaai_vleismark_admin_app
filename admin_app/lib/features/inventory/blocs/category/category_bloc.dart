import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/supabase_service.dart';
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

      final response = await _supabaseService.client
          .from('categories')
          .select()
          .order('sort_order', ascending: true);

      final categories = (response as List)
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();

      emit(CategoryLoaded(categories));
    } catch (e) {
      emit(CategoryError('Failed to load categories: ${e.toString()}'));
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

      await _supabaseService.client
          .from('categories')
          .insert(categoryData);

      emit(const CategoryOperationSuccess('Category created successfully'));
      add(const LoadCategories());
    } catch (e) {
      emit(CategoryError('Failed to create category: ${e.toString()}'));
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

      await _supabaseService.client
          .from('categories')
          .update(categoryData)
          .eq('id', event.category.id);

      emit(const CategoryOperationSuccess('Category updated successfully'));
      add(const LoadCategories());
    } catch (e) {
      emit(CategoryError('Failed to update category: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteCategory(
    DeleteCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await _supabaseService.client
          .from('categories')
          .delete()
          .eq('id', event.id);

      emit(const CategoryOperationSuccess('Category deleted successfully'));
      add(const LoadCategories());
    } catch (e) {
      emit(CategoryError('Failed to delete category: ${e.toString()}'));
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
        await _supabaseService.client
            .from('categories')
            .update({'sort_order': i + 1})
            .eq('id', category.id);
      }

      emit(const CategoryOperationSuccess('Categories reordered successfully'));
      add(const LoadCategories());
    } catch (e) {
      emit(CategoryError('Failed to reorder categories: ${e.toString()}'));
    }
  }
}