# .insert() / .update() audit — lib/**/*.dart

For each call: file, line, table, and any fields set to `''`, `null`, or with a TODO.  
**Focus:** `recorded_by`, `created_by`, `staff_id`, `completed_by`, `account_id`.

---

## INSERT calls

| File | Line | Table | Empty / null / TODO notes |
|------|------|-------|---------------------------|
| modifier_repository.dart | 44 | (from context) | — |
| modifier_repository.dart | 98 | (from context) | — |
| announcement_screen.dart | 180 | customer_announcements | — |
| recipe_form_screen.dart | 163 | inventory_items | — |
| job_intake_screen.dart | 116 | hunter_jobs | No `completed_by`; no `staff_id` |
| equipment_register_screen.dart | 365 | equipment_register | — |
| analytics_repository.dart | 284 | event_tags | — |
| staff_credit_repository.dart | 77 | staff_credit | Has `staff_id` (granted_by, deduct_from, etc.) |
| ledger_repository.dart | 45 | ledger_entries | **Has `recorded_by`** (required param) |
| category_bloc.dart | 53 | categories | — |
| account_list_screen.dart | 1523 | business_accounts | — |
| account_list_screen.dart | 1881 | account_transactions | **Missing `recorded_by`** (DB allows null; audit gap) |
| equipment_register_screen.dart | 365 | equipment_register | — |
| invoice_repository.dart | 116 | invoices | `account_id` optional (nullable); **has `created_by`** |
| invoice_repository.dart | 134 | invoice_line_items | `description` can be `''` via `?? ''` in other path |
| invoice_repository.dart | 207 | invoices | **No `account_id`** in createFromOcr (intentional); **has `created_by`** |
| invoice_repository.dart | 225 | invoice_line_items | `description`: `li['description'] as String? ?? ''` → **can be `''`** |
| invoice_repository.dart | 292 | invoice_line_items | — |
| job_list_screen.dart | 323 | hunter_jobs | No `completed_by`; customer_email/notes can be empty |
| job_list_screen.dart | 339 | hunter_job_processes | — |
| job_list_screen.dart | 694 | hunter_services | — |
| settings_repository.dart | 125 | scale_config | — |
| settings_repository.dart | 147 | tax_rules | — |
| staff_list_screen.dart | 2106 | staff_profiles | — |
| account_detail_screen.dart | 301 | account_transactions | **Missing `recorded_by`** (ledger uses staffId; table insert does not) |
| shrinkage_screen.dart | 752 | purchase_orders | — |
| shrinkage_screen.dart | 763 | purchase_order_lines | — |
| awol_repository.dart | 71 | staff_awol_records | **Has `staff_id`, `recorded_by`** |
| production_batch_repository.dart | 91 | production_batches | **`notes`: null** literal |
| production_batch_repository.dart | 98 | production_batch_ingredients | **`actual_quantity`: null** |
| production_batch_repository.dart | 187 | production_batch_outputs | `notes` can be null |
| dryer_batch_repository.dart | 99 | dryer_batches | `processed_by`, `notes`, `input_product_id`, `output_product_id`, `recipe_id` can be null (no literal null in map) |
| dryer_batch_screen.dart (via repo) | — | dryer_batches | **performedBy: null** passed to createBatch → repo uses `processed_by` in insert; processedBy not set → **null in DB** |
| customer_repository.dart | 67 | announcements | **Has `created_by`** |
| product_list_screen.dart | 748 | inventory_items | — |
| product_list_screen.dart | 2022 | product_suppliers | — |
| recipe_repository.dart | 41 | recipes | — |
| recipe_repository.dart | 93 | recipe_ingredients | — |
| chart_of_accounts_screen.dart | 185 | chart_of_accounts | — |
| chart_of_accounts_screen.dart | 234 | chart_of_accounts | — |
| supplier_list_screen.dart | 222 | suppliers | — |
| whatsapp_service.dart | 260 | message_logs | — |
| carcass_intake_screen.dart | 899 | yield_templates | — |
| carcass_intake_screen.dart | 1278 | carcass_intakes | — |
| carcass_intake_screen.dart | 1775 | carcass_cuts | — |
| inventory_repository.dart | 53 | (from context) | — |
| inventory_repository.dart | 167 | (from context) | — |

---

## UPDATE calls

