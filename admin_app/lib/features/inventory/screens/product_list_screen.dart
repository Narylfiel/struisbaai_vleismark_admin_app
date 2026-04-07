import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/db/cached_category.dart';
import 'package:admin_app/core/db/cached_inventory_item.dart';
import 'package:admin_app/core/db/isar_service.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/core/services/auth_service.dart';
import 'package:admin_app/core/services/connectivity_service.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/audit_service.dart';
import 'package:admin_app/core/services/export_service.dart';
import 'package:admin_app/core/config/edge_pipeline_config.dart';
import 'package:admin_app/core/services/edge_pipeline_client.dart';
import 'package:admin_app/features/inventory/constants/category_mappings.dart';
import 'package:admin_app/features/inventory/widgets/stock_movement_dialogs.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, this.openInventoryItemId});

  /// When set (e.g. from dashboard pricing alert), opens the product form once after load.
  final String? openInventoryItemId;

  @override
  State<ProductListScreen> createState() => ProductListScreenState();
}

/// Public state so parent (Inventory nav) can call openAddProduct() when + is pressed.
class ProductListScreenState extends State<ProductListScreen> {
  /// Call from parent (e.g. Inventory + button) to open Add Product form.
  void openAddProduct() => _openProduct(null);
  final _supabase = SupabaseService.client;
  final _export = ExportService();

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filtered = [];
  List<Map<String, dynamic>> _categories = []; // includes {id, name}; first item is All (id: null)
  bool _isLoading = true;
  Set<String> _selectedCategoryIds = {}; // empty = All
  String? _selectedChannelFilter; // null = All, 'pos', 'app', 'online'
  bool _showInactive = false;
  final Set<String> _selectedProductIds = {}; // for bulk channel action
  String? _searchExactProductId; // when user selects autocomplete suggestion
  String _searchQuery = ''; // text search (managed by Autocomplete field)
  String _sortOption = 'plu_asc'; // plu_asc, plu_desc, name_az, name_za, price_low, price_high, stock_low, stock_high, category
  bool _isExportingCsv = false;
  bool _isImportingCsv = false;
  bool _didConsumeOpenInventoryItemId = false;
  final ScrollController _scrollController = ScrollController();

