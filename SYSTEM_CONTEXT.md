# BUTCHERY OS — SYSTEM CONTEXT
## Read this before touching any code in any app
**Last verified:** 2026-03-18
**Verified by:** Direct code reading + live Supabase schema queries
**Project root:** C:\Users\grize\ButcheryOS

---

## THE SYSTEM AT A GLANCE

Four Flutter apps share one Supabase database. They are not independent.
Every change in one app can affect what another app reads or displays.
Never audit, fix, or change any single app without understanding how it
connects to the others.

```
         ADMIN APP (Windows Desktop)
         The control centre — creates all products, staff,
         prices, recipes, accounts. Everything else reads from it.
                    │
        ┌───────────┼───────────┐
        ▼           ▼           ▼
    POS APP     CLOCK-IN    LOYALTY APP
  (sells meat)  (HR time)   (customers)
        │           │           │
        └───────────┴───────────┘
                    │
              SUPABASE DB
         nasfakcqzmpfcpqttmti.supabase.co
```

---

## THE MOST IMPORTANT RULE: TWO STAFF TABLES

This is the single most misunderstood thing about this system.
There are TWO staff tables. This is **intentional architecture**, not a bug.

### `profiles` — Operational identity
- Who performed an action in the business
- Used for: transactions, audit log, stock movements, production,
  accounts, announcements, equipment, invoices
- POS authenticates against this table
- FK pattern: `transactions.staff_id → profiles.id`

### `staff_profiles` — HR/employment record
- The employment record for payroll, timekeeping, compliance
- Used for: timecards, payroll, leave requests, compliance documents,
  AWOL records, staff credits
- Admin App and Clock-In App authenticate against this table
- FK pattern: `timecards.staff_id → staff_profiles.id`

### The critical fact
`profiles.id = staff_profiles.id` for every real staff member.
**Same UUID. Different table. Different domain.**

When Admin saves a staff member, it writes to BOTH tables simultaneously.
The PIN hash is kept in sync across both tables.
One PIN works in all apps because both tables have the same hash.

### Join rules — never mix these
```
✅ CORRECT:
timecards         → JOIN staff_profiles  (HR domain)
leave_requests    → JOIN staff_profiles  (HR domain)
payroll_entries   → JOIN staff_profiles  (HR domain)
compliance_records→ JOIN staff_profiles  (HR domain)
transactions      → JOIN profiles        (operational domain)
stock_movements   → JOIN profiles        (operational domain)
audit_log         → JOIN profiles        (operational domain)
carcass_breakdown → JOIN profiles        (operational domain)
account_transactions→JOIN profiles      (operational domain)

❌ WRONG (will return nulls or wrong names):
timecards         → JOIN profiles
transactions      → JOIN staff_profiles
```

---

## APP IDENTITIES

### App 1 — POS App (`pos_app`)
- **Platform:** Windows Desktop (Flutter)
- **Users:** Cashiers, Manager, Owner
- **Auth:** SHA-256 PIN → `profiles` table
- **Offline:** Isar-first. Writes to Isar immediately, then tries Supabase.
  SyncService retries failed Supabase writes on reconnect.
- **Owns (writes):** transactions, transaction_items, till_sessions,
  stock_movements (sale type), audit_log (voids/overrides),
  account_transactions (account payments), suspended_transactions,
  petty_cash_movements, loyalty_customers (new signups at till),
  split_payments, staff_credit (meat purchases via staff account)
- **Reads:** inventory_items (via Isar cache), profiles (auth),
  loyalty_customers (lookup), business_accounts, promotions,
  customer_invoices

### App 2 — Admin App (`admin_app` inside `struisbaai_vleismark_admin_app`)
- **Platform:** Windows Desktop (Flutter)
- **Users:** Owner (full access), Manager (limited)
- **Auth:** SHA-256 PIN → `staff_profiles` table
- **Offline:** Isar for some production workflows
- **Owns (writes):** inventory_items, categories, suppliers,
  staff_profiles + profiles (both on staff save), business_accounts,
  invoices, invoice_line_items, ledger_entries, chart_of_accounts,
  equipment_register, purchase_sale_agreement, recipes,
  recipe_ingredients, production_batches, production_batch_ingredients,
  production_batch_outputs, dryer_batches, dryer_batch_ingredients,
  carcass_intakes, carcass_breakdown_sessions, carcass_cuts,
  hunter_jobs, hunter_job_processes, hunter_process_materials,
  hunter_services, leave_requests (admin-created), payroll_periods,
  payroll_entries, staff_credit (admin-created), staff_awol_records,
  compliance_records, announcements, customer_recipes, promotions,
  business_settings, shrinkage_alerts, reorder_recommendations,
  event_tags, stock_take_sessions, stock_take_entries
