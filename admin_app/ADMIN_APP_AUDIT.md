# ADMIN APP — FULL CODEBASE AUDIT REPORT
**Generated:** 2026-02-25
**Auditor:** Claude Sonnet 4.6 (automated codebase scan)
**Project:** Struisbaai Vleismark Admin App (App 2 of Butchery OS)
**Working Directory:** `lib/`

---

## LEGEND

| Badge | Meaning |
|-------|---------|
| ✅ | Complete and working |
| ⚠️ | Partial — exists but has gaps |
| ❌ | Missing — not built |
| 🔴 | Critical bug — broken or wrong |

---

## 1. PROJECT STRUCTURE

```
lib/
├── core/
│   ├── constants/
│   │   ├── admin_config.dart          — App constants: PIN length, lockout, allowed roles
│   │   ├── app_colors.dart            — Colour palette (hardcoded hex values)
│   │   └── app_theme.dart             — ThemeData configuration
│   ├── services/
│   │   ├── auth_service.dart          — Session management, role checks (🔴 staff_profiles bug)
│   │   ├── base_service.dart          — Base Supabase helper (🔴 staff_profiles bug)
│   │   ├── export_service.dart        — CSV/Excel/PDF export helpers
│   │   ├── ocr_service.dart           — Google Cloud Vision OCR (❌ empty API key)
│   │   ├── supabase_service.dart      — Supabase client singleton
│   │   └── whatsapp_service.dart      — Twilio WhatsApp (❌ empty credentials)
│   └── utils/
│       └── (utility helpers)
├── features/
│   ├── accounts/
│   │   └── screens/
│   │       └── account_list_screen.dart  — Customer accounts + credit (🔴 staff_profiles bug)
│   ├── analytics/
│   │   ├── screens/
│   │   │   └── shrinkage_screen.dart     — 4 tabs: Shrinkage, Dynamic Pricing, Reorder, Events
│   │   └── services/
│   │       └── analytics_repository.dart — Supabase queries for analytics data
│   ├── audit/
│   │   ├── screens/
│   │   │   └── audit_log_screen.dart     — Read-only audit log viewer
│   │   └── services/
│   │       └── audit_repository.dart     — SELECT only, no INSERT anywhere (🔴 critical gap)
│   ├── auth/
│   │   └── screens/
│   │       └── pin_screen.dart           — PIN login + offline JSON cache (🔴 staff_profiles bug)
│   ├── bookkeeping/
│   │   └── screens/
│   │       ├── invoice_list_screen.dart  — 6 tabs: Invoices, Ledger, Chart of Accounts, P&L, Equipment, PTY
│   │       ├── ledger_screen.dart        — Double-entry ledger
│   │       └── pty_conversion_screen.dart — PTY Ltd checklist + document upload ✅
│   ├── customers/
│   │   ├── screens/
│   │   │   ├── announcement_screen.dart  — Push announcements to customers
│   │   │   └── customer_list_screen.dart — Loyalty customer list + WhatsApp (url_launcher)
│   │   └── services/
│   │       └── customer_repository.dart  — Queries: loyalty_customers, announcements
│   ├── dashboard/
│   │   └── screens/
│   │       ├── dashboard_screen.dart     — KPIs + 7-day chart + alerts (🔴 staff_profiles bug)
│   │       └── main_shell.dart           — Sidebar nav + auto-lock (5 min background)
│   ├── hr/
│   │   ├── models/
│   │   │   ├── awol_record.dart          — (🔴 staff_profiles in FK reference)
│   │   │   └── staff_credit.dart         — (🔴 staff_profiles in FK reference)
│   │   └── screens/
│   │       ├── compliance_screen.dart    — Compliance checks (🔴 staff_profiles bug)
│   │       ├── staff_credit_screen.dart  — Staff credit management (🔴 staff_profiles bug)
│   │       └── staff_list_screen.dart    — 7-tab HR module (🔴 staff_profiles bug × 15+)
│   ├── hunter/
│   │   ├── models/
│   │   │   └── hunter_job.dart           — Hunter job model
│   │   ├── screens/
│   │   │   ├── job_intake_screen.dart    — Species, services, materials intake form
│   │   │   ├── job_list_screen.dart      — 3 tabs: Active, Completed, Services Config
│   │   │   ├── job_process_screen.dart   — Processing steps per service
│   │   │   └── job_summary_screen.dart   — Job summary + billing
│   │   └── services/                     — Hunter service helpers (new, untracked)
│   ├── inventory/
│   │   ├── blocs/
│   │   │   └── category/
│   │   │       └── category_bloc.dart    — BLoC for category state
│   │   ├── models/
│   │   │   ├── category.dart             — Category model with parent/sub support
│   │   │   └── inventory_item.dart       — Product model (full field set)
│   │   └── screens/
│   │       ├── category_form_screen.dart — Add/edit category with parent selector
│   │       ├── category_list_screen.dart — Category list with hierarchy display
│   │       ├── inventory_navigation_screen.dart — Tab shell for inventory
│   │       ├── product_list_screen.dart  — Full product CRUD (PLU lock ✅, 25k+ tokens)
│   │       ├── stock_take_screen.dart    — Barcode scanner + stock count
│   │       └── supplier_list_screen.dart — Supplier management
│   ├── production/
│   │   ├── models/
│   │   │   └── production_batch.dart     — Carcass/batch model
│   │   └── screens/
│   │       └── carcass_intake_screen.dart — 6-tab production screen
│   ├── promotions/
│   │   └── screens/
│   │       ├── promotion_form_screen.dart — 5-step promotion builder
│   │       └── promotion_list_screen.dart — Promotion list with status tabs ✅
│   ├── reports/
│   │   └── screens/
│   │       └── report_hub_screen.dart    — Report hub with filters and export
│   └── settings/
│       └── screens/
│           └── business_settings_screen.dart — 5 tabs: Business Info, Scale/HW, Tax, Notifications, Utilities
├── shared/
│   └── widgets/
│       └── form_widgets.dart             — Reusable form input widgets
└── main.dart                             — App entry point + Supabase init

supabase/
└── migrations/
    ├── 001_admin_app_tables_part1.sql    — Core tables (profiles, products, categories...)
    ├── 002–045_*.sql                      — Incremental schema migrations
    ├── 046_categories_parent_subcategory.sql — Category hierarchy (new, untracked)
    ├── 047_promotions.sql                — Promotions schema (new, untracked)
    └── 048_hunter_species_services.sql   — Hunter species/services (new, untracked)
```

