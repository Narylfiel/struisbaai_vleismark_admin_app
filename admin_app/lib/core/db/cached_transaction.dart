import 'package:isar/isar.dart';

part 'cached_transaction.g.dart';

/// Isar collection for transactions cached for offline list view.
@collection
class CachedTransaction {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String transactionId;

  late double totalAmount;
  double? costAmount;
  String? paymentMethod;
  String? tillSessionId;
  String? staffId;
  String? staffName;
  String? accountId;
  String? accountName;
  String? receiptNumber;
  late bool isVoided;
  late bool isRefund;
  DateTime? createdAt;
  late DateTime cachedAt;

  CachedTransaction() {
    isVoided = false;
    isRefund = false;
  }

  /// From Supabase transactions row (with optional profile/account names from joins).
  factory CachedTransaction.fromSupabase(
    Map<String, dynamic> row, {
    String? staffName,
    String? accountName,
  }) {
    final c = CachedTransaction();
    c.transactionId = row['id']?.toString() ?? '';
    c.totalAmount = (row['total_amount'] as num?)?.toDouble() ?? 0;
    c.costAmount = (row['cost_amount'] as num?)?.toDouble();
    c.paymentMethod = row['payment_method']?.toString();
    c.tillSessionId = row['till_session_id']?.toString();
    c.staffId = row['staff_id']?.toString();
    c.staffName = staffName ?? (row['profiles'] is Map ? (row['profiles'] as Map)['full_name']?.toString() : null);
    c.accountId = row['account_id']?.toString();
    c.accountName = accountName;
    c.receiptNumber = row['receipt_number']?.toString();
    c.isVoided = row['is_voided'] == true;
    c.isRefund = row['is_refund'] == true;
    c.createdAt = row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null;
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  Map<String, dynamic> toListMap() {
    return {
      'id': transactionId,
      'total_amount': totalAmount,
      'cost_amount': costAmount,
      'payment_method': paymentMethod,
      'till_session_id': tillSessionId,
      'staff_id': staffId,
      'account_id': accountId,
      'receipt_number': receiptNumber,
      'is_voided': isVoided,
      'is_refund': isRefund,
      'created_at': createdAt?.toIso8601String(),
      'profiles': staffName != null ? {'full_name': staffName} : null,
      'business_accounts': accountName != null ? {'name': accountName} : null,
    };
  }
}
