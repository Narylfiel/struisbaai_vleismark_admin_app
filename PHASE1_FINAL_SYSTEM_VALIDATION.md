# Phase 1 — Final System Validation

## VERIFIED WORKING

### 1. SHRINKAGE
- **Trigger:** `017_phase1_triggers_ledger_stock.sql` creates `trigger_shrinkage_check` on `production_batches` (AFTER UPDATE), executing `check_shrinkage_threshold()`.
- **Table:** `shrinkage_alerts` exists (016); trigger inserts into it when shrinkage &gt; 2%.
- **Fields:** Insert sets `status = 'Pending'`, `resolved = false`, `item_name = COALESCE(recipe_name, 'Production batch')` (017). Batch and weight fields populated.
- **Dashboard:** Queries `shrinkage_alerts` with `resolved` / `item_name`; fallback label uses `item_name` or gap %.
- **Analytics:** `updateShrinkageStatus` updates `status` and `resolved` on alerts.

### 2. POS SALES
- **transactions → ledger:** Trigger `trigger_post_transaction_to_ledger` (017) on `transactions` INSERT:
  - Inserts two rows into `ledger_entries`: DR Cash (1000) / Bank (1100) / AR (1200 if account_id set), CR Meat Sales (4000). Uses `recorded_by = COALESCE(NEW.staff_id, first owner profile)`.
- **transaction_items → stock:** Trigger `trigger_deduct_stock_on_sale` (017) on `transaction_items` INSERT:
  - Updates `inventory_items.current_stock = GREATEST(0, current_stock - NEW.quantity)` for `NEW.inventory_item_id`.

### 3. ACCOUNT PAYMENTS
- **account_list_screen.dart** (_RecordPaymentDialog._save):
  1. Inserts into `account_transactions` (account_id, type, amount, running_balance, payment_method, transaction_date, etc.).
  2. Updates `business_accounts.balance` and `updated_at` for the account.
  3. Calls `LedgerRepository().createDoubleEntry(DR 1000 Cash / 1100 Bank, CR 1200 AR, source: 'payment_received', recordedBy: AuthService().currentStaffId)` when staff is logged in.
- **account_transactions** table created in 017 (CREATE TABLE IF NOT EXISTS) so schema exists where app inserts.

### 4. INVOICES
- **InvoiceRepository.approve():** Calls `_ledgerRepo.createDoubleEntry` with DR 5000 (Meat Purchases), CR 2000 (Accounts Payable), then sets invoice status to approved. Double-entry is correct and consistent.

### 5. PRODUCT SYSTEM — category_id
- **product_list_screen.dart:** Categories loaded with `id, name`; filter uses `_selectedCategoryFilterId` and `p['category_id']`. Form uses `_selectedCategoryId`; save sends `'category_id': _selectedCategoryId`. Display uses `_categoryNameById(p['category_id'])`. No reliance on a `category` text field for create/update or list filter.

---

## ISSUES FOUND

### 1. Stock display vs single source (MEDIUM)
- **Behaviour:** POS trigger (017) only decrements `inventory_items.current_stock`. Stock Levels screen and Product list “ON HAND” column use `stock_on_hand_fresh + stock_on_hand_frozen` only.
- **Effect:** After a POS sale, `current_stock` decreases but `stock_on_hand_fresh` / `stock_on_hand_frozen` are unchanged. Stock Levels and Product list will not reflect POS deductions.
- **Recommendation:** Either (a) have the sale trigger also update fresh/frozen (e.g. deduct from fresh first), or (b) make Stock Levels and Product list show `current_stock` (or a single “on hand” that prefers `current_stock` when present and falls back to fresh+frozen) so one source of truth is reflected everywhere.

### 2. Two stock representations (MEDIUM)
- **Fields:** `inventory_items` has both `current_stock` (used by POS trigger, InventoryRepository movements, analytics, reports) and `stock_on_hand_fresh` / `stock_on_hand_frozen` (used by Stock Levels, Product list ON HAND, freezer movements, stock-take).
- **Risk:** Divergence between “current_stock” and “fresh+frozen” unless all writers keep them in sync. 012 backfills `current_stock` from fresh+frozen where zero; trigger and movements do not currently update fresh/frozen on sale.

### 3. InventoryItem model still has category (text) (LOW)
- **Location:** `inventory_item.dart` — `toJson()` / `fromJson()` use `'category'` (String). Product form does not use this model for save; it builds a raw map and sends `category_id`.
- **Risk:** If any code later uses `InventoryItem.toJson()` for insert/update, it would send `category` instead of `category_id`. Currently no such usage found.

### 4. Account payment when not logged in (LOW)
- **Behaviour:** If `AuthService().currentStaffId` is null, payment is still saved to `account_transactions` and `business_accounts`, but no ledger entry is created (and a warning SnackBar is shown).
- **Recommendation:** Require PIN login before recording payments, or document that ledger will not be updated when not logged in.

---

## DATA FLOW MAP

### Shrinkage
```
production_batches UPDATE (actual_quantity set/changed)
  → check_shrinkage_threshold() [trigger]
  → INSERT shrinkage_alerts (batch_id, expected_weight, actual_weight, shrinkage_percentage, alert_type, status='Pending', resolved=false, item_name)
  → Dashboard / Analytics read and update status/resolved
```

### POS sales
```
transactions INSERT
  → post_pos_sale_to_ledger() [trigger]
  → INSERT ledger_entries ×2 (DR Cash/Bank/AR, CR 4000 Meat Sales; source='pos_sale')

transaction_items INSERT
  → deduct_stock_on_sale() [trigger]
  → UPDATE inventory_items SET current_stock = current_stock - quantity
```

### Account payments
```
User records payment (account_list_screen)
  → INSERT account_transactions
  → UPDATE business_accounts.balance
  → LedgerRepository.createDoubleEntry(DR 1000/1100, CR 1200; source='payment_received')
```

### Invoices
```
InvoiceRepository.approve(invoiceId, approvedBy)
  → LedgerRepository.createDoubleEntry(DR 5000 Meat Purchases, CR 2000 AP; source='invoice')
  → setStatus(invoiceId, approved)
```

### Product (category)
```
Product form save
  → inventory_items INSERT/UPDATE with category_id (no category text)
List / filter
  → Load categories (id, name); filter by category_id; display via _categoryNameById(category_id)
```

### Stock (current state)
```
POS sale        → trigger updates current_stock only
Waste/donation  → InventoryRepository updates current_stock and/or stock_on_hand_fresh/frozen
Production in/out → InventoryRepository updates current_stock or fresh/frozen
Stock take      → InventoryRepository.adjustStock() uses current_stock or fresh/frozen
Stock Levels UI → reads stock_on_hand_fresh + stock_on_hand_frozen only (does not reflect POS)
Product list ON HAND → same (fresh + frozen only)
```

---

## FINAL VERDICT

**NOT READY** for production without resolving stock consistency.

- **Blocking:** Stock Levels and Product list “ON HAND” do not reflect POS sales because they use `stock_on_hand_fresh` + `stock_on_hand_frozen` while the POS trigger only updates `current_stock`. Users will see incorrect “on hand” values after sales until either:
  - the trigger (or a sync) also updates fresh/frozen, or
  - the UI uses `current_stock` (or a single derived “on hand”) for display.
- **Recommendation:** Implement one of the options above so there is a single, consistent source of truth for “on hand” and all UIs and triggers align. After that, Phase 1 can be considered **PRODUCTION READY** from a data-flow and trigger perspective; the remaining items (InventoryItem category field, payment-without-login behaviour) are low severity and can be handled in a follow-up.