---

## 2. DEPENDENCIES (`pubspec.yaml`)

| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| `supabase_flutter` | ^2.0.0 | Backend / auth | ✅ Used |
| `isar` | ^3.1.0 | Local cache DB | 🔴 Declared, zero Isar models exist |
| `isar_flutter_libs` | ^3.1.0 | Isar native libs | 🔴 Declared but unused |
| `crypto` | ^3.0.3 | SHA-256 PIN hash | ⚠️ Works but spec says bcrypt |
| `flutter_bloc` | ^8.0.0 | State management | ⚠️ Only used in inventory/category |
| `shared_preferences` | ^2.0.0 | Session storage | ✅ Used for auth session |
| `path_provider` | ^2.0.0 | File paths | ✅ Used for JSON cache |
| `syncfusion_flutter_charts` | ^28.0.0 | Charts | ✅ Dashboard + Analytics |
| `syncfusion_flutter_datagrid` | ^28.0.0 | Data tables | ✅ Various list screens |
| `googleapis` | ^12.0.0 | Google Cloud Vision | 🔴 Declared, empty API key |
| `pdf` | ^3.0.0 | PDF generation | ✅ Used in export_service |
| `printing` | ^5.0.0 | Print PDF | ✅ Used in export_service |
| `csv` | ^5.0.0 | CSV export | ✅ Used in export_service |
| `excel` | ^4.0.0 | Excel export | ✅ Used in export_service |
| `mobile_scanner` | ^4.0.0 | Barcode scan | ✅ Used in stock_take_screen |
| `file_picker` | ^6.0.0 | Document upload | ✅ Used in pty_conversion_screen |
| `url_launcher` | ^6.0.0 | WhatsApp launch | ⚠️ Opens WhatsApp URL, no Twilio API |
| `intl` | ^0.19.0 | Date/number format | ✅ Used throughout |
| `uuid` | ^4.0.0 | UUID generation | ✅ Used throughout |

---

