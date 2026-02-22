# Audit: Invoice & Procurement System vs Blueprint

**Blueprint:** `AdminAppBluePrintTruth.md` (§9.1 Invoice Management)  
**Scope:** Manual invoice entry, OCR pipeline (Google Drive + Vision), approval workflow, ledger integration, bulk CSV import/export.

---

## 1. What exists (with file references)

| Item | Evidence |
|------|----------|
| **Bookkeeping → Invoices entry point** | `main_shell.dart`: Bookkeeping opens `InvoiceListScreen` (line 46). |
| **Invoice list screen and tabs** | `invoice_list_screen.dart`: Scaffold with 4 tabs — Invoices, Chart of Accounts, P&L / Reports, PTY Conversion (lines 38–60). |
| **Invoices tab: list from DB** | `_InvoicesTab`: `_load()` reads `.from('invoices').select('*').order('created_at', ascending: false)` (lines 91–95). Displays supplier_name, invoice_number, date, total_amount, status (lines 165–174). |
| **“Add Manually” button** | `_InvoicesTab`: ElevatedButton “Add Manually” calls `_openInvoiceForm()` (lines 128–131). |
| **Manual invoice form** | **Placeholder only.** `_openInvoiceForm()` (lines 101–109) shows an `AlertDialog` with title “Add Invoice Manually” and content “Form to manually add supplier invoice details...” — no fields, no save, no `invoice_line_items`. |
| **“Bulk Import CSV” button** | **Placeholder only.** OutlinedButton “Bulk Import CSV” has `onPressed: () {}` (lines 123–126) — no file picker, no CSV parse, no bulk insert. |
| **OCR service (core)** | `ocr_service.dart`: `OcrService` with Google Cloud Vision (`processImageForText`), `processReceiptFromCamera()`, `processReceiptFromGallery()`, `_parseReceiptText()` (vendor_name, total_amount, date, items), regex-based parsing (lines 18–133). API key is empty: `final String _apiKey = ''; // TODO` (line 14). |
| **OCR usage in bookkeeping** | **None.** No import or use of `OcrService` (or `ocr_service`) in `lib/features/bookkeeping/`. No “Scan invoice” or “From camera/gallery” in invoice flow. |
| **Google Drive in OCR** | **None.** Blueprint: “Owner photos supplier invoice OR drops PDF into designated Google Drive folder” and “Supabase Edge Function monitors folder”. No Google Drive integration, no Edge Function, no folder monitor in app or migrations. |
| **Invoice tables in DB** | `002_admin_app_tables_part2.sql`: `invoices` (id, invoice_number, account_id, invoice_date, due_date, subtotal, tax_amount, total_amount, status, notes, created_by, created_at, updated_at); status CHECK: `'draft','sent','paid','overdue','cancelled'` (lines 46–60). `invoice_line_items` (invoice_id, description, quantity, unit_price, line_total, sort_order) (lines 63–72). `ledger_entries` (entry_date, account_code, account_name, debit, credit, description, reference_type, reference_id, recorded_by) (lines 75–87). |
| **Chart of Accounts tab** | `_ChartOfAccountsTab`: loads `.from('chart_of_accounts').select('*').order('account_number')` — UI uses `account_number`, `balance` (lines 209, 264–270). Migration has `account_code` and no `balance` column (002 lines 90–100). |
| **P&L / VAT display** | `_ReportsTab`: static P&L and VAT cards with hardcoded numbers (lines 289–371) — not generated from ledger. |
| **Export service (generic)** | `export_service.dart`: `exportToCsv()`, `exportToExcel()`, PDF helpers (lines 19–51+). Not used by invoice list; no invoice export button or CSV export for invoices. |
| **invoice_form_screen.dart** | **Missing.** Blueprint §16 lists `invoice_form_screen.dart` under bookkeeping; only `invoice_list_screen.dart` exists in `lib/features/bookkeeping/screens/`. |

So: **invoice list + DB read exists; manual form and bulk CSV are placeholders; OCR exists but is unused in bookkeeping and has no Drive pipeline; no approval UI, no ledger integration, no invoice CSV import/export.**

---

## 2. What is missing (explicitly from blueprint)

**Manual invoice entry (§9.1)**  
- Real “Add Invoice Manually” form: supplier, date, line items, amounts.  
- Same approval flow as OCR (review → approve).  
- Creating `invoice` + `invoice_line_items` records from the form.

**OCR pipeline (§9.1)**  
- **Google Drive:** Owner drops PDF / photo into designated folder; no Drive integration.  
- **Supabase Edge Function:** Webhook/cron to monitor folder; not present in app or migrations.  
- **Cloud Vision:** Used inside `OcrService` but not invoked from bookkeeping; no “Pending Review” feed from OCR.  
- **AI parse:** “supplier name, invoice #, date, line items, totals” — parsing exists in `_parseReceiptText` but not wired to invoice creation or Admin.  
- **Flow:** “Invoice appears in Admin with status 'Pending Review'” — no OCR → Admin path.  
- **Price change detection:** “Detects if supplier has changed prices since last invoice” — not implemented.

