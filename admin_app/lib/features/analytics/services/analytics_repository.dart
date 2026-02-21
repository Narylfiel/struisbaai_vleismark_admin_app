import 'package:supabase_flutter/supabase_flutter.dart';

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
      : _client = client ?? Supabase.instance.client;

  // ═════════════════════════════════════════════════════════
  // 1. SHRINKAGE ALERTS
  // ═════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> getShrinkageAlerts() async {
    try {
      final response = await _client
          .from('shrinkage_alerts')
          .select()
          .order('created_at', ascending: false)
          .limit(50); // Pagination / limit for safety
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
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
  // 2. DYNAMIC PRICING SUGGESTIONS
  // ═════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> getPricingSuggestions() async {
    try {
      final response = await _client
          .from('supplier_price_changes')
          .select()
          .eq('status', 'Pending')
          .order('created_at', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Will return empty if table missing, preventing crashes.
      return [];
    }
  }

  Future<void> updatePricingSuggestion(String id, String status) async {
    await _client.from('supplier_price_changes').update({'status': status}).eq('id', id);
  }

  // ═════════════════════════════════════════════════════════
  // 3. PREDICTIVE REORDER
  // ═════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> getReorderRecommendations() async {
    try {
      final response = await _client
          .from('reorder_recommendations')
          .select()
          .order('days_remaining', ascending: true)
          .limit(50);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // ═════════════════════════════════════════════════════════
  // 4. EVENT TAG FORECASTING
  // ═════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> getRecentEvents() async {
    try {
      // Spikes identified by system awaiting tagging
      final response = await _client
          .from('event_sales_history')
          .select()
          .isFilter('event_tag_id', null)
          .order('date', ascending: false)
          .limit(5);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getHistoricalEventTags() async {
    try {
      final response = await _client
          .from('event_tags')
          .select()
          .order('date', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> saveEventTag(String eventType, String description) async {
    try {
      await _client.from('event_tags').insert({
        'event_type': eventType,
        'description': description,
        'date': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getForecastForEvent(String eventType) async {
    try {
      final response = await _client.rpc('get_event_forecast', params: {'p_event_type': eventType});
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      return [];
    }
  }
}
