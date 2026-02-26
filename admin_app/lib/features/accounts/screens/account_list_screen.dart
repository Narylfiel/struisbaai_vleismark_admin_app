import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/auth_service.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/audit_service.dart';
import 'package:admin_app/features/accounts/screens/account_detail_screen.dart';
import 'package:admin_app/features/bookkeeping/services/ledger_repository.dart';

class AccountListScreen extends StatefulWidget {
  const AccountListScreen({super.key});

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(children: [
        Container(
          color: AppColors.cardBg,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(icon: Icon(Icons.business, size: 18), text: 'Business Accounts'),
              Tab(icon: Icon(Icons.receipt_long, size: 18), text: 'Account Statements'),
              Tab(icon: Icon(Icons.warning_amber, size: 18), text: 'Overdue Management'),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _BusinessAccountsTab(),
              _AccountStatementsTab(),
              _OverdueTab(),
            ],
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 1 — BUSINESS ACCOUNTS DASHBOARD
// Blueprint 8.1 + 8.2
// ══════════════════════════════════════════════════════════════════

class _BusinessAccountsTab extends StatefulWidget {
  const _BusinessAccountsTab();
  @override
  State<_BusinessAccountsTab> createState() => _BusinessAccountsTabState();
}

class _BusinessAccountsTabState extends State<_BusinessAccountsTab> {
  final _supabase = SupabaseService.client;
  List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = true;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      var q = _supabase.from('business_accounts').select('*');
      if (!_showInactive) q = q.eq('is_active', true);
      final data = await q.order('name');
      setState(() => _accounts = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Accounts: $e');
    }
    setState(() => _isLoading = false);
  }

  // Overdue days: days since oldest unpaid balance exceeded credit terms
  int _overdueDays(Map<String, dynamic> acc) {
    final balance = (acc['balance'] as num?)?.toDouble() ?? 0;
    if (balance <= 0) return 0;
    final terms = (acc['credit_terms_days'] as num?)?.toInt() ?? 7;
    // Simplified: use updated_at as proxy until proper aging is implemented
    final updated = acc['updated_at'] != null
        ? DateTime.parse(acc['updated_at'])
        : DateTime.now();
    final daysSince = DateTime.now().difference(updated).inDays;
    return (daysSince - terms).clamp(0, 9999);
  }

  Color _statusColor(Map<String, dynamic> acc) {
    final suspended = acc['suspended'] as bool? ?? false;
    if (suspended) return AppColors.error;
    final days = _overdueDays(acc);
    if (days >= 7) return AppColors.error;
    if (days >= 1) return AppColors.warning;
    return AppColors.success;
  }

  String _statusLabel(Map<String, dynamic> acc) {
    final suspended = acc['suspended'] as bool? ?? false;
    if (suspended) return 'SUSPENDED';
    final days = _overdueDays(acc);
    if (days >= 1) return '$days d overdue';
    return 'OK';
  }

  IconData _statusIcon(Map<String, dynamic> acc) {
    final suspended = acc['suspended'] as bool? ?? false;
    if (suspended) return Icons.block;
    final days = _overdueDays(acc);
    if (days >= 7) return Icons.error;
    if (days >= 1) return Icons.warning_amber;
    return Icons.check_circle;
  }

  void _openAccount(Map<String, dynamic>? acc) {
    showDialog(
      context: context,
      builder: (_) => _AccountFormDialog(account: acc, onSaved: _load),
    );
  }

  void _openDetail(Map<String, dynamic> a) {
    final id = a['id']?.toString();
    if (id == null || id.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AccountDetailScreen(accountId: id),
      ),
    );
  }

  void _recordPayment(Map<String, dynamic> acc) {
    // C4: Block when not logged in (ledger requires recordedBy)
    if (AuthService().currentStaffId == null || AuthService().currentStaffId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in with PIN to record payments'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => _PaymentDialog(account: acc, onSaved: _load),
    );
  }

  Future<void> _toggleSuspend(Map<String, dynamic> acc) async {
    final isSuspended = acc['suspended'] as bool? ?? false;
    final customerName = acc['name'] ?? 'Unknown';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isSuspended ? 'Re-enable Account?' : 'Suspend Account?'),
        content: Text(isSuspended
            ? 'This will allow ${acc['name']} to purchase on account again at POS.'
            : '${acc['name']} will be blocked from purchasing on account at POS immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: isSuspended ? AppColors.success : AppColors.error),
            child: Text(isSuspended ? 'Re-enable' : 'Suspend'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _supabase.from('business_accounts').update({
      'suspended': !isSuspended,
      'suspended_at': !isSuspended ? DateTime.now().toIso8601String() : null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', acc['id']);
    
    // Audit log - account suspension/reactivation
    await AuditService.log(
      action: 'UPDATE',
      module: 'Accounts',
      description: isSuspended ? 'Account reactivated: $customerName' : 'Account suspended: $customerName',
      entityType: 'Account',
      entityId: acc['id'],
    );
    
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final totalExposure = _accounts.fold<double>(
        0, (s, a) => s + ((a['balance'] as num?)?.toDouble() ?? 0));
    final overdueCount =
        _accounts.where((a) => _overdueDays(a) >= 1).length;

    return Column(children: [
      // ── Summary bar ─────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        color: AppColors.cardBg,
        child: Row(children: [
          _summaryCard('Total Accounts', '${_accounts.length}',
              AppColors.info, Icons.business),
          const SizedBox(width: 16),
          _summaryCard('Total Outstanding',
              'R ${totalExposure.toStringAsFixed(2)}',
              AppColors.warning, Icons.account_balance_wallet),
          const SizedBox(width: 16),
          _summaryCard('Overdue Accounts', '$overdueCount',
              overdueCount > 0 ? AppColors.error : AppColors.success,
              Icons.warning_amber),
          const Spacer(),
          Row(children: [
            Switch(
              value: _showInactive,
              onChanged: (v) { setState(() => _showInactive = v); _load(); },
              activeThumbColor: AppColors.primary,
            ),
            const Text('Show inactive',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ]),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => _openAccount(null),
            icon: const Icon(Icons.add_business, size: 18),
            label: const Text('Add Account'),
          ),
        ]),
      ),
      const Divider(height: 1, color: AppColors.border),
      // ── NOTE banner ─────────────────────────────────────────────
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        color: AppColors.info.withOpacity(0.06),
        child: const Row(children: [
          Icon(Icons.info_outline, size: 14, color: AppColors.info),
          SizedBox(width: 8),
          Text(
            'Business accounts only — select restaurants and caterers at owner\'s discretion. '
            'No general public credit.',
            style: TextStyle(fontSize: 12, color: AppColors.info),
          ),
        ]),
      ),
      const Divider(height: 1, color: AppColors.border),
      // ── Table header ─────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        color: AppColors.surfaceBg,
        child: const Row(children: [
          Expanded(flex: 3, child: Text('BUSINESS', style: _hS)),
          SizedBox(width: 12),
          Expanded(flex: 2, child: Text('CONTACT', style: _hS)),
          SizedBox(width: 12),
          SizedBox(width: 90,  child: Text('BALANCE', style: _hS)),
          SizedBox(width: 12),
          SizedBox(width: 90,  child: Text('LIMIT', style: _hS)),
          SizedBox(width: 12),
          SizedBox(width: 90,  child: Text('AVAILABLE', style: _hS)),
          SizedBox(width: 12),
          SizedBox(width: 100, child: Text('STATUS', style: _hS)),
          SizedBox(width: 12),
          SizedBox(width: 60,  child: Text('TERMS', style: _hS)),
          SizedBox(width: 12),
          SizedBox(width: 160, child: Text('ACTIONS', style: _hS)),
        ]),
      ),
      const Divider(height: 1, color: AppColors.border),
      // ── List ─────────────────────────────────────────────────────
      Expanded(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _accounts.isEmpty
                ? _empty()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _accounts.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (_, i) {
                      final a = _accounts[i];
                      final balance =
                          (a['balance'] as num?)?.toDouble() ?? 0;
                      final limit =
                          (a['credit_limit'] as num?)?.toDouble() ?? 0;
                      final available = (limit - balance).clamp(0, limit);
                      final usedPct =
                          limit > 0 ? (balance / limit).clamp(0.0, 1.0) : 0.0;
                      final statusColor = _statusColor(a);
                      final suspended = a['suspended'] as bool? ?? false;

                      return InkWell(
                        onTap: () => _openDetail(a),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(children: [
                            // Business name + type
                            Expanded(
                            flex: 3,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(a['name'] ?? '—',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                              if (a['account_type'] != null)
                                Text(a['account_type'],
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary)),
                              // Credit used bar
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: usedPct,
                                  minHeight: 4,
                                  backgroundColor: AppColors.border,
                                  valueColor: AlwaysStoppedAnimation(
                                    usedPct > 0.9
                                        ? AppColors.error
                                        : usedPct > 0.7
                                            ? AppColors.warning
                                            : AppColors.success,
                                  ),
                                ),
                              ),
                            ]),
                          ),
                          const SizedBox(width: 12),
                          // Contact
                          Expanded(
                            flex: 2,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              if (a['contact_person'] != null)
                                Text(a['contact_person'],
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textPrimary)),
                              if (a['whatsapp'] != null || a['phone'] != null)
                                Text(a['whatsapp'] ?? a['phone'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary)),
                              if (a['email'] != null)
                                Text(a['email'],
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis),
                            ]),
                          ),
                          const SizedBox(width: 12),
                          // Balance
                          SizedBox(
                            width: 90,
                            child: Text(
                              'R ${balance.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: balance > 0
                                      ? AppColors.warning
                                      : AppColors.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Limit
                          SizedBox(
                            width: 90,
                            child: Text(
                              'R ${limit.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Available
                          SizedBox(
                            width: 90,
                            child: Text(
                              'R ${available.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: available < limit * 0.2
                                      ? AppColors.error
                                      : AppColors.success),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Status badge
                          SizedBox(
                            width: 100,
                            child: Row(children: [
                              Icon(_statusIcon(a),
                                  size: 15, color: statusColor),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(_statusLabel(a),
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor)),
                              ),
                            ]),
                          ),
                          const SizedBox(width: 12),
                          // Terms
                          SizedBox(
                            width: 60,
                            child: Text(
                              '${a['credit_terms_days'] ?? 7} days',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Actions
                          SizedBox(
                            width: 160,
                            child: Row(children: [
                              // View detail
                              _actionBtn(
                                icon: Icons.visibility,
                                color: AppColors.primary,
                                tooltip: 'View Account',
                                onTap: () => _openDetail(a),
                              ),
                              const SizedBox(width: 4),
                              // Record payment
                              if (balance > 0)
                                _actionBtn(
                                  icon: Icons.payment,
                                  color: AppColors.success,
                                  tooltip: 'Record Payment',
                                  onTap: () => _recordPayment(a),
                                ),
                              const SizedBox(width: 4),
                              // Edit
                              _actionBtn(
                                icon: Icons.edit,
                                color: AppColors.primary,
                                tooltip: 'Edit Account',
                                onTap: () => _openAccount(a),
                              ),
                              const SizedBox(width: 4),
                              // Suspend / Re-enable
                              _actionBtn(
                                icon: suspended
                                    ? Icons.check_circle_outline
                                    : Icons.block,
                                color: suspended
                                    ? AppColors.success
                                    : AppColors.error,
                                tooltip: suspended
                                    ? 'Re-enable Account'
                                    : 'Suspend Account',
                                onTap: () => _toggleSuspend(a),
                              ),
                            ]),
                          ),
                        ]),
                        ),
                      );
                    },
                  ),
      ),
    ]);
  }

  Widget _summaryCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ]),
      ]),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.business_outlined, size: 64, color: AppColors.border),
        const SizedBox(height: 16),
        const Text('No business accounts yet',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        const Text('Only select businesses (restaurants, caterers) at owner\'s discretion',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => _openAccount(null),
          icon: const Icon(Icons.add_business),
          label: const Text('Add First Account'),
        ),
      ]),
    );
  }

  static const _hS = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: AppColors.textSecondary,
      letterSpacing: 0.5);
}

