import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/constants/admin_config.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/features/hunter/screens/job_summary_screen.dart';

/// H1: Hunter Job Process — read-only intake; per-cut actual weight + link to inventory_item; Mark Ready → update job, add stock, navigate to summary.
class JobProcessScreen extends StatefulWidget {
  final Map<String, dynamic> job;

  const JobProcessScreen({super.key, required this.job});

  @override
  State<JobProcessScreen> createState() => _JobProcessScreenState();
}

class _CutRow {
  final String name;
  final TextEditingController weightController;
  String? linkedInventoryItemId;

  _CutRow({required this.name, required this.weightController, this.linkedInventoryItemId});
}

class _JobProcessScreenState extends State<JobProcessScreen> {
  final _client = SupabaseService.client;
  List<_CutRow> _cutRows = [];
  final TextEditingController _weightInTotalCtrl = TextEditingController();
  List<Map<String, dynamic>> _inventoryItems = [];
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic>? _service;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final row in _cutRows) row.weightController.dispose();
    _weightInTotalCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final instructions = widget.job['processing_instructions'];
      List<String> cutNames = [];
      if (instructions is List) {
        cutNames = instructions.map((e) => e.toString()).toList();
      }
      for (final name in cutNames) {
        final ctrl = TextEditingController();
        ctrl.addListener(() {
          double t = 0;
          for (final r in _cutRows) {
            t += double.tryParse(r.weightController.text.trim()) ?? 0;
          }
          _weightInTotalCtrl.text = t.toStringAsFixed(AdminConfig.stockKgDecimals);
          if (mounted) setState(() {});
        });
        _cutRows.add(_CutRow(name: name, weightController: ctrl));
      }
      _weightInTotalCtrl.addListener(() => setState(() {}));
      final serviceId = widget.job['service_id']?.toString();
      if (serviceId != null) {
        final s = await _client.from('hunter_services').select('*').eq('id', serviceId).maybeSingle();
        if (s != null) _service = Map<String, dynamic>.from(s as Map);
      }
      final inv = await _client
          .from('inventory_items')
          .select('id, name, product_type')
          .eq('is_active', true)
          .order('name');
      final list = List<Map<String, dynamic>>.from(inv as List);
      _inventoryItems = list.where((i) {
        final pt = i['product_type']?.toString();
        return pt == null || pt == 'raw' || pt == 'portioned';
      }).toList();
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _recalcTotal() {
    double t = 0;
    for (final row in _cutRows) {
      t += double.tryParse(row.weightController.text.trim()) ?? 0;
    }
    if (_weightInTotalCtrl.text != t.toStringAsFixed(AdminConfig.stockKgDecimals)) {
      _weightInTotalCtrl.text = t.toStringAsFixed(AdminConfig.stockKgDecimals);
    }
  }

  double get _actualWeightIn {
    return double.tryParse(_weightInTotalCtrl.text.trim()) ?? 0;
  }

  double get _finalCharge {
    if (_service == null) return 0;
    final base = (_service!['base_price'] as num?)?.toDouble() ?? 0;
    final perKg = (_service!['price_per_kg'] as num?)?.toDouble() ?? 0;
    return base + (_actualWeightIn * perKg);
  }

  Future<void> _markReady() async {
    final weightIn = _actualWeightIn;
    if (weightIn <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter actual weight in.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final cuts = <Map<String, dynamic>>[];
      for (final row in _cutRows) {
        final w = double.tryParse(row.weightController.text.trim()) ?? 0;
        if (w > 0) {
          cuts.add({
            'name': row.name,
            'weight_kg': w,
            'inventory_item_id': row.linkedInventoryItemId,
          });
        }
      }
      final jobId = widget.job['id'] as String;
      await _client.from('hunter_jobs').update({
        'status': 'ready',
        'cuts': cuts,
        'weight_in': weightIn,
        'charge_total': _finalCharge,
        'total_amount': _finalCharge,
      }).eq('id', jobId);

      for (final c in cuts) {
        final invId = c['inventory_item_id']?.toString();
        final w = (c['weight_kg'] as num?)?.toDouble() ?? 0;
        if (invId != null && invId.isNotEmpty && w > 0) {
          final row = await _client.from('inventory_items').select('current_stock').eq('id', invId).single();
          final cur = (row['current_stock'] as num?)?.toDouble() ?? 0;
          await _client.from('inventory_items').update({'current_stock': cur + w}).eq('id', invId);
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _JobSummaryRoute(
              jobId: jobId,
              jobNumber: widget.job['job_number']?.toString() ?? '—',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Process job ${widget.job['job_number'] ?? '—'}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Intake details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Hunter: ${widget.job['hunter_name'] ?? widget.job['client_name'] ?? '—'}'),
            Text('Phone: ${widget.job['contact_phone'] ?? widget.job['client_contact'] ?? '—'}'),
            Text('Species: ${_service?['name'] ?? widget.job['species'] ?? '—'}'),
            Text('Job date: ${widget.job['job_date'] ?? '—'}'),
            Text('Estimated weight: ${widget.job['estimated_weight'] ?? widget.job['estimated_weight_kg'] ?? '—'} kg'),
            Text('Charge: R ${(widget.job['charge_total'] ?? widget.job['quoted_price'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
            const SizedBox(height: 24),
            const Text('Per cut — actual weight & link to product', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._cutRows.map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(width: 120, child: Text(row.name, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: row.weightController,
                          decoration: const InputDecoration(labelText: 'Weight (kg)', isDense: true, border: OutlineInputBorder()),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: row.linkedInventoryItemId,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Link product', isDense: true, border: OutlineInputBorder()),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('— None —')),
                            ..._inventoryItems.map((i) => DropdownMenuItem(value: i['id']?.toString(), child: Text(i['name']?.toString() ?? '—', overflow: TextOverflow.ellipsis))),
                          ],
                          onChanged: (v) => setState(() => row.linkedInventoryItemId = v),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            TextField(
              controller: _weightInTotalCtrl,
              decoration: const InputDecoration(labelText: 'Actual weight in (total, kg)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surfaceBg, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Final charge:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('R ${_finalCharge.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _markReady,
              child: _saving ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Mark Ready'),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back')),
          ],
        ),
      ),
    );
  }
}

/// Helper route to load job and show JobSummaryScreen (avoids passing full job through pop).
class _JobSummaryRoute extends StatelessWidget {
  final String jobId;
  final String jobNumber;

  const _JobSummaryRoute({required this.jobId, required this.jobNumber});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: SupabaseService.client.from('hunter_jobs').select('*, hunter_services(name, base_price, price_per_kg)').eq('id', jobId).maybeSingle(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final job = snap.data != null ? Map<String, dynamic>.from(snap.data!) : null;
        if (job == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Job')),
            body: const Center(child: Text('Job not found')),
          );
        }
        return JobSummaryScreen(job: job);
      },
    );
  }
}
