import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';

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
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase.from('invoices').select('*').order('created_at', ascending: false);
      setState(() => _invoices = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Invoices load: $e');
    }
    setState(() => _isLoading = false);
  }

  void _openInvoiceForm() {
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('Add Invoice Manually'),
        content: Text('Form to manually add supplier invoice details...'),
      ),
    );
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
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _openInvoiceForm,
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
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(children: [
                            Expanded(flex: 2, child: Text(inv['supplier_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold))),
                            SizedBox(width: 16),
                            SizedBox(width: 120, child: Text(inv['invoice_number'] ?? '—')),
                            SizedBox(width: 16),
                            SizedBox(width: 100, child: Text(inv['date'] ?? '—')),
                            SizedBox(width: 16),
                            SizedBox(width: 100, child: Text('R ${(inv['total_amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}')),
                            SizedBox(width: 16),
                            SizedBox(width: 120, child: Text(inv['status'] ?? 'Pending Review', style: const TextStyle(color: AppColors.warning))),
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
                          SizedBox(width: 16),
                          Expanded(flex: 2, child: Text(acc['name'] ?? '—')),
                          SizedBox(width: 16),
                          SizedBox(width: 150, child: Text(acc['type'] ?? '—')),
                          SizedBox(width: 16),
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
// TAB 3: P&L / REPORTS
// ══════════════════════════════════════════════════════════════════

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  Widget _buildPnLCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PROFIT & LOSS STATEMENT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Botha\'s Butchery (Pty) Ltd - Period: February 2026', style: TextStyle(color: AppColors.textSecondary)),
            const Divider(height: 32),
            const Text('REVENUE:', style: TextStyle(fontWeight: FontWeight.bold)),
            _pnlRow('Meat Sales (POS)', 145230.00),
            _pnlRow('Hunter Processing Fees', 8500.00),
            const Divider(),
            _pnlRow('Total Revenue', 153730.00, isBold: true),
            const SizedBox(height: 24),
            const Text('COST OF GOODS SOLD:', style: TextStyle(fontWeight: FontWeight.bold)),
            _pnlRow('Meat Purchases', 85340.00),
            _pnlRow('Spices & Casings', 3210.00),
            _pnlRow('Packaging Materials', 1850.00),
            _pnlRow('Shrinkage / Waste', 4520.00),
            const Divider(),
            _pnlRow('Total COGS', 94920.00, isBold: true),
            const SizedBox(height: 24),
            _pnlRow('GROSS PROFIT', 58810.00, isBold: true, highlight: AppColors.info),
            const Text(' (38.2%)', style: TextStyle(color: AppColors.info, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            const Text('OPERATING EXPENSES:', style: TextStyle(fontWeight: FontWeight.bold)),
            _pnlRow('Salaries & Wages', 28450.00),
            _pnlRow('Rent', 6500.00),
            _pnlRow('Electricity', 2340.00),
            _pnlRow('Equipment Maintenance', 850.00),
            _pnlRow('Marketing & Sponsorship', 500.00),
            _pnlRow('Donations', 200.00),
            _pnlRow('Purchase Sale Repayment', 5000.00),
            const Divider(),
            _pnlRow('Total Operating Expenses', 47260.00, isBold: true),
            const SizedBox(height: 24),
            _pnlRow('NET PROFIT', 11550.00, isBold: true, highlight: AppColors.success),
            const Text(' (7.5%)', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
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

  Widget _buildVatCard() {
    return Card(
      margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('VAT REPORT (SARS VAT201)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(height: 32),
            _pnlRow('Output VAT (Sales)', 20052.00),
            _pnlRow('Input VAT (Purchases)', 12450.00),
            const Divider(),
            _pnlRow('VAT Payable to SARS', 7602.00, isBold: true, highlight: AppColors.error),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _buildPnLCard()),
          Expanded(flex: 2, child: _buildVatCard()),
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
                            SizedBox(width: 16),
                            SizedBox(width: 120, child: Text(eq['serial_number'] ?? '—')),
                            SizedBox(width: 16),
                            SizedBox(width: 100, child: Text('R ${(eq['original_cost'] as num?)?.toStringAsFixed(2) ?? '0.00'}')),
                            SizedBox(width: 16),
                            SizedBox(width: 100, child: Text('R ${(eq['transfer_value'] as num?)?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(color: AppColors.primary))),
                            SizedBox(width: 16),
                            SizedBox(width: 80, child: Text('${eq['useful_life_years'] ?? '0'}')),
                            SizedBox(width: 16),
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
