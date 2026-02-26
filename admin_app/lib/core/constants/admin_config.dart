class AdminConfig {
  // App Info
  static const String appName = 'Struisbaai Vleismark';
  static const String appSubtitle = 'Admin & Back-Office';
  static const String appVersion = '1.0.0';

  /// Phase 5 L6: Layout breakpoints (width in logical pixels). Primary: Windows desktop; adapt for smaller screens.
  static const double breakpointMobile = 600;
  static const double breakpointTablet = 900;
  static const double breakpointDesktop = 1200;

  // Supabase — project nasfakcqzmpfcpqttmti (URL and anon key must match)
  static const String supabaseUrl = 'https://nasfakcqzmpfcpqttmti.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5hc2Zha2Nxem1wZmNwcXR0bXRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE2MDcxNTEsImV4cCI6MjA4NzE4MzE1MX0.p5YyyIGZZmnKzIcv-UlK8G05Yy3UDNZwT1FodihfVaM';

  // PIN Settings
  static const int pinLength = 4;
  static const int maxPinAttempts = 5;
  static const int pinLockoutMinutes = 15;

  // Staff roles (for profile creation and display)
  static const List<String> staffRoles = [
    'owner',
    'manager',
    'cashier',
    'blockman',
    'butchery_assistant',
  ];

  /// Display label for role (e.g. butchery_assistant -> "Butchery Assistant")
  static String roleDisplayLabel(String role) {
    switch (role) {
      case 'owner': return 'Owner';
      case 'manager': return 'Manager';
      case 'cashier': return 'Cashier';
      case 'blockman': return 'Blockman';
      case 'butchery_assistant': return 'Butchery Assistant';
      default: return role;
    }
  }

  // Roles allowed in Admin App (from blueprint Section 2)
  static const List<String> allowedRoles = ['owner', 'manager', 'blockman', 'butchery_assistant'];
  static const List<String> rejectedRoles = ['cashier'];

  /// Stock measurement precision: grams 1g, kg 3 decimal places (C6)
  static const int stockGramPrecision = 1;
  static const int stockKgDecimals = 3;

  // Stock thresholds
  static const double defaultShrinkageTolerance = 2.0;   // 2% before alert
  static const double weightVarianceTolerance = 2.0;     // 2% carcass variance
  static const double yieldTemplateDiffFlag = 5.0;       // 5% = suggest update

  // Breakdown balance tolerance
  static const double breakdownBalanceTolerance = 2.0;   // 2% unaccounted

  // Blockman performance star thresholds
  static const double stars5Min = 95.0;
  static const double stars4Min = 90.0;
  static const double stars3Min = 85.0;
  static const double stars2Min = 80.0;

  // Payroll
  static const double uifRate = 0.01;           // 1% employee UIF
  static const double overtimeMultiplier = 1.5; // weekday OT
  static const double sundayMultiplier = 2.0;   // Sunday pay
  static const double publicHolidayMultiplier = 2.0;
  static const double defaultDailyOvertimeAfter = 9.0;   // hours
  static const double defaultWeeklyOvertimeAfter = 45.0; // hours

  // BCEA Leave
  static const double annualLeavePerMonth = 1.75;  // days accrued per month
  static const double sickLeavePer36Months = 30.0;
  static const int familyLeavePerYear = 3;
  static const int awolPatternThreshold = 3;  // flag after 3 AWOL incidents

  // Business accounts
  static const int overdueYellowDays = 1;
  static const int overdueRedDays = 7;

  // Auto-report times (24hr)
  static const String dailyReportTime = '23:00';
  static const String weeklyReportDay = 'Monday';
  static const String weeklyReportTime = '06:00';
  static const int monthlyReportDay = 1;

  // Parked sales
  static const int parkSaleAutoVoidHours = 4;

  // VAT
  static const double vatStandard = 0.15;
  static const double vatZeroRated = 0.0;

  // Scale settings (Ishida)
  static const int ishdaWeightPrefix = 20;
  static const int ishdaPricePrefix = 21;
  static const int ishdaPluDigits = 4;

  // Event spike detection
  static const double eventSpikeMultiplier = 2.0;  // 200% of rolling average

  // South African minimum wage fallback (update annually)
  static const double minimumWagePerHour = 28.79;

  // Rolling averages
  static const int yieldRollingBreakdowns = 10;    // last 10 breakdowns
  static const int avgCostRollingPurchases = 5;    // last 5 purchases

  // Storage location names (default — owner can edit in settings)
  static const List<String> defaultStorageLocations = [
    'Display Fridge 1',
    'Display Fridge 2',
    'Display Fridge 3',
    'Walk-In Fridge',
    'Deep Freezer 1',
    'Deep Freezer 2',
    'Deep Freezer 3',
    'Deep Freezer 4',
    'Deep Freezer 5',
    'Deep Freezer 6',
    'Deep Freezer 7',
    'Deli Counter',
    'Dry Store',
    'Biltong Dryer',
  ];
}