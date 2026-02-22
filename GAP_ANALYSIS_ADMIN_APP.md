# GAP ANALYSIS — Admin & Back-Office App vs Blueprint

**Blueprint:** `AdminAppBluePrintTruth.md` (Single Source of Truth)  
**Codebase:** `admin_app/` Flutter project  
**Date:** 21 February 2026  
**Scope:** Read-only audit — no code changes.

---

## 1. FEATURE COMPLETENESS

### 1.1 Authentication (Blueprint §2)

| Feature | Status | File / Notes |
|--------|--------|---------------|
| PIN Login (same as POS) | ✅ Fully Implemented | `lib/features/auth/screens/pin_screen.dart` — 4-digit PIN, SHA256 hash |
| Role routing: Owner/Manager only | ✅ Fully Implemented | `pin_screen.dart` — `AdminConfig.allowedRoles` ['owner','manager'] |
| Cashier/Blockman rejected | ✅ Fully Implemented | Same file — "Access restricted to Admin staff." |
| Offline PIN cache (JSON file) | ✅ Fully Implemented | `pin_screen.dart` — `_StaffCache` using path_provider |
| Staff table: staff_profiles | ✅ Used | Queries `staff_profiles` (id, full_name, role, pin_hash, is_active) |

### 1.2 Main Dashboard (Blueprint §3)

| Feature | Status | File / Notes |
|--------|--------|---------------|
| Today's Sales | ⚠️ Partially | `dashboard_screen.dart` — reads **`sales`** table; blueprint expects **`transactions`** |
| Transaction Count | ⚠️ Partially | Same — from `sales`; blueprint: transactions (today) |
| Average Basket | ⚠️ Partially | Same data source |
| Gross Margin | ⚠️ Partially | Same — uses cost_amount from sales |
| Alerts (shrinkage, reorder, overdue, leave) | ✅ Implemented | Queries shrinkage_alerts, reorder_recommendations, business_accounts, leave_requests |
| Sales Chart (7-day) | ❌ Not Implemented | No chart widget on dashboard |
| Staff Clock-In Status | ✅ Implemented | timecards + staff_profiles |
| Top Products (today) | ❌ Not Implemented | Not on dashboard |
| Real-time refresh (Supabase subscription) | ❌ Not Implemented | One-shot load only |
| Owner vs Manager limited financials | ⚠️ Partially | MainShell hides Bookkeeping/Settings for non-owner; dashboard same for both |

### 1.3 Inventory (Blueprint §4)

| Feature | Status | File / Notes |
|--------|--------|---------------|
| Categories list + CRUD | ✅ Fully Implemented | `category_list_screen.dart`, `category_form_screen.dart`, `category_bloc.dart`, `category.dart` |
| Category colour codes | ✅ Implemented | `CategoryColors` in `category.dart`; `app_colors.dart` catBeef, catPork, etc. |
| Products list + search/filter | ✅ Implemented | `product_list_screen.dart` — inventory_items, categories |
| Product Add/Edit (full form) | ⚠️ Partially | Inline `_ProductFormDialog` in product_list_screen.dart — Sections A–D only |
| **Section A Identity** | ⚠️ Partially | PLU, Name, POS Display Name, Scale Label, Category, Item Type, Text Lookup; **missing:** Sub-Category, Supplier Link, SKU/Barcode (in Tab A), Barcode Prefix dropdown |
| **Section B Pricing** | ⚠️ Partially | Sell/Cost, Target Margin, Freezer Markdown %, VAT Group, GP%/Markup/Recommended; **missing:** Average Cost (read-only), Price Last Changed, Price History button |
| **Section C Stock** | ⚠️ Partially | Stock Control Type, Unit, Allow Fraction, Reorder, Shelf Life Fresh/Frozen, Slow-Moving Days; **missing:** Pack Size, Stock on Hand Fresh/Frozen/Total (read-only), Storage Location(s), Carcass Link, Dryer/Biltong Product |
| **Section D Barcode & Scale** | ⚠️ Partially | Barcode, Ishida Sync; **missing:** Barcode Prefix dropdown (20/21/None), Auto-generate barcode |
| **Section E Modifier Groups** | ❌ Not Implemented | No "Add Modifier Group" / link to modifier_groups |
| **Section F Production Links** | ❌ Not Implemented | No Recipe Link, Dryer/Biltong Batch Link, Manufactured Item |
| **Section G Media & Notes** | ❌ Not Implemented | No Image, Dietary Tags, Allergen Info, Internal Notes |
| **Section H Item Activity Log** | ❌ Not Implemented | No "View Item Activity" / price history / audit for PLU |
| Modifier Groups screen | ❌ Not Implemented | Placeholder only — `_ModifiersPlaceholderScreen` in inventory_navigation_screen.dart |
| Stock Levels (all locations) | ❌ Not Implemented | Placeholder — `_StockLevelsPlaceholderScreen` |
| Stock Movement Log (per product) | ❌ Not Implemented | No movement history tab/view |
| Stock lifecycle actions | ❌ Not Implemented | No Move to Freezer, Markdown, Waste, Staff Meal, Donation, Sponsorship, Stock-Take Adjustment, Transfer Between Locations |
| Supplier Management | ❌ Not Implemented | No Suppliers tab or screen under Inventory |
| Stock-Take (multi-device) | ❌ Not Implemented | No stock-take screen or session flow |
| Mobile Quick-Add (owner phone) | ❌ Not Implemented | N/A desktop app |

