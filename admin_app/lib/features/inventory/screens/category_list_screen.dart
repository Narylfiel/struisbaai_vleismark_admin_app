import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/search_bar.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../models/category.dart';
import '../blocs/category/category_bloc.dart';
import '../blocs/category/category_event.dart';
import '../blocs/category/category_state.dart';
import 'category_form_screen.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic> _filters = {};

  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(const LoadCategories());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          // Toolbar: search, filter, Add (no AppBar — matches module pattern)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: AppColors.cardBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SearchBarWidget(
                        hintText: 'Search categories...',
                        onSearch: (value) {
                          _searchController.text = value;
                          setState(() {});
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilterBarWidget(
                        filters: const [
                          FilterOption(
                            key: 'isActive',
                            label: 'Status',
                            type: FilterType.dropdown,
                            options: ['Active', 'Inactive'],
                          ),
                        ],
                        onFiltersChanged: (filters) {
                          setState(() {
                            _filters = filters;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToForm(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Category'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Categories List
          Expanded(
            child: BlocBuilder<CategoryBloc, CategoryState>(
              builder: (context, state) {
                if (state is CategoryLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is CategoryError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.danger,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Error loading categories',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.read<CategoryBloc>().add(const LoadCategories()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is CategoryLoaded) {
                  final filteredCategories = _filterCategories(state.categories);
                  final rows = _buildCategoryRows(filteredCategories);

                  if (rows.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.category_outlined,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No categories found',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create your first category to get started',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _navigateToForm(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Category'),
                          ),
                        ],
                      ),
                    );
                  }

                  return BlocListener<CategoryBloc, CategoryState>(
                    listener: (context, state) {
                      if (state is CategoryOperationSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
                        );
                      } else if (state is CategoryError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state.message), backgroundColor: AppColors.danger),
                        );
                      }
                    },
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Color')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Notes')),
                            DataColumn(label: Text('Sort Order')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: rows,
                        ),
                      ),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build flat list of rows: top-level categories first, then subcategories indented under parent.
  List<DataRow> _buildCategoryRows(List<Category> categories) {
    final roots = categories.where((c) => c.parentId == null || c.parentId!.isEmpty).toList()
      ..sort((a, b) {
        final o = a.sortOrder.compareTo(b.sortOrder);
        return o != 0 ? o : a.name.compareTo(b.name);
      });
    final childrenByParent = <String, List<Category>>{};
    for (final c in categories) {
      if (c.parentId != null && c.parentId!.isNotEmpty) {
        childrenByParent.putIfAbsent(c.parentId!, () => []).add(c);
      }
    }
    for (final list in childrenByParent.values) {
      list.sort((a, b) {
        final o = a.sortOrder.compareTo(b.sortOrder);
        return o != 0 ? o : a.name.compareTo(b.name);
      });
    }
    final rows = <DataRow>[];
    for (final category in roots) {
      rows.add(_categoryToDataRow(category, false));
      for (final child in childrenByParent[category.id] ?? []) {
        rows.add(_categoryToDataRow(child, true));
      }
    }
    return rows;
  }

  DataRow _categoryToDataRow(Category category, bool isSubcategory) {
    return DataRow(
      cells: [
        DataCell(
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Color(int.parse(category.colorCode.replaceAll('#', '0xFF'))),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        DataCell(
          Text(
            isSubcategory ? '  ↳ ${category.name}' : category.name,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontStyle: isSubcategory ? FontStyle.italic : null,
            ),
          ),
        ),
        DataCell(
          Text(
            category.notes ?? '',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DataCell(Text(category.sortOrder.toString())),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: category.isActive ? AppColors.success : AppColors.danger,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              category.isActive ? 'Active' : 'Inactive',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        DataCell(
          ActionButtonsWidget(
            actions: [
              ActionButtons.edit(onPressed: () => _navigateToForm(category: category), iconOnly: true),
              ActionButtons.delete(onPressed: () => _confirmDelete(category), iconOnly: true),
            ],
            compact: true,
            spacing: 8,
          ),
        ),
      ],
    );
  }

  List<Category> _filterCategories(List<Category> categories) {
    final searchTerm = _searchController.text.toLowerCase();
    final isActiveFilter = _filters['isActive'];

    return categories.where((category) {
      // Search filter
      if (searchTerm.isNotEmpty) {
        final matchesSearch = category.name.toLowerCase().contains(searchTerm) ||
            (category.notes?.toLowerCase().contains(searchTerm) ?? false);
        if (!matchesSearch) return false;
      }

      // Status filter
      if (isActiveFilter != null) {
        final isActive = isActiveFilter == 'Active';
        if (category.isActive != isActive) return false;
      }

      return true;
    }).toList();
  }

  void _sortCategories(int columnIndex, bool ascending) {
    // Sorting logic would be implemented here
    // For now, just reload the data
    context.read<CategoryBloc>().add(const LoadCategories());
  }

  void _applyFilters() {
    // Filters are applied in real-time through the UI
    setState(() {});
  }

  void _navigateToForm({Category? category}) {
    final categoryBloc = context.read<CategoryBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: categoryBloc,
          child: CategoryFormScreen(category: category),
        ),
      ),
    ).then((_) {
      // Refresh the list when returning from form
      context.read<CategoryBloc>().add(const LoadCategories());
    });
  }

  void _confirmDelete(Category category) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('Delete "${category.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((ok) {
      if (ok == true) context.read<CategoryBloc>().add(DeleteCategory(category.id));
    });
  }
}