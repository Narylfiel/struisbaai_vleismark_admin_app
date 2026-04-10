import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/features/bookkeeping/services/ledger_repository.dart';
import 'package:admin_app/features/reports/services/report_repository.dart';
import 'package:admin_app/features/analytics/services/analytics_repository.dart';
import 'package:admin_app/features/hr/services/staff_credit_repository.dart';
import '../models/debt_summary.dart';
import '../models/gap_analysis.dart';
import '../models/strategy_plan.dart';
import '../models/opportunity.dart';

/// Debt Buster Service — Target-driven decision engine for debt clearance.
/// 
/// READ-ONLY: This service only reads data and performs calculations.
/// It does not modify any database records.
/// 
/// Reuses existing repositories:
/// - SupplierInvoiceRepository (via direct query for total debt)
/// - StaffCreditRepository (for staff debt)
/// - LedgerRepository (for cash flow)
/// - ReportRepository (for pricing intelligence)
/// - AnalyticsRepository (for shrinkage and reorder data)
class DebtBusterService {
  final SupabaseClient _client;
  final LedgerRepository _ledgerRepo;
  final ReportRepository _reportRepo;
  final AnalyticsRepository _analyticsRepo;
  final StaffCreditRepository _staffCreditRepo;

  DebtBusterService({
    SupabaseClient? client,
    LedgerRepository? ledgerRepo,
    ReportRepository? reportRepo,
    AnalyticsRepository? analyticsRepo,
    StaffCreditRepository? staffCreditRepo,
  })  : _client = client ?? SupabaseService.client,
        _ledgerRepo = ledgerRepo ?? LedgerRepository(client: client),
        _reportRepo = reportRepo ?? ReportRepository(client: client),
        _analyticsRepo = analyticsRepo ?? AnalyticsRepository(client: client),
        _staffCreditRepo = staffCreditRepo ?? StaffCreditRepository(client: client);

  static double _round(double value) => (value * 100).roundToDouble() / 100;

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 3: TOTAL DEBT CALCULATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get total supplier debt from supplier_invoices where status is not paid.
  Future<({double total, int count})> _getSupplierDebt() async {
    try {
      final response = await _client
          .from('supplier_invoices')
          .select('balance_due, status')
          .neq('status', 'paid')
          .neq('status', 'cancelled')
          .neq('status', 'draft');

      double total = 0;
      int count = 0;

      for (final row in response as List) {
        final balance = (row['balance_due'] as num?)?.toDouble() ?? 0;
        if (balance > 0) {
          total += balance;
          count++;
        }
      }

      return (total: _round(total), count: count);
    } catch (e) {
      debugPrint('DebtBuster: Error fetching supplier debt: $e');
      return (total: 0.0, count: 0);
    }
  }

  /// Get total staff debt from staff_credit (outstanding only).
  Future<({double total, int count})> _getStaffDebt() async {
    try {
      final balances = await _staffCreditRepo.getOutstandingBalancesByStaff();
      final total = balances.values.fold<double>(0, (sum, val) => sum + val);
      return (total: _round(total), count: balances.length);
    } catch (e) {
      debugPrint('DebtBuster: Error fetching staff debt: $e');
      return (total: 0.0, count: 0);
    }
  }

