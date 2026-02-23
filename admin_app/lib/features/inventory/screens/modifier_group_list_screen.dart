import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../models/modifier_group.dart';
import '../services/modifier_repository.dart';
import 'modifier_group_form_screen.dart';
import 'modifier_items_screen.dart';

/// Blueprint §4.3: Modifier group management. List groups, Add/Edit, Manage items.
class ModifierGroupListScreen extends StatefulWidget {
  const ModifierGroupListScreen({super.key});

  @override
  State<ModifierGroupListScreen> createState() => _ModifierGroupListScreenState();
}

class _ModifierGroupListScreenState extends State<ModifierGroupListScreen> {
  final _repo = ModifierRepository();
  List<ModifierGroup> _groups = [];
  bool _loading = true;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.getGroups();
      if (mounted) setState(() {
        _groups = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _navigateToForm({ModifierGroup? group}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModifierGroupFormScreen(group: group),
      ),
    ).then((result) {
      if (result == true) _load();
    });
  }

  void _navigateToItems(ModifierGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModifierItemsScreen(group: group),
      ),
    );
  }

  Future<void> _confirmDelete(ModifierGroup group) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete modifier group'),
        content: Text('Delete "${group.name}"? All items in this group will be deleted.'),
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
      await _repo.deleteGroup(group.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group deleted'), backgroundColor: AppColors.success),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
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
            Text(
              'Error loading modifier groups',
              style: const TextStyle(color: AppColors.danger, fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Modifier groups',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create modifier groups for product customization\n(e.g. sauces, cooking preferences)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add modifier group'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    // Toolbar + table (Add inside screen — matches module pattern)
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: AppColors.cardBg,
          child: Row(
            children: [
              const Text(
                'Modifier groups',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _navigateToForm(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add modifier group'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Description')),
            DataColumn(label: Text('Required')),
            DataColumn(label: Text('Allow multiple')),
            DataColumn(label: Text('Max')),
            DataColumn(label: Text('Sort')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _groups.map((g) {
            return DataRow(
              cells: [
                DataCell(Text(g.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                DataCell(Text(
                  g.description ?? '',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )),
                DataCell(Text(g.required_ ? 'Yes' : 'No')),
                DataCell(Text(g.allowMultiple ? 'Yes' : 'No')),
                DataCell(Text(g.maxSelections.toString())),
                DataCell(Text(g.sortOrder.toString())),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: g.isActive ? AppColors.success : AppColors.danger,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      g.isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                DataCell(
                  ActionButtonsWidget(
                    actions: [
                      ActionButtons.edit(
                        onPressed: () => _navigateToForm(group: g),
                        iconOnly: true,
                      ),
                      ActionButton(
                        label: 'Items',
                        icon: Icons.list,
                        type: ActionType.info,
                        onPressed: () => _navigateToItems(g),
                        iconOnly: true,
                        tooltip: 'Manage items',
                      ),
                      ActionButtons.delete(
                        onPressed: () => _confirmDelete(g),
                        iconOnly: true,
                      ),
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
        ),
      ],
    );
  }
}
