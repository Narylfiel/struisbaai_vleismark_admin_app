import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/features/transactions/services/transaction_repository.dart';
import 'package:intl/intl.dart';

/// Read-only till session (cash-up) detail: header, Z-report, petty cash.
class TillSessionDetailScreen extends StatefulWidget {
  final String sessionId;

  const TillSessionDetailScreen({super.key, required this.sessionId});

  @override
  State<TillSessionDetailScreen> createState() => _TillSessionDetailScreenState();
}

class _TillSessionDetailScreenState extends State<TillSessionDetailScreen> {
  final _repo = TransactionRepository();
  Map<String, dynamic>? _session;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final detail = await _repo.getTillSessionDetail(widget.sessionId);
      if (mounted) setState(() {
        _session = detail;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _session = null;
        _loading = false;
      });
    }
  }

  static Color _varianceColor(double? variance) {
    if (variance == null) return AppColors.textSecondary;
    final abs = variance.abs();
    if (abs <= 50) return AppColors.success;
    if (abs <= 200) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Till session'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _session == null
              ? const Center(child: Text('Session not found', style: TextStyle(color: AppColors.textSecondary)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildZReport(),
                      const SizedBox(height: 20),
                      _buildPettyCash(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    final s = _session!;
    final openedAt = s['opened_at'] != null ? DateTime.tryParse(s['opened_at'] as String) : null;
    final closedAt = s['closed_at'] != null ? DateTime.tryParse(s['closed_at'] as String) : null;
    final terminalId = s['terminal_id'] as String? ?? '—';
    final openedByName = s['opened_by_name'] as String? ?? '—';
    final closedByName = s['closed_by_name'] as String? ?? '—';
    final openingFloat = (s['opening_float'] as num?)?.toDouble() ?? 0;
    final expectedCash = (s['expected_closing_cash'] as num?)?.toDouble();
    final actualCash = (s['actual_closing_cash'] as num?)?.toDouble();
    final variance = (s['variance'] as num?)?.toDouble();
    final notes = s['notes'] as String?;
    final status = (s['status'] as String?) ?? 'open';
    final isClosed = status == 'closed';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Terminal: $terminalId', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isClosed ? AppColors.success : Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(isClosed ? 'CLOSED' : 'OPEN', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _row('Opened by', openedByName),
          if (openedAt != null) _row('Opened at', DateFormat('dd MMM yyyy HH:mm').format(openedAt)),
          _row('Closed by', closedByName),
          if (closedAt != null) _row('Closed at', DateFormat('dd MMM yyyy HH:mm').format(closedAt)),
          const Divider(height: 20),
          _row('Opening float', 'R ${openingFloat.toStringAsFixed(2)}'),
          if (expectedCash != null) _row('Expected closing cash', 'R ${expectedCash.toStringAsFixed(2)}'),
          if (actualCash != null) _row('Actual closing cash', 'R ${actualCash.toStringAsFixed(2)}'),
          if (variance != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Variance', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('R ${variance.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: _varianceColor(variance))),
                ],
              ),
            ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Notes', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(notes, style: const TextStyle(fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildZReport() {
    final s = _session!;
    final count = (s['z_total_count'] as int?) ?? 0;
    final revenue = (s['z_total_revenue'] as num?)?.toDouble() ?? 0;
    final cash = (s['z_cash'] as num?)?.toDouble() ?? 0;
    final card = (s['z_card'] as num?)?.toDouble() ?? 0;
    final account = (s['z_account'] as num?)?.toDouble() ?? 0;
    final split = (s['z_split'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Z-report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _row('Sales count', '$count'),
          _row('Total revenue', 'R ${revenue.toStringAsFixed(2)}'),
          const Divider(height: 16),
          const Text('By payment method', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          _row('Cash', 'R ${cash.toStringAsFixed(2)}'),
          _row('Card', 'R ${card.toStringAsFixed(2)}'),
          _row('Account', 'R ${account.toStringAsFixed(2)}'),
          _row('Split', 'R ${split.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildPettyCash() {
    final list = _session!['petty_cash_movements'] as List<dynamic>? ?? [];
    final net = (_session!['petty_cash_net'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Petty cash', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('Net: R ${net.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: net >= 0 ? AppColors.success : AppColors.error)),
            ],
          ),
          const SizedBox(height: 12),
          if (list.isEmpty)
            const Text('No petty cash movements', style: TextStyle(color: AppColors.textSecondary))
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.2),
                1: FlexColumnWidth(0.8),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(2),
                4: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: AppColors.surfaceBg),
                  children: const [
                    Padding(padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text('Time', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text('Dir', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text('Amount', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text('Reason', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text('Recorded by', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  ],
                ),
                ...list.map<TableRow>((e) {
                  final m = e as Map<String, dynamic>;
                  final recordedAt = m['recorded_at'] != null ? DateTime.tryParse(m['recorded_at'] as String) : null;
                  final timeStr = recordedAt != null ? DateFormat('HH:mm').format(recordedAt) : '—';
                  final direction = (m['direction'] as String?) ?? '—';
                  final amount = (m['amount'] as num?)?.toDouble() ?? 0;
                  final reason = (m['reason'] as String?) ?? '—';
                  String recordedByName = '—';
                  final p = m['profiles'];
                  if (p is Map) recordedByName = (p['full_name'] as String?) ?? '—';
                  else if (p is List && p.isNotEmpty && p.first is Map) recordedByName = ((p.first as Map)['full_name'] as String?) ?? '—';
                  final isIn = direction.toLowerCase() == 'in';
                  return TableRow(
                    children: [
                      Padding(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text(timeStr, style: const TextStyle(fontSize: 12))),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text(direction, style: TextStyle(fontSize: 12, color: isIn ? AppColors.success : AppColors.error))),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text('R ${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12))),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text(reason, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text(recordedByName, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }
}
