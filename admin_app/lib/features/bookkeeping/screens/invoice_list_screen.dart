import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/ocr_service.dart';
import 'package:admin_app/features/bookkeeping/models/invoice.dart';
import 'package:admin_app/features/bookkeeping/screens/invoice_form_screen.dart';
import 'package:admin_app/features/bookkeeping/services/invoice_repository.dart';
import 'package:admin_app/features/bookkeeping/screens/chart_of_accounts_screen.dart';
import 'package:admin_app/features/bookkeeping/screens/ledger_screen.dart';
import 'package:admin_app/features/bookkeeping/screens/pl_screen.dart';
import 'package:admin_app/features/bookkeeping/screens/vat_report_screen.dart';
import 'package:admin_app/features/bookkeeping/screens/cash_flow_screen.dart';
import 'package:admin_app/features/bookkeeping/screens/equipment_register_screen.dart';
import 'package:admin_app/features/bookkeeping/screens/pty_conversion_screen.dart';
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
    _tabController = TabController(length: 6, vsync: this);
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
                Tab(icon: Icon(Icons.list_alt, size: 18), text: 'Ledger'),
                Tab(icon: Icon(Icons.account_balance_wallet, size: 18), text: 'Chart of Accounts'),
                Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'P&L / Reports'),
                Tab(icon: Icon(Icons.build, size: 18), text: 'Equipment'),
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
                LedgerScreen(embedded: true),
                ChartOfAccountsScreen(embedded: true),
                _ReportsHubTab(),
                EquipmentRegisterScreen(embedded: true),
                PtyConversionScreen(embedded: true),
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
    final userId = SupabaseService.client.auth.currentUser?.id;
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
    final userId = SupabaseService.client.auth.currentUser?.id;
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
          child: Row(
            children: [
              const Expanded(flex: 2, child: Text('SUPPLIER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5))),
              const SizedBox(width: 16),
              const SizedBox(width: 120, child: Text('INVOICE #', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5))),
              const SizedBox(width: 16),
              const SizedBox(width: 100, child: Text('DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5))),
              const SizedBox(width: 16),
              const SizedBox(width: 100, child: Text('TOTAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5))),
              const SizedBox(width: 16),
              const SizedBox(width: 120, child: Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5))),
            ],
          ),
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
// TAB 4: P&L / REPORTS — H7: P&L | VAT 201 | Cash Flow
// ══════════════════════════════════════════════════════════════════

class _ReportsHubTab extends StatefulWidget {
  const _ReportsHubTab();

  @override
  State<_ReportsHubTab> createState() => _ReportsHubTabState();
}

class _ReportsHubTabState extends State<_ReportsHubTab>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.surfaceBg,
          child: TabBar(
            controller: _subTabController,
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(icon: Icon(Icons.trending_up, size: 18), text: 'P&L'),
              Tab(icon: Icon(Icons.receipt_long, size: 18), text: 'VAT 201'),
              Tab(icon: Icon(Icons.account_balance, size: 18), text: 'Cash Flow'),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: const [
              PLScreen(embedded: true),
              VatReportScreen(embedded: true),
              CashFlowScreen(embedded: true),
            ],
          ),
        ),
      ],
    );
  }
}

