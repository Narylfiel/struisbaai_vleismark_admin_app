# Full Backend Audit Report

**Date:** 2026-02-22  
**Scope:** Supabase (Postgres + PostgREST) vs Flutter Admin App — tables, RPCs, storage, schema mismatches.  
**Actual schema source:** `admin_app/supabase/.temp/pulled_schema.sql` (pg_dump of deployed DB).  
**Note:** No `supabase/schema.sql` exists in repo; run `scripts/pg_dump_schema.ps1` to refresh the pulled schema.

---

## STEP 1 — Codebase references (extracted)

### Tables referenced in code (select / insert / update / delete)

| Table | Usage (files) |
|-------|----------------|
| account_awol_records | — (migrations only) |
| account_transactions | account_list_screen, account_detail_screen |
| audit_log | audit_repository, report_repository |
| business_accounts | account_list_screen, account_detail_screen, dashboard_screen |
| business_settings | settings_repository, scale/tax/notification_screens, pty_conversion, job_summary, compliance_screen, export_service |
| carcass_cuts | carcass_intake_screen (insert) |
| carcass_intakes | carcass_intake_screen |
| categories | product_list_screen, recipe_form_screen, export_service (inventory_items join) |
| chart_of_accounts | chart_of_accounts_screen, ledger_screen |
| compliance_records | compliance_screen |
| dryer_batch_ingredients | dryer_batch_repository |
| dryer_batches | dryer_batch_repository |
| equipment_register | equipment_register_screen |
| event_sales_history | analytics_repository |
| event_tags | analytics_repository |
| hunter_jobs | job_process_screen, job_summary_screen, job_intake_screen, report_repository |
| hunter_services | job_process_screen, job_intake_screen |
| inventory_items | production_batch_screen, job_process_screen, product_list_screen, recipe_form_screen, stock_take_screen, analytics_repository, export_service, report_service, inventory_repository, modifier_items_screen, dryer_batch_screen |
| invoice_line_items | invoice_repository |
| invoices | invoice_repository, account_detail_screen |
| ledger_entries | ledger_repository, chart_of_accounts_screen |
| leave_balances | staff_list_screen (_LeaveTab) |
| leave_requests | dashboard_screen, staff_list_screen, compliance_service |
| message_logs | whatsapp_service |
| modifier_groups | product_list_screen |
| payroll_entries | account_detail_screen, staff_list_screen, export_service |
| payroll_periods | report_repository |
| product_suppliers | product_list_screen |
| production_batch_ingredients | production_batch_repository |
| production_batch_outputs | production_batch_repository |
| production_batches | production_batch_repository |
| purchase_sale_agreement | account_detail_screen |
| purchase_sale_payments | account_detail_screen |
| recipes | product_list_screen |
| reorder_recommendations | dashboard_screen, analytics_repository |
| scale_config | settings_repository |
| shrinkage_alerts | dashboard_screen, analytics_repository, report_repository |
| staff_awol_records | awol_repository |
| staff_credit | staff_credit_repository |
| staff_profiles | dashboard_screen, compliance_service, staff_list_screen, account_list_screen, auth_service, base_service, awol_repository, staff_credit_repository |
| stock_locations | stock_take_screen, stock_movement_dialogs |
| stock_movements | inventory_repository |
| suppliers | invoice_repository, carcass_intake_screen, supplier_list_screen, product_list_screen |
| system_config | settings_repository |
| tax_rules | settings_repository |
| timecards | dashboard_screen, staff_list_screen, compliance_service, report_repository |
| timecard_breaks | staff_list_screen, compliance_service |
| transactions | dashboard_repository, report_repository, report_service, export_service, analytics_repository |
| transaction_items | report_repository, analytics_repository |
| yield_templates | carcass_intake_screen |
| loyalty_customers | report_repository |
| profiles | account_list_screen |

### RPCs referenced in code

| RPC | File | Notes |
|-----|------|--------|
| get_event_forecast | analytics_repository | Params: p_event_type; fallback to _getForecastFromEventHistory |
| calculate_nightly_mass_balance | analytics_repository | No params; called optionally, catch (_) {} |
| calculate_supplier_spend | report_repository | Params used in report |

### Storage buckets

| Bucket | Usage |
|--------|--------|
| documents | pty_conversion_screen (uploadBinary, getPublicUrl), compliance_screen (upload, createSignedUrl) |
| product-images | announcement_screen (upload, getPublicUrl) |

---

## STEP 2 — Actual schema (from pulled_schema.sql)

### Tables present in DB (CREATE TABLE public.*)

