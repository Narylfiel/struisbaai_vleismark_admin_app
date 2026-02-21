# Scaffolding Plan: Analytics & Compliance and Reporting & Exports

**Context:** This document provides the scaffolding plan for implementing the **Analytics & Compliance** and **Reporting & Exports** modules in the Flutter admin app, strictly ensuring alignment with the blueprint (`AdminAppBluePrintTruth.md`). It describes the exact tab structure, UI outlines, required elements, and data bindings necessary for actual code implementation later.

---

## Module 1: Smart Analytics & Compliance

**Blueprint Reference:** Section 10 (`Lines 2103 - 2205`)
**Target File:** `admin_app/lib/features/analytics/screens/shrinkage_screen.dart`
*(Note: Although named shrinkage_screen, it will act as the hub for all 4 analytics features as tabs)*

### Overall Screen Scaffolding
- **App Bar / Header:** Needs a `TabBar` configured with 4 tabs corresponding to the 4 subsections of Module 10.
- **Tabs:** 
  1. `Shrinkage` (Icon: Warning / Timeline)
  2. `Dynamic Pricing` (Icon: Attach Money / Trending Up)
  3. `Reorder Suggestions` (Icon: Shopping Cart / Sync)
  4. `Event Forecasting` (Icon: Event / Calendar Month)

---

### Tab 1: Shrinkage Detection (10.1)
**Purpose:** Daily mass-balance comparison showing theoretical vs actual stock gaps.
**Data Dependencies:** `shrinkage_alerts` table, `inventory_items` table (indirect calculation via stock counts vs transaction/production logs).
**Placeholder Layout:**
- **Header:** "SHRINKAGE ALERTS — This Week" (Date Range picker optional component).
- **List View:** Cards representing individual product alerts.
- **Card Content Elements:**
  - Status/Severity Indicator (🔴 Critical, 🟡 Warning, ✅ OK).
  - Product Name (e.g. "T-Bone Steak").
  - Gap Calculation: `Gap: 2.4 kg (27%)`
  - Subtext: `Theoretical: [X] kg | On-hand: [Y] kg`
  - Automated Insight: `Possible: Theft, unlogged waste, label error`
  - Staff trace: `Staff involved: Mike (breakdown), Sarah (12 sales)`
- **Action Buttons per item:** `[INVESTIGATE]`, `[CONDUCT STOCK-TAKE]`, `[ACCEPT & NOTE]`
**Expected Interaction:** Clicking actions handles the alert state in the database.

---

### Tab 2: Dynamic Pricing Recommendations (10.2)
**Purpose:** AI-suggested markdown strategies for aging stock and reaction to supplier price increases.
**Data Dependencies:** `inventory_items` (cost/sell prices, shelf life, slow-mover threshold), recent `invoices` for cost increases.
**Placeholder Layout:**
- **Two Sub-Sections / Sections:** 
  - **Section A: Supplier Price Change Alerts:**
    - Title: "PRICE ALERT: [Product Group / Supplier]"
    - Change context: `Supplier increased: R62/kg → R68/kg (+9.7%)`
    - Affected items list with old/new margins: `Mince: R85/kg — Margin now 20% (was 27%)`
    - Recommended action list (targeting 30% margin).
    - Buttons: `[ACCEPT ALL]`, `[ADJUST INDIVIDUALLY]`, `[IGNORE]`
  - **Section B: Slow-Moving / Markdown Alerts:**
    - Title: "MARKDOWN SUGGESTION"
    - Item details: Product, Stock Qty, Sales velocity (e.g. "only 0.5 kg sold in 3 days").
    - Expiration context: `Sell-by date: 09 Feb 2026 (3 days remaining)`
    - Suggestion block: `% markdown (Old → New) to move stock`
    - Buttons: `[APPLY]`, `[DIFFERENT %]`, `[IGNORE]`

---

