# AUDIT 1 — Full Blueprint & Feature Audit

**Date:** 22 February 2026  
**Scope:** Flutter Admin App codebase vs. AdminAppBluePrintTruth.md and AdminAppBluePrintTruth_ADDENDUM.md  
**Type:** READ-ONLY — no files changed, created, or deleted.

---

## SECTION A — SCREEN COVERAGE AUDIT

Navigation is index-based via `main_shell.dart` (no go_router). Screens are embedded directly in `MainShell._navItems` or reached via tabs within parent screens.

| Screen | File | Route wired | Broken buttons | Save writes to | Issues |
|--------|------|-------------|----------------|----------------|--------|
| **Dashboard** | `lib/features/dashboard/screens/dashboard_screen.dart` | YES (main_shell) | NONE | N/A | NONE |
| **Inventory → Categories** | `lib/features/inventory/screens/category_list_screen.dart` | YES (InventoryNavigationScreen tab) | NONE | categories | Delete has confirm |
| **Inventory → Products** | `lib/features/inventory/screens/product_list_screen.dart` | YES | NONE | inventory_items | Delete confirm via _ProductFormDialog |
| **Inventory → Modifiers** | `lib/features/inventory/screens/modifier_group_list_screen.dart` | YES | NONE | modifier_groups, modifier_items | Delete has confirm |
| **Inventory → Suppliers** | `lib/features/inventory/screens/supplier_list_screen.dart` | YES | NONE | suppliers | Delete has confirm |
| **Inventory → Stock Levels** | `lib/features/inventory/screens/stock_levels_screen.dart` | YES | NONE | N/A (read) | NONE |
| **Inventory → Stock Take** | `lib/features/inventory/screens/stock_take_screen.dart` | YES | NONE | stock_take_entries | NONE |
| **Production → Yield Templates** | `lib/features/production/screens/carcass_intake_screen.dart` (_YieldTemplatesTab) | YES (CarcassIntakeScreen tab) | NONE | yield_templates | NONE |
| **Production → Carcass Intake** | `lib/features/production/screens/carcass_intake_screen.dart` (_CarcassIntakeTab) | YES | NONE | carcass_intakes | NONE |
| **Production → Breakdown** | `lib/features/production/screens/carcass_intake_screen.dart` (_PendingBreakdownsTab) | YES | NONE | carcass_breakdown_sessions | NONE |
| **Production → Recipes** | `lib/features/production/screens/recipe_list_screen.dart` | YES | NONE | recipes | Delete has confirm |
| **Production → Batches** | `lib/features/production/screens/production_batch_screen.dart` | YES | NONE | production_batches | NONE |
| **Production → Dryer** | `lib/features/production/screens/dryer_batch_screen.dart` | YES | NONE | dryer_batches | NONE |
| **Hunter → Job List** | `lib/features/hunter/screens/job_list_screen.dart` | YES (main_shell) | `onPressed: () {}` line 508 (Process button) | hunter_jobs | Dead Process button |
| **Hunter → Service Config** | `lib/features/hunter/screens/job_list_screen.dart` (_ServicesTab) | YES | NONE | hunter_services | Schema mismatch: code uses service_name, rate, rate_type; table has name, base_price, price_per_kg |
| **Hunter → Intake** | `lib/features/hunter/screens/job_intake_screen.dart` | YES (JobListScreen → New Job) | NONE | hunter_jobs | Uses hunter_services for species |
| **Hunter → Process** | `lib/features/hunter/screens/job_process_screen.dart` | YES (from JobListScreen) | NONE | hunter_job_processes | NONE |
| **Hunter → Summary** | `lib/features/hunter/screens/job_summary_screen.dart` | YES | NONE | N/A | NONE |
| **HR → Staff List** | `lib/features/hr/screens/staff_list_screen.dart` (_StaffProfilesTab) | YES | NONE | staff_profiles/profiles | NONE |
| **HR → Staff Form** | Inline in staff_list_screen | YES | NONE | staff_profiles | NONE |
| **HR → Timecards** | `lib/features/hr/screens/staff_list_screen.dart` (_TimecardsTab) | YES | NONE | N/A (read-only) | No admin edit/add timecard |
| **HR → Leave** | `lib/features/hr/screens/staff_list_screen.dart` (_LeaveTab) | YES | NONE | N/A | Placeholder |
| **HR → AWOL** | `lib/features/hr/screens/staff_list_screen.dart` (_AwolTab) | YES | NONE | account_awol_records | NONE |
| **HR → Payroll** | `lib/features/hr/screens/staff_list_screen.dart` (_PayrollTab) | YES | NONE | payroll_entries | NONE |
| **HR → Staff Credits** | `lib/features/hr/screens/staff_credit_screen.dart` | YES (main_shell) | NONE | staff_credit | Auth check may show "Sign in with PIN" |
| **HR → Compliance** | `lib/features/hr/screens/compliance_screen.dart` | YES (main_shell) | NONE | N/A | NONE |
| **Accounts → Account List** | `lib/features/accounts/screens/account_list_screen.dart` | YES | NONE | business_accounts | Delete has confirm |
| **Accounts → Account Detail** | `lib/features/accounts/screens/account_detail_screen.dart` | YES | NONE | business_accounts | NONE |
| **Accounts → Statement** | In account_detail_screen | YES | NONE | N/A | NONE |
| **Bookkeeping → Invoices** | `lib/features/bookkeeping/screens/invoice_list_screen.dart` (_InvoicesTab) | YES | `onPressed: () {}` line 239 (Bulk Import CSV) | invoices | Dead Bulk Import button |
| **Bookkeeping → Ledger** | `lib/features/bookkeeping/screens/ledger_screen.dart` | YES | NONE | ledger_entries | NONE |
| **Bookkeeping → Chart of Accounts** | `lib/features/bookkeeping/screens/chart_of_accounts_screen.dart` | YES | NONE | chart_of_accounts | Delete has confirm |
| **Bookkeeping → P&L** | `lib/features/bookkeeping/screens/pl_screen.dart` | YES | NONE | N/A | NONE |
| **Bookkeeping → VAT** | `lib/features/bookkeeping/screens/vat_report_screen.dart` | YES | NONE | N/A | NONE |
| **Bookkeeping → Cash Flow** | `lib/features/bookkeeping/screens/cash_flow_screen.dart` | YES | NONE | N/A | NONE |
| **Bookkeeping → Equipment** | `lib/features/bookkeeping/screens/equipment_register_screen.dart` | YES | NONE | equipment_register | NONE |
| **Bookkeeping → PTY** | `lib/features/bookkeeping/screens/pty_conversion_screen.dart` | YES | NONE | purchase_sale_agreement | NONE |
| **Analytics → Shrinkage** | `lib/features/analytics/screens/shrinkage_screen.dart` | YES | NONE | N/A | NONE |
| **Analytics → Pricing** | MISSING | NO | — | — | No dedicated screen |
| **Analytics → Reorder** | MISSING | NO | — | — | No dedicated screen |
| **Analytics → Event Forecast** | MISSING | NO | — | — | No dedicated screen |
| **Reports Hub** | `lib/features/reports/screens/report_hub_screen.dart` | YES | NONE | N/A | Export uses path_provider |
| **Customers → List** | `lib/features/customers/screens/customer_list_screen.dart` (_CustomersTab) | YES | NONE | loyalty_customers | NONE |
| **Customers → Announcements** | `lib/features/customers/screens/announcement_screen.dart` | YES | NONE | customer_announcements | NONE |
| **Customers → Recipe Library** | `lib/features/customers/screens/recipe_library_screen.dart` | YES | NONE | recipes (read) | Shares recipes table |
| **Audit Log** | `lib/features/audit/screens/audit_log_screen.dart` | YES | NONE | N/A | NONE |
| **Settings → Business** | `lib/features/settings/screens/business_settings_screen.dart` (_BusinessTab) | YES | NONE | business_settings | **SCHEMA MISMATCH** — see I-01 |
| **Settings → Tax** | `lib/features/settings/screens/tax_settings_screen.dart` | YES | NONE | business_settings (key-value) | NONE |
| **Settings → Scale** | `lib/features/settings/screens/scale_settings_screen.dart` | YES | NONE | business_settings (key-value) | NONE |
| **Settings → Notifications** | `lib/features/settings/screens/notification_settings_screen.dart` | YES | NONE | business_settings (key-value) | NONE |

