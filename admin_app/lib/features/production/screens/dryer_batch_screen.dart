import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../features/settings/services/settings_repository.dart';
import '../models/dryer_batch.dart';
import '../services/dryer_batch_repository.dart';

/// Blueprint §5.6: Dryer batches — Biltong/Droewors/Chilli Bites; weight loss tracking; deduct raw, add output.
class DryerBatchScreen extends StatefulWidget {
  const DryerBatchScreen({super.key});

  @override
  State<DryerBatchScreen> createState() => _DryerBatchScreenState();
}

class _DryerBatchScreenState extends State<DryerBatchScreen> {
  final _repo = DryerBatchRepository();
  final _client = SupabaseService.client;
  final _settingsRepo = SettingsRepository();
  List<DryerBatch> _batches = [];
  List<Map<String, dynamic>> _inventoryItems = [];
  bool _loading = true;
  String? _error;
  double _electricityRate = 2.5;
  Timer? _timer;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final batches = await _repo.getBatches();
      final inv = await _client
          .from('inventory_items')
          .select('id, name')
          .eq('is_active', true)
          .order('name');
      if (mounted) {
        setState(() {
          _batches = batches;
          _inventoryItems = List<Map<String, dynamic>>.from(inv as List);
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
    _loadElectricityRate();
    _load();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadElectricityRate() async {
    final rate = await _settingsRepo.getElectricityRate();
    if (mounted) setState(() => _electricityRate = rate);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _newBatch() {
    showDialog(
      context: context,
      builder: (ctx) => _NewDryerBatchDialog(
        repo: _repo,
        inventoryItems: _inventoryItems,
        onDone: () {
          Navigator.pop(ctx);
          _load();
        },
      ),
    ).then((_) => _load());
  }

  void _weighOut(DryerBatch batch) {
    if (batch.status != DryerBatchStatus.drying) return;
    showDialog(
      context: context,
      builder: (ctx) => _WeighOutDialog(
        batch: batch,
        repo: _repo,
        electricityRate: _electricityRate,
        kwhPerHourDefault: 2.5,
        onDone: () {
          Navigator.pop(ctx);
          _load();
        },
      ),
    ).then((_) => _load());
  }

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h}h ${m}m';
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
            Text(_error!, style: const TextStyle(color: AppColors.danger), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
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
              const Expanded(child: SizedBox()),
              ElevatedButton.icon(
                onPressed: _newBatch,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New dryer batch'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _batches.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.ac_unit, size: 64, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      const Text(
                        'Dryer batches',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Biltong, Droewors, Chilli Bites — Load dryer → track drying → Weigh out (deduct raw, add output)',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _newBatch,
                        icon: const Icon(Icons.add),
                        label: const Text('New dryer batch'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _batches.length,
                  itemBuilder: (context, i) {
                    final b = _batches[i];
                    return _DryerBatchCard(
                      batch: b,
                      electricityRate: _electricityRate,
                      onWeighOut: () => _weighOut(b),
                      onTap: () => _showBatchDetail(b),
                      onLongPress: () => _confirmDeleteDryerBatch(b),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showBatchDetail(DryerBatch b) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => _DryerBatchDetailPanel(
          batch: b,
          electricityRate: _electricityRate,
          scrollController: scrollController,
          onDelete: () {
            Navigator.pop(ctx);
            _confirmDeleteDryerBatch(b);
          },
        ),
      ),
    );
  }

  Future<void> _confirmDeleteDryerBatch(DryerBatch batch) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete batch?'),
        content: Text('Delete batch ${batch.batchNumber}? This cannot be undone.'),
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
    if (confirm != true || !mounted) return;
    try {
      await _repo.deleteBatch(batch.id);
      if (mounted) {
        setState(() => _batches.removeWhere((b) => b.id == batch.id));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    }
  }
}

class _DryerBatchCard extends StatelessWidget {
  final DryerBatch batch;
  final double electricityRate;
  final VoidCallback onWeighOut;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _DryerBatchCard({
    required this.batch,
    required this.electricityRate,
    required this.onWeighOut,
    required this.onTap,
    this.onLongPress,
  });

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final canWeighOut = batch.status == DryerBatchStatus.drying;
    final loadedAt = batch.loadedAt ?? batch.startedAt ?? batch.createdAt;
    final elapsed = loadedAt != null ? DateTime.now().difference(loadedAt) : Duration.zero;
    final elapsedHours = elapsed.inMinutes / 60.0;
    final plannedHours = batch.plannedHours ?? 0.0;
    final progress = plannedHours > 0 ? (elapsedHours / plannedHours).clamp(0.0, 1.0) : 0.0;
    final isOverdue = plannedHours > 0 && elapsedHours > plannedHours;
    final overdueDuration = isOverdue
        ? Duration(minutes: ((elapsedHours - plannedHours) * 60).round())
        : Duration.zero;

    String subtitle;
    Widget? extraLine;
    if (batch.status == DryerBatchStatus.drying) {
      final plannedStr = plannedHours > 0 ? ' / ${plannedHours.toStringAsFixed(0)}h planned' : '';
      subtitle = 'In dryer: ${_formatDuration(elapsed)}$plannedStr | Est. shrinkage: --%';
      if (plannedHours > 0) {
        extraLine = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverdue ? AppColors.warning : AppColors.primary,
              ),
            ),
            if (isOverdue) ...[
              const SizedBox(height: 4),
              Text(
                '⚠ Overdue by ${_formatDuration(overdueDuration)}',
                style: const TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w500),
              ),
            ],
          ],
        );
      }
    } else {
      final shrinkage = batch.shrinkagePct;
      final shrinkageStr = shrinkage != null
          ? 'Shrinkage: ${shrinkage.toStringAsFixed(1)}% (${(batch.inputWeightKg - (batch.outputWeightKg ?? 0)).toStringAsFixed(1)} kg lost)'
          : '—';
      final hours = batch.dryingHours ?? 0.0;
      final kwh = hours * (batch.kwhPerHour ?? 2.5);
      final cost = batch.electricityCost ?? 0.0;
      final costPerKg = (batch.outputWeightKg != null && batch.outputWeightKg! > 0)
          ? (cost / batch.outputWeightKg!)
          : 0.0;
      subtitle = 'Dried: ${batch.dryingHours != null ? _formatDuration(Duration(minutes: (batch.dryingHours! * 60).round())) : "—"} | '
          '$shrinkageStr | Electricity: ${kwh.toStringAsFixed(1)} kWh = R${cost.toStringAsFixed(2)} | Cost per kg: R${costPerKg.toStringAsFixed(2)}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      batch.batchNumber,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (canWeighOut)
                    TextButton(
                      onPressed: onWeighOut,
                      child: const Text('Weigh out'),
                    )
                  else
                    Chip(
                      label: Text(batch.status.displayLabel),
                      backgroundColor: batch.status == DryerBatchStatus.complete
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${batch.productName} | ${batch.dryerType.dbValue} | In: ${batch.inputWeightKg} kg | Out: ${batch.outputWeightKg ?? "—"} kg',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              if (extraLine != null) extraLine,
            ],
          ),
        ),
      ),
    );
  }
}

