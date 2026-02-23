import '../../../core/models/base_model.dart';

/// Blueprint §4.2: Product (inventory item) — Sections A–H.
/// Maps to inventory_items table.
class InventoryItem extends BaseModel {
  // A: Identity
  final int pluCode;
  final String name;
  final String? posDisplayName;
  final String? scaleLabelName;
  final String? barcode;
  final String itemType;
  /// UUID reference to categories.id (canonical for save/insert).
  final String? categoryId;
  /// Display name when loaded with join; not sent on insert/update.
  final String? category;
  final String? subCategory;
  final List<String>? supplierIds;
  final bool isActive;
  final bool scaleItem;

  // B: Pricing
  final double? sellPrice;
  final double? costPrice;
  final double? averageCost;
  final double? targetMarginPct;
  final double? freezerMarkdownPct;
  final String vatGroup;
  final DateTime? priceLastChanged;

  // C: Stock
  final String stockControlType;
  final String unitType;
  final bool allowSellByFraction;
  final double? packSize;
  final double? stockOnHandFresh;
  final double? stockOnHandFrozen;
  final double? reorderLevel;
  final int? slowMovingTriggerDays;
  final int? shelfLifeFresh;
  final int? shelfLifeFrozen;
  final List<String>? storageLocationIds;
  final String? carcassLinkId;
  final bool dryerBiltongProduct;

  // D: Barcode & Scale
  final String? barcodePrefix;
  final bool ishidaSync;
  final String? textLookupCode;

  // E: Modifiers — linked group IDs (stored in junction or JSON)
  final List<String>? modifierGroupIds;

  // F: Production
  final String? recipeId;
  final String? dryerProductType;
  final bool manufacturedItem;

  // G: Media & Notes
  final String? imageUrl;
  final List<String>? dietaryTags;
  final List<String>? allergenInfo;
  final String? internalNotes;

  // H: Activity (read-only from DB)
  final String? lastEditedBy;
  final DateTime? lastEditedAt;

  const InventoryItem({
    required super.id,
    required this.pluCode,
    required this.name,
    this.posDisplayName,
    this.scaleLabelName,
    this.barcode,
    this.itemType = 'own_cut',
    this.categoryId,
    this.category,
    this.subCategory,
    this.supplierIds,
    this.isActive = true,
    this.scaleItem = false,
    this.sellPrice,
    this.costPrice,
    this.averageCost,
    this.targetMarginPct,
    this.freezerMarkdownPct,
    this.vatGroup = 'standard',
    this.priceLastChanged,
    this.stockControlType = 'use_stock_control',
    this.unitType = 'kg',
    this.allowSellByFraction = true,
    this.packSize,
    this.stockOnHandFresh,
    this.stockOnHandFrozen,
    this.reorderLevel,
    this.slowMovingTriggerDays,
    this.shelfLifeFresh,
    this.shelfLifeFrozen,
    this.storageLocationIds,
    this.carcassLinkId,
    this.dryerBiltongProduct = false,
    this.barcodePrefix,
    this.ishidaSync = false,
    this.textLookupCode,
    this.modifierGroupIds,
    this.recipeId,
    this.dryerProductType,
    this.manufacturedItem = false,
    this.imageUrl,
    this.dietaryTags,
    this.allergenInfo,
    this.internalNotes,
    this.lastEditedBy,
    this.lastEditedAt,
    super.createdAt,
    super.updatedAt,
  });

  double get stockOnHandTotal =>
      (stockOnHandFresh ?? 0) + (stockOnHandFrozen ?? 0);

  double? get gpPct =>
      sellPrice != null && sellPrice! > 0 && costPrice != null
          ? ((sellPrice! - costPrice!) / sellPrice! * 100)
          : null;

