import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../core/constants/app_colors.dart';

/// Reusable chart widgets using Syncfusion Charts
class ChartWidgets {
  /// Sales trend line chart
  static Widget salesTrendChart({
    required List<ChartData> data,
    String title = 'Sales Trend',
    double height = 300,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: SfCartesianChart(
        title: ChartTitle(
          text: title,
          textStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        legend: const Legend(isVisible: false),
        tooltipBehavior: TooltipBehavior(enable: true),
        primaryXAxis: DateTimeAxis(
          dateFormat: DateFormat.MMMd(),
          intervalType: DateTimeIntervalType.days,
          majorGridLines: const MajorGridLines(width: 0),
        ),
        primaryYAxis: NumericAxis(
          numberFormat: NumberFormat.currency(symbol: 'R'),
          majorGridLines: const MajorGridLines(width: 0.5, color: AppColors.border),
        ),
        series: <CartesianSeries<ChartData, dynamic>>[
          LineSeries<ChartData, DateTime>(
            dataSource: data,
            xValueMapper: (ChartData sales, _) => sales.x,
            yValueMapper: (ChartData sales, _) => sales.y,
            color: AppColors.primary,
            width: 3,
            markerSettings: const MarkerSettings(
              isVisible: true,
              color: AppColors.primary,
              borderColor: Colors.white,
              borderWidth: 2,
            ),
          ),
        ],
      ),
    );
  }

  /// Product performance bar chart
  static Widget productPerformanceChart({
    required List<ChartData> data,
    String title = 'Top Products',
    double height = 300,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: SfCartesianChart(
        title: ChartTitle(
          text: title,
          textStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        primaryXAxis: const CategoryAxis(
          majorGridLines: MajorGridLines(width: 0),
          labelRotation: 45,
        ),
        primaryYAxis: const NumericAxis(
          majorGridLines: MajorGridLines(width: 0.5, color: AppColors.border),
        ),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CartesianSeries<ChartData, dynamic>>[
          ColumnSeries<ChartData, String>(
            dataSource: data,
            xValueMapper: (ChartData product, _) => product.x.toString(),
            yValueMapper: (ChartData product, _) => product.y,
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              textStyle: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Inventory levels pie chart
  static Widget inventoryLevelsChart({
    required List<ChartData> data,
    String title = 'Inventory Status',
    double height = 300,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: SfCircularChart(
        title: ChartTitle(
          text: title,
          textStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        legend: const Legend(
          isVisible: true,
          position: LegendPosition.bottom,
          textStyle: TextStyle(color: AppColors.textPrimary, fontSize: 12),
        ),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CircularSeries<ChartData, String>>[
          PieSeries<ChartData, String>(
            dataSource: data,
            xValueMapper: (ChartData data, _) => data.x.toString(),
            yValueMapper: (ChartData data, _) => data.y,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              textStyle: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            pointColorMapper: (ChartData data, _) => data.color ?? AppColors.primary,
          ),
        ],
      ),
    );
  }

  /// Shrinkage trend area chart
  static Widget shrinkageTrendChart({
    required List<ChartData> data,
    String title = 'Shrinkage Trend',
    double height = 300,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: SfCartesianChart(
        title: ChartTitle(
          text: title,
          textStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        legend: const Legend(isVisible: false),
        tooltipBehavior: TooltipBehavior(enable: true),
        primaryXAxis: DateTimeAxis(
          dateFormat: DateFormat.MMMd(),
          intervalType: DateTimeIntervalType.days,
          majorGridLines: const MajorGridLines(width: 0),
        ),
        primaryYAxis: NumericAxis(
          numberFormat: NumberFormat.percentPattern(),
          majorGridLines: const MajorGridLines(width: 0.5, color: AppColors.border),
        ),
        series: <CartesianSeries<ChartData, dynamic>>[
          AreaSeries<ChartData, DateTime>(
            dataSource: data,
            xValueMapper: (ChartData shrinkage, _) => shrinkage.x,
            yValueMapper: (ChartData shrinkage, _) => shrinkage.y,
            color: Colors.red.withOpacity(0.3),
            borderColor: Colors.red,
            borderWidth: 2,
          ),
        ],
      ),
    );
  }

  /// Staff performance bar chart (replaces radar for compatibility)
  static Widget staffPerformanceChart({
    required List<ChartData> data,
    String title = 'Staff Performance',
    double height = 300,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: SfCartesianChart(
        title: ChartTitle(
          text: title,
          textStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        legend: const Legend(isVisible: false),
        tooltipBehavior: TooltipBehavior(enable: true),
        primaryXAxis: const CategoryAxis(
          majorGridLines: MajorGridLines(width: 0),
          labelRotation: 45,
        ),
        primaryYAxis: const NumericAxis(
          majorGridLines: MajorGridLines(width: 0.5, color: AppColors.border),
        ),
        series: <CartesianSeries<ChartData, dynamic>>[
          ColumnSeries<ChartData, String>(
            dataSource: data,
            xValueMapper: (ChartData performance, _) => performance.x.toString(),
            yValueMapper: (ChartData performance, _) => performance.y,
            color: AppColors.primary.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              textStyle: TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  /// Financial summary donut chart
  static Widget financialSummaryChart({
    required List<ChartData> data,
    String title = 'Financial Summary',
    double height = 300,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: SfCircularChart(
        title: ChartTitle(
          text: title,
          textStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        legend: const Legend(
          isVisible: true,
          position: LegendPosition.right,
          textStyle: TextStyle(color: AppColors.textPrimary, fontSize: 12),
        ),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CircularSeries<ChartData, String>>[
          DoughnutSeries<ChartData, String>(
            dataSource: data,
            xValueMapper: (ChartData data, _) => data.x.toString(),
            yValueMapper: (ChartData data, _) => data.y,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              textStyle: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            pointColorMapper: (ChartData data, _) => data.color ?? AppColors.primary,
            innerRadius: '60%',
          ),
        ],
      ),
    );
  }
}

/// Chart data model
class ChartData {
  final dynamic x;
  final num y;
  final Color? color;
  final String? label;

  ChartData({
    required this.x,
    required this.y,
    this.color,
    this.label,
  });
}