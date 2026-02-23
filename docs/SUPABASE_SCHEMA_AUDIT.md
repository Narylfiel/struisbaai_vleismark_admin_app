# Supabase Schema Audit — Admin App (APP 2)

**Purpose:** Compare the remote Supabase `public` schema with the schema defined in `admin_app/supabase/migrations/`. Use this after `supabase db push` to verify alignment.

**Last push:** Run `supabase db push` with password from `admin_app/supabase/.temp/db-password.txt`. Remote was reported "up to date."

---

## Actual vs project alignment (from Section 3 query)

Remote schema differs in a few places from our migrations; the app and migration 032 were updated to align.

### chart_of_accounts (actual)
- **Primary columns:** `code` (text, NOT NULL), `name` (text, NOT NULL) — remote uses these.
- **Also present:** `account_code`, `account_name`, `account_type`, `parent_id`, `subcategory`, `sort_order`, `is_active`, `created_at`, `updated_at`.
- **App change:** Read/write both: insert/update set `code`, `name`, `account_code`, `account_name`. Display uses `account_code ?? code`, `account_name ?? name`. Order by `code`.

### ledger_entries (actual)
- **Remote had:** `account_id` (UUID NOT NULL), `reference` (text), `created_by` (UUID) — no `account_code`, `account_name`, `recorded_by`.
- **Migration 032:** Adds `account_code`, `account_name`, `reference_type`, `reference_id`, `recorded_by`; makes `account_id` nullable; backfills from `chart_of_accounts` + `created_by`.
- **App:** Unchanged; uses `account_code`, `account_name`, `recorded_by`. `LedgerEntry.fromJson` accepts `created_by` as fallback for `recorded_by`.

### invoices (actual)
- **Remote has:** `line_items` (jsonb), `total` (not `total_amount`), `tax_rate`, `payment_date`; `account_id` NOT NULL. Our migrations use `invoice_line_items` table and `total_amount`. If the app uses `invoice_line_items` and `total_amount`, ensure the app matches the table it actually uses (or the remote has both).

### business_accounts (actual)
- Matches expected: `id`, `name`, `account_type`, `email`, `phone`, `balance`, `credit_limit`, `is_active`, `contact_person`, `whatsapp`, `credit_terms_days`, `suspended`, `active`, `suspension_recommended`, `address`, `notes`, etc.

### purchase_sale_agreement (actual)
- Has `account_id` (UUID, nullable) — matches migration 029.

---

## 1. Expected Tables (from migrations 001–032)

Tables that should exist in `public` (created or extended by our migrations):

| Table | Created in | Notes |
|-------|------------|--------|
| staff_documents | 001 | |
| business_settings | 001 | |
| stock_locations | 001 | |
| modifier_groups | 001 | + sort_order, updated_at (003, 018, 023) |
| modifier_items | 001 | + updated_at, track_inventory, inventory_item_id (008, 018) |
| yield_templates | 001 | |
| yield_template_cuts | 001 | |
| carcass_intakes | 001 | |
| carcass_breakdown_sessions | 001 | |
| stock_movements | 001 | + metadata (005) |
| recipes | 001 | + output_product_id, expected_yield_pct, batch_size_kg (009) |
| recipe_ingredients | 001 | |
| production_batches | 001 | + output_product_id (009) |
| production_batch_ingredients | 001 | |
| dryer_batches | 001 | + batch_number, started_at, input/output_product_id, recipe_id (009, 012) |
| dryer_batch_ingredients | 001 | |
| hunter_services | 001 | + cut_options (026) |
| hunter_jobs | 001 | + job_date, processing_instructions, weight_in, cuts, paid, customer_*, animal_type, estimated_weight, total_amount (026) |
| hunter_job_processes | 001 | |
| hunter_process_materials | 001 | |
| account_awol_records | 002 | |
| staff_credit | 002 | + credit_type, items_purchased, repayment_plan, deduct_from, status (003, 015, 027) |
| staff_loans | 002 | |
| invoices | 002 | + supplier_id, status check (014) |
| invoice_line_items | 002 | |
| ledger_entries | 002 | + source, metadata (006) |
| **chart_of_accounts** | 002 | + **parent_id** (030), **account_code/account_name/account_type/…** ensured (031) |
| equipment_register | 002 | |
| purchase_sale_agreement | 002 | + **account_id** (029) |
| purchase_sale_payments | 002 | |
| sponsorships | 002 | |
| donations | 002 | |
| payroll_periods | 002 | |
| payroll_entries | 002 | |
| loyalty_customers | 002 | |
| announcements | 002 | |
| event_tags | 002 | |
| event_sales_history | 002 | |
| transactions | 004 | + vat_amount (019) |
| transaction_items | 004 | |
| suppliers | 010 | + bbbee_level (011) |
| stock_take_sessions | 010 | |
| stock_take_entries | 010 | |
| production_batches | 001 | (see above) |
| inventory_items | (from POS/base) | + many columns in 003, 007, 009, 012, 020 |
| categories | (from POS/base) | + notes, sort_order, updated_at, is_active, color_code (003) |
| profiles | (auth) | + is_active (003) |
| business_accounts | (from POS/base) | + active, suspension_recommended (003) |
| account_transactions | 017 | |
| staff_awol_records | 015 | |
| shrinkage_alerts | 016, 024 | + product_id, item_name, status, theoretical_stock, etc. (016); shrinkage_percentage, alert_type, batch_id, expected/actual_weight (024) |
| purchase_orders | 022 | |
| purchase_order_lines | 022 | |
| product_suppliers | 021 | |
| compliance_records | 028 | |

