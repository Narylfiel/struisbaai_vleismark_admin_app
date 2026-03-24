part of 'product_suggestion_bloc.dart';

abstract class ProductSuggestionEvent extends Equatable {
  const ProductSuggestionEvent();

  @override
  List<Object> get props => [];
}

class LoadSuggestions extends ProductSuggestionEvent {
  final String productId;

  const LoadSuggestions(this.productId);

  @override
  List<Object> get props => [productId];
}

class AddSuggestion extends ProductSuggestionEvent {
  final String sourceProductId;
  final String suggestedProductId;
  final String suggestionType;
  final String performedBy;

  const AddSuggestion({
    required this.sourceProductId,
    required this.suggestedProductId,
    required this.suggestionType,
    required this.performedBy,
  });

  @override
  List<Object> get props => [sourceProductId, suggestedProductId, suggestionType, performedBy];
}

class RemoveSuggestion extends ProductSuggestionEvent {
  final String suggestionId;
  final String performedBy;

  const RemoveSuggestion({
    required this.suggestionId,
    required this.performedBy,
  });

  @override
  List<Object> get props => [suggestionId, performedBy];
}

class ReorderSuggestions extends ProductSuggestionEvent {
  final List<Map<String, dynamic>> updatedOrders;
  final String performedBy;

  const ReorderSuggestions({
    required this.updatedOrders,
    required this.performedBy,
  });

  @override
  List<Object> get props => [updatedOrders, performedBy];
}

class SearchProducts extends ProductSuggestionEvent {
  final String query;
  final String excludeProductId;

  const SearchProducts({
    required this.query,
    required this.excludeProductId,
  });

  @override
  List<Object> get props => [query, excludeProductId];
}

class LoadAvailableProducts extends ProductSuggestionEvent {
  final String excludeProductId;

  const LoadAvailableProducts(this.excludeProductId);

  @override
  List<Object> get props => [excludeProductId];
}

class BulkAddSuggestions extends ProductSuggestionEvent {
  final String sourceProductId;
  final List<String> productIds;
  final String suggestionType;
  final String performedBy;

  const BulkAddSuggestions({
    required this.sourceProductId,
    required this.productIds,
    required this.suggestionType,
    required this.performedBy,
  });

  @override
  List<Object> get props => [sourceProductId, productIds, suggestionType, performedBy];
}

class ToggleSuggestionStatus extends ProductSuggestionEvent {
  final String suggestionId;
  final bool isActive;
  final String performedBy;

  const ToggleSuggestionStatus({
    required this.suggestionId,
    required this.isActive,
    required this.performedBy,
  });

  @override
  List<Object> get props => [suggestionId, isActive, performedBy];
}

class MoveSuggestionToTop extends ProductSuggestionEvent {
  final String suggestionId;
  final String performedBy;

  const MoveSuggestionToTop({
    required this.suggestionId,
    required this.performedBy,
  });

  @override
  List<Object> get props => [suggestionId, performedBy];
}

class MoveSuggestionToBottom extends ProductSuggestionEvent {
  final String suggestionId;
  final String performedBy;

  const MoveSuggestionToBottom({
    required this.suggestionId,
    required this.performedBy,
  });

  @override
  List<Object> get props => [suggestionId, performedBy];
}
