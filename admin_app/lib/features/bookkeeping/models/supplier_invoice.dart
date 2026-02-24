import '../../../core/models/base_model.dart';

/// Supplier invoice — table supplier_invoices.
/// Status CHECK: draft, pending_review, approved, paid, overdue, cancelled (no sent).
enum SupplierInvoiceStatus {
  draft,
  pendingReview,
  approved,
  paid,
  overdue,
  cancelled,
}

extension SupplierInvoiceStatusExt on SupplierInvoiceStatus {
  String get dbValue {
    switch (this) {
      case SupplierInvoiceStatus.draft:
        return 'draft';
      case SupplierInvoiceStatus.pendingReview:
        return 'pending_review';
      case SupplierInvoiceStatus.approved:
        return 'approved';
      case SupplierInvoiceStatus.paid:
        return 'paid';
      case SupplierInvoiceStatus.overdue:
        return 'overdue';
      case SupplierInvoiceStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayLabel {
    switch (this) {
      case SupplierInvoiceStatus.draft:
        return 'Draft';
      case SupplierInvoiceStatus.pendingReview:
        return 'Pending Review';
      case SupplierInvoiceStatus.approved:
        return 'Approved';
      case SupplierInvoiceStatus.paid:
        return 'Paid';
      case SupplierInvoiceStatus.overdue:
        return 'Overdue';
      case SupplierInvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }

  static SupplierInvoiceStatus fromDb(String? value) {
    switch (value) {
      case 'pending_review':
        return SupplierInvoiceStatus.pendingReview;
      case 'approved':
        return SupplierInvoiceStatus.approved;
      case 'paid':
        return SupplierInvoiceStatus.paid;
      case 'overdue':
        return SupplierInvoiceStatus.overdue;
      case 'cancelled':
        return SupplierInvoiceStatus.cancelled;
      default:
        return SupplierInvoiceStatus.draft;
    }
  }
}

class SupplierInvoice extends BaseModel {
  final String invoiceNumber;
  final String? supplierId;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final List<Map<String, dynamic>> lineItems;
  final double subtotal;
  final double? taxRate;
  final double taxAmount;
  final double total;
  final SupplierInvoiceStatus status;
  final DateTime? paymentDate;
  final String? notes;
  final String? createdBy;
  final String? supplierName;

  const SupplierInvoice({
    required super.id,
    required this.invoiceNumber,
    this.supplierId,
    required this.invoiceDate,
    required this.dueDate,
    this.lineItems = const [],
    this.subtotal = 0,
    this.taxRate,
    this.taxAmount = 0,
    this.total = 0,
    this.status = SupplierInvoiceStatus.draft,
    this.paymentDate,
    this.notes,
    this.createdBy,
    this.supplierName,
    super.createdAt,
    super.updatedAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'supplier_id': supplierId,
      'invoice_date': invoiceDate.toIso8601String().substring(0, 10),
      'due_date': dueDate.toIso8601String().substring(0, 10),
      'line_items': lineItems,
      'subtotal': subtotal,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total': total,
      'status': status.dbValue,
      'payment_date': paymentDate?.toIso8601String().substring(0, 10),
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory SupplierInvoice.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> items = [];
    final raw = json['line_items'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          items.add(e);
        } else if (e is Map) {
          items.add(Map<String, dynamic>.from(e));
        }
      }
    }
    return SupplierInvoice(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String? ?? '',
      supplierId: json['supplier_id'] as String?,
      invoiceDate: json['invoice_date'] != null
          ? DateTime.parse(json['invoice_date'] as String)
          : DateTime.now(),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : DateTime.now(),
      lineItems: items,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      taxRate: (json['tax_rate'] as num?)?.toDouble(),
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      status: SupplierInvoiceStatusExt.fromDb(json['status'] as String?),
      paymentDate: json['payment_date'] != null
          ? DateTime.tryParse(json['payment_date'] as String)
          : null,
      notes: json['notes'] as String?,
      createdBy: json['created_by']?.toString(),
      supplierName: json['suppliers'] != null
          ? (json['suppliers'] as Map<String, dynamic>)['name'] as String?
          : json['supplier_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  bool get canApprove =>
      status == SupplierInvoiceStatus.draft ||
      status == SupplierInvoiceStatus.pendingReview;

  SupplierInvoice copyWith({String? supplierName}) {
    return SupplierInvoice(
      id: id,
      invoiceNumber: invoiceNumber,
      supplierId: supplierId,
      invoiceDate: invoiceDate,
      dueDate: dueDate,
      lineItems: lineItems,
      subtotal: subtotal,
      taxRate: taxRate,
      taxAmount: taxAmount,
      total: total,
      status: status,
      paymentDate: paymentDate,
      notes: notes,
      createdBy: createdBy,
      supplierName: supplierName ?? this.supplierName,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool validate() =>
      invoiceNumber.isNotEmpty && total >= 0;

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (invoiceNumber.isEmpty) errors.add('Invoice number is required');
    if (total < 0) errors.add('Total cannot be negative');
    return errors;
  }
}
