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
      await _client.from('loyalty_customers').update({'is_active': isActive}).eq('id', id);
    } catch (_) {}
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

  Future<void> createAnnouncement(String title, String body, String targetTier) async {
    try {
      await _client.from('announcements').insert({
        'title': title,
        'body': body,
        'target_tier': targetTier,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  // ═════════════════════════════════════════════════════════
  // 3. RECIPE LIBRARY
  // ═════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getRecipes() async {
    try {
      final response = await _client
          .from('recipes') // Standard blueprint tag logic
          .select()
          .order('title')
          .limit(50);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteRecipe(String id) async {
    try {
      await _client.from('recipes').delete().eq('id', id);
    } catch (_) {}
  }
}
