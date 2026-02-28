import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import 'package:admin_app/core/db/isar_service.dart';
import 'package:admin_app/core/db/pending_write.dart';
import 'package:admin_app/core/models/stock_movement.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/features/bookkeeping/services/supplier_invoice_repository.dart';
import 'package:admin_app/features/inventory/services/inventory_repository.dart';
import 'package:admin_app/features/production/services/production_batch_repository.dart';

/// Singleton offline write queue. Items are synced when connection returns.
class OfflineQueueService {
  OfflineQueueService._() {
    _initStream();
  }
  static final OfflineQueueService _instance = OfflineQueueService._();
  factory OfflineQueueService() => _instance;

  static const String _statusPending = 'pending';
  static const String _statusFailed = 'failed';
  static const int _maxRetries = 3;

  final StreamController<int> _pendingCountController = StreamController<int>.broadcast();
  bool _streamInitialized = false;

  /// Broadcasts current pending count. Emits when items are added, synced, or moved to failed.
  Stream<int> get pendingCountStream => _pendingCountController.stream;

  void _initStream() {
    if (_streamInitialized) return;
    _streamInitialized = true;
    _emitPendingCount();
  }

  Future<void> _emitPendingCount() async {
    final count = await getPendingCount();
    if (!_pendingCountController.isClosed) {
      _pendingCountController.add(count);
    }
  }

  /// Add an action to the queue. Payload is serialised to JSON.
  Future<void> addToQueue(String actionType, Map<String, dynamic> payload) async {
    final isar = IsarService.isar;
    if (isar == null) return;
    final pw = PendingWrite()
      ..actionType = actionType
      ..payload = jsonEncode(payload)
      ..createdAt = DateTime.now().toUtc()
      ..retryCount = 0
      ..lastError = null
      ..status = _statusPending;
    await isar.writeTxn(() async {
      await isar.pendingWrites.put(pw);
    });
    await _emitPendingCount();
  }

  /// Get all pending items ordered by createdAt ascending.
  Future<List<PendingWrite>> _getPendingItems() async {
    final isar = IsarService.isar;
    if (isar == null) return [];
    return isar.pendingWrites
        .where()
        .anyId()
        .filter()
        .statusEqualTo(_statusPending)
        .sortByCreatedAt()
        .findAll();
  }

  /// Process one item: execute then remove on success or update retry/failed on failure.
  Future<void> processQueue() async {
    final isar = IsarService.isar;
    if (isar == null) return;
    final items = await _getPendingItems();
    for (final item in items) {
      try {
        await _executeAction(item);
        await isar.writeTxn(() async {
          await isar.pendingWrites.delete(item.id);
        });
        await _emitPendingCount();
      } catch (e, st) {
        final errMsg = e.toString();
        debugPrint('OfflineQueueService: ${item.actionType} failed: $e\n$st');
        item.retryCount++;
        item.lastError = errMsg;
        if (item.retryCount >= _maxRetries) {
          item.status = _statusFailed;
        }
        await isar.writeTxn(() async {
          await isar.pendingWrites.put(item);
        });
        await _emitPendingCount();
      }
    }
  }

  Future<void> _executeAction(PendingWrite item) async {
    final payload = jsonDecode(item.payload) as Map<String, dynamic>;
    switch (item.actionType) {
      case 'record_waste':
        await _executeRecordWaste(payload);
        break;
      case 'stock_adjustment':
        await _executeStockAdjustment(payload);
        break;
      case 'complete_batch':
        await _executeCompleteBatch(payload);
        break;
      case 'receive_invoice':
        await _executeReceiveInvoice(payload);
        break;
      case 'create_hunter_job':
        await _executeCreateHunterJob(payload);
        break;
      case 'approve_leave':
        await _executeApproveLeave(payload);
        break;
      default:
        throw UnsupportedError('Unknown actionType: ${item.actionType}');
    }
  }

  Future<void> _executeRecordWaste(Map<String, dynamic> p) async {
    final movementTypeStr = p['movementType'] as String? ?? 'waste';
    final movementType = movementTypeStr == 'sponsorship'
        ? MovementType.sponsorship
        : MovementType.waste;
    await InventoryRepository().recordMovement(
      itemId: p['itemId'] as String,
      movementType: movementType,
      quantity: (p['quantity'] as num).toDouble(),
      performedBy: p['performedBy'] as String,
      notes: p['notes'] as String?,
    );
  }

