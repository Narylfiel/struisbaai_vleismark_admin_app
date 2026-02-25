import '../../../core/models/base_model.dart';

/// Role of a product in a promotion (trigger, reward, or bundle member).
enum PromotionProductRole {
  triggerItem,
  rewardItem,
  bundleItem,
}

extension PromotionProductRoleExt on PromotionProductRole {
  String get dbValue {
    switch (this) {
      case PromotionProductRole.triggerItem:
        return 'trigger_item';
      case PromotionProductRole.rewardItem:
        return 'reward_item';
      case PromotionProductRole.bundleItem:
        return 'bundle_item';
    }
  }

  static PromotionProductRole fromDb(String? value) {
    switch (value) {
      case 'trigger_item':
        return PromotionProductRole.triggerItem;
      case 'reward_item':
        return PromotionProductRole.rewardItem;
      case 'bundle_item':
        return PromotionProductRole.bundleItem;
      default:
        return PromotionProductRole.triggerItem;
    }
  }
}

/// Link between a promotion and an inventory item (role + quantity).
class PromotionProduct extends BaseModel {
  final String promotionId;
  final String inventoryItemId;
  final PromotionProductRole role;
  final int quantity;

  const PromotionProduct({
    required super.id,
    required this.promotionId,
    required this.inventoryItemId,
    this.role = PromotionProductRole.triggerItem,
    this.quantity = 1,
    super.createdAt,
    super.updatedAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'promotion_id': promotionId,
      'inventory_item_id': inventoryItemId,
      'role': role.dbValue,
      'quantity': quantity,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory PromotionProduct.fromJson(Map<String, dynamic> json) {
    return PromotionProduct(
      id: json['id'] as String,
      promotionId: json['promotion_id'] as String? ?? '',
      inventoryItemId: json['inventory_item_id'] as String? ?? '',
      role: PromotionProductRoleExt.fromDb(json['role'] as String?),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  @override
  bool validate() => promotionId.isNotEmpty && inventoryItemId.isNotEmpty;

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (promotionId.isEmpty) errors.add('Promotion is required');
    if (inventoryItemId.isEmpty) errors.add('Product is required');
    return errors;
  }
}
