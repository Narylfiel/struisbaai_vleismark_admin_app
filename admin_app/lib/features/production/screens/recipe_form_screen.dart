import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
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
  List<_IngredientRow> _ingredients = [];
  List<Map<String, dynamic>> _inventoryItems = [];
  bool _loadingInventory = true;
  bool _saving = false;
  final _repo = RecipeRepository();
  final _client = Supabase.instance.client;

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
              if (_loadingInventory)
                const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
              else
                DropdownButtonFormField<String>(
                  value: _outputProductId,
                  decoration: const InputDecoration(
                    labelText: 'Output product (Blueprint: links to inventory)',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('— None —')),
                    ..._inventoryItems.map((e) {
                      final id = e['id'] as String?;
                      final name = e['name'] as String? ?? '';
                      return DropdownMenuItem(value: id, child: Text(name));
                    }),
                  ],
                  onChanged: (v) => setState(() => _outputProductId = v),
                ),
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
