# Sales-Related Data Flow Audit — Admin App

**Blueprint (single source of truth):** `AdminAppBluePrintTruth.md`  
**Scope:** Sales-related tables, queries, and data flow only. No code changes.

---

## 1. WHAT EXISTS (with file references)

### 1.1 Dashboard — today’s sales, count, basket, margin

| Location | Table(s) used | Columns / relation |
|----------|----------------|---------------------|
| `admin_app/lib/features/dashboard/screens/dashboard_screen.dart` | **`sales`** | `total_amount`, `cost_amount`; filtered by `created_at` (today / yesterday) |

**Exact queries:**

- **Today (lines 63–67):**  
  `_supabase.from('sales').select('total_amount, cost_amount').gte('created_at', todayStart).lte('created_at', todayEnd)`
- **Yesterday (lines 70–74):**  
  `_supabase.from('sales').select('total_amount').gte('created_at', yesterdayStart).lte('created_at', yesterdayEnd)`

**Derived in code:**  
`_todaySales`, `_transactionCount`, `_avgBasket` (todayTotal / count), `_grossMargin` ((todayTotal - todayCost) / todayTotal * 100), `_salesChange` (vs yesterday). No other data source for these four widgets.

**Comment in code (line 105):**  
`// transactions table may not exist yet (POS not built)` — comment refers to `transactions` but the query uses **`sales`**.

### 1.2 Report service — sales report generation

| Location | Table(s) used | Relation |
|----------|----------------|----------|
| `admin_app/lib/core/services/report_service.dart` | **`sales`** | Nested: **`transaction_items(quantity, unit_price, line_total, inventory_items(name, category))`** |

**Exact query (lines 172–186):**  
`client.from('sales').select('*, transaction_items(...)').gte('created_at', ...).lte('created_at', ...)`  
Assumes `sales` has a foreign key to `transaction_items` (or vice versa). Uses `sale['transaction_items']`, `sale['total_amount']`, `sale['payment_method']`, `sale['created_at']`.

### 1.3 Export service — sales export

| Location | Table(s) used | Relation |
|----------|----------------|----------|
| `admin_app/lib/core/services/export_service.dart` | **`sales`** | **`transaction_items(quantity, unit_price, line_total, inventory_items(name))`** |

**Exact query (lines 203–209):**  
`client.from('sales').select('*, transaction_items(...)').gte('created_at', ...).lte('created_at', ...).order('created_at')`  
Same parent table **`sales`**; uses `sale['transaction_items']`, `sale['total_amount']`, etc.

### 1.4 Report repository — daily sales

| Location | Table(s) used |
|----------|----------------|
| `admin_app/lib/features/reports/services/report_repository.dart` | **`sales_transactions`** |

**Exact query (lines 21–26):**  
`_client.from('sales_transactions').select().gte('created_at', start).lte('created_at', end).order('created_at', ascending: true)`  
No join to line items. Used by `getDailySales(DateTime date)`.

### 1.5 Other references (not POS sales)

- **account_list_screen.dart:** `account_transactions` — business account payments/charges, not POS sales.
- **analytics_repository.dart:** `event_sales_history` — event/holiday analytics; not the main POS transaction table.
- **chart_widgets.dart:** “sales” only in widget name `salesTrendChart` and parameter name; no table access.
- **shrinkage_screen.dart:** “sales” only in user-facing text (“unusual sales spikes”); no table access.
- **admin_config.dart:** “Parked sales” is a config label; no table access.

**Summary of tables used for POS sales in the admin app:**

| File | Table name used | Purpose |
|------|-----------------|---------|
| dashboard_screen.dart | **sales** | Today’s sales, transaction count, avg basket, gross margin, % change vs yesterday |
| report_service.dart | **sales** + **transaction_items** (as relation) | Generate sales report (PDF/Excel/CSV) |
| export_service.dart | **sales** + **transaction_items** (as relation) | Export sales data |
| report_repository.dart | **sales_transactions** | Daily sales summary (getDailySales) |

---

## 2. WHAT IS MISSING (explicitly from blueprint)

### 2.1 Blueprint specification

