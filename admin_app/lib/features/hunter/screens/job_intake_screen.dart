import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/features/hunter/models/hunter_job.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Hunter Job Intake — species (hunter_species), services, materials, processing options.
class JobIntakeScreen extends StatefulWidget {
  final Map<String, dynamic>? existingJob;
  
  const JobIntakeScreen({super.key, this.existingJob});

  @override
  State<JobIntakeScreen> createState() => _JobIntakeScreenState();
}

class _JobIntakeScreenState extends State<JobIntakeScreen> {
  final _client = SupabaseService.client;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _processingNotesCtrl = TextEditingController();

  List<Map<String, dynamic>> _speciesOptions = [];
  List<Map<String, dynamic>> _serviceOptions = [];
  List<Map<String, dynamic>> _inventoryItems = [];

  // Species rows: {species_id, name, estimated_weight, count}
  final List<Map<String, dynamic>> _speciesRows = [];
  // Service rows: {service_id, name, quantity, notes}
  final List<Map<String, dynamic>> _serviceRows = [];
  // Material rows: {item_id, name, quantity, unit, unit_cost, line_total}
  final List<Map<String, dynamic>> _materialRows = [];

  static const List<String> _unitOptions = ['kg', 'g', 'units', 'packs', 'litres', 'ml'];

  // Processing options checkboxes
  bool _optSkin = false;
  bool _optRemoveHead = false;
  bool _optRemoveFeet = false;
  bool _optHalaal = false;
  bool _optKosher = false;
  bool _optSplit = false;
  bool _optQuarter = false;
  bool _optWhole = false;
  final List<String> _selectedCutOptions = []; // from services' cut_options

