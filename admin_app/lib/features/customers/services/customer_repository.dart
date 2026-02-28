import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';

/// Repository for managing Customer metrics and CRM features 
/// defined in AdminAppBluePrintTruth Module 12.
class CustomerRepository {
  final SupabaseClient _client;

  CustomerRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  // ═════════════════════════════════════════════════════════
  // 1. LIFECYCLE CUSTOMERS (LOYALTY)
  // ═════════════════════════════════════════════════════════

  /// Fetch loyalty-registered customers and their calculated metrics.
  /// Uses filtering map for future UI search inputs.
  Future<List<Map<String, dynamic>>> getCustomers({String? searchQuery}) async {
    try {
      var query = _client.from('loyalty_customers').select();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('full_name', '%$searchQuery%');
      }

      final response = await query.order('full_name').limit(100);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Toggle Customer suspension / activation state
  Future<void> updateCustomerStatus(String id, bool isActive) async {
    try {
      await _client.from('loyalty_customers').update({'active': isActive}).eq('id', id);
    } catch (e, stack) {
      debugPrint('DATABASE WRITE FAILED: loyalty_customers update status');
      debugPrint(e.toString());
      debugPrint(stack.toString());
      rethrow;
    }
  }

  // ═════════════════════════════════════════════════════════
  // 2. PUSH ANNOUNCEMENTS
  // ═════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    try {
      final response = await _client
          .from('announcements')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Return empty safely if feature tables not migrated fully yet.
      return [];
    }
  }

  /// target_audience DB CHECK: 'all', 'customers', 'staff'
  Future<void> createAnnouncement(String title, String body, String targetTier) async {
    try {
      final audience = ['all', 'customers', 'staff'].contains(targetTier) ? targetTier : 'all';
      final currentUserId = _client.auth.currentUser?.id;
      await _client.from('announcements').insert({
        'title': title,
        'content': body,
        'target_audience': audience,
        'created_by': currentUserId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e, stack) {
      debugPrint('DATABASE WRITE FAILED: announcements insert');
      debugPrint(e.toString());
      debugPrint(stack.toString());
      rethrow;
    }
  }

}
