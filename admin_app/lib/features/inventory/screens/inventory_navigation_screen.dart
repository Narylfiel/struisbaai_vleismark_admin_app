import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../blocs/category/category_bloc.dart';
import '../blocs/category/category_state.dart';
import 'category_list_screen.dart';
import 'product_list_screen.dart';

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
            ActionButtons.add(
              onPressed: () => _navigateToCategoryForm(),
              iconOnly: true,
            ),
          if (_tabController.index == 1) // Products
            ActionButtons.add(
              onPressed: () => _navigateToProductForm(),
              iconOnly: true,
            ),
          if (_tabController.index == 2) // Modifiers
            ActionButtons.add(
              onPressed: () => _navigateToModifierForm(),
              iconOnly: true,
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Categories Tab
          BlocProvider(
            create: (context) => CategoryBloc(context.read()),
            child: const CategoryListScreen(),
          ),

          // Products Tab
          const ProductListScreen(),

          // Modifiers Tab - Placeholder for now
          const _ModifiersPlaceholderScreen(),

          // Stock Levels Tab - Placeholder for now
          const _StockLevelsPlaceholderScreen(),
        ],
      ),
    );
  }

  void _navigateToCategoryForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<CategoryBloc>(),
          child: const CategoryFormScreen(),
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
    // TODO: Implement modifier form navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modifier form coming soon')),
    );
  }
}

/// Placeholder screen for modifiers
class _ModifiersPlaceholderScreen extends StatelessWidget {
  const _ModifiersPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_circle_outline,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Modifier Groups',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create modifier groups for product customization\n(e.g., sauces, cooking preferences)',
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
                const SnackBar(content: Text('Modifier management coming soon')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Modifier Group'),
          ),
        ],
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
          Icon(
            Icons.warehouse,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Stock Levels',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
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