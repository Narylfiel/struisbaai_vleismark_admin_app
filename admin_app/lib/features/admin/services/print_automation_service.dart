import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';

/// Lightweight automation service for print queue operations
class PrintAutomationService {
  static final PrintAutomationService instance = PrintAutomationService._();
  PrintAutomationService._();

  final SupabaseClient _supabase = SupabaseService.client;

  // Automation metrics
  int _autoRetriesAttempted = 0;
  int _autoRetriesSucceeded = 0;
  int _priorityEscalations = 0;
  bool _backlogThrottlingActive = false;

  // Safe auto-retry error patterns
  static const List<String> _safeErrorPatterns = [
    'timeout',
    'temporary',
    'connection',
    'network',
    'unavailable',
  ];

  static const List<String> _unsafeErrorPatterns = [
    'paper jam',
    'printer offline',
    'out of paper',
    'hardware',
    'mechanical',
  ];

  /// Check if error is safe for auto-retry
  bool _isSafeError(String error) {
    final errorLower = error.toLowerCase();
    
    // Check for unsafe patterns first
    for (final unsafePattern in _unsafeErrorPatterns) {
      if (errorLower.contains(unsafePattern)) {
        return false;
      }
    }
    
    // Check for safe patterns
    for (final safePattern in _safeErrorPatterns) {
      if (errorLower.contains(safePattern)) {
        return true;
      }
    }
    
    return false;
  }

  /// Attempt safe auto-retry for a failed job
  Future<bool> attemptAutoRetry(Map<String, dynamic> job) async {
    try {
      final jobId = job['id'] as String;
      final lastError = job['last_error'] as String? ?? '';
      final attempts = job['print_attempts'] as int? ?? 0;

      // Safety checks
      if (attempts > 1) {
        debugPrint('[PRINT_QUEUE][AUTO] Skip auto-retry: too many attempts ($attempts)');
        return false;
      }

      if (!_isSafeError(lastError)) {
        debugPrint('[PRINT_QUEUE][AUTO] Skip auto-retry: unsafe error type');
        return false;
      }

      _autoRetriesAttempted++;
      debugPrint('[PRINT_QUEUE][AUTO] Attempting auto-retry for job $jobId');

      // Perform the retry (same logic as manual retry)
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
        _autoRetriesSucceeded++;
        debugPrint('[PRINT_QUEUE][AUTO] Auto-retry SUCCESS: job_id=$jobId');
      } else {
        debugPrint('[PRINT_QUEUE][AUTO] Auto-retry FAILED: job_id=$jobId (not found)');
      }

      return success;
    } catch (e) {
      debugPrint('[PRINT_QUEUE][AUTO] Auto-retry ERROR: $e');
      return false;
    }
  }

  /// Check for stuck jobs and escalate priority
  Future<List<String>> checkStuckJobs() async {
    try {
      final fifteenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 15)).toUtc().toIso8601String();
      
      final response = await _supabase
          .from('online_order_print_queue')
          .select('id, order_id, created_at')
          .eq('printed', false)
          .lt('created_at', fifteenMinutesAgo);

      final escalatedJobs = <String>[];
      
      for (final job in response) {
        final jobId = job['id'] as String;
        final orderId = job['order_id'] as String? ?? 'Unknown';
        
        // Mark as priority (we could add a priority column in the future)
        // For now, just log the escalation
        _priorityEscalations++;
        debugPrint('[PRINT_QUEUE][AUTO] Priority escalation: stuck job $orderId ($jobId)');
        escalatedJobs.add(orderId);
      }

      return escalatedJobs;
    } catch (e) {
      debugPrint('[PRINT_QUEUE][AUTO] Error checking stuck jobs: $e');
      return [];
    }
  }

  /// Check backlog and adjust polling if needed
  Future<bool> checkBacklogThrottling(int pendingCount) async {
    const backlogThreshold = 50;
    
    if (pendingCount > backlogThreshold && !_backlogThrottlingActive) {
      _backlogThrottlingActive = true;
      debugPrint('[PRINT_QUEUE][AUTO] Backlog high ($pendingCount) - throttling activated');
      return true;
    } else if (pendingCount <= backlogThreshold && _backlogThrottlingActive) {
      _backlogThrottlingActive = false;
      debugPrint('[PRINT_QUEUE][AUTO] Backlog normal ($pendingCount) - throttling deactivated');
      return true;
    }
    
    return false;
  }

  /// Process failed jobs for auto-retry
  Future<int> processFailedJobs() async {
    try {
      final response = await _supabase
          .from('online_order_print_queue')
          .select('*')
          .is('last_error', 'not', null)
          .eq('printed', false)
          .order('created_at', ascending: false)
          .limit(5); // Process only recent failed jobs

      int retryCount = 0;
      
      for (final job in response) {
        if (await attemptAutoRetry(job)) {
          retryCount++;
        }
      }

      if (retryCount > 0) {
        debugPrint('[PRINT_QUEUE][AUTO] Processed $retryCount auto-retries');
      }

      return retryCount;
    } catch (e) {
      debugPrint('[PRINT_QUEUE][AUTO] Error processing failed jobs: $e');
      return 0;
    }
  }

  /// Get automation metrics
  Map<String, dynamic> getAutomationMetrics() {
    return {
      'auto_retries_attempted': _autoRetriesAttempted,
      'auto_retries_succeeded': _autoRetriesSucceeded,
      'auto_retry_success_rate': _autoRetriesAttempted > 0 
          ? (_autoRetriesSucceeded / _autoRetriesAttempted * 100).toStringAsFixed(1) + '%'
          : '0%',
      'priority_escalations': _priorityEscalations,
      'backlog_throttling_active': _backlogThrottlingActive,
    };
  }

  /// Reset automation metrics (for testing or daily reset)
  void resetMetrics() {
    _autoRetriesAttempted = 0;
    _autoRetriesSucceeded = 0;
    _priorityEscalations = 0;
    _backlogThrottlingActive = false;
    debugPrint('[PRINT_QUEUE][AUTO] Metrics reset');
  }

  /// Check if throttling is currently active
  bool get isThrottlingActive => _backlogThrottlingActive;
}
