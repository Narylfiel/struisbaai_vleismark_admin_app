import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/export_service.dart';
import 'package:share_plus/share_plus.dart';

/// Blueprint §4.4: Stock Levels — table view of all products across locations.
/// C1: Single source of truth — display uses current_stock (updated by POS trigger).
class StockLevelsScreen extends StatefulWidget {
  const StockLevelsScreen({super.key});

  @override
  State<StockLevelsScreen> createState() => _StockLevelsScreenState();
}

class _StockLevelsScreenState extends State<StockLevelsScreen> {
  final _supabase = SupabaseService.client;
  final _searchController = TextEditingController();
  final _exportService = ExportService();
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String _filter = 'all'; // all | low | ok
  String? _selectedCategoryId; // null = All
  String _sortOption = 'plu_asc'; // plu_asc, name_az, stock_low, stock_high, reorder

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final cats = await _supabase
          .from('categories')
          .select('id, name')
          .eq('active', true)
          .order('sort_order');
      _categories = [
        {'id': null, 'name': 'All'},
        ...List<Map<String, dynamic>>.from(cats),
      ];

      // inventory_items has reorder_level (not reorder_point per schema)
      final res = await _supabase
          .from('inventory_items')
          .select('id, name, plu_code, current_stock, stock_on_hand_fresh, stock_on_hand_frozen, reorder_level, unit_type, stock_control_type, category_id')
          .eq('is_active', true)
          .order('name');
      _items = List<Map<String, dynamic>>.from(res);
      _applyFilters();
    } catch (e) {
      debugPrint('Stock levels load: $e');
    }
    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    setState(() {});
  }

  /// C1: Single source of truth — current_stock only (POS trigger updates it).
  double _onHand(Map<String, dynamic> p) {
    return (p['current_stock'] as num?)?.toDouble() ?? 0;
  }

  double _reorderLevel(Map<String, dynamic> p) {
    return (p['reorder_level'] as num?)?.toDouble() ?? 0;
  }

  /// Format stock quantity: weight items (kg) show 3 decimals; unit items show whole numbers.
  String _formatStock(dynamic quantity, Map<String, dynamic> item) {
    final double qty = (quantity as num?)?.toDouble() ?? 0.0;
    final unitType = item['unit_type']?.toString().toLowerCase();
    final stockControl = item['stock_control_type']?.toString().toLowerCase();

    // Weight items: unit_type kg, or stock_control_type weight/weighted
    final isWeight = unitType == 'kg' ||
        stockControl == 'weight' ||
        stockControl == 'weighted' ||
        stockControl == 'kg';
    if (isWeight) {
      return '${qty.toStringAsFixed(3)} kg';
    }

    // Unit/pack items: whole number or 1 decimal
    final unitLabel = unitType == 'packs' ? 'packs' : 'units';
    if (qty == qty.roundToDouble()) {
      return '${qty.toInt()} $unitLabel';
    }
    return '${qty.toStringAsFixed(1)} $unitLabel';
  }

  String _status(Map<String, dynamic> p) {
    final onHand = _onHand(p);
    final reorder = _reorderLevel(p);
    if (reorder <= 0) return 'OK';
    return onHand <= reorder ? 'LOW' : 'OK';
  }

  bool _isLow(Map<String, dynamic> p) => _status(p) == 'LOW';

  String? _categoryName(String? categoryId) {
    if (categoryId == null) return null;
    for (final c in _categories) {
      if (c['id']?.toString() == categoryId) return c['name'] as String?;
    }
    return null;
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _items;
    if (_filter == 'low') list = list.where(_isLow).toList();
    else if (_filter == 'ok') list = list.where((p) => !_isLow(p)).toList();

    if (_selectedCategoryId != null) {
      list = list.where((p) => p['category_id']?.toString() == _selectedCategoryId).toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((p) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        final plu = (p['plu_code']?.toString() ?? '');
        return name.contains(query) || plu.contains(query);
      }).toList();
    }

    // Sort
    final sorted = List<Map<String, dynamic>>.from(list);
    sorted.sort((a, b) {
      switch (_sortOption) {
        case 'name_az':
          return ((a['name'] ?? '').toString().toLowerCase())
              .compareTo((b['name'] ?? '').toString().toLowerCase());
        case 'stock_low':
          return _onHand(a).compareTo(_onHand(b));
        case 'stock_high':
          return _onHand(b).compareTo(_onHand(a));
        case 'reorder':
          final aDist = _reorderLevel(a) - _onHand(a);
          final bDist = _reorderLevel(b) - _onHand(b);
          return aDist.compareTo(bDist); // closest to reorder first
        case 'plu_asc':
        default:
          return ((a['plu_code'] as num?) ?? 0).compareTo((b['plu_code'] as num?) ?? 0);
      }
    });
    return sorted;
  }

  String _sortLabel() {
    switch (_sortOption) {
      case 'name_az': return 'Name A→Z';
      case 'stock_low': return 'Stock ↑';
      case 'stock_high': return 'Stock ↓';
      case 'reorder': return 'Reorder';
      case 'plu_asc':
      default: return 'PLU ↑';
    }
  }

  Future<void> _exportCsv() async {
    try {
      final data = _filtered.asMap().entries.map((e) {
        final i = e.key + 1;
        final p = e.value;
        final st = _status(p);
        return {
          '#': i.toString(),
          'PLU': p['plu_code']?.toString() ?? '',
          'Product': p['name']?.toString() ?? '',
          'Category': _categoryName(p['category_id']?.toString()) ?? '',
          'On Hand': _formatStock(p['current_stock'], p),
          'Fresh': _formatStock(p['stock_on_hand_fresh'], p),
          'Frozen': _formatStock(p['stock_on_hand_frozen'], p),
          'Reorder Level': _formatStock(p['reorder_level'], p),
          'Status': st,
        };
      }).toList();
      final date = DateTime.now().toIso8601String().split('T')[0];
      final file = await _exportService.exportToCsv(
        fileName: 'stock_levels_$date',
        data: data,
        columns: ['#', 'PLU', 'Product', 'Category', 'On Hand', 'Fresh', 'Frozen', 'Reorder Level', 'Status'],
      );
      await Share.shareXFiles([XFile(file.path)], text: 'Stock levels export');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          color: AppColors.cardBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text('Stock Levels', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 24),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'all', label: Text('All'), icon: Icon(Icons.list, size: 16)),
                      ButtonSegment(value: 'low', label: Text('Low'), icon: Icon(Icons.warning, size: 16)),
                      ButtonSegment(value: 'ok', label: Text('OK'), icon: Icon(Icons.check_circle, size: 16)),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (s) => setState(() => _filter = s.first),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 140,
                    child: DropdownButton<String?>(
                      value: _selectedCategoryId,
                      underline: const SizedBox(),
                      hint: const Text('Category'),
                      isExpanded: true,
                      items: _categories
                          .map((c) => DropdownMenuItem<String?>(
                                value: c['id']?.toString(),
                                child: Text(c['name'] as String, overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: _isLoading ? null : _exportCsv,
                    tooltip: 'Export to CSV',
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _isLoading ? null : _load,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name or PLU...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  PopupMenuButton<String>(
                    tooltip: 'Sort',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort, size: 18),
                        const SizedBox(width: 6),
                        Text(_sortLabel(), style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    onSelected: (v) => setState(() => _sortOption = v),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'plu_asc', child: Text('PLU (ascending)')),
                      const PopupMenuItem(value: 'name_az', child: Text('Name (A→Z)')),
                      const PopupMenuItem(value: 'stock_low', child: Text('Stock (low→high)')),
                      const PopupMenuItem(value: 'stock_high', child: Text('Stock (high→low)')),
                      const PopupMenuItem(value: 'reorder', child: Text('Reorder level (closest first)')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          color: AppColors.surfaceBg,
          child: const Row(
            children: [
              SizedBox(width: 36, child: Text('#', style: _headerStyle)),
              SizedBox(width: 8),
              SizedBox(width: 60, child: Text('PLU', style: _headerStyle)),
              SizedBox(width: 12),
              Expanded(flex: 2, child: Text('PRODUCT', style: _headerStyle)),
              SizedBox(width: 12),
              SizedBox(width: 100, child: Text('CATEGORY', style: _headerStyle)),
              SizedBox(width: 12),
              SizedBox(width: 90, child: Text('ON HAND', style: _headerStyle)),
              SizedBox(width: 12),
              SizedBox(width: 80, child: Text('FRESH', style: _headerStyle)),
              SizedBox(width: 12),
              SizedBox(width: 80, child: Text('FROZEN', style: _headerStyle)),
              SizedBox(width: 12),
              SizedBox(width: 90, child: Text('REORDER', style: _headerStyle)),
              SizedBox(width: 12),
              SizedBox(width: 80, child: Text('STATUS', style: _headerStyle)),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _filtered.isEmpty
                  ? Center(
                      child: Text(
                        _items.isEmpty ? 'No active products' : 'No items match filter',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (_, i) {
                        final p = _filtered[i];
                        final rowNum = i + 1;
                        final onHand = _onHand(p); // C1: current_stock only
                        final fresh = (p['stock_on_hand_fresh'] as num?)?.toDouble() ?? 0;
                        final frozen = (p['stock_on_hand_frozen'] as num?)?.toDouble() ?? 0;
                        final reorder = _reorderLevel(p);
                        final low = reorder > 0 && onHand <= reorder;
                        final catName = _categoryName(p['category_id']?.toString()) ?? '—';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              SizedBox(width: 36, child: Text('$rowNum', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                              const SizedBox(width: 8),
                              SizedBox(width: 60, child: Text('${p['plu_code'] ?? '—'}', style: const TextStyle(fontWeight: FontWeight.w600))),
                              const SizedBox(width: 12),
                              Expanded(flex: 2, child: Text(p['name'] ?? '—')),
                              const SizedBox(width: 12),
                              SizedBox(width: 100, child: Text(catName, overflow: TextOverflow.ellipsis)),
                              const SizedBox(width: 12),
                              SizedBox(width: 90, child: Text(_formatStock(p['current_stock'], p))),
                              const SizedBox(width: 12),
                              SizedBox(width: 80, child: Text(_formatStock(p['stock_on_hand_fresh'], p))),
                              const SizedBox(width: 12),
                              SizedBox(width: 80, child: Text(_formatStock(p['stock_on_hand_frozen'], p))),
                              const SizedBox(width: 12),
                              SizedBox(width: 90, child: Text(_formatStock(p['reorder_level'], p))),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 80,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: low ? AppColors.warning.withOpacity(0.15) : AppColors.success.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    low ? 'LOW' : 'OK',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: low ? AppColors.warning : AppColors.success,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

const _headerStyle = TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.bold,
  color: AppColors.textSecondary,
  letterSpacing: 0.5,
);
