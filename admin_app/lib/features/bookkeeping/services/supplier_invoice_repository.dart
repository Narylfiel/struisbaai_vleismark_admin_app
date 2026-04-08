import 'dart:math' show Random;

import 'package:flutter/foundation.dart';
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

/// AP totals for one supplier (`getSupplierBalance`).
class SupplierBalanceSummary {
  final double totalOutstanding;
  final double totalInvoiced;
  final double totalPaid;

  const SupplierBalanceSummary({
    required this.totalOutstanding,
    required this.totalInvoiced,
    required this.totalPaid,
  });
}

double _money(double x) => (x * 100).roundToDouble() / 100;

/// Enforces 0 <= amount_paid <= total and balance_due = total - amount_paid (>= 0).
Map<String, double> _amountPaidAndBalanceDue({
  required double total,
  required double amountPaid,
}) {
  var paid = amountPaid;
  if (paid < 0) paid = 0;
  if (paid > total) paid = total;
  var due = total - paid;
  if (due < 0) due = 0;
  return {
    'amount_paid': _money(paid),
    'balance_due': _money(due),
  };
}

/// Aligns with [InventoryRepository] stock columns: `current_stock` OR fresh+frozen total.
double _stockBasisForWac(Map<String, dynamic> item) {
  final hasCurrentStock = item.containsKey('current_stock');
  final hasFreshFrozen = item.containsKey('stock_on_hand_fresh') &&
      item.containsKey('stock_on_hand_frozen');
  if (hasCurrentStock) {
    return (item['current_stock'] as num?)?.toDouble() ?? 0;
  }
  if (hasFreshFrozen) {
    final fresh = (item['stock_on_hand_fresh'] as num?)?.toDouble() ?? 0;
    final frozen = (item['stock_on_hand_frozen'] as num?)?.toDouble() ?? 0;
    return fresh + frozen;
  }
  return 0;
}