---

## SECTION B — KNOWN ISSUE INVESTIGATION

### I-01 SETTINGS NOT SAVING (Windows)

**Business tab (Business Info):**
- **File:** `lib/features/settings/screens/business_settings_screen.dart` — `_BusinessTab`
- **Save handler:** `_save()` calls `_repo.updateBusinessSettings({...})`
- **Repository:** `lib/features/settings/services/settings_repository.dart`
  - `getBusinessSettings()`: `select().limit(1).maybeSingle()` — returns ONE row
  - `updateBusinessSettings(data)`: `if (existing.isEmpty) insert(data) else update(data).eq('id', existing['id'])`
- **Table schema:** `business_settings` (001_admin_app_tables_part1.sql) has `(id, setting_key, setting_value, description, updated_at, updated_by)` — **key-value schema**
- **Root cause:** Business tab expects column-based schema (`business_name`, `address`, `vat_number`, etc.). The table uses key-value rows. `getBusinessSettings()` returns a single row (e.g. `{id, setting_key: 'vat_rate', setting_value: 15}`), so `data['business_name']` is null. `updateBusinessSettings()` passes `{business_name, address, ...}` to `.update()` — **these columns do not exist**. The write will fail with "column does not exist".
- **Tax, Scale, Notification tabs:** Correctly use key-value pattern with `upsert(..., onConflict: 'setting_key')` — they work.
- **Verdict:** Business Settings save is **broken**. Write call is reached but fails due to schema mismatch. Tax/Scale/Notification saves work.

