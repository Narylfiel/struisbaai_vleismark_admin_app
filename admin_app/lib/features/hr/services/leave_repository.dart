import 'package:supabase_flutter/supabase_flutter.dart';

class LeaveRepository {
  final SupabaseClient _client;
  const LeaveRepository({required SupabaseClient client}) : _client = client;

  // Fetch all leave requests, optionally filtered by staff_id or status
  Future<List<Map<String, dynamic>>> getAll({
    String? staffId,
    String? status,
  }) async {
    var q = _client.from('leave_requests').select(
          '*, staff_profiles(full_name, role)',
        );
    if (staffId != null) q = q.eq('staff_id', staffId);
    if (status != null) q = q.eq('status', status);
    return List<Map<String, dynamic>>.from(
      await q.order('created_at', ascending: false),
    );
  }

  Future<Map<String, dynamic>?> getById(String id) async =>
      await _client.from('leave_requests').select().eq('id', id).maybeSingle();

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async =>
      await _client.from('leave_requests').insert(data).select().single();

  Future<Map<String, dynamic>> updateStatus({
    required String id,
    required String status,
    required String approvedBy,
  }) async =>
      await _client.from('leave_requests').update({
        'status': status,
        'approved_by': approvedBy,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id).select().single();

  Future<void> delete(String id) async =>
      await _client.from('leave_requests').delete().eq('id', id);
}

