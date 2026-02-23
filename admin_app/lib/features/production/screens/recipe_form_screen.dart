import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/form_widgets.dart';
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
  late bool _isActive;
  String? _outputProductId;
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
      _descriptionController.text = widget.recipe!.description ?? '';
      _categoryController.text = widget.recipe!.category ?? '';
      _expectedYieldController.text = widget.recipe!.expectedYieldPct.toString();
      _batchSizeController.text = widget.recipe!.batchSizeKg.toString();
      _isActive = widget.recipe!.isActive;
      _outputProductId = widget.recipe!.outputProductId;
    } else {
      _expectedYieldController.text = '95';
      _batchSizeController.text = '10';
      _isActive = true;
    }
    _loadInventory();
    _loadCategories();
    if (widget.recipe != null) _loadIngredients();
  }

  Future<void> _loadInventory() async {
    try {
      final r = await _client
          .from('inventory_items')
          .select('id, name')
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

  Future<void> _loadCategories() async {
    try {
      final r = await _client.from('categories').select('id, name').order('name');
      if (mounted) setState(() => _categories = List<Map<String, dynamic>>.from(r as List));
    } catch (_) {}
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
      final data = <String, dynamic>{
        'name': name,
        'pos_display_name': name,
        'category_id': categoryId,
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
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
          servings: widget.recipe!.servings,
          prepTimeMinutes: widget.recipe!.prepTimeMinutes,
          cookTimeMinutes: widget.recipe!.cookTimeMinutes,
          difficulty: widget.recipe!.difficulty,
          isActive: _isActive,
          outputProductId: _outputProductId?.isEmpty == true ? null : _outputProductId,
          expectedYieldPct: expectedYield,
          batchSizeKg: batchSize,
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
        final created = Recipe(
          id: '',
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
          servings: 1,
          isActive: _isActive,
          outputProductId: _outputProductId?.isEmpty == true ? null : _outputProductId,
          expectedYieldPct: expectedYield,
          batchSizeKg: batchSize,
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
                label: 'Description (optional)',
                hint: 'Short description',
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
                  DropdownButtonFormField<String>(
                    value: _outputProductId,
                    decoration: const InputDecoration(
                      labelText: 'Select product',
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('— Select —')),
                      ..._inventoryItems.map((e) {
                        final id = e['id'] as String?;
                        final name = e['name'] as String? ?? '';
                        return DropdownMenuItem(value: id, child: Text(name));
                      }),
                    ],
                    onChanged: (v) => setState(() => _outputProductId = v),
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
              child: DropdownButtonFormField<String>(
                value: row.inventoryItemId,
                decoration: const InputDecoration(labelText: 'Linked item', isDense: true),
                items: [
                  const DropdownMenuItem(value: null, child: Text('—')),
                  ..._inventoryItems.map((e) {
                    final id = e['id'] as String?;
                    final name = e['name'] as String? ?? '';
                    return DropdownMenuItem(value: id, child: Text(name.length > 15 ? '${name.substring(0, 15)}…' : name));
                  }),
                ],
                onChanged: (v) => row.inventoryItemId = v,
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
