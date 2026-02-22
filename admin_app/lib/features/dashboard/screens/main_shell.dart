import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/constants/admin_config.dart';
import 'package:admin_app/features/auth/screens/pin_screen.dart';
import 'package:admin_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:admin_app/features/inventory/screens/inventory_navigation_screen.dart';
import 'package:admin_app/features/production/screens/carcass_intake_screen.dart';
import 'package:admin_app/features/hunter/screens/job_list_screen.dart';
import 'package:admin_app/features/hr/screens/staff_list_screen.dart';
import 'package:admin_app/features/accounts/screens/account_list_screen.dart';
import 'package:admin_app/features/bookkeeping/screens/invoice_list_screen.dart';
import 'package:admin_app/features/analytics/screens/shrinkage_screen.dart';
import 'package:admin_app/features/reports/screens/report_hub_screen.dart';
import 'package:admin_app/features/customers/screens/customer_list_screen.dart';
import 'package:admin_app/features/audit/screens/audit_log_screen.dart';
import 'package:admin_app/features/settings/screens/business_settings_screen.dart';

class MainShell extends StatefulWidget {
  final String staffId;
  final String staffName;
  final String role;

  const MainShell({
    super.key,
    required this.staffId,
    required this.staffName,
    required this.role,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  List<_NavItem> get _navItems {
    final isOwner = widget.role == 'owner';
    return [
      _NavItem(icon: Icons.dashboard,     label: 'Dashboard',   screen: const DashboardScreen()),
      _NavItem(icon: Icons.inventory_2,   label: 'Inventory',   screen: const InventoryNavigationScreen()),
      _NavItem(icon: Icons.cut,           label: 'Production',  screen: const CarcassIntakeScreen()),
      _NavItem(icon: Icons.forest,        label: 'Hunter',      screen: const JobListScreen()),
      _NavItem(icon: Icons.people,        label: 'HR / Staff',  screen: const StaffListScreen()),
      _NavItem(icon: Icons.credit_card,   label: 'Accounts',    screen: const AccountListScreen()),
      if (isOwner)
        _NavItem(icon: Icons.book,        label: 'Bookkeeping', screen: const InvoiceListScreen()),
      _NavItem(icon: Icons.analytics,     label: 'Analytics',   screen: const ShrinkageScreen()),
      _NavItem(icon: Icons.summarize,     label: 'Reports',     screen: const ReportHubScreen()),
      _NavItem(icon: Icons.person_search, label: 'Customers',   screen: const CustomerListScreen()),
      _NavItem(icon: Icons.history,       label: 'Audit Log',   screen: const AuditLogScreen()),
      if (isOwner)
        _NavItem(icon: Icons.settings,    label: 'Settings',    screen: const BusinessSettingsScreen()),
    ];
  }

  void _logout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PinScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _navItems;
    final selected = _selectedIndex.clamp(0, items.length - 1);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          SizedBox(
            width: 220,
            child: Container(
              color: AppColors.sidebarBg,
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.storefront,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                AdminConfig.appName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person,
                                  color: AppColors.sidebarText, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.staffName,
                                  style: const TextStyle(
                                    color: AppColors.sidebarText,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.role.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 8),

                  // Nav items
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        final isSelected = i == selected;
                        return _SidebarItem(
                          icon: item.icon,
                          label: item.label,
                          isSelected: isSelected,
                          onTap: () => setState(() => _selectedIndex = i),
                        );
                      },
                    ),
                  ),

                  // Logout
                  const Divider(color: Colors.white12, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: _SidebarItem(
                      icon: Icons.logout,
                      label: 'Log Out',
                      isSelected: false,
                      onTap: _logout,
                      isDestructive: true,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main content
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 52,
                  color: AppColors.cardBg,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        items[selected].label,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formattedDate(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),

                // Screen content
                Expanded(child: items[selected].screen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Widget screen;
  _NavItem({required this.icon, required this.label, required this.screen});
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.sidebarSelected : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isDestructive
                    ? AppColors.error
                    : isSelected
                        ? Colors.white
                        : AppColors.sidebarText,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isDestructive
                      ? AppColors.error
                      : isSelected
                          ? Colors.white
                          : AppColors.sidebarText,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
