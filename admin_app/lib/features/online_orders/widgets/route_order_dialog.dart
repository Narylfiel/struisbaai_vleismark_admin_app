import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';

/// Dialog for ordering delivery routes by drag and drop
class RouteOrderDialog extends StatefulWidget {
  final List<Map<String, dynamic>> orders;
  final String zone;
  final Function(List<Map<String, dynamic>>) onSave;

  const RouteOrderDialog({
    super.key,
    required this.orders,
    required this.zone,
    required this.onSave,
  });

  @override
  State<RouteOrderDialog> createState() => _RouteOrderDialogState();
}

class _RouteOrderDialogState extends State<RouteOrderDialog> {
  late List<Map<String, dynamic>> _orderedOrders;

  @override
  void initState() {
    super.initState();
    _orderedOrders = List.from(widget.orders);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Route Order - ${widget.zone}'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            Text(
              'Drag and drop to reorder delivery stops:',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _orderedOrders.length,
                onReorder: _onReorder,
                itemBuilder: (context, index) {
                  final order = _orderedOrders[index];
                  final customer = order['loyalty_customers'] as Map<String, dynamic>?;
                  final customerName = customer?['full_name'] ?? 
                                     order['customer_name'] ?? 
                                     'Unknown';
                  final address = order['delivery_address'] ?? 
                                 order['address'] ?? 
                                 'No address';

                  return Card(
                    key: ValueKey(order['id']),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        order['order_number'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customerName,
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            address,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.drag_handle),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_orderedOrders);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: const Text('Save Order'),
        ),
      ],
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    setState(() {
      final item = _orderedOrders.removeAt(oldIndex);
      _orderedOrders.insert(newIndex, item);
    });
  }
}
