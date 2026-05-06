import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_breakpoints.dart';

/// Reusable filter bar widget for data filtering
class FilterBarWidget extends StatefulWidget {
  final List<FilterOption> filters;
  final Function(Map<String, dynamic>) onFiltersChanged;
  final Map<String, dynamic> initialFilters;
  final bool showClearButton;
  final String clearButtonText;

  const FilterBarWidget({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
    this.initialFilters = const {},
    this.showClearButton = true,
    this.clearButtonText = 'Clear Filters',
  });

  @override
  State<FilterBarWidget> createState() => _FilterBarWidgetState();
}

class _FilterBarWidgetState extends State<FilterBarWidget> {
  late Map<String, dynamic> _activeFilters;

  @override
  void initState() {
    super.initState();
    _activeFilters = Map.from(widget.initialFilters);
  }

  void _updateFilter(String key, dynamic value) {
    setState(() {
      if (value == null ||
          (value is String && value.isEmpty) ||
          (value is List && value.isEmpty)) {
        _activeFilters.remove(key);
      } else {
        _activeFilters[key] = value;
      }
    });
    widget.onFiltersChanged(_activeFilters);
  }

  void _clearFilters() {
    setState(() {
      _activeFilters.clear();
    });
    widget.onFiltersChanged({});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow =
                  constraints.maxWidth < ResponsiveBreakpoints.phoneMaxWidth;
              const title = Text(
                'Filters',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              );
              final clearButton =
                  widget.showClearButton && _activeFilters.isNotEmpty
                      ? TextButton(
                          onPressed: _clearFilters,
                          child: Text(
                            widget.clearButtonText,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : null;
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    if (clearButton != null) ...[
                      const SizedBox(height: 8),
                      clearButton,
                    ],
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  title,
                  if (clearButton != null) clearButton,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = _filterWidthFor(constraints.maxWidth);
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: widget.filters
                    .map((filter) => SizedBox(
                          width: itemWidth,
                          child: _buildFilterWidget(filter),
                        ))
                    .toList(),
              );
            },
          ),
          if (_activeFilters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _buildActiveFilterChips(),
              ),
            ),
        ],
      ),
    );
  }

  double _filterWidthFor(double maxWidth) {
    if (maxWidth < 430) return maxWidth;
    if (maxWidth < 760) return (maxWidth - 16) / 2;
    return 280;
  }

  Widget _buildFilterWidget(FilterOption filter) {
    final currentValue = _activeFilters[filter.key];

    switch (filter.type) {
      case FilterType.dropdown:
        return DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: currentValue,
          decoration: InputDecoration(
            labelText: filter.label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: filter.options?.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (value) => _updateFilter(filter.key, value),
        );

      case FilterType.dateRange:
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              suffixIcon: const Icon(
                Icons.date_range,
                color: AppColors.textSecondary,
              ),
            ),
            child: Text(
              currentValue != null
                  ? '${currentValue.start.toString().split(' ')[0]} - ${currentValue.end.toString().split(' ')[0]}'
                  : 'Select date range',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: currentValue != null
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        );

      case FilterType.checkbox:
        return CheckboxListTile(
          title: Text(filter.label),
          value: currentValue ?? false,
          onChanged: (value) => _updateFilter(filter.key, value),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          contentPadding: EdgeInsets.zero,
        );

      case FilterType.numericRange:
        return LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 260;
            final minField = TextFormField(
              initialValue: currentValue?['min']?.toString(),
              decoration: InputDecoration(
                labelText: '${filter.label} (Min)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final numValue = num.tryParse(value);
                final range =
                    Map<String, dynamic>.from(_activeFilters[filter.key] ?? {});
                range['min'] = numValue;
                _updateFilter(filter.key, range.isEmpty ? null : range);
              },
            );
            final maxField = TextFormField(
              initialValue: currentValue?['max']?.toString(),
              decoration: InputDecoration(
                labelText: '${filter.label} (Max)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final numValue = num.tryParse(value);
                final range =
                    Map<String, dynamic>.from(_activeFilters[filter.key] ?? {});
                range['max'] = numValue;
                _updateFilter(filter.key, range.isEmpty ? null : range);
              },
            );
            if (stack) {
              return Column(
                children: [
                  minField,
                  const SizedBox(height: 8),
                  maxField,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: minField),
                const SizedBox(width: 8),
                Expanded(child: maxField),
              ],
            );
          },
        );
    }
  }

  List<Widget> _buildActiveFilterChips() {
    return _activeFilters.entries.map((entry) {
      final filter = widget.filters.firstWhere(
        (f) => f.key == entry.key,
        orElse: () => FilterOption(
            key: entry.key, label: entry.key, type: FilterType.dropdown),
      );

      String displayValue;
      if (entry.value is DateTimeRange) {
        displayValue =
            '${entry.value.start.toString().split(' ')[0]} - ${entry.value.end.toString().split(' ')[0]}';
      } else if (entry.value is Map) {
        final range = entry.value as Map;
        if (range.containsKey('min') && range.containsKey('max')) {
          displayValue = '${range['min'] ?? ''} - ${range['max'] ?? ''}';
        } else {
          displayValue = range.toString();
        }
      } else {
        displayValue = entry.value.toString();
      }

      return Chip(
        label: Text(
          '${filter.label}: $displayValue',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
          ),
        ),
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        deleteIcon: const Icon(
          Icons.close,
          size: 16,
          color: AppColors.primary,
        ),
        onDeleted: () => _updateFilter(entry.key, null),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      );
    }).toList();
  }
}

/// Filter option configuration
class FilterOption {
  final String key;
  final String label;
  final FilterType type;
  final List<String>? options;

  const FilterOption({
    required this.key,
    required this.label,
    required this.type,
    this.options,
  });
}

/// Filter types
enum FilterType {
  dropdown,
  dateRange,
  checkbox,
  numericRange,
}
