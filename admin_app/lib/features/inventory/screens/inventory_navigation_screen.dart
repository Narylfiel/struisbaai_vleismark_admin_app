import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../core/services/supabase_service.dart';
import '../blocs/category/category_bloc.dart';
import 'category_list_screen.dart';
import 'category_form_screen.dart';
import 'product_list_screen.dart';
import 'modifier_group_list_screen.dart';
import 'modifier_group_form_screen.dart';

class InventoryNavigationScreen extends StatefulWidget {
  const InventoryNavigationScreen({super.key});

  @override
  State<InventoryNavigationScreen> createState() => _InventoryNavigationScreenState();
}

class _InventoryNavigationScreenState extends State<InventoryNavigationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CategoryBloc(SupabaseService()),
      child: Builder(
        builder: (context) {
          return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Categories', icon: Icon(Icons.category)),
            Tab(text: 'Products', icon: Icon(Icons.inventory_2)),
            Tab(text: 'Modifiers', icon: Icon(Icons.add_circle_outline)),
            Tab(text: 'Stock Levels', icon: Icon(Icons.warehouse)),
          ],
        ),
        actions: [
          // Quick actions based on current tab
          if (_tabController.index == 0) // Categories
            ActionButtonsWidget(
              actions: [
                ActionButtons.add(
                  onPressed: () => _navigateToCategoryForm(context),
                  iconOnly: true,
                )
              ],
              compact: true,
            ),
          if (_tabController.index == 1) // Products
            ActionButtonsWidget(
              actions: [
                ActionButtons.add(
                  onPressed: () => _navigateToProductForm(),
                  iconOnly: true,
                )
              ],
              compact: true,
            ),
          if (_tabController.index == 2) // Modifiers
            ActionButtonsWidget(
              actions: [
                ActionButtons.add(
                  onPressed: () => _navigateToModifierForm(),
                  iconOnly: true,
                )
              ],
              compact: true,
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Categories Tab
          const CategoryListScreen(),

          // Products Tab
          const ProductListScreen(),

          // Modifiers Tab - Blueprint §4.3
          const ModifierGroupListScreen(),

          // Stock Levels Tab - Placeholder for now
          const _StockLevelsPlaceholderScreen(),
        ],
      ),
          );
        }
      ),
    );
  }

  void _navigateToCategoryForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<CategoryBloc>(),
          child: CategoryFormScreen(),
        ),
      ),
    );
  }

  void _navigateToProductForm() {
    // TODO: Implement product form navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product form coming soon')),
    );
  }

  void _navigateToModifierForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ModifierGroupFormScreen(),
      ),
    );
  }
}

/// Placeholder screen for stock levels
class _StockLevelsPlaceholderScreen extends StatelessWidget {
  const _StockLevelsPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.warehouse,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Stock Levels',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Monitor inventory levels across all storage locations\nTrack stock movements and reorder alerts',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Stock level management coming soon')),
              );
            },
            icon: const Icon(Icons.visibility),
            label: const Text('View Stock Levels'),
          ),
        ],
      ),
    );
  }
}