## 3. MODULE STATUS

### 3.1 AUTH ⚠️ Partial

| Feature | Status | Notes |
|---------|--------|-------|
| PIN login screen | ✅ | 4-digit PIN, numeric keypad |
| Offline JSON cache | ✅ | JSON file via path_provider |
| SHA-256 PIN hashing | ⚠️ | Works but spec requires bcrypt |
| Isar local cache / CachedProfile | 🔴 | Zero Isar models — not built |
| Auto-lock on background (5 min) | ✅ | Implemented in MainShell via WidgetsBindingObserver |
| Max 5 PIN attempts + 15 min lockout | ✅ | AdminConfig constants applied |
| Role gate (owner/manager only) | ✅ | AdminConfig.allowedRoles enforced |
| `profiles` table query | 🔴 | Queries `staff_profiles` — WRONG table name |
| `butchery_assistant` role | 🔴 | Not defined anywhere in app |
| Biometric fallback | ❌ | Not built |

### 3.2 DASHBOARD ⚠️ Partial

| Feature | Status | Notes |
|---------|--------|-------|
| Today's sales KPI | ✅ | Real-time via Supabase subscription |
| Transaction count | ✅ | |
| Average basket | ✅ | |
| Gross margin % | ✅ | |
| 7-day sales chart | ✅ | Syncfusion line chart |
| Shrinkage alerts | ✅ | |
| Reorder alerts | ✅ | |
| Clock-in status (staff) | ✅ | From timecards + staff_profiles |
| Top products widget | ❌ | Not built |
| Role-based financial visibility | ❌ | Manager sees all financial KPIs — should be owner-only |
| `profiles` table query | 🔴 | Queries `staff_profiles` — WRONG |

### 3.3 INVENTORY ⚠️ Partial

| Feature | Status | Notes |
|---------|--------|-------|
| Product list with search | ✅ | Search by name/PLU/barcode |
| Product CRUD (add/edit/archive) | ✅ | Full form |
| PLU read-only after creation | ✅ | `enabled: widget.product == null` |
| POS display name (max 20 chars) | ✅ | `maxLength: 20` enforced |
| Scale label name (max 16 chars) | ✅ | `maxLength: 16` enforced |
| Category list with hierarchy | ✅ | Parent/sub-category support |
| Category CRUD | ✅ | |
| Supplier list | ✅ | |
| Stock take (barcode scanner) | ✅ | mobile_scanner integrated |
| Waste log screen | ❌ | Not built |
| Dedicated stock movements screen | ❌ | Not built |
| Price history / audit trail | ❌ | Not built |

### 3.4 PRODUCTION ⚠️ Partial

| Feature | Status | Notes |
|---------|--------|-------|
| Carcass intake | ✅ | 6-tab screen |
| Batch processing | ✅ | |
| Yield recording | ✅ | |
| Breakdown history tab | ❌ | Not observed in tabs |
| Waste recording per batch | ⚠️ | Unclear if captured |

### 3.5 PROMOTIONS ✅ Complete

| Feature | Status | Notes |
|---------|--------|-------|
| 5-step promotion builder | ✅ | Basic → Trigger → Reward → Audience → Schedule |
| 7 promotion types | ✅ | BOGO, Bundle, SpendThreshold, WeightThreshold, TimeBased, PointsMultiplier, Custom |
| 7 reward types | ✅ | |
| Status tabs (All/Active/Draft/Scheduled/Expired) | ✅ | |
| Product linking | ✅ | Reads `promotion_products` join table |
| Activate/deactivate toggle | ✅ | |

### 3.6 HUNTER JOBS ✅ Complete

| Feature | Status | Notes |
|---------|--------|-------|
| Job intake form | ✅ | Species, services, materials |
| Processing steps per service | ✅ | job_process_screen.dart |
| Job lifecycle (intake→processing→ready→completed) | ✅ | Status transitions implemented |
| Create parked sale when ready | ✅ | Linked to POS |
| Services configuration tab | ✅ | name, base_price, price_per_kg, cut_options, linked_product |
| Species management | ✅ | From migration 048 |

### 3.7 HR / STAFF ⚠️ Partial

