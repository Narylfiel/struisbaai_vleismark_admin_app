/// Debt summary model — aggregates all debt sources.
class DebtSummary {
  final double supplierDebt;
  final double staffDebt;
  final double totalDebt;
  final int supplierInvoiceCount;
  final int staffCreditCount;
  final DateTime asOfDate;

  const DebtSummary({
    required this.supplierDebt,
    required this.staffDebt,
    required this.totalDebt,
    required this.supplierInvoiceCount,
    required this.staffCreditCount,
    required this.asOfDate,
  });

  factory DebtSummary.empty() => DebtSummary(
        supplierDebt: 0,
        staffDebt: 0,
        totalDebt: 0,
        supplierInvoiceCount: 0,
        staffCreditCount: 0,
        asOfDate: DateTime.now(),
      );

  bool get hasDebt => totalDebt > 0;

  String get formattedTotal => 'R ${totalDebt.toStringAsFixed(2)}';
  String get formattedSupplierDebt => 'R ${supplierDebt.toStringAsFixed(2)}';
  String get formattedStaffDebt => 'R ${staffDebt.toStringAsFixed(2)}';
}
