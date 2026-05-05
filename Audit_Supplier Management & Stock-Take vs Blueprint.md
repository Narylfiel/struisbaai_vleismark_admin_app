# Audit: Supplier Management & Stock-Take vs Blueprint

**Blueprint:** `AdminAppBluePrintTruth.md` (single source of truth)  
**Scope:** Supplier management UI, supplier linkage to products, stock-take sessions (multi-device), stock-take adjustments, `stock_locations` usage.

---

## 1. What exists (with file references)

| Item | Evidence |
|------|----------|
| **Suppliers table usage (read-only)** | Carcass intake loads suppliers for dropdown: `carcass_intake_screen.dart` — `_loadSuppliers()` reads `.from('suppliers')` (lines 1203–1211); list/detail views use `intake['suppliers']?['name']` (lines 441, 691). |
| **Supplier name on carcass intakes** | DB: `carcass_intakes.supplier_name TEXT NOT NULL` in `001_admin_app_tables_part1.sql` (line 84). |
| **Supplier name on invoices** | DB: `invoices.supplier_name TEXT` in `002_admin_app_tables_part2.sql` (line 110). |
| **Report entry for Supplier Spend** | `report_hub_screen.dart` line 29 — report type "Supplier Spend Report" (Monthly). |
| **Report repo for supplier spend** | `report_repository.dart` lines 77–81 — `getSupplierSpend()` calls RPC `calculate_supplier_spend`. |
| **“Trigger Stock Take” as alert action** | `shrinkage_screen.dart` line 165 — button calls `_handleAction(alertId, 'StockTakeTriggered')`; `_handleAction` only calls `AnalyticsRepository.updateShrinkageStatus(alertId, action)` (lines 97–99). So it only updates shrinkage alert status, not a stock-take session. |
| **stock_locations table** | `001_admin_app_tables_part1.sql` lines 28–34 — table with `id`, `name`, `description`, `is_active`, `created_at`. |
| **stock_movements location FKs** | `001_admin_app_tables_part1.sql` lines 118–119 — `location_from`, `location_to` reference `stock_locations(id)`. |
| **Inventory nav tabs** | `inventory_navigation_screen.dart` — 4 tabs: Categories, Products, Modifiers, Stock Levels (lines 51–56, 94–106). No Suppliers or Stock-Take tabs. |
| **Stock Levels tab** | Placeholder only: `_StockLevelsPlaceholderScreen` shows “Stock level management coming soon” (lines 189–235). |
| **Product form** | Not implemented — `_navigateToProductForm()` shows SnackBar “Product form coming soon” (lines 126–130). |

So: **supplier data is only consumed (carcass intake dropdown + report)**; **no Supplier Management UI**, **no product–supplier link**, **no real stock-take flow**, and **no UI using `stock_locations`**.

---

## 2. What is missing (explicitly from blueprint)

**Supplier management (Blueprint §4.6)**  
- **Sidebar → 🥩 Inventory → Suppliers** — missing.  
- **Supplier CRUD screen** — no `supplier_screen.dart`; blueprint §16 expects `supplier_screen.dart` under `inventory/screens/`.  
- **Supplier form fields:** Name, Contact Person, Phone, Email, Address, Payment Terms, BBBEE Level, Active — none in app.  
- **Supplier Scorecard:** Deliveries, On Time %, Weight Variance, Invoice Accuracy, Quality Issues — none in app.  

**Supplier linkage to products (Blueprint §4.2 Section A)**  
- **Product form “Supplier Link”** — “Multi-select dropdown — Which suppliers deliver this item” — missing (product form itself is “coming soon”).  

**Stock-take (Blueprint §4.7)**  
- **Sidebar → 🥩 Inventory → Stock-Take** — no tab or route.  
- **stock_take_screen.dart** — not present; blueprint §16 lists `stock_take_screen.dart` (multi-device).  
- **Start Stock-Take** — no session creation.  
- **Multi-device sessions** — “All active devices see the open session” — not implemented.  
- **Location selection** — “Each counter selects their physical location (Display Fridge 1, Walk-In, Deep Freezer 4, etc.)” — not implemented.  
- **Count entry** — “Enter actual quantities — system shows expected vs actual with variance” — no UI.  
- **Live progress** — “38 of 120 items counted (3 devices active)” — not implemented.  
- **Conflict handling** — “Conflicts (same item, same location, different counters) flagged” — not implemented.  
- **Manager/Owner approval** — “Reviews consolidated totals before approving” — not implemented.  
- **On approval:** “stock adjusted to physical counts; all variances logged to stock_movements + audit_logs” — not implemented.  
- **Shrinkage trigger** — “Triggers shrinkage analysis after approval” — no stock-take flow to trigger it.  

**Stock-take adjustment (Blueprint §4.5)**  
- **Stock-Take Adjustment** — “Admin → Inventory — Corrects stock to actual count; logs variance” — no dedicated adjustment flow from a stock-take.  