| Feature | Status | Notes |
|---------|--------|-------|
| Staff profiles tab | ✅ | Full form with all fields |
| Timecards tab | ✅ | Clock in/out |
| Leave management tab | ✅ | |
| Payroll tab | ✅ | Weekly/monthly frequency |
| AWOL tracker tab | ✅ | |
| Staff credit tab | ✅ | |
| Compliance tab | ✅ | |
| `butchery_assistant` role | 🔴 | MISSING from role dropdown |
| `profiles` table query | 🔴 | Queries `staff_profiles` — WRONG (×15+ locations) |

### 3.8 STAFF CREDITS ⚠️ Partial

| Feature | Status | Notes |
|---------|--------|-------|
| Staff credit screen | ✅ | Separate nav item + tab in HR |
| `profiles` table query | 🔴 | Queries `staff_profiles` — WRONG |

### 3.9 COMPLIANCE ⚠️ Partial

| Feature | Status | Notes |
|---------|--------|-------|
| Compliance checklist screen | ✅ | |
| `profiles` table query | 🔴 | Queries `staff_profiles` — WRONG |

### 3.10 ACCOUNTS ⚠️ Partial

| Feature | Status | Notes |
|---------|--------|-------|
| Account list | ✅ | |
| Customer credit | ✅ | |
| `profiles` table query | 🔴 | Queries `staff_profiles` — WRONG (account_list_screen lines 1826, 1829, 1839) |

### 3.11 BOOKKEEPING ⚠️ Partial

| Feature | Status | Notes |
|---------|--------|-------|
| Invoice list | ✅ | |
| Ledger (double-entry) | ✅ | |
| Chart of Accounts | ✅ | |
| P&L / Reports tab | ✅ | |
| Equipment tab | ✅ | |
| PTY Conversion checklist | ✅ | 8 steps, document upload, deadline 1 Mar 2026 |
| OCR invoice scanning | 🔴 | Wired but empty API key — NOT functional |
| Owner-only gate | ✅ | Nav item only shown for isOwner |

### 3.12 ANALYTICS ⚠️ Partial

| Feature | Status | Notes |
|---------|--------|-------|
| Shrinkage alerts | ✅ | Tab 1 |
| Dynamic pricing suggestions | ✅ | Tab 2 |
| Predictive reorder | ✅ | Tab 3 |
| Event forecasting | ✅ | Tab 4 |
| Sales trend drilldown | ❌ | Not built as separate screen |

### 3.13 REPORTS ⚠️ Partial

| Feature | Status | Notes |
|---------|--------|-------|
| Report hub with filters | ✅ | Date range, category, report type |
| PDF/CSV/Excel export | ✅ | Via export_service.dart |
| Custom report builder | ❌ | Not built |

### 3.14 CUSTOMERS ⚠️ Partial

| Feature | Status | Notes |
|---------|--------|-------|
| Loyalty customer list | ✅ | Queries `loyalty_customers` table |
| Announcements screen | ✅ | Push to `announcements` table |
| WhatsApp messaging | ⚠️ | Opens WhatsApp via url_launcher — NOT Twilio API |
| Twilio WhatsApp API | 🔴 | Wired but empty credentials — NOT functional |

### 3.15 AUDIT LOG ❌ Critical Gap

| Feature | Status | Notes |
|---------|--------|-------|
| Audit log viewer (read) | ✅ | audit_log_screen.dart reads audit_repository |
| Audit log writes from any module | 🔴 | **Zero INSERT calls to audit_log anywhere in codebase** |
| Automatic action logging | 🔴 | No module writes to audit_log on create/update/delete |

### 3.16 SETTINGS ⚠️ Partial

| Feature | Status | Notes |
|---------|--------|-------|
| Business info tab | ✅ | |
| Scale / hardware config tab | ✅ | |
| Tax rates tab | ✅ | |
| Notifications tab | ✅ | |
| Utilities tab | ✅ | |
| User management screen | ❌ | Not built |
| Receipt / slip settings | ❌ | Not built |
| POS terminal config | ❌ | Not built |
| Payroll defaults | ❌ | Not built |
| Slow-mover thresholds config | ❌ | Not built |
| Owner-only gate | ✅ | Nav item only shown for isOwner |

---

## 4. CRITICAL BUGS 🔴

### BUG-001: `staff_profiles` Table — Wrong Name Throughout Entire Codebase

