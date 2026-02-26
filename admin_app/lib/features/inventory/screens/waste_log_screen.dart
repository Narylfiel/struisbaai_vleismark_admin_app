import 'dart:io';
import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/auth_service.dart';
import 'package:admin_app/core/services/audit_service.dart';
import 'package:admin_app/core/services/export_service.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Waste Log — view and record waste/sponsorship stock movements.
/// 
/// Records waste and sponsorship movements, tracks shrinkage alerts,
/// and provides export capabilities for compliance reporting.
class WasteLogScreen extends StatefulWidget {
  const WasteLogScreen({super.key});

  @override
  State<WasteLogScreen> createState() => _WasteLogScreenState();
}

class _WasteLogScreenState extends State<WasteLogScreen> {
  final _client = SupabaseService.client;
  final _auth = AuthService();

  List<Map<String, dynamic>> _movements = [];
  List<Map<String, dynamic>> _filteredMovements = [];
  bool _isLoading = true;

  // Filters
  DateTime _dateFrom = DateTime.now().subtract(const Duration(days: 30));
  DateTime _dateTo = DateTime.now();
  String _typeFilter = 'All'; // 'All' | 'Waste Only' | 'Sponsorship Only'
  String _searchQuery = '';

  // Summary stats
  int _totalEntries = 0;
  double _wasteValue = 0;
  double _sponsorshipValue = 0;
  String _wastePercentage = 'N/A';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Query stock_movements with joins
      // Pattern confirmed: table_name(columns) for joins
      final response = await _client
          .from('stock_movements')
          .select('''
            id, item_id, movement_type, quantity, unit_type,
            balance_after, reason, staff_id, photo_url, notes,
            reference_type, reference_id, created_at,
            inventory_items(plu_code, name, cost_price),
            profiles(full_name)
          ''')
          .inFilter('movement_type', ['waste', 'sponsorship'])
          .gte('created_at', _dateFrom.toIso8601String())
          .lte('created_at', _dateTo.toIso8601String())
          .order('created_at', ascending: false);

