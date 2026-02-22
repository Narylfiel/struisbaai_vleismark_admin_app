# Financial System & Ledger Audit — Admin App vs Blueprint

**Blueprint (single source of truth):** `AdminAppBluePrintTruth.md`  
**Scope:** ledger_entries usage, P&L, VAT, Cash Flow, chart of accounts, and any transaction flows that should write to ledger. No code changes.

---

## 1. WHAT EXISTS (with file references)

### 1.1 ledger_entries table

- **Blueprint §15:** `ledger_entries` — Bookkeeping. §9.3: Events (cash sale, card sale, account sale, supplier invoice, account payment, payroll, sponsorship, donation, purchase sale repayment) auto-generate ledger entries (debit/credit by account).
- **Codebase:** No reference to `ledger_entries` anywhere in `admin_app/lib`. Grep for `ledger_entries`, `ledger_entry`, and `.from('...ledger` returns **no matches**. The table is **never read from or written to**.

### 1.2 Chart of Accounts

| Location | What exists |
|----------|-------------|
| `admin_app/lib/features/bookkeeping/screens/invoice_list_screen.dart` | **_ChartOfAccountsTab** (lines 188–278): Reads `chart_of_accounts` via `_supabase.from('chart_of_accounts').select('*').order('account_number')` (line 208). Displays account_number, name, type, balance in a list. "Add Account" button has `onPressed: () {}` — no implementation. No edit/rename/delete UI. No check for "has transactions" before delete. No link to or aggregation from ledger_entries. |

Chart of accounts is **read-only display** from `chart_of_accounts`; balances shown are whatever is stored on the account row (not necessarily derived from ledger in this app).

### 1.3 P&L Statement

| Location | What exists |
|----------|-------------|
| `admin_app/lib/features/bookkeeping/screens/invoice_list_screen.dart` | **_ReportsTab** (lines 285–379): ** _buildPnLCard()** (287–332) builds a card titled "PROFIT & LOSS STATEMENT" with subtitle "Botha's Butchery (Pty) Ltd - Period: February 2026". All line amounts are **literal constants** in code: `_pnlRow('Meat Sales (POS)', 145230.00)`, `_pnlRow('Hunter Processing Fees', 8500.00)`, `_pnlRow('Meat Purchases', 85340.00)`, etc. through Total Revenue, COGS, Gross Profit, Operating Expenses, Net Profit. No period selector. No query of ledger_entries or any other table for P&L data. No aggregation by account or period. |

P&L is **hardcoded sample data** only; it does not auto-generate from ledger.

### 1.4 VAT Report

| Location | What exists |
|----------|-------------|
| Same file, **_ReportsTab** | **_buildVatCard()** (347–365): Card titled "VAT REPORT (SARS VAT201)". Three lines: `_pnlRow('Output VAT (Sales)', 20052.00)`, `_pnlRow('Input VAT (Purchases)', 12450.00)`, `_pnlRow('VAT Payable to SARS', 7602.00, ...)`. All values are **literal constants**. No period selector. No query of ledger_entries or VAT-related accounts (e.g. 2100). |

VAT report is **hardcoded**; it does not auto-generate from ledger.

### 1.5 Cash Flow View

- **Blueprint §9.6:** Cash Flow view — Opening Balance, + Cash Sales, + Card Sales, + Account Payments, − Supplier Payments, − Salaries, etc. = Closing Balance.
- **Codebase:** No dedicated Cash Flow screen or tab. **report_hub_screen.dart** (line 24) lists a report type `{'title': 'Cash Flow', 'freq': 'Monthly (auto)', ...}`; (line 316) text "P&L, VAT, Cash Flow (Dashboard + Email + Google Drive)". There is **no** UI that displays a cash flow statement (opening/closing, inflows/outflows) and **no** query of ledger or any table to build it. **account_list_screen.dart** (lines 811, 821) uses "Opening Balance" and "= Closing Balance" only in the context of a **single business account statement**, not the group cash flow view from §9.6.

Cash Flow as defined in the blueprint (period-based, from ledger) **does not exist**.

### 1.6 Transaction flows that should create ledger entries (blueprint)

| Blueprint event | Expected | In app |
|-----------------|----------|--------|
| Account payment received (§8.3) | "Balance reduced \| Ledger entry auto-created" | **account_list_screen.dart** (1791–1809): Inserts into `account_transactions`, updates `business_accounts.balance`. **No** insert into `ledger_entries`. |
| Supplier invoice approved (§9.1) | "Auto-creates Accounts Payable ledger entry" | Invoices tab: list only; manual add is placeholder dialog; no approval flow. No ledger entry created. |
| Cash sale, card sale, account sale (§9.3) | Ledger entries (e.g. 1000/1100/1200 Dr, 4000/2100 Cr) | Handled by POS/backend; not visible in admin app. Admin app does not write ledger for these. |
| Payroll, sponsorship, donation, purchase sale repayment (§9.3) | Ledger entries | No flows in app that create these ledger entries (no payroll run writing to ledger in bookkeeping; no donation/sponsorship UI; PTY repayment may be elsewhere). |