// ══════════════════════════════════════════════════════════════════
// TAB 2 — ACCOUNT STATEMENTS
// Blueprint 8.4
// ══════════════════════════════════════════════════════════════════

class _AccountStatementsTab extends StatefulWidget {
  const _AccountStatementsTab();
  @override
  State<_AccountStatementsTab> createState() => _AccountStatementsTabState();
}

class _AccountStatementsTabState extends State<_AccountStatementsTab> {
  final _supabase = SupabaseService.client;
  List<Map<String, dynamic>> _accounts = [];
  Map<String, dynamic>? _selectedAccount;
  List<Map<String, dynamic>> _transactions = [];
  bool _loadingAccounts = true;
  bool _loadingTxns = false;

  // Period
  DateTime _periodStart =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _periodEnd = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _loadingAccounts = true);
    try {
      final data = await _supabase
          .from('business_accounts')
          .select('id, name, balance, credit_limit, credit_terms_days, '
              'contact_person, email, whatsapp, phone, vat_number, suspended')
          .eq('is_active', true)
          .order('name');
      setState(() => _accounts = List<Map<String, dynamic>>.from(data));
      if (_accounts.isNotEmpty && _selectedAccount == null) {
        _selectedAccount = _accounts.first;
        _loadTransactions();
      }
    } catch (e) {
      debugPrint('Accounts: $e');
    }
    setState(() => _loadingAccounts = false);
  }

  Future<void> _loadTransactions() async {
    if (_selectedAccount == null) return;
    setState(() => _loadingTxns = true);
    try {
      final data = await _supabase
          .from('account_transactions')
          .select('*')
          .eq('account_id', _selectedAccount!['id'])
          .gte('transaction_date', _periodStart.toIso8601String().substring(0, 10))
          .lte('transaction_date', _periodEnd.toIso8601String().substring(0, 10))
          .order('transaction_date')
          .order('created_at');
      setState(() => _transactions = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Transactions: $e');
    }
    setState(() => _loadingTxns = false);
  }

  double get _openingBalance {
    // Rough: current balance minus sum of period transactions
    final current =
        (_selectedAccount?['balance'] as num?)?.toDouble() ?? 0;
    final periodNet = _transactions.fold<double>(0, (s, t) {
      final amt = (t['amount'] as num?)?.toDouble() ?? 0;
      return t['transaction_type'] == 'sale' ? s + amt : s - amt;
    });
    return current - periodNet;
  }

  double get _periodPurchases => _transactions
      .where((t) => t['transaction_type'] == 'sale')
      .fold(0, (s, t) => s + ((t['amount'] as num?)?.toDouble() ?? 0));

  double get _periodPayments => _transactions
      .where((t) => t['transaction_type'] == 'payment')
      .fold(0, (s, t) => s + ((t['amount'] as num?)?.toDouble() ?? 0));

  double get _closingBalance => _openingBalance + _periodPurchases - _periodPayments;

  String _fmtDate(String? d) {
    if (d == null) return '—';
    try {
      final dt = DateTime.parse(d);
      const m = ['Jan','Feb','Mar','Apr','May','Jun',
                  'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day.toString().padLeft(2,'0')} ${m[dt.month-1]}';
    } catch (_) { return d; }
  }

  @override
  Widget build(BuildContext context) {
    final acc = _selectedAccount;

    return Row(children: [
      // ── Left: account selector ──────────────────────────────────
      SizedBox(
        width: 220,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.cardBg,
            child: const Text('SELECT ACCOUNT',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5)),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _loadingAccounts
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary))
                : ListView.separated(
                    itemCount: _accounts.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (_, i) {
                      final a = _accounts[i];
                      final isSelected =
                          _selectedAccount?['id'] == a['id'];
                      final balance =
                          (a['balance'] as num?)?.toDouble() ?? 0;
                      return InkWell(
                        onTap: () {
                          setState(() => _selectedAccount = a);
                          _loadTransactions();
                        },
                        child: Container(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.08)
                              : Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(children: [
                            Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                Text(a['name'] ?? '—',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textPrimary)),
                                Text(
                                  'R ${balance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: balance > 0
                                          ? AppColors.warning
                                          : AppColors.textSecondary),
                                ),
                              ]),
                            ),
                            if (isSelected)
                              const Icon(Icons.chevron_right,
                                  size: 16, color: AppColors.primary),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
      const VerticalDivider(width: 1, color: AppColors.border),

      // ── Right: statement ────────────────────────────────────────
      Expanded(
        child: acc == null
            ? const Center(
                child: Text('Select an account to view statement',
                    style: TextStyle(color: AppColors.textSecondary)))
            : Column(children: [
                // Period picker toolbar
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  color: AppColors.cardBg,
                  child: Row(children: [
                    Text(acc['name'] ?? '—',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    if (acc['vat_number'] != null) ...[
                      const SizedBox(width: 12),
                      Text('VAT: ${acc['vat_number']}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ],
                    const Spacer(),
                    // Period: start
                    _datePicker(
                      label: 'From',
                      date: _periodStart,
                      onPicked: (d) {
                        setState(() => _periodStart = d);
                        _loadTransactions();
                      },
                    ),
                    const SizedBox(width: 8),
                    _datePicker(
                      label: 'To',
                      date: _periodEnd,
                      onPicked: (d) {
                        setState(() => _periodEnd = d);
                        _loadTransactions();
                      },
                    ),
                  ]),
                ),
                const Divider(height: 1, color: AppColors.border),

                // Statement summary
                Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom:
                                BorderSide(color: AppColors.border)),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('STATEMENT: ${acc['name']}',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                        if (acc['vat_number'] != null)
                          Text('VAT Number: ${acc['vat_number']}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        Text(
                          'Period: ${_fmtDate(_periodStart.toIso8601String())} '
                          '– ${_fmtDate(_periodEnd.toIso8601String())} ${_periodEnd.year}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                      ]),
                    ),
                    // Balances
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        _stmtRow('Opening Balance',
                            'R ${_openingBalance.toStringAsFixed(2)}',
                            bold: false),
                        _stmtRow('+ Purchases',
                            'R ${_periodPurchases.toStringAsFixed(2)}',
                            bold: false, color: AppColors.warning),
                        _stmtRow('− Payments',
                            '−R ${_periodPayments.toStringAsFixed(2)}',
                            bold: false, color: AppColors.success),
                        const Divider(color: AppColors.border),
                        _stmtRow('= Closing Balance',
                            'R ${_closingBalance.toStringAsFixed(2)}',
                            bold: true),
                        const SizedBox(height: 4),
                        Row(children: [
                          Text(
                            'Terms: ${acc['credit_terms_days'] ?? 7} days  |  ',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                          Text(
                            acc['suspended'] == true
                                ? 'Status: SUSPENDED'
                                : _closingBalance > 0
                                    ? 'Status: OUTSTANDING'
                                    : 'Status: CLEAR',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: acc['suspended'] == true
                                    ? AppColors.error
                                    : _closingBalance > 0
                                        ? AppColors.warning
                                        : AppColors.success),
                          ),
                        ]),
                      ]),
                    ),
                  ]),
                ),

                // Transactions list
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Row(children: [
                    Text('TRANSACTIONS',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5)),
                  ]),
                ),
                Expanded(
                  child: _loadingTxns
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : _transactions.isEmpty
                          ? const Center(
                              child: Text('No transactions for this period',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)))
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                  20, 0, 20, 20),
                              itemCount: _transactions.length,
                              separatorBuilder: (_, __) => const Divider(
                                  height: 1, color: AppColors.border),
                              itemBuilder: (_, i) {
                                final t = _transactions[i];
                                final isPayment =
                                    t['transaction_type'] == 'payment';
                                final amt =
                                    (t['amount'] as num?)?.toDouble() ?? 0;
                                final runBal =
                                    (t['running_balance'] as num?)?.toDouble();

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8),
                                  child: Row(children: [
                                    // Date
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                          _fmtDate(t['transaction_date']),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color:
                                                  AppColors.textSecondary)),
                                    ),
                                    const SizedBox(width: 12),
                                    // Reference + description
                                    Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(
                                          t['reference'] ??
                                              (isPayment
                                                  ? 'Payment'
                                                  : 'Sale'),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  AppColors.textPrimary),
                                        ),
                                        if (t['description'] != null)
                                          Text(t['description'],
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors
                                                      .textSecondary)),
                                        if (isPayment &&
                                            t['payment_method'] != null)
                                          Text(t['payment_method'],
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      AppColors.success)),
                                      ]),
                                    ),
                                    const SizedBox(width: 12),
                                    // Amount
                                    Text(
                                      isPayment
                                          ? '−R ${amt.toStringAsFixed(2)}'
                                          : 'R ${amt.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isPayment
                                              ? AppColors.success
                                              : AppColors.warning),
                                    ),
                                    const SizedBox(width: 16),
                                    // Running balance
                                    if (runBal != null)
                                      SizedBox(
                                        width: 80,
                                        child: Text(
                                          'Bal: R ${runBal.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color:
                                                  AppColors.textSecondary),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                  ]),
                                );
                              },
                            ),
                ),
              ]),
      ),
    ]);
  }

  Widget _stmtRow(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight:
                    bold ? FontWeight.bold : FontWeight.normal,
                color: AppColors.textPrimary)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight:
                    bold ? FontWeight.bold : FontWeight.normal,
                color: color ?? AppColors.textPrimary)),
      ]),
    );
  }

  Widget _datePicker({
    required String label,
    required DateTime date,
    required ValueChanged<DateTime> onPicked,
  }) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (d != null) onPicked(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today,
              size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            '$label: ${date.day} ${months[date.month - 1]} ${date.year}',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textPrimary),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 3 — OVERDUE MANAGEMENT
