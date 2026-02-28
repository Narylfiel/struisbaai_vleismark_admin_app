import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/core/services/auth_service.dart';
import 'package:admin_app/features/customers/models/customer_recipe.dart';
import 'package:admin_app/features/customers/services/customer_recipe_repository.dart';

/// Add / Edit screen for a customer recipe.
/// [existingRecipe] is null when creating, non-null when editing.
class CustomerRecipeFormScreen extends StatefulWidget {
  final CustomerRecipe? existingRecipe;

  const CustomerRecipeFormScreen({super.key, this.existingRecipe});

  @override
  State<CustomerRecipeFormScreen> createState() =>
      _CustomerRecipeFormScreenState();
}

class _CustomerRecipeFormScreenState extends State<CustomerRecipeFormScreen> {
  final _repo = CustomerRecipeRepository();
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  // ── Controllers ──────────────────────────────────────────
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _servingSizeCtrl = TextEditingController(text: '4');
  final _prepTimeCtrl = TextEditingController(text: '0');
  final _cookTimeCtrl = TextEditingController(text: '0');

  String _status = 'draft';
  bool _saving = false;
  bool _loadingCategories = true;

  // ── Ingredients ──────────────────────────────────────────
  // Each entry: {text: String, optional: bool, controller: TextEditingController}
  final List<Map<String, dynamic>> _ingredients = [];

  // ── Steps ────────────────────────────────────────────────
  final List<TextEditingController> _stepControllers = [];

  // ── Categories ───────────────────────────────────────────
  List<CustomerRecipeCategoryType> _categoryTypes = [];
  final Set<String> _selectedOptionIds = {};

  // ── Images ───────────────────────────────────────────────
  // Existing images (already in DB)
  List<CustomerRecipeImage> _existingImages = [];
  // New images picked but not yet uploaded
  final List<File> _newImageFiles = [];
  String? _pendingPrimaryImageId; // id of existing image to set as primary

  bool get _isEditing => widget.existingRecipe != null;

  @override
  void initState() {
    super.initState();
    _initForm();
    _loadCategories();
  }

  void _initForm() {
    final r = widget.existingRecipe;
    if (r != null) {
      _titleCtrl.text = r.title;
      _descriptionCtrl.text = r.description ?? '';
      _servingSizeCtrl.text = r.servingSize.toString();
      _prepTimeCtrl.text = r.prepTimeMinutes.toString();
      _cookTimeCtrl.text = r.cookTimeMinutes.toString();
      _status = r.status;
      _existingImages = List.from(r.images);

      for (final ing in r.ingredients) {
        final ctrl = TextEditingController(text: ing.ingredientText);
        _ingredients.add({'controller': ctrl, 'optional': ing.isOptional});
      }
      for (final step in r.steps) {
        _stepControllers.add(
            TextEditingController(text: step.instructionText));
      }
      for (final opt in r.categoryAssignments) {
        _selectedOptionIds.add(opt.id);
      }
    }

    // Always start with at least one ingredient and one step row
    if (_ingredients.isEmpty) _addIngredientRow();
    if (_stepControllers.isEmpty) _addStepRow();
  }

  Future<void> _loadCategories() async {
    final types = await _repo.getCategoryTypes(activeOnly: true);
    if (mounted) {
      setState(() {
        _categoryTypes = types;
        _loadingCategories = false;
      });
    }
  }

  // ── Ingredient helpers ────────────────────────────────────

  void _addIngredientRow() {
    setState(() {
      _ingredients.add({
        'controller': TextEditingController(),
        'optional': false,
      });
    });
  }

  void _removeIngredientRow(int index) {
    final ctrl = _ingredients[index]['controller'] as TextEditingController;
    ctrl.dispose();
    setState(() => _ingredients.removeAt(index));
  }

  // ── Step helpers ──────────────────────────────────────────

  void _addStepRow() {
    setState(() => _stepControllers.add(TextEditingController()));
  }

  void _removeStepRow(int index) {
    _stepControllers[index].dispose();
    setState(() => _stepControllers.removeAt(index));
  }

