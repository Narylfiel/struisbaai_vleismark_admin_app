import 'package:isar/isar.dart';

part 'cached_leave_request.g.dart';

@collection
class CachedLeaveRequest {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  late String requestId;
  String? staffId;
  String? staffName;
  String? leaveType;
  DateTime? startDate;
  DateTime? endDate;
  double? daysRequested;
  String? status;
  String? notes;
  late DateTime cachedAt;

  CachedLeaveRequest();

  factory CachedLeaveRequest.fromSupabase(Map<String, dynamic> row) {
    final c = CachedLeaveRequest();
    c.requestId = row['id']?.toString() ?? '';
    c.staffId = row['staff_id']?.toString();
    c.staffName = row['staff_name']?.toString();
    c.leaveType = row['leave_type']?.toString();
    c.startDate = row['start_date'] != null ? DateTime.tryParse(row['start_date'].toString()) : null;
    c.endDate = row['end_date'] != null ? DateTime.tryParse(row['end_date'].toString()) : null;
    c.daysRequested = (row['days_requested'] as num?)?.toDouble();
    c.status = row['status']?.toString();
    c.notes = row['notes']?.toString();
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  Map<String, dynamic> toMap() => {'id': requestId, 'staff_id': staffId, 'staff_name': staffName, 'leave_type': leaveType, 'start_date': startDate?.toIso8601String(), 'end_date': endDate?.toIso8601String(), 'days_requested': daysRequested, 'status': status, 'notes': notes};
}
