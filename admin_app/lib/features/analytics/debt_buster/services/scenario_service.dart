import 'dart:convert';

import 'package:admin_app/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../bookkeeping/services/ledger_repository.dart';
import '../models/opportunity.dart';
import '../models/scenario_input.dart';
import '../models/scenario_result.dart';
import 'debt_buster_service.dart';

/// Scenario Engine (planning-only).
/// It never modifies DB state and never changes `DebtBusterService` logic.
///
/// It works by:
/// 1) Using DebtBuster's baseline outputs (DebtBusterAnalysis)
/// 2) Reading additional "real data" needed for operational levers (ledger + inventory)
/// 3) Applying controlled, explainable percentages to baseline derived totals
class ScenarioService {
  final SupabaseClient _client = SupabaseService.client;
  final LedgerRepository _ledgerRepo = LedgerRepository();

  _ScenarioTotals? _cachedTotals;
  String? _cachedKey;
  String? _inFlightKey;
  Future<void>? _inFlightLoad;

  /// Simulate controlled improvements on top of Debt Buster.
  Future<ScenarioResult> simulateScenario({
    required ScenarioInput input,
    required DebtBusterAnalysis baseline,
  }) async {
    await _ensureTotalsLoaded(baseline);
    final totals = _cachedTotals;
    if (totals == null) {
      return _fallbackResult(baseline);
    }

    final clamped = _clampedInput(input);

    // Controlled cash levers.
    // - shrinkageImpact: recover a pct of monetized shrinkage losses (monthly basis).
    // - marginImpact: profit improvement from revenue * margin increase pct (monthly basis).
    // - expenseImpact: monthly expense reduction from ledger expense totals.
    // - stockImpact: one-off cash release from clearing identified slow stock.
    //   For feasibility against a monthly repayment plan, we convert to a monthly equivalent
    //   by spreading across `targetMonths`.
    final shrinkageImpact =
        totals.totalShrinkageValue * (clamped.shrinkageReductionPct / 100.0);
    final marginImpact =
        totals.totalRevenue * (clamped.marginIncreasePct / 100.0);
    final expenseImpact =
        totals.totalExpensesMonthly * (clamped.expenseReductionPct / 100.0);
    final stockImpact = totals.totalStockValue * (clamped.stockClearancePct / 100.0);

    final safeTargetMonths = totals.targetMonths > 0 ? totals.targetMonths : 1;
    final monthlyStockImpact = stockImpact / safeTargetMonths;

    // Enhanced overlap model:
    // Apply diminishing returns per lever, then adjust recurring levers for
    // dependency overlap. Stock is handled separately (one-off cash release).
    double overlapFactor = 1.0;
    if (clamped.shrinkageReductionPct > 25.0) {
      overlapFactor -= (clamped.shrinkageReductionPct - 25.0) * 0.005;
    }
    if (clamped.marginIncreasePct > 4.0) {
      overlapFactor -= (clamped.marginIncreasePct - 4.0) * 0.01;
    }
    if (clamped.expenseReductionPct > 10.0) {
      overlapFactor -= (clamped.expenseReductionPct - 10.0) * 0.005;
    }
    overlapFactor = overlapFactor.clamp(0.65, 1.0);

    final effectiveShrinkage = shrinkageImpact *
        (1.0 - (clamped.shrinkageReductionPct / 100.0 * 0.3));
    final effectiveMargin =
        marginImpact * (1.0 - (clamped.marginIncreasePct / 100.0 * 0.4));
    final effectiveExpenses =
        expenseImpact * (1.0 - (clamped.expenseReductionPct / 100.0 * 0.3));

    final sumEffectiveRecurring = effectiveShrinkage + effectiveMargin + effectiveExpenses;
    final adjustedRecurringImpact = sumEffectiveRecurring * overlapFactor;

    // Allocate the net recurring impact back to levers so the UI breakdown
    // matches the actual applied recurring impact (after overlap).
    final shareBase = sumEffectiveRecurring > 0 ? sumEffectiveRecurring : 0.0;
    final netShrinkageImpact =
        shareBase > 0 ? (effectiveShrinkage / shareBase) * adjustedRecurringImpact : 0.0;
    final netMarginImpact =
        shareBase > 0 ? (effectiveMargin / shareBase) * adjustedRecurringImpact : 0.0;
    final netExpenseImpact =
        shareBase > 0 ? (effectiveExpenses / shareBase) * adjustedRecurringImpact : 0.0;

    final adjustedAvailableCash = baseline.availableMonthlyCash + adjustedRecurringImpact + monthlyStockImpact;
    final rawGap = baseline.gapAnalysis.requiredMonthly - adjustedAvailableCash;
    final newGap = rawGap > 0 ? rawGap : 0.0;
    final achievable = rawGap <= 0;

    final confidenceBreakdown = _computeConfidenceBreakdown(
      clamped: clamped,
      overlapFactor: overlapFactor,
    );
    final confidenceScore = _computeConfidenceScoreFromBreakdown(
      confidenceBreakdown: confidenceBreakdown,
    );

    final primaryDriver = _computePrimaryDriver(
      shrinkageImpact: netShrinkageImpact,
      marginImpact: netMarginImpact,
      expenseImpact: netExpenseImpact,
      stockImpact: stockImpact,
    );

    return ScenarioResult(
      adjustedAvailableCash: _round2(adjustedAvailableCash),
      newGap: _round2(newGap),
      achievable: achievable,
      confidenceScore: confidenceScore,
      confidenceBreakdown: confidenceBreakdown,
      primaryDriver: primaryDriver,
      shrinkageImpact: _round2(netShrinkageImpact),
      marginImpact: _round2(netMarginImpact),
      expenseImpact: _round2(netExpenseImpact),
      stockImpact: _round2(stockImpact),
    );
  }

