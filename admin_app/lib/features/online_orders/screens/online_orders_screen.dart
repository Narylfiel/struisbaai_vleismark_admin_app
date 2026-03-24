import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'online_order_detail_screen.dart';

class OnlineOrdersScreen extends StatefulWidget {
  const OnlineOrdersScreen({super.key});

  @override
  State<OnlineOrdersScreen> createState() => _OnlineOrdersScreenState();
}

class _OnlineOrdersScreenState extends State<OnlineOrdersScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = SupabaseService.client;
  late TabController _tabController;
  RealtimeChannel? _ordersChannel;

  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];

  // Tab filters
  static const _tabs = [
    'All',
    'Pending',
    'Confirmed',
    'Packing',
    'Ready',
    'Collected',
    'Cancelled',
  ];

  static const _tabStatusFilters = <String, List<String>>{
    'All': [],
    'Pending': ['pending_cod', 'pending_payment'],
    'Confirmed': ['confirmed'],
    'Packing': ['packing'],
    'Ready': ['ready'],
    'Collected': ['collected'],
    'Cancelled': ['cancelled', 'uncollected'],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadOrders();
    _subscribeOrders();
  }

  @override
  void dispose() {
    _ordersChannel?.unsubscribe();
    _tabController.dispose();
    super.dispose();
  }

  void _subscribeOrders() {
    _ordersChannel = _supabase
        .channel('admin-online-orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
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
    setState(() => _isLoading = true);
    try {
      final res = await _supabase
          .from('online_orders')
          .select('''
            *,
            loyalty_customers!customer_id(full_name, phone),
            online_order_items(count)
          ''')
          .order('created_at', ascending: false)
          .limit(200);

      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[ONLINE_ORDERS] Load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _filteredOrders(int tabIndex) {
    final tab = _tabs[tabIndex];
    final filters = _tabStatusFilters[tab] ?? [];
    if (filters.isEmpty) return _orders;
    return _orders
        .where((o) => filters.contains(o['status'] as String? ?? ''))
        .toList();
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
                const Text('Online Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                // Add any header actions here if needed in the future
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
              isScrollable: true,
              onTap: (_) => setState(() {}),
              tabs: _tabs.map((t) {
                final count = _filteredOrders(_tabs.indexOf(t)).length;
                return Tab(text: count > 0 ? '$t ($count)' : t);
              }).toList(),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Refresh button row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_orders.length} orders total',
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

          // Order list
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))
                : TabBarView(
                    controller: _tabController,
                    children: List.generate(_tabs.length, (tabIndex) {
                      final filtered = _filteredOrders(tabIndex);
                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            'No ${_tabs[tabIndex].toLowerCase()} orders',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return _OrderCard(
                              order: filtered[index],
                              onTap: () => _openOrderDetail(filtered[index]),
                            );
                          },
                        ),
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }

  void _openOrderDetail(Map<String, dynamic> order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OnlineOrderDetailScreen(
          orderId: order['id'] as String,
        ),
      ),
    ).then((_) => _loadOrders());
  }
}

// ── Order Card ─────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final orderNumber = order['order_number'] as String? ?? '';
    final status = order['status'] as String? ?? 'pending';
    final total = (order['total'] as num?)?.toDouble() ?? 0.0;
    final paymentMethod = order['payment_method'] as String? ?? 'cod';
    final createdAt =
        DateTime.tryParse(order['created_at'] as String? ?? '');
    final collectionDate = order['collection_date'] as String? ?? '';
    final collectionSlot = order['collection_slot'] as String? ?? '';
    final itemCount =
        (order['online_order_items'] as List?)?.length ?? 0;

    // Customer info from join
    final customer =
        order['loyalty_customers'] as Map<String, dynamic>?;
    final customerName = customer?['full_name'] as String? ?? 'Unknown';
    final customerPhone = customer?['phone'] as String? ?? '';

    final statusInfo = _statusInfo(status);

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
                          orderNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusInfo.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusInfo.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusInfo.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: paymentMethod == 'cod'
                                ? AppColors.textSecondary
                                    .withValues(alpha: 0.1)
                                : AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            paymentMethod == 'cod' ? 'COD' : 'PayFast',
                            style: TextStyle(
                              fontSize: 10,
                              color: paymentMethod == 'cod'
                                  ? AppColors.textSecondary
                                  : AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$customerName${customerPhone.isNotEmpty ? ' · $customerPhone' : ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (collectionDate.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Collect: $collectionDate${collectionSlot.isNotEmpty ? ' ($collectionSlot)' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Right: total, items, date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$itemCount items',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (createdAt != null)
                    Text(
                      '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 11,
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

  static _StatusInfo _statusInfo(String status) {
    switch (status) {
      case 'pending_cod':
      case 'pending_payment':
        return _StatusInfo('Pending', AppColors.textSecondary);
      case 'confirmed':
        return _StatusInfo('Confirmed', AppColors.info);
      case 'packing':
        return _StatusInfo('Packing', AppColors.warning);
      case 'ready':
        return _StatusInfo('Ready', AppColors.success);
      case 'collected':
        return _StatusInfo('Collected', AppColors.textSecondary);
      case 'cancelled':
        return _StatusInfo('Cancelled', AppColors.error);
      case 'uncollected':
        return _StatusInfo('Uncollected', AppColors.error);
      default:
        return _StatusInfo(status, AppColors.textSecondary);
    }
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  const _StatusInfo(this.label, this.color);
}
