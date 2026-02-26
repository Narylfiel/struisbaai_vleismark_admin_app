/// Permission constant keys for role-based access control.
///
/// All permissions are boolean flags stored in:
/// - role_permissions.permissions (jsonb) — role defaults
/// - profiles.permissions (jsonb) — personal overrides
///
/// Use with PermissionService:
/// ```dart
/// if (PermissionService().can(Permissions.seeFinancials)) {
///   // show financial data
/// }
/// ```
class Permissions {
  // ═══════════════════════════════════════════════════════════════════
  // DASHBOARD WIDGETS
  // ═══════════════════════════════════════════════════════════════════

  /// View financial metrics (sales amounts, margin, avg basket)
  static const seeFinancials = 'see_financials';

  /// View rand amounts on 7-day sales chart
  static const seeChartAmounts = 'see_chart_amounts';

  /// View transaction counts on 7-day sales chart
  static const seeChartCounts = 'see_chart_counts';

  /// View alert widgets (shrinkage, reorder, overdue)
  static const seeAlerts = 'see_alerts';

  /// View top 5 products widget
  static const seeTopProducts = 'see_top_products';

  /// View revenue mode on top products widget
  static const seeTopRevenue = 'see_top_revenue';

  // ═══════════════════════════════════════════════════════════════════
  // MODULE ACCESS
  // ═══════════════════════════════════════════════════════════════════

  /// Access Inventory module (products, stock, categories, suppliers)
  static const manageInventory = 'manage_inventory';

  /// Access Production module (batches, dryer, carcass intake)
  static const manageProduction = 'manage_production';

  /// Access HR module (staff profiles, payroll, leave)
  static const manageHr = 'manage_hr';

  /// Access Accounts module (business accounts, statements, payments)
  static const manageAccounts = 'manage_accounts';

  /// Access Bookkeeping module (invoices, ledger, VAT)
  static const manageBookkeeping = 'manage_bookkeeping';

  /// Access Hunter Jobs module (intake and processing)
  static const manageHunters = 'manage_hunters';

  /// Access Promotions module (deals and promotions)
  static const managePromotions = 'manage_promotions';

  /// Access Customers module (loyalty customers)
  static const manageCustomers = 'manage_customers';

  /// View system audit log
  static const viewAuditLog = 'view_audit_log';

  /// Access Settings module (business settings and config)
  static const manageSettings = 'manage_settings';

  /// Access User Management (add/edit admin users — typically owner only)
  static const manageUsers = 'manage_users';

  // ═══════════════════════════════════════════════════════════════════
  // PERMISSION METADATA
  // ═══════════════════════════════════════════════════════════════════

  /// All available permissions with display names and descriptions.
  static const Map<String, Map<String, String>> metadata = {
    seeFinancials: {
      'name': 'View Financials',
      'description': 'Sales amounts, margin, avg basket',
    },
    seeChartAmounts: {
      'name': 'Chart: R Values',
      'description': 'Show rand amounts on 7-day chart',
    },
    seeChartCounts: {
      'name': 'Chart: Counts',
      'description': 'Show transaction counts on chart',
    },
    seeAlerts: {
      'name': 'View Alerts',
      'description': 'Shrinkage, reorder, overdue alerts',
    },
    seeTopProducts: {
      'name': 'Top Products',
      'description': 'View top 5 products widget',
    },
    seeTopRevenue: {
      'name': 'Top Products: Revenue',
      'description': 'Show revenue mode on top products',
    },
    manageInventory: {
      'name': 'Inventory',
      'description': 'Products, stock, categories',
    },
    manageProduction: {
      'name': 'Production',
      'description': 'Batches, dryer, carcass',
    },
    manageHr: {
      'name': 'HR & Staff',
      'description': 'Staff profiles, payroll, leave',
    },
    manageAccounts: {
      'name': 'Accounts',
      'description': 'Business accounts, statements',
    },
    manageBookkeeping: {
      'name': 'Bookkeeping',
      'description': 'Invoices, ledger, VAT',
    },
    manageHunters: {
      'name': 'Hunter Jobs',
      'description': 'Hunter intake and processing',
    },
    managePromotions: {
      'name': 'Promotions',
      'description': 'Promotions and deals',
    },
    manageCustomers: {
      'name': 'Customers',
      'description': 'Loyalty customers',
    },
    viewAuditLog: {
      'name': 'Audit Log',
      'description': 'View system audit trail',
    },
    manageSettings: {
      'name': 'Settings',
      'description': 'Business settings and config',
    },
    manageUsers: {
      'name': 'User Management',
      'description': 'Add/edit admin users (owner only)',
    },
  };

  /// Get all permission keys in order.
  static List<String> get allKeys => [
        seeFinancials,
        seeChartAmounts,
        seeChartCounts,
        seeAlerts,
        seeTopProducts,
        seeTopRevenue,
        manageInventory,
        manageProduction,
        manageHr,
        manageAccounts,
        manageBookkeeping,
        manageHunters,
        managePromotions,
        manageCustomers,
        viewAuditLog,
        manageSettings,
        manageUsers,
      ];

  /// Get display name for a permission key.
  static String getName(String key) =>
      metadata[key]?['name'] ?? key;

  /// Get description for a permission key.
  static String getDescription(String key) =>
      metadata[key]?['description'] ?? '';
}
