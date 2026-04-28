import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import '../models/gap_analysis.dart';

/// Visual indicator for gap status.
class GapIndicator extends StatelessWidget {
  final GapAnalysis analysis;
  final bool isGoalAchievable;

  const GapIndicator({
    super.key,
    required this.analysis,
    this.isGoalAchievable = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        analysis.status.displayLabel,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        _getStatusDescription(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _MetricRow(
              label: 'Required Monthly',
              value: analysis.formattedRequired,
              subtitle: 'To clear in ${analysis.targetMonths} months',
            ),
            const SizedBox(height: 12),
            _MetricRow(
              label: 'Available Monthly',
              value: analysis.formattedAvailable,
              subtitle: 'Average net cash flow',
            ),
            if (analysis.hasShortfall) ...[
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: AppColors.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monthly Shortfall',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                          Text(
                            analysis.formattedGap,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${analysis.shortfallPercentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                        const Text(
                          'of required',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (analysis.availableMonthly <= 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.money_off, color: AppColors.error, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No available cash for repayment',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (isGoalAchievable) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lightbulb, color: AppColors.success, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Gap can be closed with recommended actions',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber, color: AppColors.error, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Goal not achievable with current conditions',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (analysis.status) {
      case GapStatus.onTrack:
        return AppColors.success;
      case GapStatus.shortfall:
        return isGoalAchievable ? AppColors.warning : AppColors.error;
      case GapStatus.noDebt:
        return AppColors.success;
    }
  }

  IconData _getStatusIcon() {
    switch (analysis.status) {
      case GapStatus.onTrack:
        return Icons.check_circle;
      case GapStatus.shortfall:
        return isGoalAchievable ? Icons.info : Icons.error;
      case GapStatus.noDebt:
        return Icons.celebration;
    }
  }

  String _getStatusDescription() {
    switch (analysis.status) {
      case GapStatus.onTrack:
        return 'Current cash flow can cover the repayment';
      case GapStatus.shortfall:
        return isGoalAchievable
            ? 'Shortfall can be addressed with actions below'
            : 'Additional income needed to meet deadline';
      case GapStatus.noDebt:
        return 'No outstanding debt to repay';
    }
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13)),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