account_awol_records, account_transactions, announcements, audit_log, awol_records, business_accounts, business_settings, carcass_breakdown_sessions, carcass_cuts, carcass_intakes, categories, chart_of_accounts, compliance_records, customer_announcements, donations, dryer_batch_ingredients, dryer_batches, equipment_assets, equipment_register, event_sales_history, event_tags, hunter_job_processes, hunter_jobs, hunter_process_materials, hunter_service_config, hunter_services, inventory_items, invoice_line_items, invoices, leave_balances, leave_requests, ledger_entries, loyalty_customers, message_logs, modifier_groups, modifier_items, payroll_entries, payroll_periods, printer_config, product_suppliers, production_batch_ingredients, production_batch_outputs, production_batches, profiles, purchase_order_lines, purchase_orders, purchase_sale_agreement, purchase_sale_agreements, purchase_sale_payments, recipe_ingredients, recipes, reorder_recommendations, role_permissions, sales_transactions, scale_config, shrinkage_alerts, sponsorships, staff_awol_records, staff_credit, staff_credits, staff_documents, staff_loans, staff_profiles, stock_locations, stock_movements, stock_take_entries, stock_take_sessions, stock_takes, suppliers, system_config, tax_rules, timecards, transaction_items, transactions, yield_template_cuts, yield_templates.

### Tables in code but NOT in DB

- **timecard_breaks** — Code: staff_list_screen (select by timecard_id, break_start, break_end), compliance_service (break_duration_minutes). **Missing table.**
- **supplier_price_changes** — Code: analytics_repository (getPricingSuggestions, updatePricingSuggestion). **Missing table.** (Code has fallback to inventory margin calc.)

### RPCs in DB (CREATE FUNCTION public.*)

audit_trigger_function, calculate_asset_depreciation, calculate_yield_percentage, check_account_suspension, check_reorder_threshold, check_shrinkage_threshold, deduct_stock_on_sale, detect_awol_pattern, get_dashboard_metrics, get_inventory_valuation, post_pos_sale_to_ledger, process_payroll_period, update_updated_at_column, validate_timecard.

### RPCs in code but NOT in DB

- **get_event_forecast** — Code has fallback _getForecastFromEventHistory.
- **calculate_nightly_mass_balance** — Code calls optionally; no crash if missing.
- **calculate_supplier_spend** — Report repository; will fail if report is run.

---

## STEP 3 — Detected issues

### Critical failures

| # | Issue | Detail |
|---|--------|--------|
| 1 | **business_settings schema mismatch** | Code uses **key-value**: `setting_key`, `setting_value` (select/upsert by key). Deployed DB has **column-based** schema: `business_name`, `trading_name`, `address`, `vat_number`, `phone`, etc. — **no** `setting_key` or `setting_value`. Settings screens and repository will fail or return empty. |
| 2 | **leave_requests missing columns** | Code updates `review_notes`, `reviewed_at` (staff_list_screen). DB has `notes`, `approved_by`, `employee_id` but **no** `review_notes` or `reviewed_at`. Update will omit or fail. |
| 3 | **leave_balances column / join mismatch** | Code: `.select('*, staff_profiles!staff_id(full_name)').order('staff_id')`. DB: `leave_balances` has **employee_id** (FK to profiles), **no** `staff_id`. PostgREST join and order will fail (column staff_id does not exist). |
| 4 | **timecard_breaks table missing** | Code selects from `timecard_breaks` (timecard_id, break_start, break_end, break_duration_minutes). Table does not exist in DB → query fails. |
| 5 | **reorder_recommendations column names** | Code: `.order('days_remaining', ascending: true)` and uses `r['status']`. DB: columns are **days_of_stock** and **urgency** (no `days_remaining`, no `status`). PGRST205 / invalid column. |
| 6 | **event_tags missing event_type** | Code: `insert({ 'event_name', 'event_date', 'event_type' })`. DB: **no** `event_type` column. Insert will fail. |

### Schema conflicts (code vs DB)

| Table | Code expects | DB has | Risk |
|-------|--------------|--------|------|
| business_settings | setting_key, setting_value (multiple rows) | business_name, address, vat_number, ... (single row) | All settings read/write broken |
| leave_requests | review_notes, reviewed_at | notes, approved_by, employee_id only | Leave tab update incomplete |
| leave_balances | staff_id, FK to staff_profiles | employee_id, FK to profiles | Leave balances query/join broken |
| reorder_recommendations | days_remaining, status | days_of_stock, urgency | Reorder list sort/filter broken |
| event_tags | event_type | — | Event tag save broken |
| shrinkage_alerts (model) | product_name, product_id from JSON | item_name, item_id, product_id in DB | fromJson can use item_name/item_id as fallback |