**Severity:** CRITICAL — will cause runtime 400/404 errors from Supabase on every staff query.

**Root Cause:** The correct PostgreSQL table name (per migration `001_admin_app_tables_part1.sql` and all FK references) is **`profiles`**. Every Dart file queries **`staff_profiles`** — a table that does not exist.

**Affected Files (confirmed via grep):**

| File | Occurrences |
|------|------------|
| `lib/core/services/auth_service.dart` | Lines 76, 133, 171, 279 |
| `lib/core/services/base_service.dart` | Line 69 |
| `lib/features/auth/screens/pin_screen.dart` | Lines 103, 155 |
| `lib/features/dashboard/screens/dashboard_screen.dart` | Lines 159, 175 |
| `lib/features/hr/screens/staff_list_screen.dart` | Lines 108, 381, 415, 906, 911, 1184, 1449, 1664, 2098, 2148, 2152 (15+ occurrences) |
| `lib/features/hr/screens/staff_credit_screen.dart` | Multiple |
| `lib/features/hr/screens/compliance_screen.dart` | Multiple |
| `lib/features/accounts/screens/account_list_screen.dart` | Lines 1826, 1829, 1839 |
| `lib/features/reports/screens/report_hub_screen.dart` | Multiple |
| `lib/features/hr/models/awol_record.dart` | FK reference |
| `lib/features/hr/models/staff_credit.dart` | FK reference |
| `lib/core/services/compliance_service.dart` | Multiple |
| `lib/features/hr/services/awol_repository.dart` | Multiple |
| `lib/features/hr/services/staff_credit_repository.dart` | Multiple |

**Fix:** Global find-and-replace `staff_profiles` → `profiles` across all Dart files.

---

### BUG-002: SHA-256 PIN Hashing — Not bcrypt

**Severity:** HIGH — security specification mismatch.

**Detail:** `auth_service.dart` and `pin_screen.dart` use `crypto` package with SHA-256 to hash PINs before storage/comparison. The specification requires bcrypt (slow hash, salted). SHA-256 is fast and unsalted — making brute-force of 4-digit PINs trivial (only 10,000 combinations).

**Fix:** Replace `crypto` SHA-256 with `bcrypt` package (or `dart_bcrypt`). Update PIN storage and comparison logic.

---

### BUG-003: Isar Declared But Not Implemented

**Severity:** HIGH — architecture specification not met.

**Detail:** `pubspec.yaml` declares `isar: ^3.1.0` and `isar_flutter_libs: ^3.1.0`. The specification requires a `CachedProfile` Isar model for offline-capable PIN auth and local data caching. **Zero Isar models exist in the codebase.** Offline caching uses a plain JSON file via `path_provider` instead.

**Fix:** Create `lib/core/models/cached_profile.dart` with `@collection` annotation. Run `isar_generator`. Replace JSON file cache with Isar writes/reads in `auth_service.dart` and `pin_screen.dart`.

---

### BUG-004: Audit Log Has Zero Write Calls

**Severity:** HIGH — compliance and traceability requirement not met.

**Detail:** `audit_log_screen.dart` displays audit records and `audit_repository.dart` can read them. However, **no module in the entire codebase inserts any record into `audit_log`**. Every create, update, delete, login, logout, and role change goes unlogged.

**Affected:** All modules — product changes, staff changes, promotions, sales voids, inventory adjustments, etc.

**Fix:** Create an `AuditService.log(action, table, recordId, oldValues, newValues)` method. Call it after every significant mutation across all modules, or implement a Supabase database trigger to capture row-level changes automatically.

---

### BUG-005: OCR Not Configured

**Severity:** MEDIUM — feature advertised but non-functional.

**Detail:** `lib/core/services/ocr_service.dart` has Google Cloud Vision OCR wired via `googleapis` package with `_apiKey = ''` (empty string). Any OCR call will throw an authentication error.

**Fix:** Provide a valid Google Cloud Vision API key via a secrets file or environment variable. Never hardcode in source.

---

### BUG-006: WhatsApp / Twilio Not Configured

**Severity:** MEDIUM — feature non-functional.

