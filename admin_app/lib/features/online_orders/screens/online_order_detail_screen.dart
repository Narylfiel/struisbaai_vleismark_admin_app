import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/config/edge_pipeline_config.dart';
import 'package:admin_app/core/services/edge_pipeline_client.dart';
import 'package:admin_app/core/services/supabase_service.dart';

class OnlineOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OnlineOrderDetailScreen({super.key, required this.orderId});

  @override
  State<OnlineOrderDetailScreen> createState() =>
      _OnlineOrderDetailScreenState();
}

class _OnlineOrderDetailScreenState extends State<OnlineOrderDetailScreen> {
  final _supabase = SupabaseService.client;
  bool _isLoading = true;
  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _items = [];

  // Status progression for the workflow
  static const _statusFlow = [
    'pending_cod',
    'pending_payment',
    'confirmed',
    'packing',
    'ready',
    'collected',
  ];

  @override
  void initState() {
    super.initState();
    _loadOrder();
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

      if (mounted) {
        setState(() {
          _order = Map<String, dynamic>.from(orderRes);
          _items = List<Map<String, dynamic>>.from(itemsRes);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[ORDER_DETAIL] Load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _nextStatus(String current) {
    switch (current) {
      case 'pending_cod':
      case 'pending_payment':
        return 'confirmed';
      case 'confirmed':
        return 'packing';
      case 'packing':
        return 'ready';
      case 'ready':
        return 'collected';
      default:
        return current;
    }
  }

  String _nextStatusLabel(String current) {
    switch (current) {
      case 'pending_cod':
      case 'pending_payment':
        return 'Confirm Order';
      case 'confirmed':
        return 'Start Packing';
      case 'packing':
        return 'Mark Ready';
      case 'ready':
        return 'Mark Collected';
      default:
        return '';
    }
  }

  Future<void> _advanceStatus() async {
    if (_order == null) return;
    final current = _order!['status'] as String? ?? '';
    final next = _nextStatus(current);
    if (next == current) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_nextStatusLabel(current)),
        content: Text(
          'Change order status from "${_statusLabel(current)}" to "${_statusLabel(next)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _supabase
          .from('online_orders')
          .update({
            'status': next,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', widget.orderId);

      // If marking as collected, create stock movements
      if (next == 'collected') {
        final staffId = _supabase.auth.currentUser?.id;
        if (staffId != null && _items.isNotEmpty) {
          final movements = _items.map((item) {
            final inventoryItemId = item['inventory_item_id'] as String?;
            final quantity = (item['quantity'] as num?)?.toDouble() ?? 0.0;
            
            return {
              'item_id': inventoryItemId,
              'movement_type': 'sale',
              'quantity': -quantity,
              'unit_type': 'unit',
              'reference_id': widget.orderId,
              'reference_type': 'online_order',
              'staff_id': staffId,
              'reason': 'Click & Collect collection',
            };
          }).toList();

          if (EdgePipelineConfig.canUseEdgePipeline) {
            for (final movement in movements) {
              debugPrint('[EDGE] Calling stock_adjust');
              try {
                await EdgePipelineClient.instance.stockAdjust(movement: movement);
              } catch (e) {
                debugPrint('[EDGE] Failed: stock_adjust — $e');
                rethrow;
              }
            }
          } else {
            await _supabase.from('stock_movements').insert(movements);
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order updated to ${_statusLabel(next)}'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadOrder();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmCodOrder() async {
    if (_order == null) return;
    final status = _order!['status'] as String? ?? '';
    if (status != 'pending_cod') return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm COD Order'),
        content: const Text(
          'Confirm this COD order and create a parked sale for POS pickup?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final order = _order!;
      final orderId = widget.orderId;
      final customer = order['loyalty_customers'] as Map<String, dynamic>?;
      final customerName = customer?['full_name'] as String?;
      final customerPhone = customer?['phone'] as String?;
      final customerId = order['customer_id']?.toString();
      final orderNumber = order['order_number']?.toString() ?? '';
      final subtotal = (order['subtotal'] as num?)?.toDouble() ?? 0.0;

      final lineItems = _items.map((item) {
        final quantity = (item['quantity'] as num?)?.toDouble() ??
            (item['qty'] as num?)?.toDouble() ??
            0.0;
        final unitPrice = (item['unit_price'] as num?)?.toDouble() ?? 0.0;
        final lineTotal = (item['line_total'] as num?)?.toDouble() ?? 0.0;
        return <String, dynamic>{
          'id': item['id']?.toString(),
          'inventory_item_id': item['inventory_item_id'],
          'product_name': item['product_name'],
          'quantity': quantity,
          'unit_type': 'each',
          'unit_price': unitPrice,
          'line_total': lineTotal,
          'cost_price': 0,
          'vat_group': 'Standard',
          'is_weighted': false,
          'scanned_barcode': null,
          'barcode_weight': null,
          'barcode_price': null,
        };
      }).toList();

      final parkedSale = await _supabase
          .from('parked_sales')
          .insert({
            'source': 'online_order',
            'online_order_id': orderId,
            'customer_id': customerId,
            'customer_name': customerName,
            'customer_phone': customerPhone,
            'reference': orderNumber,
            'line_items': lineItems,
            'subtotal': subtotal,
            'notes': 'Online order — COD',
            'status': 'parked',
            'payment_status': 'unpaid',
            'created_by': null,
          })
          .select('id')
          .single();

      await _supabase
          .from('online_orders')
          .update({
            'status': 'confirmed',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', orderId);

      final staffId = _supabase.auth.currentUser?.id;
      if (staffId != null && _items.isNotEmpty) {
        final movements = _items
            .where((item) => item['inventory_item_id'] != null)
            .map((item) {
          final quantity = (item['quantity'] as num?)?.toDouble() ??
              (item['qty'] as num?)?.toDouble() ??
              0.0;
          return <String, dynamic>{
            'item_id': item['inventory_item_id'],
            'movement_type': 'sale',
            'quantity': -quantity,
            'unit_type': 'unit',
            'reference_id': orderId,
            'reference_type': 'online_order',
            'staff_id': staffId,
            'reason': 'COD order confirmed',
          };
        }).toList();

        try {
          if (EdgePipelineConfig.canUseEdgePipeline) {
            for (final movement in movements) {
              debugPrint('[EDGE] Calling stock_adjust');
              await EdgePipelineClient.instance.stockAdjust(movement: movement);
            }
          } else if (movements.isNotEmpty) {
            await _supabase.from('stock_movements').insert(movements);
          }
        } catch (e) {
          debugPrint('[COD] Stock movement failed (non-fatal): $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'COD order confirmed and parked sale created (${parkedSale['id']})',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        _loadOrder();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('COD confirm failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _cancelOrder() async {
    if (_order == null) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Cancel Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Are you sure you want to cancel this order?'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('BACK'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error),
              child:
                  const Text('CANCEL ORDER', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
    if (reason == null) return;

    try {
      await _supabase
          .from('online_orders')
          .update({
            'status': 'cancelled',
            'notes': reason.isNotEmpty ? reason : null,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', widget.orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled'),
            backgroundColor: AppColors.error,
          ),
        );
        _loadOrder();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cancel failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(_order != null
            ? 'Order ${_order!['order_number'] ?? ''}'
            : 'Order Detail'),
        backgroundColor: AppColors.cardBg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrder,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _order == null
              ? const Center(child: Text('Order not found'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final order = _order!;
    final status = order['status'] as String? ?? '';
    final total = (order['total'] as num?)?.toDouble() ?? 0.0;
    final paymentMethod = order['payment_method'] as String? ?? 'cod';
    final createdAt =
        DateTime.tryParse(order['created_at'] as String? ?? '');
    final collectionDate = order['collection_date'] as String? ?? '';
    final collectionSlot = order['collection_slot'] as String? ?? '';
    final notes = order['notes'] as String? ?? '';

    final customer =
        order['loyalty_customers'] as Map<String, dynamic>?;
    final customerName = customer?['full_name'] as String? ?? 'Unknown';
    final customerPhone = customer?['phone'] as String? ?? '';
    final customerEmail = customer?['email'] as String? ?? '';
    final customerTier = customer?['loyalty_tier'] as String? ?? '';
    final customerPoints = customer?['points_balance'] ?? 0;

    final canConfirmCod = status == 'pending_cod';
    final canAdvance = ['pending_payment', 'confirmed', 'packing', 'ready']
        .contains(status);
    final canCancel = ['pending_cod', 'pending_payment', 'confirmed'].contains(status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status + Actions ──────────────────────────────────────
          _buildStatusCard(status, canConfirmCod, canAdvance, canCancel),
          const SizedBox(height: 16),

          // ── Customer Info ─────────────────────────────────────────
          _sectionCard(
            title: 'Customer',
            icon: Icons.person,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Name', customerName),
                if (customerPhone.isNotEmpty)
                  _infoRow('Phone', customerPhone),
                if (customerEmail.isNotEmpty)
                  _infoRow('Email', customerEmail),
                if (customerTier.isNotEmpty)
                  _infoRow('Tier', customerTier.toUpperCase()),
                _infoRow('Points', '$customerPoints'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Order Info ────────────────────────────────────────────
          _sectionCard(
            title: 'Order Info',
            icon: Icons.info_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Order #', order['order_number'] ?? ''),
                _infoRow('Payment', paymentMethod == 'cod' ? 'Cash on Collection' : 'PayFast'),
                if (createdAt != null)
                  _infoRow(
                    'Placed',
                    '${createdAt.day.toString().padLeft(2, '0')}/'
                    '${createdAt.month.toString().padLeft(2, '0')}/'
                    '${createdAt.year} '
                    '${createdAt.hour.toString().padLeft(2, '0')}:'
                    '${createdAt.minute.toString().padLeft(2, '0')}',
                  ),
                if (collectionDate.isNotEmpty)
                  _infoRow('Collection Date', collectionDate),
                if (collectionSlot.isNotEmpty)
                  _infoRow('Time Slot', collectionSlot),
                if (notes.isNotEmpty)
                  _infoRow('Notes', notes),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Order Items ───────────────────────────────────────────
          _sectionCard(
            title: 'Items (${_items.length})',
            icon: Icons.shopping_cart,
            child: Column(
              children: _items.map((item) => _buildItemRow(item)).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Totals ────────────────────────────────────────────────
          _sectionCard(
            title: 'Total',
            icon: Icons.receipt,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'R${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    String status,
    bool canConfirmCod,
    bool canAdvance,
    bool canCancel,
  ) {
    final info = _statusInfoFull(status);
    return Card(
      color: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(info.icon, color: info.color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: info.color,
                        ),
                      ),
                      Text(
                        info.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (canConfirmCod || canAdvance || canCancel) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (canConfirmCod)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _confirmCodOrder,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Confirm COD Order'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  if (canConfirmCod && (canAdvance || canCancel))
                    const SizedBox(width: 12),
                  if (canAdvance)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _advanceStatus,
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: Text(_nextStatusLabel(status)),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  if (canAdvance && canCancel) const SizedBox(width: 12),
                  if (canCancel)
                    OutlinedButton.icon(
                      onPressed: _cancelOrder,
                      icon: const Icon(Icons.cancel, size: 18,
                          color: AppColors.error),
                      label: const Text('Cancel',
                          style: TextStyle(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                ],
              ),
            ],
            // ── Progress indicator ──────────────────────────────────
            const SizedBox(height: 16),
            _buildProgressBar(status),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String status) {
    final steps = ['Pending', 'Confirmed', 'Packing', 'Ready', 'Collected'];
    int currentIdx;
    switch (status) {
      case 'pending_cod':
      case 'pending_payment':
        currentIdx = 0;
        break;
      case 'confirmed':
        currentIdx = 1;
        break;
      case 'packing':
        currentIdx = 2;
        break;
      case 'ready':
        currentIdx = 3;
        break;
      case 'collected':
        currentIdx = 4;
        break;
      default:
        currentIdx = -1; // cancelled / uncollected
    }

    if (currentIdx < 0) {
      return const SizedBox.shrink();
    }

    return Row(
      children: List.generate(steps.length, (i) {
        final isActive = i <= currentIdx;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? AppColors.primary : AppColors.border,
                    ),
                    child: isActive
                        ? const Icon(Icons.check,
                            size: 12, color: Colors.white)
                        : null,
                  ),
                  if (i < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: i < currentIdx
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                steps[i],
                style: TextStyle(
                  fontSize: 9,
                  color: isActive
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    final product =
        item['inventory_items'] as Map<String, dynamic>?;
    final productName =
        product?['product_name'] as String? ?? item['product_name'] as String? ?? 'Unknown';
    final plu = product?['plu_code'] as String? ?? '';
    final quantity = (item['quantity'] as num?)?.toDouble() ?? 0;
    final unitPrice = (item['unit_price'] as num?)?.toDouble() ?? 0;
    final lineTotal = (item['line_total'] as num?)?.toDouble() ?? (quantity * unitPrice);
    final isWeighted = product?['item_type'] == 'weighted';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  isWeighted
                      ? '${quantity.toStringAsFixed(3)}kg @ R${unitPrice.toStringAsFixed(2)}/kg'
                      : '${quantity.toStringAsFixed(0)} x R${unitPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (plu.isNotEmpty)
                  Text(
                    'PLU: $plu',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            'R${lineTotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
      {required String title,
      required IconData icon,
      required Widget child}) {
    return Card(
      color: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'pending_cod':
        return 'Pending (COD)';
      case 'pending_payment':
        return 'Pending Payment';
      case 'confirmed':
        return 'Confirmed';
      case 'packing':
        return 'Packing';
      case 'ready':
        return 'Ready';
      case 'collected':
        return 'Collected';
      case 'cancelled':
        return 'Cancelled';
      case 'uncollected':
        return 'Uncollected';
      default:
        return status;
    }
  }

  static _StatusInfoFull _statusInfoFull(String status) {
    switch (status) {
      case 'pending_cod':
        return _StatusInfoFull(
          'Pending (COD)',
          'Customer will pay cash on collection',
          Icons.hourglass_empty,
          AppColors.textSecondary,
        );
      case 'pending_payment':
        return _StatusInfoFull(
          'Pending Payment',
          'Waiting for online payment confirmation',
          Icons.hourglass_empty,
          AppColors.warning,
        );
      case 'confirmed':
        return _StatusInfoFull(
          'Confirmed',
          'Order confirmed — ready to start packing',
          Icons.check_circle,
          AppColors.info,
        );
      case 'packing':
        return _StatusInfoFull(
          'Packing',
          'Staff are packing this order',
          Icons.inventory_2,
          AppColors.warning,
        );
      case 'ready':
        return _StatusInfoFull(
          'Ready for Collection',
          'Customer has been notified — waiting for pickup',
          Icons.local_shipping,
          AppColors.success,
        );
      case 'collected':
        return _StatusInfoFull(
          'Collected',
          'Order has been collected by the customer',
          Icons.done_all,
          AppColors.textSecondary,
        );
      case 'cancelled':
        return _StatusInfoFull(
          'Cancelled',
          'This order has been cancelled',
          Icons.cancel,
          AppColors.error,
        );
      case 'uncollected':
        return _StatusInfoFull(
          'Uncollected',
          'Customer did not collect this order',
          Icons.warning,
          AppColors.error,
        );
      default:
        return _StatusInfoFull(
          status,
          '',
          Icons.help_outline,
          AppColors.textSecondary,
        );
    }
  }
}

class _StatusInfoFull {
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  const _StatusInfoFull(this.label, this.description, this.icon, this.color);
}
