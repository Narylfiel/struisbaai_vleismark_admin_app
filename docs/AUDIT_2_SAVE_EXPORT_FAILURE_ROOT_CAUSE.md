# AUDIT 2 — Save & Export Failure Root Cause Analysis

**Date:** 22 February 2026  
**Type:** READ-ONLY diagnostic. No files changed.

---

## DIAGNOSTIC 1 — SETTINGS AND FORMS NOT SAVING ON WINDOWS

### STEP 1: Settings screens and Save handlers

| Screen | File | Save button onPressed |
|--------|------|------------------------|
| Business Info | `business_settings_screen.dart` | Line 155: `ElevatedButton(onPressed: _save, ...)` |
| Tax | `tax_settings_screen.dart` | Line 167: `onPressed: _saving ? null : _save` |
| Scale | `scale_settings_screen.dart` | Line 184: `onPressed: _saving ? null : _save` |
| Notifications | `notification_settings_screen.dart` | Line 232: `onPressed: _saving ? null : _save` |

### STEP 2: Trace save call chain

#### Business Info (_BusinessTab)

- **onPressed:** `_save` (line 111–125)
- **Call chain:** `_save()` → `await _repo.updateBusinessSettings({...})` → `SettingsRepository.updateBusinessSettings`
- **Repository:** `settings_repository.dart` lines 29–36:
  - `getBusinessSettings()` returns `select().limit(1).maybeSingle()` — one row
  - `updateBusinessSettings(data)`: if `existing.isEmpty` → `insert(data)`; else → `update(data).eq('id', existing['id'])`
  - Data passed: `{business_name, address, vat_number, phone, bcea_start_time, bcea_end_time}`

| Question | Answer |
|----------|--------|
| a) Await on Supabase call? | YES |
| b) Result checked / try-catch? | NO — no try/catch in `_save` or `updateBusinessSettings` |
| c) setState after save? | YES (inside success path) |
| d) Success SnackBar before or after await? | AFTER await |
| e) Condition that prevents save? | NO — but schema mismatch causes write to fail |

**Verdict:** WILL FAIL — schema mismatch (see Step 3).

---

#### Tax Settings

- **onPressed:** `_save` (lines 74–99)
- **Call chain:** `_save()` → `await _client.from('business_settings').upsert(..., onConflict: 'setting_key')` in loop
- **Data:** `{setting_key, setting_value}` per row

| Question | Answer |
|----------|--------|
| a) Await? | YES |
| b) Error caught? | YES (try/catch, shows error SnackBar) |
| c) setState after save? | YES |
| d) Success before await? | NO |
| e) Silent prevention? | NO |

**Verdict:** WILL SAVE.

---

#### Scale Settings

- Same pattern as Tax: upsert with `setting_key`/`setting_value`, try/catch, success after await.  
**Verdict:** WILL SAVE.

---

#### Notification Settings

- Same pattern: upsert key-value, try/catch, success after await.  
**Verdict:** WILL SAVE.

---

### STEP 3: business_settings table structure

**Migration:** `001_admin_app_tables_part1.sql` lines 17–25

```sql
CREATE TABLE IF NOT EXISTS business_settings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  setting_key TEXT UNIQUE NOT NULL,
  setting_value JSONB,
  description TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_by UUID REFERENCES profiles(id)
);
```

**Schema:** Key-value. Columns: `id`, `setting_key`, `setting_value`, `description`, `updated_at`, `updated_by`.  
No columns: `business_name`, `address`, `vat_number`, `phone`, `bcea_start_time`, `bcea_end_time`.

**Business tab mismatch:**
- `updateBusinessSettings` passes `{business_name, address, ...}` to `.update()` or `.insert()`.
- Table has no such columns → Postgres error: column does not exist.
- Tax/Scale/Notification use `upsert(..., onConflict: 'setting_key')` with `setting_key`/`setting_value` → correct.

**Fix (plain English):** Change Business tab to use the same key-value pattern as Tax/Scale/Notification: load all rows, build a map from `setting_key`→`setting_value`, and save each field as a separate row via `upsert(..., onConflict: 'setting_key')`.

---

### STEP 4: Windows-specific checks

- No `path_provider`, local file storage, or SharedPreferences used in settings save flow.
- All settings writes go to Supabase.
- No local storage instead of Supabase for settings.

---

### STEP 5: Other forms — same trace

