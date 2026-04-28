/// Opportunity model — actionable item to close the gap.
///
/// NOTE: Keep this enum tightly scoped to avoid double-counting across
/// overlapping opportunity categories.
enum OpportunityType {
  margin,
  shrinkage,
  loss,
  slow_stock,
}

extension OpportunityTypeExt on OpportunityType {
  String get displayLabel {
    switch (this) {
      case OpportunityType.margin:
        return 'Margin';
      case OpportunityType.shrinkage:
        return 'Shrinkage';
      case OpportunityType.loss:
        return 'Loss Product';
      case OpportunityType.slow_stock:
        return 'Slow Moving Stock';
    }
  }

  String get icon {
    switch (this) {
      case OpportunityType.margin:
        return '📈';
      case OpportunityType.loss:
        return '📉';
      case OpportunityType.shrinkage:
        return '⚠️';
      case OpportunityType.slow_stock:
        return '📦';
    }
  }
}

class Opportunity {
  final String id;
  final String productName;
  final String? inventoryItemId;
  final OpportunityType type;
  final String action;
  final String reason;
  final double monthlyImpact;
  final double confidenceScore;
  final Map<String, dynamic> breakdown;

  const Opportunity({
    required this.id,
    required this.productName,
    this.inventoryItemId,
    required this.type,
    required this.action,
    required this.reason,
    required this.monthlyImpact,
    this.confidenceScore = 0.7,
    this.breakdown = const {},
  });

  String get formattedImpact => 'R ${monthlyImpact.toStringAsFixed(2)}';

  bool get isHighImpact => monthlyImpact >= 500;
  bool get isMediumImpact => monthlyImpact >= 200 && monthlyImpact < 500;

  String get impactLevel {
    if (monthlyImpact >= 1000) return 'High';
    if (monthlyImpact >= 500) return 'Medium';
    return 'Low';
  }
}

class GapMatchResult {
  final double targetGap;
  final List<Opportunity> selectedOpportunities;
  final double totalImpact;
  final bool gapClosable;
  final double remainingShortfall;
  final double coveragePercentage;

  const GapMatchResult({
    required this.targetGap,
    required this.selectedOpportunities,
    required this.totalImpact,
    required this.gapClosable,
    required this.remainingShortfall,
    required this.coveragePercentage,
  });

  factory GapMatchResult.empty() => const GapMatchResult(
        targetGap: 0,
        selectedOpportunities: [],
        totalImpact: 0,
        gapClosable: true,
        remainingShortfall: 0,
        coveragePercentage: 100,
      );

  factory GapMatchResult.match({
    required double gap,
    required List<Opportunity> opportunities,
  }) {
    if (gap <= 0) {
      return const GapMatchResult(
        targetGap: 0,
        selectedOpportunities: [],
        totalImpact: 0,
        gapClosable: true,
        remainingShortfall: 0,
        coveragePercentage: 100,
      );
    }

    final sorted = List<Opportunity>.from(opportunities)
      ..sort((a, b) => b.monthlyImpact.compareTo(a.monthlyImpact));

    final selected = <Opportunity>[];
    double runningTotal = 0;

    for (final opp in sorted) {
      if (runningTotal >= gap) break;
      selected.add(opp);
      runningTotal += opp.monthlyImpact;
    }

    final totalImpact = _round(runningTotal);
    final gapClosable = totalImpact >= gap;
    final remaining = gapClosable ? 0.0 : _round(gap - totalImpact);
    final coverage = gap > 0
        ? _round((totalImpact / gap) * 100).clamp(0.0, 100.0).toDouble()
        : 100.0;

    return GapMatchResult(
      targetGap: gap,
      selectedOpportunities: selected,
      totalImpact: totalImpact,
      gapClosable: gapClosable,
      remainingShortfall: remaining,
      coveragePercentage: coverage,
    );
  }

  static double _round(double value) => (value * 100).roundToDouble() / 100;

  String get formattedTotalImpact => 'R ${totalImpact.toStringAsFixed(2)}';
  String get formattedShortfall => 'R ${remainingShortfall.toStringAsFixed(2)}';
}