- **Reads:** transactions, transaction_items, till_sessions (from POS),
  timecards, timecard_breaks (from Clock-In),
  staff_requests (advances from Clock-In),
  loyalty_customers, loyalty_points_log (from Loyalty + POS)

### App 3 — Clock-In App (`clock_in_app`)
- **Platform:** Android Mobile (kiosk mounted at shop entrance)
- **Users:** All staff
- **Auth:** SHA-256 PIN → `staff_profiles` table
- **Offline:** shared_preferences queue. Actions timestamped and
  replayed in order when connectivity restores.
- **Owns (writes):** timecards, timecard_breaks, staff_requests
  (both leave and advance requests)
- **Reads:** staff_profiles (auth + display), timecards (own record),
  timecard_breaks (own breaks), leave_balances, staff_credit
  (advance eligibility check)

### App 4 — Loyalty App (`loyalty_app_sbvm`)
- **Platform:** iOS + Android
- **Users:** Retail customers (not staff)
- **Auth:** Supabase Auth — phone OTP or email/Google OAuth
- **Offline:** None implemented
- **Owns (writes):** loyalty_customers (own record via auth_uid link),
  custom_reward_orders (via reserve_boerewors_slot RPC only)
- **Reads:** loyalty_points_log, promotions, announcements,
  customer_recipes, custom_reward_campaigns,
  custom_reward_ingredients, loyalty_notifications

---

## CRITICAL CROSS-APP CONTRACTS

These are the points where one app writes data that another reads.
A mismatch here causes silent data loss. Never change these without
checking both sides.

### Contract 1 — Staff credentials
```
Admin writes → profiles.pin_hash + staff_profiles.pin_hash (both)
POS reads   → profiles.pin_hash
Admin reads → staff_profiles.pin_hash
Clock-In    → staff_profiles.pin_hash
Status: ✅ Verified working — all staff have hashes in both tables
```

### Contract 2 — Sales data for reporting
```
POS writes  → transactions (cost_amount, total_amount, vat_amount)
Admin reads → transactions for dashboard, P&L, margin reports
Key field:  → cost_amount = sum of (costPrice × quantity) per item
Note:       → cost_amount = R0 until supplier invoices are entered
              and cost_price is set on inventory_items. This is
              EXPECTED behaviour, not a bug.
Status: ✅ Code correct — needs cost data entry to show real margins
```

### Contract 3 — Stock levels
```
POS writes  → stock_movements (type='sale') after online Supabase insert
Admin writes→ stock_movements (type='waste','breakdown','adjustment')
DB trigger  → stock_movements INSERT → updates inventory_items stock
Note:       → Offline POS sales do NOT create stock_movements
              until sync. Stock levels lag during outages.
Status: ⚠️ Works online, gap for offline sales
```

### Contract 4 — Loyalty points
```
POS calls   → increment_loyalty RPC (customer_id, points_to_add,
              spend_to_add, transaction_id)
RPC writes  → loyalty_points_log + updates loyalty_customers
Loyalty reads→ loyalty_points_log for history screen
Note:       → Offline POS sales do NOT call RPC until sync
Status: ⚠️ Works online, gap for offline sales
```

### Contract 5 — Leave requests
```
Clock-In writes → staff_requests (request_type = leave type)
Admin reads     → leave_requests (DIFFERENT TABLE)
Status: 🔴 GAP — Clock-In leave requests never reach Admin
Fix needed:     → Admin leave tab must also read staff_requests
                  where request_type is a leave type
```

### Contract 6 — Salary advances
```
Clock-In writes → staff_requests (request_type = advance)
Admin reads     → staff_requests (advance type)
Status: ✅ Verified working — same table, chain complete
```

### Contract 7 — Timecard hours for payroll
```
Clock-In writes → timecards (clock_out, break_minutes, status)
                  total_hours NOT in update payload
DB trigger OR   → total_hours calculated automatically
Admin reads     → timecards.total_hours for payroll calculation
Status: ⚠️ total_hours in payload missing from clockOut()
         Verify if DB trigger calculates it instead
```

### Contract 8 — Announcements and promotions
```
Admin writes  → announcements (content, target_audience, is_active)
Loyalty reads → announcements
Note:         → Column names: 'content' (not 'body'),
                'target_audience' (not 'target_tiers'),
                'is_active' (not 'active')
Status: ✅ Loyalty app uses correct column names
```

---

## CONFIRMED TABLE NAME FACTS
*(Previous audits got some of these wrong — these are verified)*