### 1.4 Production (Blueprint §5)

| Feature | Status | File / Notes |
|--------|--------|---------------|
| Yield Templates list + form | ✅ Implemented | `carcass_intake_screen.dart` — _YieldTemplatesTab, _TemplateFormDialog; yield_templates table |
| Carcass Intake (delivery + weighing) | ✅ Implemented | _CarcassIntakeTab — supplier, invoice, weight, variance check |
| Pending Breakdowns list | ✅ Implemented | _PendingBreakdownsTab — status received/in_progress, remaining_weight |
| Start Breakdown / Partial support | ✅ Implemented | _BreakdownDialog; remaining on hook; partial breakdown mentioned in UI |
| Carcass breakdown cut entry (actual vs expected) | ✅ Implemented | In-file breakdown dialog with template cuts |
| Blockman performance rating | ⚠️ Unclear | Logic may exist in breakdown flow; no dedicated stars/rating UI per blueprint |
| Recipes list + form | ❌ Not Implemented | No recipe_screen or recipes tab |
| Production Batches | ❌ Not Implemented | No production_batch_screen or batch workflow |
| Dryer / Biltong & Droewors | ❌ Not Implemented | No dryer_batch_screen or dryer module |

**Detailed audit:** See **AUDIT_PRODUCTION_SYSTEM.md** for full production audit (yield templates, intake, breakdown, recipes, batches, dryer; stock_movements/inventory update on breakdown; completion %).

### 1.5 Hunter (Blueprint §6)

| Feature | Status | File / Notes |
|--------|--------|---------------|
| Active / Completed Jobs tabs | ✅ Implemented | `job_list_screen.dart` — hunter_jobs |
| Services Config tab | ✅ Implemented | _ServicesTab — hunter_services |
| New Job (intake) | ⚠️ Partially | Create job flow may be in dialog/same file; needs verification |
| Job workflow (Process 1–N, materials, output) | ⚠️ Unclear | job_list_screen has tabs; full sequential process UI not verified |
| Job Summary & Invoice | ⚠️ Unclear | May be inline |
| WhatsApp on job ready | ❌ Not Implemented | whatsapp_service exists but integration with hunter job not verified |

### 1.6 HR & Staff (Blueprint §7)

