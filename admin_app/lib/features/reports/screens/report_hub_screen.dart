import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/core/services/export_service.dart';
import 'package:admin_app/features/reports/models/report_data.dart';
import 'package:admin_app/features/reports/models/report_definition.dart';
import 'package:admin_app/features/reports/models/report_schedule.dart';
import 'package:admin_app/features/reports/services/report_repository.dart';
import 'package:admin_app/features/reports/screens/timecard_report_screen.dart';

/// Blueprint §11: Report hub — real data, export CSV/PDF/Excel, scheduling structure.
class ReportHubScreen extends StatefulWidget {
  const ReportHubScreen({super.key});

  @override
  State<ReportHubScreen> createState() => _ReportHubScreenState();
}

class _ReportHubScreenState extends State<ReportHubScreen> {
  final _repo = ReportRepository();
  final _export = ExportService();
  bool _isLoadingView = false;
  bool _isExporting = false;
  String _selectedCategory = 'All Reports';
  DateTime _rangeStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _rangeEnd = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  DateTime _singleDate = DateTime.now();

  List<ReportDefinition> get _filteredReports {
    var list = ReportDefinitions.all;
    if (_selectedCategory != 'All Reports') {
      list = list.where((r) => r.category == _selectedCategory).toList();
    }
    return list;
  }

