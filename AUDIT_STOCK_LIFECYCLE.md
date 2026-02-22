# Stock Lifecycle Audit — Admin App vs Blueprint

**Blueprint (single source of truth):** `AdminAppBluePrintTruth.md`  
**Scope:** Stock lifecycle actions, stock_movements usage, inventory mutation. No code changes.

---

## 1. WHAT EXISTS (with file references)

### 1.1 Inventory mutation in code

| Location | Table | Operation | Purpose |
|----------|--------|-----------|---------|
| `admin_app/lib/features/inventory/screens/product_list_screen.dart` | `inventory_items` | `.update({'is_active': newVal})` (line 103–104) | Toggle product active/inactive |
| `admin_app/lib/features/inventory/screens/product_list_screen.dart` | `inventory_items` | `.insert(data)` / `.update(data)` (lines 609, 612–613) | Product add/edit form — writes plu_code, name, sell_price, cost_price, reorder_level, shelf_life, etc. **Does not** create stock_movements or perform lifecycle actions. |
| `admin_app/lib/features/production/screens/carcass_intake_screen.dart` | `carcass_intakes` | `.update({status, remaining_weight})` (lines 1758–1762) | Carcass breakdown — set status in_progress/completed |
| `admin_app/lib/features/production/screens/carcass_intake_screen.dart` | `carcass_cuts` | `.insert(...)` (lines 1764–1774) | Carcass breakdown — log cut names, expected_kg, actual_kg, plu_code, sellable, breakdown_date. **Does not** insert into stock_movements or update inventory_items.stock_on_hand. |

No other files in `lib` perform insert/update on `inventory_items` or insert into `stock_movements`.

### 1.2 Stock data read (display only)

| Location | What is read |
|----------|----------------|
| `product_list_screen.dart` (lines 247–255) | `stock_on_hand_fresh`, `stock_on_hand_frozen`, `reorder_level` from `inventory_items` — used for display and reorder indicator. Not mutated by any lifecycle action. |
| `report_repository.dart` (line 37) | `inventory_items` for getInventoryValuation (id, name, current_stock, cost_price, selling_price, category_id). |
| `dashboard_screen.dart` (line 126) | `reorder_recommendations` with `inventory_items(name)` for alert text. |

### 1.3 References to lifecycle concepts (no implementation)

| Location | Context |
|----------|---------|
| `report_hub_screen.dart` (line 38) | Report type title only: `'Sponsorship & Donations'` — no screen or flow to record sponsorship/donation. |
| `invoice_list_screen.dart` (lines 309, 321–322) | Static P&L rows: "Shrinkage / Waste", "Marketing & Sponsorship", "Donations" — hardcoded sample data; no link to stock actions. |
| `shrinkage_screen.dart` (line 165) | Button label `'Trigger Stock Take'` — calls `_handleAction(alertId, 'StockTakeTriggered')` which updates shrinkage_alert status only (AnalyticsRepository.updateShrinkageStatus). Does **not** start a stock-take session, record counts, or adjust stock. |
| `report_repository.dart` (line 80) | Comment only: "Typically an RPC grouping by supplier from incoming invoices/stock_movements" — no query or insert to stock_movements. |

### 1.4 Stock Levels and Movement History (blueprint §4.4, §4.5)

| Blueprint | Implementation |
|-----------|----------------|
| Sidebar → Inventory → Stock Levels: table of Product, On Hand, Fresh, Frozen, Reorder, Status | **Placeholder only.** `inventory_navigation_screen.dart` — `_StockLevelsPlaceholderScreen` (lines 191–236): static text "Stock Levels", "Monitor inventory levels... Track stock movements..."; button "View Stock Levels" shows SnackBar "Stock level management coming soon". No table, no data. |
| Per-product Movement History tab: Date, Type, Qty, Balance, Reference | **Not implemented.** No screen or tab shows movement history. No query of stock_movements. |

### 1.5 stock_movements table usage

- **Blueprint §15:** `stock_movements` — "Production / Inventory (all types)".
- **Codebase:** No `.from('stock_movements')` anywhere in `admin_app/lib`. No insert into stock_movements. Only mention is the comment in `report_repository.dart` (line 80). **stock_movements is never read from or written to.**

---

## 2. WHAT IS MISSING (explicitly from blueprint)

### 2.1 Blueprint §4.5 Stock Lifecycle Actions

