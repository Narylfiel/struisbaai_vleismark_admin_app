import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';

/// Repository for storing and reading application configurations mapped directly
/// to the Business Blueprint Module 13.
class SettingsRepository {
  final SupabaseClient _client;

  SettingsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  // ═════════════════════════════════════════════════════════
  // 1. BUSINESS SETTINGS (supports column-based main row + key-value rows)
  // DB may have: (a) main row with setting_key null and columns business_name, address, etc.;
  //              (b) key-value rows with setting_key, setting_value (Scale/Tax/Notification).
  // ═════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> getBusinessSettings() async {
    try {
      final rows = await _client.from('business_settings').select('*');
      final map = <String, dynamic>{};
      for (final r in rows as List) {
        final row = Map<String, dynamic>.from(r as Map);
        final key = row['setting_key']?.toString();
        if (key != null && key.isNotEmpty) {
          map[key] = row['setting_value'];
        } else if (row.containsKey('business_name') || row.containsKey('address')) {
          // Main row (column-based): map to keys expected by Business tab
          final ws = row['working_hours_start']?.toString() ?? '';
          final we = row['working_hours_end']?.toString() ?? '';
          map['business_name'] = row['business_name'];
          map['address'] = row['address'];
          map['vat_number'] = row['vat_number'];
          map['phone'] = row['phone'];
          map['bcea_start_time'] = ws.length >= 5 ? ws.substring(0, 5) : (ws.isNotEmpty ? ws : '07:00');
          map['bcea_end_time'] = we.length >= 5 ? we.substring(0, 5) : (we.isNotEmpty ? we : '17:00');
        }
      }
      if (map.isEmpty) {
        map['bcea_start_time'] = '07:00';
        map['bcea_end_time'] = '17:00';
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<void> updateBusinessSettings(Map<String, dynamic> data) async {
    const mainKeys = [
      'business_name',
      'address',
      'vat_number',
      'phone',
      'bcea_start_time',
      'bcea_end_time',
    ];
    try {
      // Main row: row with column-based config (has business_name; or first row if only one)
      final list = (await _client.from('business_settings').select('id, business_name')) as List;
      final maps = list.cast<Map<String, dynamic>>();
      Map<String, dynamic>? mainRow;
      for (final r in maps) {
        if (r['business_name'] != null && r['business_name'].toString().trim().isNotEmpty) {
          mainRow = r;
          break;
        }
      }
      mainRow ??= maps.isNotEmpty ? maps.first : null;
      if (mainRow != null && mainRow['id'] != null) {
        final payload = <String, dynamic>{};
        if (data['business_name'] != null) payload['business_name'] = data['business_name'];
        if (data['address'] != null) payload['address'] = data['address'];
        if (data['vat_number'] != null) payload['vat_number'] = data['vat_number'];
        if (data['phone'] != null) payload['phone'] = data['phone'];
        final start = data['bcea_start_time']?.toString()?.trim();
        if (start != null && start.isNotEmpty) {
          payload['working_hours_start'] = start.length == 5 ? '$start:00' : start;
        }
        final end = data['bcea_end_time']?.toString()?.trim();
        if (end != null && end.isNotEmpty) {
          payload['working_hours_end'] = end.length == 5 ? '$end:00' : end;
        }
        if (payload.isNotEmpty) {
          await _client.from('business_settings').update(payload).eq('id', mainRow['id']);
        }
      } else {
        // No main row: upsert key-value rows for Business tab keys
        for (final key in mainKeys) {
          final value = data[key];
          if (value == null || (value is String && (value as String).trim().isEmpty)) continue;
          await _client.from('business_settings').upsert(
            {'setting_key': key, 'setting_value': value},
            onConflict: 'setting_key',
          );
        }
      }
    } catch (e, stack) {
      debugPrint('DATABASE WRITE FAILED: business_settings update/upsert');
      debugPrint(e.toString());
      debugPrint(stack.toString());
      rethrow;
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
