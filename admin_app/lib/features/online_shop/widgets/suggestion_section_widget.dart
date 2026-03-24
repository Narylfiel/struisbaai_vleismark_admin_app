import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Widget for displaying a section of suggestions with drag-and-drop reordering
/// Used for each suggestion type (FBT, Upsell, Related)
class SuggestionSectionWidget extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Map<String, dynamic>> suggestions;
  final Function(List<Map<String, dynamic>> updates) onReorder;
  final Function(String suggestionId) onRemove;
  final Function(String suggestionId, bool isActive) onToggleStatus;
  final Function(String suggestionId) onMoveToTop;
  final Function(String suggestionId) onMoveToBottom;

  const SuggestionSectionWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.suggestions,
    required this.onReorder,
    required this.onRemove,
    required this.onToggleStatus,
    required this.onMoveToTop,
    required this.onMoveToBottom,
  });

  @override
  State<SuggestionSectionWidget> createState() => _SuggestionSectionWidgetState();
}

class _SuggestionSectionWidgetState extends State<SuggestionSectionWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.suggestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              widget.icon,
              color: widget.color.withOpacity(0.5),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'No ${widget.title.toLowerCase()} yet',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  color: widget.color,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: widget.color,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.suggestions.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.color,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Suggestions list with drag-and-drop
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            itemCount: widget.suggestions.length,
            onReorder: _onReorder,
            itemBuilder: (context, index) {
              final suggestion = widget.suggestions[index];
              // SYSTEM CONTEXT: Only explicit FK syntax allowed
              final product = suggestion['inventory_items!suggested_product_id'] as Map<String, dynamic>?;
              
              if (product == null) {
                return const SizedBox.shrink(key: ValueKey('null_product'));
              }
              
              return _SuggestionItem(
                key: ValueKey(suggestion['id'] ?? 'suggestion_$index'),
                suggestion: suggestion,
                product: product,
                color: widget.color,
                onRemove: () => widget.onRemove(suggestion['id']),
                onToggleStatus: widget.onToggleStatus,
                onMoveToTop: widget.onMoveToTop,
                onMoveToBottom: widget.onMoveToBottom,
              );
            },
          ),
        ],
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    setState(() {
      final item = widget.suggestions.removeAt(oldIndex);
      widget.suggestions.insert(newIndex, item);
    });

    // Create updates for batch order update
    final updates = widget.suggestions.asMap().entries.map((entry) {
      return {
        'id': entry.value['id'],
        'display_order': entry.key + 1,
      };
    }).toList();

    widget.onReorder(updates);
  }
}

/// Individual suggestion item with drag handle, preview, and quick actions
class _SuggestionItem extends StatefulWidget {
  final Map<String, dynamic> suggestion;
  final Map<String, dynamic>? product;
  final Color color;
  final VoidCallback onRemove;
  final Function(String suggestionId, bool isActive) onToggleStatus;
  final Function(String suggestionId) onMoveToTop;
  final Function(String suggestionId) onMoveToBottom;

  const _SuggestionItem({
    super.key,
    required this.suggestion,
    required this.product,
    required this.color,
    required this.onRemove,
    required this.onToggleStatus,
    required this.onMoveToTop,
    required this.onMoveToBottom,
  });

  @override
  State<_SuggestionItem> createState() => _SuggestionItemState();
}

class _SuggestionItemState extends State<_SuggestionItem> {
  bool _isHovered = false;

  bool get _isInStock {
    if (widget.product == null) return false;
    final fresh = (widget.product!['stock_on_hand_fresh'] as num?)?.toDouble() ?? 0.0;
    final frozen = (widget.product!['stock_on_hand_frozen'] as num?)?.toDouble() ?? 0.0;
    final threshold = (widget.product!['online_min_stock_threshold'] as num?)?.toDouble() ?? 0.0;
    return (fresh + frozen) > threshold;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.product == null) {
      return const SizedBox.shrink();
    }

    final isActive = widget.suggestion['is_active'] as bool? ?? true;
    final isInactive = !isActive;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isInactive ? AppColors.scaffoldBg.withOpacity(0.5) : AppColors.scaffoldBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isInactive ? AppColors.border.withOpacity(0.5) : AppColors.border,
          ),
          boxShadow: _isHovered ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          children: [
            // Drag handle
            ReorderableDragStartListener(
              index: 0, // This will be replaced by the actual index in the list
              child: Container(
                width: 40,
                height: 60,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(isInactive ? 0.02 : 0.05),
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                ),
                child: Icon(
                  Icons.drag_handle,
                  color: widget.color.withOpacity(isInactive ? 0.3 : 0.5),
                  size: 20,
                ),
              ),
            ),

            // Product info with preview
            Expanded(
              child: GestureDetector(
                onTap: _showProductPreview,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.product!['online_display_name'] ?? widget.product!['name'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isInactive ? AppColors.textSecondary : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_isHovered)
                            Icon(
                              Icons.preview,
                              size: 14,
                              color: widget.color.withOpacity(0.6),
                            ),
                        ],
                      ),
                      if (widget.product!['online_display_name'] != null && widget.product!['online_display_name'] != widget.product!['name'])
                        Text(
                          widget.product!['name'],
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Row(
                        children: [
                          Text(
                            'R ${widget.product!['sell_price']?.toStringAsFixed(2) ?? '0.00'}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: _isInStock ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _isInStock ? 'In Stock' : 'Low Stock',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: _isInStock ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Order indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(isInactive ? 0.05 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '#${widget.suggestion['display_order'] ?? '1'}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: widget.color.withOpacity(isInactive ? 0.5 : 1.0),
                ),
              ),
            ),

            // Quick actions (shown on hover)
            if (_isHovered) ...[
              // Move to top
              IconButton(
                onPressed: () => widget.onMoveToTop(widget.suggestion['id']),
                icon: Icon(
                  Icons.keyboard_double_arrow_up,
                  color: AppColors.info,
                  size: 16,
                ),
                tooltip: 'Move to top',
                visualDensity: VisualDensity.compact,
              ),
              // Move to bottom
              IconButton(
                onPressed: () => widget.onMoveToBottom(widget.suggestion['id']),
                icon: Icon(
                  Icons.keyboard_double_arrow_down,
                  color: AppColors.info,
                  size: 16,
                ),
                tooltip: 'Move to bottom',
                visualDensity: VisualDensity.compact,
              ),
              // Toggle status
              IconButton(
                onPressed: () => widget.onToggleStatus(widget.suggestion['id'], !isActive),
                icon: Icon(
                  isActive ? Icons.visibility : Icons.visibility_off,
                  color: isActive ? AppColors.success : AppColors.warning,
                  size: 16,
                ),
                tooltip: isActive ? 'Deactivate' : 'Activate',
                visualDensity: VisualDensity.compact,
              ),
            ],

            // Delete button (always visible)
            IconButton(
              onPressed: widget.onRemove,
              icon: Icon(
                Icons.delete_outline,
                color: AppColors.error,
                size: 18,
              ),
              tooltip: 'Remove suggestion',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  void _showProductPreview() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.product!['online_display_name'] ?? widget.product!['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.product!['online_display_name'] != null && widget.product!['online_display_name'] != widget.product!['name']) ...[
              Text(
                'Display Name:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                widget.product!['online_display_name'],
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Price:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              'R ${widget.product!['sell_price']?.toStringAsFixed(2) ?? '0.00'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stock Status:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              _isInStock ? 'In Stock' : 'Low Stock',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _isInStock ? AppColors.success : AppColors.error,
              ),
            ),
            if (widget.product!['plu_code'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'SKU/PLU:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                widget.product!['plu_code'],
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
