import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/auth_service.dart';
import 'package:flutter/foundation.dart';

/// Singleton audit service for fire-and-forget audit logging.
/// 
/// CRITICAL RULES:
/// - NEVER block the calling operation
/// - NEVER throw errors up to callers
/// - Log failures to console only
/// - Audit failures must NEVER crash the app
class AuditService {
  static final AuditService _instance = AuditService._internal();
  factory AuditService() => _instance;
  AuditService._internal();

  final _client = SupabaseService.client;
  final _auth = AuthService();

  /// Fire-and-forget audit log write.
  /// 
  /// Confirmed audit_log table columns (based on existing reads):
  /// - action: text (required)
  /// - staff_name: text
  /// - details: text
  /// - created_at: timestamptz (auto)
  /// - staff_id: uuid
  /// - module: text
  /// - entity_type: text
  /// - entity_id: text
  /// - old_values: jsonb
  /// - new_values: jsonb
  static Future<void> log({
    required String action,      // 'CREATE' | 'UPDATE' | 'DELETE' | 'LOGIN' | 'LOGOUT' | 'EXPORT' | 'APPROVE' | 'REJECT'
    required String module,      // 'Inventory' | 'HR' | 'Production' | 'Hunter' | 'Accounts' | 'Bookkeeping' | 'Auth'
    required String description, // Human-readable: "Product 'Rump Steak 500g' price updated"
    String? entityType,          // 'Product' | 'Staff' | 'Invoice' | 'Job' | etc.
    String? entityId,            // UUID of the affected record
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  }) async {
    // Fire-and-forget - never await
    _instance._writeLog(
      action: action,
      module: module,
      description: description,
      entityType: entityType,
      entityId: entityId,
      oldValues: oldValues,
      newValues: newValues,
    );
  }

  /// Internal write method - swallows ALL errors
  Future<void> _writeLog({
    required String action,
    required String module,
    required String description,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  }) async {
    try {
      // Get current staff info
      final staffId = _auth.currentStaffId;
      final staffName = _auth.currentStaffName ?? _auth.getCurrentStaffName();

      // Build payload
      final payload = <String, dynamic>{
        'action': action,
        'module': module,
        'details': description,
        'staff_id': staffId,
        'staff_name': staffName.isNotEmpty ? staffName : 'System',
        'entity_type': entityType,
        'entity_id': entityId,
        'old_values': oldValues,
        'new_values': newValues,
      };

      // Remove nulls
      payload.removeWhere((key, value) => value == null);

      // Write to audit_log table
      await _client.from('audit_log').insert(payload);
      
      // Success - silent
      if (kDebugMode) {
        debugPrint('[AUDIT] $action $module: $description');
      }
    } catch (e, stackTrace) {
      // NEVER throw - just log to console
      if (kDebugMode) {
        debugPrint('[AUDIT ERROR] Failed to log audit entry: $e');
        debugPrint('[AUDIT ERROR] Stack trace: $stackTrace');
      }
      // Swallow error - audit must never crash the app
    }
  }

  /// Convenience method for login events
  static Future<void> logLogin({
    required bool success,
    required String email,
    String? role,
    String? failureReason,
  }) async {
    await log(
      action: success ? 'LOGIN' : 'LOGIN_FAILED',
      module: 'Auth',
      description: success
          ? 'Successful login: $email${role != null ? " (role: $role)" : ""}'
          : 'Failed login attempt: $email${failureReason != null ? " - $failureReason" : ""}',
      entityType: 'User',
      entityId: email,
    );
  }

  /// Convenience method for logout events
  static Future<void> logLogout({required String email}) async {
    await log(
      action: 'LOGOUT',
      module: 'Auth',
      description: 'User logged out: $email',
      entityType: 'User',
      entityId: email,
    );
  }

  /// Convenience method for lockout events
  static Future<void> logLockout({
    required String email,
    required int attemptCount,
  }) async {
    await log(
      action: 'LOCKOUT',
      module: 'Auth',
      description: 'Account locked after $attemptCount failed attempts: $email',
      entityType: 'User',
      entityId: email,
    );
  }
}
