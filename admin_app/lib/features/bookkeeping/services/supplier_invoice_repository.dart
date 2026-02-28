import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/audit_service.dart';
import 'package:admin_app/core/models/stock_movement.dart';
import 'package:admin_app/features/inventory/services/inventory_repository.dart';
import '../models/supplier_invoice.dart';
import 'ledger_repository.dart';

/// Result of receive(): how many line items had stock movements created.
class ReceiveResult {
  final int itemsReceived;
  ReceiveResult({required this.itemsReceived});
}

/// Supplier invoices — table supplier_invoices only.
class SupplierInvoiceRepository {
  final SupabaseClient _client;
  final LedgerRepository _ledgerRepo;
  final InventoryRepository _inventoryRepo;

  static const String _coaPurchases = '5000';
  static const String _coaPurchasesName = 'Meat Purchases';
  static const String _coaAP = '2000';
  static const String _coaAPName = 'Accounts Payable (Suppliers)';

  SupplierInvoiceRepository({
    SupabaseClient? client,
    LedgerRepository? ledgerRepo,
    InventoryRepository? inventoryRepo,
  })  : _client = client ?? SupabaseService.client,
        _ledgerRepo = ledgerRepo ?? LedgerRepository(client: client),
        _inventoryRepo = inventoryRepo ?? InventoryRepository(client: client);

  Future<List<SupplierInvoice>> getAll({String? status}) async {
    var q = _client.from('supplier_invoices').select('*, suppliers(id, name)');
    if (status != null && status.isNotEmpty) {
      q = q.eq('status', status);
    }
    final list = await q.order('created_at', ascending: false);
    final invoices = (list as List)
        .map((e) => SupplierInvoice.fromJson(e as Map<String, dynamic>))
        .toList();
    return invoices;
  }

  Future<SupplierInvoice?> getById(String id) async {
    final row = await _client
        .from('supplier_invoices')
        .select('*, suppliers(id, name)')
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return SupplierInvoice.fromJson(row as Map<String, dynamic>);
  }

