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

                  if (filteredCategories.isEmpty) {
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

                  return SingleChildScrollView(
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
                        rows: filteredCategories.map((category) {
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
                                  category.name,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              DataCell(
                                Text(
                                  category.notes ?? '',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              DataCell(
                                Text(category.sortOrder.toString()),
                              ),
                              DataCell(
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
                              ),
                              DataCell(
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
                                  compact: true,
                                  spacing: 8,
                                ),
                              ),
                            ]
                          );
                        }).toList(),
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