      _movements = List<Map<String, dynamic>>.from(response);
      _applyFilters();
      await _calculateStats();
    } catch (e) {
      debugPrint('Waste log load error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredMovements = _movements.where((m) {
        // Type filter
        final type = m['movement_type'] as String?;
        final matchType = _typeFilter == 'All' ||
            (_typeFilter == 'Waste Only' && type == 'waste') ||
            (_typeFilter == 'Sponsorship Only' && type == 'sponsorship');

        // Search filter
        final item = m['inventory_items'] as Map<String, dynamic>?;
        final pluCode = item?['plu_code']?.toString() ?? '';
        final name = item?['name']?.toString() ?? '';
        final query = _searchQuery.toLowerCase();
        final matchSearch = query.isEmpty ||
            pluCode.contains(query) ||
            name.toLowerCase().contains(query);

        return matchType && matchSearch;
      }).toList();

      _totalEntries = _filteredMovements.length;
    });
  }

  Future<void> _calculateStats() async {
    // Calculate waste and sponsorship values
    double wasteVal = 0;
    double sponsorshipVal = 0;

    for (final m in _filteredMovements) {
      final qty = ((m['quantity'] as num?)?.toDouble() ?? 0).abs();
      final item = m['inventory_items'] as Map<String, dynamic>?;
      final costPrice = (item?['cost_price'] as num?)?.toDouble() ?? 0;
      final value = qty * costPrice;

      if (m['movement_type'] == 'waste') {
        wasteVal += value;
      } else if (m['movement_type'] == 'sponsorship') {
        sponsorshipVal += value;
      }
    }

    // Calculate waste percentage
    try {
      final wasteQty = _movements
          .where((m) => m['movement_type'] == 'waste')
          .fold<double>(0, (sum, m) => sum + ((m['quantity'] as num?)?.toDouble() ?? 0).abs());

      final receiveResponse = await _client
          .from('stock_movements')
          .select('quantity')
          .eq('movement_type', 'receive')
          .gte('created_at', _dateFrom.toIso8601String())
          .lte('created_at', _dateTo.toIso8601String());

      final receiveQty = (receiveResponse as List).fold<double>(
        0,
        (sum, m) => sum + ((m['quantity'] as num?)?.toDouble() ?? 0),
      );

      if (receiveQty > 0) {
        final wastePct = (wasteQty / receiveQty * 100);
        _wastePercentage = '${wastePct.toStringAsFixed(1)}%';
      } else {
        _wastePercentage = 'N/A';
      }
    } catch (e) {
      debugPrint('Waste % calc error: $e');
      _wastePercentage = 'N/A';
    }

    setState(() {
      _wasteValue = wasteVal;
      _sponsorshipValue = sponsorshipVal;
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

  Future<void> _exportCsv() async {
    try {
      final rows = _filteredMovements.map((m) {
        final item = m['inventory_items'] as Map<String, dynamic>?;
        final staff = m['staff_profiles'] as Map<String, dynamic>?;
        final qty = (m['quantity'] as num?)?.toDouble() ?? 0;
        final costPrice = (item?['cost_price'] as num?)?.toDouble() ?? 0;
        final estValue = qty.abs() * costPrice;

        return {
          'Date': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(m['created_at'])),
          'PLU': item?['plu_code']?.toString() ?? '',
          'Product': item?['name']?.toString() ?? '',
          'Type': m['movement_type'] == 'waste' ? 'Waste' : 'Sponsorship',
          'Reason': m['reason']?.toString() ?? '',
          'Quantity': qty.toStringAsFixed(2),
          'Unit': m['unit_type']?.toString() ?? 'kg',
          'Est Value (R)': estValue.toStringAsFixed(2),
          'Staff': staff?['full_name']?.toString() ?? '',
          'Notes': m['notes']?.toString() ?? '',
        };
      }).toList();

      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final fileName = 'waste_log_${DateFormat('yyyy-MM-dd').format(_dateFrom)}_${DateFormat('yyyy-MM-dd').format(_dateTo)}';
      
      final path = await ExportService().saveCsvToFile(
        suggestedFileName: '$fileName.csv',
        data: rows,
        columns: ['Date', 'PLU', 'Product', 'Type', 'Reason', 'Quantity', 'Unit', 'Est Value (R)', 'Staff', 'Notes'],
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
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Header
            pw.Text(businessName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('WASTE LOG REPORT', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text('Period: $dateRange', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 16),
            
            // Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Summary', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Text('Total Entries: $_totalEntries', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Waste Value: R ${_wasteValue.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Sponsorship Value: R ${_sponsorshipValue.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Waste %: $_wastePercentage', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            
            // Table
            pw.Table.fromTextArray(
              headers: ['Date', 'PLU', 'Product', 'Type', 'Qty', 'Unit', 'Value (R)', 'Reason'],
              data: _filteredMovements.map((m) {
                final item = m['inventory_items'] as Map<String, dynamic>?;
                final qty = (m['quantity'] as num?)?.toDouble() ?? 0;
                final costPrice = (item?['cost_price'] as num?)?.toDouble() ?? 0;
                final estValue = qty.abs() * costPrice;
                
                return [
                  DateFormat('dd/MM HH:mm').format(DateTime.parse(m['created_at'])),
                  item?['plu_code']?.toString() ?? '',
                  item?['name']?.toString() ?? '',
                  m['movement_type'] == 'waste' ? 'W' : 'S',
                  qty.toStringAsFixed(2),
                  m['unit_type']?.toString() ?? 'kg',
                  estValue.toStringAsFixed(2),
                  m['reason']?.toString() ?? '',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
              cellStyle: const pw.TextStyle(fontSize: 7),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellHeight: 18,
            ),
          ],
          footer: (context) => pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Text(
              'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())} by ${_auth.currentStaffName}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ),
        ),
      );

      final dir = await getDownloadsDirectory();
      if (dir == null) throw Exception('Downloads directory not available');
      
      final fileName = 'waste_log_${DateFormat('yyyy-MM-dd').format(_dateFrom)}_${DateFormat('yyyy-MM-dd').format(_dateTo)}.pdf';
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
        title: const Text('Export Waste Log'),
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
    final costPrice = (item?['cost_price'] as num?)?.toDouble() ?? 0;
    final estValue = qty.abs() * costPrice;
    final type = movement['movement_type'] as String?;
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
              Text(
                type == 'waste' ? 'Waste Entry Details' : 'Sponsorship Entry Details',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),
              _detailRow('Date/Time', DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(movement['created_at']))),
              _detailRow('Product', '${item?['plu_code'] ?? ''} — ${item?['name'] ?? 'Unknown'}'),
              _detailRow('Type', type == 'waste' ? 'Waste' : 'Sponsorship'),
              _detailRow('Reason', movement['reason']?.toString() ?? '-'),
              _detailRow('Quantity', '${qty.toStringAsFixed(2)} ${movement['unit_type'] ?? 'kg'}'),
              _detailRow('Estimated Value', 'R ${estValue.toStringAsFixed(2)}'),
              _detailRow('Staff', staff?['full_name']?.toString() ?? '-'),
              if (movement['notes'] != null && (movement['notes'] as String).isNotEmpty)
                _detailRow('Notes', movement['notes'].toString()),
              if (movement['reference_id'] != null)
                _detailRow('Reference', '${movement['reference_type'] ?? ''}: ${movement['reference_id']}'),
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
            width: 120,
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

  void _openRecordWasteDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _RecordWasteDialog(onSaved: _loadData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          // Top bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.cardBg,
            child: Row(
              children: [
                const Text(
                  'Waste Log',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.file_download, color: AppColors.primary),
                  onPressed: _showExportMenu,
                  tooltip: 'Export',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Filter row
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.cardBg,
            child: Row(
              children: [
                // Date range chip
                ActionChip(
                  avatar: const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                  label: Text('${DateFormat('dd MMM').format(_dateFrom)} - ${DateFormat('dd MMM').format(_dateTo)}'),
                  onPressed: _pickDateRange,
                  backgroundColor: AppColors.scaffoldBg,
                ),
                const SizedBox(width: 8),
                
                // Type filter dropdown
                Flexible(
                  child: DropdownButtonFormField<String>(
                    value: _typeFilter,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All')),
                      DropdownMenuItem(value: 'Waste Only', child: Text('Waste Only')),
                      DropdownMenuItem(value: 'Sponsorship Only', child: Text('Sponsorship Only')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _typeFilter = v);
                        _applyFilters();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                
                // Search field
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search product or PLU...',
                      prefixIcon: Icon(Icons.search, size: 20),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      setState(() => _searchQuery = v);
                      _applyFilters();
                    },
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
                _statTile('Entries', _totalEntries.toString(), Icons.list_alt),
                _statTile('Waste Value', 'R ${_wasteValue.toStringAsFixed(2)}', Icons.delete_outline, color: AppColors.danger),
                _statTile('Sponsorship Value', 'R ${_sponsorshipValue.toStringAsFixed(2)}', Icons.favorite_border, color: Colors.blue),
                _statTile('Waste %', _wastePercentage, Icons.trending_down, color: AppColors.warning),
              ],
            ),
          ),

          // Data list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _filteredMovements.isEmpty
                    ? const Center(
                        child: Text(
                          'No waste or sponsorship entries found',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _filteredMovements.length,
                        itemBuilder: (context, index) => _buildMovementCard(_filteredMovements[index]),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openRecordWasteDialog,
        backgroundColor: AppColors.danger,
        child: const Icon(Icons.add, color: Colors.white),
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

  Widget _buildMovementCard(Map<String, dynamic> movement) {
    final item = movement['inventory_items'] as Map<String, dynamic>?;
    final staff = movement['profiles'] as Map<String, dynamic>?;
    final qty = (movement['quantity'] as num?)?.toDouble() ?? 0;
    final costPrice = (item?['cost_price'] as num?)?.toDouble() ?? 0;
    final estValue = qty.abs() * costPrice;
    final type = movement['movement_type'] as String?;
    final isWaste = type == 'waste';
    final photoUrl = movement['photo_url'] as String?;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.cardBg,
      child: InkWell(
        onTap: () => _showMovementDetails(movement),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Left side
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('dd MMM HH:mm').format(DateTime.parse(movement['created_at'])),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item?['name']?.toString() ?? 'Unknown',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    Text(
                      'PLU ${item?['plu_code'] ?? '-'}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      movement['reason']?.toString() ?? '-',
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              // Center - Type chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isWaste ? AppColors.danger : Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isWaste ? 'Waste' : 'Sponsorship',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),

              // Right side
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${qty.toStringAsFixed(2)} ${movement['unit_type'] ?? 'kg'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isWaste ? AppColors.danger : Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R ${estValue.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  if (hasPhoto) ...[
                    const SizedBox(height: 4),
                    const Icon(Icons.camera_alt, size: 14, color: AppColors.primary),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// RECORD WASTE DIALOG
// ═══════════════════════════════════════════════════════

class _RecordWasteDialog extends StatefulWidget {
  final VoidCallback onSaved;

  const _RecordWasteDialog({required this.onSaved});

  @override
  State<_RecordWasteDialog> createState() => _RecordWasteDialogState();
}

class _RecordWasteDialogState extends State<_RecordWasteDialog> {
  final _client = SupabaseService.client;
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _products = [];
  Map<String, dynamic>? _selectedProduct;
  String _selectedType = 'Waste';
  final _quantityController = TextEditingController();
  String? _selectedReason;
  DateTime _selectedDate = DateTime.now();
  final _notesController = TextEditingController();
  XFile? _selectedPhoto;
  bool _isSaving = false;
  bool _isLoading = true;

  // Reason options
  final List<String> _wasteReasons = ['Expired', 'Spoiled', 'Trim Loss', 'Damaged', 'Other'];
  final List<String> _sponsorshipReasons = ['Community Sponsorship', 'Staff Donation', 'Event', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final response = await _client
          .from('inventory_items')
          .select('id, plu_code, name, cost_price, unit_type')
          .eq('is_active', true)
          .order('name');
      
      setState(() {
        _products = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load products error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (photo != null) {
        setState(() => _selectedPhoto = photo);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product'), backgroundColor: AppColors.warning),
      );
      return;
    }
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      final qty = double.parse(_quantityController.text);
      if (qty <= 0) {
        throw Exception('Quantity must be positive');
      }

      // Upload photo if selected
      // NOTE: Supabase Storage bucket 'waste-photos' must be created in Supabase dashboard
      String? photoUrl;
      if (_selectedPhoto != null) {
        try {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'waste_${timestamp}_${_selectedProduct!['id']}.jpg';
          final bytes = await _selectedPhoto!.readAsBytes();
          
          await _client.storage.from('waste-photos').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: 'image/jpeg'),
          );
          
          photoUrl = _client.storage.from('waste-photos').getPublicUrl(fileName);
        } catch (e) {
          debugPrint('Photo upload error: $e');
          // Continue without photo
        }
      }

      // Get current balance_after (latest movement for this item)
      double balanceAfter = 0;
      try {
        final latest = await _client
            .from('stock_movements')
            .select('balance_after')
            .eq('item_id', _selectedProduct!['id'])
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        
        if (latest != null) {
          balanceAfter = (latest['balance_after'] as num?)?.toDouble() ?? 0;
        }
      } catch (e) {
        debugPrint('Balance fetch error: $e');
      }

      // STEP 1: Insert stock_movements
      final movementType = _selectedType == 'Waste' ? 'waste' : 'sponsorship';
      final movementData = {
        'item_id': _selectedProduct!['id'],
        'movement_type': movementType,
        'quantity': -qty, // Always negative
        'unit_type': _selectedProduct!['unit_type'],
        'balance_after': balanceAfter - qty,
        'reason': _selectedReason,
        'staff_id': _auth.currentStaffId,
        'photo_url': photoUrl,
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        'reference_type': 'manual_waste',
        'created_at': _selectedDate.toIso8601String(),
      };

      final result = await _client
          .from('stock_movements')
          .insert(movementData)
          .select()
          .single();

      // STEP 2: Check shrinkage threshold (waste only)
      if (movementType == 'waste') {
        await _checkShrinkageThreshold(
          productId: _selectedProduct!['id'],
          productName: _selectedProduct!['name'],
          enteredQty: qty,
          reason: _selectedReason!,
          currentBalance: balanceAfter - qty,
        );
      }

      // STEP 3: Audit log
      final costPrice = (_selectedProduct!['cost_price'] as num?)?.toDouble() ?? 0;
      final estValue = qty * costPrice;
      await AuditService.log(
        action: 'CREATE',
        module: 'Inventory',
        description: '${_selectedType}: ${qty.toStringAsFixed(2)} ${_selectedProduct!['unit_type']} x ${_selectedProduct!['name']} — $_selectedReason',
        entityType: 'StockMovement',
        entityId: result['id'],
      );

      // STEP 4: Success feedback
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              movementType == 'waste'
                  ? 'Waste recorded — R ${estValue.toStringAsFixed(2)} value written off'
                  : 'Sponsorship recorded — R ${estValue.toStringAsFixed(2)} donated',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Save waste error: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _checkShrinkageThreshold({
    required String productId,
    required String productName,
    required double enteredQty,
    required String reason,
    required double currentBalance,
  }) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      // Calculate 30-day waste
      final wasteResp = await _client
          .from('stock_movements')
          .select('quantity')
          .eq('item_id', productId)
          .eq('movement_type', 'waste')
          .gte('created_at', thirtyDaysAgo.toIso8601String());
      
      final wasteSum = (wasteResp as List).fold<double>(
        0,
        (sum, m) => sum + ((m['quantity'] as num?)?.toDouble() ?? 0).abs(),
      );

      // Calculate 30-day receive
      final receiveResp = await _client
          .from('stock_movements')
          .select('quantity')
          .eq('item_id', productId)
          .eq('movement_type', 'receive')
          .gte('created_at', thirtyDaysAgo.toIso8601String());
      
      final receiveSum = (receiveResp as List).fold<double>(
        0,
        (sum, m) => sum + ((m['quantity'] as num?)?.toDouble() ?? 0),
      );

      if (receiveSum <= 0) return; // No receive data, skip alert

      final shrinkagePct = (wasteSum / receiveSum * 100);

      // Get threshold from business_settings
      double threshold = 2.0; // Default
      try {
        final settings = await _client
            .from('business_settings')
            .select('setting_value')
            .eq('setting_key', 'shrinkage_threshold_percent')
            .maybeSingle();
        
        if (settings != null && settings['setting_value'] != null) {
          threshold = double.tryParse(settings['setting_value'].toString()) ?? 2.0;
        }
      } catch (e) {
        debugPrint('Threshold fetch error (using default 2.0%): $e');
      }

      // Create alert if over threshold
      if (shrinkagePct > threshold) {
        await _client.from('shrinkage_alerts').insert({
          'item_id': productId,
          'product_id': productId,
          'item_name': productName,
          'alert_date': DateTime.now().toIso8601String().substring(0, 10),
          'alert_type': 'waste_threshold',
          'status': 'open',
          'actual_qty': currentBalance,
          'gap_amount': enteredQty,
          'gap_percentage': shrinkagePct,
          'shrinkage_percentage': shrinkagePct,
          'possible_reasons': reason,
          'acknowledged': false,
          'resolved': false,
        });
      }
    } catch (e) {
      debugPrint('Shrinkage check error: $e');
      // Don't block the save
    }
  }

  Future<void> _pickDate() async {
    final minDate = DateTime.now().subtract(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: minDate,
      lastDate: DateTime.now(),
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
      setState(() => _selectedDate = picked);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 400,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final costPriceHint = _selectedProduct != null
        ? 'Cost price: R ${(_selectedProduct!['cost_price'] as num?)?.toStringAsFixed(2) ?? '0.00'} per ${_selectedProduct!['unit_type'] ?? 'unit'}'
        : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.warning_amber, color: AppColors.danger, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Record Waste / Sponsorship',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 1. Product selector
            const Text('Product *', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedProduct,
              decoration: InputDecoration(
                hintText: 'Select product...',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                helperText: costPriceHint,
                helperStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              items: _products.map((p) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: p,
                  child: Text('${p['plu_code']} — ${p['name']}'),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedProduct = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // 2. Type selector
            const Text('Type *', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Waste', label: Text('Waste'), icon: Icon(Icons.delete_outline)),
                ButtonSegment(value: 'Sponsorship', label: Text('Sponsorship'), icon: Icon(Icons.favorite_border)),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedType = newSelection.first;
                  _selectedReason = null; // Reset reason when type changes
                });
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return _selectedType == 'Waste' ? AppColors.danger : Colors.blue;
                  }
                  return AppColors.scaffoldBg;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return AppColors.textPrimary;
                }),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Quantity
            const Text('Quantity *', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                hintText: 'Enter quantity',
                labelText: _selectedProduct != null ? 'Quantity (${_selectedProduct!['unit_type'] ?? 'unit'})' : 'Quantity',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final qty = double.tryParse(v);
                if (qty == null || qty <= 0) return 'Must be positive';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 4. Reason
            const Text('Reason *', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedReason,
              decoration: const InputDecoration(
                hintText: 'Select reason...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: (_selectedType == 'Waste' ? _wasteReasons : _sponsorshipReasons)
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedReason = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // 5. Date
            const Text('Date *', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('dd MMM yyyy').format(_selectedDate),
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 6. Notes
            const Text('Notes (optional)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Additional details...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // 7. Photo
            const Text('Photo (optional)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            if (_selectedPhoto != null) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_selectedPhoto!.path),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(backgroundColor: Colors.black54),
                      onPressed: () => setState(() => _selectedPhoto = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.camera_alt),
              label: Text(_selectedPhoto == null ? 'Attach Photo' : 'Change Photo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedType == 'Waste' ? AppColors.danger : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text('Record ${_selectedType}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
