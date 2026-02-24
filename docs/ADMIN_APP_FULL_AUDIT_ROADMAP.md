# Flutter Admin App — Full Audit & Completion Roadmap

**Date:** 2026-02-23  
**Scope:** Struisbaai Vleismark Admin App (Windows) — butchery management  
**Type:** Architecture audit, DB/code alignment, completion roadmap

---

## SECTION 1 – Critical Failures

| # | Item | Location | Evidence |
|---|------|----------|----------|
| 1 | **business_accounts table never created in migrations** | `admin_app/supabase/migrations/` | `account_awol_records`, `account_transactions` (017), `invoices` (002) all reference `business_accounts(id)`. Migration 003 ALTERs `business_accounts` and 017 CREATEs `account_transactions` with FK to it. No `CREATE TABLE business_accounts` exists in 001, 002, or any migration. Accounts feature will fail at runtime (FK violation or missing table). |
| 2 | **audit_log table never created** | `lib/features/audit/services/audit_repository.dart` | `AuditRepository.getAuditLogs()` queries `_client.from('audit_log')`. No migration creates `audit_log`. Audit Log screen will throw or return empty. |
| 3 | **message_logs table never created** | `lib/core/services/whatsapp_service.dart` | Service inserts/selects `message_logs`. No migration creates it. WhatsApp logging will fail. |
| 4 | **OCR non-functional** | `lib/core/services/ocr_service.dart` line 14 | `final String _apiKey = ''; // TODO: Add Google Cloud Vision API key`. OCR calls will fail without key. Invoice bulk import / receipt scan affected. |
| 5 | **Dead “Bulk Import CSV” button** | `lib/features/bookkeeping/screens/invoice_list_screen.dart` line 239 | `onPressed: () {}` — no handler. Users cannot trigger bulk import. |
| 6 | **Dead “Process” button (Hunter)** | `lib/features/hunter/screens/job_list_screen.dart` line 508 | `onPressed: () {}` — no handler. Process flow not wired. |
| 7 | **completedBy not set from auth** | `lib/features/production/screens/dryer_batch_screen.dart` ~391, `production_batch_screen.dart` ~566 | `completedBy: '', // TODO: from auth` — batches saved with empty completedBy; breaks audit trail. |

---

## SECTION 2 – Incomplete Modules

| Module | Issue | Files |
|--------|-------|--------|
| **BCEA Compliance** | Weekly hours, breaks, leave, Sunday work are **placeholder only**; no real timecard/leave data. | `lib/features/hr/services/compliance_service.dart` (lines 54–78: “Placeholder: …”). Compliance screen shows static/placeholder items. |
| **Dashboard – reorder_recommendations** | Dashboard queries `reorder_recommendations` (and `inventory_items` join). **Fixed:** Migration 037 creates table; trigger in 003 inserts. Depends on `inventory_items` (POS/shared). Dashboard shows fallback when empty or missing. | `lib/features/dashboard/screens/dashboard_screen.dart` 131–134; `003_indexes_triggers_rpc.sql` 241–258. |
| **Dashboard – leave_requests / timecards** | Dashboard queries `leave_requests` and `timecards`. **No CREATE TABLE** in admin_app migrations. Depends on external “Clock-In” app or shared schema. Empty/missing tables = empty widgets or errors. | `dashboard_screen.dart` 155–160 (leave_requests), 171–177 (timecards). |
| **Staff List – Leave tab** | Documented as **placeholder** (no real leave CRUD). | AUDIT_1: “HR → Leave … Placeholder”. |
| **Hunter – Service config schema mismatch** | Code uses `service_name`, `rate`, `rate_type`; table has `name`, `base_price`, `price_per_kg`. Risk of wrong/missing fields. | AUDIT_1 I-02; `job_list_screen.dart` hunter_services usage. |
| **Analytics – Pricing / Reorder / Event Forecast** | **No dedicated screens**; only Shrinkage exists. | AUDIT_1: “Analytics → Pricing | Reorder | Event Forecast → MISSING”. |
| **Reports – Export path** | Export uses `getApplicationDocumentsDirectory()`. On Windows, file lands in Documents; user may expect Downloads. No in-app “open folder” hint. | `lib/core/services/export_service.dart`; AUDIT_1 I-02. |

---

## SECTION 3 – Database Mismatches

