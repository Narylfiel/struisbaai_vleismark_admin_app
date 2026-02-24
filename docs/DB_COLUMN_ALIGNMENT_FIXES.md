# DB column alignment — insert/update payloads and toJson()

Only Flutter-side renames/removals; no DB columns added. Read/display code left unchanged except where a query used a wrong column name (e.g. order by).

## staff_awol_records
- **No changes.** Insert and update payloads already use: staff_id, awol_date, expected_start_time, notified_owner_manager, notified_who, resolution, written_warning_issued, warning_document_url, notes, recorded_by.

## staff_credit
- **No changes to payloads.** Create/update use correct names (credit_amount, granted_date, is_paid, paid_date, granted_by, notes, credit_type, items_purchased, repayment_plan, deduct_from, status).
- **toJson():** Already does not include `updated_at` (table has no updated_at).

## staff_loans
- **No insert/update in lib.** Table not used for writes.

## payroll_entries
- **No insert/update in lib.** Only selects.

## leave_requests
- **No changes.** Update uses status, review_notes, reviewed_at.

## purchase_orders
- **No changes.** Insert uses po_number, supplier_id, status, order_date.

## purchase_order_lines
- **No changes.** Insert uses purchase_order_id, inventory_item_id, quantity, unit, unit_price, line_total (from spread).

## account_transactions
- **No changes.** Inserts use account_id, transaction_type, reference, description, amount, running_balance, payment_method, transaction_date.

## ledger_entries
- **No changes.** Insert uses entry_date, account_code, account_name, debit, credit, description, reference_type, reference_id, source, metadata, recorded_by.

## invoices
- **No changes.** Inserts and invoice.toJson() use only valid columns (invoice_number, supplier_id, account_id, invoice_date, due_date, subtotal, tax_amount, total, status, notes, created_by, created_at, updated_at).

## stock_take_sessions
- **No changes.** Insert/update use status, started_at, started_by, notes; approve adds approved_at, approved_by, updated_at.

## stock_take_entries
- **Actual DB columns:** id, session_id, item_id, location_id, expected_quantity, actual_quantity, variance, counted_by, device_id, created_at, updated_at (no notes).
- **Repository payloads:** Use item_id (not inventory_item_id), expected_quantity (not expected_qty), actual_quantity (not counted_qty); update includes updated_at. No notes in insert/update.
- **StockTakeEntry toJson():** Uses item_id, expected_quantity, actual_quantity, variance, updated_at.
- **StockTakeEntry fromJson():** Reads item_id, expected_quantity, actual_quantity, variance from DB.
- **stock_take_screen.dart:** Uses model properties (itemId, expectedQuantity, actualQuantity, variance) only; no raw column names — no changes needed.

## stock_movements
- **Renamed in insert payloads:**  
  `performed_by` → **staff_id**
- **Removed from insert payloads:**  
  **unit_cost**, **total_cost** (not in table).
- **InventoryRepository:** `getMovementHistory` order changed from `performed_at` to **created_at** (table has no performed_at).
- **StockMovement toJson():** Uses **staff_id** instead of performed_by; removed unit_cost, total_cost, performed_at.
- **StockMovement fromJson():** Reads **staff_id** (fallback performed_by) for performedBy.

## carcass_intakes
- **Insert payload:**  
  **Removed:** invoice_number, invoice_weight (no such columns).  
  **Renamed:** actual_weight → **weight_in**.
- **Update payload:** Unchanged (status, remaining_weight, updated_at all valid).

## announcements
- **No changes.** Insert uses title, content, target_audience, created_by, created_at.

## equipment_register
- **No changes.** Insert/update use description, asset_number, location, purchase_date, purchase_price, depreciation_rate, depreciation_method, useful_life_years, status, category.
