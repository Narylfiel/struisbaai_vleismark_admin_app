import 'dart:async';
import 'dart:convert';

import 'package:admin_app/core/services/ai_service.dart';

import '../models/debt_buster_ai_input.dart';

/// Thin wrapper around the existing bookkeeping AI service.
///
/// This wrapper must:
/// - Reuse the same [AiService] instance/implementation.
/// - ONLY build a prompt from already-computed, structured Debt Buster data.
/// - NEVER query Supabase or calculate new values.
class DebtBusterAIService {
  final AiService _aiService;

  const DebtBusterAIService(this._aiService);

  Future<String> generateInsights(DebtBusterAIInput input) async {
    final prompt = _buildPrompt(input);

    try {
      // Timeout safety: avoid blocking the UI indefinitely.
      final result = await _aiService
          .prompt(prompt)
          .timeout(const Duration(seconds: 12));
      return result ?? '';
    } on TimeoutException {
      return '';
    } catch (_) {
      return '';
    }
  }

  String _buildPrompt(DebtBusterAIInput input) {
    final payload = jsonEncode({
      'total_debt': input.totalDebt,
      'required_monthly': input.requiredMonthly,
      'available_monthly': input.availableMonthly,
      'gap': input.gap,
      'is_achievable': input.isAchievable,
      'opportunities': input.opportunities,
      'scenario_inputs': {
        'shrinkage_reduction_pct': input.scenarioShrinkageReductionPct,
        'margin_increase_pct': input.scenarioMarginIncreasePct,
        'expense_reduction_pct': input.scenarioExpenseReductionPct,
        'stock_clearance_pct': input.scenarioStockClearancePct,
      },
      'scenario_confidence_score': input.scenarioConfidenceScore,
      'scenario_primary_driver': input.scenarioPrimaryDriver,
    });

    return '''
You are a business financial advisor.

You MUST ONLY use the data provided below.
DO NOT assume missing data.
DO NOT invent numbers.
DO NOT perform calculations.

MUST follow this deterministic markdown structure exactly (use the headings):

## 1. Current Situation
- In 2–3 short lines, explain why the debt exists using the provided `gap`, `total_debt`,
  `available_monthly`, and `is_achievable` fields.

## 2. Primary Driver
- In 1–2 lines, state the `scenario_primary_driver` and what it implies operationally.

## 3. Top Actions
- In 3–5 short bullets, list the top actions from the provided `opportunities` array.
- For each action, include `action` and `impact` (no new numbers).

## 4. Feasibility
- In 1–2 lines, state whether the goal is achievable using `scenario_confidence_score`.
- If not achievable, explain the constraint using the provided `gap` only.

## 5. Recommended Focus
- In 1–2 lines, recommend what to do first, aligned with the primary driver.

Constraints:
- Max ~5–7 lines per section.
- DO NOT invent numbers.
- DO NOT perform calculations.
- Use only DATA provided below.

DATA:
${payload}
''';
  }
}

