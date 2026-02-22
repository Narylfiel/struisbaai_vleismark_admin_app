import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import '../../../core/models/stock_movement.dart';
import '../models/stock_take_entry.dart';
import '../models/stock_take_session.dart';
import 'inventory_repository.dart';

/// Blueprint §4.7: Stock-take — session, count entries, approve → adjustments (stock_movements + audit).
class StockTakeRepository {
  final SupabaseClient _client;
  final InventoryRepository _inventoryRepo;

  StockTakeRepository({
    SupabaseClient? client,
    InventoryRepository? inventoryRepo,
  })  : _client = client ?? SupabaseService.client,
        _inventoryRepo = inventoryRepo ?? InventoryRepository(client: client);

  Future<List<StockTakeSession>> getSessions({String? status}) async {
    var q = _client.from('stock_take_sessions').select();
    if (status != null && status.isNotEmpty) {
      q = q.eq('status', status);
    }
    final list = await q.order('started_at', ascending: false);
    return (list as List)
        .map((e) => StockTakeSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get current open or in_progress session (for multi-device: all devices see this).
  Future<StockTakeSession?> getOpenSession() async {
    final list = await _client
        .from('stock_take_sessions')
        .select()
        .inFilter('status', ['open', 'in_progress'])
        .order('started_at', ascending: false)
        .limit(1);
    if (list.isEmpty) return null;
    return StockTakeSession.fromJson(list.first as Map<String, dynamic>);
  }

  Future<StockTakeSession?> getSession(String id) async {
    final row = await _client
        .from('stock_take_sessions')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return StockTakeSession.fromJson(row as Map<String, dynamic>);
  }

  Future<StockTakeSession> createSession({String? startedBy, String? notes}) async {
    final data = {
      'status': 'open',
      'started_at': DateTime.now().toIso8601String(),
      'started_by': startedBy,
      'notes': notes,
    };
    final response = await _client
        .from('stock_take_sessions')
        .insert(data)
        .select()
        .single();
    return StockTakeSession.fromJson(response as Map<String, dynamic>);
  }

  Future<void> setSessionStatus(String sessionId, String status) async {
    final payload = <String, dynamic>{'status': status};
    if (status == 'approved') {
      payload['approved_at'] = DateTime.now().toIso8601String();
    }
    await _client
        .from('stock_take_sessions')
        .update(payload)
        .eq('id', sessionId);
  }

  Future<List<StockTakeEntry>> getEntriesBySession(String sessionId) async {
    final list = await _client
        .from('stock_take_entries')
        .select()
        .eq('session_id', sessionId)
        .order('item_id')
        .order('location_id');
    return (list as List)
        .map((e) => StockTakeEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Upsert count: one row per (session, item, location). Multi-device: last write wins (or use device_id for conflict detection).
  Future<StockTakeEntry> saveEntry({
    required String sessionId,
    required String itemId,
    String? locationId,
    required double expectedQuantity,
    required double? actualQuantity,
    String? countedBy,
    String? deviceId,
  }) async {
    var q = _client.from('stock_take_entries').select().eq('session_id', sessionId).eq('item_id', itemId);
    if (locationId == null || locationId.isEmpty) {
      q = q.isFilter('location_id', null);
    } else {
      q = q.eq('location_id', locationId);
    }
    final existing = await q.maybeSingle();
    if (existing != null) {
      final row = await _client
          .from('stock_take_entries')
          .update({
            'actual_quantity': actualQuantity,
            'counted_by': countedBy,
            'device_id': deviceId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existing['id'])
          .select()
          .single();
      return StockTakeEntry.fromJson(row as Map<String, dynamic>);
    }
    final data = {
      'session_id': sessionId,
      'item_id': itemId,
      'location_id': locationId,
      'expected_quantity': expectedQuantity,
      'actual_quantity': actualQuantity,
      'counted_by': countedBy,
      'device_id': deviceId,
    };
    final response = await _client
        .from('stock_take_entries')
        .insert(data)
        .select()
        .single();
    return StockTakeEntry.fromJson(response as Map<String, dynamic>);
  }

  /// Blueprint §4.7 step 9: On approval — stock adjusted to physical counts; variances logged to stock_movements.
  Future<void> approveSession(String sessionId, String approvedBy) async {
    final session = await getSession(sessionId);
    if (session == null) throw ArgumentError('Session not found');
    if (session.status == StockTakeSessionStatus.approved) {
      throw StateError('Session already approved');
    }
    final entries = await getEntriesBySession(sessionId);
    for (final e in entries) {
      if (e.actualQuantity != null) {
        await _inventoryRepo.adjustStock(
          itemId: e.itemId,
          actualQuantity: e.actualQuantity!,
          performedBy: approvedBy,
          notes: 'Stock-take session ${session.id} (location: ${e.locationId ?? "default"})',
        );
      }
    }
    await _client
        .from('stock_take_sessions')
        .update({
          'status': 'approved',
          'approved_at': DateTime.now().toIso8601String(),
          'approved_by': approvedBy,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', sessionId);
  }
}
