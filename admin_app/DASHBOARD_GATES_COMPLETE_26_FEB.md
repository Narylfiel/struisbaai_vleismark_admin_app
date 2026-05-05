# PERMISSION GATES IMPLEMENTATION — COMPLETE
**Date**: 26 February 2026  
**Status**: ✅ COMPLETE — Permission-based UI gates active

---

## 📋 SUMMARY

Implemented comprehensive permission-based gates for the sidebar navigation and dashboard widgets. The system dynamically shows/hides UI elements based on user permissions loaded at login, providing fine-grained access control without hard-coded role checks.

---

## 🎯 DELIVERABLES

### 1. Main Shell (Sidebar Navigation) — COMPLETE REWRITE
**File**: `lib/features/dashboard/screens/main_shell.dart`

**Structural Changes**:
- Removed all hardcoded `isOwner`/`isLimitedRole` logic
- Replaced with `PermissionService()` checks for each nav item
- Added `locked` property to `_NavItem` class
- Updated `_SidebarItem` widget to display locked state
- Added content area protection with `_buildAccessDenied()` method

**Key Features**:
- **Locked Items Display**: Greyed out with lock icon + tooltip
- **Navigation Blocking**: Locked items non-interactive (no tap response)
- **Content Protection**: Shows "Access Restricted" screen if locked item selected
- **Always Visible**: All 14 nav items always shown (Dashboard + 13 modules)

**Permission Mapping**:
```
Dashboard    → Always accessible (no permission check)
Inventory    → Permissions.manageInventory
Promotions   → Permissions.managePromotions
Production   → Permissions.manageProduction
Hunter       → Permissions.manageHunters
HR / Staff   → Permissions.manageHr
Compliance   → Permissions.manageHr
Accounts     → Permissions.manageAccounts
Bookkeeping  → Permissions.manageBookkeeping
Analytics    → Permissions.manageInventory
Reports      → Permissions.manageInventory
Customers    → Permissions.manageCustomers
Audit Log    → Permissions.viewAuditLog
Settings     → Permissions.manageSettings
```

### 2. Dashboard Screen — TARGETED UPDATES
**File**: `lib/features/dashboard/screens/dashboard_screen.dart`

**Added Features**:
1. **Permission Getters** (6 computed properties)
2. **KPI Cards Gating** (3 financial cards)
3. **Dual Chart System** (amounts chart OR counts chart)
4. **Top 5 Products Widget** (new feature)
5. **Alerts Panel Gating**
6. **Refresh Button** (top bar)

---

## 🔐 PERMISSION GATES IMPLEMENTED

### Sidebar Navigation (Main Shell)

#### Locked Item Visual Design
```
┌─────────────────────────────────────┐
│ [grey icon]  Module Name   [lock]  │  ← 30% opacity, no hover
└─────────────────────────────────────┘
```

**Locked State Styling**:
- Icon: 30% opacity of `AppColors.sidebarText`
- Label: 30% opacity of `AppColors.sidebarText`
- Lock icon: 12px, 30% opacity, right-aligned
- Tooltip: "Access restricted"
- No hover effect
- No tap response (onTap: empty function)

**Access Denied Screen** (when locked item selected):
- Large lock icon (64px, grey)
- Title: "Access Restricted" (20pt bold)
- Message: "You do not have permission to access [Module Name]"
- Centered layout

### Dashboard Widgets

#### 1. KPI Cards (Stats Row)
**Gated Cards** (3 of 4):
- **Today's Sales** → `see_financials`
- **Avg Basket** → `see_financials`
- **Gross Margin** → `see_financials`

**Always Visible** (1 of 4):
- **Transactions** → No gate (count only, no amounts)

**Behavior**:
- Gated cards completely hidden if permission denied
- Row dynamically adjusts spacing (SizedBox.width: 12 removed with cards)
- Transactions card always takes at least 1/4 width (Expanded)

#### 2. 7-Day Chart
**Dual Mode System**:
```dart
if (_canSeeChartAmounts)
  _build7DayChart()              // Sales amounts (R values)
else if (_canSeeChartCounts)
  _buildTransactionCountChart()  // Transaction counts only
else
  const SizedBox.shrink()        // No chart
```

**Chart A**: Sales Amounts
- Permission: `see_chart_amounts`
- Title: "SALES (LAST 7 DAYS)"
- Y-axis: Rand amounts
- Data: `_sevenDaySales` from `DashboardRepository`
- Color: `AppColors.primary`

