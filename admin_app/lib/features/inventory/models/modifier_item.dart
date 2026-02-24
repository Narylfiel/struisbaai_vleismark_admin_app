import '../../../core/models/base_model.dart';

/// Blueprint §4.3: Modifier Item — e.g. Pepper Sauce +R15.00, Track Inventory, Linked Item.
class ModifierItem extends BaseModel {
  final String groupId;
  final String name;
  final double priceAdjustment;
  final bool isActive;
  final int sortOrder;
  /// Blueprint: Track Inventory?
  final bool trackInventory;
  /// Blueprint: Linked Item (inventory product)
  final String? linkedInventoryItemId;

  const ModifierItem({
    required super.id,
    required this.groupId,
    required this.name,
    this.priceAdjustment = 0,
    this.isActive = true,
    this.sortOrder = 0,
    this.trackInventory = false,
    this.linkedInventoryItemId,
    super.createdAt,
    super.updatedAt,
  });

  /// DB columns: id, modifier_group_id, name, price_adjustment, track_inventory, linked_item_id, sort_order, active, created_at, inventory_item_id, updated_at.
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'modifier_group_id': groupId,
      'name': name,
      'price_adjustment': priceAdjustment,
      'track_inventory': trackInventory,
      'linked_item_id': linkedInventoryItemId,
      'sort_order': sortOrder,
      'active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'inventory_item_id': linkedInventoryItemId,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory ModifierItem.fromJson(Map<String, dynamic> json) {
    return ModifierItem(
      id: json['id'] as String,
      groupId: json['modifier_group_id'] as String? ?? json['group_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      priceAdjustment: (json['price_adjustment'] as num?)?.toDouble() ?? 0,
      isActive: json['active'] as bool? ?? json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      trackInventory: json['track_inventory'] as bool? ?? false,
      linkedInventoryItemId: json['inventory_item_id'] as String? ?? json['linked_item_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  bool validate() => name.trim().isNotEmpty && groupId.isNotEmpty;

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (name.trim().isEmpty) errors.add('Item name is required');
    if (groupId.isEmpty) errors.add('Group is required');
    return errors;
  }
}