| Feature | Status | File / Notes |
|--------|--------|---------------|
| Staff Profiles tab | ✅ Implemented | `staff_list_screen.dart` — staff_profiles (full_name, role, phone, email, employment_type, hourly_rate, monthly_salary, pay_frequency, hire_date, max_discount_pct) |
| Timecards tab | ✅ Implemented | _TimecardsTab — timecards |
| Leave tab | ✅ Implemented | _LeaveTab — leave_requests / balances |
| Payroll tab | ✅ Implemented | _PayrollTab |
| Break detail (Brk 1 Out/In, etc.) | ⚠️ Unverified | Blueprint requires per-break detail; code may show summary only |
| AWOL / Absconding records | ❌ Not Implemented | No awol_screen, no account_awol_records UI |
| Staff Loans / Advances / Meat on Credit | ❌ Not Implemented | No staff_credit_screen or staff_credit ledger UI |
| BCEA Compliance dashboard | ⚠️ Partially | Text "SA BCEA Compliance" at line 1778 staff_list_screen; no dedicated compliance_screen |
| Employee Documents tab | ⚠️ Unverified | Not clearly present in staff list |
| Per-staff payroll frequency | ✅ In config | admin_config; staff has pay_frequency |

### 1.7 Business Accounts (Blueprint §8)

| Feature | Status | File / Notes |
|--------|--------|---------------|
| Business Accounts list | ✅ Implemented | `account_list_screen.dart` — business_accounts |
| Account fields (VAT, WhatsApp, Email) | ⚠️ Schema-dependent | UI may not show all blueprint fields (cell/WhatsApp, email, VAT number) |
| Account Dashboard (balance, limit, status) | ✅ Implemented | _BusinessAccountsTab |
| Overdue Management tab | ✅ Implemented | _OverdueTab |
| Payment Recording | ⚠️ Unverified | Likely in account flow |
| Statement Generation (PDF/WhatsApp) | ⚠️ Unverified | _AccountStatementsTab exists |
| Auto-Suspend = Off by default | ✅ In config | admin_config overdueYellowDays/overdueRedDays; blueprint says owner enables per account |

### 1.8 Bookkeeping & Financial (Blueprint §9)

| Feature | Status | File / Notes |
|--------|--------|---------------|
| Invoices list | ✅ Implemented | `invoice_list_screen.dart` — invoices table |
| Add Invoice Manually | ❌ Not Implemented | Placeholder dialog only ("Form to manually add...") |
| OCR Flow (Google Drive + Cloud Vision) | ❌ Not Implemented | ocr_service exists; no UI/webhook flow for invoice OCR |
| Bulk CSV Import / Export | ⚠️ Partially | "Bulk Import CSV" button present; no implementation (onPressed: () {}) |
| Chart of Accounts tab | ✅ Implemented | _ChartOfAccountsTab — chart_of_accounts |
| Chart editable (add/rename, no delete if has txns) | ⚠️ Unverified | Blueprint: fully editable; implementation not verified |
| P&L Statement | ⚠️ Partially | _ReportsTab — **hardcoded sample data**, not auto-generated from ledger |
| VAT Report | ⚠️ Partially | Same — hardcoded VAT201-style values |
| Cash Flow view | ❌ Not Implemented | No cash flow screen/tab with real data |
| Ledger entries (auto on sale, payment, etc.) | ❌ Unverified | No ledger_screen; ledger_entries usage not confirmed |
| PTY Conversion / Equipment tab | ✅ Implemented | _PtyConversionTab — equipment list; equipment_register |
| Purchase Sale Agreement tracker | ⚠️ Unverified | May be in same tab |

### 1.9 Analytics (Blueprint §10)

| Feature | Status | File / Notes |
|--------|--------|---------------|
| Shrinkage Alerts tab | ✅ Implemented | `shrinkage_screen.dart` — AnalyticsRepository.getShrinkageAlerts |
| Dynamic Pricing tab | ✅ Implemented | _PricingTab (placeholder or simple UI) |
| Predictive Reorder tab | ✅ Implemented | _ReorderTab |
| Event Forecasting tab | ✅ Implemented | _EventTab |
| Mass-balance nightly run | ❌ Backend | Not visible in app; assumed backend/cron |
| Supplier price change trigger (recommendations) | ⚠️ Unverified | _PricingTab content |
| Slow-mover per product | ✅ In product form | slow_moving_trigger_days in product dialog |
| Event tagging (spike detection) | ⚠️ Unverified | _EventTab implementation |