  Future<void> _viewReport(ReportDefinition def) async {
    if (def.key == 'timecard_report') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const TimecardReportScreen()));
      return;
    }

    // Show filter dialog first — data loads only when user presses Run
    final filters = await showDialog<_ReportFilters>(
      context: context,
      builder: (_) => _ReportFilterDialog(
        def: def,
        initialStart: _rangeStart,
        initialEnd: _rangeEnd,
        initialSingleDate: _singleDate,
      ),
    );
    if (filters == null || !mounted) return; // user cancelled

    // Update global date range to match what was run
    setState(() {
      _rangeStart = filters.start;
      _rangeEnd = filters.end;
      _singleDate = filters.singleDate;
    });

    setState(() => _isLoadingView = true);
    try {
      final reportData = await _repo.getReportData(
        def.key,
        filters.start,
        filters.end,
        singleDate: def.key == 'daily_sales' ? filters.singleDate : null,
        staffId: filters.staffId,
        paymentMethod: filters.paymentMethod,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => _ReportPreviewDialog(data: reportData),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ErrorHandler.friendlyMessage(e)),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoadingView = false);
    }
  }

  Future<void> _exportReport(ReportDefinition def, String format) async {
    if (def.key == 'timecard_report') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const TimecardReportScreen()));
      return;
    }

    setState(() => _isExporting = true);
    try {
      final start = def.requiresDateRange ? _rangeStart : _singleDate;
      final end = def.requiresDateRange ? _rangeEnd : _singleDate;
      final reportData = await _repo.getReportData(
        def.key, start, end,
        singleDate: def.key == 'daily_sales' ? _singleDate : null,
      );
      final isEmpty = reportData.data.isEmpty;

      final safeTitle = def.title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_');
      final dateTag =
          '${start.toIso8601String().substring(0, 10)}_'
          '${end.toIso8601String().substring(0, 10)}';
      final fileName = '${safeTitle}_$dateTag';

      if (format == 'csv') {
        // CSV: Windows Save As dialog / Downloads on other platforms
        final path = await _export.saveCsvToFile(
          suggestedFileName: '$fileName.csv',
          data: reportData.data,
          columns: reportData.columns,
        );
        if (mounted && path != null) {
          final shortName = path.split(RegExp(r'[/\\]')).last;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isEmpty
                ? 'No data for this period — empty CSV saved: $shortName'
                : 'CSV saved: $shortName'),
            backgroundColor: AppColors.success,
          ));
        }
        return;
      }

      // PDF and Excel: show Save As dialog on Windows, Downloads elsewhere
      if (format == 'pdf') {
        // Build the PDF bytes first
        final pdfFile = await _export.exportToPdf(
          fileName: fileName,
          title: reportData.title,
          data: reportData.data,
          columns: reportData.columns,
          columnHeaders: reportData.columnHeaders,
          subtitle: reportData.subtitle,
          summary: reportData.summary,
        );

        if (Platform.isWindows) {
          // Show Save As dialog so the user picks the location
          final savePath = await FilePicker.platform.saveFile(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
            fileName: '$fileName.pdf',
          );
          if (savePath != null) {
            final dest = File(savePath);
            await dest.writeAsBytes(await pdfFile.readAsBytes());
            // Open PDF in default viewer
            await Process.run('cmd', ['/c', 'start', '', dest.path]);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(isEmpty
                    ? 'No data — PDF saved to ${dest.path.split(r'\').last}'
                    : 'PDF saved and opened'),
                backgroundColor: AppColors.success,
              ));
            }
          }
        } else {
          // Non-Windows: open directly from temp location
          final filePath = pdfFile.path;
          await Process.run('open', [filePath]); // macOS
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(isEmpty ? 'No data for this period' : 'PDF opened'),
              backgroundColor: AppColors.success,
            ));
          }
        }
        return;
      }

      if (format == 'xlsx') {
        final xlsxFile = await _export.exportToExcel(
          fileName: fileName,
          data: reportData.data,
          columns: reportData.columns,
          columnHeaders: reportData.columnHeaders,
          sheetName: def.title.length > 31
              ? def.title.substring(0, 31)
              : def.title,
        );

        if (Platform.isWindows) {
          final savePath = await FilePicker.platform.saveFile(
            type: FileType.custom,
            allowedExtensions: ['xlsx'],
            fileName: '$fileName.xlsx',
          );
          if (savePath != null) {
            final dest = File(savePath);
            await dest.writeAsBytes(await xlsxFile.readAsBytes());
            await Process.run('cmd', ['/c', 'start', '', dest.path]);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(isEmpty
                    ? 'No data — Excel saved to ${dest.path.split(r'\').last}'
                    : 'Excel saved and opened'),
                backgroundColor: AppColors.success,
              ));
            }
          }
        } else {
          await Process.run('open', [xlsxFile.path]);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(isEmpty ? 'No data for this period' : 'Excel opened'),
              backgroundColor: AppColors.success,
            ));
          }
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ErrorHandler.friendlyMessage(e)),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _pickDateRange() async {
    final start = await showDatePicker(
      context: context,
      initialDate: _rangeStart,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (start == null || !mounted) return;
    final end = await showDatePicker(
      context: context,
      initialDate: _rangeEnd.isBefore(start) ? start : _rangeEnd,
      firstDate: start,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (end != null && mounted) setState(() { _rangeStart = start; _rangeEnd = end; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.cardBg,
            child: Row(
              children: [
                const Text('Reports & Exports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 24),
                TextButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text('${_rangeStart.day}/${_rangeStart.month}/${_rangeStart.year} – ${_rangeEnd.day}/${_rangeEnd.month}/${_rangeEnd.year}'),
                ),
                const Spacer(),
                if (_isExporting) const Padding(padding: EdgeInsets.only(right: 16), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                ElevatedButton.icon(
                  onPressed: () => _openScheduleConfig(context),
                  icon: const Icon(Icons.schedule, size: 18),
                  label: const Text('Schedule'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 250,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: ReportDefinitions.categories.map((cat) => _sidebarItem(cat)).toList(),
                  ),
                ),
                const VerticalDivider(width: 1, color: AppColors.border),
                Expanded(
                  child: _isLoadingView
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : GridView.extent(
                          padding: const EdgeInsets.all(24),
                          maxCrossAxisExtent: 340,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.45,
                          children: _filteredReports.map((def) => _reportCard(def)).toList(),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(String label) {
    final isSelected = _selectedCategory == label;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
      onTap: () => setState(() => _selectedCategory = label),
    );
  }

  Widget _reportCard(ReportDefinition def) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(def.icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(def.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              ],
            ),
            Text(def.frequency, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoadingView ? null : () => _viewReport(def),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('View'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  tooltip: 'Export report',
                  onSelected: (val) => _exportReport(def, val),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'pdf', child: ListTile(leading: Icon(Icons.picture_as_pdf), title: Text('PDF'))),
                    const PopupMenuItem(value: 'csv', child: ListTile(leading: Icon(Icons.table_chart), title: Text('CSV'))),
                    const PopupMenuItem(value: 'xlsx', child: ListTile(leading: Icon(Icons.grid_on), title: Text('Excel (.xlsx)'))),
                  ],
                  enabled: !_isExporting,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download, color: Colors.white, size: 20),
                        SizedBox(width: 6),
                        Text('Export', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        SizedBox(width: 2),
                        Icon(Icons.arrow_drop_down, color: Colors.white, size: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openScheduleConfig(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Automated Report Schedule'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Blueprint §11.3: When reports run and where they are delivered.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ...DefaultReportSchedules.blueprint.map((s) => ListTile(
                    leading: const Icon(Icons.schedule, color: AppColors.primary),
                    title: Text(s.description),
                    subtitle: Text(
                      '${ReportDefinitions.byKey(s.reportKey)?.title ?? s.reportKey} → ${s.delivery.map((d) => d.name).join(', ')}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  )),
              const Divider(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add schedule (backend/cron)'),
              ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}

/// Holds filter values returned by _ReportFilterDialog.
class _ReportFilters {
  final DateTime start;
  final DateTime end;
  final DateTime singleDate;
  final String? staffId;
  final String? paymentMethod;

  const _ReportFilters({
    required this.start,
    required this.end,
    required this.singleDate,
    this.staffId,
    this.paymentMethod,
  });
}

/// Per-report filter dialog. Shows relevant filters then
/// returns _ReportFilters when user presses Run Report.
class _ReportFilterDialog extends StatefulWidget {
  final ReportDefinition def;
  final DateTime initialStart;
  final DateTime initialEnd;
  final DateTime initialSingleDate;

  const _ReportFilterDialog({
    required this.def,
    required this.initialStart,
    required this.initialEnd,
    required this.initialSingleDate,
  });

  @override
  State<_ReportFilterDialog> createState() => _ReportFilterDialogState();
}

class _ReportFilterDialogState extends State<_ReportFilterDialog> {
  late DateTime _start;
  late DateTime _end;
  late DateTime _singleDate;
  String? _staffId;
  String? _paymentMethod;

  // Staff list for reports that filter by staff
  List<Map<String, dynamic>> _staffList = [];
  bool _loadingStaff = false;

  // Reports that need a staff dropdown
  static const _staffFilterReports = {
    'staff_hours', 'payroll', 'blockman_performance',
    'staff_loan_credit', 'awol', 'bcea_compliance',
  };

  // Reports that use a single date instead of a range
  static const _singleDateReports = {'daily_sales'};

  bool get _needsStaff =>
      _staffFilterReports.contains(widget.def.key);
  bool get _isSingleDate =>
      _singleDateReports.contains(widget.def.key);
  bool get _needsPaymentFilter =>
      widget.def.key == 'daily_sales' ||
      widget.def.key == 'weekly_sales';

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
    _singleDate = widget.initialSingleDate;
    if (_needsStaff) _loadStaffList();
  }

  Future<void> _loadStaffList() async {
    setState(() => _loadingStaff = true);
    try {
      final rows = await Supabase.instance.client
          .from('staff_profiles')
          .select('id, full_name')
          .eq('is_active', true)
          .order('full_name');
      if (mounted) {
        setState(() {
          _staffList = List<Map<String, dynamic>>.from(rows);
        });
      }
    } catch (_) {
      // Leave empty — user can still run without filter
    } finally {
      if (mounted) setState(() => _loadingStaff = false);
    }
  }

  Future<void> _pickStart() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null && mounted) setState(() => _start = d);
  }

  Future<void> _pickEnd() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _end.isBefore(_start) ? _start : _end,
      firstDate: _start,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null && mounted) setState(() => _end = d);
  }

  Future<void> _pickSingleDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _singleDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null && mounted) setState(() => _singleDate = d);
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Icon(widget.def.icon,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(widget.def.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
            const Text('Set filters',
                style: TextStyle(
                    color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── Date filter ──────────────────────────────
            if (_isSingleDate) ...[
              const Text('Date',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _pickSingleDate,
                icon: const Icon(Icons.calendar_today,
                    size: 16),
                label: Text(_fmt(_singleDate)),
              ),
            ] else ...[
              const Text('Date Range',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const SizedBox(height: 6),
              Row(children: [
                OutlinedButton.icon(
                  onPressed: _pickStart,
                  icon: const Icon(Icons.calendar_today,
                      size: 16),
                  label: Text('From: ${_fmt(_start)}'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _pickEnd,
                  icon: const Icon(Icons.calendar_today,
                      size: 16),
                  label: Text('To: ${_fmt(_end)}'),
                ),
              ]),
            ],

            // ── Staff filter ─────────────────────────────
            if (_needsStaff) ...[
              const SizedBox(height: 16),
              const Text('Staff Member',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const SizedBox(height: 6),
              _loadingStaff
                  ? const SizedBox(
                      height: 36,
                      child: Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2)))
                  : DropdownButtonFormField<String>(
                      initialValue: _staffId,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10),
                      ),
                      hint: const Text('All staff'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All staff'),
                        ),
                        ..._staffList.map((s) =>
                            DropdownMenuItem<String>(
                              value: s['id']
                                  ?.toString(),
                              child: Text(
                                  s['full_name']
                                          ?.toString() ??
                                      '—'),
                            )),
                      ],
                      onChanged: (v) =>
                          setState(() => _staffId = v),
                    ),
            ],

            // ── Payment method filter ────────────────────
            if (_needsPaymentFilter) ...[
              const SizedBox(height: 16),
              const Text('Payment Method',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod ?? '',
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                items: const [
                  DropdownMenuItem(
                      value: '',
                      child: Text('All methods')),
                  DropdownMenuItem(
                      value: 'cash',
                      child: Text('Cash')),
                  DropdownMenuItem(
                      value: 'card',
                      child: Text('Card')),
                  DropdownMenuItem(
                      value: 'account',
                      child: Text('Account')),
                  DropdownMenuItem(
                      value: 'eft',
                      child: Text('EFT')),
                ],
                onChanged: (v) => setState(
                    () => _paymentMethod =
                        (v == null || v.isEmpty)
                            ? null
                            : v),
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(
            context,
            _ReportFilters(
              start: _start,
              end: _end,
              singleDate: _singleDate,
              staffId: _staffId,
              paymentMethod: _paymentMethod,
            ),
          ),
          icon: const Icon(Icons.play_arrow, size: 18),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white),
          label: const Text('Run Report'),
        ),
      ],
    );
  }
}

class _ReportPreviewDialog extends StatelessWidget {
  final ReportData data;
  const _ReportPreviewDialog({required this.data});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(
        locale: 'en_ZA', symbol: 'R ', decimalDigits: 2);

    final headers =
        data.columns.map((c) => data.columnHeaders[c] ?? c).toList();

    // Build totals row for monetary columns (only if data is non-empty)
    Map<String, double>? totals;
    if (data.data.isNotEmpty && data.monetaryColumns.isNotEmpty) {
      totals = {};
      for (final col in data.monetaryColumns) {
        totals[col] = data.data.fold<double>(
            0, (s, r) => s + ((r[col] as num?)?.toDouble() ?? 0));
      }
    }

    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      titlePadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.assessment_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(data.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
            if (data.subtitle != null)
              Text(data.subtitle!,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
      content: SizedBox(
        width: 720,
        height: 520,
        child: Column(
          children: [
            // ── Table area ──────────────────────────────────────
            Expanded(
              child: data.data.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 48, color: AppColors.textLight),
                          SizedBox(height: 8),
                          Text('No data for this range.',
                              style:
                                  TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: Table(
                          defaultColumnWidth:
                              const IntrinsicColumnWidth(),
                          border: TableBorder(
                            horizontalInside: BorderSide(
                                color: AppColors.border, width: 0.5),
                            bottom: BorderSide(
                                color: AppColors.border, width: 0.5),
                          ),
                          children: [
                            // Header row
                            TableRow(
                              decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.08)),
                              children: headers
                                  .map((h) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                        child: Text(h,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: AppColors.textPrimary)),
                                      ))
                                  .toList(),
                            ),
                            // Data rows (max 100)
                            ...data.data.take(100).toList().asMap().entries.map(
                              (entry) {
                                final i = entry.key;
                                final row = entry.value;
                                return TableRow(
                                  decoration: BoxDecoration(
                                    color: i.isEven
                                        ? AppColors.cardBg
                                        : AppColors.surfaceBg,
                                  ),
                                  children: data.columns.map((col) {
                                    final isMoney =
                                        data.monetaryColumns.contains(col);
                                    final raw = row[col];
                                    final display = isMoney
                                        ? (raw == null
                                            ? '—'
                                            : currencyFmt.format(
                                                (raw as num).toDouble()))
                                        : '${raw ?? ""}';
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      child: Text(
                                        display,
                                        textAlign: isMoney
                                            ? TextAlign.right
                                            : TextAlign.left,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                            // Totals row
                            if (totals != null)
                              TableRow(
                                decoration: BoxDecoration(
                                  color: AppColors.accent
                                      .withValues(alpha: 0.12),
                                ),
                                children: data.columns.map((col) {
                                  final t = totals![col];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 9),
                                    child: Text(
                                      t != null
                                          ? currencyFmt.format(t)
                                          : (col == data.columns.first
                                              ? 'TOTAL'
                                              : ''),
                                      textAlign: data.monetaryColumns
                                              .contains(col)
                                          ? TextAlign.right
                                          : TextAlign.left,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ),
            ),

            // ── Summary tiles ────────────────────────────────────
            if (data.summary != null && data.summary!.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceBg,
                  border: Border(
                      top: BorderSide(color: AppColors.border)),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: data.summary!.entries.map((e) {
                    final valStr = e.value is double
                        ? currencyFmt.format(e.value as double)
                        : '${e.value}';
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.key,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary)),
                          Text(valStr,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            // ── Footer ───────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.cardBg,
                border:
                    Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Text(
                    data.data.isEmpty
                        ? 'No records'
                        : data.data.length > 100
                            ? 'Showing 100 of ${data.data.length} records'
                            : '${data.data.length} record${data.data.length == 1 ? "" : "s"}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
