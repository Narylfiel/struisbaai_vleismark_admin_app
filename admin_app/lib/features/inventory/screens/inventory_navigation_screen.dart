import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../blocs/category/category_bloc.dart';
import 'category_list_screen.dart';
import 'product_list_screen.dart';
import 'modifier_group_list_screen.dart';
import 'supplier_list_screen.dart';
import 'stock_take_screen.dart';
import 'stock_levels_screen.dart';
import 'waste_log_screen.dart';
import 'stock_movements_screen.dart';

/// Inventory module: layout matches dominant app pattern (no AppBar, TabBar in body).
/// Add actions live inside each tab screen (Categories, Products, Modifiers, Suppliers).
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
    _tabController = TabController(length: 8, vsync: this);
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
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        body: Column(
          children: [
            Container(
              color: AppColors.cardBg,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(icon: Icon(Icons.category, size: 18), text: 'Categories'),
                  Tab(icon: Icon(Icons.inventory_2, size: 18), text: 'Products'),
                  Tab(icon: Icon(Icons.add_circle_outline, size: 18), text: 'Modifiers'),
                  Tab(icon: Icon(Icons.local_shipping, size: 18), text: 'Suppliers'),
                  Tab(icon: Icon(Icons.checklist, size: 18), text: 'Stock-Take'),
                  Tab(icon: Icon(Icons.warehouse, size: 18), text: 'Stock Levels'),
                  Tab(icon: Icon(Icons.warning_amber_outlined, size: 18), text: 'Waste Log'),
                  Tab(icon: Icon(Icons.swap_vert, size: 18), text: 'Movements'),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  CategoryListScreen(),
                  ProductListScreen(),
                  ModifierGroupListScreen(),
                  SupplierListScreen(),
                  StockTakeScreen(),
                  StockLevelsScreen(),
                  WasteLogScreen(),
                  StockMovementsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
