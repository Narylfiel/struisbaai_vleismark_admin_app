import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/features/reports/models/report_definition.dart';
import 'package:admin_app/features/reports/models/report_schedule.dart';
import 'package:admin_app/features/reports/services/report_schedule_repository.dart';

/// Full CRUD for [report_schedules] — replaces the read-only hub stub.
class ReportScheduleScreen extends StatefulWidget {
  const ReportScheduleScreen({super.key});

  @override
  State<ReportScheduleScreen> createState() => _ReportScheduleScreenState();
}

class _ReportScheduleScreenState extends State<ReportScheduleScreen> {
  final _repo = ReportScheduleRepository();
  List<ReportScheduleDb> _items = [];
  bool _loading = true;

  static const _dateRanges = [
    'today',
    'yesterday',
    'last_7_days',
    'last_30_days',
    'this_month',
    'last_month',
  ];

  static const _formats = ['pdf', 'csv', 'xlsx'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.getAll();
      if (mounted) setState(() => _items = list);
    } catch (e) {
      if (mounted) _snack('Failed to load schedules: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  String _describe(ReportScheduleDb s) {
    switch (s.scheduleType) {
      case ScheduleType.daily:
        return 'Daily at ${s.timeOfDay}';
      case ScheduleType.weekly:
        return '${_weekdayName(s.dayOfWeek ?? 1)} at ${s.timeOfDay}';
      case ScheduleType.monthly:
        return 'Day ${s.dayOfMonth ?? 1} of month at ${s.timeOfDay}';
    }
  }

  static String _weekdayName(int d) {
    const names = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[d.clamp(1, 7)];
  }

  Future<void> _toggleActive(ReportScheduleDb s) async {
    try {
      await _repo.update(s.copyWith(isActive: !s.isActive));
      await _load();
    } catch (e) {
      _snack('Update failed: $e');
    }
  }

  Future<void> _delete(ReportScheduleDb s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete schedule?'),
        content: Text('Remove "${s.label}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.delete(s.id);
      await _load();
    } catch (e) {
      _snack('Delete failed: $e');
    }
  }

  Future<void> _showEditor({ReportScheduleDb? existing}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ScheduleFormDialog(initial: existing),
    );
    if (saved == true) await _load();
  }

