import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/admin_config.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../inventory/constants/category_mappings.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';
import '../services/recipe_repository.dart';

/// Blueprint §5.5: Create/Edit Recipe — Output Product, Expected Yield %, ingredients per batch size.
class RecipeFormScreen extends StatefulWidget {
  final Recipe? recipe;

  const RecipeFormScreen({super.key, this.recipe});

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _expectedYieldController = TextEditingController();
  final _batchSizeController = TextEditingController();
  final _prepTimeController = TextEditingController();
  late bool _isActive;
  String? _outputProductId;
  String? _requiredRole;
  double _avgLabourRate = 0.0;
  bool _loadingLabourRate = false;
  bool _goesToDryer = false;
  String? _dryerOutputProductId;
  /// C5: Explicit choice — link to existing product or create new (no auto-create, no duplicate).
  bool _outputProductLinkExisting = true;
  List<_IngredientRow> _ingredients = [];
  List<Map<String, dynamic>> _inventoryItems = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loadingInventory = true;
  bool _saving = false;
  // Recipe costing
  double _calculatedIngredientCost = 0.0;
  double _calculatedLabourCost = 0.0;
  double _calculatedTotalCost = 0.0;
  double _calculatedCostPerKg = 0.0;
  bool _costCalculated = false;
  // Cost prices keyed by inventory_item_id — loaded once, refreshed on demand
  Map<String, double> _costPriceCache = {};
  final _repo = RecipeRepository();
  final _client = SupabaseService.client;

  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      _nameController.text = widget.recipe!.name;
      _descriptionController.text = widget.recipe!.instructions ?? '';
      _categoryController.text = widget.recipe!.category ?? '';
      _expectedYieldController.text = widget.recipe!.expectedYieldPct.toString();
      _batchSizeController.text = widget.recipe!.batchSizeKg.toString();
      _prepTimeController.text = (widget.recipe!.prepTimeMinutes ?? 0).toString();
      _isActive = widget.recipe!.isActive;
      _outputProductId = widget.recipe!.outputProductId;
      _requiredRole = widget.recipe!.requiredRole ?? 'butchery_assistant';
      _goesToDryer = widget.recipe!.goesToDryer;
      _dryerOutputProductId = widget.recipe!.dryerOutputProductId;
    } else {
      _expectedYieldController.text = '95';
      _batchSizeController.text = '10';
      _prepTimeController.text = '0';
      _isActive = true;
      _requiredRole = 'butchery_assistant';
    }
    _loadInventory();
    _loadCategories();
    _loadLabourRate(_requiredRole ?? 'butchery_assistant');
    if (widget.recipe != null) _loadIngredients();
  }

  Future<void> _loadInventory() async {
    try {
      final r = await _client
          .from('inventory_items')
          .select('id, name, plu_code, barcode, cost_price, unit_type')
          .eq('is_active', true)
          .order('name');
      if (mounted) {
        setState(() {
          _inventoryItems = List<Map<String, dynamic>>.from(r as List);
          _costPriceCache = {
            for (final item in _inventoryItems)
              if (item['id'] != null && item['cost_price'] != null)
                item['id'] as String:
                    (item['cost_price'] as num).toDouble(),
          };
          _loadingInventory = false;
        });
        if (mounted) _calculateCost();
      }
    } catch (_) {
      if (mounted) setState(() => _loadingInventory = false);
    }
  }

  /// Filter inventory items by search (name, PLU, barcode). Minimum 2 characters to avoid loading all products.
  List<Map<String, dynamic>> _filterProducts(String search) {
    final q = search.trim();
    if (q.length < 2) return [];
    final lower = q.toLowerCase();
    return _inventoryItems.where((e) {
      final name = (e['name'] as String? ?? '').toLowerCase();
      final plu = (e['plu_code']?.toString() ?? '').toLowerCase();
      final barcode = (e['barcode']?.toString() ?? '').toLowerCase();
      return name.contains(lower) || plu.contains(lower) || barcode.contains(lower);
    }).toList();
  }

  /// Display label for product: "PLU123 — Beef Fillet"
  String _productLabel(Map<String, dynamic> e) {
    final plu = e['plu_code']?.toString() ?? '—';
    final name = e['name'] as String? ?? '';
    return '$plu — $name';
  }

  /// Show searchable product picker dialog; returns selected product id or null. Min 2 chars to filter.
  Future<String?> _showProductPicker({String? currentValue}) async {
    final searchController = TextEditingController();
    List<Map<String, dynamic>> filtered = [];
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialog) {
            final query = searchController.text;
            if (query.trim().length >= 2) {
              filtered = _filterProducts(query);
            } else {
              filtered = [];
            }
            return AlertDialog(
              title: const Text('Select product'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search by name, PLU or barcode',
                        hintText: 'Type at least 2 characters...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setDialog(() {}),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: query.trim().length < 2
                          ? const Center(
                              child: Text(
                                'Type at least 2 characters to search',
                                style: TextStyle(color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : filtered.isEmpty
                              ? const Center(child: Text('No products match'))
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: filtered.length,
                                  itemBuilder: (_, i) {
                                    final e = filtered[i];
                                    final id = e['id'] as String?;
                                    final selected = id == currentValue;
                                    return ListTile(
                                      title: Text(_productLabel(e), style: const TextStyle(fontSize: 14)),
                                      selected: selected,
                                      onTap: () => Navigator.pop(ctx, id),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, ''),
                  child: const Text('Clear'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    ).then((v) {
      searchController.dispose();
      return v;
    });
  }

  Future<void> _loadCategories() async {
    try {
      final r = await _client
          .from('categories')
          .select('id, name')
          .eq('active', true)
          .order('sort_order');
      if (mounted) setState(() => _categories = List<Map<String, dynamic>>.from(r as List));
    } catch (_) {}
  }

  Future<void> _loadLabourRate(String role) async {
    setState(() => _loadingLabourRate = true);
    try {
      final rows = await _client
          .from('staff_profiles')
          .select('hourly_rate')
          .eq('role', role)
          .eq('is_active', true);
      final list = List<Map<String, dynamic>>.from(rows as List);
      double avg = 0.0;
      if (list.isNotEmpty) {
        final rates = list
            .map((r) => (r['hourly_rate'] as num?)?.toDouble() ?? 0.0)
            .where((r) => r > 0)
            .toList();
        if (rates.isNotEmpty) {
          avg = rates.reduce((a, b) => a + b) / rates.length;
        }
      }
      // Fallback to SA minimum wage if no staff data
      if (avg == 0.0) avg = AdminConfig.minimumWagePerHour;
      if (mounted) {
        setState(() {
        _avgLabourRate = avg;
        _loadingLabourRate = false;
      });
      }
      if (mounted) _calculateCost();
    } catch (_) {
      if (mounted) {
        setState(() {
        _avgLabourRate = AdminConfig.minimumWagePerHour; // SA minimum wage fallback
        _loadingLabourRate = false;
      });
      }
      if (mounted) _calculateCost();
    }
  }

  void _calculateCost() {
    final batchSize =
        double.tryParse(_batchSizeController.text) ?? 0;
    final expectedYield =
        double.tryParse(_expectedYieldController.text) ?? 100;
    final prepMinutes =
        int.tryParse(_prepTimeController.text) ?? 0;

    if (batchSize <= 0) {
      setState(() => _costCalculated = false);
      return;
    }

    double ingredientTotal = 0.0;
    for (final row in _ingredients) {
      if (row.inventoryItemId == null ||
          row.inventoryItemId!.isEmpty) {
        continue;
      }
      final cp = _costPriceCache[row.inventoryItemId];
      if (cp == null || cp <= 0) continue;
      final qty = row.quantity;
      if (qty <= 0) continue;

      // Convert to kg-equivalent before multiplying by cost_price
      double qtyInKg;
      final unit = row.unit.trim().toLowerCase();
      if (unit == 'g') {
        qtyInKg = qty / 1000.0;
      } else if (unit == 'ml') {
        qtyInKg = qty / 1000.0;
      } else {
        // kg, l, units, or anything else — use as-is
        qtyInKg = qty;
      }
      final yieldFactor = row.yieldPct / 100.0;
      final effectiveCost = cp / yieldFactor;
      ingredientTotal += qtyInKg * effectiveCost;
    }

    final labourCost =
        (prepMinutes / 60.0) * _avgLabourRate;
    final total = ingredientTotal + labourCost;
    final actualYieldKg = batchSize * (expectedYield / 100.0);
    final costPerKg =
        actualYieldKg > 0 ? total / actualYieldKg : 0.0;

    setState(() {
      _calculatedIngredientCost = ingredientTotal;
      _calculatedLabourCost = labourCost;
      _calculatedTotalCost = total;
      _calculatedCostPerKg = costPerKg;
      _costCalculated = true;
    });
  }

  /// C5: Create new output product (minimal) — no auto-create; explicit user action only.
  Future<String?> _showCreateOutputProductDialog() async {
    final nameController = TextEditingController(text: _nameController.text.trim());
    String? categoryId;
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setDialog) => AlertDialog(
              title: const Text('Create output product'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Creates a new inventory product and links it to this recipe.'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product name *',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setDialog(() {}),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category (optional)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('— None —')),
                        ..._categories.map((e) {
                          final id = e['id'] as String?;
                          final name = e['name'] as String? ?? '';
                          return DropdownMenuItem(value: id, child: Text(name));
                        }),
                      ],
                      onChanged: (v) => setDialog(() => categoryId = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Product name is required')),
                      );
                      return;
                    }
                    Navigator.pop(ctx, 'create');
                  },
                  child: const Text('Create'),
                ),
              ],
            ),
          );
        },
      );
      if (result != 'create' || !mounted) return null;
      final name = nameController.text.trim();
      String? categoryName;
      if (categoryId != null) {
        for (final c in _categories) {
          if (c['id']?.toString() == categoryId) {
            categoryName = c['name'] as String?;
            break;
          }
        }
        categoryName ??= kCategoryIdToName[categoryId!];
      }
      final data = <String, dynamic>{
        'name': name,
        'pos_display_name': name,
        'category_id': categoryId,
        'category': categoryName,
        'is_active': true,
        'unit_type': 'kg',
        'sell_price': 0,
        'cost_price': 0,
      };
      final res = await _client.from('inventory_items').insert(data).select('id').single();
      final id = res['id'] as String?;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product "$name" created'), backgroundColor: AppColors.success),
        );
      }
      return id;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.danger),
        );
      }
      return null;
    } finally {
      nameController.dispose();
    }
  }

  Future<void> _loadIngredients() async {
    if (widget.recipe == null) return;
    try {
      final list = await _repo.getIngredientsByRecipe(widget.recipe!.id);
      if (mounted) {
        setState(() {
          _ingredients = list
              .map((ri) => _IngredientRow(
                    ingredientName: ri.ingredientName,
                    inventoryItemId: ri.inventoryItemId,
                    quantity: ri.quantity,
                    unit: ri.unit,
                    isOptional: ri.isOptional,
                    recipeIngredientId: ri.id,
                    yieldPct: ri.yieldPct,
                  ))
              .toList();
        });
      }
      _calculateCost();
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _expectedYieldController.dispose();
    _batchSizeController.dispose();
    _prepTimeController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add(_IngredientRow(
        ingredientName: '',
        quantity: 0,
        unit: 'kg',
      ));
    });
    _calculateCost();
  }

  void _removeIngredient(int index) {
    setState(() => _ingredients.removeAt(index));
    _calculateCost();
  }

  Future<void> _confirmDeleteRecipe(Recipe recipe) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete recipe?'),
        content: Text('Delete ${recipe.name}? This cannot be undone.'),
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
      await _repo.deleteRecipe(recipe.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // C5: Output product required — no auto-create; user must link existing or create new.
    if (_outputProductId == null || _outputProductId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select an output product (Link to existing) or create one (Create new). Required for production.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    final expectedYield = double.tryParse(_expectedYieldController.text) ?? 95;
    final batchSize = double.tryParse(_batchSizeController.text) ?? 10;
    final costPerUnit = _costCalculated && _calculatedCostPerKg > 0
        ? _calculatedCostPerKg
        : null;
    if (expectedYield <= 0 || expectedYield > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expected yield % must be 0–100'), backgroundColor: AppColors.danger),
      );
      return;
    }
    if (batchSize <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Batch size must be positive'), backgroundColor: AppColors.danger),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.recipe != null) {
        final updated = Recipe(
          id: widget.recipe!.id,
          name: _nameController.text.trim(),
          instructions: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
          servings: widget.recipe!.servings,
          prepTimeMinutes: int.tryParse(_prepTimeController.text) ?? 0,
          cookTimeMinutes: widget.recipe!.cookTimeMinutes,
          difficulty: widget.recipe!.difficulty,
          isActive: _isActive,
          outputProductId: _outputProductId?.isEmpty == true ? null : _outputProductId,
          expectedYieldPct: expectedYield,
          batchSizeKg: batchSize,
          costPerUnit: costPerUnit,
          requiredRole: _requiredRole,
          goesToDryer: _goesToDryer,
          dryerOutputProductId: _goesToDryer ? _dryerOutputProductId : null,
          createdBy: widget.recipe!.createdBy,
          createdAt: widget.recipe!.createdAt,
          updatedAt: DateTime.now(),
        );
        await _repo.updateRecipe(updated);
        for (final row in _ingredients) {
          if (row.recipeIngredientId != null) {
            final ing = RecipeIngredient(
              id: row.recipeIngredientId!,
              recipeId: widget.recipe!.id,
              ingredientName: row.ingredientName.trim().isEmpty ? 'Ingredient' : row.ingredientName.trim(),
              inventoryItemId: row.inventoryItemId?.isEmpty == true ? null : row.inventoryItemId,
              quantity: row.quantity,
              unit: row.unit.trim().isEmpty ? 'kg' : row.unit.trim(),
              isOptional: row.isOptional,
            );
            await _repo.updateIngredient(ing);
          } else {
            final ing = RecipeIngredient(
              id: '',
              recipeId: widget.recipe!.id,
              ingredientName: row.ingredientName.trim().isEmpty ? 'Ingredient' : row.ingredientName.trim(),
              inventoryItemId: row.inventoryItemId?.isEmpty == true ? null : row.inventoryItemId,
              quantity: row.quantity,
              unit: row.unit.trim().isEmpty ? 'kg' : row.unit.trim(),
              isOptional: row.isOptional,
            );
            await _repo.createIngredient(ing);
          }
        }
      } else {
        final staffId = AuthService().getCurrentStaffId();
        final created = Recipe(
          id: '',
          name: _nameController.text.trim(),
          instructions: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
          servings: 1,
          prepTimeMinutes: int.tryParse(_prepTimeController.text) ?? 0,
          isActive: _isActive,
          outputProductId: _outputProductId?.isEmpty == true ? null : _outputProductId,
          expectedYieldPct: expectedYield,
          batchSizeKg: batchSize,
          costPerUnit: costPerUnit,
          requiredRole: _requiredRole,
          goesToDryer: _goesToDryer,
          dryerOutputProductId: _goesToDryer ? _dryerOutputProductId : null,
          createdBy: staffId.isEmpty ? null : staffId,
        );
        final saved = await _repo.createRecipe(created);
        for (final row in _ingredients) {
          final ing = RecipeIngredient(
            id: '',
            recipeId: saved.id,
            ingredientName: row.ingredientName.trim().isEmpty ? 'Ingredient' : row.ingredientName.trim(),
            inventoryItemId: row.inventoryItemId?.isEmpty == true ? null : row.inventoryItemId,
            quantity: row.quantity,
            unit: row.unit.trim().isEmpty ? 'kg' : row.unit.trim(),
            isOptional: row.isOptional,
            yieldPct: row.yieldPct,
          );
          await _repo.createIngredient(ing);
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe saved'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.recipe != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit recipe' : 'Add recipe'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (isEditing && widget.recipe != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDeleteRecipe(widget.recipe!),
              tooltip: 'Delete recipe',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormWidgets.textFormField(
                controller: _nameController,
                label: 'Recipe name',
                hint: 'e.g. Traditional Boerewors',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                prefixIcon: const Icon(Icons.menu_book),
              ),
              const SizedBox(height: 16),
              FormWidgets.textFormField(
                controller: _descriptionController,
                label: 'Instructions (optional)',
                hint: 'Method / steps',
                maxLines: 2,
                prefixIcon: const Icon(Icons.description_outlined),
              ),
              const SizedBox(height: 16),
              FormWidgets.textFormField(
                controller: _categoryController,
                label: 'Category (optional)',
                hint: 'e.g. Sausages',
                prefixIcon: const Icon(Icons.category_outlined),
              ),
              const SizedBox(height: 16),
              const Text('Output product (Blueprint: required for production)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: _outputProductLinkExisting,
                    onChanged: (v) => setState(() {
                      _outputProductLinkExisting = true;
                      if (_outputProductId != null && !_inventoryItems.any((e) => e['id'] == _outputProductId)) {
                        _outputProductId = null;
                      }
                    }),
                  ),
                  const Text('Link to existing product'),
                  const SizedBox(width: 16),
                  Radio<bool>(
                    value: false,
                    groupValue: _outputProductLinkExisting,
                    onChanged: (v) => setState(() {
                      _outputProductLinkExisting = false;
                      _outputProductId = null;
                    }),
                  ),
                  const Text('Create new product'),
                ],
              ),
              const SizedBox(height: 8),
              if (_outputProductLinkExisting) ...[
                if (_loadingInventory)
                  const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
                else
                  InkWell(
                    onTap: () async {
                      final id = await _showProductPicker(currentValue: _outputProductId);
                      if (id == null || !mounted) return;
                      setState(() => _outputProductId = id.isEmpty ? null : id);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Select product',
                        border: OutlineInputBorder(),
                        filled: true,
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      child: Text(
                        _outputProductId == null
                            ? '— Select —'
                            : _productLabel(_inventoryItems.firstWhere(
                                (e) => e['id'] == _outputProductId,
                                orElse: () => {'plu_code': '—', 'name': _outputProductId ?? ''},
                              )),
                        style: TextStyle(
                          color: _outputProductId == null ? AppColors.textSecondary : null,
                        ),
                      ),
                    ),
                  ),
              ] else ...[
                if (_outputProductId != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _inventoryItems.cast<Map<String, dynamic>?>().where((e) => e != null && e['id'] == _outputProductId).isNotEmpty
                              ? _inventoryItems.firstWhere((e) => e['id'] == _outputProductId)['name']?.toString() ?? 'Product created'
                              : 'Product created',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final id = await _showCreateOutputProductDialog();
                    if (id != null && mounted) {
                      setState(() {
                        _outputProductId = id;
                        _loadInventory();
                      });
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: Text(_outputProductId == null ? 'Create output product' : 'Create another (replace selection)'),
                ),
              ],
              const SizedBox(height: 16),
              FormWidgets.textFormField(
                controller: _expectedYieldController,
                label: 'Expected yield % (e.g. 95 = 5% loss)',
                hint: '95',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                onChanged: (_) => _calculateCost(),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0 || n > 100) return 'Enter 0–100';
                  return null;
                },
                prefixIcon: const Icon(Icons.percent),
              ),
              const SizedBox(height: 16),
              FormWidgets.textFormField(
                controller: _batchSizeController,
                label: 'Batch size (kg) — ingredient quantities are per this',
                hint: '10',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                onChanged: (_) => _calculateCost(),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Must be positive';
                  return null;
                },
                prefixIcon: const Icon(Icons.scale),
              ),
              const SizedBox(height: 16),
              FormWidgets.textFormField(
                controller: _prepTimeController,
                label: 'Prep time (minutes)',
                hint: 'e.g. 60 for 1 hour of labour',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d]'))],
                onChanged: (_) => _calculateCost(),
                prefixIcon: const Icon(Icons.timer_outlined),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Required staff role (for labour cost)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _requiredRole,
                    decoration: const InputDecoration(
                      labelText: 'Staff role',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'owner', child: Text('Owner')),
                      DropdownMenuItem(value: 'manager', child: Text('Manager')),
                      DropdownMenuItem(value: 'blockman', child: Text('Blockman')),
                      DropdownMenuItem(value: 'butchery_assistant', child: Text('Butchery Assistant')),
                      DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _requiredRole = v);
                      _loadLabourRate(v);
                    },
                  ),
                  const SizedBox(height: 6),
                  if (_loadingLabourRate)
                    const Text(
                      'Loading rate...',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _avgLabourRate > 0
                                  ? 'Avg rate for ${AdminConfig.roleDisplayLabel(_requiredRole ?? '')}: '
                                    'R${_avgLabourRate.toStringAsFixed(2)}/hr '
                                    '(from staff records${_avgLabourRate == AdminConfig.minimumWagePerHour ? " — using SA minimum wage fallback" : ""})'
                                  : 'No staff data — using SA minimum wage: R${AdminConfig.minimumWagePerHour.toStringAsFixed(2)}/hr',
                              style: const TextStyle(fontSize: 12, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (_costCalculated) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'RECIPE COST BREAKDOWN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _calculateCost,
                                icon: const Icon(Icons.refresh, size: 14),
                                label: const Text('Recalculate',
                                    style: TextStyle(fontSize: 12)),
                                style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Per-ingredient breakdown
                          ..._ingredients.where((row) =>
                              row.inventoryItemId != null &&
                              row.inventoryItemId!.isNotEmpty &&
                              _costPriceCache.containsKey(row.inventoryItemId))
                          .map((row) {
                            final cp = _costPriceCache[row.inventoryItemId]!;
                            final unit = row.unit.trim().toLowerCase();
                            double qtyInKg;
                            if (unit == 'g' || unit == 'ml') {
                              qtyInKg = row.quantity / 1000.0;
                            } else {
                              qtyInKg = row.quantity;
                            }
                            final yieldFactor = row.yieldPct / 100.0;
                            final effectiveCost = cp / yieldFactor;
                            final lineCost = qtyInKg * effectiveCost;
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      row.ingredientName.isEmpty
                                          ? 'Ingredient'
                                          : row.ingredientName,
                                      style: const TextStyle(
                                          fontSize: 13),
                                    ),
                                  ),
                                  Text(
                                    '${row.quantity} ${row.unit}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(width: 8),
                                  if (row.yieldPct < 100) ...[
                                    Text(
                                      '÷ ${(row.yieldPct / 100).toStringAsFixed(2)} yield',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.orange),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '= R${effectiveCost.toStringAsFixed(2)}/kg',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange),
                                    ),
                                  ] else
                                    Text(
                                      '× R${cp.toStringAsFixed(2)}/kg',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary),
                                    ),
                                  const Spacer(),
                                  Text(
                                    'R${lineCost.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            );
                          }),
                          // Ingredients with no cost price
                          ..._ingredients.where((row) =>
                              row.inventoryItemId != null &&
                              row.inventoryItemId!.isNotEmpty &&
                              !_costPriceCache.containsKey(row.inventoryItemId))
                          .map((row) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    row.ingredientName.isEmpty
                                        ? 'Ingredient'
                                        : row.ingredientName,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                const Text(
                                  'no cost price set',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontStyle: FontStyle.italic),
                                ),
                                const Spacer(),
                                const Text('R 0.00',
                                    style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          )),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Ingredients:',
                                  style: TextStyle(fontSize: 13)),
                              Text(
                                'R${_calculatedIngredientCost.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Labour (${_prepTimeController.text}min'
                                ' × R${_avgLabourRate.toStringAsFixed(2)}/hr):',
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                'R${_calculatedLabourCost.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Batch total:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600)),
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
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Yield: ${_batchSizeController.text}kg'
                                ' × ${_expectedYieldController.text}%'
                                ' = ${((double.tryParse(_batchSizeController.text) ?? 0) * ((double.tryParse(_expectedYieldController.text) ?? 100) / 100)).toStringAsFixed(2)}kg output',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Cost per kg output:',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14),
                              ),
                              Text(
                                'R${_calculatedCostPerKg.toStringAsFixed(2)}/kg',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Suggested sell prices at common GP targets
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Suggested sell prices:',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                      letterSpacing: 0.3),
                                ),
                                const SizedBox(height: 6),
                                ...[25, 30, 35, 40].map((gp) {
                                  final sell = _calculatedCostPerKg > 0
                                      ? _calculatedCostPerKg /
                                          (1 - gp / 100.0)
                                      : 0.0;
                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('$gp% GP:',
                                          style: const TextStyle(
                                              fontSize: 12)),
                                      Text(
                                        'R${sell.toStringAsFixed(2)}/kg',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Automatically send to dryer when batch completes'),
                subtitle: const Text('Enable for biltong, droewors, chilli bites'),
                value: _goesToDryer,
                onChanged: (v) => setState(() {
                  _goesToDryer = v;
                  if (!v) _dryerOutputProductId = null;
                }),
                activeThumbColor: AppColors.primary,
              ),
              if (_goesToDryer) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _dryerOutputProductId,
                  decoration: const InputDecoration(
                    labelText: 'Finished dried product (inventory item) *',
                    helperText: 'Product added to stock after dryer weigh-out',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('— Select product —')),
                    ..._inventoryItems.map((item) => DropdownMenuItem(
                      value: item['id'] as String,
                      child: Text(item['name'] as String? ?? ''),
                    )),
                  ],
                  validator: _goesToDryer
                      ? (v) => (v == null || v.isEmpty) ? 'Select the finished dried product' : null
                      : null,
                  onChanged: (v) => setState(() => _dryerOutputProductId = v),
                ),
              ],
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                activeThumbColor: AppColors.primary,
              ),
              const SizedBox(height: 24),
              const Text('Ingredients (per batch size)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              ..._ingredients.asMap().entries.map((e) {
                final i = e.key;
                final row = e.value;
                return _buildIngredientRow(i, row);
              }),
              TextButton.icon(
                onPressed: _addIngredient,
                icon: const Icon(Icons.add),
                label: const Text('Add ingredient'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _saving
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientRow(int index, _IngredientRow row) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: row.ingredientName,
                    decoration: const InputDecoration(labelText: 'Name', isDense: true),
                    onChanged: (v) => row.ingredientName = v,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final id = await _showProductPicker(currentValue: row.inventoryItemId);
                      if (id == null || !mounted) return;
                      setState(() => row.inventoryItemId = id.isEmpty ? null : id);
                      _calculateCost();
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Linked item',
                        isDense: true,
                        suffixIcon: Icon(Icons.arrow_drop_down, size: 20),
                      ),
                      child: Text(
                        row.inventoryItemId == null || row.inventoryItemId!.isEmpty
                            ? '—'
                            : _productLabel(_inventoryItems.firstWhere(
                                (e) => e['id'] == row.inventoryItemId,
                                orElse: () => {'plu_code': '—', 'name': row.inventoryItemId ?? ''},
                              )),
                        style: TextStyle(
                          fontSize: 14,
                          color: (row.inventoryItemId == null || row.inventoryItemId!.isEmpty) ? AppColors.textSecondary : null,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: row.quantity > 0 ? row.quantity.toString() : '',
                    decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) {
                      row.quantity = double.tryParse(v) ?? 0;
                      _calculateCost();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    initialValue: row.unit,
                    decoration: const InputDecoration(labelText: 'Unit', isDense: true),
                    onChanged: (v) {
                      row.unit = v;
                      _calculateCost();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
                  onPressed: () => _removeIngredient(index),
                  tooltip: 'Remove',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 130,
                  child: StatefulBuilder(
                    builder: (ctx, setRow) => TextFormField(
                      initialValue: row.yieldPct == 100.0
                          ? '100'
                          : row.yieldPct.toStringAsFixed(0),
                      decoration: const InputDecoration(
                        labelText: 'Yield %',
                        isDense: true,
                        suffixText: '%',
                        helperText: '100 = no loss',
                        helperStyle: TextStyle(fontSize: 10),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true),
                      onChanged: (v) {
                        final val =
                            double.tryParse(v) ?? 100.0;
                        setState(() {
                          row.yieldPct = val.clamp(1.0, 100.0);
                        });
                        _calculateCost();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (row.yieldPct < 99.9 &&
                    row.inventoryItemId != null &&
                    row.inventoryItemId!.isNotEmpty)
                  Builder(builder: (ctx) {
                    final cp =
                        _costPriceCache[row.inventoryItemId];
                    if (cp == null || cp <= 0) {
                      return const SizedBox.shrink();
                    }
                    final effectiveCost =
                        cp / (row.yieldPct / 100.0);
                    final lossPercent =
                        (100 - row.yieldPct).toStringAsFixed(0);
                    return Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: Colors.orange.shade200),
                        ),
                        child: Text(
                          'Effective: R${effectiveCost.toStringAsFixed(2)}/kg '
                          '(after $lossPercent% loss)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientRow {
  String ingredientName;
  String? inventoryItemId;
  double quantity;
  String unit;
  bool isOptional;
  String? recipeIngredientId;
  double yieldPct;

  _IngredientRow({
    this.ingredientName = '',
    this.inventoryItemId,
    this.quantity = 0,
    this.unit = 'kg',
    this.isOptional = false,
    this.recipeIngredientId,
    this.yieldPct = 100.0,
  });
}