**stock_locations usage (Blueprint §4.2 Section C, §4.5, §4.7, §15)**  
- **Product form “Storage Location(s)”** — “Multi-select — Display Fridge 1/2/3, Walk-In, Deep Freezer 1–7, etc.” — missing (no product form).  
- **Transfer Between Locations** — “Admin → Inventory — Moves stock between physical locations” — no UI.  
- **Stock-take per location** — counts by location — not implemented.  
- **Any app code using `stock_locations`** — no references in `admin_app/lib`.  

**Database**  
- **suppliers table** — not defined in `admin_app/supabase/migrations` (carcass intake uses `.from('suppliers')`, so it is assumed to exist elsewhere or is missing).  

So: **Supplier management UI, supplier–product link, full stock-take flow, stock-take adjustments, and any use of `stock_locations` in the app are missing.**

---

## 3. What is incorrect (deviations)

| Deviation | Blueprint expectation | Current implementation |
|-----------|------------------------|-------------------------|
| **“Trigger Stock Take”** | Should start or lead into a stock-take session (multi-device count, then adjustments). | Only updates `shrinkage_alerts.status` to `'StockTakeTriggered'`. No session, no count UI, no stock adjustment. |
| **Inventory nav** | §3.1 / §4: Inventory should include Categories, Products, Modifiers, **Stock Levels**, **Suppliers**, **Stock-Take**. §16: `stock_levels_screen.dart`, `stock_take_screen.dart`, `supplier_screen.dart`. | Only 4 tabs; no Suppliers, no Stock-Take. Stock Levels is a placeholder. No supplier or stock-take screens. |
| **Carcass intake and suppliers** | §5.2: “Supplier — Dropdown (from suppliers)”. Expects a proper suppliers entity and Supplier Management to maintain it. | App reads `suppliers` for dropdown but there is no UI to manage suppliers; `suppliers` is not created in app migrations. So either the table lives elsewhere or is missing — in both cases the blueprint’s “Supplier management” is not fulfilled. |

---

## 4. System impact (what breaks or is missing)

- **Inventory cannot be verified in real life**  
  - No stock-take sessions, no multi-device counting, no location-based counts, no approval, no adjustment of system stock to actual counts.  
  - Shrinkage logic assumes “Actual Stock = Last stock-take count (or system running total)” (§10.1); with no stock-take, “actual” is never updated from physical counts, so shrinkage detection has no real baseline.

- **Stock control impact**  
  - Reorder and stock levels are based only on system totals; no way to correct for counting errors or theft except outside the app.  
  - No location-level view or transfers, so display vs freezer vs walk-in cannot be managed.  
  - “Trigger Stock Take” does not start a stock-take; it only marks an alert, so the intended workflow (alert → conduct stock-take → adjust → shrinkage) is broken.

- **Supplier and product impact**  
  - Suppliers cannot be maintained in the admin app (no CRUD).  
  - Products cannot be linked to suppliers (no product form, no Supplier Link field).  
  - Supplier scorecard and payment terms/BBBEE are not available.  
  - Carcass intake and reports depend on a `suppliers` table that is not created in app migrations — risk of missing table or inconsistent data.

- **Reporting and analytics**  
  - Supplier Spend Report is listed and has a repo method but depends on supplier and invoice data; without Supplier Management, data quality and completeness are unclear.  
  - Shrinkage and reorder logic cannot use location or stock-take data because those flows are absent.

---

## 5. Completion % for this module

| Sub-module | Completion % | Notes |
|------------|--------------|--------|
| **Supplier management UI** | **0%** | No screen, no CRUD, no scorecard; only consumption of `suppliers` in carcass intake (and possibly elsewhere). |
| **Supplier linkage to products** | **0%** | No product form, no Supplier Link field. |
| **Stock-take sessions (multi-device)** | **0%** | No screen, no session, no count UI, no multi-device, no location selection. |
| **Stock-take adjustments** | **0%** | No approval flow, no write to `stock_movements`/audit from a stock-take. |
| **stock_locations usage** | **0%** | Table and FKs exist; no UI or app logic uses them. |
| **Supporting pieces** | **~15%** | Carcass intake supplier dropdown, Supplier Spend report entry + repo, “Trigger Stock Take” as alert status only; DB has `stock_locations` and movement FKs. |

**Overall completion for “Supplier management + Stock-take systems” (vs blueprint): ~5%.**

Only minor supporting pieces exist (supplier dropdown, report stub, alert action, DB schema for locations). All core blueprint features for supplier management, supplier–product link, stock-take sessions, stock-take adjustments, and use of `stock_locations` are missing or incorrect (e.g. “Trigger Stock Take” not starting a real stock-take). Inventory cannot be physically verified or adjusted through the app as specified in the blueprint.