### Missing modules / endpoints

- **supplier_price_changes** — Table missing; Dynamic Pricing tab falls back to inventory-only suggestions.
- **get_event_forecast** — RPC missing; Event tab uses _getForecastFromEventHistory.
- **calculate_nightly_mass_balance** — RPC missing; optional, no crash.
- **calculate_supplier_spend** — RPC missing; report that calls it will fail.

### Other

- **audit_log**: DB has table_name, record_id, staff_id, staff_name, old_value, new_value, details, severity. Code filters by action, staff_name, details — **compatible**.
- **message_logs**: Columns match WhatsAppService insert/select — **compatible**.
- **ledger_entries**: Has account_code, account_name, source, recorded_by — **compatible** with ledger_repository.

### RLS

- Pulled schema shows RLS enabled on many tables with policies (e.g. "Allow all for anon"). No evidence of PGRST205 from RLS in this audit; failures above are from missing tables/columns.

---

## STEP 4 — Structured audit summary

### Completion score (backend vs code)

| Area | Score | Notes |
|------|--------|--------|
| Tables used by app | ~85% | 2 tables missing (timecard_breaks, supplier_price_changes); several column mismatches. |
| RPCs | ~70% | 3 RPCs missing; 2 have fallbacks. |
| Storage | N/A | Buckets `documents`, `product-images` must exist in Supabase Storage (not in pg_dump). |
| Schema alignment | ~75% | business_settings, leave_*, reorder_recommendations, event_tags need fixes. |

### Critical failures (must fix)

1. business_settings: code expects key-value; DB is column-based.  
2. leave_requests: missing review_notes, reviewed_at.  
3. leave_balances: code uses staff_id; DB has employee_id.  
4. timecard_breaks: table missing.  
5. reorder_recommendations: code uses days_remaining, status; DB has days_of_stock, urgency.  
6. event_tags: missing event_type.

### Schema conflicts

- business_settings (full read/write path).  
- leave_requests (update path).  
- leave_balances (select + join).  
- reorder_recommendations (order + field names).  
- event_tags (insert).

### Missing modules

- supplier_price_changes table.  
- get_event_forecast, calculate_nightly_mass_balance, calculate_supplier_spend RPCs.  
- timecard_breaks table.

### Broken endpoints / flows

- Settings (Business / Scale / Tax / Notifications) if they use SettingsRepository with key-value.  
- HR → Leave tab: leave_balances load and leave_requests update.  
- HR → Timecards: timecard_breaks load.  
- Analytics → Reorder: sort/filter.  
- Analytics → Event: save event tag.  
- Analytics → Dynamic Pricing: supplier_price_changes (fallback exists).  
- Reports → supplier spend report (if it calls calculate_supplier_spend).

---

## STEP 5 — Safe fix plan

### 5.1 SQL migration scripts (one migration: 040_backend_audit_fixes.sql)

1. **business_settings**  
   - Do **not** change DB schema. Fix in **code** to read/write the existing column-based table (single row: business_name, address, vat_number, phone, working_hours_start, working_hours_end, etc.). See 5.2.

2. **leave_requests**  
   - `ALTER TABLE leave_requests ADD COLUMN IF NOT EXISTS review_notes TEXT;`  
   - `ALTER TABLE leave_requests ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ;`

3. **leave_balances**  
   - Add column so code’s join works: `ALTER TABLE leave_balances ADD COLUMN IF NOT EXISTS staff_id UUID REFERENCES staff_profiles(id);`  
   - Backfill: `UPDATE leave_balances SET staff_id = employee_id WHERE staff_id IS NULL AND employee_id IS NOT NULL;`  
   - (If staff_profiles.id ≠ profiles.id, backfill may need a mapping; document.)

4. **timecard_breaks**  
   - `CREATE TABLE IF NOT EXISTS timecard_breaks (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), timecard_id UUID NOT NULL REFERENCES timecards(id) ON DELETE CASCADE, break_start TIMESTAMPTZ, break_end TIMESTAMPTZ, break_duration_minutes NUMERIC(6,2), created_at TIMESTAMPTZ DEFAULT NOW());`  
   - Index: `CREATE INDEX IF NOT EXISTS idx_timecard_breaks_timecard_id ON timecard_breaks(timecard_id);`