| Code reference | Migration status | Risk |
|----------------|------------------|------|
| **profiles** | Not created in admin_app; referenced in 001, 002, 003, 017, 019, 028, 031, 032. | Assumed from Supabase Auth or shared schema. If missing, all profile FK writes fail. |
| **staff_profiles** | Not created in admin_app migrations. | PIN screen, dashboard, HR, accounts use it. Likely view or external table. |
| **business_accounts** | **Never CREATE TABLE** in migrations. | Critical: Accounts list/detail, account_transactions, invoices depend on it. |
| **reorder_recommendations** | **Created** in migration 037; trigger in 003 inserts. | Depends on `inventory_items` (external). Dashboard shows empty on error. |
| **leave_requests** | Only **index** in 003; no CREATE TABLE. | Dashboard “Pending Leave” fails if table missing. |
| **timecards** | No CREATE TABLE in admin_app. | Dashboard “Clocked in” and HR Timecards tab depend on it. |
| **audit_log** | **Not created** in any migration. | Audit Log screen and ReportRepository (report_repository.dart line 565) use it. |
| **message_logs** | **Not created** in any migration. | WhatsAppService insert/select fails. |
| **categories** | Not in 001; 003 ALTERs it. | Assumed from POS or other app. Category list/form need it. |
| **inventory_items** | Not in 001; 007, 012, etc. ALTER. | Assumed from POS/shared. Core for stock, production, hunter. |

**Tables that ARE created in admin_app migrations (confirmed):**  
business_settings, staff_documents, stock_locations, modifier_groups/items, yield_templates, yield_template_cuts, carcass_intakes, carcass_breakdown_sessions, stock_movements, recipes, recipe_ingredients, production_batches, production_batch_ingredients, dryer_batches, dryer_batch_ingredients, hunter_services, hunter_jobs, hunter_job_processes, hunter_process_materials, account_awol_records, staff_credit, staff_loans, invoices, invoice_line_items, ledger_entries, chart_of_accounts, equipment_register, purchase_sale_agreement, purchase_sale_payments, sponsorships, donations, payroll_periods, payroll_entries, loyalty_customers, announcements, event_tags, event_sales_history, suppliers, stock_take_sessions, stock_take_entries, shrinkage_alerts, purchase_orders, purchase_order_lines, product_suppliers, compliance_records, account_transactions, production_batch_outputs, staff_awol_records, transactions, transaction_items; customer_announcements (033).

---

## SECTION 4 – Architecture Problems

| Problem | Detail |
|---------|--------|
| **No single source of truth for “base” tables** | `profiles`, `staff_profiles`, `business_accounts`, `categories`, `inventory_items`, `timecards`, `leave_requests`, `reorder_recommendations` are referenced in migrations or code but not created in this repo. Deployment assumes another app or SQL run created them. |
| **Mixed auth sources** | AuthService uses `profiles` (PIN hash); PinScreen and others use `staff_profiles`. If these are different tables, sync/consistency must be guaranteed elsewhere. |
| **completedBy / recorded_by not set from session** | Production/dryer batches and ledger use “from auth” in comments but pass empty string. Audit trail incomplete. |
| **Placeholder compliance data** | ComplianceService returns fixed placeholder items; no integration with timecards/leave. |
| **No provider/state layer** | Screens call repositories and Supabase directly; no shared BLoC/Provider/ChangeNotifier for auth or global state (except AuthService singleton). |
| **Export success UX** | File is written then Share invoked; no explicit “Saved to X” or “Open folder” for Windows. |

---

## SECTION 5 – Exact Fix Plan (Step by Step)

### Phase A – Critical for business operations (do first)

1. **Create `business_accounts` table**  
   - Add migration `036_business_accounts.sql`: CREATE TABLE business_accounts (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), name TEXT NOT NULL, contact_name TEXT, email TEXT, phone TEXT, balance DECIMAL(10,2) DEFAULT 0, credit_limit DECIMAL(10,2), credit_terms_days INT, is_active BOOLEAN DEFAULT true, active BOOLEAN DEFAULT true, suspension_recommended BOOLEAN DEFAULT false, created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()). Add RLS if required.  
   - Run migration; verify Account List and Account Detail load and save.

2. **Create `audit_log` table**  
   - Add migration for audit_log (columns matching AuditRepository: e.g. id, created_at, action, staff_id, staff_name, details, severity/reference_type if used).  
   - Run migration; verify Audit Log screen loads.

3. **Create `message_logs` table**  
   - Add migration for message_logs (columns matching WhatsAppService insert: e.g. id, sent_at, recipient, channel, body, status).  
   - Run migration; verify WhatsApp send path no longer throws on log insert.

4. **Wire Bulk Import CSV**  
   - In `invoice_list_screen.dart`, replace `onPressed: () {}` with a handler: file_picker for CSV, parse, then call InvoiceRepository (or new method) to create invoices from rows. Show SnackBar on success/failure.

5. **Wire Hunter Process button**  
   - In `job_list_screen.dart`, replace `onPressed: () {}` with navigation to process screen (e.g. JobProcessScreen) for the selected job, or open the existing process flow with the correct job id.