// Blueprint 8.5 (changes file) — NO auto-suspend default
// ══════════════════════════════════════════════════════════════════

class _OverdueTab extends StatefulWidget {
  const _OverdueTab();
  @override
  State<_OverdueTab> createState() => _OverdueTabState();
}

class _OverdueTabState extends State<_OverdueTab> {
  final _supabase = SupabaseService.client;
  List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('business_accounts')
          .select('*')
          .eq('is_active', true)
          .gt('balance', 0)
          .order('balance', ascending: false);
      setState(() => _accounts = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Overdue: $e');
    }
    setState(() => _isLoading = false);
  }

  int _overdueDays(Map<String, dynamic> acc) {
    final terms = (acc['credit_terms_days'] as num?)?.toInt() ?? 7;
    final updated = acc['updated_at'] != null
        ? DateTime.parse(acc['updated_at'])
        : DateTime.now();
    final daysSince = DateTime.now().difference(updated).inDays;
    return (daysSince - terms).clamp(0, 9999);
  }

  Future<void> _toggleSuspend(Map<String, dynamic> acc) async {
    final isSuspended = acc['suspended'] as bool? ?? false;
    await _supabase.from('business_accounts').update({
      'suspended': !isSuspended,
      'suspended_at':
          !isSuspended ? DateTime.now().toIso8601String() : null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', acc['id']);
    _load();
  }

  Future<void> _saveAutoSuspendSettings(
      Map<String, dynamic> acc, bool enabled, int days) async {
    await _supabase.from('business_accounts').update({
      'auto_suspend': enabled,
      'auto_suspend_days': days,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', acc['id']);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final overdue1 = _accounts.where((a) => _overdueDays(a) >= 1).length;
    final overdue7 = _accounts.where((a) => _overdueDays(a) >= 7).length;
    final suspended =
        _accounts.where((a) => a['suspended'] == true).length;

    return Column(children: [
      // Summary
      Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        color: AppColors.cardBg,
        child: Row(children: [
          _chip('With Balance', '${_accounts.length}',
              AppColors.textSecondary),
          const SizedBox(width: 24),
          _chip('1+ Days Overdue', '$overdue1', AppColors.warning),
          const SizedBox(width: 24),
          _chip('7+ Days Overdue', '$overdue7', AppColors.error),
          const SizedBox(width: 24),
          _chip('Suspended', '$suspended', AppColors.error),
          const Spacer(),
          // Important notice — changes file: no auto-suspend default
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
              border:
                  Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, size: 14, color: AppColors.info),
              SizedBox(width: 6),
              Text(
                'Auto-suspend is OFF by default. Owner controls all suspensions.',
                style:
                    TextStyle(fontSize: 11, color: AppColors.info),
              ),
            ]),
          ),
        ]),
      ),
      const Divider(height: 1, color: AppColors.border),
      // Header
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        color: AppColors.surfaceBg,
        child: const Row(children: [
          Expanded(flex: 2, child: Text('BUSINESS', style: _hS)),
          SizedBox(width: 12),
          SizedBox(width: 90,  child: Text('BALANCE', style: _hS)),
          SizedBox(width: 12),
          SizedBox(width: 80,  child: Text('OVERDUE', style: _hS)),
          SizedBox(width: 12),
          SizedBox(width: 90,  child: Text('ALERT LEVEL', style: _hS)),
          SizedBox(width: 12),
          SizedBox(width: 130, child: Text('AUTO-SUSPEND', style: _hS)),
          SizedBox(width: 12),
          SizedBox(width: 100, child: Text('STATUS', style: _hS)),
          SizedBox(width: 12),
          SizedBox(width: 100, child: Text('ACTION', style: _hS)),
        ]),
      ),
      const Divider(height: 1, color: AppColors.border),
      Expanded(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary))
            : _accounts.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 64, color: AppColors.success),
                        SizedBox(height: 16),
                        Text('No outstanding balances',
                            style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _accounts.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, color: AppColors.border),
                    itemBuilder: (_, i) {
                      final a = _accounts[i];
                      final overdue = _overdueDays(a);
                      final isSuspended = a['suspended'] as bool? ?? false;
                      final autoSuspend =
                          a['auto_suspend'] as bool? ?? false;
                      final autoSuspendDays =
                          (a['auto_suspend_days'] as num?)?.toInt() ?? 30;
                      final balance =
                          (a['balance'] as num?)?.toDouble() ?? 0;

                      // Alert level
                      Color alertColor;
                      String alertLabel;
                      IconData alertIcon;
                      if (isSuspended) {
                        alertColor = AppColors.error;
                        alertLabel = 'SUSPENDED';
                        alertIcon = Icons.block;
                      } else if (overdue >= 7) {
                        alertColor = AppColors.error;
                        alertLabel = '🔴 Critical';
                        alertIcon = Icons.error;
                      } else if (overdue >= 1) {
                        alertColor = AppColors.warning;
                        alertLabel = '🟡 Overdue';
                        alertIcon = Icons.warning_amber;
                      } else {
                        alertColor = AppColors.success;
                        alertLabel = '✅ Within terms';
                        alertIcon = Icons.check_circle;
                      }

                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        child: Row(children: [
                          // Business name
                          Expanded(
                            flex: 2,
                            child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                              Text(a['name'] ?? '—',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                              if (a['contact_person'] != null)
                                Text(a['contact_person'],
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color:
                                            AppColors.textSecondary)),
                            ]),
                          ),
                          const SizedBox(width: 12),
                          // Balance
                          SizedBox(
                            width: 90,
                            child: Text(
                              'R ${balance.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Overdue days
                          SizedBox(
                            width: 80,
                            child: Text(
                              overdue > 0 ? '$overdue days' : 'Within terms',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: overdue >= 7
                                      ? AppColors.error
                                      : overdue >= 1
                                          ? AppColors.warning
                                          : AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Alert level
                          SizedBox(
                            width: 90,
                            child: Row(children: [
                              Icon(alertIcon,
                                  size: 14, color: alertColor),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(alertLabel,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: alertColor,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ]),
                          ),
                          const SizedBox(width: 12),
                          // Auto-suspend toggle + days
                          SizedBox(
                            width: 130,
                            child: Row(children: [
                              Transform.scale(
                                scale: 0.75,
                                child: Switch(
                                  value: autoSuspend,
                                  onChanged: (v) =>
                                      _saveAutoSuspendSettings(
                                          a, v, autoSuspendDays),
                                  activeThumbColor: AppColors.warning,
                                ),
                              ),
                              if (autoSuspend)
                                DropdownButton<int>(
                                  value: autoSuspendDays,
                                  underline: const SizedBox(),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textPrimary),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 7, child: Text('7d')),
                                    DropdownMenuItem(
                                        value: 14, child: Text('14d')),
                                    DropdownMenuItem(
                                        value: 30, child: Text('30d')),
                                  ],
                                  onChanged: (v) =>
                                      _saveAutoSuspendSettings(
                                          a, autoSuspend, v!),
                                )
                              else
                                const Text('Off',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            AppColors.textSecondary)),
                            ]),
                          ),
                          const SizedBox(width: 12),
                          // Status
                          SizedBox(
                            width: 100,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSuspended
                                    ? AppColors.error.withOpacity(0.1)
                                    : AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isSuspended ? 'SUSPENDED' : 'ACTIVE',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSuspended
                                        ? AppColors.error
                                        : AppColors.success),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Action
                          SizedBox(
                            width: 100,
                            child: ElevatedButton(
                              onPressed: () => _toggleSuspend(a),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSuspended
                                    ? AppColors.success
                                    : AppColors.error,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                textStyle: const TextStyle(fontSize: 11),
                              ),
                              child: Text(isSuspended
                                  ? 'Re-enable'
                                  : 'Suspend'),
                            ),
                          ),
                        ]),
                      );
                    },
                  ),
      ),
    ]);
  }

  Widget _chip(String label, String value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 10, color: AppColors.textSecondary)),
      Text(value,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  static const _hS = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: AppColors.textSecondary,
      letterSpacing: 0.5);
}

