/// Controlled levers for "What if we improve operations?"
/// This is planning-only: it never writes to the database or changes DebtBuster outputs.
class ScenarioInput {
  /// Percent reduction in monetized shrinkage losses.
  /// Expected range: 0–50 (clamped defensively in ScenarioService).
  final double shrinkageReductionPct;

  /// Percent increase applied to margin improvement, derived from revenue.
  /// Expected range: 0–10 (clamped defensively in ScenarioService).
  final double marginIncreasePct;

  /// Percent reduction applied to monthly expense totals.
  /// Expected range: 0–20 (clamped defensively in ScenarioService).
  final double expenseReductionPct;

  /// Percent of tied-up capital from identified slow-moving items that is released as cash.
  /// Expected range: 0–100 (clamped defensively in ScenarioService).
  final double stockClearancePct;

  const ScenarioInput({
    required this.shrinkageReductionPct,
    required this.marginIncreasePct,
    required this.expenseReductionPct,
    required this.stockClearancePct,
  });
}

