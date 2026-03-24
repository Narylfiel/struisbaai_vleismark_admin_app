import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../blocs/product_suggestion/product_suggestion_bloc.dart';
import '../widgets/add_suggestion_dialog.dart';
import '../widgets/suggestion_section_widget.dart';

/// Admin screen for managing product suggestions
/// Follows existing admin app UI patterns with clean layout and intuitive interactions
class ProductSuggestionManagerScreen extends StatefulWidget {
  final String productId;
  final String productName;

  const ProductSuggestionManagerScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<ProductSuggestionManagerScreen> createState() => _ProductSuggestionManagerScreenState();
}

class _ProductSuggestionManagerScreenState extends State<ProductSuggestionManagerScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductSuggestionBloc>().add(LoadSuggestions(widget.productId));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text('Product Suggestions - ${widget.productName}'),
        backgroundColor: AppColors.cardBg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showAddSuggestionDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Add Suggestion',
          ),
        ],
      ),
      body: BlocBuilder<ProductSuggestionBloc, ProductSuggestionState>(
        builder: (context, state) {
          if (state is ProductSuggestionLoading) {
            return const LoadingWidget();
          }

          if (state is ProductSuggestionError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading suggestions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.read<ProductSuggestionBloc>().add(LoadSuggestions(widget.productId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ProductSuggestionLoaded) {
            return _buildContent(state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(ProductSuggestionLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ProductSuggestionBloc>().add(LoadSuggestions(widget.productId));
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Managing suggestions for:',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          widget.productName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${state.suggestions.length} suggestions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Suggestion sections
            SuggestionSectionWidget(
              title: 'Frequently Bought Together',
              icon: Icons.shopping_cart,
              color: AppColors.success,
              suggestions: state.frequentlyBoughtTogether,
              onReorder: (updates) => _reorderSuggestions(updates),
              onRemove: (suggestionId) => _removeSuggestion(suggestionId),
              onToggleStatus: (suggestionId, isActive) => _toggleSuggestionStatus(suggestionId, isActive),
              onMoveToTop: (suggestionId) => _moveSuggestionToTop(suggestionId),
              onMoveToBottom: (suggestionId) => _moveSuggestionToBottom(suggestionId),
            ),

            const SizedBox(height: 24),

            SuggestionSectionWidget(
              title: 'Upsell Items',
              icon: Icons.trending_up,
              color: AppColors.warning,
              suggestions: state.upsellItems,
              onReorder: (updates) => _reorderSuggestions(updates),
              onRemove: (suggestionId) => _removeSuggestion(suggestionId),
              onToggleStatus: (suggestionId, isActive) => _toggleSuggestionStatus(suggestionId, isActive),
              onMoveToTop: (suggestionId) => _moveSuggestionToTop(suggestionId),
              onMoveToBottom: (suggestionId) => _moveSuggestionToBottom(suggestionId),
            ),

            const SizedBox(height: 24),

            SuggestionSectionWidget(
              title: 'Related Products',
              icon: Icons.category,
              color: AppColors.info,
              suggestions: state.relatedProducts,
              onReorder: (updates) => _reorderSuggestions(updates),
              onRemove: (suggestionId) => _removeSuggestion(suggestionId),
              onToggleStatus: (suggestionId, isActive) => _toggleSuggestionStatus(suggestionId, isActive),
              onMoveToTop: (suggestionId) => _moveSuggestionToTop(suggestionId),
              onMoveToBottom: (suggestionId) => _moveSuggestionToBottom(suggestionId),
            ),

            const SizedBox(height: 32),

            // Empty state if no suggestions
            if (state.suggestions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No suggestions yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add product suggestions to increase cross-sells and improve customer experience.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showAddSuggestionDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Suggestion'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showAddSuggestionDialog() {
    showDialog(
      context: context,
      builder: (context) => AddSuggestionDialog(
        productId: widget.productId,
        onAdd: (suggestedProductId, suggestionType) {
          final performedBy = AuthService().currentUser?.id ?? '';
          if (performedBy.isNotEmpty) {
            context.read<ProductSuggestionBloc>().add(AddSuggestion(
              sourceProductId: widget.productId,
              suggestedProductId: suggestedProductId,
              suggestionType: suggestionType,
              performedBy: performedBy,
            ));
          }
        },
      ),
    );
  }

  void _reorderSuggestions(List<Map<String, dynamic>> updates) {
    final performedBy = AuthService().currentUser?.id ?? '';
    if (performedBy.isNotEmpty) {
      context.read<ProductSuggestionBloc>().add(ReorderSuggestions(
        updatedOrders: updates,
        performedBy: performedBy,
      ));
    }
  }

  void _removeSuggestion(String suggestionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Suggestion'),
        content: const Text('Are you sure you want to remove this suggestion?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              final performedBy = AuthService().currentUser?.id ?? '';
              if (performedBy.isNotEmpty) {
                context.read<ProductSuggestionBloc>().add(RemoveSuggestion(
                  suggestionId: suggestionId,
                  performedBy: performedBy,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _toggleSuggestionStatus(String suggestionId, bool isActive) {
    final performedBy = AuthService().currentUser?.id ?? '';
    if (performedBy.isNotEmpty) {
      context.read<ProductSuggestionBloc>().add(ToggleSuggestionStatus(
        suggestionId: suggestionId,
        isActive: isActive,
        performedBy: performedBy,
      ));
    }
  }

  void _moveSuggestionToTop(String suggestionId) {
    final performedBy = AuthService().currentUser?.id ?? '';
    if (performedBy.isNotEmpty) {
      context.read<ProductSuggestionBloc>().add(MoveSuggestionToTop(
        suggestionId: suggestionId,
        performedBy: performedBy,
      ));
    }
  }

  void _moveSuggestionToBottom(String suggestionId) {
    final performedBy = AuthService().currentUser?.id ?? '';
    if (performedBy.isNotEmpty) {
      context.read<ProductSuggestionBloc>().add(MoveSuggestionToBottom(
        suggestionId: suggestionId,
        performedBy: performedBy,
      ));
    }
  }
}