// ══════════════════════════════════════════════════════════════════
// ACCOUNT FORM DIALOG — Create / Edit
// Blueprint 8.1 + changes file 5.1
// ══════════════════════════════════════════════════════════════════

class _AccountFormDialog extends StatefulWidget {
  final Map<String, dynamic>? account;
  final VoidCallback onSaved;
  const _AccountFormDialog({required this.account, required this.onSaved});

  @override
  State<_AccountFormDialog> createState() => _AccountFormDialogState();
}

class _AccountFormDialogState extends State<_AccountFormDialog> {
  final _supabase = SupabaseService.client;
  bool _isSaving = false;

  final _nameCtrl        = TextEditingController();
  final _contactCtrl     = TextEditingController();
  final _whatsappCtrl    = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _vatCtrl         = TextEditingController();
  final _addressCtrl     = TextEditingController();
  final _limitCtrl       = TextEditingController();
  final _notesCtrl       = TextEditingController();

  String _accountType    = 'Restaurant';
  int _creditTermsDays   = 7;
  bool _autoSuspend      = false;
  int _autoSuspendDays   = 30;
  bool _isActive         = true;

  @override
  void initState() {
    super.initState();
    if (widget.account != null) _populate(widget.account!);
  }

  void _populate(Map<String, dynamic> a) {
    _nameCtrl.text     = a['name'] ?? '';
    _contactCtrl.text  = a['contact_person'] ?? '';
    _whatsappCtrl.text = a['whatsapp'] ?? '';
    _emailCtrl.text    = a['email'] ?? '';
    _vatCtrl.text      = a['vat_number'] ?? '';
    _addressCtrl.text  = a['address'] ?? '';
    _limitCtrl.text    = a['credit_limit']?.toString() ?? '';
    _notesCtrl.text    = a['notes'] ?? '';
    _accountType       = a['account_type'] ?? 'Restaurant';
    _creditTermsDays   = (a['credit_terms_days'] as num?)?.toInt() ?? 7;
    _autoSuspend       = a['auto_suspend'] as bool? ?? false;
    _autoSuspendDays   = (a['auto_suspend_days'] as num?)?.toInt() ?? 30;
    _isActive          = a['is_active'] as bool? ?? true;
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    final data = {
      'name':               _nameCtrl.text.trim(),
      'contact_person':     _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim(),
      'whatsapp':           _whatsappCtrl.text.trim().isEmpty ? null : _whatsappCtrl.text.trim(),
      'email':              _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      'vat_number':         _vatCtrl.text.trim().isEmpty ? null : _vatCtrl.text.trim(),
      'address':            _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      'credit_limit':       double.tryParse(_limitCtrl.text),
      'notes':              _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      'account_type':       _accountType,
      'credit_terms_days':  _creditTermsDays,
      'auto_suspend':       _autoSuspend,
      'auto_suspend_days':  _autoSuspendDays,
      'is_active':          _isActive,
      'updated_at':         DateTime.now().toIso8601String(),
    };

    try {
      if (widget.account == null) {
        data['balance'] = 0.0;
        final result = await _supabase.from('business_accounts').insert(data).select().single();
        
        // Audit log - account creation
        final creditLimit = (data['credit_limit'] as num?)?.toDouble();
        await AuditService.log(
          action: 'CREATE',
          module: 'Accounts',
          description: 'Business account created: ${data['name']} - Credit limit R${creditLimit?.toStringAsFixed(2) ?? "0.00"}',
          entityType: 'Account',
          entityId: result['id'],
          newValues: data,
        );
      } else {
        final oldCreditLimit = (widget.account!['credit_limit'] as num?)?.toDouble();
        final newCreditLimit = (data['credit_limit'] as num?)?.toDouble();
        
        await _supabase
            .from('business_accounts')
            .update(data)
            .eq('id', widget.account!['id']);
        
        // Audit log - account update (with credit limit tracking)
        String desc = 'Business account updated: ${data['name']}';
        if (oldCreditLimit != newCreditLimit) {
          desc += ' - Credit limit changed: R${oldCreditLimit?.toStringAsFixed(2) ?? "0.00"} → R${newCreditLimit?.toStringAsFixed(2) ?? "0.00"}';
        }
        await AuditService.log(
          action: 'UPDATE',
          module: 'Accounts',
          description: desc,
          entityType: 'Account',
          entityId: widget.account!['id'],
          oldValues: widget.account,
          newValues: data,
        );
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'),
                backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 580,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
            child: Row(children: [
              const Icon(Icons.business, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                widget.account == null
                    ? 'Add Business Account'
                    : 'Edit — ${widget.account!['name']}',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ]),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                // Business name + type
                Row(children: [
                  Expanded(child: _field('Business Name *', _nameCtrl,
                      hint: 'Giovanni\'s Restaurant')),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('Account Type', style: _lbl),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _accountType,
                        decoration: const InputDecoration(isDense: true),
                        items: const [
                          DropdownMenuItem(value: 'Restaurant', child: Text('Restaurant')),
                          DropdownMenuItem(value: 'Caterer', child: Text('Caterer')),
                          DropdownMenuItem(value: 'Retailer', child: Text('Retailer')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (v) => setState(() => _accountType = v!),
                      ),
                    ]),
                  ),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _field('Contact Person', _contactCtrl,
                      hint: 'Giovanni Rossi')),
                  const SizedBox(width: 16),
                  Expanded(child: _field('WhatsApp / Cell', _whatsappCtrl,
                      hint: '082 345 6789',
                      note: 'Primary — for statements & overdue notices')),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _field('Email', _emailCtrl,
                      hint: 'giovanni@restaurant.co.za',
                      note: 'For emailed statements')),
                  const SizedBox(width: 16),
                  Expanded(child: _field('VAT Number', _vatCtrl,
                      hint: '4712345678',
                      note: 'For VAT-compliant invoice generation')),
                ]),
                const SizedBox(height: 16),
                _field('Address', _addressCtrl,
                    hint: '12 Main Road, Struisbaai'),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: _field('Credit Limit (R)', _limitCtrl,
                        hint: '10000',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('Credit Terms', style: _lbl),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        initialValue: _creditTermsDays,
                        decoration: const InputDecoration(isDense: true),
                        items: const [
                          DropdownMenuItem(value: 7,  child: Text('7 days')),
                          DropdownMenuItem(value: 14, child: Text('14 days')),
                          DropdownMenuItem(value: 30, child: Text('30 days')),
                          DropdownMenuItem(value: 60, child: Text('60 days')),
                        ],
                        onChanged: (v) => setState(() => _creditTermsDays = v!),
                      ),
                    ]),
                  ),
                ]),
                const SizedBox(height: 16),
                // Auto-suspend — off by default per changes file
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      const Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Auto-Suspend',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          Text(
                            'OFF by default. Only enable for specific accounts at owner\'s discretion.',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary),
                          ),
                        ]),
                      ),
                      Switch(
                        value: _autoSuspend,
                        onChanged: (v) =>
                            setState(() => _autoSuspend = v),
                        activeThumbColor: AppColors.warning,
                      ),
                    ]),
                    if (_autoSuspend) ...[
                      const SizedBox(height: 10),
                      Row(children: [
                        const Text('Suspend after ',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                        DropdownButton<int>(
                          value: _autoSuspendDays,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 7,  child: Text('7 days')),
                            DropdownMenuItem(value: 14, child: Text('14 days')),
                            DropdownMenuItem(value: 30, child: Text('30 days')),
                          ],
                          onChanged: (v) =>
                              setState(() => _autoSuspendDays = v!),
                        ),
                        const Text(' overdue',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                      ]),
                    ],
                  ]),
                ),
                const SizedBox(height: 16),
                _field('Notes', _notesCtrl,
                    hint: 'e.g. Long-standing client, pays monthly',
                    maxLines: 2),
              ]),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(children: [
              Row(children: [
                Switch(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  activeThumbColor: AppColors.success,
                ),
                Text(_isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                        color: _isActive
                            ? AppColors.success
                            : AppColors.textSecondary)),
              ]),
              const Spacer(),
              OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(widget.account == null
                        ? 'Create Account'
                        : 'Save Changes'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {
    String? hint, String? note,
    TextInputType? keyboardType, int maxLines = 1,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: _lbl),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(hintText: hint, isDense: true),
      ),
      if (note != null) ...[
        const SizedBox(height: 3),
        Text(note,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    ]);
  }

  static const _lbl = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary);
}

