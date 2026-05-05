import 'package:isar/isar.dart';

part 'cached_audit_log.g.dart';

@collection
class CachedAuditLog {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  late String logId;
  String? userId;
  String? userName;
  String? action;
  String? tableName;
  String? recordId;
  DateTime? createdAt;
  late DateTime cachedAt;

  CachedAuditLog();

  factory CachedAuditLog.fromSupabase(Map<String, dynamic> row) {
    final c = CachedAuditLog();
    c.logId = row['id']?.toString() ?? '';
    c.userId = row['user_id']?.toString();
    c.userName = row['user_name']?.toString();
    c.action = row['action']?.toString();
    c.tableName = row['table_name']?.toString();
    c.recordId = row['record_id']?.toString();
    c.createdAt = row['created_at'] != null ? DateTime.tryParse(row['created_at'].toString()) : null;
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': logId,
      'user_id': userId,
      'user_name': userName,
      'action': action,
      'table_name': tableName,
      'record_id': recordId,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
