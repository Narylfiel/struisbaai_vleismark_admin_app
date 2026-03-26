import 'package:supabase_flutter/supabase_flutter.dart';

class StaffProfileRepository {
  final SupabaseClient _client;
  const StaffProfileRepository({required SupabaseClient client}) : _client = client;

  Future<List<Map<String, dynamic>>> getAll({bool? isActive}) async {
    var q = _client.from('staff_profiles').select();
    if (isActive != null) q = q.eq('is_active', isActive);
    return List<Map<String, dynamic>>.from(
      await q.order('full_name', ascending: true),
    );
  }

  Future<Map<String, dynamic>?> getById(String id) async =>
      await _client.from('staff_profiles').select().eq('id', id).maybeSingle();

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async =>
      await _client.from('staff_profiles').insert(data).select().single();

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> data,
  ) async =>
      await _client
          .from('staff_profiles')
          .update({
            ...data,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

  Future<void> deactivate(String id) async =>
      await _client.from('staff_profiles').update({
        'is_active': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);

  Future<List<Map<String, dynamic>>> search(String query) async {
    final rows = await _client
        .from('staff_profiles')
        .select()
        .or('full_name.ilike.%$query%,role.ilike.%$query%')
        .eq('is_active', true)
        .order('full_name', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }
}

