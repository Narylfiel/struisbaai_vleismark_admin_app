import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import '../admin/services/print_retry_service.dart';
import '../admin/services/print_automation_service.dart';
import 'print_queue_analytics_screen.dart';

/// Alert levels for print queue monitoring
enum AlertLevel {
  info,
  warning,
  critical,
}

/// Alert data structure
class Alert {
  final AlertLevel level;
  final String message;
  final String type;
  final DateTime timestamp;

  Alert({
    required this.level,
    required this.message,
    required this.type,
  }) : timestamp = DateTime.now();
}

/// Real-time Print Queue Monitoring Dashboard
class PrintQueueMonitorScreen extends StatefulWidget {
  const PrintQueueMonitorScreen({super.key});

  @override
  State<PrintQueueMonitorScreen> createState() => _PrintQueueMonitorScreenState();
}

class _PrintQueueMonitorScreenState extends State<PrintQueueMonitorScreen> {
  final SupabaseClient _supabase = SupabaseService.client;
  
  // Data
  Map<String, dynamic> _queueSummary = {};
  List<Map<String, dynamic>> _recentJobs = [];
  List<Map<String, dynamic>> _failedJobs = [];
  
  // Root cause analysis data
  Map<String, int> _failureBreakdown = {};
  Map<String, dynamic> _timeAnalysis = {};
  Map<String, dynamic> _printTypeHealth = {};
  List<Map<String, dynamic>> _stuckJobs = [];
  List<String> _systemInsights = [];
  
  // Automation data
  Map<String, dynamic> _automationMetrics = {};
  List<String> _priorityEscalations = [];
  bool _automationEnabled = true;
  
  // State
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  bool _isPolling = false;
  
  // Health indicators
  String _healthStatus = 'healthy';
  Color _healthColor = Colors.green;
  List<String> _healthIssues = [];
  
