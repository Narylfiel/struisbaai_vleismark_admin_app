import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/audit_service.dart';

/// M7: PTY Conversion checklist — 8 steps, status, upload, notes; stored in business_settings.
class PtyConversionScreen extends StatefulWidget {
  const PtyConversionScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<PtyConversionScreen> createState() => _PtyConversionScreenState();
}

class _PtyConversionScreenState extends State<PtyConversionScreen> {
  final _client = SupabaseService.client;
  static const _steps = [
    _StepDef('cipc_registration', 'CIPC Registration'),
    _StepDef('sars_vat_transfer', 'SARS VAT Transfer'),
    _StepDef('new_bank_account', 'New Bank Account'),
    _StepDef('staff_contracts', 'Staff Contracts'),
    _StepDef('supplier_agreements', 'Supplier Agreements'),
    _StepDef('customer_agreements', 'Customer Agreements'),
    _StepDef('insurance_update', 'Insurance Update'),
    _StepDef('lease_transfer', 'Lease Transfer'),
  ];

  Map<String, Map<String, dynamic>> _stepData = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final row = await _client
          .from('business_settings')
          .select('setting_value')
          .eq('setting_key', 'pty_conversion_steps')
          .maybeSingle();
      if (mounted && row != null && row['setting_value'] != null) {
        final v = row['setting_value'];
        if (v is Map) {
          final map = Map<String, dynamic>.from(v as Map);
          final stepData = <String, Map<String, dynamic>>{};
          for (final s in _steps) {
            stepData[s.slug] = Map<String, dynamic>.from(Map<String, dynamic>.from(map[s.slug] as Map? ?? {}));
          }
          setState(() {
            _stepData = stepData;
            _loading = false;
          });
          return;
        }
      }
      if (mounted) {
        setState(() {
          for (final s in _steps) {
            _stepData[s.slug] = {'status': 'not_started', 'notes': '', 'file_path': null};
          }
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    try {
      await _client.from('business_settings').upsert(
        {'setting_key': 'pty_conversion_steps', 'setting_value': _stepData},
        onConflict: 'setting_key',
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error));
    }
  }

  void _cycleStatus(String slug) {
    final d = _stepData[slug] ?? {'status': 'not_started', 'notes': '', 'file_path': null};
    final current = d['status'] as String? ?? 'not_started';
    final next = current == 'not_started'
        ? 'in_progress'
        : current == 'in_progress'
            ? 'complete'
            : 'not_started';
    setState(() {
      _stepData[slug] = {...d, 'status': next};
    });
    try {
      final stepTitle = _steps
          .firstWhere((s) => s.slug == slug,
              orElse: () => const _StepDef('', 'Unknown step'))
          .title;
      AuditService.log(
        action: 'UPDATE',
        module: 'Bookkeeping',
        description: 'PTY step status changed: $stepTitle → $next',
        entityType: 'PtyConversion',
        entityId: slug,
        oldValues: {'status': current},
        newValues: {'status': next},
      );
    } catch (_) {}
    _save();
  }

  Future<void> _uploadFile(String slug) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null || result.files.isEmpty || result.files.single.bytes == null) return;
    final file = result.files.single;
    final bytes = file.bytes!;
    final path = 'pty/$slug/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    setState(() => _loading = true);
    try {
      await _client.storage.from('documents').uploadBinary(path, bytes, fileOptions: FileOptions(upsert: true));
      final url = _client.storage.from('documents').getPublicUrl(path);
      setState(() {
        _stepData[slug] = {...?_stepData[slug], 'file_path': path, 'file_url': url};
        _loading = false;
      });
      try {
        final stepTitle = _steps
            .firstWhere((s) => s.slug == slug,
                orElse: () => const _StepDef('', 'Unknown step'))
            .title;
        AuditService.log(
          action: 'UPDATE',
          module: 'Bookkeeping',
          description: 'PTY document uploaded: $stepTitle — ${path.split('/').last}',
          entityType: 'PtyConversion',
          entityId: slug,
          newValues: {
            'file_path': path,
            'step': stepTitle,
          },
        );
      } catch (_) {}
      _save();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File uploaded'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error));
      }
    }
  }

  int get _completeCount => _steps.where((s) => (_stepData[s.slug]?['status'] ?? 'not_started') == 'complete').length;

  @override
  Widget build(BuildContext context) {
    if (_loading && _stepData.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    final complete = _completeCount;
    final progress = _steps.isEmpty ? 0.0 : (complete / _steps.length) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PTY Conversion Checklist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 10,
                  backgroundColor: AppColors.textLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 6),
              Text('$complete / ${_steps.length} complete (${progress.toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: _steps.map((s) {
              final d = _stepData[s.slug] ?? {'status': 'not_started', 'notes': '', 'file_path': null};
              final status = d['status'] as String? ?? 'not_started';
              final notes = d['notes'] as String? ?? '';
              final filePath = d['file_path'] as String?;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w600))),
                          Material(
                            color: status == 'complete'
                                ? AppColors.success.withValues(alpha: 0.2)
                                : status == 'in_progress'
                                    ? AppColors.warning.withValues(alpha: 0.2)
                                    : AppColors.textLight.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _cycleStatus(s.slug),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: Text(
                                  status == 'complete' ? 'Complete' : status == 'in_progress' ? 'In Progress' : 'Not Started',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: status == 'complete' ? AppColors.success : status == 'in_progress' ? AppColors.warning : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _uploadFile(s.slug),
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: Text(filePath != null ? 'Re-upload' : 'Upload'),
                          ),
                        ],
                      ),
                      if (filePath != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('File: ${filePath.split('/').last}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ),
                      const SizedBox(height: 8),
                      _NotesField(
                        notes: notes,
                        onChanged: (v) {
                          setState(() {
                            _stepData[s.slug] = {...d, 'notes': v};
                          });
                        },
                        onSave: _save,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Save all'),
          ),
        ),
      ],
    );
  }
}

class _StepDef {
  final String slug;
  final String title;
  const _StepDef(this.slug, this.title);
}

class _NotesField extends StatefulWidget {
  final String notes;
  final ValueChanged<String> onChanged;
  final VoidCallback onSave;

  const _NotesField({required this.notes, required this.onChanged, required this.onSave});

  @override
  State<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<_NotesField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.notes);
  }

  @override
  void didUpdateWidget(_NotesField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notes != widget.notes && _controller.text != widget.notes) {
      _controller.text = widget.notes;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(
        labelText: 'Notes',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      maxLines: 2,
      onChanged: widget.onChanged,
      onSubmitted: (_) => widget.onSave(),
    );
  }
}
