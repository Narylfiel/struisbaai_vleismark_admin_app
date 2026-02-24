# Final Completion Plan — Butcher Admin System

**Date:** 2026-02-22  
**Scope:** Remaining unfinished features, ranked by operational importance, with a production-safe step-by-step plan.  
**Rules:** Do not recreate existing modules; only extend, fix, or complete. Follow existing architecture.

---

## 1. Current Status Summary

- **Core system:** ~70% complete.
- **Already done (verified in codebase):**
  - **Phase A (critical):** `business_accounts`, `audit_log`, `message_logs` (migration 036); Bulk Import CSV and Hunter Process buttons wired; `completedBy` from AuthService in production/dryer; Hunter schema aligned (`name`, `base_price`, `price_per_kg`).
  - **Phase B (financial):** Invoice approve → ledger double-entry (Debit COGS, Credit AP); Ledger/P&L/VAT use correct account codes (4000, 2100, etc.); reorder_recommendations, leave_requests, timecards (037).
  - **Phase C/D:** Recipes `created_by` (038); Business Settings key-value load/save aligned; BCEA compliance uses real timecards/leave; HR Leave tab loads/updates `leave_requests`; Analytics (Shrinkage, Pricing, Reorder, Event) tabs implemented with repo calls; Dashboard and Report Hub export file write + Share working.

---

## 2. Remaining Unfinished Features (Identified)

| # | Feature / gap | Location / evidence | Category |
|---|----------------|--------------------|----------|
| 1 | **OCR API key empty** | `lib/core/services/ocr_service.dart`: `_apiKey = ''` | Automation / Financial |
| 2 | **WhatsApp/Twilio credentials** | `lib/core/services/whatsapp_service.dart`: TODO move to secure config | Automation |
| 3 | **Settings tables not in admin_app migrations** | `scale_config`, `tax_rules`, `system_config` used by SettingsRepository; only in root `fix_missing_schema_from_blueprint.sql` | Financial / Config |
| 4 | **supplier_price_changes table** | AnalyticsRepository uses it; no `CREATE TABLE` in admin_app migrations; Pricing tab falls back to inventory margin calc | Reporting / Stock |
| 5 | **Export path UX** | ExportService uses Documents; no “Saved to X” SnackBar or “Open folder” on Windows | Reporting |
| 6 | **get_event_forecast RPC** | Event tab calls it; if missing in DB, forecast list is empty or errors | Reporting |
| 7 | **Audit log write path** | AuditRepository only reads; no app or trigger writes to `audit_log` → log stays empty | Reporting / Compliance |
| 8 | **Optional: leave_balances** | If compliance or HR need annual leave balance display; schema may exist elsewhere | Staff |

---

## 3. Ranking by Operational Importance (Butcher Shop)

### Financial accuracy
1. **Settings tables (scale_config, tax_rules, system_config)** — Scale/Tax/Notifications screens fail if tables missing.  
2. **OCR API key** — Enables invoice/receipt scan and faster capture; optional if manual entry is acceptable.

### Stock control
3. **supplier_price_changes** — Improves Dynamic Pricing tab when supplier price data exists; fallback to inventory margins already works.

### Staff management
4. **Audit log write path** — Needed for accountability and compliance; currently read-only.  
5. **leave_balances** — Nice-to-have if BCEA/annual leave display is required.

### Reporting
6. **Export path UX** — “Saved to Documents” / “Open folder” improves clarity.  
7. **get_event_forecast RPC** — Event forecast tab works if RPC exists; otherwise empty/graceful.

### Automation
8. **WhatsApp/Twilio secure config** — Move credentials out of code for security; does not change behaviour.

---

## 4. Step-by-Step Completion Plan (Production-Safe)

**Principles:** Extend/fix only; no duplicate tables or screens; one change at a time; verify after each step.

### Step 1 — Ensure settings tables exist (financial accuracy)
- **Action:** If `scale_config`, `tax_rules`, `system_config` are not yet in the DB used by the admin app, add a single migration under `admin_app/supabase/migrations/` (e.g. `039_settings_tables.sql`) with `CREATE TABLE IF NOT EXISTS` for each, matching columns used by SettingsRepository (see `fix_missing_schema_from_blueprint.sql` for reference).
- **Verify:** Open Settings → Scale / Tax / Notifications; load and save once; no errors.
- **Rollback:** Migration can be reverted; no app code change.

### Step 2 — Export path UX (reporting)
- **Action:** In ExportService (or callers such as Report Hub), after successful write and before/after Share: show SnackBar with file path (e.g. “Saved to: Documents\<filename>”). Optionally add “Open folder” action (e.g. `Process.run('explorer', [directory])` on Windows) in SnackBar action or a small “Open folder” button where export is triggered.
- **Verify:** Export a report; confirm SnackBar shows path; optionally open folder and see file.
- **Rollback:** Remove SnackBar/path text and “Open folder”; revert to previous behaviour.

