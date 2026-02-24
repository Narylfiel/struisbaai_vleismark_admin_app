import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/auth_service.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/features/bookkeeping/screens/invoice_form_screen.dart';
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
    try {
      await _client.from('account_transactions').insert({
        'account_id': widget.accountId,
        'transaction_type': 'payment',
        'reference': ref,
        'description': description,
        'amount': amt,
        'running_balance': newBalance,
        'payment_method': 'EFT',
        'transaction_date': date.toIso8601String().substring(0, 10),
      });
      await _client.from('business_accounts').update({
        'balance': newBalance,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.accountId);
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
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
          child: Row(
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
                    final debit = type == 'payment' ? 0.0 : amt;
                    final credit = type == 'payment' ? amt : 0.0;
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
          .from('invoices')
          .select('*')
          .eq('account_id', widget.accountId)
          .order('invoice_date', ascending: false);
      if (mounted) setState(() => _invoices = List<Map<String, dynamic>>.from(data));
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InvoiceFormScreen(initialAccountId: widget.accountId),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: AppColors.surfaceBg,
          child: const Row(
            children: [
              SizedBox(width: 120, child: Text('Invoice #', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
              SizedBox(width: 90, child: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
              SizedBox(width: 90, child: Text('Due Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
              SizedBox(width: 80, child: Text('Total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
              SizedBox(width: 90, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
            ],
          ),
        ),
        Expanded(
          child: _invoices.isEmpty
              ? const Center(child: Text('No invoices'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _invoices.length,
                  itemBuilder: (_, i) {
                    final inv = _invoices[i];
                    final status = inv['status']?.toString() ?? 'draft';
                    Color chipColor = AppColors.textSecondary;
                    if (status == 'paid') chipColor = AppColors.success;
                    else if (status == 'overdue' || status == 'sent') chipColor = AppColors.warning;
                    else if (status == 'cancelled') chipColor = AppColors.error;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(width: 120, child: Text(inv['invoice_number']?.toString() ?? '—')),
                          SizedBox(width: 90, child: Text(inv['invoice_date']?.toString().substring(0, 10) ?? '—')),
                          SizedBox(width: 90, child: Text(inv['due_date']?.toString().substring(0, 10) ?? '—')),
                          SizedBox(width: 80, child: Text('R ${(inv['total_amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}')),
                          SizedBox(width: 90, child: Chip(label: Text(status), backgroundColor: chipColor.withOpacity(0.2), labelStyle: TextStyle(fontSize: 11, color: chipColor))),
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
  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to = DateTime.now();
  List<Map<String, dynamic>> _rows = [];
  bool _loading = false;

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
          .gte('transaction_date', _from.toIso8601String().substring(0, 10))
          .lte('transaction_date', _to.toIso8601String().substring(0, 10))
          .order('transaction_date', ascending: true)
          .order('created_at', ascending: true);
      if (mounted) setState(() => _rows = List<Map<String, dynamic>>.from(data));
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  double get _closingBalance {
    if (_rows.isEmpty) return (widget.account['balance'] as num?)?.toDouble() ?? 0;
    final last = _rows.last;
    return (last['running_balance'] as num?)?.toDouble() ?? (widget.account['balance'] as num?)?.toDouble() ?? 0;
  }

  Future<void> _exportPdf() async {
    final pdf = pw.Document();
    final name = widget.account['name'] ?? 'Account';
    final addr = widget.account['address'] ?? widget.account['phone'] ?? '';
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(widget.businessName ?? 'Business', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Statement of Account', style: pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 8),
          pw.Text('Account: $name'),
          if (addr.isNotEmpty) pw.Text('Address: $addr'),
          pw.Text('Period: ${_from.toIso8601String().substring(0, 10)} to ${_to.toIso8601String().substring(0, 10)}'),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Reference', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Debit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Credit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Balance', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                ],
              ),
              ..._rows.map((t) {
                final type = t['transaction_type']?.toString() ?? '';
                final amt = (t['amount'] as num?)?.toDouble() ?? 0;
                final debit = type == 'payment' ? 0.0 : amt;
                final credit = type == 'payment' ? amt : 0.0;
                final run = (t['running_balance'] as num?)?.toDouble();
                return pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(t['transaction_date']?.toString().substring(0, 10) ?? '—', style: const pw.TextStyle(fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text((t['description'] ?? '—').toString(), style: const pw.TextStyle(fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text((t['reference'] ?? '—').toString(), style: const pw.TextStyle(fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(debit > 0 ? '${debit.toStringAsFixed(2)}' : '', style: const pw.TextStyle(fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(credit > 0 ? '${credit.toStringAsFixed(2)}' : '', style: const pw.TextStyle(fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(run != null ? run.toStringAsFixed(2) : '', style: const pw.TextStyle(fontSize: 8))),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text('Closing balance: R ${_closingBalance.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          pw.Text('Thank you for your business.', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 8),
          pw.Text('Generated: ${DateTime.now().toIso8601String().substring(0, 19)}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
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
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Text('From:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () async {
                  final d = await showDatePicker(context: context, initialDate: _from, firstDate: DateTime(2020), lastDate: _to);
                  if (d != null) setState(() => _from = d);
                  _load();
                },
                child: Text(_from.toIso8601String().substring(0, 10)),
              ),
              const SizedBox(width: 16),
              const Text('To:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () async {
                  final d = await showDatePicker(context: context, initialDate: _to, firstDate: _from, lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (d != null) setState(() => _to = d);
                  _load();
                },
                child: Text(_to.toIso8601String().substring(0, 10)),
              ),
              const SizedBox(width: 16),
              ElevatedButton(onPressed: _loading ? null : _load, child: const Text('Apply')),
              const Spacer(),
              OutlinedButton.icon(onPressed: _exportPdf, icon: const Icon(Icons.picture_as_pdf, size: 18), label: const Text('Export PDF')),
              const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: _sendWhatsApp, icon: const Icon(Icons.chat, size: 18), label: const Text('Send WhatsApp')),
            ],
          ),
        ),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
        else
          Expanded(
            child: _rows.isEmpty
                ? const Center(child: Text('No transactions in range'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _rows.length,
                    itemBuilder: (_, i) {
                      final t = _rows[i];
                      final type = t['transaction_type']?.toString() ?? '';
                      final amt = (t['amount'] as num?)?.toDouble() ?? 0;
                      final debit = type == 'payment' ? 0.0 : amt;
                      final credit = type == 'payment' ? amt : 0.0;
                      final run = (t['running_balance'] as num?)?.toDouble();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            SizedBox(width: 100, child: Text(t['transaction_date']?.toString().substring(0, 10) ?? '—')),
                            Expanded(child: Text(t['description']?.toString() ?? '—', overflow: TextOverflow.ellipsis)),
                            SizedBox(width: 70, child: Text(debit > 0 ? 'R ${debit.toStringAsFixed(2)}' : '—')),
                            SizedBox(width: 70, child: Text(credit > 0 ? 'R ${credit.toStringAsFixed(2)}' : '—')),
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