  DateTime _jobDate = DateTime.now();
  bool _loading = true;
  bool _saving = false;
  String? _savedJobId;
  String? _savedJobNumber;
  Map<String, dynamic>? _savedJob;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Pre-fill data if editing existing job
    if (widget.existingJob != null) {
      _prefillFromExistingJob();
    } else {
      // Initialize empty rows for new job
      if (_speciesRows.isEmpty) _speciesRows.add({'species_id': null, 'name': null, 'estimated_weight': null, 'count': 1});
      if (_serviceRows.isEmpty) _serviceRows.add({'service_id': null, 'name': null, 'quantity': 1, 'notes': ''});
    }
  }
  
  void _prefillFromExistingJob() {
    final job = widget.existingJob!;
    
    // Basic fields
    _nameCtrl.text = job['hunter_name']?.toString() ?? job['customer_name']?.toString() ?? '';
    _phoneCtrl.text = job['contact_phone']?.toString() ?? job['customer_phone']?.toString() ?? '';
    _processingNotesCtrl.text = job['processing_instructions']?.toString() ?? '';
    
    // Job date
    if (job['job_date'] != null) {
      try {
        _jobDate = DateTime.parse(job['job_date'].toString());
      } catch (_) {}
    }
    
    // Species list
    final speciesList = job['species_list'];
    if (speciesList is List && speciesList.isNotEmpty) {
      _speciesRows.clear();
      for (final s in speciesList) {
        if (s is Map) {
          _speciesRows.add({
            'species_id': s['species_id'],
            'name': s['name'],
            'estimated_weight': s['estimated_weight'],
            'count': s['count'] ?? 1,
          });
        }
      }
    } else {
      _speciesRows.add({'species_id': null, 'name': null, 'estimated_weight': null, 'count': 1});
    }
    
    // Services list
    final servicesList = job['services_list'];
    if (servicesList is List && servicesList.isNotEmpty) {
      _serviceRows.clear();
      for (final s in servicesList) {
        if (s is Map) {
          _serviceRows.add({
            'service_id': s['service_id'],
            'name': s['name'],
            'quantity': s['quantity'] ?? 1,
            'notes': s['notes'] ?? '',
          });
        }
      }
    } else {
      _serviceRows.add({'service_id': null, 'name': null, 'quantity': 1, 'notes': ''});
    }
    
    // Materials list
    final materialsList = job['materials_list'];
    if (materialsList is List && materialsList.isNotEmpty) {
      _materialRows.clear();
      for (final m in materialsList) {
        if (m is Map) {
          _materialRows.add({
            'item_id': m['item_id'],
            'name': m['name'],
            'quantity': m['quantity'] ?? 1,
            'unit': m['unit'] ?? 'kg',
            'unit_cost': m['unit_cost'] ?? 0,
            'line_total': m['line_total'] ?? 0,
          });
        }
      }
    }
    
    // Processing options
    final opts = job['processing_options'];
    if (opts is Map) {
      _optSkin = opts['skin'] == true;
      _optRemoveHead = opts['remove_head'] == true;
      _optRemoveFeet = opts['remove_feet'] == true;
      _optHalaal = opts['halaal'] == true;
      _optKosher = opts['kosher'] == true;
      _optSplit = opts['split'] == true;
      _optQuarter = opts['quarter'] == true;
      _optWhole = opts['whole'] == true;
      final selectedCuts = opts['selected_cuts'];
      if (selectedCuts is List) {
        _selectedCutOptions.clear();
        _selectedCutOptions.addAll(selectedCuts.map((c) => c.toString()));
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _processingNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final speciesRes = await _client.from('hunter_species').select('id, name, typical_weight_min, typical_weight_max').eq('is_active', true).order('sort_order');
      final servicesRes = await _client.from('hunter_services').select('id, name, base_price, price_per_kg, cut_options').eq('is_active', true).order('name');
      final invRes = await _client.from('inventory_items').select('id, name, plu_code, unit_type, cost_price').eq('is_active', true).order('name');
      if (mounted) {
        setState(() {
          _speciesOptions = List<Map<String, dynamic>>.from(speciesRes as List);
          _serviceOptions = List<Map<String, dynamic>>.from(servicesRes as List);
          _inventoryItems = List<Map<String, dynamic>>.from(invRes as List);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _speciesMidpoint(Map<String, dynamic>? s) {
    if (s == null) return 0;
    final min = (s['typical_weight_min'] as num?)?.toDouble();
    final max = (s['typical_weight_max'] as num?)?.toDouble();
    if (min != null && max != null) return (min + max) / 2;
    if (min != null) return min;
    if (max != null) return max;
    return 0;
  }

  int get _totalAnimalCount {
    int n = 0;
    for (final r in _speciesRows) {
      n += (r['count'] as int?) ?? 1;
    }
    return n;
  }

  double get _totalEstimatedWeight {
    double w = 0;
    for (final r in _speciesRows) {
      final ew = (r['estimated_weight'] as num?)?.toDouble();
      final c = (r['count'] as int?) ?? 1;
      if (ew != null) w += ew * c;
    }
    return w;
  }

  /// Unique cut option names from all selected services (for Processing instructions checkboxes).
  List<String> get _availableCutOptions {
    final names = <String>{};
    for (final row in _serviceRows) {
      final serviceId = row['service_id']?.toString();
      if (serviceId == null) continue;
      Map<String, dynamic>? svc;
      try {
        svc = _serviceOptions.firstWhere((x) => x['id']?.toString() == serviceId);
      } catch (_) {}
      if (svc == null) continue;
      final opts = svc['cut_options'];
      if (opts is List) {
        for (final o in opts) {
          if (o is Map && o['name'] != null) {
            names.add(o['name'].toString().trim());
          } else if (o is String && o.trim().isNotEmpty) {
            names.add(o.trim());
          }
        }
      }
    }
    return names.toList()..sort();
  }

  double get _estimatedCharge {
    double total = 0;
    final totalWeight = _totalEstimatedWeight;
    
    // Services charges
    for (final row in _serviceRows) {
      final serviceId = row['service_id']?.toString();
      if (serviceId == null) continue;
      final s = _serviceOptions.cast<Map<String, dynamic>?>().firstWhere(
        (x) => x!['id']?.toString() == serviceId,
        orElse: () => null,
      );
      if (s == null) continue;
      final base = (s['base_price'] as num?)?.toDouble() ?? 0;
      final perKg = (s['price_per_kg'] as num?)?.toDouble() ?? 0;
      final qty = (row['quantity'] as num?)?.toDouble() ?? 1;
      total += (base + (totalWeight * perKg)) * qty;
    }
    
    // Materials costs
    for (final row in _materialRows) {
      final lineTotal = (row['line_total'] as num?)?.toDouble() ?? 0;
      total += lineTotal;
    }
    
    return total;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final hasSpecies = _speciesRows.any((r) => r['species_id'] != null);
    if (!hasSpecies) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one species.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final speciesList = <Map<String, dynamic>>[];
      for (final r in _speciesRows) {
        if (r['species_id'] == null) continue;
        speciesList.add({
          'species_id': r['species_id'],
          'name': r['name']?.toString() ?? '',
          'estimated_weight': (r['estimated_weight'] as num?)?.toDouble(),
          'count': (r['count'] as int?) ?? 1,
        });
      }
      final servicesList = <Map<String, dynamic>>[];
      for (final r in _serviceRows) {
        if (r['service_id'] == null) continue;
        servicesList.add({
          'service_id': r['service_id'],
          'name': r['name']?.toString() ?? '',
          'quantity': (r['quantity'] as num?)?.toDouble() ?? 1,
          'notes': r['notes']?.toString() ?? '',
        });
      }
      final materialsList = <Map<String, dynamic>>[];
      for (final r in _materialRows) {
        if (r['item_id'] == null) continue;
        materialsList.add({
          'item_id': r['item_id'],
          'name': r['name']?.toString() ?? '',
          'quantity': (r['quantity'] as num?)?.toDouble() ?? 1,
          'unit': r['unit']?.toString() ?? 'kg',
          'unit_cost': (r['unit_cost'] as num?)?.toDouble() ?? 0,
          'line_total': (r['line_total'] as num?)?.toDouble() ?? 0,
        });
      }
      final processingOptions = {
        'skin': _optSkin,
        'remove_head': _optRemoveHead,
        'remove_feet': _optRemoveFeet,
        'halaal': _optHalaal,
        'kosher': _optKosher,
        'split': _optSplit,
        'quarter': _optQuarter,
        'whole': _optWhole,
        'selected_cuts': _selectedCutOptions,
      };
      
      final chargeTotal = _estimatedCharge;
      final totalWeight = _totalEstimatedWeight;
      final animalCount = _totalAnimalCount;
      final firstSpeciesName = speciesList.isNotEmpty ? (speciesList.first['name']?.toString() ?? '') : '';
      
      // Build payload using ONLY confirmed hunter_jobs columns
      final payload = {
        'job_date': _jobDate.toIso8601String().substring(0, 10),
        'hunter_name': _nameCtrl.text.trim(),
        'contact_phone': _phoneCtrl.text.trim(),
        'species': firstSpeciesName,
        'weight_in': totalWeight,
        'estimated_weight': totalWeight,
        'processing_instructions': _processingNotesCtrl.text.trim().isEmpty ? null : _processingNotesCtrl.text.trim(),
        'status': widget.existingJob?['status'] ?? 'intake', // Preserve status when editing
        'charge_total': chargeTotal,
        'total_amount': chargeTotal,
        'paid': widget.existingJob?['paid'] ?? false, // Preserve paid status
        'animal_count': animalCount,
        'animal_type': firstSpeciesName,
        'customer_name': _nameCtrl.text.trim(),
        'customer_phone': _phoneCtrl.text.trim(),
        'species_list': speciesList,
        'services_list': servicesList,
        'materials_list': materialsList,
        'processing_options': processingOptions,
      };
      
      final dynamic row;
      if (widget.existingJob != null) {
        // UPDATE existing job
        row = await _client
            .from('hunter_jobs')
            .update(payload)
            .eq('id', widget.existingJob!['id'])
            .select()
            .single();
      } else {
        // INSERT new job
        row = await _client.from('hunter_jobs').insert(payload).select().single();
      }
      
      if (mounted) {
        final id = row['id']?.toString();
        setState(() {
          _saving = false;
          _savedJobId = id;
          _savedJobNumber = id != null ? hunterJobDisplayNumber(id) : null;
          _savedJob = Map<String, dynamic>.from(row as Map);
        });
      }
    } catch (e) {
      print('Hunter job save error: $e');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _printJobTicket() async {
    if (_savedJob == null) return;
    final job = _savedJob!;
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('Job Ticket $_savedJobNumber', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Hunter: ${job['hunter_name'] ?? job['client_name'] ?? '—'}'),
          pw.Text('Phone: ${job['contact_phone'] ?? job['client_contact'] ?? '—'}'),
          pw.Text('Date: ${job['job_date'] ?? '—'}'),
          pw.Text('Estimated weight: ${job['estimated_weight'] ?? job['estimated_weight_kg']} kg'),
          pw.Text('Charge: R ${(job['charge_total'] ?? job['quoted_price'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
          pw.SizedBox(height: 8),
          pw.Text('Processing notes: ${job['processing_instructions'] ?? '—'}'),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    if (_savedJobNumber != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job created'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Job $_savedJobNumber saved.', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton.icon(onPressed: _printJobTicket, icon: const Icon(Icons.picture_as_pdf), label: const Text('Print Job Ticket')),
              const SizedBox(height: 16),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Back to list')),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.existingJob != null ? 'Edit Hunter Job — ${hunterJobDisplayNumber(widget.existingJob!['id']?.toString())}' : 'New Hunter Job Intake'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Hunter name *', border: OutlineInputBorder()),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Contact phone', border: OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text('Job date'),
                      subtitle: Text('${_jobDate.year}-${_jobDate.month.toString().padLeft(2, '0')}-${_jobDate.day.toString().padLeft(2, '0')}'),
                      trailing: TextButton(
                        onPressed: () async {
                          final d = await showDatePicker(context: context, initialDate: _jobDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                          if (d != null) setState(() => _jobDate = d);
                        },
                        child: const Text('Change'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('A) Species', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._speciesRows.asMap().entries.map((e) => _buildSpeciesRow(e.key)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(onPressed: () => setState(() => _speciesRows.add({'species_id': null, 'name': null, 'estimated_weight': null, 'count': 1})), icon: const Icon(Icons.add, size: 18), label: const Text('Add another species')),
                    const SizedBox(height: 20),
                    const Text('B) Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._serviceRows.asMap().entries.map((e) => _buildServiceRow(e.key)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(onPressed: () => setState(() => _serviceRows.add({'service_id': null, 'name': null, 'quantity': 1, 'notes': ''})), icon: const Icon(Icons.add, size: 18), label: const Text('Add service')),
                    const SizedBox(height: 20),
                    const Text('C) Ingredients / Materials', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._materialRows.asMap().entries.map((e) => _buildMaterialRow(e.key)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(onPressed: () => setState(() => _materialRows.add({'item_id': null, 'name': null, 'quantity': 1, 'unit': 'kg', 'unit_cost': 0, 'line_total': 0})), icon: const Icon(Icons.add, size: 18), label: const Text('Add material')),
                    const SizedBox(height: 20),
                    const Text('D) Processing instructions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(controller: _processingNotesCtrl, decoration: const InputDecoration(labelText: 'Free-text instructions', border: OutlineInputBorder(), alignLabelWithHint: true), maxLines: 3),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _procCb('Skin', _optSkin, (v) => setState(() => _optSkin = v)),
                        _procCb('Remove head', _optRemoveHead, (v) => setState(() => _optRemoveHead = v)),
                        _procCb('Remove feet', _optRemoveFeet, (v) => setState(() => _optRemoveFeet = v)),
                        _procCb('Halaal slaughter', _optHalaal, (v) => setState(() => _optHalaal = v)),
                        _procCb('Kosher', _optKosher, (v) => setState(() => _optKosher = v)),
                        _procCb('Split carcass', _optSplit, (v) => setState(() => _optSplit = v)),
                        _procCb('Quarter', _optQuarter, (v) => setState(() => _optQuarter = v)),
                        _procCb('Whole', _optWhole, (v) => setState(() => _optWhole = v)),
                      ],
                    ),
                    if (_availableCutOptions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Cut options (from selected services)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: _availableCutOptions.map((name) {
                          final selected = _selectedCutOptions.contains(name);
                          return _procCb(name, selected, (v) {
                            setState(() {
                              if (v) _selectedCutOptions.add(name);
                              else _selectedCutOptions.remove(name);
                            });
                          });
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.surfaceBg, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Charge preview:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('R ${_estimatedCharge.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save job'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _procCb(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(value: value, onChanged: (v) => onChanged(v ?? false), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _buildSpeciesRow(int index) {
    final row = _speciesRows[index];
    final speciesId = row['species_id']?.toString();
    Map<String, dynamic>? selectedSpecies;
    if (speciesId != null) {
      try {
        selectedSpecies = _speciesOptions.firstWhere((x) => x['id']?.toString() == speciesId);
      } catch (_) {}
    }
    final weightHint = selectedSpecies != null
        ? 'Typical: ${(selectedSpecies['typical_weight_min'] as num?)?.toInt() ?? '?'}–${(selectedSpecies['typical_weight_max'] as num?)?.toInt() ?? '?'} kg'
        : null;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String?>(
                value: speciesId,
                decoration: InputDecoration(
                  labelText: 'Species',
                  hintText: weightHint,
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Select species')),
                  ..._speciesOptions.map((s) => DropdownMenuItem<String?>(value: s['id']?.toString(), child: Text(s['name']?.toString() ?? '—'))),
                ],
                onChanged: (v) {
                  setState(() {
                    Map<String, dynamic>? s;
                    if (v != null) s = _speciesOptions.cast<Map<String, dynamic>?>().firstWhere((x) => x!['id']?.toString() == v, orElse: () => null);
                    _speciesRows[index] = {
                      'species_id': v,
                      'name': s?['name']?.toString(),
                      'estimated_weight': s != null ? _speciesMidpoint(s) : null,
                      'count': row['count'] ?? 1,
                    };
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: TextFormField(
                key: ValueKey('species_weight_$index\_${row['species_id']}_${row['estimated_weight']}'),
                initialValue: row['estimated_weight'] != null ? row['estimated_weight'].toString() : null,
                decoration: InputDecoration(
                  labelText: 'Est. weight (kg)',
                  hintText: weightHint,
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) {
                  final n = double.tryParse(v);
                  setState(() => _speciesRows[index]['estimated_weight'] = n);
                },
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: (row['count'] ?? 1).toString(),
                decoration: const InputDecoration(labelText: 'Count', isDense: true),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final n = int.tryParse(v) ?? 1;
                  setState(() => _speciesRows[index]['count'] = n);
                },
              ),
            ),
            if (_speciesRows.length > 1)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
                onPressed: () => setState(() => _speciesRows.removeAt(index)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceRow(int index) {
    final row = _serviceRows[index];
    final serviceId = row['service_id']?.toString();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String?>(
                value: serviceId,
                decoration: const InputDecoration(labelText: 'Service', isDense: true),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Select service')),
                  ..._serviceOptions.map((s) => DropdownMenuItem<String?>(value: s['id']?.toString(), child: Text('${s['name']} (R ${(s['base_price'] as num?)?.toStringAsFixed(0) ?? '0'})'))),
                ],
                onChanged: (v) {
                  setState(() {
                    Map<String, dynamic>? s;
                    if (v != null) s = _serviceOptions.cast<Map<String, dynamic>?>().firstWhere((x) => x!['id']?.toString() == v, orElse: () => null);
                    _serviceRows[index]['service_id'] = v;
                    _serviceRows[index]['name'] = s?['name']?.toString();
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              child: TextFormField(
                initialValue: (row['quantity'] ?? 1).toString(),
                decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => setState(() => _serviceRows[index]['quantity'] = double.tryParse(v) ?? 1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: row['notes']?.toString(),
                decoration: const InputDecoration(labelText: 'Notes', isDense: true),
                onChanged: (v) => setState(() => _serviceRows[index]['notes'] = v),
              ),
            ),
            if (_serviceRows.length > 1)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
                onPressed: () => setState(() => _serviceRows.removeAt(index)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialRow(int index) {
    final row = _materialRows[index];
    final itemId = row['item_id']?.toString();
    final quantity = (row['quantity'] as num?)?.toDouble() ?? 1;
    final unitCost = (row['unit_cost'] as num?)?.toDouble() ?? 0;
    final lineTotal = quantity * unitCost;
    
    // Auto-update line total when qty or unit cost changes
    if (row['line_total'] != lineTotal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _materialRows[index]['line_total'] = lineTotal);
      });
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String?>(
                    value: itemId,
                    decoration: const InputDecoration(labelText: 'Product', isDense: true),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Select product')),
                      ..._inventoryItems.map((i) => DropdownMenuItem<String?>(
                        value: i['id']?.toString(), 
                        child: Text('${i['plu_code'] ?? '—'} ${i['name'] ?? '—'}', overflow: TextOverflow.ellipsis),
                      )),
                    ],
                    onChanged: (v) {
                      setState(() {
                        Map<String, dynamic>? i;
                        if (v != null) i = _inventoryItems.cast<Map<String, dynamic>?>().firstWhere((x) => x!['id']?.toString() == v, orElse: () => null);
                        _materialRows[index]['item_id'] = v;
                        _materialRows[index]['name'] = i?['name']?.toString();
                        _materialRows[index]['unit'] = i?['unit_type']?.toString() ?? 'kg';
                        _materialRows[index]['unit_cost'] = (i?['cost_price'] as num?)?.toDouble() ?? 0;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: (row['quantity'] ?? 1).toString(),
                    decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => setState(() => _materialRows[index]['quantity'] = double.tryParse(v) ?? 1),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: DropdownButtonFormField<String>(
                    value: row['unit']?.toString() ?? 'kg',
                    decoration: const InputDecoration(labelText: 'Unit', isDense: true),
                    items: _unitOptions.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) => setState(() => _materialRows[index]['unit'] = v ?? 'kg'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
                  onPressed: () => setState(() => _materialRows.removeAt(index)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey('material_unit_cost_$index\_${row['item_id']}_${row['unit_cost']}'),
                    initialValue: unitCost.toStringAsFixed(2),
                    decoration: const InputDecoration(
                      labelText: 'Unit Cost (R)',
                      isDense: true,
                      helperText: 'Auto-filled from inventory',
                      helperMaxLines: 1,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => setState(() => _materialRows[index]['unit_cost'] = double.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBg,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'Line Total: R ${lineTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
