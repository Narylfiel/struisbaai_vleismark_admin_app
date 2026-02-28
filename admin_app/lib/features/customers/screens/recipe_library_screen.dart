import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/core/services/auth_service.dart';
import 'package:admin_app/features/customers/models/customer_recipe.dart';
import 'package:admin_app/features/customers/services/customer_recipe_repository.dart';
import 'customer_recipe_form_screen.dart';
import 'category_manager_screen.dart';

/// Customer Recipe Library — Tab 3 in CustomerListScreen.
///
/// Admin view: shows all recipes (draft + published).
/// Owner/Manager: can add, edit, delete, publish/draft, manage categories.
/// Other roles: read-only view of published recipes only.
class RecipeLibraryScreen extends StatefulWidget {
  const RecipeLibraryScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<RecipeLibraryScreen> createState() => _RecipeLibraryScreenState();
}

class _RecipeLibraryScreenState extends State<RecipeLibraryScreen> {
  final _repo = CustomerRecipeRepository();
  final _auth = AuthService();

  List<CustomerRecipe> _recipes = [];
  List<CustomerRecipeCategoryType> _categoryTypes = [];
  bool _loading = true;

  // Active filters: typeId → set of selected optionIds
  final Map<String, Set<String>> _activeFilters = {};
  String _statusFilter = 'all'; // 'all' | 'published' | 'draft'

  bool _filterPanelOpen = false;
  OverlayEntry? _filterOverlayEntry;
  OverlayState? _overlayState;
  final GlobalKey _toolbarKey = GlobalKey();

  bool get _canEdit {
    final role = _auth.currentRole;
    return role == 'owner' || role == 'manager';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _closeFilterPanel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait<dynamic>([
      _repo.getRecipes(publishedOnly: false),
      _repo.getCategoryTypes(activeOnly: true),
    ]);
    if (mounted) {
      setState(() {
        _recipes = results[0] as List<CustomerRecipe>;
        _categoryTypes =
            results[1] as List<CustomerRecipeCategoryType>;
        _loading = false;
      });
    }
  }

  // ── Filtering ─────────────────────────────────────────────

  List<CustomerRecipe> get _filtered {
    var list = List<CustomerRecipe>.from(_recipes);

    // Status filter
    if (_statusFilter == 'published') {
      list = list.where((r) => r.isPublished).toList();
    } else if (_statusFilter == 'draft') {
      list = list.where((r) => r.isDraft).toList();
    }

    // Category filters
    for (final entry in _activeFilters.entries) {
      if (entry.value.isEmpty) continue;
      list = list.where((r) {
        final recipeOptionIds = r.categoryAssignments.map((a) => a.id).toSet();
        return entry.value.any((id) => recipeOptionIds.contains(id));
      }).toList();
    }

    return list;
  }

  void _toggleFilter(String typeId, String optionId) {
    setState(() {
      _activeFilters.putIfAbsent(typeId, () => {});
      if (_activeFilters[typeId]!.contains(optionId)) {
        _activeFilters[typeId]!.remove(optionId);
      } else {
        _activeFilters[typeId]!.add(optionId);
      }
    });
    _filterOverlayEntry?.markNeedsBuild();
  }

  void _clearFilters() {
    setState(() {
      _activeFilters.clear();
      _statusFilter = 'all';
    });
  }

  void _toggleFilterPanel() {
    if (_filterPanelOpen) {
      _closeFilterPanel();
      return;
    }
    _filterOverlayEntry = OverlayEntry(
      builder: (ctx) => _buildFilterOverlay(ctx),
    );
    _overlayState = Overlay.of(context);
    _overlayState!.insert(_filterOverlayEntry!);
    setState(() => _filterPanelOpen = true);
  }

  void _closeFilterPanel() {
    if (_filterOverlayEntry == null) return;
    _filterOverlayEntry!.remove();
    _filterOverlayEntry = null;
    _overlayState = null;
    if (mounted) setState(() => _filterPanelOpen = false);
  }

