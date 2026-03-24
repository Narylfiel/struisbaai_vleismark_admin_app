import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../blocs/product_suggestion/product_suggestion_bloc.dart';

/// Dialog for adding a new product suggestion
/// Features searchable product list and suggestion type selection
class AddSuggestionDialog extends StatefulWidget {
  final String productId;
  final Function(String suggestedProductId, String suggestionType) onAdd;

  const AddSuggestionDialog({
    super.key,
    required this.productId,
    required this.onAdd,
  });

  @override
  State<AddSuggestionDialog> createState() => _AddSuggestionDialogState();
}

class _AddSuggestionDialogState extends State<AddSuggestionDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedProductId = '';
  String _selectedSuggestionType = 'frequently_bought_together';
  bool _isLoading = false;

  final List<Map<String, String>> _suggestionTypes = [
    {
      'value': 'frequently_bought_together',
      'label': 'Frequently Bought Together',
      'description': 'Products often purchased together',
    },
    {
      'value': 'upsell',
      'label': 'Upsell Item',
      'description': 'Premium alternatives or add-ons',
    },
    {
      'value': 'related',
      'label': 'Related Product',
      'description': 'Similar or complementary items',
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Load available products
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductSuggestionBloc>().add(LoadAvailableProducts(widget.productId));
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      context.read<ProductSuggestionBloc>().add(SearchProducts(
        query: query,
        excludeProductId: widget.productId,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBg,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.add_shopping_cart,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add Product Suggestion',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Suggestion type selection
            Text(
              'Suggestion Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _suggestionTypes.map((type) {
                final isSelected = _selectedSuggestionType == type['value'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedSuggestionType = type['value']!),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _getIconForType(type['value']!),
                            size: 20,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type['label']!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            type['description']!,
                            style: TextStyle(
                              fontSize: 9,
                              color: isSelected ? Colors.white70 : AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Product search
            Text(
              'Select Product',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Product list
            Expanded(
              child: BlocBuilder<ProductSuggestionBloc, ProductSuggestionState>(
                builder: (context, state) {
                  if (state is ProductSuggestionLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  List<Map<String, dynamic>> products = [];
                  if (state is ProductSuggestionLoaded) {
                    products = _searchController.text.trim().isEmpty
                        ? state.availableProducts
                        : state.searchResults;
                  }

                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No products found',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final isSelected = _selectedProductId == product['id'];
                      
                      return GestureDetector(
                        onTap: () => setState(() => _selectedProductId = product['id']),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.cardBg,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: product['id'],
                                groupValue: _selectedProductId,
                                onChanged: (value) => setState(() => _selectedProductId = value!),
                                activeColor: AppColors.primary,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['online_display_name'] ?? product['name'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                      ),
                                    ),
                                    if (product['online_display_name'] != null && product['online_display_name'] != product['name'])
                                      Text(
                                        product['name'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    Text(
                                      'R ${product['sell_price']?.toStringAsFixed(2) ?? '0.00'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Actions
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _selectedProductId.isNotEmpty && !_isLoading
                      ? _addSuggestion
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Add Suggestion'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'frequently_bought_together':
        return Icons.shopping_cart;
      case 'upsell':
        return Icons.trending_up;
      case 'related':
        return Icons.category;
      default:
        return Icons.help_outline;
    }
  }

  void _addSuggestion() async {
    setState(() => _isLoading = true);
    
    try {
      widget.onAdd(_selectedProductId, _selectedSuggestionType);
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding suggestion: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