| File | Line | Table | Empty / null / TODO notes |
|------|------|-------|---------------------------|
| category_bloc.dart | 73 | categories | — |
| category_bloc.dart | 110 | categories | — |
| staff_list_screen.dart | 926 | leave_requests | — |
| staff_list_screen.dart | 2111 | staff_profiles | — |
| account_detail_screen.dart | 311 | business_accounts | — |
| settings_repository.dart | 85 | business_settings | — |
| settings_repository.dart | 127 | scale_config | — |
| settings_repository.dart | 170 | system_config | — |
| equipment_register_screen.dart | 99 | equipment_register | — |
| equipment_register_screen.dart | 363 | equipment_register | — |
| invoice_repository.dart | 241 | invoices | — |
| invoice_repository.dart | 252 | invoices | — |
| job_process_screen.dart | 129 | hunter_jobs | — |
| job_process_screen.dart | 145 | inventory_items | — |
| analytics_repository.dart | 40 | shrinkage_alerts | — |
| analytics_repository.dart | 100 | supplier_price_changes | — |
| customer_repository.dart | 37 | loyalty_customers | — |
| account_list_screen.dart | 198, 1118, 1129, 1527, 1895 | business_accounts | — |
| job_list_screen.dart | 470 | hunter_jobs | — |
| job_list_screen.dart | 696 | hunter_services | — |
| recipe_repository.dart | 53, 105 | recipes / recipe_ingredients | — |
| chart_of_accounts_screen.dart | 177 | chart_of_accounts | — |
| chart_of_accounts_screen.dart | 253 | chart_of_accounts | — |
| stock_take_repository.dart | 74 | stock_take_entries | `counted_by`, `device_id` can be null |
| stock_take_repository.dart | 110 | stock_take_entries | same |
| stock_take_repository.dart | 158 | stock_take_sessions | — |
| modifier_repository.dart | 56, 110 | modifiers / modifier_items | — |
| supplier_list_screen.dart | 211 | suppliers | — |
| job_summary_screen.dart | 42 | hunter_jobs | — |
| job_summary_screen.dart | 129 | hunter_jobs | — |
| product_list_screen.dart | 123, 752, 2026 | inventory_items / product_suppliers | — |
| dryer_batch_repository.dart | 179 | dryer_batches | **Has `completed_by`** via processed_by on complete |
| production_batch_repository.dart | 121, 153, 216, 226 | production_batch_ingredients / production_batches | **completed_by** set on complete (216) |
| staff_credit_repository.dart | 87 | staff_credit | — |
| inventory_repository.dart | 94, 105, 111, 118, 123, 173 | inventory_items | — |
| awol_repository.dart | 78 | staff_awol_records | — |
| carcass_intake_screen.dart | 903, 1769 | yield_templates / carcass_intakes | — |

---

## Focus: recorded_by, created_by, staff_id, completed_by, account_id

### recorded_by
- **Set:** ledger_repository (ledger_entries), awol_repository (staff_awol_records).
- **Missing:**  
  - **account_list_screen.dart:1881** — `account_transactions.insert` does not set `recorded_by` (table allows null; ledger call uses `recordedBy`).  
  - **account_detail_screen.dart:301** — `account_transactions.insert` does not set `recorded_by` (ledger uses `staffId`).

### created_by
- **Set:** invoice_repository (invoices create + createFromOcr), customer_repository (announcements).
- **Not applicable:** Other inserts don’t use a created_by column.

### staff_id
- **Set:** awol_repository (staff_awol_records), staff_credit (via payload), staff_list_screen (staff_profiles — user_id, not staff_id as FK).
- **Not set in insert/update:** hunter_jobs (no staff_id in schema for jobs), timecards (Clock-In app).

### completed_by
- **Set:** production_batch_repository (production_batches on complete), dryer_batch_repository (dryer_batches as processed_by on complete).
- **Not set:** hunter_jobs insert/update (no completed_by in hunter job payloads; status set to 'Completed' only).

### account_id
- **Set:** invoice_repository create() — optional param, can be null.  
- **Omitted (intentional):** invoice_repository createFromOcr() — no account_id in insert.  
- **Set:** account_list_screen (account_transactions), account_detail_screen (account_transactions).

---

## Summary of issues

1. **account_transactions.recorded_by** — Never set in either insert (account_list_screen, account_detail_screen). DB column is nullable; consider setting from current user/staff for audit.
2. **invoice_line_items.description** — Can be written as `''` (e.g. createFromOcr path: `li['description'] as String? ?? ''`).
3. **production_batch_repository** — `notes: null` and `actual_quantity: null` in inserts (nullable columns).
4. **dryer_batch_screen** — `performedBy: null` passed to createBatch; dryer_batches insert uses `processed_by` only, so processed_by can be null in DB.
5. **createFromOcr** — Intentionally no `account_id` on invoices (optional link to business account).

---

## Save error fix process (Flutter side only)

When a screen or repository has a **save error** (insert/update fails):

1. **Find** the insert/update payload (the map passed to `.insert()` or `.update()`).
2. **Compare** every field name against the **actual DB columns** (e.g. from `pulled_schema.sql` or migrations).
3. **Rename** fields that don’t match (e.g. `description` → `instructions`, `client_name` → `hunter_name`, `input_weight_kg` → `weight_in`).
4. **Remove** fields that do not exist in the DB (e.g. `product_name`, `dryer_type`, `processed_by` if not in schema).
5. **Never add new DB columns** unless explicitly asked — only fix the Flutter payload and model reads (e.g. `fromJson` fallbacks for old/new column names).
