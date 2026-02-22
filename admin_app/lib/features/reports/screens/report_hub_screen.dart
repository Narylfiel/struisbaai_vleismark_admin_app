import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/export_service.dart';
import 'package:admin_app/features/reports/models/report_data.dart';
import 'package:admin_app/features/reports/models/report_definition.dart';
import 'package:admin_app/features/reports/models/report_schedule.dart';
import 'package:admin_app/features/reports/services/report_repository.dart';

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
    setState(() => _isLoadingView = true);
    try {
      final start = def.requiresDateRange ? _rangeStart : _singleDate;
      final end = def.requiresDateRange ? _rangeEnd : _singleDate;
      final reportData = await _repo.getReportData(def.key, start, end, singleDate: def.key == 'daily_sales' ? _singleDate : null);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => _ReportPreviewDialog(data: reportData),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingView = false);
    }
  }

  Future<void> _exportReport(ReportDefinition def, String format) async {
    setState(() => _isExporting = true);
    try {
      final start = def.requiresDateRange ? _rangeStart : _singleDate;
      final end = def.requiresDateRange ? _rangeEnd : _singleDate;
      final reportData = await _repo.getReportData(def.key, start, end, singleDate: def.key == 'daily_sales' ? _singleDate : null);
      final safeTitle = def.title.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
      final fileName = '${safeTitle}_${start.toIso8601String().substring(0, 10)}_${end.toIso8601String().substring(0, 10)}';
      File file;
      if (format == 'csv') {
        file = await _export.exportToCsv(
          fileName: fileName,
          data: reportData.data,
          columns: reportData.columns,
        );
      } else if (format == 'xlsx') {
        file = await _export.exportToExcel(
          fileName: fileName,
          data: reportData.data,
          columns: reportData.columns,
          columnHeaders: reportData.columnHeaders,
          sheetName: def.title.length > 31 ? def.title.substring(0, 31) : def.title,
        );
      } else {
        file = await _export.exportToPdf(
          fileName: fileName,
          title: reportData.title,
          data: reportData.data,
          columns: reportData.columns,
          columnHeaders: reportData.columnHeaders,
          subtitle: reportData.subtitle,
          summary: reportData.summary,
        );
      }
      if (mounted) {
        try {
          await Share.shareXFiles([XFile(file.path)], text: '${def.title} export');
        } catch (_) { /* share not supported */ }
        if (mounted) {
          final dir = await getApplicationDocumentsDirectory();
          final shortPath = file.path.startsWith(dir.path) ? file.path.substring(dir.path.length) : file.path;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exported. Save via dialog or find in: $shortPath'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.error),
        );
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

class _ReportPreviewDialog extends StatelessWidget {
  final ReportData data;

  const _ReportPreviewDialog({required this.data});

  @override
  Widget build(BuildContext context) {
    final headers = data.columns.map((c) => data.columnHeaders[c] ?? c).toList();
    return AlertDialog(
      title: Text(data.title),
      content: SizedBox(
        width: 640,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (data.subtitle != null) Text(data.subtitle!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            Expanded(
              child: data.data.isEmpty
                  ? const Center(child: Text('No data for this range.'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: headers.map((h) => DataColumn(label: Text(h, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                          rows: data.data.take(100).map((row) {
                            return DataRow(
                              cells: data.columns.map((col) => DataCell(Text('${row[col] ?? ""}'))).toList(),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ),
            if (data.summary != null && data.summary!.isNotEmpty) ...[
              const Divider(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: data.summary!.entries.map((e) => Chip(label: Text('${e.key}: ${e.value}'))).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    );
  }
}
