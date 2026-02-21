/// Application-wide constants and configuration values
class AppConstants {
  // Screen sizes
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1200;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // File sizes
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxDocumentSizeBytes = 10 * 1024 * 1024; // 10MB

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration cacheTimeout = Duration(hours: 24);

  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  // Date formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'dd/MM/yyyy';
  static const String displayDateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Currency
  static const String currencySymbol = 'R';
  static const String currencyCode = 'ZAR';
  static const int decimalPlaces = 2;

  // Validation
  static const int minPasswordLength = 4; // For PIN
  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 500;

  // Stock thresholds
  static const double lowStockThreshold = 0.1; // 10%
  static const double criticalStockThreshold = 0.05; // 5%

  // Business rules
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);

  // Export formats
  static const List<String> supportedExportFormats = ['PDF', 'Excel', 'CSV'];

  // Notification types
  static const String notificationTypeInfo = 'info';
  static const String notificationTypeWarning = 'warning';
  static const String notificationTypeError = 'error';
  static const String notificationTypeSuccess = 'success';
}