---

### I-02 REPORTS NO FILE CREATED

**ExportService:** `lib/core/services/export_service.dart`
- **Path:** `_getExportFile()` uses `getApplicationDocumentsDirectory()` (line 324)
- **File write:** `await file.writeAsString(csvString)` / `await file.writeAsBytes(...)` — properly awaited
- **Report Hub:** `lib/features/reports/screens/report_hub_screen.dart` — `_exportReport()`:
  1. Fetches report data
  2. Calls `_export.exportToCsv/Excel/Pdf` — **awaits** result
  3. `Share.shareXFiles([XFile(file.path)], ...)` — **after** file is written
  4. SnackBar "Report generated" — **after** Share (inside same try)
- **Success timing:** SnackBar fires only after file write and Share complete. Not before.
- **Windows path:** `getApplicationDocumentsDirectory()` on Windows returns a path like `C:\Users\<user>\Documents`. This is typically writable. `share_plus` Share on Windows may open a system dialog; if user cancels, no error is thrown.
- **Potential failure point:** If `getApplicationDocumentsDirectory()` returns an invalid path on some Windows configs, or if Share dialog is cancelled and user expects file in Downloads — file is in Documents. Addendum §8 (empty data) was addressed: templates render with "No data" row.
- **Verdict:** File write chain is correct. Last line before "no file" would be either path_provider returning unexpected path, or user expectation (file in Downloads vs Documents). No evidence of success-before-write.

---

### I-03 CUSTOMER RECIPES vs PRODUCTION RECIPES

- **Table:** `recipes` (001_admin_app_tables_part1.sql) — columns: `id, name, description, category, servings, prep_time_minutes, cook_time_minutes, total_time_minutes, difficulty, is_active, created_at, created_by, updated_at`
- **No `type` or `recipe_type` column** to distinguish production vs customer/marketing.
- **Production:** `lib/features/production/screens/recipe_list_screen.dart`, `recipe_form_screen.dart` — use `RecipeRepository` → `recipes` table
- **Customer:** `lib/features/customers/screens/recipe_library_screen.dart` — uses same `RecipeRepository`, same `recipes` table
- **Verdict:** Customer recipes and production recipes **share the same table**. No type/category field to distinguish them. Both use `category` (text) for grouping. Marketing vs production distinction is not enforced.

