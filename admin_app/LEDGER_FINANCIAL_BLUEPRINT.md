# Ledger-Based Financial System — Blueprint Implementation

Blueprint §9: **ledger_entries** as the single financial truth. Every financial event must create ledger entries. P&L, VAT, and Cash Flow are rebuilt from the ledger.

---

## 1. Data model

### LedgerEntry

| File | Purpose |
|------|--------|
| `lib/core/models/ledger_entry.dart` | **LedgerEntry** — id, entryDate, accountCode, accountName, debit, credit, description, referenceType, referenceId, source, metadata, recordedBy. fromJson/toJson, validate. |

- **date** → `entryDate`
- **type** (event type) → `source` (pos_sale, invoice, payment_received, waste, donation, sponsorship, etc.)
- **amount** → one of debit or credit (double-entry: two rows per event)
- **reference_id** → `referenceId` (transaction_id, invoice_id, stock_movement id)
- **source** → event that created the entry
- **metadata** → JSONB for extra context

---

## 2. Supabase schema

### Existing (002)

- **ledger_entries**: id, entry_date, account_code, account_name, debit, credit, description, reference_type, reference_id, recorded_by, created_at.

### Migration 006

| File | Content |
|------|--------|
| `supabase/migrations/006_ledger_financial_truth.sql` | Add **source** TEXT, **metadata** JSONB. Indexes on source and (entry_date, account_code). |

**Required fields (blueprint):** date, type (source), amount (debit/credit), reference_id, source, metadata.

---

## 3. Repository layer

| File | Methods |
|------|--------|
| `lib/features/bookkeeping/services/ledger_repository.dart` | **createEntry(...)** — insert one ledger row (one leg). **createDoubleEntry(...)** — insert debit + credit legs with same reference_id/source. **getEntriesByDate(start, end)** — list entries in period. **getByType(source)** — list entries by event type. **getEntriesByAccount(accountCode, start, end)** — for VAT/cash. **getPnLSummary(start, end)** — sums by account_code (debit/credit). **getVatSummary(start, end)** — output/input/payable from account 2100. **getCashFlowSummary(start, end)** — cash (1000) and bank (1100) in/out. |

---

## 4. Integration rules (every financial event creates ledger entries)

| Event | Integration point | Ledger effect |
|-------|-------------------|---------------|
| **POS sale** | POS writes `transactions`; Admin or DB trigger/Edge Function creates ledger entries | Debit 1000/1100/1200 (cash/card/AR), Credit 4000 Revenue + 2100 VAT |
| **Invoice** (supplier) | Bookkeeping → approve invoice | Debit 5000 COGS, Credit 2000 AP (Blueprint §9.3) |
| **Payment received** (account) | Account payment recorded | Debit 1100 Bank, Credit 1200 AR |
| **Waste** | Stock movement (Waste dialog) | After recordMovement → LedgerRepository.createDoubleEntry: Debit 5300 Shrinkage/Waste, Credit 1300 Inventory (at cost) |
| **Donation** | Stock movement (Donation dialog) | After recordMovement → createDoubleEntry: Debit 6510 Donations, Credit 1300 Inventory |
| **Sponsorship** | Stock movement (Sponsorship dialog) | After recordMovement → createDoubleEntry: Debit 6500 Marketing & Sponsorship, Credit 1300 Inventory |

**POS sale → ledger:** Implement via Supabase trigger on `transactions` insert, or Edge Function, or Admin “Post daily sales” that reads transactions and creates ledger entries. Admin app does not duplicate POS logic; LedgerRepository is the single API for creating entries.

---

## 5. Refactor: remove hardcoded financial calculations

| Before | After |
|--------|--------|
| P&L / Reports tab used hardcoded amounts (153730, 94920, 58810, 11550, etc.) | **P&L, VAT, Cash Flow** all from LedgerRepository.getEntriesByDate + getPnLSummary, getVatSummary, getCashFlowSummary |
| No ledger source | All figures derived from **ledger_entries** for the selected period |

---

## 6. Rebuild: P&L, VAT, Cash Flow from ledger

### P&L (Blueprint §9.4)

- **Source:** LedgerRepository.getPnLSummary(periodStart, periodEnd).
- **Revenue:** Sum of **credit** for accounts 4000, 4100, 4200.
- **COGS:** Sum of **debit** for 5000, 5100, 5200, 5300.
- **Gross profit:** Revenue − COGS.
- **Operating expenses:** Sum of **debit** for 6000–6900.
- **Net profit:** Gross profit − Operating expenses.
- **UI:** Bookkeeping → P&L / Reports tab; period selector; no hardcoded numbers.

### VAT report (Blueprint §9.5)

- **Source:** LedgerRepository.getVatSummary(periodStart, periodEnd).
- **Account 2100:** credit = Output VAT (sales), debit = Input VAT (purchases).
- **VAT Payable:** output − input.
- **UI:** Same Reports tab; VAT card from ledger.

### Cash flow (Blueprint §9.6)

- **Source:** LedgerRepository.getCashFlowSummary(periodStart, periodEnd).
- **1000 Cash:** debit = cash in, credit = cash out.
- **1100 Bank:** debit = bank in, credit = bank out.
- **UI:** Cash Flow card on Reports tab.

---

## 7. Example flows

### Sale → Ledger → Report

1. **POS records sale:** transaction R295.90 (cash). (POS writes to `transactions`.)
2. **Ledger entries created** (by trigger, Edge Function, or Admin “Post sales”):
   - Debit 1000 Cash R295.90, description “POS sale”, source `pos_sale`, reference_id = transaction.id.
   - Credit 4000 Revenue R257.30, Credit 2100 VAT R38.60, same reference_id/source.
3. **P&L report:** getPnLSummary(Feb 1, Feb 28) → Revenue includes R257.30 from 4000; VAT report includes R38.60 output from 2100.

### Waste → Ledger → P&L

1. **User records waste:** 2 kg mince, cost R80/kg. Stock movement created (stock_movements + inventory updated).
2. **Ledger:** createDoubleEntry(Debit 5300 R160, Credit 1300 R160, source `waste`, reference_id = movement.id).
3. **P&L:** COGS (5300) includes R160; Shrinkage / Waste line shows R160.

### Donation → Ledger → P&L

1. **User records donation:** 1 kg steak, cost R120. Donation dialog creates stock movement.
2. **Ledger:** createDoubleEntry(Debit 6510 R120, Credit 1300 R120, source `donation`).
3. **P&L:** Operating expenses — Donations (6510) shows R120.

---

## 8. File list

- `lib/core/models/ledger_entry.dart` — LedgerEntry model
- `supabase/migrations/006_ledger_financial_truth.sql` — source, metadata, indexes
- `lib/features/bookkeeping/services/ledger_repository.dart` — createEntry, createDoubleEntry, getEntriesByDate, getByType, getPnLSummary, getVatSummary, getCashFlowSummary
- `lib/features/bookkeeping/screens/invoice_list_screen.dart` — P&L / VAT / Cash Flow from ledger; period selector; no hardcoded amounts
- `lib/features/inventory/widgets/stock_movement_dialogs.dart` — Waste / Donation / Sponsorship create ledger entries after recordMovement

This system is mandatory for real accounting accuracy: all financial figures flow from **ledger_entries**.
