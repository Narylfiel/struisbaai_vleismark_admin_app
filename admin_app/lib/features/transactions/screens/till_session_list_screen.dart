import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/features/transactions/services/transaction_repository.dart';
import 'package:admin_app/features/transactions/screens/till_session_detail_screen.dart';
import 'package:intl/intl.dart';

/// Read-only list of POS till sessions (cash-ups). Third in sidebar.
class TillSessionListScreen extends StatefulWidget {
  const TillSessionListScreen({super.key});

  @override
  State<TillSessionListScreen> createState() => _TillSessionListScreenState();
}

class _TillSessionListScreenState extends State<TillSessionListScreen> {
  final _repo = TransactionRepository();
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = true;
  DateTime _dateFrom = DateTime.now().subtract(const Duration(days: 6));
  DateTime _dateTo = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final start = DateTime(_dateFrom.year, _dateFrom.month, _dateFrom.day);
      final end = DateTime(_dateTo.year, _dateTo.month, _dateTo.day, 23, 59, 59);
      final list = await _repo.getTillSessions(start, end);
      if (mounted) setState(() {
        _sessions = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _sessions = [];
        _loading = false;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _dateFrom, end: _dateTo),
    );
    if (picked != null && mounted) {
      setState(() {
        _dateFrom = picked.start;
        _dateTo = picked.end;
      });
      await _load();
    }
  }

  void _openDetail(Map<String, dynamic> session) {
    final id = session['id'] as String?;
    if (id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TillSessionDetailScreen(sessionId: id),
      ),
    ).then((_) => _load());
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
    final totalVariance = _sessions.fold<double>(0, (s, m) => s + ((m['variance'] as num?)?.toDouble() ?? 0));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          // Summary
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Icon(Icons.point_of_sale, size: 22, color: AppColors.textSecondary),
                      const SizedBox(height: 4),
                      Text('${_sessions.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text('Sessions', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Icon(Icons.balance, size: 22, color: totalVariance.abs() <= 50 ? AppColors.success : (totalVariance.abs() <= 200 ? AppColors.warning : AppColors.error)),
                      const SizedBox(height: 4),
                      Text('R ${totalVariance.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _varianceColor(totalVariance))),
                      const Text('Total variance', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Date filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppColors.cardBg,
            child: Row(
              children: [
                InkWell(
                  onTap: _pickDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${DateFormat('dd MMM').format(_dateFrom)} – ${DateFormat('dd MMM').format(_dateTo)}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _sessions.isEmpty
                    ? const Center(child: Text('No till sessions in this period', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: _sessions.length,
                        itemBuilder: (context, i) => _buildRow(_sessions[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> s) {
    final openedAt = s['opened_at'] != null ? DateTime.tryParse(s['opened_at'] as String) : null;
    final closedAt = s['closed_at'] != null ? DateTime.tryParse(s['closed_at'] as String) : null;
    final dateStr = openedAt != null ? DateFormat('dd MMM').format(openedAt) : '—';
    final openedAtStr = openedAt != null ? DateFormat('HH:mm').format(openedAt) : '—';
    final closedAtStr = closedAt != null ? DateFormat('HH:mm').format(closedAt) : '—';
    final terminalId = s['terminal_id'] as String? ?? '—';
    final profiles = s['profiles'];
    String openedByName = '—';
    if (profiles is Map) openedByName = (profiles['full_name'] as String?) ?? '—';
    else if (profiles is List && profiles.isNotEmpty && profiles.first is Map) openedByName = ((profiles.first as Map)['full_name'] as String?) ?? '—';
    final openingFloat = (s['opening_float'] as num?)?.toDouble() ?? 0;
    final expectedCash = (s['expected_closing_cash'] as num?)?.toDouble();
    final actualCash = (s['actual_closing_cash'] as num?)?.toDouble();
    final variance = (s['variance'] as num?)?.toDouble();
    final status = (s['status'] as String?) ?? 'open';
    final isClosed = status == 'closed';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.cardBg,
      child: InkWell(
        onTap: () => _openDetail(s),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(width: 64, child: Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
              SizedBox(width: 56, child: Text(terminalId, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
              Expanded(flex: 2, child: Text(openedByName, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
              SizedBox(width: 48, child: Text(openedAtStr, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
              SizedBox(width: 48, child: Text(closedAtStr, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
              SizedBox(width: 64, child: Text('R ${openingFloat.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11))),
              SizedBox(width: 64, child: Text(expectedCash != null ? 'R ${expectedCash.toStringAsFixed(0)}' : '—', style: const TextStyle(fontSize: 11))),
              SizedBox(width: 64, child: Text(actualCash != null ? 'R ${actualCash.toStringAsFixed(0)}' : '—', style: const TextStyle(fontSize: 11))),
              SizedBox(
                width: 72,
                child: Text(
                  variance != null ? 'R ${variance.toStringAsFixed(2)}' : '—',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _varianceColor(variance)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isClosed ? AppColors.success : Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(isClosed ? 'CLOSED' : 'OPEN', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
