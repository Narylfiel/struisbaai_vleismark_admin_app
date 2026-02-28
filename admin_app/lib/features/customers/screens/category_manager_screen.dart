import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/features/customers/models/customer_recipe.dart';
import 'package:admin_app/features/customers/services/customer_recipe_repository.dart';

/// Category manager screen — owner/manager only.
/// Manages customer_recipe_category_types and their options.
class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  final _repo = CustomerRecipeRepository();
  List<CustomerRecipeCategoryType> _types = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final types = await _repo.getCategoryTypes();
    if (mounted) setState(() {
      _types = types;
      _loading = false;
    });
  }

  // ── TYPE DIALOGS ──────────────────────────────────────────

  Future<void> _showAddTypeDialog() async {
    final nameCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category Type'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Type name (e.g. "Cooking Method")',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result != true || !mounted) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    try {
      await _repo.createCategoryType(
        name: name,
        sortOrder: _types.length,
      );
      _load();
    } catch (e) {
      if (mounted) _showError(ErrorHandler.friendlyMessage(e));
    }
  }

  Future<void> _showEditTypeDialog(CustomerRecipeCategoryType type) async {
    final nameCtrl = TextEditingController(text: type.name);
    bool isActive = type.isActive;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Edit Category Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Type name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                subtitle: const Text('Inactive types are hidden in recipe form'),
                value: isActive,
                onChanged: (v) => setSt(() => isActive = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result != true || !mounted) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    try {
      await _repo.updateCategoryType(
        typeId: type.id,
        name: name,
        sortOrder: type.sortOrder,
        isActive: isActive,
      );
      _load();
    } catch (e) {
      if (mounted) _showError(ErrorHandler.friendlyMessage(e));
    }
  }

  Future<void> _confirmDeleteType(CustomerRecipeCategoryType type) async {
    final optionCount = type.options.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category Type?'),
        content: Text(
          'Delete "${type.name}"?\n\n'
          'This will also delete all $optionCount option(s) under it '
          'and remove them from any recipes. This cannot be undone.',
        ),
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
      await _repo.deleteCategoryType(type.id);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${type.name}" deleted')),
        );
      }
    } catch (e) {
      if (mounted) _showError(ErrorHandler.friendlyMessage(e));
    }
  }

  // ── OPTION DIALOGS ────────────────────────────────────────

  Future<void> _showAddOptionDialog(CustomerRecipeCategoryType type) async {
    final nameCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add option to "${type.name}"'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Option name (e.g. "Pan-Fry")',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result != true || !mounted) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    try {
      await _repo.createCategoryOption(
        typeId: type.id,
        name: name,
        sortOrder: type.options.length,
      );
      _load();
    } catch (e) {
      if (mounted) _showError(ErrorHandler.friendlyMessage(e));
    }
  }

  Future<void> _showEditOptionDialog(
    CustomerRecipeCategoryOption option,
    CustomerRecipeCategoryType type,
  ) async {
    final nameCtrl = TextEditingController(text: option.name);
    bool isActive = option.isActive;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text('Edit "${option.name}"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Option name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                subtitle: const Text('Inactive options hidden in recipe form'),
                value: isActive,
                onChanged: (v) => setSt(() => isActive = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result != true || !mounted) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    try {
      await _repo.updateCategoryOption(
        optionId: option.id,
        name: name,
        sortOrder: option.sortOrder,
        isActive: isActive,
      );
      _load();
    } catch (e) {
      if (mounted) _showError(ErrorHandler.friendlyMessage(e));
    }
  }

  Future<void> _confirmDeleteOption(
    CustomerRecipeCategoryOption option,
    CustomerRecipeCategoryType type,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Option?'),
        content: Text(
          'Delete "${option.name}" from "${type.name}"?\n\n'
          'It will be removed from all recipes that use it.',
        ),
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
      await _repo.deleteCategoryOption(option.id);
      _load();
    } catch (e) {
      if (mounted) _showError(ErrorHandler.friendlyMessage(e));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Recipe Categories'),
        backgroundColor: AppColors.cardBg,
        actions: [
          TextButton.icon(
            onPressed: _showAddTypeDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Type'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _types.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No category types yet.'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddTypeDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Type'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _types.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final type = _types[i];
                    return Card(
                      color: AppColors.cardBg,
                      child: ExpansionTile(
                        leading: Icon(
                          Icons.label_outline,
                          color: type.isActive
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                type.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: type.isActive
                                      ? null
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            if (!type.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Inactive',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          '${type.options.length} option(s)',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'Edit type',
                              onPressed: () => _showEditTypeDialog(type),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: AppColors.danger),
                              tooltip: 'Delete type',
                              onPressed: () => _confirmDeleteType(type),
                            ),
                          ],
                        ),
                        children: [
                          // Options list
                          ...type.options.map((opt) => ListTile(
                                contentPadding: const EdgeInsets.only(
                                    left: 32, right: 16),
                                leading: Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: opt.isActive
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                title: Text(
                                  opt.name,
                                  style: TextStyle(
                                    color: opt.isActive
                                        ? null
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                subtitle: opt.isActive
                                    ? null
                                    : const Text('Inactive',
                                        style: TextStyle(fontSize: 11)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 16),
                                      tooltip: 'Edit option',
                                      onPressed: () =>
                                          _showEditOptionDialog(opt, type),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 16, color: AppColors.danger),
                                      tooltip: 'Delete option',
                                      onPressed: () =>
                                          _confirmDeleteOption(opt, type),
                                    ),
                                  ],
                                ),
                              )),
                          // Add option button
                          Padding(
                            padding: const EdgeInsets.fromLTRB(32, 4, 16, 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () => _showAddOptionDialog(type),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add option'),
                                style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}