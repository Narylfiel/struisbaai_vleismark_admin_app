import 'package:isar/isar.dart';

part 'cached_modifier_item.g.dart';

@collection
class CachedModifierItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String itemId;

  late String modifierGroupId;
  late String name;
  late double priceAdjustment;
  late bool isActive;
  late DateTime cachedAt;

  CachedModifierItem();

  factory CachedModifierItem.fromSupabase(Map<String, dynamic> row) {
    final c = CachedModifierItem();
    c.itemId = row['id']?.toString() ?? '';
    c.modifierGroupId = row['modifier_group_id']?.toString() ?? '';
    c.name = row['name']?.toString() ?? '';
    c.priceAdjustment = (row['price_adjustment'] as num?)?.toDouble() ?? 0;
    c.isActive = row['is_active'] == true || row['is_active'] == 'true';
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  Map<String, dynamic> toMap() => {
        'id': itemId,
        'modifier_group_id': modifierGroupId,
        'name': name,
        'price_adjustment': priceAdjustment,
        'is_active': isActive,
      };
}
