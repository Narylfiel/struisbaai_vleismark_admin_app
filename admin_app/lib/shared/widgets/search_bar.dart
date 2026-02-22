import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Reusable search bar widget
class SearchBarWidget extends StatefulWidget {
  final String hintText;
  final Function(String) onSearch;
  final String? initialValue;
  final bool showClearButton;
  final Duration debounceDuration;

  const SearchBarWidget({
    super.key,
    this.hintText = 'Search...',
    required this.onSearch,
    this.initialValue,
    this.showClearButton = true,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;
  String _lastSearchValue = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _lastSearchValue = _controller.text;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _performSearch(String value) {
    if (value != _lastSearchValue) {
      _lastSearchValue = value;
      widget.onSearch(value);
    }
  }

  void _clearSearch() {
    _controller.clear();
    _performSearch('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          // Debounce search
          Future.delayed(widget.debounceDuration, () {
            if (mounted && _controller.text == value) {
              _performSearch(value);
            }
          });
        },
        onSubmitted: _performSearch,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: 20,
          ),
          suffixIcon: widget.showClearButton && _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: _clearSearch,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
    );
  }
}

/// Advanced search bar with filters
class AdvancedSearchBar extends StatefulWidget {
  final String hintText;
  final Function(String, Map<String, dynamic>) onSearch;
  final List<SearchFilter> filters;
  final String? initialValue;
  final bool showFilters;

  const AdvancedSearchBar({
    super.key,
    this.hintText = 'Search...',
    required this.onSearch,
    this.filters = const [],
    this.initialValue,
    this.showFilters = true,
  });

  @override
  State<AdvancedSearchBar> createState() => _AdvancedSearchBarState();
}

class _AdvancedSearchBarState extends State<AdvancedSearchBar> {
  late TextEditingController _controller;
  final Map<String, dynamic> _filterValues = {};
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _performSearch() {
    widget.onSearch(_controller.text, Map.from(_filterValues));
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  void _updateFilter(String key, dynamic value) {
    setState(() {
      _filterValues[key] = value;
    });
    _performSearch();
  }

  void _clearFilters() {
    setState(() {
      _filterValues.clear();
    });
    _performSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Row(
          children: [
            Expanded(
              child: SearchBarWidget(
                hintText: widget.hintText,
                onSearch: (value) {
                  _controller.text = value;
                  _performSearch();
                },
                initialValue: widget.initialValue,
              ),
            ),
            if (widget.showFilters && widget.filters.isNotEmpty)
              IconButton(
                icon: Icon(
                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                  color: _filterValues.isNotEmpty ? AppColors.primary : AppColors.textSecondary,
                ),
                onPressed: _toggleFilters,
                tooltip: _showFilters ? 'Hide filters' : 'Show filters',
              ),
          ],
        ),

        // Filters
        if (_showFilters && widget.filters.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_filterValues.isNotEmpty)
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text(
                          'Clear All',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: widget.filters.map((filter) {
                    return SizedBox(
                      width: 200,
                      child: _buildFilterWidget(filter),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFilterWidget(SearchFilter filter) {
    final currentValue = _filterValues[filter.key];

    switch (filter.type) {
      case SearchFilterType.dropdown:
        return DropdownButtonFormField<String>(
          initialValue: currentValue,
          decoration: InputDecoration(
            labelText: filter.label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: filter.options?.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (value) => _updateFilter(filter.key, value),
        );

      case SearchFilterType.dateRange:
        return InkWell(
          onTap: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              initialDateRange: currentValue,
            );
            if (picked != null) {
              _updateFilter(filter.key, picked);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: filter.label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              suffixIcon: const Icon(
                Icons.date_range,
                color: AppColors.textSecondary,
              ),
            ),
            child: Text(
              currentValue != null
                  ? '${currentValue.start.toString().split(' ')[0]} - ${currentValue.end.toString().split(' ')[0]}'
                  : 'Select date range',
              style: TextStyle(
                color: currentValue != null ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        );

      case SearchFilterType.checkbox:
        return CheckboxListTile(
          title: Text(filter.label),
          value: currentValue ?? false,
          onChanged: (value) => _updateFilter(filter.key, value),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          contentPadding: EdgeInsets.zero,
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

/// Search filter configuration
class SearchFilter {
  final String key;
  final String label;
  final SearchFilterType type;
  final List<String>? options;

  const SearchFilter({
    required this.key,
    required this.label,
    required this.type,
    this.options,
  });
}

/// Search filter types
enum SearchFilterType {
  dropdown,
  dateRange,
  checkbox,
}