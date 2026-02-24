import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/auth_service.dart';
import 'package:admin_app/core/services/ocr_service.dart';
import 'package:admin_app/features/bookkeeping/models/customer_invoice.dart';
import 'package:admin_app/features/bookkeeping/models/supplier_invoice.dart';
import 'package:admin_app/features/bookkeeping/screens/customer_invoice_form_screen.dart';
import 'package:admin_app/features/bookkeeping/screens/supplier_invoice_form_screen.dart';
import 'package:admin_app/features/bookkeeping/services/customer_invoice_repository.dart';
import 'package:admin_app/features/bookkeeping/services/supplier_invoice_repository.dart';
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
// TAB 1: INVOICES — sub-tabs Customer Invoices | Supplier Invoices
// ══════════════════════════════════════════════════════════════════

class _InvoicesTab extends StatefulWidget {
  const _InvoicesTab();
  @override
  State<_InvoicesTab> createState() => _InvoicesTabState();
}

class _InvoicesTabState extends State<_InvoicesTab> with SingleTickerProviderStateMixin {
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
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
              Tab(icon: Icon(Icons.person, size: 18), text: 'Customer Invoices'),
              Tab(icon: Icon(Icons.local_shipping, size: 18), text: 'Supplier Invoices'),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: const [
              _CustomerInvoicesSubTab(),
              _SupplierInvoicesSubTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Customer Invoices sub-tab ─────────────────────────────────────

class _CustomerInvoicesSubTab extends StatefulWidget {
  const _CustomerInvoicesSubTab();

  @override
  State<_CustomerInvoicesSubTab> createState() => _CustomerInvoicesSubTabState();
}

class _CustomerInvoicesSubTabState extends State<_CustomerInvoicesSubTab> {
  final _repo = CustomerInvoiceRepository();
  List<CustomerInvoice> _invoices = [];
  bool _isLoading = true;
  String? _statusFilter;

  static const List<MapEntry<String, String>> _statusOptions = [
    MapEntry('', 'All'),
    MapEntry('draft', 'Draft'),
    MapEntry('pending_review', 'Pending Review'),
    MapEntry('approved', 'Approved'),
    MapEntry('sent', 'Sent'),
    MapEntry('paid', 'Paid'),
    MapEntry('overdue', 'Overdue'),
    MapEntry('cancelled', 'Cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final list = await _repo.getAll(status: _statusFilter?.isEmpty == true ? null : _statusFilter);
      if (mounted) setState(() => _invoices = list);
    } catch (e) {
      debugPrint('Customer invoices load: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _openForm({CustomerInvoice? invoice}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerInvoiceFormScreen(invoice: invoice),
      ),
    );
    if (result == true) _load();
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
              const Text('Customer Invoices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _statusFilter ?? '',
                hint: const Text('Status'),
                items: _statusOptions.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) {
                  setState(() {
                    _statusFilter = v?.isEmpty == true ? null : v;
                    _load();
                  });
                },
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New customer invoice'),
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
              const Expanded(flex: 2, child: Text('ACCOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5))),
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
                  ? const Center(child: Text('No customer invoices'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: _invoices.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (_, i) {
                        final inv = _invoices[i];
                        final dateStr = '${inv.invoiceDate.day.toString().padLeft(2, '0')}/${inv.invoiceDate.month.toString().padLeft(2, '0')}/${inv.invoiceDate.year}';
                        return InkWell(
                          onTap: () => _openForm(invoice: inv),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: Text(inv.accountName ?? '—', style: const TextStyle(fontWeight: FontWeight.bold))),
                                const SizedBox(width: 16),
                                SizedBox(width: 120, child: Text(inv.invoiceNumber)),
                                const SizedBox(width: 16),
                                SizedBox(width: 100, child: Text(dateStr)),
                                const SizedBox(width: 16),
                                SizedBox(width: 100, child: Text('R ${inv.total.toStringAsFixed(2)}')),
                                const SizedBox(width: 16),
                                SizedBox(width: 120, child: Text(inv.status.displayLabel, style: TextStyle(color: AppColors.textSecondary))),
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

// ─── Supplier Invoices sub-tab ─────────────────────────────────────

class _SupplierInvoicesSubTab extends StatefulWidget {
  const _SupplierInvoicesSubTab();

  @override
  State<_SupplierInvoicesSubTab> createState() => _SupplierInvoicesSubTabState();
}

class _SupplierInvoicesSubTabState extends State<_SupplierInvoicesSubTab> {
  final _repo = SupplierInvoiceRepository();
  final _ocrService = OcrService();
  final _supplierRepo = SupplierRepository();
  List<SupplierInvoice> _invoices = [];
  bool _isLoading = true;
  bool _ocrLoading = false;
  bool _bulkImporting = false;
  String? _statusFilter;

  static const List<MapEntry<String, String>> _statusOptions = [
    MapEntry('', 'All'),
    MapEntry('draft', 'Draft'),
    MapEntry('pending_review', 'Pending Review'),
    MapEntry('approved', 'Approved'),
    MapEntry('paid', 'Paid'),
    MapEntry('overdue', 'Overdue'),
    MapEntry('cancelled', 'Cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final list = await _repo.getAll(status: _statusFilter?.isEmpty == true ? null : _statusFilter);
      if (mounted) setState(() => _invoices = list);
    } catch (e) {
      debugPrint('Supplier invoices load: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _openForm({SupplierInvoice? invoice}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierInvoiceFormScreen(invoice: invoice),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _bulkImportCsv() async {
    final createdBy = AuthService().getCurrentStaffId();
    if (createdBy.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in with PIN to bulk import'), backgroundColor: AppColors.warning),
        );
      }
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || result.files.single.bytes == null || !mounted) return;
    setState(() => _bulkImporting = true);
    int successCount = 0;
    final errors = <String>[];
    try {
      final content = String.fromCharCodes(result.files.single.bytes!);
      List<List<dynamic>> rows;
      try {
        rows = const CsvToListConverter().convert(content);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid CSV: $e'), backgroundColor: AppColors.error),
          );
        }
        return;
      }
      if (rows.isEmpty || rows.length < 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CSV is empty or has no data rows'), backgroundColor: AppColors.warning),
          );
        }
        return;
      }
      final headerRow = rows.first.map((c) => (c as String).trim()).toList();
      final headersLower = headerRow.map((h) => h.toString().toLowerCase()).toList();
      final invNumIdx = headersLower.indexOf('invoice_number');
      final invNumAlt = headersLower.indexOf('invoice number');
      final invNumCol = invNumIdx >= 0 ? invNumIdx : invNumAlt;
      final supplierIdx = headersLower.indexOf('supplier_name');
      final supplierAlt = headersLower.indexOf('supplier');
      final supplierCol = supplierIdx >= 0 ? supplierIdx : supplierAlt;
      final dateIdx = headersLower.indexOf('invoice_date');
      final dateAlt = headersLower.indexOf('date');
      final dateCol = dateIdx >= 0 ? dateIdx : dateAlt;
      final dueIdx = headersLower.indexOf('due_date');
      final dueCol = dueIdx >= 0 ? dueIdx : -1;
      final subtotalCol = headersLower.indexOf('subtotal');
      final taxCol = headersLower.indexOf('tax_amount');
      final taxAlt = headersLower.indexOf('tax');
      final taxColRes = taxCol >= 0 ? taxCol : taxAlt;
      final totalCol = headersLower.indexOf('total_amount');
      final totalAlt = headersLower.indexOf('total');
      final totalColRes = totalCol >= 0 ? totalCol : totalAlt;
      final notesCol = headersLower.indexOf('notes');

      final suppliers = await _supplierRepo.getSuppliers(activeOnly: true);
      final supplierByName = {for (var s in suppliers) s.name.toLowerCase(): s.id};

      for (var i = 1; i < rows.length; i++) {
        if (!mounted) break;
        final row = rows[i];
        if (row.isEmpty) continue;
        String? invoiceNumber;
        if (invNumCol >= 0 && invNumCol < row.length && row[invNumCol].toString().trim().isNotEmpty) {
          invoiceNumber = row[invNumCol].toString().trim();
        } else {
          try {
            invoiceNumber = await _repo.nextInvoiceNumber();
          } catch (_) {
            errors.add('Row ${i + 1}: could not generate invoice number');
            continue;
          }
        }
        String? supplierId;
        if (supplierCol >= 0 && supplierCol < row.length) {
          final name = row[supplierCol].toString().trim();
          if (name.isNotEmpty) supplierId = supplierByName[name.toLowerCase()];
        }
        DateTime invoiceDate = DateTime.now();
        if (dateCol >= 0 && dateCol < row.length) {
          final d = DateTime.tryParse(row[dateCol].toString().trim());
          if (d != null) invoiceDate = d;
        }
        DateTime dueDate = invoiceDate.add(const Duration(days: 30));
        if (dueCol >= 0 && dueCol < row.length) {
          final d = DateTime.tryParse(row[dueCol].toString().trim());
          if (d != null) dueDate = d;
        }
        double subtotal = 0;
        if (subtotalCol >= 0 && subtotalCol < row.length) {
          subtotal = double.tryParse(row[subtotalCol].toString().replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0;
        }
        double taxAmount = 0;
        if (taxColRes >= 0 && taxColRes < row.length) {
          taxAmount = double.tryParse(row[taxColRes].toString().replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0;
        }
        double totalAmount = 0;
        if (totalColRes >= 0 && totalColRes < row.length) {
          totalAmount = double.tryParse(row[totalColRes].toString().replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0;
        }
        if (totalAmount <= 0 && subtotal > 0) totalAmount = subtotal + taxAmount;
        if (subtotal <= 0 && totalAmount > 0) subtotal = totalAmount - taxAmount;
        String? notes;
        if (notesCol >= 0 && notesCol < row.length && row[notesCol].toString().trim().isNotEmpty) {
          notes = row[notesCol].toString().trim();
        }
        try {
          final inv = SupplierInvoice(
            id: '',
            invoiceNumber: invoiceNumber!,
            supplierId: supplierId,
            invoiceDate: invoiceDate,
            dueDate: dueDate,
            lineItems: const [],
            subtotal: subtotal,
            taxAmount: taxAmount,
            total: totalAmount,
            status: SupplierInvoiceStatus.draft,
            notes: notes,
            createdBy: createdBy,
          );
          await _repo.create(inv);
          successCount++;
        } catch (e) {
          errors.add('Row ${i + 1} ($invoiceNumber): $e');
        }
      }
      await _load();
      if (mounted) {
        if (errors.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported $successCount invoice(s)'), backgroundColor: AppColors.success),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imported $successCount; ${errors.length} failed. ${errors.take(2).join(' ')}'),
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _bulkImporting = false);
    }
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

  Future<void> _addFromPhoto({bool fromGallery = false}) async {
    final userId = AuthService().getCurrentStaffId();
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in with PIN to add from photo'), backgroundColor: AppColors.warning),
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
      _openForm(invoice: invoice);
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

  Future<void> _approve(SupplierInvoice inv) async {
    final userId = AuthService().getCurrentStaffId();
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in with PIN to approve'), backgroundColor: AppColors.warning),
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
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _statusFilter ?? '',
                hint: const Text('Status'),
                items: _statusOptions.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) {
                  setState(() {
                    _statusFilter = v?.isEmpty == true ? null : v;
                    _load();
                  });
                },
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _bulkImporting ? null : _bulkImportCsv,
                icon: _bulkImporting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.upload_file, size: 18),
                label: Text(_bulkImporting ? 'Importing…' : 'Bulk Import CSV'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _ocrLoading ? null : _showOcrSourceDialog,
                icon: _ocrLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.camera_alt, size: 18),
                label: Text(_ocrLoading ? 'Processing…' : 'From photo'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _openForm(),
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
                  ? const Center(child: Text('No supplier invoices recorded'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: _invoices.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (_, i) {
                        final inv = _invoices[i];
                        final dateStr = '${inv.invoiceDate.day.toString().padLeft(2, '0')}/${inv.invoiceDate.month.toString().padLeft(2, '0')}/${inv.invoiceDate.year}';
                        return InkWell(
                          onTap: () => _openForm(invoice: inv),
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
                                SizedBox(width: 100, child: Text('R ${inv.total.toStringAsFixed(2)}')),
                                const SizedBox(width: 16),
                                SizedBox(width: 120, child: Text(inv.status.displayLabel, style: TextStyle(color: inv.canApprove ? AppColors.warning : AppColors.textSecondary))),
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

