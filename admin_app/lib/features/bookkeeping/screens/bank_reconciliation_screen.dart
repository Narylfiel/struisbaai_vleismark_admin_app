import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/auth_service.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import '../services/bank_reconciliation_repository.dart';

class BankReconciliationScreen extends StatefulWidget {
  final bool embedded;
  const BankReconciliationScreen({super.key, this.embedded = false});

  @override
  State<BankReconciliationScreen> createState() =>
      _BankReconciliationScreenState();
}

class _BankReconciliationScreenState
    extends State<BankReconciliationScreen>
    with SingleTickerProviderStateMixin {
  final _repo = BankReconciliationRepository();
  late TabController _tabController;

  List<Map<String, dynamic>> _transactions = [];
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _accounts = [];
  bool _loading = true;
  String _statusFilter = '';

  static const _statusOptions = [
    MapEntry('', 'All'),
    MapEntry('unmatched', 'Unmatched'),
    MapEntry('matched', 'Matched'),
    MapEntry('manually_coded', 'Manually Coded'),
    MapEntry('excluded', 'Excluded'),
  ];

  final _currencyFmt = NumberFormat.currency(
      locale: 'en_ZA', symbol: 'R ', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _repo.getTransactions(
            status: _statusFilter.isEmpty ? null : _statusFilter),
        _repo.getSummary(),
        _repo.getChartOfAccounts(),
      ]);
      if (mounted) {
        setState(() {
          // SYSTEM CONTEXT: Defensive type safety
          _transactions = (results[0] as List?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ?? [];
          _summary = (results[1] as Map<String, dynamic>?) ?? {};
          _accounts = (results[2] as List?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ErrorHandler.friendlyMessage(e)),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Sub-tab bar ──────────────────────────────────────
        Container(
          color: AppColors.surfaceBg,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(
                  icon: Icon(Icons.list_alt, size: 18),
                  text: 'Transactions'),
              Tab(
                  icon: Icon(Icons.link, size: 18),
                  text: 'Match'),
              Tab(
                  icon: Icon(Icons.summarize, size: 18),
                  text: 'Summary'),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _TransactionsTab(
                transactions: _transactions,
                loading: _loading,
                statusFilter: _statusFilter,
                statusOptions: _statusOptions,
                currencyFmt: _currencyFmt,
                onFilterChanged: (v) {
                  setState(() => _statusFilter = v);
                  _load();
                },
                onAdd: () => _showAddDialog(),
                onImportCsv: () => _importCsv(),
                onDelete: (id) => _deleteTransaction(id),
                onRefresh: _load,
              ),
              _MatchTab(
                transactions: _transactions
                    .where((t) =>
                        t['status'] == 'unmatched')
                    .toList(),
                accounts: _accounts,
                currencyFmt: _currencyFmt,
                repo: _repo,
                onMatched: _load,
              ),
              _SummaryTab(
                summary: _summary,
                currencyFmt: _currencyFmt,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showAddDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _AddTransactionDialog(
        accounts: _accounts,
        repo: _repo,
      ),
    );
    if (result == true) _load();
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.single.bytes;
    if (bytes == null) return;

    final content = utf8.decode(bytes, allowMalformed: true);
    final rows = _repo.parseCapitecCsv(content);

    if (rows.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No valid transactions found in file. '
                'Check format: Post Date, Trans. Date, '
                'Description, Reference, Fees, Amount, Balance'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    // Show preview dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import Preview'),
        content: SizedBox( // ignore: prefer_const_constructors
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${rows.length} transaction(s) found in file.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'Duplicates (same date + description + amount) '
                'will be skipped automatically.',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              // Show first 5 rows as preview
              ...rows.take(5).map((r) => Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${r['post_date']}  ${r['description']}  '
                      '${r['amount']}',
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
              if (rows.length > 5)
                Text(
                  '… and ${rows.length - 5} more',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.upload, size: 16),
            label: const Text('Import'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final userId = AuthService().getCurrentStaffId();
      final inserted = await _repo.importCsvRows(
        rows: rows,
        createdBy: userId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(inserted == 0
                ? 'All transactions already exist — nothing imported'
                : '$inserted transaction(s) imported successfully'),
            backgroundColor: inserted == 0
                ? AppColors.warning
                : AppColors.success,
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ErrorHandler.friendlyMessage(e)),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _deleteTransaction(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text(
            'This will also remove any matches. Cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _repo.deleteTransaction(id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ErrorHandler.friendlyMessage(e)),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 1: TRANSACTIONS
// ══════════════════════════════════════════════════════════════════

class _TransactionsTab extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final bool loading;
  final String statusFilter;
  final List<MapEntry<String, String>> statusOptions;
  final NumberFormat currencyFmt;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onAdd;
  final VoidCallback onImportCsv;
  final ValueChanged<String> onDelete;
  final VoidCallback onRefresh;

  const _TransactionsTab({
    required this.transactions,
    required this.loading,
    required this.statusFilter,
    required this.statusOptions,
    required this.currencyFmt,
    required this.onFilterChanged,
    required this.onAdd,
    required this.onImportCsv,
    required this.onDelete,
    required this.onRefresh,
  });

  Color _statusColor(String? status) {
    switch (status) {
      case 'matched': return const Color(0xFF2E7D32);
      case 'manually_coded': return const Color(0xFF1565C0);
      case 'excluded': return AppColors.textSecondary;
      default: return AppColors.warning;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'matched': return 'Matched';
      case 'manually_coded': return 'Coded';
      case 'excluded': return 'Excluded';
      default: return 'Unmatched';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.cardBg,
          child: Row(
            children: [
              const Text('Bank Transactions',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: statusFilter,
                items: statusOptions
                    .map((e) => DropdownMenuItem(
                        value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) =>
                    onFilterChanged(v ?? ''),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onImportCsv,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Import CSV'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Transaction'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        // Column headers
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 10),
          color: AppColors.surfaceBg,
          child: const Row(
            children: [
              SizedBox(
                  width: 90,
                  child: Text('DATE',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5))),
              SizedBox(width: 8),
              Expanded(
                  child: Text('DESCRIPTION',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5))),
              SizedBox(width: 8),
              SizedBox(
                  width: 120,
                  child: Text('REFERENCE',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5))),
              SizedBox(width: 8),
              SizedBox(
                  width: 80,
                  child: Text('FEES',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5))),
              SizedBox(width: 8),
              SizedBox(
                  width: 100,
                  child: Text('AMOUNT',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5))),
              SizedBox(width: 8),
              SizedBox(
                  width: 100,
                  child: Text('BALANCE',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5))),
              SizedBox(width: 8),
              SizedBox(
                  width: 90,
                  child: Text('STATUS',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5))),
              SizedBox(width: 40),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : transactions.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.account_balance,
                              size: 48,
                              color: AppColors.textLight),
                          SizedBox(height: 8),
                          Text(
                              'No transactions yet. '
                              'Add entries from your bank statement.',
                              style: TextStyle(
                                  color:
                                      AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      itemCount: transactions.length,
                      separatorBuilder: (_, __) =>
                          const Divider(
                              height: 1,
                              color: AppColors.border),
                      itemBuilder: (_, i) {
                        final t = transactions[i];
                        final amt =
                            (t['amount'] as num?)
                                    ?.toDouble() ??
                                0;
                        final fees =
                            (t['fees'] as num?)
                                    ?.toDouble() ??
                                0;
                        final bal =
                            (t['balance'] as num?)
                                ?.toDouble();
                        final status =
                            t['status']?.toString() ??
                                'unmatched';
                        return Padding(
                          padding:
                              const EdgeInsets.symmetric(
                                  vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 90,
                                child: Text(
                                  t['post_date']
                                          ?.toString()
                                          .substring(
                                              0, 10) ??
                                      '—',
                                  style: const TextStyle(
                                      fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  t['description']
                                          ?.toString() ??
                                      '—',
                                  style: const TextStyle(
                                      fontWeight:
                                          FontWeight.w500,
                                      fontSize: 12),
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 120,
                                child: Text(
                                  t['reference']
                                          ?.toString() ??
                                      '—',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors
                                          .textSecondary),
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  fees != 0
                                      ? currencyFmt
                                          .format(fees)
                                      : '—',
                                  textAlign:
                                      TextAlign.right,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: fees != 0
                                          ? AppColors.error
                                          : AppColors
                                              .textSecondary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  currencyFmt.format(amt),
                                  textAlign:
                                      TextAlign.right,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.bold,
                                      color: amt >= 0
                                          ? const Color(
                                              0xFF2E7D32)
                                          : AppColors
                                              .error),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  bal != null
                                      ? currencyFmt
                                          .format(bal)
                                      : '—',
                                  textAlign:
                                      TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 90,
                                child: Container(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                          horizontal: 8,
                                          vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _statusColor(
                                            status)
                                        .withValues(
                                            alpha: 0.12),
                                    borderRadius:
                                        BorderRadius
                                            .circular(4),
                                  ),
                                  child: Text(
                                    _statusLabel(status),
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight:
                                            FontWeight.bold,
                                        color:
                                            _statusColor(
                                                status)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 32,
                                child: IconButton(
                                  icon: const Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                      color:
                                          AppColors.error),
                                  onPressed: () =>
                                      onDelete(
                                          t['id']
                                              .toString()),
                                  tooltip:
                                      'Delete transaction',
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 2: MATCH
// ══════════════════════════════════════════════════════════════════

class _MatchTab extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final List<Map<String, dynamic>> accounts;
  final NumberFormat currencyFmt;
  final BankReconciliationRepository repo;
  final VoidCallback onMatched;

  const _MatchTab({
    required this.transactions,
    required this.accounts,
    required this.currencyFmt,
    required this.repo,
    required this.onMatched,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 48, color: Color(0xFF2E7D32)),
            SizedBox(height: 8),
            Text('All transactions are matched.',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: transactions.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final t = transactions[i];
        return _MatchCard(
          transaction: t,
          accounts: accounts,
          currencyFmt: currencyFmt,
          repo: repo,
          onMatched: onMatched,
        );
      },
    );
  }
}

class _MatchCard extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final List<Map<String, dynamic>> accounts;
  final NumberFormat currencyFmt;
  final BankReconciliationRepository repo;
  final VoidCallback onMatched;

  const _MatchCard({
    required this.transaction,
    required this.accounts,
    required this.currencyFmt,
    required this.repo,
    required this.onMatched,
  });

  @override
  State<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<_MatchCard> {
  List<Map<String, dynamic>> _invoiceCandidates = [];
  bool _loadingCandidates = false;
  String? _selectedAccountCode;
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCandidates() async {
    setState(() => _loadingCandidates = true);
    try {
      final amt =
          (widget.transaction['amount'] as num?)
                  ?.toDouble() ??
              0;
      final results = await Future.wait([
        widget.repo.findSupplierInvoiceCandidates(
            amount: amt),
        widget.repo.findLedgerCandidates(amount: amt),
      ]);
      if (mounted) {
        setState(() {
          _invoiceCandidates =
              List<Map<String, dynamic>>.from(results[0] as List);
          // Ledger candidates loaded for potential future use
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingCandidates = false);
    }
  }

  Future<void> _matchToInvoice(
      Map<String, dynamic> invoice) async {
    final accountCode = _selectedAccountCode ?? '2000';
    try {
      await widget.repo.createMatch(
        bankTransactionId:
            widget.transaction['id'].toString(),
        matchType: 'supplier_invoice',
        matchedRecordId: invoice['id'].toString(),
        matchedAmount:
            (invoice['total'] as num?)?.toDouble() ?? 0,
        accountCode: accountCode,
        notes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
        createdBy:
            AuthService().getCurrentStaffId(),
      );
      widget.onMatched();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    ErrorHandler.friendlyMessage(e)),
                backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _matchManual() async {
    if (_selectedAccountCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Select a chart of accounts code first'),
            backgroundColor: AppColors.warning),
      );
      return;
    }
    try {
      final amt =
          (widget.transaction['amount'] as num?)
                  ?.toDouble() ??
              0;
      await widget.repo.createMatch(
        bankTransactionId:
            widget.transaction['id'].toString(),
        matchType: 'manual',
        matchedAmount: amt,
        accountCode: _selectedAccountCode!,
        notes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
        createdBy:
            AuthService().getCurrentStaffId(),
      );
      widget.onMatched();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    ErrorHandler.friendlyMessage(e)),
                backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _exclude() async {
    await widget.repo.updateTransactionStatus(
      id: widget.transaction['id'].toString(),
      status: 'excluded',
      notes: 'Excluded by user',
    );
    widget.onMatched();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final amt =
        (t['amount'] as num?)?.toDouble() ?? 0;
    final fees =
        (t['fees'] as num?)?.toDouble() ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction header
            Row(
              children: [
                Icon(
                  amt >= 0
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  color: amt >= 0
                      ? const Color(0xFF2E7D32)
                      : AppColors.error,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t['description']?.toString() ?? '—',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
                Text(
                  widget.currencyFmt.format(amt),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: amt >= 0
                          ? const Color(0xFF2E7D32)
                          : AppColors.error),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  t['post_date']
                          ?.toString()
                          .substring(0, 10) ??
                      '—',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary),
                ),
                if (t['reference'] != null) ...[
                  const Text(' · ',
                      style: TextStyle(
                          color: AppColors.textSecondary)),
                  Text(
                    t['reference'].toString(),
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary),
                  ),
                ],
                if (fees != 0) ...[
                  const Text(' · ',
                      style: TextStyle(
                          color: AppColors.textSecondary)),
                  Text(
                    'Fees: ${widget.currencyFmt.format(fees)}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.error),
                  ),
                ],
              ],
            ),
            const Divider(height: 20),

            // Suggested invoice matches
            if (_loadingCandidates)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Finding matches…',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ],
                ),
              )
            else if (_invoiceCandidates.isNotEmpty) ...[
              const Text('Suggested invoice matches:',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              ..._invoiceCandidates.take(3).map((inv) {
                final supplierName = inv['suppliers']
                        ?['name']
                        ?.toString() ??
                    '—';
                final total =
                    (inv['total'] as num?)?.toDouble() ??
                        0;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                      Icons.local_shipping_outlined,
                      size: 18,
                      color: AppColors.primary),
                  title: Text(
                    '$supplierName — ${inv['invoice_number'] ?? '—'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  subtitle: Text(
                    '${inv['invoice_date']?.toString().substring(0, 10) ?? ''} · '
                    '${widget.currencyFmt.format(total)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: TextButton(
                    onPressed: () =>
                        _matchToInvoice(inv),
                    child: const Text('Match'),
                  ),
                );
              }),
              const Divider(height: 16),
            ],

            // Manual coding
            const Text('Or code manually:',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedAccountCode,
                    decoration: const InputDecoration(
                      labelText: 'Chart of Accounts',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    items: widget.accounts
                        .map((a) => DropdownMenuItem<String>(
                              value: a['code']?.toString(),
                              child: Text(
                                '${a['code']} — ${a['name']}',
                                style: const TextStyle(
                                    fontSize: 12),
                                overflow:
                                    TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(
                        () => _selectedAccountCode = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    style:
                        const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _matchManual,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Code to Account'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10)),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _exclude,
                  icon: const Icon(Icons.block, size: 16),
                  label: const Text('Exclude'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor:
                          AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 3: SUMMARY
// ══════════════════════════════════════════════════════════════════

class _SummaryTab extends StatelessWidget {
  final Map<String, dynamic> summary;
  final NumberFormat currencyFmt;

  const _SummaryTab({
    required this.summary,
    required this.currencyFmt,
  });

  @override
  Widget build(BuildContext context) {
    final total = (summary['total'] as num?)?.toInt() ?? 0;
    final matched =
        (summary['matched'] as num?)?.toInt() ?? 0;
    final unmatched =
        (summary['unmatched'] as num?)?.toInt() ?? 0;
    final manuallyCoded =
        (summary['manually_coded'] as num?)?.toInt() ?? 0;
    final excluded =
        (summary['excluded'] as num?)?.toInt() ?? 0;
    final totalIn =
        (summary['total_in'] as num?)?.toDouble() ?? 0;
    final totalOut =
        (summary['total_out'] as num?)?.toDouble() ?? 0;
    final totalFees =
        (summary['total_fees'] as num?)?.toDouble() ?? 0;
    final pct =
        total > 0 ? ((matched + manuallyCoded) / total * 100) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          const Text('Reconciliation Progress',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 12,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF2E7D32)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${pct.toStringAsFixed(1)}% reconciled '
            '(${matched + manuallyCoded} of $total transactions)',
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Status breakdown
          const Text('Status Breakdown',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _summaryTile('Total', '$total',
                  AppColors.primary),
              _summaryTile('Unmatched', '$unmatched',
                  AppColors.warning),
              _summaryTile('Matched', '$matched',
                  const Color(0xFF2E7D32)),
              _summaryTile('Coded', '$manuallyCoded',
                  const Color(0xFF1565C0)),
              _summaryTile('Excluded', '$excluded',
                  AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 24),

          // Money summary
          const Text('Money Summary',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _summaryTile('Total In',
                  currencyFmt.format(totalIn),
                  const Color(0xFF2E7D32)),
              _summaryTile('Total Out',
                  currencyFmt.format(totalOut),
                  AppColors.error),
              _summaryTile('Bank Fees',
                  currencyFmt.format(totalFees),
                  AppColors.warning),
              _summaryTile(
                  'Net',
                  currencyFmt.format(totalIn - totalOut),
                  AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(
      String label, String value, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// ADD TRANSACTION DIALOG
// ══════════════════════════════════════════════════════════════════

class _AddTransactionDialog extends StatefulWidget {
  final List<Map<String, dynamic>> accounts;
  final BankReconciliationRepository repo;

  const _AddTransactionDialog({
    required this.accounts,
    required this.repo,
  });

  @override
  State<_AddTransactionDialog> createState() =>
      _AddTransactionDialogState();
}

class _AddTransactionDialogState
    extends State<_AddTransactionDialog> {
  DateTime _postDate = DateTime.now();
  DateTime _transDate = DateTime.now();
  final _descCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _feesCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _refCtrl.dispose();
    _amountCtrl.dispose();
    _feesCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  Future<void> _pickDate(bool isPost) async {
    final current = isPost ? _postDate : _transDate;
    final d = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(
          const Duration(days: 365)),
    );
    if (d != null && mounted) {
      setState(() {
        if (isPost) {
          _postDate = d;
        } else {
          _transDate = d;
        }
      });
    }
  }

  Future<void> _save() async {
    final desc = _descCtrl.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Description is required'),
            backgroundColor: AppColors.warning),
      );
      return;
    }
    final amount =
        double.tryParse(_amountCtrl.text.trim());
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Enter a valid amount (use - for debits, e.g. -500.00)'),
            backgroundColor: AppColors.warning),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.repo.createTransaction(
        postDate: _postDate,
        transDate: _transDate,
        description: desc,
        reference: _refCtrl.text.trim().isEmpty
            ? null
            : _refCtrl.text.trim(),
        fees: double.tryParse(
                _feesCtrl.text.trim()) ??
            0,
        amount: amount,
        balance: double.tryParse(
            _balanceCtrl.text.trim()),
        createdBy:
            AuthService().getCurrentStaffId(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    ErrorHandler.friendlyMessage(e)),
                backgroundColor: AppColors.error));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.account_balance,
                color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Add Bank Transaction',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Dates
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text('Post Date',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.bold)),
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _pickDate(true),
                        icon: const Icon(
                            Icons.calendar_today,
                            size: 14),
                        label: Text(_fmt(_postDate),
                            style: const TextStyle(
                                fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text('Transaction Date',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.bold)),
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _pickDate(false),
                        icon: const Icon(
                            Icons.calendar_today,
                            size: 14),
                        label: Text(
                            _fmt(_transDate),
                            style: const TextStyle(
                                fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              // Description
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              // Reference
              TextField(
                controller: _refCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reference',
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              // Amount + Fees
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType:
                        const TextInputType
                            .numberWithOptions(
                            decimal: true,
                            signed: true),
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Amount * (- for debit)',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _feesCtrl,
                    keyboardType:
                        const TextInputType
                            .numberWithOptions(
                            decimal: true,
                            signed: true),
                    decoration:
                        const InputDecoration(
                      labelText: 'Fees',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              // Balance
              TextField(
                controller: _balanceCtrl,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                        decimal: true,
                        signed: true),
                decoration: const InputDecoration(
                  labelText:
                      'Running Balance (optional)',
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tip: Credits are positive (+200.00), '
                'debits are negative (-500.00). '
                'Fees are entered as negative numbers.',
                style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white))
              : const Icon(Icons.save, size: 16),
          label:
              Text(_saving ? 'Saving…' : 'Save'),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white),
        ),
      ],
    );
  }
}
