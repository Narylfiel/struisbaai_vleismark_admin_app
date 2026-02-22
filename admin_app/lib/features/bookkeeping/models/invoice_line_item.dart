import '../../../core/models/base_model.dart';

/// Blueprint §9.1: Invoice line item — description, quantity, unit_price; line_total generated in DB.
class InvoiceLineItem extends BaseModel {
  final String invoiceId;
  final String description;
  final double quantity;
  final double unitPrice;
  final double? lineTotal; // from DB generated column or computed

  const InvoiceLineItem({
    required super.id,
    required this.invoiceId,
    required this.description,
    this.quantity = 1,
    this.unitPrice = 0,
    this.lineTotal,
    super.createdAt,
    super.updatedAt,
  });

  double get computedLineTotal => quantity * unitPrice;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'line_total': lineTotal ?? computedLineTotal,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) {
    return InvoiceLineItem(
      id: json['id'] as String,
      invoiceId: json['invoice_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['line_total'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  bool validate() => invoiceId.isNotEmpty && description.isNotEmpty;

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (invoiceId.isEmpty) errors.add('Invoice is required');
    if (description.isEmpty) errors.add('Description is required');
    return errors;
  }
}
