# FLUTTER CODEBASE AUDIT REPORT
## Struisbaai Vleismark Admin App

**Date:** February 27, 2026  
**Type:** Full exhaustive audit (replaces 26_Feb_Audit)  
**Scope:** All bugs, incomplete features, missing implementations, TODOs, hardcoded values, table name mismatches, empty credentials, code quality issues.

---

## 1. EXECUTIVE SUMMARY

- **Codebase:** Flutter desktop admin app (Windows primary), feature-first layout, Supabase backend.
- **Dart files:** 144+ under `lib/`.
- **SQL migrations:** 49 under `supabase/migrations/`.
- **Overall grade:** **B- (7.5/10)** — Solid feature set; credentials, schema consistency, and code hygiene need attention.

---

## 2. BUGS (EXHAUSTIVE)

### 2.1 Critical / High

| ID | Description | Location | Notes |
|----|-------------|----------|--------|
| BUG-001 | **Recipes table has `name`, not `title`** — query orders by non-existent column | `lib/features/customers/services/customer_repository.dart` line 93 | `getRecipes()` uses `.order('title')`; `recipes` table has `name`. Will throw or sort incorrectly. |
| BUG-002 | **Dual recipe delete** — Customer module has its own `deleteRecipe()` with no cascade | `lib/features/customers/services/customer_repository.dart` lines 101–105 | Simple `recipes.delete()`; no recipe_ingredients, production_batch_ingredients, or recipe_id nulling. Conflicts with production’s full cascade in `recipe_repository.dart`. |
| BUG-003 | **profiles vs staff_profiles** — Two identity tables used inconsistently | App-wide | Migrations reference both. Auth/login use `staff_profiles`; user_management_screen, pin_screen, permission_service use `profiles` for some ops. If only one table exists in DB, some code paths fail. |
| BUG-004 | **Isar declared but unused** | `pubspec.yaml`, auth flow | No Isar models; offline auth uses JSON file cache. Spec/architecture mismatch. |
| BUG-005 | **PIN hashing: SHA-256 unsalted** | `auth_service.dart`, `pin_screen.dart` | Spec suggests bcrypt; current scheme is weak for 4-digit PIN space. |

### 2.2 Medium (Credentials / Non-functional features)

| ID | Description | Location |
|----|-------------|----------|
| BUG-006 | **OCR API key empty** — Google Cloud Vision never configured | `lib/core/services/ocr_service.dart` line 14: `final String _apiKey = '';` |
| BUG-007 | **Twilio WhatsApp credentials empty** | `lib/core/services/whatsapp_service.dart` lines 13–15: `_accountSid`, `_authToken`, `_fromNumber` all `''` |
| BUG-008 | **Supabase URL and anon key hardcoded** | `lib/core/constants/admin_config.dart` lines 13–15 | Must match single allowed project; no env-based config. |

### 2.3 Resolved / Partially Addressed (from prior audits)

- **Audit log writes:** AuditService.log() is called from production (batch/dryer/recipe), inventory, accounts, bookkeeping, auth, HR, hunter, settings. Not every mutation is audited, but the “never written” claim is outdated.
- **completedBy / performedBy:** Addressed with null checks and `'SYSTEM'` fallback in production and dryer repos.
- **butchery_assistant in dropdown:** Present in recipe_form_screen and staff_list_screen dropdowns; AdminConfig includes it.

---

## 3. TODOs (EXHAUSTIVE)

| File | Line / context | TODO text / intent |
|------|----------------|--------------------|
| `lib/core/services/whatsapp_service.dart` | 12 | Move Twilio credentials to secure config |
| `lib/core/services/ocr_service.dart` | 14 | Add Google Cloud Vision API key |

No other in-code TODOs found in `lib/`.

---

## 4. HARDCODED VALUES (EXHAUSTIVE)

### 4.1 Credentials / URLs

| Value | Location | Risk |
|-------|----------|------|
| `https://nasfakcqzmpfcpqttmti.supabase.co` | `admin_config.dart` | Project lock-in; no env switch |
| Supabase anon JWT | `admin_config.dart` | Exposure if repo is public |
| `_apiKey = ''` | `ocr_service.dart` | Feature disabled until set |
| `_accountSid`, `_authToken`, `_fromNumber` = `''` | `whatsapp_service.dart` | Feature disabled until set |

### 4.2 Business constants (acceptable if documented)

