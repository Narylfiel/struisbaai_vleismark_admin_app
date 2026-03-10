import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/export_service.dart';

class TimecardReportScreen extends StatefulWidget {
  const TimecardReportScreen({super.key});

  @override
  State<TimecardReportScreen> createState() => _TimecardReportScreenState();
}

class _TimecardReportScreenState extends State<TimecardReportScreen> {
  final _client = SupabaseService.client;
  final _export = ExportService();
  
  DateTime _fromDate = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  DateTime _toDate = DateTime.now();
  String? _selectedStaffId;
  
  List<Map<String, dynamic>> _staffList = [];
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = false;
  bool _isExporting = false;
  
  @override
  void initState() {
    super.initState();
    _loadStaff();
    _loadData();
  }

  Future<void> _loadStaff() async {
    try {
      final rows = await _client
          .from('staff_profiles')
          .select('id, full_name')
          .eq('is_active', true)
          .eq('can_clock_in', true)
          .order('full_name');
      if (mounted) {
        setState(() {
          _staffList = List<Map<String, dynamic>>.from(rows);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final fromStr = _fromDate.toIso8601String().substring(0, 10);
      final toStr = _toDate.toIso8601String().substring(0, 10);

      var q = _client.from('timecards')
          .select('shift_date, clock_in, clock_out, total_hours, break_minutes, status, staff_id, staff_profiles!inner(full_name, can_clock_in)')
          .gte('shift_date', fromStr)
          .lte('shift_date', toStr)
          .eq('staff_profiles.can_clock_in', true);

      if (_selectedStaffId != null) {
        q = q.eq('staff_id', _selectedStaffId!);
      }

      final data = await q.order('shift_date', ascending: false);
      
      final list = List<Map<String, dynamic>>.from(data);
      list.sort((a, b) {
        final dateA = a['shift_date'] as String;
        final dateB = b['shift_date'] as String;
        var cmp = dateB.compareTo(dateA); // desc
        if (cmp != 0) return cmp;
        final nameA = (a['staff_profiles']?['full_name'] as String?) ?? '';
        final nameB = (b['staff_profiles']?['full_name'] as String?) ?? '';
        return nameA.compareTo(nameB);
      });

      if (mounted) setState(() => _records = list);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading report: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDateRange() async {
    final DateTime? start = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (start != null && mounted) {
      final DateTime? end = await showDatePicker(
        context: context,
        initialDate: _toDate.isBefore(start) ? start : _toDate,
        firstDate: start,
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (end != null && mounted) {
        setState(() {
          _fromDate = start;
          _toDate = end;
        });
      }
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    try {
      final fromStr = _fromDate.toIso8601String().substring(0, 10);
      final toStr = _toDate.toIso8601String().substring(0, 10);

      final columns = ['Date', 'Staff', 'Clock In', 'Clock Out', 'Total Hrs', 'Break Mins', 'Status'];
      final data = _records.map((r) {
        final staffName = r['staff_profiles']?['full_name'] ?? 'Unknown';
        final clockIn = r['clock_in'] != null ? r['clock_in'].toString().substring(11, 16) : '';
        final clockOut = r['clock_out'] != null ? r['clock_out'].toString().substring(11, 16) : '';
        final totalHrs = (r['total_hours'] as num?)?.toDouble() ?? 0.0;
        final breakMins = (r['break_minutes'] as num?)?.toInt() ?? 0;
        return {
          'Date': r['shift_date'],
          'Staff': staffName,
          'Clock In': clockIn,
          'Clock Out': clockOut,
          'Total Hrs': totalHrs.toStringAsFixed(2),
          'Break Mins': breakMins.toString(),
          'Status': r['status'],
        };
      }).toList();

      final path = await _export.saveCsvToFile(
        suggestedFileName: 'timecards_${fromStr}_$toStr.csv',
        data: data,
        columns: columns,
      );

      if (mounted && path != null) {
        final shortName = path.split(RegExp(r'[/\\]')).last;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data.isEmpty ? 'No data — empty CSV saved: $shortName' : 'CSV saved: $shortName'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Widget _buildStatusChip(String? status) {
    Color bg;
    Color text = Colors.white;
    String label;
    switch (status) {
      case 'clocked_in':
        bg = const Color(0xFFFFB300);
        text = Colors.black;
        label = 'Active';
        break;
      case 'on_break':
        bg = const Color(0xFFE65100);
        label = 'On Break';
        break;
      case 'clocked_out':
        bg = AppColors.success;
        label = 'Complete';
        break;
      default:
        bg = Colors.grey;
        label = status ?? '—';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: text, fontSize: 11)),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalHrsSum = 0;
    int totalBreakMinsSum = 0;
    for (var r in _records) {
      totalHrsSum += (r['total_hours'] as num?)?.toDouble() ?? 0;
      totalBreakMinsSum += (r['break_minutes'] as num?)?.toInt() ?? 0;
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Timecard Report', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (_isExporting)
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
          TextButton.icon(
            onPressed: _isExporting ? null : _exportCsv,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Export CSV'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.cardBg,
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text('${_fromDate.day}/${_fromDate.month}/${_fromDate.year} – ${_toDate.day}/${_toDate.month}/${_toDate.year}'),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedStaffId,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    hint: const Text('All Staff'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Staff')),
                      ..._staffList.map((s) => DropdownMenuItem(value: s['id'] as String?, child: Text(s['full_name']?.toString() ?? ''))),
                    ],
                    onChanged: (v) => setState(() => _selectedStaffId = v),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.surfaceBg,
            child: const Row(
              children: [
                SizedBox(width: 100, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('Staff', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                SizedBox(width: 80, child: Text('Clock In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                SizedBox(width: 80, child: Text('Clock Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                SizedBox(width: 80, child: Text('Total Hrs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                SizedBox(width: 90, child: Text('Break Mins', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                SizedBox(width: 90, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _records.isEmpty
                ? const Center(child: Text('No timecards found for this period', style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _records.length,
                    itemBuilder: (_, i) {
                      final r = _records[i];
                      final staffName = r['staff_profiles']?['full_name'] ?? 'Unknown';
                      final clockIn = r['clock_in'] != null ? r['clock_in'].toString().substring(11, 16) : '—';
                      final clockOut = r['clock_out'] != null ? r['clock_out'].toString().substring(11, 16) : '—';
                      final totalHrs = (r['total_hours'] as num?)?.toDouble() ?? 0.0;
                      final breakMins = (r['break_minutes'] as num?)?.toInt() ?? 0;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            SizedBox(width: 100, child: Text(r['shift_date'] ?? '—')),
                            Expanded(flex: 2, child: Text(staffName, overflow: TextOverflow.ellipsis)),
                            SizedBox(width: 80, child: Text(clockIn)),
                            SizedBox(width: 80, child: Text(clockOut)),
                            SizedBox(width: 80, child: Text('${totalHrs.toStringAsFixed(1)}h', style: const TextStyle(fontWeight: FontWeight.w600))),
                            SizedBox(width: 90, child: Text(breakMins > 0 ? '${breakMins}m' : '—')),
                            SizedBox(width: 90, child: Align(alignment: Alignment.centerLeft, child: _buildStatusChip(r['status']))),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (!_isLoading && _records.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.cardBg,
              child: Row(
                children: [
                  const Text('TOTALS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const Spacer(),
                  Text('Shifts: ${_records.length}  |  Hours: ${totalHrsSum.toStringAsFixed(1)}h  |  Breaks: ${totalBreakMinsSum}m',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
