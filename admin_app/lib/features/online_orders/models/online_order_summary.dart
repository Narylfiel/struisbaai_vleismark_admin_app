import 'package:flutter/foundation.dart';
import 'order_type.dart';

/// Online Order Summary model
/// 
/// Contains all fixes from validated plan:
/// - FIX 7.1: Uses 'total' column (not 'total_amount')
/// - FIX 7.2: Uses 'special_instructions' column (not 'delivery_instructions')
/// - FIX 7.3: Timestamp-aware delivery status
/// - FIX 7.4: dispatchedAt and deliveredAt fields
/// - FIX B: Item count from Supabase count format
class OnlineOrderSummary {
  final String id;
  final String orderNumber;
  final String customerName;
  final OrderType type;
  final String rawStatus;
  final String paymentStatus;
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime? deliveryDate;
  final String? deliveryZone;
  final String? deliveryAddress;
  final String? specialInstructions;
  final DateTime? packedAt;
  final DateTime? dispatchedAt;
  final DateTime? deliveredAt;
  final double totalAmount;
  final int itemCount;

  OnlineOrderSummary({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.type,
    required this.rawStatus,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.createdAt,
    this.deliveryDate,
    this.deliveryZone,
    this.deliveryAddress,
    this.specialInstructions,
    this.packedAt,
    this.dispatchedAt,
    this.deliveredAt,
    required this.totalAmount,
    required this.itemCount,
  });

  factory OnlineOrderSummary.fromJson(Map<String, dynamic> json) {
    final isDelivery = json['is_delivery'] as bool? ?? false;
    final customer = json['loyalty_customers'] as Map<String, dynamic>?;

    // FIX B: Item count from Supabase count() response format
    final itemCount = json['online_order_items'] is Map
        ? (json['online_order_items']['count'] as int? ?? 0)
        : (json['online_order_items'] as List?)?.length ?? 0;

    return OnlineOrderSummary(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      customerName: customer?['full_name'] as String? ?? 'Unknown',
      type: OrderType.fromIsDelivery(isDelivery),
      rawStatus: json['status'] as String,
      paymentStatus: json['payment_status'] as String,
      paymentMethod: json['payment_method'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      deliveryDate: json['delivery_date'] != null
          ? DateTime.tryParse(json['delivery_date'] as String)
          : null,
      deliveryZone: json['delivery_zone'] as String?,
      deliveryAddress: json['delivery_address'] as String?,
      // FIX 7.2: Correct column name
      specialInstructions: json['special_instructions'] as String?,
      packedAt: json['packed_at'] != null
          ? DateTime.tryParse(json['packed_at'] as String)
          : null,
      // FIX 7.4: Map new timestamp fields
      dispatchedAt: json['dispatched_at'] != null
          ? DateTime.tryParse(json['dispatched_at'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'] as String)
          : null,
      // FIX 7.1: Correct column name is 'total', NOT 'total_amount'
      totalAmount: (json['total'] as num?)?.toDouble() ?? 0.0,
      itemCount: itemCount,
    );
  }

  /// Derive display status from raw data
  /// 
  /// FIX 7.3 & FIX E: TIMESTAMP-AWARE DELIVERY STATUS
  /// Use actual timestamps as primary signals, status field as fallback
  OrderDisplayStatus get displayStatus {
    // Cancelled overrides everything
    if (rawStatus == 'cancelled') {
      return OrderDisplayStatus.cancelled;
    }

    // FIX A: Payment status normalization
    // Handle both 'pending_payment' and 'pending_eft'
    final isPendingPayment = paymentStatus == 'pending_payment' ||
        paymentStatus == 'pending_eft' ||
        paymentStatus == 'pending';

    if (isPendingPayment) {
      return paymentStatus == 'pending_eft'
          ? OrderDisplayStatus.awaitingConfirmation
          : OrderDisplayStatus.pendingPayment;
    }

    // FIX 7.3 & FIX E: TIMESTAMP-AWARE DELIVERY STATUS
    // Priority: delivered_at > dispatched_at > packed_at
    if (type == OrderType.capeTownDelivery) {
      if (deliveredAt != null) return OrderDisplayStatus.delivered;
      if (dispatchedAt != null) return OrderDisplayStatus.dispatched;
      if (packedAt != null) return OrderDisplayStatus.packed;
      if (rawStatus == 'confirmed') return OrderDisplayStatus.readyForPacking;
    }

    // Retail flow (Click & Collect)
    if (type == OrderType.clickCollect) {
      if (rawStatus == 'collected') return OrderDisplayStatus.collected;
      if (rawStatus == 'ready') return OrderDisplayStatus.readyForCollection;
      if (rawStatus == 'confirmed') return OrderDisplayStatus.confirmed;
    }

    // Status fallback safety - log warning for unknown
    // ignore: avoid_print
    print('WARNING: Unknown order status "$rawStatus" for order type $type');
    return OrderDisplayStatus.confirmed;
  }

  // Action availability flags

  /// FIX A: Payment status normalization
  bool get canConfirmEft {
    final isPendingEft = paymentStatus == 'pending_eft' ||
        paymentStatus == 'pending_payment';
    return isPendingEft && rawStatus != 'cancelled';
  }

  /// FIX 7.3 & FIX E: Can mark as packed
  bool get canMarkPacked {
    return type == OrderType.capeTownDelivery &&
        rawStatus == 'confirmed' &&
        packedAt == null &&
        paymentStatus == 'paid';
  }

  /// FIX 7.3 & FIX E: Can dispatch (use timestamps)
  bool get canDispatch {
    return type == OrderType.capeTownDelivery &&
        packedAt != null &&
        dispatchedAt == null &&
        deliveredAt == null;
  }

  /// FIX 7.3 & FIX E: Can deliver (use timestamps)
  bool get canDeliver {
    return type == OrderType.capeTownDelivery &&
        dispatchedAt != null &&
        deliveredAt == null;
  }

  /// Check if order is already packed (double pack protection)
  /// FIX 4: Double pack protection
  bool get isPacked => packedAt != null;

  // Display helpers
  String get relevantDate {
    if (type == OrderType.capeTownDelivery && deliveryDate != null) {
      return 'Delivery: ${_formatDate(deliveryDate!)}';
    }
    return 'Ordered: ${_formatDate(createdAt)}';
  }

  String get zoneDisplay {
    if (type == OrderType.capeTownDelivery && deliveryZone != null) {
      return deliveryZone!;
    }
    return '';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
