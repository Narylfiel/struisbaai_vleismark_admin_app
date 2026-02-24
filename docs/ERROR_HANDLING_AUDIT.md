# Error handling audit — Supabase calls in lib/**/*.dart

## 1. Are errors being caught and swallowed?

**Yes.** Many catch blocks either do nothing, only setState/return a fallback (e.g. `return []`), or only `debugPrint` without any user-visible feedback.

---

## 2. Catch blocks with NO SnackBar, dialog, or print/log (swallowed or silent fallback)

These are places where a catch block does **not** show a SnackBar, showDialog, or print/debugPrint.  
(Included: `catch (_) {}`, `catch (_) { setState(...); }`, `catch (_) { return []; }` etc. with no user message.)

| File | Line | What the catch does |
|------|------|---------------------|
| **export_service.dart** | 122 | `catch (_) {}` — inner PDF image load |
| **product_list_screen.dart** | 622 | `catch (_)` — setState empty list for product suppliers; no message |
| **product_list_screen.dart** | 631 | `catch (_) {}` — _loadSuppliers |
| **product_list_screen.dart** | 638 | `catch (_) {}` — _loadModifierGroups |
| **product_list_screen.dart** | 645 | `catch (_) {}` — _loadRecipes |
| **report_repository.dart** | 371, 401, 431, 451, 464, 484 | `catch (_)` or `catch (e)` — return `[]`; no user feedback |
| **report_repository.dart** | 504, 517, 531, 545, 557, 572 | same — return `[]` |
| **tax_settings_screen.dart** | 64 | `catch (_)` — setState loading false; no SnackBar |
| **audit_log_screen.dart** | 201 | `catch (_) {}` — date parse in row builder |
| **report_definition.dart** | 57 | `catch (_)` — return null; no feedback |
| **staff_credit_repository.dart** | 31 | `catch (_) {}` — getCredits fallback |
| **settings_repository.dart** | 44, 117, 141, 164 | `catch (_)` — return `{}` or `[]`; no user feedback |
| **stock_take_screen.dart** | 78, 126, 138, 178, 200 | `catch (_)` — return null or setState; no SnackBar |
| **pty_conversion_screen.dart** | 69 | `catch (_)` — setState loading false; no SnackBar |
| **stock_movement_dialogs.dart** | 372, 1175 | `catch (_)` — setState only; no SnackBar |
| **job_process_screen.dart** | 83 | `catch (_)` — setState loading false; no SnackBar |
| **account_detail_screen.dart** | 63, 71, 235, 438, 556, 659 | `catch (_)` — load fallbacks / setState; no SnackBar |
| **account_detail_screen.dart** | 328 | inner `catch (_) {}` — ledger write failure; outer catch shows SnackBar for main flow |
| **dashboard_screen.dart** | 127 | `catch (_) {}` — shrinkage alerts fallback |
| **customer_repository.dart** | 102 | `catch (_) {}` — updateAnnouncementReadStatus |
| **compliance_service.dart** | 220, 293, 408, 429 | `catch (_)` — optional compliance items / return {}; no user message |
| **recipe_form_screen.dart** | 75, 84, 201 | `catch (_)` — load/loadOutputProducts; no SnackBar |
| **announcement_screen.dart** | 176 | `catch (_) {}` — storage upload; insert continues; outer catch has SnackBar |
| **equipment_register_screen.dart** | 40, 203 | `catch (_)` — load / fetch item; no SnackBar |
| **staff_list_screen.dart** | 1454, 1669 | `catch (_) {}` — load fallbacks |
| **production_batch_screen.dart** | 449 | `catch (_) {}` — optional load |
| **job_intake_screen.dart** | 62, 80, 89 | `catch (_)` — load / species fetch; no SnackBar |
| **recipe_library_screen.dart** | 207 | `catch (_)` — setState loading false; no SnackBar |
| **invoice_repository.dart** | 67 | `catch (_) {}` — nextInvoiceNumber |
| **awol_repository.dart** | 32 | `catch (_) {}` — getRecords fallback |
| **job_summary_screen.dart** | 36 | `catch (_) {}` — load paid state |
| **staff_credit_screen.dart** | 40 | `catch (_) {}` — load |
| **pin_screen.dart** | 62, 130, 194 | `catch (_)` — cache / auth; sets offline state |
| **ledger_screen.dart** | 280 | `catch (_) {}` — export path; then SnackBar for success path |
| **shrinkage_screen.dart** | 637, 704 | `catch (_)` — setState loading false; no SnackBar |
| **scale_settings_screen.dart** | 56 | `catch (_)` — setState loading false; no SnackBar |
| **compliance_screen.dart** | 70, 89 | `catch (_) {}` / return null — load |
| **analytics_repository.dart** | 33, 47, 63, 94, 125, 205, 218, 258, 271, 275, 302, 335 | `catch (_)` — return [] or {} or fallback; no user feedback |
| **audit_repository.dart** | 59, 82 | `catch (e)` / `catch (_)` — return [] or ['All']; no user feedback |
| **supplier_list_screen.dart** | 119 | `catch (_)` — but has SnackBar "Could not read file" ✓ |
| **invoice_list_screen.dart** | 208 | inner `catch (_)` — per-row error, adds to errors list (user sees errors) ✓ |

