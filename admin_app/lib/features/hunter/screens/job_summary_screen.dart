import 'dart:io';
import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/features/hunter/models/hunter_job.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';

/// H1: Hunter Job Summary — read-only job details; Mark Paid, Print PDF Invoice, WhatsApp, Mark Collected.
class JobSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> job;

  const JobSummaryScreen({super.key, required this.job});

  @override
  State<JobSummaryScreen> createState() => _JobSummaryScreenState();
}

class _JobSummaryScreenState extends State<JobSummaryScreen> {
  final _client = SupabaseService.client;
  bool _saving = false;
  bool _collected = false;
  Map<String, dynamic>? _businessSettings;

  @override
  void initState() {
    super.initState();
    _collected = (widget.job['status']?.toString().toLowerCase() ?? '') == 'completed';
    _loadBusinessSettings();
  }

  Future<void> _loadBusinessSettings() async {
    try {
      final row = await _client.from('business_settings').select('*').eq('setting_key', 'business_name').maybeSingle();
      if (row != null && mounted) setState(() => _businessSettings = Map<String, dynamic>.from(row as Map));
    } catch (_) {}
  }

  Future<void> _markPaid() async {
    setState(() => _saving = true);
    try {
      await _client.from('hunter_jobs').update({'paid': true}).eq('id', widget.job['id']);
      if (mounted) setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as paid')));
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _printPdfInvoice() async {
    final job = widget.job;
    final pdf = pw.Document();
    
    // Load business settings
    Map<String, dynamic>? bizSettings;
    try {
      final rows = await _client.from('business_settings').select('setting_key, setting_value');
      final settingsMap = <String, String>{};
      for (final row in rows as List) {
        final key = row['setting_key']?.toString();
        final value = row['setting_value']?.toString();
        if (key != null && value != null) settingsMap[key] = value;
      }
      bizSettings = settingsMap;
    } catch (_) {}
    
    final businessName = bizSettings?['business_name'] ?? 'Business';
    final address = bizSettings?['address'] ?? '';
    final phone = bizSettings?['phone'] ?? '';
    final email = bizSettings?['email'] ?? '';
    final vatNumber = bizSettings?['vat_number'] ?? '';
    final jobNumber = hunterJobDisplayNumber(job['id']?.toString());
    final jobDate = job['job_date']?.toString() ?? DateTime.now().toString().substring(0, 10);
    
    // Parse lists
    final speciesList = job['species_list'] is List ? List<Map<String, dynamic>>.from((job['species_list'] as List).map((e) => e is Map ? Map<String, dynamic>.from(e) : {})) : <Map<String, dynamic>>[];
    final servicesList = job['services_list'] is List ? List<Map<String, dynamic>>.from((job['services_list'] as List).map((e) => e is Map ? Map<String, dynamic>.from(e) : {})) : <Map<String, dynamic>>[];
    final materialsList = job['materials_list'] is List ? List<Map<String, dynamic>>.from((job['materials_list'] as List).map((e) => e is Map ? Map<String, dynamic>.from(e) : {})) : <Map<String, dynamic>>[];
    final processingOpts = job['processing_options'] is Map ? Map<String, dynamic>.from(job['processing_options'] as Map) : <String, dynamic>{};
    
    // Calculate totals
    double servicesTotal = 0;
    for (final s in servicesList) {
      // Simplified - actual calculation would need service details
      servicesTotal += ((job['charge_total'] as num?)?.toDouble() ?? 0) - materialsList.fold<double>(0, (sum, m) => sum + ((m['line_total'] as num?)?.toDouble() ?? 0));
    }
    final materialsTotal = materialsList.fold<double>(0, (sum, m) => sum + ((m['line_total'] as num?)?.toDouble() ?? 0));
    final totalCharge = (job['charge_total'] as num?)?.toDouble() ?? 0;
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // PAGE HEADER
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 80,
                      height: 80,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                        color: PdfColors.grey200,
                      ),
                      child: pw.Center(child: pw.Text('LOGO', style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10))),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(businessName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    if (address.isNotEmpty) pw.Text(address, style: const pw.TextStyle(fontSize: 10)),
                    if (phone.isNotEmpty) pw.Text(phone, style: const pw.TextStyle(fontSize: 10)),
                    if (email.isNotEmpty) pw.Text(email, style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Center(child: pw.Text('HUNTER JOB CARD', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 4),
            pw.Center(child: pw.Text('Job Number: $jobNumber  |  Date: $jobDate', style: const pw.TextStyle(fontSize: 12))),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 16),
            
            // CUSTOMER SECTION
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(border: pw.Border.all(), color: PdfColors.grey100),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Hunter Name: ${job['hunter_name'] ?? '—'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Contact: ${job['contact_phone'] ?? '—'}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Job Date: $jobDate'),
                      pw.Text('Status: ${HunterJobStatusExt.fromDb(job['status']?.toString()).displayLabel}'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            
            // SPECIES & ANIMALS TABLE
            pw.Text('SPECIES & ANIMALS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: ['Species', 'Est. Weight (kg)', 'Count', 'Notes'],
              data: speciesList.map((s) => [
                s['name'] ?? '—',
                (s['estimated_weight'] as num?)?.toStringAsFixed(1) ?? '—',
                (s['count'] ?? 1).toString(),
                '—',
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              border: pw.TableBorder.all(),
            ),
            pw.SizedBox(height: 16),
            
            // SERVICES TABLE
            pw.Text('SERVICES', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: ['Service', 'Qty', 'Unit Price', 'Total'],
              data: servicesList.map((s) => [
                s['name'] ?? '—',
                (s['quantity'] ?? 1).toString(),
                '—',
                '—',
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              border: pw.TableBorder.all(),
            ),
            pw.SizedBox(height: 16),
            
            // MATERIALS TABLE
            if (materialsList.isNotEmpty) ...[
              pw.Text('MATERIALS/INGREDIENTS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Table.fromTextArray(
                headers: ['Material/Ingredient', 'Qty', 'Unit', 'Unit Cost', 'Total'],
                data: materialsList.map((m) => [
                  m['name'] ?? '—',
                  (m['quantity'] as num?)?.toString() ?? '—',
                  m['unit'] ?? '—',
                  'R ${(m['unit_cost'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                  'R ${(m['line_total'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                ]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 9),
                border: pw.TableBorder.all(),
              ),
              pw.SizedBox(height: 16),
            ],
            
            // PROCESSING INSTRUCTIONS
            pw.Text('PROCESSING INSTRUCTIONS:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(border: pw.Border.all(), color: PdfColors.grey50),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(job['processing_instructions']?.toString() ?? 'None specified', style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _pdfCheckbox('Skin', processingOpts['skin'] == true),
                            _pdfCheckbox('Remove Head', processingOpts['remove_head'] == true),
                            _pdfCheckbox('Remove Feet', processingOpts['remove_feet'] == true),
                            _pdfCheckbox('Halaal', processingOpts['halaal'] == true),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _pdfCheckbox('Split Carcass', processingOpts['split'] == true),
                            _pdfCheckbox('Quarter', processingOpts['quarter'] == true),
                            _pdfCheckbox('Whole', processingOpts['whole'] == true),
                            _pdfCheckbox('Kosher', processingOpts['kosher'] == true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            
            // TOTALS BOX
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 250,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Services Total:'), pw.Text('R ${servicesTotal.toStringAsFixed(2)}')]),
                      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Materials Total:'), pw.Text('R ${materialsTotal.toStringAsFixed(2)}')]),
                      pw.Divider(),
                      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('TOTAL CHARGE:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text('R ${totalCharge.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))]),
                    ],
                  ),
                ),
              ],
            ),
            pw.Spacer(),
            
            // FOOTER
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Authorized by: _________________  Date: _______', style: const pw.TextStyle(fontSize: 10)),
                pw.Text('Customer signature: _____________  Date: _______', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            if (vatNumber.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Center(child: pw.Text('VAT Number: $vatNumber', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))),
            ],
          ],
        ),
      ),
    );
    
    // Save using ExportService pattern
    try {
      final dir = await getDownloadsDirectory();
      if (dir == null) {
        await Printing.layoutPdf(onLayout: (_) async => pdf.save());
        return;
      }
      final fileName = 'job_card_${jobNumber.replaceAll('-', '_')}_${DateTime.now().toIso8601String().substring(0, 10)}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to ${file.path}'), duration: const Duration(seconds: 5)));
      }
    } catch (e) {
      await Printing.layoutPdf(onLayout: (_) async => pdf.save());
    }
  }
  
  pw.Widget _pdfCheckbox(String label, bool checked) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Container(
            width: 12,
            height: 12,
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: checked ? pw.Center(child: pw.Text('X', style: const pw.TextStyle(fontSize: 10))) : null,
          ),
          pw.SizedBox(width: 4),
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  Future<void> _sendWhatsApp() async {
    final phone = (widget.job['contact_phone'] ?? widget.job['client_contact'])?.toString()?.replaceAll(RegExp(r'[^\d+]'), '') ?? '';
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No phone number for hunter.')));
      return;
    }
    final name = widget.job['hunter_name'] ?? widget.job['client_name'] ?? 'there';
    final species = (widget.job['hunter_services'] is Map ? (widget.job['hunter_services'] as Map)['name'] : null) ?? 'order';
    final text = Uri.encodeComponent('Hi $name, your $species is ready for collection.');
    final url = Uri.parse('https://wa.me/$phone?text=$text');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp.')));
    }
  }

  Future<void> _markCollected() async {
    setState(() => _saving = true);
    try {
      await _client.from('hunter_jobs').update({'status': 'completed'}).eq('id', widget.job['id']);
      if (mounted) setState(() { _saving = false; _collected = true; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as collected')));
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final service = job['hunter_services'] is Map ? job['hunter_services'] as Map<String, dynamic>? : null;
    final cuts = job['cuts'];
    List<dynamic> cutList = [];
    if (cuts is List) cutList = cuts;

    return Scaffold(
      appBar: AppBar(
        title: Text('Job ${hunterJobDisplayNumber(job['id']?.toString())}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Job details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _row('Hunter', (job['hunter_name'] ?? job['client_name'])?.toString() ?? '—'),
            _row('Phone', (job['contact_phone'] ?? job['client_contact'])?.toString() ?? '—'),
            _row('Species', service?['name']?.toString() ?? '—'),
            _row('Job date', job['job_date']?.toString() ?? '—'),
            _row('Weight in (kg)', (job['weight_in'] ?? job['actual_weight_kg'] as num?)?.toString() ?? '—'),
            _row('Charge', 'R ${(job['charge_total'] ?? job['final_price'] ?? job['quoted_price'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
            _row('Payment', job['paid'] == true ? 'Paid' : 'Unpaid'),
            const SizedBox(height: 16),
            const Text('Cuts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (cutList.isEmpty)
              const Text('—')
            else
              ...cutList.map((c) {
                final map = c is Map ? Map<String, dynamic>.from(c) : <String, dynamic>{};
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('${map['name'] ?? '—'} — ${(map['weight_kg'] as num?)?.toStringAsFixed(3) ?? '—'} kg'),
                );
              }),
            const SizedBox(height: 32),
            if (!_collected) ...[
              ElevatedButton.icon(
                onPressed: _saving ? null : _markPaid,
                icon: const Icon(Icons.payment),
                label: const Text('Mark Paid'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _printPdfInvoice,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Print PDF Invoice'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _sendWhatsApp,
                icon: const Icon(Icons.chat),
                label: const Text('WhatsApp'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _saving ? null : _markCollected,
                icon: const Icon(Icons.check_circle),
                label: const Text('Mark Collected'),
              ),
            ] else
              const Text('Job collected. All actions disabled.', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back to list')),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
