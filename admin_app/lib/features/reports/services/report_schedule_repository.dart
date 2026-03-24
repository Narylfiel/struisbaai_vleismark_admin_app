import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/features/reports/models/report_schedule.dart';

/// CRUD for [report_schedules] and read audit [scheduled_report_runs].
class ReportScheduleRepository {
  ReportScheduleRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  Future<List<ReportScheduleDb>> getAll() async {
    final rows = await _client
        .from('report_schedules')
        .select()
        .order('created_at', ascending: true);
    final list = rows as List<dynamic>;
    return list
        .map((e) => ReportScheduleDb.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ReportScheduleDb> create(ReportScheduleDb schedule) async {
    final json = Map<String, dynamic>.from(schedule.toJson())
      ..remove('id')
      ..remove('created_at')
      ..remove('last_run_at')
      ..remove('next_run_at')
      ..removeWhere((k, v) => v == null);
    final row = await _client.from('report_schedules').insert(json).select().single();
    return ReportScheduleDb.fromJson(Map<String, dynamic>.from(row as Map));
  }

  Future<ReportScheduleDb> update(ReportScheduleDb schedule) async {
    final json = Map<String, dynamic>.from(schedule.toJson())
      ..remove('id')
      ..remove('created_at')
      ..removeWhere((k, v) => v == null);
    final row = await _client
        .from('report_schedules')
        .update(json)
        .eq('id', schedule.id)
        .select()
        .single();
    return ReportScheduleDb.fromJson(Map<String, dynamic>.from(row as Map));
  }

  Future<void> delete(String id) async {
    await _client.from('report_schedules').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getRuns(String scheduleId, {int limit = 20}) async {
    final rows = await _client
        .from('scheduled_report_runs')
        .select()
        .eq('schedule_id', scheduleId)
        .order('run_at', ascending: false)
        .limit(limit);
    final list = rows as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
