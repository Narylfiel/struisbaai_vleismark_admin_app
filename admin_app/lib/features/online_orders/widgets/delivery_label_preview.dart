import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';

/// Widget for previewing delivery labels before printing
/// Shows customer info, address, order details, and special instructions
class DeliveryLabelPreview extends StatelessWidget {
  final Map<String, dynamic> order;
  final List<Map<String, dynamic>> items;

  const DeliveryLabelPreview({
    super.key,
    required this.order,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.local_shipping, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              const Text(
                'DELIVERY LABEL',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Text(
                order['order_number'] ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Customer Information
          _buildSection('CUSTOMER INFORMATION', [
            _buildInfoRow('Name', _getCustomerName()),
            _buildInfoRow('Phone', _getCustomerPhone()),
          ]),

          const SizedBox(height: 16),

          // Delivery Address
          _buildSection('DELIVERY ADDRESS', [
            _buildInfoRow('Address', _getDeliveryAddress()),
            _buildInfoRow('Zone', _getDeliveryZone()),
            _buildInfoRow('Date', _getDeliveryDate()),
          ]),

          const SizedBox(height: 16),

          // Order Items
          _buildSection('ORDER ITEMS', [
            ...items.map((item) => _buildItemRow(item)),
          ]),

          const SizedBox(height: 16),

          // Special Instructions
          if (_hasSpecialInstructions()) ...[
            _buildSection('SPECIAL INSTRUCTIONS', [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getSpecialInstructions(),
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.orange,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),
          ],

          // Order Total
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'R${(_getOrderTotal()).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    final productName = item['inventory_items']?['product_name'] ?? 
                       item['product_name'] ?? 
                       'Unknown';
    final quantity = (item['quantity'] as num?)?.toDouble() ?? 0;
    final unitPrice = (item['unit_price'] as num?)?.toDouble() ?? 0;
    final lineTotal = (item['line_total'] as num?)?.toDouble() ?? 
                     (quantity * unitPrice);
    final plu = item['inventory_items']?['plu_code'] ?? item['plu_code'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              productName,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              'x${quantity.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              'R${lineTotal.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCustomerName() {
    final customer = order['loyalty_customers'] as Map<String, dynamic>?;
    return customer?['full_name'] ?? 
           order['customer_name'] ?? 
           'Unknown';
  }

  String _getCustomerPhone() {
    final customer = order['loyalty_customers'] as Map<String, dynamic>?;
    return customer?['phone'] ?? '';
  }

  String _getDeliveryAddress() {
    return order['delivery_address'] ?? 
           order['address'] ?? 
           'No address provided';
  }

  String _getDeliveryZone() {
    return order['delivery_zone'] ?? 
           order['zone'] ?? 
           'No zone';
  }

  String _getDeliveryDate() {
    if (order['delivery_date'] != null) {
      final date = DateTime.tryParse(order['delivery_date']);
      if (date != null) {
        return '${date.day}/${date.month}/${date.year}';
      }
    }
    return 'No date set';
  }

  bool _hasSpecialInstructions() {
    return _getSpecialInstructions().isNotEmpty;
  }

  String _getSpecialInstructions() {
    return order['special_instructions'] ?? 
           order['notes'] ?? 
           order['delivery_notes'] ?? '';
  }

  double _getOrderTotal() {
    return (order['total'] as num?)?.toDouble() ?? 0.0;
  }
}