### 1.10 Reports (Blueprint §11)

| Feature | Status | File / Notes |
|--------|--------|---------------|
| Report Hub / list of report types | ✅ Implemented | `report_hub_screen.dart` — list of 19 report titles + categories |
| Export (CSV) for some reports | ⚠️ Partially | getInventoryValuation, getShrinkageReport, getStaffHours, getAuditTrail → CSV preview in dialog |
| PDF / Excel export | ⚠️ Unverified | report_service / export_service exist; UI shows CSV only |
| Auto-report schedule (daily 23:00, etc.) | ❌ Not Implemented | No scheduler in app |
| All report types actionable | ❌ No | Only 4 report types wired to repo; rest "Export configuration pending" |

### 1.11 Customers (Blueprint §12)

| Feature | Status | File / Notes |
|--------|--------|---------------|
| Customer list (from loyalty) | ✅ Implemented | `customer_list_screen.dart` — CustomerRepository |
| Announcements tab | ✅ Implemented | _AnnouncementsTab |
| Recipe Library tab | ✅ Implemented | _RecipesTab |
| Customer fields (email, cell, birthday, address) | ⚠️ Schema-dependent | Blueprint §12.1 extended fields |

### 1.12 Settings (Blueprint §13)

| Feature | Status | File / Notes |
|--------|--------|---------------|
| Business Info tab | ✅ Implemented | `business_settings_screen.dart` — SettingsRepository.getBusinessSettings |
| Scale / Ishida tab | ✅ Implemented | _ScaleTab |
| Tax Rates tab | ✅ Implemented | _TaxTab |
| Notification Settings tab | ✅ Implemented | _NotificationTab |
| Default Markdown % per product (not system default) | ✅ In product form | freezer_markdown_pct per product |
| Slow-Mover per product | ✅ In product form | slow_moving_trigger_days |

### 1.13 Audit Log (Blueprint §14)

| Feature | Status | File / Notes |
|--------|--------|---------------|
| Audit log viewer | ✅ Implemented | `audit_log_screen.dart` — AuditRepository |
| Filters (date, action type, staff) | ✅ Implemented | date range, _selectedAction, staffController |
| Immutable logs (RLS) | ❌ Backend | Not verifiable in app code |

---

## 2. LOGIC COMPARISON

### 2.1 Data Source Mismatches

| Expected (Blueprint) | Actual | Risk |
|----------------------|--------|------|
| Dashboard: `transactions` (today) | `sales` table | **Critical** — POS may write to `transactions`; dashboard will show no data or wrong schema |
| POS writes transactions → Admin reads | Dashboard reads `sales` | Integration broken if POS uses different table name |
| Till sessions / Z-reports from POS | Not used on dashboard | No Z-report or till view in dashboard |

### 2.2 Missing Workflows

- **Stock lifecycle:** No Move to Freezer (with per-product markdown %), Waste (reason, staff, photo), Donation, Sponsorship, Transfer Between Locations, Stock-Take approval flow.
- **Invoice:** No OCR → Pending Review → Approve → ledger; manual add is placeholder; bulk CSV not implemented.
- **P&L / VAT / Cash Flow:** Not generated from ledger_entries; P&L/VAT tabs use hardcoded numbers.
- **Payroll:** Per-frequency (weekly/monthly) and deductions (UIF, PAYE, staff loans) — logic not verified end-to-end.
- **Hunter job:** Full sequential process (Cut & Pack → Make Droewors → Vacuum Seal) with materials and output weights — not fully verified.
- **Dryer/Biltong:** No workflow at all.
- **Yield template update:** Blueprint Phase 2–5 (actuals → suggested template update); only template CRUD present.
- **Blockman performance:** Stars and cut-by-cut rating — not clearly exposed in UI.

### 2.3 Simplifications / Deviations

- **Product form:** Single dialog with 4 tabs (A–D); no separate full-screen product_form_screen; Sections E–H missing.
- **Bookkeeping P&L/VAT:** Static placeholder data instead of period selector + ledger aggregation.
- **Reports:** Many report types listed but only four connected to data; export opens dialog with CSV text instead of file save.
- **Inventory:** No Suppliers, Stock-Take, or stock movement history; Modifiers and Stock Levels are placeholders.

