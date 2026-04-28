import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/models/shrinkage_alert.dart';

/// Repository handling data for the Smart Analytics & Compliance module.
/// Strictly maps directly to the blueprint dependencies:
/// - shrinkage_alerts
/// - inventory_items
/// - supplier_price_changes
/// - reorder_recommendations
/// - event_tags
/// - event_sales_history
class AnalyticsRepository {
  final SupabaseClient _client;

  AnalyticsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  String _nameFromEmbed(Map<String, dynamic> r) {
    final inv = r['inventory_items'];
    if (inv is Map && inv['name'] != null) {
      return inv['name'].toString();
    }
    return r['product_name']?.toString() ?? '—';
  }

  double _reorderSortKey(Map<String, dynamic> r) {
    final ds = r['days_of_stock'];
    if (ds is num) return ds.toDouble();
    final dr = r['days_remaining']?.toString();
    if (dr == null || dr == '—') return double.infinity;
    return double.tryParse(dr) ?? double.infinity;
  }

  // ═════════════════════════════════════════════════════════
  // 1. SHRINKAGE ALERTS (model-based; no raw maps)
  // ═════════════════════════════════════════════════════════
  Future<List<ShrinkageAlert>> getShrinkageAlerts() async {
    try {
      final response = await _client
          .from('shrinkage_alerts')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      return (response as List)
          .map((e) => ShrinkageAlert.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('Analytics error: $e');
      return [];
    }
  }

  Future<void> updateShrinkageStatus(String alertId, String newStatus) async {
    final resolved = newStatus == 'Accepted' || newStatus == 'Resolved' || newStatus == 'Acknowledged';
    await _client.from('shrinkage_alerts').update({'status': newStatus, 'resolved': resolved}).eq('id', alertId);
  }

  Future<void> triggerMassBalance() async {
    // Optional RPC if defined in the DB. Falls silently if not present.
    try {
      await _client.rpc('calculate_nightly_mass_balance');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  // ═════════════════════════════════════════════════════════
  // 2. DYNAMIC PRICING SUGGESTIONS (supplier_price_changes or inventory-based)
  // ═════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> getPricingSuggestions() async {
    try {
      final response = await _client
          .from('supplier_price_changes')
          .select('*, inventory_items(name)')
          .eq('status', 'Pending')
          .order('created_at', ascending: false)
          .limit(20);
      final list = List<Map<String, dynamic>>.from(response);
      for (final r in list) {
        r['product_name'] = _nameFromEmbed(r);
      }
      if (list.isNotEmpty) return list;
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
    return _getPricingFromInventory();
  }

  Future<List<Map<String, dynamic>>> _getPricingFromInventory() async {
    try {
      final rows = await _client
          .from('inventory_items')
          .select('id, name, sell_price, average_cost, cost_price, target_margin_pct')
          .eq('is_active', true)
          .eq('stock_control_type', 'use_stock_control');
      final suggestions = <Map<String, dynamic>>[];
      for (final r in rows as List) {
        final map = Map<String, dynamic>.from(r as Map<String, dynamic>);
        final sell = (map['sell_price'] as num?)?.toDouble() ?? 0;
        final cost = (map['average_cost'] as num?)?.toDouble() ??
            (map['cost_price'] as num?)?.toDouble() ?? 0;
        if (cost <= 0 || sell <= 0) continue;
        final targetMarginPct =
            (map['target_margin_pct'] as num?)?.toDouble() ?? 30.0;
        final currentMarginPct = ((sell - cost) / sell) * 100;
        if (currentMarginPct >= targetMarginPct - 3) continue;
        final suggested = cost / (1 - targetMarginPct / 100);
        suggestions.add({
          'id': map['id'],
          'product_name': map['name'],
          'current_sell_price': sell.toStringAsFixed(2),
          'suggested_sell_price': suggested.toStringAsFixed(2),
          'current_margin_pct': currentMarginPct.toStringAsFixed(1),
          'target_margin_pct': targetMarginPct.toStringAsFixed(0),
          'margin_impact':
              '${currentMarginPct.toStringAsFixed(1)}% → ${targetMarginPct.toStringAsFixed(0)}% target',
          'supplier_name': '—',
          'percentage_increase':
              ((suggested - sell) / sell * 100).toStringAsFixed(1),
          'cost_price': cost.toStringAsFixed(2),
        });
      }
      suggestions.sort((a, b) =>
          double.parse(a['current_margin_pct'])
              .compareTo(double.parse(b['current_margin_pct'])));
      return suggestions.take(20).toList();
    } catch (e) {
      debugPrint('Analytics error: $e');
      return [];
    }
  }

  Future<void> updatePricingSuggestion(
      String id, String status, {double? newSellPrice}) async {
    try {
      await _client
          .from('supplier_price_changes')
          .update({'status': status})
          .eq('id', id);
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
    if (status == 'Applied' && newSellPrice != null) {
      try {
        await _client.from('inventory_items').update({
          'sell_price': newSellPrice,
          'price_last_changed': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', id);
      } catch (e) {
        debugPrint('Analytics error: $e');
      }
    }
  }

  // ═════════════════════════════════════════════════════════
  // 3. PREDICTIVE REORDER (reorder_recommendations or inventory + velocity)
  // Phase 4: Fallback uses same source as Stock Levels (inventory_items: current_stock, reorder_point/reorder_level).
  // ═════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> getReorderRecommendations() async {
    try {
      // DB columns: days_of_stock, urgency (not days_remaining, status)
      final response = await _client
          .from('reorder_recommendations')
          .select('*, inventory_items(name)')
          .order('days_of_stock', ascending: true)
          .limit(50);
      final list = List<Map<String, dynamic>>.from(response);
      for (final r in list) {
        r['product_name'] = _nameFromEmbed(r);
        final days = r['days_remaining'] ?? r['days_of_stock'];
        r['days_remaining'] = days;
        final status = r['status'] ?? r['urgency'];
        r['recommendation_text'] ??= _reorderRecommendationText(days, status);
      }
      list.sort(
          (a, b) => _reorderSortKey(a).compareTo(_reorderSortKey(b)));
      if (list.isNotEmpty) return list;
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
    return _getReorderFromInventoryAndVelocity();
  }

  String _reorderRecommendationText(dynamic days, dynamic status) {
    final d = (days is num) ? days.toDouble() : double.tryParse(days?.toString() ?? '') ?? 0;
    final s = status?.toString().toUpperCase() ?? '';
    if (s == 'URGENT' || d < 2) return 'Order NOW';
    if (s == 'WARNING' || s == 'SOON' || d < 5) return 'Order by Friday';
    return 'OK for now';
  }

  Future<List<Map<String, dynamic>>> _getReorderFromInventoryAndVelocity() async {
    try {
      final invRows = await _client
          .from('inventory_items')
          .select('id, name, current_stock, reorder_level')
          .eq('is_active', true);
      final recs = <Map<String, dynamic>>[];
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
      final txnIds = await _client
          .from('transactions')
          .select('id')
          .gte('created_at', sevenDaysAgo);
      final txnIdList = (txnIds as List).map((t) => (t as Map)['id']).whereType<String>().toList();
      if (txnIdList.isEmpty) {
        for (final r in invRows as List) {
          final map = Map<String, dynamic>.from(r as Map<String, dynamic>);
          final id = map['id']?.toString();
          if (id == null) continue;
          final stock = (map['current_stock'] as num?)?.toDouble() ?? 0;
          final reorder = (map['reorder_level'] as num?)?.toDouble() ?? 0;
          if (reorder <= 0) continue;
          if (stock > reorder) continue;
          recs.add({
            'inventory_item_id': id,
            'product_name': map['name'],
            'days_remaining': stock <= 0 ? '0' : '—',
            'recommendation_text': stock <= 0 ? 'Order NOW' : 'Below reorder point',
            'status': stock <= 0 ? 'URGENT' : 'WARNING',
          });
        }
        recs.sort(
            (a, b) => _reorderSortKey(a).compareTo(_reorderSortKey(b)));
        return recs.take(50).toList();
      }
      final items = await _client
          .from('transaction_items')
          .select('inventory_item_id, quantity')
          .inFilter('transaction_id', txnIdList);
      final qtyByItem = <String, double>{};
      for (final ti in items as List) {
        final id = (ti as Map)['inventory_item_id']?.toString();
        if (id == null) continue;
        final q = (ti['quantity'] as num?)?.toDouble() ?? 0;
        qtyByItem[id] = (qtyByItem[id] ?? 0) + q;
      }
      for (final r in invRows as List) {
        final map = Map<String, dynamic>.from(r as Map<String, dynamic>);
        final id = map['id']?.toString();
        final stock = (map['current_stock'] as num?)?.toDouble() ?? 0;
        final reorder = (map['reorder_level'] as num?)?.toDouble() ?? 0;
        if (reorder <= 0) continue;
        final sold7 = qtyByItem[id] ?? 0;
        final dailyVelocity = sold7 / 7;
        double daysRemaining = dailyVelocity > 0 ? stock / dailyVelocity : 999;
        if (daysRemaining > 999) daysRemaining = 999;
        String status = 'OK';
        if (stock <= reorder || daysRemaining < 2) status = 'URGENT';
        else if (daysRemaining < 5) status = 'WARNING';
        final weeklyAvg = sold7;
        String contextMsg;
        if (dailyVelocity <= 0) {
          contextMsg = 'No sales in last 7 days — check if product is active';
        } else if (daysRemaining >= 14) {
          contextMsg =
              'Stock OK — ${daysRemaining.toStringAsFixed(0)} days remaining at current velocity';
        } else if (daysRemaining >= 7) {
          contextMsg =
              'Monitor — ${daysRemaining.toStringAsFixed(0)} days remaining. Weekly avg: ${weeklyAvg.toStringAsFixed(2)} kg';
        } else if (daysRemaining >= 3) {
          contextMsg =
              'Consider ordering — ${daysRemaining.toStringAsFixed(0)} days left. Weekly avg: ${weeklyAvg.toStringAsFixed(2)} kg';
        } else {
          contextMsg =
              'Order soon — only ${daysRemaining.toStringAsFixed(1)} days left. Weekly avg: ${weeklyAvg.toStringAsFixed(2)} kg';
        }
        recs.add({
          'inventory_item_id': id,
          'product_name': map['name'],
          'days_remaining': daysRemaining >= 999 ? '—' : daysRemaining.toStringAsFixed(1),
          'recommendation_text': _reorderRecommendationText(daysRemaining, status),
          'status': status,
          'current_stock': stock.toStringAsFixed(3),
          'reorder_point': reorder.toStringAsFixed(3),
          'weekly_avg_sales': weeklyAvg.toStringAsFixed(2),
          'daily_velocity': dailyVelocity.toStringAsFixed(3),
          'context_message': contextMsg,
        });
      }
      recs.sort(
          (a, b) => _reorderSortKey(a).compareTo(_reorderSortKey(b)));
      return recs.take(50).toList();
    } catch (e) {
      debugPrint('Analytics error: $e');
      return [];
    }
  }


  // ═════════════════════════════════════════════════════════
  // 4. EVENT TAG FORECASTING
  // ═════════════════════════════════════════════════════════

  /// Reads the spike detection threshold from business_settings.
  /// event_spike_multiplier is stored as a percentage (e.g. 30 = 30% above normal).
  Future<double> _getSpikeThresholdPct() async {
    try {
      final settings = await _client
          .from('business_settings')
          .select('event_spike_multiplier')
          .limit(1)
          .single();
      final multiplier =
          (settings['event_spike_multiplier'] as num?)?.toDouble() ?? 1.5;
      return multiplier;
    } catch (e) {
      debugPrint('Analytics error: $e');
      return 1.5;
    }
  }

  /// Detects weeks (Mon–Sun) where revenue, kg sold, OR transaction count
  /// exceeded the 8-week rolling average by more than the configured threshold.
  Future<List<Map<String, dynamic>>> getRecentEvents() async {
    try {
      return _getSalesSpikesFromTransactions();
    } catch (e) {
      debugPrint('Analytics error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getSalesSpikesFromTransactions() async {
    try {
      final thresholdPct = await _getSpikeThresholdPct();

      // Fetch 10 weeks of transactions to build 8-week baseline + 2 recent weeks
      final end = DateTime.now();
      final start = end.subtract(const Duration(days: 70));

      final txns = await _client
          .from('transactions')
          .select('created_at, total_amount')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .eq('is_voided', false)
          .eq('is_refund', false);

      // Aggregate by ISO week start (Monday)
      final byWeek = <String, Map<String, double>>{};
      for (final t in txns as List) {
        final map = Map<String, dynamic>.from(t as Map);
        final dateStr = (map['created_at'] as String?)?.substring(0, 10);
        if (dateStr == null) continue;
        final date = DateTime.tryParse(dateStr);
        if (date == null) continue;

        // Find Monday of this week
        final monday = date.subtract(Duration(days: date.weekday - 1));
        final weekKey = monday.toIso8601String().substring(0, 10);

        final amt = (map['total_amount'] as num?)?.toDouble() ?? 0;
        final txCount = 1.0;

        byWeek[weekKey] ??= {'revenue': 0, 'transactions': 0};
        byWeek[weekKey]!['revenue'] = (byWeek[weekKey]!['revenue'] ?? 0) + amt;
        byWeek[weekKey]!['transactions'] =
            (byWeek[weekKey]!['transactions'] ?? 0) + txCount;
      }

      if (byWeek.length < 4) return [];

      // Sort weeks chronologically
      final sortedWeeks = byWeek.keys.toList()..sort();

      // Use all but last 2 weeks as baseline (minimum 4 weeks)
      final baselineWeeks = sortedWeeks.length > 2
          ? sortedWeeks.sublist(0, sortedWeeks.length - 2)
          : sortedWeeks;

      if (baselineWeeks.isEmpty) return [];

      final baselineRevenues =
          baselineWeeks.map((w) => byWeek[w]!['revenue']!).toList();
      final baselineTxCounts =
          baselineWeeks.map((w) => byWeek[w]!['transactions']!).toList();

      final avgRevenue =
          baselineRevenues.reduce((a, b) => a + b) / baselineRevenues.length;
      final avgTxCount =
          baselineTxCounts.reduce((a, b) => a + b) / baselineTxCounts.length;

      // Check last 2 weeks for spikes
      final recentWeeks = sortedWeeks.length >= 2
          ? sortedWeeks.sublist(sortedWeeks.length - 2)
          : sortedWeeks;

      final spikes = <Map<String, dynamic>>[];

      for (final weekStart in recentWeeks) {
        final weekData = byWeek[weekStart]!;
        final revenue = weekData['revenue']!;
        final txCount = weekData['transactions']!;

        if (avgRevenue <= 0) continue;

        final revenueVariancePct = ((revenue - avgRevenue) / avgRevenue) * 100;
        final txVariancePct = avgTxCount > 0
            ? ((txCount - avgTxCount) / avgTxCount) * 100
            : 0.0;

        // Flag if revenue OR transaction count exceeds threshold
        if (revenueVariancePct >= thresholdPct ||
            txVariancePct >= thresholdPct) {
          // Calculate Sunday (end of week)
          final monday = DateTime.parse(weekStart);
          final sunday = monday.add(const Duration(days: 6));

          spikes.add({
            'week_start': weekStart,
            'week_end': sunday.toIso8601String().substring(0, 10),
            'revenue': revenue,
            'total_amount': revenue,
            'transaction_count': txCount.toInt(),
            'baseline_revenue': avgRevenue,
            'revenue_variance_pct': revenueVariancePct.toStringAsFixed(1),
            'tx_variance_pct': txVariancePct.toStringAsFixed(1),
            'display_date':
                '${_formatDate(monday)} – ${_formatDate(sunday)}',
          });
        }
      }

      spikes.sort((a, b) {
        final ba = (b['total_amount'] as num?)?.toDouble() ?? 0;
        final aa = (a['total_amount'] as num?)?.toDouble() ?? 0;
        return ba.compareTo(aa);
      });
      return spikes;
    } catch (e) {
      debugPrint('Analytics error: $e');
      return [];
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  /// Returns all saved event tags ordered by most recent start_date.
  Future<List<Map<String, dynamic>>> getHistoricalEventTags() async {
    try {
      final response = await _client
          .from('event_tags')
          .select()
          .eq('dismissed', false)
          .order('start_date', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Analytics error: $e');
      try {
        final response = await _client
            .from('event_tags')
            .select()
            .order('event_date', ascending: false)
            .limit(50);
        return List<Map<String, dynamic>>.from(response);
      } catch (e2) {
        debugPrint('Analytics error: $e2');
        return [];
      }
    }
  }

  /// Returns saved events whose anniversary falls within the next
  /// [reminder_days_before] days (default 45).
  Future<List<Map<String, dynamic>>> getUpcomingEventReminders() async {
    try {
      final tags = await getHistoricalEventTags();
      final today = DateTime.now();
      final reminders = <Map<String, dynamic>>[];

      for (final tag in tags) {
        final startDate = DateTime.tryParse(
            tag['start_date']?.toString() ??
            tag['event_date']?.toString() ?? '');
        if (startDate == null) continue;

        final reminderDays =
            (tag['reminder_days_before'] as num?)?.toInt() ?? 45;

        // Shift start_date to current year for anniversary check
        DateTime anniversary = DateTime(today.year, startDate.month, startDate.day);

        // If anniversary already passed this year, check next year
        if (anniversary.isBefore(today)) {
          anniversary = DateTime(today.year + 1, startDate.month, startDate.day);
        }

        final daysUntil = anniversary.difference(today).inDays;

        if (daysUntil <= reminderDays) {
          reminders.add({
            ...tag,
            'days_until': daysUntil,
            'anniversary_date': anniversary.toIso8601String().substring(0, 10),
          });
        }
      }

      reminders.sort((a, b) =>
          (a['days_until'] as int).compareTo(b['days_until'] as int));
      return reminders;
    } catch (e) {
      debugPrint('Analytics error: $e');
      return [];
    }
  }

  /// Saves a new event tag with full date range and captured sales metrics.
  Future<void> saveEventTag(
    String eventType,
    String eventName, {
    required String startDate,
    required String endDate,
    double revenue = 0,
    double baselineRevenue = 0,
    double revenueVariancePct = 0,
    int transactionCount = 0,
    bool autoDetected = false,
  }) async {
    try {
      final start = DateTime.parse(startDate);
      await _client.from('event_tags').insert({
        'event_name': eventName,
        'event_type': eventType,
        'event_date': startDate,
        'start_date': startDate,
        'end_date': endDate,
        'spike_date': startDate,
        'recurrence_month': start.month,
        'recurrence_week': _isoWeekNumber(start),
        'total_revenue': revenue,
        'baseline_revenue': baselineRevenue,
        'revenue_variance_pct': revenueVariancePct,
        'total_transactions': transactionCount,
        'auto_detected': autoDetected,
        'reminder_days_before': 45,
        'dismissed': false,
      });
    } catch (e, stack) {
      debugPrint('DATABASE WRITE FAILED: event_tags insert');
      debugPrint(e.toString());
      debugPrint(stack.toString());
      rethrow;
    }
  }

  /// Marks a detected spike as dismissed (won't show again).
  Future<void> dismissSpike(String weekStart) async {
    try {
      await _client.from('event_tags').insert({
        'event_name': 'Dismissed spike',
        'event_type': 'dismissed',
        'event_date': weekStart,
        'start_date': weekStart,
        'dismissed': true,
        'auto_detected': true,
      });
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  int _isoWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final firstMonday = startOfYear.weekday <= 4
        ? startOfYear.subtract(Duration(days: startOfYear.weekday - 1))
        : startOfYear.add(Duration(days: 8 - startOfYear.weekday));
    return ((date.difference(firstMonday).inDays) / 7).floor() + 1;
  }

  /// Year-on-year comparison for a specific event name.
  Future<List<Map<String, dynamic>>> getEventYearOnYear(
      String eventName) async {
    try {
      final tags = await _client
          .from('event_tags')
          .select()
          .ilike('event_name', '%$eventName%')
          .eq('dismissed', false)
          .order('start_date', ascending: true);

      return List<Map<String, dynamic>>.from(tags);
    } catch (e) {
      debugPrint('Analytics error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getForecastForEvent(
      String eventName) async {
    try {
      final instances = await getEventYearOnYear(eventName);
      if (instances.isEmpty) return [];

      // Calculate average metrics across all recorded instances
      double totalRevenue = 0;
      double totalVariance = 0;
      int totalTx = 0;
      int count = 0;

      for (final inst in instances) {
        final rev = (inst['total_revenue'] as num?)?.toDouble() ?? 0;
        final variance =
            (inst['revenue_variance_pct'] as num?)?.toDouble() ?? 0;
        final tx = (inst['total_transactions'] as num?)?.toInt() ?? 0;
        if (rev > 0) {
          totalRevenue += rev;
          totalVariance += variance;
          totalTx += tx;
          count++;
        }
      }

      if (count == 0) return [];

      return [
        {
          'avg_revenue': (totalRevenue / count).toStringAsFixed(2),
          'avg_variance_pct': (totalVariance / count).toStringAsFixed(1),
          'avg_transactions': (totalTx / count).toStringAsFixed(0),
          'years_recorded': count,
          'instances': instances,
        }
      ];
    } catch (e) {
      debugPrint('Analytics error: $e');
      return [];
    }
  }
}
