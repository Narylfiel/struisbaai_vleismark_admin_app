import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../models/modifier_group.dart';
import '../services/modifier_repository.dart';

/// Blueprint §4.3: Create/Edit Modifier Group — Name, Required?, Allow Multiple?, Max Selections.
class ModifierGroupFormScreen extends StatefulWidget {
  final ModifierGroup? group;

  const ModifierGroupFormScreen({super.key, this.group});

  @override
  State<ModifierGroupFormScreen> createState() => _ModifierGroupFormScreenState();
}

class _ModifierGroupFormScreenState extends State<ModifierGroupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sortOrderController = TextEditingController();
  final _maxSelectionsController = TextEditingController();

  late bool _isRequired;
  late bool _allowMultiple;
  late bool _isActive;
  bool _isLoading = false;

  final _repo = ModifierRepository();

  @override
  void initState() {
    super.initState();
    if (widget.group != null) {
      _nameController.text = widget.group!.name;
      _descriptionController.text = widget.group!.description ?? '';
      _sortOrderController.text = widget.group!.sortOrder.toString();
      _maxSelectionsController.text = widget.group!.maxSelections.toString();
      _isRequired = widget.group!.required_;
      _allowMultiple = widget.group!.allowMultiple;
      _isActive = widget.group!.isActive;
    } else {
      _sortOrderController.text = '0';
      _maxSelectionsController.text = '1';
      _isRequired = false;
      _allowMultiple = false;
      _isActive = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _sortOrderController.dispose();
    _maxSelectionsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final sortOrder = int.tryParse(_sortOrderController.text) ?? 0;
      final maxSelections = int.tryParse(_maxSelectionsController.text) ?? 1;
      if (widget.group != null) {
        final updated = ModifierGroup(
          id: widget.group!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          isActive: _isActive,
          sortOrder: sortOrder,
          required_: _isRequired,
          allowMultiple: _allowMultiple,
          maxSelections: maxSelections.clamp(1, 99),
          createdAt: widget.group!.createdAt,
          updatedAt: DateTime.now(),
        );
        await _repo.updateGroup(updated);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modifier group updated'), backgroundColor: AppColors.success),
        );
      } else {
        final created = ModifierGroup(
          id: '',
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          isActive: _isActive,
          sortOrder: sortOrder,
          required_: _isRequired,
          allowMultiple: _allowMultiple,
          maxSelections: maxSelections.clamp(1, 99),
        );
        await _repo.createGroup(created);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modifier group created'), backgroundColor: AppColors.success),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete() async {
    if (widget.group == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete modifier group?'),
        content: Text('Delete "${widget.group!.name}"? This cannot be undone.'),
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
    if (ok != true || !mounted) return;
    setState(() => _isLoading = true);
    try {
      await _repo.deleteGroup(widget.group!.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.group != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit modifier group' : 'Add modifier group'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _confirmDelete,
              tooltip: 'Delete',
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
                label: 'Group name',
                hint: 'e.g. Sauce options',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                prefixIcon: const Icon(Icons.label_outline),
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
                controller: _sortOrderController,
                label: 'Sort order',
                hint: '0',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Sort order is required';
                  if (int.tryParse(v) == null) return 'Enter a number';
                  return null;
                },
                prefixIcon: const Icon(Icons.sort),
              ),
              const SizedBox(height: 16),
              FormWidgets.textFormField(
                controller: _maxSelectionsController,
                label: 'Max selections',
                hint: '1',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Max selections is required';
                  final n = int.tryParse(v);
                  if (n == null || n < 1) return 'Must be at least 1';
                  return null;
                },
                prefixIcon: const Icon(Icons.touch_app),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Required'),
                subtitle: const Text('Customer must pick at least one (Blueprint: Required?)'),
                value: _isRequired,
                onChanged: (v) => setState(() => _isRequired = v),
                activeColor: AppColors.primary,
              ),
              SwitchListTile(
                title: const Text('Allow multiple'),
                subtitle: const Text('Customer can select more than one (Blueprint: Allow Multiple?)'),
                value: _allowMultiple,
                onChanged: (v) => setState(() => _allowMultiple = v),
                activeColor: AppColors.primary,
              ),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                activeColor: AppColors.primary,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
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
}
