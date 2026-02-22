import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/ocr_service.dart';
import 'package:admin_app/features/bookkeeping/models/invoice.dart';
import 'package:admin_app/features/bookkeeping/screens/invoice_form_screen.dart';
import 'package:admin_app/features/bookkeeping/services/invoice_repository.dart';
import 'package:admin_app/features/bookkeeping/services/ledger_repository.dart';
import 'package:admin_app/features/inventory/services/supplier_repository.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      body: Column(
        children: [
          Container(
            color: AppColors.cardBg,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(icon: Icon(Icons.receipt, size: 18), text: 'Invoices'),
                Tab(icon: Icon(Icons.account_balance_wallet, size: 18), text: 'Chart of Accounts'),
                Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'P&L / Reports'),
                Tab(icon: Icon(Icons.business, size: 18), text: 'PTY Conversion'),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _InvoicesTab(),
                _ChartOfAccountsTab(),
                _ReportsTab(),
                _PtyConversionTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 1: INVOICES
// ══════════════════════════════════════════════════════════════════

class _InvoicesTab extends StatefulWidget {
  const _InvoicesTab();
  @override
  State<_InvoicesTab> createState() => _InvoicesTabState();
}

class _InvoicesTabState extends State<_InvoicesTab> {
  final _repo = InvoiceRepository();
  final _ocrService = OcrService();
  final _supplierRepo = SupplierRepository();
  List<Invoice> _invoices = [];
  bool _isLoading = true;
  bool _ocrLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final list = await _repo.getInvoices();
      setState(() => _invoices = list);
    } catch (e) {
      debugPrint('Invoices load: $e');
    }
    setState(() => _isLoading = false);
  }

  void _openInvoiceForm({Invoice? invoice}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceFormScreen(invoice: invoice),
      ),
    );
    if (result == true) _load();
  }

  void _showOcrSourceDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add invoice from photo'),
        content: const Text('Take a photo of the receipt/invoice or choose from gallery. The invoice will be created as Pending review.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _addFromPhoto(fromGallery: false);
            },
            child: const Text('Take photo'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _addFromPhoto(fromGallery: true);
            },
            child: const Text('Choose from gallery'),
          ),
        ],
      ),
    );
  }

  /// OCR pipeline: photo/gallery → OcrService → InvoiceRepository.createFromOcrResult → invoice with status pending_review.
  Future<void> _addFromPhoto({bool fromGallery = false}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to add from photo'), backgroundColor: AppColors.warning),
      );
      return;
    }
    setState(() => _ocrLoading = true);
    try {
      final result = fromGallery
          ? await _ocrService.processReceiptFromGallery()
          : await _ocrService.processReceiptFromCamera();
      if (!mounted) return;
      if (result == null || (result['total_amount'] == null && (result['items'] as List?)?.isEmpty == true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read invoice from image. Try manual entry.'), backgroundColor: AppColors.warning),
        );
        return;
      }
      String? supplierId;
      final vendorName = result['vendor_name']?.toString()?.trim();
      if (vendorName != null && vendorName.isNotEmpty) {
        final suppliers = await _supplierRepo.getSuppliers(activeOnly: true);
        final matched = suppliers.where((s) => s.name.toLowerCase().contains(vendorName.toLowerCase())).toList();
        if (matched.isNotEmpty) supplierId = matched.first.id;
      }
      final invoice = await _repo.createFromOcrResult(ocrResult: result, createdBy: userId, supplierId: supplierId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice created from photo (pending review)'), backgroundColor: AppColors.success),
      );
      _load();
      _openInvoiceForm(invoice: invoice);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OCR failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _ocrLoading = false);
    }
  }

  Future<void> _approve(Invoice inv) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to approve'), backgroundColor: AppColors.warning),
      );
      return;
    }
    try {
      await _repo.approve(inv.id, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice approved and posted to ledger'), backgroundColor: AppColors.success),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.cardBg,
          child: Row(
            children: [
              const Text('Supplier Invoices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Bulk Import CSV'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _ocrLoading ? null : () => _showOcrSourceDialog(),
                icon: _ocrLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.camera_alt, size: 18),
                label: Text(_ocrLoading ? 'Processing…' : 'From photo'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _openInvoiceForm(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Manually'),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          color: AppColors.surfaceBg,
          child: const Row(children: [
            Expanded(flex: 2, child: Text('SUPPLIER', style: _h)),
            SizedBox(width: 16),
            SizedBox(width: 120, child: Text('INVOICE #', style: _h)),
            SizedBox(width: 16),
            SizedBox(width: 100, child: Text('DATE', style: _h)),
            SizedBox(width: 16),
            SizedBox(width: 100, child: Text('TOTAL', style: _h)),
            SizedBox(width: 16),
            SizedBox(width: 120, child: Text('STATUS', style: _h)),
          ]),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _invoices.isEmpty
                  ? const Center(child: Text('No invoices recorded'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: _invoices.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (_, i) {
                        final inv = _invoices[i];
                        final dateStr = '${inv.invoiceDate.day.toString().padLeft(2, '0')}/${inv.invoiceDate.month.toString().padLeft(2, '0')}/${inv.invoiceDate.year}';
                        return InkWell(
                          onTap: () => _openInvoiceForm(invoice: inv),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: Text(inv.supplierName ?? '—', style: const TextStyle(fontWeight: FontWeight.bold))),
                                const SizedBox(width: 16),
                                SizedBox(width: 120, child: Text(inv.invoiceNumber)),
                                const SizedBox(width: 16),
                                SizedBox(width: 100, child: Text(dateStr)),
                                const SizedBox(width: 16),
                                SizedBox(width: 100, child: Text('R ${inv.totalAmount.toStringAsFixed(2)}')),
                                const SizedBox(width: 16),
                                SizedBox(width: 120, child: Text(inv.status.dbValue, style: TextStyle(color: inv.canApprove ? AppColors.warning : AppColors.textSecondary))),
                                if (inv.canApprove)
                                  TextButton(
                                    onPressed: () => _approve(inv),
                                    child: const Text('Approve'),
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
// TAB 2: CHART OF ACCOUNTS
// ══════════════════════════════════════════════════════════════════

class _ChartOfAccountsTab extends StatefulWidget {
  const _ChartOfAccountsTab();
  @override
  State<_ChartOfAccountsTab> createState() => _ChartOfAccountsTabState();
}

class _ChartOfAccountsTabState extends State<_ChartOfAccountsTab> {
  final _supabase = Supabase.instance.client;
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
      final res = await _supabase.from('chart_of_accounts').select('*').order('account_number');
      setState(() => _accounts = List<Map<String, dynamic>>.from(res));
    } catch (e) {
      debugPrint('Accounts: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.cardBg,
          child: Row(
            children: [
              const Text('Chart of Accounts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Account'),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          color: AppColors.surfaceBg,
          child: const Row(children: [
            SizedBox(width: 80, child: Text('ACC #', style: _h)),
            SizedBox(width: 16),
            Expanded(flex: 2, child: Text('ACCOUNT NAME', style: _h)),
            SizedBox(width: 16),
            SizedBox(width: 150, child: Text('TYPE', style: _h)),
            SizedBox(width: 16),
            SizedBox(width: 100, child: Text('BALANCE', style: _h)),
          ]),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _accounts.isEmpty
                ? const Center(child: Text('Chart of accounts empty'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: _accounts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (_, i) {
                      final acc = _accounts[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(children: [
                          SizedBox(width: 80, child: Text('${acc['account_number']}', style: const TextStyle(fontWeight: FontWeight.bold))),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: Text(acc['name'] ?? '—')),
                          const SizedBox(width: 16),
                          SizedBox(width: 150, child: Text(acc['type'] ?? '—')),
                          const SizedBox(width: 16),
                          SizedBox(width: 100, child: Text('R ${(acc['balance'] as num?)?.toStringAsFixed(2) ?? '0.00'}')),
                        ]),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 3: P&L / REPORTS (from ledger — Blueprint §9.4, §9.5, §9.6)
// ══════════════════════════════════════════════════════════════════

/// Blueprint account code → display label (fallback when chart_of_accounts not used).
const Map<String, String> _accountLabels = {
  '4000': 'Meat Sales (POS)',
  '4100': 'Hunter Processing Fees',
  '4200': 'Other Income',
  '5000': 'Meat Purchases',
  '5100': 'Spices & Casings',
  '5200': 'Packaging Materials',
  '5300': 'Shrinkage / Waste',
  '6000': 'Salaries & Wages',
  '6100': 'Rent',
  '6200': 'Electricity',
  '6300': 'Equipment Maintenance',
  '6400': 'Insurance',
  '6500': 'Marketing & Sponsorship',
  '6510': 'Donations',
  '6600': 'Transport & Fuel',
  '6700': 'Purchase Sale Repayments',
  '6900': 'Sundry Expenses',
};

class _ReportsTab extends StatefulWidget {
  const _ReportsTab();

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  final LedgerRepository _ledger = LedgerRepository();
  DateTime _periodStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _periodEnd = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  bool _loading = true;
  Map<String, Map<String, double>> _pnlSummary = {};
  double _outputVat = 0, _inputVat = 0, _vatPayable = 0;
  double _cashIn = 0, _cashOut = 0, _bankIn = 0, _bankOut = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final pnl = await _ledger.getPnLSummary(_periodStart, _periodEnd);
      final vat = await _ledger.getVatSummary(_periodStart, _periodEnd);
      final cash = await _ledger.getCashFlowSummary(_periodStart, _periodEnd);
      setState(() {
        _pnlSummary = pnl;
        _outputVat = vat.outputVat;
        _inputVat = vat.inputVat;
        _vatPayable = vat.payable;
        _cashIn = cash.cashIn;
        _cashOut = cash.cashOut;
        _bankIn = cash.bankIn;
        _bankOut = cash.bankOut;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Reports load: $e');
      setState(() => _loading = false);
    }
  }

  double _revenueTotal() {
    double t = 0;
    for (final code in ['4000', '4100', '4200']) {
      t += _pnlSummary[code]?['credit'] ?? 0;
    }
    return t;
  }

  double _cogsTotal() {
    double t = 0;
    for (final code in ['5000', '5100', '5200', '5300']) {
      t += _pnlSummary[code]?['debit'] ?? 0;
    }
    return t;
  }

  double _expensesTotal() {
    double t = 0;
    for (final code in ['6000', '6100', '6200', '6300', '6400', '6500', '6510', '6600', '6700', '6900']) {
      t += _pnlSummary[code]?['debit'] ?? 0;
    }
    return t;
  }

  Widget _pnlRow(String label, double amount, {bool isBold = false, Color? highlight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: highlight)),
          Text('R ${amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: highlight ?? AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildPnLCard() {
    final revenue = _revenueTotal();
    final cogs = _cogsTotal();
    final grossProfit = revenue - cogs;
    final grossPct = revenue > 0 ? (grossProfit / revenue * 100) : 0.0;
    final expenses = _expensesTotal();
    final netProfit = grossProfit - expenses;
    final netPct = revenue > 0 ? (netProfit / revenue * 100) : 0.0;
    final periodLabel = '${_periodStart.year}-${_periodStart.month.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('PROFIT & LOSS STATEMENT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _loading ? null : () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _periodStart,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(now.year + 1),
                    );
                    if (picked != null) {
                      setState(() {
                        _periodStart = DateTime(picked.year, picked.month, 1);
                        _periodEnd = DateTime(picked.year, picked.month + 1, 0);
                      });
                      _load();
                    }
                  },
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: Text(periodLabel),
                ),
              ],
            ),
            const Text('From ledger — select period', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const Divider(height: 32),
            const Text('REVENUE:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...['4000', '4100', '4200'].map((code) {
              final credit = _pnlSummary[code]?['credit'] ?? 0;
              if (credit == 0) return const SizedBox.shrink();
              return _pnlRow(_accountLabels[code] ?? code, credit);
            }),
            const Divider(),
            _pnlRow('Total Revenue', revenue, isBold: true),
            const SizedBox(height: 24),
            const Text('COST OF GOODS SOLD:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...['5000', '5100', '5200', '5300'].map((code) {
              final debit = _pnlSummary[code]?['debit'] ?? 0;
              if (debit == 0) return const SizedBox.shrink();
              return _pnlRow(_accountLabels[code] ?? code, debit);
            }),
            const Divider(),
            _pnlRow('Total COGS', cogs, isBold: true),
            const SizedBox(height: 24),
            _pnlRow('GROSS PROFIT', grossProfit, isBold: true, highlight: AppColors.info),
            Text(' (${grossPct.toStringAsFixed(1)}%)', style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            const Text('OPERATING EXPENSES:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...['6000', '6100', '6200', '6300', '6400', '6500', '6510', '6600', '6700', '6900'].map((code) {
              final debit = _pnlSummary[code]?['debit'] ?? 0;
              if (debit == 0) return const SizedBox.shrink();
              return _pnlRow(_accountLabels[code] ?? code, debit);
            }),
            const Divider(),
            _pnlRow('Total Operating Expenses', expenses, isBold: true),
            const SizedBox(height: 24),
            _pnlRow('NET PROFIT', netProfit, isBold: true, highlight: AppColors.success),
            Text(' (${netPct.toStringAsFixed(1)}%)', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildVatCard() {
    return Card(
      margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('VAT REPORT (SARS VAT201)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('From ledger — ${_periodStart.year}-${_periodStart.month.toString().padLeft(2, '0')}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const Divider(height: 32),
            _pnlRow('Output VAT (Sales)', _outputVat),
            _pnlRow('Input VAT (Purchases)', _inputVat),
            const Divider(),
            _pnlRow('VAT Payable to SARS', _vatPayable, isBold: true, highlight: AppColors.error),
          ],
        ),
      ),
    );
  }

  Widget _buildCashFlowCard() {
    final cashNet = _cashIn - _cashOut;
    final bankNet = _bankIn - _bankOut;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CASH FLOW', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('From ledger — ${_periodStart.year}-${_periodStart.month.toString().padLeft(2, '0')}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const Divider(height: 24),
            _pnlRow('+ Cash in', _cashIn),
            _pnlRow('− Cash out', _cashOut),
            _pnlRow('Cash net', cashNet, isBold: true),
            const SizedBox(height: 12),
            _pnlRow('+ Bank in', _bankIn),
            _pnlRow('− Bank out', _bankOut),
            _pnlRow('Bank net', bankNet, isBold: true),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _buildPnLCard()),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildVatCard(),
                _buildCashFlowCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 4: PTY CONVERSION & EQUIPMENT
// ══════════════════════════════════════════════════════════════════

class _PtyConversionTab extends StatefulWidget {
  const _PtyConversionTab();
  @override
  State<_PtyConversionTab> createState() => _PtyConversionTabState();
}

class _PtyConversionTabState extends State<_PtyConversionTab> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _equipment = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase.from('equipment_register').select('*');
      setState(() => _equipment = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Equipment load: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.cardBg,
          child: Row(
            children: [
              const Text('Equipment Register (PTY Conversion)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Equipment'),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          color: AppColors.surfaceBg,
          child: const Row(children: [
            Expanded(flex: 2, child: Text('NAME', style: _h)),
            SizedBox(width: 16),
            SizedBox(width: 120, child: Text('SERIAL NO', style: _h)),
            SizedBox(width: 16),
            SizedBox(width: 100, child: Text('ORIG COST', style: _h)),
            SizedBox(width: 16),
            SizedBox(width: 100, child: Text('XFER VALUE', style: _h)),
            SizedBox(width: 16),
            SizedBox(width: 80, child: Text('LIFE (YRS)', style: _h)),
            SizedBox(width: 16),
            SizedBox(width: 100, child: Text('BOOK VALUE', style: _h)),
          ]),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _equipment.isEmpty
                  ? const Center(child: Text('No equipment registered'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: _equipment.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (_, i) {
                        final eq = _equipment[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(children: [
                            Expanded(flex: 2, child: Text(eq['name'] ?? '—', style: const TextStyle(fontWeight: FontWeight.bold))),
                            const SizedBox(width: 16),
                            SizedBox(width: 120, child: Text(eq['serial_number'] ?? '—')),
                            const SizedBox(width: 16),
                            SizedBox(width: 100, child: Text('R ${(eq['original_cost'] as num?)?.toStringAsFixed(2) ?? '0.00'}')),
                            const SizedBox(width: 16),
                            SizedBox(width: 100, child: Text('R ${(eq['transfer_value'] as num?)?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(color: AppColors.primary))),
                            const SizedBox(width: 16),
                            SizedBox(width: 80, child: Text('${eq['useful_life_years'] ?? '0'}')),
                            const SizedBox(width: 16),
                            SizedBox(width: 100, child: Text('R ${(eq['current_book_value'] as num?)?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontWeight: FontWeight.bold))),
                          ]),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

const _h = TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5);
