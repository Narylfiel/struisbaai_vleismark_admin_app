import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/responsive/responsive_breakpoints.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/core/services/export_service.dart';
import 'package:admin_app/features/hr/services/staff_profile_repository.dart';
import 'package:admin_app/features/reports/models/report_data.dart';
import 'package:admin_app/features/reports/models/report_definition.dart';
import 'package:admin_app/features/reports/services/report_repository.dart';
import 'package:admin_app/features/reports/screens/timecard_report_screen.dart';
import 'package:admin_app/features/reports/screens/report_schedule_screen.dart';

/// Blueprint §11: Report hub — real data, export CSV/PDF/Excel, scheduling structure.
class ReportHubScreen extends StatefulWidget {
  const ReportHubScreen({super.key, this.initialReportKey});

  /// When set (e.g. dashboard alert fallback), opens that report’s run flow once after first frame.
  final String? initialReportKey;

  @override
  State<ReportHubScreen> createState() => _ReportHubScreenState();
}

class _ReportHubScreenState extends State<ReportHubScreen> {
  final _repo = ReportRepository();
  final _export = ExportService();
  bool _isLoadingView = false;
  bool _isExporting = false;
  bool _didConsumeInitialReportKey = false;
  String _selectedCategory = 'All Reports';
  DateTime _rangeStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _rangeEnd = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  DateTime _singleDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final key = widget.initialReportKey;
    if (key != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || _didConsumeInitialReportKey) return;
        _didConsumeInitialReportKey = true;
        final def = ReportDefinitions.byKey(key);
        if (def == null) return;
        await _viewReport(def);
      });
    }
  }

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
        } else if (Platform.isAndroid || Platform.isIOS) {
          await Share.shareXFiles([XFile(pdfFile.path)]);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(isEmpty ? 'No data for this period' : 'PDF shared'),
              backgroundColor: AppColors.success,
            ));
          }
        } else {
          // Non-Windows desktop fallback
          final filePath = pdfFile.path;
          await Process.run('open', [filePath]);
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
        } else if (Platform.isAndroid || Platform.isIOS) {
          await Share.shareXFiles([XFile(xlsxFile.path)]);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(isEmpty ? 'No data for this period' : 'Excel shared'),
              backgroundColor: AppColors.success,
            ));
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                final dateButton = TextButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text('${_rangeStart.day}/${_rangeStart.month}/${_rangeStart.year} – ${_rangeEnd.day}/${_rangeEnd.month}/${_rangeEnd.year}'),
                );
                final scheduleButton = ElevatedButton.icon(
                  onPressed: () => _openScheduleConfig(context),
                  icon: const Icon(Icons.schedule, size: 18),
                  label: const Text('Schedule'),
                );
                if (isWide) {
                  return Row(
                    children: [
                      const Text('Reports & Exports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      dateButton,
                      const Spacer(),
                      if (_isExporting) const Padding(padding: EdgeInsets.only(right: 16), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                      scheduleButton,
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Reports & Exports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _pickDateRange,
                        style: TextButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          '${_rangeStart.day}/${_rangeStart.month}/${_rangeStart.year} – ${_rangeEnd.day}/${_rangeEnd.month}/${_rangeEnd.year}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (_isExporting)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        Expanded(child: scheduleButton),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mobile = constraints.maxWidth < 600;
                final grid = _isLoadingView
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : GridView.extent(
                        padding: const EdgeInsets.all(24),
                        maxCrossAxisExtent: 340,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.45,
                        children: _filteredReports.map((def) => _reportCard(def)).toList(),
                      );
                if (!mobile) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 250,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children:
                              ReportDefinitions.categories.map((cat) => _sidebarItem(cat)).toList(),
                        ),
                      ),
                      const VerticalDivider(width: 1, color: AppColors.border),
                      Expanded(child: grid),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: ReportDefinitions.categories
                            .map((c) => DropdownMenuItem<String>(
                                  value: c,
                                  child: Text(c, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _selectedCategory = v);
                        },
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    Expanded(child: grid),
                  ],
                );
              },
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
            LayoutBuilder(
              builder: (context, cardConstraints) {
                final stackActions = cardConstraints.maxWidth < 260;
                final exportMenu = PopupMenuButton<String>(
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
                );
                final viewBtn = OutlinedButton.icon(
                  onPressed: _isLoadingView ? null : () => _viewReport(def),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('View'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                );
                if (stackActions) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      viewBtn,
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.center, child: exportMenu),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: viewBtn),
                    const SizedBox(width: 8),
                    exportMenu,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openScheduleConfig(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReportScheduleScreen()),
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
      final rows = await StaffProfileRepository(client: Supabase.instance.client)
          .getAll(isActive: true);
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
    final maxContentW =
        ResponsiveBreakpoints.dialogContentMaxWidth(context, desktopMax: 440);

    Widget dateRangePickers(BoxConstraints constraints) {
      final stackVertically = constraints.maxWidth < 400;
      if (stackVertically) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: _pickStart,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text('From: ${_fmt(_start)}'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pickEnd,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text('To: ${_fmt(_end)}'),
            ),
          ],
        );
      }
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pickStart,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text('From: ${_fmt(_start)}', overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pickEnd,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text('To: ${_fmt(_end)}', overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      );
    }

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(widget.def.icon,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.def.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Set filters',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentW),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                  bottom: math.max(8, MediaQuery.viewInsetsOf(context).bottom)),
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
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _pickSingleDate,
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_fmt(_singleDate)),
                      ),
                    ),
                  ] else ...[
                    const Text('Date Range',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    const SizedBox(height: 6),
                    dateRangePickers(constraints),
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
                            isExpanded: true,
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
                      isExpanded: true,
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
            );
          },
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actionsOverflowAlignment: OverflowBarAlignment.end,
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