| What code uses | Status | Notes |
|---|---|---|
| `staff_awol_records` | ✅ Correct | Admin uses this. Previous audits wrongly said it used `awol_records` |
| `ledger_entries` | ✅ Correct | Admin uses this. Previous audits wrongly said `journal_entries` |
| `chart_of_accounts` | ✅ Correct | Admin uses this. Previous audits wrongly said `ledger_accounts` |
| `carcass_intakes` | ✅ Correct | Admin intake screen uses this |
| `carcass_cuts` | ✅ Correct | Admin breakdown uses this for individual cuts |
| `carcass_breakdown_sessions` | ✅ Correct | Admin uses this for session header |
| `staff_requests` | ✅ Correct | Clock-In uses for both leave AND advances |
| `leave_requests` | ✅ Correct | Admin uses for admin-created leave |
| `production_batches` | ✅ Correct | |
| `production_batch_ingredients` | ✅ Correct | |
| `production_batch_outputs` | ✅ Correct | |
| `stock_take_sessions` | ✅ Correct | Admin uses this |
| `stock_take_entries` | ✅ Correct | Admin uses this |

---

## CONFIRMED FIELD NAME FACTS

### `announcements` table
| Column in DB | Used in code | Notes |
|---|---|---|
| `content` | ✅ Admin + Loyalty use `content` | NOT `body` |
| `target_audience` | ✅ Admin + Loyalty use `target_audience` | NOT `target_tiers` |
| `is_active` | ✅ Admin uses `is_active` | NOT `active` |

### `loyalty_customers` table
| Column in DB | Used in code | Notes |
|---|---|---|
| `points_balance` | ✅ Loyalty + POS use `points_balance` | NOT `total_points` |
| `loyalty_tier` | ✅ Loyalty + POS use `loyalty_tier` | NOT `tier` |

### `ledger_entries` table
Uses `account_code` (text) as the account reference — NOT `account_id` FK.
This is intentional — the ledger works by account code string matching,
not by FK join to chart_of_accounts.

---

## WHAT EACH APP DOES NOT DO

### POS does NOT:
- Manage inventory (no create/edit products)
- Manage staff profiles
- Approve leave or advances
- Generate reports
- Access bookkeeping
- Run payroll

### Admin does NOT:
- Process sales at the till
- Clock staff in or out
- Display the customer loyalty card
- Handle customer-facing features

### Clock-In does NOT:
- Process sales
- Edit timecards (read-only after submission)
- Approve its own leave requests
- Generate payslips (reads PDF from Storage, doesn't generate)

### Loyalty App does NOT:
- Interact with staff tables
- Access admin functions
- Process payments directly (uses PayFast via Edge Function)
- Write to loyalty_points_log directly (POS writes via RPC)

---

## KNOWN ISSUES (as of 2026-03-18)

### 🔴 Confirmed bugs — fix in progress
1. **Leave request gap** — Clock-In leave requests go to `staff_requests`,
   Admin reads `leave_requests`. Admin leave tab must also read
   `staff_requests` for leave-type entries.

2. **total_hours not in clockOut payload** — Calculated correctly but
   not sent to Supabase. Verify if DB trigger handles it before fixing.

3. **Offline sales miss loyalty + stock** — sync_service only syncs
   transactions and transaction_items. Loyalty RPC and stock_movements
   are skipped for offline sales.

### ✅ Not bugs — context needed
- **cost_amount = R0** — No supplier invoices entered yet.
  Once cost_price is set on inventory_items via invoices,
  margin reporting works automatically.

- **leave_balances shows 0** — No trigger or writer confirmed yet.
  Needs investigation — may need DB trigger on leave_requests.

---

## RULES FOR AI TOOLS WORKING ON THIS PROJECT

1. **Read this file first.** Every time. No exceptions.

2. **Never assume a table name is wrong** without running a schema
   query first. Multiple previous audits flagged correct table names
   as bugs. Always verify with:
   ```sql
   SELECT table_name FROM information_schema.tables
   WHERE table_schema = 'public' AND table_name = 'your_table_name';
   ```

3. **Never assume a field name is wrong** without checking:
   ```sql
   SELECT column_name FROM information_schema.columns
   WHERE table_schema = 'public' AND table_name = 'your_table';
   ```

4. **One fix at a time.** Show the change before applying it.
   Do not bundle multiple fixes in one prompt.

5. **The dual-table staff identity is intentional.**
   Do not suggest merging `profiles` and `staff_profiles`.
   Do not change which table an app authenticates against.

6. **If something looks broken, check the data first.**
   cost_amount = R0 looks like a bug — it's missing data.
   total_hours appears missing — a DB trigger may handle it.
   Always verify before fixing.

7. **Cross-app changes need both sides read first.**
   If fixing how Clock-In writes data, read how Admin reads it first.
   If fixing how POS reads products, read how Admin writes them first.
