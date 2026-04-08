import 'package:flutter/foundation.dart';

/// Centralized error handling for print operations
class PrintErrorHandler {
  static void logError(String service, String operation, dynamic error, {String? jobId}) {
    final jobIdStr = jobId != null ? ' (Job: $jobId)' : '';
    debugPrint('[$service] $operation failed$jobIdStr: $error');
  }

  static void logWarning(String service, String message, {String? jobId}) {
    final jobIdStr = jobId != null ? ' (Job: $jobId)' : '';
    debugPrint('[$service] WARNING$message$jobIdStr');
  }

  static void logInfo(String service, String message, {String? jobId}) {
    final jobIdStr = jobId != null ? ' (Job: $jobId)' : '';
    debugPrint('[$service] INFO$message$jobIdStr');
  }

  static bool isRetryableError(dynamic error) {
    // Network errors, timeouts, and temporary issues are retryable
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('network') ||
           errorStr.contains('timeout') ||
           errorStr.contains('connection') ||
           errorStr.contains('temporary') ||
           errorStr.contains('unavailable');
  }

  static bool isDuplicateError(dynamic error) {
    // Unique constraint violations indicate duplicate attempts
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('unique') ||
           errorStr.contains('duplicate') ||
           errorStr.contains('already exists');
  }

  static bool isPermissionError(dynamic error) {
    // Permission or authentication errors
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('permission') ||
           errorStr.contains('unauthorized') ||
           errorStr.contains('forbidden') ||
           errorStr.contains('access denied');
  }
}
