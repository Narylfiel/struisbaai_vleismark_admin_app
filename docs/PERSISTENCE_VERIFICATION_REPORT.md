# Full Persistence Verification Report

**Date:** 2026-02-22  
**Scope:** Entire admin app — schema `admin_app/supabase/.temp/pulled_schema.sql`, migrations through 041, full codebase.  
**Goal:** Ensure every database write path actually persists data.

---

## STEP 1 — Write map

Scan result: all insert/update/upsert/rpc write paths, with table, operation, file, function, and payload fields. Schema column existence verified against `pulled_schema.sql` + migrations 040–041.

| Table | Operation | File | Function / context | Payload fields sent | Schema match |
|-------|-----------|------|--------------------|---------------------|--------------|
| business_settings | update | settings_repository.dart | saveBusinessSettings | id, business_name, address, vat_number, phone, working_hours_* | ✅ (040: setting_key, setting_value exist) |
| business_settings | upsert | settings_repository.dart | saveBusinessSettings | setting_key, setting_value | ✅ onConflict: setting_key; UNIQUE in 040 |
| business_settings | upsert | scale_settings_screen.dart, tax_settings_screen.dart, pty_conversion_screen.dart, notification_settings_screen.dart | _save / callbacks | setting_key, setting_value (or id) | ✅ |
| scale_config | insert/update | settings_repository.dart | updateScaleConfig | primary_mode, plu_digits, id | ✅ |
| tax_rules | insert | settings_repository.dart | createTaxRule | name, percentage | ✅ |
| system_config | update | settings_repository.dart | toggleNotification | is_active, id | ✅ (eq id) |
| loyalty_customers | update | customer_repository.dart | updateCustomerStatus | **is_active** | ⚠️ **Schema has `active`, not `is_active`** — write may fail or no-op |
| announcements | insert | customer_repository.dart | createAnnouncement | title, **body**, **target_tier**, created_at | ❌ **Schema: `content` (not body), `created_by` NOT NULL missing, `target_audience` (not target_tier)** |
| customer_announcements | insert | announcement_screen.dart | — | title, body, channel, status, … | ✅ |
| chart_of_accounts | insert/update | chart_of_accounts_screen.dart | _save, _import, _toggleActive | code, name, account_type, parent_id, is_active | ✅ |
| equipment_register | update/insert | equipment_register_screen.dart | _addServiceLog, form save | service_log; or full row (asset_number, description, …) | ✅ |
| invoices | insert | invoice_repository.dart | create, createFromMap | invoice_number, account_id?, supplier_id, invoice_date, due_date, subtotal, tax_amount, **total**, status, notes, created_by | ✅ (041: account_id nullable) |
| invoices | update | invoice_repository.dart | update, setStatus | toJson() / status | ✅ (toJson uses `total`) |
| invoice_line_items | insert | invoice_repository.dart | create, createFromMap, saveLineItems | invoice_id, description, quantity, unit_price, sort_order | ✅ |
| ledger_entries | insert | ledger_repository.dart | createEntry, createDoubleEntry | entry_date, account_code, account_name, debit, credit, description, reference_*, source, recorded_by, metadata | ✅ |
| dryer_batches | insert/update | dryer_batch_repository.dart | create, update, cancel | batch_number, status, dates, weights, … | ✅ |
| dryer_batch_ingredients | insert | dryer_batch_repository.dart | — | batch_id, inventory_item_id, quantity_used | ✅ |
| production_batches | insert/update | production_batch_repository.dart | create, update, cancel | batch_date, recipe_id, status, … | ✅ |
| production_batch_ingredients | insert/update | production_batch_repository.dart | — | batch_id, ingredient_id, planned_quantity, actual_quantity | ✅ |
| production_batch_outputs | insert | production_batch_repository.dart | — | batch_id, inventory_item_id, qty_produced, unit | ✅ |
| inventory_items | insert/update | inventory_repository.dart, recipe_form_screen.dart, product_list_screen.dart | upsert product, adjust stock, toggle active | plu_code, name, current_stock, … | ✅ |
| stock_movements | insert | inventory_repository.dart | recordMovement, adjustStock | item_id, quantity, movement_type, … | ✅ |
| stock_take_sessions | insert/update | stock_take_repository.dart | createSession, setSessionStatus, approveSession | status, started_at, started_by, approved_at, approved_by | ✅ |
| stock_take_entries | insert/update | stock_take_repository.dart | saveEntry | session_id, item_id, location_id, expected_quantity, actual_quantity, counted_by, device_id | ✅ UNIQUE(session_id, item_id, location_id) |
| categories | insert/update | category_bloc.dart | create, update, reorder | name, color_code, sort_order, is_active | ✅ (categories_name_key UNIQUE) |
| modifier_groups | insert/update | modifier_repository.dart | create, update | name, required, sort_order, … | ✅ |
| modifier_items | insert/update | modifier_repository.dart | create, update | modifier_group_id, name, price_adjustment, … | ✅ |
| suppliers | insert/update | supplier_repository.dart, supplier_list_screen.dart | create, update | name, contact_name, phone, … | ✅ |
| recipes | insert/update | recipe_repository.dart | create, update | name, category, ingredients, … | ✅ |
| recipe_ingredients | insert/update | recipe_repository.dart | create, update | recipe_id, ingredient_name, quantity, unit, … | ✅ |
| hunter_jobs | insert/update | job_intake_screen.dart, job_list_screen.dart, job_process_screen.dart, job_summary_screen.dart | create job, update status/paid | job_date, hunter_name, species, status, paid, … | ✅ (status CHECK includes 'Completed') |
| hunter_job_processes | insert | job_list_screen.dart | — | job_id, process_type, … | ✅ |
| hunter_services | insert/update | job_list_screen.dart | — | name, description, base_price, … | ✅ (hunter_services_name_key UNIQUE) |
| yield_templates | insert/update | carcass_intake_screen.dart | — | name, species, cuts, … | ✅ |
| carcass_intakes | insert/update | carcass_intake_screen.dart | — | intake_date, species, status, job_type, … | ✅ |
| carcass_cuts | insert | carcass_intake_screen.dart | — | carcass_id, cut_name, weight, … | ✅ |
| shrinkage_alerts | update | analytics_repository.dart | updateShrinkageStatus | status, resolved | ✅ |
| supplier_price_changes | update | analytics_repository.dart | updatePricingSuggestion | status | ✅ |
| event_tags | insert | analytics_repository.dart | saveEventTag | event_name, event_date, event_type | ✅ (040: event_type added) |
| leave_requests | update | staff_list_screen.dart | _updateStatus | status (lowercase), review_notes, reviewed_at | ✅ (CHECK: pending, approved, rejected) |
| staff_profiles | insert/update | staff_list_screen.dart | — | full_name, role, pay_frequency, **pin_hash** (optional) | ✅ (041: pin_hash nullable) |
| compliance_records | upsert | compliance_screen.dart | — | staff_id, document_type, expiry_date, file_url, …; onConflict: staff_id,document_type | ✅ (041: UNIQUE idx) |
| staff_credit | insert/update | staff_credit_repository.dart | create, update | staff_id, credit_amount, reason, granted_by, … | ✅ |
| staff_awol_records | insert/update | awol_repository.dart | create, resolve | staff_id, awol_date, resolution, recorded_by, … | ✅ |
| business_accounts | insert/update | account_list_screen.dart, account_detail_screen.dart | _suspend, _saveAutoSuspend, save account, add transaction | suspended, auto_suspend, balance, … | ✅ |
| account_transactions | insert | account_list_screen.dart, account_detail_screen.dart | — | account_id, transaction_type, amount, … | ✅ |
| purchase_orders | insert | shrinkage_screen.dart | — | po_number, supplier_id, status, … | ✅ |
| purchase_order_lines | insert | shrinkage_screen.dart | — | purchase_order_id, inventory_item_id, quantity, … | ✅ |
| message_logs | insert | whatsapp_service.dart | _logMessage | message_sid, to_number, message_content, status, error_message, sent_at | ✅ |
| calculate_nightly_mass_balance | rpc | analytics_repository.dart | — | (none) | N/A |
| get_event_forecast | rpc | analytics_repository.dart | — | p_event_type | N/A (read) |
| calculate_supplier_spend | rpc | report_repository.dart | — | params | N/A (read) |

