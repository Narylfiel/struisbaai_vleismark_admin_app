import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/admin_config.dart';
import 'package:admin_app/core/constants/app_colors.dart';
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
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filtered = [];
  List<Map<String, dynamic>> _categories = []; // includes {id, name}; first item is All (id: null)
  bool _isLoading = true;
  String? _selectedCategoryFilterId; // null = All
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Category dropdown: id + name, active only, order by sort_order. Display name, value = id.
      final cats = await _supabase
          .from('categories')
          .select('id, name')
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
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _products.where((p) {
        final matchSearch = query.isEmpty ||
            (p['name'] ?? '').toLowerCase().contains(query) ||
            (p['plu_code']?.toString() ?? '').contains(query) ||
            (p['barcode'] ?? '').toLowerCase().contains(query) ||
            (p['text_lookup_code'] ?? '').toLowerCase().contains(query);
        final matchCat = _selectedCategoryFilterId == null ||
            p['category_id']?.toString() == _selectedCategoryFilterId;
        final matchActive = _showInactive || (p['is_active'] == true);
        return matchSearch && matchCat && matchActive;
      }).toList();
    });
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
            child: Row(
              children: [
                // Search
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, PLU, barcode...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Category filter
                DropdownButton<String?>(
                  value: _selectedCategoryFilterId,
                  underline: const SizedBox(),
                  hint: const Text('All'),
                  items: _categories
                      .map((c) => DropdownMenuItem<String?>(
                            value: c['id']?.toString(),
                            child: Text(c['name'] as String),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _selectedCategoryFilterId = v);
                    _filterProducts();
                  },
                ),
                const SizedBox(width: 12),

                // Show inactive toggle
                Row(
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

                const Spacer(),

                // Count
                Text(
                  '${_filtered.length} products',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 16),

                // Add button
                ElevatedButton.icon(
                  onPressed: () => _openProduct(null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Product'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            color: AppColors.surfaceBg,
            child: const Row(
              children: [
                SizedBox(width: 60, child: Text('PLU', style: _headerStyle)),
                SizedBox(width: 12),
                Expanded(flex: 3, child: Text('NAME', style: _headerStyle)),
                SizedBox(width: 12),
                Expanded(flex: 2, child: Text('CATEGORY', style: _headerStyle)),
                SizedBox(width: 12),
                SizedBox(width: 90, child: Text('SELL PRICE', style: _headerStyle)),
                SizedBox(width: 12),
                SizedBox(width: 80, child: Text('COST', style: _headerStyle)),
                SizedBox(width: 12),
                SizedBox(width: 60, child: Text('GP %', style: _headerStyle)),
                SizedBox(width: 12),
                SizedBox(width: 80, child: Text('ON HAND', style: _headerStyle)),
                SizedBox(width: 12),
                SizedBox(width: 60, child: Text('STATUS', style: _headerStyle)),
                SizedBox(width: 12),
                SizedBox(width: 120, child: Text('ACTIONS', style: _headerStyle)),
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
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Name
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['name'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        if (p['pos_display_name'] != null &&
                                            p['pos_display_name'] != p['name'])
                                          Text(
                                            p['pos_display_name'],
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Category
                                  Expanded(
                                    flex: 2,
                                    child: Row(
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
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _categoryNameById(p['category_id']) ?? '—',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textPrimary),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Sell price
                                  SizedBox(
                                    width: 90,
                                    child: Text(
                                      'R ${sell.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Cost
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      'R ${cost.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

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
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // On hand
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      '${onHand.toStringAsFixed(AdminConfig.stockKgDecimals)} ${p['unit_type'] ?? 'kg'}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: onHand <= reorder
                                            ? AppColors.warning
                                            : AppColors.textPrimary,
                                        fontWeight: onHand <= reorder
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Status
                                  SizedBox(
                                    width: 60,
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
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Actions
                                  SizedBox(
                                    width: 120,
                                    child: Row(
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
  String? _subCategory;
  String _itemType = 'own_cut';
  /// H9: Raw (no processing), Portioned, Manufactured (recipe-based)
  String _productType = 'raw';
  bool _scaleItem = false;
  bool _ishidaSync = false;
  bool _isActive = true;
  List<String> _supplierIds = [];
  List<Map<String, dynamic>> _allSuppliers = [];

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

  // Section G
  final _internalNotesController = TextEditingController();
  List<String> _dietaryTags = [];
  List<String> _allergenInfo = [];
  final _imageUrlController = TextEditingController();
  static const List<String> _dietaryOptions = ['Halal', 'Grass-fed', 'Free-range', 'Organic', 'Game', 'Venison'];
  static const List<String> _allergenOptions = ['Gluten', 'Dairy', 'Nuts', 'Soy', 'Eggs', 'Shellfish', 'None'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
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
      final r = await _supabase.from('recipes').select('id, name').eq('is_active', true).order('name');
      setState(() => _recipes = List<Map<String, dynamic>>.from(r));
    } catch (_) {}
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
    _subCategory = p['sub_category'] as String?;
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
    _internalNotesController.text = p['internal_notes'] ?? '';
    _dietaryTags = List<String>.from(p['dietary_tags'] ?? []);
    _allergenInfo = List<String>.from(p['allergen_info'] ?? []);
    _imageUrlController.text = p['image_url']?.toString() ?? '';
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
      'sub_category': _subCategory,
      'item_type': _itemType,
      'product_type': _productType,
      'scale_item': _scaleItem,
      'ishida_sync': _ishidaSync,
      'is_active': _isActive,
      'sell_price': double.tryParse(_sellPriceController.text),
      'cost_price': double.tryParse(_costPriceController.text),
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
      'dryer_product_type': _dryerProductType,
      'manufactured_item': _manufacturedItem,
      'image_url': _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
      'dietary_tags': _dietaryTags.isEmpty ? null : _dietaryTags,
      'allergen_info': _allergenInfo.isEmpty ? null : _allergenInfo,
      'internal_notes': _internalNotesController.text.trim().isEmpty ? null : _internalNotesController.text.trim(),
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
                Tab(text: 'G — Media/Notes'),
                Tab(text: 'H — Activity'),
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
                      items: widget.categories
                          .map((c) => DropdownMenuItem<String?>(
                                value: c['id']?.toString(),
                                child: Text((c['name'] as String? ?? ''), overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedCategoryId = v;
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
                    DropdownButtonFormField<String>(
                      value: _subCategory,
                      isExpanded: true,
                      decoration: const InputDecoration(isDense: true),
                      hint: const Text('Optional'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('—')),
                        DropdownMenuItem(value: 'Steaks', child: Text('Steaks')),
                        DropdownMenuItem(value: 'Mince', child: Text('Mince')),
                        DropdownMenuItem(value: 'Stew', child: Text('Stew')),
                        DropdownMenuItem(value: 'Ribs', child: Text('Ribs')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _subCategory = v),
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
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        onPressed: () => _deleteProductSupplier(row),
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
    if (id == null) return;
    try {
      await _supabase.from('product_suppliers').delete().eq('id', id);
      _loadProductSuppliers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildTabB() {
    final sell = double.tryParse(_sellPriceController.text) ?? 0;
    final cost = double.tryParse(_costPriceController.text) ?? 0;
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
                child: _field(
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
                decoration: const InputDecoration(isDense: true),
                hint: const Text('None'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ..._recipes.map((r) => DropdownMenuItem<String>(
                        value: r['id'] as String?,
                        child: Text(r['name'] as String? ?? ''),
                      )),
                ],
                onChanged: (v) => setState(() => _recipeId = v),
              ),
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
                  DropdownMenuItem(value: 'droewors', child: Text('Droewors')),
                  DropdownMenuItem(value: 'chilli_bites', child: Text('Chilli Bites')),
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

  Widget _buildTabH() {
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
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
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
