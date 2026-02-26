# 🔧 AUTHENTICATION BUG FIXES — 26 February 2026

## CRITICAL BUGS FIXED

### 🔴 BUG 1: Session Restore Using Wrong Table
**File:** `lib/core/services/auth_service.dart`  
**Line:** 216  
**Issue:** `restoreSessionFromCache()` was querying `staff_profiles` table instead of `profiles`  
**Impact:** 
- On app restart, role validation would fail or return incorrect role
- If `staff_profiles.role` differed from `profiles.role`, permissions would be wrong
- Could cause silent authentication failures

**Fix Applied:**
```dart
// BEFORE (WRONG):
.from('staff_profiles')

// AFTER (CORRECT):
.from('profiles')
```

**Rationale:** 
- First login uses `profiles` table ✅
- Session restore MUST use same table for consistency
- `profiles` is the canonical identity source per project rules

---

### 🔴 BUG 2: PermissionService Stale State
**File:** `lib/core/services/permission_service.dart`  
**Line:** 25 (start of `loadPermissions()`)  
**Issue:** Singleton retained stale `_isOwner`, `_effectivePermissions`, `_isLoaded` state across sessions  
**Impact:**
- Hot reload in debug mode could retain previous user's permissions
- App restart might not fully reset permission state
- Non-owner session followed by owner login could retain restricted permissions

**Fix Applied:**
```dart
Future<void> loadPermissions({
  required String role,
  required String staffId,
}) async {
  // Always reset before loading — prevents stale state from previous session
  _effectivePermissions = {};
  _isOwner = false;
  _isLoaded = false;

  try {
    // ... rest of method
```

**Rationale:**
- Singleton persists across hot reloads and app restarts
- Explicit reset ensures clean slate for each login
- Prevents permission leakage between sessions

---

## FILES MODIFIED

1. ✅ `lib/core/services/auth_service.dart`
   - Line 216: Changed `staff_profiles` → `profiles`
   
2. ✅ `lib/core/services/permission_service.dart`
   - Lines 25-27: Added state reset at start of `loadPermissions()`

---

## VERIFICATION STEPS

### ✅ Code Quality Checks
- `flutter clean` — Completed successfully (exit code 0)
- `flutter analyze` — No linter errors in modified files
- Both files compile without errors

### 🧪 Testing Instructions (For User)

**Test 1: Fresh Login**
1. Run: `flutter run -d windows`
2. Log in with owner PIN
3. **Verify:** All sidebar items unlocked (no lock icons)
4. **Verify:** Dashboard shows all widgets (financials, charts, alerts)

**Test 2: Session Restore**
1. Close app (don't log out)
2. Reopen app
3. **Verify:** Session restores automatically
4. **Verify:** Sidebar still shows all items unlocked for owner
5. **Verify:** Permissions still active (can access all modules)

**Test 3: Logout/Login Cycle**
1. Log out
2. Log in again
3. **Verify:** No permission state leakage
4. **Verify:** Sidebar refreshes correctly

**Test 4: Non-Owner User**
1. Log out
2. Log in as non-owner (if available)
3. **Verify:** Sidebar shows locked items based on role
4. **Verify:** Content area shows "Access Restricted" for locked modules

---

## EXPECTED BEHAVIOR AFTER FIX

### ✅ Session Restore
- Uses `profiles` table consistently
- Role loaded correctly from `profiles.role`
- Permissions loaded based on correct role
- No silent failures

### ✅ Permission Service
- State resets on every login
- No stale permissions from previous session
- Hot reload safe
- Owner bypass works correctly

### ✅ Sidebar Navigation
- Owner sees all items unlocked
- Non-owner sees items locked per role permissions
- Lock icons display correctly
- Tapping locked items shows access denied screen

---

## RELATED DOCUMENTATION

- **Permission System:** `DASHBOARD_GATES_COMPLETE_26_FEB.md`
- **User Management:** `USER_MANAGEMENT_COMPLETE_26_FEB.md`
- **Audit Logging:** `26_Feb_Audit.md`

---

## IMPACT ASSESSMENT

### 🔴 Critical Impact (Fixed)
- ✅ Authentication now consistent across login and restore
- ✅ Permissions no longer leak between sessions
- ✅ Owner role properly identified on all auth paths

### 🟢 No Breaking Changes
- ✅ No business logic modified
- ✅ No database schema changes required
- ✅ No UI changes
- ✅ Backwards compatible

---

## NOTES

- These are surgical fixes only
- No other files modified
- Changes align with existing project architecture
- Both bugs were introduced during permission system implementation
- Fixes maintain consistency with `AuthService` doctrine: `profiles` is primary identity source

---

**Status:** ✅ READY FOR TESTING  
**Risk Level:** 🟢 LOW (targeted fixes, well-tested patterns)  
**Regression Risk:** 🟢 MINIMAL (fixes align with existing design)

---

**Next Steps:**
1. User performs manual testing (steps above)
2. If tests pass → merge to main
3. If issues found → report back for additional fixes
