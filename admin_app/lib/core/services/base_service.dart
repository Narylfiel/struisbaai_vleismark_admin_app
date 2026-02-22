import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Base service class providing common Supabase operations
/// All services should extend this class for consistent error handling and logging
abstract class BaseService {
  final SupabaseClient _client = Supabase.instance.client;

  SupabaseClient get client => _client;

  /// Execute a database query with error handling and retry logic
  Future<T> executeQuery<T>(
    Future<T> Function() query, {
    String? operationName,
    int maxRetries = 3,
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        final result = await query();
        if (operationName != null) {
          print('✅ $operationName completed successfully');
        }
        return result;
      } catch (e) {
        attempts++;
        final errorMsg = operationName != null
            ? '$operationName failed (Attempt $attempts/$maxRetries): $e'
            : 'Database operation failed (Attempt $attempts/$maxRetries): $e';
        print('⚠️ $errorMsg');
        
        if (attempts >= maxRetries) {
          print('❌ Final attempt failed for $operationName');
          throw Exception(errorMsg);
        }
        
        // Exponential backoff
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    throw Exception('Failed to execute $operationName after $maxRetries attempts');
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