import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/product_suggestion_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/error_handler.dart';

part 'product_suggestion_event.dart';
part 'product_suggestion_state.dart';

/// BLoC for managing product suggestions in the admin app
/// Follows existing admin app patterns with proper error handling and state management
class ProductSuggestionBloc extends Bloc<ProductSuggestionEvent, ProductSuggestionState> {
  final ProductSuggestionService _service;
  final AuthService _authService;

  ProductSuggestionBloc({
    ProductSuggestionService? service,
    AuthService? authService,
  })  : _service = service ?? ProductSuggestionService(),
        _authService = authService ?? AuthService(),
        super(const ProductSuggestionInitial()) {
    on<LoadSuggestions>(_onLoadSuggestions);
    on<AddSuggestion>(_onAddSuggestion);
    on<RemoveSuggestion>(_onRemoveSuggestion);
    on<ReorderSuggestions>(_onReorderSuggestions);
    on<SearchProducts>(_onSearchProducts);
    on<LoadAvailableProducts>(_onLoadAvailableProducts);
    on<BulkAddSuggestions>(_onBulkAddSuggestions);
    on<ToggleSuggestionStatus>(_onToggleSuggestionStatus);
    on<MoveSuggestionToTop>(_onMoveSuggestionToTop);
    on<MoveSuggestionToBottom>(_onMoveSuggestionToBottom);
  }

  Future<void> _onLoadSuggestions(
    LoadSuggestions event,
    Emitter<ProductSuggestionState> emit,
  ) async {
    try {
      emit(const ProductSuggestionLoading());
      
      final performedBy = _authService.currentUser?.id ?? '';
      if (performedBy.isEmpty) {
        emit(const ProductSuggestionError('User not authenticated'));
        return;
      }

      final suggestions = await _service.getSuggestionsForProduct(event.productId);
      final availableProducts = await _service.getAvailableProducts(event.productId);

      emit(ProductSuggestionLoaded(
        productId: event.productId,
        suggestions: suggestions ?? [],
        availableProducts: availableProducts ?? [],
      ));
    } catch (e) {
      emit(ProductSuggestionError(ErrorHandler.friendlyMessage(e)));
    }
  }

  Future<void> _onAddSuggestion(
    AddSuggestion event,
    Emitter<ProductSuggestionState> emit,
  ) async {
    try {
      if (state is! ProductSuggestionLoaded) return;

      final currentState = state;
      
      // Get next display order for this type
      final typeSuggestions = currentState.suggestions
          .where((s) => s['suggestion_type'] == event.suggestionType)
          .toList();
      final displayOrder = typeSuggestions.isEmpty ? 1 : 
          typeSuggestions.map((s) => s['display_order'] as int).reduce((a, b) => a > b ? a : b) + 1;

      await _service.createSuggestion(
        sourceProductId: event.sourceProductId,
        suggestedProductId: event.suggestedProductId,
        suggestionType: event.suggestionType,
        displayOrder: displayOrder,
        performedBy: event.performedBy,
      );

      // Reload suggestions to get updated list
      final updatedSuggestions = await _service.getSuggestionsForProduct(event.sourceProductId);
      
      emit(currentState.copyWith(suggestions: updatedSuggestions ?? []));
    } catch (e) {
      emit(ProductSuggestionError(ErrorHandler.friendlyMessage(e)));
      // Re-emit previous state on error
      if (state is ProductSuggestionLoaded) {
        emit(state);
      }
    }
  }

  Future<void> _onRemoveSuggestion(
    RemoveSuggestion event,
    Emitter<ProductSuggestionState> emit,
  ) async {
    try {
      if (state is! ProductSuggestionLoaded) return;

      final currentState = state;
      
      await _service.removeSuggestion(
        suggestionId: event.suggestionId,
        performedBy: event.performedBy,
      );

      // Remove from local state optimistically
      final updatedSuggestions = currentState.suggestions
          .where((s) => s['id'] != event.suggestionId)
          .toList();
      
      emit(currentState.copyWith(suggestions: updatedSuggestions));
    } catch (e) {
      emit(ProductSuggestionError(ErrorHandler.friendlyMessage(e)));
      // Re-emit previous state on error
      if (state is ProductSuggestionLoaded) {
        emit(state);
      }
    }
  }

