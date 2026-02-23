# Master Implementation Plan — Admin App

**Blueprint:** [AdminAppBluePrintTruth.md](../AdminAppBluePrintTruth.md)  
**Addendum (requirements not in blueprint):** [AdminAppBluePrintTruth_ADDENDUM.md](../AdminAppBluePrintTruth_ADDENDUM.md)  
**Sources:** PHASE1_FINAL_SYSTEM_VALIDATION, PHASE1_FULL_CORRECTION_APPLIED, FINAL_SYSTEM_VERIFICATION_REPORT, GAP_ANALYSIS_ADMIN_APP, AUDIT_FINANCIAL_LEDGER, Audit_Architecture vs Blueprint

---

## SECTION 1 — SYSTEM STATUS SUMMARY

### Completion vs Blueprint

| Module           | Completion | Status                                                                                                                             |
| ---------------- | ---------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| Auth (§2)        | 95%        | Working; Manager/Owner nav hidden                                                                                                  |
| Dashboard (§3)   | 75%        | Stats from transactions; no real-time, no 7-day chart                                                                              |
| Inventory (§4)   | 80%        | Categories, Products (category_id), Modifiers, Suppliers, Stock-Take, Stock Levels; full product form; stock display inconsistency |
| Production (§5)  | 95%        | Yield, Intake, Breakdown, Recipes, Batches, Dryer                                                                                  |
| Hunter (§6)      | 35%        | Job list + Services tab; intake/process/summary partial                                                                            |
| HR (§7)          | 50%        | Staff list, Timecards, Leave, Payroll tabs; AWOL, Staff Credit, BCEA missing                                                       |
| Accounts (§8)    | 70%        | List, payment (ledger), overdue tab; statement, detail partial                                                                    |
| Bookkeeping (§9) | 80%        | Invoices, Ledger tab, CoA, P&L/VAT/Cash from ledger; PTY tab                                                                       |
| Analytics (§10)  | 90%        | Shrinkage, Pricing, Reorder, Event tabs                                                                                            |
| Reports (§11)   | 85%        | Report hub, exports                                                                                                                |
| Customers (§12)  | 40%        | List; Announcements, Recipe library missing                                                                                        |
| Audit (§13)     | 90%        | Log viewer                                                                                                                        |
| Settings (§14)   | 35%        | Business only; Scale, Tax, Notification missing                                                                                   |

**Overall:** ~65% (post Phase 1). Stock inconsistency blocks production.

### What Is Working

- **Triggers:** Shrinkage (017), POS→ledger (017), transaction_items→current_stock (017)
- **Ledger flows:** Account payment, Invoice approval, Waste/Donation/Sponsorship post to ledger
- **Bookkeeping:** Ledger tab, LedgerRepository (getPnLSummary, getVatSummary, getCashFlowSummary), Chart of Accounts
- **Product:** category_id form/list; full Sections A–H in `_ProductFormDialog`
- **Stock movements:** Waste, Donation, Sponsorship, Transfer, Freezer, Stock Take dialogs; post to ledger
- **Inventory UI:** TabBar in body (no AppBar); Add inside each tab
- **Dashboard:** Today stats from transactions; shrinkage/reorder/overdue/clock-in alerts

### What Is Partially Working

- **Stock display:** Stock Levels and Product list use `stock_on_hand_fresh + stock_on_hand_frozen`; POS trigger updates only `current_stock` → values diverge after sales
- **Overdue accounts:** Tab exists; "X days overdue" and per-account auto-suspend config unclear
- **Hunter:** Job list + Services; intake/process/summary need verification
- **VAT in POS ledger:** Trigger posts full amount to 4000; blueprint §9.3 shows Revenue + VAT split (4000 + 2100)

### What Is Broken

- **Stock single source:** No alignment between current_stock (trigger) and fresh+frozen (UI) → production blocker
- **Supabase init (Rule 1):** main.dart initializes directly; SupabaseService.initialize() never called
- **Supabase project (Rule 2):** Config may use non-allowed project URL (verify admin_config)
- **Account payment without login:** Ledger not posted when currentStaffId null

### Production Readiness

**NOT READY** — Stock display inconsistency is blocking. After stock fix: Phase 1 flows are production-ready; remaining gaps are feature-completeness.

### System Objective Enhancement (Business Goals)

The system must actively help:
- Reduce waste
- Prevent over-ordering
- Optimize supplier selection (price vs availability)
- Increase profitability through analytics

**Influences:** Analytics module, Reorder recommendations, Supplier comparison logic, Event/holiday intelligence, Shrinkage alerts.

---

## SECTION 2 — CRITICAL ISSUES (Red)

*(C1–C9 as in plan — see .cursor/plans version for full detail)*

---

## SECTION 3 — HIGH PRIORITY (Orange)

*(H1–H9 as in plan)*

---

## SECTION 4 — MEDIUM (Yellow)

*(M1–M11 as in plan)*

---

## SECTION 5 — LOW (Green)

*(L1–L6 as in plan)*

---

## SECTION 6 — PHASED EXECUTION PLAN

*(Phases 1–5 as in plan)*

---

## SECTION 7 — DEPENDENCY MAP

*(See .cursor/plans version for mermaid diagram)*

---

## SECTION 8 — FINAL READINESS CHECKLIST

*(See .cursor/plans version for full checklist)*

---

**For full plan content including all item details, see:** `.cursor/plans/master_implementation_plan_28aa35b9.plan.md`
