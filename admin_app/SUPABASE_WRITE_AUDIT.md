# Supabase Write Operations Audit — Admin App

**Scope:** All Supabase table writes (`.insert`, `.update`, `.upsert`, `.delete`), Storage writes, and RPCs that may perform writes in the Admin App.  
**Truth sources:** `database_schema.md`, `admin_app/Employee Reference Table Mapping.md`.  
**Date:** 2025-03-02. **Mode:** READ ONLY — no code changes.

---

## 1. Summary

| Category | Count |
|----------|--------|
| Tables written (Postgres) | 45+ distinct table names |
| Storage buckets | 4 (`recipe-images`, `documents`, `product-images`, `waste-photos`) |
| RPCs invoked (possible writes) | 1 (`calculate_nightly_mass_balance`) |
| RPCs read-only | `calculate_supplier_spend`, `get_event_forecast`, `get_last_movement_by_items` |

**Schema vs code note:** Schema uses `stock_take_sessions` / `stock_take_entries`. Offline queue references `stock_takes` (see §4.7).

---

## 2. Table write operations (by table)

Tables are listed in alphabetical order. For each: operation, file path, line(s), and when relevant a note from the Employee Reference mapping (staff/profiles vs staff_profiles).

---

### account_transactions

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/accounts/screens/account_detail_screen.dart` | 304 | Record payment/sale; `recorded_by` → use **profiles** (mapping) |
| insert | `admin_app/lib/features/accounts/screens/account_list_screen.dart` | 1923 | Same |
| insert | `admin_app/lib/features/accounts/screens/account_list_screen.dart` | 1937 | (balance update is `business_accounts.update` below) |

**Schema:** `account_transactions.recorded_by` → `profiles(id)`.

---

### admin_roles

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/settings/screens/user_management_screen.dart` | 820 | New role |
| update | `admin_app/lib/features/settings/screens/user_management_screen.dart` | 1010, 1082, 1119 | Role name/permissions |

**Schema:** `admin_roles` — no staff FK.

---

### announcements

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/customers/services/customer_repository.dart` | 69 | `created_by` → use **profiles** (mapping) |

**Schema:** `announcements.created_by` → `profiles(id)`.

---

### audit_log

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/core/services/audit_service.dart` | 86 | `staff_id` → use **profiles** (mapping) |

**Schema:** `audit_log.staff_id`, `audit_log.authorised_by` → `profiles(id)`.

---

### business_accounts

| Op    | File | Line | Notes |
|-------|------|------|--------|
| update | `admin_app/lib/features/accounts/screens/account_detail_screen.dart` | 315 | Balance after transaction |
| update | `admin_app/lib/features/accounts/screens/account_list_screen.dart` | 201, 1131, 1142, 1937 | Suspend/unsuspend, balance, etc. |
| insert | `admin_app/lib/features/accounts/screens/account_list_screen.dart` | 1536 | New account |
| update | `admin_app/lib/features/accounts/screens/account_list_screen.dart` | 1554 | After insert (e.g. sync) |

**Schema:** No staff FK on `business_accounts`.

---

### business_settings

| Op    | File | Line | Notes |
|-------|------|------|--------|
| update | `admin_app/lib/features/settings/services/settings_repository.dart` | 85 | By id |
| upsert | `admin_app/lib/features/settings/services/settings_repository.dart` | 92 | Key/value style |
| upsert | `admin_app/lib/features/settings/screens/scale_settings_screen.dart` | 72 | Scale config |
| upsert | `admin_app/lib/features/settings/screens/notification_settings_screen.dart` | 92, 96 | Notifications |
| upsert | `admin_app/lib/features/bookkeeping/screens/pty_conversion_screen.dart` | 78 | PTY conversion |
| upsert | `admin_app/lib/features/settings/screens/tax_settings_screen.dart` | 87 | Tax settings |

**Schema:** `business_settings` — no staff FK.

---