/// Weighted average cost after a receipt (2 decimal places).
double _weightedAverageCost({
  required double stockBefore,
  required double currentAvgCost,
  required double incomingQty,
  required double incomingUnitCost,
}) {
  final newStock = stockBefore + incomingQty;
  if (newStock <= 0) {
    return _money(incomingUnitCost);
  }
  final raw =
      ((stockBefore * currentAvgCost) + (incomingQty * incomingUnitCost)) /
          newStock;
  return _money(raw);
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

  /// Statuses included in supplier balance aggregation (excludes draft/cancelled).
  static const List<String> _supplierBalanceStatuses = [
    'pending_review',
    'approved',
    'paid',
    'overdue',
    'received',
  ];

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

  /// Returns true if another row already uses this [invoiceNumber].
  Future<bool> invoiceNumberExists(
    String invoiceNumber, {
    String? excludeInvoiceId,
  }) async {
    final trimmed = invoiceNumber.trim();
    if (trimmed.isEmpty) return false;
    final row = await _client
        .from('supplier_invoices')
        .select('id')
        .eq('invoice_number', trimmed)
        .maybeSingle();
    if (row == null) return false;
    if (excludeInvoiceId != null &&
        row['id']?.toString() == excludeInvoiceId) {
      return false;
    }
    return true;
  }

  Future<SupplierInvoice> create(SupplierInvoice invoice) async {
    final invoiceNum = invoice.invoiceNumber.trim();
    if (invoiceNum.isEmpty) {
      throw StateError('Invoice number is required');
    }
    if (await invoiceNumberExists(invoiceNum)) {
      throw StateError(
        'Invoice number already exists. Please verify the document.',
      );
    }
    final data = Map<String, dynamic>.from(invoice.toJson())
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at')
      ..remove('supplier_name');
    data['invoice_number'] = invoiceNum;
    data.remove('amount_paid');
    data.remove('balance_due');
    final totalVal = _money((data['total'] as num?)?.toDouble() ?? 0);
    data['total'] = totalVal;
    data['amount_paid'] = 0;
    data['balance_due'] = totalVal;
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
    final invoiceNum = (payload['invoice_number'] as String?)?.trim() ?? '';
    if (invoiceNum.isEmpty) {
      throw StateError('Invoice number is required');
    }
    if (await invoiceNumberExists(invoiceNum)) {
      throw StateError(
        'Invoice number already exists. Please verify the document.',
      );
    }
    final payloadCopy = Map<String, dynamic>.from(payload);
    payloadCopy.remove('amount_paid');
    payloadCopy.remove('balance_due');
    final totalVal = _money((payloadCopy['total'] as num?)?.toDouble() ?? 0);
    payloadCopy['total'] = totalVal;
    payloadCopy['amount_paid'] = 0;
    payloadCopy['balance_due'] = totalVal;
    final row = await _client
        .from('supplier_invoices')
        .insert(payloadCopy)
        .select()
        .single();
    return row as Map<String, dynamic>;
  }

  Future<SupplierInvoice> update(SupplierInvoice invoice) async {
    final invoiceNum = invoice.invoiceNumber.trim();
    if (invoiceNum.isEmpty) {
      throw StateError('Invoice number is required');
    }
    final existing = await getById(invoice.id);
    if (existing == null) throw ArgumentError('Invoice not found');
    if (invoiceNum != existing.invoiceNumber.trim() &&
        await invoiceNumberExists(invoiceNum, excludeInvoiceId: invoice.id)) {
      throw StateError(
        'Invoice number already exists. Please verify the document.',
      );
    }
    final newTotal = _money(invoice.total);
    final preservedPaid = _money(existing.amountPaid);
    final balances = _amountPaidAndBalanceDue(
      total: newTotal,
      amountPaid: preservedPaid,
    );

    final data = Map<String, dynamic>.from(invoice.toJson())
      ..remove('supplier_name');
    data['invoice_number'] = invoiceNum;
    data['total'] = newTotal;
    data['amount_paid'] = balances['amount_paid']!;
    data['balance_due'] = balances['balance_due']!;
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

    // Invoice number: never silently auto-generate. If missing → draft + placeholder.
    final String invoiceNumber;
    final SupplierInvoiceStatus status;
    final String? extraNotes;
    final trimmedExtracted = extractedInvoiceNumber?.trim();
    if (trimmedExtracted != null && trimmedExtracted.isNotEmpty) {
      if (await invoiceNumberExists(trimmedExtracted)) {
        throw StateError(
          'Invoice number already exists. Please verify the document.',
        );
      }
      invoiceNumber = trimmedExtracted;
      status = SupplierInvoiceStatus.pendingReview;
      extraNotes = null;
    } else {
      var placeholder =
          'PENDING-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(0x7fffffff)}';
      while (await invoiceNumberExists(placeholder)) {
        placeholder =
            'PENDING-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(0x7fffffff)}';
      }
      invoiceNumber = placeholder;
      status = SupplierInvoiceStatus.draft;
      extraNotes =
          'Invoice number missing — enter the correct invoice number before approval.';
    }

    final noteParts = <String>[];
    if (extractedSupplierName != null && supplierId == null) {
      noteParts.add('Supplier from invoice: $extractedSupplierName');
    }
    if (extraNotes != null) noteParts.add(extraNotes);
    final combinedNotes = noteParts.isEmpty ? null : noteParts.join('\n');

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
      status: status,
      notes: combinedNotes,
      createdBy: createdBy,
    );
    return create(invoice);
  }

  /// WARNING:
  /// This method is deprecated.
  /// Approval must be handled via invoice_list_screen to ensure
  /// correct multi-line ledger entries.
  /// Do NOT use this method.
  ///
  /// Approve and post to ledger (Debit 5000, Credit 2000 AP).
  @Deprecated(
    'Use invoice_list_screen approval flow for multi-line ledger entries',
  )
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
    final runningStock = <String, double>{};
    final runningAvgCost = <String, double>{};
    /// When false, no `inventory_items` row was found on first touch — WAC runs in-memory only.
    final inventoryRowExists = <String, bool>{};

    for (final line in invoice.lineItems) {
      final itemId = line['inventory_item_id']?.toString();
      if (itemId == null || itemId.isEmpty) continue;
      final quantity = (line['quantity'] as num?)?.toDouble() ?? 0;
      if (quantity <= 0) continue;
      final unitPrice = (line['unit_price'] as num?)?.toDouble();
      final incomingUnitCost = unitPrice ?? 0.0;

      if (!runningStock.containsKey(itemId)) {
        final invRow = await _client
            .from('inventory_items')
            .select(
              'current_stock, stock_on_hand_fresh, stock_on_hand_frozen, average_cost, cost_price',
            )
            .eq('id', itemId)
            .maybeSingle();
        if (invRow != null) {
          final rowMap = Map<String, dynamic>.from(invRow);
          runningStock[itemId] = _stockBasisForWac(rowMap);
          runningAvgCost[itemId] =
              (rowMap['average_cost'] as num?)?.toDouble() ??
                  (rowMap['cost_price'] as num?)?.toDouble() ??
                  0.0;
          inventoryRowExists[itemId] = true;
        } else {
          runningStock[itemId] = 0;
          runningAvgCost[itemId] = incomingUnitCost;
          inventoryRowExists[itemId] = false;
        }
      }

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

      final stockBefore = runningStock[itemId]!;
      final avgBefore = runningAvgCost[itemId]!;

      final newAvg = _weightedAverageCost(
        stockBefore: stockBefore,
        currentAvgCost: avgBefore,
        incomingQty: quantity,
        incomingUnitCost: incomingUnitCost,
      );
      final newStock = stockBefore + quantity;
      runningStock[itemId] = newStock;
      runningAvgCost[itemId] = newAvg;

      if (inventoryRowExists[itemId] == true) {
        await _client.from('inventory_items').update({
          'average_cost': newAvg,
          'cost_price': newAvg,
        }).eq('id', itemId);
      }
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

  /// Records a supplier payment against [invoiceId]. Updates `amount_paid`,
  /// `balance_due`, and sets status to `paid` when fully settled.
  /// Posts ledger entries (DR Accounts Payable / CR Cash or Bank) via
  /// [LedgerRepository.createDoubleEntry]; posting failure is fatal.
  Future<void> recordPayment({
    required String invoiceId,
    required double amount,
    required String paymentMethod,
    required String recordedBy,
  }) async {
    final a = _money(amount);
    if (a <= 0) throw StateError('Payment amount must be positive');
    if (recordedBy.isEmpty) throw StateError('recordedBy is required');
    final method = paymentMethod.trim();
    if (method.isEmpty) throw StateError('paymentMethod is required');

    final invoice = await getById(invoiceId);
    if (invoice == null) throw ArgumentError('Invoice not found');
    if (invoice.status == SupplierInvoiceStatus.draft ||
        invoice.status == SupplierInvoiceStatus.cancelled) {
      throw StateError(
        'Cannot record payment for invoice in status ${invoice.status.dbValue}',
      );
    }

    final total = _money(invoice.total);
    var paid = _money(invoice.amountPaid);
    if (paid > total) paid = total;
    final remaining = _money(total - paid);
    if (a > remaining + 1e-9) {
      throw StateError(
        'Payment exceeds balance due (R${remaining.toStringAsFixed(2)} remaining)',
      );
    }

    final supplierId = invoice.supplierId;
    final paymentDateTime = DateTime.now();
    final insertedPayment = await _client.from('supplier_payments').insert({
      'invoice_id': invoiceId,
      'supplier_id': supplierId,
      'amount': a,
      'payment_method': method,
      'recorded_by': recordedBy,
      'payment_date': paymentDateTime.toIso8601String(),
    }).select('id').single();

    final newPaidMap = _amountPaidAndBalanceDue(
      total: total,
      amountPaid: paid + a,
    );
    final newDue = newPaidMap['balance_due']!;
    final newPaidStored = newPaidMap['amount_paid']!;

    final now = DateTime.now().toUtc().toIso8601String();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final updates = <String, dynamic>{
      'amount_paid': newPaidStored,
      'balance_due': newDue,
      'updated_at': now,
    };
    if (newDue <= 0.005) {
      updates['status'] = SupplierInvoiceStatus.paid.dbValue;
      updates['payment_date'] = today;
    }

    await _client.from('supplier_invoices').update(updates).eq('id', invoiceId);

    // Ledger post is fatal — failure rolls back the payment flow to the caller.
    final supplierPaymentId = insertedPayment['id']?.toString();
    final lowerMethod = method.toLowerCase();
    final creditAccountCode = lowerMethod == 'cash' ? '1000' : '1100';
    final creditAccountName = lowerMethod == 'cash' ? 'Cash' : 'Bank';
    final invoiceRef = invoice.supplierName?.trim().isNotEmpty == true
        ? invoice.supplierName!.trim()
        : invoice.invoiceNumber;
    await LedgerRepository(client: _client).createDoubleEntry(
      date: paymentDateTime,
      debitAccountCode: '2000',
      debitAccountName: 'Accounts Payable',
      creditAccountCode: creditAccountCode,
      creditAccountName: creditAccountName,
      amount: a,
      description: 'Supplier payment: $invoiceRef',
      referenceType: 'supplier_payment',
      referenceId: supplierPaymentId,
      source: 'supplier_payment',
      recordedBy: recordedBy,
    );

    await AuditService.log(
      action: 'CREATE',
      module: 'Bookkeeping',
      description:
          'Supplier payment R${a.toStringAsFixed(2)} ($method) for invoice ${invoice.invoiceNumber}',
      entityType: 'SupplierPayment',
      entityId: invoiceId,
    );
  }

  /// Outstanding and lifetime invoiced/paid amounts for [supplierId]
  /// (non-draft, non-cancelled rows only; requires non-null `supplier_id`).
  Future<SupplierBalanceSummary> getSupplierBalance(String supplierId) async {
    if (supplierId.isEmpty) {
      return const SupplierBalanceSummary(
        totalOutstanding: 0,
        totalInvoiced: 0,
        totalPaid: 0,
      );
    }

    final list = await _client
        .from('supplier_invoices')
        .select('total, amount_paid, balance_due')
        .eq('supplier_id', supplierId)
        .inFilter('status', _supplierBalanceStatuses);

    var outstanding = 0.0;
    var invoiced = 0.0;
    var paidSum = 0.0;
    for (final row in list as List) {
      final m = row as Map<String, dynamic>;
      final t = (m['total'] as num?)?.toDouble() ?? 0;
      final p = (m['amount_paid'] as num?)?.toDouble() ?? 0;
      final bRaw = m['balance_due'] as num?;
      final b = bRaw != null
          ? bRaw.toDouble()
          : (t - p < 0 ? 0.0 : t - p);
      invoiced += t;
      paidSum += p;
      outstanding += b < 0 ? 0 : b;
    }

    return SupplierBalanceSummary(
      totalOutstanding: _money(outstanding),
      totalInvoiced: _money(invoiced),
      totalPaid: _money(paidSum),
    );
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
  /// Call before saving or approving an invoice (form save and invoice_list_screen
  /// approval); callers must block the operation when this returns non-empty.
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
