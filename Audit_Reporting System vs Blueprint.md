# Audit: Reporting System vs Blueprint

**Blueprint:** `AdminAppBluePrintTruth.md` (§11 Reporting & Exports)  
**Scope:** Fully functional report hub, CSV/PDF/Excel exports, scheduled reports.

---

## 1. What exists (with file references)

| Item | Evidence |
|------|----------|
| **Report hub screen** | `report_hub_screen.dart`: Scaffold with “Reports & Exports” header, category sidebar (All Reports, Financial, Inventory, Staff & HR, Operations, Compliance), grid of report cards (lines 191–238). |
| **Report list (19 titles)** | `_reports` list (lines 18–38): Daily Sales Summary, Weekly Sales Report, Monthly P&L, VAT201, Cash Flow, Staff Hours, Payroll, Inventory Valuation, Shrinkage, Supplier Spend, Expense by Category, Product Performance, Customer (Loyalty), Hunter Jobs, Audit Trail, BCEA Compliance, Blockman Performance, Event Forecast, Sponsorship & Donations, Equipment Depreciation. Each has title, freq, icon, cat. |
| **View / Export actions** | Each card: VIEW button calls `_viewReport(title)`; EXPORT popup (PDF, CSV, Excel) calls `_exportReport(val, title)` (lines 256–272). |
| **Reports that actually load data** | Only **4** reports have a switch case in `_viewReport` and `_exportReport`: **Inventory Valuation**, **Shrinkage Report**, **Staff Hours Report**, **Audit Trail Report** (lines 50–94, 134–158). All others hit `default`: “View configuration pending for specific schema joints” / “Export configuration pending for specific schema joints.” |
| **ReportRepository** | `report_repository.dart`: getInventoryValuation (inventory_items), getShrinkageReport (shrinkage_alerts), getStaffHours (timecards + staff_profiles), getAuditTrail (audit_log), getDailySales (sales_transactions), getSupplierSpend (RPC calculate_supplier_spend). generateCSV(headers, keys) builds CSV string (lines 16–127). |
| **Export behaviour in hub** | `_exportReport(type, title)`: receives type in {'pdf','csv','xlsx'} but **always** builds a CSV string via `_repo.generateCSV(...)` and shows it in an AlertDialog with SelectableText (lines 41–126). No file write, no PDF generation, no Excel generation. Dialog title says “Exported Successfully (type.toUpperCase())” but output is CSV text only (lines 100–116). Comment (lines 98–99): “Since we are running Desktop (Windows), a real app would use path_provider to save a file … we mimic success.” |
| **Schedule configuration** | “SCHEDULE CONFIGURATION” button opens `_openScheduleConfig`: AlertDialog with **static** list — “Daily at 23:00 — Daily Sales Summary”, “Monday at 06:00 — Weekly Sales + Shrinkage”, “1st of Month — P&L, VAT, Cash Flow” — and “ADD NEW SCHEDULE” with `onPressed: () {}` (lines 277–298). No persistence, no cron, no actual scheduling. |
| **ReportService (core)** | `report_service.dart`: generatePdfReport, generateExcelReport, generateCsvReport (each writes to File via path_provider). generateSalesReport, generateInventoryReport (by format). **Not used by report_hub_screen** — hub does not import or call ReportService. |
| **ExportService (core)** | `export_service.dart`: exportToCsv, exportToExcel, PDF helpers; writes to file. **Not used by report_hub_screen** or report_repository. |
| **Audit Trail table name** | ReportRepository uses `audit_log` (report_repository.dart line 95); audit_repository also uses `audit_log` (audit_repository.dart line 29). |

So: **Report hub exists with 19 report cards and category filter.** **Only 4 reports (Inventory Valuation, Shrinkage, Staff Hours, Audit Trail) fetch data and show CSV-style output.** **Export is CSV-only and in-dialog only (no file save, no PDF, no Excel).** **Schedule is a static dialog; no automated reports.** **ReportService and ExportService exist but are not wired to the hub.**

---

## 2. What is missing (explicitly from blueprint)

**Report types that do not work (§11.1)**  
- Daily Sales Summary, Weekly Sales Report, Monthly P&L, VAT201 Report, Cash Flow — no data path in hub (placeholder message).  
- Payroll Report, Supplier Spend Report, Expense Report by Category, Product Performance, Customer (Loyalty) Report, Hunter Jobs Report — no data path in hub.  
- BCEA Compliance Report, Blockman Performance Report, Event Forecast Report, Sponsorship & Donations, Staff Loan & Credit Report, AWOL / Absconding Report, Equipment Depreciation Schedule, Purchase Sale Agreement History — no data path in hub.  
- Blueprint also lists “Purchases by Supplier” (on demand); hub has “Supplier Spend Report” but no switch case for it (getSupplierSpend exists in repo but is not used in hub).

