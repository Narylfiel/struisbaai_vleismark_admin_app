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
    // Map Gemini response fields to invoice fields
    final total = (ocrResult['total'] as num?)?.toDouble() ?? 0;
    final subtotal = (ocrResult['subtotal'] as num?)?.toDouble() ?? total;
    final taxAmount = (ocrResult['tax_amount'] as num?)?.toDouble() ?? 0;
    final taxRate = (ocrResult['tax_rate'] as num?)?.toDouble() ?? 0;

    DateTime invoiceDate = DateTime.now();
    if (ocrResult['invoice_date'] != null) {
      invoiceDate =
          DateTime.tryParse(ocrResult['invoice_date'] as String) ??
              invoiceDate;
    }

    DateTime? dueDate;
    if (ocrResult['due_date'] != null) {
      dueDate = DateTime.tryParse(ocrResult['due_date'] as String);
    }
    dueDate ??= invoiceDate.add(const Duration(days: 30));

    // Map line_items from Gemini response
    final rawItems = ocrResult['line_items'] as List<dynamic>?;
    final lineItems = <Map<String, dynamic>>[];
    if (rawItems != null) {
      for (final item in rawItems) {
        final m = item is Map<String, dynamic>
            ? item
            : Map<String, dynamic>.from(item as Map);
        lineItems.add({
          'description': m['description'] ?? m['name'] ?? '',
          'supplier_code': m['supplier_code']?.toString(),
          'quantity': (m['quantity'] as num?)?.toDouble() ?? 1,
          'unit': m['unit']?.toString(),
          'unit_price': (m['unit_price'] as num?)?.toDouble() ?? 0,
          'line_total': (m['line_total'] as num?)?.toDouble() ??
              ((m['quantity'] as num?)?.toDouble() ?? 1) *
                  ((m['unit_price'] as num?)?.toDouble() ?? 0),
        });
      }
    }

    // Use supplier name from OCR as notes if no supplier matched
    final extractedSupplierName =
        ocrResult['supplier_name']?.toString();
    final extractedInvoiceNumber =
        ocrResult['invoice_number']?.toString();

    // Use extracted invoice number if available
    final invoiceNumber = (extractedInvoiceNumber != null &&
            extractedInvoiceNumber.isNotEmpty)
        ? extractedInvoiceNumber
        : await nextInvoiceNumber();

    final invoice = SupplierInvoice(
      id: '',
      invoiceNumber: invoiceNumber,
      supplierId: supplierId,
      invoiceDate: invoiceDate,
      dueDate: dueDate,
      lineItems: lineItems,
      subtotal: subtotal,
      taxRate: taxRate,
      taxAmount: taxAmount,
      total: total,
      status: SupplierInvoiceStatus.pendingReview,
      notes: extractedSupplierName != null && supplierId == null
          ? 'Supplier from invoice: $extractedSupplierName'
          : null,
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

  /// Auto-match supplier invoice line items to inventory products.
  /// Looks up product_suppliers by supplier_id + supplier_product_code.
  /// Returns updated line items with inventory_item_id and inventory_item_name
  /// filled in where a match is found.
  Future<List<Map<String, dynamic>>> autoMatchLineItems({
    required String supplierId,
    required List<Map<String, dynamic>> lineItems,
  }) async {
    if (supplierId.isEmpty || lineItems.isEmpty) return lineItems;

    // Load all product_suppliers rows for this supplier
    final rows = await _client
        .from('product_suppliers')
        .select('supplier_product_code, supplier_product_name, inventory_item_id, inventory_items(id, name)')
        .eq('supplier_id', supplierId);

    // Build lookup map: supplier_product_code (lowercase) → {item_id, item_name}
    final lookup = <String, Map<String, String>>{};
    for (final row in rows as List) {
      final code = (row['supplier_product_code'] as String? ?? '').toLowerCase().trim();
      final itemId = row['inventory_item_id']?.toString() ?? '';
      final itemName = (row['inventory_items'] as Map<String, dynamic>?)?['name']?.toString()
          ?? row['supplier_product_name']?.toString()
          ?? '';
      if (code.isNotEmpty && itemId.isNotEmpty) {
        lookup[code] = {'item_id': itemId, 'item_name': itemName};
      }
    }

    if (lookup.isEmpty) return lineItems;

    // Match each line item
    final updated = <Map<String, dynamic>>[];
    for (final line in lineItems) {
      final copy = Map<String, dynamic>.from(line);
      // Skip if already linked
      if (copy['inventory_item_id']?.toString().isNotEmpty == true) {
        updated.add(copy);
        continue;
      }
      // Try to match by description against supplier_product_code
      final desc = (copy['description'] as String? ?? '').toLowerCase().trim();
      if (desc.isNotEmpty && lookup.containsKey(desc)) {
        copy['inventory_item_id'] = lookup[desc]!['item_id'];
        copy['inventory_item_name'] = lookup[desc]!['item_name'];
        copy['auto_matched'] = true;
      }
      updated.add(copy);
    }
    return updated;
  }

  /// Verify invoice calculations. Returns list of error strings (empty = clean).
  /// Checks:
  /// 1. Each line total = quantity * unit_price (within 0.02 rounding tolerance)
  /// 2. Sum of line totals = subtotal (within 0.05 tolerance)
  /// 3. subtotal + tax_amount = total (within 0.05 tolerance)
  List<String> verifyCalculations({
    required List<Map<String, dynamic>> lineItems,
    required double subtotal,
    required double taxAmount,
    required double total,
  }) {
    final errors = <String>[];
    double lineSum = 0;

    for (int i = 0; i < lineItems.length; i++) {
      final line = lineItems[i];
      final qty = (line['quantity'] as num?)?.toDouble() ?? 0;
      final price = (line['unit_price'] as num?)?.toDouble() ?? 0;
      final lineTotal = (line['line_total'] as num?)?.toDouble();
      final expected = qty * price;

      if (lineTotal != null && (lineTotal - expected).abs() > 0.02) {
        final desc = line['description']?.toString() ?? 'Line ${i + 1}';
        errors.add(
          '$desc: line total R${lineTotal.toStringAsFixed(2)} ≠ '
          '${qty.toStringAsFixed(3)} × R${price.toStringAsFixed(2)} '
          '= R${expected.toStringAsFixed(2)}',
        );
      }
      lineSum += lineTotal ?? expected;
    }

    if ((lineSum - subtotal).abs() > 0.05) {
      errors.add(
        'Line items sum R${lineSum.toStringAsFixed(2)} ≠ '
        'subtotal R${subtotal.toStringAsFixed(2)}',
      );
    }

    if ((subtotal + taxAmount - total).abs() > 0.05) {
      errors.add(
        'Subtotal R${subtotal.toStringAsFixed(2)} + '
        'tax R${taxAmount.toStringAsFixed(2)} = '
        'R${(subtotal + taxAmount).toStringAsFixed(2)} ≠ '
        'total R${total.toStringAsFixed(2)}',
      );
    }

    return errors;
  }
}