5. **reorder_recommendations**  
   - No DB change. Fix in **code**: use `days_of_stock` and `urgency` instead of `days_remaining` and `status`. See 5.2.

6. **event_tags**  
   - `ALTER TABLE event_tags ADD COLUMN IF NOT EXISTS event_type TEXT;`

7. **supplier_price_changes** (minimal, for Dynamic Pricing when data exists)  
   - `CREATE TABLE IF NOT EXISTS supplier_price_changes (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), inventory_item_id UUID, supplier_id UUID, old_price NUMERIC(10,2), new_price NUMERIC(10,2), percentage_increase NUMERIC(6,2), suggested_sell_price NUMERIC(10,2), status TEXT DEFAULT 'Pending', created_at TIMESTAMPTZ DEFAULT NOW());`  
   - Indexes as needed for status and created_at.

8. **RPCs** (optional; add if reports/analytics are required)  
   - get_event_forecast: return set from event_sales_history / event_tags (or placeholder).  
   - calculate_supplier_spend: aggregate from invoices/suppliers.  
   - calculate_nightly_mass_balance: optional trigger/batch.

### 5.2 Code fixes

1. **SettingsRepository + Business tab**  
   - **getBusinessSettings()**: Query `business_settings` with `.limit(1).maybeSingle()`, then build map from row: e.g. `business_name` → `'business_name'`, `address` → `'address'`, `vat_number` → `'vat_number'`, `phone` → `'phone'`, `working_hours_start` → `'bcea_start_time'`, `working_hours_end` → `'bcea_end_time'` (map DB column names to the keys the UI uses).  
   - **updateBusinessSettings(data)**: Take keys like business_name, address, vat_number, phone, bcea_start_time, bcea_end_time; map to DB columns (business_name, address, vat_number, phone, working_hours_start, working_hours_end); `.update({ ... }).eq('id', existingId)` or upsert single row.  
   - Scale/Tax/Notification screens already use `business_settings` key-value in some places; ensure they use the same single-row column-based source (or keep their current key-value if we add a key-value table later). **Decision:** Use column-based business_settings for Business tab; Scale/Tax/Notification already write to business_settings with keys like scale_model, vat_rate — so we need either (A) one row with columns for scale_model, vat_rate, etc., or (B) add setting_key/setting_value to the same table and use key-value for those. Simplest: **add columns setting_key, setting_value** to business_settings and keep one “logical” row per key by using a separate table or a JSONB column. Actually the cleanest fix that doesn’t drop data: **migration to add setting_key UNIQUE and setting_value JSONB** to business_settings, then backfill one row per key from existing columns; then code can stay key-value. But the current DB has no setting_key/setting_value at all — so we’d be adding columns to a table that has 20+ other columns. So either: (1) New table `business_settings_kv (setting_key, setting_value)` and migrate existing row into it, code uses that; or (2) Code uses column-based. User said “Only fix what the system actually needs” and “Do NOT create placeholder tables.” So **use column-based in code** for the Business tab; for Scale/Tax/Notification they currently write key-value style — they’d need to write to the same single row’s columns (e.g. scale_brand, scale_plu_digits for scale; vat_standard for tax; we’d need to map). That’s a larger change. **Minimal fix for audit:** Document that business_settings in DB is column-based; fix **only** the Business tab to use column-based (getBusinessSettings reads one row and maps columns to keys; updateBusinessSettings updates that row). Scale/Tax/Notification screens currently use their own key-value reads/writes to business_settings — if the DB has no setting_key/setting_value, those screens are already broken. So the only way to fix without adding a new table is: add setting_key and setting_value to business_settings (migration), and ensure at least one row exists per key the app needs (e.g. insert rows for business_name, address, scale_model, vat_rate, etc.). I’ll add to migration: **ADD COLUMN setting_key TEXT, ADD COLUMN setting_value JSONB**; then we need to either migrate the single existing row into multiple rows (one per key) or keep one row and have code support both. The schema in the dump has no setting_key — so it’s a single-row table. So add two columns, then run a one-time backfill: INSERT into business_settings (setting_key, setting_value) SELECT 'business_name', to_jsonb(business_name) FROM business_settings WHERE id = (SELECT id FROM business_settings LIMIT 1); etc. But then we’d have multiple rows for business_settings (one with business_name, one with address, …) and the table would have both old columns and new. So the table would have two “modes”: one row with old columns, and N rows with setting_key/setting_value. Code could then select * where setting_key is not null and get key-value rows. So migration: add setting_key, setting_value (nullable). Backfill: for each column we care about, insert a new row with setting_key = 'business_name', setting_value = (select business_name from business_settings limit 1). That duplicates data. Simpler: **just add setting_key and setting_value**, and in code, **if** getBusinessSettings finds rows with setting_key not null, use them; **else** read the single row and map columns to keys. So getBusinessSettings: try select setting_key, setting_value where setting_key is not null; if rows exist, build map from that; else select * limit 1 and build map from column names (business_name -> 'business_name', etc.). updateBusinessSettings: if any row has setting_key, upsert by setting_key; else update the single row’s columns from the map. That way we support both. I’ll add to migration only ADD COLUMN setting_key TEXT UNIQUE, ADD COLUMN setting_value JSONB (nullable). Then the first time the app runs, there are no rows with setting_key set, so code must “read one row and map columns to keys” and “update one row by column”. So we need code that does: getBusinessSettings: select * from business_settings limit 1; return map with keys business_name, address, vat_number, phone, bcea_start_time, bcea_end_time from row’s business_name, address, vat_number, phone, working_hours_start, working_hours_end. updateBusinessSettings: update business_settings set business_name = data['business_name'], address = data['address'], ... where id = (select id from business_settings limit 1). So the fix is **code-only** for Business tab (read/update single row by column). Scale/Tax/Notification: they use key-value; if we don’t add key-value columns, they need to use the same single row — e.g. scale_model stored in a column. So we need to add columns for scale_model, vat_rate, etc., OR add setting_key/setting_value. The dump shows the table has scale_brand, scale_plu_digits, vat_standard, etc. So the DB already has columns for scale and tax! So Scale screen should read scale_brand, scale_plu_digits, etc., and Tax screen vat_standard, etc. So the fix is: **Code only** — change all settings screens to use the column-based schema. I’ll document that in the fix plan and implement code changes for Business tab and optionally for Scale/Tax/Notification (they currently read/write key-value; we’ll need to map to column names). Let me add migration only for: leave_requests (review_notes, reviewed_at), leave_balances (staff_id), timecard_breaks, event_tags (event_type), supplier_price_changes. No change to business_settings schema; code fix to use column-based.

