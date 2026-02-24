/// Hunter job status — DB CHECK allows exactly (lowercase):
/// 'intake', 'processing', 'ready', 'completed', 'cancelled'
enum HunterJobStatus {
  intake,
  processing,
  ready,
  completed,
  cancelled,
}

extension HunterJobStatusExt on HunterJobStatus {
  String get dbValue {
    switch (this) {
      case HunterJobStatus.intake:
        return 'intake';
      case HunterJobStatus.processing:
        return 'processing';
      case HunterJobStatus.ready:
        return 'ready';
      case HunterJobStatus.completed:
        return 'completed';
      case HunterJobStatus.cancelled:
        return 'cancelled';
    }
  }

  /// User-friendly label for UI.
  String get displayLabel {
    switch (this) {
      case HunterJobStatus.intake:
        return 'Intake';
      case HunterJobStatus.processing:
        return 'Processing';
      case HunterJobStatus.ready:
        return 'Ready for Collection';
      case HunterJobStatus.completed:
        return 'Completed';
      case HunterJobStatus.cancelled:
        return 'Cancelled';
    }
  }

  static HunterJobStatus fromDb(String? value) {
    if (value == null || value.isEmpty) return HunterJobStatus.intake;
    final v = value.toLowerCase();
    switch (v) {
      case 'intake':
        return HunterJobStatus.intake;
      case 'processing':
      case 'in_progress':
        return HunterJobStatus.processing;
      case 'ready':
        return HunterJobStatus.ready;
      case 'completed':
      case 'collected':
        return HunterJobStatus.completed;
      case 'cancelled':
        return HunterJobStatus.cancelled;
      case 'quoted':
      case 'confirmed':
        return HunterJobStatus.intake;
      default:
        return HunterJobStatus.intake;
    }
  }
}

/// Normalize raw DB/legacy status string to allowed DB value (lowercase).
String hunterJobStatusToDbValue(String? status) {
  if (status == null || status.isEmpty) return 'intake';
  final v = status.toLowerCase();
  switch (v) {
    case 'intake':
      return 'intake';
    case 'processing':
    case 'in_progress':
      return 'processing';
    case 'ready':
    case 'ready for collection':
      return 'ready';
    case 'completed':
    case 'collected':
      return 'completed';
    case 'cancelled':
      return 'cancelled';
    case 'quoted':
    case 'confirmed':
      return 'intake';
    default:
      return 'intake';
  }
}