  Future<void> _executeStockAdjustment(Map<String, dynamic> p) async {
    await InventoryRepository().adjustStock(
      itemId: p['itemId'] as String,
      actualQuantity: (p['quantity'] as num).toDouble(),
      performedBy: p['performedBy'] as String,
      notes: p['notes'] as String?,
    );
  }

  Future<void> _executeCompleteBatch(Map<String, dynamic> p) async {
    final actualQty = p['actualQuantitiesByIngredientId'] as Map<String, dynamic>?;
    final map = <String, double>{};
    if (actualQty != null) {
      for (final e in actualQty.entries) {
        map[e.key] = (e.value as num).toDouble();
      }
    }
    final outputs = (p['outputs'] as List<dynamic>?)
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList() ?? [];
    await ProductionBatchRepository().completeBatch(
      batchId: p['batchId'] as String,
      actualQuantitiesByIngredientId: map,
      outputs: outputs,
      completedBy: p['completedBy'] as String,
      costTotal: (p['costTotal'] as num?)?.toDouble(),
    );
  }

  Future<void> _executeReceiveInvoice(Map<String, dynamic> p) async {
    await SupplierInvoiceRepository().receive(
      p['invoiceId'] as String,
      p['receivedBy'] as String,
    );
  }

  Future<void> _executeCreateHunterJob(Map<String, dynamic> p) async {
    final payload = Map<String, dynamic>.from(p);
    await SupabaseService.client.from('hunter_jobs').insert(payload);
  }

  Future<void> _executeApproveLeave(Map<String, dynamic> p) async {
    final id = p['id'] as String;
    final status = (p['status'] as String?)?.toLowerCase() ?? 'approved';
    await SupabaseService.client.from('leave_requests').update({
      'status': status,
      'review_notes': p['review_notes'] as String?,
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  Future<int> getPendingCount() async {
    final isar = IsarService.isar;
    if (isar == null) return 0;
    return isar.pendingWrites
        .filter()
        .statusEqualTo(_statusPending)
        .count();
  }

  /// All pending items ordered by createdAt ascending.
  Future<List<PendingWrite>> getAllPending() async {
    final isar = IsarService.isar;
    if (isar == null) return [];
    return isar.pendingWrites
        .where()
        .anyId()
        .filter()
        .statusEqualTo(_statusPending)
        .sortByCreatedAt()
        .findAll();
  }

  /// All failed items ordered by createdAt descending.
  Future<List<PendingWrite>> getAllFailed() async {
    final isar = IsarService.isar;
    if (isar == null) return [];
    return isar.pendingWrites
        .where()
        .anyId()
        .filter()
        .statusEqualTo(_statusFailed)
        .sortByCreatedAtDesc()
        .findAll();
  }

  Future<int> getFailedCount() async {
    final isar = IsarService.isar;
    if (isar == null) return 0;
    return isar.pendingWrites
        .where()
        .anyId()
        .filter()
        .statusEqualTo(_statusFailed)
        .count();
  }

  /// Set all failed items back to pending with retryCount 0, then process queue.
  Future<void> retryFailed() async {
    final isar = IsarService.isar;
    if (isar == null) return;
    final failed = await isar.pendingWrites
        .where()
        .anyId()
        .filter()
        .statusEqualTo(_statusFailed)
        .findAll();
    if (failed.isEmpty) return;
    for (final item in failed) {
      item.status = _statusPending;
      item.retryCount = 0;
      item.lastError = null;
    }
    await isar.writeTxn(() async {
      await isar.pendingWrites.putAll(failed);
    });
    await _emitPendingCount();
    await processQueue();
  }

  /// Delete a single pending write by its Isar id.
  Future<void> discardItem(int isarId) async {
    final isar = IsarService.isar;
    if (isar == null) return;
    await isar.writeTxn(() async {
      await isar.pendingWrites.delete(isarId);
    });
    await _emitPendingCount();
  }

  /// Reset a single failed item to pending and process queue (for Retry on one row).
  Future<void> retryItem(int isarId) async {
    final isar = IsarService.isar;
    if (isar == null) return;
    final item = await isar.pendingWrites
        .where()
        .anyId()
        .filter()
        .idEqualTo(isarId)
        .findFirst();
    if (item == null || item.status != _statusFailed) return;
    item.status = _statusPending;
    item.retryCount = 0;
    item.lastError = null;
    await isar.writeTxn(() async {
      await isar.pendingWrites.put(item);
    });
    await _emitPendingCount();
    await processQueue();
  }
}