**Note:** Some tables (e.g. `inventory_items`, `categories`, `profiles`, `business_accounts`) may be created by an earlier/POS schema; our migrations only add columns.

---

## 2. Critical Columns for Admin App

### chart_of_accounts (Bookkeeping — Chart of Accounts, Import)
- `id` (UUID, PK)
- **`account_code`** (TEXT, UNIQUE NOT NULL) — required for import; PGRST204 fix in 031
- `account_name` (TEXT NOT NULL)
- `account_type` (TEXT NOT NULL, CHECK: asset|liability|equity|income|expense)
- `subcategory` (TEXT)
- `is_active` (BOOLEAN DEFAULT true)
- `sort_order` (INTEGER DEFAULT 0)
- `parent_id` (UUID, FK chart_of_accounts, nullable) — 030
- `created_at`, `updated_by`

### ledger_entries (Ledger, P&L, VAT)
- `id`, `entry_date`, **`account_code`**, **`account_name`**, `debit`, `credit`, `description`, `reference_type`, `reference_id`, `recorded_by`, `created_at`
- `source` (TEXT), `metadata` (JSONB) — 006

### business_accounts (Accounts)
- Used by account list, account detail, invoices, purchase_sale_agreement (account_id).

### purchase_sale_agreement
- **`account_id`** (UUID, FK business_accounts, nullable) — 029, for Account Detail Agreements tab.

---

## 3. Full schema audit SQL

**Use the full audit script for the whole app:**  
**`docs/full_schema_audit.sql`**

It runs in Supabase Dashboard → SQL Editor and returns:

1. **All tables** in `public` (with column count)
2. **All columns** — table, column, data_type, is_nullable, column_default, ordinal_position
3. **Primary keys** — table, column, constraint name
4. **Foreign keys** — from_table/column → to_table/column
5. **Unique constraints**
6. **Check constraints**
7. **Indexes** (pg_indexes)

Compare the results with `admin_app/supabase/migrations/` (001–032) and with every `from('...')` in the app.

---

### Quick verification (bookkeeping / key tables only)

```sql
-- Tables in public schema
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Columns for critical tables
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('chart_of_accounts', 'ledger_entries', 'business_accounts', 'invoices', 'purchase_sale_agreement')
ORDER BY table_name, ordinal_position;
```

- If `chart_of_accounts` is missing `account_code`/`account_name`, migration **031** adds them. Remote may use `code`/`name` as primary; app now sets both.
- If `ledger_entries` is missing `account_code`/`account_name`/`recorded_by`, run **032_ledger_entries_align_schema.sql** (`supabase db push`), then re-run the verification SQL.

---

## 4. Push command (for reference)

From repo root or `admin_app`:

```powershell
cd admin_app
$env:SUPABASE_DB_PASSWORD = (Get-Content "supabase\.temp\db-password.txt" -Raw).Trim()
supabase db push
```

---

---

## 5. Tables referenced by the app (from `.from('...')`)

Use this as a checklist when comparing full schema audit results. Every table below should exist in `public` with the columns the app expects.

| Area | Tables |
|------|--------|
| **Accounts** | business_accounts, account_transactions, business_settings |
| **Bookkeeping** | chart_of_accounts, ledger_entries, invoices, invoice_line_items, equipment_register, purchase_sale_agreement, purchase_sale_payments |
| **HR / Staff** | staff_profiles, profiles, compliance_records, timecards, timecard_breaks, leave_requests, leave_balances, payroll_entries |
| **Hunter** | hunter_services, hunter_jobs, hunter_job_processes |
| **Inventory** | inventory_items, categories, stock_locations, stock_movements, modifiers (modifier_groups, modifier_items), suppliers, product_suppliers, stock_take_sessions, stock_take_entries |
| **Production** | recipes, recipe_ingredients, production_batches, dryer_batches, yield_templates, carcass_intakes, carcass_breakdown_sessions |
| **Analytics / Dashboard** | shrinkage_alerts, reorder_recommendations, transactions, transaction_items, event_tags, event_sales_history, supplier_price_changes |
| **Customers** | loyalty_customers, announcements |
| **Settings** | business_settings, scale_config, tax_rules, system_config |
| **Orders** | purchase_orders, purchase_order_lines |

Storage (optional): `documents` bucket for compliance uploads.

---

*Generated from `admin_app/supabase/migrations/` (001–032) and app codebase.*