  Future<void> _onReorderSuggestions(
    ReorderSuggestions event,
    Emitter<ProductSuggestionState> emit,
  ) async {
    try {
      if (state is! ProductSuggestionLoaded) return;
      
      // Guard: prevent empty reorder operations
      if (event.updatedOrders.isEmpty) return;

      final currentState = state;
      
      await _service.batchUpdateOrders(
        updates: event.updatedOrders,
        performedBy: event.performedBy,
      );

      // Update local state with new orders
      final updatedSuggestions = currentState.suggestions.map((suggestion) {
        final update = event.updatedOrders
            .where((u) => u['id'] == suggestion['id'])
            .firstOrNull;
        if (update != null) {
          return {...suggestion, 'display_order': update['display_order']};
        }
        return suggestion;
      }).toList();

      // Sort by display order
      updatedSuggestions.sort((a, b) => 
          (a['display_order'] as int).compareTo(b['display_order'] as int));

      emit(currentState.copyWith(suggestions: updatedSuggestions));
    } catch (e) {
      emit(ProductSuggestionError(ErrorHandler.friendlyMessage(e)));
      // Re-emit previous state on error
      if (state is ProductSuggestionLoaded) {
        emit(state);
      }
    }
  }

  Future<void> _onSearchProducts(
    SearchProducts event,
    Emitter<ProductSuggestionState> emit,
  ) async {
    try {
      if (state is! ProductSuggestionLoaded) return;

      final currentState = state;
      
      if (event.query.trim().isEmpty) {
        emit(currentState.copyWith(searchResults: []));
        return;
      }

      final searchResults = await _service.searchProducts(
        query: event.query,
        excludeProductId: event.excludeProductId,
      );

      emit(currentState.copyWith(searchResults: searchResults ?? []));
    } catch (e) {
      emit(ProductSuggestionError(ErrorHandler.friendlyMessage(e)));
      // Re-emit previous state on error
      if (state is ProductSuggestionLoaded) {
        emit(state);
      }
    }
  }

  Future<void> _onLoadAvailableProducts(
    LoadAvailableProducts event,
    Emitter<ProductSuggestionState> emit,
  ) async {
    try {
      if (state is! ProductSuggestionLoaded) return;

      final currentState = state;
      
      final availableProducts = await _service.getAvailableProducts(event.excludeProductId);

      emit(currentState.copyWith(availableProducts: availableProducts ?? []));
    } catch (e) {
      emit(ProductSuggestionError(ErrorHandler.friendlyMessage(e)));
      // Re-emit previous state on error
      if (state is ProductSuggestionLoaded) {
        emit(state);
      }
    }
  }

  Future<void> _onBulkAddSuggestions(
    BulkAddSuggestions event,
    Emitter<ProductSuggestionState> emit,
  ) async {
    try {
      if (state is! ProductSuggestionLoaded) return;
      
      // Guard: prevent empty bulk operations
      if (event.productIds.isEmpty) return;

      final currentState = state;
      
      await _service.bulkCreateSuggestions(
        sourceProductId: event.sourceProductId,
        productIds: event.productIds,
        suggestionType: event.suggestionType,
        performedBy: event.performedBy,
      );

      // Reload suggestions to get updated list
      final updatedSuggestions = await _service.getSuggestionsForProduct(event.sourceProductId);
      
      emit(currentState.copyWith(suggestions: updatedSuggestions ?? []));
    } catch (e) {
      emit(ProductSuggestionError(ErrorHandler.friendlyMessage(e)));
      // Re-emit previous state on error
      if (state is ProductSuggestionLoaded) {
        emit(state);
      }
    }
  }

  Future<void> _onToggleSuggestionStatus(
    ToggleSuggestionStatus event,
    Emitter<ProductSuggestionState> emit,
  ) async {
    try {
      if (state is! ProductSuggestionLoaded) return;

      final currentState = state;
      
      await _service.toggleSuggestionStatus(
        suggestionId: event.suggestionId,
        isActive: event.isActive,
        performedBy: event.performedBy,
      );

      // Update local state optimistically
      final updatedSuggestions = currentState.suggestions.map((suggestion) {
        if (suggestion['id'] == event.suggestionId) {
          return {...suggestion, 'is_active': event.isActive};
        }
        return suggestion;
      }).toList();
      
      emit(currentState.copyWith(suggestions: updatedSuggestions));
    } catch (e) {
      emit(ProductSuggestionError(ErrorHandler.friendlyMessage(e)));
      // Re-emit previous state on error
      if (state is ProductSuggestionLoaded) {
        emit(state);
      }
    }
  }