**Summary:** Two write paths have schema/column mismatches (loyalty_customers column name, announcements NOT NULL + column names). All other mapped writes align with schema (including 040/041).

---

## STEP 2 — Silent write failures (catch blocks)

Search pattern: `catch (_) {}` and `catch (e) {}` where the try block contains a database **write** (insert/update/upsert). These hide persistence failures.

| File | Location | Write before catch | Severity |
|------|----------|--------------------|----------|
| **equipment_register_screen.dart** | ~99–101 | `await _client.from('equipment_register').update({'service_log': log}).eq('id', id)` | **CRITICAL: hidden persistence failure** — service log update can fail silently; user sees no error. |
| **settings_repository.dart** | ~95–97 | `await _client.from('business_settings').update(payload)...` and `upsert(...)` in same try | **CRITICAL: hidden persistence failure** — business/scale/tax/notification settings save can fail with no feedback. |
| **analytics_repository.dart** | ~282–288 | `await _client.from('event_tags').insert({...})` | **CRITICAL: hidden persistence failure** — event tag save can fail silently. |
| **customer_repository.dart** | ~58–66 | `await _client.from('announcements').insert({...})` | **CRITICAL: hidden persistence failure** — also broken by schema (see Step 1). |
| **customer_repository.dart** | ~34–37 | `await _client.from('loyalty_customers').update({'is_active': isActive})` | **CRITICAL: hidden persistence failure** — wrong column name and error swallowed. |

