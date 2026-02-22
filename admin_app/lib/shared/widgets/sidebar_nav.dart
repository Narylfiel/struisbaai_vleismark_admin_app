import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Navigation sidebar widget for the admin app
class SidebarNav extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final String userRole;

  const SidebarNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.userRole,
  });

  @override
  State<SidebarNav> createState() => _SidebarNavState();
}

class _SidebarNavState extends State<SidebarNav> {
  late List<_NavItem> _navItems;

  @override
  void initState() {
    super.initState();
    _navItems = _getNavItems();
  }

  List<_NavItem> _getNavItems() {
    final isOwner = widget.userRole == 'owner';
    return [
      _NavItem(icon: Icons.dashboard, label: 'Dashboard'),
      _NavItem(icon: Icons.inventory_2, label: 'Inventory'),
      _NavItem(icon: Icons.cut, label: 'Production'),
      _NavItem(icon: Icons.forest, label: 'Hunter'),
      _NavItem(icon: Icons.people, label: 'HR / Staff'),
      _NavItem(icon: Icons.credit_card, label: 'Accounts'),
      if (isOwner) _NavItem(icon: Icons.book, label: 'Bookkeeping'),
      _NavItem(icon: Icons.analytics, label: 'Analytics'),
      _NavItem(icon: Icons.summarize, label: 'Reports'),
      _NavItem(icon: Icons.person_search, label: 'Customers'),
      _NavItem(icon: Icons.visibility, label: 'Audit'),
      if (isOwner) _NavItem(icon: Icons.settings, label: 'Settings'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: AppColors.cardBg,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(20),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.store, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Struisbaai\nVleismark',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = index == widget.selectedIndex;

                return _NavListTile(
                  icon: item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  onTap: () => widget.onItemSelected(index),
                );
              },
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Admin v2.0',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  _NavItem({required this.icon, required this.label});
}

class _NavListTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavListTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1)
            : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}