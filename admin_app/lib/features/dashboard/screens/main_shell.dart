import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/constants/admin_config.dart';
import 'package:admin_app/core/services/auth_service.dart';
import 'package:admin_app/core/services/permission_service.dart';
import 'package:admin_app/core/constants/permissions.dart';
import 'package:admin_app/features/auth/screens/pin_screen.dart';
import 'package:admin_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:admin_app/features/inventory/screens/inventory_navigation_screen.dart';
import 'package:admin_app/features/promotions/screens/promotion_list_screen.dart';
import 'package:admin_app/features/production/screens/carcass_intake_screen.dart';
import 'package:admin_app/features/hunter/screens/job_list_screen.dart';
import 'package:admin_app/features/hr/screens/staff_list_screen.dart';
import 'package:admin_app/features/hr/screens/compliance_screen.dart';
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

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  DateTime? _lastPausedAt;
  bool _permissionsReady = false;
  List<_NavItem> _navItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _waitForPermissions();
  }

  Future<void> _waitForPermissions() async {
    if (PermissionService().isLoaded) {
      _buildNavItems();
      if (mounted) setState(() => _permissionsReady = true);
      return;
    }
    for (int i = 0; i < 30; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (PermissionService().isLoaded) break;
    }
    _buildNavItems();
    if (mounted) setState(() => _permissionsReady = true);
  }

  void _buildNavItems() {
    final ps = PermissionService();
    setState(() {
      _navItems = [
        _NavItem(
          icon: Icons.dashboard,
          label: 'Dashboard',
          screen: const DashboardScreen(),
          locked: false,
        ),
        _NavItem(
          icon: Icons.inventory_2,
          label: 'Inventory',
          screen: const InventoryNavigationScreen(),
          locked: !ps.can(Permissions.manageInventory),
        ),
        _NavItem(
          icon: Icons.local_offer,
          label: 'Promotions',
          screen: const PromotionListScreen(),
          locked: !ps.can(Permissions.managePromotions),
        ),
        _NavItem(
          icon: Icons.cut,
          label: 'Production',
          screen: const CarcassIntakeScreen(),
          locked: !ps.can(Permissions.manageProduction),
        ),
        _NavItem(
          icon: Icons.forest,
          label: 'Hunter',
          screen: const JobListScreen(),
          locked: !ps.can(Permissions.manageHunters),
        ),
        _NavItem(
          icon: Icons.people,
          label: 'HR / Staff',
          screen: const StaffListScreen(),
          locked: !ps.can(Permissions.manageHr),
        ),
        _NavItem(
          icon: Icons.fact_check,
          label: 'Compliance',
          screen: const ComplianceScreen(),
          locked: !ps.can(Permissions.manageHr),
        ),
        _NavItem(
          icon: Icons.credit_card,
          label: 'Accounts',
          screen: const AccountListScreen(),
          locked: !ps.can(Permissions.manageAccounts),
        ),
        _NavItem(
          icon: Icons.book,
          label: 'Bookkeeping',
          screen: const InvoiceListScreen(),
          locked: !ps.can(Permissions.manageBookkeeping),
        ),
        _NavItem(
          icon: Icons.analytics,
          label: 'Analytics',
          screen: const ShrinkageScreen(),
          locked: !ps.can(Permissions.manageInventory),
        ),
        _NavItem(
          icon: Icons.summarize,
          label: 'Reports',
          screen: const ReportHubScreen(),
          locked: !ps.can(Permissions.manageInventory),
        ),
        _NavItem(
          icon: Icons.person_search,
          label: 'Customers',
          screen: const CustomerListScreen(),
          locked: !ps.can(Permissions.manageCustomers),
        ),
        _NavItem(
          icon: Icons.history,
          label: 'Audit Log',
          screen: const AuditLogScreen(),
          locked: !ps.can(Permissions.viewAuditLog),
        ),
        _NavItem(
          icon: Icons.settings,
          label: 'Settings',
          screen: const BusinessSettingsScreen(),
          locked: !ps.can(Permissions.manageSettings),
        ),
      ];
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _lastPausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_lastPausedAt != null && DateTime.now().difference(_lastPausedAt!) > const Duration(minutes: 5)) {
        AuthService().logout();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const PinScreen()),
            (route) => false,
          );
        }
      }
    }
  }

  void _logout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PinScreen()),
    );
  }

  Widget _buildAccessDenied(String screenName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Access Restricted',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You do not have permission to access $screenName',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show minimal loading until permissions are confirmed loaded
    if (!_permissionsReady) {
      return const Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

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
                          locked: item.locked,
                          onTap: item.locked
                              ? () {}  // blocked — no navigation
                              : () => setState(() => _selectedIndex = i),
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

                // Screen content — protected
                Expanded(
                  child: items[selected].locked
                      ? _buildAccessDenied(items[selected].label)
                      : items[selected].screen,
                ),
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
  final bool locked;
  
  _NavItem({
    required this.icon,
    required this.label,
    required this.screen,
    this.locked = false,
  });
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool locked;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isDestructive = false,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    // Locked style: grey text, grey icon, lock overlay, no tap response
    if (locked) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Tooltip(
          message: 'Access restricted',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.sidebarText.withOpacity(0.3)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.sidebarText.withOpacity(0.3),
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                Icon(
                  Icons.lock_outline,
                  size: 12,
                  color: AppColors.sidebarText.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Normal style
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