### Step 3 — supplier_price_changes table (stock / reporting)
- **Action:** Add migration `040_supplier_price_changes.sql` with `CREATE TABLE IF NOT EXISTS supplier_price_changes` (columns: id, product_id or inventory_item_id, supplier_id, old_price, new_price, percentage_increase, suggested_sell_price, status [e.g. Pending/Applied/Ignored], created_at, etc.) aligned with AnalyticsRepository (e.g. `getPricingSuggestions`, `updatePricingSuggestion`). Add RLS if required.
- **Verify:** Analytics → Dynamic Pricing tab; with no rows, “No supplier price hikes…”; after manual or trigger insert, list and Accept/Ignore work.
- **Rollback:** Migration down or leave table empty; Pricing tab continues to use inventory fallback.

### Step 4 — Audit log write path (staff / compliance)
- **Action:** Introduce a single audit logging helper (e.g. in a core service or AuditRepository) that inserts into `audit_log` (action, staff_id, staff_name, details, severity) using AuthService for staff identity. Call it from a few high-impact actions first (e.g. invoice approve, account status change, batch complete) without changing existing behaviour.
- **Verify:** Perform one of those actions; open Audit Log screen; confirm new row appears.
- **Rollback:** Stop calling the helper; table remains; no schema change.

### Step 5 — get_event_forecast RPC (reporting)
- **Action:** In Supabase SQL editor or a migration, add `CREATE OR REPLACE FUNCTION get_event_forecast(p_event_type TEXT)` returning a table (e.g. product_name, suggested_quantity_kg) based on `event_tags` / `event_sales_history` or placeholder rows. Document in migration header.
- **Verify:** Analytics → Event Forecasting; select event type; forecast list loads (or shows “No forecast data” if logic returns empty).
- **Rollback:** Drop function or return empty set; Event tab already handles empty.

### Step 6 — OCR API key (automation / financial)
- **Action:** Add Google Cloud Vision API key to a secure config (e.g. AdminConfig or env); set in OcrService; document in README. Do not commit key in repo.
- **Verify:** Use invoice/receipt scan flow; OCR calls succeed when key is valid.
- **Rollback:** Remove key from config; scan falls back to manual or fails gracefully.

### Step 7 — WhatsApp/Twilio secure config (automation)
- **Action:** Move Twilio credentials from code to AdminConfig or env; read in WhatsAppService; document where to set values.
- **Verify:** Send test message; log in message_logs.
- **Rollback:** Restore credentials in code temporarily if needed.

### Step 8 — leave_balances (staff, optional)
- **Action:** Only if product owner confirms need: add table or view for leave_balances (e.g. staff_id, year, annual_entitlement, used, balance); add minimal UI (e.g. in Compliance or HR Leave tab) to display balance. Reuse existing leave_requests for “used” if applicable.
- **Verify:** Display shows correct or zero balances.
- **Rollback:** Hide UI and/or drop view/table.

---

## 5. Implementation Order Summary

| Step | Item | Priority (butcher ops) | Risk |
|------|------|------------------------|------|
| 1 | Settings tables (scale_config, tax_rules, system_config) | High (financial) | Low |
| 2 | Export path UX | Medium (reporting) | Low |
| 3 | supplier_price_changes | Medium (stock/reporting) | Low |
| 4 | Audit log writes | Medium (compliance) | Low |
| 5 | get_event_forecast RPC | Low (reporting) | Low |
| 6 | OCR API key | Medium (if manual entry insufficient) | Low |
| 7 | WhatsApp secure config | Low (security hardening) | Low |
| 8 | leave_balances | Optional | Low |

---

## 6. What Not to Do

- Do **not** create a second `business_accounts`, `audit_log`, or `message_logs` table or screen.
- Do **not** add another Supabase.initialize() anywhere except SupabaseService.initialize().
- Do **not** introduce duplicate repositories or screens for Invoices, Ledger, Hunter, Production, or HR; extend existing ones.
- Do **not** use the forbidden Supabase project URL; only the canonical project.

---

## 7. References

- **Audits:** `ADMIN_APP_FULL_AUDIT_ROADMAP.md`, `ADMIN_CONTROL_CENTER_AUDIT.md`, `AUDIT_1_FULL_BLUEPRINT_FEATURE_AUDIT.md`, `SUPABASE_SCHEMA_AUDIT.md`
- **Auth:** `AUTH_ARCHITECTURE.md`
- **Migrations:** `admin_app/supabase/migrations/` (036, 037, 038 already applied for business_accounts, audit_log, message_logs, reorder/leave/timecards, recipes.created_by)