6. **Set completedBy from auth**  
   - In `dryer_batch_screen.dart` and `production_batch_screen.dart`, replace `completedBy: ''` with `AuthService().currentStaffId ?? ''` (or currentStaffName if schema expects name). Ensure AuthService is populated (PIN login / session restore).

### Phase B – Required for financial accuracy

7. **Create `reorder_recommendations` table**  
   - **Done:** Migration `037_dashboard_tables_reorder_leave_timecards.sql` creates `reorder_recommendations`, `leave_requests`, and `timecards`. Trigger in 003 can insert. Dashboard catches errors and shows empty lists (no crash). Dependencies (inventory_items, staff_profiles, Clock-In) documented in migration header.

8. **Ledger / P&L / VAT / Cash Flow**  
   - Confirm ledger_entries, chart_of_accounts exist and LedgerRepository.getCashFlowByMonth, getPnLSummary, getVatSummary use correct account codes. Fix any missing account codes or mappings. No schema change if tables already correct.

9. **Invoice → ledger double-entry**  
   - Ensure invoice payment or creation (if blueprint requires) posts to ledger_entries (e.g. via repository or trigger). Align with blueprint §9.

### Phase C – Required for stock control

10. **Confirm inventory_items and stock_movements**  
    - If inventory_items/categories live in another codebase, document and ensure migrations are applied in same DB. Admin app depends on them for stock levels, stock take, production, hunter.

11. **Shrinkage and reorder logic**  
    - With reorder_recommendations created, confirm shrinkage_alerts and reorder triggers run (e.g. on stock_movements or inventory_items update). Fix any trigger ordering/dependencies.

### Phase D – Nice to have later

12. **OCR API key**  
    - Move Google Cloud Vision API key to env/AdminConfig; set in OcrService. Document in README. Enables receipt/invoice scan.

13. **leave_requests and timecards**  
    - If Clock-In app or shared schema provides these, add migrations or document dependency. Otherwise add minimal CREATE TABLE for leave_requests and timecards so dashboard and HR tabs don’t error.

14. **Compliance real data**  
    - Replace ComplianceService placeholders with queries to timecards/leave when available; add break compliance if data exists.

15. **Analytics: Pricing / Reorder / Event Forecast screens**  
    - Add screens that call analytics/report repos and display pricing margins, reorder list, event forecast as per blueprint.

16. **Export path UX**  
    - After export, show SnackBar with path (e.g. “Saved to Documents”) or add “Open folder” on Windows.

17. **Hunter service config columns**  
    - Align code with DB: use name, base_price, price_per_kg in UI and repos; or add migration to add service_name/rate/rate_type and migrate data.

---

## APPENDIX – Services, Repositories, Providers, Models

**Services (core):**  
- BaseService, SupabaseService, AuthService, ExportService, OcrService, ReportService, WhatsAppService  

**Services (feature):**  
- ComplianceService  

**Repositories:**  
- SettingsRepository, DashboardRepository, LedgerRepository, InvoiceRepository, AuditRepository  
- InventoryRepository, StockTakeRepository, ModifierRepository (inventory)  
- SupplierRepository  
- ProductionBatchRepository, DryerBatchRepository, RecipeRepository  
- AwolRepository, StaffCreditRepository  
- CustomerRepository, ReportRepository, AnalyticsRepository  

**Providers:**  
- None (no BLoC/Provider/ChangeNotifier in use; AuthService is singleton).  

**Models:**  
- BaseModel, LedgerEntry, Transaction, TransactionItem, StockMovement, ShrinkageAlert  
- Invoice, InvoiceLineItem  
- InventoryItem, ModifierGroup, ModifierItem, Category, StockTakeEntry, StockTakeSession, Supplier  
- Recipe, RecipeIngredient, ProductionBatch, ProductionBatchIngredient, DryerBatch, DryerBatchIngredient  
- AwolRecord, StaffCredit  
- ReportData, ReportSchedule, ReportDefinition  

(Supplier model in inventory/models/supplier.dart; SupplierRepository in inventory/services/supplier_repository.dart.)

---

## Roadmap priority summary

| Priority | Description | Steps |
|----------|-------------|--------|
| **Critical for business operations** | Accounts, audit, messaging, key buttons, audit trail | A1–A6 |
| **Required for financial accuracy** | Reorder table, ledger/P&L/VAT, invoice→ledger | B7–B9 |
| **Required for stock control** | Inventory/suppliers/shrinkage/reorder triggers | C10–C11 |
| **Nice to have later** | OCR, leave/timecards, compliance data, extra analytics, export UX, hunter schema | D12–D17 |
