import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/constants/admin_config.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// H1: Hunter Job Intake — hunter_name, contact_phone, species (from hunter_services), estimated_weight_kg, job_date, processing_instructions (cut_options), charge preview.
class JobIntakeScreen extends StatefulWidget {
  const JobIntakeScreen({super.key});

  @override
  State<JobIntakeScreen> createState() => _JobIntakeScreenState();
}

class _JobIntakeScreenState extends State<JobIntakeScreen> {
  final _client = SupabaseService.client;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  List<Map<String, dynamic>> _speciesList = [];
  String? _selectedSpeciesId;
  DateTime _jobDate = DateTime.now();
  final List<String> _selectedCuts = [];
  bool _loading = true;
  bool _saving = false;
  String? _savedJobId;
  String? _savedJobNumber;
  Map<String, dynamic>? _savedJob;

  @override
  void initState() {
    super.initState();
    _loadSpecies();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSpecies() async {
    try {
      final res = await _client
          .from('hunter_services')
          .select('id, name, base_price, price_per_kg, cut_options')
          .eq('is_active', true)
          .order('name');
      if (mounted) {
        setState(() {
          _speciesList = List<Map<String, dynamic>>.from(res as List);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _cutOptions {
    if (_selectedSpeciesId == null) return [];
    final s = _speciesList.cast<Map<String, dynamic>?>().firstWhere(
          (x) => x!['id']?.toString() == _selectedSpeciesId,
          orElse: () => null,
        );
    if (s == null) return [];
    final opts = s['cut_options'];
    if (opts is List) return opts.map((e) => e.toString()).toList();
    if (opts is String) {
      try {
        final decoded = jsonDecode(opts) as List;
        return decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }
    return [];
  }

  Map<String, dynamic>? get _selectedSpecies {
    if (_selectedSpeciesId == null) return null;
    try {
      return _speciesList.firstWhere((x) => x['id']?.toString() == _selectedSpeciesId);
    } catch (_) {
      return null;
    }
  }

  double get _estimatedCharge {
    final s = _selectedSpecies;
    if (s == null) return 0;
    final base = (s['base_price'] as num?)?.toDouble() ?? 0;
    final perKg = (s['price_per_kg'] as num?)?.toDouble() ?? 0;
    final w = double.tryParse(_weightCtrl.text) ?? 0;
    return base + (w * perKg);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSpeciesId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select species.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final jobNumber = 'HNT-${_jobDate.year}${_jobDate.month.toString().padLeft(2, '0')}${_jobDate.day.toString().padLeft(2, '0')}-${DateTime.now().millisecond.toString().padLeft(3, '0')}';
      final charge = _estimatedCharge;
      final processingInstructions = _selectedCuts;
      final estWeight = double.tryParse(_weightCtrl.text) ?? 0;
      final speciesName = _selectedSpecies?['name']?.toString() ?? '';
      final row = await _client.from('hunter_jobs').insert({
        'job_number': jobNumber,
        'hunter_name': _nameCtrl.text.trim(),
        'contact_phone': _phoneCtrl.text.trim(),
        'service_id': _selectedSpeciesId,
        'species': speciesName,
        'status': 'intake',
        'charge_total': charge,
        'estimated_weight': estWeight,
        'job_date': _jobDate.toIso8601String().substring(0, 10),
        'processing_instructions': processingInstructions,
        'customer_name': _nameCtrl.text.trim(),
        'customer_phone': _phoneCtrl.text.trim(),
        'animal_type': speciesName,
        'total_amount': charge,
      }).select().single();
      if (mounted) {
        setState(() {
          _saving = false;
          _savedJobId = row['id']?.toString();
          _savedJobNumber = jobNumber;
          _savedJob = Map<String, dynamic>.from(row as Map);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _printJobTicket() async {
    if (_savedJob == null) return;
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('Job Ticket $_savedJobNumber', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Hunter: ${_savedJob!['hunter_name'] ?? _savedJob!['client_name'] ?? '—'}'),
          pw.Text('Phone: ${_savedJob!['contact_phone'] ?? _savedJob!['client_contact'] ?? '—'}'),
          pw.Text('Date: ${_savedJob!['job_date'] ?? '—'}'),
          pw.Text('Estimated weight: ${_savedJob!['estimated_weight'] ?? _savedJob!['estimated_weight_kg']} kg'),
          pw.Text('Charge: R ${(_savedJob!['charge_total'] ?? _savedJob!['quoted_price'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
          pw.SizedBox(height: 8),
          pw.Text('Processing: ${(_savedJob!['processing_instructions'] as List?)?.join(', ') ?? '—'}'),
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
              ElevatedButton.icon(
                onPressed: _printJobTicket,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Print Job Ticket'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Back to list'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('New Hunter Job Intake'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
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
                    DropdownButtonFormField<String>(
                      value: _selectedSpeciesId,
                      decoration: const InputDecoration(labelText: 'Species *', border: OutlineInputBorder()),
                      items: _speciesList
                          .map((s) => DropdownMenuItem(value: s['id']?.toString(), child: Text(s['name']?.toString() ?? '—')))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedSpeciesId = v;
                          _selectedCuts.clear();
                        });
                      },
                      validator: (v) => v == null ? 'Select species' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _weightCtrl,
                      decoration: const InputDecoration(labelText: 'Estimated weight (kg) *', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        return n == null || n <= 0 ? 'Enter positive weight' : null;
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text('Job date'),
                      subtitle: Text('${_jobDate.year}-${_jobDate.month.toString().padLeft(2, '0')}-${_jobDate.day.toString().padLeft(2, '0')}'),
                      trailing: TextButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _jobDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (d != null) setState(() => _jobDate = d);
                        },
                        child: const Text('Change'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Processing instructions (select cuts)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._cutOptions.map((cut) => CheckboxListTile(
                          title: Text(cut),
                          value: _selectedCuts.contains(cut),
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selectedCuts.add(cut);
                              } else {
                                _selectedCuts.remove(cut);
                              }
                            });
                          },
                        )),
                    if (_cutOptions.isEmpty && _selectedSpeciesId != null)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No cut options for this species. Add cut_options in Services config.'),
                      ),
                    const SizedBox(height: 16),
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
}
