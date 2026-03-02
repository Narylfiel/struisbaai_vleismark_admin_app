import 'package:isar/isar.dart';

part 'cached_timecard.g.dart';

@collection
class CachedTimecard {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  late String timecardId;
  String? staffId;
  String? staffName;
  DateTime? clockIn;
  DateTime? clockOut;
  late int breakMinutes;
  DateTime? shiftDate;
  double? totalHours;
  late DateTime cachedAt;

  CachedTimecard();

  factory CachedTimecard.fromSupabase(Map<String, dynamic> row) {
    final c = CachedTimecard();
    c.timecardId = row['id']?.toString() ?? '';
    c.staffId = row['staff_id']?.toString();
    c.staffName = row['staff_name']?.toString();
    c.clockIn = row['clock_in'] != null ? DateTime.tryParse(row['clock_in'].toString()) : null;
    c.clockOut = row['clock_out'] != null ? DateTime.tryParse(row['clock_out'].toString()) : null;
    c.breakMinutes = (row['break_minutes'] as num?)?.toInt() ?? 0;
    c.shiftDate = row['shift_date'] != null ? DateTime.tryParse(row['shift_date'].toString()) : null;
    c.totalHours = (row['total_hours'] as num?)?.toDouble();
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  Map<String, dynamic> toMap() => {'id': timecardId, 'staff_id': staffId, 'staff_name': staffName, 'clock_in': clockIn?.toIso8601String(), 'clock_out': clockOut?.toIso8601String(), 'break_minutes': breakMinutes, 'shift_date': shiftDate?.toIso8601String(), 'total_hours': totalHours};
}
