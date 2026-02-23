# Master Implementation Plan vs Blueprint & Addendum — Status

**Sources:**  
- [docs/MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md) (summary; full item list referenced in `.cursor/plans/master_implementation_plan_28aa35b9.plan.md` — not in repo)  
- [AdminAppBluePrintTruth.md](../AdminAppBluePrintTruth.md)  
- [AdminAppBluePrintTruth_ADDENDUM.md](../AdminAppBluePrintTruth_ADDENDUM.md)  
- Codebase and migrations as of Feb 2026

---

## 1. Master Plan — What We Have in Repo

The **docs/MASTER_IMPLEMENTATION_PLAN.md** file is a summary that:

- References the full plan (C1–C9, H1–H9, M1–M11, L1–L6, Phases 1–5) in `.cursor/plans/master_implementation_plan_28aa35b9.plan.md`.
- That `.cursor/plans` file was **not found** in the workspace (may be ignored or in a different location), so this comparison is based on:
  - The **Section 1** status table and “What Is Working / Partially / Broken” in the master plan doc.
  - **Conversation history** (Phases 2–5 implementation).
  - **Codebase and migrations** for evidence.

---

## 2. Confirmed Implemented (Plan + Blueprint + Addendum)

### From Master Plan Section 1 & Phases 2–5

| Item | Evidence |
|------|----------|
| **Supabase init once** (Rule 1) | `main.dart` calls only `SupabaseService.initialize()`; no init in blocs/repos. |
| **Single Supabase client** (L4) | Repos/screens use `SupabaseService.client` only (product_list, dashboard, ledger, recipe, batch, etc.). |
| **Recipe → product linking** (Addendum §1, C5) | `recipe_form_screen.dart`: “Link to existing product” vs “Create new product”; `_outputProductLinkExisting`, `_showCreateOutputProductDialog()`; no auto-create. |
| **VAT split in ledger** (M2) | Migration `019_transactions_vat_ledger_split.sql`: `post_pos_sale_to_ledger` posts CR 4000 (revenue) + CR 2100 (VAT) when `vat_amount` present. |
| **Product suppliers (H6)** | Migration `021_product_suppliers.sql`; product form loads/saves `product_suppliers`; “Supplier Link” UI and dialog. |
| **Purchase Order flow** (Addendum §4, C9) | Migrations `022_purchase_orders.sql`; `_CreatePODialog` in shrinkage_screen: select supplier, products from reorder recs, quantities, save PO + lines. |
| **Product types** (Addendum §6) | Migration `020_product_type.sql` (`raw` / `portioned` / `manufactured`); product form has `_productType` and save. |
| **Dashboard real-time + 7-day chart** (H5) | `dashboard_screen.dart`: `_subscribeTransactions()`, `RealtimeChannel`; 7-day sales chart from `DashboardRepository`. |
| **InventoryItem category_id** (M1) | Product list/form use `category_id`; model and migrations support it. |
| **LedgerRepository.getAccountBalancesToDate()** (Phase 4) | `ledger_repository.dart`: `getAccountBalancesToDate(DateTime asOfDate)` from `ledger_entries`. |
| **Layout breakpoints** (L6) | `admin_config.dart`: `breakpointMobile = 600`, `breakpointTablet = 900`, `breakpointDesktop = 1200`. |
| **CORE_ARCHITECTURE.md** (L5) | `docs/CORE_ARCHITECTURE.md`: multi-app ecosystem, single Supabase, `SupabaseService.client`. |
| **Modifier screen fix** (Addendum §15) | Migration `023_modifier_groups_sort_order.sql` adds `modifier_groups.sort_order`. |
| **Shrinkage alerts columns** | Migration `024_shrinkage_alerts_missing_columns.sql`: `shrinkage_percentage`, `alert_type`, `batch_id`, etc. |
| **Product form dropdown overflow** | `product_list_screen.dart`: `isExpanded: true` on Category/Sub-Category/Item Type/Product Type dropdowns; ellipsis on category names. |

### Blueprint Alignment (Sample)

- **§2 Auth:** PIN login; Owner/Manager only; role routing (allowedRoles / rejectedRoles in config).
- **§3 Dashboard:** Today stats, alerts (shrinkage, reorder, overdue, clock-in), 7-day chart, real-time subscription.
- **§4 Inventory:** Categories, full product form (Sections A–H), category_id, product_type, modifier linking, stock levels, stock movements, supplier management, stock-take.
- **§5 Production:** Yield templates, carcass intake/breakdown, recipes with output product (link existing / create new), batches, dryer.
- **§9 Bookkeeping:** Ledger as single truth; VAT split (4000 + 2100); LedgerRepository with getAccountBalancesToDate, P&L, VAT, cash flow.

### Addendum Alignment (Sample)

- **§1 Recipe → product:** Link existing or create new — implemented.
- **§2 Stock precision:** `AdminConfig.stockGramPrecision`, `stockKgDecimals`.
- **§3 Supplier product mapping:** `product_suppliers` table and UI.
- **§4 Purchase Order flow:** Create PO from reorder context; supplier + products + quantities (see gap below).
- **§6 Product types:** Raw / Portioned / Manufactured in schema and form.
- **§12 Multi-app ecosystem:** Reflected in CORE_ARCHITECTURE.md and single client usage.

---

