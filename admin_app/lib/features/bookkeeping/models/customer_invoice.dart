import '../../../core/models/base_model.dart';

/// Customer invoice — table customer_invoices.
/// Status CHECK: draft, pending_review, approved, sent, paid, overdue, cancelled.
enum CustomerInvoiceStatus {
  draft,
  pendingReview,
  approved,
  sent,
  paid,
  overdue,
  cancelled,
}

extension CustomerInvoiceStatusExt on CustomerInvoiceStatus {
  String get dbValue {
    switch (this) {
      case CustomerInvoiceStatus.draft:
        return 'draft';
      case CustomerInvoiceStatus.pendingReview:
        return 'pending_review';
      case CustomerInvoiceStatus.approved:
        return 'approved';
      case CustomerInvoiceStatus.sent:
        return 'sent';
      case CustomerInvoiceStatus.paid:
        return 'paid';
      case CustomerInvoiceStatus.overdue:
        return 'overdue';
      case CustomerInvoiceStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayLabel {
    switch (this) {
      case CustomerInvoiceStatus.draft:
        return 'Draft';
      case CustomerInvoiceStatus.pendingReview:
        return 'Pending Review';
      case CustomerInvoiceStatus.approved:
        return 'Approved';
      case CustomerInvoiceStatus.sent:
        return 'Sent';
      case CustomerInvoiceStatus.paid:
        return 'Paid';
      case CustomerInvoiceStatus.overdue:
        return 'Overdue';
      case CustomerInvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }

  static CustomerInvoiceStatus fromDb(String? value) {
    switch (value) {
      case 'pending_review':
        return CustomerInvoiceStatus.pendingReview;
      case 'approved':
        return CustomerInvoiceStatus.approved;
      case 'sent':
        return CustomerInvoiceStatus.sent;
      case 'paid':
        return CustomerInvoiceStatus.paid;
      case 'overdue':
        return CustomerInvoiceStatus.overdue;
      case 'cancelled':
        return CustomerInvoiceStatus.cancelled;
      default:
        return CustomerInvoiceStatus.draft;
    }
  }
}

class CustomerInvoice extends BaseModel {
  final String invoiceNumber;
  final String? accountId;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final List<Map<String, dynamic>> lineItems;
  final double subtotal;
  final double? taxRate;
  final double taxAmount;
  final double total;
  final CustomerInvoiceStatus status;
  final DateTime? paymentDate;
  final String? notes;
  final String? createdBy;
  final String? accountName;

  const CustomerInvoice({
    required super.id,
    required this.invoiceNumber,
    this.accountId,
    required this.invoiceDate,
    required this.dueDate,
    this.lineItems = const [],
    this.subtotal = 0,
    this.taxRate,
    this.taxAmount = 0,
    this.total = 0,
    this.status = CustomerInvoiceStatus.draft,
    this.paymentDate,
    this.notes,
    this.createdBy,
    this.accountName,
    super.createdAt,
    super.updatedAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'account_id': accountId,
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

  factory CustomerInvoice.fromJson(Map<String, dynamic> json) {
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
    return CustomerInvoice(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String? ?? '',
      accountId: json['account_id'] as String?,
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
      status: CustomerInvoiceStatusExt.fromDb(json['status'] as String?),
      paymentDate: json['payment_date'] != null
          ? DateTime.tryParse(json['payment_date'] as String)
          : null,
      notes: json['notes'] as String?,
      createdBy: json['created_by']?.toString(),
      accountName: json['business_accounts'] != null
          ? (json['business_accounts'] as Map<String, dynamic>)['name'] as String?
          : json['account_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  bool get canApprove =>
      status == CustomerInvoiceStatus.draft ||
      status == CustomerInvoiceStatus.pendingReview;

  CustomerInvoice copyWith({String? accountName}) {
    return CustomerInvoice(
      id: id,
      invoiceNumber: invoiceNumber,
      accountId: accountId,
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
      accountName: accountName ?? this.accountName,
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
