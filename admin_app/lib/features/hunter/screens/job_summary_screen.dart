import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final businessName = _businessSettings?['setting_value']?.toString() ?? 'Business';
    final cuts = job['cuts'];
    List<Map<String, dynamic>> cutList = [];
    if (cuts is List) {
      for (final c in cuts) {
        if (c is Map) {
          cutList.add(Map<String, dynamic>.from(c));
        } else if (c is Map<String, dynamic>) {
          cutList.add(c);
        }
      }
    }
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(businessName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Hunter Job Invoice — ${job['job_number'] ?? '—'}', style: pw.TextStyle(fontSize: 16)),
          pw.SizedBox(height: 12),
          pw.Text('Hunter: ${job['hunter_name'] ?? job['client_name'] ?? '—'}'),
          pw.Text('Phone: ${job['contact_phone'] ?? job['client_contact'] ?? '—'}'),
          pw.Text('Species: ${(job['hunter_services'] is Map ? (job['hunter_services'] as Map)['name'] : null) ?? '—'}'),
          pw.Text('Date: ${job['job_date'] ?? job['created_at']?.toString().substring(0, 10) ?? '—'}'),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Cut', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Weight (kg)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Linked product', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                ],
              ),
              ...cutList.map((c) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(c['name']?.toString() ?? '—')),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${(c['weight_kg'] as num?)?.toStringAsFixed(3) ?? '—'}')),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(c['inventory_item_id']?.toString() ?? '—')),
                    ],
                  )),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text('Charge: R ${(job['charge_total'] ?? job['final_price'] ?? job['quoted_price'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
          pw.Text('Payment status: ${job['paid'] == true ? 'Paid' : 'Unpaid'}'),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
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
        title: Text('Job ${job['job_number'] ?? '—'}'),
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
