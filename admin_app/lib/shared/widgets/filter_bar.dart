import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

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
      if (value == null || (value is String && value.isEmpty) || (value is List && value.isEmpty)) {
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
              if (widget.showClearButton && _activeFilters.isNotEmpty)
                TextButton(
                  onPressed: _clearFilters,
                  child: Text(
                    widget.clearButtonText,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: widget.filters.map((filter) => _buildFilterWidget(filter)).toList(),
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

  Widget _buildFilterWidget(FilterOption filter) {
    final currentValue = _activeFilters[filter.key];

    switch (filter.type) {
      case FilterType.dropdown:
        return SizedBox(
          width: 200,
          child: DropdownButtonFormField<String>(
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
          ),
        );

      case FilterType.dateRange:
        return SizedBox(
          width: 300,
          child: InkWell(
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
          ),
        );

      case FilterType.checkbox:
        return SizedBox(
          width: 200,
          child: CheckboxListTile(
            title: Text(filter.label),
            value: currentValue ?? false,
            onChanged: (value) => _updateFilter(filter.key, value),
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        );

      case FilterType.numericRange:
        return SizedBox(
          width: 300,
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: currentValue?['min']?.toString(),
                  decoration: InputDecoration(
                    labelText: '${filter.label} (Min)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final numValue = num.tryParse(value);
                    final range = Map<String, dynamic>.from(_activeFilters[filter.key] ?? {});
                    range['min'] = numValue;
                    _updateFilter(filter.key, range.isEmpty ? null : range);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: currentValue?['max']?.toString(),
                  decoration: InputDecoration(
                    labelText: '${filter.label} (Max)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final numValue = num.tryParse(value);
                    final range = Map<String, dynamic>.from(_activeFilters[filter.key] ?? {});
                    range['max'] = numValue;
                    _updateFilter(filter.key, range.isEmpty ? null : range);
                  },
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  List<Widget> _buildActiveFilterChips() {
    return _activeFilters.entries.map((entry) {
      final filter = widget.filters.firstWhere(
        (f) => f.key == entry.key,
        orElse: () => FilterOption(key: entry.key, label: entry.key, type: FilterType.dropdown),
      );

      String displayValue;
      if (entry.value is DateTimeRange) {
        displayValue = '${entry.value.start.toString().split(' ')[0]} - ${entry.value.end.toString().split(' ')[0]}';
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
        backgroundColor: AppColors.primary.withOpacity(0.1),
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