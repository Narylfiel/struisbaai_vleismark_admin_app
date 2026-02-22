/// Blueprint §10.1: Shrinkage alert — mass-balance gap (theoretical vs actual).
/// Maps to shrinkage_alerts table; used by Analytics and dashboard.
class ShrinkageAlert {
  final String id;
  final String? productName;
  final String? productId;
  final double? theoreticalStock;
  final double? actualStock;
  final double? gapAmount;
  final double? gapPercentage;
  final String? possibleReasons;
  final String? staffInvolved;
  final String status;
  final DateTime? createdAt;

  const ShrinkageAlert({
    required this.id,
    this.productName,
    this.productId,
    this.theoreticalStock,
    this.actualStock,
    this.gapAmount,
    this.gapPercentage,
    this.possibleReasons,
    this.staffInvolved,
    this.status = 'Pending',
    this.createdAt,
  });

  static ShrinkageAlert fromJson(Map<String, dynamic> json) {
    return ShrinkageAlert(
      id: json['id']?.toString() ?? '',
      productName: json['product_name']?.toString(),
      productId: json['product_id']?.toString(),
      theoreticalStock: _toDouble(json['theoretical_stock']),
      actualStock: _toDouble(json['actual_stock']),
      gapAmount: _toDouble(json['gap_amount']),
      gapPercentage: _toDouble(json['gap_percentage']),
      possibleReasons: json['possible_reasons']?.toString(),
      staffInvolved: json['staff_involved']?.toString(),
      status: json['status']?.toString() ?? 'Pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_name': productName,
        'product_id': productId,
        'theoretical_stock': theoreticalStock,
        'actual_stock': actualStock,
        'gap_amount': gapAmount,
        'gap_percentage': gapPercentage,
        'possible_reasons': possibleReasons,
        'staff_involved': staffInvolved,
        'status': status,
        'created_at': createdAt?.toIso8601String(),
      };
}