  Future<void> _showRuns(ReportScheduleDb s) async {
    try {
      final runs = await _repo.getRuns(s.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Run history — ${s.label}'),
          content: SizedBox(
            width: 520,
            height: 360,
            child: runs.isEmpty
                ? const Text('No runs yet.')
                : ListView.builder(
                    itemCount: runs.length,
                    itemBuilder: (_, i) {
                      final r = runs[i];
                      final st = r['status']?.toString() ?? '';
                      final color = _statusColor(st);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Row(
                            children: [
                              Chip(
                                label: Text(st, style: const TextStyle(fontSize: 11)),
                                backgroundColor: color.withValues(alpha: 0.2),
                              ),
                              const SizedBox(width: 8),
                              Text('rows: ${r['row_count'] ?? '—'}'),
                            ],
                          ),
                          subtitle: Text(
                            '${r['run_at']}\n${r['delivery_log'] ?? ''}${r['error_message'] != null ? '\n${r['error_message']}' : ''}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
        ),
      );
    } catch (e) {
      _snack('Failed to load runs: $e');
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'success':
        return AppColors.success;
      case 'error':
        return AppColors.error;
      case 'no_data':
        return AppColors.textSecondary;
      case 'not_implemented':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Report schedules'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _loading ? null : () => _showEditor(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _items.isEmpty
              ? const Center(
                  child: Text(
                    'No schedules yet. Tap + to add.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final s = _items[index];
                    final def = ReportDefinitions.byKey(s.reportKey);
                    return Card(
                      child: InkWell(
                        onTap: () => _showRuns(s),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      s.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    color: AppColors.primary,
                                    onPressed: () => _showEditor(existing: s),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    color: AppColors.error,
                                    onPressed: () => _delete(s),
                                  ),
                                ],
                              ),
                              Text(
                                def?.title ?? s.reportKey,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(_describe(s), style: const TextStyle(fontSize: 13)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                children: s.delivery
                                    .map(
                                      (d) => Chip(
                                        label: Text(
                                          d.name,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'Last: ${s.lastRunAt != null ? DateFormat.yMd().add_jm().format(s.lastRunAt!.toLocal()) : '—'}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Next: ${s.nextRunAt != null ? DateFormat.yMd().add_jm().format(s.nextRunAt!.toLocal()) : '—'}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  const Spacer(),
                                  const Text('Active', style: TextStyle(fontSize: 12)),
                                  Switch(
                                    value: s.isActive,
                                    activeThumbColor: AppColors.primary,
                                    onChanged: (_) => _toggleActive(s),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _ScheduleFormDialog extends StatefulWidget {
  final ReportScheduleDb? initial;

  const _ScheduleFormDialog({required this.initial});

  @override
  State<_ScheduleFormDialog> createState() => _ScheduleFormDialogState();
}

class _ScheduleFormDialogState extends State<_ScheduleFormDialog> {
  final _repo = ReportScheduleRepository();
  late String _reportKey;
  late TextEditingController _labelCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _emailCtrl;
  late ScheduleType _scheduleType;
  int? _dayOfWeek;
  int? _dayOfMonth;
  late Set<ScheduleDelivery> _delivery;
  late String _format;
  late String _dateRange;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    _reportKey = e?.reportKey ?? ReportDefinitions.all.first.key;
    _labelCtrl = TextEditingController(text: e?.label ?? '');
    _timeCtrl = TextEditingController(text: e?.timeOfDay ?? '06:00');
    _emailCtrl = TextEditingController(text: e?.emailTo ?? '');
    _scheduleType = e?.scheduleType ?? ScheduleType.daily;
    _dayOfWeek = e?.dayOfWeek ?? 1;
    _dayOfMonth = e?.dayOfMonth ?? 1;
    _delivery = e != null ? e.delivery.toSet() : {ScheduleDelivery.dashboard};
    _format = e?.format ?? 'pdf';
    _dateRange = e?.dateRange ?? 'last_7_days';
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _timeCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  bool _timeOk(String t) => RegExp(r'^\d{1,2}:\d{2}$').hasMatch(t);

  Future<void> _save() async {
    if (_labelCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Label is required'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (!_timeOk(_timeCtrl.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Time must be HH:MM (UTC)'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_delivery.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one delivery channel'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final id = widget.initial?.id ?? '';
    final schedule = ReportScheduleDb(
      id: id,
      reportKey: _reportKey,
      label: _labelCtrl.text.trim(),
      scheduleType: _scheduleType,
      timeOfDay: _timeCtrl.text.trim(),
      dayOfWeek: _scheduleType == ScheduleType.weekly ? _dayOfWeek : null,
      dayOfMonth: _scheduleType == ScheduleType.monthly ? _dayOfMonth : null,
      delivery: _delivery.toList(),
      emailTo: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      format: _format,
      dateRange: _dateRange,
      isActive: _isActive,
      lastRunAt: widget.initial?.lastRunAt,
      nextRunAt: widget.initial?.nextRunAt,
      createdAt: widget.initial?.createdAt ?? DateTime.now().toUtc(),
    );

    try {
      if (id.isEmpty) {
        await _repo.create(schedule);
      } else {
        await _repo.update(schedule);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add schedule' : 'Edit schedule'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _reportKey,
                  decoration: const InputDecoration(labelText: 'Report'),
                  items: ReportDefinitions.all
                      .map(
                        (d) => DropdownMenuItem(value: d.key, child: Text(d.title)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _reportKey = v ?? _reportKey),
                ),
                TextFormField(
                  controller: _labelCtrl,
                  decoration: const InputDecoration(labelText: 'Label'),
                ),
                DropdownButtonFormField<ScheduleType>(
                  initialValue: _scheduleType,
                  decoration: const InputDecoration(labelText: 'Schedule type'),
                  items: const [
                    DropdownMenuItem(value: ScheduleType.daily, child: Text('Daily')),
                    DropdownMenuItem(value: ScheduleType.weekly, child: Text('Weekly')),
                    DropdownMenuItem(value: ScheduleType.monthly, child: Text('Monthly')),
                  ],
                  onChanged: (v) => setState(() => _scheduleType = v ?? ScheduleType.daily),
                ),
                TextFormField(
                  controller: _timeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Time (HH:MM UTC)',
                    hintText: '06:00',
                  ),
                ),
                if (_scheduleType == ScheduleType.weekly)
                  DropdownButtonFormField<int>(
                    initialValue: _dayOfWeek,
                    decoration: const InputDecoration(labelText: 'Day of week (1=Mon)'),
                    items: List.generate(
                      7,
                      (i) => DropdownMenuItem(value: i + 1, child: Text(_ReportScheduleScreenState._weekdayName(i + 1))),
                    ),
                    onChanged: (v) => setState(() => _dayOfWeek = v),
                  ),
                if (_scheduleType == ScheduleType.monthly)
                  DropdownButtonFormField<int>(
                    initialValue: _dayOfMonth,
                    decoration: const InputDecoration(labelText: 'Day of month (1–28)'),
                    items: List.generate(
                      28,
                      (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                    ),
                    onChanged: (v) => setState(() => _dayOfMonth = v),
                  ),
                const Text('Delivery', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                CheckboxListTile(
                  value: _delivery.contains(ScheduleDelivery.dashboard),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _delivery.add(ScheduleDelivery.dashboard);
                    } else {
                      _delivery.remove(ScheduleDelivery.dashboard);
                    }
                  }),
                  title: const Text('dashboard'),
                  dense: true,
                ),
                CheckboxListTile(
                  value: _delivery.contains(ScheduleDelivery.email),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _delivery.add(ScheduleDelivery.email);
                    } else {
                      _delivery.remove(ScheduleDelivery.email);
                    }
                  }),
                  title: const Text('email'),
                  dense: true,
                ),
                CheckboxListTile(
                  value: _delivery.contains(ScheduleDelivery.googleDrive),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _delivery.add(ScheduleDelivery.googleDrive);
                    } else {
                      _delivery.remove(ScheduleDelivery.googleDrive);
                    }
                  }),
                  title: const Text('googleDrive (Phase 2: not sent)'),
                  dense: true,
                ),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email override (optional)'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _format,
                  decoration: const InputDecoration(labelText: 'Format'),
                  items: _ReportScheduleScreenState._formats
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => setState(() => _format = v ?? 'pdf'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _dateRange,
                  decoration: const InputDecoration(labelText: 'Date range'),
                  items: _ReportScheduleScreenState._dateRanges
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => setState(() => _dateRange = v ?? 'last_7_days'),
                ),
                SwitchListTile(
                  title: const Text('Active'),
                  value: _isActive,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
            ),
          ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