**Chart B**: Transaction Counts (**NEW**)
- Permission: `see_chart_counts`
- Title: "TRANSACTIONS (LAST 7 DAYS)"
- Y-axis: Integer counts
- Data: `_weeklyTransactionCounts` (Map<String, int>)
- Color: `AppColors.info`
- Load method: `_loadWeeklyTransactionCounts()`

**Fallback Priority**:
1. Show amounts chart if `see_chart_amounts` = true
2. Else show counts chart if `see_chart_counts` = true
3. Else hide chart section entirely

#### 3. Top 5 Products Widget (**NEW**)
**Permissions**:
- Widget visibility: `see_top_products`
- Revenue mode toggle: `see_top_revenue`

**Display Modes**:
1. **Revenue Mode** (default if `see_top_revenue` = true)
   - Shows R amounts per product
   - Sorted by total_revenue descending
   - Green bold text: "R XXX.XX"

2. **Quantity Mode** (default if `see_top_revenue` = false, or user switches)
   - Shows quantities sold
   - Sorted by total_qty descending
   - Bold text: "X.X kg" (or unit_type)

**UI Elements**:
- Card with "TOP 5 PRODUCTS" title
- Orange trending_up icon (18px)
- **If `see_top_revenue`**: SegmentedButton toggle (Revenue | Qty)
- **If NOT `see_top_revenue`**: Static text "By Quantity" (grey, 12px)

**Rank Indicators**:
```
1st place: Gold circle (Colors.amber) + white text
2nd place: Silver circle (Colors.grey[400]) + white text
3rd place: Bronze circle (Colors.brown[300]) + white text
4th-5th: Light grey circle (Colors.grey[200]) + grey text
```

**Data Loading**:
1. Query transactions for today (gte: start of day)
2. Get transaction IDs list
3. Query transaction_items with `.inFilter('transaction_id', txIds)`
4. Join inventory_items (plu_code, name, unit_type)
5. Group by PLU client-side
6. Sum total_qty and total_revenue per product
7. Sort by selected mode (revenue or quantity)
8. Take top 5

**Empty State**: "No sales data for today" (grey text, centered)

#### 4. Alerts Panel
**Gate**: `see_alerts`

**Behavior**:
- If gated: Panel completely hidden
- Clock-in status widget flex adjusts:
  - With alerts: `flex: 2` (smaller, right side)
  - Without alerts: `flex: 1` (full width)

**Content** (4 alert types):
- Shrinkage alerts (red)
- Reorder recommendations (orange)
- Overdue accounts (orange)
- Pending leave requests (blue)

#### 5. Refresh Button
**Location**: AppBar top-right corner (after date text)

**Behavior**: Calls `_refreshDashboard()`:
```dart
void _refreshDashboard() {
  _loadSalesStats();
  if (_canSeeChartAmounts) _load7DaySales();
  if (_canSeeChartCounts && !_canSeeChartAmounts) _loadWeeklyTransactionCounts();
  if (_canSeeAlerts) _loadAlerts();
  _loadClockInStatus();
  if (_canSeeTopProducts) _loadTopProducts();
}
```

**Icon**: `Icons.refresh`, 18px, `AppColors.textSecondary`  
**Tooltip**: "Refresh dashboard"

---

## 📊 DASHBOARD LAYOUT FLOW

### Full Access User (All Permissions)
```
┌────────────────────────────────────────────────┐
│ [Stats Row: Sales | Transactions | Basket | Margin]
├────────────────────────────────────────────────┤
│ [Sales Chart (7-day amounts)]                  │
├────────────────────────────────────────────────┤
│ [Top 5 Products with Revenue/Qty toggle]       │
├────────────────────────────────────────────────┤
│ [Alerts (60%)]        │ [Clock-in Status (40%)]│
└────────────────────────────────────────────────┘
```

### Limited Access User (No Financial Data)
```
┌────────────────────────────────────────────────┐
│ [Stats Row: Transactions only (full width)]    │
├────────────────────────────────────────────────┤
│ [Transaction Count Chart (7-day counts)]       │
├────────────────────────────────────────────────┤
│ [Top 5 Products — Quantity only, no toggle]    │
├────────────────────────────────────────────────┤
│ [Clock-in Status (full width, no alerts)]      │
└────────────────────────────────────────────────┘
```

### Minimal Access User (Counts Only)
```
┌────────────────────────────────────────────────┐
│ [Stats Row: Transactions only (full width)]    │
├────────────────────────────────────────────────┤
│ [Transaction Count Chart (7-day counts)]       │
├────────────────────────────────────────────────┤
│ [Clock-in Status (full width)]                 │
└────────────────────────────────────────────────┘
```

