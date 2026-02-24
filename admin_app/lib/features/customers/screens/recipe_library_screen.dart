import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/features/production/models/recipe.dart';
import 'package:admin_app/features/production/models/recipe_ingredient.dart';
import 'package:admin_app/features/production/services/recipe_repository.dart';
import 'package:admin_app/features/production/screens/recipe_form_screen.dart';

/// M1: Recipe Library — GridView, filter by category, detail, Share via WhatsApp.
/// Uses same recipes table as Production.
class RecipeLibraryScreen extends StatefulWidget {
  const RecipeLibraryScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<RecipeLibraryScreen> createState() => _RecipeLibraryScreenState();
}

class _RecipeLibraryScreenState extends State<RecipeLibraryScreen> {
  final _repo = RecipeRepository();
  List<Recipe> _recipes = [];
  String? _selectedCategory;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.getRecipes(activeOnly: true);
      if (mounted) setState(() {
        _recipes = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _categories {
    final cats = _recipes.map((r) => r.category).whereType<String>().where((c) => c.isNotEmpty).toSet().toList();
    cats.sort();
    return cats;
  }

  List<Recipe> get _filtered {
    if (_selectedCategory == null || _selectedCategory!.isEmpty) return _recipes;
    return _recipes.where((r) => r.category == _selectedCategory).toList();
  }

  void _openDetail(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _RecipeDetailScreen(recipe: recipe),
      ),
    );
  }

  void _openForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RecipeFormScreen()),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedCategory == null,
                onSelected: (_) => setState(() => _selectedCategory = null),
              ),
              ..._categories.map((cat) => FilterChip(
                label: Text(cat),
                selected: _selectedCategory == cat,
                onSelected: (_) => setState(() => _selectedCategory = cat),
              )),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              _filtered.isEmpty
                  ? const Center(child: Text('No recipes. Add via Production or FAB.'))
                  : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final r = _filtered[i];
                    return _RecipeCard(
                      recipe: r,
                      onTap: () => _openDetail(r),
                    );
                  },
                ),
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.extended(
                  onPressed: _openForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Recipe'),
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const _RecipeCard({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final yieldStr = recipe.batchSizeKg > 0
        ? '${recipe.batchSizeKg.toStringAsFixed(1)} kg'
        : '${recipe.servings} servings';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                recipe.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (recipe.category != null && recipe.category!.isNotEmpty)
                Chip(
                  label: Text(recipe.category!, style: const TextStyle(fontSize: 11)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              const Spacer(),
              Text(yieldStr, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const _RecipeDetailScreen({required this.recipe});

  @override
  State<_RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<_RecipeDetailScreen> {
  final _repo = RecipeRepository();
  List<RecipeIngredient> _ingredients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    try {
      final list = await _repo.getIngredientsByRecipe(widget.recipe.id);
      if (mounted) setState(() {
        _ingredients = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _shareWhatsApp() async {
    final r = widget.recipe;
    final buf = StringBuffer();
    buf.writeln(r.name);
    buf.writeln('Yield: ${r.batchSizeKg > 0 ? "${r.batchSizeKg.toStringAsFixed(1)} kg" : "${r.servings} servings"}');
    buf.writeln('');
    buf.writeln('Ingredients:');
    for (final i in _ingredients) {
      buf.writeln('- ${i.ingredientName}: ${i.quantity} ${i.unit}');
    }
    buf.writeln('');
    buf.writeln('Instructions:');
    buf.writeln(r.instructions ?? 'See recipe for instructions.');
    final msg = buf.toString();
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;
    return Scaffold(
      appBar: AppBar(
        title: Text(r.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareWhatsApp,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (r.category != null && r.category!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Chip(label: Text(r.category!)),
              ),
            Row(
              children: [
                const Text('Yield: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(r.batchSizeKg > 0 ? '${r.batchSizeKg.toStringAsFixed(1)} kg' : '${r.servings} servings'),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Ingredients', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_loading)
              const CircularProgressIndicator()
            else if (_ingredients.isEmpty)
              const Text('No ingredients listed.')
            else
              ..._ingredients.map((i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(i.ingredientName)),
                    Text('${i.quantity} ${i.unit}'),
                  ],
                ),
              )),
            const SizedBox(height: 24),
            const Text('Instructions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(r.instructions ?? 'No instructions.', style: const TextStyle(height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _shareWhatsApp,
                icon: const Icon(Icons.share),
                label: const Text('Share via WhatsApp'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