**Other catch blocks** that do **not** wrap writes (reads only, or non-DB):  
staff_credit_screen.dart (load staff list), ledger_screen.dart (Share), audit_repository.dart (getActionTypes), dryer_batch_repository (batch number gen), dashboard_screen (shrinkage/reorder/overdue/leave reads), invoice_repository _attachSupplierNames (read).  
These are not flagged as persistence-critical but could be improved (e.g. debugPrint) for diagnostics.

---

## STEP 3 — Logical write compatibility

For each written table: NOT NULL columns, DEFAULTs, CHECK constraints, triggers, FKs vs payload.

### Issues found

1. **invoices**  
   - **account_id:** NOT NULL in pulled schema; **041** makes it nullable. Post-041: supplier-only invoices (no account_id) are valid. Code sends `account_id` only when present; createFromMap omits it. **OK.**

2. **leave_requests**  
   - CHECK: `status IN ('pending','approved','rejected')`. Code uses lowercase (`statusLower`). **OK.**

3. **staff_profiles**  
   - **pin_hash:** Pulled schema shows NOT NULL; **041** makes it nullable. New staff insert without PIN is valid post-041. **OK.**

4. **compliance_records**  
   - **041** adds UNIQUE(staff_id, document_type). Upsert uses `onConflict: 'staff_id,document_type'`. **OK.**

5. **loyalty_customers**  
   - Schema column is **`active`**, not `is_active`. Code sends `is_active`. **MISMATCH** — update targets non-existent column or no-op; persistence fails or is wrong.

6. **announcements**  
   - Schema: **content** (NOT NULL), **created_by** (NOT NULL), **target_audience** (CHECK: 'all','customers','staff').  
   - Code sends: **body** (no `content`), **target_tier** (not `target_audience`), no **created_by**.  
   - **MISMATCH** — insert will fail (NOT NULL violation and/or unknown columns).

7. **business_settings**  
   - Upsert uses `setting_key`; 040 adds UNIQUE(setting_key) WHERE setting_key IS NOT NULL. **OK.**

8. **event_tags**  
   - 040 adds **event_type**. Code sends event_name, event_date, event_type. **OK.**

9. **invoice_line_items**  
   - description, quantity, unit_price NOT NULL; code sends all. **OK.**

10. **stock_take_entries**  
    - UNIQUE(session_id, item_id, location_id); saveEntry uses select-then-insert/update. **OK.**

No other NOT NULL/CHECK/trigger/FK conflicts identified for the mapped writes.

