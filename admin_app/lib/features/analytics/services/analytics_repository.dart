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
    } catch (_) {
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
    } catch (_) {}
  }

  // ═════════════════════════════════════════════════════════
  // 2. DYNAMIC PRICING SUGGESTIONS (supplier_price_changes or inventory-based)
  // ═════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> getPricingSuggestions() async {
    try {
      final response = await _client
          .from('supplier_price_changes')
          .select()
          .eq('status', 'Pending')
          .order('created_at', ascending: false)
          .limit(20);
      final list = List<Map<String, dynamic>>.from(response);
      if (list.isNotEmpty) return list;
    } catch (_) {}
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
    } catch (_) {
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
    } catch (_) {}
    if (status == 'Applied' && newSellPrice != null) {
      try {
        await _client.from('inventory_items').update({
          'sell_price': newSellPrice,
          'price_last_changed': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', id);
      } catch (_) {}
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
          .select()
          .order('days_of_stock', ascending: true)
          .limit(50);
      final list = List<Map<String, dynamic>>.from(response);
      for (final r in list) {
        final inv = (r['inventory_items'] as Map?);
        if (inv != null) r['product_name'] = inv['name'];
        final days = r['days_remaining'] ?? r['days_of_stock'];
        r['days_remaining'] = days;
        final status = r['status'] ?? r['urgency'];
        r['recommendation_text'] ??= _reorderRecommendationText(days, status);
      }
      if (list.isNotEmpty) return list;
    } catch (_) {}
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
      recs.sort((a, b) {
        final aDays = a['days_remaining'] as String?;
        final bDays = b['days_remaining'] as String?;
        if (aDays == '—') {
          return 1;
        }
        if (bDays == '—') {
          return -1;
        }
        return (double.tryParse(aDays ?? '') ?? 999)
            .compareTo(double.tryParse(bDays ?? '') ?? 999);
      });
      return recs.take(50).toList();
    } catch (_) {
      return [];
    }
  }


  // ═════════════════════════════════════════════════════════
  // 4. EVENT TAG FORECASTING (Blueprint §10.4)
  // ═════════════════════════════════════════════════════════
  /// Days with sales significantly above rolling average (e.g. 200%) for tagging.
  Future<List<Map<String, dynamic>>> getRecentEvents() async {
    try {
      return _getSalesSpikesFromTransactions();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getSalesSpikesFromTransactions() async {
    try {
      final end = DateTime.now();
      final start = end.subtract(const Duration(days: 14));
      final txns = await _client
          .from('transactions')
          .select('created_at, total_amount')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());
      final byDate = <String, double>{};
      for (final t in txns as List) {
        final map = t as Map<String, dynamic>;
        final dateStr = (map['created_at'] as String?)?.substring(0, 10) ?? '';
        if (dateStr.isEmpty) continue;
        final amt = (map['total_amount'] as num?)?.toDouble() ?? 0;
        byDate[dateStr] = (byDate[dateStr] ?? 0) + amt;
      }
      if (byDate.length < 3) return [];
      final values = byDate.values.toList();
      final avg = values.reduce((a, b) => a + b) / values.length;
      const threshold = 2.0;
      final spikes = <Map<String, dynamic>>[];
      for (final e in byDate.entries) {
        if (avg <= 0) continue;
        final pct = (e.value / avg) * 100;
        if (pct >= threshold * 100) {
          spikes.add({
            'date': e.key,
            'sales_amount': e.value,
            'variance_percentage': (pct - 100).toStringAsFixed(0),
          });
        }
      }
      spikes.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
      return spikes.take(5).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getHistoricalEventTags() async {
    try {
      final response = await _client
          .from('event_tags')
          .select()
          .order('event_date', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      try {
        return List<Map<String, dynamic>>.from(
            await _client.from('event_tags').select().order('date', ascending: false).limit(20));
      } catch (_) {
        return [];
      }
    }
  }

  /// event_type must be one of: holiday, school_holiday, public_holiday, sporting_event, local_event
  Future<void> saveEventTag(String eventType, String eventName) async {
    try {
      await _client.from('event_tags').insert({
        'event_name': eventName,
        'event_date': DateTime.now().toIso8601String().substring(0, 10),
        'event_type': eventType,
      });
    } catch (e, stack) {
      debugPrint('DATABASE WRITE FAILED: event_tags insert');
      debugPrint(e.toString());
      debugPrint(stack.toString());
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getForecastForEvent(String eventType) async {
    try {
      final response = await _client.rpc('get_event_forecast', params: {'p_event_type': eventType});
      final list = List<Map<String, dynamic>>.from(response ?? []);
      if (list.isNotEmpty) return list;
    } catch (_) {}
    return _getForecastFromEventHistory(eventType);
  }

  Future<List<Map<String, dynamic>>> _getForecastFromEventHistory(String eventType) async {
    try {
      final tags = await _client
          .from('event_tags')
          .select('id')
          .eq('event_type', eventType)
          .limit(10);
      final tagIds = (tags as List).map((t) => (t as Map)['id']).whereType<String>().toList();
      if (tagIds.isEmpty) return [];
      final history = await _client
          .from('event_sales_history')
          .select('top_products, sales_amount')
          .inFilter('event_id', tagIds);
      final productTotals = <String, double>{};
      for (final h in history as List) {
        final top = (h as Map)['top_products'];
        if (top is List) {
          for (final p in top) {
            if (p is Map) {
              final name = p['name']?.toString() ?? p['product_name']?.toString() ?? '—';
              final qty = (p['quantity'] as num?)?.toDouble() ?? (p['qty'] as num?)?.toDouble() ?? 0;
              productTotals[name] = (productTotals[name] ?? 0) + qty;
            }
          }
        }
      }
      return productTotals.entries
          .map((e) => {'product_name': e.key, 'suggested_quantity_kg': e.value.toStringAsFixed(1)})
          .toList();
    } catch (_) {
      return [];
    }
  }
}
