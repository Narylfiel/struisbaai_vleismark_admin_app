/// ═══════════════════════════════════════════════════════════════════════════
/// SHRINKAGE DETECTION v2.0 INTEGRATION EXAMPLE
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// Demonstrates how to use the precision-corrected shrinkage detection
/// with baseline modeling, unit normalization, and proper sale filtering.
/// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'services/shrinkage_detection_service_v2.dart';

/// Example 1: Daily report with baseline breakdown
Future<void> showDailyShrinkageReportV2(BuildContext context) async {
  final service = ShrinkageDetectionService();
  
  // Detect yesterday's shrinkage with v2.0 precision
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  final summary = await service.detectDaily(yesterday);
  
  print('📊 Daily Shrinkage Report v2.0 (${yesterday.toString().split(" ")[0]})');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('Total Real Shrinkage: ${summary.totalRealShrinkageQty.toStringAsFixed(3)} kg');
  print('Total Baseline Loss: ${summary.totalBaselineLossQty.toStringAsFixed(3)} kg');
  print('Total Value Lost: R${summary.totalShrinkageValue.toStringAsFixed(2)}');
  print('Warnings: ${summary.warningCount} | Critical: ${summary.criticalCount}');
  print('Unanalyzable: ${summary.unanalyzableCount}');
  
  // Show top 10 worst offenders (after baseline adjustment)
  final worst = summary.topByQuantity(10);
  print('\n🔴 Top Real Shrinkage (after baseline):');
  for (final product in worst) {
    if (product.status == ShrinkageStatus.normal) continue;
    
    print('  ${product.productName}: '
        '${product.realShrinkageQty.toStringAsFixed(3)} kg real '
        '(baseline: ${product.baselineLossQty.toStringAsFixed(3)} kg) '
        '[${product.status.name.toUpperCase()}]');
  }
  
  // Show raw vs real for comparison
  print('\n📈 Raw vs Real Shrinkage:');
  for (final product in worst.take(5)) {
    print('  ${product.productName}: '
        'raw=${product.rawShrinkageQty.toStringAsFixed(3)}kg '
        '→ real=${product.realShrinkageQty.toStringAsFixed(3)}kg '
        '(baseline -${product.baselineLossQty.toStringAsFixed(3)}kg)');
  }
}

/// Example 2: Custom baseline configuration
Future<void> configureCustomBaselines() async {
  final service = ShrinkageDetectionService();
  
  // Customize baselines for specific products/categories
  service.setBaselineOverrides({
    'ribeye': 7.0,              // High-end cut, more trimming
    'fillet': 6.5,              // Premium cut
    'mince_premium': 1.0,       // Very consistent
    'chicken_wings': 5.0,       // Higher bone ratio
    'offcuts': 10.0,            // Inconsistent by nature
  });
  
  // Now detect with custom baselines
  final summary = await service.detectRollingWindow(7);
  
  print('📊 7-Day Report with Custom Baselines');
  print('Total Real Loss: ${summary.totalRealShrinkageQty.toStringAsFixed(3)} kg');
}

/// Example 3: Handle unanalyzable products
Future<void> handleUnitBasedProducts() async {
  final service = ShrinkageDetectionService();
  final summary = await service.detectRollingWindow(7);
  
  // Separate analyzable vs unanalyzable
  final analyzable = summary.analyzableProducts;
  final unanalyzable = summary.unanalyzable;
  
  print('✅ Analyzable products: ${analyzable.length}');
  print('⚠️  Unanalyzable products: ${unanalyzable.length}');
  
  if (unanalyzable.isNotEmpty) {
    print('\nProducts needing unit conversion setup:');
    for (final product in unanalyzable.take(10)) {
      print('  ${product.productName} (${product.category})');
      print('    Sold as: ${product.unitType}');
      print('    Needs: kg per ${product.unitType} conversion factor');
    }
  }
}

/// Example 4: v2.0 Dashboard Widget
class ShrinkageDashboardV2 extends StatefulWidget {
  @override
  _ShrinkageDashboardV2State createState() => _ShrinkageDashboardV2State();
}

