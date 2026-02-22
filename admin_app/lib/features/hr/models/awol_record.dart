import '../../../core/models/base_model.dart';

/// Blueprint §7.3a: Staff AWOL / Absconding — date, expected start, notified, resolution, warning, notes.
enum AwolResolution {
  returned,
  resigned,
  dismissed,
  warningIssued,
  pending,
}

extension AwolResolutionExt on AwolResolution {
  String get dbValue {
    switch (this) {
      case AwolResolution.returned:
        return 'returned';
      case AwolResolution.resigned:
        return 'resigned';
      case AwolResolution.dismissed:
        return 'dismissed';
      case AwolResolution.warningIssued:
        return 'warning_issued';
      case AwolResolution.pending:
        return 'pending';
    }
  }

  static AwolResolution fromDb(String? value) {
    switch (value) {
      case 'returned':
        return AwolResolution.returned;
      case 'resigned':
        return AwolResolution.resigned;
      case 'dismissed':
        return AwolResolution.dismissed;
      case 'warning_issued':
        return AwolResolution.warningIssued;
      default:
        return AwolResolution.pending;
    }
  }
}

class AwolRecord extends BaseModel {
  final String staffId;
  final DateTime awolDate;
  final DateTime? expectedStartTime;
  final bool notifiedOwnerManager;
  final String? notifiedWho;
  final AwolResolution resolution;
  final bool writtenWarningIssued;
  final String? warningDocumentUrl;
  final String? notes;
  final String recordedBy;
  final String? staffName;

  const AwolRecord({
    required super.id,
    required this.staffId,
    required this.awolDate,
    this.expectedStartTime,
    this.notifiedOwnerManager = false,
    this.notifiedWho,
    this.resolution = AwolResolution.pending,
    this.writtenWarningIssued = false,
    this.warningDocumentUrl,
    this.notes,
    required this.recordedBy,
    super.createdAt,
    super.updatedAt,
    this.staffName,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'staff_id': staffId,
      'awol_date': awolDate.toIso8601String().substring(0, 10),
      'expected_start_time': expectedStartTime != null
          ? '${expectedStartTime!.hour.toString().padLeft(2, '0')}:${expectedStartTime!.minute.toString().padLeft(2, '0')}:00'
          : null,
      'notified_owner_manager': notifiedOwnerManager,
      'notified_who': notifiedWho,
      'resolution': resolution.dbValue,
      'written_warning_issued': writtenWarningIssued,
      'warning_document_url': warningDocumentUrl,
      'notes': notes,
      'recorded_by': recordedBy,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory AwolRecord.fromJson(Map<String, dynamic> json) {
    DateTime? expectedTime;
    if (json['expected_start_time'] != null) {
      final t = json['expected_start_time'].toString();
      if (t.length >= 5) {
        final parts = t.split(':');
        if (parts.length >= 2) {
          expectedTime = DateTime(2000, 1, 1, int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0);
        }
      }
    }
    return AwolRecord(
      id: json['id'] as String,
      staffId: json['staff_id'] as String,
      awolDate: json['awol_date'] != null ? DateTime.parse(json['awol_date'] as String) : DateTime.now(),
      expectedStartTime: expectedTime,
      notifiedOwnerManager: json['notified_owner_manager'] as bool? ?? false,
      notifiedWho: json['notified_who'] as String?,
      resolution: AwolResolutionExt.fromDb(json['resolution'] as String?),
      writtenWarningIssued: json['written_warning_issued'] as bool? ?? false,
      warningDocumentUrl: json['warning_document_url'] as String?,
      notes: json['notes'] as String?,
      recordedBy: json['recorded_by']?.toString() ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      staffName: json['staff_profiles'] != null
          ? (json['staff_profiles'] as Map<String, dynamic>)['full_name'] as String?
          : json['full_name'] as String?,
    );
  }

  AwolRecord copyWith({
    String? staffName,
    AwolResolution? resolution,
    bool? writtenWarningIssued,
    String? notes,
  }) {
    return AwolRecord(
      id: id,
      staffId: staffId,
      awolDate: awolDate,
      expectedStartTime: expectedStartTime,
      notifiedOwnerManager: notifiedOwnerManager,
      notifiedWho: notifiedWho,
      resolution: resolution ?? this.resolution,
      writtenWarningIssued: writtenWarningIssued ?? this.writtenWarningIssued,
      warningDocumentUrl: warningDocumentUrl,
      notes: notes ?? this.notes,
      recordedBy: recordedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      staffName: staffName ?? this.staffName,
    );
  }

  @override
  bool validate() => staffId.isNotEmpty && recordedBy.isNotEmpty;

  @override
  List<String> getValidationErrors() {
    final e = <String>[];
    if (staffId.isEmpty) e.add('Staff is required');
    if (recordedBy.isEmpty) e.add('Recorded by is required');
    return e;
  }
}
