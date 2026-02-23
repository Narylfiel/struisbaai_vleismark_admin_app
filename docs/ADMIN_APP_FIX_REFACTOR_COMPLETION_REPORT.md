# Admin App Fix Refactor — Completion Report

**Project:** Struisbaai Vleismark Admin App  
**Report date:** 2025-02-22  
**Scope:** Business Settings persistence, AuthService session population, Staff Credit / AWOL fix

---

## 1. Executive Summary

All Phase 1 deliverables from the Admin App Fix Refactor Plan have been implemented. Business Settings now persist correctly to Supabase using the key-value `business_settings` schema. AuthService is populated via `setSession()` on PIN login, and the optional Phase 2 session restore with Supabase validation has been implemented. Staff Credit and AWOL screens will display correct staff names instead of "Sign in with PIN" when a valid session exists.

---

## 2. Implemented Deliverables

### 2.1 Business Settings (Phase 1)

| Item | Status | Location |
|------|--------|----------|
| Key-value `getBusinessSettings()` | ✅ | `admin_app/lib/features/settings/services/settings_repository.dart` |
| Per-key `updateBusinessSettings()` with `onConflict: 'setting_key'` | ✅ | Same |
| JSONB validation (skip null/empty string) | ✅ | Same |
| Business tab `_load()` with `data['business_name']?.toString()` etc. | ✅ | `admin_app/lib/features/settings/screens/business_settings_screen.dart` |
| `_save()` with try/catch, success/error SnackBars, `mounted` guards | ✅ | Same |

### 2.2 AuthService Session (Phase 1)

| Item | Status | Location |
|------|--------|----------|
| `setSession(staffId, staffName, role)` | ✅ | `admin_app/lib/core/services/auth_service.dart` |
| `_persistSession()` to SharedPreferences (`_activeSessionKey`) | ✅ | Same |
| PinScreen calls `AuthService().setSession()` before MainShell navigation | ✅ | `admin_app/lib/features/auth/screens/pin_screen.dart` |

### 2.3 Session Restore (Phase 2 – Optional)

| Item | Status | Location |
|------|--------|----------|
| `restoreSessionFromCache()` with Supabase validation | ✅ | `auth_service.dart` |
| Validation: `staff_profiles` id, role, is_active, allowed roles | ✅ | Same |
| PinScreen `_tryRestoreSession()` on initState | ✅ | `pin_screen.dart` |
| Auto-navigation to MainShell if valid cached session | ✅ | Same |

---

## 3. Technical Details

### 3.1 Business Settings Schema Alignment

- **Schema:** `business_settings(setting_key TEXT PRIMARY KEY, setting_value JSONB)`
- **Keys used:** `business_name`, `address`, `vat_number`, `phone`, `bcea_start_time`, `bcea_end_time`
- **Load:** Select all rows, build map by `setting_key` → `setting_value`
- **Save:** Per-key upsert with `onConflict: 'setting_key'`; null and empty string values are skipped

### 3.2 Session Persistence

- **Storage:** SharedPreferences under key `active_session`
- **Format:** `{ id, name, role }` as JSON
- **Restore validation:** Query `staff_profiles` for `id, full_name, role, is_active`; if no row or `is_active != true` or role not in `AdminConfig.allowedRoles`, session is cleared

### 3.3 Rules Compliance

- Supabase initialized only in `SupabaseService.initialize()` — not in main.dart, blocs, or repositories
- Single Supabase project enforced per user rules
- OAuth redirect: `io.supabase.flutter://login-callback`

---

## 4. Verification

| Check | Result |
|-------|--------|
| Flutter build (Windows) | ✅ `flutter run -d windows` succeeded |
| Supabase init on startup | ✅ Logged "Supabase init completed" |
| No duplicate Supabase.initialize() | ✅ |

---

## 5. Manual Testing Checklist (Recommended)

- [ ] Open Settings → Business tab; edit business name, address; Save → verify SnackBar success
- [ ] Restart app; verify Business tab shows persisted values
- [ ] PIN login as Owner/Manager → Staff Credit / AWOL screens show correct staff names
- [ ] Cold restart with cached session → app restores to MainShell without re-entering PIN (when online)
- [ ] Offline: cached session invalidated; user must re-enter PIN

---

## 6. Not Implemented (Optional)

- Bulk upsert for business settings (current per-key upsert is sufficient)
- Session restore when fully offline (requires trusting cache without Supabase; deemed unsafe per plan)

---

## 7. Files Modified

- `admin_app/lib/features/settings/services/settings_repository.dart` — key-value get/update
- `admin_app/lib/features/settings/screens/business_settings_screen.dart` — _load/_save with guards
- `admin_app/lib/core/services/auth_service.dart` — setSession, _persistSession, restoreSessionFromCache
- `admin_app/lib/features/auth/screens/pin_screen.dart` — setSession call, _tryRestoreSession

---

## 8. Sign-off

Phase 1 and optional Phase 2 deliverables are complete. The app builds and runs on Windows. Manual testing of Business Settings persistence and Staff Credit/AWOL display is recommended before production deployment.
