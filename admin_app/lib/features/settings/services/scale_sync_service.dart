import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScaleSyncResult {
  final bool success;
  final String message;
  final int itemCount;
  const ScaleSyncResult({
    required this.success,
    required this.message,
    required this.itemCount,
  });
}

class ScaleSyncService {
  final SupabaseClient client;
  const ScaleSyncService({required this.client});

  /// Fetch all active scale items, generate Update.csv in Capitec
  /// ScaleLink Pro format, write to [outputPath]/Update.csv,
  /// then trigger send.bat.
  Future<ScaleSyncResult> generateAndSend({
    required String outputPath,
    void Function(String)? onStatus,
  }) async {
    onStatus?.call('Fetching scale items from database...');

    // Fetch all active scale items
    final rows = await client
        .from('inventory_items')
        .select('plu_code, sell_price, scale_shelf_life, '
            'scale_label_name, name')
        .eq('scale_item', true)
        .eq('is_active', true)
        .order('plu_code');

    final items = rows as List;
    if (items.isEmpty) {
      return const ScaleSyncResult(
        success: false,
        message: 'No active scale items found. '
            'Mark products as scale items in the product form.',
        itemCount: 0,
      );
    }

    onStatus?.call('Generating Update.csv (${items.length} items)...');

    // Build CSV content — exact Capitec ScaleLink Pro format
    // Header: "Plu_No","UnitPrice","ShelfLife","SalesMode",
    //         "DateFlag","Posflag","BarCodeNum","ItemCode","Desc"
    final buffer = StringBuffer();
    buffer.writeln(
      '"Plu_No","UnitPrice","ShelfLife","SalesMode",'
      '"DateFlag","Posflag","BarCodeNum","ItemCode","Desc"',
    );

    for (final item in items) {
      final pluRaw = item['plu_code'];
      final plu = pluRaw?.toString() ?? '';
      // Zero-pad PLU to 4 digits
      final pluPadded = plu.padLeft(4, '0');

      // Price — format to 2 decimal places
      final priceRaw = item['sell_price'];
      final price = double.tryParse(priceRaw?.toString() ?? '0') ?? 0.0;
      final priceStr = price.toStringAsFixed(2);

      // Shelf life — 3-digit zero-padded, default 005
      final shelfRaw = item['scale_shelf_life'] as int?;
      final shelf = (shelfRaw ?? 5).toString().padLeft(3, '0');

      // Desc — scale label name; strip quotes to keep CSV valid
      final desc = (item['scale_label_name'] as String? ?? '').replaceAll('"', "'");

      buffer.writeln(
        '"$pluPadded","$priceStr","$shelf","0","","","","$pluPadded","$desc"',
      );
    }

    // Normalise path separators for Windows
    final normPath = outputPath.replaceAll('/', '\\');
    final csvPath = '$normPath\\Update.csv';
    final batPath = '$normPath\\send.bat';

    onStatus?.call('Writing $csvPath...');

    try {
      final file = File(csvPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(buffer.toString());
    } catch (e) {
      return ScaleSyncResult(
        success: false,
        message: 'Failed to write Update.csv: ${e.toString()}\n'
            'Check that the ScaleLink path is correct and accessible.',
        itemCount: items.length,
      );
    }

    // Check send.bat exists
    final bat = File(batPath);
    if (!await bat.exists()) {
      return ScaleSyncResult(
        success: false,
        message: 'Update.csv written successfully (${items.length} items) '
            'but send.bat not found at $batPath.\n'
            'Copy ScaleLink Pro to $normPath and try again.',
        itemCount: items.length,
      );
    }

    onStatus?.call('Triggering ScaleLink Pro (send.bat)...');

    try {
      final result = await Process.run(
        'cmd',
        ['/c', batPath],
        workingDirectory: normPath,
      );

      if (result.exitCode == 0) {
        return ScaleSyncResult(
          success: true,
          message: '✓ ${items.length} item(s) sent to scale successfully.',
          itemCount: items.length,
        );
      } else {
        final stderr = result.stderr?.toString() ?? '';
        final stdout = result.stdout?.toString() ?? '';
        return ScaleSyncResult(
          success: false,
          message: 'send.bat exited with code ${result.exitCode}.\n'
              '${stderr.isNotEmpty ? stderr : stdout}',
          itemCount: items.length,
        );
      }
    } catch (e) {
      return ScaleSyncResult(
        success: false,
        message: 'Failed to run send.bat: ${e.toString()}',
        itemCount: items.length,
      );
    }
  }
}