| Action | Blueprint requirement | In app? |
|--------|-----------------------|--------|
| **Move to Freezer** | Admin → Inventory. Select product + quantity, "Move to Freezer" button; prompt markdown % (per product); new variant "T-Bone (Previously Frozen)"; fresh reduced, frozen increased; new PLU; print labels. | ❌ No UI, no button, no flow, no inventory update for this action. |
| **Waste / Disposal** | Admin → Inventory. "Log Waste" button; Reason (Expired/Spoiled/Dropped/Trimming/Customer Return); Staff ID; optional photo; Save → stock_movements created, stock_on_hand reduced; in shrinkage reports. | ❌ No UI, no button, no flow, no stock_movements insert, no inventory reduction. |
| **Donation** | Admin → Inventory. Separate from waste. Recipient, Type, Value, Date; stock reduced + ledger (6510 Donations); P&L Donation Expense. | ❌ No UI, no button, no flow, no stock or ledger write. |
| **Sponsorship / Marketing** | Admin → Inventory. Recipient, Event, Date, Description, Estimated Value; stock reduced + ledger (6500 Marketing); P&L Marketing Expense. | ❌ No UI, no button, no flow, no stock or ledger write. |
| **Transfer Between Locations** | Admin → Inventory. Move between locations (e.g. Display Fridge 1 → Deep Freezer 3); total on-hand unchanged. | ❌ No UI, no flow. |
| **Stock-Take Adjustment** | Admin → Inventory. Correct stock to actual count; log variance. Blueprint §4.7: Start Stock-Take, session, locations, enter actual qty, variance, approve → stock adjusted; variances to stock_movements + audit_logs. | ❌ No Stock-Take screen, no session, no count entry, no approval, no stock adjustment, no stock_movements. Only "Trigger Stock Take" on shrinkage alert updates alert status. |
| **Stock movements log** | Blueprint §4.4: Movement History per product — Date, Type, Qty, Balance, Reference. Blueprint §4.5: Waste "stock_movements created"; §4.7: Stock-Take "variances logged to stock_movements". | ❌ No UI to view movements; no code writes to stock_movements. |

### 2.2 Carcass breakdown and stock (blueprint §5.3)

- Blueprint: "stock_movements records created for each cut" and "inventory_items.stock_on_hand updated for each cut".
- Implementation: Carcass breakdown only updates `carcass_intakes` and inserts `carcass_cuts`. **No** insert into stock_movements. **No** update to inventory_items.stock_on_hand. Cuts are logged but stock is not increased for the produced cuts.

### 2.3 Other lifecycle-related (no UI)

- **Markdown (Still Fresh):** Blueprint §4.5 — reduces sell price, new barcode label. Not implemented.
- **Staff Meal:** Blueprint §4.5 — reduces stock, staff ID. Not implemented.
- **Sale:** POS (auto) reduces stock — assumed backend/POS; not part of admin app audit.

---

## 3. WHAT IS INCORRECT (deviations)

### 3.1 Carcass breakdown does not update inventory

- **Blueprint §5.3 Complete Breakdown:** "stock_movements records created for each cut" and "inventory_items.stock_on_hand updated for each cut".
- **Implementation:** `carcass_intake_screen.dart` inserts into `carcass_cuts` only. No stock_movements insert, no inventory_items update. Breakdown is recorded for yield/blockman purposes but **does not increase sellable stock** in the system. Result: production data and inventory on-hand are disconnected.

### 3.2 "Trigger Stock Take" does not perform stock-take

- **Blueprint §4.7:** Stock-Take = start session, select location, enter actual counts, variance, approve → stock adjusted, variances to stock_movements + audit_logs.
- **Implementation:** "Trigger Stock Take" in shrinkage screen only calls `_handleAction(alertId, 'StockTakeTriggered')` → `AnalyticsRepository.updateShrinkageStatus(alertId, action)`. That updates the shrinkage_alert row (e.g. status). It does **not** start a stock-take session, capture counts, or adjust stock. Label is misleading relative to blueprint.

### 3.3 Stock Levels tab is non-functional

- Blueprint §4.4: Stock Levels = table view of products with On Hand, Fresh, Frozen, Reorder, Status, and per-product Movement History.
- Implementation: Placeholder with static text and a button that shows "coming soon". No data, no movements. Structurally present, functionally missing.

---

## 4. SYSTEM IMPACT (what breaks because of this)

### 4.1 Inventory accuracy

- **Stock on hand** is only changed by: (1) product form (reorder_level, shelf life, etc. — not on-hand quantities), and (2) active toggle. No lifecycle actions (waste, donation, sponsorship, move to freezer, transfer, stock-take) write to inventory or stock_movements. So:
  - Any waste, donation, or move to freezer done outside the system is not reflected.
  - Stock-Take cannot correct system stock to actual counts.
  - Carcass breakdown does not increase stock for cuts; production and inventory stay out of sync.
- **Result:** On-hand figures in the app are not a reliable record of physical stock. Reorder and shrinkage logic depend on correct stock; both are undermined.

### 4.2 Shrinkage analytics

- Blueprint §10.1: Theoretical stock = Opening + Purchases + Production − Sales − **Logged Waste** − Moisture Loss; gap vs actual → alert.
- **Logged waste** requires Waste flow that creates stock_movements and reduces stock. That flow does not exist. So:
  - Waste is not logged in the system; "Logged Waste" in the formula is missing.
  - Shrinkage alerts (if generated elsewhere) are based on incomplete data; expected vs actual cannot be reconciled properly.
