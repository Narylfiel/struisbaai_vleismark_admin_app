import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import '../services/print_retry_service.dart';

/// Screen to view and manage failed print jobs
class FailedPrintJobsScreen extends StatefulWidget {
  const FailedPrintJobsScreen({super.key});

  @override
  State<FailedPrintJobsScreen> createState() => _FailedPrintJobsScreenState();
}

class _FailedPrintJobsScreenState extends State<FailedPrintJobsScreen> {
  final SupabaseClient _supabase = SupabaseService.client;
  List<Map<String, dynamic>> _failedJobs = [];
  bool _isLoading = true;
  String? _error;
  final Set<String> _retryingJobs = <String>{};

  @override
  void initState() {
    super.initState();
    _loadFailedJobs();
  }

  Future<void> _loadFailedJobs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _supabase
          .from('online_order_print_queue')
          .select('*')
          .not('last_error', 'is', null)
          .order('created_at', ascending: false);

      setState(() {
        _failedJobs = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _retryPrintJob(String jobId) async {
    // Prevent multiple simultaneous retries
    if (_retryingJobs.contains(jobId)) {
      return;
    }

    setState(() {
      _retryingJobs.add(jobId);
    });

    try {
      final success = await PrintRetryService.instance.retryPrintJob(jobId);

      if (success) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Print job requeued for retry'),
            backgroundColor: AppColors.success,
          ),
        );
        // Refresh the list
        _loadFailedJobs();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot retry job - job may already be active'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to retry job: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _retryingJobs.remove(jobId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Failed Print Jobs'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFailedJobs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text('Error loading failed jobs: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFailedJobs,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _failedJobs.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 64, color: AppColors.success),
                          SizedBox(height: 16),
                          Text(
                            'No failed print jobs',
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'All print jobs are processing successfully',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFailedJobs,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _failedJobs.length,
                        itemBuilder: (context, index) {
                          final job = _failedJobs[index];
                          return _buildJobCard(job);
                        },
                      ),
                    ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final jobId = job['id']?.toString().substring(0, 8) ?? 'Unknown';
    final orderId = job['order_id']?.toString().substring(0, 8) ?? 'Unknown';
    final printType = job['print_type'] ?? 'Unknown';
    final error = job['last_error'] ?? 'No error message';
    final attempts = job['print_attempts'] ?? 0;
    final createdAt = job['created_at'] != null
        ? DateTime.tryParse(job['created_at'])
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  printType == 'pos' ? Icons.receipt : Icons.local_shipping,
                  color: AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${printType.toUpperCase()} - Job $jobId',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Text(
                    '$attempts attempts',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Order ID: $orderId',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            if (createdAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Created: ${_formatDateTime(createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Error:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    error,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _retryingJobs.contains(job['id']) 
                      ? null 
                      : () => _retryPrintJob(job['id']),
                  style: TextButton.styleFrom(
                    backgroundColor: _retryingJobs.contains(job['id']) 
                        ? Colors.grey 
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _retryingJobs.contains(job['id'])
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Requeue Print'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final sast = dateTime.toUtc().add(const Duration(hours: 2));
    return '${sast.day.toString().padLeft(2, '0')}/'
           '${sast.month.toString().padLeft(2, '0')}/'
           '${sast.year} '
           '${sast.hour.toString().padLeft(2, '0')}:'
           '${sast.minute.toString().padLeft(2, '0')}';
  }
}
