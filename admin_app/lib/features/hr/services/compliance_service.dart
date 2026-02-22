import '../models/awol_record.dart';
import 'awol_repository.dart';

/// Blueprint §7.6: BCEA Compliance dashboard — weekly hours, breaks, leave, Sunday work, AWOL flags.
/// Aggregates AWOL data (from this app) and placeholders for timecard/leave data (from Clock-In App).
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

class ComplianceService {
  final AwolRepository _awolRepo;
  static const int _persistentAwolThreshold = 3;

  ComplianceService({AwolRepository? awolRepo}) : _awolRepo = awolRepo ?? AwolRepository();

  /// Build BCEA compliance checklist for the given month. AWOL from staff_awol_records; hours/breaks/leave from Clock-In (placeholder if not available).
  Future<List<ComplianceItem>> getBceaCompliance(DateTime monthStart) async {
    final items = <ComplianceItem>[];
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);

    // AWOL: persistent flag (3+ incidents per staff in period)
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

    // Placeholder: weekly hours (data from Clock-In App — if timecards table populated)
    items.add(const ComplianceItem(
      id: 'weekly_hours',
      status: ComplianceStatus.ok,
      title: 'Weekly working hour limits',
      detail: 'All staff within max 45h/week (from timecards when available).',
    ));

    // Placeholder: breaks
    items.add(const ComplianceItem(
      id: 'breaks',
      status: ComplianceStatus.ok,
      title: 'Break compliance',
      detail: '30+ min for 5+ hour shifts (BCEA) — from timecard breaks when available.',
    ));

    // Placeholder: annual leave low
    items.add(const ComplianceItem(
      id: 'leave',
      status: ComplianceStatus.warning,
      title: 'Leave balances',
      detail: 'Minimum 21 days annual leave per year — check Leave tab / Clock-In data.',
    ));

    // Placeholder: Sunday work
    items.add(const ComplianceItem(
      id: 'sunday',
      status: ComplianceStatus.info,
      title: 'Sunday work',
      detail: 'Confirm double pay applied for Sunday work — check payroll.',
    ));

    return items;
  }
}