  /// Get combined debt summary.
  Future<DebtSummary> getDebtSummary() async {
    try {
      final supplierDebt = await _getSupplierDebt();
      final staffDebt = await _getStaffDebt();

      final totalDebt = _round(supplierDebt.total + staffDebt.total);

      return DebtSummary(
        supplierDebt: supplierDebt.total,
        staffDebt: staffDebt.total,
        totalDebt: totalDebt,
        supplierInvoiceCount: supplierDebt.count,
        staffCreditCount: staffDebt.count,
        asOfDate: DateTime.now(),
      );
    } catch (e) {
      debugPrint('DebtBuster: Error calculating debt summary: $e');
      return DebtSummary.empty();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 4: AVAILABLE MONTHLY CASH
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculate average monthly net cash from the last N months.
  /// Uses LedgerRepository.getCashFlowByMonth() which returns real ledger data.
  Future<double> getAvailableMonthlyCash({int monthCount = 6}) async {
    try {
      final now = DateTime.now();

      // 1) Get real balances as a sanity check (cash + bank are operational capability).
      final balances = await _ledgerRepo.getAccountBalancesToDate(now);
      final cashBalance = (balances['1000'] ?? 0).toDouble();
      final bankBalance = (balances['1100'] ?? 0).toDouble();
      final currentBalance = cashBalance + bankBalance;

      // 2) Use cashflow trend as the monthly repayment capability.
      final cashFlowData = await _ledgerRepo.getCashFlowByMonth(monthCount);
      if (cashFlowData.isEmpty) return 0.0;

      double totalNet = 0.0;
      int validMonths = 0;

      for (final month in cashFlowData) {
        final net = (month['net'] as num?)?.toDouble();
        if (net == null || !net.isFinite) continue;
        totalNet += net;
        validMonths++;
      }

      if (validMonths == 0) return 0.0;

      // IMPORTANT: monthly capability comes from flow trend (net cash), not only balances.
      final avgNetCash = totalNet / validMonths;
      if (!avgNetCash.isFinite) return 0.0;

      // Defensive: if flow trend is exactly 0 and on-hand cash is also non-positive, return 0.
      // Otherwise we return avgNetCash as the monthly repayment capability.
      if (currentBalance <= 0 && avgNetCash == 0.0) return 0.0;

      // Final: monthly repayment capability comes from the flow trend.
      return _round(avgNetCash);
    } catch (e) {
      debugPrint('DebtBuster: Error calculating available cash: $e');
      return 0.0;
    }
  }

  /// Get detailed cash flow breakdown for display.
  Future<List<Map<String, dynamic>>> getCashFlowBreakdown({int monthCount = 6}) async {
    try {
      return await _ledgerRepo.getCashFlowByMonth(monthCount);
    } catch (e) {
      debugPrint('DebtBuster: Error fetching cash flow breakdown: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 5: GAP ANALYSIS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculate the gap between required and available cash.
  GapAnalysis calculateGap({
    required double totalDebt,
    required int targetMonths,
    required double availableCash,
  }) {
    return GapAnalysis.calculate(
      totalDebt: totalDebt,
      targetMonths: targetMonths,
      availableCash: availableCash,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 6: STRATEGY PLANS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate all three strategy plans.
  List<StrategyPlan> generateStrategies({
    required double totalDebt,
    required double availableCash,
  }) {
    return [
      StrategyPlan.calculate(
        level: StrategyLevel.conservative,
        totalDebt: totalDebt,
        availableCash: availableCash,
      ),
      StrategyPlan.calculate(
        level: StrategyLevel.balanced,
        totalDebt: totalDebt,
        availableCash: availableCash,
      ),
      StrategyPlan.calculate(
        level: StrategyLevel.aggressive,
        totalDebt: totalDebt,
        availableCash: availableCash,
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 7: OPPORTUNITY ENGINE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate actionable opportunities from real data.
  Future<List<Opportunity>> generateOpportunities() async {
    try {
      // Prevent double counting across opportunity types by keeping only the
      // highest-priority opportunity per product.
      final bestByProductId = <String, Opportunity>{};

      void upsert(Opportunity opp) {
        final productKey = (opp.inventoryItemId ?? opp.id).trim();
        if (productKey.isEmpty) return;

        final existing = bestByProductId[productKey];
        if (existing == null) {
          bestByProductId[productKey] = opp;
          return;
        }

        final existingPriority = _opportunityPriority(existing.type);
        final newPriority = _opportunityPriority(opp.type);

        // Lower number = higher priority.
        final isHigherPriority = newPriority < existingPriority;
        final isSamePriorityHigherImpact =
            newPriority == existingPriority && opp.monthlyImpact > existing.monthlyImpact;

        if (isHigherPriority || isSamePriorityHigherImpact) {
          bestByProductId[productKey] = opp;
        }
      }

      // A. Pricing-based opportunities (loss + low margin).
      final pricingOpportunities = await _getPricingOpportunities();
      for (final opp in pricingOpportunities) {
        upsert(opp);
      }

      // B. Shrinkage opportunities.
      final shrinkageOpportunities = await _getShrinkageOpportunities();
      for (final opp in shrinkageOpportunities) {
        upsert(opp);
      }

      // C. Slow-moving stock opportunities.
      final slowStockOpportunities = await _getSlowStockOpportunities();
      for (final opp in slowStockOpportunities) {
        upsert(opp);
      }

      final opportunities = bestByProductId.values.toList();
      opportunities.sort((a, b) => b.monthlyImpact.compareTo(a.monthlyImpact));
      return opportunities;
    } catch (e) {
      debugPrint('DebtBuster: Error generating opportunities: $e');
      return [];
    }
  }

  int _opportunityPriority(OpportunityType type) {
    switch (type) {
      case OpportunityType.loss:
        return 0;
      case OpportunityType.shrinkage:
        return 1;
      case OpportunityType.margin:
        return 2;
      case OpportunityType.slow_stock:
        return 3;
    }
  }

  /// A & B: Extract opportunities from pricing intelligence (low margin + loss).
  Future<List<Opportunity>> _getPricingOpportunities() async {
    final opportunities = <Opportunity>[];

    try {
      final now = DateTime.now();
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final start = DateTime(end.year, end.month, end.day).subtract(const Duration(days: 30));

      final rows = await _reportRepo.getPricingIntelligenceRowsForAlerts(start, end);

      for (final row in rows) {
        final productName = row['product_name']?.toString() ?? 'Unknown';
        final itemId = row['inventory_item_id']?.toString() ?? '';
        final profit = (row['profit'] as num?)?.toDouble() ?? 0;
        final margin = (row['margin'] as num?)?.toDouble() ?? 0;
        final revenue = (row['revenue'] as num?)?.toDouble() ?? 0;
        final marginFlag = row['margin_flag']?.toString();

        if (itemId.isEmpty || itemId == 'unknown') continue;

        // LOSS PRODUCTS (profit < 0)
        if (profit < 0) {
          final monthlyImpact = _round(profit.abs());
          if (monthlyImpact >= 50) {
            opportunities.add(Opportunity(
              id: 'loss_$itemId',
              productName: productName,
              inventoryItemId: itemId,
              type: OpportunityType.loss,
              action: 'Review pricing or discontinue',
              reason: 'Product is losing R${profit.abs().toStringAsFixed(2)}/month',
              monthlyImpact: monthlyImpact,
              confidenceScore: 0.9,
              breakdown: {
                'current_profit': profit,
                'revenue': revenue,
                'margin_pct': margin,
              },
            ));
          }
        }
        // LOW MARGIN PRODUCTS (margin < 20%)
        else if (marginFlag == 'low' || margin < 20) {
          // Estimate impact: if margin increased to 25%, additional profit
          final targetMargin = 25.0;
          if (margin < targetMargin && revenue > 0) {
            final currentProfit = revenue * (margin / 100);
            final potentialProfit = revenue * (targetMargin / 100);
            final additionalProfit = _round(potentialProfit - currentProfit);

            if (additionalProfit >= 50) {
              opportunities.add(Opportunity(
                id: 'margin_$itemId',
                productName: productName,
                inventoryItemId: itemId,
                type: OpportunityType.margin,
                action: 'Increase price by ${(targetMargin - margin).toStringAsFixed(1)}%',
                reason: 'Current margin ${margin.toStringAsFixed(1)}% below target',
                monthlyImpact: additionalProfit,
                confidenceScore: 0.75,
                breakdown: {
                  'current_margin': margin,
                  'target_margin': targetMargin,
                  'revenue': revenue,
                  'additional_profit': additionalProfit,
                },
              ));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('DebtBuster: Error fetching pricing opportunities: $e');
    }

    return opportunities;
  }

  /// C: Extract opportunities from shrinkage alerts.
  Future<List<Opportunity>> _getShrinkageOpportunities() async {
    final opportunities = <Opportunity>[];

    try {
      final alerts = await _analyticsRepo.getShrinkageAlerts();

      // Group shrinkage by product and separate kg-gap vs monetary gap.
      final shrinkageByProduct = <String, Map<String, dynamic>>{};

      for (final alert in alerts) {
        if (alert.status == 'Resolved' || alert.status == 'Acknowledged') continue;

        final productName = alert.productName ?? 'Unknown';
        final productId = alert.productId ?? productName;
        // Defensive: prefer theoretical/actual (kg). If those aren't present,
        // treat gap_amount as already meaningful (monetary), not kg.
        final theoreticalKg = alert.theoreticalStock;
        final actualKg = alert.actualStock;
        final hasQtyGap = theoreticalKg != null && actualKg != null;

        final qtyGapKg = hasQtyGap ? (theoreticalKg - actualKg).abs() : 0.0;
        final gapValue = hasQtyGap ? 0.0 : (alert.gapAmount ?? 0.0).toDouble();

        if (qtyGapKg <= 0 && gapValue <= 0) continue;

        shrinkageByProduct.putIfAbsent(productId, () => {
          'product_name': productName,
          'total_gap_kg': 0.0,
          'total_gap_value': 0.0,
          'alert_count': 0,
        });

        shrinkageByProduct[productId]!['total_gap_kg'] =
            (shrinkageByProduct[productId]!['total_gap_kg'] as double) + qtyGapKg;

        shrinkageByProduct[productId]!['total_gap_value'] =
            (shrinkageByProduct[productId]!['total_gap_value'] as double) + gapValue;
        shrinkageByProduct[productId]!['alert_count'] =
            (shrinkageByProduct[productId]!['alert_count'] as int) + 1;
      }

      // Fetch cost (average_cost) for all productIds in one query (defensive + performance).
      final productIds = shrinkageByProduct.keys.toList();
      final costById = <String, double>{};
      if (productIds.isNotEmpty) {
        try {
          final rows = await _client
              .from('inventory_items')
              .select('id, average_cost, cost_price')
              .inFilter('id', productIds);

          for (final raw in (rows as List)) {
            final m = raw as Map<String, dynamic>;
            final id = (m['id'] as String?)?.trim() ?? '';
            if (id.isEmpty) continue;
            final avgCost = (m['average_cost'] as num?)?.toDouble();
            final costPrice = avgCost ??
                (m['cost_price'] as num?)?.toDouble();
            if (costPrice == null || !costPrice.isFinite) continue;
            costById[id] = costPrice;
          }
        } catch (e) {
          debugPrint('DebtBuster: shrinkage cost fetch failed: $e');
        }
      }

      // Monetize: kg-gap * average_cost + monetary gap.
      for (final entry in shrinkageByProduct.entries) {
        final productId = entry.key;
        final data = entry.value;
        final totalGapKg = (data['total_gap_kg'] as num?)?.toDouble() ?? 0.0;
        final totalGapValue = (data['total_gap_value'] as num?)?.toDouble() ?? 0.0;
        final productName = data['product_name']?.toString() ?? 'Unknown';

        final costPrice = costById[productId] ?? 0.0;
        final kgMonetized = (totalGapKg > 0 && costPrice > 0)
            ? (totalGapKg * costPrice)
            : 0.0;

        final shrinkageValue = kgMonetized + totalGapValue;
        final monthlyImpact = _round(shrinkageValue);

        if (monthlyImpact <= 0) continue;

        opportunities.add(Opportunity(
          id: 'shrink_$productId',
          productName: productName,
          inventoryItemId: productId,
          type: OpportunityType.shrinkage,
          action: 'Increase sell-through (promotion cycle)',
          reason: 'Estimated shrinkage value: R${monthlyImpact.toStringAsFixed(2)}',
          monthlyImpact: monthlyImpact,
          confidenceScore: 0.7,
          breakdown: {
            'shrinkage_saved': monthlyImpact,
            'alert_count': data['alert_count'],
          },
        ));
      }
    } catch (e) {
      debugPrint('DebtBuster: Error fetching shrinkage opportunities: $e');
    }

    return opportunities;
  }

  /// D: Extract opportunities from slow-moving stock.
  Future<List<Opportunity>> _getSlowStockOpportunities() async {
    final opportunities = <Opportunity>[];

    try {
      final recommendations = await _analyticsRepo.getReorderRecommendations();

      // STEP A: Collect all itemIds that need cost lookup.
      final itemIds = <String>{};
      final candidates = <Map<String, dynamic>>[];

      for (final rec in recommendations) {
        final productName = rec['product_name']?.toString() ?? 'Unknown';
        final itemId = rec['inventory_item_id']?.toString() ?? '';
        final daysRemainingStr = rec['days_remaining']?.toString() ?? '999';
        final dailyVelocity = (rec['daily_velocity'] as num?)?.toDouble() ?? 0;
        final currentStock = double.tryParse(rec['current_stock']?.toString() ?? '0') ?? 0;

        // Only process slow-moving items (high days remaining, low velocity)
        final daysRemaining = double.tryParse(daysRemainingStr) ?? 999;

        if (daysRemaining > 30 && dailyVelocity < 0.5 && currentStock > 0) {
          if (itemId.isNotEmpty) {
            itemIds.add(itemId);
          }
          candidates.add({
            'productName': productName,
            'itemId': itemId,
            'daysRemaining': daysRemaining,
            'dailyVelocity': dailyVelocity,
            'currentStock': currentStock,
          });
        }
      }

      // STEP B: Single batched query for all costs (N+1 elimination).
      final costById = <String, double>{};
      if (itemIds.isNotEmpty) {
        try {
          final rows = await _client
              .from('inventory_items')
              .select('id, average_cost, cost_price')
              .inFilter('id', itemIds.toList());

          for (final raw in (rows as List)) {
            final map = raw as Map<String, dynamic>;
            final id = map['id']?.toString() ?? '';
            if (id.isEmpty) continue;

            final avg = (map['average_cost'] as num?)?.toDouble();
            final cost = (map['cost_price'] as num?)?.toDouble();
            costById[id] = avg ?? cost ?? 0.0;
          }
        } catch (e) {
          debugPrint('DebtBuster: slow stock batch cost fetch failed: $e');
          // Fail gracefully — costById remains empty, fallbacks apply below.
        }
      }

      // STEP C: Process candidates with cached costs.
      for (final c in candidates) {
        final productName = c['productName'] as String;
        final itemId = c['itemId'] as String;
        final daysRemaining = c['daysRemaining'] as double;
        final dailyVelocity = c['dailyVelocity'] as double;
        final currentStock = c['currentStock'] as double;

        // Lookup cached cost (fallback to 0.0 if missing, then to 50.0 if zero)
        var costPrice = costById[itemId] ?? 0.0;
        if (costPrice == 0.0) {
          costPrice = 50.0; // Historical fallback preserved
        }

        final tiedCapital = currentStock * costPrice;

        // Assume promotion could move 30% of excess stock monthly
        final excessStock = currentStock * 0.3;
        final monthlyImpact = _round(excessStock * costPrice * 0.1);

        if (monthlyImpact >= 100 && tiedCapital > 500) {
          opportunities.add(Opportunity(
            id: 'slow_$itemId',
            productName: productName,
            inventoryItemId: itemId,
            type: OpportunityType.slow_stock,
            action: 'Run promotion or reduce ordering',
            reason: '${daysRemaining.toStringAsFixed(0)} days of stock, low velocity',
            monthlyImpact: monthlyImpact,
            confidenceScore: 0.5,
            breakdown: {
              'current_stock': currentStock,
              'days_remaining': daysRemaining,
              'daily_velocity': dailyVelocity,
              'tied_capital': tiedCapital,
            },
          ));
        }
      }
    } catch (e) {
      debugPrint('DebtBuster: Error fetching slow stock opportunities: $e');
    }

    return opportunities;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 8: GAP MATCHING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Match opportunities to close the gap.
  GapMatchResult matchOpportunitiesToGap({
    required double gap,
    required List<Opportunity> opportunities,
  }) {
    return GapMatchResult.match(gap: gap, opportunities: opportunities);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMBINED ANALYSIS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Run full debt buster analysis.
  Future<DebtBusterAnalysis> runFullAnalysis({
    required int targetMonths,
    int cashFlowMonths = 6,
  }) async {
    // 1. Get debt summary
    final debtSummary = await getDebtSummary();

    // 2. Get available monthly cash
    final availableCash = await getAvailableMonthlyCash(monthCount: cashFlowMonths);

    // 3. Calculate gap
    final gapAnalysis = calculateGap(
      totalDebt: debtSummary.totalDebt,
      targetMonths: targetMonths,
      availableCash: availableCash,
    );

    // 4. Generate strategies
    final strategies = generateStrategies(
      totalDebt: debtSummary.totalDebt,
      availableCash: availableCash,
    );

    // 5. Generate opportunities
    final opportunities = await generateOpportunities();

    // 6. Match opportunities to gap
    final gapMatch = matchOpportunitiesToGap(
      gap: gapAnalysis.gap,
      opportunities: opportunities,
    );

    // 7. Get cash flow breakdown for details
    final cashFlowBreakdown = await getCashFlowBreakdown(monthCount: cashFlowMonths);

    return DebtBusterAnalysis(
      debtSummary: debtSummary,
      availableMonthlyCash: availableCash,
      gapAnalysis: gapAnalysis,
      strategies: strategies,
      opportunities: opportunities,
      gapMatch: gapMatch,
      cashFlowBreakdown: cashFlowBreakdown,
      analyzedAt: DateTime.now(),
    );
  }
}

/// Complete debt buster analysis result.
class DebtBusterAnalysis {
  final DebtSummary debtSummary;
  final double availableMonthlyCash;
  final GapAnalysis gapAnalysis;
  final List<StrategyPlan> strategies;
  final List<Opportunity> opportunities;
  final GapMatchResult gapMatch;
  final List<Map<String, dynamic>> cashFlowBreakdown;
  final DateTime analyzedAt;

  const DebtBusterAnalysis({
    required this.debtSummary,
    required this.availableMonthlyCash,
    required this.gapAnalysis,
    required this.strategies,
    required this.opportunities,
    required this.gapMatch,
    required this.cashFlowBreakdown,
    required this.analyzedAt,
  });

  factory DebtBusterAnalysis.empty() => DebtBusterAnalysis(
        debtSummary: DebtSummary.empty(),
        availableMonthlyCash: 0,
        gapAnalysis: GapAnalysis.empty(),
        strategies: [],
        opportunities: [],
        gapMatch: GapMatchResult.empty(),
        cashFlowBreakdown: [],
        analyzedAt: DateTime.now(),
      );

  bool get isGoalAchievable => gapAnalysis.status != GapStatus.shortfall || gapMatch.gapClosable;

  String get formattedAvailableCash => 'R ${availableMonthlyCash.toStringAsFixed(2)}';
}
