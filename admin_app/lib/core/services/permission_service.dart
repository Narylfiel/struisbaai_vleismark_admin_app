import 'package:supabase_flutter/supabase_flutter.dart';

/// PermissionService — Singleton service for role-based permission checking.
///
/// Loads once after login, caches effective permissions for the session.
/// Owner role bypasses all checks (always returns true).
/// Personal overrides (profiles.permissions) take priority over role defaults.
class PermissionService {
  // Singleton pattern
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final _client = Supabase.instance.client;

  // Cached effective permissions for current session
  Map<String, bool> _effectivePermissions = {};
  bool _isOwner = false;
  bool _isLoaded = false;

  /// Load permissions once after login.
  ///
  /// Loads role defaults from role_permissions table, then applies personal
  /// overrides from profiles.permissions. Owner role bypasses DB queries.
  Future<void> loadPermissions({
    required String role,
    required String staffId,
  }) async {
    // Always reset before loading — prevents stale state from previous session
    _effectivePermissions = {};
    _isOwner = false;
    _isLoaded = false;

    try {
      // Owner bypass — no DB query needed
      if (role == 'owner') {
        _isOwner = true;
        _isLoaded = true;
        return;
      }

      // 1. Load role defaults from role_permissions
      Map<String, bool> roleDefaults = {};
      try {
        final roleData = await _client
            .from('role_permissions')
            .select('permissions')
            .eq('role_name', role)
            .maybeSingle();

        if (roleData != null && roleData['permissions'] != null) {
          final perms = roleData['permissions'] as Map<String, dynamic>;
          roleDefaults = perms.map((k, v) => MapEntry(k, v == true));
        }
      } catch (e) {
        // Fail safe — deny all if role permissions can't be loaded
      }

      // 2. Load personal overrides from profiles.permissions
      Map<String, bool> personalOverrides = {};
      try {
        final userData = await _client
            .from('profiles')
            .select('permissions')
            .eq('id', staffId)
            .maybeSingle();

        if (userData != null && userData['permissions'] != null) {
          final overrides = userData['permissions'] as Map<String, dynamic>;
          // Only apply keys that are explicitly set (not empty object)
          if (overrides.isNotEmpty) {
            personalOverrides = overrides.map((k, v) => MapEntry(k, v == true));
          }
        }
      } catch (e) {
        // Continue with role defaults only
      }

      // 3. Merge: start with role defaults, apply personal overrides on top
      _effectivePermissions = {...roleDefaults, ...personalOverrides};
      _isOwner = false;
      _isLoaded = true;

    } catch (e) {
      _effectivePermissions = {};
      _isLoaded = true;
    }
  }

  /// Check if current user has a specific permission.
  ///
  /// Owner always returns true. Otherwise checks cached effective permissions.
  /// Returns false if permissions not loaded or permission not found.
  bool can(String permission) {
    // Owner always gets everything
    if (_isOwner) return true;

    // If permissions not loaded yet — deny (safety)
    if (!_isLoaded) return false;

    // Check effective permissions (role defaults + personal overrides merged)
    return _effectivePermissions[permission] ?? false;
  }

  /// Check if user has ANY of the specified permissions.
  bool canAny(List<String> permissions) =>
      permissions.any((p) => can(p));

  /// Check if user has ALL of the specified permissions.
  bool canAll(List<String> permissions) =>
      permissions.every((p) => can(p));

  /// Clear cached permissions on logout.
  void clear() {
    _effectivePermissions = {};
    _isOwner = false;
    _isLoaded = false;
  }

  /// Get all effective permissions for debugging.
  Map<String, bool> get allPermissions => Map.unmodifiable(_effectivePermissions);

  /// Check if permissions have been loaded.
  bool get isLoaded => _isLoaded;

  /// Check if current user is owner.
  bool get isOwner => _isOwner;
}