The only **transaction flow implemented in the app** that blueprint says should auto-create a ledger entry is **account payment**. That flow updates `business_accounts` and `account_transactions` but **does not** write to `ledger_entries`.

### 1.7 Bookkeeping screen structure

| Tab | File | Content |
|-----|------|---------|
| Invoices | invoice_list_screen.dart | List from `invoices`; "Add Manually" → placeholder dialog; "Bulk Import CSV" → `onPressed: () {}`. No approval flow, no ledger. |
| Chart of Accounts | Same | Read-only list from `chart_of_accounts`; "Add Account" → no-op. |
| P&L / Reports | Same | P&L card + VAT card; both hardcoded. No Cash Flow card/section. |
| PTY Conversion | Same | _PtyConversionTab — equipment_register; no ledger or cash flow. |

There is **no** ledger_screen, ledger_entry model, or any UI that lists or filters ledger_entries.

---

## 2. WHAT IS MISSING (explicitly from blueprint)

### 2.1 ledger_entries as financial backbone

- **Blueprint §9.3:** Auto-generated ledger entries for: cash sale, card sale, account sale, supplier invoice, account payment received, payroll, sponsorship, donation, purchase sale repayment. Each event has Debit/Credit accounts and amounts.
- **Blueprint §9.4:** "P&L Statement … Select period — **auto-generates from ledger**".
- **Blueprint §9.5:** "VAT Report … **Auto-generates** VAT201 data" (from ledger implied by §9.3 accounts 2100, etc.).
- **Blueprint §9.6:** Cash Flow View — opening, inflows, outflows, closing (from ledger/accounts implied).
- **Blueprint §15:** ledger_entries — Bookkeeping.

**Missing in app:**

- Any read from `ledger_entries` (for P&L, VAT, Cash Flow, or ledger view).
- Any insert into `ledger_entries` (for account payment, invoice approval, or any other event).
- P&L generated from ledger (period + aggregate ledger by account type).
- VAT report generated from ledger (e.g. output/input VAT from ledger entries).
- Cash Flow view generated from ledger or from movements in cash/bank/AR/AP accounts.
- Standalone ledger screen or ledger view (blueprint §16 lists ledger_screen.dart).

### 2.2 Chart of Accounts — full behaviour

- **Blueprint §9.2:** Chart is fully editable; new accounts can be added, existing renamed; accounts cannot be deleted if they have transactions — only deactivated.
- **Implementation:** Chart is displayed only; "Add Account" does nothing; no rename/delete/deactivate UI; no check against ledger_entries or "has transactions".

### 2.3 Period selection for P&L / VAT / Cash Flow

- Blueprint §9.4: "Select period" for P&L. §9.5 / §9.6: period-based VAT and Cash Flow.
- Implementation: P&L and VAT show fixed text "Period: February 2026" and fixed numbers; no period picker; no date-range-driven query.

---

## 3. WHAT IS INCORRECT (deviations)

### 3.1 P&L and VAT are not from ledger

- Blueprint: P&L and VAT **auto-generate** from ledger for a selected period.
- Implementation: Both are **static UI** with hardcoded amounts. Same numbers every time; no connection to ledger_entries or to real transactions. Labelled as "PROFIT & LOSS STATEMENT" and "VAT REPORT (SARS VAT201)" but they are **placeholders**, not reports.

### 3.2 Account payment does not create ledger entry

- Blueprint §8.3: "Balance reduced | **Ledger entry auto-created**".
- Implementation: account_list_screen records payment in `account_transactions` and updates `business_accounts.balance`. No insert into `ledger_entries`. So the financial backbone is not updated; P&L/VAT/Cash Flow cannot reflect this payment even if they were built from ledger later.

### 3.3 Chart of Accounts balance source

- Blueprint implies ledger drives account balances (double-entry; entries post to accounts).
- Implementation: Chart tab displays `acc['balance']` from `chart_of_accounts`. There is no code that computes balance from ledger_entries or that posts to ledger. So either balances are maintained elsewhere/manually, or they are stale/placeholder; the app does not implement a ledger-based balance.

---

## 4. SYSTEM IMPACT (what breaks because of this)

### 4.1 Accounting accuracy