  Future<String> nextInvoiceNumber() async {
    final prefix =
        'SINV-${DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '')}-';
    final list = await _client
        .from('supplier_invoices')
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

  Future<SupplierInvoice> create(SupplierInvoice invoice) async {
    final data = Map<String, dynamic>.from(invoice.toJson())
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at')
      ..remove('supplier_name');
    final row = await _client
        .from('supplier_invoices')
        .insert(data)
        .select()
        .single();
    
    final created = SupplierInvoice.fromJson(row as Map<String, dynamic>);
    
    // Audit log - invoice creation
    await AuditService.log(
      action: 'CREATE',
      module: 'Bookkeeping',
      description: 'Supplier invoice created: ${created.invoiceNumber} - ${invoice.supplierName ?? "Unknown"} R${created.total.toStringAsFixed(2)}',
      entityType: 'SupplierInvoice',
      entityId: created.id,
      newValues: data,
    );
    
    return created;
  }

  /// Create from raw payload (for direct column control)
  Future<Map<String, dynamic>> createFromRawPayload(Map<String, dynamic> payload) async {
    final row = await _client
        .from('supplier_invoices')
        .insert(payload)
        .select()
        .single();
    return row as Map<String, dynamic>;
  }

  Future<SupplierInvoice> update(SupplierInvoice invoice) async {
    final data = Map<String, dynamic>.from(invoice.toJson())
      ..remove('supplier_name');
    final row = await _client
        .from('supplier_invoices')
        .update(data)
        .eq('id', invoice.id)
        .select()
        .single();
    
    // Audit log - invoice update
    await AuditService.log(
      action: 'UPDATE',
      module: 'Bookkeeping',
      description: 'Supplier invoice updated: ${invoice.invoiceNumber}',
      entityType: 'SupplierInvoice',
      entityId: invoice.id,
      newValues: data,
    );
    
    return SupplierInvoice.fromJson(row as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _client.from('supplier_invoices').delete().eq('id', id);
  }

  /// Soft delete: set status = 'cancelled'. Only call when status is 'draft'.
  Future<void> cancelInvoice(String id) async {
    await _client
        .from('supplier_invoices')
        .update({'status': SupplierInvoiceStatus.cancelled.dbValue})
        .eq('id', id);
  }

  Future<void> setStatus(String id, SupplierInvoiceStatus status) async {
    await _client
        .from('supplier_invoices')
        .update({'status': status.dbValue})
        .eq('id', id);
  }

  /// Create supplier invoice from OCR result (status pending_review).
  Future<SupplierInvoice> createFromOcrResult({
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
    String? notes;
    final rawText = ocrResult['raw_text'];
    if (rawText != null) {
      final s = rawText.toString();
      if (s.isNotEmpty) notes = 'OCR: ${s.length > 500 ? s.substring(0, 500) : s}';
    }
    final invoiceNumber = await nextInvoiceNumber();
    final invoice = SupplierInvoice(
      id: '',
      invoiceNumber: invoiceNumber,
      supplierId: supplierId,
      invoiceDate: invoiceDate,
      dueDate: dueDate,
      lineItems: lineItems,
      subtotal: totalAmount,
      taxAmount: 0,
      total: totalAmount,
      status: SupplierInvoiceStatus.pendingReview,
      notes: notes,
      createdBy: createdBy,
    );
    return create(invoice);
  }

  /// Approve and post to ledger (Debit 5000, Credit 2000 AP).
  Future<void> approve(String invoiceId, String approvedBy) async {
    final invoice = await getById(invoiceId);
    if (invoice == null) throw ArgumentError('Invoice not found');
    if (!invoice.canApprove) {
      throw StateError('Invoice cannot be approved (status: ${invoice.status.dbValue})');
    }
    if (invoice.total <= 0) throw StateError('Invoice total must be positive to post');
    await _ledgerRepo.createDoubleEntry(
      date: invoice.invoiceDate,
      debitAccountCode: _coaPurchases,
      debitAccountName: _coaPurchasesName,
      creditAccountCode: _coaAP,
      creditAccountName: _coaAPName,
      amount: invoice.total,
      description: 'Supplier invoice ${invoice.invoiceNumber}',
      referenceType: 'supplier_invoice',
      referenceId: invoiceId,
      source: 'supplier_invoice',
      metadata: {'invoice_number': invoice.invoiceNumber, 'supplier_id': invoice.supplierId},
      recordedBy: approvedBy,
    );
    await setStatus(invoiceId, SupplierInvoiceStatus.approved);
    
    // Audit log - invoice approval
    await AuditService.log(
      action: 'APPROVE',
      module: 'Bookkeeping',
      description: 'Supplier invoice approved and posted to ledger: ${invoice.invoiceNumber} - ${invoice.supplierName ?? "Unknown"} R${invoice.total.toStringAsFixed(2)}',
      entityType: 'SupplierInvoice',
      entityId: invoiceId,
    );
  }

  /// Mark invoice as received: create stock movements for lines with inventory_item_id, then set status to received.
  /// Only allowed when status is approved. Once received cannot receive again.
  /// Returns number of line items that had stock movements (0 if none linked).
  Future<ReceiveResult> receive(String invoiceId, String receivedBy) async {
    final invoice = await getById(invoiceId);
    if (invoice == null) throw ArgumentError('Invoice not found');
    if (!invoice.canReceive) {
      throw StateError('Invoice cannot be received (status: ${invoice.status.dbValue}). Only approved invoices can be marked received.');
    }
    int itemsReceived = 0;
    for (final line in invoice.lineItems) {
      final itemId = line['inventory_item_id']?.toString();
      if (itemId == null || itemId.isEmpty) continue;
      final quantity = (line['quantity'] as num?)?.toDouble() ?? 0;
      if (quantity <= 0) continue;
      final unitPrice = (line['unit_price'] as num?)?.toDouble();
      await _inventoryRepo.recordMovement(
        itemId: itemId,
        movementType: MovementType.in_,
        quantity: quantity,
        unitCost: unitPrice,
        referenceType: 'supplier_invoice',
        referenceId: invoiceId,
        performedBy: receivedBy,
        notes: 'Supplier invoice ${invoice.invoiceNumber}',
        metadata: {'invoice_number': invoice.invoiceNumber},
      );
      itemsReceived++;
    }
    final now = DateTime.now().toUtc().toIso8601String();
    await _client
        .from('supplier_invoices')
        .update({
          'status': SupplierInvoiceStatus.received.dbValue,
          'received_at': now,
          'received_by': receivedBy,
          'updated_at': now,
        })
        .eq('id', invoiceId);
    await AuditService.log(
      action: 'RECEIVE',
      module: 'Bookkeeping',
      description: 'Supplier invoice received: ${invoice.invoiceNumber}${itemsReceived > 0 ? ' — $itemsReceived product(s) added to stock' : ' — no products linked'}',
      entityType: 'SupplierInvoice',
      entityId: invoiceId,
    );
    return ReceiveResult(itemsReceived: itemsReceived);
  }
}
