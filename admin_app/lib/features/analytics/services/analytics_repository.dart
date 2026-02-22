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
    await _client.from('shrinkage_alerts').update({'status': newStatus}).eq('id', alertId);
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
          .select('id, name, selling_price, sell_price, average_cost, cost_price')
          .eq('is_active', true);
      const targetMarginPct = 30.0;
      final suggestions = <Map<String, dynamic>>[];
      for (final r in rows as List) {
        final map = Map<String, dynamic>.from(r as Map<String, dynamic>);
        final sell = (map['selling_price'] as num?)?.toDouble() ?? (map['sell_price'] as num?)?.toDouble() ?? 0;
        final cost = (map['average_cost'] as num?)?.toDouble() ?? (map['cost_price'] as num?)?.toDouble() ?? 0;
        if (cost <= 0 || sell <= 0) continue;
        final marginPct = ((sell - cost) / sell) * 100;
        if (marginPct >= targetMarginPct) continue;
        final suggested = cost / (1 - targetMarginPct / 100);
        suggestions.add({
          'id': map['id'],
          'product_name': map['name'],
          'current_sell_price': sell.toStringAsFixed(2),
          'suggested_sell_price': suggested.toStringAsFixed(2),
          'margin_impact': '${marginPct.toStringAsFixed(1)}% → ${targetMarginPct.toStringAsFixed(0)}% target',
          'supplier_name': '—',
          'percentage_increase': ((suggested - sell) / sell * 100).toStringAsFixed(1),
        });
      }
      return suggestions.take(20).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> updatePricingSuggestion(String id, String status) async {
    await _client.from('supplier_price_changes').update({'status': status}).eq('id', id);
  }

  // ═════════════════════════════════════════════════════════
  // 3. PREDICTIVE REORDER (reorder_recommendations or inventory + velocity)
  // ═════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> getReorderRecommendations() async {
    try {
      final response = await _client
          .from('reorder_recommendations')
          .select()
          .order('days_remaining', ascending: true)
          .limit(50);
      final list = List<Map<String, dynamic>>.from(response);
      for (final r in list) {
        final inv = (r['inventory_items'] as Map?);
        if (inv != null) r['product_name'] = inv['name'];
        r['days_remaining'] ??= r['days_of_stock'];
        r['recommendation_text'] ??= _reorderRecommendationText(r['days_remaining'], r['status']);
      }
      if (list.isNotEmpty) return list;
    } catch (_) {}
    return _getReorderFromInventoryAndVelocity();
  }

  String _reorderRecommendationText(dynamic days, dynamic status) {
    final d = (days is num) ? days.toDouble() : double.tryParse(days?.toString() ?? '') ?? 0;
    if (status == 'URGENT' || d < 2) return 'Order NOW';
    if (status == 'WARNING' || d < 5) return 'Order by Friday';
    return 'OK for now';
  }

  Future<List<Map<String, dynamic>>> _getReorderFromInventoryAndVelocity() async {
    try {
      final invRows = await _client
          .from('inventory_items')
          .select('id, name, current_stock, reorder_point, reorder_level')
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
          final stock = (map['current_stock'] as num?)?.toDouble() ?? 0;
          final reorder = (map['reorder_point'] as num?)?.toDouble() ?? (map['reorder_level'] as num?)?.toDouble() ?? 0;
          if (reorder <= 0) continue;
          if (stock > reorder) continue;
          recs.add({
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
        final reorder = (map['reorder_point'] as num?)?.toDouble() ?? (map['reorder_level'] as num?)?.toDouble() ?? 0;
        if (reorder <= 0) continue;
        final sold7 = qtyByItem[id] ?? 0;
        final dailyVelocity = sold7 / 7;
        double daysRemaining = dailyVelocity > 0 ? stock / dailyVelocity : 999;
        if (daysRemaining > 999) daysRemaining = 999;
        String status = 'OK';
        if (stock <= reorder || daysRemaining < 2) status = 'URGENT';
        else if (daysRemaining < 5) status = 'WARNING';
        recs.add({
          'product_name': map['name'],
          'days_remaining': daysRemaining.toStringAsFixed(1),
          'recommendation_text': _reorderRecommendationText(daysRemaining, status),
          'status': status,
          'current_stock': stock,
          'reorder_point': reorder,
        });
      }
      recs.sort((a, b) => (a['days_remaining'] as String).compareTo(b['days_remaining'] as String));
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
    } catch (_) {}
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
