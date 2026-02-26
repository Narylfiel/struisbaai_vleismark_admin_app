import 'dart:io';
import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/audit_service.dart';
import 'package:admin_app/features/hunter/models/hunter_job.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

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
  bool _isLoading = false;
  Map<String, dynamic>? _businessSettings;
  Map<String, dynamic>? _currentJob;

  @override
  void initState() {
    super.initState();
    _currentJob = widget.job;
    _collected = (widget.job['status']?.toString().toLowerCase() ?? '') == 'completed';
    _loadBusinessSettings();
    _reloadJob();
  }
  
  Future<void> _reloadJob() async {
    try {
      final fresh = await _client
          .from('hunter_jobs')
          .select('*')
          .eq('id', widget.job['id'])
          .single();
      if (mounted) {
        setState(() => _currentJob = Map<String, dynamic>.from(fresh as Map));
      }
    } catch (e) {
      debugPrint('Error reloading job: $e');
      // Keep using widget.job as fallback
    }
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
      final job = _currentJob ?? widget.job;
      final jobNumber = hunterJobDisplayNumber(job['id']?.toString());
      final hunterName = job['hunter_name'] ?? job['client_name'] ?? 'Unknown';
      
      await _client.from('hunter_jobs').update({'paid': true}).eq('id', widget.job['id']);
      
      // Audit log - payment recorded
      await AuditService.log(
        action: 'UPDATE',
        module: 'Hunter',
        description: 'Hunter job marked as paid: $hunterName - Job #$jobNumber',
        entityType: 'HunterJob',
        entityId: widget.job['id'],
      );
      
      await _reloadJob(); // Reload after update
      if (mounted) setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as paid')));
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _printJobCard() async {
    // Always fetch fresh data before printing
    setState(() => _isLoading = true);
    try {
      final fresh = await _client
          .from('hunter_jobs')
          .select('*')
          .eq('id', widget.job['id'])
          .single();
      
      final freshJob = Map<String, dynamic>.from(fresh as Map);
      await _generateJobCard(freshJob);
    } catch (e) {
      debugPrint('Error reloading job for PDF: $e');
      // Fall back to current job if reload fails
      await _generateJobCard(_currentJob ?? widget.job);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateJobCard(Map<String, dynamic> job) async {
    // Load business settings
    Map<String, dynamic> biz = {};
    try {
      final r = await _client
          .from('business_settings')
          .select('business_name, address, phone, email, vat_number')
          .maybeSingle();
      if (r != null) biz = Map<String, dynamic>.from(r as Map);
    } catch (e) {
      debugPrint('Biz settings error: $e');
    }

    final bizName = biz['business_name'] ?? 'Struisbaai Vleismark';
    final bizAddress = biz['address'] ?? '';
    final bizPhone = biz['phone'] ?? '';
    final bizEmail = biz['email'] ?? '';
    final vatNo = biz['vat_number'] ?? '';
    final jobRef = hunterJobDisplayNumber(job['id']?.toString());
    
    // Parse job date
    DateTime jobDate = DateTime.now();
    try {
      if (job['job_date'] != null) {
        jobDate = DateTime.parse(job['job_date'].toString());
      }
    } catch (_) {}

    // Parse JSONB lists safely
    List speciesList = [];
    List servicesList = [];
    List materialsList = [];
    Map processingOpts = {};
    try { speciesList = (job['species_list'] as List?) ?? []; } catch(_) {}
    try { servicesList = (job['services_list'] as List?) ?? []; } catch(_) {}
    try { materialsList = (job['materials_list'] as List?) ?? []; } catch(_) {}
    try { processingOpts = (job['processing_options'] as Map?) ?? {}; } catch(_) {}

    // Calculate totals
    double servicesTotal = 0;
    for (final s in servicesList) {
      final qty = (s['quantity'] as num?)?.toDouble() ?? 1;
      final price = (s['unit_price'] as num?)?.toDouble() ?? 0;
      servicesTotal += qty * price;
    }
    double materialsTotal = 0;
    for (final m in materialsList) {
      final total = (m['line_total'] as num?)?.toDouble() ?? 0;
      materialsTotal += total;
    }
    final grandTotal = servicesTotal + materialsTotal;

    final pdf = pw.Document();

    // Helper for table header cell
    pw.Widget headerCell(String text) => pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold, fontSize: 8)));

    // Helper for table data cell
    pw.Widget dataCell(String text, {pw.TextAlign align = pw.TextAlign.left}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(text,
          textAlign: align,
          style: const pw.TextStyle(fontSize: 8)));

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [

          // ══ HEADER ══
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left: business info
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(bizName,
                    style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 2),
                  if (bizAddress.isNotEmpty)
                    pw.Text(bizAddress, style: const pw.TextStyle(fontSize: 8)),
                  if (bizPhone.isNotEmpty)
                    pw.Text('Tel: $bizPhone', style: const pw.TextStyle(fontSize: 8)),
                  if (bizEmail.isNotEmpty)
                    pw.Text(bizEmail, style: const pw.TextStyle(fontSize: 8)),
                  if (vatNo.isNotEmpty)
                    pw.Text('VAT No: $vatNo', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              // Right: job card title
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey800,
                      borderRadius: pw.BorderRadius.circular(4)),
                    child: pw.Text('HUNTER JOB CARD',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text('Job #: $jobRef',
                    style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    'Date: ${DateFormat('dd/MM/yyyy').format(jobDate)}',
                    style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 10),
          pw.Divider(thickness: 1.5),
          pw.SizedBox(height: 8),

          // ══ CUSTOMER INFO ══
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 0.5),
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(3)),
            child: pw.Row(
              children: [
                pw.Expanded(child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Hunter / Customer',
                      style: const pw.TextStyle(
                        fontSize: 7, color: PdfColors.grey600)),
                    pw.Text(
                      job['hunter_name'] ?? job['customer_name'] ?? '-',
                      style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 2),
                    pw.Text('Contact: ${job['contact_phone'] ?? job['customer_phone'] ?? '-'}',
                      style: const pw.TextStyle(fontSize: 9)),
                  ],
                )),
                pw.Expanded(child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Job Date',
                      style: const pw.TextStyle(
                        fontSize: 7, color: PdfColors.grey600)),
                    pw.Text(
                      DateFormat('dd/MM/yyyy').format(jobDate),
                      style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 2),
                    pw.Text('Status: ${(job['status'] ?? 'intake').toString().toUpperCase()}',
                      style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                )),
              ],
            ),
          ),

          pw.SizedBox(height: 12),

          // ══ SPECIES TABLE ══
          if (speciesList.isNotEmpty) ...[
            pw.Text('SPECIES / ANIMALS',
              style: pw.TextStyle(
                fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    headerCell('Species'),
                    headerCell('Est. Weight'),
                    headerCell('Count'),
                  ]),
                ...speciesList.map((s) => pw.TableRow(children: [
                  dataCell(s['name']?.toString() ?? ''),
                  dataCell('${s['estimated_weight'] ?? ''} kg'),
                  dataCell('${s['count'] ?? 1}'),
                ])),
              ],
            ),
            pw.SizedBox(height: 10),
          ],

          // ══ SERVICES TABLE ══
          if (servicesList.isNotEmpty) ...[
            pw.Text('SERVICES',
              style: pw.TextStyle(
                fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    headerCell('Service'),
                    headerCell('Qty'),
                    headerCell('Unit Price'),
                    headerCell('Total'),
                  ]),
                ...servicesList.map((s) {
                  final qty = (s['quantity'] as num?)?.toDouble() ?? 1;
                  final price = (s['unit_price'] as num?)?.toDouble() ?? 0;
                  final total = qty * price;
                  return pw.TableRow(children: [
                    dataCell(s['name']?.toString() ?? s['service_name']?.toString() ?? ''),
                    dataCell('${qty.toInt()}'),
                    dataCell('R ${price.toStringAsFixed(2)}',
                      align: pw.TextAlign.right),
                    dataCell('R ${total.toStringAsFixed(2)}',
                      align: pw.TextAlign.right),
                  ]);
                }),
              ],
            ),
            pw.SizedBox(height: 10),
          ],

          // ══ MATERIALS TABLE ══
          if (materialsList.isNotEmpty) ...[
            pw.Text('MATERIALS / INGREDIENTS',
              style: pw.TextStyle(
                fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    headerCell('Material'),
                    headerCell('Qty'),
                    headerCell('Unit'),
                    headerCell('Unit Cost'),
                    headerCell('Total'),
                  ]),
                ...materialsList.map((m) {
                  final qty = (m['quantity'] as num?)?.toDouble() ?? 0;
                  final unitCost = (m['unit_cost'] as num?)?.toDouble() ?? 0;
                  final lineTotal = (m['line_total'] as num?)?.toDouble() ?? 0;
                  return pw.TableRow(children: [
                    dataCell(m['name']?.toString() ?? ''),
                    dataCell('$qty'),
                    dataCell(m['unit']?.toString() ?? 'kg'),
                    dataCell('R ${unitCost.toStringAsFixed(2)}',
                      align: pw.TextAlign.right),
                    dataCell('R ${lineTotal.toStringAsFixed(2)}',
                      align: pw.TextAlign.right),
                  ]);
                }),
              ],
            ),
            pw.SizedBox(height: 10),
          ],

          // ══ PROCESSING INSTRUCTIONS ══
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 0.5),
              borderRadius: pw.BorderRadius.circular(3)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('PROCESSING INSTRUCTIONS',
                  style: pw.TextStyle(
                    fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                if ((job['processing_instructions'] ?? '').toString().isNotEmpty)
                  pw.Text(job['processing_instructions'] ?? '',
                    style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 8),
                // Checkboxes 2 columns
                pw.Row(children: [
                  pw.Expanded(child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _pdfCheckbox('Skin', processingOpts['skin'] == true),
                      _pdfCheckbox('Remove Head', processingOpts['remove_head'] == true),
                      _pdfCheckbox('Remove Feet', processingOpts['remove_feet'] == true),
                      _pdfCheckbox('Halaal', processingOpts['halaal'] == true),
                    ],
                  )),
                  pw.Expanded(child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _pdfCheckbox('Kosher', processingOpts['kosher'] == true),
                      _pdfCheckbox('Split Carcass', processingOpts['split'] == true),
                      _pdfCheckbox('Quarter', processingOpts['quarter'] == true),
                      _pdfCheckbox('Whole', processingOpts['whole'] == true),
                    ],
                  )),
                ]),
              ],
            ),
          ),

          pw.SizedBox(height: 10),

          // ══ TOTALS ══
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 220,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.5),
                  borderRadius: pw.BorderRadius.circular(3)),
                child: pw.Column(children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Services Total:',
                        style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('R ${servicesTotal.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 9)),
                    ]),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Materials Total:',
                        style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('R ${materialsTotal.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 9)),
                    ]),
                  pw.Divider(thickness: 0.5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('TOTAL CHARGE:',
                        style: pw.TextStyle(
                          fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text('R ${grandTotal.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ]),
                ]),
              ),
            ],
          ),

          pw.Spacer(),

          // ══ FOOTER ══
          pw.Divider(thickness: 0.5),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            pw.Expanded(child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Authorized by: ________________________________',
                  style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 4),
                pw.Text('Date: ________________',
                  style: const pw.TextStyle(fontSize: 9)),
              ],
            )),
            pw.Expanded(child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Customer signature: ___________________________',
                  style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 4),
                pw.Text('Date: ________________',
                  style: const pw.TextStyle(fontSize: 9)),
              ],
            )),
          ]),
        ],
      ),
    ));

    // Save to Downloads
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final fileName = 'job_card_${jobRef}_$dateStr.pdf';
    final bytes = await pdf.save();

    final dir = await getDownloadsDirectory();
    final filePath = '${dir!.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Job card saved: $filePath')));
    }
  }

  // Helper for checkbox display in PDF
  pw.Widget _pdfCheckbox(String label, bool checked) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(children: [
        pw.Container(
          width: 10, height: 10,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 0.5),
            color: checked ? PdfColors.grey800 : PdfColors.white),
          child: checked
            ? pw.Center(child: pw.Text('✓',
                style: const pw.TextStyle(
                  fontSize: 7, color: PdfColors.white)))
            : null,
        ),
        pw.SizedBox(width: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
      ]),
    );
  }

  Future<void> _sendWhatsApp() async {
    final job = _currentJob ?? widget.job;
    final phone = (job['contact_phone'] ?? job['client_contact'])?.toString()?.replaceAll(RegExp(r'[^\d+]'), '') ?? '';
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No phone number for hunter.')));
      return;
    }
    final name = job['hunter_name'] ?? job['client_name'] ?? 'there';
    final species = (job['hunter_services'] is Map ? (job['hunter_services'] as Map)['name'] : null) ?? 'order';
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
      final job = _currentJob ?? widget.job;
      final jobNumber = hunterJobDisplayNumber(job['id']?.toString());
      final hunterName = job['hunter_name'] ?? job['client_name'] ?? 'Unknown';
      final oldStatus = job['status'];
      
      await _client.from('hunter_jobs').update({'status': 'completed'}).eq('id', widget.job['id']);
      
      // Audit log - status change
      await AuditService.log(
        action: 'UPDATE',
        module: 'Hunter',
        description: 'Hunter job status changed: $oldStatus → completed for $hunterName - Job #$jobNumber',
        entityType: 'HunterJob',
        entityId: widget.job['id'],
      );
      
      await _reloadJob(); // Reload after update
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
    final job = _currentJob ?? widget.job;
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
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
                onPressed: _isLoading ? null : _printJobCard,
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
