import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/ai_service.dart';
import '../services/debt_buster_service.dart';
import '../models/debt_buster_ai_input.dart';
import '../services/debt_buster_ai_service.dart';
import '../models/scenario_input.dart';
import '../models/scenario_result.dart';
import '../services/scenario_service.dart';
import '../services/action_tracking_service.dart';
import '../models/action_tracking.dart';
import '../widgets/debt_summary_card.dart';
import '../widgets/gap_indicator.dart';
import '../widgets/strategy_cards.dart';
import '../widgets/opportunity_list.dart';
import '../models/opportunity.dart';

/// Debt Buster Tab — Target-driven decision engine for debt clearance.
class DebtBusterTab extends StatefulWidget {
  const DebtBusterTab({super.key});

  @override
  State<DebtBusterTab> createState() => _DebtBusterTabState();
}

class _DebtBusterTabState extends State<DebtBusterTab> {
  final _service = DebtBusterService();
  final _aiWrapper = DebtBusterAIService(AiService());
  final _scenarioService = ScenarioService();
  final _targetMonthsController = TextEditingController(text: '6');

  DebtBusterAnalysis? _analysis;
  bool _isLoading = true;
  String? _error;
  int _targetMonths = 6;

  bool _isAiLoading = false;
  String? _aiInsights;
  String? _aiCacheKey;
  String? _aiCacheValue;
  int _aiRequestId = 0;

  // Scenario Engine (planning-only).
  double _shrinkageReductionPct = 0.0; // 0–50
  double _marginIncreasePct = 0.0; // 0–10
  double _expenseReductionPct = 0.0; // 0–20
  double _stockClearancePct = 0.0; // 0–100

  ScenarioResult? _scenarioResult;
  bool _isScenarioLoading = false;
  int _scenarioRequestId = 0;
  Timer? _scenarioDebounce;

