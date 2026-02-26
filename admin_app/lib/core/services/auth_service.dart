import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:admin_app/core/services/audit_service.dart';
import 'package:admin_app/core/services/permission_service.dart';
import 'base_service.dart';
import '../constants/admin_config.dart';

/// Authentication service: single identity source and session for the admin app.
///
/// **Identity source:** All identity and validation use `staff_profiles` (id, full_name, role,
/// is_active, pin_hash). Do not use `profiles` for auth in this app.
///
/// **Flow:** (1) PinScreen verifies PIN against staff_profiles (or local cache), then calls
/// [setSession]. (2) On startup, [restoreSessionFromCache] validates cached session against
/// staff_profiles. (3) All modules use [currentStaffId]/[getCurrentStaffId] for audit fields.
///
/// **Session:** In-memory + SharedPreferences; no Supabase Auth. Use [AuthService] singleton
/// or [SessionScope.of](context) for consistent access.
class AuthService extends BaseService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _currentStaffId;
  String? _currentStaffName;
  String? _currentRole;

  static const String _cachedStaffKey = 'cached_staff_profiles';
  static const String _activeSessionKey = 'active_session';

  // Getters
  String? get currentStaffId => _currentStaffId;
  String? get currentStaffName => _currentStaffName;
  String? get currentRole => _currentRole;
  bool get isLoggedIn => _currentStaffId != null;

  /// Reusable audit helper: current staff id for completedBy, recorded_by, created_by. Returns empty string if not logged in.
  String getCurrentStaffId() => _currentStaffId ?? '';

  /// Reusable audit helper: current staff name for display or audit. Returns empty string if not logged in.
  String getCurrentStaffName() => _currentStaffName ?? '';

  /// Authenticate user with PIN
  Future<Map<String, dynamic>?> authenticateWithPin(String pin) async {
    try {
      // Hash the PIN for comparison
      final pinHash = _hashPin(pin);

      // First try online authentication
      final onlineResult = await _authenticateOnline(pinHash);
      if (onlineResult != null) {
        _setCurrentUser(onlineResult);
        await _cacheStaffProfile(onlineResult);
        
        // Load permissions for the session
        await PermissionService().loadPermissions(
          role: onlineResult['role'],
          staffId: onlineResult['id'],
        );
        
        // Audit log - successful login
        await AuditService.logLogin(
          success: true,
          email: onlineResult['name'] ?? 'Unknown',
          role: onlineResult['role'],
        );
        
        return onlineResult;
      }

      // Fallback to offline authentication
      final offlineResult = await _authenticateOffline(pinHash);
      if (offlineResult != null) {
        _setCurrentUser(offlineResult);
        
        // Load permissions for the session
        await PermissionService().loadPermissions(
          role: offlineResult['role'],
          staffId: offlineResult['id'],
        );
        
        // Audit log - successful offline login
        await AuditService.logLogin(
          success: true,
          email: offlineResult['name'] ?? 'Unknown',
          role: offlineResult['role'],
        );
        
        return offlineResult;
      }

      // Failed authentication
      await AuditService.logLogin(
        success: false,
        email: 'PIN: ${pin.substring(0, 1)}***',
        failureReason: 'Invalid PIN',
      );

      return null;
    } catch (e) {
      print('Authentication error: $e');
      
      // Audit log - authentication error
      await AuditService.logLogin(
        success: false,
        email: 'Unknown',
        failureReason: 'System error: $e',
      );
      
      throw Exception('Authentication failed: $e');
    }
  }

  /// Online authentication against Supabase (single identity source: staff_profiles)
  Future<Map<String, dynamic>?> _authenticateOnline(String pinHash) async {
    try {
      final response = await executeQuery(
        () => client
            .from('staff_profiles')
            .select('id, full_name, role, is_active, pin_hash')
            .eq('pin_hash', pinHash)
            .eq('is_active', true)
            .single(),
        operationName: 'Online PIN authentication',
      );

      if (response != null && response['pin_hash'] == pinHash) {
        return {
          'id': response['id'],
          'name': response['full_name'],
          'role': response['role'],
        };
      }
      return null;
    } catch (e) {
      print('Online auth failed, trying offline: $e');
      return null;
    }
  }

  /// Offline authentication using cached profiles
  Future<Map<String, dynamic>?> _authenticateOffline(String pinHash) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStaffJson = prefs.getString(_cachedStaffKey);
      
      if (cachedStaffJson != null) {
        final List<dynamic> cachedStaff = jsonDecode(cachedStaffJson);
        final profile = cachedStaff.firstWhere(
          (staff) => staff['pin_hash'] == pinHash && staff['is_active'] == true,
          orElse: () => null,
        );
        
        if (profile != null) {
          print('✅ Offline authentication successful for: ${profile['name']}');
          // Cache the active session locally
          await prefs.setString(_activeSessionKey, jsonEncode(profile));
          return Map<String, dynamic>.from(profile);
        }
      }
      return null;
    } catch (e) {
      print('❌ Offline auth failed: $e');
      return null;
    }
  }

  /// Validate current session (single identity source: staff_profiles)
  Future<bool> validateSession() async {
    if (!isLoggedIn || _currentStaffId == null) return false;
    final staffId = _currentStaffId!;

    try {
      final response = await executeQuery(
        () => client
            .from('staff_profiles')
            .select('is_active')
            .eq('id', staffId)
            .single(),
        operationName: 'Session validation',
      );

      return response?['is_active'] == true;
    } catch (e) {
      print('Session validation failed: $e');
      return false;
    }
  }

  /// Set session from external auth (e.g. PIN screen). Call after PIN verification.
  void setSession(String staffId, String staffName, String role) {
    _currentStaffId = staffId;
    _currentStaffName = staffName;
    _currentRole = role;
    _persistSession(staffId, staffName, role);
  }

  /// Restore session from SharedPreferences with Supabase validation.
  /// Returns validated staff map (id, full_name, role) if valid, otherwise null.
  /// Validates: staff exists, is_active, role allowed.
  Future<Map<String, dynamic>?> restoreSessionFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_activeSessionKey);
      if (cached == null) return null;

      final map = jsonDecode(cached) as Map<String, dynamic>;
      final id = map['id']?.toString();
      if (id == null || id.isEmpty) return null;

      // Validate via Supabase: staff exists and is active
      final response = await executeQuery(
        () => client
            .from('profiles')
            .select('id, full_name, role, is_active')
            .eq('id', id)
            .maybeSingle(),
        operationName: 'Session restore validation',
      );

      if (response == null) {
        await logout();
        return null;
      }

      final isActive = response['is_active'];
      if (isActive != true) {
        await logout();
        return null;
      }

      final role = response['role'] as String? ?? '';
      if (!AdminConfig.allowedRoles.contains(role.toLowerCase())) {
        await logout();
        return null;
      }

      _setCurrentUser({
        'id': id,
        'name': response['full_name'],
        'role': role,
      });
      
      // Load permissions for restored session
      await PermissionService().loadPermissions(
        role: role,
        staffId: id,
      );
      
      return {
        'id': id,
        'full_name': response['full_name'],
        'role': role,
      };
    } catch (e) {
      print('Session restore failed: $e');
      await logout();
      return null;
    }
  }

  Future<void> _persistSession(String staffId, String staffName, String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeSessionKey, jsonEncode({
        'id': staffId,
        'name': staffName,
        'role': role,
      }));
    } catch (e) {
      print('Failed to persist session: $e');
    }
  }

  /// Logout current user
  Future<void> logout() async {
    // Capture name before clearing session
    final staffName = _currentStaffName ?? 'Unknown';
    
    // Audit log - logout
    await AuditService.logLogout(email: staffName);
    
    // Clear permissions cache
    PermissionService().clear();
    
    _currentStaffId = null;
    _currentStaffName = null;
    _currentRole = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeSessionKey);
    } catch (e) {
      print('Failed to clear active session cache: $e');
    }
  }

  /// Check if user has required role
  bool hasRole(String requiredRole) {
    if (!isLoggedIn || _currentRole == null) return false;

    // Role hierarchy: owner > manager > others
    const roleHierarchy = {'owner': 3, 'manager': 2, 'cashier': 1, 'blockman': 1};

    final currentLevel = roleHierarchy[_currentRole] ?? 0;
    final requiredLevel = roleHierarchy[requiredRole] ?? 0;

    return currentLevel >= requiredLevel;
  }

  /// Check if user can access a specific feature
  bool canAccessFeature(String feature) {
    if (!isLoggedIn) return false;

    // Define role-based feature access
    const featureAccess = {
      'dashboard': ['owner', 'manager', 'cashier', 'blockman'],
      'inventory': ['owner', 'manager'],
      'production': ['owner', 'manager', 'blockman'],
      'hr': ['owner', 'manager'],
      'accounts': ['owner', 'manager'],
      'bookkeeping': ['owner'],
      'analytics': ['owner', 'manager'],
      'reports': ['owner', 'manager'],
      'customers': ['owner', 'manager'],
      'audit': ['owner'],
      'settings': ['owner'],
    };

    final allowedRoles = featureAccess[feature] ?? [];
    return allowedRoles.contains(_currentRole);
  }

  /// Get all active staff for caching (single identity source: staff_profiles)
  Future<List<Map<String, dynamic>>> getAllActiveStaff() async {
    try {
      final response = await executeQuery(
        () => client
            .from('staff_profiles')
            .select('id, full_name, role, pin_hash, is_active')
            .eq('is_active', true)
            .order('full_name'),
        operationName: 'Fetch active staff',
      );

      final list = List<Map<String, dynamic>>.from(response ?? []);
      for (final row in list) {
        row['name'] = row['full_name'];
      }
      return list;
    } catch (e) {
      throw Exception('Failed to fetch staff: $e');
    }
  }

  /// Cache staff profile for offline use
  Future<void> _cacheStaffProfile(Map<String, dynamic> profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStaffJson = prefs.getString(_cachedStaffKey);
      List<dynamic> cachedStaff = cachedStaffJson != null ? jsonDecode(cachedStaffJson) : [];
      
      // Update existing or add new
      final index = cachedStaff.indexWhere((staff) => staff['id'] == profile['id']);
      if (index >= 0) {
        cachedStaff[index] = profile;
      } else {
        cachedStaff.add(profile);
      }
      
      await prefs.setString(_cachedStaffKey, jsonEncode(cachedStaff));
      await prefs.setString(_activeSessionKey, jsonEncode(profile));
    } catch (e) {
      print('Failed to cache staff profile: $e');
    }
  }

  /// Hash PIN using SHA-256 (unsalted — matches PinScreen and staff_profiles form)
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  /// Set current user session
  void _setCurrentUser(Map<String, dynamic> user) {
    _currentStaffId = user['id'];
    _currentStaffName = user['name'];
    _currentRole = user['role'];
  }

  /// Handle authentication errors
  @override
  String handleAuthError(dynamic error) {
    if (error is AuthException) {
      switch (error.message) {
        case 'Invalid login credentials':
          return 'Invalid PIN. Please try again.';
        case 'User not found':
          return 'Staff member not found.';
        default:
          return 'Authentication error: ${error.message}';
      }
    }
    return super.handleAuthError(error);
  }
}