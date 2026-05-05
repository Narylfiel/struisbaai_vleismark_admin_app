import 'package:isar/isar.dart';

part 'cached_payroll_entry.g.dart';

@collection
class CachedPayrollEntry {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  late String entryId;
  String? staffId;
  String? staffName;
  DateTime? payPeriodStart;
  DateTime? payPeriodEnd;
  late double grossPay;
  late double deductions;
  late double netPay;
  String? status;
  late DateTime cachedAt;

  CachedPayrollEntry();

  factory CachedPayrollEntry.fromSupabase(Map<String, dynamic> row) {
    final c = CachedPayrollEntry();
    c.entryId = row['id']?.toString() ?? '';
    c.staffId = row['staff_id']?.toString();
    c.staffName = row['staff_name']?.toString();
    c.payPeriodStart = row['pay_period_start'] != null ? DateTime.tryParse(row['pay_period_start'].toString()) : null;
    c.payPeriodEnd = row['pay_period_end'] != null ? DateTime.tryParse(row['pay_period_end'].toString()) : null;
    c.grossPay = (row['gross_pay'] as num?)?.toDouble() ?? 0;
    c.deductions = (row['deductions'] as num?)?.toDouble() ?? 0;
    c.netPay = (row['net_pay'] as num?)?.toDouble() ?? 0;
    c.status = row['status']?.toString();
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  Map<String, dynamic> toMap() => {'id': entryId, 'staff_id': staffId, 'staff_name': staffName, 'pay_period_start': payPeriodStart?.toIso8601String(), 'pay_period_end': payPeriodEnd?.toIso8601String(), 'gross_pay': grossPay, 'deductions': deductions, 'net_pay': netPay, 'status': status};
}