**Approval workflow (§9.1)**  
- Status “Pending Review” and “Owner reviews, corrects any OCR errors, approves” — no review/approve UI.  
- DB status is `draft,sent,paid,overdue,cancelled` — no `Pending Review` or `Approved`.  
- No approve/reject actions on list or detail.

**Ledger integration (§9.1)**  
- “Auto-creates Accounts Payable ledger entry” on approval — no code creating `ledger_entries` from invoice approval.  
- No references to `ledger_entries` in bookkeeping feature.

**Bulk CSV import (§9.1)**  
- “Upload CSV of multiple invoices — system maps columns and creates entries in bulk” — not implemented (button empty).  
- “Template download” and “Duplicate detection (invoice number already exists)” — not implemented.

**Bulk CSV export (§9.1)**  
- “Export all invoices or filtered selection to CSV for accountant” — no export button or use of `ExportService` for invoices.  
- “Export formats: CSV, Excel (.xlsx), PDF” for invoices — not present.

**invoice_form_screen.dart (§16)**  
- Blueprint project structure lists `invoice_form_screen.dart`; file does not exist.

---

## 3. What is incorrect (deviations)

| Deviation | Blueprint | Current |
|-----------|----------|--------|
| **Manual form** | Full form: supplier, date, line items, amounts; same approval as OCR. | Dialog with text only: “Form to manually add supplier invoice details...” — no fields, no persistence. |
| **Bulk Import CSV** | Upload CSV, map columns, bulk create, duplicate check. | Button present; `onPressed: () {}` — no behaviour. |
| **Invoice status** | Pending Review → Owner reviews/approves. | DB: `draft,sent,paid,overdue,cancelled` — no Pending Review/Approved; list shows `status ?? 'Pending Review'` (line 174) so UI label can conflict with schema. |
| **Invoices table vs supplier invoices** | Supplier invoices (supplier name, approval, AP ledger). | Migration: `invoices` has `account_id` (business_accounts), no `supplier_name`; list displays `supplier_name` (fallback “Unknown”) — schema looks like customer/sales invoices; supplier invoice use not reflected in schema. |
| **OCR pipeline** | Drive → Edge Function → Vision → parse → Admin “Pending Review”. | Vision + parse only in `OcrService`; not used in bookkeeping; no Drive, no Edge Function, no pipeline into Admin. |
| **Chart of Accounts list** | N/A (schema). | Screen orders by `account_number` and shows `balance`; migration has `account_code` and no `balance` — possible schema/display mismatch. |

---

## 4. System impact (what breaks or is missing)

- **Bookkeeping:** Supplier invoices cannot be entered manually (form is placeholder), so purchase-side bookkeeping depends on data entered elsewhere or not at all. No approval means no controlled “approved invoice” state for AP.  
- **Ledger and P&L:** No auto-creation of AP entries on approval, so Accounts Payable and COGS from supplier invoices are not reliably reflected in `ledger_entries`; P&L tab is static, not ledger-driven.  
- **Supplier tracking:** No manual or OCR-driven invoice capture, so supplier spend and “Supplier Spend Report” cannot be populated from this flow; report exists in UI but data source is incomplete.  
- **Procurement:** No bulk CSV import for month-end or accountant handover; no CSV/Excel export of invoices.  
- **OCR:** Camera/gallery OCR exists but is unused; no Google Drive pipeline, so “photo/PDF in folder → Admin Pending Review” is impossible.  
- **Audit:** No approval step or ledger link, so no clear audit trail from “invoice received → reviewed → approved → ledger” in the app.

---

## 5. Completion % for this module

| Sub-module | Completion % | Notes |
|------------|--------------|--------|
| **Manual invoice entry** | **~5%** | Button + dialog with text only; no real form or save. |
| **OCR pipeline (Google Drive + Vision)** | **~15%** | Vision + receipt parse in `OcrService`; not used in bookkeeping; no Drive, no Edge Function, no “Pending Review” flow. |
| **Approval workflow** | **0%** | No review/approve UI; DB has no Pending Review/Approved. |
| **Ledger integration** | **0%** | No code creating `ledger_entries` on invoice approval. |
| **Bulk CSV import** | **0%** | Button only; no file picker, parse, or bulk insert. |
| **Bulk CSV/Excel/PDF export (invoices)** | **0%** | ExportService exists; not used for invoices; no export in list. |
| **invoice + invoice_line_items creation** | **0%** | No form or OCR flow that inserts invoices/line items. |

**Overall completion for “Invoice & Procurement” (vs blueprint §9.1): ~8%.**

Only the invoice list (read from `invoices`), placeholder manual dialog, placeholder bulk button, and a standalone OCR service exist. Manual entry form, full OCR pipeline (Drive + Edge Function + Admin), approval workflow, ledger integration, and bulk CSV import/export are missing or placeholder. Bookkeeping and supplier tracking cannot rely on this module as specified in the blueprint.