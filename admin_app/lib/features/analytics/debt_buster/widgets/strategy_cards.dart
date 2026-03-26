import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import '../models/strategy_plan.dart';

/// Displays the three repayment strategy options.
class StrategyCards extends StatelessWidget {
  final List<StrategyPlan> strategies;
  final StrategyLevel? selectedLevel;
  final ValueChanged<StrategyLevel>? onSelect;

  const StrategyCards({
    super.key,
    required this.strategies,
    this.selectedLevel,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (strategies.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No strategies available',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.route, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'Repayment Strategies',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: strategies.map((strategy) {
            final isSelected = selectedLevel == strategy.level;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: strategy.level != StrategyLevel.aggressive ? 8 : 0,
                ),
                child: _StrategyCard(
                  strategy: strategy,
                  isSelected: isSelected,
                  onTap: onSelect != null ? () => onSelect!(strategy.level) : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StrategyCard extends StatelessWidget {
  final StrategyPlan strategy;
  final bool isSelected;
  final VoidCallback? onTap;

  const _StrategyCard({
    required this.strategy,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getLevelColor();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strategy.level.displayLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              strategy.formattedMonthlyPayment,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : AppColors.textPrimary,
              ),
            ),
            Text(
              '/month',
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? color.withOpacity(0.7) : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: strategy.isFeasible
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                strategy.timelineDescription,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: strategy.isFeasible ? AppColors.success : AppColors.error,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(strategy.level.cashAllocationPercent * 100).toInt()}% of available cash',
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

  Color _getLevelColor() {
    switch (strategy.level) {
      case StrategyLevel.conservative:
        return Colors.blue;
      case StrategyLevel.balanced:
        return Colors.orange;
      case StrategyLevel.aggressive:
        return Colors.red;
    }
  }
}
