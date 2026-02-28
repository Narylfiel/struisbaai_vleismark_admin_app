import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/admin_config.dart';
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
          .select('id, name, plu_code, barcode')
          .eq('is_active', true)
          .order('name');
      if (mounted) {
        setState(() {
          _inventoryItems = List<Map<String, dynamic>>.from(r as List);
          _loadingInventory = false;
        });
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
      if (mounted) setState(() {
        _avgLabourRate = avg;
        _loadingLabourRate = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _avgLabourRate = AdminConfig.minimumWagePerHour; // SA minimum wage fallback
        _loadingLabourRate = false;
      });
    }
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
                      value: categoryId,
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
          SnackBar(content: Text('Failed to create product: $e'), backgroundColor: AppColors.danger),
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
                  ))
              .toList();
        });
      }
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
  }

  void _removeIngredient(int index) {
    setState(() => _ingredients.removeAt(index));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
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
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
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
                        Icon(Icons.check_circle, color: AppColors.success, size: 20),
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
                    value: _requiredRole,
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
                activeColor: AppColors.primary,
              ),
              if (_goesToDryer) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _dryerOutputProductId,
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
                activeColor: AppColors.primary,
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
        child: Row(
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
                onChanged: (v) => row.quantity = double.tryParse(v) ?? 0,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: TextFormField(
                initialValue: row.unit,
                decoration: const InputDecoration(labelText: 'Unit', isDense: true),
                onChanged: (v) => row.unit = v,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
              onPressed: () => _removeIngredient(index),
              tooltip: 'Remove',
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

  _IngredientRow({
    this.ingredientName = '',
    this.inventoryItemId,
    this.quantity = 0,
    this.unit = 'kg',
    this.isOptional = false,
    this.recipeIngredientId,
  });
}
