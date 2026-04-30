import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/export_service.dart';
import 'package:admin_app/features/hr/services/staff_profile_repository.dart';
import 'package:admin_app/features/hr/services/timecard_repository.dart';

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
      final rows = (await StaffProfileRepository(client: _client)
          .getAll(isActive: true))
          .where((r) => r['can_clock_in'] == true)
          .toList();
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
      final timeRepo = TimecardRepository(client: _client);
      final timecards = await timeRepo.getAll(
        staffId: _selectedStaffId,
        from: _fromDate,
        to: _toDate,
      );

      final staffIds = timecards
          .map((t) => t['staff_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      // Match original server-side filter: staff_profiles.can_clock_in = true
      final canClockInByStaffId = <String, bool>{};
      if (staffIds.isNotEmpty) {
        final staffRows = (await StaffProfileRepository(client: _client)
            .getAll(isActive: null))
            .where((r) => staffIds.contains(r['id']?.toString()))
            .toList();

        for (final row in staffRows) {
          final id = row['id']?.toString();
          if (id == null) continue;
          canClockInByStaffId[id] = (row['can_clock_in'] as bool?) ?? false;
        }
      }

      final data = timecards
          .where((tc) => canClockInByStaffId[tc['staff_id']?.toString()] == true)
          .map((tc) {
            final staffProfiles = tc['staff_profiles'];
            final fullName =
                (staffProfiles is Map ? staffProfiles['full_name'] : null) as String?;
            final staffId = tc['staff_id']?.toString();
            final canClockIn = staffId != null ? canClockInByStaffId[staffId] ?? false : false;

            final rawBreaks = tc['timecard_breaks'];
              final breaks = (rawBreaks is List)
                  ? (rawBreaks.cast<Map<String, dynamic>>()
                      ..sort((a, b) =>
                          (a['break_start'] as String? ?? '')
                              .compareTo(b['break_start'] as String? ?? '')))
                  : <Map<String, dynamic>>[];
              return <String, dynamic>{
              'shift_date': tc['shift_date'],
              'clock_in': tc['clock_in'],
              'clock_out': tc['clock_out'],
              'total_hours': tc['total_hours'],
              'break_minutes': tc['break_minutes'],
              'status': tc['status'],
              'staff_id': tc['staff_id'],
              'timecard_breaks': breaks,
              'staff_profiles': {
                'full_name': fullName,
                'can_clock_in': canClockIn,
              },
            };
          })
          .toList();
      
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

  String _fmtDate(String? dt) {
    if (dt == null) return '—';
    final d = DateTime.parse(dt).toLocal();
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day.toString().padLeft(2,'0')} ${months[d.month-1]}';
  }

  static const _hS = TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.bold,
      color: AppColors.textSecondary,
      letterSpacing: 0.4,
      height: 1.3);

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
            child: const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(width: 80,  child: Text('DATE',      style: _hS)),
                  SizedBox(width: 8),
                  SizedBox(width: 110, child: Text('STAFF',     style: _hS)),
                  SizedBox(width: 8),
                  SizedBox(width: 68,  child: Text('CLOCK IN',  style: _hS)),
                  SizedBox(width: 8),
                  SizedBox(width: 56,  child: Text('BRK 1\nOUT', style: _hS)),
                  SizedBox(width: 4),
                  SizedBox(width: 56,  child: Text('BRK 1\nIN',  style: _hS)),
                  SizedBox(width: 8),
                  SizedBox(width: 56,  child: Text('BRK 2\nOUT', style: _hS)),
                  SizedBox(width: 4),
                  SizedBox(width: 56,  child: Text('BRK 2\nIN',  style: _hS)),
                  SizedBox(width: 8),
                  SizedBox(width: 56,  child: Text('BRK 3\nOUT', style: _hS)),
                  SizedBox(width: 4),
                  SizedBox(width: 56,  child: Text('BRK 3\nIN',  style: _hS)),
                  SizedBox(width: 8),
                  SizedBox(width: 68,  child: Text('CLOCK OUT', style: _hS)),
                  SizedBox(width: 8),
                  SizedBox(width: 64,  child: Text('TOTAL BRK', style: _hS)),
                  SizedBox(width: 8),
                  SizedBox(width: 64,  child: Text('TOTAL HRS', style: _hS)),
                  SizedBox(width: 8),
                  SizedBox(width: 80,  child: Text('STATUS',    style: _hS)),
                ],
              ),
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
                      final clockIn = r['clock_in'] != null
                          ? () { final d = DateTime.parse(r['clock_in'].toString()).toUtc().add(const Duration(hours: 2)); return '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}'; }()
                          : '—';
                      final clockOut = r['clock_out'] != null
                          ? () { final d = DateTime.parse(r['clock_out'].toString()).toUtc().add(const Duration(hours: 2)); return '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}'; }()
                          : '—';
                      final totalHrs = (r['total_hours'] as num?)?.toDouble() ?? 0.0;
                      final breakMins = (r['break_minutes'] as num?)?.toInt() ?? 0;
                      
                      final breaks = (r['timecard_breaks'] as List?)
                              ?.cast<Map<String, dynamic>>() ??
                          [];

                      String brkTime(int idx, String field) {
                        if (idx >= breaks.length) return '—';
                        final val = breaks[idx][field] as String?;
                        if (val == null) return '—';
                        final dt = DateTime.tryParse(val)?.toLocal();
                        if (dt == null) return '—';
                        return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
                      }

                      final isOpen = r['clock_out'] == null;
                      final longBreak = breakMins > 60;

                      return Container(
                        color: longBreak
                            ? AppColors.error.withValues(alpha: 0.04)
                            : Colors.transparent,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 9),
                            child: Row(children: [
                              SizedBox(width: 80,
                                child: Text(
                                  r['shift_date'] != null
                                      ? _fmtDate(r['clock_in'])
                                      : '—',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(width: 110,
                                child: Text(staffName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(width: 68, child: Text(clockIn,
                                  style: const TextStyle(fontSize: 13))),
                              const SizedBox(width: 8),
                              // BRK 1 OUT
                              SizedBox(width: 56, child: Text(
                                brkTime(0, 'break_start'),
                                style: TextStyle(fontSize: 12,
                                    color: breaks.isNotEmpty
                                        ? AppColors.textPrimary
                                        : AppColors.border),
                                textAlign: TextAlign.center)),
                              const SizedBox(width: 4),
                              // BRK 1 IN
                              SizedBox(width: 56, child: Text(
                                brkTime(0, 'break_end'),
                                style: TextStyle(fontSize: 12,
                                    color: breaks.isNotEmpty
                                        ? AppColors.textPrimary
                                        : AppColors.border),
                                textAlign: TextAlign.center)),
                              const SizedBox(width: 8),
                              // BRK 2 OUT
                              SizedBox(width: 56, child: Text(
                                brkTime(1, 'break_start'),
                                style: TextStyle(fontSize: 12,
                                    color: breaks.length > 1
                                        ? AppColors.textPrimary
                                        : AppColors.border),
                                textAlign: TextAlign.center)),
                              const SizedBox(width: 4),
                              // BRK 2 IN
                              SizedBox(width: 56, child: Text(
                                brkTime(1, 'break_end'),
                                style: TextStyle(fontSize: 12,
                                    color: breaks.length > 1
                                        ? AppColors.textPrimary
                                        : AppColors.border),
                                textAlign: TextAlign.center)),
                              const SizedBox(width: 8),
                              // BRK 3 OUT
                              SizedBox(width: 56, child: Text(
                                brkTime(2, 'break_start'),
                                style: TextStyle(fontSize: 12,
                                    color: breaks.length > 2
                                        ? AppColors.textPrimary
                                        : AppColors.border),
                                textAlign: TextAlign.center)),
                              const SizedBox(width: 4),
                              // BRK 3 IN
                              SizedBox(width: 56, child: Text(
                                brkTime(2, 'break_end'),
                                style: TextStyle(fontSize: 12,
                                    color: breaks.length > 2
                                        ? AppColors.textPrimary
                                        : AppColors.border),
                                textAlign: TextAlign.center)),
                              const SizedBox(width: 8),
                              // CLOCK OUT
                              SizedBox(width: 68,
                                child: Text(
                                  isOpen ? '● Active' : clockOut,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: isOpen
                                          ? AppColors.success
                                          : AppColors.textPrimary,
                                      fontWeight: isOpen
                                          ? FontWeight.bold
                                          : FontWeight.normal)),
                              ),
                              const SizedBox(width: 8),
                              // TOTAL BREAK
                              SizedBox(width: 64,
                                child: Text(
                                  breakMins > 0 ? '${breakMins}m' : '—',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: longBreak
                                          ? AppColors.error
                                          : breakMins > 0
                                              ? AppColors.info
                                              : AppColors.textSecondary)),
                              ),
                              const SizedBox(width: 8),
                              // TOTAL HRS
                              SizedBox(width: 64,
                                child: Text(
                                  '${totalHrs.toStringAsFixed(1)}h',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                              ),
                              const SizedBox(width: 8),
                              // STATUS
                              SizedBox(width: 80,
                                child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: _buildStatusChip(r['status']))),
                            ]),
                          ),
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
