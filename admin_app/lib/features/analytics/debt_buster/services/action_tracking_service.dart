import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:admin_app/features/analytics/services/analytics_repository.dart';
import 'package:admin_app/features/reports/services/report_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/action_tracking.dart';
import '../models/opportunity.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/models/shrinkage_alert.dart';

/// Local persistence for action tracking.
/// No DB writes; kept strictly in-memory + SharedPreferences.
class ActionTrackingService {
  static const _prefsKey = 'debt_buster_action_tracking_v1';

  final AnalyticsRepository _analyticsRepo = AnalyticsRepository();
  final ReportRepository _reportRepo = ReportRepository();
  final SupabaseClient _client = SupabaseService.client;

  Future<Map<String, ActionTracking>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.trim().isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};

      final result = <String, ActionTracking>{};
      for (final entry in decoded.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is! Map) continue;
        result[key] = ActionTracking.fromJson(
          Map<String, dynamic>.from(value as Map),
        );
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveAll(Map<String, ActionTracking> actionsById) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(actionsById.map((key, a) => MapEntry(key, a.toJson())));
    await prefs.setString(_prefsKey, encoded);
  }

  /// Capture baseline signals at the moment the user starts an action.
  /// We reuse already-computed signals from `Opportunity.breakdown` where possible.
  /// This avoids extra DB queries on click.
  ActionTracking captureBaseline({
    required Opportunity opportunity,
    required DateTime startedAt,
  }) {
    final oppType = opportunity.type;
    final productId = (opportunity.inventoryItemId ?? '').trim();
    final typeString = _typeToString(oppType);

    double? shrinkageValue;
    double? marginPct;
    double? revenue;
    double? lossProfit;
    double? stockLevel;

    switch (oppType) {
      case OpportunityType.shrinkage:
        // DebtBuster monetizes shrinkage into currency monthlyImpact.
        shrinkageValue = (opportunity.breakdown['shrinkage_saved'] as num?)?.toDouble() ??
            opportunity.monthlyImpact;
        break;
      case OpportunityType.margin:
        marginPct = (opportunity.breakdown['current_margin'] as num?)?.toDouble();
        revenue = (opportunity.breakdown['revenue'] as num?)?.toDouble();
        break;
      case OpportunityType.loss:
        lossProfit = (opportunity.breakdown['current_profit'] as num?)?.toDouble();
        revenue = (opportunity.breakdown['revenue'] as num?)?.toDouble();
        break;
      case OpportunityType.slow_stock:
        // DebtBuster computes tiedCapital = currentStock * costPrice.
        stockLevel = (opportunity.breakdown['tied_capital'] as num?)?.toDouble();
        break;
    }

    return ActionTracking(
      opportunityId: opportunity.id,
      type: typeString,
      productId: productId,
      startedAt: startedAt,
      completed: false,
      expectedImpact: opportunity.monthlyImpact,
      baselineShrinkageValue: shrinkageValue,
      baselineMargin: marginPct,
      baselineRevenue: revenue,
      baselineLossProfit: lossProfit,
      baselineStockLevel: stockLevel,
      measuredImpact: null,
    );
  }

  Future<Map<String, ActionTracking>> measureActions({
    required Map<String, ActionTracking> actionsById,
    required int minEvaluationDays,
    DateTime? now,
  }) async {
    final evaluationNow = now ?? DateTime.now();

    // Only measure actions that are due and have baseline signals.
    // Re-measure actions (including previously "completed") once enough
    // time has passed. This keeps local feedback consistent when
    // measurement logic improves.
    final incomplete = actionsById.entries
        .map((e) => e.value)
        .where(
          (a) => evaluationNow.difference(a.startedAt).inDays >= minEvaluationDays,
        )
        .toList();

    if (incomplete.isEmpty) return actionsById;

    const minShrinkageEvents = 5; // post-action alert events
    const minPricingQuantity = 5.0; // post-action sold quantity proxy

    final shrinkageActions = incomplete
        .where((a) =>
            a.type == 'shrinkage' &&
            a.productId.isNotEmpty &&
            a.baselineShrinkageValue != null)
        .toList();

    final pricingActions = incomplete
        .where((a) =>
            (a.type == 'margin' || a.type == 'loss') &&
            a.productId.isNotEmpty)
        .toList();

    final stockActions = incomplete
        .where((a) =>
            a.type == 'slow_stock' &&
            a.productId.isNotEmpty &&
            a.baselineStockLevel != null)
        .toList();

    final shrinkageIds = shrinkageActions.map((a) => a.productId).toSet().toList(growable: false);
    final stockIds = stockActions.map((a) => a.productId).toSet().toList(growable: false);

    // These are snapshot signals; differences isolate post-action changes.
    final currentStockValueByProductId =
        await _fetchCurrentStockValueByProductId(stockIds);

    // Pre-load shrinkage alerts (read-only) and average costs for monetization.
    final allShrinkageAlerts = shrinkageIds.isEmpty
        ? const <ShrinkageAlert>[]
        : await _analyticsRepo.getShrinkageAlerts();
    final costById = await _fetchAvgCostById(shrinkageIds.toSet());

    // Cache shrinkage post-action windows by action startedAt.
    final shrinkageStartEpochs = shrinkageActions
        .map((a) => a.startedAt.millisecondsSinceEpoch)
        .toSet()
        .toList(growable: false);

    final Map<int, Map<String, ({double value, int count})>> shrinkageWindowCache = {};
    for (final epoch in shrinkageStartEpochs) {
      final windowStart = DateTime.fromMillisecondsSinceEpoch(epoch);
      final windowEnd = evaluationNow;

      final qtyGapKgByProductId = <String, double>{};
      final monetaryGapByProductId = <String, double>{};
      final countByProductId = <String, int>{};

      for (final alert in allShrinkageAlerts) {
        if (alert.productId == null) continue;
        final pid = alert.productId!.trim();
        if (pid.isEmpty || !shrinkageIds.contains(pid)) continue;
        if (alert.createdAt == null) continue;

        final createdAt = alert.createdAt!;
        if (createdAt.isBefore(windowStart) || createdAt.isAfter(windowEnd)) continue;
        if (alert.status == 'Resolved' || alert.status == 'Acknowledged') continue;

        final theoreticalKg = alert.theoreticalStock;
        final actualKg = alert.actualStock;
        final hasQtyGap = theoreticalKg != null && actualKg != null;

        final qtyGapKg = hasQtyGap ? (theoreticalKg - actualKg).abs() : 0.0;
        final gapValue = hasQtyGap ? 0.0 : (alert.gapAmount ?? 0.0).toDouble();

        qtyGapKgByProductId[pid] = (qtyGapKgByProductId[pid] ?? 0.0) + qtyGapKg;
        monetaryGapByProductId[pid] =
            (monetaryGapByProductId[pid] ?? 0.0) + gapValue;
        countByProductId[pid] = (countByProductId[pid] ?? 0) + 1;
      }

      final metrics = <String, ({double value, int count})>{};
      for (final pid in shrinkageIds) {
        final qtyGapKg = qtyGapKgByProductId[pid] ?? 0.0;
        final monetaryGap = monetaryGapByProductId[pid] ?? 0.0;
        final cost = costById[pid] ?? 0.0;
        final kgMonetized = (qtyGapKg > 0 && cost > 0) ? (qtyGapKg * cost) : 0.0;
        final value = _round2(kgMonetized + monetaryGap);
        metrics[pid] = (value: value, count: countByProductId[pid] ?? 0);
      }
      shrinkageWindowCache[epoch] = metrics;
    }

    // Cache pricing windows by action startedAt.
    final pricingStartEpochs = pricingActions
        .where((a) => a.productId.isNotEmpty)
        .map((a) => a.startedAt.millisecondsSinceEpoch)
        .toSet()
        .toList(growable: false);

    final pricingProductIds = pricingActions.map((a) => a.productId).toSet().toList(growable: false);
    final Set<String> pricingIdSet = pricingProductIds.toSet();

    final Map<int, Map<String, ({double margin, double revenue, double profit, double quantity})>> pricingWindowCache = {};
    for (final epoch in pricingStartEpochs) {
      final windowStart = DateTime.fromMillisecondsSinceEpoch(epoch);
      final windowEnd = evaluationNow;

      // Read-only: pricing intelligence over the post-action window.
      final rows = await _reportRepo.getPricingIntelligenceRowsForAlerts(windowStart, windowEnd);

      final out = <String, ({double margin, double revenue, double profit, double quantity})>{};
      for (final raw in rows) {
        final pid = raw['inventory_item_id']?.toString() ?? '';
        if (pid.isEmpty || !pricingIdSet.contains(pid)) continue;
        final margin = (raw['margin'] as num?)?.toDouble() ?? 0.0;
        final revenue = (raw['revenue'] as num?)?.toDouble() ?? 0.0;
        final profit = (raw['profit'] as num?)?.toDouble() ?? 0.0;
        final quantity = (raw['quantity'] as num?)?.toDouble() ?? 0.0;
        out[pid] = (margin: margin, revenue: revenue, profit: profit, quantity: quantity);
      }
      pricingWindowCache[epoch] = out;
    }

    final updated = Map<String, ActionTracking>.from(actionsById);

    for (final action in incomplete) {
      final daysSinceStart = evaluationNow.difference(action.startedAt).inDays;
      if (daysSinceStart < minEvaluationDays) continue;
      final startedEpoch = action.startedAt.millisecondsSinceEpoch;

      double? measuredMonthlyImpact;

      switch (action.type) {
        case 'shrinkage': {
          final pid = action.productId;
          final metrics = shrinkageWindowCache[startedEpoch]?[pid];
          if (pid.isEmpty || metrics == null) break;
          if (metrics.count < minShrinkageEvents) break;

          final baseMonthly = action.baselineShrinkageValue;
          if (baseMonthly == null) break;

          final currentMonthly = (metrics.value / daysSinceStart) * 30.0;
          final delta = (baseMonthly - currentMonthly).clamp(0.0, double.infinity);
          measuredMonthlyImpact = _round2(delta);
          break;
        }
        case 'margin': {
          final pid = action.productId;
          final pricing = pricingWindowCache[startedEpoch]?[pid];
          final baseMargin = action.baselineMargin;
          final baseRevenue = action.baselineRevenue;
          if (pid.isEmpty || pricing == null || baseMargin == null || baseRevenue == null) break;
          if (pricing.quantity < minPricingQuantity || pricing.revenue <= 0) break;

          final currentMonthlyRevenue = (pricing.revenue / daysSinceStart) * 30.0;
          var deltaMonthly = ((pricing.margin - baseMargin) / 100.0) * currentMonthlyRevenue;
          if (!deltaMonthly.isFinite) break;
          deltaMonthly = deltaMonthly.clamp(0.0, double.infinity);

          // Prevent false signals: margin improvement while revenue collapses.
          final baselineThresholdRevenue = baseRevenue * 0.7;
          if (baselineThresholdRevenue > 0 && currentMonthlyRevenue < baselineThresholdRevenue) {
            final ratio = currentMonthlyRevenue / baselineThresholdRevenue; // 0..1
            deltaMonthly = (deltaMonthly * ratio).clamp(0.0, double.infinity);
          }

          measuredMonthlyImpact = _round2(deltaMonthly);
          break;
        }
        case 'loss': {
          final pid = action.productId;
          final pricing = pricingWindowCache[startedEpoch]?[pid];
          final baseProfit = action.baselineLossProfit;
          if (pid.isEmpty || pricing == null || baseProfit == null) break;
          if (pricing.quantity < minPricingQuantity) break;

          final baseLossAbs = baseProfit < 0 ? baseProfit.abs() : 0.0;
          final currentLossAbs = pricing.profit < 0 ? pricing.profit.abs() : 0.0;
          final currentMonthlyLossAbs = (currentLossAbs / daysSinceStart) * 30.0;

          final delta = (baseLossAbs - currentMonthlyLossAbs).clamp(0.0, double.infinity);
          measuredMonthlyImpact = _round2(delta);
          break;
        }
        case 'slow_stock': {
          final pid = action.productId;
          final baseLevel = action.baselineStockLevel;
          final currentValue = currentStockValueByProductId[pid];
          if (pid.isEmpty || baseLevel == null || currentValue == null) break;

          final measuredActual = (baseLevel - currentValue).clamp(0.0, double.infinity);
          final measuredMonthly = (measuredActual / daysSinceStart) * 30.0;
          measuredMonthlyImpact = _round2(measuredMonthly);
          break;
        }
        default:
          break;
      }

      if (measuredMonthlyImpact == null) continue;

      final effectiveThreshold = action.expectedImpact * 0.6;
      final completed = measuredMonthlyImpact >= effectiveThreshold;

      updated[action.opportunityId] = action.copyWith(
        completed: completed,
        measuredImpact: measuredMonthlyImpact,
      );
    }

    return updated;
  }

  /// Spec-required method.
  /// In practice we support batch caches via optional parameters to keep
  /// measurements deterministic and low-noise.
  Future<Map<String, double>> _fetchCurrentShrinkageValueByProductId(
    List<String> productIds,
  ) async {
    if (productIds.isEmpty) return {};

    final setIds = productIds.toSet();
    final alerts = await _analyticsRepo.getShrinkageAlerts();

    // Compute kg-gaps + monetary gaps separately.
    final qtyGapKgByProduct = <String, double>{};
    final monetaryGapByProduct = <String, double>{};
    for (final alert in alerts) {
      final pid = (alert.productId ?? '').trim();
      if (pid.isEmpty || !setIds.contains(pid)) continue;
      if (alert.status == 'Resolved' || alert.status == 'Acknowledged') continue;

      final theoreticalKg = alert.theoreticalStock;
      final actualKg = alert.actualStock;
      final hasQtyGap = theoreticalKg != null && actualKg != null;

      final qtyGapKg = hasQtyGap ? (theoreticalKg - actualKg).abs() : 0.0;
      final gapValue = hasQtyGap ? 0.0 : (alert.gapAmount ?? 0.0).toDouble();

      qtyGapKgByProduct[pid] = (qtyGapKgByProduct[pid] ?? 0.0) + qtyGapKg;
      monetaryGapByProduct[pid] = (monetaryGapByProduct[pid] ?? 0.0) + gapValue;
    }

    final costById = await _fetchAvgCostById(setIds);

    final current = <String, double>{};
    for (final pid in setIds) {
      final qtyGapKg = qtyGapKgByProduct[pid] ?? 0.0;
      final monetaryGap = monetaryGapByProduct[pid] ?? 0.0;
      final cost = costById[pid] ?? 0.0;
      final kgMonetized = (qtyGapKg > 0 && cost > 0) ? (qtyGapKg * cost) : 0.0;
      current[pid] = _round2(kgMonetized + monetaryGap);
    }

    return current;
  }

  Future<Map<String, double>> _fetchCurrentStockValueByProductId(
    List<String> productIds,
  ) async {
    if (productIds.isEmpty) return {};

    final setIds = productIds.toSet();
    const chunkSize = 100;
    final out = <String, double>{};

    final ids = productIds.toList(growable: false);
    for (var i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.sublist(i, (i + chunkSize > ids.length) ? ids.length : i + chunkSize);
      try {
        final rows = await _client
            .from('inventory_items')
            .select('id, current_stock, average_cost, cost_price')
            .inFilter('id', chunk);

        for (final raw in (rows as List)) {
          final m = raw as Map<String, dynamic>;
          final pid = (m['id'] as String?)?.trim() ?? '';
          if (pid.isEmpty || !setIds.contains(pid)) continue;

          final stock = (m['current_stock'] as num?)?.toDouble() ?? 0.0;
          final avgCost = (m['average_cost'] as num?)?.toDouble();
          final costPrice = avgCost ?? (m['cost_price'] as num?)?.toDouble() ?? 0.0;
          if (!stock.isFinite || !costPrice.isFinite) continue;
          final safeStock = stock > 0 ? stock : 0.0;
          out[pid] = safeStock * costPrice;
        }
      } catch (_) {
        // Degrade gracefully: missing ids stay absent.
      }
    }

    return out;
  }

  Future<Map<String, double>> _fetchAvgCostById(Set<String> productIds) async {
    if (productIds.isEmpty) return {};

    const chunkSize = 100;
    final ids = productIds.toList(growable: false);
    final out = <String, double>{};

    for (var i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.sublist(i, (i + chunkSize > ids.length) ? ids.length : i + chunkSize);
      try {
        final rows = await _client
            .from('inventory_items')
            .select('id, average_cost, cost_price')
            .inFilter('id', chunk);
        for (final raw in (rows as List)) {
          final m = raw as Map<String, dynamic>;
          final pid = (m['id'] as String?)?.trim() ?? '';
          if (pid.isEmpty || !productIds.contains(pid)) continue;
          final avgCost = (m['average_cost'] as num?)?.toDouble();
          final costPrice = avgCost ?? (m['cost_price'] as num?)?.toDouble() ?? 0.0;
          if (costPrice.isFinite) out[pid] = costPrice;
        }
      } catch (_) {}
    }
    return out;
  }

  String _typeToString(OpportunityType type) {
    switch (type) {
      case OpportunityType.margin:
        return 'margin';
      case OpportunityType.shrinkage:
        return 'shrinkage';
      case OpportunityType.loss:
        return 'loss';
      case OpportunityType.slow_stock:
        return 'slow_stock';
    }
  }

  double _round2(double v) => (v * 100).roundToDouble() / 100.0;
}

