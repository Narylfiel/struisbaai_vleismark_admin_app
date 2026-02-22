import '../../../core/models/base_model.dart';

/// Blueprint §9.1: Supplier invoice — manual or OCR; create → approve → post to ledger (AP).
enum InvoiceStatus {
  draft,
  pendingReview,
  approved,
  sent,
  paid,
  overdue,
  cancelled,
}

extension InvoiceStatusExt on InvoiceStatus {
  String get dbValue {
    switch (this) {
      case InvoiceStatus.draft:
        return 'draft';
      case InvoiceStatus.pendingReview:
        return 'pending_review';
      case InvoiceStatus.approved:
        return 'approved';
      case InvoiceStatus.sent:
        return 'sent';
      case InvoiceStatus.paid:
        return 'paid';
      case InvoiceStatus.overdue:
        return 'overdue';
      case InvoiceStatus.cancelled:
        return 'cancelled';
    }
  }

  static InvoiceStatus fromDb(String? value) {
    switch (value) {
      case 'pending_review':
        return InvoiceStatus.pendingReview;
      case 'approved':
        return InvoiceStatus.approved;
      case 'sent':
        return InvoiceStatus.sent;
      case 'paid':
        return InvoiceStatus.paid;
      case 'overdue':
        return InvoiceStatus.overdue;
      case 'cancelled':
        return InvoiceStatus.cancelled;
      default:
        return InvoiceStatus.draft;
    }
  }
}

class Invoice extends BaseModel {
  final String invoiceNumber;
  final String? supplierId;
  final String? accountId;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final InvoiceStatus status;
  final String? notes;
  final String createdBy;
  final String? supplierName; // resolved from suppliers when loading list

  const Invoice({
    required super.id,
    required this.invoiceNumber,
    this.supplierId,
    this.accountId,
    required this.invoiceDate,
    required this.dueDate,
    this.subtotal = 0,
    this.taxAmount = 0,
    this.totalAmount = 0,
    this.status = InvoiceStatus.draft,
    this.notes,
    required this.createdBy,
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
      'account_id': accountId,
      'invoice_date': invoiceDate.toIso8601String().substring(0, 10),
      'due_date': dueDate.toIso8601String().substring(0, 10),
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'status': status.dbValue,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String? ?? '',
      supplierId: json['supplier_id'] as String?,
      accountId: json['account_id'] as String?,
      invoiceDate: json['invoice_date'] != null
          ? DateTime.parse(json['invoice_date'] as String)
          : DateTime.now(),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : DateTime.now(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      status: InvoiceStatusExt.fromDb(json['status'] as String?),
      notes: json['notes'] as String?,
      createdBy: json['created_by']?.toString() ?? '',
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
      status == InvoiceStatus.draft || status == InvoiceStatus.pendingReview;

  Invoice copyWith({String? supplierName}) {
    return Invoice(
      id: id,
      invoiceNumber: invoiceNumber,
      supplierId: supplierId,
      accountId: accountId,
      invoiceDate: invoiceDate,
      dueDate: dueDate,
      subtotal: subtotal,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      status: status,
      notes: notes,
      createdBy: createdBy,
      supplierName: supplierName ?? this.supplierName,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool validate() =>
      invoiceNumber.isNotEmpty &&
      totalAmount >= 0 &&
      createdBy.isNotEmpty;

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (invoiceNumber.isEmpty) errors.add('Invoice number is required');
    if (totalAmount < 0) errors.add('Total amount cannot be negative');
    if (createdBy.isEmpty) errors.add('Created by is required');
    return errors;
  }
}