  static const List<String> _productCsvColumns = [
    'plu_code',
    'name',
    'pos_display_name',
    'scale_label_name',
    'barcode',
    'barcode_prefix',
    'text_lookup_code',
    'item_type',
    'product_type',
    'category',
    'sub_category',
    'scale_item',
    'ishida_sync',
    'is_active',
    'sell_price',
    'cost_price',
    'target_margin_pct',
    'freezer_markdown_pct',
    'vat_group',
    'stock_control_type',
    'unit_type',
    'allow_sell_by_fraction',
    'pack_size',
    'reorder_level',
    'slow_moving_trigger_days',
    'shelf_life_fresh',
    'shelf_life_frozen',
    'shrinkage_allowance_pct',
    'min_stock_alert',
    'is_frozen_variant',
    'dryer_biltong_product',
    'scale_shelf_life',
    'best_by',
    'label_format',
    'bar_flag',
    'department_no',
    'des_li1',
    'des_li2',
    'des_li3',
    'des_li4',
    'weighed',
    'has_ingredient',
    'cdv',
    'modifier_group_ids',
    'recipe_id',
    'dryer_product_type',
    'manufactured_item',
    'image_url',
    'dietary_tags',
    'allergen_info',
    'internal_notes',
    'available_pos',
    'available_loyalty_app',
    'available_online',
    'online_display_name',
    'online_description',
    'online_weight_description',
    'online_ingredients',
    'online_allergens',
    'online_cooking_tips',
    'online_image_url',
    'online_sort_order',
    'online_min_stock_threshold',
    'is_best_seller',
    'is_featured',
    'delivery_eligible',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // DATABASE-FIRST: Fetch from Supabase FIRST with 300-record limit
      try {
        await _fetchFromSupabaseAndSave();
      } catch (e) {
        // Fallback to cache if database fails
        debugPrint('Supabase fetch failed, using cache: $e');
        await _loadFromCache();
      }
      _filterProducts();
    } catch (e) {
      debugPrint('Product list error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
    final openId = widget.openInventoryItemId;
    if (openId != null &&
        !_didConsumeOpenInventoryItemId &&
        mounted) {
      _didConsumeOpenInventoryItemId = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_tryOpenProductById(openId));
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchSingleInventoryItem(String id) async {
    try {
      final row = await _supabase
          .from('inventory_items')
          .select('*')
          .eq('id', id)
          .maybeSingle();
      if (row == null) return null;
      return Map<String, dynamic>.from(row as Map);
    } catch (e) {
      debugPrint('Fetch single inventory item failed: $e');
      return null;
    }
  }

  Future<void> _tryOpenProductById(String id) async {
    Map<String, dynamic>? found;
    for (final p in _products) {
      if (p['id']?.toString() == id) {
        found = p;
        break;
      }
    }
    found ??= await _fetchSingleInventoryItem(id);
    if (!mounted) return;
    if (found != null) {
      _openProduct(found);
    } else {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Product not found')),
      );
    }
  }

  Future<void> _loadFromCache() async {
    final categories = await IsarService.getAllCategories();
    final active = categories.where((c) => c.isActive).toList();
    _categories = [
      {'id': null, 'name': 'All'},
      ...active.map((c) => {'id': c.categoryId, 'name': c.name}),
    ];
    final items = await IsarService.getAllInventoryItems(_showInactive);
    _products = items.map((e) => e.toMap()).toList();
  }

  Future<void> _fetchFromSupabaseAndSave() async {
    // Fetch categories
    final cats = await _supabase
        .from('categories')
        .select('id, name, parent_id, active')
        .eq('active', true)
        .order('sort_order');
    final categoryList = (cats as List)
        .map((c) => CachedCategory.fromSupabase(Map<String, dynamic>.from(c as Map)))
        .toList();
    _categories = [
      {'id': null, 'name': 'All'},
      ...(cats as List).map((c) {
        final m = Map<String, dynamic>.from(c as Map);
        return {'id': m['id'], 'name': m['name']};
      }),
    ];

    // DATABASE-FIRST: Fetch products with 300-record limit (preserving original plu_code ordering)
    var q = _supabase.from('inventory_items').select('*');
    if (!_showInactive) q = q.eq('is_active', true);
    final res = await q.order('plu_code').limit(300);
    _products = List<Map<String, dynamic>>.from(res);
    
    // Update cache in background (non-blocking)
    unawaited(IsarService.saveCategories(categoryList));
    final itemList = _products.map((i) => CachedInventoryItem.fromSupabase(i)).toList();
    unawaited(IsarService.saveInventoryItems(itemList));
  }

  void _filterProducts() {
    final query = _searchQuery.trim().toLowerCase();
    setState(() {
      _filtered = _products.where((p) {
        final matchSearch = _searchExactProductId != null
            ? p['id']?.toString() == _searchExactProductId
            : query.isEmpty ||
                (p['name'] ?? '').toLowerCase().contains(query) ||
                (p['plu_code']?.toString() ?? '').contains(query) ||
                (p['barcode'] ?? '').toLowerCase().contains(query) ||
                (p['text_lookup_code'] ?? '').toLowerCase().contains(query);
        final catId = p['category_id']?.toString();
        final matchCat = _selectedCategoryIds.isEmpty ||
            (catId != null && _selectedCategoryIds.contains(catId));
        final matchActive = _showInactive || (p['is_active'] == true);
        final matchChannel = _matchChannelFilter(p);
        return matchSearch && matchCat && matchActive && matchChannel;
      }).toList();
      _applySort();
    });
  }

  void _applySort() {
    final catNames = <String, String>{};
    for (final c in _categories) {
      if (c['id'] != null) {
        catNames[c['id'].toString()] = c['name'] as String? ?? '';
      }
    }
    _filtered.sort((a, b) {
      switch (_sortOption) {
        case 'plu_desc':
          return ((b['plu_code'] as num?) ?? 0).compareTo((a['plu_code'] as num?) ?? 0);
        case 'name_az':
          return ((a['name'] ?? '').toString().toLowerCase())
              .compareTo((b['name'] ?? '').toString().toLowerCase());
        case 'name_za':
          return ((b['name'] ?? '').toString().toLowerCase())
              .compareTo((a['name'] ?? '').toString().toLowerCase());
        case 'price_low':
          return ((a['sell_price'] as num?) ?? 0).compareTo((b['sell_price'] as num?) ?? 0);
        case 'price_high':
          return ((b['sell_price'] as num?) ?? 0).compareTo((a['sell_price'] as num?) ?? 0);
        case 'stock_low':
          return ((a['current_stock'] as num?) ?? 0).compareTo((b['current_stock'] as num?) ?? 0);
        case 'stock_high':
          return ((b['current_stock'] as num?) ?? 0).compareTo((a['current_stock'] as num?) ?? 0);
        case 'category':
          final na = catNames[a['category_id']?.toString()] ?? '';
          final nb = catNames[b['category_id']?.toString()] ?? '';
          return na.compareTo(nb);
        case 'plu_asc':
        default:
          return ((a['plu_code'] as num?) ?? 0).compareTo((b['plu_code'] as num?) ?? 0);
      }
    });
  }

  String _sortLabel() {
    switch (_sortOption) {
      case 'plu_asc': return 'PLU ↑';
      case 'plu_desc': return 'PLU ↓';
      case 'name_az': return 'Name A→Z';
      case 'name_za': return 'Name Z→A';
      case 'price_low': return 'Price ↑';
      case 'price_high': return 'Price ↓';
      case 'stock_low': return 'Stock ↑';
      case 'stock_high': return 'Stock ↓';
      case 'category': return 'Category';
      default: return 'PLU ↑';
    }
  }

  /// Format stock quantity: weight items (kg) show 3 decimals; unit items show whole numbers.
  String _formatStock(dynamic quantity, Map<String, dynamic> item) {
    final double qty = (quantity as num?)?.toDouble() ?? 0.0;
    final unitType = item['unit_type']?.toString().toLowerCase();
    final stockControl = item['stock_control_type']?.toString().toLowerCase();

    final isWeight = unitType == 'kg' ||
        stockControl == 'weight' ||
        stockControl == 'weighted' ||
        stockControl == 'kg';
    if (isWeight) {
      return '${qty.toStringAsFixed(3)} kg';
    }

    final unitLabel = unitType == 'packs' ? 'packs' : 'units';
    if (qty == qty.roundToDouble()) {
      return '${qty.toInt()} $unitLabel';
    }
    return '${qty.toStringAsFixed(1)} $unitLabel';
  }

  PopupMenuItem<String> _sortMenuItem(String value, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          if (_sortOption == value)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.check, size: 18, color: AppColors.primary),
            ),
          Text(label),
        ],
      ),
    );
  }

  bool _matchChannelFilter(Map<String, dynamic> p) {
    if (_selectedChannelFilter == null || _selectedChannelFilter == 'all') return true;
    final pos = p['available_pos'] as bool? ?? true;
    final app = p['available_loyalty_app'] as bool? ?? false;
    final online = p['available_online'] as bool? ?? false;
    switch (_selectedChannelFilter) {
      case 'pos':
        return pos;
      case 'app':
        return app;
      case 'online':
        return online;
      default:
        return true;
    }
  }

  /// Resolve category_id to display name. Prefer loaded _categories; fallback to valid mappings.
  String? _categoryNameById(dynamic categoryId) {
    if (categoryId == null) return null;
    final idStr = categoryId.toString();
    for (final c in _categories) {
      if (c['id']?.toString() == idStr) return c['name'] as String?;
    }
    return kCategoryIdToName[idStr];
  }

  Color _categoryColor(String? category) {
    switch (category) {
      case 'Beef': return AppColors.catBeef;
      case 'Pork': return AppColors.catPork;
      case 'Lamb': return AppColors.catLamb;
      case 'Chicken': return AppColors.catChicken;
      case 'Processed': return AppColors.catProcessed;
      case 'Drinks': return AppColors.catDrinks;
      case 'Spices & Condiments': return AppColors.catSpices;
      case 'Game & Venison': return AppColors.catGame;
      default: return AppColors.catOther;
    }
  }

  void _openProduct(Map<String, dynamic>? product) {
    showDialog(
      context: context,
      builder: (_) => _ProductFormDialog(
        product: product,
        categories: _categories.where((c) => c['id'] != null).toList(),
        onSaved: () async {
          final offset = _scrollController.hasClients
              ? _scrollController.offset
              : 0.0;
          await _loadData();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(
                offset.clamp(0.0, _scrollController.position.maxScrollExtent),
              );
            }
          });
        },
      ),
    );
  }

  Future<void> _openBulkChannelDialog() async {
    if (_selectedProductIds.isEmpty) return;
    await showDialog(
      context: context,
      builder: (_) => _BulkChannelDialog(
        productIds: _selectedProductIds.toList(),
        onSaved: () {
          _loadData();
          setState(() => _selectedProductIds.clear());
        },
      ),
    );
  }

  Future<void> _toggleActive(Map<String, dynamic> product) async {
    final newVal = !(product['is_active'] as bool? ?? true);
    await _supabase
        .from('inventory_items')
        .update({'is_active': newVal})
        .eq('id', product['id']);
    final productId = product['id']?.toString() ?? '';
    // Update local list without full reload to preserve scroll position.
    setState(() {
      final idx = _products.indexWhere((p) => p['id'] == productId);
      if (idx != -1) {
        _products[idx] = Map<String, dynamic>.from(_products[idx])
          ..['is_active'] = newVal;
      }
    });
    _filterProducts();
  }

  Future<void> _quickToggle(
      String productId, String field, bool newValue) async {
    try {
      await _supabase
          .from('inventory_items')
          .update({
            field: newValue,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', productId);
      // Update local list without full reload to preserve scroll position
      setState(() {
        final idx = _products.indexWhere((p) => p['id'] == productId);
        if (idx != -1) {
          _products[idx] = Map<String, dynamic>.from(_products[idx])
            ..[field] = newValue;
        }
      });
      _filterProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: ${ErrorHandler.friendlyMessage(e)}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _exportProductsCsv() async {
    if (mounted) setState(() => _isExportingCsv = true);
    try {
      var q = _supabase.from('inventory_items').select('*');
      if (!_showInactive) q = q.eq('is_active', true);
      final rows = await q.order('plu_code');
      final list = List<Map<String, dynamic>>.from(rows as List);

      String boolString(dynamic v) => v == true ? 'true' : 'false';
      String listString(dynamic v) {
        if (v is List) {
          return v.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).join(';');
        }
        return '';
      }
      String val(dynamic v) => v == null ? '' : v.toString();

      final data = list.map((r) {
        return <String, dynamic>{
          'plu_code': val(r['plu_code']),
          'name': val(r['name']),
          'pos_display_name': val(r['pos_display_name']),
          'scale_label_name': val(r['scale_label_name']),
          'barcode': val(r['barcode']),
          'barcode_prefix': val(r['barcode_prefix']),
          'text_lookup_code': val(r['text_lookup_code']),
          'item_type': val(r['item_type']),
          'product_type': val(r['product_type']),
          'category': val(r['category']),
          'sub_category': val(r['sub_category']),
          'scale_item': boolString(r['scale_item']),
          'ishida_sync': boolString(r['ishida_sync']),
          'is_active': boolString(r['is_active']),
          'sell_price': val(r['sell_price']),
          'cost_price': val(r['cost_price']),
          'target_margin_pct': val(r['target_margin_pct']),
          'freezer_markdown_pct': val(r['freezer_markdown_pct']),
          'vat_group': val(r['vat_group']),
          'stock_control_type': val(r['stock_control_type']),
          'unit_type': val(r['unit_type']),
          'allow_sell_by_fraction': boolString(r['allow_sell_by_fraction']),
          'pack_size': val(r['pack_size']),
          'reorder_level': val(r['reorder_level']),
          'slow_moving_trigger_days': val(r['slow_moving_trigger_days']),
          'shelf_life_fresh': val(r['shelf_life_fresh']),
          'shelf_life_frozen': val(r['shelf_life_frozen']),
          'shrinkage_allowance_pct': val(r['shrinkage_allowance_pct']),
          'min_stock_alert': val(r['min_stock_alert']),
          'is_frozen_variant': boolString(r['is_frozen_variant']),
          'dryer_biltong_product': boolString(r['dryer_biltong_product']),
          'scale_shelf_life': val(r['scale_shelf_life']),
          'best_by': val(r['best_by']),
          'label_format': val(r['label_format']),
          'bar_flag': val(r['bar_flag']),
          'department_no': val(r['department_no']),
          'des_li1': val(r['des_li1']),
          'des_li2': val(r['des_li2']),
          'des_li3': val(r['des_li3']),
          'des_li4': val(r['des_li4']),
          'weighed': boolString(r['weighed']),
          'has_ingredient': boolString(r['has_ingredient']),
          'cdv': val(r['cdv']),
          'modifier_group_ids': listString(r['modifier_group_ids']),
          'recipe_id': val(r['recipe_id']),
          'dryer_product_type': val(r['dryer_product_type']),
          'manufactured_item': boolString(r['manufactured_item']),
          'image_url': val(r['image_url']),
          'dietary_tags': listString(r['dietary_tags']),
          'allergen_info': listString(r['allergen_info']),
          'internal_notes': val(r['internal_notes']),
          'available_pos': boolString(r['available_pos']),
          'available_loyalty_app': boolString(r['available_loyalty_app']),
          'available_online': boolString(r['available_online']),
          'online_display_name': val(r['online_display_name']),
          'online_description': val(r['online_description']),
          'online_weight_description': val(r['online_weight_description']),
          'online_ingredients': val(r['online_ingredients']),
          'online_allergens': val(r['online_allergens']),
          'online_cooking_tips': val(r['online_cooking_tips']),
          'online_image_url': val(r['online_image_url']),
          'online_sort_order': val(r['online_sort_order']),
          'online_min_stock_threshold': val(r['online_min_stock_threshold']),
          'is_best_seller': boolString(r['is_best_seller']),
          'is_featured': boolString(r['is_featured']),
          'delivery_eligible': boolString(r['delivery_eligible']),
        };
      }).toList();

      final dateStr = DateTime.now().toIso8601String().split('T')[0];
      final path = await _export.saveCsvToFile(
        suggestedFileName: 'products_$dateStr.csv',
        data: data,
        columns: _productCsvColumns,
      );
      if (mounted && path != null) {
        final fileName = path.split(RegExp(r'[/\\]')).last;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to Downloads/$fileName'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.friendlyMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingCsv = false);
    }
  }

  Future<void> _importProductsCsv() async {
    if (mounted) setState(() => _isImportingCsv = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty || !mounted) {
        return;
      }
      if (result.files.single.bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to read file bytes. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      final bytes = result.files.single.bytes!;
      final content = utf8.decode(bytes, allowMalformed: true);
      final rows = _parseCsvRows(content);
      if (rows.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File is empty'), backgroundColor: AppColors.warning),
          );
        }
        return;
      }

      final headerRow = rows.first
          .map((c) => c.toString().replaceFirst(RegExp(r'^\uFEFF'), '').trim().toLowerCase())
          .toList();
      final headerIndex = <String, int>{};
      for (var i = 0; i < headerRow.length; i++) {
        headerIndex[headerRow[i]] = i;
      }
      if (!headerIndex.containsKey('plu_code')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Missing required column: plu_code'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final parsed = <Map<String, dynamic>>[];
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i] as List;
        final item = <String, dynamic>{};
        for (final col in _productCsvColumns) {
          final idx = headerIndex[col];
          item[col] = (idx != null && idx < row.length) ? row[idx]?.toString().trim() ?? '' : '';
        }
        if ((item['plu_code']?.toString() ?? '').trim().isEmpty) continue;
        parsed.add(item);
      }
      if (!mounted) return;

      final missingPlu = rows.length - 1 - parsed.length;
      await showDialog<void>(
        context: context,
        builder: (ctx) => _ProductImportPreviewDialog(
          rows: parsed,
          missingPluCount: missingPlu < 0 ? 0 : missingPlu,
          onConfirm: () async {
            Navigator.pop(ctx);
            await _applyProductImport(parsed);
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isImportingCsv = false);
    }
  }

  int? _toInt(dynamic raw) {
    final s = raw?.toString().trim() ?? '';
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }

  double? _toDouble(dynamic raw) {
    final s = raw?.toString().trim() ?? '';
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  bool? _toBool(dynamic raw) {
    final s = raw?.toString().trim().toLowerCase() ?? '';
    if (s.isEmpty) return null;
    if (s == 'true' || s == '1' || s == 'yes' || s == 'y') return true;
    if (s == 'false' || s == '0' || s == 'no' || s == 'n') return false;
    return null;
  }

  List<String>? _toList(dynamic raw) {
    final s = raw?.toString().trim() ?? '';
    if (s.isEmpty) return null;
    final normalized = s.startsWith('[') && s.endsWith(']')
        ? s.substring(1, s.length - 1)
        : s;
    final delim = normalized.contains(';') ? ';' : ',';
    final values = normalized
        .split(delim)
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return values.isEmpty ? null : values;
  }

  String? _toStringOrNull(dynamic raw) {
    final s = raw?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  List<List<dynamic>> _parseCsvRows(String content) {
    final commaRows = const CsvToListConverter().convert(content);
    if (commaRows.isNotEmpty) {
      final header = commaRows.first;
      final hasPlu = header.any(
        (c) =>
            c.toString().replaceFirst(RegExp(r'^\uFEFF'), '').trim().toLowerCase() ==
            'plu_code',
      );
      if (hasPlu) return commaRows;
    }
    return const CsvToListConverter(fieldDelimiter: ';').convert(content);
  }

  String? _validateImportRow(Map<String, dynamic> row, int pluCode) {
    bool inSet(String? value, Set<String> allowed) =>
        value == null || value.isEmpty || allowed.contains(value);
    final itemType = _toStringOrNull(row['item_type']);
    final unitType = _toStringOrNull(row['unit_type']);
    final vatGroup = _toStringOrNull(row['vat_group']);
    final barcodePrefix = _toStringOrNull(row['barcode_prefix']);
    final stockControlType = _toStringOrNull(row['stock_control_type']);
    final productType = _toStringOrNull(row['product_type']);
    final recipeId = _toStringOrNull(row['recipe_id']);

    if (!inSet(itemType, {
      'own_cut',
      'own_processed',
      'third_party_resale',
      'service',
      'packaging',
      'internal',
    })) {
      return 'Invalid item_type "$itemType"';
    }
    if (!inSet(unitType, {'kg', 'units', 'packs'})) {
      return 'Invalid unit_type "$unitType"';
    }
    if (!inSet(vatGroup, {'standard', 'zero_rated', 'exempt'})) {
      return 'Invalid vat_group "$vatGroup"';
    }
    if (!inSet(barcodePrefix, {'20', '21', 'none'})) {
      return 'Invalid barcode_prefix "$barcodePrefix"';
    }
    if (!inSet(stockControlType, {
      'use_stock_control',
      'no_stock_control',
      'recipe_based',
      'carcass_linked',
      'hanger_count',
    })) {
      return 'Invalid stock_control_type "$stockControlType"';
    }
    if (!inSet(productType, {'raw', 'portioned', 'manufactured'})) {
      return 'Invalid product_type "$productType"';
    }
    if (recipeId != null &&
        !RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
        ).hasMatch(recipeId)) {
      return 'Invalid recipe_id UUID "$recipeId"';
    }
    if (_toInt(row['cdv']) == null && _toStringOrNull(row['cdv']) != null) {
      return 'Invalid cdv "${row['cdv']}" (must be integer)';
    }
    if (pluCode <= 0) return 'Invalid plu_code "$pluCode"';
    return null;
  }

  Future<void> _applyProductImport(List<Map<String, dynamic>> rows) async {
    int inserted = 0, updated = 0, skipped = 0, errors = 0;
    final sampleErrors = <String>[];
    if (mounted) setState(() => _isImportingCsv = true);
    try {
      for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
        final row = rows[rowIndex];
        try {
          final pluCode = _toInt(row['plu_code']);
          if (pluCode == null) {
            skipped++;
            continue;
          }
          final rowError = _validateImportRow(row, pluCode);
          if (rowError != null) {
            errors++;
            if (sampleErrors.length < 5) {
              sampleErrors.add('Row ${rowIndex + 2} (PLU $pluCode): $rowError');
            }
            continue;
          }

          final payload = <String, dynamic>{
            'plu_code': pluCode,
            'name': _toStringOrNull(row['name']),
            'pos_display_name': _toStringOrNull(row['pos_display_name']),
            'scale_label_name': _toStringOrNull(row['scale_label_name']),
            'barcode': _toStringOrNull(row['barcode']),
            'barcode_prefix': _toStringOrNull(row['barcode_prefix']),
            'text_lookup_code': _toStringOrNull(row['text_lookup_code']),
            'item_type': _toStringOrNull(row['item_type']),
            'product_type': _toStringOrNull(row['product_type']),
            'category': _toStringOrNull(row['category']),
            'sub_category': _toStringOrNull(row['sub_category']),
            'scale_item': _toBool(row['scale_item']),
            'ishida_sync': _toBool(row['ishida_sync']),
            'is_active': _toBool(row['is_active']),
            'sell_price': _toDouble(row['sell_price']),
            'cost_price': _toDouble(row['cost_price']),
            'target_margin_pct': _toDouble(row['target_margin_pct']),
            'freezer_markdown_pct': _toDouble(row['freezer_markdown_pct']),
            'vat_group': _toStringOrNull(row['vat_group']),
            'stock_control_type': _toStringOrNull(row['stock_control_type']),
            'unit_type': _toStringOrNull(row['unit_type']),
            'allow_sell_by_fraction': _toBool(row['allow_sell_by_fraction']),
            'pack_size': _toDouble(row['pack_size']),
            'reorder_level': _toDouble(row['reorder_level']),
            'slow_moving_trigger_days': _toInt(row['slow_moving_trigger_days']),
            'shelf_life_fresh': _toInt(row['shelf_life_fresh']),
            'shelf_life_frozen': _toInt(row['shelf_life_frozen']),
            'shrinkage_allowance_pct': _toDouble(row['shrinkage_allowance_pct']),
            'min_stock_alert': _toDouble(row['min_stock_alert']),
            'is_frozen_variant': _toBool(row['is_frozen_variant']),
            'dryer_biltong_product': _toBool(row['dryer_biltong_product']),
            'scale_shelf_life': _toInt(row['scale_shelf_life']),
            'best_by': _toInt(row['best_by']),
            'label_format': _toStringOrNull(row['label_format']),
            'bar_flag': _toStringOrNull(row['bar_flag']),
            'department_no': _toStringOrNull(row['department_no']),
            'des_li1': _toStringOrNull(row['des_li1']),
            'des_li2': _toStringOrNull(row['des_li2']),
            'des_li3': _toStringOrNull(row['des_li3']),
            'des_li4': _toStringOrNull(row['des_li4']),
            'weighed': _toBool(row['weighed']),
            'has_ingredient': _toBool(row['has_ingredient']),
            'cdv': _toInt(row['cdv']),
            'modifier_group_ids': _toList(row['modifier_group_ids']),
            'recipe_id': _toStringOrNull(row['recipe_id']),
            'dryer_product_type': _toStringOrNull(row['dryer_product_type']),
            'manufactured_item': _toBool(row['manufactured_item']),
            'image_url': _toStringOrNull(row['image_url']),
            'dietary_tags': _toList(row['dietary_tags']),
            'allergen_info': _toList(row['allergen_info']),
            'internal_notes': _toStringOrNull(row['internal_notes']),
            'available_pos': _toBool(row['available_pos']),
            'available_loyalty_app': _toBool(row['available_loyalty_app']),
            'available_online': _toBool(row['available_online']),
            'online_display_name': _toStringOrNull(row['online_display_name']),
            'online_description': _toStringOrNull(row['online_description']),
            'online_weight_description': _toStringOrNull(row['online_weight_description']),
            'online_ingredients': _toStringOrNull(row['online_ingredients']),
            'online_allergens': _toStringOrNull(row['online_allergens']),
            'online_cooking_tips': _toStringOrNull(row['online_cooking_tips']),
            'online_image_url': _toStringOrNull(row['online_image_url']),
            'online_sort_order': _toInt(row['online_sort_order']),
            'online_min_stock_threshold': _toDouble(row['online_min_stock_threshold']),
            'is_best_seller': _toBool(row['is_best_seller']),
            'is_featured': _toBool(row['is_featured']),
            'delivery_eligible': _toBool(row['delivery_eligible']),
            'updated_at': DateTime.now().toIso8601String(),
          };

          // Guard required NOT NULL columns — never let these be null or absent on insert
          if (payload['name'] == null || payload['name'].toString().trim().isEmpty) {
            payload['name'] = 'Unnamed Product ${payload['plu_code']}';
          }
          // online_min_stock_threshold and delivery_eligible have DB defaults so they're safe
          payload.removeWhere((key, value) => value == null && key != 'name' && key != 'plu_code');

          payload.remove('current_stock');
          payload.remove('stock_on_hand_fresh');
          payload.remove('stock_on_hand_frozen');
          payload.remove('average_cost');
          payload.remove('average_cost_price');
          payload.remove('id');
          payload.remove('category_id');
          payload.remove('stock_deduction_qty');

          final existing = await _supabase
              .from('inventory_items')
              .select('id')
              .eq('plu_code', pluCode)
              .maybeSingle();

          if (existing != null) {
            await _supabase.from('inventory_items').update(payload).eq('id', existing['id']);
            updated++;
          } else {
            await _supabase.from('inventory_items').insert(payload);
            inserted++;
          }
        } catch (e) {
          errors++;
          debugPrint("IMPORT ROW ERROR [plu=${row['plu_code']}]: $e");
          if (errors <= 3) debugPrint('IMPORT ROW DATA: $row');
          if (sampleErrors.length < 5) {
            sampleErrors.add(
              'Row ${rowIndex + 2} (PLU ${row['plu_code'] ?? 'unknown'}): ${ErrorHandler.friendlyMessage(e)}',
            );
          }
        }
      }

      await IsarService.clearInventoryItemsCache();
      await _loadData();
      if (mounted) {
        final hasFailures = errors > 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$inserted inserted, $updated updated, $skipped skipped, $errors errors'),
            backgroundColor: hasFailures ? AppColors.warning : AppColors.success,
            duration: const Duration(seconds: 5),
          ),
        );
        if (sampleErrors.isNotEmpty) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Import completed with issues'),
              content: SizedBox(
                width: 640,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Top row errors:'),
                    const SizedBox(height: 8),
                    ...sampleErrors.map(
                      (msg) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('• $msg'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isImportingCsv = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            color: AppColors.cardBg,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;

                final searchField = SizedBox(
                  width: isWide ? 260 : double.infinity,
                  child: Autocomplete<Map<String, dynamic>>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Map<String, dynamic>>.empty();
                      }
                      final query = textEditingValue.text.toLowerCase();
                      return _products.where((p) {
                        final name = (p['name'] ?? '').toString().toLowerCase();
                        final plu = (p['plu_code']?.toString() ?? '').toLowerCase();
                        return name.contains(query) || plu.contains(query);
                      }).take(8);
                    },
                    displayStringForOption: (p) =>
                        '${p['plu_code'] ?? ''} — ${p['name'] ?? ''}',
                    onSelected: (p) {
                      setState(() {
                        _searchExactProductId = p['id']?.toString();
                        _filterProducts();
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: 'Search by name, PLU...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              controller.clear();
                              setState(() {
                                _searchExactProductId = null;
                                _searchQuery = '';
                                _filterProducts();
                              });
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchExactProductId = null;
                            _searchQuery = value;
                            _filterProducts();
                          });
                        },
                        onSubmitted: (_) => onSubmitted(),
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          child: SizedBox(
                            width: 320,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 240),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final p = options.elementAt(index);
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      '${p['plu_code'] ?? ''} — ${p['name'] ?? ''}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () => onSelected(p),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );

                final categoryFilterBtn = InkWell(
                  onTap: () async {
                    var selected = Set<String>.from(_selectedCategoryIds);
                    await showDialog(
                      context: context,
                      builder: (ctx) => StatefulBuilder(
                        builder: (ctx, setDialogState) => AlertDialog(
                          title: const Text('Filter by Category'),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ListTile(
                                  dense: true,
                                  title: const Text('All', style: TextStyle(fontWeight: FontWeight.w600)),
                                  onTap: () {
                                    selected.clear();
                                    Navigator.pop(ctx);
                                    setState(() {
                                      _selectedCategoryIds.clear();
                                      _filterProducts();
                                    });
                                  },
                                ),
                                const Divider(),
                                ..._categories.where((c) => c['id'] != null).map((c) {
                                  final id = c['id']?.toString() ?? '';
                                  final name = c['name'] as String? ?? '';
                                  return CheckboxListTile(
                                    dense: true,
                                    title: Text(name),
                                    value: selected.contains(id),
                                    onChanged: (v) {
                                      setDialogState(() {
                                        if (v == true) {
                                          selected.add(id);
                                        } else {
                                          selected.remove(id);
                                        }
                                      });
                                    },
                                  );
                                }),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                setState(() {
                                  _selectedCategoryIds = selected;
                                  _filterProducts();
                                });
                              },
                              child: const Text('Apply'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.category, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          _selectedCategoryIds.isEmpty
                              ? 'All'
                              : '${_selectedCategoryIds.length} categories',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );

                final filters = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    categoryFilterBtn,
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 120,
                      child: DropdownButton<String?>(
                        value: _selectedChannelFilter,
                        underline: const SizedBox(),
                        hint: const Text('All'),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All')),
                          DropdownMenuItem(value: 'pos', child: Text('POS Only')),
                          DropdownMenuItem(value: 'app', child: Text('App')),
                          DropdownMenuItem(value: 'online', child: Text('Online')),
                        ],
                        onChanged: (v) {
                          setState(() => _selectedChannelFilter = v);
                          _filterProducts();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: _showInactive,
                          onChanged: (v) {
                            setState(() => _showInactive = v);
                            _filterProducts();
                          },
                          activeThumbColor: AppColors.primary,
                        ),
                        const Text('Show inactive',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                );

                final addButton = ElevatedButton.icon(
                  onPressed: () => _openProduct(null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Product'),
                );

                final sortButton = PopupMenuButton<String>(
                  tooltip: 'Sort',
                  icon: const Icon(Icons.sort, size: 20),
                  onSelected: (v) {
                    setState(() {
                      _sortOption = v;
                      _filterProducts();
                    });
                  },
                  itemBuilder: (context) => [
                    _sortMenuItem('plu_asc', 'PLU (ascending)'),
                    _sortMenuItem('plu_desc', 'PLU (descending)'),
                    _sortMenuItem('name_az', 'Name (A→Z)'),
                    _sortMenuItem('name_za', 'Name (Z→A)'),
                    _sortMenuItem('price_low', 'Price (low→high)'),
                    _sortMenuItem('price_high', 'Price (high→low)'),
                    _sortMenuItem('stock_low', 'Stock (low→high)'),
                    _sortMenuItem('stock_high', 'Stock (high→low)'),
                    _sortMenuItem('category', 'Category'),
                  ],
                );

                final bulkButton = AuthService().currentRole == 'owner' &&
                        _selectedProductIds.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OutlinedButton.icon(
                          onPressed: () => _openBulkChannelDialog(),
                          icon: const Icon(Icons.storefront, size: 18),
                          label: Text('Set channel (${_selectedProductIds.length})'),
                        ),
                      )
                    : const SizedBox.shrink();

                final countText = Text(
                  '${_filtered.length} products',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                );

                final refreshButton = IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh from server',
                  onPressed: () async {
                    await IsarService.clearInventoryItemsCache();
                    _loadData();
                  },
                );

                if (isWide) {
                  return Row(
                    children: [
                      SizedBox(width: 220, child: searchField),
                      const SizedBox(width: 6),
                      categoryFilterBtn,
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 110,
                        child: DropdownButton<String?>(
                          value: _selectedChannelFilter,
                          underline: const SizedBox(),
                          hint: const Text('All'),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: null, child: Text('All')),
                            DropdownMenuItem(value: 'pos', child: Text('POS Only')),
                            DropdownMenuItem(value: 'app', child: Text('App')),
                            DropdownMenuItem(value: 'online', child: Text('Online')),
                          ],
                          onChanged: (v) {
                            setState(() => _selectedChannelFilter = v);
                            _filterProducts();
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: _showInactive,
                            onChanged: (v) {
                              setState(() => _showInactive = v);
                              _filterProducts();
                            },
                            activeThumbColor: AppColors.primary,
                          ),
                          const Text('Show inactive',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                countText,
                                const SizedBox(width: 6),
                                bulkButton,
                                IconButton(
                                  icon: const Icon(Icons.refresh, size: 20),
                                  tooltip: 'Refresh from server',
                                  onPressed: () async {
                                    await IsarService.clearInventoryItemsCache();
                                    _loadData();
                                  },
                                ),
                                IconButton(
                                  onPressed: _isExportingCsv ? null : _exportProductsCsv,
                                  icon: _isExportingCsv
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.download, size: 20),
                                  tooltip: 'Export CSV',
                                ),
                                IconButton(
                                  onPressed: _isImportingCsv ? null : _importProductsCsv,
                                  icon: _isImportingCsv
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.upload_file, size: 20),
                                  tooltip: 'Import CSV',
                                ),
                                const SizedBox(width: 4),
                                sortButton,
                                const SizedBox(width: 6),
                                addButton,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: searchField),
                          const SizedBox(width: 4),
                          bulkButton,
                          refreshButton,
                          IconButton(
                            onPressed: _isExportingCsv ? null : _exportProductsCsv,
                            icon: _isExportingCsv
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.download, size: 20),
                            tooltip: 'Export CSV',
                          ),
                          const SizedBox(width: 2),
                          IconButton(
                            onPressed: _isImportingCsv ? null : _importProductsCsv,
                            icon: _isImportingCsv
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.upload_file, size: 20),
                            tooltip: 'Import CSV',
                          ),
                          const SizedBox(width: 2),
                          sortButton,
                          addButton,
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          filters,
                          const Spacer(),
                          countText,
                        ],
                      ),
                    ],
                  );
                }
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Table header — fixed widths to prevent overflow at 996px
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            color: AppColors.surfaceBg,
            child: Row(
              children: [
                const SizedBox(width: 40, child: Text('#', style: _headerStyle)),
                const SizedBox(width: 8),
                if (AuthService().currentRole == 'owner')
                  const SizedBox(width: 36, child: Text('', style: _headerStyle)),
                if (AuthService().currentRole == 'owner') const SizedBox(width: 8),
                const SizedBox(width: 60, child: Text('PLU', style: _headerStyle)),
                const SizedBox(width: 8),
                const Expanded(child: Text('NAME', style: _headerStyle)),
                const SizedBox(width: 8),
                const SizedBox(width: 60, child: Text('CHANNELS', style: _headerStyle)),
                const SizedBox(width: 8),
                const SizedBox(width: 100, child: Text('CATEGORY', style: _headerStyle)),
                const SizedBox(width: 8),
                const SizedBox(width: 80, child: Text('SELL PRICE', style: _headerStyle)),
                const SizedBox(width: 8),
                const SizedBox(width: 70, child: Text('COST', style: _headerStyle)),
                const SizedBox(width: 8),
                const SizedBox(width: 60, child: Text('GP %', style: _headerStyle)),
                const SizedBox(width: 8),
                const SizedBox(width: 90, child: Text('ON HAND', style: _headerStyle)),
                const SizedBox(width: 8),
                const SizedBox(width: 70, child: Text('STATUS', style: _headerStyle)),
                const SizedBox(width: 8),
                const SizedBox(width: 128, child: Text('ACTIONS', style: _headerStyle)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Product list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _filtered.isEmpty
                    ? const Center(
                        child: Text('No products found',
                            style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: AppColors.border),
                        itemBuilder: (context, i) {
                          final p = _filtered[i];
                          final rowNum = i + 1;
                          final sell =
                              (p['sell_price'] as num?)?.toDouble() ?? 0;
                          final cost =
                              (p['cost_price'] as num?)?.toDouble() ?? 0;
                          final gp = sell > 0
                              ? ((sell - cost) / sell * 100)
                              : 0.0;
                          // C1: Single source of truth — POS trigger updates current_stock; UI uses it only.
                          final onHand = (p['current_stock'] as num?)?.toDouble() ?? 0;
                          final isActive = p['is_active'] as bool? ?? true;
                          final reorder =
                              (p['reorder_level'] as num?)?.toDouble() ?? 0;

                          final availablePos = p['available_pos'] as bool? ?? true;
                          final availableApp = p['available_loyalty_app'] as bool? ?? false;
                          final availableOnline = p['available_online'] as bool? ?? false;
                          final productId = p['id']?.toString() ?? '';
                          final isSelected = _selectedProductIds.contains(productId);

                          return InkWell(
                            onTap: () => _openProduct(p),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 10),
                              color: isActive
                                  ? null
                                  : AppColors.border.withOpacity(0.3),
                              child: Row(
                                children: [
                                  // Row number
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      '$rowNum',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Checkbox (owner only)
                                  if (AuthService().currentRole == 'owner') ...[
                                    SizedBox(
                                      width: 36,
                                      child: Checkbox(
                                        value: isSelected,
                                        onChanged: (v) {
                                          setState(() {
                                            if (v == true) {
                                              _selectedProductIds.add(productId);
                                            } else {
                                              _selectedProductIds.remove(productId);
                                            }
                                          });
                                        },
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        activeColor: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  // PLU
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      '${p['plu_code'] ?? '—'}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Name — Expanded, must not overflow
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['name'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        if (p['pos_display_name'] != null &&
                                            p['pos_display_name'] != p['name'])
                                          Text(
                                            p['pos_display_name'],
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Channel indicators — fixed 60px
                                  SizedBox(
                                    width: 60,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (availablePos)
                                          Icon(Icons.receipt, size: 14, color: AppColors.textSecondary),
                                        if (availablePos && (availableApp || availableOnline)) const SizedBox(width: 2),
                                        if (availableApp)
                                          Icon(Icons.phone_android, size: 14, color: AppColors.textSecondary),
                                        if (availableApp && availableOnline) const SizedBox(width: 2),
                                        if (availableOnline)
                                          Icon(Icons.public, size: 14, color: AppColors.textSecondary),
                                        if (!availablePos && !availableApp && !availableOnline)
                                          const Text('—', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Category — fixed 100px with ellipsis
                                  SizedBox(
                                    width: 100,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: _categoryColor(
                                                _categoryNameById(p['category_id'])),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            _categoryNameById(p['category_id']) ?? '—',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textPrimary),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Sell price
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      'R ${sell.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Cost
                                  SizedBox(
                                    width: 70,
                                    child: Text(
                                      'R ${cost.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // GP %
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      '${gp.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: gp >= 30
                                            ? AppColors.success
                                            : gp >= 20
                                                ? AppColors.warning
                                                : AppColors.error,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // On hand
                                  SizedBox(
                                    width: 90,
                                    child: Text(
                                      _formatStock(p['current_stock'], p),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: onHand <= reorder
                                            ? AppColors.warning
                                            : AppColors.textPrimary,
                                        fontWeight: onHand <= reorder
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Status
                                  SizedBox(
                                    width: 70,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? AppColors.success.withOpacity(0.1)
                                            : AppColors.error.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isActive
                                              ? AppColors.success
                                              : AppColors.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Actions — fixed width, min size
                                  SizedBox(
                                    width: 128,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Online toggle
                                        Tooltip(
                                          message: (p['available_online'] as bool? ?? false)
                                              ? 'Online: ON — tap to disable'
                                              : 'Online: OFF — tap to enable',
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.storefront,
                                              size: 16,
                                              color: (p['available_online'] as bool? ?? false)
                                                  ? AppColors.success
                                                  : AppColors.textSecondary,
                                            ),
                                            onPressed: () => _quickToggle(
                                              p['id'] as String,
                                              'available_online',
                                              !(p['available_online'] as bool? ?? false),
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                          ),
                                        ),
                                        // Loyalty toggle
                                        Tooltip(
                                          message: (p['available_loyalty_app'] as bool? ?? false)
                                              ? 'Loyalty: ON — tap to disable'
                                              : 'Loyalty: OFF — tap to enable',
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.loyalty,
                                              size: 16,
                                              color: (p['available_loyalty_app'] as bool? ?? false)
                                                  ? AppColors.primary
                                                  : AppColors.textSecondary,
                                            ),
                                            onPressed: () => _quickToggle(
                                              p['id'] as String,
                                              'available_loyalty_app',
                                              !(p['available_loyalty_app'] as bool? ?? false),
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              size: 16),
                                          color: AppColors.primary,
                                          onPressed: () => _openProduct(p),
                                          tooltip: 'Edit',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.inventory_2,
                                            size: 16,
                                          ),
                                          color: AppColors.primary,
                                          onPressed: () =>
                                              showStockActionsMenu(
                                            context,
                                            product: p,
                                            onDone: _loadData,
                                          ),
                                          tooltip: 'Stock (Waste, Transfer, Freezer, Donation, etc.)',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            isActive
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            size: 16,
                                          ),
                                          color: AppColors.textSecondary,
                                          onPressed: () => _toggleActive(p),
                                          tooltip: isActive
                                              ? 'Deactivate'
                                              : 'Activate',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
}

// ── Product Form Dialog ───────────────────────────────────────

class _ProductFormDialog extends StatefulWidget {
  final Map<String, dynamic>? product;
  final List<Map<String, dynamic>> categories;
  final VoidCallback onSaved;

  const _ProductFormDialog({
    required this.product,
    required this.categories,
    required this.onSaved,
  });

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog>
    with SingleTickerProviderStateMixin {
  final _supabase = SupabaseService.client;
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  bool _isSaving = false;

  // Section A
  final _pluController = TextEditingController();
  final _nameController = TextEditingController();
  final _posNameController = TextEditingController();
  final _scaleLabelController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _lookupController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedCategoryName; // display name; kept in sync with _selectedCategoryId for DB category column
  String? _selectedSubCategoryId; // subcategory category id (child of main category)
  String? _subCategoryName; // display name for subcategory; saved as sub_category on inventory_items
  String _itemType = 'own_cut';
  /// H9: Raw (no processing), Portioned, Manufactured (recipe-based)
  String _productType = 'raw';
  bool _scaleItem = false;
  bool _ishidaSync = false;
  // Tab G — Scale/Label fields
  final _scaleShelfLifeController = TextEditingController();
  final _bestByController = TextEditingController();
  final _labelFormatController = TextEditingController();
  final _barFlagController = TextEditingController();
  final _departmentNoController = TextEditingController();
  final _desLi1Controller = TextEditingController();
  final _desLi2Controller = TextEditingController();
  final _desLi3Controller = TextEditingController();
  final _desLi4Controller = TextEditingController();
  bool _weighed = true;
  bool _hasIngredient = false;
  // Section I - Online Shop fields
  final _onlineDisplayNameController = TextEditingController();
  final _onlineDescriptionController = TextEditingController();
  final _onlineImageUrlController = TextEditingController();
  final _onlineMinStockThresholdController = TextEditingController();
  final _onlineSortOrderController = TextEditingController();
  bool _availableOnline = false;
  bool _isActive = true;
  List<String> _supplierIds = [];
  List<Map<String, dynamic>> _allSuppliers = [];

  /// Top-level categories only (parent_id null or empty) for main Category dropdown.
  List<Map<String, dynamic>> get _topLevelCategories {
    return widget.categories
        .where((c) =>
            c['id'] != null &&
            (c['parent_id'] == null || c['parent_id'].toString().isEmpty))
        .toList();
  }

  /// Subcategories of selected main category for Sub-Category dropdown. None if no children.
  List<DropdownMenuItem<String?>> get _subCategoryDropdownItems {
    final none = DropdownMenuItem<String?>(value: null, child: Text('None'));
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      return [none];
    }
    final children = widget.categories
        .where((c) => c['parent_id']?.toString() == _selectedCategoryId)
        .toList();
    if (children.isEmpty) return [none];
    return [
      none,
      ...children.map((c) => DropdownMenuItem<String?>(
            value: c['id']?.toString(),
            child: Text((c['name'] as String? ?? ''), overflow: TextOverflow.ellipsis),
          )),
    ];
  }

  // Section B
  final _sellPriceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _targetMarginController = TextEditingController();
  final _freezerMarkdownController = TextEditingController();
  String _vatGroup = 'standard';

  // Section C
  String _stockControlType = 'use_stock_control';
  String _unitType = 'kg';
  bool _allowFraction = true;
  final _reorderController = TextEditingController();
  final _shelfLifeFreshController = TextEditingController();
  final _shelfLifeFrozenController = TextEditingController();
  final _slowMovingController = TextEditingController();
  final _packSizeController = TextEditingController(text: '1');
  List<String> _storageLocationIds = [];
  String? _carcassLinkId;
  bool _dryerBiltongProduct = false;
  double? _shrinkageAllowancePct;
  bool _isFrozenVariant = false;
  double? _minStockAlert;

  // Section D (barcode in A; D adds prefix)
  String? _barcodePrefix;

  // Section E
  List<String> _modifierGroupIds = [];
  List<Map<String, dynamic>> _allModifierGroups = [];

  // H6: Supplier product mapping (product_suppliers)
  List<Map<String, dynamic>> _productSupplierRows = [];

  // Section F
  String? _recipeId;
  String? _dryerProductType;
  bool _manufacturedItem = false;
  List<Map<String, dynamic>> _recipes = [];
  List<Map<String, dynamic>> _dryerTypes = [];
  double? _recipeCostPerKg;
  bool _recipeCostLoading = false;

  // Section G — Channels
  bool _availablePos = true;
  bool _availableLoyaltyApp = false;

  // Section J — Online Store (Enhanced)
  bool _isBestSeller = false;
  bool _isFeatured = false;
  final _onlineWeightDescriptionController = TextEditingController();
  final _onlineIngredientsController = TextEditingController();
  final _onlineAllergensController = TextEditingController();
  final _onlineCookingTipsController = TextEditingController();
  Set<String> _selectedOnlineCategoryIds = {};
  List<Map<String, dynamic>> _onlineCategories = [];
  List<Map<String, dynamic>> _linkedRecipes = [];
  List<Map<String, dynamic>> _allCustomerRecipes = [];
  bool _isUploadingImage = false;
  
  // Parent Stock Link
  String? _parentStockItemId;
  String? _parentStockItemName;
  String? _parentStockItemPlu;
  final _parentStockSearchController = TextEditingController();
  final _stockDeductionQtyController = TextEditingController();
  String _stockDeductionUnit = 'kg';
  List<Map<String, dynamic>> _parentStockSearchResults = [];
  Timer? _parentStockDebounce;

  // Production parent link
  String? _productionParentItemId;
  String? _productionParentItemName;
  String? _productionParentItemPlu;
  final TextEditingController _productionParentSearchController =
      TextEditingController();
  List<Map<String, dynamic>> _productionParentSearchResults = [];
  Timer? _productionParentDebounce;

  // Section H — Media & Notes
  final _internalNotesController = TextEditingController();
  List<String> _dietaryTags = [];
  List<String> _allergenInfo = [];
  final _imageUrlController = TextEditingController();
  static const List<String> _dietaryOptions = ['Halal', 'Grass-fed', 'Free-range', 'Organic', 'Game', 'Venison'];
  static const List<String> _allergenOptions = ['Gluten', 'Dairy', 'Nuts', 'Soy', 'Eggs', 'Shellfish', 'None'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this);
    if (widget.product != null) {
      _populateForm(widget.product!);
      _loadProductSuppliers();
      _loadOnlineProductCategories();
      _loadLinkedRecipes();
    }
    _loadModifierGroups();
    _loadRecipes();
    _loadSuppliers();
    _loadOnlineCategories();
    _loadCustomerRecipes();
  }

  Future<void> _loadProductSuppliers() async {
    if (widget.product == null) return;
    try {
      final rows = await _supabase
          .from('product_suppliers')
          .select('*, suppliers(name)')
          .eq('inventory_item_id', widget.product!['id'])
          .order('supplier_id');
      setState(() => _productSupplierRows = List<Map<String, dynamic>>.from(rows));
    } catch (_) {
      setState(() => _productSupplierRows = []);
    }
  }

  Future<void> _loadSuppliers() async {
    try {
      final r = await _supabase.from('suppliers').select('id, name').eq('is_active', true).order('name');
      setState(() => _allSuppliers = List<Map<String, dynamic>>.from(r));
    } catch (_) {}
  }

  Future<void> _loadModifierGroups() async {
    try {
      final r = await _supabase.from('modifier_groups').select('id, name').eq('is_active', true).order('name');
      setState(() => _allModifierGroups = List<Map<String, dynamic>>.from(r));
    } catch (_) {}
  }

  Future<void> _loadRecipes() async {
    try {
      final r = await _supabase.from('recipes').select('id, name').order('name');
      if (mounted) {
        setState(() => _recipes = List<Map<String, dynamic>>.from(r));
        debugPrint('Recipes loaded: ${_recipes.length}');
      }
    } catch (e) {
      debugPrint('Error loading recipes: $e');
    }
  }

  Future<void> _loadOnlineCategories() async {
    try {
      final r = await _supabase
          .from('categories')
          .select('id, name, sort_order')
          .eq('available_online', true)
          .order('sort_order');
      if (mounted) {
        setState(() => _onlineCategories = List<Map<String, dynamic>>.from(r));
      }
    } catch (e) {
      debugPrint('Error loading online categories: $e');
    }
  }

  Future<void> _loadCustomerRecipes() async {
    try {
      final r = await _supabase
          .from('customer_recipes')
          .select('id, title, image_url')
          .eq('status', 'published')
          .order('title');
      if (mounted) {
        setState(() => _allCustomerRecipes = List<Map<String, dynamic>>.from(r));
      }
    } catch (e) {
      debugPrint('Error loading customer recipes: $e');
    }
  }

  Future<void> _loadOnlineProductCategories() async {
    if (widget.product == null) return;
    try {
      final rows = await _supabase
          .from('online_product_categories')
          .select('category_id')
          .eq('inventory_item_id', widget.product!['id']);
      if (mounted) {
        setState(() {
          _selectedOnlineCategoryIds = (rows as List)
              .map((r) => (r as Map)['category_id']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .toSet();
        });
      }
    } catch (e) {
      debugPrint('Error loading online product categories: $e');
    }
  }

  Future<void> _loadLinkedRecipes() async {
    if (widget.product == null) return;
    try {
      final rows = await _supabase
          .from('online_product_recipes')
          .select('id, customer_recipe_id, display_order, customer_recipes(title, image_url)')
          .eq('inventory_item_id', widget.product!['id'])
          .order('display_order');
      if (mounted) {
        setState(() => _linkedRecipes = List<Map<String, dynamic>>.from(rows));
      }
    } catch (e) {
      debugPrint('Error loading linked recipes: $e');
    }
  }

  Future<void> _uploadProductImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      
      final file = result.files.first;
      if (file.bytes == null) return;
      
      setState(() => _isUploadingImage = true);
      
      final productId = widget.product?['id'] ?? const Uuid().v4();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final storagePath = 'products/$productId/$fileName';
      
      await Supabase.instance.client.storage
        .from('product-images')
        .uploadBinary(
          storagePath,
          file.bytes!,
          fileOptions: const FileOptions(upsert: true),
        );
      
      final publicUrl = Supabase.instance.client.storage
        .from('product-images')
        .getPublicUrl(storagePath);
      
      setState(() {
        _onlineImageUrlController.text = publicUrl;
        _isUploadingImage = false;
      });
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadRecipeCost(String? recipeId) async {
    if (recipeId == null || recipeId.isEmpty) {
      setState(() => _recipeCostPerKg = null);
      return;
    }
    setState(() => _recipeCostLoading = true);
    try {
      final recipe = await _supabase.from('recipes').select('id, name, batch_size_kg').eq('id', recipeId).maybeSingle();
      if (recipe == null) {
        if (mounted) setState(() { _recipeCostPerKg = null; _recipeCostLoading = false; });
        return;
      }
      final batchSize = (recipe['batch_size_kg'] as num?)?.toDouble() ?? 1.0;
      if (batchSize <= 0) {
        if (mounted) setState(() { _recipeCostPerKg = null; _recipeCostLoading = false; });
        return;
      }
      final ingredients = await _supabase
          .from('recipe_ingredients')
          .select('inventory_item_id, quantity')
          .eq('recipe_id', recipeId);
      double totalCost = 0;
      for (final ing in ingredients as List) {
        final itemId = (ing as Map)['inventory_item_id']?.toString();
        final qty = ((ing['quantity'] as num?)?.toDouble()) ?? 0;
        if (itemId == null || qty <= 0) continue;
        final item = await _supabase.from('inventory_items').select('cost_price').eq('id', itemId).maybeSingle();
        final cp = (item?['cost_price'] as num?)?.toDouble();
        if (cp != null) totalCost += qty * cp;
      }
      if (mounted) setState(() {
        _recipeCostPerKg = totalCost / batchSize;
        _recipeCostLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _recipeCostPerKg = null; _recipeCostLoading = false; });
    }
  }

  /// Recipe name for recipe_link column (backward compatibility) when recipe_id is set.
  String? get _recipeNameForSelectedId {
    if (_recipeId == null) return null;
    try {
      return _recipes.firstWhere((r) => r['id']?.toString() == _recipeId)['name'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadParentStockItemDetails(String parentId) async {
    try {
      final result = await _supabase
          .from('inventory_items')
          .select('id, name, plu_code')
          .eq('id', parentId)
          .maybeSingle();
      if (result != null && mounted) {
        setState(() {
          _parentStockItemName = result['name'] as String?;
          _parentStockItemPlu = result['plu_code']?.toString();
        });
      }
    } catch (e) {
      debugPrint('Error loading parent stock item: $e');
    }
  }

  Future<void> _loadProductionParentItemDetails(String parentId) async {
    try {
      final result = await _supabase
          .from('inventory_items')
          .select('id, name, plu_code')
          .eq('id', parentId)
          .maybeSingle();
      if (result != null && mounted) {
        setState(() {
          _productionParentItemName = result['name']?.toString();
          _productionParentItemPlu = result['plu_code']?.toString();
        });
      }
    } catch (e) {
      debugPrint('Error loading production parent item details: $e');
    }
  }

  void _searchProductionParentItems(String query) {
    _productionParentDebounce?.cancel();
    _productionParentDebounce =
        Timer(const Duration(milliseconds: 300), () async {
      if (query.trim().isEmpty) {
        setState(() => _productionParentSearchResults = []);
        return;
      }
      try {
        final byName = await _supabase
            .from('inventory_items')
            .select('id, name, plu_code')
            .ilike('name', '%$query%')
            .eq('is_active', true)
            .neq('id', widget.product?['id'] ?? '')
            .limit(8);

        List<Map<String, dynamic>> byPlu = [];
        final pluInt = int.tryParse(query.trim());
        if (pluInt != null) {
          byPlu = await _supabase
              .from('inventory_items')
              .select('id, name, plu_code')
              .eq('plu_code', pluInt)
              .eq('is_active', true)
              .neq('id', widget.product?['id'] ?? '')
              .limit(4);
        }

        final seen = <String>{};
        final merged = <Map<String, dynamic>>[];
        for (final item in [...byPlu, ...byName]) {
          final id = item['id']?.toString() ?? '';
          if (seen.add(id)) merged.add(item);
        }

        if (mounted) {
          setState(() => _productionParentSearchResults =
              List<Map<String, dynamic>>.from(merged));
        }
      } catch (e) {
        debugPrint('Error searching production parent items: $e');
      }
    });
  }

  void _searchParentStockItems(String query) {
    _parentStockDebounce?.cancel();
    _parentStockDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.trim().isEmpty) {
        setState(() => _parentStockSearchResults = []);
        return;
      }
      try {
        final byName = await _supabase
            .from('inventory_items')
            .select('id, name, plu_code')
            .ilike('name', '%$query%')
            .eq('is_active', true)
            .neq('id', widget.product?['id'] ?? '')
            .limit(8);

        List<Map<String, dynamic>> byPlu = [];
        final pluInt = int.tryParse(query.trim());
        if (pluInt != null) {
          byPlu = await _supabase
              .from('inventory_items')
              .select('id, name, plu_code')
              .eq('plu_code', pluInt)
              .eq('is_active', true)
              .neq('id', widget.product?['id'] ?? '')
              .limit(4);
        }

        final seen = <String>{};
        final merged = <Map<String, dynamic>>[];
        for (final item in [...byPlu, ...byName]) {
          final id = item['id']?.toString() ?? '';
          if (seen.add(id)) merged.add(item);
        }

        if (mounted) {
          setState(() => _parentStockSearchResults =
              List<Map<String, dynamic>>.from(merged));
        }
      } catch (e) {
        debugPrint('Error searching parent stock items: $e');
      }
    });
  }

  void _populateForm(Map<String, dynamic> p) {
    debugPrint('POPULATE DEBUG: available_online=${p['available_online']}');
    debugPrint('POPULATE DEBUG: is_best_seller=${p['is_best_seller']}');
    debugPrint('POPULATE DEBUG: online_display_name=${p['online_display_name']}');
    debugPrint('POPULATE DEBUG: online_ingredients=${p['online_ingredients']}');
    
    _pluController.text = p['plu_code']?.toString() ?? '';
    _nameController.text = p['name'] ?? '';
    _posNameController.text = p['pos_display_name'] ?? '';
    _scaleLabelController.text = p['scale_label_name'] ?? '';
    _barcodeController.text = p['barcode'] ?? '';
    _lookupController.text = p['text_lookup_code'] ?? '';
    _selectedCategoryId = p['category_id']?.toString();
    _selectedCategoryName = p['category'] as String? ?? (_selectedCategoryId != null ? kCategoryIdToName[_selectedCategoryId] : null);
    _selectedSubCategoryId = p['sub_category_id']?.toString();
    _subCategoryName = p['sub_category'] as String?;
    _itemType = p['item_type'] ?? 'own_cut';
    _productType = p['product_type'] ?? 'raw';
    _scaleItem = p['scale_item'] ?? false;
    _ishidaSync = p['ishida_sync'] ?? false;
    _shelfLifeFreshController.text = p['shelf_life_fresh']?.toString() ?? '';
    _shelfLifeFrozenController.text = p['shelf_life_frozen']?.toString() ?? '';
    _scaleShelfLifeController.text = p['scale_shelf_life']?.toString() ?? '';
    _bestByController.text = p['best_by']?.toString() ?? '';
    _labelFormatController.text = p['label_format']?.toString() ?? '';
    _barFlagController.text = p['bar_flag']?.toString() ?? '';
    _departmentNoController.text = p['department_no']?.toString() ?? '1';
    _desLi1Controller.text = p['des_li1']?.toString() ?? '';
    _desLi2Controller.text = p['des_li2']?.toString() ?? '';
    _desLi3Controller.text = p['des_li3']?.toString() ?? '';
    _desLi4Controller.text = p['des_li4']?.toString() ?? '';
    _weighed = p['weighed'] != false;
    _hasIngredient = p['has_ingredient'] == true;

    _isActive = p['is_active'] ?? true;
    _sellPriceController.text = p['sell_price']?.toString() ?? '';
    _costPriceController.text = p['cost_price']?.toString() ?? '';
    _targetMarginController.text = p['target_margin_pct']?.toString() ?? '';
    _freezerMarkdownController.text =
        p['freezer_markdown_pct']?.toString() ?? '';
    _vatGroup = p['vat_group'] ?? 'standard';
    _stockControlType = p['stock_control_type'] ?? 'use_stock_control';
    _unitType = p['unit_type'] ?? 'kg';
    _allowFraction = p['allow_sell_by_fraction'] ?? true;
    _reorderController.text = p['reorder_level']?.toString() ?? '';
    _shelfLifeFreshController.text = p['shelf_life_fresh']?.toString() ?? '';
    _shelfLifeFrozenController.text =
        p['shelf_life_frozen']?.toString() ?? '';
    _slowMovingController.text =
        p['slow_moving_trigger_days']?.toString() ?? '3';
    _packSizeController.text = p['pack_size']?.toString() ?? '1';
    _storageLocationIds = List<String>.from(p['storage_location_ids'] ?? []);
    _carcassLinkId = p['carcass_link_id'] as String?;
    _dryerBiltongProduct = p['dryer_biltong_product'] as bool? ?? false;
    _shrinkageAllowancePct = (p['shrinkage_allowance_pct'] as num?)?.toDouble() ?? 2.0;
    _isFrozenVariant = p['is_frozen_variant'] as bool? ?? false;
    _minStockAlert = (widget.product?['min_stock_alert'] as num?)?.toDouble();
    _barcodePrefix = p['barcode_prefix'] as String?;
    _modifierGroupIds = List<String>.from(p['modifier_group_ids'] ?? []);
    _supplierIds = List<String>.from(p['supplier_ids'] ?? []);
    _recipeId = p['recipe_id'] as String?;
    _dryerProductType = p['dryer_product_type'] as String?;
    _manufacturedItem = p['manufactured_item'] as bool? ?? false;
    _loadRecipeCost(_recipeId);
    _internalNotesController.text = p['internal_notes'] ?? '';
    _dietaryTags = List<String>.from(p['dietary_tags'] ?? []);
    _allergenInfo = List<String>.from(p['allergen_info'] ?? []);
    _imageUrlController.text = p['image_url']?.toString() ?? '';
    // Channel availability — defaults: available_pos = true, others = false
    _availablePos = p['available_pos'] as bool? ?? true;
    _availableLoyaltyApp = p['available_loyalty_app'] as bool? ?? false;
    _availableOnline = p['available_online'] as bool? ?? false;
    _onlineDisplayNameController.text = p['online_display_name']?.toString() ?? '';
    _onlineDescriptionController.text = p['online_description']?.toString() ?? '';
    _onlineMinStockThresholdController.text = p['online_min_stock_threshold']?.toString() ?? '';
    _onlineSortOrderController.text = p['online_sort_order']?.toString() ?? '';
    _onlineImageUrlController.text = p['online_image_url']?.toString() ?? '';
    // New online store fields
    _isBestSeller = p['is_best_seller'] as bool? ?? false;
    _isFeatured = p['is_featured'] as bool? ?? false;
    _onlineWeightDescriptionController.text = p['online_weight_description']?.toString() ?? '';
    _onlineIngredientsController.text = p['online_ingredients']?.toString() ?? '';
    _onlineAllergensController.text = p['online_allergens']?.toString() ?? '';
    _onlineCookingTipsController.text = p['online_cooking_tips']?.toString() ?? '';
    
    // Parent Stock Link
    _parentStockItemId = p['parent_stock_item_id']?.toString();
    _stockDeductionQtyController.text = p['stock_deduction_qty']?.toString() ?? '';
    _stockDeductionUnit = p['stock_deduction_unit']?.toString() ?? 'kg';
    if (_parentStockItemId != null) {
      _loadParentStockItemDetails(_parentStockItemId!);
    }
    _productionParentItemId =
        p['production_parent_item_id']?.toString();
    if (_productionParentItemId != null) {
      _loadProductionParentItemDetails(_productionParentItemId!);
    }
  }

  Future<void> _confirmDeleteProduct(Map<String, dynamic> product) async {
    final name = product['name']?.toString() ?? 'Product';
    final pluCode = product['plu_code']?.toString() ?? '';
    final productId = product['id'];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Delete $name? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _supabase
          .from('inventory_items')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', product['id']);
      
      // Audit log - product deletion
      await AuditService.log(
        action: 'DELETE',
        module: 'Inventory',
        description: 'Product "$name" deactivated${pluCode.isNotEmpty ? " (PLU: $pluCode)" : ""}',
        entityType: 'Product',
        entityId: productId,
      );
      
      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final data = <String, dynamic>{
      'plu_code': int.tryParse(_pluController.text),
      'name': _nameController.text.trim(),
      'pos_display_name': _posNameController.text.trim().isEmpty
          ? _nameController.text.trim()
          : _posNameController.text.trim(),
      'scale_label_name': _scaleLabelController.text.trim().length > 16
          ? _scaleLabelController.text.trim().substring(0, 16)
          : _scaleLabelController.text.trim(),
      'barcode': _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
      'text_lookup_code': _lookupController.text.trim().toLowerCase().isEmpty ? null : _lookupController.text.trim().toLowerCase(),
      'category_id': _selectedCategoryId,
      'category': _selectedCategoryName ?? (_selectedCategoryId != null ? kCategoryIdToName[_selectedCategoryId] : null),
      'sub_category_id': _selectedSubCategoryId,
      'sub_category': _subCategoryName,
      'item_type': _itemType,
      'product_type': _productType,
      'scale_item': _scaleItem,
      'ishida_sync': _ishidaSync,
      'shelf_life_fresh': int.tryParse(_shelfLifeFreshController.text),
      'shelf_life_frozen': int.tryParse(_shelfLifeFrozenController.text),
      'scale_shelf_life': int.tryParse(_scaleShelfLifeController.text),
      'best_by': int.tryParse(_bestByController.text),
      'label_format': _labelFormatController.text.trim().isEmpty ? null : _labelFormatController.text.trim(),
      'bar_flag': _barFlagController.text.trim().isEmpty ? null : _barFlagController.text.trim(),
      'department_no': _departmentNoController.text.trim().isEmpty ? '1' : _departmentNoController.text.trim(),
      'des_li1': _desLi1Controller.text.trim().isEmpty ? null : _desLi1Controller.text.trim(),
      'des_li2': _desLi2Controller.text.trim().isEmpty ? null : _desLi2Controller.text.trim(),
      'des_li3': _desLi3Controller.text.trim().isEmpty ? null : _desLi3Controller.text.trim(),
      'des_li4': _desLi4Controller.text.trim().isEmpty ? null : _desLi4Controller.text.trim(),
      'weighed': _weighed,
      'has_ingredient': _hasIngredient,
      'is_active': _isActive,
      'sell_price': double.tryParse(_sellPriceController.text),
      'cost_price': _recipeId != null && _recipeCostPerKg != null
          ? _recipeCostPerKg!
          : double.tryParse(_costPriceController.text),
      'target_margin_pct': double.tryParse(_targetMarginController.text),
      'freezer_markdown_pct': double.tryParse(_freezerMarkdownController.text),
      'vat_group': _vatGroup,
      'stock_control_type': _stockControlType,
      'unit_type': _unitType,
      'allow_sell_by_fraction': _allowFraction,
      'reorder_level': double.tryParse(_reorderController.text),
      'shelf_life_fresh': int.tryParse(_shelfLifeFreshController.text),
      'shelf_life_frozen': int.tryParse(_shelfLifeFrozenController.text),
      'slow_moving_trigger_days': int.tryParse(_slowMovingController.text) ?? 3,
      'pack_size': double.tryParse(_packSizeController.text) ?? 1,
      'storage_location_ids': _storageLocationIds.isEmpty ? null : _storageLocationIds,
      'carcass_link_id': _carcassLinkId,
      'dryer_biltong_product': _dryerBiltongProduct,
      'barcode_prefix': _barcodePrefix,
      'modifier_group_ids': _modifierGroupIds.isEmpty ? null : _modifierGroupIds,
      'supplier_ids': _supplierIds.isEmpty ? null : _supplierIds,
      'recipe_id': _recipeId,
      'recipe_link': _recipeId != null
          ? _recipeNameForSelectedId
          : null,
      'dryer_product_type': _dryerProductType,
      'manufactured_item': _manufacturedItem,
      'shrinkage_allowance_pct': _shrinkageAllowancePct ?? 2.0,
      'min_stock_alert': _minStockAlert,
      'is_frozen_variant': _isFrozenVariant,
      'image_url': _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
      'dietary_tags': _dietaryTags.isEmpty ? null : _dietaryTags,
      'allergen_info': _allergenInfo.isEmpty ? null : _allergenInfo,
      'internal_notes': _internalNotesController.text.trim().isEmpty ? null : _internalNotesController.text.trim(),
      'available_pos': _availablePos,
      'available_loyalty_app': _availableLoyaltyApp,
      'available_online': _availableOnline,
      'online_display_name': _onlineDisplayNameController.text.trim().isEmpty ? null : _onlineDisplayNameController.text.trim(),
      'online_description': _onlineDescriptionController.text.trim().isEmpty ? null : _onlineDescriptionController.text.trim(),
      'online_min_stock_threshold': double.tryParse(_onlineMinStockThresholdController.text) ?? 0,
      'online_sort_order': int.tryParse(_onlineSortOrderController.text) ?? 0,
      'delivery_eligible': false, // Always false - controlled globally
      'online_image_url': _onlineImageUrlController.text.trim().isEmpty ? null : _onlineImageUrlController.text.trim(),
      'is_best_seller': _isBestSeller,
      'is_featured': _isFeatured,
      'online_weight_description': _onlineWeightDescriptionController.text.trim().isEmpty ? null : _onlineWeightDescriptionController.text.trim(),
      'online_ingredients': _onlineIngredientsController.text.trim().isEmpty ? null : _onlineIngredientsController.text.trim(),
      'online_allergens': _onlineAllergensController.text.trim().isEmpty ? null : _onlineAllergensController.text.trim(),
      'online_cooking_tips': _onlineCookingTipsController.text.trim().isEmpty ? null : _onlineCookingTipsController.text.trim(),
      'parent_stock_item_id': _parentStockItemId,
      'production_parent_item_id': _productionParentItemId,
      'stock_deduction_qty': double.tryParse(_stockDeductionQtyController.text),
      'stock_deduction_unit': _parentStockItemId != null ? _stockDeductionUnit : null,
      'price_last_changed': DateTime.now().toIso8601String(),
      'last_edited_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      if (widget.product == null) {
        // Ensure PLU is unique before insert
        var pluCode = int.tryParse(_pluController.text);
        if (pluCode != null) {
          final existing = await _supabase
              .from('inventory_items')
              .select('id')
              .eq('plu_code', pluCode)
              .maybeSingle();
          if (existing != null) {
            // Find next available PLU
            int candidate = pluCode + 1;
            bool found = false;
            while (candidate <= 9999) {
              final check = await _supabase
                  .from('inventory_items')
                  .select('id')
                  .eq('plu_code', candidate)
                  .maybeSingle();
              if (check == null) {
                pluCode = candidate;
                data['plu_code'] = pluCode;
                found = true;
                break;
              }
              candidate++;
            }
            if (!found) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No available PLU codes under 9999. Please assign manually.'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
              setState(() => _isSaving = false);
              return;
            }
          }
        }
        
        final result = await _supabase.from('inventory_items').insert(data).select().single();
        
        // Audit log - product creation
        await AuditService.log(
          action: 'CREATE',
          module: 'Inventory',
          description: 'Product "${data['name']}" created (PLU: ${data['plu_code']})',
          entityType: 'Product',
          entityId: result['id'],
          newValues: data,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product saved — PLU: ${data['plu_code']}'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        await _supabase
            .from('inventory_items')
            .update(data)
            .eq('id', widget.product!['id']);
        
        // Audit log - product update
        await AuditService.log(
          action: 'UPDATE',
          module: 'Inventory',
          description: 'Product "${data['name']}" updated (PLU: ${data['plu_code']})',
          entityType: 'Product',
          entityId: widget.product!['id'],
          oldValues: widget.product,
          newValues: data,
        );
      }

      // Save online product categories (delete all, then re-insert selected)
      final productId = widget.product?['id'] ?? data['id'];
      if (productId != null) {
        await _supabase
            .from('online_product_categories')
            .delete()
            .eq('inventory_item_id', productId);
        
        if (_selectedOnlineCategoryIds.isNotEmpty) {
          final categoryInserts = _selectedOnlineCategoryIds
              .map((catId) => {
                    'inventory_item_id': productId,
                    'category_id': catId,
                  })
              .toList();
          await _supabase.from('online_product_categories').insert(categoryInserts);
        }
      }

      await IsarService.clearInventoryItemsCache();
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.friendlyMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _onlineDisplayNameController.dispose();
    _onlineDescriptionController.dispose();
    _onlineMinStockThresholdController.dispose();
    _onlineSortOrderController.dispose();
    _onlineWeightDescriptionController.dispose();
    _onlineIngredientsController.dispose();
    _onlineAllergensController.dispose();
    _onlineCookingTipsController.dispose();
    _tabController.dispose();
    _pluController.dispose();
    _nameController.dispose();
    _posNameController.dispose();
    _scaleLabelController.dispose();
    _barcodeController.dispose();
    _lookupController.dispose();
    _scaleShelfLifeController.dispose();
    _bestByController.dispose();
    _labelFormatController.dispose();
    _barFlagController.dispose();
    _departmentNoController.dispose();
    _desLi1Controller.dispose();
    _desLi2Controller.dispose();
    _desLi3Controller.dispose();
    _desLi4Controller.dispose();
    _sellPriceController.dispose();
    _costPriceController.dispose();
    _targetMarginController.dispose();
    _freezerMarkdownController.dispose();
    _reorderController.dispose();
    _shelfLifeFreshController.dispose();
    _shelfLifeFrozenController.dispose();
    _slowMovingController.dispose();
    _packSizeController.dispose();
    _internalNotesController.dispose();
    _imageUrlController.dispose();
    _onlineImageUrlController.dispose();
    _parentStockSearchController.dispose();
    _stockDeductionQtyController.dispose();
    _parentStockDebounce?.cancel();
    _productionParentSearchController.dispose();
    _productionParentDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 760,
        height: 680,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(
                children: [
                  Icon(isEdit ? Icons.edit : Icons.add_circle,
                      color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    isEdit
                        ? 'Edit Product — PLU ${widget.product!['plu_code']}'
                        : 'Add New Product',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (isEdit)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                      onPressed: () => _confirmDeleteProduct(widget.product!),
                      tooltip: 'Delete product',
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              isScrollable: true,
              tabs: const [
                Tab(text: 'A — Identity'),
                Tab(text: 'B — Pricing'),
                Tab(text: 'C — Stock'),
                Tab(text: 'D — Barcode/Scale'),
                Tab(text: 'E — Modifiers'),
                Tab(text: 'F — Production'),
                Tab(text: 'G — Scale/Label'),
                Tab(text: 'H — Media/Notes'),
                Tab(text: 'I — Activity'),
                Tab(text: 'J — Online Shop'),
              ],
            ),
            const Divider(height: 1, color: AppColors.border),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabA(),
                    _buildTabB(),
                    _buildTabC(),
                    _buildTabD(),
                    _buildTabE(),
                    _buildTabF(),
                    _buildTabG(),
                    _buildTabH(),
                    _buildTabI(),
                    _buildTabJ(),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Switch(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    activeThumbColor: AppColors.success,
                  ),
                  Text(
                    _isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color:
                          _isActive ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(isEdit ? 'Save Changes' : 'Add Product'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabA() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _field(
                  label: 'PLU Code *',
                  controller: _pluController,
                  hint: '1001',
                  keyboardType: TextInputType.number,
                  enabled: widget.product == null,
                  note: widget.product != null
                      ? 'PLU cannot be changed after creation'
                      : 'Unique — cashier shortcut & scale code',
                  validator: (v) =>
                      v == null || v.isEmpty ? 'PLU required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _field(
                  label: 'Full Name *',
                  controller: _nameController,
                  hint: 'T-Bone Steak',
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Name required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _field(
                  label: 'POS Display Name',
                  controller: _posNameController,
                  hint: 'T-Bone Steak (max 20 chars)',
                  maxLength: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _field(
                  label: 'Scale Label Name',
                  controller: _scaleLabelController,
                  hint: 'T-Bone Steak (max 16 chars)',
                  maxLength: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Category',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String?>(
                      value: _selectedCategoryId,
                      isExpanded: true,
                      decoration: const InputDecoration(isDense: true),
                      hint: const Text('Select category'),
                      items: _topLevelCategories
                          .map((c) => DropdownMenuItem<String?>(
                                value: c['id']?.toString(),
                                child: Text((c['name'] as String? ?? ''), overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedCategoryId = v;
                          _selectedSubCategoryId = null;
                          _subCategoryName = null;
                          if (v == null) {
                            _selectedCategoryName = null;
                          } else {
                            String? name;
                            for (final c in widget.categories) {
                              if (c['id']?.toString() == v) {
                                name = c['name'] as String?;
                                break;
                              }
                            }
                            _selectedCategoryName = name ?? kCategoryIdToName[v];
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sub-Category',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String?>(
                      value: _selectedSubCategoryId,
                      isExpanded: true,
                      decoration: const InputDecoration(isDense: true),
                      hint: const Text('None'),
                      items: _subCategoryDropdownItems,
                      onChanged: (v) {
                        setState(() {
                          _selectedSubCategoryId = v;
                          if (v == null) {
                            _subCategoryName = null;
                          } else {
                            for (final c in widget.categories) {
                              if (c['id']?.toString() == v) {
                                _subCategoryName = c['name'] as String?;
                                break;
                              }
                            }
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Item Type',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _itemType,
                      isExpanded: true,
                      decoration: const InputDecoration(isDense: true),
                      items: const [
                        DropdownMenuItem(
                            value: 'own_cut', child: Text('Own Cut')),
                        DropdownMenuItem(
                            value: 'own_processed',
                            child: Text('Own Processed')),
                        DropdownMenuItem(
                            value: 'third_party_resale',
                            child: Text('Third Party Resale')),
                        DropdownMenuItem(
                            value: 'service', child: Text('Service')),
                        DropdownMenuItem(
                            value: 'packaging', child: Text('Packaging')),
                        DropdownMenuItem(
                            value: 'internal', child: Text('Internal')),
                      ],
                      onChanged: (v) => setState(() => _itemType = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Product Type (H9)',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _productType,
                      isExpanded: true,
                      decoration: const InputDecoration(isDense: true),
                      items: const [
                        DropdownMenuItem(value: 'raw', child: Text('Raw (no processing)')),
                        DropdownMenuItem(value: 'portioned', child: Text('Portioned')),
                        DropdownMenuItem(value: 'manufactured', child: Text('Manufactured (recipe-based)')),
                      ],
                      onChanged: (v) => setState(() => _productType = v ?? 'raw'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Supplier Link',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          // Selected suppliers as removable chips
          if (_supplierIds.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _supplierIds.map((id) {
                final supplier = _allSuppliers.firstWhere(
                  (s) => s['id'] == id,
                  orElse: () => {'id': id, 'name': id},
                );
                return Chip(
                  label: Text(supplier['name'] as String? ?? id,
                      style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => setState(() => _supplierIds.remove(id)),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                );
              }).toList(),
            ),
          const SizedBox(height: 8),
          // Dropdown to add a supplier
          Autocomplete<Map<String, dynamic>>(
            displayStringForOption: (s) => s['name'] as String? ?? '',
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return _allSuppliers
                    .where((s) => !_supplierIds.contains(s['id'] as String?));
              }
              final query = textEditingValue.text.toLowerCase();
              return _allSuppliers.where((s) {
                final name = (s['name'] as String? ?? '').toLowerCase();
                return name.contains(query) &&
                    !_supplierIds.contains(s['id'] as String?);
              });
            },
            onSelected: (s) {
              final id = s['id'] as String?;
              if (id != null && !_supplierIds.contains(id)) {
                setState(() => _supplierIds.add(id));
              }
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmit) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  hintText: 'Search supplier...',
                  prefixIcon: Icon(Icons.search, size: 18),
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                        maxHeight: 200, maxWidth: 400),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final s = options.elementAt(index);
                        return ListTile(
                          dense: true,
                          title: Text(s['name'] as String? ?? ''),
                          onTap: () => onSelected(s),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          // H6: Supplier product mapping (product_suppliers) — only when editing
          const SizedBox(height: 20),
          const Text('Supplier product mapping (H6)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          if (widget.product == null)
            const Text(
              'Save the product first to add supplier-specific codes and pricing.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            )
          else ...[
            ..._productSupplierRows.map((row) {
              final supplierName = row['suppliers'] is Map
                  ? (row['suppliers'] as Map)['name'] as String?
                  : null;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(supplierName ?? row['supplier_product_name']?.toString() ?? 'Supplier'),
                  subtitle: Text(
                    '${row['supplier_product_code'] ?? ''} • R ${row['unit_price'] ?? '—'}${row['is_preferred'] == true ? ' • Preferred' : ''}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _openProductSupplierDialog(row),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppColors.danger),
                        onPressed: () => _deleteProductSupplier(row),
                        tooltip: 'Remove',
                      ),
                    ],
                  ),
                ),
              );
            }),
            OutlinedButton.icon(
              onPressed: () => _openProductSupplierDialog(null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add supplier mapping'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openProductSupplierDialog(Map<String, dynamic>? existing) async {
    await showDialog(
      context: context,
      builder: (_) => _ProductSupplierMappingDialog(
        inventoryItemId: widget.product!['id'] as String,
        existing: existing,
        suppliers: _allSuppliers,
        onSaved: _loadProductSuppliers,
      ),
    );
  }

  Future<void> _deleteProductSupplier(Map<String, dynamic> row) async {
    final id = row['id'] as String?;
    final supplierId = row['supplier_id']?.toString();
    if (id == null) return;
    final supplierName = row['suppliers'] is Map
        ? (row['suppliers'] as Map)['name'] as String?
        : row['supplier_product_name']?.toString();
    final name = supplierName ?? 'this supplier';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove supplier mapping?'),
        content: Text('Remove $name from this product?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _supabase.from('product_suppliers').delete().eq('id', id);
      if (mounted) {
        await _loadProductSuppliers();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supplier mapping removed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.danger));
      }
    }
  }

  Widget _buildTabB() {
    final sell = double.tryParse(_sellPriceController.text) ?? 0;
    final cost = (_recipeId != null && _recipeCostPerKg != null)
        ? _recipeCostPerKg!
        : (double.tryParse(_costPriceController.text) ?? 0);
    final gp = sell > 0 ? ((sell - cost) / sell * 100) : 0.0;
    final markup = cost > 0 ? ((sell - cost) / cost * 100) : 0.0;
    final target = double.tryParse(_targetMarginController.text) ?? 30.0;
    final recommended = cost > 0 && target < 100
        ? cost / (1 - target / 100)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _field(
                  label: 'Sell Price (R) *',
                  controller: _sellPriceController,
                  hint: '120.00',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _recipeId != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cost Price (R)',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: _recipeCostLoading
                                ? const Text('Calculating…', style: TextStyle(color: AppColors.textSecondary))
                                : Text(
                                    'Auto (from recipe): R ${_recipeCostPerKg?.toStringAsFixed(2) ?? '—'}',
                                    style: const TextStyle(color: AppColors.textSecondary),
                                  ),
                          ),
                        ],
                      )
                    : _field(
                        label: 'Cost Price (R)',
                        controller: _costPriceController,
                        hint: '72.00',
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _field(
                  label: 'Target Margin %',
                  controller: _targetMarginController,
                  hint: '30',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Auto-calculated
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _calcStat('GP %', '${gp.toStringAsFixed(1)}%',
                    gp >= target ? AppColors.success : AppColors.error),
                const SizedBox(width: 24),
                _calcStat('Markup %', '${markup.toStringAsFixed(1)}%',
                    AppColors.textPrimary),
                const SizedBox(width: 24),
                _calcStat(
                    'Recommended Price',
                    recommended > 0 ? 'R ${recommended.toStringAsFixed(2)}' : '—',
                    AppColors.info),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _field(
                  label: 'Freezer Markdown % (per product)',
                  controller: _freezerMarkdownController,
                  hint: '20',
                  note: 'Owner sets per product — NOT a system default',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('VAT Group',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _vatGroup,
                      decoration: const InputDecoration(isDense: true),
                      items: const [
                        DropdownMenuItem(
                            value: 'standard',
                            child: Text('Standard (15%)')),
                        DropdownMenuItem(
                            value: 'zero_rated',
                            child: Text('Zero-Rated (0%)')),
                        DropdownMenuItem(
                            value: 'exempt', child: Text('Exempt (0%)')),
                      ],
                      onChanged: (v) => setState(() => _vatGroup = v!),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabC() {
    // Read current stock values from the loaded product map (read-only display)
    final double freshStock = (widget.product?['stock_on_hand_fresh'] as num?)?.toDouble() ?? 0.0;
    final double frozenStock = (widget.product?['stock_on_hand_frozen'] as num?)?.toDouble() ?? 0.0;
    final double totalStock = freshStock + frozenStock;
    final String unitLabel = _unitType;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── SECTION: CURRENT STOCK LEVELS ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Stock Levels',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _readOnlyStockTile(
                        label: 'Fresh / On Display',
                        value: '${freshStock.toStringAsFixed(2)} $unitLabel',
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _readOnlyStockTile(
                        label: 'Frozen',
                        value: '${frozenStock.toStringAsFixed(2)} $unitLabel',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _readOnlyStockTile(
                        label: 'Total On Hand',
                        value: '${totalStock.toStringAsFixed(2)} $unitLabel',
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.tune, size: 16),
                    label: const Text('Adjust Stock'),
                    onPressed: () => _showStockAdjustDialog(freshStock, frozenStock),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── SECTION: STOCK SETTINGS ─────────────────────────────────────
          const Text('Stock Settings',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Stock Control Type',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _stockControlType,
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          items: const [
                            DropdownMenuItem(
                                value: 'use_stock_control',
                                child: Text('Use Stock Control')),
                            DropdownMenuItem(
                                value: 'no_stock_control',
                                child: Text('No Stock Control')),
                            DropdownMenuItem(
                                value: 'recipe_based',
                                child: Text('Recipe Based')),
                            DropdownMenuItem(
                                value: 'carcass_linked',
                                child: Text('Carcass Linked')),
                            DropdownMenuItem(
                                value: 'hanger_count',
                                child: Text('Hanger Count')),
                          ],
                          onChanged: (v) => setState(() => _stockControlType = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Unit Type',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _unitType,
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'kg', child: Text('kg')),
                            DropdownMenuItem(value: 'units', child: Text('Units')),
                            DropdownMenuItem(value: 'packs', child: Text('Packs')),
                          ],
                          onChanged: (v) => setState(() => _unitType = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Allow Sell by Fraction',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Switch(
                              value: _allowFraction,
                              onChanged: (v) => setState(() => _allowFraction = v),
                              activeColor: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(_allowFraction ? 'Yes' : 'No',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Frozen Variant',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Switch(
                              value: _isFrozenVariant,
                              onChanged: (v) =>
                                  setState(() => _isFrozenVariant = v),
                              activeColor: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _isFrozenVariant
                                    ? 'Yes — deducts frozen'
                                    : 'No — deducts fresh',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _field(
                  label: 'Pack Size (units per pack)',
                  controller: _packSizeController,
                  hint: '1',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Shrinkage Allowance %',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue:
                          _shrinkageAllowancePct?.toString() ?? '2.0',
                      decoration: const InputDecoration(
                          isDense: true, hintText: '2.0'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      onChanged: (v) => setState(
                          () => _shrinkageAllowancePct = double.tryParse(v)),
                    ),
                    const SizedBox(height: 4),
                    const Text('Natural loss % before theft alert triggers',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── SECTION: ALERTS & THRESHOLDS ────────────────────────────────
          const Text('Alerts & Thresholds',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _field(
                  label: 'Reorder Level',
                  controller: _reorderController,
                  hint: '5.0',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  note: 'Triggers reorder alert on dashboard',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Minimum Stock Alert',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue: _minStockAlert?.toString() ?? '',
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'e.g. 2.0',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      onChanged: (v) => setState(
                          () => _minStockAlert = double.tryParse(v)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                        'Critical low threshold — triggers predictive order alert',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _field(
                  label: 'Slow Moving Trigger (days)',
                  controller: _slowMovingController,
                  hint: '3',
                  keyboardType: TextInputType.number,
                  note: 'Days without sale = slow-moving alert',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _field(
                  label: 'Shelf Life Fresh (days)',
                  controller: _shelfLifeFreshController,
                  hint: '3',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _field(
                  label: 'Shelf Life Frozen (days)',
                  controller: _shelfLifeFrozenController,
                  hint: '90',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(child: SizedBox()),
            ],
          ),

          const SizedBox(height: 24),

          // ── SECTION: LINKING ────────────────────────────────────────────
          const Text('Linking',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Switch(
                value: _dryerBiltongProduct,
                onChanged: (v) =>
                    setState(() => _dryerBiltongProduct = v),
                activeColor: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text('Dryer/Biltong Product (links to Dryer module)',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabD() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field(
            label: 'Standard Barcode (EAN-13)',
            controller: _barcodeController,
            hint: '6001234567890',
            note: 'For non-scale packaged items',
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Barcode Prefix (Ishida)',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _barcodePrefix,
                decoration: const InputDecoration(isDense: true),
                hint: const Text('None'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('None')),
                  DropdownMenuItem(value: '20', child: Text('20 (weight)')),
                  DropdownMenuItem(value: '21', child: Text('21 (price)')),
                ],
                onChanged: (v) => setState(() => _barcodePrefix = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Scale Item (Ishida)',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Switch(
                          value: _scaleItem,
                          onChanged: (v) =>
                              setState(() => _scaleItem = v),
                          activeThumbColor: AppColors.primary,
                        ),
                        Text(
                          _scaleItem ? 'Yes' : 'No',
                          style: const TextStyle(
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ishida Scale Sync',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Switch(
                          value: _ishidaSync,
                          onChanged: (v) =>
                              setState(() => _ishidaSync = v),
                          activeThumbColor: AppColors.primary,
                        ),
                        Text(
                          _ishidaSync ? 'Sync ON' : 'Sync OFF',
                          style: const TextStyle(
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _field(
            label: 'Text Lookup Code',
            controller: _lookupController,
            hint: 'tbone — alternative search keyword for POS',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    color: AppColors.info, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PLU Code = Scale Code. The PLU number is NEVER changed after creation — it is the Ishida scale code and cashier shortcut.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabE() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Modifier Group Linking',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'When this product is sold, show these modifier pop-ups at POS.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allModifierGroups.map((g) {
              final id = g['id'] as String?;
              final name = g['name'] as String? ?? '';
              final selected = id != null && _modifierGroupIds.contains(id);
              return FilterChip(
                label: Text(name),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v && id != null) {
                      _modifierGroupIds.add(id);
                    } else if (id != null) {
                      _modifierGroupIds.remove(id);
                    }
                  });
                },
              );
            }).toList(),
          ),
          if (_allModifierGroups.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'No modifier groups. Create groups in Inventory → Modifiers.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabF() {
    Map<String, dynamic>? selectedRecipe;
    if (_recipeId != null) {
      try {
        selectedRecipe = _recipes.firstWhere((r) => r['id']?.toString() == _recipeId);
      } catch (_) {}
    }
    final recipeName = selectedRecipe?['name'] as String? ?? '';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Recipe Link (Own-Processed)',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _recipeId,
                isExpanded: true,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Recipe Link (Own-Processed)',
                ),
                hint: const Text('None'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ..._recipes.map((r) => DropdownMenuItem<String>(
                        value: r['id'] as String?,
                        child: Text(r['name'] as String? ?? 'Unnamed'),
                      )),
                ],
                onChanged: (v) {
                  setState(() => _recipeId = v);
                  if (v != null) _loadRecipeCost(v);
                },
              ),
              if (_recipeId != null && recipeName.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Recipe: $recipeName${_recipeCostPerKg != null ? ' | Est. cost/kg: R ${_recipeCostPerKg!.toStringAsFixed(2)}' : _recipeCostLoading ? ' | Calculating…' : ''}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Dryer/Biltong Product Type',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _dryerProductType,
                decoration: const InputDecoration(isDense: true),
                hint: const Text('None'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('None')),
                  DropdownMenuItem(value: 'biltong', child: Text('Biltong')),
                  DropdownMenuItem(value: 'droewors', child: Text('Droëwors')),
                  DropdownMenuItem(value: 'snap_sticks', child: Text('Snap Sticks')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _dryerProductType = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Switch(
                value: _manufacturedItem,
                onChanged: (v) => setState(() => _manufacturedItem = v),
                activeThumbColor: AppColors.primary,
              ),
              const Text(
                'Manufactured Item (cost-of-production tracking)',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabG() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Scale Behaviour ──────────────────────────────
          _sectionHeader('SCALE BEHAVIOUR'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  title: const Text('Weighed Item'),
                  subtitle: const Text('Scale weighs this item'),
                  value: _weighed,
                  onChanged: (v) => setState(() => _weighed = v),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SwitchListTile(
                  title: const Text('Has Ingredient List'),
                  subtitle: const Text('Ingredient label required'),
                  value: _hasIngredient,
                  onChanged: (v) => setState(() => _hasIngredient = v),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Shelf Life ───────────────────────────────────
          _sectionHeader('SHELF LIFE'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _field(
                  label: 'Shelf Life Fresh (days)',
                  controller: _shelfLifeFreshController,
                  hint: '5',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _field(
                  label: 'Shelf Life Frozen (days)',
                  controller: _shelfLifeFrozenController,
                  hint: '90',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _field(
                  label: 'Scale Shelf Life (days)',
                  controller: _scaleShelfLifeController,
                  hint: '15',
                  keyboardType: TextInputType.number,
                  note: 'Printed on scale label',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _field(
                  label: 'Best By (days)',
                  controller: _bestByController,
                  hint: '0',
                  keyboardType: TextInputType.number,
                  note: 'Scale best-by offset',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Label Format ─────────────────────────────────
          _sectionHeader('LABEL FORMAT'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _field(
                  label: 'Label Format',
                  controller: _labelFormatController,
                  hint: '005',
                  note: 'e.g. 005, 010, 015, 020',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _field(
                  label: 'Bar Flag',
                  controller: _barFlagController,
                  hint: '21',
                  note: 'Barcode flag / dept code',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _field(
                  label: 'Department No',
                  controller: _departmentNoController,
                  hint: '1',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Description Lines ────────────────────────────
          _sectionHeader('SCALE DESCRIPTION LINES'),
          const SizedBox(height: 8),
          const Text(
            'Up to 4 lines printed on the scale label. Line 1 is the product name by default.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _field(
                  label: 'Description Line 1',
                  controller: _desLi1Controller,
                  hint: 'e.g. T-Bone Steak',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _field(
                  label: 'Description Line 2',
                  controller: _desLi2Controller,
                  hint: 'e.g. Beef',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _field(
                  label: 'Description Line 3',
                  controller: _desLi3Controller,
                  hint: '',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _field(
                  label: 'Description Line 4',
                  controller: _desLi4Controller,
                  hint: '',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── PLU Export Preview ───────────────────────────
          _sectionHeader('PLU EXPORT PREVIEW'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _buildPluPreview(),
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Colors.greenAccent,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }

  String _buildPluPreview() {
    final plu = _pluController.text.padLeft(8, '0');
    final dept = _departmentNoController.text.isEmpty ? '1' : _departmentNoController.text;
    final barFlag = _barFlagController.text.isEmpty ? '21' : _barFlagController.text;
    final eanNo = _pluController.text.padLeft(5, '0');
    final price = (double.tryParse(_sellPriceController.text) ?? 0.0).toStringAsFixed(2);
    final labelFmt = _labelFormatController.text.isEmpty ? '005' : _labelFormatController.text;
    final shelfLife = _scaleShelfLifeController.text.isEmpty ? '000' : _scaleShelfLifeController.text.padLeft(3, '0');
    final bestBy = _bestByController.text.isEmpty ? '0000' : _bestByController.text.padLeft(4, '0');
    final weighed = _weighed ? '0' : '1';
    final cdv = '0';
    final des1 = _desLi1Controller.text.isEmpty ? (_scaleLabelController.text.isEmpty ? _nameController.text : _scaleLabelController.text) : _desLi1Controller.text;
    final des2 = _desLi2Controller.text;
    final hasIng = _hasIngredient ? 'TRUE' : 'FALSE';
    return '$plu,$dept,DEPT1,01,$barFlag,$eanNo,$price,,$shelfLife,$bestBy,$weighed,$cdv,7,$des1,,$des2,,,,,$hasIng,,';
  }

  Widget _buildTabH() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field(
            label: 'Image URL (optional)',
            controller: _imageUrlController,
            hint: 'https://... or leave empty — shown on POS grid button',
          ),
          const SizedBox(height: 16),
          const Text('Dietary Tags',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _dietaryOptions.map((tag) {
              final selected = _dietaryTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) _dietaryTags.add(tag);
                    else _dietaryTags.remove(tag);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Allergen Info',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allergenOptions.map((tag) {
              final selected = _allergenInfo.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) _allergenInfo.add(tag);
                    else _allergenInfo.remove(tag);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _field(
            label: 'Internal Notes (Owner/Manager only)',
            controller: _internalNotesController,
            hint: 'Not on receipts or POS',
            maxLength: 500,
          ),
        ],
      ),
    );
  }

  Widget _buildTabI() {
    final lastEdited = widget.product?['last_edited_at'] != null
        ? DateTime.tryParse(widget.product!['last_edited_at'] as String)
        : null;
    final lastEditedBy = widget.product?['last_edited_by'] as String?;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.product != null) ...[
            const Text('Item Activity Log',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            if (lastEdited != null || lastEditedBy != null)
              Text(
                'Last edited: ${lastEdited?.toString().substring(0, 16) ?? '—'} ${lastEditedBy != null ? '($lastEditedBy)' : ''}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              )
            else
              const Text(
                'No edit history yet.',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                showMovementHistoryDialog(context, product: widget.product!);
              },
              icon: const Icon(Icons.history, size: 18),
              label: const Text('View Item Activity / Movement History'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Price history — link to audit log by PLU')),
                );
              },
              icon: const Icon(Icons.trending_up, size: 18),
              label: const Text('View Price History'),
            ),
          ] else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Save the product first to see activity log.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabJ() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            title: const Text('Available on POS / Till'),
            value: _availablePos,
            onChanged: (v) => setState(() => _availablePos = v),
            activeColor: AppColors.success,
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(height: 32),
          // SECTION: Store Listing
          const Text(
            'Store Listing',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Show in online store'),
            value: _availableOnline,
            onChanged: (v) => setState(() => _availableOnline = v),
            activeColor: AppColors.success,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Show in loyalty app'),
            value: _availableLoyaltyApp,
            onChanged: (v) => setState(() => _availableLoyaltyApp = v),
            activeColor: AppColors.success,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _onlineDisplayNameController,
            decoration: const InputDecoration(
              labelText: 'Display name in store',
              hintText: 'Leave blank to use product name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _onlineWeightDescriptionController,
            decoration: const InputDecoration(
              labelText: 'Weight / size description',
              hintText: 'e.g. ±450g per pack, 6 per pack',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _sellPriceController,
            decoration: const InputDecoration(
              labelText: 'Store price (R)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _onlineSortOrderController,
            decoration: const InputDecoration(
              labelText: 'Sort order',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Mark as best seller'),
            value: _isBestSeller,
            onChanged: (v) => setState(() => _isBestSeller = v),
            activeColor: AppColors.success,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Mark as featured'),
            value: _isFeatured,
            onChanged: (v) => setState(() => _isFeatured = v),
            activeColor: AppColors.success,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _onlineMinStockThresholdController,
            decoration: const InputDecoration(
              labelText: 'Min stock before hiding from store',
              hintText: 'Product hides when stock falls to or below this number',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const Divider(height: 48),
          
          // SECTION: Product Label
          const Text(
            'Product Label',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _onlineIngredientsController,
            decoration: const InputDecoration(
              labelText: 'Ingredients',
              hintText: 'e.g. Lamb, Salt, Pepper, Rosemary',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _onlineAllergensController,
            decoration: const InputDecoration(
              labelText: 'Allergens',
              hintText: 'e.g. Contains: Gluten, Soy',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _onlineCookingTipsController,
            decoration: const InputDecoration(
              labelText: 'Cooking tips',
              hintText: 'e.g. Pan fry on medium heat for 4 min per side',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          // Live preview card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _onlineDisplayNameController.text.isEmpty
                      ? _nameController.text
                      : _onlineDisplayNameController.text,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (_onlineWeightDescriptionController.text.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _onlineWeightDescriptionController.text,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                if (_onlineIngredientsController.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Ingredients:', style: TextStyle(fontSize: 12)),
                  Text(
                    _onlineIngredientsController.text,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
                if (_onlineAllergensController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _onlineAllergensController.text,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
                if (_onlineCookingTipsController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Cooking Tips:', style: TextStyle(fontSize: 12)),
                  Text(
                    _onlineCookingTipsController.text,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 48),
          
          // SECTION: Categories
          const Text(
            'Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select which online store categories this product belongs to',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _onlineCategories.map((cat) {
              final catId = cat['id']?.toString() ?? '';
              final catName = cat['name']?.toString() ?? '';
              final isSelected = _selectedOnlineCategoryIds.contains(catId);
              return FilterChip(
                label: Text(catName),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedOnlineCategoryIds.add(catId);
                    } else {
                      _selectedOnlineCategoryIds.remove(catId);
                    }
                  });
                },
                selectedColor: AppColors.primary.withOpacity(0.2),
              );
            }).toList(),
          ),
          const Divider(height: 48),
          
          // SECTION: Recipes
          const Text(
            'Recipes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          const Text(
            'First 2 recipes shown in store',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (_linkedRecipes.isEmpty)
            const Text(
              'No recipes linked',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            )
          else
            ..._linkedRecipes.asMap().entries.map((entry) {
              final idx = entry.key;
              final recipe = entry.value;
              final recipeData = recipe['customer_recipes'] as Map?;
              final title = recipeData?['title']?.toString() ?? 'Unknown';
              final displayOrder = recipe['display_order'] ?? (idx + 1);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('$displayOrder'),
                  ),
                  title: Text(title),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: () async {
                      await _supabase
                          .from('online_product_recipes')
                          .delete()
                          .eq('id', recipe['id']);
                      _loadLinkedRecipes();
                    },
                  ),
                ),
              );
            }),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final selected = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Add Recipe'),
                  content: SizedBox(
                    width: 400,
                    height: 400,
                    child: ListView.builder(
                      itemCount: _allCustomerRecipes.length,
                      itemBuilder: (ctx, i) {
                        final recipe = _allCustomerRecipes[i];
                        return ListTile(
                          title: Text(recipe['title'] ?? ''),
                          onTap: () => Navigator.pop(ctx, recipe),
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              );
              if (selected != null && widget.product != null) {
                final nextOrder = _linkedRecipes.isEmpty
                    ? 1
                    : (_linkedRecipes.map((r) => r['display_order'] as int? ?? 0).reduce((a, b) => a > b ? a : b) + 1);
                await _supabase.from('online_product_recipes').insert({
                  'inventory_item_id': widget.product!['id'],
                  'customer_recipe_id': selected['id'],
                  'display_order': nextOrder,
                });
                _loadLinkedRecipes();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Recipe'),
          ),
          const Divider(height: 48),
          
          // SECTION: Product Image
          const Text(
            'Product Image',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          if (_onlineImageUrlController.text.isNotEmpty)
            Column(
              children: [
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _onlineImageUrlController.text,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 250,
                        color: Colors.grey[300],
                        child: const Center(child: Text('Image load error')),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _onlineImageUrlController.clear());
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Remove Image'),
                ),
              ],
            ),
          const SizedBox(height: 16),
          
          // Upload Button
          _isUploadingImage
              ? const Center(child: CircularProgressIndicator())
              : OutlinedButton.icon(
                  onPressed: _uploadProductImage,
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload Product Image'),
                ),
          const Divider(height: 48),

          // SECTION: Production / Carcass Source Link
          const SizedBox(height: 32),
          const Text(
            'Production Source Link',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Link this product to the bulk or carcass item it is cut or '
            'yielded from. Used by the carcass breakdown and production '
            'screens to track yield sources. This is separate from the '
            'online order stock deduction link below.',
            style: TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _productionParentSearchController,
            decoration: const InputDecoration(
              labelText: 'Search source item by name or PLU',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _searchProductionParentItems,
          ),
          if (_productionParentSearchResults.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _productionParentSearchResults.length,
                itemBuilder: (context, index) {
                  final item = _productionParentSearchResults[index];
                  return ListTile(
                    title: Text(item['name']?.toString() ?? ''),
                    subtitle: Text('PLU: ${item['plu_code']}'),
                    onTap: () {
                      setState(() {
                        _productionParentItemId =
                            item['id']?.toString();
                        _productionParentItemName =
                            item['name']?.toString();
                        _productionParentItemPlu =
                            item['plu_code']?.toString();
                        _productionParentSearchController.clear();
                        _productionParentSearchResults = [];
                      });
                    },
                  );
                },
              ),
            ),
          ],
          if (_productionParentItemId != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Chip(
                    label: Text(
                      '${_productionParentItemName ?? 'Unknown'} '
                      '(PLU: ${_productionParentItemPlu ?? 'N/A'})',
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                        _productionParentItemId = null;
                        _productionParentItemName = null;
                        _productionParentItemPlu = null;
                        _productionParentSearchController.clear();
                        _productionParentSearchResults = [];
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 32),

          // SECTION: Parent Stock Link
          const Text(
            'Parent Stock Link',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Link this product to a bulk inventory item. When an online order is confirmed, the deduction quantity will be removed from the parent item\'s stock.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          
          // Parent stock item search
          TextFormField(
            controller: _parentStockSearchController,
            decoration: InputDecoration(
              labelText: 'Search parent product by name or PLU',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _parentStockSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _parentStockSearchController.clear();
                          _parentStockSearchResults = [];
                        });
                      },
                    )
                  : null,
            ),
            onChanged: _searchParentStockItems,
          ),
          
          // Search results dropdown
          if (_parentStockSearchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _parentStockSearchResults.length,
                itemBuilder: (context, index) {
                  final item = _parentStockSearchResults[index];
                  return ListTile(
                    dense: true,
                    title: Text('${item['name']}'),
                    subtitle: Text('PLU: ${item['plu_code']}'),
                    onTap: () {
                      setState(() {
                        _parentStockItemId = item['id']?.toString();
                        _parentStockItemName = item['name'] as String?;
                        _parentStockItemPlu = item['plu_code']?.toString();
                        _parentStockSearchController.clear();
                        _parentStockSearchResults = [];
                      });
                    },
                  );
                },
              ),
            ),
          ],
          
          // Selected parent item chip
          if (_parentStockItemId != null) ...[
            const SizedBox(height: 16),
            Chip(
              avatar: const Icon(Icons.link, size: 18),
              label: Text('${_parentStockItemName ?? 'Unknown'} (PLU: ${_parentStockItemPlu ?? 'N/A'})'),
              deleteIcon: const Icon(Icons.close),
              onDeleted: () {
                setState(() {
                  _parentStockItemId = null;
                  _parentStockItemName = null;
                  _parentStockItemPlu = null;
                  _stockDeductionQtyController.clear();
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Deduction quantity
            TextFormField(
              controller: _stockDeductionQtyController,
              decoration: const InputDecoration(
                labelText: 'Deduction quantity per unit sold',
                hintText: 'e.g. 0.280 for 280g',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            
            // Deduction unit dropdown
            DropdownButtonFormField<String>(
              value: _stockDeductionUnit,
              decoration: const InputDecoration(
                labelText: 'Deduction unit',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'g', child: Text('g (grams)')),
                DropdownMenuItem(value: 'kg', child: Text('kg (kilograms)')),
                DropdownMenuItem(value: 'units', child: Text('units')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _stockDeductionUnit = value);
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _readOnlyStockTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }

  Future<void> _showStockAdjustDialog(
      double currentFresh, double currentFrozen) async {
    final adjustQtyController = TextEditingController();
    String adjustType = 'fresh';
    String adjustReason = 'count_correction';
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Adjust Stock'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current levels summary
                Row(
                  children: [
                    Expanded(
                      child: _readOnlyStockTile(
                        label: 'Current Fresh',
                        value: '${currentFresh.toStringAsFixed(2)} $_unitType',
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _readOnlyStockTile(
                        label: 'Current Frozen',
                        value: '${currentFrozen.toStringAsFixed(2)} $_unitType',
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stock type
                const Text('Adjust Which Stock?',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: adjustType,
                  decoration: const InputDecoration(isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'fresh', child: Text('Fresh / On Display')),
                    DropdownMenuItem(value: 'frozen', child: Text('Frozen')),
                  ],
                  onChanged: (v) => setDlg(() => adjustType = v!),
                ),
                const SizedBox(height: 12),
                // Reason
                const Text('Reason',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: adjustReason,
                  decoration: const InputDecoration(isDense: true),
                  items: const [
                    DropdownMenuItem(
                        value: 'count_correction',
                        child: Text('Count Correction')),
                    DropdownMenuItem(
                        value: 'received_delivery',
                        child: Text('Received Delivery')),
                    DropdownMenuItem(value: 'waste', child: Text('Waste / Spoilage')),
                    DropdownMenuItem(
                        value: 'staff_meal', child: Text('Staff Meal')),
                    DropdownMenuItem(
                        value: 'donation', child: Text('Donation')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setDlg(() => adjustReason = v!),
                ),
                const SizedBox(height: 12),
                // Quantity — positive to add, negative to subtract
                const Text('Quantity (+ to add, − to subtract)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: adjustQtyController,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'e.g. 5.0 or -2.5',
                    suffixText: _unitType,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true, signed: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final qty =
                          double.tryParse(adjustQtyController.text.trim());
                      if (qty == null || qty == 0) return;

                      final productId = widget.product?['id']?.toString();
                      if (productId == null) return;

                      setDlg(() => isSaving = true);

                      try {
                        final double currentVal =
                            adjustType == 'fresh' ? currentFresh : currentFrozen;
                        final double newVal =
                            (currentVal + qty).clamp(0.0, double.infinity);

                        final movement = {
                          'item_id': productId,
                          'movement_type': 'adjustment',
                          'quantity': qty,
                          'unit_type': _unitType,
                          'balance_after': newVal,
                          'reason': adjustReason,
                          'notes': 'Manual adjustment ($adjustType stock) — $adjustReason',
                          'staff_id': _supabase.auth.currentUser?.id,
                        };
                        if (EdgePipelineConfig.canUseEdgePipeline) {
                          debugPrint('[EDGE] Calling stock_adjust');
                          try {
                            await EdgePipelineClient.instance.stockAdjust(
                              movement: movement,
                            );
                          } catch (e) {
                            debugPrint('[EDGE] Failed: stock_adjust — $e');
                            rethrow;
                          }
                        } else {
                          await _supabase.from('stock_movements').insert(movement);
                        }

                        if (ctx.mounted) Navigator.pop(ctx);

                        // 3. Bust cache and notify parent to reload list
                        await IsarService.clearInventoryItemsCache();
                        if (mounted) widget.onSaved();

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Stock adjusted: ${qty > 0 ? '+' : ''}${qty.toStringAsFixed(2)} $_unitType ($adjustType)'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDlg(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error saving adjustment: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Adjustment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? note,
    TextInputType? keyboardType,
    bool enabled = true,
    int? maxLength,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLength: maxLength,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            isDense: maxLines <= 1,
            counterText: '',
            filled: !enabled,
            fillColor:
                enabled ? null : AppColors.border.withOpacity(0.3),
          ),
          validator: validator,
          onChanged: onChanged,
        ),
        if (note != null) ...[
          const SizedBox(height: 4),
          Text(note,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ],
    );
  }

  Widget _calcStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }
}

// ── H6: Supplier product mapping dialog (product_suppliers) ─────────────
class _ProductSupplierMappingDialog extends StatefulWidget {
  final String inventoryItemId;
  final Map<String, dynamic>? existing;
  final List<Map<String, dynamic>> suppliers;
  final VoidCallback onSaved;

  const _ProductSupplierMappingDialog({
    required this.inventoryItemId,
    required this.existing,
    required this.suppliers,
    required this.onSaved,
  });

  @override
  State<_ProductSupplierMappingDialog> createState() => _ProductSupplierMappingDialogState();
}

class _ProductSupplierMappingDialogState extends State<_ProductSupplierMappingDialog> {
  final _supabase = SupabaseService.client;
  late String? _selectedSupplierId;
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _leadTimeController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isPreferred = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _selectedSupplierId = e?['supplier_id']?.toString();
    _codeController.text = e?['supplier_product_code']?.toString() ?? '';
    _nameController.text = e?['supplier_product_name']?.toString() ?? '';
    _unitPriceController.text = e?['unit_price']?.toString() ?? '';
    _leadTimeController.text = e?['lead_time_days']?.toString() ?? '';
    _notesController.text = e?['notes']?.toString() ?? '';
    _isPreferred = e?['is_preferred'] == true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _unitPriceController.dispose();
    _leadTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a supplier.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final data = {
        'inventory_item_id': widget.inventoryItemId,
        'supplier_id': _selectedSupplierId,
        'supplier_product_code': _codeController.text.trim().isEmpty ? null : _codeController.text.trim(),
        'supplier_product_name': _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        'unit_price': double.tryParse(_unitPriceController.text),
        'lead_time_days': int.tryParse(_leadTimeController.text),
        'is_preferred': _isPreferred,
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (widget.existing == null) {
        await _supabase.from('product_suppliers').insert(data);
      } else {
        await _supabase
            .from('product_suppliers')
            .update(data)
            .eq('id', widget.existing!['id']);
      }
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.friendlyMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add supplier mapping' : 'Edit supplier mapping'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Supplier', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String?>(
                value: _selectedSupplierId,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                items: widget.suppliers
                    .map((s) => DropdownMenuItem<String?>(
                          value: s['id']?.toString(),
                          child: Text(s['name']?.toString() ?? '—'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedSupplierId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Supplier product code',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Supplier product name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _unitPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Unit price (R)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _leadTimeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Lead time (days)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _isPreferred,
                    onChanged: (v) => setState(() => _isPreferred = v ?? false),
                    activeColor: AppColors.primary,
                  ),
                  const Text('Preferred supplier for this product'),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}

// ── Bulk channel availability (owner only) ─────────────────────────────
class _BulkChannelDialog extends StatefulWidget {
  final List<String> productIds;
  final VoidCallback onSaved;

  const _BulkChannelDialog({
    required this.productIds,
    required this.onSaved,
  });

  @override
  State<_BulkChannelDialog> createState() => _BulkChannelDialogState();
}

class _BulkChannelDialogState extends State<_BulkChannelDialog> {
  final _supabase = SupabaseService.client;
  bool _availablePos = true;
  bool _availableLoyaltyApp = false;
  bool _availableOnline = false;
  bool _saving = false;

  Future<void> _apply() async {
    setState(() => _saving = true);
    try {
      final data = {
        'available_pos': _availablePos,
        'available_loyalty_app': _availableLoyaltyApp,
        'available_online': _availableOnline,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await _supabase
          .from('inventory_items')
          .update(data)
          .inFilter('id', widget.productIds);
      widget.onSaved();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated channel availability for ${widget.productIds.length} products')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set channel availability'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apply to ${widget.productIds.length} selected products.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Switch(value: _availablePos, onChanged: (v) => setState(() => _availablePos = v), activeThumbColor: AppColors.primary),
                const Text('POS / Till'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Switch(value: _availableLoyaltyApp, onChanged: (v) => setState(() => _availableLoyaltyApp = v), activeThumbColor: AppColors.primary),
                const Text('Loyalty App'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Switch(value: _availableOnline, onChanged: (v) => setState(() => _availableOnline = v), activeThumbColor: AppColors.primary),
                const Text('Online Orders'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _apply,
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Apply'),
        ),
      ],
    );
  }
}

class _ProductImportPreviewDialog extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final int missingPluCount;
  final VoidCallback onConfirm;

  const _ProductImportPreviewDialog({
    required this.rows,
    required this.missingPluCount,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final previewRows = rows.take(10).toList();
    return AlertDialog(
      title: const Text('Import products — Preview'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${rows.length} product rows found in file.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (missingPluCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '$missingPluCount row(s) missing required field "plu_code" (will be skipped).',
                    style: const TextStyle(color: AppColors.warning, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('PLU')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Sell Price')),
                    DataColumn(label: Text('Cost Price')),
                    DataColumn(label: Text('Active')),
                    DataColumn(label: Text('VAT Group')),
                  ],
                  rows: previewRows.map((r) {
                    return DataRow(
                      cells: [
                        DataCell(Text((r['plu_code'] ?? '').toString().trim().isEmpty ? '(missing)' : (r['plu_code'] ?? '').toString().trim())),
                        DataCell(Text((r['name'] ?? '').toString().trim().isEmpty ? '—' : (r['name'] ?? '').toString().trim())),
                        DataCell(Text((r['sell_price'] ?? '').toString().trim().isEmpty ? '—' : (r['sell_price'] ?? '').toString().trim())),
                        DataCell(Text((r['cost_price'] ?? '').toString().trim().isEmpty ? '—' : (r['cost_price'] ?? '').toString().trim())),
                        DataCell(Text((r['is_active'] ?? '').toString().trim().isEmpty ? '—' : (r['is_active'] ?? '').toString().trim())),
                        DataCell(Text((r['vat_group'] ?? '').toString().trim().isEmpty ? '—' : (r['vat_group'] ?? '').toString().trim())),
                      ],
                    );
                  }).toList(),
                ),
              ),
              if (rows.length > 10)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '... and ${rows.length - 10} more',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            onConfirm();
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: const Text('Confirm import'),
        ),
      ],
    );
  }
}
