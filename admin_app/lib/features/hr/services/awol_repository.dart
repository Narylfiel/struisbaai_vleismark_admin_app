import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import '../models/awol_record.dart';

/// Blueprint §7.3a: AWOL / Absconding records — create, list, update resolution; pattern detection (3+ = persistent).
class AwolRepository {
  final SupabaseClient _client;

  AwolRepository({SupabaseClient? client}) : _client = client ?? SupabaseService.client;

  Future<List<AwolRecord>> getRecords({String? staffId, DateTime? from, DateTime? to}) async {
    var q = _client.from('staff_awol_records').select();
    if (staffId != null) q = q.eq('staff_id', staffId);
    if (from != null) q = q.gte('awol_date', from.toIso8601String().substring(0, 10));
    if (to != null) q = q.lte('awol_date', to.toIso8601String().substring(0, 10));
    final list = await q.order('awol_date', ascending: false);
    final records = (list as List).map((e) => AwolRecord.fromJson(e as Map<String, dynamic>)).toList();
    await _attachStaffNames(records);
    return records;
  }

  Future<void> _attachStaffNames(List<AwolRecord> records) async {
    final ids = records.map((e) => e.staffId).toSet().toList();
    if (ids.isEmpty) return;
    try {
      final rows = await _client.from('staff_profiles').select('id, full_name').inFilter('id', ids);
      final nameMap = {for (var r in rows as List) r['id'] as String: r['full_name'] as String?};
      for (var i = 0; i < records.length; i++) {
        final name = nameMap[records[i].staffId];
        if (name != null) records[i] = records[i].copyWith(staffName: name);
      }
    } catch (_) {}
  }

  /// Blueprint: 3+ AWOL incidents for same staff = persistent AWOL flag.
  Future<Map<String, int>> getAwolCountByStaff({DateTime? from, DateTime? to}) async {
    final list = await getRecords(from: from, to: to);
    final counts = <String, int>{};
    for (final r in list) {
      counts[r.staffId] = (counts[r.staffId] ?? 0) + 1;
    }
    return counts;
  }

  Future<AwolRecord> create({
    required String staffId,
    required DateTime awolDate,
    DateTime? expectedStartTime,
    bool notifiedOwnerManager = false,
    String? notifiedWho,
    AwolResolution resolution = AwolResolution.pending,
    bool writtenWarningIssued = false,
    String? warningDocumentUrl,
    String? notes,
    required String recordedBy,
  }) async {
    final payload = {
      'staff_id': staffId,
      'awol_date': awolDate.toIso8601String().substring(0, 10),
      'expected_start_time': expectedStartTime != null
          ? '${expectedStartTime.hour.toString().padLeft(2, '0')}:${expectedStartTime.minute.toString().padLeft(2, '0')}:00'
          : null,
      'notified_owner_manager': notifiedOwnerManager,
      'notified_who': notifiedWho,
      'resolution': resolution.dbValue,
      'written_warning_issued': writtenWarningIssued,
      'warning_document_url': warningDocumentUrl,
      'notes': notes,
      'recorded_by': recordedBy,
    };
    final row = await _client.from('staff_awol_records').insert(payload).select().single();
    return AwolRecord.fromJson(row as Map<String, dynamic>);
  }

  Future<void> updateResolution(String id, AwolResolution resolution, {bool writtenWarningIssued = false, String? notes}) async {
    final payload = <String, dynamic>{'resolution': resolution.dbValue, 'written_warning_issued': writtenWarningIssued};
    if (notes != null) payload['notes'] = notes;
    await _client.from('staff_awol_records').update(payload).eq('id', id);
  }
}