### carcass_cuts

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/production/screens/carcass_intake_screen.dart` | 1871 | Per-cut rows after breakdown |

**Schema:** `carcass_cuts` — carcass_id/intake_id → carcass_intakes.

---

### carcass_intakes

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/production/screens/carcass_intake_screen.dart` | 1344 | New intake |
| insert | `admin_app/lib/core/services/offline_queue_service.dart` | 221 | Offline sync |
| update | `admin_app/lib/features/production/screens/carcass_intake_screen.dart` | 1856 | Status/weights after breakdown |

**Schema:** No staff FK on `carcass_intakes` (supplier_id, hunter_job_id, etc.).

---

### categories

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/inventory/blocs/category/category_bloc.dart` | 113 | New category |
| update | `admin_app/lib/features/inventory/blocs/category/category_bloc.dart` | 133, 161, 181 | Edit, deactivate, sort_order |

**Schema:** `categories` — parent_id self-FK only.

---

### chart_of_accounts

| Op    | File | Line | Notes |
|-------|------|------|--------|
| delete | `admin_app/lib/features/bookkeeping/screens/chart_of_accounts_screen.dart` | 158 | Remove account |
| update | `admin_app/lib/features/bookkeeping/screens/chart_of_accounts_screen.dart` | 178, 254 | Edit, toggle is_active |
| insert | `admin_app/lib/features/bookkeeping/screens/chart_of_accounts_screen.dart` | 186, 235 | New account |

**Schema:** No staff FK.

---

### compliance_records

| Op    | File | Line | Notes |
|-------|------|------|--------|
| upsert | `admin_app/lib/features/hr/screens/compliance_screen.dart` | 429 | `onConflict: 'staff_id,document_type'`; `staff_id` / `verified_by` → use **staff_profiles** (mapping) |

**Schema:** `compliance_records.staff_id`, `verified_by` → `staff_profiles(id)`.

---

### customer_announcements

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/customers/screens/announcement_screen.dart` | 181 | New draft/sent announcement |

**Schema:** No staff FK.

---

### customer_invoices

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/bookkeeping/services/customer_invoice_repository.dart` | 59 | `created_by` → use **profiles** (mapping) |
| update | `admin_app/lib/features/bookkeeping/services/customer_invoice_repository.dart` | 70, 83 | Edit, cancel |
| delete | `admin_app/lib/features/bookkeeping/services/customer_invoice_repository.dart` | 78 | Hard delete |

**Schema:** `customer_invoices.created_by` → `profiles(id)`.

---

### customer_recipe_category_assignments

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/customers/services/customer_recipe_repository.dart` | 195, 438 | Link recipe to category options |
| delete | `admin_app/lib/features/customers/services/customer_recipe_repository.dart` | 378, 426 | Clear then re-insert on save |

**Schema:** recipe_id → customer_recipes, option_id → customer_recipe_category_options.

---

### customer_recipe_category_options

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/customers/services/customer_recipe_repository.dart` | 719 | New option |
| update | `admin_app/lib/features/customers/services/customer_recipe_repository.dart` | 739 | Edit option |
| delete | `admin_app/lib/features/customers/services/customer_recipe_repository.dart` | 756 | Remove option |

**Schema:** type_id → customer_recipe_category_types.

---

### customer_recipe_category_types

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/customers/services/customer_recipe_repository.dart` | 662 | New type |
| update | `admin_app/lib/features/customers/services/customer_recipe_repository.dart` | 681 | Edit type |
| delete | `admin_app/lib/features/customers/services/customer_recipe_repository.dart` | 700 | Remove type |

**Schema:** No staff FK.

---

### customer_recipe_images

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/customers/services/customer_recipe_repository.dart` | 328, 562 | Add image; set primary |
| update | `admin_app/lib/features/customers/services/customer_recipe_repository.dart` | 559, 606, 609 | Clear/set is_primary |
| delete | `admin_app/lib/features/customers/services/customer_recipe_repository.dart` | 588, 589 | Remove image |

**Schema:** recipe_id → customer_recipes.

---

### customer_recipe_ingredients

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/customers/services/customer_recipe_repository.dart` | 164, 396 | Save ingredients (batch) |
| delete | `admin_app/lib/features/customers/services/customer_recipe_repository.dart` | 377, 403 | Replace list on save |

