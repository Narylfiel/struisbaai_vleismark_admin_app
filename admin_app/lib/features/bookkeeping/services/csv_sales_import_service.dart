import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

class CsvSalesLine {
  final int pluCode;
  final String pluName;
  final double qty;
  final double totalIncl;
  // Set after PLU matching:
  String? inventoryItemId;
  String? unitType;
  bool matched = false;

  CsvSalesLine({
    required this.pluCode,
    required this.pluName,
    required this.qty,
    required this.totalIncl,
  });
}

class CsvImportResult {
  final int imported;
  final int skipped;
  final List<CsvSalesLine> skippedLines;
  final DateTime importDate;

  const CsvImportResult({
    required this.imported,
    required this.skipped,
    required this.skippedLines,
    required this.importDate,
  });
}

class CsvSalesImportService {
  final SupabaseClient _client;

  CsvSalesImportService({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  DateTime? parseDateFromFilename(String filename) {
    try {
      // Remove extension first
      final nameOnly = filename.contains('.')
          ? filename.substring(0, filename.lastIndexOf('.'))
          : filename;

      // Split on underscore or space
      final parts = nameOnly.split(RegExp(r'[_\s]+'));

      if (parts.length < 3) return null;

      final dd = int.parse(parts[0]);
      final mm = int.parse(parts[1]);
      final yy = int.parse(parts[2]);
      final year = 2000 + yy;

      return DateTime(year, mm, dd);
    } catch (e) {
      return null;
    }
  }

  // Parse CSV content into sales lines
  List<CsvSalesLine> parseCsv(String content) {
    final lines = content.split('\n');
    if (lines.isEmpty) return [];

    // Find header row
    final header = lines.first
        .split(',')
        .map((h) => h.trim().toLowerCase())
        .toList();

    final pluIndex = header.indexWhere((h) => h == 'plu no');
    final nameIndex = header.indexWhere((h) => h == 'plu name');
    final qtyIndex = header.indexWhere((h) => h == 'qty');
    final totalIndex =
        header.indexWhere((h) => h.contains('total inc'));

    if (pluIndex < 0 || qtyIndex < 0) return [];

    final result = <CsvSalesLine>[];

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final cols = line.split(',');
      if (cols.length <= qtyIndex) continue;

      try {
        final rawPlu = cols[pluIndex].trim();
        // Strip 'P' prefix and leading zeros: P002001 → 2001
        final pluStr = rawPlu
            .replaceFirst(RegExp(r'^P0*'), '');
        final pluCode = int.parse(pluStr);

        final pluName = nameIndex >= 0 && nameIndex < cols.length
            ? cols[nameIndex].trim()
            : 'Unknown';

        final qty =
            double.tryParse(cols[qtyIndex].trim()) ?? 0;
        if (qty <= 0) continue;

        final totalIncl = totalIndex >= 0 &&
                totalIndex < cols.length
            ? double.tryParse(cols[totalIndex].trim()) ?? 0
            : 0.0;

        result.add(CsvSalesLine(
          pluCode: pluCode,
          pluName: pluName,
          qty: qty,
          totalIncl: totalIncl,
        ));
      } catch (_) {
        continue;
      }
    }

    // Deduplicate PLU codes — some exports contain
    // duplicate rows. Take first occurrence only.
    final Map<int, CsvSalesLine> deduped = {};
    for (final line in result) {
      deduped.putIfAbsent(line.pluCode, () => line);
    }
    return deduped.values.toList();
  }

  // Match PLU codes to inventory items
  Future<List<CsvSalesLine>> matchPlus(
      List<CsvSalesLine> lines) async {
    // Get all inventory items with plu_code
    final response = await _client
        .from('inventory_items')
        .select('id, plu_code, unit_type')
        .not('plu_code', 'is', null);

    final items = response as List<dynamic>;
    final pluMap = <int, Map<String, dynamic>>{};
    for (final item in items) {
      final plu = item['plu_code'];
      if (plu != null) {
        pluMap[plu as int] = item as Map<String, dynamic>;
      }
    }

    for (final line in lines) {
      final match = pluMap[line.pluCode];
      if (match != null) {
        line.inventoryItemId = match['id'] as String;
        line.unitType = match['unit_type'] as String? ?? 'kg';
        line.matched = true;
      }
    }

    return lines;
  }

  // Check if this file has already been imported
  Future<DateTime?> checkAlreadyImported(
      String filenameWithoutExtension) async {
    final response = await _client
        .from('stock_movements')
        .select('created_at')
        .eq('reference_type', 'csv_import')
        .eq('reference_id', filenameWithoutExtension)
        .limit(1);

    final list = response as List<dynamic>;
    if (list.isEmpty) return null;

    final raw = list.first['created_at'] as String?;
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  // Import matched lines as stock movements
  Future<CsvImportResult> importLines({
    required List<CsvSalesLine> lines,
    required DateTime date,
    required String filename,
  }) async {
    final refId = filename.contains('.')
        ? filename.substring(0, filename.lastIndexOf('.'))
        : filename;

    // Created_at: end of that trading day SAST
    final createdAt = DateTime(
      date.year,
      date.month,
      date.day,
      21, // 23:59 SAST = 21:59 UTC
      59,
    ).toUtc().toIso8601String();

    final matched = lines.where((l) => l.matched).toList();
    final skipped = lines.where((l) => !l.matched).toList();

    final movements = matched
        .map((line) => {
              'line_id': 'csv-$refId-${line.pluCode}-${line.qty.toStringAsFixed(3)}',
              'item_id': line.inventoryItemId,
              'movement_type': 'out',
              'reference_type': 'csv_import',
              'reference_id': refId,
              'quantity': -(line.qty),
              'unit_type': line.unitType ?? 'kg',
              'notes': 'Imported from $filename',
              'created_at': createdAt,
              'metadata': {
                'plu_code': line.pluCode,
                'plu_name': line.pluName,
                'original_qty': line.qty,
                'total_incl': line.totalIncl,
                'import_source': 'csv_import',
              },
            })
        .toList();

    if (movements.isNotEmpty) {
      await _client.from('stock_movements').insert(movements);
    }

    return CsvImportResult(
      imported: movements.length,
      skipped: skipped.length,
      skippedLines: skipped,
      importDate: date,
    );
  }
}
