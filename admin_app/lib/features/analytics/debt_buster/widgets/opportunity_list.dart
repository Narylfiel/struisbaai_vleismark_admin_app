import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import '../models/opportunity.dart';
import '../models/action_tracking.dart';

/// List of actionable opportunities to close the gap.
class OpportunityList extends StatelessWidget {
  final List<Opportunity> opportunities;
  final GapMatchResult? matchResult;
  final bool showAll;

  final Map<String, ActionTracking> actionTrackingByOpportunityId;
  final ValueChanged<Opportunity>? onStartAction;
  final String? highlightOpportunityId;

  const OpportunityList({
    super.key,
    required this.opportunities,
    this.matchResult,
    this.showAll = false,
    this.actionTrackingByOpportunityId = const {},
    this.onStartAction,
    this.highlightOpportunityId,
  });

  @override
  Widget build(BuildContext context) {
    final displayList = showAll
        ? opportunities
        : (matchResult?.selectedOpportunities ?? opportunities.take(10).toList());

    if (displayList.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.lightbulb_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No actionable improvements found',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your pricing and operations appear optimized',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb, color: AppColors.warning, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Actions to Close Gap',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            if (matchResult != null && matchResult!.targetGap > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: matchResult!.gapClosable
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  matchResult!.gapClosable
                      ? 'Goal Achievable'
                      : '${matchResult!.coveragePercentage.toStringAsFixed(0)}% Coverage',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: matchResult!.gapClosable ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
          ],
        ),
        if (matchResult != null && matchResult!.targetGap > 0) ...[
          const SizedBox(height: 8),
          _MatchSummaryBar(matchResult: matchResult!),
        ],
        const SizedBox(height: 12),
        ...displayList.asMap().entries.map((entry) {
          final index = entry.key;
          final opp = entry.value;
          final isSelected = matchResult?.selectedOpportunities.contains(opp) ?? true;
          final isHighlight = highlightOpportunityId != null && opp.id == highlightOpportunityId;
          return Padding(
            padding: EdgeInsets.only(bottom: index < displayList.length - 1 ? 8 : 0),
            child: _OpportunityCard(
              opportunity: opp,
              isSelected: isSelected,
              actionTracking: actionTrackingByOpportunityId[opp.id],
              onStartAction: onStartAction,
              isHighlight: isHighlight,
            ),
          );
        }),
        if (!showAll && opportunities.length > displayList.length) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {},
              child: Text(
                'View all ${opportunities.length} opportunities',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MatchSummaryBar extends StatelessWidget {
  final GapMatchResult matchResult;

  const _MatchSummaryBar({required this.matchResult});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Potential Monthly Impact',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                Text(
                  matchResult.formattedTotalImpact,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          if (!matchResult.gapClosable) ...[
            Container(
              width: 1,
              height: 32,
              color: AppColors.border,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Remaining Shortfall',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  Text(
                    matchResult.formattedShortfall,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  final Opportunity opportunity;
  final bool isSelected;
  final ActionTracking? actionTracking;
  final ValueChanged<Opportunity>? onStartAction;
  final bool isHighlight;

  const _OpportunityCard({
    required this.opportunity,
    required this.isSelected,
    required this.actionTracking,
    required this.onStartAction,
    required this.isHighlight,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor();

    final highlightColor = typeColor;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlight
            ? highlightColor.withOpacity(0.12)
            : (isSelected ? AppColors.cardBg : AppColors.surfaceBg),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlight
              ? highlightColor.withOpacity(0.55)
              : (isSelected ? typeColor.withOpacity(0.3) : AppColors.border),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              opportunity.type.icon,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isHighlight) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: highlightColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: highlightColor.withOpacity(0.25)),
                    ),
                    child: const Text(
                      'Top priority',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        opportunity.productName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        opportunity.type.displayLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: typeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  opportunity.action,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  opportunity.reason,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${opportunity.formattedImpact}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              Text(
                '/month',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(
                    3,
                    (i) => Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(left: 2),
                      decoration: BoxDecoration(
                        color: _getConfidenceColor(i),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _actionButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton() {
    final tracking = actionTracking;

    if (tracking != null && tracking.completed) {
      return OutlinedButton.icon(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          side: BorderSide(color: AppColors.success.withOpacity(0.35)),
        ),
        icon: Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
        label: const Text(
          'Completed',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      );
    }

    if (tracking != null && !tracking.completed) {
      return OutlinedButton.icon(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          side: BorderSide(color: Colors.orange.withOpacity(0.35)),
        ),
        icon: Icon(Icons.play_arrow_outlined, size: 16, color: Colors.orange),
        label: const Text(
          'In Progress',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      );
    }

    if (onStartAction == null) {
      return const SizedBox.shrink();
    }

    return FilledButton.icon(
      onPressed: () => onStartAction?.call(opportunity),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        backgroundColor: AppColors.primary,
      ),
      icon: const Icon(Icons.play_arrow, size: 16),
      label: const Text(
        'Start Action',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Color _getTypeColor() {
    switch (opportunity.type) {
      case OpportunityType.margin:
        return Colors.orange;
      case OpportunityType.loss:
        return Colors.red;
      case OpportunityType.shrinkage:
        return Colors.purple;
      case OpportunityType.slow_stock:
        return Colors.blue;
    }
  }

  Color _getConfidenceColor(int dotIndex) {
    final confidence = opportunity.confidenceScore;
    if (confidence >= 0.8 || (confidence >= 0.6 && dotIndex < 2) || (confidence >= 0.4 && dotIndex < 1)) {
      return AppColors.success;
    }
    return Colors.grey.shade300;
  }
}
