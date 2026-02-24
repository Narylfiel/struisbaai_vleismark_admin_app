import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/supabase_service.dart';
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
  List<DryerBatch> _batches = [];
  List<Map<String, dynamic>> _inventoryItems = [];
  bool _loading = true;
  String? _error;

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
    _load();
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
        onDone: () {
          Navigator.pop(ctx);
          _load();
        },
      ),
    ).then((_) => _load());
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
                    final canWeighOut = b.status == DryerBatchStatus.drying;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(b.batchNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${b.productName} | ${b.dryerType.dbValue} | In: ${b.inputWeightKg} kg | '
                          'Out: ${b.outputWeightKg ?? "—"} kg | ${b.status.displayLabel}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: canWeighOut
                            ? TextButton(
                                onPressed: () => _weighOut(b),
                                child: const Text('Weigh out'),
                              )
                            : Chip(
                                label: Text(b.status.displayLabel),
                                backgroundColor: b.status == DryerBatchStatus.complete
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                              ),
                      ),
                    );
                  },
                ),
        ),
      ],
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
  String _dryerType = 'biltong';
  String? _inputProductId;
  String? _outputProductId;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _productNameController.dispose();
    _inputWeightController.dispose();
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
      await widget.repo.createBatch(
        productName: name,
        inputWeightKg: weight,
        dryerType: _dryerType,
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
  final VoidCallback onDone;

  const _WeighOutDialog({
    required this.batch,
    required this.repo,
    required this.onDone,
  });

  @override
  State<_WeighOutDialog> createState() => _WeighOutDialogState();
}

class _WeighOutDialogState extends State<_WeighOutDialog> {
  final _outputWeightController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _outputWeightController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final out = double.tryParse(_outputWeightController.text);
    if (out == null || out < 0) {
      setState(() => _error = 'Enter output weight (kg)');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.repo.completeBatch(
        batchId: widget.batch.id,
        outputWeightKg: out,
        completedBy: AuthService().getCurrentStaffId(),
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
    return AlertDialog(
      title: Text('Weigh out: ${widget.batch.batchNumber}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Input: ${widget.batch.inputWeightKg} kg', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _outputWeightController,
              decoration: const InputDecoration(
                labelText: 'Output weight (kg)',
                hintText: 'e.g. 8.5',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
