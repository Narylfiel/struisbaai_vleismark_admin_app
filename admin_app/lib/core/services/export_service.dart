import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'base_service.dart';
import '../utils/app_constants.dart';

/// Service for exporting data in various formats (CSV, Excel, PDF)
class ExportService extends BaseService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  /// Export data to CSV format. When data is empty, writes file with header row only.
  Future<File> exportToCsv({
    required String fileName,
    required List<Map<String, dynamic>> data,
    required List<String> columns,
    String? delimiter,
  }) async {
    try {
      final csvData = <List<dynamic>>[];

      // Add headers (always — never skip when data is empty)
      csvData.add(columns);

      // Add data rows
      for (final row in data) {
        final csvRow = <dynamic>[];
        for (final column in columns) {
          final value = row[column];
          csvRow.add(_formatValueForCsv(value));
        }
        csvData.add(csvRow);
      }

      // Convert to CSV string (header + data, or header only when empty)
      final csvString = const ListToCsvConverter().convert(csvData);

      // Save to file — never return null or skip when data is empty
      final file = await _getExportFile(fileName, 'csv');
      await file.writeAsString(csvString);

      return file;
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }

  /// Export data to Excel format. When data is empty, writes file with header row only.
  Future<File> exportToExcel({
    required String fileName,
    required List<Map<String, dynamic>> data,
    required List<String> columns,
    Map<String, String>? columnHeaders,
    String sheetName = 'Sheet1',
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel[sheetName];

      // Add headers (always — never skip when data is empty)
      for (var col = 0; col < columns.length; col++) {
        final headerText = columnHeaders?[columns[col]] ?? columns[col];
        final headerCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        headerCell.value = TextCellValue(headerText);
        headerCell.cellStyle = CellStyle(bold: true, fontSize: 12);
      }

      // Add data rows (none when empty — header-only file is valid)
      for (var row = 0; row < data.length; row++) {
        for (var col = 0; col < columns.length; col++) {
          final value = data[row][columns[col]];
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1));
          cell.value = _formatValueForExcel(value);
        }
      }

      // Auto-fit columns
      for (var col = 0; col < columns.length; col++) {
        sheet.setColumnWidth(col, 15);
      }

      // Save to file — never return null or skip when data is empty
      final file = await _getExportFile(fileName, 'xlsx');
      await file.writeAsBytes(excel.encode()!);

      return file;
    } catch (e) {
      throw Exception('Failed to export Excel: $e');
    }
  }

  /// Export data to PDF format. When data is empty, renders full layout with
  /// headers and one row: 'No data available for the selected period.'
  Future<File> exportToPdf({
    required String fileName,
    required String title,
    required List<Map<String, dynamic>> data,
    required List<String> columns,
    Map<String, String>? columnHeaders,
    String? subtitle,
    Map<String, dynamic>? summary,
    String? businessName,
  }) async {
    try {
      String resolvedBusinessName = businessName ?? '';
      if (resolvedBusinessName.isEmpty) {
        try {
          final row = await client
              .from('business_settings')
              .select('setting_value')
              .eq('setting_key', 'business_name')
              .maybeSingle();
          if (row != null && row['setting_value'] != null) {
            resolvedBusinessName = row['setting_value'].toString();
          }
        } catch (_) {}
      }

      final pdf = pw.Document();
      final genDate = DateTime.now().toString().split('.')[0];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            _buildPdfHeader(title, subtitle),
            pw.SizedBox(height: 20),
            _buildPdfTable(data, columns, columnHeaders),
            if (summary != null && summary.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              _buildPdfSummary(summary),
            ],
          ],
          footer: (context) => pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Text(
              '${resolvedBusinessName.isNotEmpty ? '$resolvedBusinessName • ' : ''}Generated: $genDate',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ),
        ),
      );

      final file = await _getExportFile(fileName, 'pdf');
      await file.writeAsBytes(await pdf.save());

      return file;
    } catch (e) {
      throw Exception('Failed to export PDF: $e');
    }
  }

  /// Export inventory data
  Future<File> exportInventory({
    String format = 'excel',
    bool includeInactive = false,
  }) async {
    try {
      final query = !includeInactive
          ? client.from('inventory_items').select('*, categories(name)').eq('is_active', true).order('plu_code')
          : client.from('inventory_items').select('*, categories(name)').order('plu_code');

      final inventoryData = await executeQuery(() => query, operationName: 'Export inventory data');

      final data = List<Map<String, dynamic>>.from(inventoryData ?? []);
      final columns = ['plu_code', 'name', 'categories.name', 'current_stock', 'reorder_point', 'average_cost', 'total_value'];
      final headers = {
        'plu_code': 'PLU Code',
        'name': 'Product Name',
        'categories.name': 'Category',
        'current_stock': 'Current Stock',
        'reorder_point': 'Reorder Point',
        'average_cost': 'Avg Cost',
        'total_value': 'Total Value',
      };

      // Calculate total value
      for (final item in data) {
        final stock = item['current_stock'] as num? ?? 0;
        final cost = item['average_cost'] as num? ?? 0;
        item['total_value'] = stock * cost;
      }

      final fileName = 'inventory_export_${DateTime.now().toIso8601String().split('T')[0]}';

      switch (format) {
        case 'csv':
          return await exportToCsv(fileName: fileName, data: data, columns: columns);
        case 'excel':
          return await exportToExcel(fileName: fileName, data: data, columns: columns, columnHeaders: headers);
        case 'pdf':
          return await exportToPdf(
            fileName: fileName,
            title: 'Inventory Report',
            data: data,
            columns: columns,
            columnHeaders: headers,
            subtitle: 'Generated on ${DateTime.now().toString().split('T')[0]}',
          );
        default:
          throw Exception('Unsupported format: $format');
      }
    } catch (e) {
      throw Exception('Failed to export inventory: $e');
    }
  }

  /// Export transactions data (blueprint: transactions + transaction_items).
  Future<File> exportSales({
    required DateTime startDate,
    required DateTime endDate,
    String format = 'excel',
  }) async {
    try {
      final txnData = await executeQuery(
        () => client
            .from('transactions')
            .select('*, transaction_items(quantity, unit_price, line_total, inventory_items(name))')
            .gte('created_at', startDate.toIso8601String())
            .lte('created_at', endDate.toIso8601String())
            .order('created_at'),
        operationName: 'Export transactions data',
      );

      final data = List<Map<String, dynamic>>.from(txnData ?? []);
      final columns = ['created_at', 'total_amount', 'payment_method', 'items_count'];
      final headers = {
        'created_at': 'Date/Time',
        'total_amount': 'Total Amount',
        'payment_method': 'Payment Method',
        'items_count': 'Items Count',
      };

      for (final txn in data) {
        final items = txn['transaction_items'] as List? ?? [];
        txn['items_count'] = items.length;
        txn['created_at'] = DateTime.parse(txn['created_at']).toLocal().toString();
      }

      final fileName = 'transactions_export_${startDate.toIso8601String().split('T')[0]}_to_${endDate.toIso8601String().split('T')[0]}';

      switch (format) {
        case 'csv':
          return await exportToCsv(fileName: fileName, data: data, columns: columns);
        case 'excel':
          return await exportToExcel(fileName: fileName, data: data, columns: columns, columnHeaders: headers);
        case 'pdf':
          final summary = {
            'Total Sales': data.fold<double>(0, (sum, txn) => sum + (txn['total_amount'] as num? ?? 0)),
            'Total Transactions': data.length,
            'Average Transaction': data.isNotEmpty
                ? data.fold<double>(0, (sum, txn) => sum + (txn['total_amount'] as num? ?? 0)) / data.length
                : 0,
          };

          return await exportToPdf(
            fileName: fileName,
            title: 'Transactions Report',
            subtitle: '${startDate.toString().split('T')[0]} to ${endDate.toString().split('T')[0]}',
            data: data,
            columns: columns,
            columnHeaders: headers,
            summary: summary,
          );
        default:
          throw Exception('Unsupported format: $format');
      }
    } catch (e) {
      throw Exception('Failed to export transactions: $e');
    }
  }

  /// Export staff payroll data
  Future<File> exportPayroll({
    required String payrollPeriodId,
    String format = 'excel',
  }) async {
    try {
      final payrollData = await executeQuery(
        () => client
            .from('payroll_entries')
            .select('*, profiles(full_name)')
            .eq('payroll_period_id', payrollPeriodId),
        operationName: 'Export payroll data',
      );

      final data = List<Map<String, dynamic>>.from(payrollData ?? []);
      final columns = ['profiles.full_name', 'basic_salary', 'overtime_amount', 'gross_pay', 'total_deductions', 'net_pay'];
      final headers = {
        'profiles.full_name': 'Staff Name',
        'basic_salary': 'Basic Salary',
        'overtime_amount': 'Overtime',
        'gross_pay': 'Gross Pay',
        'total_deductions': 'Deductions',
        'net_pay': 'Net Pay',
      };

      final fileName = 'payroll_export_$payrollPeriodId';

      switch (format) {
        case 'csv':
          return await exportToCsv(fileName: fileName, data: data, columns: columns);
        case 'excel':
          return await exportToExcel(fileName: fileName, data: data, columns: columns, columnHeaders: headers);
        case 'pdf':
          final summary = {
            'Total Staff': data.length,
            'Total Gross Pay': data.fold<double>(0, (sum, entry) => sum + (entry['gross_pay'] as num? ?? 0)),
            'Total Deductions': data.fold<double>(0, (sum, entry) => sum + (entry['total_deductions'] as num? ?? 0)),
            'Total Net Pay': data.fold<double>(0, (sum, entry) => sum + (entry['net_pay'] as num? ?? 0)),
          };

          return await exportToPdf(
            fileName: fileName,
            title: 'Payroll Report',
            data: data,
            columns: columns,
            columnHeaders: headers,
            summary: summary,
          );
        default:
          throw Exception('Unsupported format: $format');
      }
    } catch (e) {
      throw Exception('Failed to export payroll: $e');
    }
  }

  /// Save CSV to Downloads folder (or save-file dialog on Windows). Returns path for SnackBar, or null if cancelled.
  Future<String?> saveCsvToFile({
    required String suggestedFileName,
    required List<Map<String, dynamic>> data,
    required List<String> columns,
  }) async {
    final csvData = <List<dynamic>>[];
    csvData.add(columns);
    for (final row in data) {
      final csvRow = <dynamic>[];
      for (final column in columns) {
        csvRow.add(_formatValueForCsv(row[column]));
      }
      csvData.add(csvRow);
    }
    final csvString = const ListToCsvConverter().convert(csvData);
    final bytes = utf8.encode(csvString);

    if (Platform.isWindows) {
      final path = await FilePicker.platform.saveFile(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        fileName: suggestedFileName.endsWith('.csv') ? suggestedFileName : '$suggestedFileName.csv',
      );
      if (path == null) return null;
      final file = File(path);
      await file.writeAsBytes(bytes);
      return path;
    }
    final dir = await getDownloadsDirectory();
    if (dir == null) return null;
    final fileName = suggestedFileName.endsWith('.csv') ? suggestedFileName : '$suggestedFileName.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Share exported file
  Future<void> shareFile(File file, String title) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: title,
      );
    } catch (e) {
      throw Exception('Failed to share file: $e');
    }
  }

  /// Get list of available export formats
  List<String> getAvailableFormats() {
    return AppConstants.supportedExportFormats;
  }

  // Helper methods

  String _formatValueForCsv(dynamic value) {
    if (value == null) return '';
    final stringValue = value.toString();

    // Escape quotes and wrap in quotes if contains comma, quote, or newline
    if (stringValue.contains(',') || stringValue.contains('"') || stringValue.contains('\n')) {
      return '"${stringValue.replaceAll('"', '""')}"';
    }

    return stringValue;
  }

  CellValue? _formatValueForExcel(dynamic value) {
    if (value == null) return TextCellValue('');

    if (value is DateTime) {
      return TextCellValue(value.toIso8601String().split('T')[0]);
    }
    if (value is int) {
      return IntCellValue(value);
    }
    if (value is double) {
      return DoubleCellValue(value);
    }
    return TextCellValue(value.toString());
  }

  pw.Widget _buildPdfHeader(String title, String? subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        if (subtitle != null) ...[
          pw.SizedBox(height: 8),
          pw.Text(subtitle, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        ],
        pw.Text('Generated: ${DateTime.now().toString().split('T')[0]}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
      ],
    );
  }

  pw.Widget _buildPdfTable(List<Map<String, dynamic>> data, List<String> columns, Map<String, String>? headers) {
    final headerTexts = columns.map((col) => headers?[col] ?? col).toList();
    final tableData = data.isEmpty
        ? [
            ['No data available for the selected period.', ...List.generate(columns.length > 1 ? columns.length - 1 : 0, (_) => '')],
          ]
        : data.map((row) => columns.map((col) => _formatValueForPdf(row[col])).toList()).toList();

    return pw.Table.fromTextArray(
      headers: headerTexts,
      data: tableData,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 20,
      columnWidths: Map.fromEntries(
        columns.asMap().entries.map((e) => MapEntry(e.key, const pw.FlexColumnWidth(1))),
      ),
    );
  }

  pw.Widget _buildPdfSummary(Map<String, dynamic> summary) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Summary', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          ...summary.entries.map((entry) => pw.Text('${entry.key}: ${entry.value}',
              style: const pw.TextStyle(fontSize: 10))),
        ],
      ),
    );
  }

  String _formatValueForPdf(dynamic value) {
    if (value == null) return '';
    if (value is num) return value.toStringAsFixed(2);
    if (value is DateTime) return value.toString().split('T')[0];
    return value.toString();
  }

  Future<File> _getExportFile(String fileName, String extension) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fullFileName = '${fileName}_$timestamp.$extension';
    return File('${directory.path}/$fullFileName');
  }
}