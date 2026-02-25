import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../models/supplier.dart';
import '../services/supplier_repository.dart';
import 'supplier_form_screen.dart';

/// Blueprint §4.6: Supplier Management — list suppliers, Add/Edit/Delete.
class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  final _repo = SupplierRepository();
  final _export = ExportService();
  final _client = SupabaseService.client;
  List<Supplier> _suppliers = [];
  bool _loading = true;
  bool _exporting = false;
  String? _error;

  static const _csvColumns = ['name', 'contact_name', 'phone', 'email', 'account_number', 'notes'];

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.getSuppliers();
      if (mounted) {
        setState(() {
          _suppliers = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _navigateToForm({Supplier? supplier}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierFormScreen(supplier: supplier),
      ),
    ).then((result) {
      if (result == true) _load();
    });
  }

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      final rows = await _client
          .from('suppliers')
          .select('id, name, contact_name, phone, email, account_number, notes')
          .order('name');
      final list = List<Map<String, dynamic>>.from(rows as List);
      final data = list.map((r) => {
        'name': r['name']?.toString() ?? '',
        'contact_name': (r['contact_name'] ?? r['contact_person'])?.toString() ?? '',
        'phone': r['phone']?.toString() ?? '',
        'email': r['email']?.toString() ?? '',
        'account_number': r['account_number']?.toString() ?? '',
        'notes': r['notes']?.toString() ?? '',
      }).toList();
      final file = await _export.exportToCsv(
        fileName: 'suppliers_export',
        data: data,
        columns: _csvColumns,
      );
      if (mounted) {
        await Share.shareXFiles([XFile(file.path)], text: 'Suppliers export');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported ${data.length} suppliers'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _exporting = false);
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || result.files.single.bytes == null || !mounted) return;
    final bytes = result.files.single.bytes!;
    String content;
    try {
      content = String.fromCharCodes(bytes);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read file'), backgroundColor: AppColors.error),
        );
      }
      return;
    }
    List<Map<String, String>> parsed;
    try {
      final rows = const CsvToListConverter().convert(content);
      if (rows.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File is empty'), backgroundColor: AppColors.warning),
        );
        return;
      }
      final headerRow = rows.first.map((c) => (c as String).trim().toLowerCase()).toList();
      final nameIdx = _indexOfHeader(headerRow, 'name');
      final contactIdx = _indexOfHeader(headerRow, 'contact_name');
      final phoneIdx = _indexOfHeader(headerRow, 'phone');
      final emailIdx = _indexOfHeader(headerRow, 'email');
      final accountIdx = _indexOfHeader(headerRow, 'account_number');
      final notesIdx = _indexOfHeader(headerRow, 'notes');
      parsed = [];
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i] as List;
        parsed.add({
          'name': nameIdx >= 0 && nameIdx < row.length ? (row[nameIdx] as String?)?.trim() ?? '' : '',
          'contact_name': contactIdx >= 0 && contactIdx < row.length ? (row[contactIdx] as String?)?.trim() ?? '' : '',
          'phone': phoneIdx >= 0 && phoneIdx < row.length ? (row[phoneIdx] as String?)?.trim() ?? '' : '',
          'email': emailIdx >= 0 && emailIdx < row.length ? (row[emailIdx] as String?)?.trim() ?? '' : '',
          'account_number': accountIdx >= 0 && accountIdx < row.length ? (row[accountIdx] as String?)?.trim() ?? '' : '',
          'notes': notesIdx >= 0 && notesIdx < row.length ? (row[notesIdx] as String?)?.trim() ?? '' : '',
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid CSV: $e'), backgroundColor: AppColors.error),
        );
      }
      return;
    }
    if (!mounted) return;
    final skipped = parsed.where((r) => (r['name'] ?? '').trim().isEmpty).length;
    await showDialog<void>(
      context: context,
      builder: (ctx) => _ImportPreviewDialog(
        rows: parsed,
        skippedCount: skipped,
        onConfirm: () async {
          Navigator.pop(ctx);
          await _applyImport(parsed);
        },
      ),
    );
  }

  int _indexOfHeader(List<String> header, String name) {
    final lower = name.toLowerCase();
    for (var i = 0; i < header.length; i++) {
      if (header[i] == lower) return i;
    }
    return -1;
  }

  Future<void> _applyImport(List<Map<String, String>> rows) async {
    int imported = 0, updated = 0, skipped = 0;
    setState(() => _loading = true);
    try {
      final existing = await _client.from('suppliers').select('id, name').order('name');
      final existingList = List<Map<String, dynamic>>.from(existing as List);
      final nameToId = <String, String>{};
      for (final e in existingList) {
        final name = (e['name'] as String?)?.trim() ?? '';
        if (name.isNotEmpty) nameToId[name.toLowerCase()] = e['id'] as String;
      }
      for (final r in rows) {
        final name = (r['name'] ?? '').trim();
        if (name.isEmpty) {
          skipped++;
          continue;
        }
        final contactName = (r['contact_name'] ?? '').trim();
        final phone = (r['phone'] ?? '').trim();
        final email = (r['email'] ?? '').trim();
        final accountNumber = (r['account_number'] ?? '').trim();
        final notes = (r['notes'] ?? '').trim();
        final id = nameToId[name.toLowerCase()];
        if (id != null) {
          await _client.from('suppliers').update({
            'contact_name': contactName.isEmpty ? null : contactName,
            'phone': phone.isEmpty ? null : phone,
            'email': email.isEmpty ? null : email,
            'account_number': accountNumber.isEmpty ? null : accountNumber,
            'notes': notes.isEmpty ? null : notes,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', id);
          updated++;
          nameToId[name.toLowerCase()] = id;
        } else {
          await _client.from('suppliers').insert({
            'name': name,
            'contact_name': contactName.isEmpty ? null : contactName,
            'phone': phone.isEmpty ? null : phone,
            'email': email.isEmpty ? null : email,
            'account_number': accountNumber.isEmpty ? null : accountNumber,
            'notes': notes.isEmpty ? null : notes,
            'is_active': true,
          });
          imported++;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$imported imported, $updated updated, $skipped skipped (missing name)'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e'), backgroundColor: AppColors.error),
        );
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _confirmDelete(Supplier supplier) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete supplier?'),
        content: Text('Delete "${supplier.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _repo.deleteSupplier(supplier.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              'Error loading suppliers',
              style: const TextStyle(color: AppColors.danger, fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_suppliers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_shipping, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Suppliers',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add suppliers (e.g. Karan Beef). Link them to products in the product form.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _exporting ? null : _importCsv,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import CSV'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _exporting ? null : _exportCsv,
                  icon: _exporting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download),
                  label: const Text('Export CSV'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _navigateToForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add supplier'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: _exporting ? null : _importCsv,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Import CSV'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _exporting ? null : _exportCsv,
                icon: _exporting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download, size: 18),
                label: const Text('Export CSV'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
              ),
              const SizedBox(width: 16),
              const Expanded(child: SizedBox()),
              ElevatedButton.icon(
                onPressed: () => _navigateToForm(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add supplier'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Contact')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Payment terms')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _suppliers.map((s) {
                  return DataRow(
                    cells: [
                      DataCell(Text(s.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Text(s.contactPerson ?? '—', style: const TextStyle(fontSize: 12))),
                      DataCell(Text(s.phone ?? '—', style: const TextStyle(fontSize: 12))),
                      DataCell(Text(s.email ?? '—', style: const TextStyle(fontSize: 12))),
                      DataCell(Text(s.paymentTerms ?? '—', style: const TextStyle(fontSize: 12))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: s.isActive ? AppColors.success : AppColors.danger,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            s.isActive ? 'Active' : 'Inactive',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      DataCell(
                        ActionButtonsWidget(
                          actions: [
                            ActionButtons.edit(onPressed: () => _navigateToForm(supplier: s), iconOnly: true),
                            ActionButtons.delete(onPressed: () => _confirmDelete(s), iconOnly: true),
                          ],
                          compact: true,
                          spacing: 8,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImportPreviewDialog extends StatelessWidget {
  final List<Map<String, String>> rows;
  final int skippedCount;
  final VoidCallback onConfirm;

  const _ImportPreviewDialog({
    required this.rows,
    required this.skippedCount,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final previewRows = rows.take(10).toList();
    return AlertDialog(
      title: const Text('Import suppliers — Preview'),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${rows.length} suppliers found in file.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (skippedCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '$skippedCount row(s) missing required field "name" (will be skipped).',
                    style: const TextStyle(color: AppColors.warning, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Contact')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Account #')),
                    DataColumn(label: Text('Notes')),
                  ],
                  rows: previewRows.map((r) {
                    final name = (r['name'] ?? '').trim();
                    final missingName = name.isEmpty;
                    return DataRow(
                      color: MaterialStateProperty.resolveWith((_) =>
                          missingName ? AppColors.warning.withValues(alpha: 0.15) : null),
                      cells: [
                        DataCell(Text(name.isEmpty ? '(missing)' : name,
                            style: TextStyle(
                              color: missingName ? AppColors.warning : null,
                              fontWeight: missingName ? FontWeight.w600 : null,
                            ))),
                        DataCell(Text((r['contact_name'] ?? '').trim().isEmpty ? '—' : (r['contact_name'] ?? '').trim())),
                        DataCell(Text((r['phone'] ?? '').trim().isEmpty ? '—' : (r['phone'] ?? '').trim())),
                        DataCell(Text((r['email'] ?? '').trim().isEmpty ? '—' : (r['email'] ?? '').trim())),
                        DataCell(Text((r['account_number'] ?? '').trim().isEmpty ? '—' : (r['account_number'] ?? '').trim())),
                        DataCell(Text((r['notes'] ?? '').trim().isEmpty ? '—' : (r['notes'] ?? '').trim(), maxLines: 2, overflow: TextOverflow.ellipsis)),
                      ],
                    );
                  }).toList(),
                ),
              ),
              if (rows.length > 10)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '... and ${rows.length - 10} more',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: const Text('Confirm import'),
        ),
      ],
    );
  }
}
