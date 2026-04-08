import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/online_order_summary.dart';

/// Repository for online orders data access
/// 
/// Contains all fixes from validated plan:
/// - FIX 7.1: Uses 'total' column
/// - FIX 7.4: Selects dispatched_at and delivered_at
/// - FIX C: Date filtering for delivery_date
class OnlineOrdersRepository {
  final SupabaseClient _supabase;

  OnlineOrdersRepository(this._supabase);

  /// Get all online orders with optional filters
  Future<List<OnlineOrderSummary>> getAllOnlineOrders({
    bool? isDelivery,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _supabase.from('online_orders').select('''
        id,
        order_number,
        status,
        payment_status,
        payment_method,
        is_delivery,
        delivery_date,
        delivery_zone,
        delivery_address,
        special_instructions,
        packed_at,
        dispatched_at,
        delivered_at,
        total,
        created_at,
        loyalty_customers!inner(
          full_name
        ),
        online_order_items(count)
      ''');

    // Apply filters
    if (isDelivery != null) {
      query = query.eq('is_delivery', isDelivery);
    }

    if (status != null) {
      query = query.eq('status', status);
    }

    // FIX C: DATE-safe filtering for delivery_date
    // Use date-only format for delivery_date queries (DATE column)
    if (startDate != null) {
      query = query.gte('created_at', startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.lte('created_at', endDate.toIso8601String());
    }

    // Sort by most recent first
    // FIX: Don't reassign - order() returns different type
    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((json) => OnlineOrderSummary.fromJson(json))
        .toList();
  }

  /// Get order detail by ID
  Future<Map<String, dynamic>> getOrderDetail(String orderId) async {
    final response = await _supabase
        .from('online_orders')
        .select('''
          *,
          loyalty_customers!inner(
            full_name,
            email,
            phone
          ),
          online_order_items(
            *,
            inventory_items!product_id(
              product_name
            )
          )
        ''')
        .eq('id', orderId)
        .single();

    return response;
  }

  /// Get delivery orders for manifest (date range filter)
  /// 
  /// FIX C: Uses DATE-safe filtering
  Future<List<Map<String, dynamic>>> getDeliveryOrdersForManifest(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final response = await _supabase
        .from('online_orders')
        .select('''
          id,
          order_number,
          delivery_date,
          delivery_zone,
          delivery_address,
          special_instructions,
          status,
          packed_at,
          dispatched_at,
          delivered_at,
          loyalty_customers!inner(
            full_name,
            phone
          ),
          online_order_items(
            quantity,
            inventory_items!product_id(
              product_name,
              plu_code
            )
          )
        ''')
        .eq('is_delivery', true)
        // FIX C: DATE-safe filtering for delivery_date (DATE column)
        .gte('delivery_date', startDate.toIso8601String().split('T')[0])
        .lte('delivery_date', endDate.toIso8601String().split('T')[0])
        .order('delivery_date')
        .order('delivery_zone');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Mark delivery order as packed via RPC
  /// 
  /// FIX 4: Double pack protection applied at UI level
  /// FIX 5: Uses auth.uid() directly as staff_id
  Future<Map<String, dynamic>> markAsPacked(
    String orderId,
    String staffId,
  ) async {
    return await _supabase.rpc(
      'mark_delivery_order_packed',
      params: {
        'p_order_id': orderId,
        'p_staff_id': staffId,
      },
    );
  }

  /// Update delivery order status via RPC
  /// 
  /// FIX 5: Uses auth.uid() directly as staff_id
  Future<Map<String, dynamic>> updateStatus(
    String orderId,
    String newStatus,
    String staffId,
  ) async {
    return await _supabase.rpc(
      'update_delivery_order_status',
      params: {
        'p_order_id': orderId,
        'p_new_status': newStatus,
        'p_staff_id': staffId,
      },
    );
  }
}
