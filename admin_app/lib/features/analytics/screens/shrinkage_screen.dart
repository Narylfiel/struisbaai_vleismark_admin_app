import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/models/shrinkage_alert.dart';
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

  void _openCreatePODialog() {
    showDialog(
      context: context,
      builder: (_) => _CreatePODialog(recs: _recs, onSaved: _load),
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
  List<Map<String, dynamic>> _forecast = [];
  bool _isLoading = true;
  bool _forecastLoading = false;
  String? _selectedEventType;

  final _eventNameController = TextEditingController();
  static const List<String> _eventTypes = [
    'public_holiday',
    'holiday',
    'school_holiday',
    'sporting_event',
    'local_event',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final t = await _repo.getHistoricalEventTags();
    final s = await _repo.getRecentEvents();
    if (mounted) {
      setState(() {
        _tags = t;
        _spikes = s;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadForecast(String eventType) async {
    setState(() => _forecastLoading = true);
    final f = await _repo.getForecastForEvent(eventType);
    if (mounted) {
      setState(() {
        _forecast = f;
        _forecastLoading = false;
      });
    }
  }

  Future<void> _saveTag() async {
    final type = _selectedEventType ?? _eventTypes.first;
    if (_eventNameController.text.trim().isEmpty) return;
    await _repo.saveEventTag(type, _eventNameController.text.trim());
    _eventNameController.clear();
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
                      Text('Unusual sales: ${_spikes.first['date'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Sales +${_spikes.first['variance_percentage'] ?? '0'}% vs 14-day average. Tag for future forecasts:'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedEventType ?? _eventTypes.first,
                    decoration: const InputDecoration(labelText: 'Event type'),
                    items: _eventTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ')))).toList(),
                    onChanged: (v) => setState(() => _selectedEventType = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _eventNameController,
                    decoration: const InputDecoration(labelText: 'Event name (e.g. Easter Weekend)'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _saveTag, child: const Text('Save Event Tag')),
                ],
              ),
            ),
          )
        else
          const Card(
            color: AppColors.surfaceBg,
            child: Padding(
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
                const Text('Demand prediction for upcoming events', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                if (_tags.isEmpty)
                  const Text('No historical events tagged yet. Tag spikes above to build forecasts.')
                else ...[
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Select tagged event type'),
                    value: _tags.any((t) => (t['event_type'] ?? t['event_name']) == _selectedEventType)
                        ? _selectedEventType
                        : (_tags.isNotEmpty ? _tags.first['event_type']?.toString() ?? _tags.first['event_name']?.toString() : null),
                    items: _tags.map((t) {
                      final type = t['event_type']?.toString() ?? t['event_name']?.toString() ?? 'unknown';
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(t['event_name']?.toString() ?? type),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedEventType = v;
                        _forecast = [];
                      });
                      if (v != null) _loadForecast(v);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedEventType != null) ...[
                    if (_forecastLoading)
                      const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
                    else if (_forecast.isEmpty)
                      const Text('No forecast data for this event type yet.', style: TextStyle(color: AppColors.textSecondary))
                    else
                      ..._forecast.map((f) => ListTile(
                            leading: const Icon(Icons.trending_up, color: AppColors.primary),
                            title: Text(f['product_name']?.toString() ?? '—'),
                            subtitle: Text('Suggested: ${f['suggested_quantity_kg'] ?? f['suggested_quantity'] ?? '—'} kg'),
                          )),
                  ] else
                    const Text('Select an event type to load forecast from historical performance.', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// CREATE PURCHASE ORDER DIALOG (H7 / C9)
// ══════════════════════════════════════════════════════════════════
class _CreatePODialog extends StatefulWidget {
  final List<Map<String, dynamic>> recs;
  final VoidCallback onSaved;

  const _CreatePODialog({required this.recs, required this.onSaved});

  @override
  State<_CreatePODialog> createState() => _CreatePODialogState();
}

class _CreatePODialogState extends State<_CreatePODialog> {
  final _client = SupabaseService.client;
  List<Map<String, dynamic>> _suppliers = [];
  String? _selectedSupplierId;
  final Map<String, TextEditingController> _qtyControllers = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
    for (final r in widget.recs) {
      final id = r['inventory_item_id']?.toString();
      if (id != null) {
        final rec = r;
        final suggested = (rec['current_stock'] != null && rec['reorder_point'] != null)
            ? ((rec['reorder_point'] as num).toDouble() - (rec['current_stock'] as num).toDouble()).clamp(0.0, double.infinity)
            : null;
        _qtyControllers[id] = TextEditingController(text: suggested != null && suggested > 0 ? suggested.toStringAsFixed(0) : '');
      }
    }
  }

  @override
  void dispose() {
    for (final c in _qtyControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    try {
      final data = await _client
          .from('suppliers')
          .select('id, name')
          .eq('is_active', true)
          .order('name');
      if (mounted) {
        setState(() {
          _suppliers = List<Map<String, dynamic>>.from(data as List);
          _loading = false;
          if (_suppliers.isNotEmpty && _selectedSupplierId == null) {
            _selectedSupplierId = _suppliers.first['id'] as String?;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a supplier.')));
      return;
    }
    final lines = <Map<String, dynamic>>[];
    for (final r in widget.recs) {
      final id = r['inventory_item_id']?.toString();
      if (id == null) continue;
      final c = _qtyControllers[id];
      final qty = double.tryParse(c?.text.trim() ?? '') ?? 0;
      if (qty <= 0) continue;
      lines.add({
        'inventory_item_id': id,
        'quantity': qty,
        'unit': 'kg',
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
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Purchase order $poNumber created.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recsWithId = widget.recs.where((r) => r['inventory_item_id'] != null).toList();
    return AlertDialog(
      title: const Text('Create Purchase Order'),
      content: SizedBox(
        width: 400,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Supplier', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedSupplierId,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: _suppliers
                          .map((s) => DropdownMenuItem<String>(
                                value: s['id'] as String?,
                                child: Text(s['name']?.toString() ?? '—'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedSupplierId = v),
                    ),
                    const SizedBox(height: 16),
                    const Text('Products & quantities', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...recsWithId.map((r) {
                      final id = r['inventory_item_id']?.toString();
                      if (id == null) return const SizedBox.shrink();
                      final c = _qtyControllers[id];
                      if (c == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: Text(r['product_name']?.toString() ?? '—', overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: c,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder(), isDense: true),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
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
