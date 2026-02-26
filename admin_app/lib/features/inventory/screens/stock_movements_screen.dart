import 'dart:io';
import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/auth_service.dart';
import 'package:admin_app/core/services/export_service.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stock Movements — READ-ONLY view of all stock_movements records.
/// 
/// Displays complete movement history with filtering, search, and export.
/// No create/edit/delete functionality — viewing only.
class StockMovementsScreen extends StatefulWidget {
  const StockMovementsScreen({super.key});

  @override
  State<StockMovementsScreen> createState() => _StockMovementsScreenState();
}

class _StockMovementsScreenState extends State<StockMovementsScreen> {
  final _client = SupabaseService.client;
  final _auth = AuthService();
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _allMovements = [];
  List<Map<String, dynamic>> _movements = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;

  // Filters
  DateTime _dateFrom = DateTime.now().subtract(const Duration(days: 7));
  DateTime _dateTo = DateTime.now();
  Set<String> _selectedTypes = {'all'};
  String _searchTerm = '';

  // Pagination
  int _offset = 0;
  int _totalCount = 0;
  static const int _pageSize = 100;

  // Summary stats
  double _stockIn = 0;
  double _stockOut = 0;
  double _netChange = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchTerm = _searchController.text.trim());
      _applyFilters();
    });
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _offset = 0;
      _allMovements = [];
    });

    try {
      // Build query chain based on filter
      dynamic query = _client
          .from('stock_movements')
          .select('''
            id, item_id, movement_type, quantity, unit_type,
            balance_after, reference_id, reference_type,
            reason, staff_id, photo_url, notes, created_at,
            location_from, location_to,
            inventory_items(plu_code, name, cost_price),
            profiles(full_name)
          ''');

      if (!_selectedTypes.contains('all')) {
        query = query.inFilter('movement_type', _selectedTypes.toList());
      }

      final data = await query
          .gte('created_at', _dateFrom.toIso8601String())
          .lte('created_at', _dateTo.toIso8601String())
          .order('created_at', ascending: false)
          .limit(_pageSize);

      _allMovements = List<Map<String, dynamic>>.from(data as List);
      _totalCount = _allMovements.length;
      _offset = _pageSize;
      _applyFilters();
      _calculateStats();
    } catch (e) {
      debugPrint('Stock movements load error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _allMovements.length < _pageSize) return;

    setState(() => _isLoadingMore = true);

    try {
      dynamic query = _client
          .from('stock_movements')
          .select('''
            id, item_id, movement_type, quantity, unit_type,
            balance_after, reference_id, reference_type,
            reason, staff_id, photo_url, notes, created_at,
            location_from, location_to,
            inventory_items(plu_code, name, cost_price),
            profiles(full_name)
          ''');

      if (!_selectedTypes.contains('all')) {
        query = query.inFilter('movement_type', _selectedTypes.toList());
      }

      final data = await query
          .gte('created_at', _dateFrom.toIso8601String())
          .lte('created_at', _dateTo.toIso8601String())
          .order('created_at', ascending: false)
          .range(_offset, _offset + _pageSize - 1);

      final newMovements = List<Map<String, dynamic>>.from(data as List);

      setState(() {
        _allMovements.addAll(newMovements);
        _totalCount = _allMovements.length;
        _offset += _pageSize;
      });

      _applyFilters();
      _calculateStats();
    } catch (e) {
      debugPrint('Load more error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(_allMovements);

    if (_searchTerm.isNotEmpty) {
      final term = _searchTerm.toLowerCase();
      filtered = filtered.where((m) {
        final item = m['inventory_items'] as Map<String, dynamic>?;
        final plu = item?['plu_code']?.toString() ?? '';
        final name = (item?['name'] ?? '').toString().toLowerCase();
        return plu.contains(term) || name.contains(term);
      }).toList();
    }

    setState(() => _movements = filtered);
  }

  void _calculateStats() {
    double stockIn = 0;
    double stockOut = 0;

    for (final m in _movements) {
      final qty = (m['quantity'] as num?)?.toDouble() ?? 0;
      if (qty > 0) {
        stockIn += qty;
      } else {
        stockOut += qty.abs();
      }
    }

    setState(() {
      _stockIn = stockIn;
      _stockOut = stockOut;
      _netChange = stockIn - stockOut;
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _dateFrom, end: _dateTo),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.cardBg,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateFrom = picked.start;
        _dateTo = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
      await _loadData();
    }
  }

  void _toggleTypeFilter(String type) {
    setState(() {
      if (type == 'all') {
        _selectedTypes = {'all'};
      } else {
        _selectedTypes.remove('all');
        if (_selectedTypes.contains(type)) {
          _selectedTypes.remove(type);
          if (_selectedTypes.isEmpty) {
            _selectedTypes = {'all'};
          }
        } else {
          _selectedTypes.add(type);
        }
      }
    });
    _loadData();
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'in':
        return Colors.green;
      case 'out':
        return Colors.red;
      case 'adjustment':
        return Colors.orange;
      case 'waste':
        return Colors.red[700]!;
      case 'sponsorship':
        return Colors.blue;
      case 'donation':
        return Colors.blue[300]!;
      case 'production':
        return Colors.purple;
      case 'transfer':
        return Colors.teal;
      case 'staff_meal':
        return Colors.brown;
      case 'freezer':
        return Colors.cyan[700]!;
      default:
        return Colors.grey;
    }
  }

  String _typeLabel(String? type) {
    switch (type) {
      case 'in':
        return 'In';
      case 'out':
        return 'Out';
      case 'adjustment':
        return 'Adjustment';
      case 'waste':
        return 'Waste';
      case 'sponsorship':
        return 'Sponsorship';
      case 'donation':
        return 'Donation';
      case 'production':
        return 'Production';
      case 'transfer':
        return 'Transfer';
      case 'staff_meal':
        return 'Staff Meal';
      case 'freezer':
        return 'Freezer';
      default:
        return type ?? 'Unknown';
    }
  }

  Future<void> _exportCsv() async {
    try {
      final rows = _movements.map((m) {
        final item = m['inventory_items'] as Map<String, dynamic>?;
        final staff = m['profiles'] as Map<String, dynamic>?;
        final qty = (m['quantity'] as num?)?.toDouble() ?? 0;

        return {
          'Date': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(m['created_at'])),
          'PLU': item?['plu_code']?.toString() ?? '-',
          'Product Name': item?['name']?.toString() ?? 'Unknown Product',
          'Movement Type': _typeLabel(m['movement_type'] as String?),
          'Quantity': qty.toStringAsFixed(2),
          'Unit': m['unit_type']?.toString() ?? 'kg',
          'Balance After': (m['balance_after'] as num?)?.toStringAsFixed(2) ?? '0.00',
          'Reference ID': m['reference_id']?.toString() ?? '',
          'Reference Type': m['reference_type']?.toString() ?? '',
          'Reason': m['reason']?.toString() ?? '',
          'Staff': staff?['full_name']?.toString() ?? 'System',
          'Notes': m['notes']?.toString() ?? '',
        };
      }).toList();

      final fromStr = DateFormat('yyyyMMdd').format(_dateFrom);
      final toStr = DateFormat('yyyyMMdd').format(_dateTo);
      final fileName = 'stock_movements_${fromStr}_$toStr.csv';

      final path = await ExportService().saveCsvToFile(
        suggestedFileName: fileName,
        data: rows,
        columns: [
          'Date',
          'PLU',
          'Product Name',
          'Movement Type',
          'Quantity',
          'Unit',
          'Balance After',
          'Reference ID',
          'Reference Type',
          'Reason',
          'Staff',
          'Notes'
        ],
      );

      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV exported: $path'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _exportPdf() async {
    try {
      final pdf = pw.Document();

      // Get business name
      String businessName = 'Struisbaai Vleismark';
      try {
        final biz = await _client
            .from('business_settings')
            .select('setting_value')
            .eq('setting_key', 'business_name')
            .maybeSingle();
        if (biz != null && biz['setting_value'] != null) {
          businessName = biz['setting_value'].toString();
        }
      } catch (_) {}

      final dateRange = '${DateFormat('dd/MM/yyyy').format(_dateFrom)} - ${DateFormat('dd/MM/yyyy').format(_dateTo)}';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => [
            // Header
            pw.Text(businessName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('STOCK MOVEMENTS REPORT', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.Text('Period: $dateRange', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(height: 12),

            // Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Text('Movements: ${_movements.length}', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Stock In: +${_stockIn.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Stock Out: -${_stockOut.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Net Change: ${_netChange >= 0 ? '+' : ''}${_netChange.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Table
            pw.Table.fromTextArray(
              headers: ['Date', 'PLU', 'Product', 'Type', 'Qty', 'Unit', 'Bal', 'Ref ID', 'Staff'],
              data: _movements.map((m) {
                final item = m['inventory_items'] as Map<String, dynamic>?;
                final staff = m['profiles'] as Map<String, dynamic>?;
                final qty = (m['quantity'] as num?)?.toDouble() ?? 0;
                final productName = item?['name']?.toString() ?? 'Unknown';
                final staffName = staff?['full_name']?.toString() ?? 'System';
                final refId = m['reference_id']?.toString() ?? '';

                return [
                  DateFormat('dd/MM HH:mm').format(DateTime.parse(m['created_at'])),
                  item?['plu_code']?.toString() ?? '-',
                  productName.length > 25 ? '${productName.substring(0, 25)}...' : productName,
                  _typeLabel(m['movement_type'] as String?),
                  qty.toStringAsFixed(2),
                  m['unit_type']?.toString() ?? 'kg',
                  (m['balance_after'] as num?)?.toStringAsFixed(1) ?? '0.0',
                  refId.length > 12 ? '${refId.substring(0, 12)}...' : refId,
                  staffName.length > 15 ? '${staffName.substring(0, 15)}...' : staffName,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7),
              cellStyle: const pw.TextStyle(fontSize: 6),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellHeight: 14,
            ),
          ],
          footer: (context) => pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Text(
              'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())} by ${_auth.currentStaffName}',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
            ),
          ),
        ),
      );

      final dir = await getDownloadsDirectory();
      if (dir == null) throw Exception('Downloads directory not available');

      final fromStr = DateFormat('yyyyMMdd').format(_dateFrom);
      final toStr = DateFormat('yyyyMMdd').format(_dateTo);
      final fileName = 'stock_movements_${fromStr}_$toStr.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF saved: ${file.path}'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showExportMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Export Stock Movements'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart, color: AppColors.primary),
              title: const Text('CSV'),
              onTap: () {
                Navigator.pop(context);
                _exportCsv();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: AppColors.danger),
              title: const Text('PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportPdf();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMovementDetails(Map<String, dynamic> movement) {
    final item = movement['inventory_items'] as Map<String, dynamic>?;
    final staff = movement['profiles'] as Map<String, dynamic>?;
    final qty = (movement['quantity'] as num?)?.toDouble() ?? 0;
    final photoUrl = movement['photo_url'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Movement Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),
              _detailRow('Date/Time', DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(movement['created_at']))),
              _detailRow('Product', '${item?['plu_code'] ?? '-'} — ${item?['name'] ?? 'Unknown Product'}'),
              _detailRow('Movement Type', _typeLabel(movement['movement_type'] as String?)),
              _detailRow('Quantity', '${qty.toStringAsFixed(2)} ${movement['unit_type'] ?? 'kg'}'),
              _detailRow('Balance After', (movement['balance_after'] as num?)?.toStringAsFixed(2) ?? '0.00'),
              if (movement['reference_id'] != null)
                _detailRow('Reference ID', movement['reference_id'].toString()),
              if (movement['reference_type'] != null)
                _detailRow('Reference Type', movement['reference_type'].toString()),
              if (movement['reason'] != null && (movement['reason'] as String).isNotEmpty)
                _detailRow('Reason', movement['reason'].toString()),
              _detailRow('Staff', staff?['full_name']?.toString() ?? 'System'),
              if (movement['location_from'] != null)
                _detailRow('Location From', movement['location_from'].toString()),
              if (movement['location_to'] != null)
                _detailRow('Location To', movement['location_to'].toString()),
              if (movement['notes'] != null && (movement['notes'] as String).isNotEmpty)
                _detailRow('Notes', movement['notes'].toString()),
              _detailRow('Created At', DateTime.parse(movement['created_at']).toLocal().toString()),
              if (photoUrl != null && photoUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Photo:', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    photoUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: AppColors.border,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: AppColors.border,
                      child: const Center(child: Text('Image not available')),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Stock Movements'),
        backgroundColor: AppColors.cardBg,
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: AppColors.primary),
            onPressed: _showExportMenu,
            tooltip: 'Export',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter section
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.cardBg,
            child: Column(
              children: [
                // Row 1: Date range + Search
                Row(
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                      label: Text('${DateFormat('dd MMM').format(_dateFrom)} - ${DateFormat('dd MMM').format(_dateTo)}'),
                      onPressed: _pickDateRange,
                      backgroundColor: AppColors.scaffoldBg,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search product or PLU...',
                          prefixIcon: Icon(Icons.search, size: 20),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Row 2: Type filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Wrap(
                    spacing: 6,
                    children: [
                      _typeFilterChip('All', 'all'),
                      _typeFilterChip('In', 'in'),
                      _typeFilterChip('Out', 'out'),
                      _typeFilterChip('Adjustment', 'adjustment'),
                      _typeFilterChip('Waste', 'waste'),
                      _typeFilterChip('Sponsorship', 'sponsorship'),
                      _typeFilterChip('Production', 'production'),
                      _typeFilterChip('Transfer', 'transfer'),
                      _typeFilterChip('Donation', 'donation'),
                      _typeFilterChip('Staff Meal', 'staff_meal'),
                      _typeFilterChip('Freezer', 'freezer'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Summary card
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _statTile('Movements', _movements.length.toString(), Icons.list_alt),
                _statTile('Stock In', '+${_stockIn.toStringAsFixed(2)}', Icons.arrow_downward, color: Colors.green),
                _statTile('Stock Out', '-${_stockOut.toStringAsFixed(2)}', Icons.arrow_upward, color: Colors.red),
                _statTile(
                  'Net Change',
                  '${_netChange >= 0 ? '+' : ''}${_netChange.toStringAsFixed(2)}',
                  Icons.trending_flat,
                  color: _netChange >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ),

          // Count text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Showing ${_movements.length} movements',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Data table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _movements.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.swap_vert_circle_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            const Text('No movements found', style: TextStyle(fontSize: 16, color: AppColors.textPrimary)),
                            const Text(
                              'Try adjusting your filters or date range',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                child: _buildDataTable(),
                              ),
                            ),
                          ),
                          if (_allMovements.length >= _pageSize) ...[
                            const Divider(height: 1, color: AppColors.border),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Center(
                                child: _isLoadingMore
                                    ? const CircularProgressIndicator(color: AppColors.primary)
                                    : TextButton.icon(
                                        onPressed: _loadMore,
                                        icon: const Icon(Icons.download),
                                        label: const Text('Load more'),
                                      ),
                              ),
                            ),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _typeFilterChip(String label, String value) {
    final isSelected = _selectedTypes.contains(value);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _toggleTypeFilter(value),
      backgroundColor: AppColors.scaffoldBg,
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon, {Color? color}) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color ?? AppColors.textSecondary),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(AppColors.cardBg),
      dataRowColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.hovered) ? AppColors.scaffoldBg : AppColors.cardBg;
      }),
      border: TableBorder.all(color: AppColors.border, width: 0.5),
      columnSpacing: 12,
      horizontalMargin: 12,
      columns: const [
        DataColumn(label: Text('Date/Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        DataColumn(label: Text('PLU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        DataColumn(label: Text('Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        DataColumn(label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
        DataColumn(label: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        DataColumn(label: Text('Bal After', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
        DataColumn(label: Text('Reference', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        DataColumn(label: Text('Staff', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        DataColumn(label: Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
      ],
      rows: _movements.map((m) => _buildDataRow(m)).toList(),
    );
  }

  DataRow _buildDataRow(Map<String, dynamic> movement) {
    final item = movement['inventory_items'] as Map<String, dynamic>?;
    final staff = movement['profiles'] as Map<String, dynamic>?;
    final qty = (movement['quantity'] as num?)?.toDouble() ?? 0;
    final type = movement['movement_type'] as String?;

    return DataRow(
      onSelectChanged: (_) => _showMovementDetails(movement),
      cells: [
        DataCell(
          SizedBox(
            width: 110,
            child: Text(DateFormat('dd MMM HH:mm').format(DateTime.parse(movement['created_at'])), style: const TextStyle(fontSize: 11)),
          ),
        ),
        DataCell(
          SizedBox(
            width: 55,
            child: Center(child: Text(item?['plu_code']?.toString() ?? '-', style: const TextStyle(fontSize: 11))),
          ),
        ),
        DataCell(
          SizedBox(
            width: 180,
            child: Text(
              item?['name']?.toString() ?? 'Unknown Product',
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 115,
            child: Chip(
              label: Text(_typeLabel(type), style: const TextStyle(color: Colors.white, fontSize: 11)),
              backgroundColor: _typeColor(type),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 85,
            child: Text(
              '${qty >= 0 ? '+' : ''}${qty.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 11, color: qty >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 55,
            child: Center(child: Text(movement['unit_type']?.toString() ?? 'kg', style: const TextStyle(fontSize: 11))),
          ),
        ),
        DataCell(
          SizedBox(
            width: 85,
            child: Text(
              (movement['balance_after'] as num?)?.toStringAsFixed(2) ?? '0.00',
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.right,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 110,
            child: Text(
              _truncate(movement['reference_id']?.toString() ?? '', 15),
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 120,
            child: Text(
              staff?['full_name']?.toString() ?? 'System',
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 140,
            child: Text(
              _truncate(movement['notes']?.toString() ?? '', 20),
              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
