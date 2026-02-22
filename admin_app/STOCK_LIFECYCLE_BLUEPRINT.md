# Stock Lifecycle System — Blueprint Implementation

Blueprint §4.5: Stock lifecycle actions — every stock change MUST create a movement record; stock levels must update correctly.

---

## 1. Data model

### StockMovement + MovementType

| File | Purpose |
|------|--------|
| `lib/core/models/stock_movement.dart` | **MovementType** enum: in_, out, adjustment, transfer, waste, production, donation, sponsorship, staffMeal, freezer. **StockMovement** — id, itemId, movementType, quantity, unitCost, totalCost, referenceType, referenceId, locationFromId, locationToId, performedBy, performedAt, notes, metadata. fromJson/toJson, validate. |

- `MovementType.dbValue` maps to DB strings (`in`, `waste`, `donation`, etc.).
- `MovementTypeExt.fromDb()` parses DB string to enum.
- `reducesStock` / `increasesStock` drive repository stock updates.

---

## 2. Supabase schema

### Existing (001)

- **stock_movements**: item_id, movement_type (in, out, adjustment, transfer, waste, production), quantity, unit_cost, total_cost, reference_type, reference_id, location_from, location_to, performed_by, performed_at, notes.

### Migration 005

| File | Content |
|------|--------|
| `supabase/migrations/005_stock_lifecycle_blueprint.sql` | Add **metadata** JSONB. Extend **movement_type** CHECK to include: donation, sponsorship, staff_meal, freezer. |

**Required fields (blueprint):** product_id → **item_id**, quantity, type → **movement_type**, reason → **notes** (and/or metadata), staff_id → **performed_by**, timestamp → **performed_at**, metadata.

---

## 3. Repository layer

| File | Methods |
|------|--------|
| `lib/features/inventory/services/inventory_repository.dart` | **recordMovement(...)** — insert stock_movements row, then _applyStockChange (update inventory_items: current_stock or stock_on_hand_fresh/frozen). **adjustStock(itemId, actualQuantity, performedBy, notes)** — stock-take: insert adjustment movement with metadata {previous, actual}, set current_stock (or fresh/frozen) to actualQuantity. **transferStock(itemId, quantity, locationFromId, locationToId, performedBy, notes)** — single transfer movement; total on-hand unchanged. **getMovementHistory(itemId, limit)** — list StockMovement for product. |

**Business rule:** Every stock change goes through the repository; a movement row is always created; inventory_items stock is updated when applicable (reducesStock / increasesStock / freezer for fresh↔frozen).

---

## 4. UI implementation

### Action buttons (product list)

| File | Change |
|------|--------|
| `lib/features/inventory/screens/product_list_screen.dart` | Added **Stock** icon button (Icons.inventory_2) per row. On tap → **showStockActionsMenu(context, product, onDone: _loadData)**. ACTIONS column width 120. |

### Dialogs (clean modal flows)

| File | Dialogs |
|------|--------|
| `lib/features/inventory/widgets/stock_movement_dialogs.dart` | **showStockActionsMenu** — picker dialog (Waste, Transfer, Move to Freezer, Donation, Sponsorship, Stock Take, Movement History). **showWasteDialog** — quantity, reason (optional). **showTransferDialog** — quantity, From/To location (stock_locations). **showFreezerDialog** — quantity, markdown %. **showDonationDialog** — quantity, recipient, type, value, date. **showSponsorshipDialog** — quantity, recipient, event, date, description, estimated value. **showStockTakeDialog** — actual count, notes. **showMovementHistoryDialog** — list of movements for product. All use InventoryRepository + AuthService.currentStaffId (performedBy). |

---

## 5. Data flow (end-to-end)

### Before → action → after

1. **Before:** User sees product list with On Hand; inventory_items has current_stock (or stock_on_hand_fresh + stock_on_hand_frozen).
2. **Action:** User taps Stock → chooses e.g. Waste → enters quantity and reason → Record Waste.
3. **Repository:** `recordMovement(itemId, MovementType.waste, quantity, performedBy: staffId, notes, metadata)`. Inserts into stock_movements; _applyStockChange decrements current_stock (or fresh).
4. **After:** Product list refreshes (onDone = _loadData); On Hand reduced; movement appears in Movement History.

### Flow summary by action

| Action | Dialog | Repository call | DB effect |
|--------|--------|------------------|-----------|
| Waste | Quantity, reason | recordMovement(waste) | stock_movements row; stock ↓ |
| Transfer | Quantity, From, To | transferStock(...) | stock_movements row (transfer); total unchanged |
| Move to Freezer | Quantity, markdown % | recordMovement(freezer, metadata: markdown_pct) | stock_movements row; fresh ↓ frozen ↑ (if columns exist) |
| Donation | Qty, recipient, type, value, date | recordMovement(donation, metadata) | stock_movements row; stock ↓ |
| Sponsorship | Qty, recipient, event, date, desc, value | recordMovement(sponsorship, metadata) | stock_movements row; stock ↓ |
| Stock Take | Actual count, notes | adjustStock(itemId, actualQuantity, ...) | stock_movements (adjustment); current_stock = actual |
| Movement History | — | getMovementHistory(itemId) | Read-only list |

---

## 6. File list

- `lib/core/models/stock_movement.dart` — model + enum
- `supabase/migrations/005_stock_lifecycle_blueprint.sql` — metadata + movement_type
- `lib/features/inventory/services/inventory_repository.dart` — recordMovement, adjustStock, transferStock, getMovementHistory
- `lib/features/inventory/widgets/stock_movement_dialogs.dart` — all dialogs + showStockActionsMenu
- `lib/features/inventory/screens/product_list_screen.dart` — Stock button + import

This system is airtight for inventory accuracy: every stock-changing action creates a movement and updates stock levels through the repository.
