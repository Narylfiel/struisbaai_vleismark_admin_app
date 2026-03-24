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

---

## HR LEAVE SYSTEM — IMPLEMENTED 2026-03-19

### How it works

Four leave types exist. Two are staff-initiated, two are admin-recorded.

| Type | Applied by | Approved/Set by | Staff sees |
|---|---|---|---|
| annual | Staff via Clock-In | Admin approves | Balance + history |
| unpaid | Staff via Clock-In | Admin approves | History |
| sick | Nobody | Admin records directly | History (read only) |
| family_responsibility | Nobody | Admin records directly | History (read only) |

### Leave Rules (South African Butchery - Accrual Based)

**Annual Leave:**
- Accrues at 1 day per 17 actual working days
- "Actual working day" = a day with a timecard clock_in record
- Leave days taken do NOT count toward the 17-day accrual
- Sick days taken do NOT count toward the 17-day accrual
- Unpaid days do NOT count toward the 17-day accrual
- Public holidays do NOT count toward the 17-day accrual
- Only clock-in records in timecards table count
- Balance = (days_worked ÷ 17) - days_taken (annual only)
- Balance floors at 0 — never goes negative in display

**Sick Leave:**
- 10 days per calendar year
- 30 days per 36-month rolling cycle (BCEA minimum)
- NOT accrual-based — full entitlement per cycle
- Balance = entitlement - sick days taken in period

**Family Responsibility Leave:**
- 3 days per calendar year
- NOT accrual-based — full entitlement per year
- Balance = 3 - family days taken in calendar year

**Unpaid Leave:**
- No balance tracking — just recorded in leave_history
- Does not affect any balance

### Data flow — staff-initiated leave (annual/unpaid)
1. Staff submits request → staff_requests (request_type='leave')
2. Admin sees it in Admin app → HR → Leave tab (reads BOTH 
   leave_requests AND staff_requests)
3. Admin approves → UPDATE staff_requests status='approved'
   + INSERT leave_history (source='staff_request')
4. DB trigger fires → leave_balances auto-updated
5. Staff sees updated balance in Clock-In

### Data flow — admin-recorded leave (sick/family_responsibility)
1. Admin opens staff profile → Leave tab
2. Clicks "Record Sick Leave" or "Record Family Responsibility"
3. Enters dates + days + notes → INSERT leave_history 
   (source='admin_entry')
4. DB trigger fires → leave_balances auto-updated
5. Staff sees entry in Clock-In leave history

### Tables used
- staff_requests — Clock-In writes leave requests here
  staff_id → staff_profiles.id
  request_type = 'leave' for all leave requests
  leave_type = 'annual' or 'unpaid'
  
- leave_requests — Admin-created leave records
  staff_id → staff_profiles.id
  approved_by → staff_profiles.id

- leave_history — Permanent immutable record of all leave taken
  staff_id → staff_profiles.id (the staff member)
  recorded_by → profiles.id (the admin who acted)
  source = 'staff_request' or 'admin_entry'
  NEVER filtered or hidden — permanent record

- leave_balances — Current balance per staff member
  staff_id → staff_profiles.id
  employee_id → profiles.id
  Flat columns: annual_leave_balance, sick_leave_balance, 
  family_leave_balance
  Updated AUTOMATICALLY by trigger on leave_history changes
  DO NOT update manually — trigger handles it

### DB trigger
Name: trg_update_balances_from_history
Table: leave_history
Events: AFTER INSERT OR UPDATE OR DELETE
Function: update_leave_balances_from_history()
Recalculates: annual (calendar year), sick (36-month rolling),
              family (calendar year)

### BCEA South Africa entitlements
- Annual: 21 days/year, accrues 1.75 days/month
- Sick: 30 days per 36-month rolling cycle
- Family responsibility: 3 days per calendar year
- Unpaid: no entitlement — recorded for transparency only

