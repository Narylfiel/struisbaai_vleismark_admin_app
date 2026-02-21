import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for storing and reading application configurations mapped directly
/// to the Business Blueprint Module 13.
class SettingsRepository {
  final SupabaseClient _client;

  SettingsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ═════════════════════════════════════════════════════════
  // 1. BUSINESS SETTINGS
  // ═════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> getBusinessSettings() async {
    try {
      final response = await _client
          .from('business_settings')
          .select()
          .limit(1)
          .maybeSingle();
      return response ?? {};
    } catch (_) {
      return {};
    }
  }

  Future<void> updateBusinessSettings(Map<String, dynamic> data) async {
    final existing = await getBusinessSettings();
    if (existing.isEmpty) {
      await _client.from('business_settings').insert(data);
    } else {
      await _client.from('business_settings').update(data).eq('id', existing['id']);
    }
  }

  // ═════════════════════════════════════════════════════════
  // 2. SCALE / HW CONFIG
  // ═════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> getScaleConfig() async {
    try {
      final response = await _client
          .from('scale_config')
          .select()
          .limit(1)
          .maybeSingle();
      return response ?? {};
    } catch (_) {
      return {};
    }
  }

  Future<void> updateScaleConfig(Map<String, dynamic> data) async {
    final existing = await getScaleConfig();
    if (existing.isEmpty) {
      await _client.from('scale_config').insert(data);
    } else {
      await _client.from('scale_config').update(data).eq('id', existing['id']);
    }
  }

  // ═════════════════════════════════════════════════════════
  // 3. TAX RULES
  // ═════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> getTaxRules() async {
    try {
      final response = await _client
          .from('tax_rules')
          .select()
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  Future<void> createTaxRule(String name, double percentage) async {
    await _client.from('tax_rules').insert({'name': name, 'percentage': percentage});
  }

  Future<void> deleteTaxRule(String id) async {
    await _client.from('tax_rules').delete().eq('id', id);
  }

  // ═════════════════════════════════════════════════════════
  // 4. SYSTEM NOTIFICATIONS / ALERTS
  // ═════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> getSystemConfig() async {
    try {
      final response = await _client
          .from('system_config')
          .select()
          .order('key');
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  Future<void> toggleNotification(String id, bool val) async {
    await _client.from('system_config').update({'is_active': val}).eq('id', id);
  }
}
