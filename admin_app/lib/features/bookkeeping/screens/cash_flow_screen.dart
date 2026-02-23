import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/features/bookkeeping/services/ledger_repository.dart';

/// H7: Cash Flow Screen — last 6 months, Operating/Investing/Financing, bar chart.
/// Colors: Cash In #2E86AB, Cash Out #B91C1C.
class CashFlowScreen extends StatefulWidget {
  const CashFlowScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends State<CashFlowScreen> {
  final LedgerRepository _ledger = LedgerRepository();
  int _monthCount = 6;
  int _selectedMonthIndex = 0; // which month in _monthlyData to show in ExpansionTiles
  bool _loading = true;
  List<Map<String, dynamic>> _monthlyData = [];
  ({double cashIn, double cashOut, double bankIn, double bankOut}) _summary = (cashIn: 0, cashOut: 0, bankIn: 0, bankOut: 0);

  static const _cashInColor = Color(0xFF2E86AB);
  static const _cashOutColor = Color(0xFFB91C1C);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final months = await _ledger.getCashFlowByMonth(_monthCount);
      if (mounted) setState(() {
        _monthlyData = months;
        _selectedMonthIndex = _selectedMonthIndex.clamp(0, months.length - 1);
        if (months.isNotEmpty) {
          final m = months[_selectedMonthIndex];
          _summary = (
            cashIn: (m['cashIn'] as num).toDouble(),
            cashOut: (m['cashOut'] as num).toDouble(),
            bankIn: (m['bankIn'] as num).toDouble(),
            bankOut: (m['bankOut'] as num).toDouble(),
          );
        } else {
          _summary = (cashIn: 0, cashOut: 0, bankIn: 0, bankOut: 0);
        }
        _loading = false;
      });
    } catch (e) {
      debugPrint('Cash flow load: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setMonthCount(int n) {
    setState(() => _monthCount = n);
    _load();
  }

  void _setSelectedMonthIndex(int i) {
    setState(() {
      _selectedMonthIndex = i.clamp(0, _monthlyData.length - 1);
      if (_monthlyData.isNotEmpty) {
        final m = _monthlyData[_selectedMonthIndex];
        _summary = (
          cashIn: (m['cashIn'] as num).toDouble(),
          cashOut: (m['cashOut'] as num).toDouble(),
          bankIn: (m['bankIn'] as num).toDouble(),
          bankOut: (m['bankOut'] as num).toDouble(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    // Chart data: each month has cashIn, cashOut, net
    final cashInPoints = _monthlyData.map((m) => _ChartPoint(m['label'] as String, m['totalIn'] as double)).toList();
    final cashOutPoints = _monthlyData.map((m) => _ChartPoint(m['label'] as String, m['totalOut'] as double)).toList();
    final netPoints = _monthlyData.map((m) => _ChartPoint(m['label'] as String, m['net'] as double)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Cash Flow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 24),
              Wrap(
                spacing: 8,
                children: [6, 12].map((n) {
                  return FilterChip(
                    label: Text('$n months'),
                    selected: _monthCount == n,
                    onSelected: (_) => _setMonthCount(n),
                  );
                }).toList(),
              ),
              const SizedBox(width: 16),
              if (_monthlyData.isNotEmpty) ...[
                const Text('Detail for:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<int>(
                    value: _selectedMonthIndex.clamp(0, _monthlyData.length - 1),
                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                    items: List.generate(_monthlyData.length, (i) {
                      final m = _monthlyData[i];
                      return DropdownMenuItem(value: i, child: Text(m['label'] as String, overflow: TextOverflow.ellipsis));
                    }),
                    onChanged: (i) => i != null ? _setSelectedMonthIndex(i) : null,
                  ),
                ),
              ],
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          // Bar chart: Cash In | Cash Out per month, Net as line
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 12, height: 12, color: _cashInColor),
                      const SizedBox(width: 6),
                      const Text('Cash In', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 16),
                      Container(width: 12, height: 12, color: _cashOutColor),
                      const SizedBox(width: 6),
                      const Text('Cash Out', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 16),
                      Container(width: 12, height: 12, color: AppColors.info),
                      const SizedBox(width: 6),
                      const Text('Net', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 280,
                    child: SfCartesianChart(
                      primaryXAxis: CategoryAxis(
                        labelStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        majorGridLines: const MajorGridLines(width: 0),
                      ),
                      primaryYAxis: NumericAxis(
                        labelFormat: 'R {value}',
                        labelStyle: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        axisLine: const AxisLine(width: 0),
                        majorTickLines: const MajorTickLines(size: 0),
                      ),
                      tooltipBehavior: TooltipBehavior(enable: true),
                      legend: Legend(
                        isVisible: false,
                        position: LegendPosition.bottom,
                        overflowMode: LegendItemOverflowMode.wrap,
                      ),
                      series: <CartesianSeries>[
                        ColumnSeries<_ChartPoint, String>(
                          dataSource: cashInPoints,
                          xValueMapper: (_ChartPoint p, _) => p.label,
                          yValueMapper: (_ChartPoint p, _) => p.value,
                          color: _cashInColor,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          name: 'Cash In',
                        ),
                        ColumnSeries<_ChartPoint, String>(
                          dataSource: cashOutPoints,
                          xValueMapper: (_ChartPoint p, _) => p.label,
                          yValueMapper: (_ChartPoint p, _) => p.value,
                          color: _cashOutColor,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          name: 'Cash Out',
                        ),
                        LineSeries<_ChartPoint, String>(
                          dataSource: netPoints,
                          xValueMapper: (_ChartPoint p, _) => p.label,
                          yValueMapper: (_ChartPoint p, _) => p.value,
                          color: AppColors.info,
                          width: 2,
                          markerSettings: const MarkerSettings(isVisible: true, height: 4, width: 4),
                          name: 'Net',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ExpansionTiles: Operating | Investing | Financing
          ExpansionTile(
            initiallyExpanded: true,
            title: const Text('Operating', style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              _cfRow('Cash in (1000)', _summary.cashIn),
              _cfRow('Cash out (1000)', _summary.cashOut),
              _cfRow('Bank in (1100)', _summary.bankIn),
              _cfRow('Bank out (1100)', _summary.bankOut),
              const Divider(height: 1),
              _cfRow('Net Operating', _summary.cashIn - _summary.cashOut + _summary.bankIn - _summary.bankOut, isBold: true),
            ],
          ),
          ExpansionTile(
            initiallyExpanded: false,
            title: const Text('Investing', style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No investing activities in selected period.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
            ],
          ),
          ExpansionTile(
            initiallyExpanded: false,
            title: const Text('Financing', style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No financing activities in selected period.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cfRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text('R ${amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

class _ChartPoint {
  final String label;
  final double value;
  _ChartPoint(this.label, this.value);
}
