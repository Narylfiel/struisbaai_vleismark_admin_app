import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';

/// Repository for retrieving immutable system activity logs 
/// as defined in AdminAppBluePrintTruth Module 14.
class AuditRepository {
  final SupabaseClient _client;

  AuditRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  // ═════════════════════════════════════════════════════════
  // 1. CHRONOLOGICAL AUDIT LOGS
  // ═════════════════════════════════════════════════════════
  
  /// Fetches system audit logs supporting pagination and filters
  /// to prevent overloading the application with full historic datasets.
  Future<List<Map<String, dynamic>>> getAuditLogs({
    String? dateRangeStart,
    String? dateRangeEnd,
    String? actionType,
    String? staffMember,
    String? searchText,
    String? severity,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      // NOTE: Using 'audit_log' singular as corrected in reports_hub module
      // representing the immutable tracking table.
      var query = _client.from('audit_log').select();

      // Apply date filters if available
      if (dateRangeStart != null && dateRangeStart.isNotEmpty) {
        query = query.gte('created_at', dateRangeStart);
      }
      if (dateRangeEnd != null && dateRangeEnd.isNotEmpty) {
        query = query.lte('created_at', dateRangeEnd);
      }

      // Apply text filters loosely where applicable
      if (actionType != null && actionType.isNotEmpty) {
        query = query.ilike('action', '%$actionType%');
      }
      if (staffMember != null && staffMember.isNotEmpty) {
        query = query.ilike('staff_name', '%$staffMember%');
      }
      if (searchText != null && searchText.isNotEmpty) {
        query = query.or(
          'details.ilike.%$searchText%,'
          'description.ilike.%$searchText%,'
          'table_name.ilike.%$searchText%',
        );
      }
      if (severity != null && severity.isNotEmpty && severity != 'All') {
        // Assuming severity is tracked in details or a specific column. 
        // We'll map it to ilike on details for robust searching 
        // if a dedicated column isn't explicitly defined.
        query = query.ilike('details', '%$severity%');
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1); // 0-indexed range inclusive

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Get distinct action types for the filter dropdown
  Future<List<String>> getDistinctActions() async {
    try {
      final staticActions = <String>[
        'All',
        'INSERT',
        'UPDATE',
        'DELETE',
        'CREATE',
        'LOGOUT',
        'RECEIVE',
        'void_sale',
        'Clock In',
        'Clock Out',
        'Break Start',
        'Break End',
        'Sale Completed',
        'Sale Offline',
        'Refund',
        'Parked Sale',
        'Account Sale',
      ];

      final rows = await _client.from('audit_log').select('action');
      final dbActions = <String>{
        for (final row in rows as List)
          (row['action']?.toString() ?? '').trim()
      }..remove('');

      final merged = <String>{
        ...staticActions,
        ...dbActions,
      }.toList();
      merged.sort((a, b) {
        if (a == 'All') return -1;
        if (b == 'All') return 1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });
      return merged;
    } catch (_) {
      return [
        'All',
        'INSERT',
        'UPDATE',
        'DELETE',
        'CREATE',
        'LOGOUT',
        'RECEIVE',
        'void_sale',
        'Clock In',
        'Clock Out',
        'Break Start',
        'Break End',
        'Sale Completed',
        'Sale Offline',
        'Refund',
        'Parked Sale',
        'Account Sale',
      ];
    }
  }
}
