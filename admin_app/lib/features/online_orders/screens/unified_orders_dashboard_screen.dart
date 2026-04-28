import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import '../models/order_type.dart';
import '../models/online_order_summary.dart';
import '../online_order_navigation.dart';
import '../repositories/online_orders_repository.dart';
import 'cape_town_delivery_manifest_screen.dart';

/// Unified Admin Online Orders Dashboard
/// 
/// Features:
/// - Three tabs: All Orders, Click & Collect, Cape Town Delivery
/// - Hard routing guards (delivery vs retail)
/// - Real-time updates (FIX F: Only INSERT/UPDATE)
/// - FIX D: Runtime guards instead of asserts
class UnifiedOrdersDashboardScreen extends StatefulWidget {
  const UnifiedOrdersDashboardScreen({super.key});

  @override
  State<UnifiedOrdersDashboardScreen> createState() =>
      _UnifiedOrdersDashboardScreenState();
}

class _UnifiedOrdersDashboardScreenState
    extends State<UnifiedOrdersDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = SupabaseService.client;
  late TabController _tabController;
  late OnlineOrdersRepository _repository;
  RealtimeChannel? _ordersChannel;

  bool _isLoading = true;
  String? _error;
  List<OnlineOrderSummary> _allOrders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _repository = OnlineOrdersRepository(_supabase);
    _loadOrders();
    _subscribeOrders();
  }

  @override
  void dispose() {
    _ordersChannel?.unsubscribe();
    _tabController.dispose();
    super.dispose();
  }

  /// FIX F: REALTIME PERFORMANCE GUARD
  /// Subscribe ONLY to INSERT and UPDATE, not DELETE
  void _subscribeOrders() {
    _ordersChannel = _supabase
        .channel('admin-unified-orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'online_orders',
          callback: (_) {
            if (mounted) _loadOrders();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'online_orders',
          callback: (_) {
            if (mounted) _loadOrders();
          },
        )
        .subscribe();
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders = await _repository.getAllOnlineOrders();
      if (mounted) {
        setState(() {
          _allOrders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[UNIFIED_ORDERS] Load error: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<OnlineOrderSummary> _getFilteredOrders(int tabIndex) {
    switch (tabIndex) {
      case 0: // All Orders
        return _allOrders;
      case 1: // Click & Collect
        return _allOrders.where((o) => o.type == OrderType.clickCollect).toList();
      case 2: // Cape Town Delivery
        return _allOrders.where((o) => o.type == OrderType.capeTownDelivery).toList();
      default:
        return _allOrders;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.cardBg,
            child: Row(
              children: [
                const Text(
                  'Online Orders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Manifest button (only relevant for delivery)
                IconButton(
                  icon: const Icon(Icons.local_shipping_outlined),
                  onPressed: () => _openManifestScreen(),
                  tooltip: 'Delivery Manifest',
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Tab bar
          Container(
            color: AppColors.cardBg,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              onTap: (_) => setState(() {}),
              tabs: [
                _buildTab('All Orders', 0),
                _buildTab('Click & Collect', 1),
                _buildTab('Cape Town Delivery', 2),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_allOrders.length} orders total',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: _loadOrders,
                  tooltip: 'Refresh',
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),

          // Error display
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.error.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Error: $_error',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadOrders,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),

          // Order list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrdersList(0),
                      _buildOrdersList(1),
                      _buildOrdersList(2),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Tab _buildTab(String label, int index) {
    final count = _getFilteredOrders(index).length;
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrdersList(int tabIndex) {
    final orders = _getFilteredOrders(tabIndex);

    if (orders.isEmpty) {
      return const Center(
        child: Text(
          'No orders found',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _UnifiedOrderCard(
            order: orders[index],
            onTap: () async {
              await _navigateToDetail(orders[index]);
            },
          );
        },
      ),
    );
  }

  Future<void> _navigateToDetail(OnlineOrderSummary order) async {
    await OnlineOrderNavigator.openOrder(
      context,
      order,
      onRoutePopped: () {
        if (!mounted) return;
        _loadOrders();
      },
    );
  }

  void _openManifestScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CapeTownDeliveryManifestScreen(),
      ),
    );
  }
}

// ── Unified Order Card ─────────────────────────────────────────────────

class _UnifiedOrderCard extends StatelessWidget {
  final OnlineOrderSummary order;
  final VoidCallback onTap;

  const _UnifiedOrderCard({
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayStatus = order.displayStatus;
    final statusColor = _getStatusColor(displayStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.cardBg,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Left: order info
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          order.orderNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Type badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: order.type.isDelivery
                                ? Colors.blue.withOpacity(0.12)
                                : Colors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            order.type.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: order.type.isDelivery
                                  ? Colors.blue
                                  : Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            displayStatus.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.customerName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    // Delivery info (only for delivery)
                    if (order.type.isDelivery) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${order.relevantDate}${order.zoneDisplay.isNotEmpty ? ' · Zone: ${order.zoneDisplay}' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Right: total, items
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.itemCount} items',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(OrderDisplayStatus status) {
    switch (status) {
      case OrderDisplayStatus.pendingPayment:
      case OrderDisplayStatus.awaitingConfirmation:
        return AppColors.textSecondary;
      case OrderDisplayStatus.confirmed:
      case OrderDisplayStatus.readyForPacking:
        return AppColors.info;
      case OrderDisplayStatus.packed:
        return AppColors.warning;
      case OrderDisplayStatus.dispatched:
        return Colors.blue;
      case OrderDisplayStatus.delivered:
      case OrderDisplayStatus.readyForCollection:
      case OrderDisplayStatus.collected:
        return AppColors.success;
      case OrderDisplayStatus.cancelled:
        return AppColors.error;
    }
  }
}