// ══════════════════════════════════════════════════════════════════
// PAYMENT DIALOG — Record Payment
// Blueprint 8.3
// ══════════════════════════════════════════════════════════════════

class _PaymentDialog extends StatefulWidget {
  final Map<String, dynamic> account;
  final VoidCallback onSaved;
  const _PaymentDialog({required this.account, required this.onSaved});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _supabase  = SupabaseService.client;
  final _amtCtrl   = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _method   = 'EFT';
  DateTime _date   = DateTime.now();
  bool _isSaving   = false;

  /// C3: Resolve staff id for ledger recorded_by when currentStaffId is null (session edge case).
  Future<String?> _getFallbackStaffId() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return null;
    // profiles.id often equals auth.users.id in Supabase
    try {
      final fromProfiles = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      if (fromProfiles != null && fromProfiles['id'] != null) {
        return fromProfiles['id'] as String?;
      }
    } catch (_) {}
    // staff_profiles may link via auth_user_id (adjust column name if different)
    try {
      final fromStaff = await _supabase
          .from('staff_profiles')
          .select('id')
          .eq('auth_user_id', user.id)
          .maybeSingle();
      if (fromStaff != null && fromStaff['id'] != null) {
        return fromStaff['id'] as String?;
      }
    } catch (_) {
      try {
        final fromStaff = await _supabase
            .from('staff_profiles')
            .select('id')
            .eq('id', user.id)
            .maybeSingle();
        return fromStaff?['id'] as String?;
      } catch (_) {}
    }
    return null;
  }

  Future<void> _save() async {
    // C3: Resolve staff id before any insert; ledger requires non-null recorded_by (FK).
    String? staffId = AuthService().currentStaffId;
    staffId ??= SupabaseService.client.auth.currentUser?.id;
    staffId ??= await _getFallbackStaffId();
    if (staffId == null || staffId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot record payment: no active session. Please log in again.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }
    final recordedBy = staffId;
    final amt = double.tryParse(_amtCtrl.text);
    if (amt == null || amt <= 0) return;
    setState(() => _isSaving = true);

    final accId  = widget.account['id'] as String;
    final balance = (widget.account['balance'] as num?)?.toDouble() ?? 0;
    final newBalance = (balance - amt).clamp(0, double.infinity);

    // Generate reference
    final now = DateTime.now();
    final ref =
        'PMT-${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';

    try {
      // Insert transaction record
      await _supabase.from('account_transactions').insert({
        'account_id':       accId,
        'transaction_type': 'payment',
        'reference':        ref,
        'description':      _notesCtrl.text.trim().isEmpty
            ? 'Payment received'
            : _notesCtrl.text.trim(),
        'amount':           amt,
        'running_balance':  newBalance,
        'payment_method':   _method,
        'transaction_date': _date.toIso8601String().substring(0, 10),
      });

      // Update account balance
      await _supabase.from('business_accounts').update({
        'balance':    newBalance,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', accId);

      // C3: recordedBy already resolved above; do not insert ledger with null (FK violation).
      try {
        final drCode = _method.toUpperCase() == 'CASH' ? '1000' : '1100';
        final drName = _method.toUpperCase() == 'CASH' ? 'Cash on Hand' : 'Bank Account';
        await LedgerRepository().createDoubleEntry(
          date: DateTime(_date.year, _date.month, _date.day),
          debitAccountCode: drCode,
          debitAccountName: drName,
          creditAccountCode: '1200',
          creditAccountName: 'Accounts Receivable (Business Accounts)',
          amount: amt,
          description: _notesCtrl.text.trim().isEmpty ? 'Payment received' : _notesCtrl.text.trim(),
          referenceId: accId,
          source: 'payment_received',
          recordedBy: recordedBy,
        );
      } catch (ledgerErr) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment saved; ledger update failed: $ledgerErr'), backgroundColor: AppColors.warning),
          );
        }
      }

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'),
                backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = (widget.account['balance'] as num?)?.toDouble() ?? 0;
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 440,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
            child: Row(children: [
              const Icon(Icons.payment, color: AppColors.success),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Record Payment',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  Text(widget.account['name'] ?? '—',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ]),
              ),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ]),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              // Current balance
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Text('Current Outstanding:',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const Spacer(),
                  Text('R ${balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning)),
                ]),
              ),
              const SizedBox(height: 20),
              // Amount
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Payment Amount (R) *',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _amtCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '0.00',
                  isDense: true,
                  prefixText: 'R ',
                  suffixText: balance > 0
                      ? 'Full: R ${balance.toStringAsFixed(2)}'
                      : null,
                  suffixStyle: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                onTap: () {
                  if (_amtCtrl.text.isEmpty) {
                    _amtCtrl.text = balance.toStringAsFixed(2);
                    _amtCtrl.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _amtCtrl.text.length);
                  }
                },
              ),
              const SizedBox(height: 16),
              // Payment method
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Payment Method',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _method,
                      decoration: const InputDecoration(isDense: true),
                      items: const [
                        DropdownMenuItem(value: 'EFT',   child: Text('EFT')),
                        DropdownMenuItem(value: 'Cash',  child: Text('Cash')),
                        DropdownMenuItem(value: 'Card',  child: Text('Card')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _method = v!),
                    ),
                  ]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Payment Date',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) setState(() => _date = d);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(children: [
                          const Icon(Icons.calendar_today,
                              size: 14,
                              color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            '${_date.day} ${months[_date.month - 1]} ${_date.year}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 16),
              // Notes
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Notes (optional)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                    hintText: 'e.g. EFT ref #ABC123',
                    isDense: true),
              ),
            ]),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 14),
            child: Row(children: [
              OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              const Spacer(),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success),
                child: _isSaving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Record Payment'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}