import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';

/// Read-only repository for POS transactions. Admin never writes.
class TransactionRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// List transactions in date range with optional filters. Joins profiles for cashier name.
  Future<List<Map<String, dynamic>>> getTransactions({
    required DateTime start,
    required DateTime end,
    String? paymentMethod,
    String? staffId,
    int limit = 500,
  }) async {
    try {
      var q = _client
          .from('transactions')
          .select('''
            id, created_at, total_amount, cost_amount, payment_method,
            till_session_id, staff_id, account_id, notes,
            receipt_number, discount_total, loyalty_customer_id,
            refund_of_transaction_id, is_refund, is_voided,
            voided_by, voided_at, void_reason,
            profiles(full_name)
          ''')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());
      if (paymentMethod != null && paymentMethod.isNotEmpty) {
        q = q.eq('payment_method', paymentMethod);
      }
      if (staffId != null && staffId.isNotEmpty) {
        q = q.eq('staff_id', staffId);
      }
      final response = await q.order('created_at', ascending: false).limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Single transaction with line items, split payments, and joined names.
  Future<Map<String, dynamic>?> getTransactionDetail(String transactionId) async {
    try {
      final t = await _client
          .from('transactions')
          .select('''
            id, created_at, total_amount, cost_amount, payment_method,
            till_session_id, staff_id, account_id, notes,
            receipt_number, discount_total, loyalty_customer_id,
            refund_of_transaction_id, is_refund, is_voided,
            voided_by, voided_at, void_reason,
            profiles(full_name),
            business_accounts(name),
            loyalty_customers(customer_name, full_name)
          ''')
          .eq('id', transactionId)
          .maybeSingle();
      if (t == null) return null;

      final tx = Map<String, dynamic>.from(t);

      // Voided_by name
      if (tx['voided_by'] != null) {
        try {
          final voidedByRow = await _client
              .from('profiles')
              .select('full_name')
              .eq('id', tx['voided_by'])
              .maybeSingle();
          if (voidedByRow != null) {
            tx['voided_by_name'] = voidedByRow['full_name'];
          }
        } catch (_) {}
      }

      // Line items with product name
      final items = await _client
          .from('transaction_items')
          .select('''
            id, transaction_id, inventory_item_id, quantity, unit_price,
            line_total, cost_price, discount_amount, is_weighted, weight_kg,
            modifier_selections, created_at,
            inventory_items(name)
          ''')
          .eq('transaction_id', transactionId)
          .order('created_at', ascending: true);
      tx['items'] = List<Map<String, dynamic>>.from(items);

      // Split payments if any
      try {
        final splits = await _client
            .from('split_payments')
            .select('''
              id, transaction_id, payment_method, amount,
              amount_tendered, change_given, card_reference,
              business_account_id, created_at
            ''')
            .eq('transaction_id', transactionId)
            .order('created_at', ascending: true);
        tx['split_payments'] = List<Map<String, dynamic>>.from(splits);
      } catch (_) {
        tx['split_payments'] = <Map<String, dynamic>>[];
      }

      return tx;
    } catch (e) {
      return null;
    }
  }

  /// Staff list for filter dropdown (profiles with full_name).
  Future<List<Map<String, dynamic>>> getStaffForFilter() async {
    try {
      final r = await _client
          .from('profiles')
          .select('id, full_name')
          .order('full_name');
      return List<Map<String, dynamic>>.from(r);
    } catch (e) {
      return [];
    }
  }

  /// Till sessions in date range. Joins profiles for opened_by name.
  Future<List<Map<String, dynamic>>> getTillSessions(DateTime start, DateTime end) async {
    try {
      final response = await _client
          .from('till_sessions')
          .select('''
            id, terminal_id, opened_by, opened_at, opening_float,
            closed_by, closed_at, expected_closing_cash, actual_closing_cash,
            variance, status, notes, created_at,
            profiles(full_name)
          ''')
          .gte('opened_at', start.toIso8601String())
          .lte('opened_at', end.toIso8601String())
          .order('opened_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Single till session with Z-report (transactions summary by payment method) and petty cash movements.
  Future<Map<String, dynamic>?> getTillSessionDetail(String sessionId) async {
    try {
      final row = await _client
          .from('till_sessions')
          .select('''
            id, terminal_id, opened_by, opened_at, opening_float,
            closed_by, closed_at, expected_closing_cash, actual_closing_cash,
            variance, status, notes, created_at,
            profiles(full_name)
          ''')
          .eq('id', sessionId)
          .maybeSingle();
      if (row == null) return null;

      final session = Map<String, dynamic>.from(row);

      // Resolve opened_by and closed_by names (profiles join may only give one; fetch both)
      if (session['opened_by'] != null) {
        try {
          final r = await _client.from('profiles').select('full_name').eq('id', session['opened_by']).maybeSingle();
          if (r != null) session['opened_by_name'] = r['full_name'];
        } catch (_) {}
      }
      if (session['closed_by'] != null) {
        try {
          final r = await _client.from('profiles').select('full_name').eq('id', session['closed_by']).maybeSingle();
          if (r != null) session['closed_by_name'] = r['full_name'];
        } catch (_) {}
      }
      if (session['opened_by_name'] == null && session['profiles'] != null) {
        final p = session['profiles'];
        if (p is Map) session['opened_by_name'] = p['full_name'];
      }

      // Z-report: transactions for this session
      final txns = await _client
          .from('transactions')
          .select('id, total_amount, payment_method')
          .eq('till_session_id', sessionId);
      final txnList = List<Map<String, dynamic>>.from(txns);
      session['transactions'] = txnList;

      double cashTotal = 0, cardTotal = 0, accountTotal = 0, splitTotal = 0;
      for (final t in txnList) {
        final amount = (t['total_amount'] as num?)?.toDouble() ?? 0;
        final method = (t['payment_method'] as String?)?.toLowerCase() ?? '';
        if (method == 'cash') cashTotal += amount;
        else if (method == 'card') cardTotal += amount;
        else if (method == 'account') accountTotal += amount;
        else if (method == 'split') splitTotal += amount;
        else cashTotal += amount; // fallback
      }
      session['z_total_count'] = txnList.length;
      session['z_total_revenue'] = txnList.fold<double>(0, (s, t) => s + ((t['total_amount'] as num?)?.toDouble() ?? 0));
      session['z_cash'] = cashTotal;
      session['z_card'] = cardTotal;
      session['z_account'] = accountTotal;
      session['z_split'] = splitTotal;

      // Petty cash movements
      final pcm = await _client
          .from('petty_cash_movements')
          .select('''
            id, direction, amount, reason, recorded_by, recorded_at, created_at,
            profiles(full_name)
          ''')
          .eq('till_session_id', sessionId)
          .order('recorded_at', ascending: true);
      final pcmList = List<Map<String, dynamic>>.from(pcm);
      session['petty_cash_movements'] = pcmList;

      double pettyIn = 0, pettyOut = 0;
      for (final m in pcmList) {
        final amt = (m['amount'] as num?)?.toDouble() ?? 0;
        if ((m['direction'] as String?) == 'in') pettyIn += amt;
        else pettyOut += amt;
      }
      session['petty_cash_net'] = pettyIn - pettyOut;

      return session;
    } catch (e) {
      return null;
    }
  }
}