**Schema:** recipe_id → customer_recipes.

---

### customer_recipe_steps

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/customers/services/customer_recipe_repository.dart` | 182, 419 | Save steps (batch) |
| delete | `admin_app/lib/features/customers/services/customer_recipe_repository.dart` | 402, 426 | Replace list on save |

**Schema:** recipe_id → customer_recipes.

---

### customer_recipes

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/customers/services/customer_recipe_repository.dart` | 134 | New recipe; `created_by` → **profiles** (mapping) |
| update | `admin_app/lib/features/customers/services/customer_recipe_repository.dart` | 365, 464 | Edit recipe |
| delete | `admin_app/lib/features/customers/services/customer_recipe_repository.dart` | 511 | Delete recipe |

**Schema:** `customer_recipes.created_by` → `profiles(id)`.

---

### dryer_batch_ingredients

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/production/services/dryer_batch_repository.dart` | 118 | Per-ingredient row |
| delete | `admin_app/lib/features/production/services/dryer_batch_repository.dart` | 249 | Before deleting batch |

**Schema:** batch_id → dryer_batches, inventory_item_id → inventory_items.

---

### dryer_batches

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/production/services/dryer_batch_repository.dart` | 111 | New batch |
| update | `admin_app/lib/features/production/services/dryer_batch_repository.dart` | 217 | Status/weights etc. |
| delete | `admin_app/lib/features/production/services/dryer_batch_repository.dart` | 250 | After deleting ingredients |

**Schema:** recipe_id, input_product_id, output_product_id, etc.

---

### equipment_register

| Op    | File | Line | Notes |
|-------|------|------|--------|
| update | `admin_app/lib/features/bookkeeping/screens/equipment_register_screen.dart` | 117 | Append to `service_log` |
| insert | `admin_app/lib/features/bookkeeping/screens/equipment_register_screen.dart` | 427 | New asset |
| update | `admin_app/lib/features/bookkeeping/screens/equipment_register_screen.dart` | 402 | Edit asset; `updated_by` → **profiles** (mapping) |

**Schema:** `equipment_register.updated_by` → `profiles(id)`.

---

### event_tags

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/analytics/services/analytics_repository.dart` | 284 | New event tag |

**Schema:** No staff FK.

---

### hunter_job_processes

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/hunter/screens/job_list_screen.dart` | 500 | New process; `processed_by` → **profiles** (mapping) |

**Schema:** `hunter_job_processes.processed_by` → `profiles(id)`.

---

### hunter_jobs

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/hunter/screens/job_intake_screen.dart` | 412 | New job |
| insert | `admin_app/lib/features/hunter/screens/job_list_screen.dart` | 483 | Create job from list |
| insert | `admin_app/lib/core/services/offline_queue_service.dart` | 205 | Offline sync |
| update | `admin_app/lib/features/hunter/screens/job_intake_screen.dart` | 387 | Edit intake |
| update | `admin_app/lib/features/hunter/screens/job_list_screen.dart` | 250, 638 | Cancel, status |
| update | `admin_app/lib/features/hunter/screens/job_summary_screen.dart` | 80, 603 | paid, status completed |
| update | `admin_app/lib/features/hunter/screens/job_process_screen.dart` | 145 | Status/weights |
| update | `admin_app/lib/core/services/offline_queue_service.dart` | 231 | Offline status update |
| delete | `admin_app/lib/features/hunter/screens/job_list_screen.dart` | 201 | Delete job |

**Schema:** No staff FK on hunter_jobs (hunter_name, etc. are text).

---

### hunter_services

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/hunter/screens/job_list_screen.dart` | 962 | New service |
| update | `admin_app/lib/features/hunter/screens/job_list_screen.dart` | 771, 964 | Deactivate, edit |

