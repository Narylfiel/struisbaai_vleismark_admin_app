import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/auth_service.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/audit_service.dart';
import '../../bookkeeping/screens/customer_invoice_form_screen.dart';
import 'package:admin_app/features/bookkeeping/services/ledger_repository.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

/// H5: Account Detail — summary card, Transactions / Invoices / Agreements / Statement tabs.
class AccountDetailScreen extends StatefulWidget {
  final String accountId;

  const AccountDetailScreen({super.key, required this.accountId});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen>
    with SingleTickerProviderStateMixin {
  final _client = SupabaseService.client;

  Map<String, dynamic>? _account;
  String? _businessName;
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      final acc = await _client
          .from('business_accounts')
          .select('*')
          .eq('id', widget.accountId)
          .maybeSingle();
      String? biz;
      try {
        final s = await _client
            .from('business_settings')
            .select('setting_value')
            .eq('setting_key', 'business_name')
            .maybeSingle();
        if (s != null && s['setting_value'] != null) {
          final v = s['setting_value'];
          biz = v is String ? v : v.toString();
        }
      } catch (_) {}
      if (mounted) {
        setState(() {
          _account = acc != null ? Map<String, dynamic>.from(acc) : null;
          _businessName = biz;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _account == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    final acc = _account!;
    final balance = (acc['balance'] as num?)?.toDouble() ?? 0;
    final limit = (acc['credit_limit'] as num?)?.toDouble() ?? 0;
    final usedPct = limit > 0 ? (balance / limit).clamp(0.0, 1.0) : 0.0;
    final balanceColor = balance <= 0 ? AppColors.success : AppColors.error;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(acc['name'] ?? 'Account'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt, size: 18), text: 'Transactions'),
            Tab(icon: Icon(Icons.receipt_long, size: 18), text: 'Invoices'),
            Tab(icon: Icon(Icons.handshake, size: 18), text: 'Agreements'),
            Tab(icon: Icon(Icons.description, size: 18), text: 'Statement'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSummaryCard(acc, balance, limit, usedPct, balanceColor),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TransactionsTab(accountId: widget.accountId, account: acc, onSaved: _load),
                _InvoicesTab(accountId: widget.accountId, onSaved: _load),
                _AgreementsTab(accountId: widget.accountId, onSaved: _load),
                _StatementTab(
                  accountId: widget.accountId,
                  account: acc,
                  businessName: _businessName,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    Map<String, dynamic> acc,
    double balance,
    double limit,
    double usedPct,
    Color balanceColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(acc['name'] ?? '—', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (acc['account_type'] != null)
                      Text(acc['account_type'].toString(), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    if (acc['phone'] != null && acc['phone'].toString().isNotEmpty)
                      Text('Phone: ${acc['phone']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    if (acc['email'] != null && acc['email'].toString().isNotEmpty)
                      Text('Email: ${acc['email']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Balance', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('R ${balance.toStringAsFixed(2)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: balanceColor)),
                  const SizedBox(height: 8),
                  Text('Credit limit: R ${limit.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 160,
                    child: LinearProgressIndicator(
                      value: usedPct,
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        usedPct > 0.9 ? AppColors.error : usedPct > 0.7 ? AppColors.warning : AppColors.success,
                      ),
                    ),
                  ),
                  Text('${(usedPct * 100).toStringAsFixed(0)}% used', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 1 — TRANSACTIONS (account_transactions)
// ══════════════════════════════════════════════════════════════════

class _TransactionsTab extends StatefulWidget {
  final String accountId;
  final Map<String, dynamic> account;
  final VoidCallback onSaved;

  const _TransactionsTab({required this.accountId, required this.account, required this.onSaved});

  @override
  State<_TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<_TransactionsTab> {
  final _client = SupabaseService.client;
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _client
          .from('account_transactions')
          .select('*')
          .eq('account_id', widget.accountId)
          .order('transaction_date', ascending: true)
          .order('created_at', ascending: true);
      if (mounted) setState(() => _rows = List<Map<String, dynamic>>.from(data));
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _recordPayment() async {
    final staffId = AuthService().currentStaffId;
    if (staffId == null || staffId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in with PIN to record payments'), backgroundColor: AppColors.warning),
      );
      return;
    }
    final amtCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime date = DateTime.now();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Record Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amtCtrl,
                  decoration: const InputDecoration(labelText: 'Amount (R)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text('${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'),
                  trailing: TextButton(
                    onPressed: () async {
                      final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)));
                      if (d != null) setDlg(() => date = d);
                    },
                    child: const Text('Pick'),
                  ),
                ),
                TextField(controller: refCtrl, decoration: const InputDecoration(labelText: 'Reference')),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final amt = double.tryParse(amtCtrl.text.replaceAll(',', '.')) ?? 0;
    if (amt <= 0) return;
    final balance = (widget.account['balance'] as num?)?.toDouble() ?? 0;
    final newBalance = (balance - amt).clamp(0.0, double.infinity);
    final ref = refCtrl.text.trim().isEmpty ? 'PMT-${DateTime.now().millisecondsSinceEpoch}' : refCtrl.text.trim();
    final description = notesCtrl.text.trim().isEmpty ? 'Payment received' : notesCtrl.text.trim();
    final customerName = widget.account['account_name'] ?? 'Unknown';
    try {
      final txResult = await _client.from('account_transactions').insert({
        'account_id': widget.accountId,
        'transaction_type': 'payment',
        'reference': ref,
        'description': description,
        'amount': amt,
        'running_balance': newBalance,
        'payment_method': 'EFT',
        'transaction_date': date.toIso8601String().substring(0, 10),
      }).select().single();
      
      await _client.from('business_accounts').update({
        'balance': newBalance,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.accountId);
      
      // Audit log - payment recorded
      await AuditService.log(
        action: 'CREATE',
        module: 'Accounts',
        description: 'Payment recorded: R${amt.toStringAsFixed(2)} for $customerName - $ref',
        entityType: 'Payment',
        entityId: txResult['id'],
      );
      
      try {
        await LedgerRepository().createDoubleEntry(
          date: date,
          debitAccountCode: '1100',
          debitAccountName: 'Bank Account',
          creditAccountCode: '1200',
          creditAccountName: 'Accounts Receivable (Business Accounts)',
          amount: amt,
          description: description,
          referenceId: widget.accountId,
          source: 'payment_received',
          recordedBy: staffId,
        );
      } catch (_) {}
      widget.onSaved();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment recorded'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    const hStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _recordPayment,
                icon: const Icon(Icons.payment, size: 18),
                label: const Text('Record Payment'),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: AppColors.surfaceBg,
          child: const Row(
            children: [
              SizedBox(width: 90, child: Text('Date', style: hStyle)),
              Expanded(flex: 2, child: Text('Description', style: hStyle)),
              SizedBox(width: 100, child: Text('Reference', style: hStyle)),
              SizedBox(width: 80, child: Text('Debit', style: hStyle)),
              SizedBox(width: 80, child: Text('Credit', style: hStyle)),
              SizedBox(width: 90, child: Text('Balance', style: hStyle)),
            ],
          ),
        ),
        Expanded(
          child: _rows.isEmpty
              ? const Center(child: Text('No transactions'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _rows.length,
                  itemBuilder: (_, i) {
                    final t = _rows[i];
                    final type = t['transaction_type']?.toString() ?? '';
                    final amt = (t['amount'] as num?)?.toDouble() ?? 0;
                    final debit = type == 'payment' ? 0.0 : amt.abs();
                    final credit = type == 'payment' ? amt.abs() : 0.0;
                    final run = (t['running_balance'] as num?)?.toDouble();
                    final dateStr = t['transaction_date']?.toString().substring(0, 10) ?? '—';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(width: 90, child: Text(dateStr)),
                          Expanded(flex: 2, child: Text(t['description']?.toString() ?? '—', overflow: TextOverflow.ellipsis)),
                          SizedBox(width: 100, child: Text(t['reference']?.toString() ?? '—', overflow: TextOverflow.ellipsis)),
                          SizedBox(width: 80, child: Text(debit > 0 ? 'R ${debit.toStringAsFixed(2)}' : '—', style: const TextStyle(color: AppColors.textSecondary))),
                          SizedBox(width: 80, child: Text(credit > 0 ? 'R ${credit.toStringAsFixed(2)}' : '—', style: const TextStyle(color: AppColors.success))),
                          SizedBox(width: 90, child: Text(run != null ? 'R ${run.toStringAsFixed(2)}' : '—')),
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
// TAB 2 — INVOICES
// ══════════════════════════════════════════════════════════════════
class _InvoicesTab extends StatefulWidget {
  final String accountId;
  final VoidCallback onSaved;
  const _InvoicesTab({required this.accountId, required this.onSaved});
  @override
  State<_InvoicesTab> createState() => _InvoicesTabState();
}

class _InvoicesTabState extends State<_InvoicesTab> {
  final _client = SupabaseService.client;
  List<Map<String, dynamic>> _invoices = [];
  final Set<String> _selectedIds = {};
  bool _loading = true;
  bool _paying = false;
  String _paymentMethod = 'Cash';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _client
          .from('customer_invoices')
          .select('*')
          .eq('account_id', widget.accountId)
          .order('invoice_date', ascending: false);
      if (mounted) {
        setState(() {
          _invoices = List<Map<String, dynamic>>.from(data);
          // Clear selections that no longer exist
          _selectedIds.removeWhere(
              (id) => !_invoices.any((inv) => inv['id'] == id));
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  double get _selectedTotal {
    return _invoices
        .where((inv) => _selectedIds.contains(inv['id']))
        .fold(0, (sum, inv) => sum + ((inv['total'] as num?)?.toDouble() ?? 0));
  }

  bool _isPayable(Map<String, dynamic> inv) {
    final status = inv['status']?.toString() ?? '';
    return status != 'paid' && status != 'cancelled';
  }

  Future<void> _paySelected() async {
    if (_selectedIds.isEmpty) return;
    final staffId = AuthService().currentStaffId;
    if (staffId == null || staffId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sign in with PIN to record payments'),
            backgroundColor: AppColors.warning),
      );
      return;
    }

    // Confirm dialog
    final selectedInvoices = _invoices
        .where((inv) => _selectedIds.contains(inv['id']))
        .toList();
    final total = _selectedTotal;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Confirm Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Paying ${selectedInvoices.length} invoice(s):'),
              const SizedBox(height: 8),
              ...selectedInvoices.map((inv) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(inv['invoice_number']?.toString() ?? '—',
                            style: const TextStyle(fontSize: 13)),
                        Text(
                            'R ${(inv['total'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ],
                    ),
                  )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('R ${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Payment method:'),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Cash', label: Text('Cash')),
                  ButtonSegment(value: 'Card', label: Text('Card')),
                  ButtonSegment(value: 'EFT', label: Text('EFT')),
                ],
                selected: {_paymentMethod},
                onSelectionChanged: (v) =>
                    setDlg(() => _paymentMethod = v.first),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirm Payment')),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _paying = true);

    try {
      final invoiceIds = _selectedIds.toList();
      final invoiceNums = selectedInvoices
          .map((i) => i['invoice_number']?.toString() ?? '')
          .join(', ');

      // 1. Mark each selected invoice as paid
      await _client
          .from('customer_invoices')
          .update({
            'status': 'paid',
            'payment_date': DateTime.now().toIso8601String().substring(0, 10),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .inFilter('id', invoiceIds);

      // 2. Get current account balance
      final accData = await _client
          .from('business_accounts')
          .select('balance')
          .eq('id', widget.accountId)
          .single();
      final currentBalance =
          (accData['balance'] as num?)?.toDouble() ?? 0;
      final newBalance = currentBalance - total;

      // 3. Write payment transaction
      final ref = 'PMT-${DateTime.now().millisecondsSinceEpoch}';
      await _client.from('account_transactions').insert({
        'account_id': widget.accountId,
        'transaction_type': 'payment',
        'reference': ref,
        'description': 'Payment for: $invoiceNums',
        'amount': -total,
        'running_balance': newBalance,
        'payment_method': _paymentMethod,
        'recorded_by': staffId,
        'transaction_date': DateTime.now().toIso8601String().substring(0, 10),
        'created_at': DateTime.now().toIso8601String(),
      });

      // 4. Update account balance
      await _client.from('business_accounts').update({
        'balance': newBalance,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.accountId);

      // 5. Ledger double entry
      try {
        await LedgerRepository().createDoubleEntry(
          date: DateTime.now(),
          debitAccountCode: '1100',
          debitAccountName: 'Bank Account',
          creditAccountCode: '1200',
          creditAccountName: 'Accounts Receivable (Business Accounts)',
          amount: total,
          description: 'Payment for: $invoiceNums',
          referenceId: widget.accountId,
          source: 'payment_received',
          recordedBy: staffId,
        );
      } catch (_) {}

      _selectedIds.clear();
      widget.onSaved();
      await _load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Payment of R${total.toStringAsFixed(2)} recorded for ${selectedInvoices.length} invoice(s)'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Payment failed: ${ErrorHandler.friendlyMessage(e)}'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final payableInvoices =
        _invoices.where(_isPayable).toList();
    final allPayableSelected = payableInvoices.isNotEmpty &&
        payableInvoices.every((inv) => _selectedIds.contains(inv['id']));

    return Column(
      children: [
        // Toolbar
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (payableInvoices.isNotEmpty) ...[
                Checkbox(
                  value: allPayableSelected,
                  tristate: true,
                  onChanged: (_) {
                    setState(() {
                      if (allPayableSelected) {
                        _selectedIds.removeAll(
                            payableInvoices.map((i) => i['id'] as String));
                      } else {
                        _selectedIds.addAll(
                            payableInvoices.map((i) => i['id'] as String));
                      }
                    });
                  },
                ),
                const Text('Select all unpaid',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 16),
              ],
              if (_selectedIds.isNotEmpty) ...[
                Text(
                  '${_selectedIds.length} selected — R ${_selectedTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _paying ? null : _paySelected,
                  icon: _paying
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child:
                              CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.payment, size: 16),
                  label: const Text('Pay Selected'),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success),
                ),
              ],
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomerInvoiceFormScreen(
                          initialAccountId: widget.accountId),
                    ),
                  );
                  _load();
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Invoice'),
              ),
            ],
          ),
        ),

        // Header row
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: AppColors.surfaceBg,
          child: const Row(
            children: [
              SizedBox(width: 40),
              SizedBox(
                  width: 120,
                  child: Text('Invoice #',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary))),
              SizedBox(
                  width: 90,
                  child: Text('Date',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary))),
              SizedBox(
                  width: 90,
                  child: Text('Due Date',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary))),
              SizedBox(
                  width: 90,
                  child: Text('Total',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary))),
              SizedBox(
                  width: 90,
                  child: Text('Status',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary))),
            ],
          ),
        ),

        // Invoice list
        Expanded(
          child: _invoices.isEmpty
              ? const Center(child: Text('No invoices'))
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _invoices.length,
                  itemBuilder: (_, i) {
                    final inv = _invoices[i];
                    final id = inv['id'] as String;
                    final status =
                        inv['status']?.toString() ?? 'draft';
                    final payable = _isPayable(inv);
                    final selected = _selectedIds.contains(id);

                    Color chipColor = AppColors.textSecondary;
                    if (status == 'paid') {
                      chipColor = AppColors.success;
                    } else if (status == 'overdue') chipColor = AppColors.error;
                    else if (status == 'sent' || status == 'approved') chipColor = AppColors.warning;
                    else if (status == 'cancelled') chipColor = AppColors.error;

                    return InkWell(
                      onTap: payable
                          ? () => setState(() {
                                if (selected) {
                                  _selectedIds.remove(id);
                                } else {
                                  _selectedIds.add(id);
                                }
                              })
                          : null,
                      child: Container(
                        color: selected
                            ? AppColors.primary.withOpacity(0.08)
                            : null,
                        padding: const EdgeInsets.symmetric(
                            vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: payable
                                  ? Checkbox(
                                      value: selected,
                                      onChanged: (_) =>
                                          setState(() {
                                            if (selected) {
                                              _selectedIds
                                                  .remove(id);
                                            } else {
                                              _selectedIds.add(id);
                                            }
                                          }),
                                    )
                                  : const SizedBox(),
                            ),
                            SizedBox(
                                width: 120,
                                child: Text(
                                    inv['invoice_number']
                                            ?.toString() ??
                                        '—',
                                    style: const TextStyle(
                                        fontWeight:
                                            FontWeight.w600))),
                            SizedBox(
                                width: 90,
                                child: Text(inv['invoice_date']
                                            ?.toString()
                                            .substring(0, 10) ??
                                        '—',
                                    style: const TextStyle(
                                        fontSize: 12))),
                            SizedBox(
                                width: 90,
                                child: Text(inv['due_date']
                                            ?.toString()
                                            .substring(0, 10) ??
                                        '—',
                                    style: const TextStyle(
                                        fontSize: 12))),
                            SizedBox(
                                width: 90,
                                child: Text(
                                    'R ${(inv['total'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: payable
                                            ? AppColors.error
                                            : AppColors
                                                .success))),
                            SizedBox(
                              width: 90,
                              child: Chip(
                                label: Text(status),
                                backgroundColor:
                                    chipColor.withOpacity(0.15),
                                labelStyle: TextStyle(
                                    fontSize: 11,
                                    color: chipColor),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize
                                        .shrinkWrap,
                              ),
                            ),
                          ],
                        ),
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
// TAB 3 — AGREEMENTS (purchase_sale_agreement)
// ══════════════════════════════════════════════════════════════════

class _AgreementsTab extends StatefulWidget {
  final String accountId;
  final VoidCallback onSaved;

  const _AgreementsTab({required this.accountId, required this.onSaved});

  @override
  State<_AgreementsTab> createState() => _AgreementsTabState();
}

class _AgreementsTabState extends State<_AgreementsTab> {
  final _client = SupabaseService.client;
  List<Map<String, dynamic>> _agreements = [];
  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _client
          .from('purchase_sale_agreement')
          .select('*')
          .eq('account_id', widget.accountId)
          .order('agreement_date', ascending: false);
      final payData = await _client.from('purchase_sale_payments').select('*');
      if (mounted) {
        setState(() {
          _agreements = List<Map<String, dynamic>>.from(data);
          _payments = List<Map<String, dynamic>>.from(payData);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// DB: purchase, sale
  static String _agreementTypeLabel(String? v) {
    switch (v) {
      case 'purchase': return 'Purchase';
      case 'sale': return 'Sale';
      default: return v ?? '—';
    }
  }

  /// DB: draft, signed, completed, cancelled
  static String _agreementStatusLabel(String? v) {
    switch (v) {
      case 'draft': return 'Draft';
      case 'signed': return 'Signed';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      default: return v ?? '—';
    }
  }

  double _paidForAgreement(String agreementId) {
    return _payments
        .where((p) => p['agreement_id']?.toString() == agreementId)
        .fold<double>(0, (s, p) => s + ((p['amount'] as num?)?.toDouble() ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: AppColors.surfaceBg,
          child: const Row(
            children: [
              SizedBox(width: 80, child: Text('Type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
              Expanded(child: Text('Description', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
              SizedBox(width: 80, child: Text('Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
              SizedBox(width: 80, child: Text('Deposit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
              SizedBox(width: 90, child: Text('Balance Due', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
              SizedBox(width: 90, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
            ],
          ),
        ),
        Expanded(
          child: _agreements.isEmpty
              ? const Center(child: Text('No agreements'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _agreements.length,
                  itemBuilder: (_, i) {
                    final a = _agreements[i];
                    final id = a['id']?.toString();
                    final amount = (a['agreed_price'] as num?)?.toDouble() ?? 0;
                    final paid = id != null ? _paidForAgreement(id) : 0;
                    final balanceDue = amount - paid;
                    final agreementType = a['agreement_type']?.toString();
                    final agreementStatus = a['status']?.toString();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(width: 80, child: Text(_agreementTypeLabel(agreementType))),
                          Expanded(child: Text(a['asset_description']?.toString() ?? '—', overflow: TextOverflow.ellipsis)),
                          SizedBox(width: 80, child: Text('R ${amount.toStringAsFixed(2)}')),
                          SizedBox(width: 80, child: Text('R ${paid.toStringAsFixed(2)}')),
                          SizedBox(width: 90, child: Text('R ${balanceDue.toStringAsFixed(2)}')),
                          SizedBox(width: 90, child: Text(_agreementStatusLabel(agreementStatus))),
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
// TAB 4 — STATEMENT (date range, PDF, WhatsApp)
// ══════════════════════════════════════════════════════════════════

class _StatementTab extends StatefulWidget {
  final String accountId;
  final Map<String, dynamic> account;
  final String? businessName;

  const _StatementTab({required this.accountId, required this.account, this.businessName});

  @override
  State<_StatementTab> createState() => _StatementTabState();
}

class _StatementTabState extends State<_StatementTab> {
  final _client = SupabaseService.client;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<Map<String, dynamic>> _rows = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime get _monthStart => DateTime(_selectedMonth.year, _selectedMonth.month, 1);
  DateTime get _monthEnd => DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _client
          .from('account_transactions')
          .select('*')
          .eq('account_id', widget.accountId)
          .gte('transaction_date', _monthStart.toIso8601String().substring(0, 10))
          .lte('transaction_date', _monthEnd.toIso8601String().substring(0, 10))
          .order('transaction_date', ascending: true)
          .order('created_at', ascending: true);
      if (mounted) setState(() => _rows = List<Map<String, dynamic>>.from(data));
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  double get _totalPurchases {
    return _rows
        .where((r) => r['transaction_type']?.toString() == 'sale')
        .fold(0.0, (sum, r) => sum + ((r['amount'] as num?)?.toDouble() ?? 0));
  }

  double get _totalPayments {
    return _rows
        .where((r) => r['transaction_type']?.toString() == 'payment')
        .fold(0.0, (sum, r) => sum + ((r['amount'] as num?)?.toDouble() ?? 0).abs());
  }

  double get _outstanding {
    return _totalPurchases - _totalPayments;
  }

  String get _monthDisplay {
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _load();
  }

  void _nextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (nextMonth.year < now.year ||
        (nextMonth.year == now.year && nextMonth.month <= now.month)) {
      setState(() => _selectedMonth = nextMonth);
      _load();
    }
  }

  Future<void> _exportPdf() async {
    final pdf = pw.Document();
    final name = widget.account['name'] ?? 'Account';
    final contact = widget.account['contact_person']?.toString() ?? '-';
    final now = DateTime.now();
    final today = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final accountIdShort = widget.accountId.substring(0, 8).toUpperCase();
    
    final totalPurchases = _totalPurchases;
    final totalPayments = _totalPayments;
    final outstanding = _outstanding;

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          // Header section
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left side - Business details
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Struisbaai Vleismark (Pty) Ltd',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Unit 6b Struisbaai Business Centre', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Malvern Drive, Struisbaai, 7285', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Tel: 082 696 2940', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              // Right side - Statement details
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('STATEMENT',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                  pw.SizedBox(height: 8),
                  pw.Text('Account: $name', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Contact: $contact', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Period: $_monthDisplay', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Date Issued: $today', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Account Ref: $accountIdShort', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 12),
          // Table
          pw.Table(
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(2.5),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(1),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _pdfHeaderCell('Date'),
                  _pdfHeaderCell('Description'),
                  _pdfHeaderCell('Reference'),
                  _pdfHeaderCell('Debit'),
                  _pdfHeaderCell('Credit'),
                  _pdfHeaderCell('Balance'),
                ],
              ),
              // Data rows
              ..._rows.map((t) {
                final amt = (t['amount'] as num?)?.toDouble() ?? 0;
                final date = t['transaction_date']?.toString() ?? '';
                final formattedDate = date.length >= 10 
                    ? '${date.substring(8, 10)}/${date.substring(5, 7)}/${date.substring(0, 4)}'
                    : '-';
                final pdfType = t['transaction_type']?.toString() ?? '';
                final debit = pdfType == 'payment' ? '' : 'R ${amt.abs().toStringAsFixed(2)}';
                final credit = pdfType == 'payment' ? 'R ${amt.abs().toStringAsFixed(2)}' : '';
                final run = (t['running_balance'] as num?)?.toDouble();
                final balance = run != null ? 'R ${run.toStringAsFixed(2)}' : '';
                return pw.TableRow(
                  children: [
                    _pdfCell(formattedDate),
                    _pdfCell((t['description'] ?? '-').toString().replaceAll('\u2014', '-').replaceAll('\u2013', '-')),
                    _pdfCell((t['reference'] ?? '-').toString().replaceAll('\u2014', '-').replaceAll('\u2013', '-')),
                    _pdfCell(debit),
                    _pdfCell(credit),
                    _pdfCell(balance, align: pw.TextAlign.right),
                  ],
                );
              }),
              // Totals row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('TOTALS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('')),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('')),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('R ${totalPurchases.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('R ${totalPayments.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('')),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          // Outstanding balance box
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: pw.BoxDecoration(
                  color: outstanding > 0 ? PdfColors.red100 : outstanding < 0 ? PdfColors.blue100 : PdfColors.green100,
                  border: pw.Border.all(
                    color: outstanding > 0 ? PdfColors.red : outstanding < 0 ? PdfColors.blue : PdfColors.green,
                    width: 1,
                  ),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  outstanding > 0
                      ? 'OUTSTANDING: R ${outstanding.toStringAsFixed(2)}'
                      : outstanding < 0
                          ? 'CREDIT: R ${outstanding.abs().toStringAsFixed(2)}'
                          : 'FULLY PAID',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                    color: outstanding > 0 ? PdfColors.red : outstanding < 0 ? PdfColors.blue : PdfColors.green,
                  ),
                ),
              ),
            ],
          ),
          pw.Spacer(),
          // Footer
          pw.Divider(thickness: 0.5),
          pw.SizedBox(height: 8),
          pw.Text('This statement was generated on $today',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.Text('Struisbaai Vleismark (Pty) Ltd - Reg No: 2026/069883/07',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    );
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'statement_${name.replaceAll(' ', '_')}_${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}.pdf');
  }

  pw.Widget _pdfHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
    );
  }

  pw.Widget _pdfCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9), textAlign: align),
    );
  }

  Future<void> _sendWhatsApp() async {
    await _exportPdf();
    final name = widget.account['name'] ?? 'there';
    final phone = widget.account['phone']?.toString().replaceAll(RegExp(r'[^\d+]'), '') ?? '';
    final text = Uri.encodeComponent('Hi $name, please find your account statement attached.');
    final url = Uri.parse('https://wa.me/${phone.isEmpty ? '' : phone}?text=$text');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Month selector
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left, color: AppColors.primary),
              ),
              Text(_monthDisplay, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                disabledColor: AppColors.textSecondary,
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _exportPdf,
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('Export Statement'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _sendWhatsApp,
                icon: const Icon(Icons.chat, size: 18),
                label: const Text('WhatsApp'),
              ),
            ],
          ),
        ),
        // Summary cards
        if (!_loading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Purchases',
                    amount: _totalPurchases,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: 'Paid',
                    amount: _totalPayments,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: _outstanding >= 0 ? 'Outstanding' : 'Credit',
                    amount: _outstanding.abs(),
                    color: _outstanding > 0
                        ? AppColors.error
                        : _outstanding < 0
                            ? Colors.blue
                            : AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        // Transaction list header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.surfaceBg,
          child: const Row(
            children: [
              SizedBox(width: 70, child: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
              Expanded(child: Text('Description', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
              SizedBox(width: 100, child: Text('Reference', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
              SizedBox(width: 90, child: Text('Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary), textAlign: TextAlign.right)),
              SizedBox(width: 100, child: Text('Balance', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary), textAlign: TextAlign.right)),
            ],
          ),
        ),
        // Transaction list
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
        else
          Expanded(
            child: _rows.isEmpty
                ? const Center(child: Text('No transactions in selected month'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _rows.length,
                    itemBuilder: (_, i) {
                      final t = _rows[i];
                      final amt = (t['amount'] as num?)?.toDouble() ?? 0;
                      final run = (t['running_balance'] as num?)?.toDouble();
                      final type = t['transaction_type']?.toString() ?? '';
                      final isSale = type == 'sale' || amt > 0;
                      final date = t['transaction_date']?.toString() ?? '';
                      final displayDate = date.length >= 10
                          ? '${date.substring(8, 10)} ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][int.parse(date.substring(5, 7)) - 1]}'
                          : '—';
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        elevation: 0,
                        color: AppColors.surfaceBg,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 70,
                                child: Text(displayDate, style: const TextStyle(fontSize: 12)),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t['description']?.toString() ?? '—',
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isSale ? AppColors.error.withOpacity(0.15) : AppColors.success.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isSale ? 'SALE' : 'PAYMENT',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: isSale ? AppColors.error : AppColors.success,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  t['reference']?.toString() ?? '—',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: 90,
                                child: Text(
                                  amt > 0 ? 'R ${amt.toStringAsFixed(2)}' : '-R ${amt.abs().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: amt > 0 ? AppColors.error : AppColors.success,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  run != null ? 'R ${run.toStringAsFixed(2)}' : '—',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryCard({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
            'R ${amount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
