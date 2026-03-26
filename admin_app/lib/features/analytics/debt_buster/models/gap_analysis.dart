/// Gap analysis result — compares required vs available cash.
enum GapStatus {
  onTrack,
  shortfall,
  noDebt,
}

extension GapStatusExt on GapStatus {
  String get displayLabel {
    switch (this) {
      case GapStatus.onTrack:
        return 'On Track';
      case GapStatus.shortfall:
        return 'Shortfall';
      case GapStatus.noDebt:
        return 'No Debt';
    }
  }

  bool get isHealthy => this == GapStatus.onTrack || this == GapStatus.noDebt;
}

class GapAnalysis {
  final double totalDebt;
  final int targetMonths;
  final double requiredMonthly;
  final double availableMonthly;
  final double gap;
  final GapStatus status;
  final double shortfallPercentage;

  const GapAnalysis({
    required this.totalDebt,
    required this.targetMonths,
    required this.requiredMonthly,
    required this.availableMonthly,
    required this.gap,
    required this.status,
    required this.shortfallPercentage,
  });

  factory GapAnalysis.calculate({
    required double totalDebt,
    required int targetMonths,
    required double availableCash,
  }) {
    if (totalDebt <= 0) {
      return GapAnalysis(
        totalDebt: 0,
        targetMonths: targetMonths,
        requiredMonthly: 0,
        availableMonthly: availableCash,
        gap: 0,
        status: GapStatus.noDebt,
        shortfallPercentage: 0,
      );
    }

    final safeMonths = targetMonths > 0 ? targetMonths : 1;
    final required = totalDebt / safeMonths;
    final gapValue = required - availableCash;

    final status = gapValue <= 0 ? GapStatus.onTrack : GapStatus.shortfall;
    final shortfallPct = required > 0
        ? (gapValue / required * 100).clamp(0.0, 100.0).toDouble()
        : 0.0;

    return GapAnalysis(
      totalDebt: totalDebt,
      targetMonths: safeMonths,
      requiredMonthly: _round(required),
      availableMonthly: _round(availableCash),
      gap: _round(gapValue > 0 ? gapValue : 0),
      status: status,
      shortfallPercentage: _round(shortfallPct),
    );
  }

  factory GapAnalysis.empty() => const GapAnalysis(
        totalDebt: 0,
        targetMonths: 6,
        requiredMonthly: 0,
        availableMonthly: 0,
        gap: 0,
        status: GapStatus.noDebt,
        shortfallPercentage: 0,
      );

  static double _round(double value) => (value * 100).roundToDouble() / 100;

  bool get hasShortfall => gap > 0;

  String get formattedRequired => 'R ${requiredMonthly.toStringAsFixed(2)}';
  String get formattedAvailable => 'R ${availableMonthly.toStringAsFixed(2)}';
  String get formattedGap => 'R ${gap.toStringAsFixed(2)}';
}