| Form | File | Save handler | Supabase write | Awaited | Error caught | Null guard prevents save |
|------|------|--------------|----------------|---------|--------------|--------------------------|
| Staff form | `staff_list_screen.dart` _StaffFormDialog | `_save` line 2071 | staff_profiles insert/update | YES | YES | NO |
| Supplier form | `supplier_form_screen.dart` | `_save` line 58 | suppliers via SupplierRepository | YES | YES | NO |
| Hunter job intake | `job_intake_screen.dart` | `_save` line 102 | hunter_jobs insert | YES | YES | NO (species null returns early with SnackBar) |
| Product form | `product_list_screen.dart` _ProductFormDialog | `_save` (in dialog) | inventory_items upsert | YES | YES | NO |

All other forms: Supabase write awaited, errors caught, no silent null guard that blocks the write.

---

### STEP 6: Auth state during save

- Staff form: does not use `currentStaffId` for save.
- Supplier form: no auth dependency.
- Hunter job intake: no auth dependency.
- Product form: no auth dependency.
- Staff Credit and AWOL: use `AuthService().currentStaffId` — see Diagnostic 3.

---

### REPORT FORMAT — Diagnostic 1 (per screen)

| Screen | Save handler | Supabase call | Awaited | Error caught | Null guard | Success before await | Verdict |
|--------|--------------|---------------|---------|--------------|------------|---------------------|---------|
| Business Info | YES | business_settings update/insert | YES | NO | NO | NO | **WILL FAIL** — schema mismatch |
| Tax | YES | business_settings upsert | YES | YES | NO | NO | WILL SAVE |
| Scale | YES | business_settings upsert | YES | YES | NO | NO | WILL SAVE |
| Notifications | YES | business_settings upsert | YES | YES | NO | NO | WILL SAVE |
| Staff form | YES | staff_profiles | YES | YES | NO | NO | WILL SAVE |
| Supplier form | YES | suppliers | YES | YES | NO | NO | WILL SAVE |
| Hunter intake | YES | hunter_jobs | YES | YES | NO | NO | WILL SAVE |
| Product form | YES | inventory_items | YES | YES | NO | NO | WILL SAVE |

---

## DIAGNOSTIC 2 — REPORTS EXPORT PRODUCES NO FILE

### STEP 1: ExportService location and methods

**File:** `lib/core/services/export_service.dart`

**Methods:** `exportToCsv`, `exportToExcel`, `exportToPdf`, `exportInventory`, `exportSales`, `exportPayroll`, `shareFile`, `_getExportFile`

### STEP 2: Trace each export method

#### exportToCsv (lines 19–51)

| Question | Answer |
|----------|--------|
| a) File path source | `_getExportFile(fileName, 'csv')` → `getApplicationDocumentsDirectory()` (line 324) |
| b) Directory created before write? | NO — `getApplicationDocumentsDirectory()` returns existing dir; no `Directory.create()` |
| c) Write awaited? | YES — `await file.writeAsString(csvString)` line 45 |
| d) Return value used? | Returns `File` object |
| e) open_file called after? | NO — no `OpenFile.open()` in codebase |

#### exportToExcel (lines 54–95)

| Question | Answer |
|----------|--------|
| a) Package | `excel` package; `excel.encode()!` line 89 |
| b) encode() before write? | YES |
| c) Path | Same `_getExportFile` → `getApplicationDocumentsDirectory()` |
| d) Write awaited? | YES — `await file.writeAsBytes(excel.encode()!)` |
| e) Return | `File` object |

#### exportToPdf (lines 99–157)

| Question | Answer |
|----------|--------|
| a) Package | `pdf` + `printing`; uses `file.writeAsBytes(await pdf.save())` — no `Printing.layoutPdf` |
| b) Path | Same `_getExportFile` |
| c) Write awaited? | YES |

#### _getExportFile (lines 323–328)

```dart
Future<File> _getExportFile(String fileName, String extension) async {
  final directory = await getApplicationDocumentsDirectory();
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final fullFileName = '${fileName}_$timestamp.$extension';
  return File('${directory.path}/$fullFileName');
}
```

- Path: `getApplicationDocumentsDirectory()` — on Windows typically `C:\Users\<user>\Documents` or app-specific subdir.
- No `Directory.create()` — directory assumed to exist.
- Returns `File` object; actual write happens in caller.

### STEP 3: Call from report_hub_screen.dart

**File:** `lib/features/reports/screens/report_hub_screen.dart` — `_exportReport` (lines 59–124)

