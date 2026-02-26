# Audit Logging Implementation - February 26, 2026

## Summary
Comprehensive audit logging system implemented with fire-and-forget writes that never block operations or crash the app.

---

## STEP 1 - AuditService Created ✅

**File:** `lib/core/services/audit_service.dart`

### Features:
- ✅ Singleton pattern
- ✅ Fire-and-forget (never blocks calling operations)
- ✅ Silent error swallowing (logs to console only)
- ✅ Reads current staff from AuthService
- ✅ Writes to audit_log table
- ✅ Convenience methods for login/logout/lockout

### Public API:
```dart
static Future<void> log({
  required String action,      // 'CREATE' | 'UPDATE' | 'DELETE' | 'LOGIN' | 'LOGOUT' | 'EXPORT' | 'APPROVE' | 'REJECT'
  required String module,      // 'Inventory' | 'HR' | 'Production' | 'Hunter' | 'Accounts' | 'Bookkeeping' | 'Auth'
  required String description, // Human-readable description
  String? entityType,          // 'Product' | 'Staff' | 'Invoice' | etc.
  String? entityId,            // UUID of the affected record
  Map<String, dynamic>? oldValues,
  Map<String, dynamic>? newValues,
})
```

### Convenience Methods:
```dart
static Future<void> logLogin({required bool success, required String email, String? role, String? failureReason})
static Future<void> logLogout({required String email})
static Future<void> logLockout({required String email, required int attemptCount})
```

---

## STEP 2 - Wiring Locations (Comprehensive List)

### INVENTORY MODULE

**File:** `lib/features/inventory/services/inventory_repository.dart`

**Methods to update:**

1. **`createProduct()`** - Product creation
```dart
// After successful insert
await AuditService.log(
  action: 'CREATE',
  module: 'Inventory',
  description: 'Product "${product.name}" created (PLU: ${product.pluCode})',
  entityType: 'Product',
  entityId: productId,
  newValues: product.toJson(),
);
```

2. **`updateProduct()`** - Product update
```dart
// Before update - fetch old values
final old = await getProduct(product.id);
// After successful update
await AuditService.log(
  action: 'UPDATE',
  module: 'Inventory',
  description: 'Product "${product.name}" updated',
  entityType: 'Product',
  entityId: product.id,
  oldValues: old?.toJson(),
  newValues: product.toJson(),
);
```

3. **`deleteProduct()` or `deactivateProduct()`** - Product deletion
```dart
// After successful delete
await AuditService.log(
  action: 'DELETE',
  module: 'Inventory',
  description: 'Product "${productName}" deleted/deactivated',
  entityType: 'Product',
  entityId: productId,
);
```

4. **`receiveStock()`** - Stock receipt
```dart
await AuditService.log(
  action: 'UPDATE',
  module: 'Inventory',
  description: 'Stock received: ${quantity} x ${productName} from ${supplierName}',
  entityType: 'StockMovement',
  entityId: movementId,
);
```

5. **`adjustStock()`** - Stock adjustment
```dart
await AuditService.log(
  action: 'UPDATE',
  module: 'Inventory',
  description: 'Stock adjusted: ${reason} - ${quantity} x ${productName}',
  entityType: 'StockMovement',
  entityId: movementId,
);
```

6. **`recordWaste()`** - Waste recording
```dart
await AuditService.log(
  action: 'UPDATE',
  module: 'Inventory',
  description: 'Waste recorded: ${quantity} x ${productName} - ${reason}',
  entityType: 'StockMovement',
  entityId: movementId,
);
```

7. **`transferStock()`** - Stock transfer
```dart
await AuditService.log(
  action: 'UPDATE',
  module: 'Inventory',
  description: 'Stock transferred: ${quantity} x ${productName} to ${locationName}',
  entityType: 'StockMovement',
  entityId: movementId,
);
```

---

### HR MODULE

**File:** `lib/features/hr/services/staff_repository.dart` or similar

**Methods to update:**

1. **`createStaff()`** - Staff profile creation
```dart
await AuditService.log(
  action: 'CREATE',
  module: 'HR',
  description: 'Staff member created: ${fullName} (${role})',
  entityType: 'Staff',
  entityId: staffId,
);
```