- **§1.2 Data Flow:** “POS → Admin: Transaction data — POS writes via Supabase → Admin reads.”
- **§3.2 Dashboard Widgets:**  
  - Today’s Sales → **Data source: transactions (today)**  
  - Transaction Count → **transactions (today)**  
  - Average Basket → **Sales ÷ Transactions**  
  - Gross Margin → **(Revenue - COGS) ÷ Revenue**  
  - Refresh: Real-time (Supabase subscription) for sales/count/basket; Hourly for margin.  
  - Sales Chart → **7-day aggregate**; Hourly.  
  - Top Products → **sales aggregate (today)**; Every 30 min.
- **§15 Tables Admin READS:**

| Table | Written by | Admin uses for |
|-------|------------|----------------|
| **transactions** | POS App | Sales reports, P&L, analytics |
| **transaction_items** | POS App | Product performance, margins |

Blueprint does **not** define a table named **`sales`** or **`sales_transactions`** as the source for POS transaction data.

### 2.2 Not implemented in app

- **Table name:** No code references the blueprint table **`transactions`** for POS sales.
- **Real-time refresh:** Dashboard loads once on init and on pull-to-refresh; no Supabase subscription on the sales/transaction source.
- **Sales Chart (7-day):** No 7-day sales chart on the dashboard.
- **Top Products (today):** No “top products” widget on the dashboard.
- **till_sessions:** Blueprint §15 — “Z-reports, cash variance”; not queried anywhere in the app.
- **parked_sales:** Blueprint §15 — “View parked sales”; not queried anywhere in the app.

---

## 3. WHAT IS INCORRECT (deviations)

### 3.1 Table name vs blueprint

| Blueprint | Admin app actual | Deviation |
|-----------|-------------------|-----------|
| **transactions** (POS writes; Admin reads for sales, P&L, analytics) | **sales** (dashboard_screen, report_service, export_service) | Dashboard and sales report/export use **sales**, not **transactions**. |
| **transaction_items** (POS writes; Admin reads for product performance, margins) | Used only as a **relation from `sales`** (report_service, export_service) | Child rows are tied to **sales**, not to a table named **transactions**. |
| — | **sales_transactions** (report_repository.getDailySales) | Third name; not in blueprint. Inconsistent with both **transactions** and **sales**. |

### 3.2 Schema assumptions

- **Dashboard** expects **`sales`** to have: `total_amount`, `cost_amount`, `created_at`.  
  Blueprint does not define a **sales** table; it defines **transactions** (and **transaction_items**). If **transactions** has different column names (e.g. `total` vs `total_amount`, or no `cost_amount`), dashboard logic is wrong even if a view or alias were named **sales**.
- **report_service / export_service** assume a parent table (currently **sales**) with `created_at`, `total_amount`, `payment_method`, and a relation to **transaction_items**. Blueprint expects parent **transactions**; column names are not specified in the blueprint excerpt.

### 3.3 Inconsistency inside the app

- **Three different table names** for “POS sales”:
  - **sales** — dashboard_screen, report_service, export_service  
  - **sales_transactions** — report_repository.getDailySales  
- If the database has only **transactions** (and **transaction_items**), then:
  - Dashboard and report/export services query a non-existent or wrong table (**sales**).
  - Daily sales summary queries a different wrong/non-existent table (**sales_transactions**).

---

## 4. SYSTEM IMPACT (what breaks if POS writes to transactions)

### 4.1 If POS writes to `transactions` and `transaction_items` (as per blueprint)

- **Dashboard:**  
  All four sales widgets read from **`sales`**. If POS writes only to **transactions**:
  - **`sales`** either does not exist or is not populated → query fails or returns empty.
  - Result: Today’s Sales = 0, Transaction Count = 0, Avg Basket = 0, Gross Margin = 0, and % change is wrong or N/A. Dashboard sales section is effectively broken.
- **report_service.generateSalesReport:**  
  Queries **`sales`** (and relation **transaction_items**). Same as above → no data or error; sales reports empty/fail.
- **export_service.exportSales:**  
  Same → export empty or fails.
- **report_repository.getDailySales:**  
  Queries **`sales_transactions`**. If that table does not exist or is not populated → daily sales summary empty or error.

### 4.2 If database has `sales` but POS writes to `transactions`

- POS and Admin use different tables. Admin never sees POS data. Dashboard and reports show only what (if anything) writes to **sales** (e.g. another system or duplicate logic), not the real POS **transactions**. **Data flow “POS → Admin” is broken.**

### 4.3 Dependencies that assume sales data