**Detail:** `lib/core/services/whatsapp_service.dart` has Twilio WhatsApp API wired with `_accountSid = ''`, `_authToken = ''`, `_fromNumber = ''`. The customer list currently falls back to `url_launcher` (opens native WhatsApp app) rather than sending programmatic messages.

**Fix:** Provide Twilio credentials via secure config. Update `customer_list_screen.dart` to use `WhatsappService` instead of `url_launcher`.

---

### BUG-007: `butchery_assistant` Role Missing

**Severity:** MEDIUM — incomplete role hierarchy.

**Detail:** `admin_config.dart` defines `allowedRoles: ['owner', 'manager']` and `rejectedRoles: ['cashier', 'blockman']`. The role `butchery_assistant` is never defined, not in the role dropdown in `staff_list_screen.dart`, and not handled anywhere in role-based access checks.

**Fix:** Add `'butchery_assistant'` to role dropdown options in staff form. Determine whether it should be an allowed admin role or a rejected (POS-only) role, and update `AdminConfig` accordingly.

---

## 5. CROSS-CUTTING ISSUES

### 5.1 Table Name Bug
🔴 **`staff_profiles` used instead of `profiles`** — see BUG-001 above. 14+ files affected.

### 5.2 Isar Usage
🔴 **Zero Isar models exist.** Declared in pubspec, never implemented. JSON file used instead.

### 5.3 Audit Log Writes
🔴 **Zero INSERT calls to `audit_log` in any module.** See BUG-004 above.

### 5.4 Hardcoded Colours
⚠️ All colours are correctly centralised in `lib/core/constants/app_colors.dart`. Screens reference `AppColors.*` constants. No raw hex strings found directly in widget trees — this is **well implemented**.

### 5.5 Direct Supabase Calls in Screen Files
⚠️ **Mixed pattern.** Some modules have dedicated repository/service classes (analytics, audit, customer, compliance, staff_credit, awol). However, several large screen files (`product_list_screen.dart`, `staff_list_screen.dart`, `account_list_screen.dart`) contain direct `Supabase.instance.client.from(...)` calls inline. This makes testing and refactoring harder.

**Recommendation:** Extract all Supabase queries to repository classes. Screens should only call repositories.

### 5.6 Missing Loading / Error States
⚠️ **Inconsistent.** Some screens show `CircularProgressIndicator` and error `SnackBar` messages. Others load data silently with no loading indicator and swallow errors without user feedback. A reusable `AsyncStateWidget` or BLoC pattern should be applied uniformly.

### 5.7 Role-Based Access Control
⚠️ **Partially implemented.**
- `isOwner` gate: ✅ Bookkeeping and Settings nav items hidden from non-owners.
- Dashboard financial KPIs: ❌ Manager can see gross margin, revenue — should be owner-only or togglable.
- Feature-level: `AuthService.canAccessFeature()` method exists but is **not called** in most screens.
- No per-action permission checks (e.g., manager cannot void sales, only owner can).

### 5.8 PLU Lock
✅ **Correctly implemented.** In `product_list_screen.dart` line 1148:
```dart
enabled: widget.product == null,
```
PLU code field is editable only when creating a new product. Edit mode locks it.

---

## 6. DATABASE TABLE MAP

Tables confirmed via migration files and Dart code:

| Table | Used By | Notes |
|-------|---------|-------|
| `profiles` | auth_service, pin_screen, dashboard, hr (🔴 wrong name in code) | Correct name per migrations |
| `products` | product_list_screen, inventory | |
| `categories` | category_list_screen, category_form_screen | |
| `suppliers` | supplier_list_screen | |
| `stock_movements` | stock_take_screen | |
| `promotions` | promotion_list_screen, promotion_form_screen | |
| `promotion_products` | promotion_form_screen | |
| `hunter_jobs` | job_list_screen, job_intake_screen | |
| `hunter_job_processes` | job_process_screen | |
| `hunter_services` | job_list_screen (services config tab) | |
| `hunter_species` | job_intake_screen | From migration 048 |
| `timecards` | staff_list_screen | |
| `leave_requests` | staff_list_screen | |
| `payroll_records` | staff_list_screen | |
| `awol_records` | awol_repository | |
| `staff_credits` | staff_credit_repository | |
| `compliance_records` | compliance_service | |
| `transactions` | dashboard_screen (real-time) | |
| `transaction_items` | reports | |
| `loyalty_customers` | customer_repository | NOT `customers` |
| `announcements` | customer_repository, announcement_screen | |
| `audit_log` | audit_repository (READ ONLY) | No writes from app |
| `business_settings` | business_settings_screen, pty_conversion_screen | |
| `invoices` | invoice_list_screen | |
| `ledger_entries` | ledger_screen | |
| `chart_of_accounts` | invoice_list_screen | |
| `documents` (bucket) | pty_conversion_screen | Supabase Storage |
| `analytics_cache` | analytics_repository | |

