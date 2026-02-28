import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/db/cached_transaction.dart';
import 'package:admin_app/core/db/isar_service.dart';
import 'package:admin_app/core/services/connectivity_service.dart';
import 'package:admin_app/features/transactions/services/transaction_repository.dart';
import 'package:admin_app/features/transactions/screens/transaction_detail_screen.dart';
import 'package:intl/intl.dart';

/// Read-only list of POS transactions. Second in sidebar after Dashboard.
class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final _repo = TransactionRepository();
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _staffList = [];
  bool _loading = true;
  DateTime _dateFrom = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _dateTo = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 59);
  String? _paymentFilter;
  String? _staffFilter;

  static const List<MapEntry<String, String>> paymentOptions = [
    MapEntry('', 'All'),
    MapEntry('Cash', 'Cash'),
    MapEntry('Card', 'Card'),
    MapEntry('Account', 'Account'),
    MapEntry('Split', 'Split'),
  ];

  @override
  void initState() {
    super.initState();
    _loadStaff();
    _load();
  }

  Future<void> _loadStaff() async {
    try {
      final list = await _repo.getStaffForFilter();
      if (mounted) setState(() => _staffList = list);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final isOnline = ConnectivityService().isConnected;
      if (!isOnline) {
        final cached = await IsarService.getTransactions(
          _dateFrom,
          _dateTo,
          _paymentFilter?.isEmpty == true ? null : _paymentFilter,
          _staffFilter?.isEmpty == true ? null : _staffFilter,
        );
        if (mounted) setState(() {
          _transactions = cached.map((t) => t.toListMap()).toList();
          _loading = false;
        });
        return;
      }
      final stale = await IsarService.isTransactionCacheStale();
      final cached = await IsarService.getTransactions(null, null, null, null);
      if (stale || cached.isEmpty) {
        final list = await _repo.getTransactions(
          start: _dateFrom,
          end: _dateTo,
          paymentMethod: _paymentFilter?.isEmpty == true ? null : _paymentFilter,
          staffId: _staffFilter?.isEmpty == true ? null : _staffFilter,
        );
        final toSave = list.map((row) {
          final profiles = row['profiles'];
          String? staffName;
          if (profiles is Map) staffName = profiles['full_name']?.toString();
          return CachedTransaction.fromSupabase(row, staffName: staffName);
        }).toList();
        await IsarService.saveTransactions(toSave);
        if (mounted) setState(() {
          _transactions = list;
          _loading = false;
        });
        return;
      }
      final fromCache = await IsarService.getTransactions(
        _dateFrom,
        _dateTo,
        _paymentFilter?.isEmpty == true ? null : _paymentFilter,
        _staffFilter?.isEmpty == true ? null : _staffFilter,
      );
      if (mounted) setState(() {
        _transactions = fromCache.map((t) => t.toListMap()).toList();
        _loading = false;
      });
      _repo.getTransactions(start: _dateFrom, end: _dateTo, paymentMethod: _paymentFilter, staffId: _staffFilter).then((list) async {
        if (list.isEmpty) return;
        final toSave = list.map((row) {
          final profiles = row['profiles'];
          String? staffName;
          if (profiles is Map) staffName = profiles['full_name']?.toString();
          return CachedTransaction.fromSupabase(row, staffName: staffName);
        }).toList();
        await IsarService.saveTransactions(toSave);
        if (mounted) _load();
      });
    } catch (e) {
      if (mounted) setState(() {
        _transactions = [];
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
        _dateFrom = DateTime(picked.start.year, picked.start.month, picked.start.day);
        _dateTo = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
      await _load();
    }
  }

  void _openDetail(Map<String, dynamic> txn) {
    final id = txn['id'] as String?;
    if (id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionDetailScreen(transactionId: id),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final totalRevenue = _transactions.fold<double>(0, (s, t) => s + ((t['total_amount'] as num?)?.toDouble() ?? 0));
    final totalCost = _transactions.fold<double>(0, (s, t) => s + ((t['cost_amount'] as num?)?.toDouble() ?? 0));
    final marginPct = totalRevenue > 0 ? ((totalRevenue - totalCost) / totalRevenue * 100) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          // Summary row
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
                _summaryChip('Transactions', '${_transactions.length}', Icons.receipt),
                _summaryChip('Revenue', 'R ${totalRevenue.toStringAsFixed(2)}', Icons.payments),
                _summaryChip('Cost', 'R ${totalCost.toStringAsFixed(2)}', Icons.shopping_cart),
                _summaryChip('Margin', '${marginPct.toStringAsFixed(1)}%', Icons.trending_up, color: AppColors.success),
              ],
            ),
          ),
          // Filters
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
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _paymentFilter ?? '',
                  hint: const Text('Payment'),
                  items: paymentOptions.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (v) {
                    setState(() => _paymentFilter = v);
                    _load();
                  },
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _staffFilter ?? '',
                  hint: const Text('Cashier'),
                  isExpanded: false,
                  items: [
                    const DropdownMenuItem(value: '', child: Text('All')),
                    ..._staffList.map((s) => DropdownMenuItem(
                          value: s['id'] as String? ?? '',
                          child: Text((s['full_name'] as String? ?? '').isEmpty ? 'Unknown' : s['full_name'] as String),
                        )),
                  ],
                  onChanged: (v) {
                    setState(() => _staffFilter = v);
                    _load();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _transactions.isEmpty
                    ? Center(
                        child: Text(
                          ConnectivityService().isConnected
                              ? 'No transactions for this period'
                              : 'No cached data available. Connect to the internet to load data.',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: _transactions.length,
                        itemBuilder: (context, i) {
                          final t = _transactions[i];
                          return _buildRow(t);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String value, IconData icon, {Color? color}) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color ?? AppColors.textSecondary),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? AppColors.textPrimary)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> t) {
    final createdAt = t['created_at'] != null ? DateTime.tryParse(t['created_at'] as String) : null;
    final timeStr = createdAt != null ? DateFormat('HH:mm').format(createdAt) : '—';
    final receiptNumber = t['receipt_number'] as String? ?? '—';
    final profiles = t['profiles'];
    String cashierName = '—';
    if (profiles is Map) cashierName = (profiles['full_name'] as String?) ?? '—';
    else if (profiles is List && profiles.isNotEmpty && profiles.first is Map) cashierName = ((profiles.first as Map)['full_name'] as String?) ?? '—';
    final paymentMethod = t['payment_method'] as String? ?? '—';
    final total = (t['total_amount'] as num?)?.toDouble() ?? 0;
    final isVoided = t['is_voided'] == true;
    final isRefund = t['is_refund'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.cardBg,
      child: InkWell(
        onTap: () => _openDetail(t),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(width: 48, child: Text(timeStr, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
              Expanded(flex: 2, child: Text(receiptNumber, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
              Expanded(flex: 2, child: Text(cashierName, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
              SizedBox(width: 72, child: Text(paymentMethod, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
              SizedBox(width: 80, child: Text('R ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              if (isVoided) Container(margin: const EdgeInsets.only(left: 4), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(4)), child: const Text('VOID', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold))),
              if (isRefund && !isVoided) Container(margin: const EdgeInsets.only(left: 4), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.info, borderRadius: BorderRadius.circular(4)), child: const Text('REFUND', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ),
    );
  }
}