### Tab 3: Predictive Reorder Recommendations (10.3)
**Purpose:** Warn owners about inventory depletion based on sales velocity and supplier lead times.
**Data Dependencies:** `reorder_recommendations` table, current `inventory_items` stock levels.
**Placeholder Layout:**
- **List View:** Table or cards displaying recommendations.
- **Row Elements:**
  - Status indicator (🔴 Urgent, 🟡 Warning, ✅ OK).
  - Product Name.
  - Calculated remaining time: e.g. `2.3 days of stock left`
  - Actionable prompt: e.g. `→ Order NOW (3-day lead time)`
- **Global Action Button:** `[CREATE PURCHASE ORDER]` floating or top action button.

---

### Tab 4: Event & Holiday Sales Intelligence (10.4)
**Purpose:** Track abnormal sales spikes, tag them with events, and forecast future stock needs.
**Data Dependencies:** `event_tags`, `event_sales_history` tables.
**Placeholder Layout:**
- **Top Section - Recent Spikes (Tagging):**
  - Prompt: "Unusual sales volume detected for [Date]. Was this a specific event or holiday?"
  - Dropdown: Public Holiday / Local Event / Easter / etc.
  - Text Input: "Describe event"
  - Button: `[TAG & SAVE]`
- **Bottom Section - Forecasting Form:**
  - Title: "Pre-Event Forecast Report"
  - Prompt: "Are you preparing for [Event Type Dropdown]?"
  - Metric Summary View: Sales data from last X occurrences (Volume/Value, Top Products, Leftovers, Shortages).
  - Recommendation List: Estimated product needs for upcoming event.
  - Action Button: `[SAVE AS ORDER PLAN]`

---
---

## Module 2: Reporting & Exports

**Blueprint Reference:** Section 11 (`Lines 2206 - 2305`)
**Target File:** `admin_app/lib/features/reports/screens/report_hub_screen.dart`

### Overall Screen Scaffolding
- **App Bar / Header:** Title "Report Hub". Since there are 23 reports, a single list or grid structure with filtering makes more sense than 23 tabs.
- **Layout Structure:**
  - **Left Sidebar / Filter Panel:** Categories for reports (Financial, Inventory, Staff, Operations, Compliance).
  - **Main Content Area:** Grid view of Report Cards.
  - **Top Action Bar:** Quick setup for Auto-Report Schedules.

### Main Content: Report Grid
**Placeholder Layout per Report Card:**
- **Icon:** Representing the report type (e.g., Timeline for Sales, People for Staff).
- **Title:** e.g., "Daily Sales Summary"
- **Subtitle/Frequency:** e.g., "Daily / On Demand"
- **Action Buttons:** 
  - `[VIEW]` (Opens an embedded visual table/chart view in a modal or split view).
  - `[EXPORT PIP]` (Dropdown for PDF, Excel, CSV formats).

### Specifically Required Reports (from Table 11.1)
Must scaffold UI entries for:
1. Daily Sales Summary
2. Weekly Sales Report
3. Monthly P&L
4. VAT201 Report
5. Cash Flow
6. Staff Hours Report
7. Payroll Report
8. Inventory Valuation
9. Shrinkage Report
10. Supplier Spend Report
11. Purchases by Supplier
12. Expense Report by Category
13. Product Performance
14. Customer (Loyalty) Report
15. Hunter Jobs Report
16. Audit Trail Report
17. BCEA Compliance Report
18. Blockman Performance Report
19. Event / Holiday Forecast Report
20. Sponsorship & Donations Log
21. Staff Loan & Credit Report
22. AWOL / Absconding Report
23. Equipment Depreciation Schedule
24. Purchase Sale Agreement History

### Automated Reporting Configuration Pane (11.3)
**Access:** A button on the Report Hub header `[SCHEDULE CONFIGURATION]`.
**Placeholder Layout (Modal/Drawer):**
- List of automated rules.
- Rule row format:
  - `Time/Trigger`: (e.g. "Daily at 23:00")
  - `Report Type Selection`: Dropdown.
  - `Delivery Method`: Checkboxes for Dashboard, Email, Google Drive.
  - `Recipient`: Text field or Staff Dropdown.
- Button: `[ADD NEW SCHEDULE]`