  double? get recommendedPrice =>
      costPrice != null &&
          targetMarginPct != null &&
          targetMarginPct! < 100 &&
          targetMarginPct! > 0
          ? costPrice! / (1 - targetMarginPct! / 100)
          : null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plu_code': pluCode,
      'name': name,
      'pos_display_name': posDisplayName,
      'scale_label_name': scaleLabelName,
      'barcode': barcode,
      'item_type': itemType,
      'category_id': categoryId,
      'sub_category': subCategory,
      'supplier_ids': supplierIds,
      'is_active': isActive,
      'scale_item': scaleItem,
      'sell_price': sellPrice,
      'cost_price': costPrice,
      'target_margin_pct': targetMarginPct,
      'freezer_markdown_pct': freezerMarkdownPct,
      'vat_group': vatGroup,
      'price_last_changed': priceLastChanged?.toIso8601String(),
      'stock_control_type': stockControlType,
      'unit_type': unitType,
      'allow_sell_by_fraction': allowSellByFraction,
      'pack_size': packSize,
      'reorder_level': reorderLevel,
      'slow_moving_trigger_days': slowMovingTriggerDays,
      'shelf_life_fresh': shelfLifeFresh,
      'shelf_life_frozen': shelfLifeFrozen,
      'storage_location_ids': storageLocationIds,
      'carcass_link_id': carcassLinkId,
      'dryer_biltong_product': dryerBiltongProduct,
      'barcode_prefix': barcodePrefix,
      'ishida_sync': ishidaSync,
      'text_lookup_code': textLookupCode,
      'modifier_group_ids': modifierGroupIds,
      'recipe_id': recipeId,
      'dryer_product_type': dryerProductType,
      'manufactured_item': manufacturedItem,
      'image_url': imageUrl,
      'dietary_tags': dietaryTags,
      'allergen_info': allergenInfo,
      'internal_notes': internalNotes,
      'last_edited_by': lastEditedBy,
      'last_edited_at': lastEditedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static List<String>? _toStringList(dynamic v) {
    if (v == null) return null;
    if (v is List) return v.map((e) => e.toString()).toList();
    return null;
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      pluCode: _toInt(json['plu_code']) ?? 0,
      name: json['name'] as String? ?? '',
      posDisplayName: json['pos_display_name'] as String?,
      scaleLabelName: json['scale_label_name'] as String?,
      barcode: json['barcode'] as String?,
      itemType: json['item_type'] as String? ?? 'own_cut',
      categoryId: json['category_id']?.toString(),
      category: json['category'] as String?,
      subCategory: json['sub_category'] as String?,
      supplierIds: _toStringList(json['supplier_ids']),
      isActive: json['is_active'] as bool? ?? true,
      scaleItem: json['scale_item'] as bool? ?? false,
      sellPrice: _toDouble(json['sell_price']),
      costPrice: _toDouble(json['cost_price']),
      averageCost: _toDouble(json['average_cost']),
      targetMarginPct: _toDouble(json['target_margin_pct']),
      freezerMarkdownPct: _toDouble(json['freezer_markdown_pct']),
      vatGroup: json['vat_group'] as String? ?? 'standard',
      priceLastChanged: json['price_last_changed'] != null
          ? DateTime.tryParse(json['price_last_changed'] as String)
          : null,
      stockControlType:
          json['stock_control_type'] as String? ?? 'use_stock_control',
      unitType: json['unit_type'] as String? ?? 'kg',
      allowSellByFraction: json['allow_sell_by_fraction'] as bool? ?? true,
      packSize: _toDouble(json['pack_size']),
      stockOnHandFresh: _toDouble(json['stock_on_hand_fresh']),
      stockOnHandFrozen: _toDouble(json['stock_on_hand_frozen']),
      reorderLevel: _toDouble(json['reorder_level']),
      slowMovingTriggerDays: _toInt(json['slow_moving_trigger_days']),
      shelfLifeFresh: _toInt(json['shelf_life_fresh']),
      shelfLifeFrozen: _toInt(json['shelf_life_frozen']),
      storageLocationIds: _toStringList(json['storage_location_ids']),
      carcassLinkId: json['carcass_link_id'] as String?,
      dryerBiltongProduct: json['dryer_biltong_product'] as bool? ?? false,
      barcodePrefix: json['barcode_prefix'] as String?,
      ishidaSync: json['ishida_sync'] as bool? ?? false,
      textLookupCode: json['text_lookup_code'] as String?,
      modifierGroupIds: _toStringList(json['modifier_group_ids']),
      recipeId: json['recipe_id'] as String?,
      dryerProductType: json['dryer_product_type'] as String?,
      manufacturedItem: json['manufactured_item'] as bool? ?? false,
      imageUrl: json['image_url'] as String?,
      dietaryTags: _toStringList(json['dietary_tags']),
      allergenInfo: _toStringList(json['allergen_info']),
      internalNotes: json['internal_notes'] as String?,
      lastEditedBy: json['last_edited_by'] as String?,
      lastEditedAt: json['last_edited_at'] != null
          ? DateTime.tryParse(json['last_edited_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  bool validate() {
    return name.trim().isNotEmpty && pluCode > 0;
  }

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (name.trim().isEmpty) errors.add('Name is required');
    if (pluCode <= 0) errors.add('PLU Code must be a positive number');
    return errors;
  }
}