**Flow:**
1. `await _repo.getReportData(...)` — fetch data
2. `file = await _export.exportToCsv/Excel/Pdf(...)` — **awaited**; file written here
3. `await Share.shareXFiles([XFile(file.path)], ...)` — **after** file write
4. Success SnackBar — **after** Share (inside same try, after file write)

**Try/catch:** YES; errors show "Export failed: $e".

**Success SnackBar timing:** AFTER file write and Share. Not before.

### STEP 4: open_file and share_plus

- **open_file:** NOT used. No `OpenFile.open(path)` in codebase.
- **share_plus:** `Share.shareXFiles([XFile(file.path)], ...)` — uses path from `File` object.
- **Path:** Absolute path from `directory.path` + filename.
- **Path separators:** `path_provider` and `dart:io` File handle Windows paths.

### STEP 5: Edge Function

- **supabase/functions/:** Path does not exist. No Edge Function for export.
- Reports use local ExportService only.

### STEP 6: Windows file system

- **path_provider:** `getApplicationDocumentsDirectory()` — standard on Windows.
- **dart:io File:** Used; desktop-compatible.
- **Manifest:** No special Windows file permission found in pubspec.
- **Directory.create():** Not called; relies on Documents dir existing.

### REPORT FORMAT — Diagnostic 2 (per export method)

| Method | File path source | Dir created | Write awaited | Return used | open_file | Success before write | Verdict |
|--------|------------------|-------------|---------------|-------------|-----------|----------------------|---------|
| exportToCsv | getApplicationDocumentsDirectory() | NO | YES | YES | NO | AFTER | WILL CREATE FILE |
| exportToExcel | getApplicationDocumentsDirectory() | NO | YES | YES | NO | AFTER | WILL CREATE FILE |
| exportToPdf | getApplicationDocumentsDirectory() | NO | YES | YES | NO | AFTER | WILL CREATE FILE |

**Conclusion:** Export flow is correct. File is written before success SnackBar. If "no file" is reported, likely causes: (1) User expects file in Downloads but it is in Documents; (2) `path_provider` returning unexpected path on some Windows setups; (3) Share dialog cancel causing confusion; (4) File created but user cannot locate it (SnackBar shows shortPath).

**Fix (plain English):** Add `OpenFile.open(file.path)` after write (with try/catch) so the file opens in the default app. Alternatively, use `getDownloadsDirectory()` if available and document where files are saved. Ensure SnackBar shows full path on Windows.

---

## DIAGNOSTIC 3 — AUTH STATE PROPAGATION (Staff Credit / AWOL login error)

### STEP 1: Auth provider

**File:** `lib/core/services/auth_service.dart`

**Type:** Singleton (`AuthService()`), not Riverpod.

**Exposes:** `currentStaffId`, `currentStaffName`, `currentRole`, `isLoggedIn`

**Population:** `_setCurrentUser()` (private) is called only from:
- `_authenticateOnline()` — when online PIN auth succeeds
- `_authenticateOffline()` — when offline PIN auth succeeds

**Important:** `authenticateWithPin()` is never called by the app’s login flow.

### STEP 2: staff_credit_screen auth

**File:** `lib/features/hr/screens/staff_credit_screen.dart` lines 74–80

```dart
void _openAddEntry() async {
  final userId = AuthService().currentStaffId;
  if (userId == null || userId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign in with PIN to add credit'), backgroundColor: AppColors.warning),
    );
    return;
  }
  // ... rest of dialog and save
}
```

**Auth source:** `AuthService().currentStaffId`

**Condition for "Sign in with PIN":** `userId == null || userId.isEmpty`

**Root cause:** `AuthService.currentStaffId` is never set because the PIN screen does not use AuthService.

### STEP 3: AWOL screen auth

**File:** `lib/features/hr/screens/staff_list_screen.dart` lines 1466–1472

```dart
void _openRecordAwol() async {
  final userId = AuthService().currentStaffId;
  if (userId == null || userId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign in with PIN to record AWOL'), backgroundColor: AppColors.warning),
    );
    return;
  }
  // ...
}
```

Same pattern: `AuthService().currentStaffId` is null → "Sign in with PIN" shown.

### STEP 4: Supabase session vs PIN session

**PIN login flow:** `lib/features/auth/screens/pin_screen.dart`

- Queries `staff_profiles` directly (or `_StaffCache` offline).
- On success: `Navigator.pushReplacement(MaterialPageRoute(builder: (_) => MainShell(staffId: ..., staffName: ..., role: ...)))`
- Does NOT call `AuthService.authenticateWithPin()`.
- Does NOT call any method to set AuthService state.