---

### I-04 LOYALTY APP ANNOUNCEMENTS — DATABASE PUSH MISSING

- **Announcement screen:** `lib/features/customers/screens/announcement_screen.dart`
- **Channels:** WhatsApp, SMS, Both (dropdown)
- **Table:** `customer_announcements` (033_customer_announcements.sql) — `title, body, channel, recipient_count, status, sent_at, image_url`
- **Mechanism:** Admin inserts into `customer_announcements`. WhatsApp/SMS send via `launchUrl(wa.me/...)` or user manually sends SMS. **No push notification table.**
- **Loyalty app:** Would need to poll or subscribe to a table (e.g. `loyalty_notifications` or `push_notices`) for in-app notifications. **No such table exists** in migrations.
- **Verdict:** WhatsApp/SMS channels exist. **No loyalty_notifications or push_notices table.** No mechanism for loyalty app to receive in-app push from admin. `customer_announcements` is a log of sent messages, not a push target.

---

### I-05 SUPPLIER OPENING BALANCES

- **Suppliers table:** `suppliers` (010_supplier_stocktake.sql) — `id, name, contact_person, phone, email, address, payment_terms, bbbee_level, is_active, created_at, updated_at`
- **No `opening_balance` or `balance_brought_forward` column**
- **Supplier form:** `lib/features/inventory/screens/supplier_form_screen.dart` — no opening balance field
- **Ledger:** `ledger_entries` has `reference_type` (invoice, payment, adjustment, transfer). No explicit "supplier_opening_balance" type. Could post via adjustment, but no dedicated flow.
- **Verdict:** Opening balance column and form field **missing**. No dedicated ledger mechanism for supplier opening balance without invoice.

---

### I-06 HUNTER SPECIES DROPDOWN EMPTY

- **Table used:** `hunter_services` (not `hunter_service_config`). Migration 001 defines `hunter_services` with `name, base_price, price_per_kg`.
- **Job intake:** `lib/features/hunter/screens/job_intake_screen.dart` — `_loadSpecies()` queries `hunter_services` where `is_active = true`
- **Seed data:** No INSERT statements for SA game species in any migration
- **Verdict:** Table is **empty by design**. Admin must add species via Hunter → Services tab. No seed data.

---

### I-07 HUNTER JOB DATES AND DELIVERY STATUS

- **hunter_jobs** (001 + 026): `created_at`, `job_date` (026), `started_at`, `completed_at`. **No `required_delivery_date`, `delivered_at`, `delivery_status`**
- **Job intake form:** Has `job_date` (DatePicker). No required_delivery_date, delivered_at, delivery_status fields
- **Verdict:** `job_date` exists. `required_delivery_date`, `delivered_at`, `delivery_status` (on_time/late/cancelled) **missing** from schema and form.

---

### I-08 HUNTER SERVICES LINKED TO INVENTORY PRODUCTS

- **hunter_services** (001): `id, name, base_price, price_per_kg, is_active, ...`. Migration 026 adds `cut_options` JSONB.
- **No `service_product_id` or FK to inventory_items**
- **Service config screen:** `job_list_screen.dart` _ServicesTab — form has `service_name`, `rate`, `rate_type`. No product link UI
- **Processing instructions:** `job_intake_screen.dart` — `_selectedCuts` from `cut_options` (structured list from service config). Stored as `processing_instructions` JSONB on hunter_jobs
- **Verdict:** Service is **not** linked to a chargeable inventory product. Customer instruction = structured list from `cut_options`, not free text. No product link.

---

### I-09 PRODUCT CATEGORIES WIPED AFTER SUBCATEGORY MIGRATION

- **Migration 007:** Adds `sub_category` TEXT, `supplier_ids`, etc. to `inventory_items`. Does **not** drop or rename `category_id`
- **Product list/form:** Uses `category_id` (FK to categories). `product_list_screen.dart` line 76: `p['category_id']`
- **No migration found** that removes `category_id` or wipes categories
- **Verdict:** No evidence of category wipe migration. `category_id` is used. If products lost categories, cause is elsewhere (manual data change or different migration). 007 only adds columns.

