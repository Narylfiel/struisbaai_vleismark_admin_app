# Transactions Blueprint Alignment — Implementation Summary

Blueprint §15: Admin READS **transactions** and **transaction_items** (POS writes).  
§3.2: Today's Sales, Transaction Count, Average Basket, Gross Margin from **transactions (today)**.

---

## 1. Data model changes

### New models (typed, no raw maps)

| File | Purpose |
|------|--------|
| `lib/core/models/transaction.dart` | **Transaction** — id, totalAmount, costAmount, paymentMethod, tillSessionId, staffId, accountId, createdAt. fromJson/toJson, validate. |
| `lib/core/models/transaction_item.dart` | **TransactionItem** — id, transactionId, inventoryItemId, quantity, unitPrice, lineTotal. fromJson/toJson, validate. |

Both extend `BaseModel` and match blueprint §15 (transactions / transaction_items).

---

## 2. Supabase schema (migration 004)

| File | Content |
|------|--------|
| `supabase/migrations/004_transactions_blueprint.sql` | Creates **transactions** and **transaction_items** with **transaction_id** FK; indexes; **get_dashboard_metrics** RPC using `transactions` and `transaction_items.transaction_id`. |

**Tables**

- **transactions**: id, created_at, total_amount, cost_amount, payment_method, till_session_id, staff_id, account_id, notes.
- **transaction_items**: id, **transaction_id** (REFERENCES transactions(id)), inventory_item_id, quantity, unit_price, line_total, created_at.

**Compatibility:** POS should write to `transactions` and `transaction_items(transaction_id)`. If the project still has `sales_transactions` / `sale_id`, either migrate data into the new tables or add views that map old → new names.

---

## 3. Service / repository layer

| File | Change |
|------|--------|
| `lib/features/dashboard/services/dashboard_repository.dart` | **New.** `DashboardRepository`: `getTransactionsForDateRange(start, end)` → `List<Transaction>` from `transactions`; `getTodayStats()` → `DashboardTransactionStats` (todayTotal, yesterdayTotal, transactionCount, avgBasket, grossMarginPct, salesChangePct). |
| `lib/features/reports/services/report_repository.dart` | `getDailySales(date)` now queries **transactions** (was `sales_transactions`). |
| `lib/core/services/report_service.dart` | `generateSalesReport` now uses **transactions** and **transaction_items**; report title "Transactions Report"; variable names `txn` / `txnData`. |
| `lib/core/services/export_service.dart` | `exportSales` now uses **transactions** and **transaction_items**; filename `transactions_export_...`; title "Transactions Report"; variable names `txn` / `txnData`. |

---

## 4. UI implementation

| File | Change |
|------|--------|
| `lib/features/dashboard/screens/dashboard_screen.dart` | Uses `DashboardRepository` and `getTodayStats()` instead of querying `sales`. Stats still: Today's Sales, Transaction Count, Avg Basket, Gross Margin. Subtitle for count card: "transactions today". No new UI structure. |

---

## 5. Data flow (end-to-end)

```
POS App
  → writes to: transactions, transaction_items (transaction_id → transactions.id)
  → (optional) till_sessions, audit_logs

Supabase (DB)
  ← Admin reads: transactions, transaction_items
  ← Dashboard: getTodayStats() → transactions for today/yesterday
  ← Reports: getDailySales(transactions), generateSalesReport(transactions + transaction_items), exportSales(transactions + transaction_items)

Admin App
  → Dashboard: DashboardRepository.getTodayStats() → Transaction list → todayTotal, count, avgBasket, margin, change%
  → Report hub: ReportRepository.getDailySales() → transactions
  → ReportService.generateSalesReport() → transactions + transaction_items
  → ExportService.exportSales() → transactions + transaction_items
```

---

## 6. Files changed (clear list)

| Action | Path |
|--------|------|
| **Added** | `lib/core/models/transaction.dart` |
| **Added** | `lib/core/models/transaction_item.dart` |
| **Added** | `supabase/migrations/004_transactions_blueprint.sql` |
| **Added** | `lib/features/dashboard/services/dashboard_repository.dart` |
| **Modified** | `lib/features/dashboard/screens/dashboard_screen.dart` |
| **Modified** | `lib/features/reports/services/report_repository.dart` |
| **Modified** | `lib/core/services/report_service.dart` |
| **Modified** | `lib/core/services/export_service.dart` |

---

## 7. Consistency with blueprint

- **Table names:** All Admin reads use **transactions** and **transaction_items** (no `sales` or `sales_transactions` in Admin code).
- **FK:** **transaction_items.transaction_id** → **transactions(id)** in schema and in joins (e.g. report_service select).
- **Dashboard §3.2:** Today's Sales, Transaction Count, Average Basket (Sales ÷ Transactions), Gross Margin — all sourced from `transactions` via `DashboardRepository.getTodayStats()`.
- **POS:** Same schema is defined in 004 so POS can write to `transactions` and `transaction_items(transaction_id)` for full compatibility.

Run migration 004 on the target Supabase project so `transactions` and `transaction_items` exist before using the dashboard or reports.
