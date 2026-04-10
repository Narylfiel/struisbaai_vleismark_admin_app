/// ═══════════════════════════════════════════════════════════════════════════
/// SHRINKAGE DETECTION INTEGRATION EXAMPLE
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// This file demonstrates how to use the ShrinkageDetectionService
/// in the admin app for theft detection and operational monitoring.
/// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'services/shrinkage_detection_service.dart';

/// Example 1: Daily shrinkage report
Future<void> showDailyShrinkageReport(BuildContext context) async {
  final service = ShrinkageDetectionService();
  
  // Detect yesterday's shrinkage
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  final summary = await service.detectDaily(yesterday);
  
  // Show results
  print('📊 Daily Shrinkage Report (${yesterday.toString().split(" ")[0]})');
  print('Total Shrinkage: ${summary.totalShrinkageQty.toStringAsFixed(3)} kg');
  print('Total Value Lost: R${summary.totalShrinkageValue.toStringAsFixed(2)}');
  print('Warnings: ${summary.warningCount} | Critical: ${summary.criticalCount}');
  
  // Show top 10 worst offenders
  final worst = summary.topByQuantity(10);
  for (final product in worst) {
    if (product.status == ShrinkageStatus.normal) continue;
    
    print('🔴 ${product.productName}: '
        '${product.shrinkageQty.toStringAsFixed(3)} kg '
        '(${product.shrinkagePercent.toStringAsFixed(1)}%) - '
        '${product.status.name.toUpperCase()}');
  }
}

/// Example 2: Weekly rolling window for trend analysis
Future<void> showWeeklyShrinkageReport() async {
  final service = ShrinkageDetectionService();
  
  // Last 7 days rolling window
  final summary = await service.detectRollingWindow(7);
  
  print('📈 7-Day Rolling Shrinkage Report');
  print('Period: ${summary.windowStart.toString().split(" ")[0]} to '
      '${summary.windowEnd.toString().split(" ")[0]}');
  print('Total Loss: ${summary.totalShrinkageQty.toStringAsFixed(3)} kg '
      '(R${summary.totalShrinkageValue.toStringAsFixed(2)})');
  
  // Top 10 by monetary value (money lost)
  final mostExpensive = summary.topByValue(10);
  print('\n💰 Top Losses by Value:');
  for (final product in mostExpensive.take(5)) {
    print('  ${product.productName}: '
        'R${product.shrinkageValue.toStringAsFixed(2)} '
        '(${product.shrinkageQty.toStringAsFixed(3)} kg)');
  }
}

/// Example 3: Week-over-week comparison
Future<void> showWeekOverWeekComparison() async {
  final service = ShrinkageDetectionService();
  
  final comparison = await service.detectWeekOverWeek();
  
  print('📅 Week-over-Week Comparison');
  print('Products with increased shrinkage: ${comparison.products.length}');
  
  for (final product in comparison.products.take(10)) {
    final direction = product.shrinkageQty > 0 ? '↑' : '↓';
    print('  $direction ${product.productName}: '
        '${product.shrinkageQty.toStringAsFixed(3)} kg change');
  }
}

/// Example 4: Real-time anomaly detection
Future<void> checkForAnomalies() async {
  final service = ShrinkageDetectionService();
  
  // Quick check for today's issues
  final anomalies = await service.getTodayAnomalies(
    absoluteThreshold: 0.3,  // 300g threshold
    percentThreshold: 5.0,   // 5% threshold
  );
  
  if (anomalies.isEmpty) {
    print('✅ No shrinkage anomalies detected today');
    return;
  }
  
  // Alert on critical issues
  final critical = anomalies.where((a) => a.status == ShrinkageStatus.critical);
  if (critical.isNotEmpty) {
    print('🚨 CRITICAL SHRINKAGE DETECTED:');
    for (final issue in critical) {
      print('  ${issue.productName}: '
          '${issue.shrinkageQty.toStringAsFixed(3)} kg missing '
          '(R${issue.shrinkageValue.toStringAsFixed(2)})');
    }
  }
  
  // Log warnings
  final warnings = anomalies.where((a) => a.status == ShrinkageStatus.warning);
  if (warnings.isNotEmpty) {
    print('⚠️  Warnings:');
    for (final issue in warnings) {
      print('  ${issue.productName}: '
          '${issue.shrinkageQty.toStringAsFixed(3)} kg '
          '(${issue.shrinkagePercent.toStringAsFixed(1)}%)');
    }
  }
}