**Schema:** inventory_item_id → inventory_items.

---

### inventory_items

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/production/screens/recipe_form_screen.dart` | 330 | New item from recipe |
| insert | `admin_app/lib/features/inventory/screens/product_list_screen.dart` | 1433 | New product |
| update | `admin_app/lib/features/inventory/screens/product_list_screen.dart` | 1456, 285, 1300, 3106 | Edit, is_active |
| update | `admin_app/lib/features/inventory/services/inventory_repository.dart` | 108, 119, 125, 132, 137, 202 | Stock adjustments |
| update | `admin_app/lib/features/hunter/screens/job_process_screen.dart` | 166 | current_stock after process |
| update | `admin_app/lib/features/inventory/services/stock_take_repository.dart` | 180 | current_stock after approve |

**Schema:** category_id, supplier_id, etc. No direct staff_id on inventory_items.

---

### invoice_line_items

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/bookkeeping/services/invoice_repository.dart` | 134, 225, 292 | Line items for **invoices** (supplier); invoice_id → invoices |
| delete | `admin_app/lib/features/bookkeeping/services/invoice_repository.dart` | 285 | Clear lines before replace |

**Schema:** `invoice_line_items.invoice_id` → `invoices(id)`. Mapping: `invoices.created_by` → **staff_profiles**.

---

### invoices (supplier / ledger invoices)

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/bookkeeping/services/invoice_repository.dart` | 116, 207 | New invoice; `created_by` → **staff_profiles** (mapping) |
| update | `admin_app/lib/features/bookkeeping/services/invoice_repository.dart` | 241, 252 | Edit, status |

**Schema:** `invoices.created_by` → `staff_profiles(id)`.

---

### ledger_entries

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/bookkeeping/services/ledger_repository.dart` | 46 | `recorded_by` / `created_by` → mapping: **recorded_by** profiles, **created_by** staff_profiles |

**Schema:** `ledger_entries.created_by` → staff_profiles(id), `recorded_by` → profiles(id).

---

### leave_requests

| Op    | File | Line | Notes |
|-------|------|------|--------|
| update | `admin_app/lib/features/hr/screens/staff_list_screen.dart` | 1028 | Status/review; `staff_id`, `approved_by` → **staff_profiles** (mapping) |
| update | `admin_app/lib/core/services/offline_queue_service.dart` | 211 | Offline approve |

**Schema:** `leave_requests.staff_id`, `approved_by` → `staff_profiles(id)`.

---

### loyalty_customers

| Op    | File | Line | Notes |
|-------|------|------|--------|
| update | `admin_app/lib/features/customers/services/customer_repository.dart` | 37 | active flag |
| insert | `admin_app/lib/core/services/offline_queue_service.dart` | 267 | Offline create customer |

**Schema:** No staff FK.

---

### message_logs

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/core/services/whatsapp_service.dart` | 260 | Log sent WhatsApp/SMS |

**Schema:** No staff FK.

---

### modifier_groups

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/inventory/services/modifier_repository.dart` | 45 | New group |
| update | `admin_app/lib/features/inventory/services/modifier_repository.dart` | 58, 69 | Edit, deactivate items by group |

**Schema:** No staff FK.

---

### modifier_items

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/inventory/services/modifier_repository.dart` | 106 | New item |
| update | `admin_app/lib/features/inventory/services/modifier_repository.dart` | 118, 72 | Edit, deactivate |
| delete | `admin_app/lib/features/inventory/services/modifier_repository.dart` | 126 | Delete item |

**Schema:** modifier_group_id → modifier_groups.

---

### parked_sales

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/hunter/services/parked_sale_repository.dart` | 102 | Park sale (e.g. hunter) |

**Schema:** hunter_job_id → hunter_jobs, created_by optional.

---

### payroll_entries

| Op    | File | Line | Notes |
|-------|------|------|--------|
| update | `admin_app/lib/core/services/offline_queue_service.dart` | 244, 246 | Approve by entry or period; `staff_id`, `approved_by` → **staff_profiles** (mapping) |