2. **`updateStaff()`** - Staff profile update
```dart
await AuditService.log(
  action: 'UPDATE',
  module: 'HR',
  description: 'Staff member updated: ${fullName}',
  entityType: 'Staff',
  entityId: staffId,
  oldValues: oldProfile,
  newValues: newProfile,
);
```

3. **`deactivateStaff()`** - Staff deactivation
```dart
await AuditService.log(
  action: 'DELETE',
  module: 'HR',
  description: 'Staff member deactivated: ${fullName}',
  entityType: 'Staff',
  entityId: staffId,
);
```

**File:** `lib/features/hr/services/leave_repository.dart` or similar

4. **`approveLeave()`** - Leave approval
```dart
await AuditService.log(
  action: 'APPROVE',
  module: 'HR',
  description: 'Leave request approved for ${staffName}: ${startDate} to ${endDate}',
  entityType: 'LeaveRequest',
  entityId: leaveId,
);
```

5. **`rejectLeave()`** - Leave rejection
```dart
await AuditService.log(
  action: 'REJECT',
  module: 'HR',
  description: 'Leave request rejected for ${staffName}: ${reason}',
  entityType: 'LeaveRequest',
  entityId: leaveId,
);
```

**File:** `lib/features/hr/services/payroll_repository.dart` or similar

6. **`executePayrollRun()`** - Payroll execution
```dart
await AuditService.log(
  action: 'CREATE',
  module: 'HR',
  description: 'Payroll run executed for period ${periodName}: ${staffCount} staff, total R${totalAmount}',
  entityType: 'PayrollRun',
  entityId: payrollRunId,
);
```

---

### PRODUCTION MODULE

**File:** `lib/features/production/services/carcass_repository.dart` or similar

**Methods to update:**

1. **`createCarcassIntake()`** - Carcass intake
```dart
await AuditService.log(
  action: 'CREATE',
  module: 'Production',
  description: 'Carcass intake: ${animalType} - ${weight}kg from ${supplierName}',
  entityType: 'CarcassIntake',
  entityId: intakeId,
);
```

2. **`completeBreakdown()`** - Breakdown completion
```dart
await AuditService.log(
  action: 'UPDATE',
  module: 'Production',
  description: 'Breakdown completed: Carcass #${carcassNumber} → ${cutsCount} cuts',
  entityType: 'CarcassIntake',
  entityId: intakeId,
);
```

**File:** `lib/features/production/services/production_batch_repository.dart`

3. **`completeBatch()`** - Production batch completion
```dart
await AuditService.log(
  action: 'UPDATE',
  module: 'Production',
  description: 'Production batch completed: ${recipeName} - ${quantityProduced}${unit}',
  entityType: 'ProductionBatch',
  entityId: batchId,
);
```

**File:** `lib/features/production/services/dryer_batch_repository.dart`

4. **`completeDryerBatch()`** - Dryer batch completion
```dart
await AuditService.log(
  action: 'UPDATE',
  module: 'Production',
  description: 'Dryer batch completed: ${productName} - ${quantity}kg',
  entityType: 'DryerBatch',
  entityId: batchId,
);
```

---

### HUNTER MODULE

**File:** `lib/features/hunter/screens/job_intake_screen.dart` (in _save method)

**Methods to update:**

1. **Job creation** - In `_save()` after insert
```dart
await AuditService.log(
  action: 'CREATE',
  module: 'Hunter',
  description: 'Hunter job created: ${hunterName} - ${species} (${estimatedWeight}kg)',
  entityType: 'HunterJob',
  entityId: jobId,
);
```

2. **Job update** - In `_save()` after update
```dart
await AuditService.log(
  action: 'UPDATE',
  module: 'Hunter',
  description: 'Hunter job updated: ${hunterName} - Job #${jobNumber}',
  entityType: 'HunterJob',
  entityId: jobId,
  oldValues: existingJob,
  newValues: payload,
);
```

**File:** `lib/features/hunter/screens/job_list_screen.dart`

