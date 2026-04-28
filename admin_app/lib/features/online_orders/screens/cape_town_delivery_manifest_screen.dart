import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import '../repositories/online_orders_repository.dart';
import '../widgets/route_order_dialog.dart';

/// Cape Town Delivery Manifest Screen
/// 
/// Features:
/// - Group by delivery_date and delivery_zone
/// - FIX C: DATE-safe filtering
/// - FIX 7.2: Uses 'special_instructions' column
class CapeTownDeliveryManifestScreen extends StatefulWidget {
  const CapeTownDeliveryManifestScreen({super.key});

  @override
  State<CapeTownDeliveryManifestScreen> createState() =>
      _CapeTownDeliveryManifestScreenState();
}

class _CapeTownDeliveryManifestScreenState
    extends State<CapeTownDeliveryManifestScreen> {
  final _supabase = SupabaseService.client;
  late OnlineOrdersRepository _repository;

  DateTime? _startDate;
  DateTime? _endDate;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = OnlineOrdersRepository(_supabase);
    // Default to next 7 days
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 7));
    _loadManifest();
  }

  Future<void> _loadManifest() async {
    if (_startDate == null || _endDate == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders = await _repository.getDeliveryOrdersForManifest(
        _startDate!,
        _endDate!,
      );

      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[MANIFEST] Load error: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Map<String, Map<String, List<Map<String, dynamic>>>> _groupOrders() {
    final grouped = <String, Map<String, List<Map<String, dynamic>>>>{};

    for (final order in _orders) {
      final date = order['delivery_date'] as String? ?? 'Unknown';
      final zone = order['delivery_zone'] as String? ?? 'Unknown';

      grouped.putIfAbsent(date, () => {});
      grouped[date]!.putIfAbsent(zone, () => []);
      grouped[date]![zone]!.add(order);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Delivery Manifest'),
        backgroundColor: AppColors.cardBg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadManifest,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error: $_error',
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadManifest,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No deliveries scheduled',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            Text(
              '${_startDate?.day}/${_startDate?.month} - ${_endDate?.day}/${_endDate?.month}',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _selectDateRange,
              child: const Text('Change Date Range'),
            ),
          ],
        ),
      );
    }

    final grouped = _groupOrders();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Date range header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Text(
                '${_orders.length} orders',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Date sections
        ...grouped.entries.map((dateEntry) {
          return _buildDateSection(dateEntry.key, dateEntry.value);
        }),
      ],
    );
  }

  Widget _buildDateSection(
    String date,
    Map<String, List<Map<String, dynamic>>> zones,
  ) {
    final totalOrders = zones.values.fold(0, (sum, orders) => sum + orders.length);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.cardBg,
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          'Delivery Date: $_formatDisplayDate(date)',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '$totalOrders orders across ${zones.length} zone${zones.length > 1 ? 's' : ''}',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        children: zones.entries.map((zoneEntry) {
          return _buildZoneSection(date, zoneEntry.key, zoneEntry.value);
        }).toList(),
      ),
    );
  }

  Widget _buildZoneSection(String date, String zone, List<Map<String, dynamic>> orders) {
    // Sort orders by route_order if available, otherwise by order_number
    final sortedOrders = List<Map<String, dynamic>>.from(orders);
    sortedOrders.sort((a, b) {
      final routeOrderA = a['route_order'] as int?;
      final routeOrderB = b['route_order'] as int?;
      
      if (routeOrderA != null && routeOrderB != null) {
        return routeOrderA.compareTo(routeOrderB);
      } else if (routeOrderA != null) {
        return -1;
      } else if (routeOrderB != null) {
        return 1;
      } else {
        return (a['order_number'] as String? ?? '').compareTo(b['order_number'] as String? ?? '');
      }
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Text(
              'Zone: $zone',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.sort, size: 16),
              onPressed: () => _showRouteOrderDialog(sortedOrders, zone),
              tooltip: 'Order Route',
            ),
          ],
        ),
        subtitle: Text(
          '${orders.length} order${orders.length > 1 ? 's' : ''}',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        children: sortedOrders.map((order) => _buildOrderTile(order, zone)).toList(),
      ),
    );
  }

  Future<void> _showRouteOrderDialog(List<Map<String, dynamic>> orders, String zone) async {
    await showDialog(
      context: context,
      builder: (context) => RouteOrderDialog(
        orders: orders,
        zone: zone,
        onSave: (updatedOrders) => _saveRouteOrder(updatedOrders),
      ),
    );
  }

  Future<void> _saveRouteOrder(List<Map<String, dynamic>> updatedOrders) async {
    try {
      for (int i = 0; i < updatedOrders.length; i++) {
        final order = updatedOrders[i];
        await _supabase
            .from('online_orders')
            .update({'route_order': i + 1})
            .eq('id', order['id']);
      }
      _loadManifest(); // Refresh the manifest
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save route order: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildOrderTile(Map<String, dynamic> order, String zone) {
    final customer = order['loyalty_customers'] as Map<String, dynamic>?;
    final items = order['online_order_items'] as List<dynamic>? ?? [];
    final status = order['status'] as String? ?? 'confirmed';
    final packedAt = order['packed_at'];
    final dispatchedAt = order['dispatched_at'];
    final deliveredAt = order['delivered_at'];
    final routeOrder = order['route_order'] as int?;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.primary,
        child: Text(
          '${routeOrder ?? '?'}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Row(
        children: [
          Text(
            order['order_number'] ?? 'Unknown',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          _buildStatusChip(status, packedAt, dispatchedAt, deliveredAt),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            'Customer: ${customer?['full_name'] ?? 'N/A'}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            'Phone: ${customer?['phone'] ?? 'N/A'}',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary.withOpacity(0.8),
            ),
          ),
          Text(
            'Address: ${order['delivery_address'] ?? 'N/A'}',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary.withOpacity(0.8),
            ),
          ),
          // FIX 7.2: Use 'special_instructions' column
          if (order['special_instructions'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Instructions: ${order['special_instructions']}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.orange,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 4),
          // FIX 3: Empty items safety
          if (items.isEmpty)
            Text(
              'No items',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Text(
              'Items: ${_groupAppOrderItems(items)}',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      isThreeLine: true,
    );
  }

  Widget _buildStatusChip(
    String status,
    dynamic packedAt,
    dynamic dispatchedAt,
    dynamic deliveredAt,
  ) {
    // FIX 7.3 & FIX E: Timestamp-aware status display
    Color color;
    String label;

    if (deliveredAt != null) {
      color = Colors.green;
      label = 'Delivered';
    } else if (dispatchedAt != null) {
      color = Colors.blue;
      label = 'Dispatched';
    } else if (packedAt != null) {
      color = AppColors.warning;
      label = 'Packed';
    } else {
      switch (status) {
        case 'confirmed':
          color = AppColors.info;
          label = 'Confirmed';
          break;
        case 'cancelled':
          color = AppColors.error;
          label = 'Cancelled';
          break;
        default:
          color = AppColors.textSecondary;
          label = status.toUpperCase();
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDateRange: DateTimeRange(
        start: _startDate!,
        end: _endDate!,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.cardBg,
              foregroundColor: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadManifest();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDisplayDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  /// APP ORDER GROUPING LOGIC
  /// Groups fixed-unit app order items (delivery + click & collect) by product_name + plu_code
  /// CRITICAL: This applies to ALL app orders (online_orders table)
  /// DO NOT use this logic for POS or in-store weight-based items
  String _groupAppOrderItems(List<dynamic> items) {
    // STEP 2: Group by product_name + plu_code
    final Map<String, int> grouped = {};

    for (final item in items) {
      final inv = item['inventory_items'] as Map<String, dynamic>?;

      // FIX 2: Quantity safety
      final qty = (item['quantity'] as num?)?.toInt() ?? 0;

      // FIX 1: NULL product safety with trim
      final productName = inv?['product_name']?.toString().trim();
      final safeName = (productName != null && productName.isNotEmpty)
          ? productName
          : 'Unknown Product';

      // IMPROVEMENT 1: PLU code
      final plu = inv?['plu_code']?.toString().trim() ?? '';

      // Group key: product_name|plu_code
      final key = '$safeName|$plu';

      // Accumulate quantities
      grouped[key] = (grouped[key] ?? 0) + qty;
    }

    // STEP 3: Convert to display format
    final displayItems = grouped.entries.map((entry) {
      final parts = entry.key.split('|');
      final name = parts[0];
      final plu = parts.length > 1 ? parts[1] : '';
      final totalQty = entry.value;

      return (plu.isNotEmpty)
          ? '$totalQty x $name ($plu)'
          : '$totalQty x $name';
    }).toList();

    return displayItems.join(', ');
  }
}
