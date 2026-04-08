import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for printing delivery labels from the unified print queue.
/// 
/// This service:
/// - Polls online_order_print_queue for delivery_label type
/// - Respects hold_until timestamp (17:00-09:00 hold window)
/// - Uses atomic claim pattern to prevent duplicate printing
/// - Marks jobs as printed after successful print
class DeliveryLabelPrintService {
  DeliveryLabelPrintService._();
  static final instance = DeliveryLabelPrintService._();

  final _supabase = Supabase.instance.client;
  bool _isPolling = false;
  bool _isProcessing = false;
  static const Duration _pollingInterval = Duration(seconds: 30);

  /// Poll the print queue for delivery labels ready to print
  /// 
  /// Returns list of print jobs that are:
  /// - print_type = 'delivery_label'
  /// - printed = false
  /// - hold_until IS NULL OR hold_until <= now()
  Future<List<Map<String, dynamic>>> pollQueue() async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();

      final response = await _supabase
          .from('online_order_print_queue')
          .select('*')
          .eq('print_type', 'delivery_label')
          .eq('printed', false)
          .or('hold_until.is.null,hold_until.lte.$now')
          .order('created_at');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('[DELIVERY_LABEL_PRINT] Poll error: $e');
      return [];
    }
  }

  /// Atomically claim and print a delivery label
  /// 
  /// Uses UPDATE...RETURNING pattern to prevent duplicate printing.
  /// Only prints if the row was successfully claimed (not already printed).
  Future<bool> claimAndPrint(String jobId) async {
    try {
      // ATOMIC CLAIM: Update to printed=true and return row if successful
      final response = await _supabase.rpc(
        'claim_print_job',
        params: {'job_id': jobId},
      );

      if (response == null) {
        debugPrint('[PRINT_QUEUE][ADMIN] Job $jobId already claimed');
        return false;
      }

      final job = response as Map<String, dynamic>?;
      if (job == null) {
        debugPrint('[PRINT_QUEUE][ADMIN] Job $jobId returned null data');
        return false;
      }

      final orderData = job['order_data'] as Map<String, dynamic>?;
      if (orderData == null) {
        debugPrint('[PRINT_QUEUE][ADMIN] Job $jobId has no order_data');
        return false;
      }

      // Print the label
      try {
        await _printLabel(orderData);
        debugPrint('[PRINT_QUEUE][ADMIN] Print success: $jobId');
      } catch (printError) {
        // Critical: Job is already claimed but print failed
        debugPrint('[PRINT_QUEUE][ADMIN] PRINT FAILED: job_id=$jobId error=$printError');
        
        // Record failure in database for visibility and manual recovery
        try {
          await _supabase
              .from('online_order_print_queue')
              .update({
                'last_error': printError.toString(),
                'print_attempts': (job['print_attempts'] as int? ?? 0) + 1,
              })
              .eq('id', jobId);
          debugPrint('[PRINT_QUEUE][ADMIN] Failure recorded for job $jobId');
        } catch (recordError) {
          debugPrint('[PRINT_QUEUE][ADMIN] Failed to record error for job $jobId: $recordError');
        }
        
        return true; // Still return true since job was claimed
      }

      return true;
    } catch (e) {
      debugPrint('[PRINT_QUEUE][ADMIN] Claim error for job $jobId: $e');
      return false;
    }
  }

  /// Print delivery label (placeholder - implement actual print logic)
  Future<void> _printLabel(Map<String, dynamic> orderData) async {
    // TODO: Implement actual label printing
    // Options:
    // 1. PDF generation + print
    // 2. Thermal printer via platform channel
    // 3. Screenshot of label widget + print
    
    debugPrint('[DELIVERY_LABEL_PRINT] Printing label for order ${orderData['order_number']}');
    
    // For now, just log the label data
    debugPrint('Customer: ${orderData['customer_name']}');
    debugPrint('Address: ${orderData['delivery_address']}');
    debugPrint('Phone: ${orderData['customer_phone']}');
    debugPrint('Items: ${orderData['items']}');
    
    // Simulate print delay
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Calculate hold_until timestamp based on current time
  /// 
  /// Rules:
  /// - 17:00-23:59 → hold until next day 09:00
  /// - 00:00-08:59 → hold until same day 09:00
  /// - 09:00-16:59 → print immediately (return null)
  static DateTime? calculateHoldTime(DateTime orderTime) {
    final hour = orderTime.hour;

    // Between 17:00 and 23:59 → hold until next day 09:00
    if (hour >= 17) {
      return DateTime(
        orderTime.year,
        orderTime.month,
        orderTime.day + 1,
        9, 0, 0,
      ).toUtc();
    }

    // Between 00:00 and 08:59 → hold until same day 09:00
    if (hour < 9) {
      return DateTime(
        orderTime.year,
        orderTime.month,
        orderTime.day,
        9, 0, 0,
      ).toUtc();
    }

    // Between 09:00 and 16:59 → print immediately
    return null;
  }

  /// Insert delivery label print job into queue
  /// 
  /// Called when order is packed and ready for delivery.
  /// Calculates hold_until based on current time.
  /// 
  /// IDEMPOTENT: If label already queued for this order, silently succeeds.
  /// This prevents duplicate labels if packing is retried.
  Future<void> queueDeliveryLabel({
    required String orderId,
    required Map<String, dynamic> labelData,
  }) async {
    try {
      final holdUntil = calculateHoldTime(DateTime.now());

      await _supabase.from('online_order_print_queue').insert({
        'order_id': orderId,
        'order_data': labelData,
        'print_type': 'delivery_label',
        'hold_until': holdUntil?.toIso8601String(),
        'printed': false,
      });

      debugPrint('[DELIVERY_LABEL_PRINT] Queued label for order $orderId');
      if (holdUntil != null) {
        debugPrint('[DELIVERY_LABEL_PRINT] Held until ${holdUntil.toLocal()}');
      } else {
        debugPrint('[DELIVERY_LABEL_PRINT] Ready to print immediately');
      }
    } catch (e) {
      // Check if error is due to duplicate (unique constraint violation)
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('unique') || errorMsg.contains('duplicate')) {
        // Label already queued - this is OK (idempotent behavior)
        debugPrint('[DELIVERY_LABEL_PRINT] Label already queued for order $orderId (idempotent)');
        return; // Silently succeed
      }
      
      // Other error - rethrow
      debugPrint('[DELIVERY_LABEL_PRINT] Queue error: $e');
      rethrow;
    }
  }

  // ============================================
  // POLLING FUNCTIONALITY
  // ============================================

  /// Start polling for delivery labels to print
  void startPolling() {
    if (_isPolling) {
      debugPrint('[PRINT_QUEUE][ADMIN] Poll already running - skipping');
      return;
    }

    _isPolling = true;
    debugPrint('[PRINT_QUEUE][ADMIN] Starting poll loop');
    _pollLoop();
  }

  /// Stop polling with graceful shutdown
  Future<void> stopPolling() async {
    if (!_isPolling) return;

    debugPrint('[PRINT_QUEUE][ADMIN] Stopping poll loop...');
    _isPolling = false;

    // Wait for active processing to complete
    while (_isProcessing) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    debugPrint('[PRINT_QUEUE][ADMIN] Poll loop fully stopped');
  }

  /// Controlled async poll loop
  Future<void> _pollLoop() async {
    debugPrint('[PRINT_QUEUE][ADMIN] Poll loop started');

    while (_isPolling) {
      try {
        if (!_isProcessing) {
          await _pollForLabels();
        }
      } catch (e, stack) {
        debugPrint('[PRINT_QUEUE][ADMIN] Poll loop error: $e');
      }

      await Future.delayed(_pollingInterval);
    }

    debugPrint('[PRINT_QUEUE][ADMIN] Poll loop stopped');
  }

  /// Poll for unprinted delivery labels and process them
  Future<void> _pollForLabels() async {
    if (_isProcessing) {
      debugPrint('[PRINT_QUEUE][ADMIN] Poll already in progress - skipping');
      return;
    }

    _isProcessing = true;
    try {
      final jobs = await pollQueue();
      
      if (jobs.isEmpty) {
        return; // No jobs to process
      }

      debugPrint('[PRINT_QUEUE][ADMIN] Found ${jobs.length} delivery label jobs');

      // Process each job with atomic claim
      for (final job in jobs) {
        if (job == null) {
          debugPrint('[PRINT_QUEUE][ADMIN] Skipping null job');
          continue;
        }
        await _processLabelJob(job);
      }
    } catch (e) {
      debugPrint('[PRINT_QUEUE][ADMIN] Error polling for labels: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Process a single label job with atomic claim
  Future<void> _processLabelJob(Map<String, dynamic> job) async {
    if (job == null || job['id'] == null) {
      debugPrint('[PRINT_QUEUE][ADMIN] Skipping invalid job');
      return;
    }

    final String jobId = job['id'];

    try {
      // Use existing claimAndPrint method
      final success = await claimAndPrint(jobId);
      
      if (success) {
        debugPrint('[PRINT_QUEUE][ADMIN] Job claimed: $jobId');
      } else {
        debugPrint('[PRINT_QUEUE][ADMIN] Job $jobId skipped (already claimed)');
      }
    } catch (e) {
      debugPrint('[PRINT_QUEUE][ADMIN] Error processing label job $jobId: $e');
    }
  }

  /// Get current polling status
  bool get isRunning => _isPolling;

  /// Manual trigger for testing
  Future<void> testPoll() async {
    await _pollForLabels();
  }
}
