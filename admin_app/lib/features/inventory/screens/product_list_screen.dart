import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/auth_service.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/features/inventory/constants/category_mappings.dart';
import 'package:admin_app/features/inventory/widgets/stock_movement_dialogs.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => ProductListScreenState();
}

/// Public state so parent (Inventory nav) can call openAddProduct() when + is pressed.
class ProductListScreenState extends State<ProductListScreen> {
  /// Call from parent (e.g. Inventory + button) to open Add Product form.
  void openAddProduct() => _openProduct(null);
  final _supabase = SupabaseService.client;

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Category dropdown: id, name, parent_id; active only (categories table uses 'active' column); order by sort_order.
      final cats = await _supabase
          .from('categories')
          .select('id, name, parent_id')
          .eq('active', true)
          .order('sort_order');
      _categories = [
        {'id': null, 'name': 'All'},
        ...List<Map<String, dynamic>>.from(cats),
      ];

      final products = await _supabase
          .from('inventory_items')
          .select('*')
          .order('plu_code');
      _products = List<Map<String, dynamic>>.from(products);
      _filterProducts();
    } catch (e) {
      debugPrint('Product list error: $e');
    }
    setState(() => _isLoading = false);
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
        onSaved: _loadData,
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
    _loadData();
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

                if (isWide) {
                  return Row(
                    children: [
                      searchField,
                      const SizedBox(width: 8),
                      filters,
                      const Spacer(),
                      countText,
                      const SizedBox(width: 12),
                      bulkButton,
                      sortButton,
                      const SizedBox(width: 8),
                      addButton,
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: searchField),
                          const SizedBox(width: 8),
                          bulkButton,
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
                const SizedBox(width: 80, child: Text('ACTIONS', style: _headerStyle)),
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

                                  // Actions — fixed 80px, min size
                                  SizedBox(
                                    width: 80,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
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
  bool _availableOnline = false;
  final _onlineDescriptionController = TextEditingController();
  final _onlineImageUrlController = TextEditingController();
  final _onlineSortOrderController = TextEditingController();

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
    _tabController = TabController(length: 9, vsync: this);
    if (widget.product != null) {
      _populateForm(widget.product!);
      _loadProductSuppliers();
    }
    _loadModifierGroups();
    _loadRecipes();
    _loadSuppliers();
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

  void _populateForm(Map<String, dynamic> p) {
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
    _onlineDescriptionController.text = p['online_description']?.toString() ?? '';
    _onlineImageUrlController.text = p['online_image_url']?.toString() ?? '';
    _onlineSortOrderController.text = p['online_sort_order']?.toString() ?? '';
  }

  Future<void> _confirmDeleteProduct(Map<String, dynamic> product) async {
    final name = product['name']?.toString() ?? 'Product';
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
      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
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
      'image_url': _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
      'dietary_tags': _dietaryTags.isEmpty ? null : _dietaryTags,
      'allergen_info': _allergenInfo.isEmpty ? null : _allergenInfo,
      'internal_notes': _internalNotesController.text.trim().isEmpty ? null : _internalNotesController.text.trim(),
      'available_pos': _availablePos,
      'available_loyalty_app': _availableLoyaltyApp,
      'available_online': _availableOnline,
      'online_description': _onlineDescriptionController.text.trim().isEmpty ? null : _onlineDescriptionController.text.trim(),
      'online_image_url': _onlineImageUrlController.text.trim().isEmpty ? null : _onlineImageUrlController.text.trim(),
      'online_sort_order': int.tryParse(_onlineSortOrderController.text),
      'price_last_changed': DateTime.now().toIso8601String(),
      'last_edited_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      if (widget.product == null) {
        await _supabase.from('inventory_items').insert(data);
      } else {
        await _supabase
            .from('inventory_items')
            .update(data)
            .eq('id', widget.product!['id']);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pluController.dispose();
    _nameController.dispose();
    _posNameController.dispose();
    _scaleLabelController.dispose();
    _barcodeController.dispose();
    _lookupController.dispose();
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
    _onlineDescriptionController.dispose();
    _onlineImageUrlController.dispose();
    _onlineSortOrderController.dispose();
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
                Tab(text: 'G — Channels'),
                Tab(text: 'H — Media/Notes'),
                Tab(text: 'I — Activity'),
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
                    _buildTabChannels(),
                    _buildTabH(),
                    _buildTabI(),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allSuppliers.map((s) {
              final id = s['id'] as String?;
              final name = s['name'] as String? ?? '';
              final selected = id != null && _supplierIds.contains(id);
              return FilterChip(
                label: Text(name),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v && id != null) {
                      _supplierIds.add(id);
                    } else if (id != null) {
                      _supplierIds.remove(id);
                    }
                  });
                },
              );
            }).toList(),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger));
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
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
                      onChanged: (v) =>
                          setState(() => _stockControlType = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
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
                      decoration: const InputDecoration(isDense: true),
                      items: const [
                        DropdownMenuItem(value: 'kg', child: Text('kg')),
                        DropdownMenuItem(
                            value: 'units', child: Text('Units')),
                        DropdownMenuItem(
                            value: 'packs', child: Text('Packs')),
                      ],
                      onChanged: (v) => setState(() => _unitType = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Allow Sell by Fraction',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Switch(
                      value: _allowFraction,
                      onChanged: (v) =>
                          setState(() => _allowFraction = v),
                      activeThumbColor: AppColors.primary,
                    ),
                  ],
                ),
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
                child: _field(
                  label: 'Slow Moving Trigger (days)',
                  controller: _slowMovingController,
                  hint: '3',
                  keyboardType: TextInputType.number,
                  note: 'Days without sale = slow-moving alert (per product)',
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
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Switch(
                value: _dryerBiltongProduct,
                onChanged: (v) => setState(() => _dryerBiltongProduct = v),
                activeThumbColor: AppColors.primary,
              ),
              const Text(
                'Dryer/Biltong Product (links to Dryer module)',
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

  Widget _buildTabChannels() {
    final showAppListing = _availableLoyaltyApp || _availableOnline;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Channel availability',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _channelToggle(
                  label: 'POS / Till',
                  value: _availablePos,
                  onChanged: (v) => setState(() => _availablePos = v),
                  hint: 'Show this product on the point of sale screen',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _channelToggle(
                  label: 'Loyalty App',
                  value: _availableLoyaltyApp,
                  onChanged: (v) => setState(() => _availableLoyaltyApp = v),
                  hint: 'Customers can order this via the loyalty app',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _channelToggle(
                  label: 'Online Orders',
                  value: _availableOnline,
                  onChanged: (v) => setState(() => _availableOnline = v),
                  hint: 'Available when online ordering is launched',
                ),
              ),
            ],
          ),
          if (showAppListing) ...[
            const SizedBox(height: 24),
            const Text('App listing',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            _field(
              label: 'App Description',
              controller: _onlineDescriptionController,
              hint: 'Describe this product for customers in the app. Can be more detailed than the POS name.',
              maxLength: 2000,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _field(
                    label: 'App Display Order',
                    controller: _onlineSortOrderController,
                    hint: 'Lower numbers appear first in app listings',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _field(
                    label: 'Product Image URL',
                    controller: _onlineImageUrlController,
                    hint: 'Link to product photo for app display (Image upload will be added when app is built)',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _channelToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.primary,
            ),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 4),
        Text(hint, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
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
