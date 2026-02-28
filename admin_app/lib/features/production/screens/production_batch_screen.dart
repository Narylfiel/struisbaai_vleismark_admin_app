import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/admin_config.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/db/cached_production_batch.dart';
import '../../../core/db/isar_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/offline_queue_service.dart';
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
  /// Recipe name by recipe id when loaded from cache (offline).
  Map<String, String> _recipeNameById = {};
  bool _loading = true;
  bool _isOffline = false;
  String? _error;
  /// Status filter: null = All, or 'pending', 'in_progress', 'complete', 'cancelled'.
  String? _statusFilter;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final isConnected = ConnectivityService().isConnected;
    try {
      if (isConnected) {
        _isOffline = false;
        final stale = await IsarService.isProductionBatchCacheStale();
        if (stale) {
          await _fetchFromSupabaseAndSave();
        } else {
          await _loadFromCache();
          _refreshInBackground();
          final recipes = await _recipeRepo.getRecipes(activeOnly: true);
          final inv = await _client.from('inventory_items').select('id, name, current_stock').eq('is_active', true).order('name');
          final invList = List<Map<String, dynamic>>.from(inv as List);
          if (mounted) setState(() {
            _recipes = recipes;
            _inventoryItems = invList;
          });
        }
      } else {
        _isOffline = true;
        await _loadFromCache();
        if (mounted) setState(() {
          _recipes = [];
          _inventoryItems = [];
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _error = ErrorHandler.friendlyMessage(e);
      });
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadFromCache() async {
    final cached = await IsarService.getProductionBatches(null);
    _batches = cached
        .map((c) => ProductionBatch.fromJson(c.toBatchMap()))
        .toList();
    _recipeNameById = { for (final c in cached) if (c.recipeId != null) c.recipeId!: c.recipeName ?? '' };
  }

  Future<void> _fetchFromSupabaseAndSave() async {
    final batches = await _batchRepo.getBatches();
    final recipes = await _recipeRepo.getRecipes(activeOnly: true);
    final inv = await _client.from('inventory_items').select('id, name, current_stock').eq('is_active', true).order('name');
    final invList = List<Map<String, dynamic>>.from(inv as List);
    final recipeNameById = { for (final r in recipes) r.id: r.name };
    final productNameById = { for (final m in invList) m['id']?.toString() ?? '': m['name']?.toString() ?? '' };
    final toSave = batches.map((b) {
      final recipeName = b.recipeId.isNotEmpty ? recipeNameById[b.recipeId] : null;
      final outputName = b.outputProductId != null ? productNameById[b.outputProductId!] : null;
      return CachedProductionBatch.fromSupabase(
        b.toJson(),
        recipeName: recipeName,
        outputProductName: outputName,
      );
    }).toList();
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final trimmed = toSave.where((c) => (c.createdAt ?? DateTime(0)).isAfter(thirtyDaysAgo)).take(100).toList();
    await IsarService.saveProductionBatches(trimmed);
    _batches = batches;
    _recipes = recipes;
    _inventoryItems = invList;
    _recipeNameById = {};
  }

  void _refreshInBackground() {
    Future(() async {
      try {
        if (!await IsarService.isProductionBatchCacheStale()) return;
        await _fetchFromSupabaseAndSave();
        if (mounted) setState(() {});
      } catch (_) {}
    });
  }

  /// Batches to display: filter by _statusFilter in Dart (works offline from cache).
  List<ProductionBatch> get _filteredBatches {
    if (_statusFilter == null || _statusFilter!.isEmpty) return _batches;
    return _batches.where((b) => b.status.dbValue == _statusFilter).toList();
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
    if (batch.status != ProductionBatchStatus.inProgress && batch.status != ProductionBatchStatus.pending) return;
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

  void _splitBatch(ProductionBatch batch) {
    if (batch.status != ProductionBatchStatus.inProgress && batch.status != ProductionBatchStatus.complete) return;
    showDialog(
      context: context,
      builder: (ctx) => _SplitBatchDialog(
        parentBatch: batch,
        recipes: _recipes,
        batchRepo: _batchRepo,
        onDone: () {
          Navigator.pop(ctx);
          _load();
        },
      ),
    ).then((_) => _load());
  }

  Future<void> _cancelBatch(ProductionBatch batch) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel batch?'),
        content: Text(
          'Cancel ${batch.batchNumber}?\n\n'
          'All ingredients will be returned to stock.\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep batch'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Cancel batch'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _batchRepo.cancelBatch(
        batch.id,
        AuthService().getCurrentStaffId(),
      );
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Batch cancelled — ingredients returned to stock'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _deleteBatch(ProductionBatch batch) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete batch?'),
        content: Text(
          'Delete ${batch.batchNumber}?\n\n'
          'All stock movements will be reversed.\n'
          'Linked dryer batches will also be deleted.\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete + Reverse Stock'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _batchRepo.deleteBatch(batch.id);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Batch deleted — stock reversed'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.friendlyMessage(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _editBatch(ProductionBatch batch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _EditBatchScreen(
          batch: batch,
          batchRepo: _batchRepo,
          recipeRepo: _recipeRepo,
        ),
      ),
    ).then((edited) { if (edited == true) _load(); });
  }

  Future<void> _confirmDeleteProductionBatch(ProductionBatch batch) async {
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
      await _batchRepo.deleteBatch(batch.id);
      if (mounted) {
        setState(() => _batches.removeWhere((b) => b.id == batch.id));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('splits') ? 'Cannot delete — this batch has splits. Delete splits first.' : ErrorHandler.friendlyMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.danger));
      }
    }
  }

  /// Build list: roots (no parent_batch_id) then each root's children indented. Parents with children get "Split" badge.
  List<Widget> _buildBatchListItems() {
    final listToUse = _filteredBatches;
    final roots = listToUse.where((b) => b.parentBatchId == null).toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    final childrenByParent = <String, List<ProductionBatch>>{};
    for (final b in listToUse) {
      if (b.parentBatchId != null) {
        childrenByParent.putIfAbsent(b.parentBatchId!, () => []).add(b);
      }
    }
    for (final list in childrenByParent.values) {
      list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    }
    final parentIdsWithSplits = childrenByParent.keys.toSet();
    final recipeNameById = _recipeNameById.isNotEmpty
        ? Map<String, String>.from(_recipeNameById)
        : { for (final r in _recipes) r.id: r.name };
    final items = <Widget>[];
    for (final root in roots) {
      items.add(_buildBatchCard(root, recipeNameById, parentIdsWithSplits.contains(root.id), false));
      for (final child in childrenByParent[root.id] ?? []) {
        items.add(_buildBatchCard(child, recipeNameById, false, true, parentBatch: root));
      }
    }
    return items;
  }

  Widget _buildBatchCard(
    ProductionBatch b,
    Map<String, String> recipeNameById,
    bool showSplitBadge,
    bool isChild, {
    ProductionBatch? parentBatch,
  }) {
    final recipeName = recipeNameById[b.recipeId] ?? (b.recipeId.length >= 8 ? b.recipeId.substring(0, 8) : b.recipeId.isEmpty ? 'No recipe' : b.recipeId);
    final qtyDisplay = b.actualQuantity ?? b.plannedQuantity;
    return Card(
      margin: EdgeInsets.only(bottom: 8, left: isChild ? 20 : 0),
      child: ListTile(
        onLongPress: () => _confirmDeleteProductionBatch(b),
        title: Row(
          children: [
            if (isChild) const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Text('↳', style: TextStyle(fontSize: 16)),
            ),
            Expanded(
              child: Text(
                b.batchNumber,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (showSplitBadge)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Chip(
                  label: const Text('Split', style: TextStyle(fontSize: 11)),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isChild && parentBatch != null)
              Text(
                '↳ Split from ${parentBatch.createdAt != null ? _formatDate(parentBatch.createdAt!) : "parent"}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            Text(
              'Recipe: $recipeName | Qty: $qtyDisplay | ${b.status.displayLabel}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // In-progress actions
            if (b.status == ProductionBatchStatus.inProgress) ...[
              TextButton(
                onPressed: () => _editBatch(b),
                child: const Text('Edit', style: TextStyle(color: AppColors.warning)),
              ),
              TextButton(
                onPressed: () => _completeBatch(b),
                child: const Text('Complete', style: TextStyle(color: AppColors.success)),
              ),
              TextButton(
                onPressed: () => _cancelBatch(b),
                child: const Text('Cancel', style: TextStyle(color: AppColors.danger)),
              ),
            ],
            // Complete actions
            if (b.status == ProductionBatchStatus.complete) ...[
              if (!b.isSplitParent)
                TextButton(
                  onPressed: () => _splitBatch(b),
                  child: const Text('Split', style: TextStyle(color: AppColors.primary)),
                ),
              TextButton(
                onPressed: () => _editBatch(b),
                child: const Text('Edit', style: TextStyle(color: AppColors.warning)),
              ),
              TextButton(
                onPressed: () => _deleteBatch(b),
                child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
              ),
            ],
            // Cancelled actions
            if (b.status == ProductionBatchStatus.cancelled)
              TextButton(
                onPressed: () => _deleteBatch(b),
                child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
              ),
            // Pending - show chip only
            if (b.status == ProductionBatchStatus.pending)
              Chip(
                label: Text(b.status.displayLabel),
                backgroundColor: AppColors.warning,
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
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
              SegmentedButton<String?>(
                segments: const [
                  ButtonSegment(value: null, label: Text('All')),
                  ButtonSegment(value: 'pending', label: Text('Pending')),
                  ButtonSegment(value: 'in_progress', label: Text('In progress')),
                  ButtonSegment(value: 'complete', label: Text('Complete')),
                  ButtonSegment(value: 'cancelled', label: Text('Cancelled')),
                ],
                selected: {_statusFilter},
                onSelectionChanged: (s) => setState(() => _statusFilter = s.first),
              ),
              const SizedBox(width: 16),
              const Expanded(child: SizedBox()),
              ElevatedButton.icon(
                onPressed: _isOffline ? null : _startNewBatch,
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
          child: _isOffline && _batches.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No cached data available. Connect to the internet to load data.',
                      style: TextStyle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _filteredBatches.isEmpty
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
                          Text(
                            _statusFilter != null
                                ? 'No batches with status "${_statusFilter!.replaceAll('_', ' ')}".'
                                : 'Select recipe → Start batch → Enter actuals → Complete (ingredients deducted, output added)',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          if (_statusFilter == null)
                            ElevatedButton.icon(
                              onPressed: _isOffline ? null : _startNewBatch,
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
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: _buildBatchListItems(),
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
          const SnackBar(content: Text('Batch started — ingredients deducted from stock'), backgroundColor: AppColors.success),
        );
        widget.onDone();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorHandler.friendlyMessage(e);
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
                labelText: 'Batch size (kg)',
                helperText: 'Ingredients deducted immediately on start',
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
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Start — deducts ingredients now'),
        ),
      ],
    );
  }
}

class _SplitRow {
  String? recipeId;
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
}

class _SplitBatchDialog extends StatefulWidget {
  final ProductionBatch parentBatch;
  final List<Recipe> recipes;
  final ProductionBatchRepository batchRepo;
  final VoidCallback onDone;

  const _SplitBatchDialog({
    required this.parentBatch,
    required this.recipes,
    required this.batchRepo,
    required this.onDone,
  });

  @override
  State<_SplitBatchDialog> createState() => _SplitBatchDialogState();
}

class _SplitBatchDialogState extends State<_SplitBatchDialog> {
  final List<_SplitRow> _rows = [];
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _rows.add(_SplitRow());
    _rows.add(_SplitRow());
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.qtyController.dispose();
      r.notesController.dispose();
    }
    super.dispose();
  }

  double get _parentQty =>
      (widget.parentBatch.actualQuantity ?? widget.parentBatch.plannedQuantity).toDouble();

  double get _totalSplitQty {
    double sum = 0;
    for (final r in _rows) {
      final q = double.tryParse(r.qtyController.text);
      if (q != null && q > 0) sum += q;
    }
    return sum;
  }

  double get _remaining => _parentQty - _totalSplitQty;

  String _recipeName(String? recipeId) {
    if (recipeId == null || recipeId.isEmpty) return '— Select recipe —';
    try {
      final r = widget.recipes.firstWhere((x) => x.id == recipeId);
      return r.name;
    } catch (_) {
      return recipeId.length >= 8 ? '${recipeId.substring(0, 8)}…' : recipeId;
    }
  }

  Future<void> _pickRecipe(_SplitRow row) async {
    final selected = await showDialog<Recipe>(
      context: context,
      builder: (ctx) {
        final searchController = TextEditingController();
        List<Recipe> filtered = List.from(widget.recipes);
        return StatefulBuilder(
          builder: (ctx, setDialog) {
            return AlertDialog(
              title: const Text('Select recipe'),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search by name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) {
                        setDialog(() {
                          final q = searchController.text.trim().toLowerCase();
                          filtered = q.isEmpty
                              ? List.from(widget.recipes)
                              : widget.recipes
                                  .where((r) => r.name.toLowerCase().contains(q))
                                  .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final r = filtered[i];
                          return ListTile(
                            title: Text(r.name),
                            onTap: () => Navigator.pop(ctx, r),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (selected != null && mounted) {
      setState(() {
        row.recipeId = selected.id;
      });
    }
  }

  Future<void> _confirm() async {
    setState(() => _error = null);
    if (_rows.length < 2) {
      setState(() => _error = 'Add at least 2 splits');
      return;
    }
    final splits = <Map<String, dynamic>>[];
    for (final r in _rows) {
      if (r.recipeId == null || r.recipeId!.isEmpty) continue;
      final q = double.tryParse(r.qtyController.text);
      if (q == null || q <= 0) continue;
      splits.add({
        'recipe_id': r.recipeId,
        'qty_produced': q,
        'notes': r.notesController.text.trim().isEmpty ? null : r.notesController.text.trim(),
      });
    }
    if (splits.length < 2) {
      setState(() => _error = 'Add at least 2 splits with recipe and quantity');
      return;
    }
    final total = splits.fold<double>(0, (s, m) => s + ((m['qty_produced'] as num?)?.toDouble() ?? 0));
    if (total > _parentQty) {
      setState(() => _error = 'Total quantity ($total) cannot exceed parent batch ($_parentQty kg)');
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.batchRepo.splitBatch(
        parentBatchId: widget.parentBatch.id,
        splits: splits,
        performedBy: AuthService().getCurrentStaffId(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Batch split into ${splits.length} outputs'), backgroundColor: AppColors.success),
        );
        widget.onDone();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorHandler.friendlyMessage(e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String recipeName;
    try {
      recipeName = widget.recipes.firstWhere((r) => r.id == widget.parentBatch.recipeId).name;
    } catch (_) {
      recipeName = widget.parentBatch.recipeId.length >= 8
          ? '${widget.parentBatch.recipeId.substring(0, 8)}…'
          : widget.parentBatch.recipeId;
    }
    return AlertDialog(
      title: const Text('Split batch'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Parent batch', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Recipe: $recipeName | Qty produced: $_parentQty kg'),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Splits', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _rows.add(_SplitRow()));
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add output'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_rows.length, (i) {
              final row = _rows[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => _pickRecipe(row),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Recipe',
                            border: OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                          child: Text(_recipeName(row.recipeId)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              controller: row.qtyController,
                              decoration: const InputDecoration(
                                labelText: 'Quantity (kg)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: row.notesController,
                              decoration: const InputDecoration(
                                labelText: 'Notes (optional)',
                                hintText: 'e.g. filled into casings',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      if (_rows.length > 2)
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger, size: 22),
                            onPressed: () {
                              setState(() {
                                row.qtyController.dispose();
                                row.notesController.dispose();
                                _rows.removeAt(i);
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            Text(
              'Total: $_totalSplitQty kg | Remaining: $_remaining kg',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _remaining < 0 ? AppColors.danger : null,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _loading ? null : _confirm,
          child: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Confirm split'),
        ),
      ],
    );
  }
}

class _OutputRow {
  String? inventoryItemId;
  final TextEditingController qtyController = TextEditingController();
  String unit = 'kg';
  final TextEditingController notesController = TextEditingController();
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
  final _costTotalController = TextEditingController();
  List<_OutputRow> _outputRows = [];
  Map<String, TextEditingController> _actualControllers = {};
  List<ProductionBatchIngredient> _batchIngredients = [];
  Map<String, RecipeIngredient> _ingredientById = {};
  List<Map<String, dynamic>> _inventoryItems = [];
  Map<String, double> _availableStockByItemId = {};
  double _calculatedIngredientCost = 0.0;
  double _calculatedLabourCost = 0.0;
  double _calculatedTotalCost = 0.0;
  int _recipePrepTimeMinutes = 0;
  String _recipeRequiredRole = 'butchery_assistant';
  double _labourRatePerHour = 28.79;
  Map<String, double> _ingredientCostPrices = {};
  bool _costCalculated = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Recipe? _recipe;

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
      // Load cost prices for all linked inventory items
      final costItemIds = _ingredientById.values
          .map((ri) => ri.inventoryItemId)
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
      if (costItemIds.isNotEmpty) {
        final costRows = await _client
            .from('inventory_items')
            .select('id, cost_price')
            .inFilter('id', costItemIds);
        for (final row in costRows as List) {
          final id = (row as Map)['id']?.toString();
          final price = (row['cost_price'] as num?)?.toDouble() ?? 0.0;
          if (id != null) _ingredientCostPrices[id] = price;
        }
      }

      // Load recipe prep time and required role
      try {
        _recipe = await widget.recipeRepo.getRecipe(widget.batch.recipeId);
        if (_recipe != null) {
          _recipePrepTimeMinutes = _recipe!.prepTimeMinutes ?? 0;
          _recipeRequiredRole = _recipe!.requiredRole ?? 'butchery_assistant';
        }
      } catch (_) {}

      // Load avg hourly rate for required role from staff_profiles
      try {
        final staffRows = await _client
            .from('staff_profiles')
            .select('hourly_rate')
            .eq('role', _recipeRequiredRole)
            .eq('is_active', true);
        final rates = (staffRows as List)
            .map((r) => (r['hourly_rate'] as num?)?.toDouble() ?? 0.0)
            .where((r) => r > 0)
            .toList();
        if (rates.isNotEmpty) {
          _labourRatePerHour = rates.reduce((a, b) => a + b) / rates.length;
        }
      } catch (_) {}
      final inv = await _client
          .from('inventory_items')
          .select('id, name, unit_type, plu_code')
          .eq('is_active', true)
          .order('name');
      final invList = List<Map<String, dynamic>>.from(inv as List);
      if (mounted) {
        setState(() {
          _batchIngredients = batchIng;
          _inventoryItems = invList;
          if (_outputRows.isEmpty) {
            _outputRows.add(_OutputRow());
          }
          _loading = false;
        });
        _calculateCost();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorHandler.friendlyMessage(e);
          _loading = false;
        });
      }
    }
  }

  void _calculateCost() {
    double ingredientTotal = 0.0;
    for (final bi in _batchIngredients) {
      final ri = _ingredientById[bi.ingredientId];
      if (ri?.inventoryItemId == null) continue;
      final actualQty = double.tryParse(
        _actualControllers[bi.ingredientId]?.text ?? '',
      ) ?? bi.plannedQuantity;
      final costPrice =
          _ingredientCostPrices[ri!.inventoryItemId] ?? 0.0;
      ingredientTotal += actualQty * costPrice;
    }
    final labourHours = _recipePrepTimeMinutes / 60.0;
    final labourCost = labourHours * _labourRatePerHour;
    final total = ingredientTotal + labourCost;
    setState(() {
      _calculatedIngredientCost = ingredientTotal;
      _calculatedLabourCost = labourCost;
      _calculatedTotalCost = total;
      _costCalculated = true;
      _costTotalController.text = total.toStringAsFixed(2);
    });
  }

  @override
  void dispose() {
    _costTotalController.dispose();
    for (final row in _outputRows) {
      row.qtyController.dispose();
      row.notesController.dispose();
    }
    for (final c in _actualControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOutputRow() {
    setState(() => _outputRows.add(_OutputRow()));
  }

  void _removeOutputRow(int index) {
    if (_outputRows.length <= 1) return;
    setState(() {
      _outputRows[index].qtyController.dispose();
      _outputRows[index].notesController.dispose();
      _outputRows.removeAt(index);
    });
  }

  Widget _buildOutputRow(int index) {
    final row = _outputRows[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Autocomplete<Map<String, dynamic>>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return _inventoryItems.take(50);
                        }
                        final query = textEditingValue.text.toLowerCase();
                        return _inventoryItems.where((m) {
                          final name = (m['name'] as String? ?? '').toLowerCase();
                          final plu = (m['plu_code']?.toString() ?? '').toLowerCase();
                          return name.contains(query) || plu.contains(query);
                        }).take(50);
                      },
                      displayStringForOption: (m) {
                        final name = m['name'] as String? ?? '';
                        final plu = m['plu_code']?.toString() ?? '';
                        return plu.isNotEmpty ? '$name (PLU: $plu)' : name;
                      },
                      onSelected: (m) {
                        setState(() {
                          row.inventoryItemId = m['id']?.toString();
                          row.unit = m['unit_type']?.toString() ?? 'kg';
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                        // Pre-fill if item already selected
                        if (row.inventoryItemId != null && controller.text.isEmpty) {
                          try {
                            final existing = _inventoryItems.firstWhere(
                              (m) => m['id']?.toString() == row.inventoryItemId,
                            );
                            final name = existing['name'] as String? ?? '';
                            final plu = existing['plu_code']?.toString() ?? '';
                            controller.text = plu.isNotEmpty ? '$name (PLU: $plu)' : name;
                          } catch (_) {}
                        }
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Product (type to search)',
                            hintText: 'Search by name or PLU...',
                            border: OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: Icon(Icons.search, size: 18),
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            child: SizedBox(
                              width: 400,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (_, i) {
                                  final m = options.elementAt(i);
                                  final name = m['name'] as String? ?? '';
                                  final plu = m['plu_code']?.toString() ?? '';
                                  return ListTile(
                                    dense: true,
                                    title: Text(name),
                                    subtitle: plu.isNotEmpty ? Text('PLU: $plu') : null,
                                    onTap: () => onSelected(m),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_outputRows.length > 1)
                    IconButton(
                      onPressed: () => _removeOutputRow(index),
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger, size: 22),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      controller: row.qtyController,
                      decoration: const InputDecoration(
                        labelText: 'Qty produced',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(row.unit, style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: row.notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _complete() async {
    final outputs = <Map<String, dynamic>>[];
    for (final row in _outputRows) {
      if (row.inventoryItemId == null || row.inventoryItemId!.isEmpty) continue;
      final qty = double.tryParse(row.qtyController.text);
      if (qty == null || qty <= 0) continue;
      outputs.add({
        'inventory_item_id': row.inventoryItemId,
        'qty_produced': qty,
        'unit': row.unit,
        'notes': row.notesController.text.trim().isEmpty ? null : row.notesController.text.trim(),
      });
    }
    if (outputs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one output product with quantity'), backgroundColor: AppColors.danger),
      );
      return;
    }
    final actuals = <String, double>{};
    for (final entry in _actualControllers.entries) {
      final v = double.tryParse(entry.value.text);
      if (v != null && v >= 0) actuals[entry.key] = v;
    }
    final costTotal = double.tryParse(_costTotalController.text);
    final completedBy = AuthService().getCurrentStaffId() ?? '';
    if (completedBy.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in with PIN to complete batch'), backgroundColor: AppColors.warning),
      );
      return;
    }
    if (!ConnectivityService().isConnected) {
      await OfflineQueueService().addToQueue('complete_batch', {
        'batchId': widget.batch.id,
        'actualQuantitiesByIngredientId': actuals,
        'outputs': outputs,
        'completedBy': completedBy,
        'costTotal': costTotal,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved — will sync when back online.'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context, true);
      }
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.batchRepo.completeBatch(
        batchId: widget.batch.id,
        actualQuantitiesByIngredientId: actuals,
        outputs: outputs,
        completedBy: completedBy,
        costTotal: costTotal,
      );
      if (mounted) {
        final dryerAutoCreated = _recipe?.goesToDryer == true && 
                                 _recipe?.dryerOutputProductId != null && 
                                 _recipe!.dryerOutputProductId!.isNotEmpty;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(dryerAutoCreated 
                ? 'Batch complete — dryer batch auto-created' 
                : 'Batch complete — output added to inventory'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.danger),
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
              final name = ri?.ingredientName ?? (bi.ingredientId.length >= 8 ? bi.ingredientId.substring(0, 8) : bi.ingredientId);
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
                        onChanged: (_) => _calculateCost(),
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
            Row(
              children: [
                const Text('Outputs', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _addOutputRow,
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                  tooltip: 'Add output row',
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_outputRows.length, (i) => _buildOutputRow(i)),
            const SizedBox(height: 16),
            if (_costCalculated) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AUTO-CALCULATED COST',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Ingredients:', style: TextStyle(fontSize: 13)),
                        Text('R${_calculatedIngredientCost.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Labour (${_recipePrepTimeMinutes}min × '
                            'R${_labourRatePerHour.toStringAsFixed(2)}/hr '
                            '[${AdminConfig.roleDisplayLabel(_recipeRequiredRole)}]):',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text('R${_calculatedLabourCost.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          'R${_calculatedTotalCost.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Override below if needed',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            TextFormField(
              controller: _costTotalController,
              decoration: InputDecoration(
                labelText: _costCalculated
                    ? 'Override total cost (optional)'
                    : 'Total cost (optional)',
                hintText: 'e.g. 1250.00',
                border: const OutlineInputBorder(),
                suffixIcon: _costCalculated
                    ? IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        tooltip: 'Reset to calculated',
                        onPressed: () => setState(() =>
                            _costTotalController.text =
                                _calculatedTotalCost.toStringAsFixed(2)),
                      )
                    : null,
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

// Edit Batch Screen - reuses Complete Batch layout but calls editBatch() instead
class _EditBatchScreen extends StatefulWidget {
  final ProductionBatch batch;
  final ProductionBatchRepository batchRepo;
  final RecipeRepository recipeRepo;

  const _EditBatchScreen({
    required this.batch,
    required this.batchRepo,
    required this.recipeRepo,
  });

  @override
  State<_EditBatchScreen> createState() => _EditBatchScreenState();
}

class _EditBatchScreenState extends State<_EditBatchScreen> {
  final _client = SupabaseService.client;
  final _costTotalController = TextEditingController();
  List<_OutputRow> _outputRows = [];
  Map<String, TextEditingController> _actualControllers = {};
  List<ProductionBatchIngredient> _batchIngredients = [];
  Map<String, RecipeIngredient> _ingredientById = {};
  List<Map<String, dynamic>> _inventoryItems = [];
  Map<String, double> _availableStockByItemId = {};
  double _calculatedIngredientCost = 0.0;
  double _calculatedLabourCost = 0.0;
  double _calculatedTotalCost = 0.0;
  int _recipePrepTimeMinutes = 0;
  String _recipeRequiredRole = 'butchery_assistant';
  double _labourRatePerHour = 28.79;
  Map<String, double> _ingredientCostPrices = {};
  bool _costCalculated = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Recipe? _recipe;

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
        // Load actual or planned quantity
        final qty = bi.actualQuantity ?? bi.plannedQuantity;
        _actualControllers[bi.ingredientId] = TextEditingController(text: qty.toString());
      }
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
      // Load cost prices
      final costItemIds = _ingredientById.values
          .map((ri) => ri.inventoryItemId)
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
      if (costItemIds.isNotEmpty) {
        final costRows = await _client
            .from('inventory_items')
            .select('id, cost_price')
            .inFilter('id', costItemIds);
        for (final row in costRows as List) {
          final id = (row as Map)['id']?.toString();
          final price = (row['cost_price'] as num?)?.toDouble() ?? 0.0;
          if (id != null) _ingredientCostPrices[id] = price;
        }
      }

      // Load recipe
      try {
        _recipe = await widget.recipeRepo.getRecipe(widget.batch.recipeId);
        if (_recipe != null) {
          _recipePrepTimeMinutes = _recipe!.prepTimeMinutes ?? 0;
          _recipeRequiredRole = _recipe!.requiredRole ?? 'butchery_assistant';
        }
      } catch (_) {}

      // Load labour rate
      try {
        final staffRows = await _client
            .from('staff_profiles')
            .select('hourly_rate')
            .eq('role', _recipeRequiredRole)
            .eq('is_active', true);
        final rates = (staffRows as List)
            .map((r) => (r['hourly_rate'] as num?)?.toDouble() ?? 0.0)
            .where((r) => r > 0)
            .toList();
        if (rates.isNotEmpty) {
          _labourRatePerHour = rates.reduce((a, b) => a + b) / rates.length;
        }
      } catch (_) {}

      final inv = await _client
          .from('inventory_items')
          .select('id, name, unit_type, plu_code')
          .eq('is_active', true)
          .order('name');
      final invList = List<Map<String, dynamic>>.from(inv as List);

      // Load existing outputs if batch is complete
      if (widget.batch.status == ProductionBatchStatus.complete) {
        final outputs = await _client
            .from('production_batch_outputs')
            .select()
            .eq('batch_id', widget.batch.id);
        for (final out in outputs as List) {
          final row = _OutputRow();
          row.inventoryItemId = out['inventory_item_id'] as String?;
          row.qtyController.text = ((out['qty_produced'] as num?)?.toDouble() ?? 0).toString();
          row.unit = out['unit'] as String? ?? 'kg';
          row.notesController.text = out['notes'] as String? ?? '';
          _outputRows.add(row);
        }
      }

      if (mounted) {
        setState(() {
          _batchIngredients = batchIng;
          _inventoryItems = invList;
          if (_outputRows.isEmpty) {
            _outputRows.add(_OutputRow());
          }
          _loading = false;
        });
        _calculateCost();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorHandler.friendlyMessage(e);
          _loading = false;
        });
      }
    }
  }

  void _calculateCost() {
    double ingredientTotal = 0.0;
    for (final bi in _batchIngredients) {
      final ri = _ingredientById[bi.ingredientId];
      if (ri?.inventoryItemId == null) continue;
      final actualQty = double.tryParse(
        _actualControllers[bi.ingredientId]?.text ?? '',
      ) ?? bi.plannedQuantity;
      final costPrice =
          _ingredientCostPrices[ri!.inventoryItemId] ?? 0.0;
      ingredientTotal += actualQty * costPrice;
    }
    final labourHours = _recipePrepTimeMinutes / 60.0;
    final labourCost = labourHours * _labourRatePerHour;
    final total = ingredientTotal + labourCost;
    setState(() {
      _calculatedIngredientCost = ingredientTotal;
      _calculatedLabourCost = labourCost;
      _calculatedTotalCost = total;
      _costCalculated = true;
      _costTotalController.text = total.toStringAsFixed(2);
    });
  }

  @override
  void dispose() {
    _costTotalController.dispose();
    for (final row in _outputRows) {
      row.qtyController.dispose();
      row.notesController.dispose();
    }
    for (final c in _actualControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOutputRow() {
    setState(() => _outputRows.add(_OutputRow()));
  }

  void _removeOutputRow(int index) {
    if (_outputRows.length <= 1) return;
    setState(() {
      _outputRows[index].qtyController.dispose();
      _outputRows[index].notesController.dispose();
      _outputRows.removeAt(index);
    });
  }

  Widget _buildOutputRow(int index) {
    final row = _outputRows[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Autocomplete<Map<String, dynamic>>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return _inventoryItems.take(50);
                        }
                        final query = textEditingValue.text.toLowerCase();
                        return _inventoryItems.where((m) {
                          final name = (m['name'] as String? ?? '').toLowerCase();
                          final plu = (m['plu_code']?.toString() ?? '').toLowerCase();
                          return name.contains(query) || plu.contains(query);
                        }).take(50);
                      },
                      displayStringForOption: (m) {
                        final name = m['name'] as String? ?? '';
                        final plu = m['plu_code']?.toString() ?? '';
                        return plu.isNotEmpty ? '$name (PLU: $plu)' : name;
                      },
                      onSelected: (m) {
                        setState(() {
                          row.inventoryItemId = m['id']?.toString();
                          row.unit = m['unit_type']?.toString() ?? 'kg';
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                        if (row.inventoryItemId != null && controller.text.isEmpty) {
                          try {
                            final existing = _inventoryItems.firstWhere(
                              (m) => m['id']?.toString() == row.inventoryItemId,
                            );
                            final name = existing['name'] as String? ?? '';
                            final plu = existing['plu_code']?.toString() ?? '';
                            controller.text = plu.isNotEmpty ? '$name (PLU: $plu)' : name;
                          } catch (_) {}
                        }
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Product (type to search)',
                            hintText: 'Search by name or PLU...',
                            border: OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: Icon(Icons.search, size: 18),
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            child: SizedBox(
                              width: 400,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (_, i) {
                                  final m = options.elementAt(i);
                                  final name = m['name'] as String? ?? '';
                                  final plu = m['plu_code']?.toString() ?? '';
                                  return ListTile(
                                    dense: true,
                                    title: Text(name),
                                    subtitle: plu.isNotEmpty ? Text('PLU: $plu') : null,
                                    onTap: () => onSelected(m),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_outputRows.length > 1)
                    IconButton(
                      onPressed: () => _removeOutputRow(index),
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger, size: 22),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      controller: row.qtyController,
                      decoration: const InputDecoration(
                        labelText: 'Qty produced',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(row.unit, style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: row.notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final outputs = <Map<String, dynamic>>[];
    // Only validate outputs if batch is complete
    if (widget.batch.status == ProductionBatchStatus.complete) {
      for (final row in _outputRows) {
        if (row.inventoryItemId == null || row.inventoryItemId!.isEmpty) continue;
        final qty = double.tryParse(row.qtyController.text);
        if (qty == null || qty <= 0) continue;
        outputs.add({
          'inventory_item_id': row.inventoryItemId,
          'qty_produced': qty,
          'unit': row.unit,
          'notes': row.notesController.text.trim().isEmpty ? null : row.notesController.text.trim(),
        });
      }
      if (outputs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one output product with quantity'), backgroundColor: AppColors.danger),
        );
        return;
      }
    }

    final actuals = <String, double>{};
    for (final entry in _actualControllers.entries) {
      final v = double.tryParse(entry.value.text);
      if (v != null && v >= 0) actuals[entry.key] = v;
    }
    final costTotal = double.tryParse(_costTotalController.text);
    setState(() => _saving = true);
    try {
      await widget.batchRepo.editBatch(
        batchId: widget.batch.id,
        newIngredientQtys: actuals,
        newOutputs: outputs,
        editedBy: AuthService().getCurrentStaffId(),
        costTotal: costTotal,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Batch updated — stock adjusted'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.danger),
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
        title: Text('Edit batch ${widget.batch.batchNumber}'),
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingredient quantities', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            ..._batchIngredients.map((bi) {
              final ri = _ingredientById[bi.ingredientId];
              final name = ri?.ingredientName ?? (bi.ingredientId.length >= 8 ? bi.ingredientId.substring(0, 8) : bi.ingredientId);
              final ctrl = _actualControllers[bi.ingredientId];
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
                        decoration: const InputDecoration(labelText: 'Quantity', isDense: true),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => _calculateCost(),
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
            if (widget.batch.status == ProductionBatchStatus.complete) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Outputs', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: _addOutputRow,
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                    tooltip: 'Add output row',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(_outputRows.length, (i) => _buildOutputRow(i)),
            ],
            const SizedBox(height: 16),
            if (_costCalculated) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AUTO-CALCULATED COST',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Ingredients:', style: TextStyle(fontSize: 13)),
                        Text('R${_calculatedIngredientCost.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Labour (${_recipePrepTimeMinutes}min × '
                            'R${_labourRatePerHour.toStringAsFixed(2)}/hr '
                            '[${AdminConfig.roleDisplayLabel(_recipeRequiredRole)}]):',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text('R${_calculatedLabourCost.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          'R${_calculatedTotalCost.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Override below if needed',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            TextFormField(
              controller: _costTotalController,
              decoration: InputDecoration(
                labelText: _costCalculated
                    ? 'Override total cost (optional)'
                    : 'Total cost (optional)',
                hintText: 'e.g. 1250.00',
                border: const OutlineInputBorder(),
                suffixIcon: _costCalculated
                    ? IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        tooltip: 'Reset to calculated',
                        onPressed: () => setState(() =>
                            _costTotalController.text =
                                _calculatedTotalCost.toStringAsFixed(2)),
                      )
                    : null,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _saving
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save changes (adjust stock)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
