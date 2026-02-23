# Phase 1 — Full System Correction Applied

## FIXES APPLIED

### 1. SHRINKAGE ALERT SYSTEM
- **Migration 017** (`017_phase1_triggers_ledger_stock.sql`):
  - Replaced `check_shrinkage_threshold()` so it always sets `status = 'Pending'`, `resolved = false`, and `item_name` (recipe name or `'Production batch'`).
  - **Trigger created explicitly:** `DROP TRIGGER IF EXISTS trigger_shrinkage_check ON production_batches` then `CREATE TRIGGER trigger_shrinkage_check AFTER UPDATE ON production_batches ... EXECUTE FUNCTION check_shrinkage_threshold();` so the trigger exists regardless of migration order (table from 016, trigger now in 017).
- Table `shrinkage_alerts` and columns (`status`, `resolved`, `item_name`) remain as in 016; no schema change.

### 2. BOOKKEEPING — LEDGER INTEGRATION
- **POS → Ledger (DB trigger):**
  - New function `post_pos_sale_to_ledger()` in 017: on `AFTER INSERT` on `transactions`, inserts two rows into `ledger_entries`:
    - DR: Cash (1000) / Bank (1100) / Accounts Receivable (1200) if `account_id` set
    - CR: Meat Sales (4000)
  - Uses `COALESCE(NEW.staff_id, (SELECT id FROM profiles WHERE role = 'owner' LIMIT 1))` for `recorded_by`; skips if no valid `recorded_by`.
- **Account payment → Ledger (app):**
  - In `account_list_screen.dart`, after inserting into `account_transactions` and updating `business_accounts.balance`, the app now calls `LedgerRepository().createDoubleEntry(...)`:
    - DR: 1000 Cash on Hand or 1100 Bank Account (from payment method)
    - CR: 1200 Accounts Receivable (Business Accounts)
    - `source: 'payment_received'`, `recordedBy: AuthService().currentStaffId`
  - If `currentStaffId` is null, payment is still saved but ledger is not updated and a warning SnackBar is shown on ledger failure.
- **account_transactions table:** Created in 017 with `CREATE TABLE IF NOT EXISTS account_transactions (...)` so payment history has a defined schema where the app already inserts.

### 3. PRODUCT SYSTEM — CATEGORY FIX
- **Product list** (`product_list_screen.dart`):
  - Categories loaded with `select('id', 'name')`; filter list includes `{id: null, name: 'All'}`.
  - Filter uses `_selectedCategoryFilterId` (null = All); match uses `p['category_id'] == _selectedCategoryFilterId`.
  - Display: added `_categoryNameById(categoryId)` to resolve category name from `_categories` for table and colour.
- **Product form dialog:**
  - Replaced `_selectedCategory` (string) with `_selectedCategoryId` (String?).
  - Dropdown: `value: _selectedCategoryId`, items from `widget.categories` with `value: c['id']?.toString()`, `child: Text(c['name'])`.
  - `_populateForm`: sets `_selectedCategoryId = p['category_id']?.toString()`.
  - `_save()`: sends `'category_id': _selectedCategoryId`; removed `'category': _selectedCategory`.
- Schema: `inventory_items` already has `category_id` (003); form and list now use it. Legacy `category` (TEXT) column is not removed so existing data or other readers are not broken.

### 4. STOCK SYSTEM — REAL UPDATES
- **Migration 017:** New trigger `deduct_stock_on_sale`:
  - `AFTER INSERT ON transaction_items`, for each row with `inventory_item_id` and `quantity > 0`:
  - `UPDATE inventory_items SET current_stock = GREATEST(0, COALESCE(current_stock, 0) - NEW.quantity) WHERE id = NEW.inventory_item_id`.
- Ensures POS sales that insert `transaction_items` automatically deduct from `inventory_items.current_stock` (single source of stock for this flow).
- Production, stock take, and waste/donations already use `InventoryRepository` / stock movement dialogs that update `inventory_items` (e.g. `current_stock` or `stock_on_hand_fresh`/`stock_on_hand_frozen` per existing code).

---

## DATABASE CHANGES

| Migration | Content |
|-----------|---------|
| **017_phase1_triggers_ledger_stock.sql** | 1) Shrinkage: replace function + create trigger on `production_batches`. 2) `CREATE TABLE IF NOT EXISTS account_transactions`. 3) Function `post_pos_sale_to_ledger()` + trigger on `transactions` INSERT. 4) Function `deduct_stock_on_sale()` + trigger on `transaction_items` INSERT. |

All triggers are created only when the required tables exist (guarded by `information_schema` checks).

---

## VERIFIED FLOWS (TO RUN AFTER MIGRATE)

1. **Create product** — Use product form; select category (by id); save. Verify in DB: `inventory_items.category_id` set.
2. **Perform sale** — POS (or direct insert into `transactions` + `transaction_items`). Verify: `ledger_entries` has two rows (DR Cash/Bank/AR, CR 4000) with `source = 'pos_sale'`; `inventory_items.current_stock` decreased for the sold item.
3. **Trigger shrinkage** — Update a `production_batches` row with `actual_quantity` set and expected weight such that shrinkage &gt; 2%. Verify: new row in `shrinkage_alerts` with `status = 'Pending'`, `resolved = false`, `item_name` set.
4. **Record account payment** — Record payment on a business account (logged in with PIN so `AuthService().currentStaffId` is set). Verify: `account_transactions` and `business_accounts.balance` updated; `ledger_entries` has DR Cash/Bank, CR 1200, `source = 'payment_received'`.
5. **Approve invoice** — Already implemented; verify ledger entries for that invoice.

---

## REMAINING RISKS

- **recorded_by for POS:** Trigger uses `NEW.staff_id` or first owner profile. If POS does not set `staff_id` on `transactions`, entries still post but with fallback user.
- **Account payment when not logged in:** If `AuthService().currentStaffId` is null (e.g. no PIN login), payment is saved but no ledger entry is created; user sees a warning. For full compliance, require PIN login before recording payments.
- **Legacy `category` column:** Still present on `inventory_items`; any code or reports that read `category` (text) will not see new saves (only `category_id` is set). Consider a DB view or backfill from `categories` if needed.
- **Stock:** Production and stock-take flows that should update `inventory_items` are assumed to go through existing InventoryRepository/stock movement code; no new triggers were added for those in this pass.

---

## FILES TOUCHED

- `admin_app/supabase/migrations/017_phase1_triggers_ledger_stock.sql` (new)
- `admin_app/lib/features/accounts/screens/account_list_screen.dart` (ledger posting + imports)
- `admin_app/lib/features/inventory/screens/product_list_screen.dart` (category_id: load, filter, form, save, display)

Apply migrations (e.g. `supabase db push` or run 017 on your Supabase project), then run the verification steps above.
