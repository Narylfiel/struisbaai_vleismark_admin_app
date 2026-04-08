import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';

/// Service for managing print job retries
class PrintRetryService {
  static final PrintRetryService instance = PrintRetryService._();
  PrintRetryService._();

  final SupabaseClient _supabase = SupabaseService.client;

  /// Check if a job can be retried (not already active)
  Future<bool> canRetryJob(String jobId) async {
    try {
      final response = await _supabase
          .from('online_order_print_queue')
          .select('printed, last_error')
          .eq('id', jobId)
          .single();

      // Prevent retry if job is already active (printed=false and no error)
      if (response != null) {
        final printed = response['printed'] as bool? ?? true;
        final lastError = response['last_error'] as String?;
        
        if (!printed && lastError == null) {
          debugPrint('[PRINT_QUEUE][ADMIN] RETRY BLOCKED: job_id=$jobId (already active)');
          return false;
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('[PRINT_QUEUE][ADMIN] RETRY CHECK ERROR: job_id=$jobId error=$e');
      return false;
    }
  }

  /// Retry a failed print job by resetting its status
  Future<bool> retryPrintJob(String jobId) async {
    try {
      // Check if job can be retried
      if (!await canRetryJob(jobId)) {
        return false;
      }

      debugPrint('[PRINT_QUEUE][ADMIN] RETRY: job_id=$jobId');

      final response = await _supabase
          .from('online_order_print_queue')
          .update({
            'printed': false,
            'printed_at': null,
            'last_error': null,
            // NOTE: print_attempts is preserved - it remains cumulative
          })
          .eq('id', jobId)
          .select();

      final success = response.isNotEmpty;
      if (success) {
        debugPrint('[PRINT_QUEUE][ADMIN] RETRY SUCCESS: job_id=$jobId');
      } else {
        debugPrint('[PRINT_QUEUE][ADMIN] RETRY FAILED: job_id=$jobId (not found)');
      }

      return success;
    } catch (e) {
      debugPrint('[PRINT_QUEUE][ADMIN] RETRY ERROR: job_id=$jobId error=$e');
      throw Exception('Failed to retry print job: $e');
    }
  }

  /// Get count of failed print jobs
  Future<int> getFailedJobsCount() async {
    try {
      final response = await _supabase
          .from('online_order_print_queue')
          .select('id')
          .is('last_error', 'not', null);

      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to get failed jobs count: $e');
    }
  }

  /// Get failed jobs by print type
  Future<Map<String, int>> getFailedJobsByType() async {
    try {
      final response = await _supabase
          .from('online_order_print_queue')
          .select('print_type, count(*)')
          .is('last_error', 'not', null)
          .group('print_type');

      final Map<String, int> result = {};
      for (final item in response) {
        result[item['print_type']] = item['count'] as int;
      }
      return result;
    } catch (e) {
      throw Exception('Failed to get failed jobs by type: $e');
    }
  }

  /// Clear old error records (cleanup utility)
  Future<int> clearOldErrors({int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld)).toIso8601String();
      
      final response = await _supabase
          .from('online_order_print_queue')
          .delete()
          .lt('created_at', cutoffDate)
          .is('last_error', 'not', null)
          .eq('printed', true);

      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to clear old errors: $e');
    }
  }
}
