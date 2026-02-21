import 'package:equatable/equatable.dart';
import '../../models/category.dart';

/// Base class for all category states
abstract class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

/// State when categories are being loaded
class CategoryLoading extends CategoryState {
  const CategoryLoading();
}

/// State when categories are successfully loaded
class CategoryLoaded extends CategoryState {
  final List<Category> categories;

  const CategoryLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

/// State when an error occurs
class CategoryError extends CategoryState {
  final String message;

  const CategoryError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State when a category operation is successful
class CategoryOperationSuccess extends CategoryState {
  final String message;

  const CategoryOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}