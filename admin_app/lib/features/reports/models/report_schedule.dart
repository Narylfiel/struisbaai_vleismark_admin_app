/// Blueprint §11.3: Auto-Report Schedule — when reports run and delivery (Dashboard, Email, Google Drive).
enum ScheduleType { daily, weekly, monthly }

enum ScheduleDelivery { dashboard, email, googleDrive }

class ScheduledReport {
  final String id;
  final String reportKey;
  final ScheduleType scheduleType;
  final String timeOfDay; // e.g. "23:00", "06:00"
  final int? dayOfWeek; // 1=Monday for weekly
  final int? dayOfMonth; // 1-31 for monthly
  final List<ScheduleDelivery> delivery;

  const ScheduledReport({
    required this.id,
    required this.reportKey,
    required this.scheduleType,
    required this.timeOfDay,
    this.dayOfWeek,
    this.dayOfMonth,
    this.delivery = const [ScheduleDelivery.dashboard],
  });

  String get description {
    switch (scheduleType) {
      case ScheduleType.daily:
        return 'Daily at $timeOfDay';
      case ScheduleType.weekly:
        return '${_weekdayName(dayOfWeek ?? 1)} at $timeOfDay';
      case ScheduleType.monthly:
        return 'Day $dayOfMonth of month at $timeOfDay';
    }
  }

  static String _weekdayName(int d) {
    const names = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[d.clamp(1, 7)];
  }
}

/// Blueprint §11.3: Default schedule entries.
class DefaultReportSchedules {
  static const List<ScheduledReport> blueprint = [
    ScheduledReport(
      id: 'daily_sales',
      reportKey: 'daily_sales',
      scheduleType: ScheduleType.daily,
      timeOfDay: '23:00',
      delivery: [ScheduleDelivery.dashboard],
    ),
    ScheduledReport(
      id: 'weekly_sales_shrinkage',
      reportKey: 'weekly_sales',
      scheduleType: ScheduleType.weekly,
      timeOfDay: '06:00',
      dayOfWeek: 1,
      delivery: [ScheduleDelivery.dashboard, ScheduleDelivery.email],
    ),
    ScheduledReport(
      id: 'monthly_pl_vat_cashflow',
      reportKey: 'monthly_pl',
      scheduleType: ScheduleType.monthly,
      timeOfDay: '06:00',
      dayOfMonth: 1,
      delivery: [ScheduleDelivery.dashboard, ScheduleDelivery.email, ScheduleDelivery.googleDrive],
    ),
  ];
}

/// DB-backed schedule row (`report_schedules` table). Kept separate from blueprint [ScheduledReport].
class ReportScheduleDb {
  final String id;
  final String reportKey;
  final String label;
  final ScheduleType scheduleType;
  final String timeOfDay;
  final int? dayOfWeek;
  final int? dayOfMonth;
  final List<ScheduleDelivery> delivery;
  final String? emailTo;
  final String format;
  final String dateRange;
  final bool isActive;
  final DateTime? lastRunAt;
  final DateTime? nextRunAt;
  final DateTime createdAt;

  const ReportScheduleDb({
    required this.id,
    required this.reportKey,
    required this.label,
    required this.scheduleType,
    required this.timeOfDay,
    this.dayOfWeek,
    this.dayOfMonth,
    required this.delivery,
    this.emailTo,
    required this.format,
    required this.dateRange,
    required this.isActive,
    this.lastRunAt,
    this.nextRunAt,
    required this.createdAt,
  });

  factory ReportScheduleDb.fromJson(Map<String, dynamic> json) {
    return ReportScheduleDb(
      id: json['id']?.toString() ?? '',
      reportKey: json['report_key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      scheduleType: _parseType(json['schedule_type']?.toString() ?? 'daily'),
      timeOfDay: json['time_of_day']?.toString() ?? '06:00',
      dayOfWeek: (json['day_of_week'] as num?)?.toInt(),
      dayOfMonth: (json['day_of_month'] as num?)?.toInt(),
      delivery: _parseDelivery(json['delivery']),
      emailTo: json['email_to']?.toString(),
      format: json['format']?.toString() ?? 'pdf',
      dateRange: json['date_range']?.toString() ?? 'last_7_days',
      isActive: json['is_active'] == true,
      lastRunAt: json['last_run_at'] != null
          ? DateTime.tryParse(json['last_run_at'].toString())
          : null,
      nextRunAt: json['next_run_at'] != null
          ? DateTime.tryParse(json['next_run_at'].toString())
          : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'id': id,
      'report_key': reportKey,
      'label': label,
      'schedule_type': scheduleType.name,
      'time_of_day': timeOfDay,
      'day_of_week': dayOfWeek,
      'day_of_month': dayOfMonth,
      'delivery': delivery.map((e) => e.name).toList(),
      'email_to': emailTo,
      'format': format,
      'date_range': dateRange,
      'is_active': isActive,
      'last_run_at': lastRunAt?.toIso8601String(),
      'next_run_at': nextRunAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
    m.removeWhere((_, v) => v == null);
    return m;
  }

  ReportScheduleDb copyWith({
    String? id,
    String? reportKey,
    String? label,
    ScheduleType? scheduleType,
    String? timeOfDay,
    int? dayOfWeek,
    int? dayOfMonth,
    List<ScheduleDelivery>? delivery,
    String? emailTo,
    String? format,
    String? dateRange,
    bool? isActive,
    DateTime? lastRunAt,
    DateTime? nextRunAt,
    DateTime? createdAt,
  }) {
    return ReportScheduleDb(
      id: id ?? this.id,
      reportKey: reportKey ?? this.reportKey,
      label: label ?? this.label,
      scheduleType: scheduleType ?? this.scheduleType,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      delivery: delivery ?? this.delivery,
      emailTo: emailTo ?? this.emailTo,
      format: format ?? this.format,
      dateRange: dateRange ?? this.dateRange,
      isActive: isActive ?? this.isActive,
      lastRunAt: lastRunAt ?? this.lastRunAt,
      nextRunAt: nextRunAt ?? this.nextRunAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static ScheduleType _parseType(String s) {
    switch (s) {
      case 'weekly':
        return ScheduleType.weekly;
      case 'monthly':
        return ScheduleType.monthly;
      case 'daily':
      default:
        return ScheduleType.daily;
    }
  }

  static List<ScheduleDelivery> _parseDelivery(dynamic d) {
    if (d == null) return const [ScheduleDelivery.dashboard];
    if (d is List) {
      final out = <ScheduleDelivery>[];
      for (final e in d) {
        final x = e.toString();
        switch (x) {
          case 'email':
            out.add(ScheduleDelivery.email);
            break;
          case 'googleDrive':
            out.add(ScheduleDelivery.googleDrive);
            break;
          case 'dashboard':
            out.add(ScheduleDelivery.dashboard);
            break;
        }
      }
      return out.isEmpty ? const [ScheduleDelivery.dashboard] : out;
    }
    return const [ScheduleDelivery.dashboard];
  }
}