### Files changed
Admin app:
  struisbaai_vleismark_admin_app/admin_app/lib/features/hr/
  screens/staff_list_screen.dart
  
  _LeaveTabState class (lines 948–1740 replaced 2026-03-19):
  - Unified leave management screen replacing two-column layout
  - Main area: full-width table showing ALL leave records across 
    ALL staff — leave_history + staff_requests combined
  - Staff filter dropdown + type filter dropdown at top of table
  - Each row shows: staff name, leave type badge, date range, 
    days, source badge, status badge, inline actions
  - Approve button: UPDATE staff_requests + INSERT leave_history
  - Reject button: UPDATE staff_requests only, no history insert
  - Delete button: only on leave_history rows where 
    source='admin_entry', shows confirmation dialog
  - Right sidebar (220px): status filter card, record leave card 
    with staff dropdown + sick/family buttons, balances card
  - Double-submission protection on Record Leave save button
  - DB trigger handles leave_balances automatically on all 
    leave_history INSERT/DELETE — never update balances manually
  - leave_history has NO status column — admin_entry = "Recorded",
    staff_request in history = "Approved"
  - staff_requests status IN ('pending','rejected') loaded for display

  _StaffFormDialog: Leave tab retained (unchanged) —
    staff-level balances, record buttons, and history still 
    accessible from individual staff profile

Clock-In app:
  clock_in_app/lib/features/hr/screens/hr_home_screen.dart
  - Added _buildLeaveHistorySection() reading leave_history
  clock_in_app/lib/features/hr/services/hr_repository.dart
  - Added getLeaveHistory() method

### Known working state (updated 2026-03-19)
- Duplicate Leon Strauss sick leave entry deleted (SQL)
  Deleted id: f18bd559-447e-4326-a984-bf54a28c32b0
  Kept id: bf997c8e-ebfd-4687-a95b-21be5ee170df
- Leon Strauss sick_leave_balance confirmed 29.00 after delete
- Unified leave table live and showing all staff records
- Delete confirmation dialog prevents accidental removal
- Double-submission protection prevents duplicate entries

### timecards.total_hours — GENERATED COLUMN
- total_hours is a GENERATED ALWAYS column in Supabase
- Formula: ROUND((clock_out - clock_in in hours) - (break_minutes/60), 2)
- Cannot be manually updated — DB calculates it automatically
- Clock-In app sends total_hours in clockOut payload — harmless,
  DB ignores it and uses the generated expression
- Any attempt to UPDATE total_hours directly will fail with an error
- This is correct behaviour — do not try to fix it
- The validate_timecard_trigger also runs on timecards — 
  do not remove it

---

## OFFLINE IMPROVEMENTS — IMPLEMENTED 2026-03-19

### POS App — sync_service.dart
After syncing each offline transaction, SyncService now also:
1. Writes stock_movements (idempotent — checks before inserting)
2. Calls increment_loyalty RPC (idempotent — checks loyalty_points_log first)
Both are non-fatal — transaction marked synced regardless.
File: pos_app/lib/core/services/sync_service.dart

### Loyalty App — supabase_service.dart
All 5 fetch methods now use cache-then-network pattern:
- fetchCustomer(), fetchHistory(), fetchDeals(), 
  fetchAnnouncements(), fetchNotifications()
- On success: saves to SharedPreferences with timestamp
- On failure: returns cached data instead of empty array
- Cache keys: cache_customer_$uid, cache_history_$uid,
  cache_deals_$tier, cache_announcements, cache_notifications_$uid
- getCacheTimestamp(key) returns when data was last cached
File: loyalty_app_sbvm/struisbaai_loyalty_app/lib/core/services/supabase_service.dart

### Loyalty App — main_shell.dart
Offline banner shown when serving cached data.
"Showing saved data — reconnect to refresh"
Uses cache-based detection (no connectivity_plus dependency).
File: loyalty_app_sbvm/struisbaai_loyalty_app/lib/shared/widgets/main_shell.dart

### Clock-In App — idle_screen.dart
Sync status indicator at top of idle screen.
ValueListenableBuilder on SyncService.instance.pendingCount.
Shows amber banner "⏳ X action(s) pending sync" when count > 0.
Invisible (SizedBox.shrink) when all synced.
File: clock_in_app/lib/features/idle/screens/idle_screen.dart
---

## PROMOTIONS, ANNOUNCEMENTS & NOTIFICATIONS — FIXED 2026-03-19

### Critical Fixes Applied:

**1. Loyalty App Promotion Model** — COMPLETE REWRITE
- File: loyalty_app/lib/core/models/promotion.dart
- Fixed field mismatch: `promo_type` → `promotion_type` (matches DB)
- Fixed field mismatch: `discount_value` → `rewardConfig` JSONB
- Added missing fields: `status`, `channels`, `triggerConfig`
- Added computed property `discountValue` extracted from `rewardConfig`
- Deals screen now correctly parses and displays promotions

