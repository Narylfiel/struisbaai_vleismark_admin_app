/// Minimal, local-only action tracking for the closed-loop workflow:
/// plan -> act -> measure -> adjust
///
/// Stored in SharedPreferences. This is NOT persisted in Supabase/DB.
///
/// NOTE: This is a "signal-level" tracker. It never uses cash deltas to
/// determine effectiveness, to avoid unrelated financial noise.
class ActionTracking {
  /// Debt Buster opportunity id (stable key).
  final String opportunityId;

  /// Targeted lever/issue type.
  /// Expected values: `shrinkage`, `margin`, `loss`, `slow_stock`.
  final String type;

  /// Inventory/product id the action targets.
  final String productId;

  final DateTime startedAt;
  final bool completed;

  /// Expected monthly impact (currency) from the Debt Buster opportunity.
  final double expectedImpact;

  // === Baseline signal snapshots (captured on "Start Action") ===
  final double? baselineShrinkageValue;
  final double? baselineMargin; // margin in pct (0-100)
  final double? baselineRevenue; // actual revenue (currency)
  final double? baselineLossProfit; // negative profit (currency, negative or 0)
  final double? baselineStockLevel; // current_stock * average_cost

  /// Measured improvement (currency). Null means insufficient data or
  /// evaluation window not met.
  final double? measuredImpact;

  const ActionTracking({
    required this.opportunityId,
    required this.type,
    required this.productId,
    required this.startedAt,
    required this.completed,
    required this.expectedImpact,
    this.baselineShrinkageValue,
    this.baselineMargin,
    this.baselineRevenue,
    this.baselineLossProfit,
    this.baselineStockLevel,
    this.measuredImpact,
  });

  ActionTracking copyWith({
    String? opportunityId,
    String? type,
    String? productId,
    DateTime? startedAt,
    bool? completed,
    double? expectedImpact,
    double? baselineShrinkageValue,
    double? baselineMargin,
    double? baselineRevenue,
    double? baselineLossProfit,
    double? baselineStockLevel,
    double? measuredImpact,
  }) {
    return ActionTracking(
      opportunityId: opportunityId ?? this.opportunityId,
      type: type ?? this.type,
      productId: productId ?? this.productId,
      startedAt: startedAt ?? this.startedAt,
      completed: completed ?? this.completed,
      expectedImpact: expectedImpact ?? this.expectedImpact,
      baselineShrinkageValue:
          baselineShrinkageValue ?? this.baselineShrinkageValue,
      baselineMargin: baselineMargin ?? this.baselineMargin,
      baselineRevenue: baselineRevenue ?? this.baselineRevenue,
      baselineLossProfit: baselineLossProfit ?? this.baselineLossProfit,
      baselineStockLevel: baselineStockLevel ?? this.baselineStockLevel,
      measuredImpact: measuredImpact ?? this.measuredImpact,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'opportunityId': opportunityId,
      'type': type,
      'productId': productId,
      'startedAt': startedAt.toIso8601String(),
      'completed': completed,
      'expectedImpact': expectedImpact,
      'baselineShrinkageValue': baselineShrinkageValue,
      'baselineMargin': baselineMargin,
      'baselineRevenue': baselineRevenue,
      'baselineLossProfit': baselineLossProfit,
      'baselineStockLevel': baselineStockLevel,
      'measuredImpact': measuredImpact,
    };
  }

  factory ActionTracking.fromJson(Map<String, dynamic> json) {
    final startedAtRaw = json['startedAt'];
    final startedAt = startedAtRaw is String
        ? DateTime.tryParse(startedAtRaw) ?? DateTime.now()
        : DateTime.now();

    // Backward compatibility: if older entries used only cash delta fields,
    // safely fall back to defaults for new signal fields.
    final opportunityId = json['opportunityId']?.toString() ?? '';

    String type = json['type']?.toString() ?? '';
    String productId = json['productId']?.toString() ?? '';
    if (type.isEmpty || productId.isEmpty) {
      // opportunityId patterns:
      // shrink_<productId>, margin_<productId>, loss_<productId>, slow_<productId>
      if (opportunityId.startsWith('shrink_')) {
        type = 'shrinkage';
        productId = opportunityId.substring('shrink_'.length);
      } else if (opportunityId.startsWith('margin_')) {
        type = 'margin';
        productId = opportunityId.substring('margin_'.length);
      } else if (opportunityId.startsWith('loss_')) {
        type = 'loss';
        productId = opportunityId.substring('loss_'.length);
      } else if (opportunityId.startsWith('slow_')) {
        type = 'slow_stock';
        productId = opportunityId.substring('slow_'.length);
      }
    }
    if (type.isEmpty) type = 'shrinkage';

    return ActionTracking(
      opportunityId: opportunityId,
      type: type,
      productId: productId,
      startedAt: startedAt,
      completed: json['completed'] == true,
      expectedImpact: (json['expectedImpact'] as num?)?.toDouble() ?? 0.0,
      baselineShrinkageValue:
          (json['baselineShrinkageValue'] as num?)?.toDouble(),
      baselineMargin: (json['baselineMargin'] as num?)?.toDouble(),
      baselineRevenue: (json['baselineRevenue'] as num?)?.toDouble(),
      baselineLossProfit: (json['baselineLossProfit'] as num?)?.toDouble(),
      baselineStockLevel: (json['baselineStockLevel'] as num?)?.toDouble(),
      measuredImpact: (json['measuredImpact'] as num?)?.toDouble(),
    );
  }
}