**Schema:** `payroll_entries.staff_id`, `approved_by` → `staff_profiles(id)`.

---

### production_batch_ingredients

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/production/services/production_batch_repository.dart` | 213 | Per-ingredient row |
| delete | (same file, cascade/cleanup) | 564, 574 | When cancelling/deleting batch |

**Schema:** batch_id → production_batches, ingredient_id → recipe_ingredients.

---

### production_batch_outputs

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/production/services/production_batch_repository.dart` | 316, 697 | Output rows |
| delete | (same file) | 568, 684 | Cleanup |

**Schema:** batch_id → production_batches, inventory_item_id → inventory_items.

---

### production_batches

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/production/services/production_batch_repository.dart` | 88, 205 | New batch |
| update | (same file) | 59, 257, 290, 343, 436, 650, 721 | is_split_parent, status, in_progress, complete, cancel |
| delete | (same file) | 575, 583 | Cancel/delete batch |

**Schema:** recipe_id, output_product_id, parent_batch_id.

---

### profiles

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/settings/screens/user_management_screen.dart` | 258 | New user profile |
| insert | `admin_app/lib/features/hr/screens/staff_list_screen.dart` | 2129 | Create profile when adding staff |
| update | `admin_app/lib/features/settings/screens/user_management_screen.dart` | 399, 469, 561, 630, 669 | Edit profile/role |
| update | `admin_app/lib/features/hr/screens/staff_list_screen.dart` | 2154, 2172 | Sync profile (staff list) |

**Schema:** profiles — auth-linked user profile. Mapping: many tables reference profiles for POS/reporting.

---

### promotion_products

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/promotions/services/promotion_repository.dart` | 100, 127 | Link products to promotion |
| delete | `admin_app/lib/features/promotions/services/promotion_repository.dart` | 123, 159 | Clear/replace by promotion |

**Schema:** promotion_id → promotions.

---

### promotions

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/promotions/services/promotion_repository.dart` | 94 | New promotion |
| update | `admin_app/lib/features/promotions/services/promotion_repository.dart` | 118, 138, 143, 148 | Edit, activate, pause, cancel |
| delete | `admin_app/lib/features/promotions/services/promotion_repository.dart` | 160 | Delete promotion |
| delete | (UI calls repo) | `admin_app/lib/features/promotions/screens/promotion_list_screen.dart` | 380 |

**Schema:** No staff FK.

---

### purchase_order_lines

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/analytics/screens/shrinkage_screen.dart` | 764 | Create PO line (e.g. for shrinkage) |

**Schema:** References purchase orders / inventory.

---

### product_suppliers

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/inventory/screens/product_list_screen.dart` | 2953 | Link product to supplier |
| update | `admin_app/lib/features/inventory/screens/product_list_screen.dart` | 2957 | Edit link |
| delete | `admin_app/lib/features/inventory/screens/product_list_screen.dart` | 1956 | Remove link |

**Schema:** inventory_item_id → inventory_items, supplier_id → suppliers.

---

### recipe_ingredients

| Op    | File | Line | Notes |
|-------|------|------|--------|
| delete | `admin_app/lib/features/production/services/recipe_repository.dart` | 153 | Remove ingredient from recipe |

**Schema:** recipe_id → recipes, ingredient_id → inventory_items.

---

### role_permissions

| Op    | File | Line | Notes |
|-------|------|------|--------|
| upsert | `admin_app/lib/features/settings/screens/user_management_screen.dart` | 1018 | Role–permission matrix |

**Schema:** role_id → admin_roles.

---

### scale_config

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/settings/services/settings_repository.dart` | 125 | New config row |
| update | `admin_app/lib/features/settings/services/settings_repository.dart` | 127 | Update existing |

**Schema:** scale_config — single-row or keyed config.

---

### shrinkage_alerts

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/analytics/screens/shrinkage_screen.dart` | 753 | New alert |
| insert | `admin_app/lib/features/inventory/screens/waste_log_screen.dart` | 1083 | From waste log |
| update | `admin_app/lib/features/analytics/services/analytics_repository.dart` | 40 | status/resolved; `resolved_by` → **profiles** (mapping) |

