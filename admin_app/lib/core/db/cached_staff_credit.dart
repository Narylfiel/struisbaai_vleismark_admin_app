import 'package:isar/isar.dart';

part 'cached_staff_credit.g.dart';

@collection
class CachedStaffCredit {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  late String creditId;
  String? staffId;
  String? staffName;
  DateTime? creditDate;
  late double amount;
  String? reason;
  late double balance;
  late DateTime cachedAt;

  CachedStaffCredit();

  factory CachedStaffCredit.fromSupabase(Map<String, dynamic> row) {
    final c = CachedStaffCredit();
    c.creditId = row['id']?.toString() ?? '';
    c.staffId = row['staff_id']?.toString();
    c.staffName = row['staff_name']?.toString();
    c.creditDate = row['credit_date'] != null ? DateTime.tryParse(row['credit_date'].toString()) : null;
    c.amount = (row['amount'] as num?)?.toDouble() ?? 0;
    c.reason = row['reason']?.toString();
    c.balance = (row['balance'] as num?)?.toDouble() ?? 0;
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': creditId,
      'staff_id': staffId,
      'staff_name': staffName,
      'credit_date': creditDate?.toIso8601String(),
      'amount': amount,
      'reason': reason,
      'balance': balance,
    };
  }
}
