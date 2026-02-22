import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import '../../../core/models/ledger_entry.dart';
import '../models/invoice.dart';
import '../models/invoice_line_item.dart';
import 'ledger_repository.dart';

/// Blueprint §9.1: Supplier invoices — create (draft/pending_review) → approve → post to ledger (AP).
class InvoiceRepository {
  final SupabaseClient _client;
  final LedgerRepository _ledgerRepo;

  static const String _coaPurchases = '5000';
  static const String _coaPurchasesName = 'Meat Purchases';
  static const String _coaAP = '2000';
  static const String _coaAPName = 'Accounts Payable (Suppliers)';

  InvoiceRepository({
    SupabaseClient? client,
    LedgerRepository? ledgerRepo,
  })  : _client = client ?? SupabaseService.client,
        _ledgerRepo = ledgerRepo ?? LedgerRepository(client: client);

  /// List invoices; optionally include supplier name via join (if supplier_id exists).
  Future<List<Invoice>> getInvoices({String? status}) async {
    var q = _client.from('invoices').select();
    if (status != null && status.isNotEmpty) {
      q = q.eq('status', status);
    }
    final list = await q.order('created_at', ascending: false);
    final invoices = (list as List)
        .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
        .toList();
    await _attachSupplierNames(invoices);
    return invoices;
  }

  Future<Invoice?> getInvoice(String id) async {
    final row = await _client
        .from('invoices')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    final invoice = Invoice.fromJson(row as Map<String, dynamic>);
    await _attachSupplierNames([invoice]);
    return invoice;
  }

  Future<void> _attachSupplierNames(List<Invoice> invoices) async {
    final supplierIds =
        invoices.map((e) => e.supplierId).whereType<String>().toSet().toList();
    if (supplierIds.isEmpty) return;
    try {
      final suppliers = await _client
          .from('suppliers')
          .select('id, name')
          .inFilter('id', supplierIds);
      final nameMap = {for (var s in suppliers as List) s['id'] as String: s['name'] as String?};
      for (var i = 0; i < invoices.length; i++) {
        final inv = invoices[i];
        if (inv.supplierId != null) {
          final name = nameMap[inv.supplierId];
          if (name != null) invoices[i] = inv.copyWith(supplierName: name);
        }
      }
    } catch (_) {}
  }

