import 'base_model.dart';

/// TransactionItem model — POS writes; Admin reads for product performance, margins.
/// Blueprint §15: transaction_items (POS App) — Product performance, margins.
class TransactionItem extends BaseModel {
  final String transactionId;
  final String? inventoryItemId;
  final double quantity;
  final double unitPrice;
  final double lineTotal;

  const TransactionItem({
    required super.id,
    required this.transactionId,
    this.inventoryItemId,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    super.createdAt,
    super.updatedAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'inventory_item_id': inventoryItemId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'line_total': lineTotal,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] as String,
      transactionId: json['transaction_id'] as String,
      inventoryItemId: json['inventory_item_id'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['line_total'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  bool validate() {
    return quantity >= 0 && unitPrice >= 0 && lineTotal >= 0;
  }

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (quantity < 0) errors.add('Quantity cannot be negative');
    if (unitPrice < 0) errors.add('Unit price cannot be negative');
    if (lineTotal < 0) errors.add('Line total cannot be negative');
    return errors;
  }
}