**Schema:** `shrinkage_alerts.resolved_by` → profiles; `acknowledged_by` → staff_profiles (mapping).

---

### staff_awol_records

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/hr/services/awol_repository.dart` | 71 | `staff_id`, `recorded_by` → **profiles** (mapping) |
| update | `admin_app/lib/features/hr/services/awol_repository.dart` | 78 | Edit record |

**Schema:** staff_awol_records.staff_id, recorded_by → profiles(id) per mapping.

---

### staff_credit

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/hr/services/staff_credit_repository.dart` | 77 | `staff_id`, `granted_by` → **profiles** (mapping) |
| update | `admin_app/lib/features/hr/services/staff_credit_repository.dart` | 87 | Edit |

**Schema:** staff_credit.staff_id, granted_by → profiles (mapping).

---

### stock_take_entries

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/inventory/services/stock_take_repository.dart` | 61, 132 | New/upsert count; `counted_by` → **profiles** (mapping) |
| update | `admin_app/lib/features/inventory/services/stock_take_repository.dart` | 74, 110, 159, 212 | actual_quantity, status flow |
| delete | `admin_app/lib/features/inventory/services/stock_take_repository.dart` | 190 | Before deleting session |
| insert | `admin_app/lib/core/services/offline_queue_service.dart` | 257 | Offline sync |

**Schema:** `stock_take_entries.counted_by` → `profiles(id)`; session_id → stock_take_sessions.

---

### stock_take_sessions

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/inventory/services/stock_take_repository.dart` | 61 | New session; `started_by` → **profiles** (mapping) |
| update | `admin_app/lib/features/inventory/services/stock_take_repository.dart` | 74, 159, 198, 212 | Status, approved_at, approved_by, rejection |
| delete | `admin_app/lib/features/inventory/services/stock_take_repository.dart` | 191 | Delete session |

**Schema:** `stock_take_sessions.started_by`, `approved_by` → `profiles(id)`.

---

### stock_takes (schema mismatch)

| Op    | File | Line | Notes |
|-------|------|------|--------|
| update | `admin_app/lib/core/services/offline_queue_service.dart` | 260 | `stock_takes.update({'status': 'completed'})`. **Schema has no `stock_takes` table** — only `stock_take_sessions`. Possible bug: should be `stock_take_sessions`. |

---

### supplier_invoices

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/bookkeeping/services/supplier_invoice_repository.dart` | 81, 104 | New/receive; `created_by` → **profiles** (mapping) |
| update | `admin_app/lib/features/bookkeeping/services/supplier_invoice_repository.dart` | 115, 141, 148, 266 | Edit, status |
| delete | `admin_app/lib/features/bookkeeping/services/supplier_invoice_repository.dart` | 134 | Hard delete |

**Schema:** supplier_invoices.created_by, received_by → profiles(id).

---

### supplier_price_changes

| Op    | File | Line | Notes |
|-------|------|------|--------|
| update | `admin_app/lib/features/analytics/services/analytics_repository.dart` | 100 | status |

**Schema:** No staff FK.

---

### suppliers

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/inventory/services/supplier_repository.dart` | 42 | New supplier |
| insert | `admin_app/lib/features/inventory/screens/supplier_list_screen.dart` | 251 | From UI |
| update | `admin_app/lib/features/inventory/services/supplier_repository.dart` | 56, 65 | Edit, is_active false |
| update | `admin_app/lib/features/inventory/screens/supplier_list_screen.dart` | 240 | From UI |

**Schema:** No staff FK.

---

### system_config

| Op    | File | Line | Notes |
|-------|------|------|--------|
| update | `admin_app/lib/features/settings/services/settings_repository.dart` | 170 | is_active by id |

**Schema:** system_config — key/value style.

---

