part of 'product_suggestion_bloc.dart';

abstract class ProductSuggestionState extends Equatable {
  const ProductSuggestionState();

  @override
  List<Object> get props => [];
}

class ProductSuggestionInitial extends ProductSuggestionState {}

class ProductSuggestionLoading extends ProductSuggestionState {}

class ProductSuggestionLoaded extends ProductSuggestionState {
  final String productId;
  final List<Map<String, dynamic>> suggestions;
  final List<Map<String, dynamic>> availableProducts;
  final List<Map<String, dynamic>> searchResults;

  const ProductSuggestionLoaded({
    required this.productId,
    required this.suggestions,
    required this.availableProducts,
    this.searchResults = const [],
  });

  @override
  List<Object> get props => [productId, suggestions, availableProducts, searchResults];

  ProductSuggestionLoaded copyWith({
    String? productId,
    List<Map<String, dynamic>>? suggestions,
    List<Map<String, dynamic>>? availableProducts,
    List<Map<String, dynamic>>? searchResults,
  }) {
    return ProductSuggestionLoaded(
      productId: productId ?? this.productId,
      suggestions: suggestions ?? this.suggestions,
      availableProducts: availableProducts ?? this.availableProducts,
      searchResults: searchResults ?? this.searchResults,
    );
  }

  // Helper methods to get suggestions by type
  List<Map<String, dynamic>> get frequentlyBoughtTogether =>
      suggestions.where((s) => s['suggestion_type'] == 'frequently_bought_together').toList();
      
  List<Map<String, dynamic>> get upsellItems =>
      suggestions.where((s) => s['suggestion_type'] == 'upsell').toList();
      
  List<Map<String, dynamic>> get relatedProducts =>
      suggestions.where((s) => s['suggestion_type'] == 'related').toList();
}

class ProductSuggestionError extends ProductSuggestionState {
  final String message;

  const ProductSuggestionError(this.message);

  @override
  List<Object> get props => [message];
}