  Map<String, double> _computeConfidenceBreakdown({
    required ScenarioInput clamped,
    required double overlapFactor,
  }) {
    // Overlap risk is represented as "trust" (higher = safer).
    final overlapRiskScore =
        (((overlapFactor.clamp(0.65, 1.0) - 0.65) / 0.35) * 100.0).clamp(0.0, 100.0);

    final dataStrength = (100.0 -
            (clamped.marginIncreasePct > 5.0 ? 10.0 : 0.0) -
            (clamped.shrinkageReductionPct > 30.0 ? 10.0 : 0.0) -
            (clamped.expenseReductionPct > 15.0 ? 10.0 : 0.0))
        .clamp(0.0, 100.0);

    final assumptionLevel = (100.0 -
            (clamped.stockClearancePct > 70.0 ? 10.0 : 0.0) -
            (overlapFactor < 0.85 ? 10.0 : 0.0))
        .clamp(0.0, 100.0);

    return {
      'data_strength': _round2(dataStrength),
      'assumption_level': _round2(assumptionLevel),
      'overlap_risk': _round2(overlapRiskScore),
    };
  }

  double _computeConfidenceScoreFromBreakdown({
    required Map<String, double> confidenceBreakdown,
  }) {
    final data = confidenceBreakdown['data_strength'] ?? 50.0;
    final assumptions = confidenceBreakdown['assumption_level'] ?? 50.0;
    final overlapRisk = confidenceBreakdown['overlap_risk'] ?? 50.0;

    final score = [data, assumptions, overlapRisk].reduce((a, b) => a < b ? a : b);
    if (!score.isFinite) return 50.0;
    return score.clamp(50.0, 100.0);
  }

  String _computePrimaryDriver({
    required double shrinkageImpact,
    required double marginImpact,
    required double expenseImpact,
    required double stockImpact,
  }) {
    final eps = 1e-9;
    final maxVal = _scenarioMax4(
      a: shrinkageImpact,
      b: marginImpact,
      c: expenseImpact,
      d: stockImpact,
    );

    if (shrinkageImpact >= maxVal - eps) return 'shrinkage';
    if (marginImpact >= maxVal - eps) return 'margin';
    if (expenseImpact >= maxVal - eps) return 'expenses';
    return 'stock';
  }