**Export formats (§11.2)**  
- **PDF** — “for printing, emailing, filing, SARS submission”. Hub offers “Export as PDF” but always produces CSV text in a dialog; ReportService has generatePdfReport but hub does not use it.  
- **Excel (.xlsx)** — “for further analysis, accountant”. Hub offers “Export as Excel (.xlsx)” but same CSV-in-dialog; ReportService/ExportService have Excel support but hub does not use them.  
- **CSV** — hub produces CSV string but does not save to file (no path_provider write, no file picker); user cannot get a CSV file for “accountant/bookkeeper import”.

**Fully functional report hub**  
- “Fully functional” implies: each listed report returns real data; export produces downloadable file in chosen format. Only 4 reports return data; export never writes a file or generates PDF/Excel.

**Scheduled reports (§11.3)**  
- **Daily at 23:00** — Daily Sales Summary → Dashboard + optional email. No cron, no job, no delivery.  
- **Monday at 06:00** — Weekly Sales + Shrinkage → Dashboard + email. Not implemented.  
- **1st of month** — P&L, VAT, Cash Flow → Dashboard + email + Google Drive. Not implemented.  
- Schedule config is display-only; “ADD NEW SCHEDULE” has no handler. No persistence of schedule, no integration with email or Google Drive.

**Delivery**  
- Blueprint: “Dashboard + optional email”, “Dashboard + email”, “Dashboard + email + Google Drive”. No email or Google Drive integration in report hub or schedule.

---

## 3. What is incorrect (deviations)

| Deviation | Blueprint | Current |
|-----------|-----------|---------|
| **Export format** | User chooses PDF, Excel, or CSV and gets that format. | User chooses PDF/CSV/Excel but always gets CSV text in a dialog; format choice ignored for output; no file saved. |
| **Export outcome** | File for printing, emailing, accountant. | In-dialog preview only; comment says “mimic success”; no real file export from hub. |
| **Report coverage** | All report types in §11.1 are available and functional. | 19 cards shown; only 4 have data; 15 show “View/Export configuration pending for specific schema joints.” |
| **Schedule** | Automated runs at specified times with delivery. | Static dialog describing schedule; no automation, no “ADD NEW SCHEDULE” logic, no delivery. |
| **Use of ReportService/ExportService** | Blueprint §16 lists report_service.dart and export_service.dart for PDF/Excel/CSV. | Report hub uses only ReportRepository and in-repo generateCSV; ReportService and ExportService are never called from the report hub. |

---

## 4. System impact (what breaks or is missing)

- **Operations/management:** Daily/weekly sales, P&L, VAT, cash flow, payroll, supplier spend, product performance, customer/hunter reports cannot be run from the hub; only inventory, shrinkage, staff hours, and audit trail return data.  
- **Compliance/audit:** BCEA Compliance, Audit Trail (works), AWOL, Sponsorship & Donations, Equipment Depreciation, Purchase Sale Agreement cannot all be produced from the hub; compliance and audit evidence is incomplete.  
- **Export and handover:** No PDF for printing/filing/SARS; no Excel for accountant; no CSV file for bookkeeper — only on-screen CSV text.  
- **Scheduled reports:** No automatic generation or delivery; owner/manager must run reports manually and have no automated “Daily at 23:00” / “Monday 06:00” / “1st of month” workflow.  
- **Reliance on hub:** Users may believe all 19 reports and all three formats work; in practice only 4 reports return data and “export” does not produce downloadable files in the chosen format.

---

## 5. Completion % for this module

| Sub-module | Completion % | Notes |
|------------|--------------|--------|
| **Report hub UI** | **~90%** | Screen, categories, 19 cards, VIEW/EXPORT buttons, schedule button present. |
| **Reports that actually work** | **~21%** | 4 of 19 reports (Inventory Valuation, Shrinkage, Staff Hours, Audit Trail) load data and show output; 15 are placeholders. |
| **CSV export** | **~30%** | CSV string generated for the 4 reports; no file save from hub; ReportRepository.generateCSV only. |
| **PDF export** | **0%** | PDF option in UI; hub never produces PDF; ReportService.generatePdfReport exists but is not used by hub. |
| **Excel export** | **0%** | Excel option in UI; hub never produces Excel; ReportService/ExportService have Excel but hub does not use them. |
| **File export from hub** | **0%** | No path_provider/file write or share from report hub; “mimic success” dialog only. |
| **Scheduled reports** | **0%** | Schedule config is static text; no cron/job, no delivery (email, Google Drive), no “ADD NEW SCHEDULE” behaviour. |

**Overall completion for “Reporting system” (fully functional report hub + CSV/PDF/Excel exports + scheduled reports): ~25%.**

Only the hub shell and 4 working reports (with CSV-style in-dialog output) exist. Most report types are placeholders; export does not produce files or PDF/Excel; scheduled reports are not implemented. The reporting system does not meet the blueprint for a fully functional report hub, real CSV/PDF/Excel exports, or scheduled reports.