class _ShrinkageDashboardV2State extends State<ShrinkageDashboardV2> {
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
    final unanalyzable = _weeklyData!.unanalyzable;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with v2.0 badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Operational Shrinkage (7 Days)',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      'v2.0 - Baseline Adjusted',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _loadData,
                ),
              ],
            ),
            
            Divider(),
            
            // Summary metrics (v2.0 - includes baseline breakdown)
            _MetricCardV2(
              label: 'Real Shrinkage',
              value: '${_weeklyData!.totalRealShrinkageQty.toStringAsFixed(2)} kg',
              subtext: 'Above baseline',
              color: _weeklyData!.criticalCount > 0 ? Colors.red : 
                     _weeklyData!.warningCount > 0 ? Colors.orange : Colors.green,
            ),
            
            _MetricCardV2(
              label: 'Baseline Loss',
              value: '${_weeklyData!.totalBaselineLossQty.toStringAsFixed(2)} kg',
              subtext: 'Expected natural loss',
              color: Colors.blue,
            ),
            
            _MetricCardV2(
              label: 'Value Lost',
              value: 'R${_weeklyData!.totalShrinkageValue.toStringAsFixed(0)}',
              subtext: 'Real shrinkage × cost',
              color: _weeklyData!.totalShrinkageValue > 1000 ? Colors.red : Colors.orange,
            ),
            
            _MetricCardV2(
              label: 'Issues',
              value: '${_weeklyData!.warningCount + _weeklyData!.criticalCount}',
              subtext: '${_weeklyData!.criticalCount} critical, '
                      '${_weeklyData!.warningCount} warning',
              color: _weeklyData!.criticalCount > 0 ? Colors.red : Colors.orange,
            ),
            
            if (unanalyzable.isNotEmpty)
              _MetricCardV2(
                label: 'Unanalyzable',
                value: '${unanalyzable.length}',
                subtext: 'Unit-based, needs conversion',
                color: Colors.grey,
              ),
            
            SizedBox(height: 16),
            
            // Anomalies list (v2.0 - shows baseline context)
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('No abnormal shrinkage detected'),
                          Text(
                            'Total baseline loss: ${_weeklyData!.totalBaselineLossQty.toStringAsFixed(2)} kg (expected)',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Issues (Real Shrinkage)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  ..._weeklyData!.topByQuantity(5).map((p) => _buildV2IssueRow(p)),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildV2IssueRow(ProductShrinkage product) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${product.realShrinkageQty.toStringAsFixed(3)} kg',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: product.status == ShrinkageStatus.critical 
                        ? Colors.red 
                        : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'R${product.shrinkageValue.toStringAsFixed(0)}',
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          // Baseline context
          Padding(
            padding: EdgeInsets.only(left: 20),
            child: Text(
              'Raw: ${product.rawShrinkageQty.toStringAsFixed(3)}kg '
              '→ Baseline: -${product.baselineLossQty.toStringAsFixed(3)}kg '
              '(${product.baselinePercent}%)',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCardV2 extends StatelessWidget {
  final String label;
  final String value;
  final String subtext;
  final Color color;
  
  _MetricCardV2({
    required this.label, 
    required this.value, 
    required this.subtext,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12, 
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtext,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Example 5: Export data for external analysis
Future<Map<String, dynamic>> exportShrinkageData() async {
  final service = ShrinkageDetectionService();
  final summary = await service.detectRollingWindow(7);
  
  return {
    'period': {
      'start': summary.windowStart.toIso8601String(),
      'end': summary.windowEnd.toIso8601String(),
    },
    'summary': {
      'total_real_shrinkage_kg': summary.totalRealShrinkageQty,
      'total_raw_shrinkage_kg': summary.totalRawShrinkageQty,
      'total_baseline_loss_kg': summary.totalBaselineLossQty,
      'total_value_lost_rands': summary.totalShrinkageValue,
      'warning_count': summary.warningCount,
      'critical_count': summary.criticalCount,
      'unanalyzable_count': summary.unanalyzableCount,
    },
    'anomalies': summary.anomalies.map((p) => {
      'product_id': p.productId,
      'product_name': p.productName,
      'category': p.category,
      'expected_kg': p.expectedQty,
      'actual_kg': p.actualQty,
      'baseline_loss_kg': p.baselineLossQty,
      'baseline_percent': p.baselinePercent,
      'real_shrinkage_kg': p.realShrinkageQty,
      'real_shrinkage_percent': p.realShrinkagePercent,
      'value_lost_rands': p.shrinkageValue,
      'status': p.status.name,
    }).toList(),
    'unanalyzable': summary.unanalyzable.map((p) => {
      'product_id': p.productId,
      'product_name': p.productName,
      'category': p.category,
      'unit_type': p.unitType,
    }).toList(),
  };
}

/// Example 6: Alert routing based on severity
Future<void> routeAlertsBySeverity() async {
  final service = ShrinkageDetectionService();
  final summary = await service.detectDaily(DateTime.now());
  
  // Critical: Immediate SMS/email to manager
  final critical = summary.products.where((p) => p.status == ShrinkageStatus.critical);
  for (final issue in critical) {
    await sendCriticalAlert(
      '🚨 CRITICAL: ${issue.productName}\n'
      'Real shrinkage: ${issue.realShrinkageQty.toStringAsFixed(3)} kg\n'
      'Value lost: R${issue.shrinkageValue.toStringAsFixed(2)}\n'
      'Immediate investigation required.',
    );
  }
  
  // Warning: Daily report summary
  final warnings = summary.products.where((p) => p.status == ShrinkageStatus.warning);
  if (warnings.isNotEmpty) {
    await sendDailyReport(
      '⚠️ Warnings: ${warnings.length} products with elevated shrinkage',
      warnings.map((p) => '${p.productName}: ${p.realShrinkageQty.toStringAsFixed(3)} kg').join('\n'),
    );
  }
  
  // Unanalyzable: Weekly data quality report
  if (summary.unanalyzableCount > 0) {
    await sendDataQualityReport(
      '${summary.unanalyzableCount} products need unit conversion setup',
    );
  }
  
  // Normal: Just log
  print('✅ ${summary.analyzableProducts.length - warnings.length - critical.length} products within baseline');
}

// Placeholder alert functions
Future<void> sendCriticalAlert(String message) async {
  print('CRITICAL ALERT: $message');
}

Future<void> sendDailyReport(String summary, String details) async {
  print('DAILY REPORT: $summary\n$details');
}

Future<void> sendDataQualityReport(String message) async {
  print('DATA QUALITY: $message');
}
