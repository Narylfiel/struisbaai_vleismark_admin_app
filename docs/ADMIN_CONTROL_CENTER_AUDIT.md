# Admin App — Control Center Audit

**Scope:** How the Admin App interacts with POS, Clock-In, Inventory, Production, and Hunter intake.  
**Goal:** Dependency map, shared tables, missing sync logic, and minimal improvements for Admin as source of truth. No new features; focus on system reliability.

---

## 1. Dependency map

```
                    ┌─────────────────────────────────────────────────────────────────┐
                    │                     SUPABASE (single project)                    │
                    └─────────────────────────────────────────────────────────────────┘
                                                      │
     ┌────────────────────────────────────────────────┼────────────────────────────────────────────────┐
     │                                                │                                                │
     ▼                                                ▼                                                ▼
┌─────────────┐                              ┌─────────────────┐                              ┌──────────────┐
│  POS App    │  writes                      │  Admin App      │  reads/writes                │ Clock-In App │  writes
│  (separate) │  transactions,               │  (this repo)    │  config, master data,        │  (separate)  │  timecards,
│             │  transaction_items            │                 │  HR, production, hunter,     │              │  timecard_breaks
│             │  (004)                        │  reads         │  ledger, invoices,          │              │  (optional: leave)
│             │                               │  transactions  │  accounts, compliance        │              │
└──────┬──────┘                               └────────┬────────┘                              └──────┬───────┘
       │                                                │                                                │
       │  reads (intended)                             │  reads                                        │  reads (intended)
       │  inventory_items,                             │  timecards, leave_requests,                   │  staff_profiles
       │  categories, modifier_*,                     │  staff_profiles, transactions,                │  (PIN / identity)
       │  business_settings,                           │  inventory_items, reorder_*,                 │
       │  business_accounts (credit)                   │  shrinkage_alerts, business_accounts       │
       ▼                                                ▼                                                ▼
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  SHARED TABLES (same DB)                                                                                      │
│  • transactions, transaction_items (POS write; Admin read)                                                   │
│  • inventory_items, categories (Admin or POS create; both use — no single owner in this repo)                │
│  • staff_profiles, profiles (identity; Admin HR writes staff; Clock-In/POS read)                             │
│  • timecards, timecard_breaks, leave_requests (Clock-In write; Admin read + leave_requests status update)     │
│  • business_accounts (Admin write; POS read for credit sales)                                                │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  INVENTORY (stock)                    PRODUCTION                          HUNTER INTAKE
  Admin: stock_movements,              Admin: production_batches,          Admin: hunter_services,
  stock_take_*, inventory_items        dryer_batches, recipes,             hunter_jobs, hunter_job_processes
  updates (current_stock);             recipe_ingredients;                 (full CRUD in Admin)
  trigger (003) deducts stock          triggers (017) shrinkage,           No separate “Hunter app”;
  on transaction_items (POS sale).     ledger.                             Admin is source of truth.
  Single source of truth:              Admin is source of truth.
  current_stock (025, product_list).
```

**Summary**

| System         | Direction to Admin | Direction from Admin | Shared tables |
|----------------|-------------------|----------------------|---------------|
| **POS**        | Writes transactions, transaction_items. May read inventory_items, categories, modifiers, business_accounts. | Admin writes inventory_items, categories, modifier_*, business_settings; POS is expected to read. | transactions, transaction_items, inventory_items, categories, business_accounts |
| **Clock-In**   | Writes timecards (and optionally timecard_breaks, leave_requests). Reads staff_profiles. | Admin writes staff_profiles (HR); updates leave_requests (approve/reject). | timecards, timecard_breaks, leave_requests, staff_profiles |
| **Inventory**  | N/A (stock is in same DB). POS/triggers write stock_movements or deduct current_stock. | Admin writes stock_movements, stock_take_*, updates inventory_items; trigger (003) reorder_recommendations. | inventory_items, stock_movements, reorder_recommendations |
| **Production** | N/A. | Admin only: recipes, production_batches, dryer_batches, triggers for shrinkage/ledger. | recipes, production_batches, dryer_batches, shrinkage_alerts |
| **Hunter**     | N/A. | Admin only: hunter_services, hunter_jobs, hunter_job_processes. | hunter_services, hunter_jobs, hunter_job_processes |

---

## 2. Shared tables (who creates, who uses)

Tables that more than one system depends on, and where they are created in this repo vs elsewhere.

| Table | Created in Admin migrations? | Admin role | POS | Clock-In | Notes |
|-------|------------------------------|------------|-----|----------|--------|
| **transactions** | Yes (004) | Read only (dashboard, reports) | Write | — | POS must write; Admin shows “no data” if POS not built (dashboard comment). |
| **transaction_items** | Yes (004) | Read only | Write | — | Links to inventory_item_id. |
| **inventory_items** | No (007, 012, etc. ALTER only) | Read + update (stock, product form) | Read (and possibly write if POS creates products) | — | Single source for stock: current_stock (025, C1). Not created in admin_app. |
| **categories** | No (003 ALTERs) | Read + write (category bloc) | Read (grid tabs) | — | Assumed from POS or shared. |
| **staff_profiles** | No | Read + write (HR Staff list, PIN cache) | Read (login, override) | Read (PIN, identity) | Identity source for Admin (AUTH_ARCHITECTURE.md). Not created in admin_app. |
| **profiles** | No | Referenced in FKs (001, 002, 017…) | — | — | Auth/shared; some FKs point here. |
| **timecards** | Yes (037) | Read only (dashboard, HR, compliance) | — | Write | 037 creates table; Clock-In may populate. |
| **timecard_breaks** | No | Read (compliance_service) | — | Write | Optional; compliance uses if present. |
| **leave_requests** | Yes (037) | Read + update (approve/reject) | — | Write (submit) | 037 creates; Clock-In may create rows. |
| **business_accounts** | Yes (036) | Full CRUD | Read (credit sales) | — | Admin is source of truth. |
| **business_settings** | Yes (001) | Full CRUD | Read (config) | — | Admin is source of truth. |
| **reorder_recommendations** | Yes (037) | Read (dashboard); trigger (003) writes | — | — | Trigger depends on inventory_items. |
| **ledger_entries** | Yes (002, 006) | Read + write (manual, invoice, etc.) | — | — | Trigger (017, 019) posts from POS sales. |

