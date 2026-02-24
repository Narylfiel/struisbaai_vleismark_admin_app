# Deep Persistence Failure Audit

**Date:** 2026-02-22  
**Scope:** All write paths (INSERT, UPDATE, UPSERT, RPC) vs pg_dump schema; silent failures; schema/constraint mismatches.  
**Schema source:** `admin_app/supabase/.temp/pulled_schema.sql`

---

## STEP 1 — Schema validation (summary)

- **Tables in DB (public):** 60+ (account_awol_records, account_transactions, business_accounts, business_settings, compliance_records, invoices, ledger_entries, staff_profiles, leave_requests, timecards, hunter_jobs, etc.).
- **RLS:** Many tables have "Allow all for anon" (USING (true) WITH CHECK (true)) — not blocking writes.
- **Triggers:** validate_timecard (timecards: break_minutes, clock_in/out), check_shrinkage_threshold, post_pos_sale_to_ledger, etc.

---

## STEP 2 & 4 — Write path analysis and runtime failure detection

### 1. Missing database structures

| Issue | Evidence |
|-------|----------|
| **compliance_records: no UNIQUE (staff_id, document_type)** | Code: `compliance_screen.dart` line 428: `upsert(payload, onConflict: 'staff_id,document_type')`. PostgREST/Supabase upsert requires a unique constraint on the conflict columns. Schema has only PRIMARY KEY (id). **Result:** Upsert fails or does not resolve conflict; data may not persist as intended. |

### 2. Write operations targeting wrong schema / column mismatches

| Location | Operation | Problem | Evidence |
|----------|-----------|---------|----------|
| **invoice_repository.dart** (insert, update) | invoices insert/update | 1) Column **total** in DB; code sends **total_amount**. 2) **account_id** NOT NULL in DB; code passes optional accountId (null for supplier-only invoices). | Schema: `invoices` has `total numeric(15,2)`, `account_id uuid NOT NULL`. Code: `'total_amount': totalAmount`, `'account_id': accountId`. **Result:** Insert fails for supplier invoices (null account_id); total amount never persisted (wrong column name). |
| **Invoice.toJson()** | Used by update() | Sends `total_amount`; DB column is `total`. | `invoice.dart` toJson uses `'total_amount': totalAmount`. **Result:** Update appears to succeed but total is not written. |
| **Invoice.fromJson()** | After select | Reads `total_amount`; DB returns `total`. | **Result:** After insert/update, fromJson may get null for totalAmount if API returns `total`. |

### 3. Invalid inserts due to schema mismatch (NOT NULL, CHECK)

| Table | Constraint | Code behaviour | Result |
|-------|------------|----------------|--------|
| **invoices** | account_id NOT NULL | create() passes accountId (optional); supplier invoices use supplier_id only. | Insert fails: null value in column "account_id" violates not-null constraint. |
| **staff_profiles** | pin_hash NOT NULL | Insert only adds pin_hash when _pinController.text.isNotEmpty (staff_list_screen.dart ~2096). | Insert fails for new staff without PIN: null value in column "pin_hash" violates not-null constraint. |
| **leave_requests** | status CHECK ('pending','approved','rejected') — lowercase | staff_list_screen _updateStatus sends 'Approved', 'Rejected' (capitalised). | Update can fail: check constraint leave_requests_status_check violated. |

### 4. Runtime errors preventing commits (silent catch blocks)

Writes wrapped in `try { ... } catch (_) {}` with no rethrow or user feedback — errors are swallowed, UI may show success but nothing is persisted.

| File | Function / area | Failing query / path | Data lost |
|------|------------------|----------------------|-----------|
| **settings_repository.dart** | updateBusinessSettings | business_settings update/upsert | Business tab save; no error shown. |
| **invoice_repository.dart** | _attachSupplierNames / getInvoices path | getInvoices catch (_) returns empty | List may appear empty instead of showing error. |
| **account_detail_screen.dart** | _loadAccount, _loadTransactions, etc. | Multiple catch (_) | Account/transactions/invoices not loaded; user sees empty. |
| **account_list_screen.dart** | load profiles/staff_profiles | catch (_) | Profile list empty; insert may have failed earlier. |
| **staff_list_screen.dart** | _loadTimecards, _loadLeave, etc. | catch (_) | Timecards/leave data not shown. |
| **compliance_screen.dart** | _load | catch (_) | Compliance list empty. |
| **customer_repository.dart** | toggleActive, createAnnouncement | catch (_) | Loyalty/announcement save fails silently. |
| **analytics_repository.dart** | getShrinkageAlerts, getPricingSuggestions, getReorderRecommendations, saveEventTag, getForecastForEvent | catch (_) | Analytics data not saved or loaded; no feedback. |
| **recipe_form_screen.dart** | _loadCategories, _loadInventory | catch (_) | Form load fails silently. |
| **staff_credit_screen.dart** | _load | catch (_) | Credits list empty. |
| **awol_repository.dart** | list | catch (_) | AWOL list empty. |
| **staff_credit_repository.dart** | list | catch (_) | Credit list empty. |
| **product_list_screen.dart** | suppliers/recipes load | catch (_) | Dropdowns empty. |
| **equipment_register_screen.dart** | _loadServiceLog, save | catch (_) | Service log not saved or loaded. |
| **ledger_screen.dart** | (filter/load) | catch (_) | Ledger load fails silently. |
| **production_batch_screen.dart** | (load) | catch (_) | Batch data not loaded. |
| **stock_take_screen.dart** | _load | catch (_) | Stock take data empty. |
| **dashboard_screen.dart** | shrinkage/reorder load | catch (_) | Widgets empty. |
| **job_intake_screen.dart** | _loadServices | catch (_) | Hunter job create may fail after; no message. |
| **job_summary_screen.dart** | _loadBusinessName | catch (_) | Business name not shown. |
| **announcement_screen.dart** | save | catch (_) | Announcement insert fails silently. |
| **audit_log_screen.dart** | (action) | catch (_) | Action fails silently. |

