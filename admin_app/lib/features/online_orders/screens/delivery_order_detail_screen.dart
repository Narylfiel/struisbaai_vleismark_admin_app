import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/delivery_label_print_service.dart';
import '../repositories/online_orders_repository.dart';

/// Delivery Order Detail Screen
/// 
/// Features:
/// - FIX D: Runtime guards (no asserts)
/// - FIX 4: Double pack protection
/// - FIX 5: Uses auth.uid() directly as staff_id
/// - FIX 7.1: Uses 'total' column
/// - FIX 7.2: Uses 'special_instructions' column
/// - FIX 7.3 & FIX E: Timestamp-aware status
/// - FIX A: Payment status normalization
class DeliveryOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const DeliveryOrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<DeliveryOrderDetailScreen> createState() =>
      _DeliveryOrderDetailScreenState();
}

class _DeliveryOrderDetailScreenState extends State<DeliveryOrderDetailScreen> {
  final _supabase = SupabaseService.client;
  late OnlineOrdersRepository _repository;
  final DeliveryLabelPrintService _labelService = DeliveryLabelPrintService.instance;

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _items = [];
  String? _staffId;
  // FIX 2: Double-tap protection flag
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _repository = OnlineOrdersRepository(_supabase);
    _initializeStaffId();
    _loadOrder();
  }

  /// FIX 5: STAFF ID USAGE
  /// Use auth.uid() directly, validate staff profile exists
  Future<void> _initializeStaffId() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final currentUserId = currentUser.id;

      // Validate staff profile exists
      final staffProfile = await _supabase
          .from('staff_profiles')
          .select('id, full_name, role')
          .eq('id', currentUserId)
          .maybeSingle();

      // FIX 1: Staff profile guard - explicit check
      if (staffProfile == null) {
        throw Exception('Staff profile not linked. Contact admin.');
      }

      if (mounted) {
        setState(() {
          _staffId = currentUserId;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Staff ID resolution failed: $e';
        });
      }
    }
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);
    try {
      final orderRes = await _supabase
          .from('online_orders')
          .select('''
            *,
            loyalty_customers!customer_id(id, full_name, phone, email, loyalty_tier, points_balance)
          ''')
          .eq('id', widget.orderId)
          .single();

      final itemsRes = await _supabase
          .from('online_order_items')
          .select('''
            *,
            inventory_items!product_id(product_name, plu_code, item_type)
          ''')
          .eq('order_id', widget.orderId)
          .order('created_at');

      // FIX D: Runtime guard - ensure this is a delivery order
      if (orderRes['is_delivery'] != true) {
        throw Exception(
          'ARCHITECTURE VIOLATION: Delivery screen received retail order (ID: ${orderRes['id']})',
        );
      }

      if (mounted) {
        setState(() {
          _order = Map<String, dynamic>.from(orderRes);
          _items = List<Map<String, dynamic>>.from(itemsRes);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[DELIVERY_DETAIL] Load error: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: AppColors.cardBg,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadOrder,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_order == null) {
      return const Scaffold(
        body: Center(child: Text('Order not found')),
      );
    }

    final orderNumber = _order!['order_number'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text('Delivery Order $orderNumber'),
        backgroundColor: AppColors.cardBg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrder,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderInfoCard(),
            const SizedBox(height: 16),
            _buildCustomerInfoCard(),
            const SizedBox(height: 16),
            _buildDeliveryInfoCard(),
            const SizedBox(height: 16),
            _buildItemsCard(),
            const SizedBox(height: 16),
            _buildActionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    final status = _order!['status'] as String? ?? '';
    final paymentStatus = _order!['payment_status'] as String? ?? '';
    final paymentMethod = _order!['payment_method'] as String? ?? '';
    // FIX 7.1: Use 'total' column
    final total = (_order!['total'] as num?)?.toDouble() ?? 0.0;

    return _buildCard(
      'Order Information',
      [
        _buildInfoRow('Order Number', _order!['order_number'] ?? 'N/A'),
        _buildInfoRow('Status', _formatStatus(status)),
        _buildInfoRow('Payment Status', _formatPaymentStatus(paymentStatus)),
        _buildInfoRow('Payment Method', _formatPaymentMethod(paymentMethod)),
        _buildInfoRow('Total', 'R ${total.toStringAsFixed(2)}'),
      ],
    );
  }

  Widget _buildCustomerInfoCard() {
    final customer = _order!['loyalty_customers'] as Map<String, dynamic>?;

    return _buildCard(
      'Customer Information',
      [
        _buildInfoRow('Name', customer?['full_name'] ?? 'N/A'),
        _buildInfoRow('Phone', customer?['phone'] ?? 'N/A'),
        _buildInfoRow('Email', customer?['email'] ?? 'N/A'),
        if (customer?['loyalty_tier'] != null)
          _buildInfoRow('Loyalty Tier', customer?['loyalty_tier']),
      ],
    );
  }

  Widget _buildDeliveryInfoCard() {
    final packedAt = _order!['packed_at'];
    final dispatchedAt = _order!['dispatched_at'];
    final deliveredAt = _order!['delivered_at'];

    return _buildCard(
      'Delivery Information',
      [
        _buildInfoRow('Delivery Date', _order!['delivery_date'] ?? 'N/A'),
        _buildInfoRow('Delivery Zone', _order!['delivery_zone'] ?? 'N/A'),
        _buildInfoRow('Address', _order!['delivery_address'] ?? 'N/A'),
        // FIX 7.2: Use 'special_instructions' column
        if (_order!['special_instructions'] != null)
          _buildInfoRow('Instructions', _order!['special_instructions']),
        const Divider(height: 16),
        // FIX 7.3 & FIX E: Show timestamps
        if (packedAt != null)
          _buildInfoRow('Packed At', _formatTimestamp(packedAt)),
        if (dispatchedAt != null)
          _buildInfoRow('Dispatched At', _formatTimestamp(dispatchedAt)),
        if (deliveredAt != null)
          _buildInfoRow('Delivered At', _formatTimestamp(deliveredAt)),
      ],
    );
  }

  Widget _buildItemsCard() {
    return _buildCard(
      'Items (${_items.length})',
      _items.map((item) {
        final product = item['inventory_items'] as Map<String, dynamic>?;
        final quantity = item['quantity'] as int? ?? 0;
        final price = (item['price_at_time'] as num?)?.toDouble() ?? 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product?['product_name'] ?? 'Unknown Product',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Qty: $quantity',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'R ${(price * quantity).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionsCard() {
    // FIX 5: Staff ID must be resolved
    if (_staffId == null) {
      return Card(
        color: AppColors.error.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  // FIX 1: Specific error message
                  'Staff profile not linked. Contact admin.',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final status = _order!['status'] as String? ?? '';
    final paymentStatus = _order!['payment_status'] as String? ?? '';
    final packedAt = _order!['packed_at'];
    final dispatchedAt = _order!['dispatched_at'];
    final deliveredAt = _order!['delivered_at'];

    // FIX A: Payment status normalization
    final isPendingEft = paymentStatus == 'pending_eft' ||
        paymentStatus == 'pending_payment';

    // IMPROVEMENT 1: Global button disable state
    final isDisabled = _isProcessing || _staffId == null;

    return _buildCard(
      'Actions',
      [
        // IMPROVEMENT 1: Confirm EFT with loading state
        if (isPendingEft && status != 'cancelled')
          _buildActionButton(
            label: 'Confirm EFT Payment',
            color: AppColors.info,
            onPressed: isDisabled ? null : _confirmEft,
            isLoading: _isProcessing,
          ),

        // IMPROVEMENT 1: Mark as Packed with loading state
        // FIX 4: Double pack protection
        // FIX 7.3: Check packedAt timestamp
        if (status == 'confirmed' && packedAt == null && paymentStatus == 'paid')
          _buildActionButton(
            label: 'Mark as Packed',
            color: AppColors.warning,
            onPressed: isDisabled ? null : _markAsPacked,
            isLoading: _isProcessing,
          ),

        // Show packed status
        if (packedAt != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Packed at: ${_formatTimestamp(packedAt)}',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // IMPROVEMENT 1: Mark Dispatched with loading state
        // FIX 7.3 & FIX E: Use timestamps for dispatch/deliver guards
        if (packedAt != null && dispatchedAt == null && deliveredAt == null)
          _buildActionButton(
            label: 'Mark Dispatched',
            color: Colors.blue,
            onPressed: isDisabled ? null : _markDispatched,
            isLoading: _isProcessing,
          ),

        // Show dispatched status
        if (dispatchedAt != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Dispatched at: ${_formatTimestamp(dispatchedAt)}',
                  style: TextStyle(color: Colors.blue),
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // IMPROVEMENT 1: Mark Delivered with loading state
        if (dispatchedAt != null && deliveredAt == null)
          _buildActionButton(
            label: 'Mark Delivered',
            color: Colors.green,
            onPressed: isDisabled ? null : _markDelivered,
            isLoading: _isProcessing,
          ),

        // Show delivered status
        if (deliveredAt != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Delivered at: ${_formatTimestamp(deliveredAt)}',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Card(
      color: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // IMPROVEMENT 1: Loading state support for action buttons
  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            // Fade button slightly when disabled
            disabledBackgroundColor: color.withOpacity(0.6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading) ...[
                SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  String _formatStatus(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  String _formatPaymentStatus(String status) {
    switch (status) {
      case 'pending_eft':
      case 'pending_payment':
        return 'PENDING EFT';
      case 'paid':
        return 'PAID';
      case 'unpaid':
        return 'UNPAID';
      default:
        return status.toUpperCase();
    }
  }

  String _formatPaymentMethod(String method) {
    switch (method) {
      case 'cod':
        return 'Cash on Delivery';
      case 'payfast':
        return 'PayFast';
      case 'eft':
        return 'EFT Bank Transfer';
      default:
        return method.toUpperCase();
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    final date = DateTime.tryParse(timestamp.toString());
    if (date == null) return timestamp.toString();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // ── Action Handlers ─────────────────────────────────────────────────

  Future<void> _confirmEft() async {
    // FIX 1: Staff profile guard
    if (_staffId == null) return;
    // FIX 2: Double-tap protection
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      await _repository.updateStatus(widget.orderId, 'confirmed', _staffId!);
      await _loadOrder();

      // IMPROVEMENT 2: Success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment confirmed successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // IMPROVEMENT 3: Error feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Action failed. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      // FIX 2: Reset processing flag
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _markAsPacked() async {
    // FIX 4: Double pack protection
    if (_order?['packed_at'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order already packed')),
      );
      return;
    }
    // FIX 1: Staff profile guard
    if (_staffId == null) return;
    // FIX 2: Double-tap protection
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      await _repository.markAsPacked(widget.orderId, _staffId!);
      
      // Queue delivery label for printing
      try {
        await _labelService.queueDeliveryLabel(
          orderId: widget.orderId,
          labelData: _order ?? {},
        );
        debugPrint('[DELIVERY_ORDER] Label queued for order ${widget.orderId}');
      } catch (labelError) {
        debugPrint('[DELIVERY_ORDER] Failed to queue label: $labelError');
        // Don't fail the packing operation if label queuing fails
      }
      
      await _loadOrder();

      // IMPROVEMENT 2: Success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as packed - delivery label queued'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // IMPROVEMENT 3: Error feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Action failed. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      // FIX 2: Reset processing flag
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _markDispatched() async {
    // FIX 1: Staff profile guard
    if (_staffId == null) return;
    // FIX 2: Double-tap protection
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      await _repository.updateStatus(widget.orderId, 'dispatched', _staffId!);
      await _loadOrder();

      // IMPROVEMENT 2: Success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order dispatched'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // IMPROVEMENT 3: Error feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Action failed. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      // FIX 2: Reset processing flag
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _markDelivered() async {
    // FIX 1: Staff profile guard
    if (_staffId == null) return;
    // FIX 2: Double-tap protection
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      await _repository.updateStatus(widget.orderId, 'delivered', _staffId!);
      await _loadOrder();

      // IMPROVEMENT 2: Success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order delivered'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // IMPROVEMENT 3: Error feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Action failed. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      // FIX 2: Reset processing flag
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
