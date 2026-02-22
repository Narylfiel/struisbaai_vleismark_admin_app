import 'base_model.dart';

/// Transaction model — POS writes; Admin reads for dashboard, P&L, analytics.
/// Blueprint §15: transactions (POS App) — Sales reports, P&L, analytics.
class Transaction extends BaseModel {
  final double totalAmount;
  final double? costAmount;
  final String? paymentMethod;
  final String? tillSessionId;
  final String? staffId;
  final String? accountId;

  const Transaction({
    required super.id,
    required this.totalAmount,
    this.costAmount,
    this.paymentMethod,
    this.tillSessionId,
    this.staffId,
    this.accountId,
    super.createdAt,
    super.updatedAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'total_amount': totalAmount,
      'cost_amount': costAmount,
      'payment_method': paymentMethod,
      'till_session_id': tillSessionId,
      'staff_id': staffId,
      'account_id': accountId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      costAmount: (json['cost_amount'] as num?)?.toDouble(),
      paymentMethod: json['payment_method'] as String?,
      tillSessionId: json['till_session_id'] as String?,
      staffId: json['staff_id'] as String?,
      accountId: json['account_id'] as String?,
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
    return totalAmount >= 0;
  }

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (totalAmount < 0) errors.add('Total amount cannot be negative');
    return errors;
  }
}
