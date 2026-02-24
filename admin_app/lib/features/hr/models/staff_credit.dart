import '../../../core/models/base_model.dart';

/// Blueprint §7.5: Staff credit ledger — meat purchases, salary advances, loans (one ledger per employee).
enum StaffCreditType {
  meatPurchase,
  salaryAdvance,
  loan,
  deduction,
  repayment,
  other,
}

extension StaffCreditTypeExt on StaffCreditType {
  String get dbValue {
    switch (this) {
      case StaffCreditType.meatPurchase:
        return 'meat_purchase';
      case StaffCreditType.salaryAdvance:
        return 'salary_advance';
      case StaffCreditType.loan:
        return 'loan';
      case StaffCreditType.deduction:
        return 'deduction';
      case StaffCreditType.repayment:
        return 'repayment';
      case StaffCreditType.other:
        return 'other';
    }
  }

  /// Friendly label for UI. DB: meat_purchase, salary_advance, loan, deduction, repayment, other.
  String get displayLabel {
    switch (this) {
      case StaffCreditType.meatPurchase:
        return 'Meat Purchase';
      case StaffCreditType.salaryAdvance:
        return 'Salary Advance';
      case StaffCreditType.loan:
        return 'Loan';
      case StaffCreditType.deduction:
        return 'Deduction';
      case StaffCreditType.repayment:
        return 'Repayment';
      case StaffCreditType.other:
        return 'Other';
    }
  }

  static StaffCreditType fromDb(String? value) {
    switch (value) {
      case 'meat_purchase':
        return StaffCreditType.meatPurchase;
      case 'salary_advance':
        return StaffCreditType.salaryAdvance;
      case 'loan':
        return StaffCreditType.loan;
      case 'deduction':
        return StaffCreditType.deduction;
      case 'repayment':
        return StaffCreditType.repayment;
      case 'other':
        return StaffCreditType.other;
      default:
        return StaffCreditType.meatPurchase;
    }
  }
}

enum StaffCreditStatus {
  pending,
  deducted,
  partial,
  cleared,
}

extension StaffCreditStatusExt on StaffCreditStatus {
  String get dbValue {
    switch (this) {
      case StaffCreditStatus.pending:
        return 'pending';
      case StaffCreditStatus.deducted:
        return 'deducted';
      case StaffCreditStatus.partial:
        return 'partial';
      case StaffCreditStatus.cleared:
        return 'cleared';
    }
  }

  /// Friendly label for UI. DB: pending, deducted, partial, cleared.
  String get displayLabel {
    switch (this) {
      case StaffCreditStatus.pending:
        return 'Pending';
      case StaffCreditStatus.deducted:
        return 'Deducted';
      case StaffCreditStatus.partial:
        return 'Partial';
      case StaffCreditStatus.cleared:
        return 'Cleared';
    }
  }

  static StaffCreditStatus fromDb(String? value) {
    switch (value) {
      case 'deducted':
        return StaffCreditStatus.deducted;
      case 'partial':
        return StaffCreditStatus.partial;
      case 'cleared':
        return StaffCreditStatus.cleared;
      default:
        return StaffCreditStatus.pending;
    }
  }
}

/// Display label for deduct_from. DB: next_payroll, specific_period.
String staffCreditDeductFromDisplayLabel(String? value) {
  switch (value) {
    case 'next_payroll':
      return 'Next Payroll';
    case 'specific_period':
      return 'Specific Period';
    default:
      return value ?? '—';
  }
}

class StaffCredit extends BaseModel {
  final String staffId;
  final StaffCreditType creditType;
  final double amount;
  final String reason;
  final DateTime grantedDate;
  final DateTime? dueDate;
  final String? itemsPurchased;
  final String? repaymentPlan;
  final String deductFrom;
  final StaffCreditStatus status;
  final DateTime? paidDate;
  final String grantedBy;
  final String? notes;
  final String? staffName;

  const StaffCredit({
    required super.id,
    required this.staffId,
    this.creditType = StaffCreditType.meatPurchase,
    required this.amount,
    required this.reason,
    required this.grantedDate,
    this.dueDate,
    this.itemsPurchased,
    this.repaymentPlan,
    this.deductFrom = 'next_payroll',
    this.status = StaffCreditStatus.pending,
    this.paidDate,
    required this.grantedBy,
    this.notes,
    super.createdAt,
    super.updatedAt,
    this.staffName,
  });

  bool get isOutstanding =>
      status == StaffCreditStatus.pending || status == StaffCreditStatus.partial;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'staff_id': staffId,
      'credit_type': creditType.dbValue,
      'credit_amount': amount,
      'reason': reason,
      'granted_date': grantedDate.toIso8601String().substring(0, 10),
      'due_date': dueDate?.toIso8601String().substring(0, 10),
      'items_purchased': itemsPurchased,
      'repayment_plan': repaymentPlan,
      'deduct_from': deductFrom,
      'status': status.dbValue,
      'is_paid': status == StaffCreditStatus.cleared,
      'paid_date': paidDate?.toIso8601String().substring(0, 10),
      'granted_by': grantedBy,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory StaffCredit.fromJson(Map<String, dynamic> json) {
    final status = StaffCreditStatusExt.fromDb(json['status'] as String?);
    DateTime? paidDate;
    if (json['paid_date'] != null) paidDate = DateTime.tryParse(json['paid_date'] as String);
    if (paidDate == null && (json['is_paid'] as bool? ?? false)) paidDate = DateTime.now();
    return StaffCredit(
      id: json['id'] as String,
      staffId: json['staff_id'] as String,
      creditType: StaffCreditTypeExt.fromDb(json['credit_type'] as String?),
      amount: (json['credit_amount'] as num?)?.toDouble() ?? 0,
      reason: json['reason'] as String? ?? '',
      grantedDate: json['granted_date'] != null ? DateTime.parse(json['granted_date'] as String) : DateTime.now(),
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date'] as String) : null,
      itemsPurchased: json['items_purchased'] as String?,
      repaymentPlan: json['repayment_plan'] as String?,
      deductFrom: json['deduct_from'] as String? ?? 'next_payroll',
      status: status,
      paidDate: paidDate,
      grantedBy: json['granted_by']?.toString() ?? '',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      staffName: json['staff_profiles'] != null
          ? (json['staff_profiles'] as Map<String, dynamic>)['full_name'] as String?
          : json['full_name'] as String?,
    );
  }

  StaffCredit copyWith({String? staffName, StaffCreditStatus? status, DateTime? paidDate}) {
    return StaffCredit(
      id: id,
      staffId: staffId,
      creditType: creditType,
      amount: amount,
      reason: reason,
      grantedDate: grantedDate,
      dueDate: dueDate,
      itemsPurchased: itemsPurchased,
      repaymentPlan: repaymentPlan,
      deductFrom: deductFrom,
      status: status ?? this.status,
      paidDate: paidDate ?? this.paidDate,
      grantedBy: grantedBy,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      staffName: staffName ?? this.staffName,
    );
  }

  @override
  bool validate() => staffId.isNotEmpty && amount != 0 && reason.isNotEmpty && grantedBy.isNotEmpty;

  @override
  List<String> getValidationErrors() {
    final e = <String>[];
    if (staffId.isEmpty) e.add('Staff is required');
    if (amount == 0) e.add('Amount is required');
    if (reason.isEmpty) e.add('Reason is required');
    if (grantedBy.isEmpty) e.add('Granted by is required');
    return e;
  }
}