---

## 🔧 TECHNICAL IMPLEMENTATION

### Permission Service Integration

**Main Shell**:
```dart
List<_NavItem> get _navItems {
  final ps = PermissionService();

  _NavItem item(IconData icon, String label, Widget screen, String permission) {
    final hasAccess = ps.can(permission);
    return _NavItem(
      icon: icon,
      label: label,
      screen: screen,
      locked: !hasAccess,
    );
  }

  return [
    _NavItem(icon: Icons.dashboard, label: 'Dashboard', screen: const DashboardScreen()),
    item(Icons.inventory_2, 'Inventory', const InventoryNavigationScreen(), Permissions.manageInventory),
    // ... etc
  ];
}
```

**Dashboard Screen**:
```dart
final _ps = PermissionService();

bool get _canSeeFinancials   => _ps.can(Permissions.seeFinancials);
bool get _canSeeChartAmounts => _ps.can(Permissions.seeChartAmounts);
bool get _canSeeChartCounts  => _ps.can(Permissions.seeChartCounts);
bool get _canSeeAlerts       => _ps.can(Permissions.seeAlerts);
bool get _canSeeTopProducts  => _ps.can(Permissions.seeTopProducts);
bool get _canSeeTopRevenue   => _ps.can(Permissions.seeTopRevenue);
```

### State Variables Added

**Dashboard Screen**:
```dart
// Top products
List<Map<String,dynamic>> _topProducts = [];
bool _isLoadingTopProducts = false;
String _topProductsMode = 'revenue';

// Transaction counts chart
Map<String, int> _weeklyTransactionCounts = {};
```

### New Methods Added

**Dashboard Screen**:
1. `Widget _buildTransactionCountChart()` — Counts-only chart
2. `Future<void> _loadWeeklyTransactionCounts()` — Load 7-day counts
3. `Widget _buildTopProductsWidget()` — Top 5 products widget
4. `Widget _buildTopProductRow(int rank, Map product)` — Product row UI
5. `Future<void> _loadTopProducts()` — Load today's top products
6. `void _refreshDashboard()` — Refresh all widgets
7. `String _formattedDate()` — Format current date for AppBar

**Main Shell**:
1. `Widget _buildAccessDenied(String screenName)` — Access denied screen

### New Data Classes

**Dashboard Screen**:
```dart
class _DayCountPoint {
  final String label;
  final int count;
  _DayCountPoint(this.label, this.count);
}
```

---

## 📝 SCHEMA USAGE

### Transactions Count Query
```dart
final data = await _supabase
    .from('transactions')
    .select('created_at')
    .gte('created_at', sevenDaysAgo.toIso8601String());
```

### Top Products Query (Two-Step)
**Step 1**: Get today's transaction IDs
```dart
final txData = await _supabase
    .from('transactions')
    .select('id')
    .gte('created_at', startOfDay.toIso8601String());
```

**Step 2**: Get transaction items with inventory join
```dart
final itemData = await _supabase
    .from('transaction_items')
    .select('''
      quantity, line_total,
      inventory_items(plu_code, name, unit_type)
    ''')
    .inFilter('transaction_id', txIds);
```

**Aggregation**: Client-side grouping by PLU with sum of quantities and revenues

---

## ✅ TESTING CHECKLIST

### Sidebar Navigation
- [ ] Dashboard always accessible (no lock)
- [ ] Locked items shown with grey style + lock icon
- [ ] Locked items show "Access restricted" tooltip on hover
- [ ] Locked items do not navigate on click
- [ ] Locked item selected → shows access denied screen
- [ ] Access denied screen displays correct module name
- [ ] Unlocked items navigate normally
- [ ] Owner sees all unlocked
- [ ] Non-owner sees appropriate locks per role

### Dashboard - KPI Cards
- [ ] Today's Sales hidden if `!see_financials`
- [ ] Avg Basket hidden if `!see_financials`
- [ ] Gross Margin hidden if `!see_financials`
- [ ] Transactions always visible
- [ ] Row spacing adjusts when cards hidden

### Dashboard - Charts
- [ ] Sales chart shows if `see_chart_amounts`
- [ ] Transaction count chart shows if `see_chart_counts && !see_chart_amounts`
- [ ] No chart if both permissions false
- [ ] Charts load correct data
- [ ] Chart titles correct for each type

