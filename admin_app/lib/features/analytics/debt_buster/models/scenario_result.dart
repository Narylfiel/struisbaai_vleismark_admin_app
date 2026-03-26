/// Result of simulating controlled operational improvements on top of DebtBuster.
class ScenarioResult {
  /// Baseline available monthly cash adjusted by scenario cash levers.
  final double adjustedAvailableCash;

  /// Baseline required monthly payment minus adjusted available monthly cash.
  /// <= 0 means the goal is achievable within the selected deadline.
  final double newGap;

  /// Whether `newGap <= 0`.
  final bool achievable;

  /// Trust level of this scenario plan: 0–100.
  final double confidenceScore;

  /// Deterministic breakdown of confidence components (0–100 each).
  /// Keys:
  /// - `data_strength`
  /// - `assumption_level`
  /// - `overlap_risk`
  final Map<String, double> confidenceBreakdown;

  /// Which lever contributes most to the simulated improvement.
  /// One of: `shrinkage`, `margin`, `expenses`, `stock`
  final String primaryDriver;

  /// Monetized monthly shrinkage recovery (already in currency units).
  final double shrinkageImpact;

  /// Monetized monthly margin improvement (derived from revenue * pct).
  final double marginImpact;

  /// Monetized monthly expense reduction (derived from expenses * pct).
  final double expenseImpact;

  /// Monetized cash released from clearing slow-moving stock.
  /// This is a "one-off" cash component, but can be converted to monthly
  /// for the feasibility check in the UI/service.
  final double stockImpact;

  const ScenarioResult({
    required this.adjustedAvailableCash,
    required this.newGap,
    required this.achievable,
    required this.confidenceScore,
    required this.confidenceBreakdown,
    required this.primaryDriver,
    required this.shrinkageImpact,
    required this.marginImpact,
    required this.expenseImpact,
    required this.stockImpact,
  });
}

