import '../../../core/models/base_model.dart';

/// Blueprint §4.7: Stock-take session — Owner/Manager starts; multi-device; approve → adjustments.
enum StockTakeSessionStatus {
  open,
  inProgress,
  pendingApproval,
  approved,
  cancelled,
}

extension StockTakeSessionStatusExt on StockTakeSessionStatus {
  String get dbValue {
    switch (this) {
      case StockTakeSessionStatus.open:
        return 'open';
      case StockTakeSessionStatus.inProgress:
        return 'in_progress';
      case StockTakeSessionStatus.pendingApproval:
        return 'pending_approval';
      case StockTakeSessionStatus.approved:
        return 'approved';
      case StockTakeSessionStatus.cancelled:
        return 'cancelled';
    }
  }

  static StockTakeSessionStatus fromDb(String? value) {
    switch (value) {
      case 'in_progress':
        return StockTakeSessionStatus.inProgress;
      case 'pending_approval':
        return StockTakeSessionStatus.pendingApproval;
      case 'approved':
        return StockTakeSessionStatus.approved;
      case 'cancelled':
        return StockTakeSessionStatus.cancelled;
      default:
        return StockTakeSessionStatus.open;
    }
  }
}

class StockTakeSession extends BaseModel {
  final StockTakeSessionStatus status;
  final DateTime? startedAt;
  final String? startedBy;
  final DateTime? approvedAt;
  final String? approvedBy;
  final String? notes;

  const StockTakeSession({
    required super.id,
    this.status = StockTakeSessionStatus.open,
    this.startedAt,
    this.startedBy,
    this.approvedAt,
    this.approvedBy,
    this.notes,
    super.createdAt,
    super.updatedAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.dbValue,
      'started_at': startedAt?.toIso8601String(),
      'started_by': startedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'approved_by': approvedBy,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory StockTakeSession.fromJson(Map<String, dynamic> json) {
    return StockTakeSession(
      id: json['id'] as String,
      status: StockTakeSessionStatusExt.fromDb(json['status'] as String?),
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String)
          : null,
      startedBy: json['started_by'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.tryParse(json['approved_at'] as String)
          : null,
      approvedBy: json['approved_by'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  bool validate() => true;

  @override
  List<String> getValidationErrors() => [];
}
