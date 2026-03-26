/// Structured AI input for Debt Buster.
///
/// IMPORTANT: AI must ONLY interpret these fields.
/// No AI calculations, no new data sources, no DB queries.
class DebtBusterAIInput {
  final double totalDebt;
  final double requiredMonthly;
  final double availableMonthly;
  final double gap;
  final bool isAchievable;
  final List<Map<String, dynamic>> opportunities;

  // Scenario planning inputs (deterministic levers from Scenario Engine UI).
  final double scenarioShrinkageReductionPct;
  final double scenarioMarginIncreasePct;
  final double scenarioExpenseReductionPct;
  final double scenarioStockClearancePct;

  // Scenario trust signal (from Scenario Engine overlap + bounds).
  final double scenarioConfidenceScore;
  final String scenarioPrimaryDriver;

  DebtBusterAIInput({
    required this.totalDebt,
    required this.requiredMonthly,
    required this.availableMonthly,
    required this.gap,
    required this.isAchievable,
    required this.opportunities,
    required this.scenarioShrinkageReductionPct,
    required this.scenarioMarginIncreasePct,
    required this.scenarioExpenseReductionPct,
    required this.scenarioStockClearancePct,
    required this.scenarioConfidenceScore,
    required this.scenarioPrimaryDriver,
  });
}