class _DryerBatchDetailPanel extends StatelessWidget {
  final DryerBatch batch;
  final double electricityRate;
  final ScrollController scrollController;
  final VoidCallback? onDelete;

  const _DryerBatchDetailPanel({
    required this.batch,
    required this.electricityRate,
    required this.scrollController,
    this.onDelete,
  });

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final hours = batch.dryingHours ?? 0.0;
    final kwh = hours * (batch.kwhPerHour ?? 2.5);
    final cost = batch.electricityCost ?? 0.0;
    final costPerKg = (batch.outputWeightKg != null && batch.outputWeightKg! > 0)
        ? (cost / batch.outputWeightKg!)
        : 0.0;
    final shrinkage = batch.shrinkagePct;
    final lostKg = batch.outputWeightKg != null
        ? (batch.inputWeightKg - batch.outputWeightKg!)
        : 0.0;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(batch.batchNumber, style: Theme.of(context).textTheme.titleLarge),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                onPressed: onDelete,
                tooltip: 'Delete batch',
              ),
          ],
        ),
        const SizedBox(height: 16),
        _detailRow('Drying time', batch.dryingHours != null ? _formatDuration(Duration(minutes: (batch.dryingHours! * 60).round())) : '—'),
        _detailRow('Power', '${kwh.toStringAsFixed(1)} kWh'),
        _detailRow('Electricity cost', 'R${cost.toStringAsFixed(2)}'),
        _detailRow('Weight in', '${batch.inputWeightKg} kg'),
        _detailRow('Weight out', '${batch.outputWeightKg != null ? '${batch.outputWeightKg} kg' : '—'}'),
        if (shrinkage != null) _detailRow('Shrinkage', '${shrinkage.toStringAsFixed(1)}% (${lostKg.toStringAsFixed(1)} kg)'),
        _detailRow('Cost per kg', 'R${costPerKg.toStringAsFixed(2)}'),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _NewDryerBatchDialog extends StatefulWidget {
  final DryerBatchRepository repo;
  final List<Map<String, dynamic>> inventoryItems;
  final VoidCallback onDone;

  const _NewDryerBatchDialog({
    required this.repo,
    required this.inventoryItems,
    required this.onDone,
  });

  @override
  State<_NewDryerBatchDialog> createState() => _NewDryerBatchDialogState();
}

