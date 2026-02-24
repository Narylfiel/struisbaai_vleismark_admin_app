import 'package:admin_app/core/constants/admin_config.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import '../models/awol_record.dart';
import 'awol_repository.dart';

/// Blueprint §7.6: BCEA Compliance — weekly hours, breaks, leave, Sunday work, AWOL flags.
/// Uses real data from timecards, leave_requests, staff_profiles; falls back gracefully if tables empty.
enum ComplianceStatus { ok, warning, error, info }

class ComplianceItem {
  final String id;
  final ComplianceStatus status;
  final String title;
  final String detail;
  final String? staffId;
  final String? staffName;

  const ComplianceItem({
    required this.id,
    required this.status,
    required this.title,
    required this.detail,
    this.staffId,
    this.staffName,
  });
}

/// BCEA (South Africa) constants: Section 9 ordinary 45h/week, Section 10 max 10h OT/week,
/// Section 14 meal interval 30min for 5+ hour shift, Section 20 annual leave 21 days/year.
class _BceaLimits {
  static const double maxOrdinaryHoursPerWeek = 45.0; // BCEA s9
  static const double maxOvertimeHoursPerWeek = 10.0; // BCEA s10
  static const int minBreakMinutesForLongShift = 30;  // BCEA s14
  static const double longShiftHoursThreshold = 5.0;
  static const int annualLeaveDaysPerYear = 21;       // BCEA s20
}

class ComplianceService {
  final AwolRepository _awolRepo;
  final _client = SupabaseService.client;
  static const int _persistentAwolThreshold = 3;

  ComplianceService({AwolRepository? awolRepo}) : _awolRepo = awolRepo ?? AwolRepository();

  /// Build BCEA compliance checklist for the given month from timecards, leave_requests, staff_profiles.
  Future<List<ComplianceItem>> getBceaCompliance(DateTime monthStart) async {
    final items = <ComplianceItem>[];
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);
    final monthStartStr = monthStart.toIso8601String().substring(0, 10);
    final monthEndStr = monthEnd.toIso8601String().substring(0, 10);

    // ─── AWOL: persistent flag (3+ incidents per staff in period) ───
    final awolCounts = await _awolRepo.getAwolCountByStaff(from: monthStart, to: monthEnd);
    final records = await _awolRepo.getRecords(from: monthStart, to: monthEnd);
    final staffNames = {for (var r in records) r.staffId: r.staffName};
    for (final e in awolCounts.entries) {
      if (e.value >= _persistentAwolThreshold) {
        items.add(ComplianceItem(
          id: 'awol_${e.key}',
          status: ComplianceStatus.error,
          title: 'Persistent AWOL',
          detail: '${staffNames[e.key] ?? 'Staff'} — ${e.value} AWOL incidents this period. Consider formal disciplinary process.',
          staffId: e.key,
          staffName: staffNames[e.key],
        ));
      }
    }

    // ─── Weekly working hours (BCEA s9: max 45h ordinary per week) ───
    await _addWeeklyHoursItems(items, monthStart, monthEnd, monthStartStr, monthEndStr);

    // ─── Overtime (BCEA s10: max 10h OT per week) ───
    await _addOvertimeItems(items, monthStart, monthEnd, monthStartStr, monthEndStr);

    // ─── Break compliance (BCEA s14: 30min for 5+ hour shift) ───
    await _addBreakComplianceItems(items, monthStartStr, monthEndStr);

    // ─── Leave usage (BCEA s20: 21 days annual leave; usage from leave_requests) ───
    await _addLeaveItems(items, monthStart, monthEnd, monthStartStr, monthEndStr);

    // ─── Sunday work (BCEA: double pay or alternative day off) ───
    await _addSundayWorkItems(items, monthStartStr, monthEndStr);

