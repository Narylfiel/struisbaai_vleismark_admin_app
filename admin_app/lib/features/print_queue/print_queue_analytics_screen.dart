import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/supabase_service.dart';

/// Historical Analytics for Print Queue
class PrintQueueAnalyticsScreen extends StatefulWidget {
  const PrintQueueAnalyticsScreen({super.key});

  @override
  State<PrintQueueAnalyticsScreen> createState() => _PrintQueueAnalyticsScreenState();
}

class _PrintQueueAnalyticsScreenState extends State<PrintQueueAnalyticsScreen> {
  final SupabaseClient _supabase = SupabaseService.client;
  
  // Analytics data
  List<Map<String, dynamic>> _dailyTrends = [];
  List<Map<String, dynamic>> _errorTrends = [];
  List<Map<String, dynamic>> _printTypePerformance = [];
  
  // State
  bool _isLoading = true;
  String? _error;
  int _selectedDays = 7;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _loadDailyTrends(),
        _loadErrorTrends(),
        _loadPrintTypePerformance(),
      ]);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadDailyTrends() async {
    try {
      final daysAgo = DateTime.now().subtract(Duration(days: _selectedDays)).toUtc().toIso8601String();
      
      final response = await _supabase
          .from('online_order_print_queue')
          .select('created_at, printed, print_type, last_error')
          .gte('created_at', daysAgo);

      // Process daily trends
      final dailyData = <String, Map<String, dynamic>>{};
      
      for (final item in response) {
        final date = (item['created_at'] as String).split('T')[0];
        final printed = item['printed'] as bool? ?? true;
        final printType = item['print_type'] as String? ?? 'unknown';
        final count = item['count'] as int? ?? 0;

        if (!dailyData.containsKey(date)) {
          dailyData[date] = {
            'date': date,
            'total_jobs': 0,
            'failed_jobs': 0,
            'pos_jobs': 0,
            'delivery_jobs': 0,
          };
        }

        dailyData[date]!['total_jobs'] = (dailyData[date]!['total_jobs'] as int) + count;
        
        if (printType == 'pos') {
          dailyData[date]!['pos_jobs'] = (dailyData[date]!['pos_jobs'] as int) + count;
        } else if (printType == 'delivery_label') {
          dailyData[date]!['delivery_jobs'] = (dailyData[date]!['delivery_jobs'] as int) + count;
        }
        
        if (!printed) {
          dailyData[date]!['failed_jobs'] = (dailyData[date]!['failed_jobs'] as int) + count;
        }
      }

      // Calculate success rates
      final sortedData = dailyData.values.toList()
        ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

      for (final day in sortedData) {
        final total = day['total_jobs'] as int;
        final failed = day['failed_jobs'] as int;
        day['success_rate'] = total > 0 ? ((total - failed) / total * 100) : 100.0;
      }

      setState(() {
        _dailyTrends = sortedData;
      });
    } catch (e) {
      debugPrint('[PRINT_QUEUE][ANALYTICS] Error loading daily trends: $e');
    }
  }

  Future<void> _loadErrorTrends() async {
    try {
      final daysAgo = DateTime.now().subtract(Duration(days: _selectedDays)).toUtc().toIso8601String();
      
      final response = await _supabase
          .from('online_order_print_queue')
          .select('created_at, last_error')
          .not('last_error', 'is', null)
          .gte('created_at', daysAgo)
          .order('created_at', ascending: false);

      // Process error trends by date and error type
      final errorData = <String, Map<String, int>>{};
      
      for (final item in response) {
        final date = (item['created_at'] as String).split('T')[0];
        final error = item['last_error'] as String? ?? 'Unknown error';
        final count = item['count'] as int? ?? 0;

        if (!errorData.containsKey(error)) {
          errorData[error] = {};
        }
        errorData[error]![date] = (errorData[error]![date] ?? 0) + count;
      }

      // Convert to list and sort by total count
      final sortedErrors = errorData.entries.map((entry) {
        final totalCount = entry.value.values.fold(0, (sum, count) => sum + count);
        return {
          'error': entry.key,
          'daily_counts': entry.value,
          'total_count': totalCount,
        };
      }).toList()
        ..sort((a, b) => (b['total_count'] as int).compareTo(a['total_count'] as int));

      setState(() {
        _errorTrends = sortedErrors.take(10).toList(); // Top 10 errors
      });
    } catch (e) {
      debugPrint('[PRINT_QUEUE][ANALYTICS] Error loading error trends: $e');
    }
  }

  Future<void> _loadPrintTypePerformance() async {
    try {
      final daysAgo = DateTime.now().subtract(Duration(days: _selectedDays)).toUtc().toIso8601String();
      
      final response = await _supabase
          .from('online_order_print_queue')
          .select('created_at, print_type, printed')
          .gte('created_at', daysAgo)
          .order('created_at');

      // Process print type performance by date
      final performanceData = <String, Map<String, dynamic>>{};
      
      for (final item in response) {
        final date = (item['created_at'] as String).split('T')[0];
        final printType = item['print_type'] as String? ?? 'unknown';
        final printed = item['printed'] as bool? ?? true;
        final count = item['count'] as int? ?? 0;

        if (!performanceData.containsKey(date)) {
          performanceData[date] = {
            'date': date,
            'pos': {'total': 0, 'printed': 0},
            'delivery_label': {'total': 0, 'printed': 0},
          };
        }

        if (!performanceData[date]!.containsKey(printType)) {
          performanceData[date]![printType] = {'total': 0, 'printed': 0};
        }

        performanceData[date]![printType]['total'] = (performanceData[date]![printType]['total'] as int) + count;
        if (printed) {
          performanceData[date]![printType]['printed'] = (performanceData[date]![printType]['printed'] as int) + count;
        }
      }

      // Calculate success rates
      final sortedData = performanceData.values.toList()
        ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

      for (final day in sortedData) {
        for (final printType in ['pos', 'delivery_label']) {
          if (day.containsKey(printType)) {
            final total = day[printType]['total'] as int;
            final printed = day[printType]['printed'] as int;
            day[printType]['success_rate'] = total > 0 ? (printed / total * 100) : 100.0;
          }
        }
      }

      setState(() {
        _printTypePerformance = sortedData;
      });
    } catch (e) {
      debugPrint('[PRINT_QUEUE][ANALYTICS] Error loading print type performance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Print Queue Analytics'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          DropdownButton<int>(
            value: _selectedDays,
            dropdownColor: AppColors.primary,
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            style: const TextStyle(color: Colors.white),
            items: const [
              DropdownMenuItem(value: 7, child: Text('Last 7 days', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 14, child: Text('Last 14 days', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 30, child: Text('Last 30 days', style: TextStyle(color: Colors.white))),
            ],
            onChanged: (days) {
              if (days != null) {
                setState(() {
                  _selectedDays = days;
                });
                _loadAnalytics();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDailyTrends(),
                        const SizedBox(height: 24),
                        _buildErrorTrends(),
                        const SizedBox(height: 24),
                        _buildPrintTypePerformance(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Error loading analytics: $_error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAnalytics,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTrends() {
    return Card(
      color: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Trends',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDailyTrendsChart(),
            const SizedBox(height: 16),
            _buildDailyTrendsTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTrendsChart() {
    if (_dailyTrends.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return Container(
      height: 200,
      child: _buildSimpleLineChart(
        _dailyTrends.map((day) => {
          'label': _formatDate(day['date']),
          'value': day['success_rate'] as double,
          'color': Colors.green,
        }).toList(),
        'Success Rate (%)',
      ),
    );
  }

  Widget _buildDailyTrendsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Total')),
          DataColumn(label: Text('Failed')),
          DataColumn(label: Text('Success Rate')),
        ],
        rows: _dailyTrends.map((day) => DataRow(
          cells: [
            DataCell(Text(_formatDate(day['date']))),
            DataCell(Text('${day['total_jobs']}')),
            DataCell(Text('${day['failed_jobs']}')),
            DataCell(Text(
              '${(day['success_rate'] as double).toStringAsFixed(1)}%',
              style: TextStyle(
                color: (day['success_rate'] as double) > 90 ? Colors.green :
                       (day['success_rate'] as double) > 70 ? Colors.orange : Colors.red,
              ),
            )),
          ],
        )).toList(),
      ),
    );
  }

  Widget _buildErrorTrends() {
    return Card(
      color: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Error Trends',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_errorTrends.isEmpty)
              const Text('No errors in selected period')
            else
              Column(
                children: _errorTrends.map((error) => _buildErrorCard(error)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(Map<String, dynamic> error) {
    final errorText = error['error'] as String;
    final totalCount = error['total_count'] as int;
    final dailyCounts = error['daily_counts'] as Map<String, int>;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    errorText.length > 50 ? '${errorText.substring(0, 50)}...' : errorText,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalCount occurrences',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildSimpleBarChart(
              dailyCounts.entries.map((entry) => {
                'label': _formatDate(entry.key),
                'value': entry.value.toDouble(),
                'color': Colors.red,
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrintTypePerformance() {
    return Card(
      color: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Print Type Performance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPrintTypeChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildPrintTypeChart() {
    if (_printTypePerformance.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return Container(
      height: 250,
      child: _buildMultiLineChart(
        _printTypePerformance.map((day) => {
          'label': _formatDate(day['date']),
          'pos_rate': day.containsKey('pos') ? day['pos']['success_rate'] as double : null,
          'delivery_rate': day.containsKey('delivery_label') ? day['delivery_label']['success_rate'] as double : null,
        }).toList(),
      ),
    );
  }

  Widget _buildSimpleLineChart(List<Map<String, dynamic>> data, String title) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxValue = data.map((d) => d['value'] as double).reduce((a, b) => a > b ? a : b);
    final chartHeight = 150.0;
    final chartWidth = MediaQuery.of(context).size.width - 64; // Account for padding

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: chartHeight,
          width: chartWidth,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: CustomPaint(
            painter: SimpleLineChartPainter(data, maxValue, chartHeight, chartWidth),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleBarChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxValue = data.map((d) => d['value'] as double).reduce((a, b) => a > b ? a : b);
    final chartHeight = 60.0;
    final chartWidth = MediaQuery.of(context).size.width - 64;

    return Container(
      height: chartHeight,
      width: chartWidth,
      child: CustomPaint(
        painter: SimpleBarChartPainter(data, maxValue, chartHeight, chartWidth),
      ),
    );
  }

  Widget _buildMultiLineChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final chartHeight = 200.0;
    final chartWidth = MediaQuery.of(context).size.width - 64;

    return Container(
      height: chartHeight,
      width: chartWidth,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: CustomPaint(
        painter: MultiLineChartPainter(data, chartHeight, chartWidth),
      ),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}';
  }
}

// Custom painters for simple charts
class SimpleLineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double maxValue;
  final double chartHeight;
  final double chartWidth;

  SimpleLineChartPainter(this.data, this.maxValue, this.chartHeight, this.chartWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final stepX = chartWidth / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = chartHeight - ((data[i]['value'] as double) / maxValue) * chartHeight;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw point
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = Colors.blue);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SimpleBarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double maxValue;
  final double chartHeight;
  final double chartWidth;

  SimpleBarChartPainter(this.data, this.maxValue, this.chartHeight, this.chartWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = chartWidth / data.length * 0.8;
    final stepX = chartWidth / data.length;

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX + (stepX - barWidth) / 2;
      final barHeight = ((data[i]['value'] as double) / maxValue) * chartHeight;
      final y = chartHeight - barHeight;

      canvas.drawRect(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        Paint()..color = (data[i]['color'] as Color? ?? Colors.red),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MultiLineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double chartHeight;
  final double chartWidth;

  MultiLineChartPainter(this.data, this.chartHeight, this.chartWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final stepX = chartWidth / (data.length - 1);

    // Draw POS line
    _drawLine(canvas, data.map((d) => d['pos_rate'] as double?).toList(), stepX, Colors.blue);
    
    // Draw Delivery line
    _drawLine(canvas, data.map((d) => d['delivery_rate'] as double?).toList(), stepX, Colors.orange);

    // Draw legend
    _drawLegend(canvas);
  }

  void _drawLine(Canvas canvas, List<double?> values, double stepX, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool started = false;

    for (int i = 0; i < values.length; i++) {
      final value = values[i];
      if (value == null) continue;

      final x = i * stepX;
      final y = chartHeight - (value / 100.0) * chartHeight;

      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 3, Paint()..color = color);
    }

    canvas.drawPath(path, paint);
  }

  void _drawLegend(Canvas canvas) {
    const legendY = 20.0;
    
    // POS legend
    canvas.drawCircle(const Offset(20, legendY), 4, Paint()..color = Colors.blue);
    canvas.drawText(
      const TextSpan(
        text: ' POS',
        style: TextStyle(color: Colors.blue, fontSize: 12),
      ),
      const Offset(30, legendY - 6),
    );

    // Delivery legend
    canvas.drawCircle(const Offset(80, legendY), 4, Paint()..color = Colors.orange);
    canvas.drawText(
      const TextSpan(
        text: ' Delivery',
        style: TextStyle(color: Colors.orange, fontSize: 12),
      ),
      const Offset(90, legendY - 6),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Extension for canvas text drawing
extension CanvasText on Canvas {
  void drawText(TextSpan textSpan, Offset offset) {
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(this, offset);
  }
}