- Donation and sponsorship also reduce stock; without those actions, revenue/expense and stock are inconsistent and P&L lines for 6500/6510 are not driven by real actions.

### 4.3 P&L and ledger

- Blueprint §9.3: Donation → 6510 Donations; Sponsorship → 6500 Marketing. These require stock reduction + ledger entry from the Donation/Sponsorship flows. Those flows do not exist, so:
  - No automatic ledger entries from donation or sponsorship.
  - Static P&L rows for "Donations" and "Marketing & Sponsorship" are placeholders only; they do not reflect system-recorded events.

### 4.4 Move to Freezer and pricing

- Per-product freezer markdown % exists in the product form (freezer_markdown_pct). There is no "Move to Freezer" action that uses it to create a frozen variant, reduce fresh, increase frozen, or apply markdown. So:
  - Freezer stock and pricing cannot be managed as per blueprint; fresh/frozen split in the app is not updated by this lifecycle.

### 4.5 Stock-Take and variance

- Without a Stock-Take flow (session, counts, approval, adjustment), variances between system and physical count cannot be recorded or applied. Shrinkage and inventory accuracy cannot be corrected through the app after a count.

### 4.6 Summary table

| Missing capability | Impact |
|--------------------|--------|
| Move to Freezer | Fresh/frozen quantities and freezer pricing not updated by workflow. |
| Waste | Waste not logged; shrinkage formula incomplete; stock overstated. |
| Donation / Sponsorship | Stock and P&L (6500/6510) not updated from these actions. |
| Transfer Between Locations | Location-level stock not movable; multi-location view meaningless. |
| Stock-Take | Cannot reconcile or correct stock from physical count. |
| stock_movements never written | No audit trail of stock changes; movement history empty. |
| Carcass breakdown not updating stock | Production increases not reflected in inventory; on-hand wrong for cuts. |

---

## 5. COMPLETION % FOR THIS MODULE (stock lifecycle)

**Module:** Stock lifecycle as defined in blueprint §4.4 (Stock Levels & Movement Log), §4.5 (Stock Lifecycle Actions), §4.7 (Stock-Take), and §5.3 (stock_movements + inventory update on breakdown).

| Criterion | Blueprint | Status | Score |
|-----------|-----------|--------|-------|
| Move to Freezer (UI + flow + markdown % + stock update) | Required | Not implemented | 0% |
| Waste / Disposal (UI + reason, staff, photo + stock_movements + stock reduce) | Required | Not implemented | 0% |
| Donation (UI + recipient/type/value + stock + ledger 6510) | Required | Not implemented | 0% |
| Sponsorship (UI + recipient/event/value + stock + ledger 6500) | Required | Not implemented | 0% |
| Transfer Between Locations | Required | Not implemented | 0% |
| Stock-Take (session, locations, counts, variance, approve, adjust stock, log to stock_movements) | Required | Not implemented; "Trigger Stock Take" only updates alert | 0% |
| Stock Levels screen (table + per-product movement history) | Required | Placeholder only; no data, no movements | 0% |
| stock_movements table used (read or write) | Required for all lifecycle types | Never read or written | 0% |
| Carcass breakdown creates stock_movements + updates inventory_items.stock_on_hand | Required | Only carcass_cuts inserted; no stock_movements, no inventory update | 0% |
| Product form / toggle (existing inventory mutation) | N/A | Exists for product CRUD and is_active only; not a lifecycle action | — |

**Completion % for stock lifecycle system:** **0%**

Reason: None of the blueprint-defined lifecycle actions (Move to Freezer, Waste, Donation, Sponsorship, Transfer, Stock-Take) are implemented. stock_movements is not used. Carcass breakdown does not update stock or create movements. Stock Levels is a placeholder only. The only inventory mutations in the app are product add/edit and active toggle, and (in production) carcass_intakes/carcass_cuts updates that do not touch stock or stock_movements.

---

## 6. GAP SUMMARY

- **Exists:** Product list reads stock_on_hand_fresh/frozen and reorder_level for display. Product form and active toggle update inventory_items. Carcass breakdown updates carcass_intakes and inserts carcass_cuts. Placeholder Stock Levels tab. Shrinkage "Trigger Stock Take" (updates alert only). Report title and static P&L rows mentioning sponsorship/donations/waste. No use of stock_movements anywhere.
- **Missing:** All lifecycle actions (Move to Freezer, Waste, Donation, Sponsorship, Transfer, Stock-Take); Stock Levels and Movement History implementation; any read or write of stock_movements; carcass breakdown updating inventory and creating stock_movements.
- **Incorrect:** Carcass breakdown does not update stock; "Trigger Stock Take" does not run a stock-take; Stock Levels is non-functional.
- **Impact:** Inventory accuracy and shrinkage analytics cannot be maintained; P&L for waste/donation/sponsorship not driven by app actions; production and inventory out of sync.
- **Completion:** 0% for the stock lifecycle module.

---

*Audit only. No code was modified. No fixes suggested.*