2. **staff_list_screen.dart _LeaveTab**  
   - **leave_balances**: Use `employee_id` and select `*, staff_profiles!employee_id(full_name)` if FK exists, or load leave_balances and then load staff_profiles for those employee_ids and merge in code. If we add staff_id to leave_balances and backfill, code can keep using staff_id.  
   - **leave_requests**: After migration, review_notes and reviewed_at exist; no code change needed.

3. **analytics_repository.dart**  
   - **getReorderRecommendations**: Use `.order('days_of_stock', ascending: true)` and use `r['urgency']` instead of `r['status']`; map urgency to display text (URGENT/WARNING/OK).  
   - **ShrinkageAlert fromJson**: Use `product_name: json['product_name'] ?? json['item_name']`, `product_id: json['product_id'] ?? json['item_id']`.

4. **event_tags insert**  
   - After migration (event_type column added), existing insert is correct.

5. **compliance_service / staff_list_screen timecard_breaks**  
   - After migration (table created), queries work; ensure column names match (break_start, break_end, break_duration_minutes, timecard_id).

### 5.3 RLS corrections

- No RLS changes required for the above. If specific endpoints fail with 403, add policies per table as needed (audit did not require changes).

### 5.4 Supabase bucket setup

- Ensure buckets **documents** and **product-images** exist in Supabase Dashboard → Storage, with policies allowing anon/authenticated as required for upload and read.

---

## STEP 6 — Apply fixes incrementally

1. **Migration 040** — Apply SQL (leave_requests, leave_balances, timecard_breaks, event_tags, supplier_price_changes).  
2. **Code: reorder_recommendations** — Use days_of_stock and urgency.  
3. **Code: ShrinkageAlert** — fromJson fallback for item_name/item_id.  
4. **Code: business_settings** — Use column-based read/update for Business tab (and map Scale/Tax/Notification to columns if they’re broken).  
5. **Code: leave_balances** — Use employee_id and join to staff_profiles by employee_id, or rely on migration-added staff_id after backfill.  
6. **Verify** — Run app: Settings, HR Leave, HR Timecards, Analytics Reorder/Event, Dynamic Pricing (with or without supplier_price_changes data).

---

## References

- Actual schema: `admin_app/supabase/.temp/pulled_schema.sql`
- Migrations: `admin_app/supabase/migrations/`
- FINAL_COMPLETION_PLAN.md, ADMIN_APP_FULL_AUDIT_ROADMAP.md