  // ── Image helpers ─────────────────────────────────────────

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _newImageFiles.add(File(picked.path)));
  }

  Future<void> _deleteExistingImage(CustomerRecipeImage img) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete image?'),
        content: const Text('This image will be removed immediately.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
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
      await _repo.deleteRecipeImage(
          imageId: img.id, imageUrl: img.imageUrl);
      setState(() => _existingImages.removeWhere((i) => i.id == img.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(ErrorHandler.friendlyMessage(e)),
              backgroundColor: AppColors.danger),
        );
      }
    }
  }

  // ── Save ──────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();
    final servingSize = int.tryParse(_servingSizeCtrl.text) ?? 4;
    final prepTime = int.tryParse(_prepTimeCtrl.text) ?? 0;
    final cookTime = int.tryParse(_cookTimeCtrl.text) ?? 0;
    final staffId = _auth.getCurrentStaffId();

    final ingredientLines =
        _ingredients.map((i) => (i['controller'] as TextEditingController).text).toList();
    final ingredientOptional =
        _ingredients.map((i) => i['optional'] as bool).toList();
    final stepInstructions =
        _stepControllers.map((c) => c.text).toList();

    setState(() => _saving = true);
    try {
      String recipeId;

      if (_isEditing) {
        recipeId = widget.existingRecipe!.id;
        await _repo.updateRecipe(
          recipeId: recipeId,
          title: title,
          description: description.isEmpty ? null : description,
          servingSize: servingSize,
          prepTimeMinutes: prepTime,
          cookTimeMinutes: cookTime,
          status: _status,
          updatedBy: staffId,
          ingredientLines: ingredientLines,
          ingredientOptional: ingredientOptional,
          stepInstructions: stepInstructions,
          selectedOptionIds: _selectedOptionIds.toList(),
        );
      } else {
        recipeId = await _repo.createRecipe(
          title: title,
          description: description.isEmpty ? null : description,
          servingSize: servingSize,
          prepTimeMinutes: prepTime,
          cookTimeMinutes: cookTime,
          status: _status,
          createdBy: staffId,
          ingredientLines: ingredientLines,
          ingredientOptional: ingredientOptional,
          stepInstructions: stepInstructions,
          selectedOptionIds: _selectedOptionIds.toList(),
        );
      }

      // Upload any new images
      for (int i = 0; i < _newImageFiles.length; i++) {
        final isPrimary = _existingImages.isEmpty && i == 0;
        await _repo.uploadRecipeImage(
          recipeId: recipeId,
          imageFile: _newImageFiles[i],
          isPrimary: isPrimary,
          sortOrder: _existingImages.length + i,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Recipe updated' : 'Recipe created'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(ErrorHandler.friendlyMessage(e)),
              backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _servingSizeCtrl.dispose();
    _prepTimeCtrl.dispose();
    _cookTimeCtrl.dispose();
    for (final i in _ingredients) {
      (i['controller'] as TextEditingController).dispose();
    }
    for (final c in _stepControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        title: Text(_isEditing ? 'Edit Recipe' : 'New Recipe'),
        actions: [
          // Status toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ChoiceChip(
              label: Text(_status == 'published' ? 'Published' : 'Draft'),
              selected: _status == 'published',
              selectedColor: AppColors.success.withValues(alpha: 0.2),
              onSelected: (_) => setState(() =>
                  _status = _status == 'draft' ? 'published' : 'draft'),
            ),
          ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // ── BASIC INFO ──────────────────────────────────
            _sectionHeader('Basic Info'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Recipe Title *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(
                labelText: 'Short description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _servingSizeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Servings',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _prepTimeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Prep time (min)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cookTimeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cook time (min)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── CATEGORIES ──────────────────────────────────
            _sectionHeader('Categories'),
            const SizedBox(height: 12),
            if (_loadingCategories)
              const Padding(
                padding: EdgeInsets.all(8),
                child: LinearProgressIndicator(),
              )
            else
              ..._categoryTypes.map((type) => _buildCategoryTypeSection(type)),
            const SizedBox(height: 24),

            // ── INGREDIENTS ─────────────────────────────────
            _sectionHeader('Ingredients'),
            const SizedBox(height: 12),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _ingredients.length,
              onReorder: (oldIdx, newIdx) {
                setState(() {
                  if (newIdx > oldIdx) newIdx--;
                  final item = _ingredients.removeAt(oldIdx);
                  _ingredients.insert(newIdx, item);
                });
              },
              itemBuilder: (_, i) {
                final ing = _ingredients[i];
                final ctrl = ing['controller'] as TextEditingController;
                return _IngredientRow(
                  key: ValueKey('ing_$i'),
                  controller: ctrl,
                  isOptional: ing['optional'] as bool,
                  onOptionalChanged: (v) =>
                      setState(() => _ingredients[i]['optional'] = v),
                  onRemove: _ingredients.length > 1
                      ? () => _removeIngredientRow(i)
                      : null,
                );
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addIngredientRow,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add ingredient'),
              ),
            ),
            const SizedBox(height: 24),

            // ── STEPS ───────────────────────────────────────
            _sectionHeader('Instructions'),
            const SizedBox(height: 12),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _stepControllers.length,
              onReorder: (oldIdx, newIdx) {
                setState(() {
                  if (newIdx > oldIdx) newIdx--;
                  final ctrl = _stepControllers.removeAt(oldIdx);
                  _stepControllers.insert(newIdx, ctrl);
                });
              },
              itemBuilder: (_, i) {
                return _StepRow(
                  key: ValueKey('step_$i'),
                  stepNumber: i + 1,
                  controller: _stepControllers[i],
                  onRemove: _stepControllers.length > 1
                      ? () => _removeStepRow(i)
                      : null,
                );
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addStepRow,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add step'),
              ),
            ),
            const SizedBox(height: 24),

            // ── IMAGES ──────────────────────────────────────
            _sectionHeader('Images'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Existing images
                ..._existingImages.map((img) => _ExistingImageTile(
                      image: img,
                      onDelete: () => _deleteExistingImage(img),
                      onSetPrimary: img.isPrimary
                          ? null
                          : () async {
                              await _repo.setPrimaryImage(
                                recipeId: widget.existingRecipe!.id,
                                imageId: img.id,
                              );
                              setState(() {
                                for (final i in _existingImages) {
                                  // ignore: avoid_function_literals_in_foreach_calls
                                }
                                _existingImages = _existingImages
                                    .map((i) => CustomerRecipeImage(
                                          id: i.id,
                                          recipeId: i.recipeId,
                                          imageUrl: i.imageUrl,
                                          sortOrder: i.sortOrder,
                                          isPrimary: i.id == img.id,
                                          createdAt: i.createdAt,
                                        ))
                                    .toList();
                              });
                            },
                    )),
                // New (pending) images
                ..._newImageFiles.asMap().entries.map((entry) =>
                    _NewImageTile(
                      file: entry.value,
                      onRemove: () => setState(
                          () => _newImageFiles.removeAt(entry.key)),
                    )),
                // Add button
                _AddImageButton(onTap: _pickImage),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildCategoryTypeSection(CustomerRecipeCategoryType type) {
    final options = type.options.where((o) => o.isActive).toList();
    if (options.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            type.name,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: options.map((opt) {
              final selected = _selectedOptionIds.contains(opt.id);
              return FilterChip(
                label: Text(opt.name, style: const TextStyle(fontSize: 12)),
                selected: selected,
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                onSelected: (_) => setState(() {
                  if (selected) {
                    _selectedOptionIds.remove(opt.id);
                  } else {
                    _selectedOptionIds.add(opt.id);
                  }
                }),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────

class _IngredientRow extends StatelessWidget {
  final TextEditingController controller;
  final bool isOptional;
  final ValueChanged<bool> onOptionalChanged;
  final VoidCallback? onRemove;

  const _IngredientRow({
    super.key,
    required this.controller,
    required this.isOptional,
    required this.onOptionalChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.drag_handle, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'e.g. 2 cups flour',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Optional ingredient',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Optional',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                Checkbox(
                  value: isOptional,
                  onChanged: (v) => onOptionalChanged(v ?? false),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  size: 18, color: AppColors.danger),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int stepNumber;
  final TextEditingController controller;
  final VoidCallback? onRemove;

  const _StepRow({
    super.key,
    required this.stepNumber,
    required this.controller,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.drag_handle, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$stepNumber',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Describe this step...',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              maxLines: 2,
            ),
          ),
          if (onRemove != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    size: 18, color: AppColors.danger),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
  }
}

class _ExistingImageTile extends StatelessWidget {
  final CustomerRecipeImage image;
  final VoidCallback onDelete;
  final VoidCallback? onSetPrimary;

  const _ExistingImageTile({
    required this.image,
    required this.onDelete,
    this.onSetPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            image.imageUrl,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 120,
              height: 120,
              color: AppColors.border,
              child: const Icon(Icons.broken_image, color: AppColors.textSecondary),
            ),
          ),
        ),
        if (image.isPrimary)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Primary',
                  style: TextStyle(fontSize: 9, color: Colors.white)),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
        if (onSetPrimary != null)
          Positioned(
            bottom: 4,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: onSetPrimary,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Set primary',
                      style: TextStyle(fontSize: 9, color: Colors.white)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NewImageTile extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;

  const _NewImageTile({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('New',
                style: TextStyle(fontSize: 9, color: Colors.white)),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddImageButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddImageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 2),
          borderRadius: BorderRadius.circular(8),
          color: AppColors.surfaceBg,
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 32, color: AppColors.textSecondary),
            SizedBox(height: 4),
            Text('Add image',
                style: TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}