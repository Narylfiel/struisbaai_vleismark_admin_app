import 'package:flutter/material.dart';

/// Blueprint §11: Report types with key, title, category, frequency, access.
class ReportDefinition {
  final String key;
  final String title;
  final String category;
  final String frequency;
  final IconData icon;
  final bool requiresDateRange;
  final bool ownerOnly;

  const ReportDefinition({
    required this.key,
    required this.title,
    required this.category,
    required this.frequency,
    required this.icon,
    this.requiresDateRange = true,
    this.ownerOnly = false,
  });
}

/// Blueprint §11.1: All report types.
class ReportDefinitions {
  static const List<ReportDefinition> all = [
    ReportDefinition(key: 'daily_sales', title: 'Daily Sales Summary', category: 'Operations', frequency: 'Daily (auto)', icon: Icons.point_of_sale, requiresDateRange: false),
    ReportDefinition(key: 'weekly_sales', title: 'Weekly Sales Report', category: 'Operations', frequency: 'Weekly (auto)', icon: Icons.trending_up),
    ReportDefinition(key: 'monthly_pl', title: 'Monthly P&L', category: 'Financial', frequency: 'Monthly (auto)', icon: Icons.bar_chart, ownerOnly: true),
    ReportDefinition(key: 'vat201', title: 'VAT201 Report', category: 'Financial', frequency: 'Monthly (auto)', icon: Icons.request_quote, ownerOnly: true),
    ReportDefinition(key: 'cash_flow', title: 'Cash Flow', category: 'Financial', frequency: 'Monthly (auto)', icon: Icons.account_balance_wallet, ownerOnly: true),
    ReportDefinition(key: 'staff_hours', title: 'Staff Hours Report', category: 'Staff & HR', frequency: 'Weekly / Monthly', icon: Icons.access_time),
    ReportDefinition(key: 'payroll', title: 'Payroll Report', category: 'Staff & HR', frequency: 'Monthly', icon: Icons.payments, ownerOnly: true),
    ReportDefinition(key: 'inventory_valuation', title: 'Inventory Valuation', category: 'Inventory', frequency: 'On demand', icon: Icons.inventory),
    ReportDefinition(key: 'shrinkage', title: 'Shrinkage Report', category: 'Inventory', frequency: 'Weekly (auto)', icon: Icons.warning_amber),
    ReportDefinition(key: 'supplier_spend', title: 'Supplier Spend Report', category: 'Inventory', frequency: 'Monthly', icon: Icons.local_shipping),
    ReportDefinition(key: 'expense_by_category', title: 'Expense Report by Category', category: 'Financial', frequency: 'On demand', icon: Icons.receipt_long, ownerOnly: true),
    ReportDefinition(key: 'product_performance', title: 'Product Performance', category: 'Inventory', frequency: 'On demand', icon: Icons.star),
    ReportDefinition(key: 'customer_loyalty', title: 'Customer (Loyalty) Report', category: 'Operations', frequency: 'Monthly', icon: Icons.people),
    ReportDefinition(key: 'hunter_jobs', title: 'Hunter Jobs Report', category: 'Operations', frequency: 'Monthly', icon: Icons.assignment),
    ReportDefinition(key: 'audit_trail', title: 'Audit Trail Report', category: 'Compliance', frequency: 'On demand', icon: Icons.security, ownerOnly: true),
    ReportDefinition(key: 'bcea_compliance', title: 'BCEA Compliance Report', category: 'Compliance', frequency: 'Monthly (auto)', icon: Icons.fact_check, ownerOnly: true),
    ReportDefinition(key: 'blockman_performance', title: 'Blockman Performance Report', category: 'Staff & HR', frequency: 'Monthly', icon: Icons.content_cut),
    ReportDefinition(key: 'event_forecast', title: 'Event / Holiday Forecast Report', category: 'Operations', frequency: 'On demand', icon: Icons.event, ownerOnly: true),
    ReportDefinition(key: 'sponsorship_donations', title: 'Sponsorship & Donations Log', category: 'Compliance', frequency: 'On demand', icon: Icons.volunteer_activism, ownerOnly: true),
    ReportDefinition(key: 'staff_loan_credit', title: 'Staff Loan & Credit Report', category: 'Staff & HR', frequency: 'On demand', icon: Icons.credit_card, ownerOnly: true),
    ReportDefinition(key: 'awol', title: 'AWOL / Absconding Report', category: 'Compliance', frequency: 'On demand', icon: Icons.warning_amber, ownerOnly: true),
    ReportDefinition(key: 'equipment_depreciation', title: 'Equipment Depreciation Schedule', category: 'Financial', frequency: 'Annual / On demand', icon: Icons.business, ownerOnly: true),
    ReportDefinition(key: 'purchase_sale_agreement', title: 'Purchase Sale Agreement History', category: 'Financial', frequency: 'On demand', icon: Icons.handshake, ownerOnly: true),
  ];

  static List<String> get categories => ['All Reports', 'Financial', 'Inventory', 'Staff & HR', 'Operations', 'Compliance'];

  static ReportDefinition? byKey(String key) {
    try {
      return all.firstWhere((r) => r.key == key);
    } catch (_) {
      return null;
    }
  }
}
