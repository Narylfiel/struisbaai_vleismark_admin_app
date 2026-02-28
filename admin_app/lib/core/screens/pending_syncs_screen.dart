import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/db/pending_write.dart';
import 'package:admin_app/core/services/offline_queue_service.dart';
import 'package:intl/intl.dart';

/// Human-readable label for action types.
String _actionLabel(String actionType) {
  switch (actionType) {
    case 'record_waste':
      return 'Record Waste';
    case 'stock_adjustment':
      return 'Stock Adjustment';
    case 'complete_batch':
      return 'Complete Batch';
    case 'receive_invoice':
      return 'Receive Invoice';
    case 'create_hunter_job':
      return 'Create Hunter Job';
    case 'approve_leave':
      return 'Approve Leave';
    default:
      return actionType.replaceAll('_', ' ').split(' ').map((e) => e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1)}').join(' ');
  }
}

/// Pending and failed offline actions. Refreshes when [OfflineQueueService.pendingCountStream] emits.
class PendingSyncsScreen extends StatelessWidget {
  const PendingSyncsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Syncs'),
        backgroundColor: AppColors.cardBg,
        foregroundColor: AppColors.textPrimary,
      ),
      body: StreamBuilder<int>(
        stream: OfflineQueueService().pendingCountStream,
        builder: (context, _) {
          return FutureBuilder<Map<String, List<PendingWrite>>>(
            future: _loadLists(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data!;
              final pending = data['pending']!;
              final failed = data['failed']!;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Chip(
                          backgroundColor: Colors.blue.shade100,
                          label: Text('${pending.length} pending'),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          backgroundColor: Colors.red.shade100,
                          label: Text('${failed.length} failed'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Section(
                      title: 'Pending',
                      items: pending,
                      isFailed: false,
                    ),
                    const SizedBox(height: 24),
                    _Section(
                      title: 'Failed',
                      items: failed,
                      isFailed: true,
                      onRetryAll: failed.isEmpty ? null : () => OfflineQueueService().retryFailed(),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, List<PendingWrite>>> _loadLists() async {
    final pending = await OfflineQueueService().getAllPending();
    final failed = await OfflineQueueService().getAllFailed();
    return {'pending': pending, 'failed': failed};
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
    required this.isFailed,
    this.onRetryAll,
  });

  final String title;
  final List<PendingWrite> items;
  final bool isFailed;
  final VoidCallback? onRetryAll;

  static final _dateFormat = DateFormat('dd MMM yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (isFailed && onRetryAll != null && items.isNotEmpty) ...[
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: onRetryAll,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry All'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'None',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          )
        else
          ...items.map((item) => _RowItem(
                item: item,
                isFailed: isFailed,
                dateFormat: _dateFormat,
              )),
      ],
    );
  }
}

class _RowItem extends StatelessWidget {
  const _RowItem({
    required this.item,
    required this.isFailed,
    required this.dateFormat,
  });

  final PendingWrite item;
  final bool isFailed;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _actionLabel(item.actionType),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  dateFormat.format(item.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (item.retryCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Retries: ${item.retryCount}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            if (isFailed && item.lastError != null && item.lastError!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  item.lastError!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (isFailed) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _retry(context),
                    child: const Text('Retry'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _discard(context),
                    child: const Text('Discard'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _retry(BuildContext context) async {
    await OfflineQueueService().retryItem(item.id);
  }

  Future<void> _discard(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard?'),
        content: const Text(
          'This action will be removed and will not sync. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await OfflineQueueService().discardItem(item.id);
    }
  }
}