**2. Loyalty App Deals Display** — DYNAMIC REWARD TEXT
- File: loyalty_app/lib/features/deals/screens/deals_screen.dart
- Added `_getRewardText()` helper to extract display text from reward types
- Supports: discount_pct, free_item, early_access, points_multiplier, custom
- No longer assumes all promotions have discount percentages

**3. Admin App Announcement Creation** — REQUIRED FIELDS ADDED
- File: admin_app/lib/features/customers/screens/announcement_screen.dart
- INSERT now includes: `announcement_type`, `priority`, `start_date`
- Prevents DB constraint violations when creating announcements

**4. Loyalty App Notification Badge** — NEW FEATURE
- File: loyalty_app/lib/shared/widgets/main_shell.dart
- Red badge on Profile nav item shows unread notification count
- Queries: `SELECT COUNT(*) FROM loyalty_notifications WHERE status='pending'`
- Refreshes on app resume via WidgetsBindingObserver
- Badge hidden when count = 0

**5. Loyalty App Mark Notifications as Read** — AUTO-UPDATE
- File: loyalty_app/lib/features/notifications/screens/notifications_screen.dart
- When notifications screen opens: `UPDATE status='read' WHERE status='pending'`
- Badge count updates automatically after marking as read

**6. Admin App Notification Management** — NEW SCREEN
- File: admin_app/lib/features/customers/screens/notification_management_screen.dart
- Send notifications to customers by tier or individually
- 6 notification type templates with auto-fill title/body
- Batch send: creates one notification per customer in selected tier
- History tab shows all sent notifications with status indicators
- **NOTE:** Navigation to this screen must be added to admin app main shell

### Database Schema Used:
- `promotions`: promotion_type, reward_config (JSONB), trigger_config (JSONB), channels[], audience[]
- `announcements`: announcement_type, priority, start_date (all NOT NULL with defaults)
- `loyalty_notifications`: customer_id, notification_type, title, body, scheduled_for, status

### End-to-End Flow:
1. **Promotions:** Admin creates → DB stores → Loyalty app Deals screen displays
2. **Announcements:** Admin creates → DB stores → Loyalty app News screen displays
3. **Notifications:** Admin sends → DB stores → Loyalty app badge shows → User reads → Status updates

All systems verified working with live database queries on 2026-03-19.

---

## PROMOTIONS & NOTIFICATIONS — IMPLEMENTED 2026-03-19

### Storage Buckets:
- **announcements**: Created for announcement image uploads (public bucket)
- **recipe-images**: Existing bucket for recipe images

### Promotion System Architecture:
- **POS App**: Loads all active promotions at start, caches in `cachedPromotions`
- **Auto-apply**: When customer linked, `_evaluatePromotions()` runs automatically
- **Channel filtering**: POS-only vs loyalty_app promotions enforced at query level
- **Tier filtering**: Exact tier match + 'all' audience (no cascading)
- **No stacking**: Only best discount applies (confirmed working)
- **Early Access**: Shows "VIP Early Access" badge for VIP customers (no discount)

### Loyalty App Deals Screen:
- **Automatic filtering**: Customer sees only their tier + 'all' audience promotions
- **Manual tier chips removed**: No Bronze+, Silver+, etc. selectors
- **Channel filter**: Only promotions with 'loyalty_app' in channels array
- **Enhanced cards**: Show dates, times, days, and terms conditions
- **Terms display**: Custom terms if set, else default stacking disclaimer

### Notification Badge System:
- **Real-time updates**: Badge count refreshes after viewing notifications
- **Auto-refresh**: On app resume and after returning from notifications screen
- **Source**: Queries `loyalty_notifications` table for 'pending' status

### Admin App Enhancements:
- **Announcement publishing**: Fixed storage bucket to 'announcements'
- **Created by tracking**: Added staff ID to announcement records
- **Promotion terms**: New `terms_and_conditions` field (500 chars max)
- **Form validation**: Terms field optional with hint text

### Database Schema Updates:
```sql
-- Storage bucket
INSERT INTO storage.buckets (id, name, public) VALUES ('announcements', 'announcements', true);

-- Promotions table
ALTER TABLE promotions ADD COLUMN terms_and_conditions text;
```

### Key Implementation Details:
- **POS promotion evaluation**: Handles spend_threshold, time_based, bundle, early_access types
- **Loyalty app filtering**: Server-side channel filter + client-side tier filter
- **Terms integration**: Added to both admin and loyalty app Promotion models
- **Badge refresh pattern**: `.then((_) => loadUnreadCount())` after navigation

All changes verified with flutter analyze (info-level suggestions only) and live database testing.