---

## STEP 4 — Upsert safety

All upserts checked for a matching UNIQUE or PRIMARY KEY.

| Table | Upsert site | Conflict columns | Schema constraint | Verdict |
|-------|-------------|------------------|-------------------|---------|
| business_settings | settings_repository, scale/tax/pty/notification screens | setting_key | UNIQUE(setting_key) WHERE setting_key IS NOT NULL (040) | ✅ Safe |
| compliance_records | compliance_screen.dart | staff_id, document_type | UNIQUE(staff_id, document_type) (041) | ✅ Safe |

No upserts without a matching UNIQUE or PK found.

---

## STEP 5 — Writes not awaited

Search: `.insert(`, `.update(`, `.upsert(` without `await` on the same chain (e.g. `await client.from(...).insert(...)`).

**Result:** All write calls are awaited. The pattern used is `await _client.from('table').insert(...)` (or update/upsert); the `await` applies to the full chain. No fire-and-forget writes detected.

---

## STEP 6 — Persistence health score and verdict

### 1. Database compatibility  
**Score: 7/10**  
- Most tables and columns align with schema (including 040/041).  
- **Deductions:** loyalty_customers uses `is_active` (schema has `active`); announcements insert uses wrong columns and omits required `created_by`.

### 2. Write safety  
**Score: 8/10**  
- Upserts have correct UNIQUE/PK.  
- Invoice, leave, compliance, staff_profiles fixed in 040/041.  
- **Deduction:** Two write paths (loyalty_customers, announcements) are broken or unsafe.

### 3. Error visibility  
**Score: 4/10**  
- **Critical:** Five write paths hide failures behind `catch (_) {}` or `catch (e) {}` (equipment_register service log, business_settings, event_tags, announcements, loyalty_customers).  
- Users and developers get no feedback when these writes fail.

### 4. Schema alignment  
**Score: 8/10**  
- Migrations 040 and 041 applied; schema and code largely aligned.  
- **Deduction:** Column name and NOT NULL mismatches for loyalty_customers and announcements.

### 5. Future risk  
**Score: 6/10**  
- New features that follow the same “silent catch” pattern will continue to hide persistence failures.  
- Risk of further column renames or NOT NULL additions without code updates.

---

## Final verdict: **AT RISK**

Persistence is **not BROKEN** for the majority of flows: invoices, compliance, leave, staff profiles, settings (except error visibility), ledger, inventory, production, hunter, accounts, and RPCs are schema-aligned and use correct constraints after 040/041.

**Remaining issues:**

1. **Broken or unsafe writes**  
   - **loyalty_customers:** Code updates `is_active`; schema has `active`. Fix: use column `active` in the update payload.  
   - **announcements:** Code sends `body`, `target_tier`, and omits `created_by`. Fix: send `content` (not body), `target_audience` (not target_tier), and required `created_by`.

2. **Hidden persistence failures**  
   - Replace silent `catch (_) {}` / `catch (e) {}` with at least `debugPrint(e)` and, where appropriate, user-visible feedback (e.g. SnackBar) for:  
     - equipment_register_screen.dart (service log),  
     - settings_repository.dart (business_settings),  
     - analytics_repository.dart (saveEventTag),  
     - customer_repository.dart (createAnnouncement, updateCustomerStatus).

After fixing the two schema mismatches and improving error visibility for these five paths, the verdict would move to **SAFE**.

---

## Recommended next steps

1. **Fix loyalty_customers:** In `customer_repository.dart` `updateCustomerStatus`, use `'active': isActive` instead of `'is_active': isActive`, and surface errors (no silent catch).  
2. **Fix announcements insert:** In `customer_repository.dart` `createAnnouncement`, use `content: body`, `target_audience: targetTier` (ensure value in allowed set), add `created_by: <current user id>`, and surface errors.  
3. **Improve error visibility:** In equipment_register_screen.dart, settings_repository.dart (saveBusinessSettings), analytics_repository.dart (saveEventTag), and customer_repository.dart (createAnnouncement, updateCustomerStatus), replace silent catch with `debugPrint` and user-facing SnackBar/error state where appropriate.