### 2.4 Critical Logic Gaps (POS, Stock, Accounts)

- **POS ↔ Admin:** Dashboard assumes `sales` table; blueprint says POS writes `transactions` and `transaction_items`. If schema uses `transactions`, today’s sales and margin will fail or be zero.
- **Stock:** No stock_movements UI; no lifecycle actions; reorder/shrinkage depend on backend/DB being correct.
- **Accounts:** Overdue logic exists; auto-suspend off by default aligns with blueprint; payment recording and statement generation need verification.

---

## 3. ARCHITECTURE ALIGNMENT

### 3.1 Blueprint §16 — Expected Folder Structure

| Blueprint Path | Exists? | Actual |
|----------------|---------|--------|
| core/services/supabase_service.dart | ✅ | Yes |
| core/services/auth_service.dart | ✅ | Yes (PIN logic in pin_screen; auth_service exists) |
| core/services/report_service, ocr_service, whatsapp_service, export_service | ✅ | All present |
| core/models/base_model.dart | ✅ | Yes |
| core/models/inventory_item, carcass_intake, yield_template, production_batch, dryer_batch, hunter_job, staff_profile, payroll_entry, staff_credit, awol_record, business_account, invoice, ledger_entry, equipment_asset, purchase_sale_agreement, event_tag, shrinkage_alert | ❌ | **Only base_model + category (under features/inventory/models)** |
| core/utils/currency_formatter, date_formatter, pdf_generator, excel_generator | ❌ | Only app_constants.dart |
| features/inventory/... product_form_screen, modifier_screen, stock_levels_screen, stock_take_screen, supplier_screen | ❌ | product_form = inline dialog; modifier/stock_levels = placeholders; no supplier, stock_take screens |
| features/production/... recipe_screen, production_batch_screen, dryer_batch_screen, carcass_breakdown_screen | ❌ | Only carcass_intake_screen (yield + intake + breakdown as tabs); no recipe, batch, dryer screens |
| features/hunter/... job_intake_screen, job_process_screen, job_summary_screen | ⚠️ | job_list_screen only; intake/process/summary may be inline |
| features/hr/... staff_form_screen, timecard_screen, leave_screen, awol_screen, payroll_screen, staff_credit_screen, compliance_screen | ⚠️ | staff_list_screen with tabs; no awol_screen, staff_credit_screen, compliance_screen |
| features/accounts/... account_detail_screen, statement_screen | ⚠️ | account_list_screen with tabs only |
| features/bookkeeping/... invoice_form_screen, ledger_screen, chart_of_accounts_screen, pl_screen, vat_report_screen, cash_flow_screen, equipment_register_screen, pty_conversion_screen | ⚠️ | invoice_list_screen: Invoices (placeholder form), Chart of Accounts, P&L/Reports (static), PTY Conversion; no standalone ledger, pl, vat, cash_flow, equipment screens |
| features/analytics/... pricing_screen, reorder_screen, event_forecast_screen | ⚠️ | All as tabs in shrinkage_screen |
| features/reports/report_hub_screen | ✅ | Yes |
| features/customers/... announcement_screen, recipe_library_screen | ⚠️ | Tabs in customer_list_screen |
| features/settings/... scale_settings_screen, tax_settings_screen, notification_settings_screen | ⚠️ | Tabs in business_settings_screen |
| shared/widgets/sidebar_nav, data_table, chart_widgets, form_widgets | ✅ | sidebar_nav, data_table, chart_widgets, form_widgets, action_buttons, filter_bar, search_bar |

### 3.2 State Management

- **Blueprint:** flutter_bloc.
- **Actual:** Bloc used for Categories (CategoryBloc); rest of app is setState in StatefulWidgets. No app-wide BLoC for auth or dashboard.

### 3.3 Data Flow

