import 'package:supabase_flutter/supabase_flutter.dart';

class TimecardRepository {
  final SupabaseClient _client;
  const TimecardRepository({required SupabaseClient client}) : _client = client;

  Future<List<Map<String, dynamic>>> getAll({
    String? staffId,
    DateTime? from,
    DateTime? to,
  }) async {
    var q = _client.from('timecards').select(
          '*, '
          'staff_profiles!timecards_staff_id_fkey(full_name, role, hourly_rate), '
          'timecard_breaks(id, break_type, break_start, break_end, break_duration_minutes)',
        );
    if (staffId != null) q = q.eq('staff_id', staffId);
    if (from != null) {
      q = q.gte('shift_date', from.toIso8601String().substring(0, 10));
    }
    if (to != null) {
      q = q.lte('shift_date', to.toIso8601String().substring(0, 10));
    }
    final rows = List<Map<String, dynamic>>.from(
      await q.order('shift_date', ascending: false),
    );
    for (final row in rows) {
      final breaks = row['timecard_breaks'];
      if (breaks is List) {
        breaks.sort((a, b) {
          final aStart = (a as Map)['break_start'] as String? ?? '';
          final bStart = (b as Map)['break_start'] as String? ?? '';
          return aStart.compareTo(bStart);
        });
      }
    }
    return rows;
  }

  Future<List<Map<String, dynamic>>> getForPeriod({
    required String staffId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final rows = await _client
        .from('timecards')
        .select()
        .eq('staff_id', staffId)
        .gte('shift_date', periodStart.toIso8601String().substring(0, 10))
        .lte('shift_date', periodEnd.toIso8601String().substring(0, 10))
        .order('shift_date', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> getClockedIn() async {
    final rows = await _client
        .from('timecards')
        .select('*, staff_profiles!timecards_staff_id_fkey(full_name, role)')
        .isFilter('clock_out', null);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async =>
      await _client.from('timecards').insert(data).select().single();

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> data,
  ) async =>
      await _client.from('timecards').update(data).eq('id', id).select().single();

  Future<void> delete(String id) async =>
      await _client.from('timecards').delete().eq('id', id);
}

