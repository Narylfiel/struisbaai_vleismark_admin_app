# Audit: Advanced HR Features vs Blueprint

**Blueprint:** `AdminAppBluePrintTruth.md` (§7.3a AWOL, §7.5 Staff Credit/Loans, §7.6 BCEA Compliance)  
**Scope:** AWOL tracking, Staff credit/loans, Compliance dashboard (BCEA).

---

## 1. What exists (with file references)

| Item | Evidence |
|------|----------|
| **HR entry point** | `main_shell.dart` line 43: HR / Staff → `StaffListScreen()` only. No separate route for Compliance, AWOL, or Staff Credit. |
| **Staff list screen and tabs** | `staff_list_screen.dart`: 4 tabs — Staff Profiles, Timecards, Leave, Payroll (lines 43–60). No AWOL tab, no Staff Credit tab, no Compliance tab. |
| **Staff Profiles tab** | Loads `staff_profiles` (id, full_name, role, phone, email, employment_type, hourly_rate, monthly_salary, pay_frequency, hire_date, is_active, max_discount_pct). Add/Edit via `_StaffFormDialog` (lines 77–324, 868–1170). |
| **Timecards tab** | Loads `timecards` + `timecard_breaks`; daily/weekly/monthly view; staff filter; shows clock in/out, up to 3 breaks, total break, reg hrs, OT hrs (lines 330–569). |
| **BCEA-style check in Timecards** | `staff_list_screen.dart` lines 457–469: “BCEA violation: any single break > 60 min”; row highlighted red, “LONG BREAK” badge. No other BCEA rules (weekly hours, leave balance, etc.) in this screen. |
| **Leave tab** | Loads `leave_requests`, `leave_balances`; filter Pending/Approved/Rejected; Approve/Decline; balance display (annual/sick/family) (lines 572–724). |
| **Payroll tab** | Builds payroll from `staff_profiles` + `timecards` for current month; gross = reg×rate + OT×1.5 + sunday×2; UIF 1%; net = gross − UIF. No staff_credit/staff_loans deduction (lines 731–872). |
| **Staff form BCEA text** | `_StaffFormDialog` Employment tab: static info “SA BCEA Compliance” and bullet list (max 45h/week, 10h/day, OT cap, etc.) (lines 1073–1084). Informational only, not a compliance check. |
| **BCEA settings** | `business_settings_screen.dart` lines 101–102, 115–116, 141: `bcea_start_time`, `bcea_end_time` stored/displayed as “Operational Hours (BCEA Base)”. |
| **Report types (labels only)** | `report_hub_screen.dart` lines 34–35: “BCEA Compliance Report”, “AWOL / Absconding Report” in report list. No implementation of these reports in HR. |
| **Config constant** | `admin_config.dart` line 47: `awolPatternThreshold = 3`. Not referenced by any screen or service. |
| **DB: account_awol_records** | `002_admin_app_tables_part2.sql` lines 5–12: table with id, **account_id** (→ business_accounts), awol_date, reason, recorded_by. Blueprint §7.3a requires **staff** AWOL (staff member, expected start time, resolution); schema is account-based, not staff-based. |
| **DB: staff_credit** | `002_admin_app_tables_part2.sql` lines 15–26: staff_id, credit_amount, reason, granted_date, due_date, is_paid, paid_date, granted_by, notes. |
| **DB: staff_loans** | `002_admin_app_tables_part2.sql` lines 30–42: staff_id, loan_amount, interest_rate, term_months, monthly_payment, granted_date, first_payment_date, is_active, granted_by, notes. |
| **Trigger referencing AWOL** | `003_indexes_triggers_rpc.sql` lines 257–285: trigger on `account_awol_records` (if table exists). No app code reads or writes this table. |

So: **Staff profiles, timecards (with one BCEA-style check), leave, and payroll from timecards exist.** **No AWOL UI, no Staff Credit/Loans UI, no BCEA Compliance dashboard.** **Tables exist; account_awol_records is account-linked, not staff-linked per blueprint.**

---

## 2. What is missing (explicitly from blueprint)

**AWOL tracking (§7.3a)**  
- **Sidebar → 👥 HR → AWOL** (or equivalent): not present. Blueprint §16 lists `awol_screen.dart`; file does not exist.  
- **AWOL record fields:** Date(s), Staff Member, Expected Start Time, Notified Owner/Manager, Resolution (Returned/Resigned/Dismissed/Warning Issued/Pending), Written Warning Issued, Notes, Linked to Disciplinary Record — no UI for any.  
- **Pattern detection:** “3 or more AWOL incidents for same staff member triggers flag: ‘Persistent AWOL — consider formal disciplinary process.’” — config has `awolPatternThreshold = 3` but no screen or logic uses it.  
- **Staff-based AWOL data:** Blueprint §7.3a is staff absconding; DB has `account_awol_records` with `account_id` → business_accounts. No staff-scoped AWOL table or UI.

**Staff credit / loans (§7.5)**  
- **Sidebar → 👥 HR → Staff Credit** (or equivalent): not present. Blueprint §16 lists `staff_credit_screen.dart`; file does not exist.  
- **Staff Credit ledger per employee:** Type (Meat Purchase / Salary Advance / Loan), Purchase/Loan Date, Items Purchased, Amount, Repayment Plan, Deduct From, Status (Pending/Deducted/Partial/Cleared) — no UI.  
- **Outstanding balance on staff profile:** “Running outstanding balance shown on staff profile at all times” — not shown in Staff Profiles tab or form.  
- **Full credit history per staff:** “Owner can view full credit history per staff member across all time” — no screen.  
- **Payroll integration:** “All outstanding deductions auto-applied on payroll run”; “Owner can defer or adjust individually”; “Payslip shows each purchase/advance with date and amount as separate deduction lines”; “Running loan balance shown on payslip” — payroll tab does not read staff_credit or staff_loans; no deductions; no payslip generation.

