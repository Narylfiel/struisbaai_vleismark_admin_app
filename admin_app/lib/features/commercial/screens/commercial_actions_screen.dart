import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/connectivity_service.dart';
import 'package:admin_app/features/commercial/repositories/commercial_repository.dart';
import 'package:admin_app/features/commercial/services/commercial_badge_notifier.dart';
import 'package:admin_app/features/commercial/utils/commercial_sort.dart';

/// Decision-support: pending commercial_actions only (no pricing engine duplication).
class CommercialActionsScreen extends StatefulWidget {
  const CommercialActionsScreen({super.key});

  @override
  State<CommercialActionsScreen> createState() =>
      _CommercialActionsScreenState();
}

enum _ValidationFilter { all, flagged, ok }

enum _PriorityFilter { all, high, low }

class _CommercialActionsScreenState extends State<CommercialActionsScreen> {
  final _repo = CommercialRepository();
  List<Map<String, dynamic>> _actions = [];
  bool _loading = true;
  bool _offline = false;
  String? _error;
  _ValidationFilter _validationFilter = _ValidationFilter.all;
  _PriorityFilter _priorityFilter = _PriorityFilter.all;
  final Set<String> _busyIds = {};
  bool _rpcInFlight = false;

  /// Normalized [0..1]; raw values >1 treated as 0–100 scale.
  static const double _kPriorityHighMin = 0.7;
  static const double _kPriorityLowMax = 0.3;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!ConnectivityService().isConnected) {
      if (mounted) {
        setState(() {
          _loading = false;
          _offline = true;
          _error = null;
          _actions = [];
        });
      }
      return;
    }
    setState(() {
      _loading = true;
      _offline = false;
      _error = null;
    });
    try {
      final rows = await _repo.getPendingActions();
      if (!mounted) return;
      final sorted = List<Map<String, dynamic>>.from(rows);
      CommercialSort.sortByPriority(sorted);
      setState(() {
        _actions = sorted;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[COMMERCIAL_ACTIONS] load failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load commercial actions';
        _actions = [];
      });
    }
  }

  List<Map<String, dynamic>> get _visible {
    var list = List<Map<String, dynamic>>.from(_actions);
    if (_validationFilter == _ValidationFilter.flagged) {
      list = list
          .where((a) =>
              _CommercialDisplay.validationLabel(a).toUpperCase() == 'FLAGGED')
          .toList();
    } else if (_validationFilter == _ValidationFilter.ok) {
      list = list
          .where(
              (a) => _CommercialDisplay.validationLabel(a).toUpperCase() == 'OK')
          .toList();
    }
    if (_priorityFilter == _PriorityFilter.high) {
      list = list
          .where((a) => _normalizedPriorityScore(a) >= _kPriorityHighMin)
          .toList();
    } else if (_priorityFilter == _PriorityFilter.low) {
      list = list
          .where((a) => _normalizedPriorityScore(a) <= _kPriorityLowMax)
          .toList();
    }
    return list;
  }

  static double _priorityScore(Map<String, dynamic> m) {
    final v = m['portfolio_priority_score'];
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  /// Normalizes to [0..1]: [0,1] as fraction; (1,100] as percent; extremes clamped.
  static double _normalizedPriorityScore(Map<String, dynamic> m) {
    var raw = _priorityScore(m);
    if (raw.isNaN || raw.isInfinite) return 0;
    if (raw < 0) return 0;
    if (raw <= 1.0) return raw.clamp(0.0, 1.0);
    if (raw <= 100.0) return (raw / 100.0).clamp(0.0, 1.0);
    return 1.0;
  }

  void _reinsertByPriority(Map<String, dynamic> row) {
    _actions.add(row);
    CommercialSort.sortByPriority(_actions);
  }

  void _resetFilters() {
    if (_rpcInFlight) return;
    setState(() {
      _validationFilter = _ValidationFilter.all;
      _priorityFilter = _PriorityFilter.all;
    });
  }

  static String _actionId(Map<String, dynamic> m) {
    return m['id']?.toString() ?? '';
  }

  Future<void> _approve(Map<String, dynamic> row) async {
    final id = _actionId(row);
    if (id.isEmpty || _busyIds.contains(id) || _rpcInFlight) return;
    final backup = Map<String, dynamic>.from(row);
    setState(() {
      _rpcInFlight = true;
      _busyIds.add(id);
      _actions.removeWhere((e) => _actionId(e) == id);
    });
    try {
      await _repo.approveCommercialAction(id);
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(content: Text('Action applied')),
        );
      }
      CommercialBadgeNotifier.instance.notifyPendingActionsChanged();
    } catch (e) {
      debugPrint('[COMMERCIAL_ACTIONS] approve failed: $e');
      if (mounted) {
        setState(() {
          _reinsertByPriority(backup);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approve failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _rpcInFlight = false;
          _busyIds.remove(id);
        });
      }
    }
  }

  Future<void> _reject(Map<String, dynamic> row) async {
    final id = _actionId(row);
    if (id.isEmpty || _busyIds.contains(id) || _rpcInFlight) return;
    final backup = Map<String, dynamic>.from(row);
    setState(() {
      _rpcInFlight = true;
      _busyIds.add(id);
      _actions.removeWhere((e) => _actionId(e) == id);
    });
    try {
      await _repo.rejectCommercialAction(id);
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(content: Text('Action applied')),
        );
      }
      CommercialBadgeNotifier.instance.notifyPendingActionsChanged();
    } catch (e) {
      debugPrint('[COMMERCIAL_ACTIONS] reject failed: $e');
      if (mounted) {
        setState(() {
          _reinsertByPriority(backup);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reject failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _rpcInFlight = false;
          _busyIds.remove(id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        title: const Text('Commercial actions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: (_loading || _rpcInFlight) ? null : _load,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _FilterBar(
                validation: _validationFilter,
                priority: _priorityFilter,
                filtersLocked: _rpcInFlight,
                onValidationChanged: (v) =>
                    setState(() => _validationFilter = v),
                onPriorityChanged: (p) => setState(() => _priorityFilter = p),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _offline
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Offline — showing cached data',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      : _error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary),
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: _visible.isEmpty
                                  ? ListView(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      children: [
                                        const SizedBox(height: 48),
                                        Center(
                                          child: Text(
                                            _actions.isEmpty
                                                ? 'No actions require review'
                                                : 'No actions match filters',
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        if (_actions.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 12),
                                            child: Center(
                                              child: TextButton(
                                                onPressed: _rpcInFlight
                                                    ? null
                                                    : _resetFilters,
                                                child: const Text('Reset filters'),
                                              ),
                                            ),
                                          ),
                                      ],
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 0, 16, 24),
                                      itemCount: _visible.length,
                                      itemBuilder: (context, index) {
                                        final row = _visible[index];
                                        final aid = _actionId(row);
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
                                          child: _ActionCard(
                                            row: row,
                                            actionsDisabled:
                                                _rpcInFlight ||
                                                    _busyIds.contains(aid),
                                            onApprove: () => _approve(row),
                                            onReject: () => _reject(row),
                                          ),
                                        );
                                      },
                                    ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.validation,
    required this.priority,
    required this.filtersLocked,
    required this.onValidationChanged,
    required this.onPriorityChanged,
  });

  final _ValidationFilter validation;
  final _PriorityFilter priority;
  final bool filtersLocked;
  final ValueChanged<_ValidationFilter> onValidationChanged;
  final ValueChanged<_PriorityFilter> onPriorityChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Chip(
              label: Text(
                'Status: pending_review',
                overflow: TextOverflow.ellipsis,
              ),
              backgroundColor: AppColors.surfaceBg,
              side: BorderSide(color: AppColors.border),
            ),
            DropdownButton<_ValidationFilter>(
              value: validation,
              onChanged: filtersLocked
                  ? null
                  : (v) {
                      if (v != null) onValidationChanged(v);
                    },
              items: const [
                DropdownMenuItem(
                  value: _ValidationFilter.all,
                  child: Text('Validation: All'),
                ),
                DropdownMenuItem(
                  value: _ValidationFilter.flagged,
                  child: Text('Validation: FLAGGED'),
                ),
                DropdownMenuItem(
                  value: _ValidationFilter.ok,
                  child: Text('Validation: OK'),
                ),
              ],
            ),
            DropdownButton<_PriorityFilter>(
              value: priority,
              onChanged: filtersLocked
                  ? null
                  : (v) {
                      if (v != null) onPriorityChanged(v);
                    },
              items: const [
                DropdownMenuItem(
                  value: _PriorityFilter.all,
                  child: Text('Priority: All'),
                ),
                DropdownMenuItem(
                  value: _PriorityFilter.high,
                  child: Text('Priority: High (score ≥ 0.7)'),
                ),
                DropdownMenuItem(
                  value: _PriorityFilter.low,
                  child: Text('Priority: Low (score ≤ 0.3)'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.row,
    required this.actionsDisabled,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> row;
  final bool actionsDisabled;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final name = _CommercialDisplay.productDisplayName(row);
    final valLabel = _CommercialDisplay.validationLabel(row);
    final isFlagged = valLabel.toUpperCase() == 'FLAGGED';
    final devPct = _CommercialDisplay.deviationPct(row);

    return Card(
      elevation: 1,
      color: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            const Text(
              'REAL (30d)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            _line(
              'Profit',
              _CommercialDisplay.money(_CommercialDisplay.realProfit30(row)),
            ),
            _line(
              'Revenue',
              _CommercialDisplay.money(_CommercialDisplay.realRevenue30(row)),
            ),
            _line(
              'Units',
              _CommercialDisplay.units(_CommercialDisplay.realUnits30(row)),
            ),
            const SizedBox(height: 12),
            const Text(
              'PREDICTED',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            _line(
              'Profit',
              _CommercialDisplay.money(_CommercialDisplay.predictedProfit(row)),
            ),
            _line(
              'Demand',
              _CommercialDisplay.demandDelta(_CommercialDisplay.demandPct(row)),
            ),
            const SizedBox(height: 12),
            const Text(
              'VALIDATION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (isFlagged)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                Expanded(
                  child: Text(
                    'Status: $valLabel',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isFlagged ? AppColors.error : AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Deviation: ${devPct != null ? '${devPct.toStringAsFixed(1)}%' : '—'}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            const Text(
              'ACTIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: actionsDisabled ? null : onApprove,
                  child: const Text('APPROVE'),
                ),
                OutlinedButton(
                  onPressed: actionsDisabled ? null : onReject,
                  child: const Text('REJECT'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Display-only field resolution (maps DB column names without recomputing economics).
class _CommercialDisplay {
  static final Set<String> _debugLogOnce = {};

  static void _logOnce(String key, String message) {
    if (!kDebugMode) return;
    if (_debugLogOnce.contains(key)) return;
    _debugLogOnce.add(key);
    debugPrint(message);
  }

  static String productDisplayName(Map<String, dynamic> m) {
    final direct = m['product_name'] as String? ?? m['item_name'] as String?;
    if (direct != null && direct.isNotEmpty) return direct;
    final inv = m['inventory_items'];
    if (inv is Map && inv['name'] != null) {
      return inv['name'].toString();
    }
    _logOnce(
      'product_title',
      '[COMMERCIAL_DISPLAY] missing product_name / item_name / inventory_items.name',
    );
    return 'Product';
  }

  static String validationLabel(Map<String, dynamic> m) {
    final v = m['validation_status'] ?? m['accounting_validation_status'];
    if (v == null) {
      _logOnce(
        'validation_label',
        '[COMMERCIAL_DISPLAY] missing validation_status / accounting_validation_status',
      );
      return '—';
    }
    return v.toString();
  }

  static double? deviationPct(Map<String, dynamic> m) {
    return _num(m, const [
      'validation_deviation_pct',
      'deviation_pct',
      'accounting_deviation_pct',
    ], 'deviationPct')?.toDouble();
  }

  static double? realProfit30(Map<String, dynamic> m) {
    return _num(m, const [
      'real_profit_30d',
      'real_net_profit_30d',
      'profit_real_30d',
      'actual_profit_30d',
    ], 'realProfit30')?.toDouble();
  }

  static double? realRevenue30(Map<String, dynamic> m) {
    return _num(m, const [
      'real_revenue_30d',
      'revenue_30d_real',
      'actual_revenue_30d',
    ], 'realRevenue30')?.toDouble();
  }

  static double? realUnits30(Map<String, dynamic> m) {
    return _num(m, const [
      'real_units_30d',
      'units_sold_30d',
      'actual_units_30d',
    ], 'realUnits30')?.toDouble();
  }

  static double? predictedProfit(Map<String, dynamic> m) {
    return _num(m, const [
      'predicted_profit',
      'predicted_net_profit',
      'model_predicted_profit',
    ], 'predictedProfit')?.toDouble();
  }

  static double? demandPct(Map<String, dynamic> m) {
    return _num(m, const [
      'predicted_demand_delta_pct',
      'demand_delta_pct',
      'elasticity_demand_pct',
    ], 'demandPct')?.toDouble();
  }

  static num? _num(
    Map<String, dynamic> m,
    List<String> keys,
    String group,
  ) {
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      if (v is num) return v;
      final p = num.tryParse(v.toString());
      if (p != null) return p;
    }
    _logOnce(
      'num_$group',
      '[COMMERCIAL_DISPLAY] missing keys for group="$group" tried=$keys',
    );
    return null;
  }

  static String money(double? v) {
    if (v == null) return '—';
    return 'R ${v.toStringAsFixed(2)}';
  }

  static String units(double? v) {
    if (v == null) return '—';
    if (v == v.roundToDouble()) return '${v.toInt()}';
    return v.toStringAsFixed(1);
  }

  static String demandDelta(double? v) {
    if (v == null) return '—';
    final sign = v >= 0 ? '+' : '';
    return '$sign${v.toStringAsFixed(1)}%';
  }
}