**Tables Admin creates and fully owns (source of truth in this repo)**  
business_settings, business_accounts, hunter_services, hunter_jobs, hunter_job_processes, recipes, production_batches, dryer_batches, stock_movements, invoices, ledger_entries, chart_of_accounts, shrinkage_alerts, leave_requests, timecards (schema), reorder_recommendations, audit_log, message_logs, compliance_records, staff_awol_records, equipment_register, etc.

**Tables Admin does NOT create (assumed from POS / Clock-In / shared)**  
inventory_items, categories, staff_profiles, profiles, timecard_breaks (optional).

---

## 3. Missing synchronization logic

- **No formal sync contracts**  
  Admin assumes POS writes to `transactions` / `transaction_items` and Clock-In to `timecards` / `leave_requests`. There is no documented schema contract or versioning; schema is aligned via migrations (004, 037) and blueprint docs.

- **inventory_items / categories ownership**  
  Admin ALTERs and uses them; it does not CREATE. If POS and Admin both run, who creates these first is undefined. Risk: FK or missing-table errors if one app is deployed without the other.

- **staff_profiles vs profiles**  
  Admin uses staff_profiles for auth and HR; some FKs still reference profiles(id). Two identity tables with no documented sync or single source; AuthService and AUTH_ARCHITECTURE.md standardize on staff_profiles for identity only.

- **No conflict resolution**  
  Shared tables have no version/updated_at or “last writer wins” policy documented. Admin does not implement offline queues or sync flags for POS/Clock-In.

- **Ledger from POS**  
  Trigger (017/019) posts ledger_entries from transactions. If POS writes transactions with different column semantics, ledger could be wrong; no validation or reconciliation flow in Admin.

- **Leave workflow**  
  Admin updates leave_requests (status, review_notes). Clock-In is assumed to create and display them; no API or event contract.

---

## 4. Minimal improvements (Admin as source of truth, reliability only)

No new features; only clarity and defensive behavior.

1. **Document shared-table contract**  
   In `docs/` (or migration headers), list:
   - Tables Admin **creates and owns** (e.g. business_accounts, hunter_*, recipes, production_*, timecards, leave_requests schema).
   - Tables Admin **reads only** (e.g. transactions, transaction_items) and which system is expected to write (POS).
   - Tables **shared with no single owner in this repo** (e.g. inventory_items, categories, staff_profiles) and that deployment must ensure they exist (created by POS, shared migration, or manual).

2. **Graceful degradation (already partially done)**  
   - Dashboard: already catches errors and shows empty for missing/empty reorder, leave, timecards (037 + fallbacks).  
   - Keep the same pattern elsewhere: any screen that reads from POS- or Clock-In-owned tables should catch errors and show empty/offline message instead of crashing.

3. **Single identity source (done)**  
   Auth and identity use staff_profiles; documented in AUTH_ARCHITECTURE.md. Do not reintroduce profiles for auth; keep FKs that reference profiles only where schema already requires it (e.g. payroll_entries).

4. **Hunter / Production / Accounts**  
   Already Admin-only. No change beyond ensuring all writes use AuthService for created_by/recorded_by (already done for recipes; same pattern elsewhere).

5. **Avoid destructive migrations**  
   Do not drop or rename columns that POS or Clock-In might use. Add columns with ADD COLUMN IF NOT EXISTS; document in migration comments which app uses which columns.

6. **Optional: shared schema checklist**  
   One markdown file listing “Tables that must exist before Admin runs” (e.g. staff_profiles, inventory_items if production/stock used, categories if product list used) so deployment order is explicit. No code change.

---

## 5. Summary

| Area | Shared tables | Missing sync / risk | Suggested (minimal) |
|------|----------------|---------------------|----------------------|
| **POS** | transactions, transaction_items, inventory_items, categories, business_accounts | Admin reads only; no contract; inventory_items not created here | Document read-only and “POS writes”; keep dashboard safe when no data |
| **Clock-In** | timecards, timecard_breaks, leave_requests, staff_profiles | Admin reads timecards/leave; updates leave status; no contract | Document “Clock-In writes timecards”; leave_requests Admin updates status only |
| **Inventory** | inventory_items, stock_movements, reorder_recommendations | current_stock single source (025); reorder trigger (003) | No change; ensure no duplicate stock logic |
| **Production** | recipes, production_batches, dryer_batches | Admin only | No change |
| **Hunter** | hunter_services, hunter_jobs | Admin only | No change |

Admin is already the control center for configuration, HR, production, hunter, ledger, and accounts. Making it “source of truth” in practice means: (1) documenting which tables it owns vs reads vs shares, (2) keeping graceful degradation for shared/read-only tables, and (3) not adding destructive or duplicate logic—no new features required for reliability.