| Value | Location | Purpose |
|-------|----------|---------|
| `minimumWagePerHour = 28.79` | `admin_config.dart` | SA minimum wage fallback |
| `28.79` | `production_batch_screen.dart` (2 places), `recipe_form_screen.dart` (2 places) | Labour rate fallback; should use `AdminConfig.minimumWagePerHour` only |
| `pinLength = 4`, `maxPinAttempts = 5`, `pinLockoutMinutes = 15` | `admin_config.dart` | PIN policy |
| `minPasswordLength = 4` | `app_constants.dart` | PIN validation |
| `'SYSTEM'` | Multiple repos | Fallback performer when staff ID missing |

### 4.3 Magic numbers in logic

- Production/dryer: batch number prefixes, limits (e.g. PLU 1000–9999 in product_list_screen), cost decimals.
- Report/analytics: date ranges, limits (e.g. top 5, 50/100/200 pagination). Recommend extracting to config or constants.

---

## 5. TABLE NAME & SCHEMA CONSISTENCY

### 5.1 Tables used in code (from `.from('...')`)

- **audit_log** — Used in `audit_service.dart`, `audit_repository.dart`, `report_repository.dart`. Migration `036` creates `audit_log`. ✅ Consistent.
- **profiles** — Used in auth (pin_screen, auth_service for cache key), user_management_screen, account_list_screen, permission_service. Migrations reference `profiles` in FKs. ✅ Exists in schema.
- **staff_profiles** — Used for login, staff list, timecards, leave, payroll, compliance, dashboard, production labour rate. Migration `041` alters `staff_profiles`. ✅ Exists in schema.
- **recipes** — Column used in customer_repository: `.order('title')` ❌ — table has `name`, not `title`.
- **dryer_batches** — Code and model support both `input_weight_kg`/`output_weight_kg` and `weight_in`/`weight_out` (pulled_schema has weight_in/weight_out). production_batch_repository deleteBatch uses weight_in/weight_out. ✅ Compatible.

### 5.2 Potential mismatches

- **Identity:** If the deployed DB has only `profiles` (and no `staff_profiles`), all auth and staff_profiles-based screens fail. If only `staff_profiles` exists, profile inserts in user_management_screen fail. Clarify which table(s) are the source of truth and align code.
- **customer_repository.getRecipes()** — Fix `.order('title')` to `.order('name')` (or correct column name per actual schema).

---

## 6. EMPTY CREDENTIALS / NON-FUNCTIONAL FEATURES

| Feature | Service / file | Status |
|---------|----------------|--------|
| Google Cloud Vision OCR | `ocr_service.dart` | Non-functional — `_apiKey` empty; throws “OCR not configured” |
| Twilio WhatsApp | `whatsapp_service.dart` | Non-functional — empty SID/token/number; “WhatsApp service not configured” |
| Audit log writes | `AuditService` | Functional — used in production, inventory, accounts, bookkeeping, auth, HR, hunter, settings |
| Supabase | `SupabaseService` + `admin_config` | Functional — URL and anon key set |

---

## 7. INCOMPLETE FEATURES / MISSING IMPLEMENTATIONS

- **Isar:** Declared in pubspec; no models or usage; offline auth uses JSON file.
- **Report scheduling:** Models (e.g. ReportSchedule) exist; no UI or automation for scheduled reports or email delivery.
- **Custom report builder:** Report hub has predefined reports only.
- **SMS / Email campaigns:** Only WhatsApp (and url_launcher) referenced; no SMS or email campaign implementation.
- **VAT submission:** VAT report exists; no automated submission flow.
- **Payroll → ledger posting:** No automated posting of payroll to ledger.
- **Breakdown history tab:** Production has pending breakdowns; no dedicated history view.
- **Owner-only gate for financial KPIs:** Dashboard does not restrict financial KPIs by role.
- **User management:** User management screen exists (profiles, roles, permissions); verify all create/deactivate flows and that they match intended RBAC.

---

## 8. CODE QUALITY ISSUES

### 8.1 Empty or silent catch blocks

Swallowing errors with `catch (_) {}` or `catch (e) {}` with no log or user feedback in:

- `account_list_screen.dart` (2), `account_detail_screen.dart` (5)
- `production_batch_screen.dart` (6), `recipe_form_screen.dart` (2)
- `stock_movements_screen.dart`, `job_summary_screen.dart` (2), `job_intake_screen.dart` (3), `job_list_screen.dart`
- `staff_credit_screen.dart`, `staff_list_screen.dart`, `compliance_screen.dart`
- `utilities_settings_screen.dart`, `announcement_screen.dart`, `audit_log_screen.dart`
- `staff_credit_repository.dart`, `awol_repository.dart`, `analytics_repository.dart` (4)
- `equipment_register_screen.dart` (4), `product_list_screen.dart` (3), `pty_conversion_screen.dart` (2)
- `ledger_screen.dart`, `export_service.dart`, `invoice_repository.dart`
- `waste_log_screen.dart`, `stock_take_screen.dart`, `dashboard_screen.dart`
- `customer_repository.dart`, `promotion_form_screen.dart`, `production_batch_repository.dart`

**Recommendation:** At least log with `debugPrint` or a logger; for user-facing actions, show a SnackBar or error message.

### 8.2 debugPrint / print usage

- Multiple files use `debugPrint` or `print` for diagnostics (e.g. auth_service, dashboard_screen, audit_service, ocr_service, whatsapp_service). Acceptable for debug; ensure no sensitive data and consider a proper logger for production.

### 8.3 Duplicate / overlapping logic

- **Recipe delete:** Two implementations — full cascade in `recipe_repository.deleteRecipe()` vs simple delete in `customer_repository.deleteRecipe()`. Recipe library (customers) should either call production’s recipe_repository or document why a separate, weaker delete is correct.
- **Labour rate fallback 28.79:** Repeated in production_batch_screen; should use `AdminConfig.minimumWagePerHour` everywhere.

### 8.4 Very large files

- `production_batch_screen.dart` (~2065 lines), `product_list_screen.dart` (~3000+), `account_list_screen.dart` (~1900+), `staff_list_screen.dart` (~2300+). Consider splitting into smaller widgets or feature modules.

---

## 9. FEATURE MODULE SUMMARY (CONDENSED)

| Module | Status | Notable issues |
|--------|--------|----------------|
| Auth | ✅ Works | SHA-256 PIN; Isar unused; profiles/staff_profiles usage |
| Dashboard | ✅ | staff_profiles; owner-only KPI gate missing |
| Inventory | ✅ | Large product_list_screen; PLU logic present |
| Production | ✅ | Batch/dryer/recipe logic and audit in place |
| Promotions | ✅ | — |
| Hunter | ✅ | — |
| HR | ✅ | staff_profiles; butchery_assistant in dropdown (present) |
| Accounts | ✅ | profiles + staff_profiles |
| Bookkeeping | ✅ | OCR key empty; audit used |
| Analytics | ✅ | — |
| Reports | ✅ | No scheduling/automation |
| Customers | ⚠️ | recipes.order('title'); deleteRecipe no cascade; WhatsApp empty |
| Audit | ✅ | Reads audit_log; writes from other modules |
| Settings | ✅ | — |

---

## 10. RECOMMENDATIONS (PRIORITIZED)

### P0 (Fix soon)

1. **customer_repository:** Change `getRecipes()` to `.order('name')` (or correct column) and remove or align `deleteRecipe()` with production’s cascade behaviour.
2. **Credentials:** Move Supabase URL/anon key, Twilio, and Google Vision API key to environment or secure config; never commit secrets.
3. **Identity:** Confirm whether `profiles`, `staff_profiles`, or both are in use in production DB and align all code paths.

### P1 (Important)

4. Replace empty/silent catch blocks with logging and, where appropriate, user-visible error handling.
5. Unify labour rate fallback to `AdminConfig.minimumWagePerHour` only.
6. Document or fix dual recipe delete (customer vs production) and ensure Recipe Library does not leave orphaned or inconsistent data.

### P2 (Improvement)

7. Consider bcrypt (or equivalent) for PIN hashing per spec.
8. Remove or implement Isar for offline auth.
9. Split very large screens into smaller widgets/files.
10. Add audit logging for any remaining high-value mutations that do not yet call AuditService.log().

---

## 11. FILES CHANGED SINCE 26 FEB (CONTEXT)

- **recipe_repository.dart** — deleteRecipe() hard delete with cascade and recipe_id nulling on dryer_batches/production_batches.
- **production_batch_repository.dart** — deleteBatch() with full stock reversal; editBatch() with stock-adjusted edits.
- **production_batch_screen.dart** — Edit/Delete batch actions; _EditBatchScreen; substring/length guards for recipeId/ingredientId display.
- **27_Feb_Audit.md** — This audit (replaces 26_Feb_Audit for the 27 Feb run).

---

**End of 27 February 2026 Audit**