  Widget _buildFilterOverlay(BuildContext overlayContext) {
    final box = _toolbarKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return const SizedBox.shrink();
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    final typesWithOptions = _categoryTypes
        .where((t) => t.options.any((o) => o.isActive))
        .toList();
    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _closeFilterPanel,
          child: const SizedBox.expand(),
        ),
        Positioned(
          left: offset.dx,
          top: offset.dy + size.height,
          width: size.width,
          child: Material(
            color: AppColors.cardBg,
            elevation: 8,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.zero,
              topRight: Radius.zero,
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: typesWithOptions
                        .map((type) => Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    type.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...type.options
                                      .where((o) => o.isActive)
                                      .map((opt) {
                                    final selected =
                                        (_activeFilters[type.id] ?? {})
                                            .contains(opt.id);
                                    return CheckboxListTile(
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        opt.name,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      value: selected,
                                      onChanged: (_) =>
                                          _toggleFilter(type.id, opt.id),
                                    );
                                  }),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          _clearFilters();
                          _closeFilterPanel();
                        },
                        child: const Text('Clear All'),
                      ),
                      ElevatedButton(
                        onPressed: _closeFilterPanel,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool get _hasActiveFilters =>
      _activeFilters.values.any((s) => s.isNotEmpty) ||
      _statusFilter != 'all';

  // ── Actions ───────────────────────────────────────────────

  void _openAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const CustomerRecipeFormScreen()),
    ).then((result) {
      if (result == true) _load();
    });
  }

  void _openEdit(CustomerRecipe recipe) async {
    // Load full detail before opening form
    final full = await _repo.getRecipeDetail(recipe.id);
    if (!mounted) return;
    if (full == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load recipe detail')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => CustomerRecipeFormScreen(existingRecipe: full)),
    ).then((result) {
      if (result == true) _load();
    });
  }

  void _openDetail(CustomerRecipe recipe) async {
    final full = await _repo.getRecipeDetail(recipe.id);
    if (!mounted) return;
    if (full == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => _RecipeDetailScreen(
                recipe: full,
                canEdit: _canEdit,
                onEdit: () => _openEdit(full),
                onDelete: () => _confirmDelete(full),
                onToggleStatus: () => _toggleStatus(full),
              )),
    ).then((_) => _load());
  }

  Future<void> _toggleStatus(CustomerRecipe recipe) async {
    final newStatus = recipe.isPublished ? 'draft' : 'published';
    try {
      await _repo.setRecipeStatus(
        recipeId: recipe.id,
        status: newStatus,
        updatedBy: _auth.getCurrentStaffId(),
        title: recipe.title,
      );
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '"${recipe.title}" set to ${newStatus == 'published' ? 'Published' : 'Draft'}'),
            backgroundColor: newStatus == 'published'
                ? AppColors.success
                : AppColors.textSecondary,
          ),
        );
      }
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

  Future<void> _confirmDelete(CustomerRecipe recipe) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recipe?'),
        content: Text(
          'Delete "${recipe.title}"?\n\nThis will permanently remove the recipe, '
          'all its ingredients, steps, images, and category assignments. '
          'This cannot be undone.',
        ),
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
      await _repo.deleteRecipe(
        recipeId: recipe.id,
        deletedBy: _auth.getCurrentStaffId(),
        title: recipe.title,
      );
      if (mounted) {
        Navigator.popUntil(context, (r) => r.isFirst || r.settings.name != null);
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${recipe.title}" deleted')),
        );
      }
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

  void _openCategoryManager() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CategoryManagerScreen()),
    ).then((_) => _load());
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || result.files.single.bytes == null || !mounted) return;
    final bytes = result.files.single.bytes!;
    String content;
    try {
      content = utf8.decode(bytes);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read file'), backgroundColor: AppColors.error),
        );
      }
      return;
    }
    final staffId = _auth.getCurrentStaffId() ?? '';
    CsvImportResult importResult;
    try {
      importResult = await _repo.importFromCsv(csvContent: content, importedBy: staffId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error),
        );
      }
      return;
    }
    if (!mounted) return;
    final message = StringBuffer();
    message.write('Import complete: ${importResult.successCount} recipes imported, ${importResult.skipCount} skipped.');
    if (importResult.errors.isNotEmpty) {
      message.write('\n\nErrors:\n');
      for (final err in importResult.errors) {
        message.write('• $err\n');
      }
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CSV Import'),
        content: SingleChildScrollView(
          child: Text(message.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    _load();
  }

  Future<void> _downloadCsvTemplate() async {
    const header = 'title,description,serving_size,prep_time_minutes,cook_time_minutes,status,ingredients,steps,image_urls,categories';
    const exampleRow = 'Braai Burger,Classic beef burger for the braai,4,15,10,published,"500g beef mince|1 egg (optional)|salt and pepper","Shape patties|Braai 4 min per side|Serve with rolls",https://example.com/burger.jpg,Beef|Braai|Dinner';
    final csv = '$header\n$exampleRow';
    final dir = await getDownloadsDirectory();
    final directory = dir ?? await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/recipe_import_template.csv');
    await file.writeAsString(csv);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Template saved to ${file.path}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    return Column(
      children: [
        // ── Toolbar ────────────────────────────────────────
        Container(
          key: _toolbarKey,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: AppColors.cardBg,
          child: Row(
            children: [
              // Status filter chips
              _StatusChip(
                label: 'All',
                selected: _statusFilter == 'all',
                onTap: () => setState(() => _statusFilter = 'all'),
              ),
              const SizedBox(width: 6),
              _StatusChip(
                label: 'Published',
                selected: _statusFilter == 'published',
                color: AppColors.success,
                onTap: () => setState(() => _statusFilter = 'published'),
              ),
              const SizedBox(width: 6),
              _StatusChip(
                label: 'Draft',
                selected: _statusFilter == 'draft',
                color: AppColors.textSecondary,
                onTap: () => setState(() => _statusFilter = 'draft'),
              ),
              const Spacer(),
              Stack(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.filter_list, size: 16),
                    label: Text(_hasActiveFilters
                        ? 'Filters (${_activeFilters.values.fold<int>(0, (s, e) => s + e.length)})'
                        : 'Filters'),
                    onPressed: _toggleFilterPanel,
                    style: _hasActiveFilters
                        ? OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary))
                        : null,
                  ),
                ],
              ),
              if (_canEdit) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _openCategoryManager,
                  icon: const Icon(Icons.label_outline, size: 16),
                  label: const Text('Categories'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.upload_file_outlined, size: 16),
                  label: const Text('Import CSV'),
                  onPressed: _importCsv,
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.download_outlined, size: 14),
                  label: const Text('Template'),
                  onPressed: _downloadCsvTemplate,
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _openAdd,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Recipe'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                ),
              ],
            ],
          ),
        ),

        const Divider(height: 1, color: AppColors.border),

        // ── Recipe grid ────────────────────────────────────
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.menu_book_outlined,
                          size: 48,
                          color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        _hasActiveFilters
                            ? 'No recipes match your filters.'
                            : _recipes.isEmpty
                                ? 'No recipes yet. Add one to get started.'
                                : 'No recipes match the current filter.',
                        style: const TextStyle(
                            color: AppColors.textSecondary),
                      ),
                      if (_hasActiveFilters) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear filters'),
                        ),
                      ],
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final recipe = _filtered[i];
                    return _RecipeCard(
                      recipe: recipe,
                      canEdit: _canEdit,
                      onTap: () => _openDetail(recipe),
                      onEdit: () => _openEdit(recipe),
                      onDelete: () => _confirmDelete(recipe),
                      onToggleStatus: () => _toggleStatus(recipe),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Recipe Card ────────────────────────────────────────────

class _RecipeCard extends StatelessWidget {
  final CustomerRecipe recipe;
  final bool canEdit;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const _RecipeCard({
    required this.recipe,
    required this.canEdit,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = recipe.primaryImageUrl;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: AppColors.cardBg,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image or placeholder
            AspectRatio(
              aspectRatio: 16 / 9,
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge
                    Row(
                      children: [
                        _StatusBadge(isPublished: recipe.isPublished),
                        const Spacer(),
                        if (canEdit)
                          _CardMenu(
                            onEdit: onEdit,
                            onDelete: onDelete,
                            onToggleStatus: onToggleStatus,
                            isPublished: recipe.isPublished,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Time info
                    Row(
                      children: [
                        const Icon(Icons.schedule,
                            size: 12,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.prepTimeMinutes + recipe.cookTimeMinutes} min',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.people_outline,
                            size: 12,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.servingSize}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.surfaceBg,
      child: const Center(
        child: Icon(Icons.restaurant, size: 32, color: AppColors.border),
      ),
    );
  }
}

// ── Recipe Detail Screen ───────────────────────────────────

class _RecipeDetailScreen extends StatelessWidget {
  final CustomerRecipe recipe;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const _RecipeDetailScreen({
    required this.recipe,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        title: Text(recipe.title),
        actions: [
          if (canEdit) ...[
            TextButton.icon(
              onPressed: onToggleStatus,
              icon: Icon(
                recipe.isPublished
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 16,
              ),
              label: Text(
                  recipe.isPublished ? 'Set to Draft' : 'Publish'),
            ),
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit'),
            ),
            TextButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline,
                  size: 16, color: AppColors.danger),
              label: const Text('Delete',
                  style: TextStyle(color: AppColors.danger)),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status + meta
            Row(
              children: [
                _StatusBadge(isPublished: recipe.isPublished),
                const SizedBox(width: 12),
                const Icon(Icons.schedule,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Prep: ${recipe.prepTimeMinutes} min  •  Cook: ${recipe.cookTimeMinutes} min',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.people_outline,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Serves ${recipe.servingSize}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Images
            if (recipe.images.isNotEmpty) ...[
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recipe.images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final img = recipe.images[i];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        img.imageUrl,
                        width: 280,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 280,
                          color: AppColors.border,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Description
            if (recipe.description != null &&
                recipe.description!.isNotEmpty) ...[
              Text(recipe.description!,
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5)),
              const SizedBox(height: 24),
            ],

            // Category assignments
            if (recipe.categoryAssignments.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: recipe.categoryAssignments
                    .map((opt) => Chip(
                          label: Text(opt.name,
                              style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Ingredients
            const Text('Ingredients',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (recipe.ingredients.isEmpty)
              const Text('No ingredients listed.',
                  style: TextStyle(color: AppColors.textSecondary))
            else
              ...recipe.ingredients.map((ing) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.fiber_manual_record,
                            size: 8,
                            color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ing.isOptional
                                ? '${ing.ingredientText} (optional)'
                                : ing.ingredientText,
                            style: TextStyle(
                              fontSize: 13,
                              color: ing.isOptional
                                  ? AppColors.textSecondary
                                  : null,
                              fontStyle: ing.isOptional
                                  ? FontStyle.italic
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            const SizedBox(height: 24),

            // Steps
            const Text('Instructions',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (recipe.steps.isEmpty)
              const Text('No instructions listed.',
                  style: TextStyle(color: AppColors.textSecondary))
            else
              ...recipe.steps.map((step) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primary
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${step.stepNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            step.instructionText,
                            style: const TextStyle(
                                fontSize: 13, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  )),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// ── Small reusable widgets ─────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isPublished;

  const _StatusBadge({required this.isPublished});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPublished
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.textSecondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isPublished ? 'Published' : 'Draft',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isPublished ? AppColors.success : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? c : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? c : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CardMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;
  final bool isPublished;

  const _CardMenu({
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
    required this.isPublished,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert,
          size: 16, color: AppColors.textSecondary),
      padding: EdgeInsets.zero,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: const Row(children: [
            Icon(Icons.edit_outlined, size: 16),
            SizedBox(width: 8),
            Text('Edit'),
          ]),
        ),
        PopupMenuItem(
          value: 'status',
          child: Row(children: [
            Icon(
              isPublished
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(isPublished ? 'Set to Draft' : 'Publish'),
          ]),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: const Row(children: [
            Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Delete', style: TextStyle(color: AppColors.danger)),
          ]),
        ),
      ],
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'status') onToggleStatus();
        if (value == 'delete') onDelete();
      },
    );
  }
}