**BCEA Compliance dashboard (§7.6)**  
- **Sidebar → 👥 HR → Compliance:** not present. Blueprint §16 lists `compliance_screen.dart`; file does not exist.  
- **System auto-checks and flags:** “All staff within weekly working hour limits (max 45h)”; “All breaks comply with BCEA (30+ min for 5+ hour shifts)”; “Only X days annual leave remaining (min 21)”; “Sunday work — confirm double pay”; “X AWOL incidents this month — Persistent AWOL flag” — no dedicated compliance dashboard.  
- **AWOL in compliance:** “AWOL incidents now tracked and flagged in the BCEA Compliance dashboard. Persistent AWOL pattern (3+ incidents) alerts owner” — no implementation.

**HR feature set**  
- Only one HR screen file: `staff_list_screen.dart`. No `awol_screen.dart`, `staff_credit_screen.dart`, `compliance_screen.dart`, `timecard_screen.dart`, `leave_screen.dart`, `payroll_screen.dart` as separate routes; all are tabs inside staff list.

---

## 3. What is incorrect (deviations)

| Deviation | Blueprint | Current |
|-----------|-----------|---------|
| **AWOL table scope** | §7.3a: Staff absconding — Staff Member, Expected Start Time, Resolution, etc. | DB: `account_awol_records` with `account_id` → business_accounts. Tracks account, not staff. |
| **Payroll deductions** | §7.4: “Staff Loans / Meat Purchases: auto-deducted (see 7.5)”. §7.5: “All deductions are automatic from the next payroll run.” | Payroll tab: only UIF 1% deducted; no read from staff_credit or staff_loans; no loan/advance/meat-purchase deductions. |
| **BCEA Compliance** | §7.6: Dedicated “Sidebar → 👥 HR → Compliance” dashboard with auto-checks and violation list. | No compliance screen. Single BCEA-style check in Timecards only (break > 60 min → LONG BREAK). No weekly hours, leave minimums, Sunday pay, or AWOL in one dashboard. |
| **Staff credit table vs blueprint** | §7.5: Type = Meat Purchase / Salary Advance / Loan; Items Purchased; Repayment Plan; Status Pending/Deducted/Partial/Cleared. | staff_credit: reason, credit_amount, is_paid, paid_date — no type enum, no line-item detail; staff_loans: separate table. Blueprint describes one “Staff Credit ledger” with types; app has two tables, no type/status alignment. |

---

## 4. System impact (what breaks or is missing)

**Payroll impact**  
- Staff loans, advances, and meat purchases on credit are not deducted from pay. Net pay is overstated; manual tracking required outside the app.  
- No payslip generation (PDF/email/WhatsApp); no deduction lines; no “running loan balance” on payslip.  
- Per-frequency payroll (weekly vs monthly) and “weekly staff show each weekly payment as separate line items” are partially there (pay_frequency displayed) but payroll does not apply or show staff credit/loan deductions.

**Compliance risks**  
- No single place to see BCEA violation status (weekly hours, breaks, leave minimums, Sunday pay, AWOL). Owner/manager cannot rely on the app for “Compliance STATUS — February 2026” as in the blueprint.  
- AWOL is not recorded or flagged; “Persistent AWOL” (3+ incidents) is not detected. Disciplinary and CCMA risk not supported by system evidence.  
- Leave balances and annual leave minimum (21 days) are shown in Leave tab but not evaluated in a compliance dashboard with alerts (e.g. “Only 8.3 days annual leave remaining”).  
- Timecards show one BCEA-style signal (long break) only; no automatic check for 45h/week, 30 min break for 5+ hour shifts, or double pay for Sunday.

**Missing HR features**  
- No way to record or review staff AWOL (expected start, resolution, warning).  
- No way to record staff credit/loans/meat purchases or to defer/adjust deductions.  
- “BCEA Compliance Report” and “AWOL / Absconding Report” exist as report titles only; no implementation.  
- Staff profile does not show “running outstanding balance” for credit/loans.

---

## 5. Completion % for this module

| Sub-module | Completion % | Notes |
|------------|--------------|--------|
| **AWOL tracking** | **0%** | No AWOL screen; no staff-based AWOL UI or logic. DB has account_awol_records (account-scoped); not used by app. |
| **Staff credit / loans** | **0%** | No staff credit screen; no payroll deduction from staff_credit/staff_loans; tables exist but unused in lib. |
| **BCEA Compliance dashboard** | **~5%** | One BCEA-style check in Timecards (long break); BCEA settings (start/end time); static BCEA text in staff form. No dedicated Compliance screen or auto-check list. |
| **Payroll (with deductions)** | **~40%** | Gross/UIF/net from timecards and pay types exist; per-frequency display. No staff credit/loan deductions, no payslip generation. |

**Overall completion for “Advanced HR features” (AWOL + Staff Credit/Loans + BCEA Compliance): ~10%.**

Only staff list (profiles, timecards, leave, payroll from timecards) and one BCEA-related check in Timecards exist. AWOL tracking, staff credit/loans UI, payroll deduction from credit/loans, and the BCEA Compliance dashboard are missing. Compliance and payroll accuracy cannot be guaranteed from the app as specified in the blueprint.