/// Preview helper line: aligns user expectations with CONTROL vs REALITY vs MONITORING.
/// Keys are [ReportData.title] values from [ReportDefinitions].
enum _ReportPreviewContext {
  real,
  configured,
  mixed,
  placeholder,
  inventoryValuation,
}

/// Reports that currently use the repository default empty payload — show [placeholder] copy only when [ReportData.data] is empty.
const Set<String> _kPlaceholderEmptyReportTitles = {
  'Equipment Depreciation Schedule',
  'Purchase Sale Agreement History',
  'Blockman Performance Report',
  'Event / Holiday Forecast Report',
  'Sponsorship & Donations Log',
};

const Map<String, _ReportPreviewContext> _kReportPreviewContextByTitle = {
  'Pricing Intelligence': _ReportPreviewContext.mixed,
};

_ReportPreviewContext _reportPreviewContextFor(ReportData data) {
  if (_kPlaceholderEmptyReportTitles.contains(data.title) &&
      data.data.isEmpty) {
    return _ReportPreviewContext.placeholder;
  }
  if (data.title == 'Inventory Valuation') {
    return _ReportPreviewContext.inventoryValuation;
  }
  return _kReportPreviewContextByTitle[data.title] ??
      _ReportPreviewContext.real;
}

class _ReportPreviewContextBanner extends StatelessWidget {
  const _ReportPreviewContextBanner({required this.data});

  final ReportData data;

  @override
  Widget build(BuildContext context) {
    final kind = _reportPreviewContextFor(data);
    final text = switch (kind) {
      _ReportPreviewContext.real =>
        'This report shows actual performance based on real sales and current costs.',
      _ReportPreviewContext.configured =>
        'This view is based on configured pricing and cost settings, not actual sales.',
      _ReportPreviewContext.mixed =>
        'This combines configured pricing with real sales data to highlight performance gaps.',
      _ReportPreviewContext.placeholder =>
        'This report is not yet active or has no data available.',
      _ReportPreviewContext.inventoryValuation =>
        'This view shows stock value based on configured cost prices, not real costs (WAC).',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
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
    final size = MediaQuery.sizeOf(context);
    final isPhone = ResponsiveBreakpoints.isPhoneLayout(context);
    final contentW =
        isPhone ? (size.width - 36).clamp(280.0, size.width) : math.min(720.0, size.width - 64);
    final contentH =
        isPhone ? (size.height * 0.72).clamp(320.0, size.height * 0.88) : 520.0;

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
      insetPadding: isPhone
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 24)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.assessment_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  if (data.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(data.subtitle!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: contentW,
        height: contentH,
        child: Column(
          children: [
            _ReportPreviewContextBanner(data: data),
            if (data.alerts != null && data.alerts!.isNotEmpty)
              _ReportAlertsPanel(alerts: data.alerts!),
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
                          border: const TableBorder(
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
              child: LayoutBuilder(
                builder: (context, c) {
                  final stackFooter = c.maxWidth < 320;
                  final countText = Text(
                    data.data.isEmpty
                        ? 'No records'
                        : data.data.length > 100
                            ? 'Showing 100 of ${data.data.length} records'
                            : '${data.data.length} record${data.data.length == 1 ? "" : "s"}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  );
                  final closeBtn = TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  );
                  if (stackFooter) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        countText,
                        const SizedBox(height: 6),
                        Align(alignment: Alignment.centerRight, child: closeBtn),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: countText),
                      closeBtn,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pricing / profitability alerts (read-only); shown above the report table.
class _ReportAlertsPanel extends StatelessWidget {
  const _ReportAlertsPanel({required this.alerts});

  final List<Map<String, dynamic>> alerts;

  @override
  Widget build(BuildContext context) {
    final high =
        alerts.where((a) => a['severity'] == 'high').toList();
    final medium =
        alerts.where((a) => a['severity'] == 'medium').toList();

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        border: const Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.notifications_active_outlined,
                    size: 18, color: AppColors.warning),
                SizedBox(width: 8),
                Text(
                  'Automated alerts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (high.isNotEmpty) ...[
              const Text(
                'High severity',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 4),
              ...high.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    '• ${a['message'] ?? ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              if (medium.isNotEmpty) const SizedBox(height: 8),
            ],
            if (medium.isNotEmpty) ...[
              const Text(
                'Medium severity',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 4),
              ...medium.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    '• ${a['message'] ?? ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
