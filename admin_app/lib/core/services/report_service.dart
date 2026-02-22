import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'base_service.dart';
import '../utils/app_constants.dart';

/// Service for generating reports in PDF and Excel formats
class ReportService extends BaseService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  /// Generate PDF report
  Future<File> generatePdfReport({
    required String title,
    required List<Map<String, dynamic>> data,
    required List<String> columns,
    Map<String, dynamic>? summary,
    String? subtitle,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            _buildPdfHeader(title, subtitle),
            pw.SizedBox(height: 20),
            _buildPdfTable(data, columns),
            if (summary != null) ...[
              pw.SizedBox(height: 20),
              _buildPdfSummary(summary),
            ],
          ],
        ),
      );

      final output = await _getOutputFile(title, 'pdf');
      await output.writeAsBytes(await pdf.save());
      return output;
    } catch (e) {
      throw Exception('Failed to generate PDF: $e');
    }
  }

  /// Generate Excel report
  Future<File> generateExcelReport({
    required String title,
    required List<Map<String, dynamic>> data,
    required List<String> columns,
    Map<String, dynamic>? summary,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel[excel.getDefaultSheet()!];

      // Add title
      final titleCell = sheet.cell(CellIndex.indexByString('A1'));
      titleCell.value = TextCellValue(title);
      titleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
      );

      // Add headers
      for (var i = 0; i < columns.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(
          columnIndex: i,
          rowIndex: 2,
        ));
        cell.value = TextCellValue(columns[i]);
        cell.cellStyle = CellStyle(bold: true);
      }

      // Add data
      for (var row = 0; row < data.length; row++) {
        for (var col = 0; col < columns.length; col++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: col,
            rowIndex: row + 3,
          ));
          cell.value = TextCellValue(data[row][columns[col]]?.toString() ?? '');
        }
      }

      // Add summary if provided
      if (summary != null) {
        final summaryRow = data.length + 5;
        final summaryLabelCell = sheet.cell(CellIndex.indexByColumnRow(
          columnIndex: 0,
          rowIndex: summaryRow,
        ));
        summaryLabelCell.value = TextCellValue('Summary');
        summaryLabelCell.cellStyle = CellStyle(bold: true);

        var summaryIndex = 1;
        summary.forEach((key, value) {
          sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: summaryIndex,
            rowIndex: summaryRow,
          )).value = TextCellValue('$key: $value');
          summaryIndex++;
        });
      }

      final output = await _getOutputFile(title, 'xlsx');
      await output.writeAsBytes(excel.encode()!);
      return output;
    } catch (e) {
      throw Exception('Failed to generate Excel: $e');
    }
  }

  /// Generate CSV report
  Future<File> generateCsvReport({
    required String title,
    required List<Map<String, dynamic>> data,
    required List<String> columns,
  }) async {
    try {
      final buffer = StringBuffer();

      // Add headers
      buffer.writeln(columns.join(','));

      // Add data
      for (final row in data) {
        final values = columns.map((col) {
          final value = row[col]?.toString() ?? '';
          // Escape commas and quotes in CSV
          if (value.contains(',') || value.contains('"') || value.contains('\n')) {
            return '"${value.replaceAll('"', '""')}"';
          }
          return value;
        });
        buffer.writeln(values.join(','));
      }

      final output = await _getOutputFile(title, 'csv');
      await output.writeAsString(buffer.toString());
      return output;
    } catch (e) {
      throw Exception('Failed to generate CSV: $e');
    }
  }

  /// Share generated report
  Future<void> shareReport(File reportFile, String title) async {
    try {
      await Share.shareXFiles(
        [XFile(reportFile.path)],
        subject: title,
      );
    } catch (e) {
      throw Exception('Failed to share report: $e');
    }
  }

  /// Generate transactions report (blueprint §11: Daily/Weekly Sales from transactions).
  Future<File> generateSalesReport({
    required DateTime startDate,
    required DateTime endDate,
    String format = 'pdf',
  }) async {
    try {
      final txnData = await executeQuery(
        () => client
            .from('transactions')
            .select('''
              *,
              transaction_items (
                quantity,
                unit_price,
                line_total,
                inventory_items (name, category)
              )
            ''')
            .gte('created_at', startDate.toIso8601String())
            .lte('created_at', endDate.toIso8601String()),
        operationName: 'Fetch transactions data for report',
      );

      final data = List<Map<String, dynamic>>.from(txnData ?? []);
      final columns = ['Date', 'Total Amount', 'Items Count', 'Payment Method'];

      final processedData = data.map((txn) {
        final items = txn['transaction_items'] as List? ?? [];
        return {
          'Date': DateTime.parse(txn['created_at']).toString().split('T')[0],
          'Total Amount': txn['total_amount']?.toString() ?? '0',
          'Items Count': items.length.toString(),
          'Payment Method': txn['payment_method'] ?? 'Unknown',
        };
      }).toList();

      final summary = {
        'Total Sales': data.fold<double>(0, (sum, txn) => sum + (txn['total_amount'] as num? ?? 0)),
        'Total Transactions': data.length,
        'Average Transaction': data.isNotEmpty
            ? data.fold<double>(0, (sum, txn) => sum + (txn['total_amount'] as num? ?? 0)) / data.length
            : 0,
      };

      switch (format.toLowerCase()) {
        case 'pdf':
          return await generatePdfReport(
            title: 'Transactions Report',
            subtitle: '${startDate.toString().split('T')[0]} to ${endDate.toString().split('T')[0]}',
            data: processedData,
            columns: columns,
            summary: summary,
          );
        case 'excel':
          return await generateExcelReport(
            title: 'Transactions Report',
            data: processedData,
            columns: columns,
            summary: summary,
          );
        case 'csv':
          return await generateCsvReport(
            title: 'Transactions Report',
            data: processedData,
            columns: columns,
          );
        default:
          throw Exception('Unsupported format: $format');
      }
    } catch (e) {
      throw Exception('Failed to generate transactions report: $e');
    }
  }

  /// Generate inventory report
  Future<File> generateInventoryReport({String format = 'pdf'}) async {
    try {
      final inventoryData = await executeQuery(
        () => client
            .from('inventory_items')
            .select('*, categories(name)')
            .eq('is_active', true)
            .order('name'),
        operationName: 'Fetch inventory data for report',
      );

      final data = List<Map<String, dynamic>>.from(inventoryData ?? []);
      final columns = ['PLU', 'Name', 'Category', 'Current Stock', 'Unit Cost', 'Total Value'];

      final processedData = data.map((item) {
        final stock = item['current_stock'] as num? ?? 0;
        final cost = item['average_cost'] as num? ?? 0;
        return {
          'PLU': item['plu_code'] ?? '',
          'Name': item['name'] ?? '',
          'Category': item['categories']?['name'] ?? 'Uncategorized',
          'Current Stock': stock.toString(),
          'Unit Cost': cost.toStringAsFixed(2),
          'Total Value': (stock * cost).toStringAsFixed(2),
        };
      }).toList();

      final totalValue = processedData.fold<double>(0, (sum, item) {
        return sum + double.tryParse(item['Total Value'] ?? '0')!;
      });

      final summary = {
        'Total Items': data.length,
        'Total Value': totalValue.toStringAsFixed(2),
        'Low Stock Items': data.where((item) => (item['current_stock'] as num? ?? 0) <= (item['reorder_point'] as num? ?? 0)).length,
      };

      switch (format.toLowerCase()) {
        case 'pdf':
          return await generatePdfReport(
            title: 'Inventory Report',
            data: processedData,
            columns: columns,
            summary: summary,
          );
        case 'excel':
          return await generateExcelReport(
            title: 'Inventory Report',
            data: processedData,
            columns: columns,
            summary: summary,
          );
        case 'csv':
          return await generateCsvReport(
            title: 'Inventory Report',
            data: processedData,
            columns: columns,
          );
        default:
          throw Exception('Unsupported format: $format');
      }
    } catch (e) {
      throw Exception('Failed to generate inventory report: $e');
    }
  }

  // Helper methods

  pw.Widget _buildPdfHeader(String title, String? subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        if (subtitle != null) ...[
          pw.SizedBox(height: 8),
          pw.Text(subtitle, style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
        ],
        pw.Text('Generated on ${DateTime.now().toString().split('T')[0]}',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
      ],
    );
  }

  pw.Widget _buildPdfTable(List<Map<String, dynamic>> data, List<String> columns) {
    return pw.Table.fromTextArray(
      headers: columns,
      data: data.map((row) => columns.map((col) => row[col]?.toString() ?? '').toList()).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 25,
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
          pw.Text('Summary', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          ...summary.entries.map((entry) => pw.Text('${entry.key}: ${entry.value}')),
        ],
      ),
    );
  }

  Future<File> _getOutputFile(String title, String extension) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${title.replaceAll(' ', '_')}_$timestamp.$extension';
    return File('${directory.path}/$fileName');
  }
}