### tax_rules

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/settings/services/settings_repository.dart` | 147 | New rule |
| delete | `admin_app/lib/features/settings/services/settings_repository.dart` | 151 | Delete rule |

**Schema:** tax_rules — no staff FK.

---

### timecards

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/core/services/offline_queue_service.dart` | 237 | Offline sync; `staff_id` → **staff_profiles** (mapping) |

**Schema:** timecards.staff_id → staff_profiles(id) per mapping.

---

### yield_templates

| Op    | File | Line | Notes |
|-------|------|------|--------|
| insert | `admin_app/lib/features/production/screens/carcass_intake_screen.dart` | 957 | New template |
| update | `admin_app/lib/features/production/screens/carcass_intake_screen.dart` | 961 | Edit template |

**Schema:** No staff FK.

---

## 3. Supabase Storage writes

| Bucket | File | Line | Operation |
|--------|------|------|-----------|
| recipe-images | `admin_app/lib/features/customers/services/customer_recipe_repository.dart` | 545 | upload |
| recipe-images | same | 502, 585 | remove (delete) |
| documents | `admin_app/lib/features/hr/screens/compliance_screen.dart` | 396 | upload (upsert) |
| documents | `admin_app/lib/features/bookkeeping/screens/pty_conversion_screen.dart` | 125 | uploadBinary (upsert) |
| product-images | `admin_app/lib/features/customers/screens/announcement_screen.dart` | 175 | upload |
| waste-photos | `admin_app/lib/features/inventory/screens/waste_log_screen.dart` | 904 | uploadBinary |

**Note:** `createSignedUrl` and `getPublicUrl` are read-only; not counted as writes.

---

## 4. RPCs that may perform writes

| RPC | File | Line | Likely behavior |
|-----|------|------|------------------|
| calculate_nightly_mass_balance | `admin_app/lib/features/analytics/services/analytics_repository.dart` | 46 | Name suggests it may update mass/balance data; treat as possible write until confirmed in DB. |

**Read-only RPCs (no change in this audit):**  
`calculate_supplier_spend`, `get_event_forecast`, `get_last_movement_by_items`.

---

## 5. Employee reference mapping compliance (summary)

Per `Employee Reference Table Mapping.md`:

- **profiles(full_name)** is used for: audit_log.staff_id, account_transactions.recorded_by, stock_take_sessions.started_by/approved_by, stock_take_entries.counted_by, carcass_breakdown_sessions.processed_by, hunter_job_processes.processed_by, staff_awol_records.staff_id/recorded_by, staff_credit.staff_id/granted_by, announcements.created_by, supplier_invoices.created_by, customer_invoices.created_by, ledger_entries.recorded_by, donations.recorded_by, equipment_register.updated_by, shrinkage_alerts.resolved_by, etc.
- **staff_profiles(full_name)** is used for: timecards.staff_id, leave_requests.staff_id/approved_by, payroll_entries.staff_id/approved_by, staff_credits (if present), awol_records (if different from staff_awol_records), compliance_records.staff_id/verified_by, shrinkage_alerts.acknowledged_by, invoices.created_by, ledger_entries.created_by.

All write locations above that set staff-related FKs are consistent with the schema FKs (profiles vs staff_profiles). The mapping document is the source of truth for which table to use when joining for display.

---

## 6. Findings

1. **Schema/table mismatch:** `offline_queue_service.dart` writes to `stock_takes` (update status). The schema only defines `stock_take_sessions` and `stock_take_entries`. This is a likely bug: offline sync may be targeting a non-existent or legacy table name.
2. **All other table writes** map to tables present in `database_schema.md`.
3. **Staff FK usage** aligns with `Employee Reference Table Mapping.md` and schema FKs (profiles vs staff_profiles).
4. **Storage:** Four buckets written; no schema to cross-check — audit is inventory only.
5. **RPC:** One RPC (`calculate_nightly_mass_balance`) is flagged as a possible write; the rest are read-only in this codebase.

---

**End of audit.** No code was modified.
