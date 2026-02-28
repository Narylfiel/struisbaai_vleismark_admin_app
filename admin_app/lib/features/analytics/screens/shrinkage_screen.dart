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