- **Gross margin:** Dashboard computes margin from `cost_amount` on the same row. If **transactions** does not have `cost_amount` (or it’s on **transaction_items** or derived), logic is wrong or fails.
- **P&L / analytics:** Blueprint says P&L and analytics use **transactions** (and **transaction_items**). Current report/export code uses **sales**. Any P&L or analytics that eventually call these services will be wrong or broken if only **transactions** is populated.
- **Report hub:** If “Daily Sales Summary” or similar is wired to `getDailySales`, it reads **sales_transactions**; if “Sales Report” is wired to report_service/export_service, they read **sales**. All of these are misaligned with blueprint **transactions** / **transaction_items**.

### 4.4 Summary of impact

| Scenario | Dashboard | Sales report (report_service) | Sales export (export_service) | getDailySales (report_repository) |
|----------|------------|-------------------------------|-------------------------------|-----------------------------------|
| POS writes to **transactions** only; DB has no **sales** / **sales_transactions** | Empty/error | Empty/error | Empty/error | Empty/error |
| POS writes to **transactions**; **sales** / **sales_transactions** exist but unused | Shows 0 or stale data | Wrong/empty | Wrong/empty | Wrong/empty |
| POS writes to **sales** (non-blueprint) | Works | Works | Works | Fails if no **sales_transactions** |

---

## 5. COMPLETION % FOR THIS MODULE (sales-related data flow)

**Module:** Use of POS transaction data in the Admin app for dashboard, reports, and exports (as defined in blueprint §1.2, §3.2, §15).

| Criterion | Blueprint requirement | Status | Score |
|-----------|------------------------|--------|-------|
| Correct table for “transaction data” | **transactions** | Wrong: app uses **sales** (and **sales_transactions** in one place) | 0% |
| Dashboard: Today’s Sales | From **transactions** (today) | From **sales** | 0% |
| Dashboard: Transaction Count | From **transactions** (today) | From **sales** | 0% |
| Dashboard: Average Basket | Sales ÷ Transactions | Computed from **sales** rows | 0% (wrong source) |
| Dashboard: Gross Margin | (Revenue - COGS) ÷ Revenue | From **sales** (total_amount, cost_amount) | 0% (wrong source) |
| Dashboard: Real-time refresh | Supabase subscription | One-shot load + RefreshIndicator only | 0% |
| Dashboard: Sales Chart (7-day) | Present, 7-day aggregate | Not implemented | 0% |
| Dashboard: Top Products | Present, today’s aggregate | Not implemented | 0% |
| Reports: Sales data source | **transactions** (+ **transaction_items**) | **sales** + **transaction_items** | 0% |
| Consistency across app | Single canonical table for POS sales | Three names: **sales**, **sales_transactions**, and relation **transaction_items** from **sales** | 0% |
| till_sessions / parked_sales | Admin reads (Z-reports, parked) | Not used | 0% |

**Completion % for sales-related data flow:** **0%**  
Reason: No part of the app reads the blueprint-specified **transactions** table for POS sales; dashboard and sales report/export use non-blueprint tables (**sales**, **sales_transactions**); real-time and missing widgets not implemented. Functional behaviour (e.g. dashboard showing numbers) is possible only if the database diverges from the blueprint (e.g. a **sales** table populated by something other than the POS writing to **transactions**).

---

## 6. GAP SUMMARY

- **Exists:** Dashboard and two services (report, export) plus report_repository query **sales** or **sales_transactions** and (where used) **transaction_items** as a relation from **sales**. No code path reads the blueprint table **transactions** for POS sales.
- **Missing:** Use of **transactions** and **transaction_items** as per blueprint; real-time dashboard updates; 7-day sales chart; top products widget; use of **till_sessions** and **parked_sales**.
- **Incorrect:** Table names (**sales**, **sales_transactions** vs **transactions**); schema assumption (parent **sales** with `total_amount`, `cost_amount`); inconsistent table names across dashboard, report_service, export_service, report_repository.
- **Impact:** If POS writes to **transactions** (and **transaction_items**) only, dashboard sales metrics and all sales reports/exports that rely on **sales** (or **sales_transactions**) are wrong or broken; POS → Admin transaction data flow does not work as specified.
- **Completion:** 0% for the sales-related data flow module when measured strictly against the blueprint.

---

*Audit only. No code was modified. No fixes suggested.*