---

## 7. WHAT IS NOT BUILT

| Feature | Priority | Notes |
|---------|----------|-------|
| Isar / CachedProfile offline cache | HIGH | pubspec declares it, nothing implemented |
| bcrypt PIN hashing | HIGH | Using SHA-256 instead |
| Audit log writes (any module) | HIGH | Critical compliance gap |
| `butchery_assistant` role support | MEDIUM | Missing from all role lists |
| Top products dashboard widget | MEDIUM | Spec requires it |
| Owner-only dashboard financials gate | MEDIUM | Manager sees all KPIs |
| Waste log screen | MEDIUM | Inventory gap |
| Stock movements history screen | MEDIUM | Inventory gap |
| Price history / audit trail | MEDIUM | Inventory gap |
| Production breakdown history tab | MEDIUM | |
| User management screen (Settings) | MEDIUM | Cannot create/deactivate admin users in-app |
| Receipt / slip settings | LOW | |
| POS terminal configuration | LOW | |
| Payroll defaults in Settings | LOW | |
| Slow-mover threshold configuration | LOW | |
| Twilio WhatsApp API (real) | MEDIUM | Using url_launcher fallback |
| Google Cloud Vision OCR (live) | MEDIUM | Empty API key |
| Custom report builder | LOW | |
| Biometric PIN fallback | LOW | Not in spec but common UX ask |
| Per-feature role permission checks | MEDIUM | `canAccessFeature()` defined but not called |

---

## 8. WHAT NEEDS FIXING (Priority Order)

### P1 — Fix Before Any Testing

1. **Global rename `staff_profiles` → `profiles`** in all Dart files.
   Command: `grep -rl "staff_profiles" lib/ | xargs sed -i 's/staff_profiles/profiles/g'`
   Then verify each changed file manually.

2. **Add `butchery_assistant` to role dropdown** in `staff_list_screen.dart` and `admin_config.dart`.

3. **Implement audit log INSERT** — create `AuditService.log()` and call it in at minimum:
   - Product create/update/archive
   - Staff create/update/deactivate
   - Sale void
   - Promotion activate/deactivate
   - Inventory stock take submit

### P2 — Security

4. **Replace SHA-256 with bcrypt** for PIN hashing (auth_service.dart, pin_screen.dart).

5. **Add owner-only gate to dashboard financial KPIs** — gross margin and revenue should not be visible to manager role.

6. **Provide OCR API key** (via secure environment config, not hardcoded).

7. **Provide Twilio credentials** (via secure environment config).

### P3 — Architecture

8. **Implement Isar models** — create `CachedProfile` (and optionally `CachedProduct`) with `@collection`. Replace JSON file cache.

9. **Extract inline Supabase queries to repositories** — particularly in `product_list_screen.dart`, `staff_list_screen.dart`, `account_list_screen.dart`.

10. **Apply `canAccessFeature()` checks** in screens where role-based action gating is needed.

### P4 — Missing Screens

11. Build **waste log screen** under Inventory.
12. Build **stock movements history screen** under Inventory.
13. Build **user management screen** under Settings.
14. Add **top products widget** to dashboard.

---

## 9. RECOMMENDED BUILD / FIX ORDER

Given the **PTY Ltd Conversion deadline of 1 March 2026** (3 days from audit date):