  // Alert state tracking
  Alert? _currentAlert;
  String? _lastAlertState;
  DateTime? _lastAlertTime;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    super.dispose();
  }

  void _startAutoRefresh() {
    if (_isPolling) return;
    _isPolling = true;
    _autoRefreshLoop();
  }

  void _stopAutoRefresh() {
    _isPolling = false;
  }

  Future<void> _autoRefreshLoop() async {
    while (_isPolling) {
      await Future.delayed(const Duration(seconds: 10));
      if (_isPolling && mounted) {
        await _loadData();
      }
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      if (!_isRefreshing) _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _loadQueueSummary(),
        _loadRecentJobs(),
        _loadFailedJobs(),
        _loadFailureBreakdown(),
        _loadTimeAnalysis(),
        _loadPrintTypeHealth(),
        _loadStuckJobs(),
      ]);
      
      _calculateHealthIndicators();
      _generateSystemInsights();
      
      // Process automation if enabled
      if (_automationEnabled) {
        await _processAutomation();
      }
      
      debugPrint('[PRINT_QUEUE][MONITOR] refreshed');
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _loadQueueSummary() async {
    final now = DateTime.now().toUtc().toIso8601String();
    
    // Get queue summary
    final response = await _supabase
        .from('online_order_print_queue')
        .select('print_type, printed, hold_until, last_error');

    // Process summary data
    final summary = {
      'total_pending': 0,
      'pos_pending': 0,
      'delivery_pending': 0,
      'held_jobs': 0,
      'failed_jobs': 0,
      'total_jobs': 0,
    };

    for (final item in response) {
      final count = item['count'] as int? ?? 0;
      final printType = item['print_type'] as String?;
      final printed = item['printed'] as bool? ?? true;
      final holdUntil = item['hold_until'] as String?;
      final hasError = item['last_error'] != null;

      summary['total_jobs'] = (summary['total_jobs'] as int) + count;

      if (!printed) {
        summary['total_pending'] = (summary['total_pending'] as int) + count;
        
        if (printType == 'pos') {
          summary['pos_pending'] = (summary['pos_pending'] as int) + count;
        } else if (printType == 'delivery_label') {
          summary['delivery_pending'] = (summary['delivery_pending'] as int) + count;
        }

        if (holdUntil != null && holdUntil.compareTo(now) > 0) {
          summary['held_jobs'] = (summary['held_jobs'] as int) + count;
        }
      }

      if (hasError) {
        summary['failed_jobs'] = (summary['failed_jobs'] as int) + count;
      }
    }

    setState(() {
      _queueSummary = summary;
    });
  }

  Future<void> _loadRecentJobs() async {
    final response = await _supabase
        .from('online_order_print_queue')
        .select('*')
        .order('created_at', ascending: false)
        .limit(20);

    setState(() {
      _recentJobs = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _loadFailedJobs() async {
    final response = await _supabase
        .from('online_order_print_queue')
        .select('*')
        .not('last_error', 'is', null)
        .order('created_at', ascending: false)
        .limit(10);

    setState(() {
      _failedJobs = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _loadFailureBreakdown() async {
    try {
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1)).toUtc().toIso8601String();
      
      final response = await _supabase
          .from('online_order_print_queue')
          .select('print_type, last_error')
          .not('last_error', 'is', null)
          .gte('created_at', oneHourAgo);

      final breakdown = <String, int>{};
      for (final item in response) {
        final error = item['last_error'] as String? ?? 'Unknown error';
        final count = item['count'] as int? ?? 0;
        breakdown[error] = (breakdown[error] ?? 0) + count;
      }

      setState(() {
        _failureBreakdown = breakdown;
      });
    } catch (e) {
      debugPrint('[PRINT_QUEUE][MONITOR] Error loading failure breakdown: $e');
    }
  }

  Future<void> _loadTimeAnalysis() async {
    try {
      final now = DateTime.now().toUtc();
      final fiveMinAgo = now.subtract(const Duration(minutes: 5)).toIso8601String();
      final fifteenMinAgo = now.subtract(const Duration(minutes: 15)).toIso8601String();
      final oneHourAgo = now.subtract(const Duration(hours: 1)).toIso8601String();

      final response = await _supabase
          .from('online_order_print_queue')
          .select('created_at, last_error')
          .not('last_error', 'is', null)
          .gte('created_at', oneHourAgo);

      int last5Min = 0;
      int last15Min = 0;
      int last60Min = 0;

      for (final job in response) {
        final createdAt = DateTime.tryParse(job['created_at'] ?? '');
        if (createdAt == null) continue;

        last60Min++;
        if (createdAt.isAfter(DateTime.parse(fifteenMinAgo))) {
          last15Min++;
        }
        if (createdAt.isAfter(DateTime.parse(fiveMinAgo))) {
          last5Min++;
        }
      }

      // Detect spike
      final averagePer5Min = last60Min / 12.0; // 60 minutes / 5 minute intervals
      final spikeDetected = last5Min > (averagePer5Min * 2);

      setState(() {
        _timeAnalysis = {
          'last_5_min': last5Min,
          'last_15_min': last15Min,
          'last_60_min': last60Min,
          'spike_detected': spikeDetected,
        };
      });
    } catch (e) {
      debugPrint('[PRINT_QUEUE][MONITOR] Error loading time analysis: $e');
    }
  }

  Future<void> _loadPrintTypeHealth() async {
    try {
      final response = await _supabase
          .from('online_order_print_queue')
          .select('print_type, printed')
          .gte('created_at', DateTime.now().subtract(const Duration(hours: 1)).toUtc().toIso8601String());

      final health = <String, dynamic>{};
      
      for (final item in response) {
        final printType = item['print_type'] as String? ?? 'unknown';
        final printed = item['printed'] as bool? ?? true;
        final count = item['count'] as int? ?? 0;

        if (!health.containsKey(printType)) {
          health[printType] = {'total': 0, 'printed': 0, 'failed': 0};
        }

        health[printType]['total'] = (health[printType]['total'] as int) + count;
        if (printed) {
          health[printType]['printed'] = (health[printType]['printed'] as int) + count;
        } else {
          health[printType]['failed'] = (health[printType]['failed'] as int) + count;
        }
      }

      // Calculate success rates
      for (final printType in health.keys) {
        final total = health[printType]['total'] as int;
        final printed = health[printType]['printed'] as int;
        health[printType]['success_rate'] = total > 0 ? (printed / total * 100) : 100.0;
      }

      setState(() {
        _printTypeHealth = health;
      });
    } catch (e) {
      debugPrint('[PRINT_QUEUE][MONITOR] Error loading print type health: $e');
    }
  }

  Future<void> _loadStuckJobs() async {
    try {
      final response = await _supabase
          .from('online_order_print_queue')
          .select('*')
          .eq('printed', false)
          .lt('created_at', DateTime.now().subtract(const Duration(minutes: 10)).toUtc().toIso8601String())
          .order('created_at', ascending: true)
          .limit(10);

      setState(() {
        _stuckJobs = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('[PRINT_QUEUE][MONITOR] Error loading stuck jobs: $e');
    }
  }

  void _calculateHealthIndicators() {
    final issues = <String>[];
    Color healthColor = Colors.green;
    String healthStatus = 'healthy';

    // Check backlog
    final pending = _queueSummary['total_pending'] as int? ?? 0;
    Alert? backlogAlert;
    if (pending > 20) {
      issues.add('High queue backlog ($pending jobs)');
      healthColor = Colors.orange;
      healthStatus = 'warning';
      backlogAlert = Alert(
        level: AlertLevel.warning,
        message: '⚠ High queue backlog detected ($pending jobs)',
        type: 'BACKLOG_HIGH',
      );
    }

    // Check failure rate
    final total = _queueSummary['total_jobs'] as int? ?? 1;
    final failed = _queueSummary['failed_jobs'] as int? ?? 0;
    final failureRate = failed / total;
    Alert? failureRateAlert;
    if (failureRate > 0.05) {
      issues.add('High failure rate (${(failureRate * 100).toStringAsFixed(1)}%)');
      healthColor = Colors.red;
      healthStatus = 'critical';
      failureRateAlert = Alert(
        level: AlertLevel.critical,
        message: '❌ High failure rate detected (${(failureRate * 100).toStringAsFixed(1)}%)',
        type: 'FAILURE_RATE_HIGH',
      );
    }

    // Check stuck jobs
    final stuckJobs = _recentJobs.where((job) {
      if (job['printed'] == true) return false;
      final createdAt = DateTime.tryParse(job['created_at'] ?? '');
      if (createdAt == null) return false;
      return DateTime.now().difference(createdAt).inMinutes > 10;
    }).length;

    Alert? stuckJobsAlert;
    if (stuckJobs > 0) {
      issues.add('$stuckJobs jobs stuck for >10 minutes');
      healthColor = Colors.red;
      healthStatus = 'critical';
      stuckJobsAlert = Alert(
        level: AlertLevel.critical,
        message: '⏱ Stuck jobs detected ($stuckJobs jobs)',
        type: 'STUCK_JOB_DETECTED',
      );
    }

    // Determine highest priority alert
    Alert? highestPriorityAlert;
    if (failureRateAlert != null) {
      highestPriorityAlert = failureRateAlert;
    } else if (stuckJobsAlert != null) {
      highestPriorityAlert = stuckJobsAlert;
    } else if (backlogAlert != null) {
      highestPriorityAlert = backlogAlert;
    }

    // Process alert with throttling
    _processAlert(highestPriorityAlert);

    setState(() {
      _healthIssues = issues;
      _healthColor = healthColor;
      _healthStatus = healthStatus;
    });
  }

  void _processAlert(Alert? newAlert) {
    if (newAlert == null) {
      // Clear alert if no issues
      setState(() {
        _currentAlert = null;
      });
      return;
    }

    final now = DateTime.now();
    final alertState = '${newAlert.type}_${newAlert.level}';

    // Check throttling: minimum 2 minutes between same alerts
    if (_lastAlertState == alertState && 
        _lastAlertTime != null && 
        now.difference(_lastAlertTime!).inMinutes < 2) {
      return; // Skip due to throttling
    }

    // Log alert
    debugPrint('[PRINT_QUEUE][ALERT] ${newAlert.type}');

    // Show snackbar notification for critical alerts
    if (newAlert.level == AlertLevel.critical && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newAlert.message),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
        ),
      );
    }

    setState(() {
      _currentAlert = newAlert;
      _lastAlertState = alertState;
      _lastAlertTime = now;
    });
  }

  void _generateSystemInsights() {
    final insights = <String>[];

    // Failure breakdown insights
    if (_failureBreakdown.isNotEmpty) {
      final mostCommonError = _failureBreakdown.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      insights.add('Most common failure: "${mostCommonError.key}" (${mostCommonError.value} jobs)');
    }

    // Print type health insights
    if (_printTypeHealth.isNotEmpty) {
      final posHealth = _printTypeHealth['pos'];
      final deliveryHealth = _printTypeHealth['delivery_label'];
      
      if (posHealth != null && deliveryHealth != null) {
        final posRate = (posHealth['success_rate'] as double?) ?? 100.0;
        final deliveryRate = (deliveryHealth['success_rate'] as double?) ?? 100.0;
        
        if (deliveryRate < posRate - 10) {
          insights.add('Delivery labels failing more than POS prints (${deliveryRate.toStringAsFixed(1)}% vs ${posRate.toStringAsFixed(1)}%)');
        } else if (posRate < deliveryRate - 10) {
          insights.add('POS prints failing more than delivery labels (${posRate.toStringAsFixed(1)}% vs ${deliveryRate.toStringAsFixed(1)}%)');
        }
      }
    }

    // Time analysis insights
    if (_timeAnalysis['spike_detected'] == true) {
      insights.add('Failure spike detected in last 5 minutes');
    }

    final last5Min = _timeAnalysis['last_5_min'] as int? ?? 0;
    if (last5Min > 5) {
      insights.add('High failure rate in last 5 minutes ($last5Min jobs)');
    }

    // Stuck jobs insights
    if (_stuckJobs.isNotEmpty) {
      final longestStuck = _stuckJobs.first;
      final createdAt = DateTime.tryParse(longestStuck['created_at'] ?? '');
      if (createdAt != null) {
        final stuckDuration = DateTime.now().difference(createdAt);
        if (stuckDuration.inMinutes > 15) {
          insights.add('Jobs stuck for more than 15 minutes');
        }
      }
    }

    // Queue insights
    final totalPending = _queueSummary['total_pending'] as int? ?? 0;
    if (totalPending > 50) {
      insights.add('Very high queue backlog - consider adding more printers');
    }

    // Automation insights
    if (_automationMetrics.isNotEmpty) {
      final autoRetriesSucceeded = _automationMetrics['auto_retries_succeeded'] as int? ?? 0;
      if (autoRetriesSucceeded > 0) {
        insights.add('System auto-retried $autoRetriesSucceeded jobs successfully');
      }

      final successRate = _automationMetrics['auto_retry_success_rate'] as String? ?? '0%';
      if (autoRetriesSucceeded > 0 && successRate != '0%') {
        insights.add('Auto-retry success rate: $successRate');
      }
    }

    if (_priorityEscalations.isNotEmpty) {
      insights.add('${_priorityEscalations.length} jobs escalated to priority (stuck >15min)');
    }

    if (_automationMetrics['backlog_throttling_active'] == true) {
      insights.add('System throttling active due to high backlog');
    }

    setState(() {
      _systemInsights = insights;
    });
  }

  Future<void> _processAutomation() async {
    try {
      final automationService = PrintAutomationService.instance;
      
      // Process auto-retries for failed jobs
      final retryCount = await automationService.processFailedJobs();
      
      // Check for stuck jobs and escalate
      final escalations = await automationService.checkStuckJobs();
      
      // Check backlog throttling
      final pendingCount = _queueSummary['total_pending'] as int? ?? 0;
      await automationService.checkBacklogThrottling(pendingCount);
      
      // Get automation metrics
      final metrics = automationService.getAutomationMetrics();
      
      setState(() {
        _automationMetrics = metrics;
        _priorityEscalations = escalations;
      });
      
      if (retryCount > 0) {
        debugPrint('[PRINT_QUEUE][MONITOR] Automation: $retryCount auto-retries processed');
      }
      
      if (escalations.isNotEmpty) {
        debugPrint('[PRINT_QUEUE][MONITOR] Automation: ${escalations.length} priority escalations');
      }
    } catch (e) {
      debugPrint('[PRINT_QUEUE][MONITOR] Automation error: $e');
    }
  }

  Future<void> _retryFailedJob(String jobId) async {
    try {
      final success = await PrintRetryService.instance.retryPrintJob(jobId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Job requeued for retry' : 'Failed to retry job'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
        
        // Refresh data
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrintQueueAnalyticsScreen(),
                ),
              );
            },
            tooltip: 'View Analytics',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : () {
              setState(() => _isRefreshing = true);
              _loadData();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _isRefreshing = true);
          await _loadData();
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorView()
                : Column(
                    children: [
                      // Alert Banner
                      if (_currentAlert != null) _buildAlertBanner(),
                      
                      // Main Content
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHealthIndicator(),
                              const SizedBox(height: 16),
                              _buildSystemInsights(),
                              const SizedBox(height: 16),
                              _buildAutomationStatus(),
                              const SizedBox(height: 16),
                              _buildQueueSummary(),
                              const SizedBox(height: 24),
                              _buildRootCauseAnalysis(),
                              const SizedBox(height: 24),
                              _buildRecentJobs(),
                              const SizedBox(height: 24),
                              _buildFailedJobs(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildAlertBanner() {
    if (_currentAlert == null) return const SizedBox.shrink();
    
    Color backgroundColor;
    Color textColor;
    IconData icon;
    
    switch (_currentAlert!.level) {
      case AlertLevel.info:
        backgroundColor = Colors.blue;
        textColor = Colors.white;
        icon = Icons.info;
        break;
      case AlertLevel.warning:
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        icon = Icons.warning;
        break;
      case AlertLevel.critical:
        backgroundColor = Colors.red;
        textColor = Colors.white;
        icon = Icons.error;
        break;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: backgroundColor,
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _currentAlert!.message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: textColor, size: 20),
            onPressed: () {
              setState(() {
                _currentAlert = null;
              });
            },
            tooltip: 'Dismiss alert',
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
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
    );
  }

  Widget _buildHealthIndicator() {
    return Card(
      color: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _healthStatus == 'healthy' ? Icons.check_circle :
              _healthStatus == 'warning' ? Icons.warning : Icons.error,
              color: _healthColor,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Status: ${_healthStatus.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _healthColor,
                    ),
                  ),
                  if (_healthIssues.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ..._healthIssues.map((issue) => Text(
                      '• $issue',
                      style: TextStyle(
                        fontSize: 12,
                        color: _healthColor,
                      ),
                    )),
                  ] else ...[
                    const SizedBox(height: 4),
                    const Text(
                      'All systems operational',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInsights() {
    if (_systemInsights.isEmpty) return const SizedBox.shrink();

    return Card(
      color: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text(
                  'System Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._systemInsights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 8, right: 8),
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      insight,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAutomationStatus() {
    if (!_automationEnabled) return const SizedBox.shrink();

    final autoRetriesSucceeded = _automationMetrics['auto_retries_succeeded'] as int? ?? 0;
    final autoRetrySuccessRate = _automationMetrics['auto_retry_success_rate'] as String? ?? '0%';
    final priorityEscalations = _priorityEscalations.length;
    final throttlingActive = _automationMetrics['backlog_throttling_active'] as bool? ?? false;

    return Card(
      color: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.smart_toy, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Automation Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _automationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _automationEnabled = value;
                    });
                  },
                  activeThumbColor: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAutomationMetric(
                    'Auto-Retries',
                    '$autoRetriesSucceeded',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAutomationMetric(
                    'Success Rate',
                    autoRetrySuccessRate,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAutomationMetric(
                    'Priority Jobs',
                    '$priorityEscalations',
                    priorityEscalations > 0 ? Colors.orange : Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAutomationMetric(
                    'Throttling',
                    throttlingActive ? 'Active' : 'Normal',
                    throttlingActive ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutomationMetric(String label, String value, Color color) {
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
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRootCauseAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Root Cause Analysis',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Failure Breakdown
            Expanded(child: _buildFailureBreakdown()),
            const SizedBox(width: 16),
            // Time Analysis
            Expanded(child: _buildTimeAnalysis()),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Print Type Health
            Expanded(child: _buildPrintTypeHealth()),
            const SizedBox(width: 16),
            // Stuck Jobs
            Expanded(child: _buildStuckJobsSection()),
          ],
        ),
      ],
    );
  }

  Widget _buildFailureBreakdown() {
    return Card(
      color: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Failure Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_failureBreakdown.isEmpty)
              const Text('No failures in last hour')
            else
              ..._failureBreakdown.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key.length > 30 
                            ? '${entry.key.substring(0, 30)}...'
                            : entry.key,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeAnalysis() {
    final last5Min = _timeAnalysis['last_5_min'] as int? ?? 0;
    final last15Min = _timeAnalysis['last_15_min'] as int? ?? 0;
    final last60Min = _timeAnalysis['last_60_min'] as int? ?? 0;
    final spikeDetected = _timeAnalysis['spike_detected'] as bool? ?? false;

    return Card(
      color: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Analysis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildTimeRow('Last 5 min', last5Min, spikeDetected),
            _buildTimeRow('Last 15 min', last15Min, false),
            _buildTimeRow('Last 60 min', last60Min, false),
            if (spikeDetected) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '⚠ Spike detected',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow(String label, int value, bool isSpike) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          Row(
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSpike ? Colors.orange : null,
                ),
              ),
              if (isSpike) ...[
                const SizedBox(width: 4),
                const Icon(Icons.trending_up, size: 12, color: Colors.orange),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrintTypeHealth() {
    return Card(
      color: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Print Type Health',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._printTypeHealth.entries.map((entry) {
              final type = entry.key;
              final data = entry.value as Map<String, dynamic>;
              final successRate = (data['success_rate'] as double?) ?? 100.0;
              final total = (data['total'] as int?) ?? 0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Success Rate',
                          style: TextStyle(fontSize: 11),
                        ),
                        Text(
                          '${successRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: successRate > 90 ? Colors.green : 
                                   successRate > 70 ? Colors.orange : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Total: $total jobs',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStuckJobsSection() {
    return Card(
      color: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stuck Jobs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_stuckJobs.isEmpty)
              const Text('No stuck jobs', style: TextStyle(fontSize: 12))
            else
              ..._stuckJobs.take(3).map((job) {
                final orderId = job['order_id']?.toString().substring(0, 8) ?? 'Unknown';
                final createdAt = DateTime.tryParse(job['created_at'] ?? '');
                final stuckDuration = createdAt != null 
                    ? DateTime.now().difference(createdAt)
                    : Duration.zero;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 12, color: Colors.red),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$orderId - ${stuckDuration.inMinutes}m',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            if (_stuckJobs.length > 3)
              Text(
                '+${_stuckJobs.length - 3} more',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Queue Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildSummaryCard('Pending Jobs', '${_queueSummary['total_pending'] ?? 0}', Colors.blue),
            _buildSummaryCard('Delivery Labels', '${_queueSummary['delivery_pending'] ?? 0}', Colors.purple),
            _buildSummaryCard('POS Jobs', '${_queueSummary['pos_pending'] ?? 0}', Colors.orange),
            _buildSummaryCard('Held Jobs', '${_queueSummary['held_jobs'] ?? 0}', Colors.grey),
            _buildSummaryCard('Failed Jobs', '${_queueSummary['failed_jobs'] ?? 0}', Colors.red),
            _buildSummaryCard('Total Jobs', '${_queueSummary['total_jobs'] ?? 0}', Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      color: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentJobs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Jobs (Last 20)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: AppColors.cardBg,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 2, child: Text('Order ID', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(flex: 3, child: Text('Created', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              // Jobs
              ..._recentJobs.map((job) => _buildRecentJobRow(job)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentJobRow(Map<String, dynamic> job) {
    final orderId = job['order_id']?.toString().substring(0, 8) ?? 'Unknown';
    final printType = job['print_type'] ?? 'Unknown';
    final printed = job['printed'] as bool? ?? false;
    final createdAt = job['created_at'] != null
        ? DateTime.tryParse(job['created_at'])
        : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(orderId)),
          Expanded(flex: 2, child: Text(printType.toString().toUpperCase())),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: printed ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                printed ? 'Printed' : 'Pending',
                style: TextStyle(
                  fontSize: 12,
                  color: printed ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              createdAt != null ? _formatDateTime(createdAt) : 'Unknown',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedJobs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Failed Jobs (Last 10)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._failedJobs.map((job) => _buildFailedJobCard(job)),
      ],
    );
  }

  Widget _buildFailedJobCard(Map<String, dynamic> job) {
    final jobId = job['id']?.toString().substring(0, 8) ?? 'Unknown';
    final error = job['last_error'] ?? 'No error message';
    final attempts = job['print_attempts'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Job $jobId',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
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
              error,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _retryFailedJob(job['id']),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry Job'),
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
