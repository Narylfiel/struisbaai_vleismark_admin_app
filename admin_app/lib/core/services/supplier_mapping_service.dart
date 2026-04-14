import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages supplier item mappings — remembers how each supplier
/// line item description maps to a COA account and optionally
/// an inventory item for stock updates.
class SupplierMappingService {
  static final SupplierMappingService _instance =
      SupplierMappingService._internal();
  factory SupplierMappingService() => _instance;
  SupplierMappingService._internal();

  final _client = Supabase.instance.client;

  // ── Lookup ────────────────────────────────────────────────────

  /// Find mapping for a line item description.
  /// Tries supplier-specific match first, then global match.
  Future<SupplierItemMapping?> findMapping({
    required String description,
    String? supplierId,
  }) async {
    final normalized = description.toLowerCase().trim();

    // Try supplier-specific match first
    if (supplierId != null) {
      final result = await _client
          .from('supplier_item_mappings')
          .select()
          .eq('supplier_id', supplierId)
          .eq('description_normalized', normalized)
          .maybeSingle();
      if (result != null) return SupplierItemMapping.fromJson(result);
    }

    // Fall back to global match (no supplier_id)
    final result = await _client
        .from('supplier_item_mappings')
        .select()
        .isFilter('supplier_id', null)
        .eq('description_normalized', normalized)
        .maybeSingle();
    if (result != null) return SupplierItemMapping.fromJson(result);

    return null;
  }