- **Actual:** Screens call Supabase.client directly (e.g. dashboard_screen, product_list_screen) or feature-level repositories (ReportRepository, AuditRepository, AnalyticsRepository, SettingsRepository, CustomerRepository). No unified repository layer for all domains.
- **Blueprint:** Implies services + repositories; mix of direct Supabase and repos.

### 3.4 Supabase Initialization (User Rule)

- **Rule:** "Supabase is initialized ONCE — only inside SupabaseService.initialize(). Never in main.dart."
- **Actual:** `main.dart` calls `Supabase.initialize(...)` directly. **Violation.**

### 3.5 Supabase Project (User Rule)

- **Allowed:** https://nfhltrwjtahmcpbsjhtm.supabase.co  
- **Actual:** admin_config.dart uses `nasfakcqzmpfcpqttmti.supabase.co`. **Different project.**

---

## 4. DATABASE & DATA MODELS

### 4.1 Tables Admin Writes (Blueprint §15)

| Table | Referenced in App? | Notes |
|-------|--------------------|-------|
| profiles / staff_profiles | ✅ | staff_profiles in pin, dashboard, staff list |
| business_settings | ✅ | SettingsRepository |
| inventory_items | ✅ | product list, form |
| categories | ✅ | category bloc, product form |
| stock_locations | ❌ | Not used in UI |
| modifier_groups / modifier_items | ❌ | Modifiers placeholder |
| yield_templates / yield_template_cuts | ✅ | carcass_intake_screen |
| carcass_intakes | ✅ | Production tabs |
| carcass_breakdown_sessions | ⚠️ | Likely in breakdown dialog |
| stock_movements | ❌ | No UI |
| recipes / recipe_ingredients | ❌ | No recipe screen |
| production_batches / production_batch_ingredients | ❌ | No batch screen |
| dryer_batches / dryer_batch_ingredients | ❌ | No dryer module |
| hunter_services | ✅ | Hunter Services tab |
| hunter_jobs | ✅ | Hunter tabs |
| hunter_job_processes / hunter_process_materials | ⚠️ | Unverified |
| business_accounts | ✅ | Accounts |
| account_awol_records | ❌ | No AWOL UI |
| staff_credit / staff_loans | ❌ | No staff credit UI |
| invoices / invoice_line_items | ✅ | Invoices tab |
| ledger_entries | ⚠️ | Not used in P&L/VAT UI |
| chart_of_accounts | ✅ | Chart of Accounts tab |
| equipment_register | ✅ | PTY Conversion tab |
| purchase_sale_agreement / purchase_sale_payments | ⚠️ | Unverified |
| sponsorships / donations | ❌ | No UI |
| leave_requests | ✅ | Dashboard, HR Leave tab |
| payroll_periods / payroll_entries | ⚠️ | Payroll tab |
| loyalty_customers | ⚠️ | Customer repo |
| announcements | ✅ | Customers tab |
| shrinkage_alerts | ✅ | Dashboard, Shrinkage screen |
| reorder_recommendations | ✅ | Dashboard, Analytics |
| event_tags / event_sales_history | ❌ | No event UI beyond tab |

### 4.2 Tables Admin Reads (POS, Clock-In, Customer)

- **transactions / transaction_items:** Not used; dashboard uses `sales`.
- **till_sessions:** Not used.
- **timecards:** Used (dashboard clock-in, reports).
- **timecard_breaks:** Not verified in HR timecard view.
- **audit_logs:** Used (audit_log_screen).

### 4.3 Dart Models vs Blueprint

- **Blueprint:** core/models/ for inventory_item, carcass_intake, yield_template, production_batch, dryer_batch, hunter_job, staff_profile, payroll_entry, staff_credit, awol_record, business_account, invoice, ledger_entry, equipment_asset, purchase_sale_agreement, event_tag, shrinkage_alert.
- **Actual:** core/models/ has only base_model.dart. features/inventory/models/ has category.dart. Rest of app uses `Map<String, dynamic>` from Supabase.

---

## 5. UI / UX COVERAGE

### 5.1 Missing Screens / Flows

