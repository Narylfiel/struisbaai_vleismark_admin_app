import 'package:flutter/material.dart';

import 'models/order_type.dart';
import 'models/online_order_summary.dart';
import 'screens/delivery_order_detail_screen.dart';
import 'screens/online_order_detail_screen.dart';

/// Single entry point for opening online order detail (retail vs delivery).
/// Routing is driven only by [OnlineOrderSummary.type] (no extra business rules).
class OnlineOrderNavigator {
  OnlineOrderNavigator._();

  static bool _isNavigating = false;

  /// Opens the correct detail screen for [order].
  ///
  /// Returns when navigation is skipped (validation / guard) or when the pushed
  /// route is popped ([Navigator.push] completes). [onRoutePopped] is invoked
  /// only after a successful push, when the route is popped (not on skip).
  static Future<void> openOrder(
    BuildContext context,
    OnlineOrderSummary? order, {
    VoidCallback? onRoutePopped,
  }) async {
    if (order == null) {
      _logNav(
        event: 'blocked',
        reason: 'order_null',
      );
      _failClosedSnack(context, 'Invalid order');
      return;
    }

    final id = order.id.trim();
    if (id.isEmpty) {
      _logNav(
        event: 'blocked',
        reason: 'id_empty_or_whitespace',
        orderId: order.id.isEmpty ? '(empty)' : order.id,
      );
      _failClosedSnack(context, 'Invalid order');
      return;
    }

    if (_isNavigating) {
      _logNav(
        event: 'blocked',
        reason: 'navigation_guard',
        orderId: id,
      );
      return;
    }

    if (!context.mounted) {
      _logNav(
        event: 'blocked',
        reason: 'context_not_mounted',
        orderId: id,
      );
      return;
    }

    final isDelivery = order.type.isDelivery;

    try {
      _isNavigating = true;

      final String targetScreenName;
      final Widget page;
      if (isDelivery) {
        assert(order.type == OrderType.capeTownDelivery);
        assert(order.type != OrderType.clickCollect);
        targetScreenName = 'DeliveryOrderDetailScreen';
        page = DeliveryOrderDetailScreen(orderId: id);
      } else {
        assert(order.type == OrderType.clickCollect);
        assert(order.type != OrderType.capeTownDelivery);
        targetScreenName = 'OnlineOrderDetailScreen';
        page = OnlineOrderDetailScreen(orderId: id);
      }

      _logNav(
        event: 'navigate_push',
        orderId: id,
        routeType: isDelivery ? 'delivery' : 'retail',
        target: targetScreenName,
      );

      if (!context.mounted) {
        _logNav(
          event: 'blocked',
          reason: 'context_not_mounted_before_push',
          orderId: id,
        );
        return;
      }

      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => page),
      );
      onRoutePopped?.call();
    } catch (e, st) {
      _logNav(
        event: 'error',
        reason: 'navigation_failed',
        orderId: id,
        extra: '$e $st',
      );
    } finally {
      _isNavigating = false;
    }
  }

  static void _logNav({
    required String event,
    String? reason,
    String? orderId,
    String? routeType,
    String? target,
    String? extra,
  }) {
    final parts = <String>[
      'event=$event',
      if (reason != null) 'reason=$reason',
      if (orderId != null) 'order_id=$orderId',
      if (routeType != null) 'route_type=$routeType',
      if (target != null) 'target=$target',
      if (extra != null) 'detail=$extra',
    ];
    debugPrint('[ONLINE_ORDER_NAV] ${parts.join(' | ')}');
  }

  static void _failClosedSnack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
