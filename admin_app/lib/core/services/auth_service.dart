import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/base_service.dart';
import '../core/constants/admin_config.dart';

/// Authentication service handling PIN-based login, offline fallback, and session management
class AuthService extends BaseService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _currentStaffId;
  String? _currentStaffName;
  String? _currentRole;

  // Getters
  String? get currentStaffId => _currentStaffId;
  String? get currentStaffName => _currentStaffName;
  String? get currentRole => _currentRole;
  bool get isLoggedIn => _currentStaffId != null;

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
        return onlineResult;
      }

      // Fallback to offline authentication
      final offlineResult = await _authenticateOffline(pinHash);
      if (offlineResult != null) {
        _setCurrentUser(offlineResult);
        return offlineResult;
      }

      return null;
    } catch (e) {
      print('Authentication error: $e');
      throw Exception('Authentication failed: $e');
    }
  }

  /// Online authentication against Supabase
  Future<Map<String, dynamic>?> _authenticateOnline(String pinHash) async {
    try {
      final response = await executeQuery(
        client
            .from('profiles')
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
      // This would use the same caching mechanism as PIN screen
      // For now, return null as we need to implement the cache
      return null;
    } catch (e) {
      print('Offline auth failed: $e');
      return null;
    }
  }

  /// Validate current session
  Future<bool> validateSession() async {
    if (!isLoggedIn) return false;

    try {
      // Check if user still exists and is active
      final response = await executeQuery(
        client
            .from('profiles')
            .select('is_active')
            .eq('id', _currentStaffId)
            .single(),
        operationName: 'Session validation',
      );

      return response?['is_active'] == true;
    } catch (e) {
      print('Session validation failed: $e');
      return false;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    _currentStaffId = null;
    _currentStaffName = null;
    _currentRole = null;
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

  /// Get all active staff for caching
  Future<List<Map<String, dynamic>>> getAllActiveStaff() async {
    try {
      final response = await executeQuery(
        client
            .from('profiles')
            .select('id, full_name, role, pin_hash')
            .eq('is_active', true)
            .order('full_name'),
        operationName: 'Fetch active staff',
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      throw Exception('Failed to fetch staff: $e');
    }
  }

  /// Cache staff profile for offline use
  Future<void> _cacheStaffProfile(Map<String, dynamic> profile) async {
    // Implementation would use the same caching as PIN screen
    // For now, this is a placeholder
  }

  /// Hash PIN using SHA-256
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin + AdminConfig.supabaseUrl); // Salt with project URL
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