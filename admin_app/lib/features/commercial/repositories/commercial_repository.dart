import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';

/// Read-only + workflow RPCs for [commercial_actions]. No pricing recalculation.
class CommercialRepository {
  CommercialRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  /// Single source for inventory UUID on a `commercial_actions` row.
  static String? inventoryItemIdFromCommercialRow(Map<String, dynamic> m) {
    final v = m['inventory_item_id'] ?? m['product_id'] ?? m['item_id'];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// Count-only for dashboard summary (scales without loading full rows).
  Future<int> getPendingReviewCount() async {
    final res = await _client
        .from('commercial_actions')
        .select('id')
        .eq('status', 'pending_review')
        .count(CountOption.exact);
    return res.count;
  }

  /// Decision-engine rows for Dynamic Pricing tab (view-only); priority desc.
  Future<List<Map<String, dynamic>>> getPricingActions() async {
    final res = await _client
        .from('commercial_actions')
        .select('*')
        .inFilter('status', ['pending_review', 'approved'])
        .order('portfolio_priority_score', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  /// Pending manager review, highest portfolio priority first.
  Future<List<Map<String, dynamic>>> getPendingActions() async {
    final res = await _client
        .from('commercial_actions')
        .select('*')
        .eq('status', 'pending_review')
        .order('portfolio_priority_score', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  /// Inventory item UUIDs that have at least one pending_review action (single query).
  Future<Set<String>> getPendingActionInventoryItemIds() async {
    final res = await _client
        .from('commercial_actions')
        .select('item_id')
        .eq('status', 'pending_review');
    final out = <String>{};
    for (final row in res as List) {
      final m = Map<String, dynamic>.from(row as Map);
      final id = inventoryItemIdFromCommercialRow(m);
      if (id != null && id.isNotEmpty) out.add(id);
    }
    return out;
  }

  /// RPC args use `p_action_id` (same pattern as `p_order_id` elsewhere).
  /// If PostgREST returns a parameter mismatch, align with the SQL signature.
  Future<void> approveCommercialAction(String actionId) async {
    await _client.rpc(
      'approve_commercial_action',
      params: {'p_action_id': actionId},
    );
  }

  Future<void> rejectCommercialAction(String actionId) async {
    await _client.rpc(
      'reject_commercial_action',
      params: {'p_action_id': actionId},
    );
  }
}
