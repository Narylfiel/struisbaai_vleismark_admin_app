import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/transaction.dart';

/// Dashboard data from blueprint §3.2: transactions (today), Transaction Count,
/// Average Basket (Sales ÷ Transactions), Gross Margin (Revenue - COGS) ÷ Revenue.
/// Reads from canonical tables: transactions, transaction_items.
class DashboardRepository {
  final SupabaseClient _client;

  DashboardRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Today's transactions for stats (Today's Sales, Transaction Count, Avg Basket, Margin).
  Future<List<Transaction>> getTransactionsForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _client
          .from('transactions')
          .select('id, created_at, total_amount, cost_amount, payment_method, till_session_id, staff_id, account_id')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .order('created_at', ascending: true);
      final list = List<Map<String, dynamic>>.from(response);
      return list.map((e) => Transaction.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Today's stats: todayTotal, yesterdayTotal, transactionCount, avgBasket, grossMarginPct, salesChangePct.
  Future<DashboardTransactionStats> getTodayStats() async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final yesterdayEnd = yesterdayStart.add(const Duration(hours: 23, minutes: 59, seconds: 59));

    final todayTxns = await getTransactionsForDateRange(todayStart, todayEnd);
    final yesterdayTxns = await getTransactionsForDateRange(yesterdayStart, yesterdayEnd);

    final todayTotal = todayTxns.fold<double>(0, (s, t) => s + t.totalAmount);
    final todayCost = todayTxns.fold<double>(0, (s, t) => s + (t.costAmount ?? 0));
    final yesterdayTotal = yesterdayTxns.fold<double>(0, (s, t) => s + t.totalAmount);

    final count = todayTxns.length;
    final avgBasket = count > 0 ? todayTotal / count : 0.0;
    final grossMarginPct = todayTotal > 0 ? ((todayTotal - todayCost) / todayTotal) * 100 : 0.0;
    final salesChangePct = yesterdayTotal > 0
        ? ((todayTotal - yesterdayTotal) / yesterdayTotal) * 100
        : 0.0;

    return DashboardTransactionStats(
      todayTotal,
      yesterdayTotal,
      count,
      avgBasket,
      grossMarginPct,
      salesChangePct,
    );
  }
}

/// Stats derived from transactions (blueprint §3.2).
class DashboardTransactionStats {
  final double todayTotal;
  final double yesterdayTotal;
  final int transactionCount;
  final double avgBasket;
  final double grossMarginPct;
  final double salesChangePct;

  const DashboardTransactionStats(
    this.todayTotal,
    this.yesterdayTotal,
    this.transactionCount,
    this.avgBasket,
    this.grossMarginPct,
    this.salesChangePct,
  );
}
