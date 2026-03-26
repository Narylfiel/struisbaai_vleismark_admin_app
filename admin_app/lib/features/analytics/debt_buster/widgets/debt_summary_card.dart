import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import '../models/debt_summary.dart';

/// Card displaying total debt breakdown.
class DebtSummaryCard extends StatelessWidget {
  final DebtSummary summary;
  final VoidCallback? onRefresh;

  const DebtSummaryCard({
    super.key,
    required this.summary,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: AppColors.primary),
                const SizedBox(width: 12),
                const Text(
                  'Total Debt',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: onRefresh,
                    tooltip: 'Refresh',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              summary.formattedTotal,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: summary.hasDebt ? AppColors.error : AppColors.success,
              ),
            ),
            const SizedBox(height: 20),
            _DebtBreakdownRow(
              label: 'Supplier Invoices',
              value: summary.formattedSupplierDebt,
              count: summary.supplierInvoiceCount,
              icon: Icons.receipt_long,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _DebtBreakdownRow(
              label: 'Staff Credits',
              value: summary.formattedStaffDebt,
              count: summary.staffCreditCount,
              icon: Icons.people,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            Text(
              'As of ${_formatDate(summary.asOfDate)}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _DebtBreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final int count;
  final IconData icon;
  final Color color;

  const _DebtBreakdownRow({
    required this.label,
    required this.value,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13)),
              Text(
                '$count item${count != 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
