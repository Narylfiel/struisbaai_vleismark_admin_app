import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../models/production_batch.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';
import '../models/production_batch_ingredient.dart';
import '../services/recipe_repository.dart';
import '../services/production_batch_repository.dart';

/// Blueprint §5.5: Production batches — Select recipe → Start Batch → Enter actuals → Complete (deduct ingredients, add output).
class ProductionBatchScreen extends StatefulWidget {
  const ProductionBatchScreen({super.key});

  @override
  State<ProductionBatchScreen> createState() => _ProductionBatchScreenState();
}

class _ProductionBatchScreenState extends State<ProductionBatchScreen> {
  final _batchRepo = ProductionBatchRepository();
  final _recipeRepo = RecipeRepository();
  final _client = SupabaseService.client;
  List<ProductionBatch> _batches = [];
  List<Recipe> _recipes = [];
  List<Map<String, dynamic>> _inventoryItems = [];
  bool _loading = true;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final batches = await _batchRepo.getBatches();
      final recipes = await _recipeRepo.getRecipes(activeOnly: true);
      // C1: Single source of truth — current_stock only (POS trigger updates it).
      final inv = await _client.from('inventory_items').select('id, name, current_stock').eq('is_active', true).order('name');
      final invList = List<Map<String, dynamic>>.from(inv as List);
      if (mounted) {
        setState(() {
          _batches = batches;
          _recipes = recipes;
          _inventoryItems = invList;
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

  void _startNewBatch() {
    if (_recipes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a recipe with output product first'), backgroundColor: AppColors.warning),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => _StartBatchDialog(
        recipes: _recipes,
        inventoryItems: _inventoryItems,
        batchRepo: _batchRepo,
        recipeRepo: _recipeRepo,
        onDone: () {
          Navigator.pop(ctx);
          _load();
        },
      ),
    ).then((_) => _load());
  }

  void _completeBatch(ProductionBatch batch) {
    if (batch.status != ProductionBatchStatus.inProgress && batch.status != ProductionBatchStatus.planned) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _CompleteBatchScreen(
          batch: batch,
          batchRepo: _batchRepo,
          recipeRepo: _recipeRepo,
        ),
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
                onPressed: _startNewBatch,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Start batch'),
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
                      const Icon(Icons.batch_prediction, size: 64, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      const Text(
                        'Production batches',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select recipe → Start batch → Enter actuals → Complete (ingredients deducted, output added)',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _startNewBatch,
                        icon: const Icon(Icons.add),
                        label: const Text('Start batch'),
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
                    final canComplete = b.status == ProductionBatchStatus.planned ||
                        b.status == ProductionBatchStatus.inProgress;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(b.batchNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          'Recipe: ${b.recipeId.substring(0, 8)}… | Planned: ${b.plannedQuantity} | '
                          'Actual: ${b.actualQuantity ?? "—"} | ${b.status.dbValue}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: canComplete
                            ? TextButton(
                                onPressed: () => _completeBatch(b),
                                child: const Text('Complete'),
                              )
                            : Chip(
                                label: Text(b.status.dbValue),
                                backgroundColor: b.status == ProductionBatchStatus.completed
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

class _StartBatchDialog extends StatefulWidget {
  final List<Recipe> recipes;
  final List<Map<String, dynamic>> inventoryItems;
  final ProductionBatchRepository batchRepo;
  final RecipeRepository recipeRepo;
  final VoidCallback onDone;

  const _StartBatchDialog({
    required this.recipes,
    required this.inventoryItems,
    required this.batchRepo,
    required this.recipeRepo,
    required this.onDone,
  });

  @override
  State<_StartBatchDialog> createState() => _StartBatchDialogState();
}

class _StartBatchDialogState extends State<_StartBatchDialog> {
  Recipe? _selectedRecipe;
  final _plannedQtyController = TextEditingController(text: '10');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _plannedQtyController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_selectedRecipe == null) {
      setState(() => _error = 'Select a recipe');
      return;
    }
    final planned = int.tryParse(_plannedQtyController.text);
    if (planned == null || planned <= 0) {
      setState(() => _error = 'Planned quantity must be positive');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.batchRepo.createBatch(
        recipeId: _selectedRecipe!.id,
        plannedQuantity: planned,
        outputProductId: _selectedRecipe!.outputProductId,
        performedBy: null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Batch started'), backgroundColor: AppColors.success),
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
      title: const Text('Start production batch'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recipe', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<Recipe>(
              value: _selectedRecipe,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              items: widget.recipes
                  .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedRecipe = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _plannedQtyController,
              decoration: const InputDecoration(
                labelText: 'Planned quantity (e.g. 10 kg batch)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
          onPressed: _loading ? null : _start,
          child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Start batch'),
        ),
      ],
    );
  }
}

class _CompleteBatchScreen extends StatefulWidget {
  final ProductionBatch batch;
  final ProductionBatchRepository batchRepo;
  final RecipeRepository recipeRepo;

  const _CompleteBatchScreen({
    required this.batch,
    required this.batchRepo,
    required this.recipeRepo,
  });

  @override
  State<_CompleteBatchScreen> createState() => _CompleteBatchScreenState();
}

class _CompleteBatchScreenState extends State<_CompleteBatchScreen> {
  final _client = SupabaseService.client;
  final _outputQtyController = TextEditingController();
  Map<String, TextEditingController> _actualControllers = {};
  List<ProductionBatchIngredient> _batchIngredients = [];
  Map<String, RecipeIngredient> _ingredientById = {};
  /// C1: current_stock per inventory_item_id for ingredient list (single source of truth).
  Map<String, double> _availableStockByItemId = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final batchIng = await widget.batchRepo.getBatchIngredients(widget.batch.id);
      for (final bi in batchIng) {
        final ri = await widget.recipeRepo.getIngredient(bi.ingredientId);
        if (ri != null) _ingredientById[bi.ingredientId] = ri;
        _actualControllers[bi.ingredientId] = TextEditingController(text: bi.plannedQuantity.toString());
      }
      // C1: Load current_stock for each linked inventory item so ingredient list shows accurate available stock.
      final itemIds = _ingredientById.values
          .map((ri) => ri.inventoryItemId)
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
      if (itemIds.isNotEmpty) {
        final rows = await _client
            .from('inventory_items')
            .select('id, current_stock')
            .inFilter('id', itemIds);
        final map = <String, double>{};
        for (final row in rows as List) {
          final id = (row as Map)['id']?.toString();
          if (id != null) {
            map[id] = (row['current_stock'] as num?)?.toDouble() ?? 0;
          }
        }
        if (mounted) _availableStockByItemId = map;
      }
      if (mounted) {
        setState(() {
          _batchIngredients = batchIng;
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
  void dispose() {
    _outputQtyController.dispose();
    for (final c in _actualControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _complete() async {
    final outputQty = double.tryParse(_outputQtyController.text);
    if (outputQty == null || outputQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter actual output quantity'), backgroundColor: AppColors.danger),
      );
      return;
    }
    final actuals = <String, double>{};
    for (final entry in _actualControllers.entries) {
      final v = double.tryParse(entry.value.text);
      if (v != null && v >= 0) actuals[entry.key] = v;
    }
    setState(() => _saving = true);
    try {
      await widget.batchRepo.completeBatch(
        batchId: widget.batch.id,
        actualQuantitiesByIngredientId: actuals,
        actualOutputQuantity: outputQty,
        completedBy: '', // TODO: from auth
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Batch complete — ingredients deducted, output added'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete batch ${widget.batch.batchNumber}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Actual ingredient quantities used', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            ..._batchIngredients.map((bi) {
              final ri = _ingredientById[bi.ingredientId];
              final name = ri?.ingredientName ?? bi.ingredientId.substring(0, 8);
              final ctrl = _actualControllers[bi.ingredientId];
              // C1: Show current_stock available for linked inventory item (single source of truth).
              final available = ri?.inventoryItemId != null
                  ? _availableStockByItemId[ri!.inventoryItemId]
                  : null;
              final availableStr = available != null
                  ? '${available.toStringAsFixed(1)} kg available'
                  : '—';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(name)),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        controller: ctrl,
                        decoration: const InputDecoration(labelText: 'Actual', isDense: true),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('(${bi.plannedQuantity.toStringAsFixed(1)} planned)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    Text(availableStr, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            const Text('Actual output quantity (kg)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _outputQtyController,
              decoration: const InputDecoration(
                hintText: 'e.g. 49.4',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _complete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _saving
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Complete batch (deduct ingredients, add output)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
