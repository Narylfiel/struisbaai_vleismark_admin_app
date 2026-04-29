import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/supabase_service.dart';

/// Monitoring dashboard for print queue health and status
class PrintQueueMonitorScreen extends StatefulWidget {
  const PrintQueueMonitorScreen({super.key});

  @override
  State<PrintQueueMonitorScreen> createState() => _PrintQueueMonitorScreenState();
}

class _PrintQueueMonitorScreenState extends State<PrintQueueMonitorScreen> {
  final SupabaseClient _supabase = SupabaseService.client;
  Map<String, dynamic>? _queueStats;
  List<Map<String, dynamic>> _recentJobs = [];
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load queue statistics
      final statsResponse = await _supabase
          .from('online_order_print_queue')
          .select('print_type, printed');

      // Load recent jobs
      final jobsResponse = await _supabase
          .from('online_order_print_queue')
          .select('*')
          .order('created_at', ascending: false)
          .limit(20);

      // Load trigger stats
      final triggerResponse = await _supabase
          .rpc('get_print_queue_health_stats');

      setState(() {
        _queueStats = {
          'stats': statsResponse,
          'trigger_stats': triggerResponse,
        };
        _recentJobs = List<Map<String, dynamic>>.from(jobsResponse);
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Print Queue Monitor'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
                      Text('Error loading data: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHealthStatus(),
                        const SizedBox(height: 24),
                        _buildQueueStats(),
                        const SizedBox(height: 24),
                        _buildRecentJobs(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHealthStatus() {
    final stats = _queueStats?['stats'] as List<dynamic>? ?? [];
    
    int totalJobs = 0;
    int pendingJobs = 0;
    int printedJobs = 0;
    
    for (final stat in stats) {
      final count = stat['count'] as int? ?? 0;
      totalJobs += count;
      if (stat['printed'] == false) {
        pendingJobs += count;
      } else {
        printedJobs += count;
      }
    }

    // Determine health status
    String status = 'Healthy';
    Color statusColor = Colors.green;
    if (pendingJobs > 10) {
      status = 'Warning';
      statusColor = Colors.orange;
    } else if (pendingJobs > 20) {
      status = 'Critical';
      statusColor = Colors.red;
    }

    return Card(
      color: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status == 'Healthy' ? Icons.check_circle : 
                  status == 'Warning' ? Icons.warning : Icons.error,
                  color: statusColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Queue Status: $status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Total Jobs', '$totalJobs', Colors.blue),
                _buildStatCard('Pending', '$pendingJobs', Colors.orange),
                _buildStatCard('Printed', '$printedJobs', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueStats() {
    final stats = _queueStats?['stats'] as List<dynamic>? ?? [];
    
    return Card(
      color: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Queue Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // POS Jobs
            _buildPrintTypeStats('POS (Pick Slips)', 'pos', stats),
            const SizedBox(height: 16),
            // Delivery Jobs
            _buildPrintTypeStats('Delivery Labels', 'delivery_label', stats),
          ],
        ),
      ),
    );
  }

  Widget _buildPrintTypeStats(String title, String printType, List<dynamic> stats) {
    final typeStats = stats.where((s) => s['print_type'] == printType).toList();
    
    int total = 0;
    int pending = 0;
    int printed = 0;
    
    for (final stat in typeStats) {
      final count = stat['count'] as int? ?? 0;
      total += count;
      if (stat['printed'] == false) {
        pending += count;
      } else {
        printed += count;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildProgressBar('Pending', pending, total, Colors.orange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildProgressBar('Printed', printed, total, Colors.green),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar(String label, int value, int total, Color color) {
    final percentage = total > 0 ? (value / total * 100) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value/$total'),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentJobs() {
    return Card(
      color: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Jobs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._recentJobs.map((job) => _buildJobTile(job)),
          ],
        ),
      ),
    );
  }

  Widget _buildJobTile(Map<String, dynamic> job) {
    final createdAt = DateTime.tryParse(job['created_at'] ?? '');
    final printedAt = job['printed_at'] != null 
        ? DateTime.tryParse(job['printed_at']) 
        : null;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: job['printed'] ? Colors.green : Colors.orange,
        child: Icon(
          job['printed'] ? Icons.check : Icons.hourglass_empty,
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(
        job['print_type']?.toString().toUpperCase() ?? 'UNKNOWN',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order: ${job['order_id']?.toString().substring(0, 8) ?? 'Unknown'}...'),
          if (createdAt != null)
            Text('Created: ${_formatDateTime(createdAt)}'),
          if (printedAt != null)
            Text('Printed: ${_formatDateTime(printedAt)}', 
                 style: const TextStyle(color: Colors.green)),
        ],
      ),
      trailing: job['printed'] 
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.hourglass_empty, color: Colors.orange),
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
