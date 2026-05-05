import 'package:isar/isar.dart';
part 'cached_inventory_item.g.dart';

/// Isar collection for inventory items cached for offline use.
@collection
class CachedInventoryItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String itemId;
  late String name;
  String? posDisplayName;
  late int pluCode;
  String? barcode;
  String? barcodePrefix;
  late double currentStock;
  double? stockOnHandFresh;
  double? stockOnHandFrozen;
  double? reorderLevel;
  late String unitType;
  late String stockControlType;
  String? categoryId;
  late bool isActive;
  bool? scaleItem;
  bool? isBundle;
  bool? availablePos;
  bool? availableLoyaltyApp;
  bool? availableOnline;
  double? sellPrice;
  double? costPrice;
  double? averageCost;
  double? targetMarginPct;
  String? vatGroup;
  String? onlineDisplayName;
  String? onlineWeightDescription;
  double? onlineMinStockThreshold;
  bool? isBestSeller;
  bool? isFeatured;
  String? onlineIngredients;
  String? onlineAllergens;
  String? onlineCookingTips;
  int? onlineSortOrder;
  String? onlineImageUrl;
  String? parentStockItemId;
  double? stockDeductionQty;
  String? stockDeductionUnit;
  late DateTime cachedAt;

  CachedInventoryItem();

  /// From Supabase inventory_items row.
  factory CachedInventoryItem.fromSupabase(Map<String, dynamic> row) {
    final c = CachedInventoryItem();
    c.itemId = row['id']?.toString() ?? '';
    c.name = row['name']?.toString() ?? '';
    c.posDisplayName = row['pos_display_name']?.toString();
    c.pluCode = (row['plu_code'] as num?)?.toInt() ?? 0;
    c.barcode = row['barcode']?.toString();
    c.barcodePrefix = row['barcode_prefix']?.toString();
    c.currentStock = (row['current_stock'] as num?)?.toDouble() ?? 0;
    c.stockOnHandFresh = (row['stock_on_hand_fresh'] as num?)?.toDouble();
    c.stockOnHandFrozen = (row['stock_on_hand_frozen'] as num?)?.toDouble();
    c.reorderLevel = (row['reorder_level'] as num?)?.toDouble();
    c.unitType = row['unit_type']?.toString() ?? 'kg';
    c.stockControlType = row['stock_control_type']?.toString() ?? 'use_stock_control';
    c.categoryId = row['category_id']?.toString();
    c.isActive = row['is_active'] == true || row['is_active'] == 'true';
    c.scaleItem = row['scale_item'] == true || row['scale_item'] == 'true';
    c.isBundle = row['is_bundle'] == true || row['is_bundle'] == 'true';
    c.availablePos = row['available_pos'] == true || row['available_pos'] == 'true';
    c.availableLoyaltyApp = row['available_loyalty_app'] == true || row['available_loyalty_app'] == 'true';
    c.availableOnline = row['available_online'] == true || row['available_online'] == 'true';
    c.sellPrice = (row['sell_price'] as num?)?.toDouble();
    c.costPrice = (row['cost_price'] as num?)?.toDouble();
    c.averageCost = (row['average_cost'] as num?)?.toDouble();
    c.targetMarginPct = (row['target_margin_pct'] as num?)?.toDouble();
    c.vatGroup = row['vat_group']?.toString();
    c.onlineDisplayName = row['online_display_name']?.toString();
    c.onlineWeightDescription = row['online_weight_description']?.toString();
    c.onlineMinStockThreshold = (row['online_min_stock_threshold'] as num?)?.toDouble();
    c.isBestSeller = row['is_best_seller'] == true;
    c.isFeatured = row['is_featured'] == true;
    c.onlineIngredients = row['online_ingredients']?.toString();
    c.onlineAllergens = row['online_allergens']?.toString();
    c.onlineCookingTips = row['online_cooking_tips']?.toString();
    c.onlineSortOrder = (row['online_sort_order'] as num?)?.toInt();
    c.onlineImageUrl = row['online_image_url']?.toString();
    c.parentStockItemId = row['parent_stock_item_id']?.toString();
    c.stockDeductionQty = (row['stock_deduction_qty'] as num?)?.toDouble();
    c.stockDeductionUnit = row['stock_deduction_unit']?.toString();
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  /// To map — same shape as Supabase select for all screens.
  Map<String, dynamic> toMap() => {
        'id': itemId,
        'name': name,
        'pos_display_name': posDisplayName,
        'plu_code': pluCode,
        'barcode': barcode,
        'barcode_prefix': barcodePrefix,
        'current_stock': currentStock,
        'stock_on_hand_fresh': stockOnHandFresh,
        'stock_on_hand_frozen': stockOnHandFrozen,
        'reorder_level': reorderLevel,
        'unit_type': unitType,
        'stock_control_type': stockControlType,
        'category_id': categoryId,
        'is_active': isActive,
        'scale_item': scaleItem,
        'is_bundle': isBundle,
        'available_pos': availablePos,
        'available_loyalty_app': availableLoyaltyApp,
        'available_online': availableOnline,
        'sell_price': sellPrice,
        'cost_price': costPrice,
        'average_cost': averageCost,
        'target_margin_pct': targetMarginPct,
        'vat_group': vatGroup,
        'online_display_name': onlineDisplayName,
        'online_weight_description': onlineWeightDescription,
        'online_min_stock_threshold': onlineMinStockThreshold,
        'is_best_seller': isBestSeller,
        'is_featured': isFeatured,
        'online_ingredients': onlineIngredients,
        'online_allergens': onlineAllergens,
        'online_cooking_tips': onlineCookingTips,
        'online_sort_order': onlineSortOrder,
        'online_image_url': onlineImageUrl,
        'parent_stock_item_id': parentStockItemId,
        'stock_deduction_qty': stockDeductionQty,
        'stock_deduction_unit': stockDeductionUnit,
      };
}