**MainShell:** Receives `staffId`, `staffName`, `role` but never passes them to AuthService.

**Supabase auth:** App uses PIN login against `profiles`/`staff_profiles`, not `SupabaseService.client.auth`. Supabase auth session is separate and not used for these screens.

**Conclusion:** AuthService is never populated. PIN login succeeds and MainShell is shown with staffId, but AuthService.currentStaffId stays null. Staff Credit and AWOL (and any screen using AuthService) will always see null and show "Sign in with PIN".

**Fix (plain English):** After successful PIN verification in `pin_screen.dart`, before navigating to MainShell, call a new method such as `AuthService().setSession(staffId, staffName, role)` that assigns `_currentStaffId`, `_currentStaffName`, `_currentRole`. Alternatively, have MainShell’s `initState` pass `widget.staffId` into AuthService. AuthService must also restore session from SharedPreferences (`_activeSessionKey`) on app cold start so it survives restarts.

### STEP 5: Timecard editing (I-12)

**File:** `lib/features/hr/screens/staff_list_screen.dart` — `_TimecardsTab`

- **Edit timecard:** No UI. Timecards are displayed read-only. No handler to edit clock_in, clock_out, break_minutes.
- **Add timecard:** No UI. No button or flow to insert a timecard for a day with no entry.
- **Permission check:** N/A — no edit capability.
- **Insert for missing day:** NO.

**Verdict:** Timecards are view-only. Admin cannot edit or add.

---

### REPORT FORMAT — Diagnostic 3

| Item | Value |
|------|-------|
| Auth provider found | `lib/core/services/auth_service.dart` |
| What it exposes | `currentStaffId`, `currentStaffName`, `currentRole`, `isLoggedIn` |
| Staff credit auth source | `AuthService().currentStaffId` |
| Exact condition for login redirect | `userId == null || userId.isEmpty` (line 76) |
| AWOL auth source | `AuthService().currentStaffId` |
| Supabase vs PIN mismatch | **YES (root cause)** — PIN screen never sets AuthService; currentStaffId always null |
| Timecard edit — any staff | NO — no edit UI |
| Timecard insert for missing day | NO |

---

## FINAL SUMMARY — PRIORITY FINDINGS

### 1. Business Settings save fails (CRITICAL)

- **Root cause:** Business tab uses column-based data (`business_name`, `address`, etc.) against a key-value table (`setting_key`, `setting_value`).
- **File:** `lib/features/settings/services/settings_repository.dart` lines 16–36; `lib/features/settings/screens/business_settings_screen.dart` `_BusinessTab` lines 95–125.
- **Fix:** Refactor Business tab to use the same key-value pattern as Tax/Scale/Notification: load all rows, build map from `setting_key`→`setting_value`, save each field as `upsert({setting_key, setting_value}, onConflict: 'setting_key')`. Update `getBusinessSettings` to select all rows and build the map.

### 2. AuthService never populated — Staff Credit / AWOL always "Sign in with PIN" (CRITICAL)

- **Root cause:** PIN screen uses its own auth flow and never calls AuthService. MainShell receives staffId but does not pass it to AuthService. `AuthService.currentStaffId` stays null.
- **File:** `lib/features/auth/screens/pin_screen.dart` (after line 204, before Navigator); `lib/core/services/auth_service.dart` (add `setSession` or equivalent).
- **Fix:** Add `AuthService().setSession(staffId, staffName, role)` (or similar) and call it in `pin_screen.dart` when PIN verification succeeds, before navigating to MainShell. Optionally restore session from SharedPreferences on app startup.

### 3. Export "no file" — flow is correct; UX may be the issue (LOW)

- **Root cause:** Export logic is sound. File is written before success. Likely causes: file in Documents not Downloads, or user cannot find it.
- **File:** `lib/features/reports/screens/report_hub_screen.dart`; `lib/core/services/export_service.dart`.
- **Fix:** After writing the file, call `OpenFile.open(file.path)` (with try/catch) to open it in the default app. Consider `getDownloadsDirectory()` if available. Make the SnackBar show the full absolute path on Windows.

### 4. Timecard edit/add not implemented (MEDIUM)

- **Root cause:** No edit or add UI for timecards.
- **File:** `lib/features/hr/screens/staff_list_screen.dart` — `_TimecardsTab`.
- **Fix:** Add edit dialog (clock_in, clock_out, break_minutes) and add-timecard flow. Ensure admin can edit any staff’s timecard and add entries for missing days.

---

*End of diagnostic report. No code changes were made.*
