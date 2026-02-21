import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/admin_config.dart';

/// Base service class providing common Supabase operations
/// All services should extend this class for consistent error handling and logging
abstract class BaseService {
  final SupabaseClient _client = Supabase.instance.client;

  SupabaseClient get client => _client;

  /// Execute a database query with error handling
  Future<T> executeQuery<T>(
    Future<T> Function() query, {
    String? operationName,
  }) async {
    try {
      final result = await query();
      if (operationName != null) {
        print('✅ $operationName completed successfully');
      }
      return result;
    } catch (e) {
      final errorMsg = operationName != null
          ? '$operationName failed: $e'
          : 'Database operation failed: $e';
      print('❌ $errorMsg');
      throw Exception(errorMsg);
    }
  }

  /// Handle Supabase auth errors
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
    return 'An unexpected error occurred: $error';
  }

  /// Handle general database errors
  String handleDatabaseError(dynamic error) {
    if (error is PostgrestException) {
      return 'Database error: ${error.message}';
    }
    return 'An unexpected error occurred: $error';
  }

  /// Check if device is online (basic implementation)
  Future<bool> isOnline() async {
    try {
      await client.from('profiles').select('id').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }
}