- **Single source of truth:** Blueprint uses ledger_entries as the backbone; all financial reports should derive from it. With **no** reads or writes to ledger_entries in the app:
  - There is no single, audit-ready trail of debits/credits in the app.
  - Account payment is recorded only in account_transactions and business_accounts; it does not flow into a general ledger. Any future P&L/VAT/Cash Flow built from ledger would miss these payments unless another process posts them.
  - Supplier invoices (when implemented) are required to "Auto-creates Accounts Payable ledger entry"; without ledger write, AP and expenses are not correctly reflected in a ledger-based system.
- **Result:** The app cannot deliver ledger-based accounting. Balances and reports are either manual, from other systems, or placeholder.

### 4.2 Tax compliance (SARS VAT201)

- Blueprint §9.5: VAT report auto-generates VAT201 data (Output VAT, Input VAT, VAT Payable).
- Implementation: VAT "report" is fixed numbers (20052, 12450, 7602). It is **not** derived from transactions or ledger. Submitting or using these figures for SARS would be:
  - Incorrect (not tied to real sales/purchases).
  - Risky (no audit trail from ledger to VAT report).
- **Result:** No reliable, ledger-sourced VAT report for tax compliance within the app.

### 4.3 Management reporting (P&L, Cash Flow)

- P&L and Cash Flow are intended for period-based decisions and lender/owner reporting. With P&L hardcoded and Cash Flow missing:
  - Management cannot see real revenue, COGS, or expenses by period.
  - Cash Flow view (opening, inflows, outflows, closing) does not exist.
- **Result:** No dependable P&L or Cash Flow from the app for management or external reporting.

### 4.4 Business risk summary

| Risk | Cause |
|------|--------|
| Accounting accuracy | ledger_entries never used; no double-entry; account payment and (future) invoice approval do not post to ledger. |
| Tax compliance | VAT report is static; not generated from ledger or transactions; no audit trail to VAT201. |
| Management reporting | P&L is hardcoded; Cash Flow absent; no period-based reports from ledger. |
| Audit trail | No ledger view; no way to trace P&L or VAT lines back to ledger entries in the app. |

---

## 5. COMPLETION % FOR THIS MODULE (financial system & ledger)

**Module:** Financial system and ledger usage as defined in blueprint §9.2 (Chart of Accounts), §9.3 (Auto-Generated Ledger Entries), §9.4 (P&L from ledger), §9.5 (VAT from ledger), §9.6 (Cash Flow from ledger), and §15 (ledger_entries).

| Criterion | Blueprint | Status | Score |
|-----------|-----------|--------|-------|
| ledger_entries table used (read or write) | Backbone for all financial reporting | Never read or written | 0% |
| P&L auto-generated from ledger for selected period | Required | Hardcoded constants; no period; no ledger | 0% |
| VAT report auto-generated from ledger | Required | Hardcoded constants; no ledger | 0% |
| Cash Flow view from ledger | Required | No cash flow screen; no ledger | 0% |
| Transaction flows create ledger entries (e.g. account payment) | Required | Account payment updates account_transactions + business_accounts only; no ledger_entries | 0% |
| Invoice approval creates AP ledger entry | Required | No approval flow; no ledger | 0% |
| Chart of Accounts editable (add/rename; no delete if has transactions) | Required | Read-only list; Add Account no-op; no delete/rename | 0% |
| Ledger screen / view | In blueprint structure | Not implemented | 0% |
| Chart of Accounts display | Required | Implemented (read from chart_of_accounts) | 100% |

**Completion % for financial system & ledger module:** **~11%** (1/9 criteria: Chart of Accounts display only. All ledger-based reporting and all ledger writes are missing.)

---

## 6. GAP SUMMARY

- **Exists:** Chart of Accounts tab that reads and displays `chart_of_accounts` (account_number, name, type, balance). P&L and VAT **cards** with correct labels but **hardcoded** amounts. Report hub mentions P&L, VAT, Cash Flow as report types. Account payment flow that updates `account_transactions` and `business_accounts` (but not ledger_entries).
- **Missing:** Any use of `ledger_entries`; P&L/VAT/Cash Flow generated from ledger; period selection; ledger screen; Cash Flow view; ledger entries created by account payment or invoice approval; full chart of accounts edit (add/rename/delete with transaction check).
- **Incorrect:** P&L and VAT present as "statements" but are static data, not from ledger; account payment does not auto-create ledger entry; chart balances are not shown as derived from ledger in this app.
- **Impact:** No ledger-based accounting; VAT and P&L are not suitable for tax or management use; no audit trail from transactions to financial reports; business and tax compliance risk.
- **Completion:** ~11% for the financial/ledger module (only chart of accounts display meets blueprint; all ledger backbone and ledger-derived reports are absent).

---

*Audit only. No code was modified. No fixes suggested.*
