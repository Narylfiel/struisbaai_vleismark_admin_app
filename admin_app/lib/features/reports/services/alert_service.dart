/// Read-only alerts derived from pricing_intelligence row maps.
/// Does not query the database or mutate inputs.
class AlertService {
  AlertService._();

  static List<Map<String, dynamic>> generateAlerts(
    List<Map<String, dynamic>> rows,
  ) {
    final alerts = <Map<String, dynamic>>[];

    for (final row in rows) {
      final profit = (row['profit'] as num?)?.toDouble() ?? 0;
      final margin = (row['margin'] as num?)?.toDouble() ?? 0;
      final markup = (row['markup_pct'] as num?)?.toDouble();

      final productName = row['product_name']?.toString() ?? 'Product';
      final rawId = row['inventory_item_id']?.toString();
      final String? inventoryItemId = (rawId == null ||
              rawId.isEmpty ||
              rawId == 'unknown')
          ? null
          : rawId;

      if (profit < 0) {
        alerts.add({
          'type': 'loss',
          'alert_type': 'loss',
          'message': '$productName is losing money',
          'severity': 'high',
          'inventory_item_id': inventoryItemId,
        });
      } else if (margin < 10) {
        alerts.add({
          'type': 'critical_margin',
          'alert_type': 'critical_margin',
          'message': '$productName has critically low margin',
          'severity': 'high',
          'inventory_item_id': inventoryItemId,
        });
      } else if (margin < 20) {
        alerts.add({
          'type': 'low_margin',
          'alert_type': 'low_margin',
          'message': '$productName has low margin',
          'severity': 'medium',
          'inventory_item_id': inventoryItemId,
        });
      }

      if (markup != null && markup > 100) {
        alerts.add({
          'type': 'high_markup',
          'alert_type': 'high_markup',
          'message': '$productName may be overpriced',
          'severity': 'medium',
          'inventory_item_id': inventoryItemId,
        });
      }
    }

    return alerts;
  }
}
