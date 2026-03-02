import 'package:isar/isar.dart';

part 'cached_compliance_record.g.dart';

@collection
class CachedComplianceRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String recordId;

  String? staffId;
  String? staffName;
  String? documentType;
  DateTime? expiryDate;
  String? fileUrl;
  String? notes;
  late DateTime cachedAt;

  CachedComplianceRecord();

  factory CachedComplianceRecord.fromSupabase(Map<String, dynamic> row) {
    final c = CachedComplianceRecord();
    c.recordId = row['id']?.toString() ?? '';
    c.staffId = row['staff_id']?.toString();
    c.staffName = row['staff_name']?.toString();
    c.documentType = row['document_type']?.toString();
    c.expiryDate = row['expiry_date'] != null ? DateTime.tryParse(row['expiry_date'].toString()) : null;
    c.fileUrl = row['file_url']?.toString();
    c.notes = row['notes']?.toString();
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  Map<String, dynamic> toMap() => {
        'id': recordId,
        'staff_id': staffId,
        'staff_name': staffName,
        'document_type': documentType,
        'expiry_date': expiryDate?.toIso8601String(),
        'file_url': fileUrl,
        'notes': notes,
      };
}
