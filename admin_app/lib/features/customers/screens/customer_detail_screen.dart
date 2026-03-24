import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> customer;
  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late Map<String, dynamic> _customer;
  bool _loading = false;
  late TabController _tabController;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _tabController = TabController(length: 2, vsync: this);
    _refreshCustomer();
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshCustomer() async {
    setState(() => _loading = true);
    try {
      final res = await Supabase.instance.client
          .from('loyalty_customers')
          .select()
          .eq('id', _customer['id'])
          .single();
      if (mounted) setState(() => _customer = res);
    } catch (e) {
      debugPrint('[CUSTOMER] Refresh failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadOrders() async {
    try {
      final res = await Supabase.instance.client
          .from('online_orders')
          .select('''
            *,
            online_order_items(count)
          ''')
          .eq('customer_id', _customer['id'])
          .order('created_at', ascending: false);
      
      if (mounted) setState(() => _orders = List<Map<String, dynamic>>.from(res));
    } catch (e) {
      debugPrint('Failed to load orders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final membership = _customer['membership_number'] as String? ?? '';
    final name = _customer['full_name'] as String? ?? '—';
    final tier = _customer['loyalty_tier'] as String? ?? 'Member';
    final points = _customer['points_balance'] as int? ?? 0;
    final spend = (_customer['total_spend'] as num?)?.toDouble() ?? 0.0;
    final visits = _customer['visit_count'] as int? ?? 0;
    final email = _customer['email'] as String? ?? '';
    final phone = _customer['phone'] as String? ?? '';
    final whatsapp = _customer['whatsapp'] as String? ?? '';
    final birthday = _customer['birthday'] as String? ?? '';
    final isActive = _customer['active'] as bool? ?? true;
    final joinedAt = _customer['joined_at'] != null
        ? DateTime.parse(_customer['joined_at'] as String)
        : null;

    Color tierColor = AppColors.textSecondary;
    if (tier == 'VIP') tierColor = AppColors.accent;
    if (tier == 'Elite') tierColor = AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        title: Text(name,
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _refreshCustomer();
              _loadOrders();
            },
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Orders'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(membership, name, tier, tierColor, isActive, joinedAt, birthday, email, phone, whatsapp, points, spend, visits),
                _buildOrdersTab(),
              ],
            ),
    );
  }

  Widget _buildDetailsTab(String membership, String name, String tier, Color tierColor, bool isActive, DateTime? joinedAt, String birthday, String email, String phone, String whatsapp, int points, double spend, int visits) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status banner ──────────────────────────
          if (!isActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error),
              ),
              child: const Text('SUSPENDED',
                  style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
            ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: Profile info ─────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section('PROFILE', [
                      _infoRow('Name', name),
                      _infoRow('Tier', tier,
                          valueColor: tierColor),
                      _infoRow('Status',
                          isActive ? 'Active' : 'Suspended',
                          valueColor: isActive
                              ? AppColors.success
                              : AppColors.error),
                      if (joinedAt != null)
                        _infoRow('Member Since',
                            '${joinedAt.day}/${joinedAt.month}/${joinedAt.year}'),
                      if (birthday.isNotEmpty)
                        _infoRow('Birthday', birthday),
                    ]),
                    const SizedBox(height: 16),
                    _section('CONTACT', [
                      if (email.isNotEmpty)
                        _infoRow('Email', email),
                      if (phone.isNotEmpty)
                        _infoRow('Phone', phone),
                      if (whatsapp.isNotEmpty)
                        _infoRow('WhatsApp', whatsapp),
                    ]),
                    const SizedBox(height: 16),
                    _section('LOYALTY STATS', [
                      _infoRow('Points Balance',
                          '$points pts'),
                      _infoRow('Total Spend',
                          'R${spend.toStringAsFixed(2)}'),
                      _infoRow('Total Visits',
                          '$visits visits'),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // ── Right: Membership barcode ──────────
              if (membership.isNotEmpty)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          BarcodeWidget(
                            barcode: Barcode.code128(),
                            data: membership,
                            width: 220,
                            height: 80,
                            drawText: false,
                            color: Colors.black,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            membership,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Scan at POS to link loyalty',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    if (_orders.isEmpty) {
      return const Center(
        child: Text(
          'No online orders yet',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        final orderNumber = order['order_number'] as String? ?? '';
        final createdAt = DateTime.tryParse(order['created_at'] as String? ?? '');
        final itemCount = (order['online_order_items'] as List?)?.length ?? 0;
        final total = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
        final paymentMethod = order['payment_method'] as String? ?? 'cod';
        final status = order['status'] as String? ?? 'pending';

        Color statusColor = AppColors.textSecondary;
        String statusText = 'Unknown';
        
        switch (status) {
          case 'pending_cod':
          case 'pending_payment':
            statusColor = AppColors.textSecondary;
            statusText = 'Pending';
            break;
          case 'confirmed':
            statusColor = AppColors.info;
            statusText = 'Confirmed';
            break;
          case 'packing':
            statusColor = AppColors.warning;
            statusText = 'Packing';
            break;
          case 'ready':
            statusColor = AppColors.success;
            statusText = 'Ready';
            break;
          case 'collected':
            statusColor = AppColors.textSecondary;
            statusText = 'Collected';
            break;
          case 'cancelled':
            statusColor = AppColors.error;
            statusText = 'Cancelled';
            break;
          case 'uncollected':
            statusColor = AppColors.error;
            statusText = 'Uncollected';
            break;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () => _showOrderDetails(order),
            title: Text(
              orderNumber,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  createdAt != null 
                      ? '${createdAt.day.toString().padLeft(2, '0')} ${_monthAbbrev(createdAt.month)} ${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
                      : 'Unknown date',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Chip(
                      label: Text(
                        paymentMethod == 'cod' ? 'COD' : 'PayFast',
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: paymentMethod == 'cod' 
                          ? AppColors.textSecondary.withValues(alpha: 0.1)
                          : AppColors.info.withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        color: paymentMethod == 'cod' 
                            ? AppColors.textSecondary
                            : AppColors.info,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        statusText,
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: statusColor.withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'R${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '$itemCount items',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(order['order_number'] ?? 'Order Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status: ${order['status']}'),
              Text('Total: R${(order['total_amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
              Text('Payment: ${order['payment_method']}'),
              const SizedBox(height: 16),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              // TODO: Load and display order items
              const Text('Order items loading...'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _monthAbbrev(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: valueColor ?? AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
