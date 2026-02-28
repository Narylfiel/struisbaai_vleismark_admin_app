import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/error_handler.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../models/recipe.dart';
import '../services/recipe_repository.dart';
import 'recipe_form_screen.dart';

/// Blueprint §5.5: Recipes list — Create modifier groups for product customization.
class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final _repo = RecipeRepository();
  List<Recipe> _recipes = [];
  bool _loading = true;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.getRecipes();
      if (mounted) {
        setState(() {
          _recipes = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorHandler.friendlyMessage(e);
          _loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _navigateToForm({Recipe? recipe}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeFormScreen(recipe: recipe),
      ),
    ).then((result) {
      if (result == true) _load();
    });
  }

  Future<void> _confirmDelete(Recipe recipe) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete recipe'),
        content: Text('Delete "${recipe.name}"? All ingredients will be deleted.'),
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
      await _repo.deleteRecipe(recipe.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe deleted'), backgroundColor: AppColors.success),
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
              'Error loading recipes',
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
    if (_recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Recipes',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create recipes for Boerewors, Biltong, etc.\nLink output product and ingredients per batch.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add recipe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(child: SizedBox()),
              ElevatedButton.icon(
                onPressed: () => _navigateToForm(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add recipe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Output product')),
                  DataColumn(label: Text('Yield %')),
                  DataColumn(label: Text('Batch size (kg)')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _recipes.map((r) {
                  return DataRow(
                    cells: [
                      DataCell(Text(r.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Text(r.outputProductId != null ? 'Linked' : '—', style: const TextStyle(fontSize: 12))),
                      DataCell(Text('${r.expectedYieldPct.toStringAsFixed(1)}%')),
                      DataCell(Text(r.batchSizeKg.toStringAsFixed(1))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: r.isActive ? AppColors.success : AppColors.danger,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            r.isActive ? 'Active' : 'Inactive',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      DataCell(
                        ActionButtonsWidget(
                          actions: [
                            ActionButtons.edit(onPressed: () => _navigateToForm(recipe: r), iconOnly: true),
                            ActionButtons.delete(onPressed: () => _confirmDelete(r), iconOnly: true),
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