  /// Find similar existing mappings using word overlap scoring.
  Future<List<Map<String, dynamic>>> findSimilarMappings({
    required String description,
    String? supplierId,
    int limit = 3,
  }) async {
    try {
      final normalized = description.toLowerCase().trim();

      var query = _client
          .from('supplier_item_mappings')
          .select('*, chart_of_accounts!inner(code, name)');

      final all = List<Map<String, dynamic>>.from(await query);

      double score(String a, String b) {
        final aWords = a.toLowerCase().split(' ').toSet();
        final bWords = b.toLowerCase().split(' ').toSet();
        final intersection = aWords.intersection(bWords).length;
        final union = aWords.union(bWords).length;
        return union == 0 ? 0 : intersection / union;
      }

      final scored = all
          .map((row) => {
                'mapping': row,
                'score': score(
                    normalized,
                    (row['description_normalized'] as String? ??
                        '')),
              })
          .where((e) => (e['score'] as double) > 0.3)
          .toList();

      scored.sort((a, b) => (b['score'] as double)
          .compareTo(a['score'] as double));

      return scored
          .take(limit)
          .map((e) => e['mapping'] as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('[MAPPING] findSimilarMappings error: $e');
      return [];
    }
  }

  /// Apply mappings to all line items in an invoice.
  /// Returns list of MappedLineItem — each either mapped or pending.
  Future<List<MappedLineItem>> applyMappings({
    required List<Map<String, dynamic>> lineItems,
    String? supplierId,
  }) async {
    final results = <MappedLineItem>[];
    for (final item in lineItems) {
      final description = item['description']?.toString() ?? '';
      final mapping = await findMapping(
        description: description,
        supplierId: supplierId,
      );
      results.add(MappedLineItem(
        description: description,
        supplierCode: item['supplier_code']?.toString(),
        quantity: _toDouble(item['quantity']) ?? 1,
        unitPrice: _toDouble(item['unit_price']) ?? 0,
        lineTotal: _toDouble(item['line_total']) ?? 0,
        mapping: mapping,
        isPending: mapping == null,
      ));
    }
    return results;
  }

  // ── Save mapping ──────────────────────────────────────────────

  /// Save or update a mapping for a supplier item description.
  Future<SupplierItemMapping> saveMapping({
    required String supplierDescription,
    required String accountCode,
    String? supplierId,
    String? inventoryItemId,
    bool updateStock = false,
    String? unitOfMeasure,
    String? notes,
    String? createdBy,
  }) async {
    final data = {
      'supplier_description': supplierDescription.trim(),
      'account_code': accountCode,
      'supplier_id': supplierId,
      'inventory_item_id': inventoryItemId,
      'update_stock': updateStock,
      'unit_of_measure': unitOfMeasure,
      'notes': notes,
      'created_by': createdBy,
    };

    final result = await _client
        .from('supplier_item_mappings')
        .upsert(data, onConflict: 'supplier_id,description_normalized')
        .select()
        .single();

    return SupplierItemMapping.fromJson(result);
  }

  /// Delete a mapping by ID.
  Future<void> deleteMapping(String id) async {
    await _client
        .from('supplier_item_mappings')
        .delete()
        .eq('id', id);
  }

  // ── List all mappings ─────────────────────────────────────────

  Future<List<SupplierItemMapping>> getAllMappings({
    String? supplierId,
  }) async {
    var query = _client
        .from('supplier_item_mappings')
        .select('*, chart_of_accounts(code, name), inventory_items(name)');

    if (supplierId != null) {
      query = query.eq('supplier_id', supplierId);
    }

    final result = await query.order('supplier_description');
    return (result as List)
        .map((e) => SupplierItemMapping.fromJson(e))
        .toList();
  }

  // ── COA helper ────────────────────────────────────────────────

  /// Get all active chart of accounts for dropdown.
  Future<List<CoaAccount>> getChartOfAccounts() async {
    final result = await _client
        .from('chart_of_accounts')
        .select('code, name, account_type')
        .eq('is_active', true)
        .order('code');
    return (result as List).map((e) => CoaAccount.fromJson(e)).toList();
  }

  // ── Helpers ───────────────────────────────────────────────────

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

// ── Data classes ──────────────────────────────────────────────────

class SupplierItemMapping {
  final String id;
  final String? supplierId;
  final String supplierDescription;
  final String accountCode;
  final String? accountName;
  final String? inventoryItemId;
  final String? inventoryItemName;
  final bool updateStock;
  final String? unitOfMeasure;
  final String? notes;
  final DateTime? createdAt;

  const SupplierItemMapping({
    required this.id,
    this.supplierId,
    required this.supplierDescription,
    required this.accountCode,
    this.accountName,
    this.inventoryItemId,
    this.inventoryItemName,
    required this.updateStock,
    this.unitOfMeasure,
    this.notes,
    this.createdAt,
  });

  factory SupplierItemMapping.fromJson(Map<String, dynamic> json) {
    final coa = json['chart_of_accounts'] as Map?;
    final inv = json['inventory_items'] as Map?;
    return SupplierItemMapping(
      id: json['id'].toString(),
      supplierId: json['supplier_id']?.toString(),
      supplierDescription: json['supplier_description'].toString(),
      accountCode: json['account_code'].toString(),
      accountName: coa?['name']?.toString(),
      inventoryItemId: json['inventory_item_id']?.toString(),
      inventoryItemName: inv?['name']?.toString(),
      updateStock: json['update_stock'] == true,
      unitOfMeasure: json['unit_of_measure']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// Whether this mapping updates inventory stock.
  bool get isInventory => updateStock && inventoryItemId != null;

  /// Whether this mapping posts to an expense account.
  bool get isExpense {
    final code = int.tryParse(accountCode) ?? 0;
    return code >= 5000;
  }

  /// Whether this mapping posts to an asset account.
  bool get isAsset {
    final code = int.tryParse(accountCode) ?? 0;
    return code >= 1000 && code < 2000;
  }
}

class MappedLineItem {
  final String description;
  final String? supplierCode;
  final double quantity;
  final double unitPrice;
  final double lineTotal;
  final SupplierItemMapping? mapping;
  final bool isPending;

  const MappedLineItem({
    required this.description,
    this.supplierCode,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.mapping,
    required this.isPending,
  });

  /// Display label for the mapped destination.
  String get mappingLabel {
    if (isPending) return 'Needs mapping';
    final m = mapping!;
    if (m.isInventory) return 'Stock: ${m.inventoryItemName ?? m.accountCode}';
    return 'Account: ${m.accountCode} ${m.accountName ?? ''}';
  }
}

class CoaAccount {
  final String code;
  final String name;
  final String accountType;

  const CoaAccount({
    required this.code,
    required this.name,
    required this.accountType,
  });

  factory CoaAccount.fromJson(Map<String, dynamic> json) => CoaAccount(
        code: json['code'].toString(),
        name: json['name'].toString(),
        accountType: json['account_type'].toString(),
      );

  String get displayName => '$code — $name';
}