---

### I-10 PRODUCT SORTING MISSING

- **Product list:** `lib/features/inventory/screens/product_list_screen.dart`
- **Sort controls:** None — no dropdown, column header tap, or sort option
- **Filter:** Category filter, search, show inactive
- **Verdict:** Sorting **absent**. Products ordered by `plu_code` from query only.

---

### I-11 HR AUTH ERROR ON STAFF CREDIT / ADVANCE

- **Screen:** `lib/features/hr/screens/staff_credit_screen.dart`
- **Check:** Line 75–80: `final userId = AuthService().currentStaffId; if (userId == null || userId.isEmpty) { showSnackBar('Sign in with PIN to add credit'); return; }`
- **AuthService:** `lib/core/services/auth_service.dart` — `_currentStaffId` set by `_setCurrentUser()` after PIN auth. Uses `authenticateWithPin()` → `_authenticateOnline` or `_authenticateOffline`
- **Session persistence:** `SharedPreferences` stores `_activeSessionKey`. On app restart, `_currentStaffId` is **not** restored from storage — AuthService does not read `_activeSessionKey` in `initState` or constructor
- **Verdict:** Root cause: **AuthService does not restore session on app cold start.** User must re-enter PIN. If MainShell is shown before PIN screen, or if a race occurs, `currentStaffId` can be null even after prior login. The "Sign in with PIN" message fires when `AuthService().currentStaffId` is null — i.e. no session in memory.

---

### I-12 ADMIN FULL CONTROL — TIMECARD CORRECTION

- **Timecards tab:** `lib/features/hr/screens/staff_list_screen.dart` — `_TimecardsTab`
- **Functionality:** Read-only list. Displays clock_in, clock_out, breaks, total_hours, overtime_hours
- **Edit:** No UI to edit clock_in, clock_out, break_minutes
- **Add:** No UI to add a timecard for a day with no entry
- **Guard:** N/A — no edit capability
- **Verdict:** Timecards are **view-only**. Admin cannot manually edit or add timecards.

---

### I-13 BUTTON COVERAGE — DEAD BUTTONS

**onPressed: null / onPressed: () {}:**
| File | Line | Context |
|------|------|---------|
| `invoice_list_screen.dart` | 239 | Bulk Import CSV button — `onPressed: () {}` |
| `job_list_screen.dart` | 508 | Process button in _JobDetailsDialog — `onPressed: () {}` |

**// TODO and // FIXME in screen files:**
| File | Line | Text |
|------|------|------|
| `production_batch_screen.dart` | 566 | `completedBy: '', // TODO: from auth` |
| `dryer_batch_screen.dart` | 391 | `completedBy: '', // TODO: from auth` |
| `ocr_service.dart` | 14 | `final String _apiKey = ''; // TODO: Add Google Cloud Vision API key` |

---

## SECTION C — DATABASE SCHEMA AUDIT

### 1. Tables (from migrations 001–035)

| Table | Migration |
|-------|-----------|
| account_awol_records | 002 |
| announcements | 002 |
| business_accounts | (from POS/prior) |
| business_settings | 001 |
| carcass_breakdown_sessions | 001 |
| carcass_intakes | 001 |
| chart_of_accounts | 002 |
| customer_announcements | 033 |
| donations | 002 |
| dryer_batch_ingredients | 001 |
| dryer_batches | 001 |
| equipment_register | 002 |
| equipment_register_service_log | 035 |
| event_sales_history | 002 |
| event_tags | 002 |
| hunter_job_processes | 001 |
| hunter_jobs | 001 |
| hunter_process_materials | 001 |
| hunter_services | 001 |
| invoice_line_items | 002 |
| invoices | 002 |
| ledger_entries | 002 |
| loyalty_customers | 002 |
| modifier_groups | 001 |
| modifier_items | 001 |
| production_batch_ingredients | 001 |
| production_batch_outputs | 034 |
| production_batches | 001 |
| profiles | (from auth) |
| purchase_sale_agreement | 002 |
| purchase_sale_payments | 002 |
| payroll_entries | 002 |
| payroll_periods | 002 |
| recipe_ingredients | 001 |
| recipes | 001 |
| sponsorships | 002 |
| staff_credit | 002 |
| staff_documents | 001 |
| staff_loans | 002 |
| staff_profiles | (view or table) |
| stock_locations | 001 |
| stock_movements | 001 |
| stock_take_entries | 010 |
| stock_take_sessions | 010 |
| suppliers | 010 |
| system_config | (referenced by settings) |
| tax_rules | (referenced by settings) |
| timecards | (from Clock-In app) |
| timecard_breaks | (from Clock-In app) |
| transactions | (from POS) |
| yield_template_cuts | 001 |
| yield_templates | 001 |
| + inventory_items, categories, product_suppliers, purchase_orders, etc. (from POS/other migrations) |

