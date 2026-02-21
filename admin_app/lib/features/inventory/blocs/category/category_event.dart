import 'package:equatable/equatable.dart';
import '../../models/category.dart';

/// Base class for all category events
abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all categories
class LoadCategories extends CategoryEvent {
  const LoadCategories();
}

/// Event to create a new category
class CreateCategory extends CategoryEvent {
  final Category category;

  const CreateCategory(this.category);

  @override
  List<Object?> get props => [category];
}

/// Event to update an existing category
class UpdateCategory extends CategoryEvent {
  final Category category;

  const UpdateCategory(this.category);

  @override
  List<Object?> get props => [category];
}

/// Event to delete a category
class DeleteCategory extends CategoryEvent {
  final String categoryId;

  const DeleteCategory(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

/// Event to reorder categories
class ReorderCategories extends CategoryEvent {
  final List<Category> categories;

  const ReorderCategories(this.categories);

  @override
  List<Object?> get props => [categories];
}