### Dashboard - Top Products
- [ ] Widget hidden if `!see_top_products`
- [ ] Revenue mode default if `see_top_revenue`
- [ ] Quantity mode default if `!see_top_revenue`
- [ ] Toggle button shown if `see_top_revenue`
- [ ] Toggle button hidden if `!see_top_revenue`
- [ ] Static "By Quantity" text shown if `!see_top_revenue`
- [ ] Revenue values shown in revenue mode
- [ ] Quantity values shown in quantity mode
- [ ] Rank circles colored correctly (gold, silver, bronze, grey)
- [ ] Empty state shown if no sales today
- [ ] Loading indicator shown during load

### Dashboard - Alerts & Clock-in
- [ ] Alerts panel hidden if `!see_alerts`
- [ ] Clock-in widget full width if alerts hidden
- [ ] Clock-in widget 40% width if alerts shown
- [ ] Alerts panel shows all 4 alert types

### Dashboard - Refresh Button
- [ ] Refresh button visible in AppBar
- [ ] Refresh button reloads all permitted widgets
- [ ] Refresh respects permission gates (doesn't load gated data)

---

## 🔍 PERMISSION MATRIX

| Permission | Affects | Notes |
|------------|---------|-------|
| `manage_inventory` | Sidebar: Inventory, Analytics, Reports | Analytics = shrinkage, Reports = inventory reports |
| `manage_production` | Sidebar: Production | |
| `manage_hr` | Sidebar: HR / Staff, Compliance | Same permission for both tabs |
| `manage_accounts` | Sidebar: Accounts | |
| `manage_bookkeeping` | Sidebar: Bookkeeping | |
| `manage_hunters` | Sidebar: Hunter | |
| `manage_promotions` | Sidebar: Promotions | |
| `manage_customers` | Sidebar: Customers | |
| `view_audit_log` | Sidebar: Audit Log | |
| `manage_settings` | Sidebar: Settings | |
| `see_financials` | Dashboard: 3 KPI cards (Sales, Basket, Margin) | |
| `see_chart_amounts` | Dashboard: Sales amounts chart (7-day) | Primary chart option |
| `see_chart_counts` | Dashboard: Transaction counts chart (7-day) | Fallback if amounts denied |
| `see_alerts` | Dashboard: Alerts panel | |
| `see_top_products` | Dashboard: Top 5 products widget visibility | |
| `see_top_revenue` | Dashboard: Revenue mode toggle + R values | If false, quantity-only |

---

## 🎨 UI/UX DECISIONS

### Why Locked Items Stay Visible
**Design Choice**: Show locked items (greyed) rather than hide them entirely.

**Rationale**:
1. **Discoverability**: Users know what features exist
2. **Transparency**: Clear indication of access restrictions
3. **Consistency**: Sidebar layout doesn't shift between roles
4. **Upgrade Path**: Users can see what they'd gain with different permissions

### Why Dashboard Uses Conditional Rendering
**Design Choice**: Hide gated widgets entirely rather than show locked placeholders.

**Rationale**:
1. **Clean Layout**: No visual clutter from inaccessible widgets
2. **Adaptive Layout**: Remaining widgets expand to fill space
3. **Natural Flow**: Dashboard feels purpose-built for user's role
4. **Performance**: Don't render hidden complex widgets

### Chart Fallback Strategy
**Design Choice**: Show transaction counts chart if amounts chart denied.

**Rationale**:
1. **Value Preservation**: Don't leave chart area blank
2. **Non-Sensitive Data**: Transaction counts reveal no financial info
3. **Operational Insight**: Still useful for activity monitoring
4. **Progressive Disclosure**: Some data better than no data

---

## 🚀 BUILD STATUS

**Dart Analysis**: ✅ PASS  
**Exit Code**: 0 (after removing unused import)  
**New Errors**: None

**Pre-existing Warnings** (not introduced by this change):
- withOpacity deprecation warnings (Flutter SDK change)
- prefer_const_constructors style hints

**Files Modified**: 2
- `main_shell.dart` — Complete rewrite (459 lines)
- `dashboard_screen.dart` — Targeted updates (~350 lines added)

---

## 📚 NEXT STEPS (NOT IN THIS IMPLEMENTATION)

This implementation provides the **UI gates foundation**. Future work:

### Module-Level Gates
- Entry point protection for each module
- "Access Denied" screens at module root
- Disable action buttons within modules

### Row-Level Action Gates
- Hide/disable edit buttons based on permissions
- Gate delete actions
- Protect sensitive operations

### Feature-Specific Gates
- Export functionality
- Import operations
- Bulk actions
- Admin-only features within modules

---

**End of Implementation Report**
