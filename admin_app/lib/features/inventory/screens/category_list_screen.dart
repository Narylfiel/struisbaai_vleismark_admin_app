import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/data_table.dart';
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
    context.read<CategoryBloc>().add(LoadCategories());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToForm(),
            tooltip: 'Add Category',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SearchBarWidget(
                  controller: _searchController,
                  hintText: 'Search categories...',
                  onChanged: (value) {
                    setState(() {});
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 16),
                FilterBarWidget(
                  filters: [
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
              ],
            ),
          ),

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
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.danger,
                        ),
                        const SizedBox(height: 16),
                        Text(
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
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.read<CategoryBloc>().add(LoadCategories()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is CategoryLoaded) {
                  final filteredCategories = _filterCategories(state.categories);

                  if (filteredCategories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No categories found',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
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

                  return DataTableWidget<Category>(
                    data: filteredCategories,
                    columns: [
                      DataColumn(
                        label: const Text('Color'),
                        onSort: (columnIndex, ascending) => _sortCategories(columnIndex, ascending),
                      ),
                      const DataColumn(label: Text('Name')),
                      const DataColumn(label: Text('Notes')),
                      const DataColumn(label: Text('Sort Order')),
                      const DataColumn(label: Text('Status')),
                      const DataColumn(label: Text('Actions')),
                    ],
                    cellBuilder: (category, columnIndex) {
                      switch (columnIndex) {
                        case 0:
                          return DataCell(
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Color(int.parse(category.colorCode.replaceAll('#', '0xFF'))),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        case 1:
                          return DataCell(
                            Text(
                              category.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          );
                        case 2:
                          return DataCell(
                            Text(
                              category.notes ?? '',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        case 3:
                          return DataCell(
                            Text(category.sortOrder.toString()),
                          );
                        case 4:
                          return DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: category.isActive ? AppColors.success : AppColors.danger,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                category.isActive ? 'Active' : 'Inactive',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        case 5:
                          return DataCell(
                            ActionButtonsWidget(
                              actions: [
                                ActionButtons.edit(
                                  onPressed: () => _navigateToForm(category: category),
                                  iconOnly: true,
                                ),
                                ActionButtons.delete(
                                  onPressed: () => _confirmDelete(category),
                                  iconOnly: true,
                                ),
                              ],
                              direction: Axis.horizontal,
                              spacing: 4,
                            ),
                          );
                        default:
                          return const DataCell(Text(''));
                      }
                    },
                    onRowTap: (category) => _navigateToForm(category: category),
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
    context.read<CategoryBloc>().add(LoadCategories());
  }

  void _applyFilters() {
    // Filters are applied in real-time through the UI
    setState(() {});
  }

  void _navigateToForm({Category? category}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryFormScreen(category: category),
      ),
    ).then((_) {
      // Refresh the list when returning from form
      context.read<CategoryBloc>().add(LoadCategories());
    });
  }

  void _confirmDelete(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CategoryBloc>().add(DeleteCategory(category.id));
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