import 'package:isar/isar.dart';

part 'cached_inventory_item.g.dart';

/// Isar collection for inventory items cached for offline stock levels view.
@collection
class CachedInventoryItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String itemId;

  late String name;
  late int pluCode;
  late double currentStock;
  double? stockOnHandFresh;
  double? stockOnHandFrozen;
  double? reorderLevel;
  late String unitType;
  late String stockControlType;
  String? categoryId;
  late bool isActive;
  late DateTime cachedAt;

  CachedInventoryItem();

  /// From Supabase inventory_items row.
  factory CachedInventoryItem.fromSupabase(Map<String, dynamic> row) {
    final c = CachedInventoryItem();
    c.itemId = row['id']?.toString() ?? '';
    c.name = row['name']?.toString() ?? '';
    c.pluCode = (row['plu_code'] as num?)?.toInt() ?? 0;
    c.currentStock = (row['current_stock'] as num?)?.toDouble() ?? 0;
    c.stockOnHandFresh = (row['stock_on_hand_fresh'] as num?)?.toDouble();
    c.stockOnHandFrozen = (row['stock_on_hand_frozen'] as num?)?.toDouble();
    c.reorderLevel = (row['reorder_level'] as num?)?.toDouble();
    c.unitType = row['unit_type']?.toString() ?? 'kg';
    c.stockControlType = row['stock_control_type']?.toString() ?? 'use_stock_control';
    c.categoryId = row['category_id']?.toString();
    c.isActive = row['is_active'] == true || row['is_active'] == 'true';
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  /// To map for stock_levels_screen (same shape as Supabase select).
  Map<String, dynamic> toMap() => {
        'id': itemId,
        'name': name,
        'plu_code': pluCode,
        'current_stock': currentStock,
        'stock_on_hand_fresh': stockOnHandFresh,
        'stock_on_hand_frozen': stockOnHandFrozen,
        'reorder_level': reorderLevel,
        'unit_type': unitType,
        'stock_control_type': stockControlType,
        'category_id': categoryId,
        'is_active': isActive,
      };
}