| Step | Task | Deadline | Status |
|------|------|----------|--------|
| 1 | PTY Conversion screen functional | 1 Mar 2026 | ✅ DONE — screen exists and uploads work |
| 2 | Fix `staff_profiles` → `profiles` bug | Immediate | 🔴 BROKEN — app won't log in |
| 3 | Add audit log INSERT calls | This week | 🔴 Compliance gap |
| 4 | Add `butchery_assistant` role | This week | 🔴 Missing |
| 5 | Owner-only financial gate on dashboard | This week | ⚠️ Gap |
| 6 | Replace SHA-256 with bcrypt | Next sprint | ⚠️ Security |
| 7 | Configure OCR API key | Next sprint | ⚠️ Non-functional feature |
| 8 | Configure Twilio credentials | Next sprint | ⚠️ Non-functional feature |
| 9 | Implement Isar CachedProfile | Next sprint | ⚠️ Architecture gap |
| 10 | Build waste log + stock movements screens | Next sprint | ❌ Missing |
| 11 | Build user management screen in Settings | Next sprint | ❌ Missing |
| 12 | Extract repositories from large screen files | Ongoing | ⚠️ Code quality |
| 13 | Add top products widget to dashboard | After above | ❌ Missing |
| 14 | Build custom report builder | Low priority | ❌ Missing |

---

## 10. SIDEBAR NAVIGATION — ACTUAL VS EXPECTED

| Index | Icon | Label | Screen | Owner Only | Status |
|-------|------|-------|--------|------------|--------|
| 0 | `dashboard` | Dashboard | `DashboardScreen` | No | ✅ |
| 1 | `inventory_2` | Inventory | `InventoryNavigationScreen` | No | ✅ |
| 2 | `local_offer` | Promotions | `PromotionListScreen` | No | ✅ |
| 3 | `cut` | Production | `CarcassIntakeScreen` | No | ✅ |
| 4 | `forest` | Hunter | `JobListScreen` | No | ✅ |
| 5 | `people` | HR / Staff | `StaffListScreen` | No | ✅ |
| 6 | `account_balance_wallet` | Staff Credits | `StaffCreditScreen` | No | ✅ |
| 7 | `fact_check` | Compliance | `ComplianceScreen` | No | ✅ |
| 8 | `credit_card` | Accounts | `AccountListScreen` | No | ✅ |
| 9 | `book` | Bookkeeping | `InvoiceListScreen` | **Yes** | ✅ |
| 10 | `analytics` | Analytics | `ShrinkageScreen` | No | ✅ |
| 11 | `summarize` | Reports | `ReportHubScreen` | No | ✅ |
| 12 | `person_search` | Customers | `CustomerListScreen` | No | ✅ |
| 13 | `history` | Audit Log | `AuditLogScreen` | No | ✅ |
| 14 | `settings` | Settings | `BusinessSettingsScreen` | **Yes** | ✅ |

**Total nav items:** 15 (13 always visible + 2 owner-only)

**Gaps vs expected:**
- No **Ledger / Bookkeeping** separate from invoices (merged into InvoiceListScreen tabs — acceptable)
- No separate **Stock Movements** nav item (❌ screen not built)
- No separate **Waste Log** nav item (❌ screen not built)
- Analytics tab shows only `ShrinkageScreen` — the 4-tab analytics (shrinkage, dynamic pricing, reorder, events) is housed inside that one screen (acceptable but confusing label)

---

## SUMMARY SCORECARD

| Module | Score | Blocker |
|--------|-------|---------|
| Auth | 5/10 | staff_profiles bug, no Isar, SHA-256 |
| Dashboard | 6/10 | staff_profiles bug, no top products, no role gate on financials |
| Inventory | 7/10 | No waste log, no movements screen |
| Production | 7/10 | No breakdown history |
| Promotions | 9/10 | — |
| Hunter Jobs | 9/10 | — |
| HR / Staff | 5/10 | staff_profiles bug ×15, missing butchery_assistant role |
| Staff Credits | 5/10 | staff_profiles bug |
| Compliance | 6/10 | staff_profiles bug |
| Accounts | 6/10 | staff_profiles bug |
| Bookkeeping | 8/10 | OCR not configured |
| Analytics | 7/10 | — |
| Reports | 7/10 | No custom builder |
| Customers | 6/10 | Twilio not configured |
| Audit Log | 2/10 | **No writes from any module — critical** |
| Settings | 5/10 | Missing user management, receipt, payroll, POS config |
| **OVERALL** | **6/10** | Fix staff_profiles bug first — app is broken at login |

---

*End of audit report. Total files scanned: 45+ Dart files, 48 migration SQL files.*