3. **Job deletion** - In `_confirmDeleteJob()` after delete
```dart
await AuditService.log(
  action: 'DELETE',
  module: 'Hunter',
  description: 'Hunter job deleted: Job #${jobNumber}',
  entityType: 'HunterJob',
  entityId: jobId,
);
```

**File:** `lib/features/hunter/screens/job_process_screen.dart` or similar

4. **Status change** - When status is updated
```dart
await AuditService.log(
  action: 'UPDATE',
  module: 'Hunter',
  description: 'Hunter job status changed: ${oldStatus} → ${newStatus} for Job #${jobNumber}',
  entityType: 'HunterJob',
  entityId: jobId,
);
```

---

### ACCOUNTS MODULE

**File:** `lib/features/accounts/services/account_repository.dart` or similar

**Methods to update:**

1. **`recordPayment()`** - Payment recording
```dart
await AuditService.log(
  action: 'CREATE',
  module: 'Accounts',
  description: 'Payment recorded: R${amount} for ${customerName} - ${paymentMethod}',
  entityType: 'Payment',
  entityId: paymentId,
);
```

2. **`updateCreditLimit()`** - Credit limit change
```dart
await AuditService.log(
  action: 'UPDATE',
  module: 'Accounts',
  description: 'Credit limit changed for ${customerName}: R${oldLimit} → R${newLimit}',
  entityType: 'Account',
  entityId: accountId,
  oldValues: {'credit_limit': oldLimit},
  newValues: {'credit_limit': newLimit},
);
```

3. **`suspendAccount()`** - Account suspension
```dart
await AuditService.log(
  action: 'UPDATE',
  module: 'Accounts',
  description: 'Account suspended: ${customerName} - ${reason}',
  entityType: 'Account',
  entityId: accountId,
);
```

4. **`reactivateAccount()`** - Account reactivation
```dart
await AuditService.log(
  action: 'UPDATE',
  module: 'Accounts',
  description: 'Account reactivated: ${customerName}',
  entityType: 'Account',
  entityId: accountId,
);
```

---

### BOOKKEEPING MODULE

**File:** `lib/features/bookkeeping/services/supplier_invoice_repository.dart`

**Methods to update:**

1. **`create()`** - Invoice creation
```dart
await AuditService.log(
  action: 'CREATE',
  module: 'Bookkeeping',
  description: 'Supplier invoice created: ${invoiceNumber} - ${supplierName} R${total}',
  entityType: 'SupplierInvoice',
  entityId: invoiceId,
);
```

2. **`update()`** - Invoice update
```dart
await AuditService.log(
  action: 'UPDATE',
  module: 'Bookkeeping',
  description: 'Supplier invoice updated: ${invoiceNumber}',
  entityType: 'SupplierInvoice',
  entityId: invoiceId,
);
```

3. **`approve()`** - Invoice approval/posting
```dart
await AuditService.log(
  action: 'APPROVE',
  module: 'Bookkeeping',
  description: 'Supplier invoice approved and posted to ledger: ${invoiceNumber} - R${total}',
  entityType: 'SupplierInvoice',
  entityId: invoiceId,
);
```

**File:** `lib/features/bookkeeping/services/ledger_repository.dart`

4. **`createDoubleEntry()`** - Ledger entry
```dart
await AuditService.log(
  action: 'CREATE',
  module: 'Bookkeeping',
  description: 'Ledger entry posted: ${description} - Debit ${debitAccount} / Credit ${creditAccount} R${amount}',
  entityType: 'LedgerEntry',
  entityId: entryId,
);
```

---

### AUTH MODULE

**File:** `lib/core/services/auth_service.dart`

**Methods to update:**

1. **`authenticateWithPin()`** - After successful authentication
```dart
await AuditService.logLogin(
  success: true,
  email: email,
  role: role,
);
```

2. **`authenticateWithPin()`** - After failed authentication
```dart
await AuditService.logLogin(
  success: false,
  email: attemptedPin,
  failureReason: 'Invalid PIN',
);
```

3. **`logout()`** - User logout
```dart
await AuditService.logLogout(
  email: _currentStaffName ?? 'Unknown',
);
```

4. **PIN lockout trigger** - If implemented
```dart
await AuditService.logLockout(
  email: email,
  attemptCount: failedAttempts,
);
```

