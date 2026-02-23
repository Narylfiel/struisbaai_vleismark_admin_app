import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';

/// Repository for storing and reading application configurations mapped directly
/// to the Business Blueprint Module 13.
class SettingsRepository {
  final SupabaseClient _client;

  SettingsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  // ═════════════════════════════════════════════════════════
  // 1. BUSINESS SETTINGS (key-value: setting_key, setting_value)
  // ═════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> getBusinessSettings() async {
    try {
      final rows = await _client
          .from('business_settings')
          .select('setting_key, setting_value');
      final map = <String, dynamic>{};
      for (final r in rows as List) {
        final k = r['setting_key']?.toString();
        if (k != null) map[k] = r['setting_value'];
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<void> updateBusinessSettings(Map<String, dynamic> data) async {
    const keys = [
      'business_name',
      'address',
      'vat_number',
      'phone',
      'bcea_start_time',
      'bcea_end_time',
    ];
    for (final key in keys) {
      final value = data[key];
      // JSONB validation: skip null and empty string to avoid garbage rows
      if (value == null) continue;
      if (value is String && (value as String).trim().isEmpty) continue;
      // Temporary debug logging
      print('Saving key: $key → value: $value');
      final result = await _client.from('business_settings').upsert(
        {'setting_key': key, 'setting_value': value},
        onConflict: 'setting_key',
      );
      print('Upsert result: $result');
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
