import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/core/services/auth_service.dart';
import 'package:admin_app/core/services/connectivity_service.dart';
import 'package:admin_app/core/services/offline_queue_service.dart';
import 'package:admin_app/core/services/ocr_service.dart';
import 'package:admin_app/features/bookkeeping/models/customer_invoice.dart';
import 'package:admin_app/features/bookkeeping/models/supplier_invoice.dart';
import 'package:admin_app/features/bookkeeping/screens/customer_invoice_form_screen.dart';
import 'package:admin_app/features/bookkeeping/screens/supplier_invoice_form_screen.dart';
import 'package:admin_app/features/bookkeeping/services/customer_invoice_repository.dart';
import 'package:admin_app/features/bookkeeping/services/supplier_invoice_repository.dart';
import 'package:admin_app/features/bookkeeping/services/ledger_repository.dart';
import 'package:admin_app/features/bookkeeping/screens/chart_of_accounts_screen.dart';
import 'package:admin_app/features/bookkeeping/screens/ledger_screen.dart';
import 'package:admin_app/features/bookkeeping/screens/pl_screen.dart';
import 'package:admin_app/features/bookkeeping/screens/vat_report_screen.dart';
import 'package:admin_app/features/bookkeeping/screens/cash_flow_screen.dart';
import 'package:admin_app/features/bookkeeping/screens/equipment_register_screen.dart';
import 'package:admin_app/features/bookkeeping/screens/pty_conversion_screen.dart';
import 'package:admin_app/features/bookkeeping/screens/bank_reconciliation_screen.dart';
import 'package:admin_app/features/inventory/services/supplier_repository.dart';
import '../../../core/services/email_service.dart';
import '../services/invoice_pdf_service.dart';
import '../../../core/services/google_drive_service.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/local_invoice_service.dart';
import '../services/csv_sales_import_service.dart';
import 'supplier_mapping_screen.dart';
import '../../../core/services/supplier_mapping_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/config/edge_pipeline_config.dart';
import 'package:admin_app/core/services/edge_pipeline_client.dart';

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
    _tabController = TabController(length: 10, vsync: this);
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
                Tab(icon: Icon(Icons.receipt_long, size: 18), text: 'VAT Report'),
                Tab(icon: Icon(Icons.waterfall_chart, size: 18), text: 'Cash Flow'),
                Tab(icon: Icon(Icons.build, size: 18), text: 'Equipment'),
                Tab(icon: Icon(Icons.business, size: 18), text: 'PTY Conversion'),
                Tab(icon: Icon(Icons.account_balance, size: 18), text: 'Bank Recon'),
                Tab(icon: Icon(Icons.upload_file, size: 18), text: 'Sales Import'),
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
                VatReportScreen(embedded: true),
                CashFlowScreen(embedded: true),
                EquipmentRegisterScreen(embedded: true),
                PtyConversionScreen(embedded: true),
                BankReconciliationScreen(embedded: true),
                _CsvSalesImportTab(),
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
  final _emailService = EmailService();
  final _pdfService = InvoicePdfService();
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
    _sendPendingInvoices();
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

  Future<void> _sendPendingInvoices() async {
    try {
      final sent = await _emailService.sendPendingInvoices(
        pdfGenerator: (invoice) => _pdfService.generateCustomerInvoice(invoice),
      );
      if (sent > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$sent invoice${sent == 1 ? '' : 's'} emailed to account customers'),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('sendPendingInvoices error: $e');
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
          child: const Row(
            children: [
              Expanded(flex: 2, child: Text('ACCOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5))),
              SizedBox(width: 16),
              SizedBox(width: 120, child: Text('INVOICE #', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5))),
              SizedBox(width: 16),
              SizedBox(width: 100, child: Text('DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5))),
              SizedBox(width: 16),
              SizedBox(width: 100, child: Text('TOTAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5))),
              SizedBox(width: 16),
              SizedBox(width: 120, child: Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5))),
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
                                SizedBox(width: 120, child: Text(inv.status.displayLabel, style: const TextStyle(color: AppColors.textSecondary))),
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
  final _driveService = GoogleDriveService();
  final _aiService = AiService();
  final _mappingService = SupplierMappingService();
  bool _driveScanRunning = false;
  Timer? _dailyScanTimer;

  static const List<MapEntry<String, String>> _statusOptions = [
    MapEntry('', 'All'),
    MapEntry('draft', 'Draft'),
    MapEntry('pending_review', 'Pending Review'),
    MapEntry('approved', 'Approved'),
    MapEntry('received', 'Received'),
    MapEntry('paid', 'Paid'),
    MapEntry('overdue', 'Overdue'),
    MapEntry('cancelled', 'Cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _scanDriveFolder();
    // Schedule daily auto-scan every 24 hours
    _dailyScanTimer = Timer.periodic(
      const Duration(hours: 24),
      (_) => _scanDriveFolder(),
    );
  }

  @override
  void dispose() {
    _dailyScanTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final list = await _repo.getAll(status: _statusFilter?.isEmpty == true ? null : _statusFilter);
      if (mounted) setState(() => _invoices = list);
    } catch (e) {
      debugPrint('[INVOICES] Load failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load invoices. Please retry.'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
            SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error),
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

      if (invNumCol < 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CSV must include an invoice_number column'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }
      if (supplierCol < 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CSV must include supplier_name or supplier column'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      final suppliers = await _supplierRepo.getSuppliers(activeOnly: true);
      final supplierByName = {for (var s in suppliers) s.name.toLowerCase(): s.id};
      final unmatchedSuppliers = <String>{};

      for (var i = 1; i < rows.length; i++) {
        if (!mounted) break;
        final row = rows[i];
        if (row.isEmpty) continue;
        String? invoiceNumber;
        if (invNumCol < row.length &&
            row[invNumCol].toString().trim().isNotEmpty) {
          invoiceNumber = row[invNumCol].toString().trim();
        }
        if (invoiceNumber == null || invoiceNumber.isEmpty) {
          errors.add('Row ${i + 1}: invoice number is required');
          continue;
        }
        if (await _repo.invoiceNumberExists(invoiceNumber)) {
          errors.add(
            'Row ${i + 1}: Invoice number already exists. Please verify the document. ($invoiceNumber)',
          );
          continue;
        }
        String? supplierId;
        String supplierNameFromRow = '';
        if (supplierCol < row.length) {
          supplierNameFromRow = row[supplierCol].toString().trim();
        }
        if (supplierNameFromRow.isEmpty) {
          errors.add('Row ${i + 1}: supplier name is required');
          continue;
        }
        supplierId = supplierByName[supplierNameFromRow.toLowerCase()];
        if (supplierId == null) {
          unmatchedSuppliers.add(supplierNameFromRow);
          continue;
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
            invoiceNumber: invoiceNumber,
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
        final u = unmatchedSuppliers.length;
        final parts = <String>[];
        if (successCount > 0) {
          parts.add('Imported $successCount invoice(s).');
        }
        if (u > 0) {
          parts.add(
            '$u supplier${u == 1 ? '' : 's'} could not be matched. '
            'Please fix names before importing.',
          );
        }
        if (errors.isNotEmpty) {
          parts.add(
            '${errors.length} row error(s). ${errors.take(2).join(' ')}',
          );
        }
        if (parts.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No rows imported'),
              backgroundColor: AppColors.warning,
            ),
          );
        } else {
          final clean = errors.isEmpty && u == 0 && successCount > 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(parts.join(' ')),
              backgroundColor: clean
                  ? AppColors.success
                  : (u > 0 ? AppColors.error : AppColors.warning),
              duration: Duration(
                seconds: u > 0 || errors.length > 2 ? 8 : 5,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error),
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
          ? await _ocrService.scanFromFile()
          : await _ocrService.scanFromCamera();
      if (!mounted) return;
      if (result.cancelled) return;
      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? 'Could not read invoice. Try manual entry.'), backgroundColor: AppColors.warning),
        );
        return;
      }
      if (result.invoices.isNotEmpty) {
        await _showOcrPreviewDialog(result.invoices);
      } else if (result.supplierName != null ||
          result.invoiceNumber != null) {
        await _showOcrPreviewDialog([
          <String, dynamic>{
            'supplier_name': result.supplierName,
            'invoice_number': result.invoiceNumber,
            'invoice_date': result.invoiceDate,
            'grand_total': result.total,
            'line_items': result.lineItems
                .map((li) => <String, dynamic>{
                      'description': li.description,
                      'quantity': li.quantity,
                      'unit_price': li.unitPrice,
                      'line_total': li.lineTotal,
                    })
                .toList(),
            'warnings': <dynamic>[],
          }
        ]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _ocrLoading = false);
    }
  }

  Future<void> _showOcrPreviewDialog(
      List<Map<String, dynamic>> invoices) async {
    final userId = AuthService().getCurrentStaffId();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _OcrPreviewDialog(
        invoices: invoices,
        onApproveOne: (invoice) async {
          await _repo.createFromOcrResult(
            ocrResult: invoice,
            createdBy: userId,
          );
          if (mounted) {
            _load();
          }
        },
      ),
    );
  }

  Future<void> _receiveGoods(SupplierInvoice inv) async {
    final userId = AuthService().getCurrentStaffId();
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in with PIN to receive goods'), backgroundColor: AppColors.warning),
      );
      return;
    }
    if (!ConnectivityService().isConnected) {
      await OfflineQueueService().addToQueue('receive_invoice', {
        'invoiceId': inv.id,
        'receivedBy': userId,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved — will sync when back online.'), backgroundColor: AppColors.success),
        );
      }
      return;
    }
    try {
      final result = await _repo.receive(inv.id, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.itemsReceived > 0
                  ? 'Stock updated for ${result.itemsReceived} item(s)'
                  : 'No stock movements created — no products linked',
            ),
            backgroundColor: result.itemsReceived > 0 ? AppColors.success : AppColors.warning,
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _showPaymentDialog(Map<String, dynamic> invoice) async {
    final invoiceId = invoice['id']?.toString();
    final balanceDue = (invoice['balance_due'] as num?)?.toDouble() ?? 0.0;

    if (invoiceId == null || balanceDue <= 0) {
      return;
    }

    String selectedMethod = 'Bank EFT';
    double amount = balanceDue;
    final amountController = TextEditingController(
      text: balanceDue.toStringAsFixed(2),
    );

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Record Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Invoice: ${invoice['invoice_number']}'),
                Text('Balance due: R ${balanceDue.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Payment amount',
                    prefixText: 'R ',
                  ),
                  onChanged: (v) {
                    amount = double.tryParse(v.trim()) ?? 0;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment method',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Bank EFT',
                      child: Text('Bank EFT'),
                    ),
                    DropdownMenuItem(
                      value: 'cash',
                      child: Text('Cash'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => selectedMethod = v);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Confirm Payment'),
              ),
            ],
          ),
        ),
      );

      if (confirmed != true || !mounted) return;

      final payAmount =
          double.tryParse(amountController.text.trim()) ?? amount;

      final recordedBy = AuthService().getCurrentStaffId();
      if (recordedBy.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign in with PIN to record payments'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      try {
        await _repo.recordPayment(
          invoiceId: invoiceId,
          amount: payAmount,
          paymentMethod: selectedMethod,
          recordedBy: recordedBy,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment of R ${payAmount.toStringAsFixed(2)} recorded',
              ),
              backgroundColor: Colors.green,
            ),
          );
          _load();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      amountController.dispose();
    }
  }

  Future<void> _openMappingScreen(Map<String, dynamic> invoice) async {
    final lineItems = (invoice['line_items'] as List?)
        ?.map((e) => e as Map<String, dynamic>)
        .toList() ?? [];

    if (lineItems.isEmpty) return;

    final supplierId = invoice['supplier_id']?.toString();
    final supplierName = invoice['supplier_name']?.toString() ??
        invoice['suppliers']?['name']?.toString();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SupplierMappingScreen(
          invoiceId: invoice['id']?.toString(),
          pendingItems: lineItems,
          supplierId: supplierId,
          supplierName: supplierName,
          onMappingsComplete: () {
            Navigator.pop(context);
            _approveInvoice(invoice);
          },
        ),
      ),
    );
    _load();
  }

  Future<void> _approveInvoice(Map<String, dynamic> invoice) async {
    final invoiceId = invoice['id']?.toString();
    if (invoiceId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice ID missing — cannot approve'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final invNumRaw = invoice['invoice_number']?.toString().trim() ?? '';
    if (invNumRaw.isEmpty ||
        invNumRaw.startsWith('PENDING-')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Set a valid invoice number on the invoice before approving.',
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    try {
      final lineItems = (invoice['line_items'] as List?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [];

      final supplierId = invoice['supplier_id']?.toString();

      // Apply all mappings to line items
      final mapped = await _mappingService.applyMappings(
        lineItems: lineItems,
        supplierId: supplierId,
      );

      // Check all items are mapped
      final pending = mapped.where((i) => i.isPending).toList();
      if (pending.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${pending.length} item${pending.length == 1 ? '' : 's'} '
                'still need mapping'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Map Now',
              onPressed: () => _openMappingScreen(invoice),
            ),
          ),
        );
        return;
      }

      final subtotal = (invoice['subtotal'] as num?)?.toDouble() ?? 0;
      final taxAmount =
          (invoice['tax_amount'] as num?)?.toDouble() ?? 0;
      final total = (invoice['total'] as num?)?.toDouble() ?? 0;
      final lineItemsForVerify = lineItems
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final calcErrors = _repo.verifyCalculations(
        lineItems: lineItemsForVerify,
        subtotal: subtotal,
        taxAmount: taxAmount,
        total: total,
      );
      if (calcErrors.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cannot approve: ${calcErrors.length} calculation issue(s). '
                'Open the invoice and fix amounts before approving.',
              ),
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 6),
            ),
          );
        }
        return;
      }

      final entryDate = invoice['invoice_date'] ??
          DateTime.now().toIso8601String().substring(0, 10);
      final invNum = invoice['invoice_number']?.toString() ?? '';

      if (EdgePipelineConfig.canUseEdgePipeline) {
        final ledgerRows = <Map<String, dynamic>>[];
        for (final item in mapped) {
          if (item.mapping == null) continue;
          final m = item.mapping!;
          ledgerRows.add({
            'account_id': null,
            'account_code': m.accountCode,
            'entry_date': entryDate,
            'description': '${item.description} — Invoice $invNum',
            'debit': item.lineTotal,
            'credit': 0,
            'reference': invNum,
            'reference_type': 'supplier_invoice',
            'reference_id': invoiceId,
          });
        }
        ledgerRows.add({
          'account_code': '2000',
          'entry_date': entryDate,
          'description': 'Accounts Payable — Invoice $invNum',
          'debit': 0,
          'credit': (invoice['total'] as num?)?.toDouble() ?? 0,
          'reference': invNum,
          'reference_type': 'supplier_invoice',
          'reference_id': invoiceId,
        });
        if (taxAmount > 0) {
          ledgerRows.add({
            'account_code': '2100',
            'entry_date': entryDate,
            'description': 'Input VAT — Invoice $invNum',
            'debit': taxAmount,
            'credit': 0,
            'reference': invNum,
            'reference_type': 'supplier_invoice',
            'reference_id': invoiceId,
          });
        }
        await EdgePipelineClient.instance.adminPostSupplierLedger(
          invoiceId: invoiceId,
          ledgerRows: ledgerRows,
          invoicePatch: {
            'status': 'approved',
            'mappings_complete': true,
            'updated_at': DateTime.now().toIso8601String(),
          },
        );
      } else {
        final client = Supabase.instance.client;
        final ledgerRepository = LedgerRepository(client: client);

        // Process each mapped line item
        for (final item in mapped) {
          if (item.mapping == null) continue;
          final m = item.mapping!;

          // Post ledger entry
          await ledgerRepository.createEntry(
            date: DateTime.parse(entryDate),
            accountCode: m.accountCode,
            accountName: m.accountName ?? '',
            debit: item.lineTotal,
            credit: 0,
            description:
                '${item.description} — Invoice ${invoice['invoice_number'] ?? ''}',
            referenceType: 'supplier_invoice',
            referenceId: invoiceId,
            source: 'supplier_invoice',
            recordedBy: AuthService().getCurrentStaffId(),
          );
        }

        // Post AP credit entry (total payable to supplier)
        await ledgerRepository.createEntry(
          date: DateTime.parse(entryDate),
          accountCode: '2000',
          accountName: 'Accounts Payable',
          debit: 0,
          credit: (invoice['total'] as num?)?.toDouble() ?? 0,
          description:
              'Accounts Payable — Invoice ${invoice['invoice_number'] ?? ''}',
          referenceType: 'supplier_invoice',
          referenceId: invoiceId,
          source: 'supplier_invoice',
          recordedBy: AuthService().getCurrentStaffId(),
        );

        // Post VAT entry if applicable
        if (taxAmount > 0) {
          await ledgerRepository.createEntry(
            date: DateTime.parse(entryDate),
            accountCode: '2100',
            accountName: 'Input VAT',
            debit: taxAmount,
            credit: 0,
            description:
                'Input VAT — Invoice ${invoice['invoice_number'] ?? ''}',
            referenceType: 'supplier_invoice',
            referenceId: invoiceId,
            source: 'supplier_invoice',
            recordedBy: AuthService().getCurrentStaffId(),
          );
        }

        // Update invoice status to approved
        await client
            .from('supplier_invoices')
            .update({
              'status': 'approved',
              'mappings_complete': true,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', invoiceId);
      }

      // Auto-save any line item mappings not yet remembered
      try {
        for (final line in lineItems) {
          final invId =
              line['inventory_item_id']?.toString() ?? '';
          final desc =
              line['description']?.toString() ?? '';
          if (invId.isEmpty || desc.isEmpty) continue;

          final existing =
              await _mappingService.findMapping(
            description: desc,
            supplierId: supplierId,
          );

          if (existing == null) {
            await _mappingService.saveMapping(
              supplierDescription: desc,
              accountCode: '1200',
              supplierId: supplierId,
              inventoryItemId: invId,
              updateStock: true,
            );
            debugPrint(
                '[INVOICE] Auto-saved mapping for: $desc');
          }
        }
      } catch (e) {
        debugPrint(
            '[INVOICE] Auto-save mappings error (non-fatal): $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice approved — ledger updated'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approval failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Returns a similarity score 0.0–1.0 between two strings.
  /// Normalises to lowercase, strips punctuation, then computes
  /// the proportion of character bigrams shared between the two strings.
  double _stringSimilarity(String a, String b) {
    String norm(String s) => s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .trim();
    final na = norm(a);
    final nb = norm(b);
    if (na == nb) return 1.0;
    if (na.isEmpty || nb.isEmpty) return 0.0;
    Set<String> bigrams(String s) {
      final result = <String>{};
      for (int i = 0; i < s.length - 1; i++) {
        result.add(s.substring(i, i + 2));
      }
      return result;
    }
    final ba = bigrams(na);
    final bb = bigrams(nb);
    final intersection = ba.intersection(bb).length;
    return (2.0 * intersection) / (ba.length + bb.length);
  }

  /// Finds the best-matching supplier from [suppliers] for [name].
  /// Returns the supplier ID if similarity >= [threshold], otherwise null.
  String? _fuzzyMatchSupplier(
    String name,
    List<dynamic> suppliers, {
    double threshold = 0.80,
  }) {
    String? bestId;
    double bestScore = 0.0;
    for (final s in suppliers) {
      final score = _stringSimilarity(name, s.name as String);
      if (score > bestScore) {
        bestScore = score;
        bestId = s.id as String;
      }
    }
    if (bestScore >= threshold) {
      return bestId;
    }
    return null;
  }

  Future<void> _scanDriveFolder() async {
    final source = await _driveService.getImportSource();
    if (source == 'local') {
      await _scanLocalFolder();
      return;
    }

    final enabled = await _driveService.isEnabled();
    final configured = await _driveService.isConfigured();
    final aiConfigured = await _aiService.isConfigured();
    if (!enabled || !configured || !aiConfigured) return;
    if (_driveScanRunning) return;

    setState(() => _driveScanRunning = true);

    try {
      debugPrint('DRIVE SCAN: Starting scan...');
      final files = await _driveService.scanForNewInvoices();
      debugPrint('DRIVE SCAN: Found ${files.length} new files');
      if (files.isEmpty) {
        debugPrint('DRIVE SCAN: No new files found — '
            'either all processed or folder empty');
        setState(() => _driveScanRunning = false);
        return;
      }

      int created = 0;
      int failed = 0;

      for (final file in files) {
        try {
          debugPrint('DRIVE SCAN: Processing ${file.fileName}...');
          // Extract invoice data using Gemini (may return multiple invoices)
          final extractedList = await _aiService.extractInvoiceData(
            imageBytes: file.bytes,
            mimeType: file.mimeType,
          );

          // Filter out error entries
          final validInvoices = extractedList
              .where((e) => !e.containsKey('error'))
              .toList();

          if (validInvoices.isEmpty) {
            final err = extractedList.isNotEmpty
                ? extractedList.first['error']
                : 'no data';
            debugPrint('DRIVE SCAN: Extraction failed for '
                '${file.fileName}: $err');
            failed++;
            continue;
          }

          debugPrint('DRIVE SCAN: Extracted ${validInvoices.length} '
              'invoice(s) from ${file.fileName}');

          final userId = AuthService().getCurrentStaffId();
          // Load suppliers once per file (shared across all invoices in PDF)
          final suppliers =
              await _supplierRepo.getSuppliers(activeOnly: true);

          for (final extracted in validInvoices) {
            // Try to match supplier by name (exact → fuzzy → auto-create)
            String? supplierId;
            final supplierName =
                extracted['supplier_name']?.toString().trim();
            if (supplierName != null && supplierName.isNotEmpty) {
              // 1. Exact / contains match
              final exactMatched = suppliers
                  .where((s) => s.name
                      .toLowerCase()
                      .contains(supplierName.toLowerCase()))
                  .toList();

              if (exactMatched.isNotEmpty) {
                supplierId = exactMatched.first.id;
                debugPrint('DRIVE SCAN: Exact match for supplier '
                    '"$supplierName" → ${exactMatched.first.name}');
              } else {
                // 2. Fuzzy match (≥80% bigram similarity)
                final fuzzyId =
                    _fuzzyMatchSupplier(supplierName, suppliers);
                if (fuzzyId != null) {
                  supplierId = fuzzyId;
                  final fuzzyName =
                      suppliers.firstWhere((s) => s.id == fuzzyId).name;
                  debugPrint('DRIVE SCAN: Fuzzy match for supplier '
                      '"$supplierName" → "$fuzzyName"');
                } else {
                  // 3. No match — auto-create
                  try {
                    final newSupplier = await Supabase.instance.client
                        .from('suppliers')
                        .insert({
                          'name': supplierName,
                          'contact_name': null,
                          'phone': null,
                          'email': null,
                          'account_number': null,
                          'notes':
                              'Auto-created from supplier invoice scan',
                          'is_active': true,
                        })
                        .select('id')
                        .single();
                    supplierId = newSupplier['id']?.toString();
                    debugPrint('DRIVE SCAN: Auto-created supplier: '
                        '"$supplierName" ($supplierId)');
                  } catch (e) {
                    debugPrint('DRIVE SCAN: Failed to auto-create '
                        'supplier "$supplierName": $e');
                  }
                }
              }
            }

            await _repo.createFromOcrResult(
              ocrResult: extracted,
              createdBy: userId,
              supplierId: supplierId,
              silentIfDuplicate: true,
            );
            debugPrint('DRIVE SCAN: Created invoice — '
                'supplier: $supplierName, '
                'number: ${extracted['invoice_number']}');
          }

          // Mark file processed only after all invoices created
          await _driveService.markFileAsProcessed(file.fileId);
          created += validInvoices.length;
        } catch (e) {
          debugPrint('Drive invoice create error for '
              '${file.fileName}: $e');
          failed++;
        }
      }

      if (mounted) {
        setState(() => _driveScanRunning = false);
        if (created > 0) {
          _load();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '$created invoice${created == 1 ? '' : 's'} '
                  'imported from Google Drive'
                  '${failed > 0 ? ' ($failed failed)' : ''}'),
              backgroundColor: const Color(0xFF2E7D32),
              duration: const Duration(seconds: 5),
            ),
          );
        } else if (failed > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to import $failed invoice${failed == 1 ? '' : 's'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Drive scan error: $e');
      if (mounted) setState(() => _driveScanRunning = false);
    }
  }

  Future<void> _scanLocalFolder() async {
    final localService = LocalInvoiceService();
    final path = await localService.getFolderPath();

    if (path == null || path.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No local folder configured. '
              'Go to Settings → Drive & Import to set a folder.',
            ),
          ),
        );
      }
      return;
    }

    final aiConfigured = await _aiService.isConfigured();
    if (!aiConfigured) return;
    if (_driveScanRunning) return;

    setState(() => _driveScanRunning = true);

    try {
      debugPrint('LOCAL SCAN: Starting scan from $path');
      final files = await localService.scanForInvoices();
      debugPrint('LOCAL SCAN: Found ${files.length} new files');

      if (files.isEmpty) {
        debugPrint('LOCAL SCAN: No new files found');
        setState(() => _driveScanRunning = false);
        return;
      }

      int created = 0;
      int failed = 0;

      for (final file in files) {
        try {
          debugPrint('LOCAL SCAN: Processing ${file.filename}...');
          final extractedList = await _aiService.extractInvoiceData(
            imageBytes: file.bytes,
            mimeType: 'application/pdf',
          );

          final validInvoices = extractedList
              .where((e) => !e.containsKey('error'))
              .toList();

          if (validInvoices.isEmpty) {
            final err = extractedList.isNotEmpty
                ? extractedList.first['error']
                : 'no data';
            debugPrint('LOCAL SCAN: Extraction failed for '
                '${file.filename}: $err');
            failed++;
            continue;
          }

          debugPrint('LOCAL SCAN: Extracted ${validInvoices.length} '
              'invoice(s) from ${file.filename}');

          final userId = AuthService().getCurrentStaffId();
          final suppliers =
              await _supplierRepo.getSuppliers(activeOnly: true);

          for (final extracted in validInvoices) {
            String? supplierId;
            final supplierName =
                extracted['supplier_name']?.toString().trim();
            if (supplierName != null && supplierName.isNotEmpty) {
              final exactMatched = suppliers
                  .where((s) => s.name
                      .toLowerCase()
                      .contains(supplierName.toLowerCase()))
                  .toList();

              if (exactMatched.isNotEmpty) {
                supplierId = exactMatched.first.id;
                debugPrint('LOCAL SCAN: Exact match for supplier '
                    '"$supplierName" → ${exactMatched.first.name}');
              } else {
                final fuzzyId =
                    _fuzzyMatchSupplier(supplierName, suppliers);
                if (fuzzyId != null) {
                  supplierId = fuzzyId;
                  final fuzzyName =
                      suppliers.firstWhere((s) => s.id == fuzzyId).name;
                  debugPrint('LOCAL SCAN: Fuzzy match for supplier '
                      '"$supplierName" → "$fuzzyName"');
                } else {
                  try {
                    final newSupplier = await Supabase.instance.client
                        .from('suppliers')
                        .insert({
                          'name': supplierName,
                          'contact_name': null,
                          'phone': null,
                          'email': null,
                          'account_number': null,
                          'notes':
                              'Auto-created from supplier invoice scan',
                          'is_active': true,
                        })
                        .select('id')
                        .single();
                    supplierId = newSupplier['id']?.toString();
                    debugPrint('LOCAL SCAN: Auto-created supplier: '
                        '"$supplierName" ($supplierId)');
                  } catch (e) {
                    debugPrint('LOCAL SCAN: Failed to auto-create '
                        'supplier "$supplierName": $e');
                  }
                }
              }
            }

            await _repo.createFromOcrResult(
              ocrResult: extracted,
              createdBy: userId,
              supplierId: supplierId,
              silentIfDuplicate: true,
            );
            debugPrint('LOCAL SCAN: Created invoice — '
                'supplier: $supplierName, '
                'number: ${extracted['invoice_number']}');
          }

          await localService.markProcessed(file.filename, file.size);
          created += validInvoices.length;
        } catch (e) {
          debugPrint('Local invoice create error for '
              '${file.filename}: $e');
          failed++;
        }
      }

      if (mounted) {
        setState(() => _driveScanRunning = false);
        if (created > 0) {
          _load();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '$created invoice${created == 1 ? '' : 's'} '
                  'imported from local folder'
                  '${failed > 0 ? ' ($failed failed)' : ''}'),
              backgroundColor: const Color(0xFF2E7D32),
              duration: const Duration(seconds: 5),
            ),
          );
        } else if (failed > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to import $failed invoice${failed == 1 ? '' : 's'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Local scan error: $e');
      if (mounted) setState(() => _driveScanRunning = false);
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
              const Flexible(
              child: Text('Supplier Invoices',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
            ),
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
              IconButton(
                onPressed: _driveScanRunning ? null : () async {
                  await _driveService.clearProcessedIds();
                  // Small delay to ensure storage is cleared before scan starts
                  await Future.delayed(const Duration(milliseconds: 200));
                  await _scanDriveFolder();
                },
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Force re-scan Drive folder',
              ),
              if (AuthService().hasRole('owner'))
                IconButton(
                  onPressed: _driveScanRunning ? null : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await _driveService.clearProcessedFileIds();
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Ready to re-import invoices'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.restore_from_trash, size: 18),
                  tooltip: 'Reset processed invoices',
                ),
              IconButton(
                onPressed: _driveScanRunning ? null : _scanDriveFolder,
                icon: const Icon(Icons.cloud_sync_outlined, size: 20),
                tooltip: 'Scan Drive folder now',
              ),
              if (_driveScanRunning)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 6),
                      Text('Scanning Drive…',
                          style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          color: AppColors.surfaceBg,
          child: const Row(
            children: [
              Expanded(flex: 2, child: Text('SUPPLIER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5))),
              SizedBox(width: 16),
              SizedBox(width: 120, child: Text('INVOICE #', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5))),
              SizedBox(width: 16),
              SizedBox(width: 100, child: Text('DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5))),
              SizedBox(width: 16),
              SizedBox(width: 88, child: Text('TOTAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5))),
              SizedBox(width: 16),
              SizedBox(width: 88, child: Text('PAID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5))),
              SizedBox(width: 16),
              SizedBox(width: 88, child: Text('DUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5))),
              SizedBox(width: 16),
              SizedBox(width: 120, child: Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5))),
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
                                SizedBox(width: 88, child: Text('R ${inv.total.toStringAsFixed(2)}')),
                                const SizedBox(width: 16),
                                SizedBox(width: 88, child: Text('R ${inv.amountPaid.toStringAsFixed(2)}')),
                                const SizedBox(width: 16),
                                SizedBox(width: 88, child: Text('R ${inv.balanceDue.toStringAsFixed(2)}')),
                                const SizedBox(width: 16),
                                SizedBox(width: 120, child: Text(inv.status.displayLabel, style: TextStyle(color: inv.canApprove ? AppColors.warning : (inv.canReceive ? AppColors.info : AppColors.textSecondary)))),
                                if (inv.canApprove)
                                  TextButton(
                                    onPressed: () async {
                                      final m = inv.toJson();
                                      m['supplier_name'] = inv.supplierName;
                                      m['suppliers'] = inv.supplierName != null
                                          ? {'name': inv.supplierName}
                                          : null;
                                      
                                      // Check if items are mapped
                                      final mapped = await _mappingService.applyMappings(
                                        lineItems: inv.lineItems,
                                        supplierId: inv.supplierId,
                                      );
                                      final pending = mapped.where((i) => i.isPending).toList();
                                      
                                      if (pending.isEmpty) {
                                        _approveInvoice(m);
                                      } else {
                                        _openMappingScreen(m);
                                      }
                                    },
                                    child: const Text('Approve'),
                                  ),
                                if (inv.canReceive)
                                  TextButton(
                                    onPressed: () => _receiveGoods(inv),
                                    child: const Text('Receive goods'),
                                  ),
                                if ((inv.status == SupplierInvoiceStatus.approved ||
                                        inv.status ==
                                            SupplierInvoiceStatus.received) &&
                                    inv.balanceDue > 0)
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.green,
                                    ),
                                    onPressed: () {
                                      final m = inv.toJson();
                                      m['supplier_name'] = inv.supplierName;
                                      m['suppliers'] =
                                          inv.supplierName != null
                                              ? {'name': inv.supplierName}
                                              : null;
                                      _showPaymentDialog(m);
                                    },
                                    child: const Text('Pay'),
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

class _OcrPreviewDialog extends StatefulWidget {
  final List<Map<String, dynamic>> invoices;
  final Future<void> Function(Map<String, dynamic>) onApproveOne;

  const _OcrPreviewDialog({
    required this.invoices,
    required this.onApproveOne,
  });

  @override
  State<_OcrPreviewDialog> createState() => _OcrPreviewDialogState();
}

class _OcrPreviewDialogState extends State<_OcrPreviewDialog> {
  final Set<int> _approved = {};
  bool _isApproving = false;

  @override
  Widget build(BuildContext context) {
    final count = widget.invoices.length;
    return AlertDialog(
      title: Text(
        count == 1
            ? '1 invoice detected'
            : '$count invoices detected',
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(count, (i) {
              final inv = widget.invoices[i];
              final warnings =
                  (inv['warnings'] as List<dynamic>? ?? []);
              final hasWarnings = warnings.isNotEmpty;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: hasWarnings
                        ? Colors.orange
                        : Colors.grey.shade300,
                    width: hasWarnings ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(
                        inv['supplier_name']?.toString() ??
                            'Unknown supplier',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${inv['invoice_number'] ?? 'No invoice number'}'
                        ' · ${inv['invoice_date'] ?? 'No date'}'
                        ' · R${(inv['grand_total'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                      ),
                      trailing: _approved.contains(i)
                          ? const Icon(Icons.check_circle,
                              color: Colors.green)
                          : TextButton(
                              onPressed: _isApproving
                                  ? null
                                  : () async {
                                      setState(
                                          () => _isApproving = true);
                                      await widget.onApproveOne(
                                          widget.invoices[i]);
                                      setState(() {
                                        _approved.add(i);
                                        _isApproving = false;
                                      });
                                    },
                              child: const Text('Approve'),
                            ),
                    ),
                    if (hasWarnings) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.warning_amber,
                                  color: Colors.orange, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '${warnings.length} warning${warnings.length == 1 ? '' : 's'} — please verify',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ]),
                            const SizedBox(height: 8),
                            ...warnings.map((w) {
                              final wm = w as Map<String, dynamic>;
                              return Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 4),
                                child: Text(
                                  '⚠️ ${wm['message']}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (_approved.length < count)
          FilledButton(
            onPressed: _isApproving
                ? null
                : () async {
                    final navigator = Navigator.of(context);
                    setState(() => _isApproving = true);
                    for (var i = 0;
                        i < widget.invoices.length;
                        i++) {
                      if (!_approved.contains(i)) {
                        await widget.onApproveOne(
                            widget.invoices[i]);
                        if (!mounted) return;
                        setState(() => _approved.add(i));
                      }
                    }
                    if (!mounted) return;
                    setState(() => _isApproving = false);
                    navigator.pop();
                  },
            child: Text(
              _isApproving
                  ? 'Approving...'
                  : 'Approve All ($count)',
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 10: CSV SALES IMPORT
// ══════════════════════════════════════════════════════════════════
class _CsvSalesImportTab extends StatefulWidget {
  const _CsvSalesImportTab();

  @override
  State<_CsvSalesImportTab> createState() => _CsvSalesImportTabState();
}

class _CsvSalesImportTabState extends State<_CsvSalesImportTab> {
  final _service = CsvSalesImportService();
  bool _importing = false;
  String? _selectedFile;
  List<CsvSalesLine>? _lines;
  List<CsvSalesLine>? _skippedLines;
  DateTime? _importDate;
  int _importedCount = 0;
  DateTime? _alreadyImportedDate;
  String? _lastImportedFile;

  @override
  void initState() {
    super.initState();
    _loadLastImportedFile();
  }

  Future<void> _loadLastImportedFile() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString('csv_last_imported_file');
    if (last != null && mounted) {
      setState(() => _lastImportedFile = last);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final file = File(path);
      final content = await file.readAsString();
      final filename = result.files.single.name;

      final parsed = _service.parseCsv(content);
      final matched = await _service.matchPlus(parsed);

      final date = _service.parseDateFromFilename(filename);
      final refId = filename.contains('.')
          ? filename.substring(0, filename.lastIndexOf('.'))
          : filename;
      final existingDate = await _service.checkAlreadyImported(refId);

      if (mounted) {
        setState(() {
          _selectedFile = filename;
          _lines = matched;
          _importDate = date;
          _alreadyImportedDate = existingDate;
          _skippedLines = matched.where((l) => !l.matched).toList();
        });
      }
    }
  }

  Future<void> _runImport() async {
    if (_lines == null || _importDate == null || _selectedFile == null) return;

    setState(() => _importing = true);
    try {
      final result = await _service.importLines(
        lines: _lines!,
        date: _importDate!,
        filename: _selectedFile!,
      );

      if (mounted) {
        setState(() {
          _importedCount = result.imported;
          _skippedLines = result.skippedLines;
          _importing = false;
          _lastImportedFile = _selectedFile;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('csv_last_imported_file', _selectedFile!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Imported ${result.imported} movements, '
                '${result.skipped} skipped',
              ),
              backgroundColor: const Color(0xFF2E7D32),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _importing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('CSV Sales Import',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Import sales data from POS CSV files with backdating support.',
            style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 24),
          if (_selectedFile == null) ...[
            ElevatedButton.icon(
              onPressed: _importing ? null : _pickFile,
              icon: const Icon(Icons.file_upload),
              label: const Text('Select CSV file'),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_selectedFile!)),
                  TextButton(
                    onPressed: _importing ? null : _pickFile,
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_alreadyImportedDate != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This file was already imported on ${_alreadyImportedDate!.day}/${_alreadyImportedDate!.month}/${_alreadyImportedDate!.year}. Select a different file.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_importDate != null) ...[
              Text('Import date: ${_importDate!.day}/${_importDate!.month}/${_importDate!.year}'),
              const SizedBox(height: 8),
            ],
            if (_lines != null) ...[
              Text('Total lines: ${_lines!.length}'),
              const SizedBox(height: 8),
              Text('Matched: ${_lines!.where((l) => l.matched).length}'),
              const SizedBox(height: 8),
              Text('Unmatched: ${_lines!.where((l) => !l.matched).length}'),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                FilledButton.icon(
                  onPressed: (_importing || _alreadyImportedDate != null)
                      ? null
                      : _runImport,
                  icon: _importing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white))
                      : const Icon(Icons.check),
                  label: Text(_importing ? 'Importing...' : 'Import'),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedFile = null;
                      _lines = null;
                      _importDate = null;
                      _skippedLines = null;
                      _importedCount = 0;
                      _alreadyImportedDate = null;
                      // Note: _lastImportedFile is NOT cleared - it persists
                    });
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_skippedLines != null && _skippedLines!.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 16),
              const Text('Unmatched PLU codes:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _skippedLines?.length ?? 0,
                  itemBuilder: (context, index) {
                    final line = _skippedLines![index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.warning_amber,
                        color: Colors.orange,
                        size: 18,
                      ),
                      title: Text(
                        '${line.pluCode} - ${line.pluName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text('Qty: ${line.qty.toStringAsFixed(3)}'),
                    );
                  },
                ),
              ),
            ],
            if (_lastImportedFile != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Last import: $_lastImportedFile')),
                  ],
                ),
              ),
            ],
            if (_importedCount > 0) ...[
              const Divider(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('Successfully imported $_importedCount movements'),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
