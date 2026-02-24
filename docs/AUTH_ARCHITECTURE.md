# Auth architecture (Admin App)

**Single identity source:** `staff_profiles` (id, full_name, role, is_active, pin_hash).  
Do **not** use `profiles` for authentication or current user identity in this app.

## Flow

1. **PIN login (PinScreen)**  
   Online: query `staff_profiles` by `pin_hash`, `is_active = true`, role in allowed list.  
   Offline: validate PIN against local cache (file), then call `AuthService().setSession(id, full_name, role)` and navigate to MainShell.

2. **Session restore (startup)**  
   `AuthService().restoreSessionFromCache()` reads SharedPreferences, validates against `staff_profiles` (exists, is_active, role allowed), sets in-memory session. PinScreen navigates to MainShell if valid.

3. **Audit / created_by / recorded_by**  
   All modules use `AuthService().getCurrentStaffId()` or `AuthService().currentStaffId` for completedBy, recorded_by, created_by. No direct Supabase Auth or profiles for identity.

## Accessing session

- **Singleton:** `AuthService()` (same instance everywhere).
- **With context:** `SessionScope.auth(context)` or `SessionScope.of(context)?.authService` (wraps MaterialApp in app.dart).

## PIN hash

- **Algorithm:** SHA-256 of raw PIN (unsalted), matching PinScreen and staff_profiles form in HR.  
- Stored in `staff_profiles.pin_hash`; same hash used for online and cached offline validation.

## Out of scope (unchanged)

- **profiles:** Still used where schema requires it (e.g. payroll_entries FK, export_service). Not used for auth or current user.
- **Supabase Auth:** Not used for PIN login; optional fallback in account_list_screen for staff id when AuthService has no session (edge case).
- **Direct Supabase in screens:** Existing screens that call SupabaseService.client directly are unchanged; identity for audit fields comes from AuthService.