/// Example 5: Trending issues (increasing over time)
Future<void> showTrendingIssues() async {
  final service = ShrinkageDetectionService();
  
  final trends = await service.getTrendingIssues(7);
  
  print('📈 Trending Shrinkage Issues (increasing):');
  for (final trend in trends.take(10)) {
    final product = trend['product'] as Map<String, dynamic>;
    final change = trend['change_qty'] as double;
    
    print('  📊 ${product['product_name']}: '
        '+${change.toStringAsFixed(3)} kg since yesterday');
  }
}

/// Example 6: Integration with existing shrinkage screen
/*
In your shrinkage_screen.dart or analytics dashboard:

class ShrinkageSection extends StatelessWidget {
  final ShrinkageDetectionService _service = ShrinkageDetectionService();
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ShrinkageSummary>(
      future: _service.detectRollingWindow(7),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        
        final summary = snapshot.data!;
        final anomalies = summary.anomalies;
        
        return Column(
          children: [
            // Summary card
            SummaryCard(
              title: '7-Day Shrinkage',
              totalLoss: summary.totalShrinkageQty,
              totalValue: summary.totalShrinkageValue,
              warningCount: summary.warningCount,
              criticalCount: summary.criticalCount,
            ),
            
            // Anomalies list
            if (anomalies.isNotEmpty)
              AnomalyList(products: anomalies.take(10).toList()),
            
            if (anomalies.isEmpty)
              Text('✅ No shrinkage issues detected'),
          ],
        );
      },
    );
  }
}

class AnomalyList extends StatelessWidget {
  final List<ProductShrinkage> products;
  
  AnomalyList({required this.products});
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        return ListTile(
          leading: _statusIcon(p.status),
          title: Text(p.productName),
          subtitle: Text('${p.shrinkageQty.toStringAsFixed(3)} kg missing'),
          trailing: Text(
            'R${p.shrinkageValue.toStringAsFixed(2)}',
            style: TextStyle(
              color: p.status == ShrinkageStatus.critical 
                  ? Colors.red 
                  : Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
  
  Widget _statusIcon(ShrinkageStatus status) {
    switch (status) {
      case ShrinkageStatus.critical:
        return Icon(Icons.error, color: Colors.red);
      case ShrinkageStatus.warning:
        return Icon(Icons.warning, color: Colors.orange);
      default:
        return Icon(Icons.check_circle, color: Colors.green);
    }
  }
}
*/

/// ═══════════════════════════════════════════════════════════════════════════
/// RECOMMENDED DASHBOARD WIDGET
/// ═══════════════════════════════════════════════════════════════════════════

class ShrinkageDashboard extends StatefulWidget {
  @override
  _ShrinkageDashboardState createState() => _ShrinkageDashboardState();
}

class _ShrinkageDashboardState extends State<ShrinkageDashboard> {
  final ShrinkageDetectionService _service = ShrinkageDetectionService();
  ShrinkageSummary? _weeklyData;
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    final data = await _service.detectRollingWindow(7);
    setState(() {
      _weeklyData = data;
      _loading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_loading) return Center(child: CircularProgressIndicator());
    if (_weeklyData == null) return Text('Failed to load');
    
    final anomalies = _weeklyData!.anomalies;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Operational Shrinkage (7 Days)',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _loadData,
                ),
              ],
            ),
            
            Divider(),
            
            // Summary metrics
            Row(
              children: [
                _MetricCard(
                  label: 'Total Loss',
                  value: '${_weeklyData!.totalShrinkageQty.toStringAsFixed(2)} kg',
                  color: Colors.red,
                ),
                _MetricCard(
                  label: 'Value Lost',
                  value: 'R${_weeklyData!.totalShrinkageValue.toStringAsFixed(0)}',
                  color: Colors.orange,
                ),
                _MetricCard(
                  label: 'Issues',
                  value: '${_weeklyData!.warningCount + _weeklyData!.criticalCount}',
                  color: _weeklyData!.criticalCount > 0 ? Colors.red : Colors.orange,
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Anomalies or all-clear
            if (anomalies.isEmpty)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('No shrinkage anomalies detected'),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Issues (by quantity)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  ..._weeklyData!.topByQuantity(5).map((p) => _buildIssueRow(p)),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildIssueRow(ProductShrinkage product) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: product.status == ShrinkageStatus.critical 
                  ? Colors.red 
                  : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              product.productName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${product.shrinkageQty.toStringAsFixed(3)} kg',
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${product.shrinkagePercent.toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'R${product.shrinkageValue.toStringAsFixed(0)}',
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  
  _MetricCard({required this.label, required this.value, required this.color});
  
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
