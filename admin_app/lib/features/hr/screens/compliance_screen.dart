import 'dart:io';
import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// H4: BCEA Compliance — grid of staff × document types, cell status (Valid/Expiring/Expired/—), tap to edit, PDF export.
class ComplianceScreen extends StatefulWidget {
  const ComplianceScreen({super.key});

  @override
  State<ComplianceScreen> createState() => _ComplianceScreenState();
}

/// Document type slug and display label
class _DocType {
  final String slug;
  final String label;
  const _DocType(this.slug, this.label);
}

const List<_DocType> _documentTypes = [
  _DocType('id_document', 'ID Document'),
  _DocType('work_permit', 'Work Permit'),
  _DocType('health_certificate', 'Health Certificate'),
  _DocType('food_handler_certificate', 'Food Handler Certificate'),
  _DocType('drivers_license', "Driver's License"),
  _DocType('employment_contract', 'Employment Contract'),
  _DocType('tax_certificate_irp5', 'Tax Certificate (IRP5)'),
];

enum _Filter { all, expiringSoon, expiredMissing }

class _ComplianceScreenState extends State<ComplianceScreen> {
  final _client = SupabaseService.client;

  List<Map<String, dynamic>> _staffList = [];
  List<Map<String, dynamic>> _records = [];
  String? _businessName;
  bool _loading = true;
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final staffData = await _client
          .from('staff_profiles')
          .select('id, full_name')
          .eq('is_active', true)
          .order('full_name');
      final recordsData = await _client.from('compliance_records').select('*');
      String? biz = _businessName;
      try {
        final settings = await _client.from('business_settings').select('setting_value').eq('setting_key', 'business_name').maybeSingle();
        if (settings != null && settings['setting_value'] != null) {
          final v = settings['setting_value'];
          biz = v is String ? v : v.toString();
        }
      } catch (_) {}
      if (mounted) {
        setState(() {
          _staffList = List<Map<String, dynamic>>.from(staffData);
          _records = List<Map<String, dynamic>>.from(recordsData);
          _businessName = biz;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic>? _getRecord(String staffId, String documentType) {
    try {
      return _records.firstWhere(
        (r) => (r['staff_id']?.toString() == staffId && r['document_type']?.toString() == documentType),
      );
    } catch (_) {
      return null;
    }
  }

  static String _statusLabel(DateTime? expiry) {
    if (expiry == null) return '—';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(expiry.year, expiry.month, expiry.day);
    final days30 = today.add(const Duration(days: 30));
    if (exp.isAfter(days30)) return 'Valid';
    if (exp.isAfter(today) || exp.isAtSameMomentAs(today)) return 'Expiring';
    return 'Expired';
  }

  static Color _statusColor(DateTime? expiry) {
    if (expiry == null) return AppColors.textLight;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(expiry.year, expiry.month, expiry.day);
    final days30 = today.add(const Duration(days: 30));
    if (exp.isAfter(days30)) return AppColors.success;
    if (exp.isAfter(today) || exp.isAtSameMomentAs(today)) return Colors.orange;
    return AppColors.error;
  }

  bool _showCell(String staffId, String documentType) {
    final rec = _getRecord(staffId, documentType);
    DateTime? exp;
    if (rec != null && rec['expiry_date'] != null) exp = DateTime.tryParse(rec['expiry_date'].toString().substring(0, 10));
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final today30 = today.add(const Duration(days: 30));
    switch (_filter) {
      case _Filter.all:
        return true;
      case _Filter.expiringSoon:
        return exp != null && !exp.isBefore(today) && !exp.isAfter(today30);
      case _Filter.expiredMissing:
        return exp == null || exp.isBefore(today);
      default:
        return true;
    }
  }

  List<Map<String, dynamic>> get _filteredStaff {
    if (_filter == _Filter.all) return _staffList;
    final show = <String>{};
    for (final doc in _documentTypes) {
      for (final s in _staffList) {
        final sid = s['id']?.toString();
        if (sid != null && _showCell(sid, doc.slug)) show.add(sid);
      }
    }
    return _staffList.where((s) => show.contains(s['id']?.toString())).toList();
  }

  Future<void> _exportPdf() async {
    final pdf = pw.Document();
    final staffCols = _filteredStaff;
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Text(_businessName ?? 'Business', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('BCEA Compliance — Document status', style: pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: {
              for (int i = 0; i < 1 + staffCols.length; i++) i: pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Document type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  ...staffCols.map((s) => pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text((s['full_name'] ?? '').toString(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      )),
                ],
              ),
              ..._documentTypes.map((doc) {
                return pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(doc.label, style: const pw.TextStyle(fontSize: 8))),
                    ...staffCols.map((s) {
                      final sid = s['id']?.toString();
                      final rec = sid != null ? _getRecord(sid, doc.slug) : null;
                      DateTime? exp;
                      if (rec != null && rec['expiry_date'] != null) exp = DateTime.tryParse(rec['expiry_date'].toString().substring(0, 10));
                      final label = _statusLabel(exp);
                      return pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(label, style: pw.TextStyle(fontSize: 8, color: exp == null ? PdfColors.grey : (label == 'Valid' ? PdfColors.green : (label == 'Expiring' ? PdfColors.orange : PdfColors.red)))),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text('Generated: ${DateTime.now().toIso8601String().substring(0, 19)}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final staffCols = _filteredStaff;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Show All'),
                      selected: _filter == _Filter.all,
                      onSelected: (_) => setState(() => _filter = _Filter.all),
                      selectedColor: AppColors.primary.withOpacity(0.3),
                    ),
                    ChoiceChip(
                      label: const Text('Expiring Soon (≤30d)'),
                      selected: _filter == _Filter.expiringSoon,
                      onSelected: (_) => setState(() => _filter = _Filter.expiringSoon),
                      selectedColor: AppColors.primary.withOpacity(0.3),
                    ),
                    ChoiceChip(
                      label: const Text('Expired / Missing'),
                      selected: _filter == _Filter.expiredMissing,
                      onSelected: (_) => setState(() => _filter = _Filter.expiredMissing),
                      selectedColor: AppColors.primary.withOpacity(0.3),
                    ),
                  ],
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _exportPdf,
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('Export PDF'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _staffList.isEmpty
                    ? const Center(child: Text('No active staff'))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          const rowH = 44.0;
                          const colW = 120.0;
                          const cornerW = 180.0;
                          return SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(width: cornerW, height: rowH, child: const ColoredBox(color: AppColors.surfaceBg, child: Center(child: Text('Document type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))))),
                                      ...staffCols.map((s) => SizedBox(
                                            width: colW,
                                            height: rowH,
                                            child: ColoredBox(
                                              color: AppColors.surfaceBg,
                                              child: Center(child: Text((s['full_name'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis)),
                                            ),
                                          )),
                                    ],
                                  ),
                                  ..._documentTypes.map((doc) {
                                        return Row(
                                          children: [
                                            SizedBox(
                                              width: cornerW,
                                              height: rowH,
                                              child: ColoredBox(
                                                color: AppColors.surfaceBg,
                                                child: Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(left: 8),
                                                    child: Text(doc.label, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            ...staffCols.map((s) {
                                              final sid = s['id']?.toString();
                                              if (sid == null) return SizedBox(width: colW, height: rowH, child: const ColoredBox(color: Colors.transparent));
                                              final rec = _getRecord(sid, doc.slug);
                                              DateTime? exp;
                                              if (rec != null && rec['expiry_date'] != null) exp = DateTime.tryParse(rec['expiry_date'].toString().substring(0, 10));
                                              final label = _statusLabel(exp);
                                              final color = _statusColor(exp);
                                              return SizedBox(
                                                width: colW,
                                                height: rowH,
                                                child: InkWell(
                                                  onTap: () => _openDetail(sid, s['full_name']?.toString() ?? '', doc.slug, doc.label, rec),
                                                  child: ColoredBox(
                                                    color: color.withOpacity(0.15),
                                                    child: Center(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color))),
                                                  ),
                                                ),
                                              );
                                            }),
                                          ],
                                        );
                                      }),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _openDetail(String staffId, String staffName, String documentTypeSlug, String documentTypeLabel, Map<String, dynamic>? record) {
    showDialog(
      context: context,
      builder: (ctx) => _DocumentDetailDialog(
        staffId: staffId,
        staffName: staffName,
        documentType: documentTypeSlug,
        documentTypeLabel: documentTypeLabel,
        record: record,
        onSaved: () { Navigator.pop(ctx); _load(); },
      ),
    );
  }
}

class _DocumentDetailDialog extends StatefulWidget {
  final String staffId;
  final String staffName;
  final String documentType;
  final String documentTypeLabel;
  final Map<String, dynamic>? record;
  final VoidCallback onSaved;

  const _DocumentDetailDialog({
    required this.staffId,
    required this.staffName,
    required this.documentType,
    required this.documentTypeLabel,
    this.record,
    required this.onSaved,
  });

  @override
  State<_DocumentDetailDialog> createState() => _DocumentDetailDialogState();
}

class _DocumentDetailDialogState extends State<_DocumentDetailDialog> {
  final _client = SupabaseService.client;
  final _notesCtrl = TextEditingController();
  DateTime? _expiryDate;
  String? _fileUrl;
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      _expiryDate = widget.record!['expiry_date'] != null ? DateTime.tryParse(widget.record!['expiry_date'].toString().substring(0, 10)) : null;
      _fileUrl = widget.record!['file_url']?.toString();
      _notesCtrl.text = widget.record!['notes']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.path == null || file.name.isEmpty) return;
    setState(() => _uploading = true);
    try {
      final path = '${widget.staffId}/${widget.documentType}/${file.name}';
      await _client.storage.from('documents').upload(path, File(file.path!), fileOptions: const FileOptions(upsert: true));
      setState(() { _fileUrl = path; _uploading = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File uploaded')));
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.friendlyMessage(e))));
      }
    }
  }

  Future<void> _viewFile() async {
    if (_fileUrl == null || _fileUrl!.isEmpty) return;
    try {
      final signed = await _client.storage.from('documents').createSignedUrl(_fileUrl!, 3600);
      final uri = Uri.parse(signed);
      if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open file: $e')));
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final payload = {
        'staff_id': widget.staffId,
        'document_type': widget.documentType,
        'expiry_date': _expiryDate?.toIso8601String().substring(0, 10),
        'file_url': _fileUrl,
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      await _client.from('compliance_records').upsert(payload, onConflict: 'staff_id,document_type');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved'), backgroundColor: AppColors.success));
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.friendlyMessage(e))));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.documentTypeLabel} — ${widget.staffName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Document type: ${widget.documentTypeLabel}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Expiry date: ${_expiryDate?.toIso8601String().substring(0, 10) ?? '—'}'),
            const SizedBox(height: 8),
            if (_fileUrl != null && _fileUrl!.isNotEmpty) ...[
              InkWell(
                onTap: _viewFile,
                child: const Text('View File', style: TextStyle(color: AppColors.primary, decoration: TextDecoration.underline)),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _uploading ? null : _pickAndUpload,
              icon: _uploading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.upload_file, size: 18),
              label: Text(_uploading ? 'Uploading...' : 'Upload file'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Expiry date'),
              subtitle: Text(_expiryDate?.toIso8601String().substring(0, 10) ?? 'Not set'),
              trailing: TextButton(
                onPressed: () async {
                  final d = await showDatePicker(context: context, initialDate: _expiryDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (d != null && mounted) setState(() => _expiryDate = d);
                },
                child: const Text('Pick date'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
              maxLines: 2,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
        ),
      ],
    );
  }
}

