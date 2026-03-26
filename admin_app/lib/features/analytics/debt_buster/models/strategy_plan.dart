/// Repayment strategy model — different intensity levels.
enum StrategyLevel {
  conservative,
  balanced,
  aggressive,
}

extension StrategyLevelExt on StrategyLevel {
  String get displayLabel {
    switch (this) {
      case StrategyLevel.conservative:
        return 'Conservative';
      case StrategyLevel.balanced:
        return 'Balanced';
      case StrategyLevel.aggressive:
        return 'Aggressive';
    }
  }

  String get description {
    switch (this) {
      case StrategyLevel.conservative:
        return 'Lower monthly payments, longer timeline';
      case StrategyLevel.balanced:
        return 'Moderate payments, reasonable timeline';
      case StrategyLevel.aggressive:
        return 'Higher payments, fastest clearance';
    }
  }

  double get cashAllocationPercent {
    switch (this) {
      case StrategyLevel.conservative:
        return 0.20;
      case StrategyLevel.balanced:
        return 0.40;
      case StrategyLevel.aggressive:
        return 0.75;
    }
  }
}

class StrategyPlan {
  final StrategyLevel level;
  final double totalDebt;
  final double availableCash;
  final double monthlyPayment;
  final int monthsToClear;
  final double totalInterestEstimate;
  final bool isFeasible;

  const StrategyPlan({
    required this.level,
    required this.totalDebt,
    required this.availableCash,
    required this.monthlyPayment,
    required this.monthsToClear,
    this.totalInterestEstimate = 0,
    required this.isFeasible,
  });

  factory StrategyPlan.calculate({
    required StrategyLevel level,
    required double totalDebt,
    required double availableCash,
  }) {
    if (totalDebt <= 0) {
      return StrategyPlan(
        level: level,
        totalDebt: 0,
        availableCash: availableCash,
        monthlyPayment: 0,
        monthsToClear: 0,
        isFeasible: true,
      );
    }

    final allocationPct = level.cashAllocationPercent;
    final monthlyPayment = _round(availableCash * allocationPct);

    if (monthlyPayment <= 0) {
      return StrategyPlan(
        level: level,
        totalDebt: totalDebt,
        availableCash: availableCash,
        monthlyPayment: 0,
        monthsToClear: -1,
        isFeasible: false,
      );
    }

    final months = (totalDebt / monthlyPayment).ceil();
    final isFeasible = months <= 60;

    return StrategyPlan(
      level: level,
      totalDebt: totalDebt,
      availableCash: availableCash,
      monthlyPayment: monthlyPayment,
      monthsToClear: months,
      isFeasible: isFeasible,
    );
  }

  static double _round(double value) => (value * 100).roundToDouble() / 100;

  String get formattedMonthlyPayment => 'R ${monthlyPayment.toStringAsFixed(2)}';

  String get timelineDescription {
    if (!isFeasible) return 'Not feasible';
    if (monthsToClear <= 0) return 'No debt';
    if (monthsToClear == 1) return '1 month';
    if (monthsToClear <= 12) return '$monthsToClear months';
    final years = monthsToClear ~/ 12;
    final remainingMonths = monthsToClear % 12;
    if (remainingMonths == 0) return '$years year${years > 1 ? 's' : ''}';
    return '$years year${years > 1 ? 's' : ''}, $remainingMonths month${remainingMonths > 1 ? 's' : ''}';
  }
}