class _NewDryerBatchDialogState extends State<_NewDryerBatchDialog> {
  final _productNameController = TextEditingController();
  final _inputWeightController = TextEditingController();
  final _plannedHoursController = TextEditingController();
  String _dryerType = 'biltong';
  String? _inputProductId;
  String? _outputProductId;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _productNameController.dispose();
    _inputWeightController.dispose();
    _plannedHoursController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _productNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Product name required');
      return;
    }
    final weight = double.tryParse(_inputWeightController.text);
    if (weight == null || weight <= 0) {
      setState(() => _error = 'Input weight must be positive');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plannedH = double.tryParse(_plannedHoursController.text);
      await widget.repo.createBatch(
        productName: name,
        inputWeightKg: weight,
        dryerType: _dryerType,
        plannedHours: plannedH != null && plannedH > 0 ? plannedH : null,
        inputProductId: _inputProductId?.isEmpty == true ? null : _inputProductId,
        outputProductId: _outputProductId?.isEmpty == true ? null : _outputProductId,
        deductInputNow: true,
        performedBy: null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dryer batch created — raw material deducted'), backgroundColor: AppColors.success),
        );
        widget.onDone();
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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New dryer batch'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _productNameController,
              decoration: const InputDecoration(
                labelText: 'Product name',
                hintText: 'e.g. Beef Biltong',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _dryerType,
              decoration: const InputDecoration(labelText: 'Product type', border: OutlineInputBorder(), isDense: true),
              items: const [
                DropdownMenuItem(value: 'biltong', child: Text('Biltong')),
                DropdownMenuItem(value: 'droewors', child: Text('Droewors')),
                DropdownMenuItem(value: 'chilli_bites', child: Text('Chilli Bites')),
                DropdownMenuItem(value: 'jerky', child: Text('Jerky')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _dryerType = v ?? 'biltong'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _inputWeightController,
              decoration: const InputDecoration(
                labelText: 'Input weight (kg)',
                hintText: 'e.g. 15.5',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _plannedHoursController,
              decoration: const InputDecoration(
                labelText: 'Planned drying time (hours)',
                hintText: 'e.g. 48 for biltong, 24 for droëwors',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _inputProductId,
              decoration: const InputDecoration(labelText: 'Raw material (inventory)', border: OutlineInputBorder(), isDense: true),
              items: [
                const DropdownMenuItem(value: null, child: Text('— None —')),
                ...widget.inventoryItems.map((e) {
                  final id = e['id'] as String?;
                  final name = e['name'] as String? ?? '';
                  return DropdownMenuItem(value: id, child: Text(name));
                }),
              ],
              onChanged: (v) => setState(() => _inputProductId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _outputProductId,
              decoration: const InputDecoration(labelText: 'Finished product (inventory)', border: OutlineInputBorder(), isDense: true),
              items: [
                const DropdownMenuItem(value: null, child: Text('— None —')),
                ...widget.inventoryItems.map((e) {
                  final id = e['id'] as String?;
                  final name = e['name'] as String? ?? '';
                  return DropdownMenuItem(value: id, child: Text(name));
                }),
              ],
              onChanged: (v) => setState(() => _outputProductId = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _loading ? null : _create,
          child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Load dryer'),
        ),
      ],
    );
  }
}

class _WeighOutDialog extends StatefulWidget {
  final DryerBatch batch;
  final DryerBatchRepository repo;
  final double electricityRate;
  final double kwhPerHourDefault;
  final VoidCallback onDone;

  const _WeighOutDialog({
    required this.batch,
    required this.repo,
    required this.electricityRate,
    required this.kwhPerHourDefault,
    required this.onDone,
  });

  @override
  State<_WeighOutDialog> createState() => _WeighOutDialogState();
}

class _WeighOutDialogState extends State<_WeighOutDialog> {
  final _outputWeightController = TextEditingController();
  final _kwhController = TextEditingController(text: '2.5');
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _kwhController.text = (widget.batch.kwhPerHour ?? widget.kwhPerHourDefault).toString();
  }

  @override
  void dispose() {
    _outputWeightController.dispose();
    _kwhController.dispose();
    super.dispose();
  }

  double get _dryingHours {
    final loadedAt = widget.batch.loadedAt ?? widget.batch.startedAt;
    if (loadedAt == null) return 0;
    return DateTime.now().difference(loadedAt).inMinutes / 60.0;
  }

  /// kWh = elapsed hours × kW; cost = kWh × rate. Time from loaded_at only; kW is power.
  double get _estCost {
    final kW = double.tryParse(_kwhController.text) ?? 2.5;
    final kWh = _dryingHours * kW;
    return kWh * widget.electricityRate;
  }

  String get _durationStr {
    final d = Duration(minutes: (_dryingHours * 60).round());
    return '${d.inHours}h ${d.inMinutes % 60}m';
  }

  Future<void> _complete() async {
    final out = double.tryParse(_outputWeightController.text);
    if (out == null || out < 0) {
      setState(() => _error = 'Enter output weight (kg)');
      return;
    }
    final kwh = double.tryParse(_kwhController.text) ?? widget.kwhPerHourDefault;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.repo.completeBatch(
        batchId: widget.batch.id,
        outputWeightKg: out,
        completedBy: AuthService().getCurrentStaffId(),
        kwhPerHour: kwh,
        electricityRate: widget.electricityRate,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Batch complete — finished product added to stock'), backgroundColor: AppColors.success),
        );
        widget.onDone();
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
  Widget build(BuildContext context) {
    final kW = double.tryParse(_kwhController.text) ?? 2.5;
    final plannedH = widget.batch.plannedHours;
    return AlertDialog(
      title: Text('Weigh out: ${widget.batch.batchNumber}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Input: ${widget.batch.inputWeightKg} kg', style: const TextStyle(fontWeight: FontWeight.w600)),
            if (plannedH != null && plannedH > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Planned: ${plannedH.toStringAsFixed(0)}h | Actual: $_durationStr',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _outputWeightController,
              decoration: const InputDecoration(
                labelText: 'Output weight (kg)',
                hintText: 'e.g. 8.5',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _kwhController,
              decoration: const InputDecoration(
                labelText: 'Machine power rating in kilowatts',
                hintText: 'e.g. 6 for a 6kW dryer',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Text(
              'Current rate: R${widget.electricityRate.toStringAsFixed(2)}/kWh',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Est. cost: ${_dryingHours.toStringAsFixed(1)}h × ${kW.toStringAsFixed(1)}kW × R${widget.electricityRate.toStringAsFixed(2)} = R${_estCost.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _loading ? null : _complete,
          child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Complete'),
        ),
      ],
    );
  }
}