  // Action tracking (local-only, closed-loop workflow).
  final _actionTrackingService = ActionTrackingService();
  Map<String, ActionTracking> _actionTrackingByOpportunityId = const {};
  bool _isActionTrackingLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
    _loadActionTracking();
  }

  @override
  void dispose() {
    _scenarioDebounce?.cancel();
    _aiDebounce?.cancel();
    _targetMonthsController.dispose();
    super.dispose();
  }

  Future<void> _loadActionTracking() async {
    try {
      setState(() => _isActionTrackingLoading = true);
      final loaded = await _actionTrackingService.loadAll();
      if (!mounted) return;
      setState(() {
        _actionTrackingByOpportunityId = loaded;
        _isActionTrackingLoading = false;
      });

      // If analysis is already loaded, refresh completion status on load.
      if (_analysis != null) {
        _refreshActionTrackingFeedback(_analysis!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _actionTrackingByOpportunityId = const {};
        _isActionTrackingLoading = false;
      });
    }
  }

  Future<void> _loadAnalysis() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final analysis = await _service.runFullAnalysis(
        targetMonths: _targetMonths,
        cashFlowMonths: 6,
      );

      if (mounted) {
        setState(() {
          _analysis = analysis;
          _isLoading = false;
          _isAiLoading = true;
          _aiInsights = null;

          // Kick off Scenario Engine simulation for the current slider state.
          _scenarioResult = null;
          _isScenarioLoading = true;
        });
      }

      // Scenario simulation is additive and non-blocking.
      _scenarioRequestId++;
      final scenarioRequestId = _scenarioRequestId;
      final input = _currentScenarioInput();
      _startScenarioSimulation(analysis, input, scenarioRequestId);

      // Measure tracked action outcomes against real cash movement (read-only feedback).
      _refreshActionTrackingFeedback(analysis);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  double _safeNum(double value) => value.isFinite ? value : 0.0;

  ScenarioInput _currentScenarioInput() {
    // UI sliders keep values in range, but we still build a clean object here.
    return ScenarioInput(
      shrinkageReductionPct: _shrinkageReductionPct,
      marginIncreasePct: _marginIncreasePct,
      expenseReductionPct: _expenseReductionPct,
      stockClearancePct: _stockClearancePct,
    );
  }

  Future<void> _startScenarioSimulation(
    DebtBusterAnalysis analysis,
    ScenarioInput input,
    int requestId,
  ) async {
    try {
      final result = await _scenarioService.simulateScenario(
        input: input,
        baseline: analysis,
      );
      if (!mounted) return;
      if (requestId != _scenarioRequestId) return;
      setState(() {
        _scenarioResult = result;
        _isScenarioLoading = false;
      });

      // AI enhancement uses the scenario trust signals; debounce API calls.
      _scheduleAiInsightsLoad(analysis, input, result);
    } catch (_) {
      if (!mounted) return;
      if (requestId != _scenarioRequestId) return;
      setState(() {
        _scenarioResult = _fallbackScenarioResult(analysis);
        _isScenarioLoading = false;
      });

      _scheduleAiInsightsLoad(analysis, input, _fallbackScenarioResult(analysis));
    }
  }

  void _scheduleScenarioSimulation(DebtBusterAnalysis analysis) {
    if (!mounted) return;
    setState(() {
      _isScenarioLoading = true;
      _scenarioResult = null;
    });
    _scenarioDebounce?.cancel();
    _scenarioDebounce = Timer(const Duration(milliseconds: 250), () {
      _scenarioRequestId++;
      final requestId = _scenarioRequestId;
      final input = _currentScenarioInput();
      _startScenarioSimulation(analysis, input, requestId);
    });
  }

  Timer? _aiDebounce;

  void _scheduleAiInsightsLoad(
    DebtBusterAnalysis analysis,
    ScenarioInput scenarioInput,
    ScenarioResult scenarioResult,
  ) {
    _aiDebounce?.cancel();
    _aiDebounce = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      _aiRequestId++;
      final requestId = _aiRequestId;
      setState(() {
        _isAiLoading = true;
        _aiInsights = null;
      });
      await _startAiInsightsLoad(
        analysis,
        requestId,
        scenarioInput: scenarioInput,
        scenarioResult: scenarioResult,
      );
    });
  }

  ScenarioResult _fallbackScenarioResult(DebtBusterAnalysis analysis) {
    return ScenarioResult(
      adjustedAvailableCash: analysis.availableMonthlyCash,
      newGap: analysis.gapAnalysis.gap,
      achievable: analysis.isGoalAchievable,
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

  void _startActionForOpportunity(
    DebtBusterAnalysis analysis,
    Opportunity opportunity,
  ) {
    final id = opportunity.id;
    final existing = _actionTrackingByOpportunityId[id];
    if (existing != null) return;

    final tracking = _actionTrackingService.captureBaseline(
      opportunity: opportunity,
      startedAt: DateTime.now(),
    );

    setState(() {
      _actionTrackingByOpportunityId =
          Map<String, ActionTracking>.from(_actionTrackingByOpportunityId)
            ..[id] = tracking;
    });

    // Persist asynchronously; closed-loop tracking does not block UI.
    _actionTrackingService.saveAll(_actionTrackingByOpportunityId);
  }

  Future<void> _refreshActionTrackingFeedback(DebtBusterAnalysis analysis) async {
    if (_actionTrackingByOpportunityId.isEmpty) return;
    try {
      setState(() => _isActionTrackingLoading = true);
      final updated = await _actionTrackingService.measureActions(
        actionsById: _actionTrackingByOpportunityId,
        minEvaluationDays: 3,
      );

      setState(() {
        _actionTrackingByOpportunityId = updated;
        _isActionTrackingLoading = false;
      });

      await _actionTrackingService.saveAll(updated);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isActionTrackingLoading = false);
    }
  }

  Future<void> _startAiInsightsLoad(
    DebtBusterAnalysis analysis,
    int requestId, {
    required ScenarioInput scenarioInput,
    required ScenarioResult scenarioResult,
  }) async {
    try {
      if (!mounted) return;
      if (analysis.debtSummary.totalDebt <= 0) {
        if (!mounted) return;
        setState(() {
          _isAiLoading = false;
          _aiInsights = 'AI insights unavailable — using data-driven analysis only';
        });
        return;
      }

      final selected = List<Opportunity>.from(
        analysis.gapMatch.selectedOpportunities,
      )..sort((a, b) {
          final byImpact = b.monthlyImpact.compareTo(a.monthlyImpact);
          if (byImpact != 0) return byImpact;
          final aKey = (a.inventoryItemId ?? a.productName).toString();
          final bKey = (b.inventoryItemId ?? b.productName).toString();
          return aKey.compareTo(bKey);
        });

      final opportunities = selected.map((o) {
        return {
          'product': o.productName,
          'action': o.action,
          'reason': o.reason,
          'impact': _safeNum(o.monthlyImpact),
        };
      }).toList(growable: false);

      final input = DebtBusterAIInput(
        totalDebt: _safeNum(analysis.debtSummary.totalDebt),
        requiredMonthly: _safeNum(analysis.gapAnalysis.requiredMonthly),
        availableMonthly: _safeNum(analysis.availableMonthlyCash),
        gap: _safeNum(analysis.gapAnalysis.gap),
        isAchievable: analysis.isGoalAchievable,
        opportunities: opportunities,
        scenarioShrinkageReductionPct: _safeNum(scenarioInput.shrinkageReductionPct),
        scenarioMarginIncreasePct: _safeNum(scenarioInput.marginIncreasePct),
        scenarioExpenseReductionPct: _safeNum(scenarioInput.expenseReductionPct),
        scenarioStockClearancePct: _safeNum(scenarioInput.stockClearancePct),
        scenarioConfidenceScore: _safeNum(scenarioResult.confidenceScore),
        scenarioPrimaryDriver: (scenarioResult.primaryDriver).toString(),
      );

      final cacheKey = jsonEncode({
        'totalDebt': input.totalDebt,
        'requiredMonthly': input.requiredMonthly,
        'availableMonthly': input.availableMonthly,
        'gap': input.gap,
        'isAchievable': input.isAchievable,
        'opportunities': opportunities,
        'scenario': {
          's_shrink': input.scenarioShrinkageReductionPct,
          's_margin': input.scenarioMarginIncreasePct,
          's_expense': input.scenarioExpenseReductionPct,
          's_stock': input.scenarioStockClearancePct,
          'confidence': input.scenarioConfidenceScore,
          'driver': input.scenarioPrimaryDriver,
        },
      });

      if (_aiCacheKey == cacheKey && _aiCacheValue != null) {
        if (!mounted) return;
        if (requestId != _aiRequestId) return;
        setState(() {
          _aiInsights = _aiCacheValue;
          _isAiLoading = false;
        });
        return;
      }

      final result = await _aiWrapper.generateInsights(input);
      final trimmed = result.trim();
      const fallback = 'AI insights unavailable — using data-driven analysis only';
      final finalText = trimmed.isEmpty ? fallback : trimmed;

      if (!mounted) return;
      if (requestId != _aiRequestId) return;
      setState(() {
        _aiInsights = finalText;
        _isAiLoading = false;
        _aiCacheKey = cacheKey;
        _aiCacheValue = finalText;
      });
    } catch (_) {
      if (!mounted) return;
      const fallback = 'AI insights unavailable — using data-driven analysis only';
      if (requestId != _aiRequestId) return;
      setState(() {
        _aiInsights = fallback;
        _isAiLoading = false;
      });
    }
  }

  void _updateTargetMonths(String value) {
    final months = int.tryParse(value);
    if (months != null && months > 0 && months <= 120) {
      setState(() {
        _targetMonths = months;
      });
      _loadAnalysis();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Analyzing debt and opportunities...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Error loading analysis',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadAnalysis,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final analysis = _analysis;
    if (analysis == null) {
      return const Center(child: Text('No data available'));
    }

    // No debt state
    if (!analysis.debtSummary.hasDebt) {
      return _buildNoDebtState();
    }

    return RefreshIndicator(
      onRefresh: _loadAnalysis,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header with target input
          _buildHeader(),
          const SizedBox(height: 16),

          // Two-column layout for desktop
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return _buildWideLayout(analysis);
              }
              return _buildNarrowLayout(analysis);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.track_changes, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Debt Buster',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Target-driven decision engine for debt clearance',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              const Text(
                'Clear in',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: _targetMonthsController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onSubmitted: _updateTargetMonths,
                  onChanged: (value) {
                    final months = int.tryParse(value);
                    if (months != null && months > 0 && months <= 120) {
                      _targetMonths = months;
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'months',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () {
                  _updateTargetMonths(_targetMonthsController.text);
                },
                icon: const Icon(Icons.calculate, size: 18),
                label: const Text('Calculate'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(DebtBusterAnalysis analysis) {
    final highlightOpportunityId = _topOpportunityId(analysis);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column - Debt & Gap
        Expanded(
          flex: 4,
          child: Column(
            children: [
              DebtSummaryCard(
                summary: analysis.debtSummary,
                onRefresh: _loadAnalysis,
              ),
              const SizedBox(height: 16),
              GapIndicator(
                analysis: analysis.gapAnalysis,
                isGoalAchievable: analysis.isGoalAchievable,
              ),
              const SizedBox(height: 16),
              StrategyCards(strategies: analysis.strategies),
              const SizedBox(height: 16),
              _buildScenarioEngineCard(analysis),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Right column - Opportunities
        Expanded(
          flex: 5,
          child: Column(
            children: [
              OpportunityList(
                opportunities: analysis.gapMatch.selectedOpportunities,
                matchResult: analysis.gapMatch,
                actionTrackingByOpportunityId: _actionTrackingByOpportunityId,
                onStartAction: (opp) => _startActionForOpportunity(analysis, opp),
                highlightOpportunityId: highlightOpportunityId,
              ),
              const SizedBox(height: 16),
              _buildAiInsightsCard(),
              if (analysis.cashFlowBreakdown.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildCashFlowDetails(analysis.cashFlowBreakdown),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(DebtBusterAnalysis analysis) {
    final highlightOpportunityId = _topOpportunityId(analysis);
    return Column(
      children: [
        DebtSummaryCard(
          summary: analysis.debtSummary,
          onRefresh: _loadAnalysis,
        ),
        const SizedBox(height: 16),
        GapIndicator(
          analysis: analysis.gapAnalysis,
          isGoalAchievable: analysis.isGoalAchievable,
        ),
        const SizedBox(height: 16),
        StrategyCards(strategies: analysis.strategies),
        const SizedBox(height: 16),
        _buildScenarioEngineCard(analysis),
        const SizedBox(height: 20),
        OpportunityList(
          opportunities: analysis.gapMatch.selectedOpportunities,
          matchResult: analysis.gapMatch,
          actionTrackingByOpportunityId: _actionTrackingByOpportunityId,
          onStartAction: (opp) => _startActionForOpportunity(analysis, opp),
          highlightOpportunityId: highlightOpportunityId,
        ),
        const SizedBox(height: 16),
        _buildAiInsightsCard(),
        if (analysis.cashFlowBreakdown.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildCashFlowDetails(analysis.cashFlowBreakdown),
        ],
      ],
    );
  }

  Widget _buildAiInsightsCard() {
    const fallback = 'AI insights unavailable — using data-driven analysis only';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, size: 20, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'AI Insights',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isAiLoading) ...[
              const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Generating explanation and priority guidance...',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Builder(
                builder: (context) {
                  final text = (_aiInsights ?? fallback).trim();
                  final safeText = text.isEmpty ? fallback : text;
                  return Text(
                    safeText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioEngineCard(DebtBusterAnalysis analysis) {
    final hasDebt = analysis.debtSummary.totalDebt > 0;
    final selectedOpps = analysis.gapMatch.selectedOpportunities;

    final hasPositiveCash = analysis.availableMonthlyCash > 0;

    final hasShrinkageSignal = selectedOpps.any(
      (o) =>
          o.type == OpportunityType.shrinkage &&
          ((o.breakdown['shrinkage_saved'] as num?)?.toDouble() ?? o.monthlyImpact) >
              0,
    );

    final hasMarginRevenue = selectedOpps
        .where((o) => o.type == OpportunityType.margin)
        .map((o) => (o.breakdown['revenue'] as num?)?.toDouble() ?? 0.0)
        .fold<double>(0.0, (a, b) => a + b) >
        0;

    final hasSlowStockSignal = selectedOpps
        .where((o) => o.type == OpportunityType.slow_stock)
        .map((o) => (o.breakdown['tied_capital'] as num?)?.toDouble() ?? 0.0)
        .fold<double>(0.0, (a, b) => a + b) >
        0;

    final disableShrinkage = !hasShrinkageSignal;
    final disableMargin = !hasMarginRevenue;
    final disableStock = !hasSlowStockSignal;

    final bool warnStockCombo = (_shrinkageReductionPct + _stockClearancePct) > 100.0;
    final bool warnMarginDemand = _marginIncreasePct > 8.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tune, size: 20, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Scenario Engine',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (!hasDebt) ...[
              const Text(
                'Scenario simulation is available when there is debt to clear.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
            ] else ...[
              if (!hasPositiveCash) ...[
                _warningBanner(
                  icon: Icons.money_off_rounded,
                  title: 'Business currently not generating positive cash flow',
                ),
                const SizedBox(height: 12),
              ],
              // Realism guards (UI-level warnings only).
              if (warnStockCombo) ...[
                _warningBanner(
                  icon: Icons.warning_amber_rounded,
                  title: 'Combined stock movement assumptions may be unrealistic',
                ),
                const SizedBox(height: 12),
              ],
              if (warnMarginDemand) ...[
                _warningBanner(
                  icon: Icons.info_outline,
                  title: 'High margin increase may impact demand',
                ),
                const SizedBox(height: 12),
              ],

              // Confidence + driver signal (computed from overlap + scenario levers).
              if (_scenarioResult != null) ...[
                const Divider(height: 24),
                _confidenceRow(
                  confidenceScore: _scenarioResult!.confidenceScore,
                  confidenceBreakdown: _scenarioResult!.confidenceBreakdown,
                ),
                const SizedBox(height: 10),
                _primaryDriverRow(driver: _scenarioResult!.primaryDriver),
                const SizedBox(height: 12),
                if (_scenarioResult!.confidenceScore < 65) ...[
                  _warningBanner(
                    icon: Icons.warning_amber_rounded,
                    title: 'Low confidence: verify assumptions in real operations before acting.',
                  ),
                  const SizedBox(height: 12),
                ],
              ],

              // Scenario presets for real-world usage.
              _scenarioPresets(
                onPick: (input) {
                  setState(() {
                    _shrinkageReductionPct = input.shrinkageReductionPct;
                    _marginIncreasePct = input.marginIncreasePct;
                    _expenseReductionPct = input.expenseReductionPct;
                    _stockClearancePct = input.stockClearancePct;
                  });
                  _scheduleScenarioSimulation(analysis);
                },
              ),
              const SizedBox(height: 10),

              _scenarioSlider(
                label: 'Shrinkage Reduction',
                value: _shrinkageReductionPct,
                max: 50,
                onChanged: (v) {
                  setState(() => _shrinkageReductionPct = v);
                  _scheduleScenarioSimulation(analysis);
                },
                hint: 'Controlled recovery of monetized shrinkage losses',
                enabled: !disableShrinkage,
              ),
              const SizedBox(height: 12),
              _scenarioSlider(
                label: 'Margin Increase',
                value: _marginIncreasePct,
                max: 10,
                onChanged: (v) {
                  setState(() => _marginIncreasePct = v);
                  _scheduleScenarioSimulation(analysis);
                },
                hint: 'Derived from revenue of detected margin opportunities',
                enabled: !disableMargin,
              ),
              const SizedBox(height: 12),
              _scenarioSlider(
                label: 'Expense Reduction',
                value: _expenseReductionPct,
                max: 20,
                onChanged: (v) {
                  setState(() => _expenseReductionPct = v);
                  _scheduleScenarioSimulation(analysis);
                },
                hint: 'Uses real ledger expense totals (monthly average)',
              ),
              const SizedBox(height: 12),
              _scenarioSlider(
                label: 'Stock Clearance',
                value: _stockClearancePct,
                max: 100,
                onChanged: (v) {
                  setState(() => _stockClearancePct = v);
                  _scheduleScenarioSimulation(analysis);
                },
                hint: 'One-off cash release from identified slow stock',
                enabled: !disableStock,
              ),

              const SizedBox(height: 14),
              if (_isScenarioLoading) ...[
                const Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Updating scenario impact...',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],

              if (_scenarioResult != null) ...[
                const Divider(height: 24),
                _scenarioOutputRow(
                  label: 'New Available Cash (Monthly)',
                  value: 'R ${_scenarioResult!.adjustedAvailableCash.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 10),
                _scenarioOutputRow(
                  label: 'New Gap',
                  value: 'R ${_scenarioResult!.newGap.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 12),
                _scenarioAchievableChip(
                  achievable: _scenarioResult!.achievable,
                  gap: _scenarioResult!.newGap,
                ),
                const SizedBox(height: 14),
                if (_actionTrackingByOpportunityId.isNotEmpty) ...[
                  const Text(
                    'Action Tracking',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  _actionTrackingPanel(analysis: analysis),
                  const SizedBox(height: 14),
                ] else ...[
                  const Text(
                    'Start an action from the opportunities list to enable plan -> act -> measure.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const Text(
                  'Impact Breakdown',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                _impactRow(
                  label: 'Shrinkage',
                  value: _scenarioResult!.shrinkageImpact,
                  color: AppColors.success,
                ),
                _impactRow(
                  label: 'Margin',
                  value: _scenarioResult!.marginImpact,
                  color: AppColors.success,
                ),
                _impactRow(
                  label: 'Expenses',
                  value: _scenarioResult!.expenseImpact,
                  color: AppColors.success,
                ),
                _impactRow(
                  label: 'Stock (one-off)',
                  value: _scenarioResult!.stockImpact,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Stock cash release is spread across your repayment window for feasibility.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (_scenarioResult == null && !_isScenarioLoading) ...[
                const Text(
                  'Scenario simulation unavailable — using baseline decision engine only.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _warningBanner({
    required IconData icon,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confidenceRow({
    required double confidenceScore,
    required Map<String, double> confidenceBreakdown,
  }) {
    final label = confidenceScore >= 80
        ? 'High'
        : (confidenceScore >= 65 ? 'Medium' : 'Low');
    final color = confidenceScore >= 80
        ? AppColors.success
        : (confidenceScore >= 65 ? AppColors.warning : AppColors.error);

    double dataStrength = confidenceBreakdown['data_strength'] ?? 50.0;
    double assumptionLevel = confidenceBreakdown['assumption_level'] ?? 50.0;
    double overlapRisk = confidenceBreakdown['overlap_risk'] ?? 50.0;

    final dataStrengthLabel =
        dataStrength >= 85 ? 'Strong' : (dataStrength >= 65 ? 'Moderate' : 'Weak');
    final assumptionLabel = assumptionLevel >= 85
        ? 'Low'
        : (assumptionLevel >= 65 ? 'Moderate' : 'High');
    final overlapLabel = overlapRisk >= 85
        ? 'Low'
        : (overlapRisk >= 65 ? 'Medium' : 'High');

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            border: Border.all(color: color.withOpacity(0.25)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    confidenceScore >= 80
                        ? Icons.verified
                        : (confidenceScore >= 65 ? Icons.info_outline : Icons.warning_amber),
                    size: 18,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Confidence: $label (${confidenceScore.toStringAsFixed(0)})',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Breakdown:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '- Data strength: $dataStrengthLabel (${dataStrength.toStringAsFixed(0)})',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                '- Assumptions: $assumptionLabel (${assumptionLevel.toStringAsFixed(0)})',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                '- Overlap risk: $overlapLabel (${overlapRisk.toStringAsFixed(0)})',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _primaryDriverRow({required String driver}) {
    final pretty = driver.isEmpty
        ? '—'
        : (driver[0].toUpperCase() + driver.substring(1));

    final Color color;
    switch (driver) {
      case 'shrinkage':
        color = Colors.purple;
        break;
      case 'margin':
        color = Colors.orange;
        break;
      case 'expenses':
        color = AppColors.success;
        break;
      case 'stock':
        color = AppColors.primary;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Row(
      children: [
        Icon(Icons.trending_up, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Main improvement comes from: $pretty',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            border: Border.all(color: color.withOpacity(0.25)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            pretty,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _scenarioPresets({
    required ValueChanged<ScenarioInput> onPick,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _presetButton(
          label: 'Conservative',
          icon: Icons.shield_outlined,
          input: const ScenarioInput(
            shrinkageReductionPct: 10,
            marginIncreasePct: 2,
            expenseReductionPct: 5,
            stockClearancePct: 20,
          ),
          onPick: onPick,
        ),
        _presetButton(
          label: 'Balanced',
          icon: Icons.balance_outlined,
          input: const ScenarioInput(
            shrinkageReductionPct: 20,
            marginIncreasePct: 4,
            expenseReductionPct: 10,
            stockClearancePct: 40,
          ),
          onPick: onPick,
        ),
        _presetButton(
          label: 'Aggressive',
          icon: Icons.rocket_launch_outlined,
          input: const ScenarioInput(
            shrinkageReductionPct: 30,
            marginIncreasePct: 6,
            expenseReductionPct: 15,
            stockClearancePct: 70,
          ),
          onPick: onPick,
        ),
      ],
    );
  }

  Widget _presetButton({
    required String label,
    required IconData icon,
    required ScenarioInput input,
    required ValueChanged<ScenarioInput> onPick,
  }) {
    return OutlinedButton.icon(
      onPressed: () => onPick(input),
      icon: Icon(icon, size: 18, color: AppColors.primary),
      label: Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }

  Widget _scenarioSlider({
    required String label,
    required double value,
    required double max,
    required ValueChanged<double> onChanged,
    required String hint,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${value.toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value.clamp(0.0, max),
          min: 0,
          max: max,
          divisions: max <= 100 ? max.toInt() : 100,
          onChanged: enabled ? (v) => onChanged(v) : null,
        ),
        Text(
          hint,
          style: TextStyle(
            fontSize: 12,
            color: enabled ? AppColors.textSecondary : AppColors.border,
          ),
        ),
      ],
    );
  }

  Widget _scenarioOutputRow({
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _scenarioAchievableChip({
    required bool achievable,
    required double gap,
  }) {
    final color = achievable ? AppColors.success : AppColors.error;
    final text = achievable
        ? 'Goal achievable'
        : 'Goal not achievable under current conditions';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            achievable ? Icons.check_circle_outline : Icons.warning_amber_outlined,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTrackingPanel({required DebtBusterAnalysis analysis}) {
    final panelNow = DateTime.now();
    final entries = _actionTrackingByOpportunityId.entries.toList()
      ..sort((a, b) => b.value.startedAt.compareTo(a.value.startedAt));

    final active = entries.where((e) => !e.value.completed).toList();
    final completed = entries.where((e) => e.value.completed).toList();

    Widget rowForTracking(ActionTracking t) {
      const minEvaluationDays = 3;
      final daysSince = panelNow.difference(t.startedAt).inDays;

      final opp = _findOpportunityById(analysis, t.opportunityId);
      final label = opp?.productName ?? t.productId;

      final statusBadge = _trackingStatusBadge(t: t, daysSince: daysSince);

      final measuredText = () {
        if (daysSince < minEvaluationDays) {
          return 'Tracking in progress — not enough data yet';
        }
        if (t.measuredImpact == null) {
          return 'Insufficient data to measure impact';
        }
        final measuredMonthly = t.measuredImpact!;
        final actualMeasured = (measuredMonthly * (daysSince / 30.0));
        return 'Measured impact: R ${measuredMonthly.toStringAsFixed(0)} / Expected R ${t.expectedImpact.toStringAsFixed(0)}\nActual over time: R ${actualMeasured.toStringAsFixed(0)}';
      }();

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  measuredText,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                statusBadge,
              ],
            ),
          ],
        ),
      );
    }

    return Card(
      color: AppColors.surfaceBg,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Active: ${active.length} | Completed: ${completed.length}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                if (_isActionTrackingLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (active.isEmpty && completed.isEmpty) ...[
              const Text(
                'No actions started yet.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ] else ...[
              if (active.isNotEmpty) ...[
                const Text(
                  'Active actions',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                ...active.take(3).map((e) => rowForTracking(e.value)),
                if (active.length > 3)
                  Text(
                    '+${active.length - 3} more',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
              ],
              if (completed.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Completed actions',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                ...completed.take(2).map((e) => rowForTracking(e.value)),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _trackingStatusBadge({
    required ActionTracking t,
    required int daysSince,
  }) {
    const minEvaluationDays = 3;

    if (daysSince < minEvaluationDays) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.08),
          border: Border.all(color: AppColors.warning.withOpacity(0.25)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'In Progress',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      );
    }

    final expected = t.expectedImpact;
    final measured = t.measuredImpact;

    if (measured == null || expected <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.border.withOpacity(0.08),
          border: Border.all(color: AppColors.border.withOpacity(0.35)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Insufficient data to measure impact',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      );
    }

    final ratio = measured / expected;
    final badge = ratio >= 0.8
        ? 'Achieved'
        : (ratio >= 0.5 ? 'Partial' : 'Low impact');

    final color = ratio >= 0.8 ? AppColors.success : (ratio >= 0.5 ? AppColors.warning : AppColors.error);

    final icon = ratio >= 0.8
        ? Icons.check_circle_outline
        : (ratio >= 0.5 ? Icons.info_outline : Icons.warning_amber_outlined);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            badge,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Opportunity? _findOpportunityById(
    DebtBusterAnalysis analysis,
    String opportunityId,
  ) {
    for (final opp in analysis.opportunities) {
      if (opp.id == opportunityId) return opp;
    }
    return null;
  }

  String? _topOpportunityId(DebtBusterAnalysis analysis) {
    final selected = analysis.gapMatch.selectedOpportunities;
    if (selected.isEmpty) return null;

    final sorted = List<Opportunity>.from(selected)
      ..sort((a, b) {
        final byImpact = b.monthlyImpact.compareTo(a.monthlyImpact);
        if (byImpact != 0) return byImpact;
        final aKey = (a.inventoryItemId ?? a.productName).toString();
        final bKey = (b.inventoryItemId ?? b.productName).toString();
        return aKey.compareTo(bKey);
      });

    return sorted.first.id;
  }

  Widget _impactRow({
    required String label,
    required double value,
    required Color color,
  }) {
    final sign = value >= 0 ? '+' : '-';
    final abs = value.abs();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            '${sign}R ${abs.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowDetails(List<Map<String, dynamic>> cashFlow) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text(
                  'Cash Flow History',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: cashFlow.map((month) {
                  final net = (month['net'] as num?)?.toDouble() ?? 0;
                  final label = month['label']?.toString() ?? '';
                  final maxNet = cashFlow.fold<double>(
                    1,
                    (max, m) => ((m['net'] as num?)?.toDouble().abs() ?? 0) > max
                        ? (m['net'] as num?)!.toDouble().abs()
                        : max,
                  );
                  final heightRatio = maxNet > 0 ? (net.abs() / maxNet) : 0.0;
                  final barHeight = (60 * heightRatio).clamp(4.0, 60.0);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'R${(net / 1000).toStringAsFixed(1)}k',
                            style: TextStyle(
                              fontSize: 9,
                              color: net >= 0 ? AppColors.success : AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: net >= 0
                                  ? AppColors.success.withOpacity(0.7)
                                  : AppColors.error.withOpacity(0.7),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDebtState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration,
                size: 64,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Debt Free!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You have no outstanding supplier invoices or staff credits.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadAnalysis,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
