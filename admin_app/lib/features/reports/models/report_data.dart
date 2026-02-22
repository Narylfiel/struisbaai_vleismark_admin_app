/// Blueprint §11: Unified report payload for view and export (CSV, PDF, Excel).
class ReportData {
  final List<Map<String, dynamic>> data;
  final List<String> columns;
  final Map<String, String> columnHeaders;
  final Map<String, dynamic>? summary;
  final String title;
  final String? subtitle;

  const ReportData({
    required this.data,
    required this.columns,
    required this.columnHeaders,
    this.summary,
    required this.title,
    this.subtitle,
  });
}