  Future<void> _onMoveSuggestionToTop(
    MoveSuggestionToTop event,
    Emitter<ProductSuggestionState> emit,
  ) async {
    try {
      if (state is! ProductSuggestionLoaded) return;

      final currentState = state;
      final suggestion = currentState.suggestions
          .where((s) => s['id'] == event.suggestionId)
          .firstOrNull;
      
      if (suggestion == null) return;

      // Get all suggestions of the same type
      final typeSuggestions = currentState.suggestions
          .where((s) => s['suggestion_type'] == suggestion['suggestion_type'])
          .toList()
        ..sort((a, b) => (a['display_order'] as int).compareTo(b['display_order'] as int));

      if (typeSuggestions.first['id'] == event.suggestionId) return; // Already at top

      // Create updates: move target to top (order 1), shift others down
      final updates = <Map<String, dynamic>>[];
      updates.add({'id': event.suggestionId, 'display_order': 1});
      
      for (int i = 0; i < typeSuggestions.length; i++) {
        final s = typeSuggestions[i];
        if (s['id'] != event.suggestionId) {
          updates.add({'id': s['id'], 'display_order': i + 2});
        }
      }

      await _service.batchUpdateOrders(
        updates: updates,
        performedBy: event.performedBy,
      );

      // Update local state
      final updatedSuggestions = currentState.suggestions.map((s) {
        final update = updates.where((u) => u['id'] == s['id']).firstOrNull;
        if (update != null) {
          return {...s, 'display_order': update['display_order']};
        }
        return s;
      }).toList();

      updatedSuggestions.sort((a, b) => 
          (a['display_order'] as int).compareTo(b['display_order'] as int));

      emit(currentState.copyWith(suggestions: updatedSuggestions));
    } catch (e) {
      emit(ProductSuggestionError(ErrorHandler.friendlyMessage(e)));
      // Re-emit previous state on error
      if (state is ProductSuggestionLoaded) {
        emit(state);
      }
    }
  }

  Future<void> _onMoveSuggestionToBottom(
    MoveSuggestionToBottom event,
    Emitter<ProductSuggestionState> emit,
  ) async {
    try {
      if (state is! ProductSuggestionLoaded) return;

      final currentState = state;
      final suggestion = currentState.suggestions
          .where((s) => s['id'] == event.suggestionId)
          .firstOrNull;
      
      if (suggestion == null) return;

      // Get all suggestions of the same type
      final typeSuggestions = currentState.suggestions
          .where((s) => s['suggestion_type'] == suggestion['suggestion_type'])
          .toList()
        ..sort((a, b) => (a['display_order'] as int).compareTo(b['display_order'] as int));

      if (typeSuggestions.last['id'] == event.suggestionId) return; // Already at bottom

      final maxOrder = typeSuggestions.length;
      
      // Create updates: move target to bottom, shift others up
      final updates = <Map<String, dynamic>>[];
      bool passedTarget = false;
      
      for (int i = 0; i < typeSuggestions.length; i++) {
        final s = typeSuggestions[i];
        if (s['id'] == event.suggestionId) {
          updates.add({'id': s['id'], 'display_order': maxOrder});
          passedTarget = true;
        } else {
          updates.add({'id': s['id'], 'display_order': passedTarget ? i + 1 : i + 2});
        }
      }

      await _service.batchUpdateOrders(
        updates: updates,
        performedBy: event.performedBy,
      );

      // Update local state
      final updatedSuggestions = currentState.suggestions.map((s) {
        final update = updates.where((u) => u['id'] == s['id']).firstOrNull;
        if (update != null) {
          return {...s, 'display_order': update['display_order']};
        }
        return s;
      }).toList();

      updatedSuggestions.sort((a, b) => 
          (a['display_order'] as int).compareTo(b['display_order'] as int));

      emit(currentState.copyWith(suggestions: updatedSuggestions));
    } catch (e) {
      emit(ProductSuggestionError(ErrorHandler.friendlyMessage(e)));
      // Re-emit previous state on error
      if (state is ProductSuggestionLoaded) {
        emit(state);
      }
    }
  }
}