### 2. hunter_jobs columns

From 001 + 026: `id, job_number, client_name, client_contact, service_id, status, quoted_price, final_price, estimated_weight_kg, actual_weight_kg, special_instructions, created_at, created_by, assigned_to, started_at, completed_at, notes` + `job_date, processing_instructions, weight_in, cuts, paid, customer_name, customer_phone, animal_type, estimated_weight, total_amount`

### 3. recipes columns

`id, name, description, category, servings, prep_time_minutes, cook_time_minutes, total_time_minutes, difficulty, is_active, created_at, created_by, updated_at`. **No `type` or `recipe_type`** column for production vs customer.

### 4. suppliers columns

`id, name, contact_person, phone, email, address, payment_terms, bbbee_level, is_active, created_at, updated_at`. **No opening_balance.**

### 5. inventory_items category-related columns

From 007: `category_id` (FK), `sub_category` (TEXT), `supplier_ids` (JSONB)

### 6. hunter_services columns

From 001 + 026: `id, name, base_price, price_per_kg, is_active, created_at` + `cut_options` (JSONB). **No service_product_id.**

### 7. loyalty_notifications / push_notices

**Absent.** No table for loyalty app push notifications.

### 8. Tables with no screen/repository

- `sponsorships` — no screen
- `donations` — no screen
- `event_tags` — no screen
- `event_sales_history` — no screen
- `purchase_sale_payments` — may be used by PTY screen
- `hunter_process_materials` — no screen
- `staff_loans` — no dedicated screen (staff_credit may cover)
- `staff_documents` — referenced in compliance

---

## SECTION D — BLUEPRINT COMPLETION SCORE

| Section | Completion % | Missing |
|---------|--------------|---------|
| §2 Auth & PIN | 90% | Session restore on cold start; role routing for Cashier/Blockman rejection |
| §3 Dashboard | 85% | Some widgets placeholder; real-time subscriptions |
| §4 Inventory | 88% | Product sorting; subcategory UI; barcode in stock take (added) |
| §5 Production | 85% | Recipe→product linking; batch outputs (added) |
| §6 Hunter | 75% | Species seed data; delivery dates/status; service→product link; dead Process button; schema mismatch (service_name/rate) |
| §7 HR & Payroll | 80% | Timecard edit/add; leave flow; staff credit auth edge case |
| §8 Business Accounts | 85% | Statement export |
| §9 Bookkeeping | 82% | Bulk Import CSV dead; PTY/Equipment (added) |
| §10 Analytics | 60% | Pricing, Reorder, Event Forecast screens missing |
| §11 Reports | 85% | Schedule backend; template empty state (addressed) |
| §12 Customers & Loyalty | 80% | Push notifications for loyalty app; recipe type distinction |
| §13 Audit Log | 85% | Filtering/export |
| §14 Settings | 75% | Business tab schema mismatch (broken save) |

**Overall weighted completion:** ~78%

**Production-readiness verdict:** Not production-ready. Critical issues: Business Settings save broken; 2 dead buttons; Hunter schema mismatch; no timecard correction; Analytics screens missing; staff credit auth edge case.