  Future<List<InvoiceLineItem>> getLineItems(String invoiceId) async {
    final list = await _client
        .from('invoice_line_items')
        .select()
        .eq('invoice_id', invoiceId)
        .order('sort_order')
        .order('created_at');
    return (list as List)
        .map((e) => InvoiceLineItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Generate next invoice number (e.g. INV-YYYYMMDD-001).
  Future<String> nextInvoiceNumber() async {
    final prefix =
        'INV-${DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '')}-';
    final list = await _client
        .from('invoices')
        .select('invoice_number')
        .like('invoice_number', '$prefix%')
        .order('invoice_number', ascending: false)
        .limit(1);
    if (list.isEmpty) return '${prefix}001';
    final last = list.first['invoice_number'] as String? ?? '';
    final numPart = last.length > prefix.length
        ? int.tryParse(last.substring(prefix.length)) ?? 0
        : 0;
    return '$prefix${(numPart + 1).toString().padLeft(3, '0')}';
  }

  /// Create invoice (draft) with line items.
  Future<Invoice> create({
    required String invoiceNumber,
    String? supplierId,
    String? accountId,
    required DateTime invoiceDate,
    required DateTime dueDate,
    required double subtotal,
    required double taxAmount,
    required double totalAmount,
    String? notes,
    required String createdBy,
    List<InvoiceLineItem>? lineItems,
  }) async {
    final row = await _client
        .from('invoices')
        .insert({
          'invoice_number': invoiceNumber,
          'supplier_id': supplierId,
          'account_id': accountId,
          'invoice_date': invoiceDate.toIso8601String().substring(0, 10),
          'due_date': dueDate.toIso8601String().substring(0, 10),
          'subtotal': subtotal,
          'tax_amount': taxAmount,
          'total_amount': totalAmount,
          'status': InvoiceStatus.draft.dbValue,
          'notes': notes,
          'created_by': createdBy,
        })
        .select()
        .single();
    final invoice = Invoice.fromJson(row as Map<String, dynamic>);
    if (lineItems != null && lineItems.isNotEmpty) {
      for (var i = 0; i < lineItems.length; i++) {
        await _client.from('invoice_line_items').insert({
          'invoice_id': invoice.id,
          'description': lineItems[i].description,
          'quantity': lineItems[i].quantity,
          'unit_price': lineItems[i].unitPrice,
          'sort_order': i,
        });
      }
    }
    return invoice;
  }

  static String? _ocrNotes(dynamic rawText) {
    if (rawText == null) return null;
    final s = rawText.toString();
    if (s.isEmpty) return null;
    return 'OCR: ${s.length > 500 ? s.substring(0, 500) : s}';
  }

  /// Create invoice from OCR pipeline result (status pending_review). Map OCR result to createFromOcr.
  Future<Invoice> createFromOcrResult({
    required Map<String, dynamic> ocrResult,
    required String createdBy,
    String? supplierId,
  }) async {
    final totalAmount = (ocrResult['total_amount'] as num?)?.toDouble() ?? 0;
    DateTime invoiceDate = DateTime.now();
    if (ocrResult['date'] != null) {
      invoiceDate = DateTime.tryParse(ocrResult['date'] as String) ?? invoiceDate;
    }
    final dueDate = invoiceDate.add(const Duration(days: 30));
    final rawItems = ocrResult['items'] as List<dynamic>?;
    final lineItems = <Map<String, dynamic>>[];
    if (rawItems != null) {
      for (final item in rawItems) {
        final m = item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item as Map);
        lineItems.add({
        'description': m['name'] ?? m['description'] ?? '',
        'quantity': (m['quantity'] as num?)?.toDouble() ?? 1,
        'unit_price': (m['unit_price'] as num?)?.toDouble() ?? 0,
        });
      }
    }
    final invoiceNumber = await nextInvoiceNumber();
    return createFromOcr(
      invoiceNumber: invoiceNumber,
      supplierId: supplierId,
      invoiceDate: invoiceDate,
      dueDate: dueDate,
      subtotal: totalAmount,
      taxAmount: 0,
      totalAmount: totalAmount,
      notes: _ocrNotes(ocrResult['raw_text']),
      createdBy: createdBy,
      lineItems: lineItems.isEmpty ? null : lineItems,
    );
  }

  /// Create invoice from OCR result (status pending_review) — Blueprint §9.1 OCR pipeline structure.
  Future<Invoice> createFromOcr({
    required String invoiceNumber,
    String? supplierId,
    required DateTime invoiceDate,
    required DateTime dueDate,
    required double subtotal,
    required double taxAmount,
    required double totalAmount,
    String? notes,
    required String createdBy,
    List<Map<String, dynamic>>? lineItems,
  }) async {
    final row = await _client
        .from('invoices')
        .insert({
          'invoice_number': invoiceNumber,
          'supplier_id': supplierId,
          'invoice_date': invoiceDate.toIso8601String().substring(0, 10),
          'due_date': dueDate.toIso8601String().substring(0, 10),
          'subtotal': subtotal,
          'tax_amount': taxAmount,
          'total_amount': totalAmount,
          'status': InvoiceStatus.pendingReview.dbValue,
          'notes': notes,
          'created_by': createdBy,
        })
        .select()
        .single();
    final invoice = Invoice.fromJson(row as Map<String, dynamic>);
    if (lineItems != null && lineItems.isNotEmpty) {
      for (var i = 0; i < lineItems.length; i++) {
        final li = lineItems[i];
        await _client.from('invoice_line_items').insert({
          'invoice_id': invoice.id,
          'description': li['description'] as String? ?? '',
          'quantity': (li['quantity'] as num?)?.toDouble() ?? 1,
          'unit_price': (li['unit_price'] as num?)?.toDouble() ?? 0,
          'sort_order': i,
        });
      }
    }
    return invoice;
  }

  /// Update invoice (header only; line items updated separately or recreate).
  Future<Invoice> update(Invoice invoice) async {
    final row = await _client
        .from('invoices')
        .update(invoice.toJson())
        .eq('id', invoice.id)
        .select()
        .single();
    return Invoice.fromJson(row as Map<String, dynamic>);
  }

  /// Set status (draft → approved, etc.).
  Future<void> setStatus(String invoiceId, InvoiceStatus status) async {
    await _client
        .from('invoices')
        .update({'status': status.dbValue})
        .eq('id', invoiceId);
  }

  /// Approve invoice and post to ledger (Blueprint §9.3: Debit 5000 COGS, Credit 2000 AP).
  Future<void> approve(String invoiceId, String approvedBy) async {
    final invoice = await getInvoice(invoiceId);
    if (invoice == null) throw ArgumentError('Invoice not found');
    if (!invoice.canApprove) {
      throw StateError('Invoice cannot be approved (status: ${invoice.status.dbValue})');
    }
    final amount = invoice.totalAmount;
    if (amount <= 0) throw StateError('Invoice total must be positive to post');

    await _ledgerRepo.createDoubleEntry(
      date: invoice.invoiceDate,
      debitAccountCode: _coaPurchases,
      debitAccountName: _coaPurchasesName,
      creditAccountCode: _coaAP,
      creditAccountName: _coaAPName,
      amount: amount,
      description: 'Supplier invoice ${invoice.invoiceNumber}',
      referenceType: 'invoice',
      referenceId: invoiceId,
      source: 'invoice',
      metadata: {'invoice_number': invoice.invoiceNumber, 'supplier_id': invoice.supplierId},
      recordedBy: approvedBy,
    );
    await setStatus(invoiceId, InvoiceStatus.approved);
  }

  /// Delete line items for an invoice (e.g. before replacing).
  Future<void> deleteLineItems(String invoiceId) async {
    await _client.from('invoice_line_items').delete().eq('invoice_id', invoiceId);
  }

  /// Add or replace line items.
  Future<void> saveLineItems(String invoiceId, List<InvoiceLineItem> items) async {
    await deleteLineItems(invoiceId);
    for (var i = 0; i < items.length; i++) {
      await _client.from('invoice_line_items').insert({
        'invoice_id': invoiceId,
        'description': items[i].description,
        'quantity': items[i].quantity,
        'unit_price': items[i].unitPrice,
        'sort_order': i,
      });
    }
  }
}
