/// Order type enumeration for unified online orders
/// 
/// FIX A: Payment status normalization applied
/// All logic branches on is_delivery flag
enum OrderType {
  clickCollect,
  capeTownDelivery;

  static OrderType fromIsDelivery(bool isDelivery) {
    return isDelivery ? capeTownDelivery : clickCollect;
  }

  String get displayName {
    switch (this) {
      case OrderType.clickCollect:
        return 'Click & Collect';
      case OrderType.capeTownDelivery:
        return 'Cape Town Delivery';
    }
  }

  bool get isDelivery => this == OrderType.capeTownDelivery;
}

/// Order display status for UI rendering
enum OrderDisplayStatus {
  pendingPayment,
  awaitingConfirmation,
  confirmed,
  readyForPacking,
  packed,
  dispatched,
  delivered,
  readyForCollection,
  collected,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderDisplayStatus.pendingPayment:
        return 'Pending Payment';
      case OrderDisplayStatus.awaitingConfirmation:
        return 'Awaiting EFT Confirmation';
      case OrderDisplayStatus.confirmed:
        return 'Confirmed';
      case OrderDisplayStatus.readyForPacking:
        return 'Ready for Packing';
      case OrderDisplayStatus.packed:
        return 'Packed';
      case OrderDisplayStatus.dispatched:
        return 'Dispatched';
      case OrderDisplayStatus.delivered:
        return 'Delivered';
      case OrderDisplayStatus.readyForCollection:
        return 'Ready for Collection';
      case OrderDisplayStatus.collected:
        return 'Collected';
      case OrderDisplayStatus.cancelled:
        return 'Cancelled';
    }
  }
}
