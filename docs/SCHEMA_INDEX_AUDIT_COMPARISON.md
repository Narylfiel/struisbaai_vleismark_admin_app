# Schema Index Audit — Remote vs Blueprint & Admin App

Comparison of the actual Supabase index results with what the Admin App (APP 2) uses and what the blueprint expects.

---

## 1. Tables: App uses vs Remote has

### ✅ App tables that exist in remote (all good)

| Table | App Usage | Remote |
|-------|-----------|--------|
| account_transactions | Accounts, Record Payment | ✓ |
| announcements | CustomerRepository | ✓ (also customer_announcements) |
| business_accounts | Account list, detail | ✓ |
| business_settings | Settings, compliance, hunter | ✓ |
| categories | Product list, recipes | ✓ |
| chart_of_accounts | Ledger, CoA import | ✓ |
| compliance_records | HR Compliance | ✓ |
| equipment_register | Bookkeeping PTY tab | ✓ |
| event_sales_history | Analytics | ✓ |
| event_tags | Analytics | ✓ |
| hunter_job_processes | Hunter | ✓ |
| hunter_jobs | Hunter | ✓ |
| hunter_services | Hunter | ✓ |
| inventory_items | Inventory, production | ✓ |
| invoice_line_items | Invoices | ✓ |
| invoices | Bookkeeping, Account detail | ✓ |
| leave_balances | HR Staff list | ✓ |
| leave_requests | HR, Dashboard | ✓ |
| ledger_entries | Ledger, P&L, VAT | ✓ |
| loyalty_customers | Customers | ✓ |
| modifier_groups | Product list | ✓ |
| modifier_items | Modifier items | ✓ |
| payroll_entries | HR Staff list | ✓ |
| product_suppliers | Product list, analytics | ✓ |
| production_batches | Production | ✓ |
| profiles | Account list (merge) | ✓ |
| purchase_order_lines | Analytics | ✓ |
| purchase_orders | Analytics | ✓ |
| purchase_sale_agreement | Account detail Agreements | ✓ |
| purchase_sale_payments | Account detail | ✓ |
| recipe_ingredients | Recipes | ✓ |
| recipes | Product list, production | ✓ |
| reorder_recommendations | Dashboard | ✓ |
| scale_config | Settings | ✓ |
| shrinkage_alerts | Dashboard, Analytics | ✓ |
| staff_profiles | HR, Auth, compliance | ✓ |
| stock_locations | Stock take, movements | ✓ |
| stock_movements | Inventory | ✓ |
| stock_take_entries | Stock take | ✓ |
| stock_take_sessions | Stock take | ✓ |
| suppliers | Carcass, product list | ✓ |
| system_config | Settings | ✓ |
| tax_rules | Settings | ✓ |
| timecards | HR Staff list | ✓ |
| timecard_breaks | HR Staff list | ✓ (if column exists) |
| transaction_items | Analytics | ✓ |
| transactions | Dashboard, Analytics | ✓ |
| yield_templates | Carcass intake | ✓ |
| carcass_intakes | Production | ✓ |
| carcass_cuts | Carcass intake | ✓ |
| dryer_batches | Dryer/Biltong | ✓ |
| dryer_batch_ingredients | Dryer | ✓ |
| production_batch_ingredients | Production | ✓ |

---

## 2. ⚠️ Potential mismatches (dual tables / naming)

| Remote Table | App Table | Notes |
|--------------|-----------|-------|
| **announcements** | announcements | App uses `announcements`. Remote has both `announcements` and `customer_announcements`. Confirm app reads from correct one. |
| **customer_announcements** | — | Separate table; app uses `announcements`. May be for different channel (e.g. SMS vs in-app). |
| **purchase_sale_agreement** | purchase_sale_agreement | ✓ App uses singular. Remote has BOTH `purchase_sale_agreement` and `purchase_sale_agreements` (plural). Ensure app only uses singular. |
| **purchase_sale_agreements** | — | Plural variant; app uses singular. |
| **staff_credit** | staff_credit | App (staff_credit_screen) uses `staff_credit`. Remote has BOTH `staff_credit` and `staff_credits`. |
| **staff_credits** | — | Plural; app uses singular `staff_credit`. |
| **stock_takes** | stock_take_sessions | Remote has both `stock_takes` and `stock_take_sessions`. App uses `stock_take_sessions`. |
| **equipment_register** | equipment_register | ✓ App uses this. Remote also has `equipment_assets` (different schema — may be POS or older). |
| **equipment_assets** | — | Different table; app uses `equipment_register`. |
| **transactions** | transactions | ✓ App uses `transactions`. Remote also has `sales_transactions` — may be POS-specific. |
| **sales_transactions** | — | Likely POS; app uses `transactions`. |
| **awol_records** | staff_awol_records | Remote has BOTH `awol_records` and `staff_awol_records`. Blueprint uses staff AWOL. App uses `staff_awol_records` (from HR). |
| **account_awol_records** | — | Account-level AWOL (business accounts); separate from staff AWOL. |

---

## 3. Tables in remote not used by Admin App (likely POS or shared)

These exist in the remote DB but the Admin App does not reference them in `.from()`:

- `audit_log` — audit trail (could be used by Audit module)
- `awol_records` — staff AWOL (app may use `staff_awol_records`)
- `customer_announcements` — customer-facing announcements
- `equipment_assets` — equipment (app uses `equipment_register`)
- `hunter_service_config` — hunter species config (app uses `hunter_services`)
- `printer_config` — POS printers
- `purchase_sale_agreements` (plural)
- `role_permissions` — auth/permissions
- `sales_transactions` — POS sales
- `staff_credits` (plural)
- `stock_takes` — stock take (app uses `stock_take_sessions`)

---

## 4. Column name checks (from earlier Section 3)

| Table | Remote Primary | App Expects | Status |
|-------|----------------|-------------|--------|
| chart_of_accounts | code, name (NOT NULL) | account_code, account_name | ✓ App now uses both; Import sets code/name. |
| ledger_entries | account_id, reference, created_by | account_code, account_name, recorded_by | ✓ Migration 032 added columns. |
| invoices | account_id, invoice_line_items (table), total_amount | Same | ✓ invoice_repository uses total_amount + invoice_line_items. |

---

## 5. hunter_services column

- `job_list_screen` orders by `service_name` — remote index is on `hunter_services(name)`.
- If remote has `name` not `service_name`, change order to `name` or add `service_name` if that’s the canonical column.

---

## 6. leave_balances column

- Remote unique: `leave_balances_employee_unique` on `employee_id`.
- App uses `staff_id` in `leave_requests`; `leave_balances` may use `employee_id` (same as staff_id or different). Confirm FK alignment.

---

## 7. Summary: action items

1. **✅ No changes needed** for: chart_of_accounts, ledger_entries, business_accounts, purchase_sale_agreement, account_transactions, compliance_records, most inventory/HR/Hunter tables — already aligned or fixed.
2. **FIX** `hunter_services`: app uses `service_name` but schema has `name` — update job_list_screen to use `name`.
3. **Verify** `invoices` schema if invoice form/repo fails: remote has `line_items` (jsonb), `total`; app may expect `invoice_line_items` (table) and `total_amount`.
4. **Verify** `announcements` vs `customer_announcements`: app uses `announcements`; ensure that’s the correct table.
5. **Dual tables** (agreement/agreements, credit/credits, stock_takes/sessions): app correctly uses singular/session variants; no change unless requirements differ.

---

*From index audit results and app `.from()` usage.*