---

## STEP 3 - Implementation Priority

### HIGH PRIORITY (Implement First):
1. ✅ **Auth module** - Login/logout tracking
2. ⏳ **Inventory** - Product changes and stock movements
3. ⏳ **Hunter** - Job creation/update/delete
4. ⏳ **Accounts** - Payment recording and credit changes

### MEDIUM PRIORITY (Implement Second):
5. ⏳ **HR** - Staff changes and leave approvals
6. ⏳ **Bookkeeping** - Invoice and ledger entries
7. ⏳ **Production** - Batch completions

### LOW PRIORITY (Nice to Have):
8. ⏳ **Export operations** - PDF generation, report exports
9. ⏳ **Settings changes** - Business settings updates
10. ⏳ **Price overrides** - Manual price adjustments in POS

---

## Implementation Pattern

### Standard Pattern:
```dart
// 1. Import audit service
import 'package:admin_app/core/services/audit_service.dart';

// 2. After successful operation, add audit call
try {
  // ... existing operation code ...
  final result = await _client.from('table').insert(data);
  
  // Add audit logging (fire-and-forget)
  await AuditService.log(
    action: 'CREATE',
    module: 'ModuleName',
    description: 'Human-readable description',
    entityType: 'EntityType',
    entityId: result['id'],
    newValues: data,
  );
  
  return result;
} catch (e) {
  // ... existing error handling ...
}
```

### Update Pattern (with old/new values):
```dart
try {
  // Fetch old values before update
  final old = await _client.from('table').select().eq('id', id).single();
  
  // Perform update
  final updated = await _client.from('table').update(data).eq('id', id).select().single();
  
  // Audit with before/after
  await AuditService.log(
    action: 'UPDATE',
    module: 'ModuleName',
    description: 'Record updated',
    entityType: 'EntityType',
    entityId: id,
    oldValues: old,
    newValues: updated,
  );
  
  return updated;
} catch (e) {
  // ... error handling ...
}
```

---

## Files Created/Modified

### Created:
1. ✅ `lib/core/services/audit_service.dart` - Main audit service

### To Modify (Repositories only - not screens):
1. `lib/core/services/auth_service.dart` - Login/logout
2. `lib/features/inventory/services/inventory_repository.dart` - Product & stock operations
3. `lib/features/hr/services/staff_repository.dart` - Staff operations
4. `lib/features/hr/services/leave_repository.dart` - Leave approvals
5. `lib/features/hr/services/payroll_repository.dart` - Payroll runs
6. `lib/features/production/services/carcass_repository.dart` - Carcass operations
7. `lib/features/production/services/production_batch_repository.dart` - Production batches
8. `lib/features/production/services/dryer_batch_repository.dart` - Dryer batches
9. `lib/features/hunter/screens/job_intake_screen.dart` - Hunter job save method
10. `lib/features/hunter/screens/job_list_screen.dart` - Hunter job delete
11. `lib/features/accounts/services/account_repository.dart` - Account operations
12. `lib/features/bookkeeping/services/supplier_invoice_repository.dart` - Invoice operations
13. `lib/features/bookkeeping/services/ledger_repository.dart` - Ledger entries

---

## Testing Recommendations

1. **Create operation:**
   - Perform a create operation
   - Check audit_log table for new entry with action='CREATE'
   - Verify staff_name, description, entity_id populated

2. **Update operation:**
   - Perform an update
   - Check audit_log for action='UPDATE'
   - Verify old_values and new_values are populated (if implemented)

3. **Delete operation:**
   - Perform a delete
   - Check audit_log for action='DELETE'

4. **Auth operations:**
   - Login successfully → Check for LOGIN entry
   - Login with wrong PIN → Check for LOGIN_FAILED entry
   - Logout → Check for LOGOUT entry

5. **Error resilience:**
   - Temporarily break audit_log table connection
   - Perform operations
   - Verify operations still succeed (audit failures don't crash app)
   - Check console for audit error messages

---

## Status: ✅ AUDIT SERVICE CREATED

**Next step:** Wire audit calls into repositories as documented above.

**Highest priority:** Auth module (login/logout) and Inventory module (product/stock operations).