- Standalone **Product Form** (full Sections A–H); **Modifiers** (real); **Stock Levels**; **Suppliers**; **Stock-Take**.
- **Recipe**, **Production Batch**, **Dryer Batch** screens.
- **AWOL**, **Staff Credit**, **Compliance** (dedicated screens or full tabs).
- **Account Detail** (drill-down), **Statement** (PDF/WhatsApp) as dedicated flows.
- **Invoice Form** (manual entry), **Ledger** view, **P&L** (period + generate), **VAT** (generate), **Cash Flow** (generate).
- **Equipment Register** (full CRUD), **Purchase Sale Agreement** (full tracker).
- **Sales Chart** and **Top Products** on dashboard.
- **Mobile Quick-Add** (N/A for desktop).

### 5.2 Incomplete Flows

- Product: no modifier linking, production links, media, activity log.
- Invoice: manual add placeholder; bulk CSV button does nothing.
- P&L/VAT: static data; no date range or "Generate from ledger".
- Reports: only 4 report types return data; others show "Export configuration pending".
- Hunter: job creation and multi-step process need verification.

### 5.3 Navigation

- **Sidebar:** Dashboard, Inventory, Production (Carcass Intake), Hunter, HR, Accounts, Bookkeeping (owner), Analytics, Reports, Customers, Audit, Settings (owner). Matches blueprint high-level; deep links to sub-screens (e.g. Stock-Take, Supplier) missing because those screens don’t exist.

---

## 6. INTEGRATION & SYSTEM FLOW

### 6.1 POS ↔ Admin

- **Admin → POS:** Products, prices, categories written to Supabase; POS expected to read (e.g. via sync). Product/category writes exist; modifier writes missing (no modifier UI).
- **POS → Admin:** Dashboard expects `sales`; blueprint says `transactions`. **Broken** if POS uses `transactions`. No till_sessions or parked_sales in UI.
- **Verdict:** Integration assumption (table name, schema) not aligned with blueprint; will break if POS follows blueprint.

### 6.2 Inventory ↔ Production

- Carcass intake and breakdown update stock (assumed in backend); no stock_movements or stock levels UI to confirm. Recipe/batch and dryer not implemented, so no production → inventory flow for those.

### 6.3 Inventory ↔ Accounts

- No direct link in UI (e.g. donation/sponsorship posting to 6500/6510); those actions missing.

### 6.4 Loyalty / Customers

- Customer list and announcements/recipe tabs present; repository talks to loyalty/customers data. Integration level acceptable for current scope.

### 6.5 Isar (Offline Production)

- **Blueprint:** Isar for production workflows that need offline.
- **Actual:** Isar in pubspec; **no usage** in lib. No offline production path.

---

## 7. RISK ASSESSMENT

### 7.1 Critical (Will Break or Block Production)

1. **Dashboard data source:** Use of `sales` instead of `transactions` — no or wrong sales/margin if POS uses `transactions`.
2. **Supabase init in main.dart:** Violates project rule; should use SupabaseService.initialize() only.
3. **Supabase URL:** Different project (nasfakcqzmpfcpqttmti) than allowed (nfhltrwjtahmcpbsjhtm) — environment/security risk.
4. **No stock lifecycle UI:** Waste, donation, sponsorship, move to freezer not recordable → shrinkage and P&L wrong.
5. **P&L/VAT not from ledger:** Financial reports are placeholders; no audit trail or correct figures for SARS.

### 7.2 High (Core Business Logic Missing)

1. **No modifier groups UI** — POS cannot show modifier pop-ups as per blueprint.
2. **No supplier management** — reorder and invoice flow incomplete.
3. **No stock-take** — inventory accuracy and shrinkage reconciliation impossible.
4. **No invoice manual/bulk** — bookkeeping cannot capture all supplier invoices.
5. **No dryer/biltong module** — full production range not supported.
6. **No AWOL / staff credit** — HR compliance and payroll deductions incomplete.
7. **No ledger-driven P&L/VAT/Cash Flow** — management and tax reporting unreliable.

### 7.3 Medium (Data Integrity / Completeness)

