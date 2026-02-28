import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/error_handler.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../models/modifier_group.dart';
import '../models/modifier_item.dart';
import '../services/modifier_repository.dart';
import 'package:admin_app/core/services/supabase_service.dart';

/// Blueprint §4.3: Modifier items for one group. List items, Add/Edit (name, price adjustment, track inventory, linked item).
class ModifierItemsScreen extends StatefulWidget {
  final ModifierGroup group;

  const ModifierItemsScreen({super.key, required this.group});

  @override
  State<ModifierItemsScreen> createState() => _ModifierItemsScreenState();
}

class _ModifierItemsScreenState extends State<ModifierItemsScreen> {
  final _repo = ModifierRepository();
  List<ModifierItem> _items = [];
  bool _loading = true;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.getItemsByGroup(widget.group.id);
      if (mounted) setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = ErrorHandler.friendlyMessage(e);
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _openItemForm({ModifierItem? item}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ModifierItemFormScreen(
          group: widget.group,
          item: item,
        ),
      ),
    ).then((_) => _load());
  }

  Future<void> _confirmDelete(ModifierItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete modifier item'),
        content: Text('Delete "${item.name}"?'),
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
    try {
      await _repo.deleteItem(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted'), backgroundColor: AppColors.success),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier items: ${widget.group.name}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openItemForm(),
            tooltip: 'Add item',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
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
                )
              : _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle_outline, size: 64, color: AppColors.textSecondary),
                          const SizedBox(height: 16),
                          const Text(
                            'No modifier items',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add items (e.g. Pepper Sauce +R15, Track inventory, Linked product)',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _openItemForm(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add item'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Price adj')),
                            DataColumn(label: Text('Track inv')),
                            DataColumn(label: Text('Linked item')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: _items.map((i) {
                            return DataRow(
                              cells: [
                                DataCell(Text(i.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                                DataCell(Text(i.priceAdjustment >= 0 ? '+R${i.priceAdjustment.toStringAsFixed(2)}' : 'R${i.priceAdjustment.toStringAsFixed(2)}')),
                                DataCell(Text(i.trackInventory ? 'Yes' : 'No')),
                                DataCell(Text(i.linkedInventoryItemId != null ? 'Linked' : '—', style: const TextStyle(fontSize: 12))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: i.isActive ? AppColors.success : AppColors.danger,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      i.isActive ? 'Active' : 'Inactive',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  ActionButtonsWidget(
                                    actions: [
                                      ActionButtons.edit(onPressed: () => _openItemForm(item: i), iconOnly: true),
                                      ActionButtons.delete(onPressed: () => _confirmDelete(i), iconOnly: true),
                                    ],
                                    compact: true,
                                    spacing: 8,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
      floatingActionButton: _items.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _openItemForm(),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

/// Add/Edit modifier item: Name, Price Adjustment, Track Inventory?, Linked Item.
class _ModifierItemFormScreen extends StatefulWidget {
  final ModifierGroup group;
  final ModifierItem? item;

  const _ModifierItemFormScreen({required this.group, this.item});

  @override
  State<_ModifierItemFormScreen> createState() => _ModifierItemFormScreenState();
}

class _ModifierItemFormScreenState extends State<_ModifierItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  late bool _trackInventory;
  late bool _isActive;
  String? _linkedInventoryItemId;
  List<Map<String, dynamic>> _inventoryItems = [];
  bool _loadingInventory = true;
  bool _saving = false;
  final _repo = ModifierRepository();
  final _client = SupabaseService.client;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _priceController.text = widget.item!.priceAdjustment.toString();
      _trackInventory = widget.item!.trackInventory;
      _isActive = widget.item!.isActive;
      _linkedInventoryItemId = widget.item!.linkedInventoryItemId;
    } else {
      _priceController.text = '0';
      _trackInventory = false;
      _isActive = true;
    }
    _loadInventoryItems();
  }

  Future<void> _loadInventoryItems() async {
    try {
      final r = await _client
          .from('inventory_items')
          .select('id, name')
          .eq('is_active', true)
          .order('name');
      if (mounted) setState(() {
        _inventoryItems = List<Map<String, dynamic>>.from(r as List);
        _loadingInventory = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingInventory = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final price = double.tryParse(_priceController.text) ?? 0;
      if (widget.item != null) {
        final updated = ModifierItem(
          id: widget.item!.id,
          groupId: widget.group.id,
          name: _nameController.text.trim(),
          priceAdjustment: price,
          isActive: _isActive,
          sortOrder: widget.item!.sortOrder,
          trackInventory: _trackInventory,
          linkedInventoryItemId: _linkedInventoryItemId?.isEmpty == true ? null : _linkedInventoryItemId,
          createdAt: widget.item!.createdAt,
          updatedAt: DateTime.now(),
        );
        await _repo.updateItem(updated);
      } else {
        final created = ModifierItem(
          id: '',
          groupId: widget.group.id,
          name: _nameController.text.trim(),
          priceAdjustment: price,
          isActive: _isActive,
          sortOrder: 0,
          trackInventory: _trackInventory,
          linkedInventoryItemId: _linkedInventoryItemId?.isEmpty == true ? null : _linkedInventoryItemId,
        );
        await _repo.createItem(created);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modifier item saved'), backgroundColor: AppColors.success),
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
    final isEditing = widget.item != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit modifier item' : 'Add modifier item'),
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
                label: 'Item name',
                hint: 'e.g. Pepper Sauce',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                prefixIcon: const Icon(Icons.label_outline),
              ),
              const SizedBox(height: 16),
              FormWidgets.textFormField(
                controller: _priceController,
                label: 'Price adjustment (R)',
                hint: '0 or 15.00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.-]'))],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Price adjustment is required';
                  if (double.tryParse(v) == null) return 'Enter a number';
                  return null;
                },
                prefixIcon: const Icon(Icons.attach_money),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Track inventory'),
                subtitle: const Text('Blueprint: Track Inventory?'),
                value: _trackInventory,
                onChanged: (v) => setState(() => _trackInventory = v),
                activeColor: AppColors.primary,
              ),
              if (_loadingInventory)
                const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
              else
                DropdownButtonFormField<String>(
                  value: _linkedInventoryItemId,
                  decoration: const InputDecoration(
                    labelText: 'Linked item (inventory product)',
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
                  onChanged: (v) => setState(() => _linkedInventoryItemId = v),
                ),
              const SizedBox(height: 16),
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
}
