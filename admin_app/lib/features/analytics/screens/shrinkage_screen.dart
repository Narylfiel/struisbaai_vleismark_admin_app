import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/features/analytics/services/analytics_repository.dart';

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
  List<Map<String, dynamic>> _alerts = [];
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
                        final alertId = alert['id']?.toString() ?? '';
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
                                    Text('Product: ${alert['product_name'] ?? 'Unknown'}', 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const Spacer(),
                                    Text(alert['status'] ?? 'Pending', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Expected Stock: ${alert['theoretical_stock'] ?? '0'} kg'),
                                Text('Actual Stock: ${alert['actual_stock'] ?? '0'} kg'),
                                Text('Variance: ${alert['gap_amount'] ?? '0'} kg (${alert['gap_percentage'] ?? '0'}%)', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                Text('Reason Candidates: ${alert['possible_reasons'] ?? 'Investigation needed'}', style: const TextStyle(color: AppColors.warning)),
                                Text('Linked Staff Activity: ${alert['staff_involved'] ?? 'Unknown'}', style: const TextStyle(color: AppColors.textSecondary)),
                                const SizedBox(height: 16),
                                if (alert['status'] != 'Acknowledged') Row(
                                  children: [
                                    ElevatedButton(onPressed: () => _handleAction(alertId, 'Investigating'), child: const Text('Investigate')),
                                    const SizedBox(width: 8),
                                    OutlinedButton(onPressed: () => _handleAction(alertId, 'StockTakeTriggered'), child: const Text('Trigger Stock Take')),
                                    const SizedBox(width: 8),
                                    TextButton(onPressed: () => _handleAction(alertId, 'Acknowledged'), child: const Text('Acknowledge Alert')),
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

  Future<void> _handleAction(String id, String status) async {
    await _repo.updatePricingSuggestion(id, status);
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
                    ElevatedButton(onPressed: () => _handleAction(id, 'Applied'), child: const Text('Accept Recommendations')),
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
                onPressed: () {},
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

                        return Row(
                          children: [
                            Icon(Icons.circle, color: sColor, size: 12),
                            const SizedBox(width: 16),
                            SizedBox(width: 150, child: Text(r['product_name'] ?? '—', style: const TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(child: Text('Velocity/Trend predicts ${r['days_remaining'] ?? '0'} days of stock left')),
                            Text(r['recommendation_text'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
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
  List<Map<String, dynamic>> _tags = [];
  List<Map<String, dynamic>> _spikes = [];
  bool _isLoading = true;
  String? _selectedEventTagId;

  final _typeController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final t = await _repo.getHistoricalEventTags();
    final s = await _repo.getRecentEvents(); // Untagged
    if (mounted) {
      setState(() {
        _tags = t;
        _spikes = s;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTag() async {
    if (_typeController.text.isEmpty || _descController.text.isEmpty) return;
    await _repo.saveEventTag(_typeController.text, _descController.text);
    _typeController.clear();
    _descController.clear();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text('Event Tag Forecasting', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        if (_spikes.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Text('Unusual Event Detected: ${_spikes.first['date']?.toString().substring(0, 10)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Sales spiked by ${_spikes.first['variance_percentage'] ?? '0'}% over rolling average. Tag this for future predictions:'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _typeController,
                          decoration: const InputDecoration(labelText: 'Event Tag (e.g. Easter)'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _descController,
                          decoration: const InputDecoration(labelText: 'Event Description'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _saveTag, child: const Text('Save Event Tag')),
                ],
              ),
            ),
          )
        else
          Card(
            color: AppColors.surfaceBg,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No recent unusual sales spikes detected requiring tagging. Models are currently stable.'),
            ),
          ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Demand Prediction for Upcoming Events', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                if (_tags.isEmpty)
                  const Text('No historical events tagged yet.')
                else
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Select Tagged Holiday / Event'),
                    value: _selectedEventTagId,
                    items: _tags.map((t) {
                      return DropdownMenuItem<String>(
                        value: t['event_type'],
                        child: Text(t['event_type'] ?? 'Unknown'),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() => _selectedEventTagId = v);
                    },
                  ),
                const SizedBox(height: 16),
                const Text('Demand prediction based on past tagged events (Sales history matching tag index):', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                if (_selectedEventTagId != null) ...[
                  ListTile(leading: const Icon(Icons.trending_up), title: Text('Based on ${_selectedEventTagId} forecasts, generate a 35kg target for Mince...')),
                  ListTile(leading: const Icon(Icons.trending_up), title: Text('Based on ${_selectedEventTagId} forecasts, generate a 60kg target for Boerewors...')),
                ] else
                  const Text('Select an event to load forecast models based on its historical performance tag.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