  Future<void> _ensureTotalsLoaded(DebtBusterAnalysis baseline) async {
    final safeMonthCount = baseline.cashFlowBreakdown.isNotEmpty
        ? baseline.cashFlowBreakdown.length
        : 6;

    final startEnd = _periodRange(safeMonthCount);
    final periodStart = startEnd.$1;
    final periodEnd = startEnd.$2;

    final selected = baseline.gapMatch.selectedOpportunities;
    final marginOpps = selected.where((o) => o.type == OpportunityType.margin);
    final shrinkOpps =
        selected.where((o) => o.type == OpportunityType.shrinkage);
    final slowOpps = selected.where((o) => o.type == OpportunityType.slow_stock);
    final slowIds = slowOpps
        .map((o) => (o.inventoryItemId ?? '').trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final derivedKey = jsonEncode({
      'monthCount': safeMonthCount,
      'targetMonths': baseline.gapAnalysis.targetMonths,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'totalDebt': baseline.debtSummary.totalDebt,
      'margin': marginOpps.map((o) => {
            'id': o.id,
            'inventoryItemId': o.inventoryItemId,
            'revenue': o.breakdown['revenue'],
          }).toList(growable: false),
      'shrinkage': shrinkOpps.map((o) => {
            'id': o.id,
            'impact': o.monthlyImpact,
            'saved': o.breakdown['shrinkage_saved'],
          }).toList(growable: false),
      'slowIds': slowIds,
    });

    if (_cachedKey == derivedKey && _cachedTotals != null) return;
    if (_inFlightKey == derivedKey && _inFlightLoad != null) {
      await _inFlightLoad;
      return;
    }

    // Compute totals from baseline derived values + real ledger/inventory for operational levers.
    _inFlightKey = derivedKey;
    _inFlightLoad = () async {
      double totalShrinkageValue = 0.0;
      double totalRevenue = 0.0;
      for (final opp in selected) {
        if (opp.type == OpportunityType.shrinkage) {
          // DebtBuster already monetized shrinkage losses into `monthlyImpact`.
          final saved = (opp.breakdown['shrinkage_saved'] as num?)?.toDouble();
          totalShrinkageValue += (saved ?? opp.monthlyImpact);
        } else if (opp.type == OpportunityType.margin) {
          totalRevenue += (opp.breakdown['revenue'] as num?)?.toDouble() ?? 0.0;
        }
      }

      totalShrinkageValue = totalShrinkageValue.isFinite ? totalShrinkageValue : 0.0;
      totalRevenue = totalRevenue.isFinite ? totalRevenue : 0.0;

      final totalExpensesMonthly = await _computeTotalExpensesMonthly(
        start: periodStart,
        end: periodEnd,
        monthCount: safeMonthCount,
      );

      final totalStockValue = await _computeTotalStockValueForSlowItems(slowIds);

      _cachedTotals = _ScenarioTotals(
        totalShrinkageValue: totalShrinkageValue,
        totalRevenue: totalRevenue,
        totalExpensesMonthly: totalExpensesMonthly,
        totalStockValue: totalStockValue,
        monthCount: safeMonthCount,
        targetMonths: baseline.gapAnalysis.targetMonths,
      );
      _cachedKey = derivedKey;
    }();

    try {
      await _inFlightLoad;
    } finally {
      _inFlightKey = null;
      _inFlightLoad = null;
    }
  }

  Future<double> _computeTotalExpensesMonthly({
    required DateTime start,
    required DateTime end,
    required int monthCount,
  }) async {
    final expenseCodes = <String>[
      '6000',
      '6100',
      '6200',
      '6300',
      '6400',
      '6500',
      '6510',
      '6600',
      '6700',
      '6900',
    ];

    try {
      final pnl = await _ledgerRepo.getPnLSummary(start, end);
      double expenseTotalPeriod = 0.0;
      for (final code in expenseCodes) {
        final row = pnl[code];
        if (row == null) continue;
        expenseTotalPeriod += (row['debit'] ?? 0.0);
      }

      if (monthCount <= 0) return 0.0;
      final monthly = expenseTotalPeriod / monthCount;
      return monthly.isFinite ? monthly : 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  Future<double> _computeTotalStockValueForSlowItems(List<String> itemIds) async {
    if (itemIds.isEmpty) return 0.0;

    double total = 0.0;
    const chunkSize = 100;
    for (var i = 0; i < itemIds.length; i += chunkSize) {
      final chunk = itemIds.sublist(
        i,
        i + chunkSize > itemIds.length ? itemIds.length : i + chunkSize,
      );
      try {
        final rows = await _client
            .from('inventory_items')
            .select('id, current_stock, average_cost, cost_price')
            .inFilter('id', chunk);

        for (final raw in (rows as List)) {
          final m = raw as Map<String, dynamic>;
          final currentStock = (m['current_stock'] as num?)?.toDouble() ?? 0.0;
          final avgCost = (m['average_cost'] as num?)?.toDouble();
          final costPrice = avgCost ?? (m['cost_price'] as num?)?.toDouble() ?? 0.0;
          if (!currentStock.isFinite || !costPrice.isFinite) continue;
          final safeStock = currentStock > 0 ? currentStock : 0.0;
          total += safeStock * costPrice;
        }
      } catch (_) {
        // If inventory lookup fails, scenario should still function with remaining levers.
      }
    }

    return total.isFinite ? total : 0.0;
  }

  ScenarioInput _clampedInput(ScenarioInput input) {
    final shrinkageReductionPct = _clamp(input.shrinkageReductionPct, 0.0, 50.0);
    final marginIncreasePct = _clamp(input.marginIncreasePct, 0.0, 10.0);
    final expenseReductionPct = _clamp(input.expenseReductionPct, 0.0, 20.0);
    final stockClearancePct = _clamp(input.stockClearancePct, 0.0, 100.0);
    return ScenarioInput(
      shrinkageReductionPct: shrinkageReductionPct,
      marginIncreasePct: marginIncreasePct,
      expenseReductionPct: expenseReductionPct,
      stockClearancePct: stockClearancePct,
    );
  }

  double _clamp(double value, double min, double max) {
    if (!value.isFinite) return min;
    return value.clamp(min, max).toDouble();
  }

  (DateTime, DateTime) _periodRange(int monthCount) {
    final now = DateTime.now();
    final safeMonthCount = monthCount > 0 ? monthCount : 6;
    final start = DateTime(now.year, now.month - (safeMonthCount - 1), 1);
    final end = DateTime(now.year, now.month + 1, 0);
    return (start, end);
  }

  ScenarioResult _fallbackResult(DebtBusterAnalysis baseline) {
    return ScenarioResult(
      adjustedAvailableCash: baseline.availableMonthlyCash,
      newGap: baseline.gapAnalysis.gap,
      achievable: baseline.isGoalAchievable,
      confidenceScore: 50.0,
      confidenceBreakdown: const {
        'data_strength': 50.0,
        'assumption_level': 50.0,
        'overlap_risk': 50.0,
      },
      primaryDriver: 'expenses',
      shrinkageImpact: 0.0,
      marginImpact: 0.0,
      expenseImpact: 0.0,
      stockImpact: 0.0,
    );
  }

  double _round2(double v) => (v * 100).roundToDouble() / 100.0;
}

class _ScenarioTotals {
  final double totalShrinkageValue;
  final double totalRevenue;
  final double totalExpensesMonthly;
  final double totalStockValue;

  final int monthCount;
  final int targetMonths;

  const _ScenarioTotals({
    required this.totalShrinkageValue,
    required this.totalRevenue,
    required this.totalExpensesMonthly,
    required this.totalStockValue,
    required this.monthCount,
    required this.targetMonths,
  });
}

double _scenarioMax4({
  required double a,
  required double b,
  required double c,
  required double d,
}) {
  return [a, b, c, d].reduce((x, y) => x > y ? x : y);
}


