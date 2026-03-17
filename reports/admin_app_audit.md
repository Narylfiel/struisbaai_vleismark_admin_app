# Admin App Audit Report

**Date:** 2024-05-22  
**Status:** COMPLETE (Strict Read-Only Analysis)  
**Objective:** Audit the Admin App against the blueprint with focus on control logic, permissions, and database integrity.

---

## 1. ADMIN FEATURE MAPPING

| Feature | Blueprint Requirement | Admin App Status | Implementation Note |
| :--- | :--- | :--- | :--- |
| **Dashboard** | Sales, Trans count, Avg Basket, Margin | ✅ MATCH | Uses `transactions` table; real-time refresh via Supabase channel. |
| **Inventory** | Management of products, stock, categories | ✅ MATCH | Multi-tab form covering Blueprint Sections A–H. |
| **Waste Logging** | Track shrinkage, reasons, staff attribution | ✅ MATCH | Handles `waste` and `sponsorship`; supports photo evidence and CSV/PDF export. |
| **HR / Staff** | Profiles, Timecards, Compliance, Payroll | ✅ MATCH | Staff list and compliance tracking screens implemented. |
| **Accounts** | Business accounts, credit terms, balances | ✅ MATCH | `AccountListScreen` tracks balances and overdue alerts. |
| **Bookkeeping** | Invoices, VAT reports, Ledger | ✅ MATCH | `InvoiceListScreen` and `ReportService` handle these. |
| **Promotions** | Deal management, discounts | ✅ MATCH | `PromotionListScreen` implemented. |
| **Audit Log** | Tracking all changes across all apps | ✅ MATCH | `AuditLogScreen` tied to central `audit_log` table. |

---

## 2. PERMISSION LOGIC

### Role-Based Access Control (RBAC)
The system uses a sophisticated `PermissionService` (Singleton) that:
1. Loads permissions from `admin_roles` (defaults).
2. Applies personal overrides from `profiles.permissions` (JSONB).
3. Caches locally for offline checks.
4. Implements `isOwner` bypass (full access).

### Security Risk Identification
- **Access Control:** `MainShell` dynamically builds the sidebar and **locks** screens based on `PermissionService.can()`. This is robust and prevents unauthorized access via navigation.
- **PIN Security:** Enforced at app launch (`PinScreen`). Verifies against `profiles.pin_hash` (SHA-256). Works offline using Isar cache.
- **Dead Code Risk:** `lib/shared/widgets/sidebar_nav.dart` is a dead component with hardcoded `isOwner` logic. It should be removed to avoid confusion, though it is not used in the live app (`MainShell` is used instead).

---

## 3. FEATURE LOGIC TRACE (Sample: Waste Logging)

- **Trigger:** Staff clicks "Add" on `WasteLogScreen`.
- **Processing:**
  - Dialog prompts for Item (PLU search), Quantity, Reason, and Photo.
  - Cost price is fetched from `inventory_items` to calculate "Estimated Value".
  - Staff ID is auto-filled from the current auth session.
- **DB Interaction:** Writes to `stock_movements` table with `movement_type = 'waste'`.
- **Validation:** Ensures non-negative quantities and valid item selection.
- **Output:** Entry appears in the Waste Log list; stats (`_wasteValue`) update immediately.

---

## 4. SUPABASE STRUCTURE AUDIT

### Tables Identified
| Category | Tables |
| :--- | :--- |
| **Core Admin** | `admin_roles`, `audit_log`, `business_settings` |
| **Shared** | `inventory_items`, `categories`, `profiles`, `staff_profiles` |
| **Transactions** | `transactions`, `transaction_items`, `till_sessions` |
| **Inventory Log** | `stock_movements`, `shrinkage_alerts`, `reorder_recommendations` |
| **HR/Staff** | `timecards`, `leave_requests`, `payroll_records` |
| **Accounting** | `business_accounts`, `invoices`, `ledger_entries` |

### Consistency Check
- **Naming:** Consistent snake_case used throughout (e.g., `plu_code`, `sell_price`, `cost_amount`).
- **Shared Integrity:** `inventory_items` matches Section A-H blueprint almost perfectly. The use of `categoryId` as a UUID vs `pluCode` in old docs is correctly handled via joins.

---

## 5. DATA CONSISTENCY CHECK

- **Admin → POS:** Updates to `inventory_items` (prices, stock status) are handled via Supabase; POS will receive these via its own sync logic.
- **POS → Admin:** Admin dashboard now correctly queries the `transactions` table (previously used `sales` table, which was flagged as a gap). This ensures real-time visibility of POS activity.
- **Offline Sync:** Admin app uses Isar for all core entities. `OfflineQueueService` and `ConnectivityService` handle background sync of local changes (e.g., stock adjustments made while offline).

---

## 6. RISKS & RECOMMENDATIONS

| Type | Risk | Recommendation |
| :--- | :--- | :--- |
| **Maintenance** | **Dead Code:** `sidebar_nav.dart` contains outdated logic and is unused. | Delete `lib/shared/widgets/sidebar_nav.dart`. |
| **Data Integrity** | **Margin Logic:** Dashboard calculates margin using `cost_amount` on the transaction. If POS doesn't populate this, margin metrics will be 0. | Ensure POS `initiateSale` logic calculates and writes `cost_amount` per line. |
| **UX / Security** | **Offline PIN Stale:** Offline PIN verification relies on the last successful sync. If a user was deactivated but the app hasn't synced, they could log in offline. | Implement a "Last Sync" timestamp check on the Pin Screen; force online check if sync > 24h. |
| **Performance** | **Large Transaction Lists:** Dashboard loads last 7 days of transactions in memory to compute totals. | Implement a SQL function or DB view for dashboard stats to offload computation to Supabase. |

---
*Audit complete. No code modifications were performed during this analysis.*
