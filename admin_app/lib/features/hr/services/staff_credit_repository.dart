import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import '../models/staff_credit.dart';

/// Blueprint §7.5: Staff credit ledger — meat purchases, salary advances, loans; running balance per staff.
class StaffCreditRepository {
  final SupabaseClient _client;

  StaffCreditRepository({SupabaseClient? client}) : _client = client ?? SupabaseService.client;

  Future<List<StaffCredit>> getCredits({String? staffId, bool outstandingOnly = false}) async {
    var q = _client.from('staff_credit').select();
    if (staffId != null) q = q.eq('staff_id', staffId);
    final list = await q.order('granted_date', ascending: false);
    var credits = (list as List).map((e) => StaffCredit.fromJson(e as Map<String, dynamic>)).toList();
    if (outstandingOnly) credits = credits.where((c) => c.isOutstanding).toList();
    await _attachStaffNames(credits);
    return credits;
  }

  Future<void> _attachStaffNames(List<StaffCredit> credits) async {
    final ids = credits.map((e) => e.staffId).toSet().toList();
    if (ids.isEmpty) return;
    try {
      final rows = await _client.from('staff_profiles').select('id, full_name').inFilter('id', ids);
      final nameMap = {for (var r in rows as List) r['id'] as String: r['full_name'] as String?};
      for (var i = 0; i < credits.length; i++) {
        final name = nameMap[credits[i].staffId];
        if (name != null) credits[i] = credits[i].copyWith(staffName: name);
      }
    } catch (_) {}
  }

  /// Running outstanding balance for a staff member (Blueprint: shown on staff profile).
  Future<double> getOutstandingBalance(String staffId) async {
    final list = await getCredits(staffId: staffId, outstandingOnly: true);
    return list.fold<double>(0, (sum, c) => sum + c.amount);
  }

  /// All staff with outstanding balance (for Compliance / Credit tab).
  Future<Map<String, double>> getOutstandingBalancesByStaff() async {
    final list = await getCredits(outstandingOnly: true);
    final map = <String, double>{};
    for (final c in list) {
      map[c.staffId] = (map[c.staffId] ?? 0) + c.amount;
    }
    return map;
  }

  Future<StaffCredit> create({
    required String staffId,
    required StaffCreditType creditType,
    required double amount,
    required String reason,
    required DateTime grantedDate,
    DateTime? dueDate,
    String? itemsPurchased,
    String? repaymentPlan,
    String deductFrom = 'next_payroll',
    required String grantedBy,
    String? notes,
  }) async {
    final payload = {
      'staff_id': staffId,
      'credit_type': creditType.dbValue,
      'credit_amount': amount,
      'reason': reason,
      'granted_date': grantedDate.toIso8601String().substring(0, 10),
      'due_date': dueDate?.toIso8601String().substring(0, 10),
      'items_purchased': itemsPurchased,
      'repayment_plan': repaymentPlan,
      'deduct_from': deductFrom,
      'status': StaffCreditStatus.pending.dbValue,
      'granted_by': grantedBy,
      'notes': notes,
    };
    final row = await _client.from('staff_credit').insert(payload).select().single();
    return StaffCredit.fromJson(row as Map<String, dynamic>);
  }

  Future<void> updateStatus(String id, StaffCreditStatus status, {DateTime? paidDate}) async {
    final payload = <String, dynamic>{
      'status': status.dbValue,
      'is_paid': status == StaffCreditStatus.cleared,
    };
    if (paidDate != null) payload['paid_date'] = paidDate.toIso8601String().substring(0, 10);
    await _client.from('staff_credit').update(payload).eq('id', id);
  }
}