## 3. Partially Done or Needs Verification

| Item | Plan / Addendum | Status |
|------|------------------|--------|
| **Stock single source** | Master plan “What Is Broken” | UI uses `current_stock` with fallback to `stock_on_hand_fresh` + `stock_on_hand_frozen`; trigger updates `current_stock`. Consistency strategy (single source) and any remaining divergence need product-level verification. |
| **Create PO: “Load ONLY that supplier’s products”** | Addendum §4 | Current flow: products come from reorder recommendations (any product below threshold); user then selects supplier. Addendum asks: select supplier first, then load **that supplier’s products** (e.g. via `product_suppliers`). Filtering PO product list by selected supplier not implemented. |
| **Overdue accounts** | Master plan “Partially” | Tab exists; “X days overdue” and per-account auto-suspend config to be confirmed against blueprint. |
| **Hunter** | Master plan 35% | Job list + Services; intake/process/summary need verification. |
| **Report templates independent of data** | Addendum §8 | Reports must render layout with zero data and produce output on export/print. Not verified in code. |
| **HR AWOL / Staff Credit / BCEA** | Addendum §15, Master plan §7 | Migrations/repos exist (015, AwolRepository, StaffCreditRepository, config constants). Login/AWOL flow and BCEA usage need verification. |

---

## 4. Not Implemented or Not Found in Codebase

| Item | Source | Notes |
|------|--------|------|
| **Production split (one batch → multiple outputs)** | Addendum §5 | Single recipe → multiple outputs (e.g. Boerewors + Patties). No `production_batch_outputs` or split logic found. |
| **POS customer tracking (every sale → linked customer)** | Addendum §7 | “Default POS Customer” fallback — POS/transaction schema not checked here. |
| **Bulk import/export (Suppliers CSV, Stock Take)** | Addendum §10 | Not found. |
| **Barcode scanning in stock take (Admin only)** | Addendum §11 | Not found. |
| **Full responsive/mobile** | Addendum §13 | Breakpoints present; “adapt to mobile” not fully verified. |
| **Settings: Scale, Tax, Notification** | Blueprint §14, Master plan Settings 35% | Business settings only; Scale/Tax/Notification tabs or screens not confirmed. |
| **update_active_context RPC** | User rules (Business/User toggle) | Not searched in this pass; auth stability and RPC existence noted in rules. |

---

## 5. Supabase Project URL (User Rules)

- **User rules:** Allowed project = `nfhltrwjtahmcpbsjhtm.supabase.co`; forbidden = `osgdtecmozslkkudblwc`.
- **admin_config.dart** currently has: `supabaseUrl = 'https://nasfakcqzmpfcpqttmti.supabase.co'`.
- If the intended production project is `nfhltrwjtahmcpbsjhtm`, config should be updated to that URL and anon key; otherwise treat as intentional alternate project.

---

## 6. Summary Table vs Blueprint & Addendum

| Area | Master Plan (Section 1) | Blueprint | Addendum | Codebase Status |
|------|--------------------------|-----------|----------|-----------------|
| Auth | 95% | §2 | — | PIN, roles, nav |
| Dashboard | 75% → improved | §3 | — | Real-time, 7-day chart, alerts |
| Inventory | 80% | §4 | §3 supplier mapping, §10 bulk | product_suppliers, category_id, product_type; bulk import/export missing |
| Production | 95% | §5 | §1 recipe link, §5 split, §6 types | Recipe link + types done; split outputs not done |
| Hunter | 35% | §6 | — | Partial |
| HR | 50% | §7 | §15 AWOL | Repos/config; AWOL flow to verify |
| Accounts | 70% | §8 | — | List, payment, overdue tab |
| Bookkeeping | 80% | §9 | — | Ledger, VAT split, getAccountBalancesToDate |
| Analytics | 90% | §10 | §4 PO, §14 goals | PO create done; “supplier’s products only” pending |
| Reports | 85% | §11 | §8 templates | Export; zero-data templates not verified |
| Customers | 40% | §12 | §7 POS customer | List; POS link not verified |
| Audit | 90% | §13 | — | Log viewer |
| Settings | 35% | §14 | — | Business only; Scale/Tax/Notification to confirm |
| Architecture | — | §1.2 | §12 multi-app | CORE_ARCHITECTURE.md, SupabaseService.client |

---

## 7. Recommended Next Steps (Priority)

1. **Verify/fix Supabase URL** in `admin_config.dart` against user rules (allowed project).
2. **Create PO:** Add “load products for selected supplier only” (e.g. from `product_suppliers`) when supplier is chosen.
3. **Production split:** Design and implement Addendum §5 (single batch → multiple outputs) if required for launch.
4. **Reports:** Ensure templates render and export/print with zero data (Addendum §8).
5. **HR AWOL:** Confirm login and AWOL flow for Owner (Addendum §15).
6. **Stock consistency:** Confirm single source of truth (current_stock vs fresh+frozen) and document or align UI/triggers.

---

*Generated from MASTER_IMPLEMENTATION_PLAN.md, AdminAppBluePrintTruth.md, AdminAppBluePrintTruth_ADDENDUM.md, and codebase review. The full detailed plan (all C/H/M/L items and dependency map) is referenced as `.cursor/plans/master_implementation_plan_28aa35b9.plan.md` in the master plan doc but was not present in the workspace.*
