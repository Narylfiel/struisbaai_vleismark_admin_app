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