**Catch blocks that DO provide feedback** (for contrast):  
SnackBar/dialog/print: e.g. product_list_screen 757, 1186, 2031; staff_list_screen 2119; chart_of_accounts_screen; job_summary_screen 48, 135; settings_repository 98 (debugPrint + rethrow); equipment_register_screen 102 (debugPrint + rethrow); analytics_repository 289 (debugPrint + rethrow); category_bloc (emit CategoryError — UI can show).

---

## 3. .insert( / .update( calls NOT inside try/catch (in same method)

These methods perform Supabase `.insert()` or `.update()` and do **not** wrap them in try/catch in that method. Callers may still wrap; errors propagate.

| File | Line(s) | Table / operation |
|------|---------|-------------------|
| **ledger_repository.dart** | 45 | ledger_entries.insert — no try/catch |
| **invoice_repository.dart** | 116, 134, 207, 225, 241, 252, 292 | invoices / invoice_line_items insert/update — no try/catch |
| **recipe_repository.dart** | 41, 53, 93, 105 | recipes / recipe_ingredients insert/update |
| **modifier_repository.dart** | 44, 56, 98, 110 | modifier_groups / modifier_items insert/update |
| **stock_take_repository.dart** | 61, 74, 110, 132, 158 | stock_take_sessions / stock_take_entries insert/update |
| **settings_repository.dart** | 125, 127, 147, 170 | scale_config insert/update, tax_rules insert, system_config update — updateBusinessSettings has try/rethrow |
| **production_batch_repository.dart** | 91, 98, 121, 153, 187, 216, 226 | production_batches / ingredients / outputs insert/update |
| **dryer_batch_repository.dart** | 99, 106, 179, 194 | dryer_batches / dryer_batch_ingredients insert/update |
| **inventory_repository.dart** | 53, 94, 105, 111, 118, 123, 167, 173 | inventory_items insert/update |
| **analytics_repository.dart** | 284, 40, 100 | event_tags insert; shrinkage_alerts / supplier_price_changes update (40, 100 no try) |
| **customer_repository.dart** | 67 | announcements.insert — no try in repo |
| **awol_repository.dart** | 71, 78 | staff_awol_records insert/update |
| **staff_credit_repository.dart** | 77, 87 | staff_credit insert/update |

UI/screen code that **does** wrap in try/catch (insert/update inside try):  
account_list_screen, account_detail_screen, staff_list_screen, chart_of_accounts_screen, equipment_register_screen, job_intake_screen, job_list_screen, shrinkage_screen, announcement_screen, product_list_screen, etc. — most screens that call Supabase directly use try/catch and show SnackBar on error.

---

## 4. Global error handler / SupabaseService

- **main.dart:** No `runZonedGuarded`, `FlutterError.onError`, or custom error widget. Just `SupabaseService.initialize()` and `runApp(const AdminApp())`.
- **SupabaseService** (`lib/core/services/supabase_service.dart`):  
  - Exposes `Supabase.instance.client` and `initialize()`.  
  - Does **not** wrap Supabase calls in try/catch.  
  - Provides `parseError(dynamic error)` helper only; no global handling.  
- **No** app-wide zone or error callback that catches uncaught Supabase (or other) exceptions.

---

## Summary

1. **Swallowed / silent:** Many catch blocks return fallbacks (`[]`, `{}`, null) or only setState with no SnackBar/dialog/print. Repositories and load helpers are the main offenders; screens that perform user-triggered writes usually show SnackBar on error.
2. **.insert/.update without try/catch:** All repository methods that do insert/update are untried in the repo; callers (screens) often wrap and show SnackBar. Exceptions from repo methods propagate to the UI if the caller doesn’t catch.
3. **No global error handler** and **SupabaseService does not wrap** Supabase calls in try/catch. Errors are handled (or not) at each call site.

Recommendation: For user-visible flows, ensure every Supabase write path is inside try/catch and shows SnackBar (or dialog) on failure. For read fallbacks, consider at least debugPrint so failures are visible in logs.
