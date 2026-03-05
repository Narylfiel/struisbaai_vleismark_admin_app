import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/models/shrinkage_alert.dart';
import 'package:admin_app/features/analytics/services/analytics_repository.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

class ShrinkageScreen extends StatefulWidget {
  const ShrinkageScreen({super.key});

  @override
  State<ShrinkageScreen> createState() => _ShrinkageScreenState();
}

class _ShrinkageScreenState extends State<ShrinkageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          Container(
            color: AppColors.cardBg,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(icon: Icon(Icons.warning_amber, size: 18), text: 'Shrinkage Alerts'),
                Tab(icon: Icon(Icons.price_change, size: 18), text: 'Dynamic Pricing'),
                Tab(icon: Icon(Icons.shopping_cart, size: 18), text: 'Predictive Reorder'),
                Tab(icon: Icon(Icons.event_note, size: 18), text: 'Event Forecasting'),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ShrinkageTab(),
                _PricingTab(),
                _ReorderTab(),
                _EventTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 1: SHRINKAGE ALERTS
// ══════════════════════════════════════════════════════════════════
class _ShrinkageTab extends StatefulWidget {
  @override
  State<_ShrinkageTab> createState() => _ShrinkageTabState();
}

class _ShrinkageTabState extends State<_ShrinkageTab> {
  final _repo = AnalyticsRepository();
  List<ShrinkageAlert> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _repo.getShrinkageAlerts();
    if (mounted) {
      setState(() {
        _alerts = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAction(String alertId, String action) async {
    await _repo.updateShrinkageStatus(alertId, action);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.cardBg,
          child: Row(
            children: [
              const Text('Shrinkage Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () async {
                  await _repo.triggerMassBalance();
                  _load();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh Mass-Balance'),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _alerts.isEmpty
                  ? const Center(child: Text('No shrinkage alerts automatically logged today.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _alerts.length,
                      itemBuilder: (_, i) {
                        final alert = _alerts[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.circle, color: AppColors.error, size: 12),
                                    const SizedBox(width: 8),
                                    Text('Product: ${alert.productName ?? 'Unknown'}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const Spacer(),
                                    Text(alert.status, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Expected Stock: ${alert.theoreticalStock ?? 0} kg'),
                                Text('Actual Stock: ${alert.actualStock ?? 0} kg'),
                                Text('Variance: ${alert.gapAmount ?? 0} kg (${alert.gapPercentage ?? 0}%)', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                Text('Reason Candidates: ${alert.possibleReasons ?? 'Investigation needed'}', style: const TextStyle(color: AppColors.warning)),
                                Text('Linked Staff Activity: ${alert.staffInvolved ?? 'Unknown'}', style: const TextStyle(color: AppColors.textSecondary)),
                                const SizedBox(height: 16),
                                if (alert.status != 'Acknowledged') Row(
                                  children: [
                                    ElevatedButton(onPressed: () => _handleAction(alert.id, 'Investigating'), child: const Text('Investigate')),
                                    const SizedBox(width: 8),
                                    OutlinedButton(onPressed: () => _handleAction(alert.id, 'StockTakeTriggered'), child: const Text('Trigger Stock Take')),
                                    const SizedBox(width: 8),
                                    TextButton(onPressed: () => _handleAction(alert.id, 'Acknowledged'), child: const Text('Acknowledge Alert')),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 2: DYNAMIC PRICING SUGGESTIONS
// ══════════════════════════════════════════════════════════════════
class _PricingTab extends StatefulWidget {
  @override
  State<_PricingTab> createState() => _PricingTabState();
}

class _PricingTabState extends State<_PricingTab> {
  final _repo = AnalyticsRepository();
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _repo.getPricingSuggestions();
    if (mounted) {
      setState(() {
        _suggestions = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAction(
      String id, String status, {double? suggestedPrice}) async {
    await _repo.updatePricingSuggestion(
      id,
      status,
      newSellPrice: status == 'Applied' ? suggestedPrice : null,
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_suggestions.isEmpty) {
      return const Center(child: Text('No supplier price hikes detected needing markdown corrections.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _suggestions.length,
      itemBuilder: (_, i) {
        final sug = _suggestions[i];
        final id = sug['id']?.toString() ?? '';
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.trending_up, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text('Supplier: ${sug['supplier_name'] ?? 'Unknown'} - ${sug['product_name'] ?? 'Unknown'} (+${sug['percentage_increase'] ?? '0'}%)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const Divider(height: 32),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text('Current Price', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text('Suggested Price', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text('Margin Impact', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(sug['product_name'] ?? 'Unknown')),
                    Expanded(child: Text('R ${sug['current_sell_price'] ?? '0.00'}/kg')),
                    Expanded(child: Text('R ${sug['suggested_sell_price'] ?? '0.00'}/kg', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success))),
                    Expanded(child: Text(sug['margin_impact'] ?? 'Check Margin', style: const TextStyle(color: AppColors.error))),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        final newPrice = double.tryParse(
                            sug['suggested_sell_price']?.toString() ?? '');
                        _handleAction(id, 'Applied', suggestedPrice: newPrice);
                      },
                      child: const Text('Accept & Update Price'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(onPressed: () => _handleAction(id, 'Ignored'), child: const Text('Ignore')),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 3: PREDICTIVE REORDER INSIGHTS
// ══════════════════════════════════════════════════════════════════
class _ReorderTab extends StatefulWidget {
  @override
  State<_ReorderTab> createState() => _ReorderTabState();
}

class _ReorderTabState extends State<_ReorderTab> {
  final _repo = AnalyticsRepository();
  List<Map<String, dynamic>> _recs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _repo.getReorderRecommendations();
    if (mounted) {
      setState(() {
        _recs = data;
        _isLoading = false;
      });
    }
  }

  void _openCreatePODialog() {
    showDialog(
      context: context,
      builder: (_) => _CreatePODialog(onSaved: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.cardBg,
          child: Row(
            children: [
              const Text('Predictive Reorder Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _recs.isEmpty
                    ? null
                    : () => _openCreatePODialog(),
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: const Text('Create Purchase Order'),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surfaceBg,
          child: const Text('Recommendations based on real transaction velocity, seasonality tables, and historical event correlations.', style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _recs.isEmpty
                  ? const Center(child: Text('Stock levels OK based on transaction velocities. No reorders needed.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: _recs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (_, i) {
                        final r = _recs[i];
                        final status = r['status'] ?? 'OK';
                        Color sColor = AppColors.success;
                        if (status == 'URGENT') sColor = AppColors.error;
                        if (status == 'WARNING') sColor = AppColors.warning;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Icon(Icons.circle, color: sColor, size: 12),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r['product_name'] ?? '—',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                    const SizedBox(height: 2),
                                    Text(
                                      r['context_message'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'On hand: ${r['current_stock'] ?? '—'} kg',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    'Reorder at: ${r['reorder_point'] ?? '—'} kg',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: sColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  r['recommendation_text'] ?? '—',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: sColor),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 4: EVENT TAG FORECASTING
// ══════════════════════════════════════════════════════════════════
class _EventTab extends StatefulWidget {
  @override
  State<_EventTab> createState() => _EventTabState();
}

class _EventTabState extends State<_EventTab> {
  final _repo = AnalyticsRepository();

  List<Map<String, dynamic>> _spikes = [];
  List<Map<String, dynamic>> _tags = [];
  List<Map<String, dynamic>> _reminders = [];

  bool _isLoading = true;
  String? _selectedEventForYoY;
  List<Map<String, dynamic>> _yoyData = [];
  bool _yoyLoading = false;

  // Tag form state per spike
  final Map<String, TextEditingController> _nameControllers = {};
  final Map<String, String> _selectedTypes = {};

  static const List<String> _eventTypes = [
    'fishing_competition',
    'agri_show',
    'public_holiday',
    'school_holiday',
    'sporting_event',
    'local_event',
    'other',
  ];

  static String _eventTypeLabel(String t) =>
      t.replaceAll('_', ' ').split(' ').map((w) =>
          w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _nameControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final spikes = await _repo.getRecentEvents();
    final tags = await _repo.getHistoricalEventTags();
    final reminders = await _repo.getUpcomingEventReminders();
    if (mounted) {
      setState(() {
        _spikes = spikes;
        _tags = tags;
        _reminders = reminders;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTag(Map<String, dynamic> spike) async {
    final weekStart = spike['week_start'] as String;
    final controller = _nameControllers[weekStart];
    if (controller == null || controller.text.trim().isEmpty) return;

    final eventType = _selectedTypes[weekStart] ?? _eventTypes.first;
    await _repo.saveEventTag(
      eventType,
      controller.text.trim(),
      startDate: weekStart,
      endDate: spike['week_end'] as String,
      revenue: (spike['revenue'] as num?)?.toDouble() ?? 0,
      baselineRevenue: (spike['baseline_revenue'] as num?)?.toDouble() ?? 0,
      revenueVariancePct:
          double.tryParse(spike['revenue_variance_pct']?.toString() ?? '') ?? 0,
      transactionCount: (spike['transaction_count'] as num?)?.toInt() ?? 0,
      autoDetected: true,
    );

    controller.clear();
    _load();
  }

  Future<void> _dismissSpike(String weekStart) async {
    await _repo.dismissSpike(weekStart);
    _load();
  }

  Future<void> _loadYoY(String eventName) async {
    setState(() => _yoyLoading = true);
    final data = await _repo.getEventYearOnYear(eventName);
    if (mounted) {
      setState(() {
        _yoyData = data;
        _yoyLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── SECTION 1: DETECTED SPIKES ──────────────────────────────
        _sectionHeader(Icons.bar_chart, 'Detected Sales Spikes',
            subtitle: 'Weeks significantly above your normal trading average'),
        const SizedBox(height: 8),
        if (_spikes.isEmpty)
          _emptyCard('No unusual sales spikes detected in the last 10 weeks. '
              'Models are stable.')
        else
          ..._spikes.map((spike) {
            final weekStart = spike['week_start'] as String;
            _nameControllers.putIfAbsent(
                weekStart, () => TextEditingController());
            _selectedTypes.putIfAbsent(weekStart, () => _eventTypes.first);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.trending_up, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            spike['display_date'] ?? weekStart,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _dismissSpike(weekStart),
                          child: const Text('Dismiss',
                              style:
                                  TextStyle(color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _metricChip(
                          'Revenue',
                          'R ${((spike['revenue'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}',
                          '+${spike['revenue_variance_pct']}% vs avg',
                          AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        _metricChip(
                          'Transactions',
                          '${spike['transaction_count'] ?? 0}',
                          '+${spike['tx_variance_pct']}% vs avg',
                          Colors.blue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('What caused this spike?',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedTypes[weekStart],
                            isExpanded: true,
                            decoration: const InputDecoration(
                                isDense: true,
                                labelText: 'Event type'),
                            items: _eventTypes
                                .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(_eventTypeLabel(t))))
                                .toList(),
                            onChanged: (v) => setState(
                                () => _selectedTypes[weekStart] = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _nameControllers[weekStart],
                            decoration: const InputDecoration(
                              isDense: true,
                              labelText: 'Event name',
                              hintText: 'e.g. Fishing Competition 2026',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () => _saveTag(spike),
                          child: const Text('Tag'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: 24),

        // ── SECTION 2: UPCOMING REMINDERS ────────────────────────────
        _sectionHeader(Icons.notifications_active, 'Upcoming Event Reminders',
            subtitle: 'Events from previous years with anniversaries coming up'),
        const SizedBox(height: 8),
        if (_reminders.isEmpty)
          _emptyCard('No upcoming event anniversaries in the next 45 days.')
        else
          ..._reminders.map((r) {
            final daysUntil = r['days_until'] as int? ?? 0;
            final revenue =
                (r['total_revenue'] as num?)?.toDouble() ?? 0;
            final variance =
                (r['revenue_variance_pct'] as num?)?.toDouble() ?? 0;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: daysUntil <= 14
                      ? AppColors.error.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    '$daysUntil',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: daysUntil <= 14
                          ? AppColors.error
                          : AppColors.primary,
                    ),
                  ),
                ),
                title: Text(r['event_name']?.toString() ?? '—',
                    style:
                        const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  revenue > 0
                      ? 'Last recorded: R ${revenue.toStringAsFixed(0)} (+${variance.toStringAsFixed(1)}% above normal)'
                      : 'Anniversary in $daysUntil days — ${r['anniversary_date'] ?? ''}',
                ),
                trailing: Text(
                  '$daysUntil days',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: daysUntil <= 14
                        ? AppColors.error
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }),

        const SizedBox(height: 24),

        // ── SECTION 3: SAVED EVENTS ───────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _sectionHeader(Icons.event, 'Saved Events',
                  subtitle: 'All tagged events with year-on-year history'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Event'),
              onPressed: () => _showAddEventDialog(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_tags.isEmpty)
          _emptyCard('No events tagged yet. Tag a spike above or add manually.')
        else
          ..._tags.map((tag) {
            final name = tag['event_name']?.toString() ?? '—';
            final type = _eventTypeLabel(
                tag['event_type']?.toString() ?? 'other');
            final startDate = tag['start_date']?.toString() ??
                tag['event_date']?.toString() ?? '—';
            final revenue =
                (tag['total_revenue'] as num?)?.toDouble() ?? 0;
            final variance =
                (tag['revenue_variance_pct'] as num?)?.toDouble() ?? 0;
            final year = startDate.length >= 4
                ? startDate.substring(0, 4)
                : '—';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.event_note,
                    color: AppColors.primary),
                title: Text(name,
                    style:
                        const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('$type · $startDate'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (revenue > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          'R ${revenue.toStringAsFixed(0)}\n+${variance.toStringAsFixed(1)}%',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                      ),
                    Chip(
                      label: Text(year,
                          style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.bar_chart, size: 18),
                      tooltip: 'Year-on-year comparison',
                      onPressed: () {
                        setState(
                            () => _selectedEventForYoY = name);
                        _loadYoY(name);
                      },
                    ),
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: 24),

        // ── SECTION 4: YEAR-ON-YEAR COMPARISON ───────────────────────
        _sectionHeader(Icons.compare_arrows, 'Year-on-Year Comparison',
            subtitle: 'Compare the same event across multiple years'),
        const SizedBox(height: 8),
        if (_selectedEventForYoY == null)
          _emptyCard(
              'Tap the chart icon on any saved event to compare years.')
        else if (_yoyLoading)
          const Center(child: CircularProgressIndicator())
        else if (_yoyData.isEmpty)
          _emptyCard('No data yet for "$_selectedEventForYoY".')
        else ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _selectedEventForYoY!,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(2),
                },
                children: [
                  // Header
                  TableRow(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                    ),
                    children: const [
                      _TableCell('Year', header: true),
                      _TableCell('Revenue', header: true),
                      _TableCell('vs Normal', header: true),
                      _TableCell('Transactions', header: true),
                    ],
                  ),
                  // Data rows
                  ..._yoyData.map((inst) {
                    final year = (inst['start_date'] as String?)
                            ?.substring(0, 4) ??
                        (inst['event_date'] as String?)
                            ?.substring(0, 4) ??
                        '—';
                    final rev =
                        (inst['total_revenue'] as num?)?.toDouble() ??
                            0;
                    final variance =
                        (inst['revenue_variance_pct'] as num?)
                                ?.toDouble() ??
                            0;
                    final tx =
                        (inst['total_transactions'] as num?)?.toInt() ??
                            0;
                    return TableRow(
                      children: [
                        _TableCell(year),
                        _TableCell(
                            rev > 0 ? 'R ${rev.toStringAsFixed(0)}' : '—'),
                        _TableCell(
                          variance != 0
                              ? '+${variance.toStringAsFixed(1)}%'
                              : '—',
                          color: variance > 0
                              ? Colors.green
                              : AppColors.textSecondary,
                        ),
                        _TableCell(tx > 0 ? '$tx' : '—'),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────

  Widget _sectionHeader(IconData icon, String title,
      {String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              if (subtitle != null)
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyCard(String message) {
    return Card(
      color: AppColors.surfaceBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message,
            style: const TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }

  Widget _metricChip(
      String label, String value, String sub, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color)),
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(sub,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEventDialog() async {
    final nameController = TextEditingController();
    String selectedType = _eventTypes.first;
    DateTime startDate = DateTime.now().subtract(
        Duration(days: DateTime.now().weekday - 1));
    DateTime endDate = startDate.add(const Duration(days: 6));

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Add Event Manually'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  isExpanded: true,
                  decoration:
                      const InputDecoration(labelText: 'Event Type'),
                  items: _eventTypes
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(_eventTypeLabel(t))))
                      .toList(),
                  onChanged: (v) => setDlg(() => selectedType = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Event Name',
                    hintText: 'e.g. Struisbaai Fishing Competition 2026',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start Date',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: startDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setDlg(() {
                                  startDate = picked;
                                  endDate = picked
                                      .add(const Duration(days: 6));
                                });
                              }
                            },
                            child: Text(
                                startDate.toIso8601String().substring(0, 10)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('End Date',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: endDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setDlg(() => endDate = picked);
                              }
                            },
                            child: Text(
                                endDate.toIso8601String().substring(0, 10)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                await _repo.saveEventTag(
                  selectedType,
                  nameController.text.trim(),
                  startDate:
                      startDate.toIso8601String().substring(0, 10),
                  endDate: endDate.toIso8601String().substring(0, 10),
                  autoDetected: false,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              },
              child: const Text('Save Event'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
  }
}

// ── TABLE CELL HELPER ─────────────────────────────────────────────
class _TableCell extends StatelessWidget {
  final String text;
  final bool header;
  final Color? color;

  const _TableCell(this.text, {this.header = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: header ? FontWeight.bold : FontWeight.normal,
          fontSize: header ? 12 : 13,
          color: color ??
              (header ? AppColors.textSecondary : AppColors.textPrimary),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// CREATE PURCHASE ORDER DIALOG (C4: supplier-first, products by supplier only)
// ══════════════════════════════════════════════════════════════════
class _CreatePODialog extends StatefulWidget {
  final VoidCallback onSaved;

  const _CreatePODialog({required this.onSaved});

  @override
  State<_CreatePODialog> createState() => _CreatePODialogState();
}

class _POLineRow {
  final String id;
  final String name;
  final String? supplierCode;
  final double currentStock;
  final double reorderLevel;
  final double unitPrice;
  final String unit;
  final TextEditingController qtyController;

  _POLineRow({
    required this.id,
    required this.name,
    this.supplierCode,
    required this.currentStock,
    required this.reorderLevel,
    required this.unitPrice,
    this.unit = 'kg',
    required this.qtyController,
  });
}

class _CreatePODialogState extends State<_CreatePODialog> {
  final _client = SupabaseService.client;
  List<Map<String, dynamic>> _suppliers = [];
  String? _selectedSupplierId;
  List<_POLineRow> _productRows = [];
  bool _loadingSuppliers = true;
  bool _loadingProducts = false;
  bool _saving = false;
  String? _savedPoNumber;
  Map<String, dynamic>? _savedSupplier;
  List<Map<String, dynamic>>? _savedLines;
  double? _savedGrandTotal;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    for (final row in _productRows) {
      row.qtyController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    try {
      final data = await _client
          .from('suppliers')
          .select('id, name, phone')
          .eq('is_active', true)
          .order('name');
      if (mounted) {
        setState(() {
          _suppliers = List<Map<String, dynamic>>.from(data as List);
          _loadingSuppliers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSuppliers = false);
    }
  }

  /// C4: Load ONLY that supplier's products (inventory_items JOIN product_suppliers).
  Future<void> _loadProductsForSupplier(String supplierId) async {
    setState(() {
      for (final row in _productRows) row.qtyController.dispose();
      _productRows = [];
      _loadingProducts = true;
    });
    try {
      final psRows = await _client
          .from('product_suppliers')
          .select('inventory_item_id, supplier_product_code, unit_price')
          .eq('supplier_id', supplierId);
      final itemIds = (psRows as List)
          .map((r) => (r as Map)['inventory_item_id']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
      if (itemIds.isEmpty) {
        if (mounted) setState(() => _loadingProducts = false);
        return;
      }
      final iiRows = await _client
          .from('inventory_items')
          .select('id, name, plu_code, unit_type, current_stock, reorder_level')
          .inFilter('id', itemIds)
          .eq('is_active', true)
          .order('name');
      final psByItem = <String, Map<String, dynamic>>{};
      for (final r in psRows as List) {
        final id = (r as Map)['inventory_item_id']?.toString();
        if (id != null) psByItem[id] = Map<String, dynamic>.from(r as Map);
      }
      final rows = <_POLineRow>[];
      for (final r in iiRows as List) {
        final map = r as Map<String, dynamic>;
        final id = map['id']?.toString();
        if (id == null) continue;
        final ps = psByItem[id];
        final currentStock = (map['current_stock'] as num?)?.toDouble() ?? 0;
        final reorderLevel = (map['reorder_level'] as num?)?.toDouble() ?? 0;
        final unitPrice = (ps?['unit_price'] as num?)?.toDouble() ?? 0;
        final unit = map['unit_type']?.toString() ?? 'kg';
        final suggested = reorderLevel > 0 && currentStock < reorderLevel
            ? ((reorderLevel - currentStock).clamp(1.0, double.infinity))
            : 0.0;
        final ctrl = TextEditingController(text: suggested > 0 ? suggested.toStringAsFixed(0) : '');
        rows.add(_POLineRow(
          id: id,
          name: map['name']?.toString() ?? '—',
          supplierCode: ps?['supplier_product_code']?.toString(),
          currentStock: currentStock,
          reorderLevel: reorderLevel,
          unitPrice: unitPrice,
          unit: unit,
          qtyController: ctrl,
        ));
      }
      if (mounted) setState(() {
        _productRows = rows;
        _loadingProducts = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  double _grandTotal() {
    double t = 0;
    for (final row in _productRows) {
      final qty = double.tryParse(row.qtyController.text.trim()) ?? 0;
      if (qty > 0) t += qty * row.unitPrice;
    }
    return t;
  }

  Future<void> _save() async {
    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a supplier first.')));
      return;
    }
    final lines = <Map<String, dynamic>>[];
    for (final row in _productRows) {
      final qty = double.tryParse(row.qtyController.text.trim()) ?? 0;
      if (qty <= 0) continue;
      final lineTotal = qty * row.unitPrice;
      lines.add({
        'inventory_item_id': row.id,
        'quantity': qty,
        'unit': row.unit,
        'unit_price': row.unitPrice,
        'line_total': lineTotal,
      });
    }
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter at least one quantity.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final prefix = 'PO-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}-';
      final existing = await _client
          .from('purchase_orders')
          .select('po_number')
          .like('po_number', '$prefix%');
      final count = (existing as List).length;
      final poNumber = '${prefix}${(count + 1).toString().padLeft(3, '0')}';

      final poRow = await _client
          .from('purchase_orders')
          .insert({
            'po_number': poNumber,
            'supplier_id': _selectedSupplierId,
            'status': 'draft',
            'order_date': DateTime.now().toIso8601String().split('T').first,
          })
          .select('id')
          .single();
      final poId = (poRow as Map<String, dynamic>)['id'] as String;

      for (final line in lines) {
        await _client.from('purchase_order_lines').insert({
          ...line,
          'purchase_order_id': poId,
        });
      }

      final supplier = _suppliers.firstWhere((s) => s['id']?.toString() == _selectedSupplierId, orElse: () => <String, dynamic>{});
      final savedLines = lines.map((l) {
        final row = _productRows.firstWhere((r) => r.id == l['inventory_item_id']);
        return {
          'name': row.name,
          'supplier_code': row.supplierCode,
          'qty': l['quantity'],
          'unit_price': row.unitPrice,
          'line_total': l['line_total'],
        };
      }).toList();
      final grandTotal = savedLines.fold<double>(0, (s, l) => s + ((l['line_total'] as num?)?.toDouble() ?? 0));

      if (mounted) {
        setState(() {
          _saving = false;
          _savedPoNumber = poNumber;
          _savedSupplier = supplier.isNotEmpty ? supplier : null;
          _savedLines = savedLines;
          _savedGrandTotal = grandTotal;
        });
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.friendlyMessage(e))));
      }
    }
  }

  Future<void> _generatePdf() async {
    if (_savedPoNumber == null || _savedSupplier == null || _savedLines == null || _savedGrandTotal == null) return;
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Purchase Order $_savedPoNumber', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
          pw.Paragraph(text: 'Supplier: ${_savedSupplier!['name'] ?? '—'}'),
          pw.Paragraph(text: 'Phone: ${_savedSupplier!['phone'] ?? '—'}'),
          pw.Paragraph(text: 'Date: ${DateTime.now().toIso8601String().substring(0, 10)}'),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Product', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Code', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Unit price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                ],
              ),
              ..._savedLines!.map((l) => pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(l['name']?.toString() ?? '—')),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(l['supplier_code']?.toString() ?? '—')),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${l['qty']}')),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('R ${(l['unit_price'] as num?)?.toStringAsFixed(2) ?? '0.00'}')),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('R ${(l['line_total'] as num?)?.toStringAsFixed(2) ?? '0.00'}')),
                ],
              )),
            ],
          ),
          pw.Paragraph(text: 'Grand total: R ${_savedGrandTotal!.toStringAsFixed(2)}'),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  Future<void> _sendWhatsApp() async {
    if (_savedSupplier == null || _savedLines == null || _savedGrandTotal == null) return;
    final phone = _savedSupplier!['phone']?.toString()?.replaceAll(RegExp(r'[^\d+]'), '') ?? '';
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No phone number for supplier.')));
      return;
    }
    final buffer = StringBuffer('Purchase Order $_savedPoNumber\n\n');
    for (final l in _savedLines!) {
      buffer.writeln('${l['name']} x ${l['qty']} = R ${(l['line_total'] as num?)?.toStringAsFixed(2)}');
    }
    buffer.writeln('\nTotal: R ${_savedGrandTotal!.toStringAsFixed(2)}');
    final text = Uri.encodeComponent(buffer.toString());
    final url = Uri.parse('https://wa.me/$phone?text=$text');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_savedPoNumber != null) {
      return AlertDialog(
        title: const Text('PO created'),
        content: Text('Purchase order $_savedPoNumber has been saved.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
          TextButton.icon(onPressed: _generatePdf, icon: const Icon(Icons.picture_as_pdf, size: 18), label: const Text('Generate PDF')),
          TextButton.icon(onPressed: _sendWhatsApp, icon: const Icon(Icons.chat, size: 18), label: const Text('Send WhatsApp')),
        ],
      );
    }
    return AlertDialog(
      title: const Text('Create Purchase Order'),
      content: SizedBox(
        width: 720,
        child: _loadingSuppliers
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Step 1: Select supplier', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedSupplierId,
                      isExpanded: true,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: _suppliers
                          .map((s) => DropdownMenuItem<String>(
                                value: s['id'] as String?,
                                child: Text(s['name']?.toString() ?? '—'),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() => _selectedSupplierId = v);
                        if (v != null) _loadProductsForSupplier(v);
                      },
                    ),
                    if (_selectedSupplierId != null) ...[
                      const SizedBox(height: 16),
                      const Text('Step 2: Products (this supplier only) — edit order qty', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (_loadingProducts)
                        const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
                      if (!_loadingProducts && _productRows.isEmpty)
                        const Padding(padding: EdgeInsets.all(16), child: Text('No products linked to this supplier. Add product-supplier links in Inventory.')),
                      if (!_loadingProducts && _productRows.isNotEmpty) ...[
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(1),
                            2: FlexColumnWidth(0.8),
                            3: FlexColumnWidth(0.8),
                            4: FlexColumnWidth(0.8),
                            5: FlexColumnWidth(0.8),
                          },
                          children: [
                            TableRow(
                              decoration: BoxDecoration(color: AppColors.border.withOpacity(0.3)),
                              children: const [
                                Padding(padding: EdgeInsets.all(6), child: Text('Name', style: TextStyle(fontWeight: FontWeight.w600))),
                                Padding(padding: EdgeInsets.all(6), child: Text('Supplier Code', style: TextStyle(fontWeight: FontWeight.w600))),
                                Padding(padding: EdgeInsets.all(6), child: Text('Stock', style: TextStyle(fontWeight: FontWeight.w600))),
                                Padding(padding: EdgeInsets.all(6), child: Text('Reorder', style: TextStyle(fontWeight: FontWeight.w600))),
                                Padding(padding: EdgeInsets.all(6), child: Text('Unit price', style: TextStyle(fontWeight: FontWeight.w600))),
                                Padding(padding: EdgeInsets.all(6), child: Text('Order Qty', style: TextStyle(fontWeight: FontWeight.w600))),
                              ],
                            ),
                            ..._productRows.map((row) {
                              final qty = double.tryParse(row.qtyController.text.trim()) ?? 0;
                              final lineTotal = qty > 0 ? qty * row.unitPrice : 0.0;
                              return TableRow(
                                children: [
                                  Padding(padding: const EdgeInsets.all(4), child: Text(row.name, overflow: TextOverflow.ellipsis)),
                                  Padding(padding: const EdgeInsets.all(4), child: Text(row.supplierCode ?? '—')),
                                  Padding(padding: const EdgeInsets.all(4), child: Text('${row.currentStock.toStringAsFixed(1)} ${row.unit}')),
                                  Padding(padding: const EdgeInsets.all(4), child: Text('${row.reorderLevel.toStringAsFixed(1)}')),
                                  Padding(padding: const EdgeInsets.all(4), child: Text('R ${row.unitPrice.toStringAsFixed(2)}')),
                                  Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: TextField(
                                      controller: row.qtyController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Grand total: R ${_grandTotal().toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ],
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save PO'),
        ),
      ],
    );
  }
}