### 5. Code that never actually executes writes (no-op or wrong path)

- **business_settings (Scale/Tax/Notification):** Use upsert with `setting_key`. After migration 040, `setting_key`/`setting_value` exist and unique index on setting_key exists — so upsert works. If 040 not applied, upsert would fail (no conflict target).
- **compliance_records:** Upsert with onConflict: 'staff_id,document_type' — **no unique constraint** in DB, so conflict resolution does not apply; second insert creates duplicate or fails on application logic.

### 6. Tables referenced but missing (already addressed in 040)

- timecard_breaks — created in 040.
- supplier_price_changes — created in 040.

### 7. RLS or permission blocks

- From schema: Policies found are "Allow all for anon" for many tables — **not blocking** inserts/updates.
- No evidence of missing INSERT/UPDATE policies in the dump for the tables the app writes to.

### 8. Data flow breakpoints (where the chain breaks)

| Flow | Breakpoint | Fix |
|------|------------|-----|
| **Invoice create (supplier)** | DB: account_id NOT NULL. Code passes null. | Make account_id nullable or provide placeholder account_id for supplier invoices. |
| **Invoice total** | DB column `total`; code sends `total_amount`. | Send `total` in insert/update; read `total` or `total_amount` in fromJson. |
| **Staff create (no PIN)** | DB: pin_hash NOT NULL. Code omits when PIN empty. | Provide default pin_hash (e.g. empty string or placeholder) when PIN not set; or make column nullable. |
| **Leave request approve/reject** | DB CHECK lowercase; code sends 'Approved'/'Rejected'. | Normalise status to lowercase before update. |
| **Compliance record save** | Upsert onConflict requires UNIQUE (staff_id, document_type). | Add UNIQUE constraint. |

---

## STEP 6 — Failure report summary

1. **Missing database structures:** UNIQUE (staff_id, document_type) on compliance_records.
2. **Wrong schema / column names:** invoices: use `total` not `total_amount`; account_id NOT NULL blocks supplier invoices.
3. **RLS:** No blocking policies identified.
4. **Invalid inserts:** account_id null (invoices), pin_hash null (staff_profiles), status case (leave_requests).
5. **Runtime errors preventing commits:** Many silent `catch (_) {}` blocks; exact failing query is the one inside the try (insert/update/upsert) when schema or constraint fails.
6. **Code that doesn’t persist:** Invoice insert/update use wrong column (total_amount); compliance upsert has no unique target.
7. **Tables not used / referenced but missing:** Covered in BACKEND_AUDIT_REPORT; 040 adds timecard_breaks, supplier_price_changes.

---

## STEP 7 — Autofix plan

### SQL migrations (041_persistence_fixes.sql)

1. **invoices**
   - `ALTER TABLE invoices ALTER COLUMN account_id DROP NOT NULL;`  
     (Allow supplier-only invoices with supplier_id and null account_id.)
   - Add column alias or keep `total`; app will send `total` (see code fix).  
     Optional: `ADD COLUMN total_amount NUMERIC(15,2) GENERATED ALWAYS AS (total) STORED` for backward compatibility — or just fix code to use `total`.

2. **compliance_records**
   - `CREATE UNIQUE INDEX IF NOT EXISTS idx_compliance_records_staff_document ON compliance_records(staff_id, document_type);`  
     (Enables upsert onConflict: 'staff_id,document_type'.)

3. **staff_profiles**
   - `ALTER TABLE staff_profiles ALTER COLUMN pin_hash DROP NOT NULL;`  
     Or keep NOT NULL and fix in code by setting a placeholder when PIN empty (e.g. empty string or 'no-pin').  
     **Recommendation:** Allow NULL so new staff can be created without PIN: `ALTER TABLE staff_profiles ALTER COLUMN pin_hash DROP NOT NULL;`

4. **leave_requests**
   - No schema change. Code will send lowercase status.

### Code patches

1. **invoice_repository.dart**
   - In create() and createFromOcrResult(): send `'total': totalAmount` (not total_amount). If DB has both total and total_amount, send both or only total per schema.
   - In create(): when accountId is null and supplierId is set, pass account_id as null (after migration 041).

2. **invoice.dart (Invoice model)**
   - toJson(): use `'total': totalAmount` for DB write.
   - fromJson(): use `(json['total'] ?? json['total_amount'])` for totalAmount so both column names work.

3. **staff_list_screen.dart (_save)**
   - When widget.staff == null and _pinController.text.isEmpty: set `data['pin_hash'] = ''` or a constant placeholder if DB keeps NOT NULL; or rely on migration to allow NULL and omit pin_hash.

4. **staff_list_screen.dart (_updateStatus for leave)**
   - When calling _updateStatus(id, 'Approved', null) or 'Rejected', pass lowercase: `'approved'`, `'rejected'` so leave_requests_status_check is satisfied.

5. **Silent catch blocks (optional but recommended)**
   - Replace `catch (_) {}` with at least `catch (e, st) { debugPrint('...: $e $st'); }` or show SnackBar for user-facing writes so persistence failures are visible.

---

## References

- Schema: `admin_app/supabase/.temp/pulled_schema.sql`
- Write paths: grep `.insert(`, `.update(`, `.upsert(`, `.rpc(` in `admin_app/lib`
- BACKEND_AUDIT_REPORT.md, migration 040_backend_audit_fixes.sql
