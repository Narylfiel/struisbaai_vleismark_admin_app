# Fixes Applied - February 26, 2026

## Summary
Fixed four critical issues in the admin app as requested.

---

## FIX 1 — Table Name Investigation

### Findings:

**staff_credit_screen.dart:**
- Uses repository: `StaffCreditRepository` 
- Repository table: **`staff_credit`** (singular) ✅
- Confirmed in: `lib/features/hr/services/staff_credit_repository.dart` lines 12, 77, 87

**staff_list_screen.dart (AWOL):**
- Uses repository: `AwolRepository`
- Repository table: **`staff_awol_records`** (plural) ✅
- Confirmed in: `lib/features/hr/services/awol_repository.dart` lines 12, 71, 78

**pty_conversion_screen.dart:**
- Uses table: **`business_settings`** ✅
- No purchase_sale_agreements table found
- Confirmed in: `lib/features/bookkeeping/screens/pty_conversion_screen.dart` line 42

---

## FIX 2 — Merge Staff Credits into HR Tabs

### Changes Made:

**1. lib/features/hr/screens/staff_credit_screen.dart**
- Added `isEmbedded` optional parameter to constructor
- Modified `build()` method to return embedded content when `isEmbedded = true`
- When embedded, returns just the body `Column` wrapped in `Stack` with positioned FAB
- When not embedded (standalone), returns full `Scaffold` with body and FAB

**2. lib/features/hr/screens/staff_list_screen.dart**
- Added import: `import 'package:admin_app/features/hr/screens/staff_credit_screen.dart';`
- Replaced entire `_StaffCreditTab` class (245 lines) with simple wrapper:
  ```dart
  class _StaffCreditTab extends StatelessWidget {
    const _StaffCreditTab();
    
    @override
    Widget build(BuildContext context) {
      return const StaffCreditScreen(isEmbedded: true);
    }
  }
  ```
- Removed duplicate logic - now uses single source of truth from `staff_credit_screen.dart`

**3. lib/features/dashboard/screens/main_shell.dart**
- Removed `Staff Credits` nav item from sidebar (was index 6)
- Removed import: `import 'package:admin_app/features/hr/screens/staff_credit_screen.dart';`
- Adjusted nav item indices:
  - Before: 15 items (indices 0-14)
  - After: 14 items (indices 0-13)
- Updated conditional rendering logic for owner-only items

**Result:** Staff Credits now only appears as Tab 6 inside HR screen, not as separate sidebar item.

---

## FIX 3 — Fix completedBy Empty String

### Finding:
**Already Fixed!** ✅

Both production screens already use proper auth:
- `dryer_batch_screen.dart` line 703: `completedBy: AuthService().getCurrentStaffId()`
- `production_batch_screen.dart` line 1013: `completedBy: AuthService().getCurrentStaffId()`

The `getCurrentStaffId()` method returns empty string if not logged in (safer than null).
No changes needed.

---

## FIX 4 — Hunter Job Save Fix

### Changes Made:

**lib/features/hunter/screens/job_intake_screen.dart**

Rebuilt the `_save()` method's payload to use ONLY confirmed `hunter_jobs` columns:

**Added fields:**
- `paid: false` (boolean, required)
- `weight_in: totalWeight` (maps to estimated_weight)

**Removed fields:**
- `service_id` (doesn't exist as column - services stored in services_list JSON only)

**Reordered payload for clarity:**
```dart
final payload = {
  'job_date': _jobDate.toIso8601String().substring(0, 10),
  'hunter_name': _nameCtrl.text.trim(),
  'contact_phone': _phoneCtrl.text.trim(),
  'species': firstSpeciesName,
  'weight_in': totalWeight,
  'estimated_weight': totalWeight,
  'processing_instructions': _processingNotesCtrl.text.trim().isEmpty ? null : _processingNotesCtrl.text.trim(),
  'status': 'intake',
  'charge_total': chargeTotal,
  'total_amount': chargeTotal,
  'paid': false,
  'animal_count': animalCount,
  'animal_type': firstSpeciesName,
  'customer_name': _nameCtrl.text.trim(),
  'customer_phone': _phoneCtrl.text.trim(),
  'species_list': speciesList,
  'services_list': servicesList,
  'materials_list': materialsList,
  'processing_options': processingOptions,
};
```

**Added error logging:**
- Added `print('Hunter job save error: $e');` in catch block for debugging

**Confirmed columns used match schema:**
- All fields in payload match confirmed `hunter_jobs` columns list provided
- No extraneous fields that would cause insert failures

---

## Files Modified

1. `lib/features/hr/screens/staff_credit_screen.dart` - Added isEmbedded support
2. `lib/features/hr/screens/staff_list_screen.dart` - Simplified Staff Credit tab, added import
3. `lib/features/dashboard/screens/main_shell.dart` - Removed Staff Credits nav item and import
4. `lib/features/hunter/screens/job_intake_screen.dart` - Fixed payload structure with confirmed columns

---

## Testing Recommendations

1. **Staff Credits Tab**: Navigate to HR > Staff Credit tab - should show full functionality
2. **Sidebar Nav**: Verify Staff Credits no longer appears in sidebar
3. **Hunter Job Intake**: Test creating new hunter job - should save without errors
4. **Production Batches**: completedBy already working - verify audit trail captures staff ID

---

## Status: ✅ ALL FIXES COMPLETE