1. **Product form** — Missing Sections E–H (modifiers, production links, media, activity).
2. **Reports** — Most report types not wired; export to file not standard.
3. **Blockman performance** — Rating not clearly visible.
4. **Timecard break detail** — Blueprint requires per-break; not verified in UI.
5. **Chart of accounts** — Editable and “no delete if has transactions” not verified.

### 7.4 Lower

- Missing dedicated screens (e.g. separate PL, VAT, Cash Flow screens) — can be added; logic is the main gap.
- Sales chart and top products on dashboard — nice-to-have.

---

## 8. COMPLETION SCORE

### 8.1 Overall Completion

| Area | Weight | Score (0–100) | Weighted |
|------|--------|---------------|----------|
| Auth | 5% | 95 | 4.75 |
| Dashboard | 8% | 50 | 4.0 |
| Inventory | 18% | 35 | 6.3 |
| Production | 15% | 40 | 6.0 |
| Hunter | 8% | 55 | 4.4 |
| HR | 10% | 50 | 5.0 |
| Accounts | 6% | 65 | 3.9 |
| Bookkeeping | 12% | 30 | 3.6 |
| Analytics | 5% | 55 | 2.75 |
| Reports | 5% | 40 | 2.0 |
| Customers | 4% | 70 | 2.8 |
| Audit | 2% | 90 | 1.8 |
| Settings | 2% | 85 | 1.7 |
| **Total** | **100%** | — | **~49%** |

**Overall app completion: ~49%** (by weighted feature completeness vs blueprint).

### 8.2 Per-Module Completion (Rough %)

| Module | % | Notes |
|--------|---|--------|
| Auth | 95 | PIN + roles + cache; init rule broken |
| Dashboard | 50 | Wrong table; no chart/top products; alerts/clock-in ok |
| Inventory | 35 | Categories + products + partial form; no modifiers, stock levels, suppliers, stock-take, lifecycle |
| Production | 40 | Yield + intake + breakdown; no recipe, batch, dryer |
| Hunter | 55 | Jobs + services; full process flow unverified |
| HR | 50 | Staff, timecards, leave, payroll tabs; no AWOL, staff credit, full compliance |
| Accounts | 65 | List, statements, overdue; detail flows unverified |
| Bookkeeping | 30 | Invoices list + CoA + static P&L/VAT; no manual/bulk invoice, no ledger-driven reports, PTY partial |
| Analytics | 55 | Shrinkage, pricing, reorder, event tabs; backend logic unverified |
| Reports | 40 | Hub + 4 exports; rest stubbed |
| Customers | 70 | List + announcements + recipes |
| Audit | 90 | Log viewer + filters |
| Settings | 85 | Business, scale, tax, notifications |

---

## 9. SUMMARY TABLE — FEATURE VS BLUEPRINT

| Blueprint Section | Status | File(s) |
|-------------------|--------|---------|
| §2 Authentication | ✅ | pin_screen.dart, admin_config.dart |
| §3 Dashboard | ⚠️ | dashboard_screen.dart (wrong table; no chart) |
| §4 Inventory | ⚠️ | inventory_navigation_screen, category_*, product_list_screen (partial form; placeholders) |
| §5 Production | ⚠️ | carcass_intake_screen (no recipe, batch, dryer) |
| §6 Hunter | ⚠️ | job_list_screen.dart |
| §7 HR | ⚠️ | staff_list_screen.dart (no AWOL, staff credit, full compliance) |
| §8 Accounts | ✅ | account_list_screen.dart |
| §9 Bookkeeping | ⚠️ | invoice_list_screen.dart (static P&L/VAT; no ledger) |
| §10 Analytics | ⚠️ | shrinkage_screen.dart |
| §11 Reports | ⚠️ | report_hub_screen.dart |
| §12 Customers | ✅ | customer_list_screen.dart |
| §13 Settings | ✅ | business_settings_screen.dart |
| §14 Audit | ✅ | audit_log_screen.dart |
| §15–16 DB & structure | ❌ | Models missing; table usage partial; Supabase init/URL violations |

---

*End of Gap Analysis. No code was modified; findings are for planning and remediation only.*
