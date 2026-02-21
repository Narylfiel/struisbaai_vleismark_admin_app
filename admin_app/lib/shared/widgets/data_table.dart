import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Reusable data table widget with sorting, pagination, and actions
class DataTableWidget extends StatefulWidget {
  final List<String> columns;
  final List<Map<String, dynamic>> data;
  final Map<String, String>? columnHeaders;
  final List<String>? sortableColumns;
  final int? rowsPerPage;
  final bool showActions;
  final List<DataTableAction>? actions;
  final Function(Map<String, dynamic>)? onRowTap;
  final String? emptyMessage;

  const DataTableWidget({
    super.key,
    required this.columns,
    required this.data,
    this.columnHeaders,
    this.sortableColumns,
    this.rowsPerPage = 20,
    this.showActions = true,
    this.actions,
    this.onRowTap,
    this.emptyMessage = 'No data available',
  });

  @override
  State<DataTableWidget> createState() => _DataTableWidgetState();
}

class _DataTableWidgetState extends State<DataTableWidget> {
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  int _currentPage = 0;
  late List<Map<String, dynamic>> _filteredData;

  @override
  void initState() {
    super.initState();
    _filteredData = List.from(widget.data);
  }

  @override
  void didUpdateWidget(DataTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _filteredData = List.from(widget.data);
      _currentPage = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_filteredData.isEmpty) {
      return _buildEmptyState();
    }

    final totalPages = (widget.rowsPerPage != null && widget.rowsPerPage! > 0)
        ? (_filteredData.length / widget.rowsPerPage!).ceil()
        : 1;

    final startIndex = _currentPage * (widget.rowsPerPage ?? _filteredData.length);
    final endIndex = startIndex + (widget.rowsPerPage ?? _filteredData.length);
    final pageData = _filteredData.sublist(
      startIndex,
      endIndex > _filteredData.length ? _filteredData.length : endIndex,
    );

    return Column(
      children: [
        // Table
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columnSpacing: 16,
                horizontalMargin: 16,
                headingRowHeight: 48,
                dataRowHeight: 52,
                headingTextStyle: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                dataTextStyle: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                columns: _buildColumns(),
                rows: _buildRows(pageData),
              ),
            ),
          ),
        ),

        // Pagination
        if (widget.rowsPerPage != null && totalPages > 1)
          _buildPagination(totalPages),
      ],
    );
  }

  List<DataColumn> _buildColumns() {
    final columns = <DataColumn>[];

    for (var i = 0; i < widget.columns.length; i++) {
      final column = widget.columns[i];
      final header = widget.columnHeaders?[column] ?? column;
      final isSortable = widget.sortableColumns?.contains(column) ?? false;

      columns.add(
        DataColumn(
          label: Text(header),
          onSort: isSortable ? (columnIndex, ascending) => _sort(columnIndex, ascending) : null,
        ),
      );
    }

    // Actions column
    if (widget.showActions && (widget.actions?.isNotEmpty ?? false)) {
      columns.add(const DataColumn(label: Text('Actions')));
    }

    return columns;
  }

  List<DataRow> _buildRows(List<Map<String, dynamic>> data) {
    return data.map((row) {
      final cells = widget.columns.map((column) {
        final value = row[column];
        return DataCell(
          Text(_formatCellValue(value)),
          onTap: widget.onRowTap != null ? () => widget.onRowTap!(row) : null,
        );
      }).toList();

      // Actions cell
      if (widget.showActions && widget.actions != null) {
        cells.add(DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: widget.actions!.map((action) {
              return IconButton(
                icon: Icon(action.icon, size: 18),
                color: action.color ?? AppColors.primary,
                onPressed: () => action.onPressed(row),
                tooltip: action.tooltip,
              );
            }).toList(),
          ),
        ));
      }

      return DataRow(cells: cells);
    }).toList();
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${_currentPage + 1} of $totalPages (${_filteredData.length} total)',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, size: 20),
                onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                color: _currentPage > 0 ? AppColors.primary : AppColors.textSecondary,
              ),
              Container(
                constraints: BoxConstraints(minWidth: 40),
                child: Text(
                  '${_currentPage + 1}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, size: 20),
                onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                color: _currentPage < totalPages - 1 ? AppColors.primary : AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_chart_outlined,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            widget.emptyMessage!,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _sort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;

      final column = widget.columns[columnIndex];
      _filteredData.sort((a, b) {
        final aValue = a[column];
        final bValue = b[column];

        if (aValue == null && bValue == null) return 0;
        if (aValue == null) return ascending ? -1 : 1;
        if (bValue == null) return ascending ? 1 : -1;

        // Handle different data types
        if (aValue is num && bValue is num) {
          return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
        }

        if (aValue is DateTime && bValue is DateTime) {
          return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
        }

        final aStr = aValue.toString().toLowerCase();
        final bStr = bValue.toString().toLowerCase();

        return ascending ? aStr.compareTo(bStr) : bStr.compareTo(aStr);
      });
    });
  }

  String _formatCellValue(dynamic value) {
    if (value == null) return '';

    if (value is DateTime) {
      return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
    }

    if (value is num) {
      if (value is int) return value.toString();
      return value.toStringAsFixed(2);
    }

    return value.toString();
  }
}

/// Data table action configuration
class DataTableAction {
  final IconData icon;
  final String tooltip;
  final Color? color;
  final Function(Map<String, dynamic>) onPressed;

  const DataTableAction({
    required this.icon,
    required this.tooltip,
    this.color,
    required this.onPressed,
  });
}