    return items;
  }

  /// Group timecards by staff and by week (Monday start); sum total_hours. Flag staff-weeks > 45h.
  Future<void> _addWeeklyHoursItems(
    List<ComplianceItem> items,
    DateTime monthStart,
    DateTime monthEnd,
    String monthStartStr,
    String monthEndStr,
  ) async {
    try {
      final rows = await _client
          .from('timecards')
          .select('staff_id, clock_in, total_hours')
          .gte('clock_in', '${monthStartStr}T00:00:00')
          .lte('clock_in', '${monthEndStr}T23:59:59')
          .not('total_hours', 'is', null);
      final list = List<Map<String, dynamic>>.from(rows);
      if (list.isEmpty) {
        items.add(const ComplianceItem(
          id: 'weekly_hours',
          status: ComplianceStatus.info,
          title: 'Weekly working hour limits',
          detail: 'No timecard data for this month. Limits: max 45h ordinary/week (BCEA s9).',
        ));
        return;
      }
      final staffNames = await _getStaffNames(list.map((r) => r['staff_id'] as String?).whereType<String>().toSet());
      // Group by staff_id and week (Monday = start of week)
      final Map<String, Map<String, double>> staffWeekHours = {};
      for (final r in list) {
        final staffId = r['staff_id'] as String?;
        if (staffId == null) continue;
        final clockIn = r['clock_in'] as String?;
        if (clockIn == null) continue;
        final dt = DateTime.parse(clockIn);
        final weekStart = _weekStartMonday(dt);
        final weekKey = '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
        staffWeekHours.putIfAbsent(staffId, () => {});
        final hours = (r['total_hours'] as num?)?.toDouble() ?? 0;
        staffWeekHours[staffId]![weekKey] = (staffWeekHours[staffId]![weekKey] ?? 0) + hours;
      }
      final over = <String>[];
      for (final e in staffWeekHours.entries) {
        for (final weekEntry in e.value.entries) {
          if (weekEntry.value > _BceaLimits.maxOrdinaryHoursPerWeek) {
            over.add('${staffNames[e.key] ?? e.key} (${weekEntry.value.toStringAsFixed(1)}h in week ${weekEntry.key})');
          }
        }
      }
      if (over.isEmpty) {
        items.add(const ComplianceItem(
          id: 'weekly_hours',
          status: ComplianceStatus.ok,
          title: 'Weekly working hour limits',
          detail: 'All staff within max 45h ordinary/week (BCEA s9).',
        ));
      } else {
        items.add(ComplianceItem(
          id: 'weekly_hours',
          status: ComplianceStatus.warning,
          title: 'Weekly working hour limits',
          detail: 'Over 45h in a week (BCEA s9): ${over.join('; ')}.',
        ));
      }
    } catch (e) {
      items.add(ComplianceItem(
        id: 'weekly_hours',
        status: ComplianceStatus.info,
        title: 'Weekly working hour limits',
        detail: 'Could not load timecards: $e. Max 45h ordinary/week (BCEA s9).',
      ));
    }
  }

  /// Overtime: sum overtime_hours per staff per week; flag if > 10h OT in any week (BCEA s10).
  Future<void> _addOvertimeItems(
    List<ComplianceItem> items,
    DateTime monthStart,
    DateTime monthEnd,
    String monthStartStr,
    String monthEndStr,
  ) async {
    try {
      final rows = await _client
          .from('timecards')
          .select('staff_id, clock_in, overtime_hours')
          .gte('clock_in', '${monthStartStr}T00:00:00')
          .lte('clock_in', '${monthEndStr}T23:59:59');
      final list = List<Map<String, dynamic>>.from(rows);
      if (list.isEmpty) {
        items.add(const ComplianceItem(
          id: 'overtime',
          status: ComplianceStatus.info,
          title: 'Overtime limits',
          detail: 'No timecard data. BCEA s10: max 10h OT per week.',
        ));
        return;
      }
      final Map<String, Map<String, double>> staffWeekOt = {};
      for (final r in list) {
        final staffId = r['staff_id'] as String?;
        if (staffId == null) continue;
        final clockIn = r['clock_in'] as String?;
        if (clockIn == null) continue;
        final weekStart = _weekStartMonday(DateTime.parse(clockIn));
        final weekKey = '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
        staffWeekOt.putIfAbsent(staffId, () => {});
        final ot = (r['overtime_hours'] as num?)?.toDouble() ?? 0;
        staffWeekOt[staffId]![weekKey] = (staffWeekOt[staffId]![weekKey] ?? 0) + ot;
      }
      final staffNames = await _getStaffNames(staffWeekOt.keys.toSet());
      final over = <String>[];
      for (final e in staffWeekOt.entries) {
        for (final weekEntry in e.value.entries) {
          if (weekEntry.value > _BceaLimits.maxOvertimeHoursPerWeek) {
            over.add('${staffNames[e.key] ?? e.key} (${weekEntry.value.toStringAsFixed(1)}h OT in week ${weekEntry.key})');
          }
        }
      }
      if (over.isEmpty) {
        items.add(const ComplianceItem(
          id: 'overtime',
          status: ComplianceStatus.ok,
          title: 'Overtime limits',
          detail: 'OT within max 10h/week (BCEA s10).',
        ));
      } else {
        items.add(ComplianceItem(
          id: 'overtime',
          status: ComplianceStatus.warning,
          title: 'Overtime limits',
          detail: 'OT over 10h in a week (BCEA s10): ${over.join('; ')}.',
        ));
      }
    } catch (_) {
      // Optional: no item if timecards fail (weekly_hours already added info)
    }
  }

  /// Break compliance: shifts >= 5h must have >= 30min break (timecard_breaks if available).
  Future<void> _addBreakComplianceItems(List<ComplianceItem> items, String monthStartStr, String monthEndStr) async {
    try {
      final cards = await _client
          .from('timecards')
          .select('id, staff_id, total_hours')
          .gte('clock_in', '${monthStartStr}T00:00:00')
          .lte('clock_in', '${monthEndStr}T23:59:59');
      final cardList = List<Map<String, dynamic>>.from(cards);
      final longShifts = cardList.where((c) {
        final h = (c['total_hours'] as num?)?.toDouble() ?? 0;
        return h >= _BceaLimits.longShiftHoursThreshold;
      }).toList();
      if (longShifts.isEmpty) {
        items.add(const ComplianceItem(
          id: 'breaks',
          status: ComplianceStatus.ok,
          title: 'Break compliance',
          detail: 'No shifts ≥5h this month; 30+ min break required for 5+ hour shifts (BCEA s14).',
        ));
        return;
      }
      final ids = longShifts.map((c) => c['id'] as String?).whereType<String>().toList();
      if (ids.isEmpty) {
        items.add(const ComplianceItem(
          id: 'breaks',
          status: ComplianceStatus.info,
          title: 'Break compliance',
          detail: '30+ min break for 5+ hour shifts (BCEA s14). Check timecard_breaks when available.',
        ));
        return;
      }
      final breaksRows = await _client
          .from('timecard_breaks')
          .select('timecard_id, break_duration_minutes')
          .inFilter('timecard_id', ids);
      final breaksList = List<Map<String, dynamic>>.from(breaksRows);
      final breakByTimecard = <String, int>{};
      for (final b in breaksList) {
        final tid = b['timecard_id'] as String?;
        if (tid == null) continue;
        final mins = (b['break_duration_minutes'] as num?)?.toInt() ?? 0;
        breakByTimecard[tid] = (breakByTimecard[tid] ?? 0) + mins;
      }
      final short = <String>[];
      for (final c in longShifts) {
        final tid = c['id'] as String?;
        if (tid == null) continue;
        final totalBreak = breakByTimecard[tid] ?? 0;
        if (totalBreak < _BceaLimits.minBreakMinutesForLongShift) {
          short.add('Timecard $tid (${(c['total_hours'] as num?)?.toStringAsFixed(1) ?? '?'}h, ${totalBreak}min break)');
        }
      }
      if (short.isEmpty) {
        items.add(const ComplianceItem(
          id: 'breaks',
          status: ComplianceStatus.ok,
          title: 'Break compliance',
          detail: 'Shifts ≥5h have ≥30min break (BCEA s14).',
        ));
      } else {
        items.add(ComplianceItem(
          id: 'breaks',
          status: ComplianceStatus.warning,
          title: 'Break compliance',
          detail: 'Shifts ≥5h require 30min break (BCEA s14). Short/missing: ${short.take(3).join('; ')}${short.length > 3 ? '...' : ''}.',
        ));
      }
    } catch (_) {
      items.add(const ComplianceItem(
        id: 'breaks',
        status: ComplianceStatus.info,
        title: 'Break compliance',
        detail: '30+ min for 5+ hour shifts (BCEA s14). From timecard_breaks when available.',
      ));
    }
  }

  /// Leave: Approved leave_requests overlapping month; days taken. BCEA 21 days/year.
  Future<void> _addLeaveItems(
    List<ComplianceItem> items,
    DateTime monthStart,
    DateTime monthEnd,
    String monthStartStr,
    String monthEndStr,
  ) async {
    try {
      // Fetch Approved leave that could overlap month (start_date <= monthEnd); filter overlap in Dart (handles null end_date)
      final rows = await _client
          .from('leave_requests')
          .select('*, staff_profiles!staff_id(full_name)')
          .eq('status', 'approved')
          .lte('start_date', monthEndStr);
      var list = List<Map<String, dynamic>>.from(rows);
      list = list.where((r) {
        final end = r['end_date'] != null ? DateTime.tryParse(r['end_date'].toString().substring(0, 10)) : null;
        final effectiveEnd = end ?? DateTime.tryParse(r['start_date']?.toString().substring(0, 10) ?? '');
        return effectiveEnd != null && !effectiveEnd.isBefore(monthStart);
      }).toList();
      if (list.isEmpty) {
        items.add(const ComplianceItem(
          id: 'leave',
          status: ComplianceStatus.ok,
          title: 'Leave balances',
          detail: 'No approved leave in period. BCEA: min 21 days annual leave per year.',
        ));
        return;
      }
      int totalDays = 0;
      final byStaff = <String, int>{};
      for (final r in list) {
        final start = r['start_date'] != null ? DateTime.tryParse(r['start_date'].toString().substring(0, 10)) : null;
        final end = r['end_date'] != null ? DateTime.tryParse(r['end_date'].toString().substring(0, 10)) : null;
        if (start == null || end == null) continue;
        final overlapStart = start.isBefore(monthStart) ? monthStart : start;
        final overlapEnd = end.isAfter(monthEnd) ? monthEnd : end;
        final days = overlapEnd.difference(overlapStart).inDays + 1;
        if (days < 1) continue;
        totalDays += days;
        final staffId = r['staff_id']?.toString();
        if (staffId != null) byStaff[staffId] = (byStaff[staffId] ?? 0) + days;
      }
      final proRataPerMonth = _BceaLimits.annualLeaveDaysPerYear / 12;
      if (totalDays == 0) {
        items.add(const ComplianceItem(
          id: 'leave',
          status: ComplianceStatus.ok,
          title: 'Leave balances',
          detail: 'No approved leave days in period. BCEA: 21 days annual leave/year.',
        ));
        return;
      }
      final staffNames = await _getStaffNames(byStaff.keys.toSet());
      final details = byStaff.entries.map((e) => '${staffNames[e.key] ?? e.key}: ${e.value}d').take(5).join('; ');
      items.add(ComplianceItem(
        id: 'leave',
        status: ComplianceStatus.info,
        title: 'Leave usage',
        detail: '$totalDays days approved leave this month ($details). BCEA: min 21 days annual leave per year.',
      ));
    } catch (e) {
      items.add(ComplianceItem(
        id: 'leave',
        status: ComplianceStatus.warning,
        title: 'Leave balances',
        detail: 'Could not load leave data: $e. Minimum 21 days annual leave per year (BCEA s20).',
      ));
    }
  }

  /// Sunday work: sum sunday_hours per staff; info to confirm double pay (BCEA).
  Future<void> _addSundayWorkItems(List<ComplianceItem> items, String monthStartStr, String monthEndStr) async {
    try {
      final rows = await _client
          .from('timecards')
          .select('staff_id, sunday_hours')
          .gte('clock_in', '${monthStartStr}T00:00:00')
          .lte('clock_in', '${monthEndStr}T23:59:59');
      final list = List<Map<String, dynamic>>.from(rows);
      final staffSunday = <String, double>{};
      for (final r in list) {
        final staffId = r['staff_id'] as String?;
        if (staffId == null) continue;
        final h = (r['sunday_hours'] as num?)?.toDouble() ?? 0;
        if (h > 0) staffSunday[staffId] = (staffSunday[staffId] ?? 0) + h;
      }
      if (staffSunday.isEmpty) {
        items.add(const ComplianceItem(
          id: 'sunday',
          status: ComplianceStatus.ok,
          title: 'Sunday work',
          detail: 'No Sunday hours this month. BCEA: double pay or alternative day off if worked.',
        ));
        return;
      }
      final staffNames = await _getStaffNames(staffSunday.keys.toSet());
      final details = staffSunday.entries.map((e) => '${staffNames[e.key] ?? e.key}: ${e.value.toStringAsFixed(1)}h').join('; ');
      items.add(ComplianceItem(
        id: 'sunday',
        status: ComplianceStatus.info,
        title: 'Sunday work',
        detail: 'Confirm double pay applied (BCEA): $details.',
      ));
    } catch (_) {
      items.add(const ComplianceItem(
        id: 'sunday',
        status: ComplianceStatus.info,
        title: 'Sunday work',
        detail: 'Confirm double pay applied for Sunday work (BCEA).',
      ));
    }
  }

  DateTime _weekStartMonday(DateTime dt) {
    final weekday = dt.weekday; // 1=Mon, 7=Sun
    return DateTime(dt.year, dt.month, dt.day - (weekday - 1));
  }

  Future<Map<String, String>> _getStaffNames(Set<String> staffIds) async {
    if (staffIds.isEmpty) return {};
    try {
      final rows = await _client.from('staff_profiles').select('id, full_name').inFilter('id', staffIds.toList());
      final list = List<Map<String, dynamic>>.from(rows);
      return {for (var r in list) r['id'] as String: (r['full_name'] as String?) ?? ''};
    } catch (_) {
      return {};
    }
  }
}
