import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../models/category.dart';
import '../blocs/category/category_bloc.dart';
import '../blocs/category/category_event.dart';
import '../blocs/category/category_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryFormScreen extends StatefulWidget {
  final Category? category;

  const CategoryFormScreen({super.key, this.category});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _sortOrderController = TextEditingController();

  late String _selectedColor;
  late bool _isActive;
  late int _sortOrder;
  String? _selectedParentId;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _notesController.text = widget.category!.notes ?? '';
      _sortOrderController.text = widget.category!.sortOrder.toString();
      _selectedColor = widget.category!.colorCode;
      _isActive = widget.category!.isActive;
      _sortOrder = widget.category!.sortOrder;
      _selectedParentId = widget.category!.parentId;
    } else {
      _selectedColor = CategoryColors.grey;
      _isActive = true;
      _sortOrder = 0;
      _selectedParentId = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;

    return BlocListener<CategoryBloc, CategoryState>(
      listener: (context, state) {
        if (state is CategoryOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        } else if (state is CategoryError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Category' : 'Add Category'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            if (isEditing)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _confirmDelete,
                tooltip: 'Delete Category',
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
                // Color Picker Section
                _buildColorPickerSection(),

                const SizedBox(height: 24),

                // Parent category (optional — blank = top-level)
                BlocBuilder<CategoryBloc, CategoryState>(
                  buildWhen: (prev, curr) => curr is CategoryLoaded,
                  builder: (context, state) {
                    final topLevel = state is CategoryLoaded
                        ? (state.categories.where((c) => c.parentId == null || c.parentId!.isEmpty).toList()
                          ..sort((a, b) {
                            final o = a.sortOrder.compareTo(b.sortOrder);
                            return o != 0 ? o : a.name.compareTo(b.name);
                          }))
                        : <Category>[];
                    return FormWidgets.dropdownFormField<String?>(
                      value: _selectedParentId,
                      label: 'Parent category (optional)',
                      hint: '— Top level —',
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('— Top level —')),
                        ...topLevel
                            .where((c) => c.id != widget.category?.id)
                            .map((c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (v) => setState(() => _selectedParentId = v),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Form Fields
                FormWidgets.textFormField(
                  controller: _nameController,
                  label: 'Category Name',
                  hint: 'Enter category name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Category name is required';
                    }
                    if (value.length < 2) {
                      return 'Category name must be at least 2 characters';
                    }
                    return null;
                  },
                  prefixIcon: const Icon(Icons.category),
                ),

                const SizedBox(height: 16),

                FormWidgets.textFormField(
                  controller: _sortOrderController,
                  label: 'Sort Order',
                  hint: 'Enter sort order (lower numbers appear first)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Sort order is required';
                    }
                    final order = int.tryParse(value);
                    if (order == null || order < 0) {
                      return 'Sort order must be a positive number';
                    }
                    return null;
                  },
                  prefixIcon: const Icon(Icons.sort),
                ),

                const SizedBox(height: 16),

                FormWidgets.textFormField(
                  controller: _notesController,
                  label: 'Notes (Optional)',
                  hint: 'Enter any additional notes',
                  maxLines: 3,
                  prefixIcon: const Icon(Icons.notes),
                ),

                const SizedBox(height: 16),

                // Active Toggle
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('Inactive categories are hidden from POS'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  activeThumbColor: AppColors.primary,
                ),

                const SizedBox(height: 32),

                // Action Buttons
                ActionButtonsWidget(
                  actions: [
                    ActionButtons.cancel(
                      onPressed: () => Navigator.pop(context),
                    ),
                    ActionButtons.save(
                      onPressed: _saveCategory,
                      enabled: !_isLoading,
                    ),
                  ],
                  mainAxisAlignment: MainAxisAlignment.end,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorPickerSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Color',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose a color to represent this category',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Color Preview
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(int.parse(_selectedColor.replaceAll('#', '0xFF'))),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                ),
                const SizedBox(width: 16),
                // Color Picker Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showColorPicker,
                    icon: const Icon(Icons.color_lens),
                    label: const Text('Choose Color'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Predefined Colors
            const Text(
              'Quick Colors',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CategoryColors.availableColors.map((color) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(int.parse(color.replaceAll('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _selectedColor == color ? AppColors.primary : AppColors.border,
                        width: _selectedColor == color ? 2 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: Color(int.parse(_selectedColor.replaceAll('#', '0xFF'))),
            onColorChanged: (color) {
              setState(() {
                _selectedColor = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
              });
            },
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _saveCategory() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final sortOrder = int.parse(_sortOrderController.text);

    final category = Category(
      id: widget.category?.id ?? '',
      name: _nameController.text.trim(),
      colorCode: _selectedColor,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      sortOrder: sortOrder,
      isActive: _isActive,
      parentId: _selectedParentId,
      createdAt: widget.category?.createdAt,
      updatedAt: DateTime.now(),
    );

    if (widget.category != null) {
      context.read<CategoryBloc>().add(UpdateCategory(category));
    } else {
      context.read<CategoryBloc>().add(CreateCategory(category));
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${widget.category!.name}"? '
          'This action cannot be undone and may affect products in this category.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CategoryBloc>().add(DeleteCategory(widget.category!.id));
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}