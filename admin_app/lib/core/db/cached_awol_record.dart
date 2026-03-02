import 'package:isar/isar.dart';

part 'cached_awol_record.g.dart';

@collection
class CachedAwolRecord {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  late String recordId;
  String? staffId;
  String? staffName;
  DateTime? awolDate;
  String? notes;
  late bool resolved;
  late DateTime cachedAt;

  CachedAwolRecord();

  factory CachedAwolRecord.fromSupabase(Map<String, dynamic> row) {
    final c = CachedAwolRecord();
    c.recordId = row['id']?.toString() ?? '';
    c.staffId = row['staff_id']?.toString();
    c.staffName = row['staff_name']?.toString();
    c.awolDate = row['awol_date'] != null ? DateTime.tryParse(row['awol_date'].toString()) : null;
    c.notes = row['notes']?.toString();
    c.resolved = row['resolved'] == true;
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': recordId,
      'staff_id': staffId,
      'staff_name': staffName,
      'awol_date': awolDate?.toIso8601String(),
      'notes': notes,
      'resolved': resolved,
    };
  }
}
