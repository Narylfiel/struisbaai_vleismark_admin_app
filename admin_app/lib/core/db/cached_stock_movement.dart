import 'package:isar/isar.dart';

part 'cached_stock_movement.g.dart';

@collection
class CachedStockMovement {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  late String movementId;
  String? itemId;
  String? itemName;
  String? movementType;
  late double quantity;
  String? reason;
  String? staffId;
  DateTime? createdAt;
  late DateTime cachedAt;

  CachedStockMovement();

  factory CachedStockMovement.fromSupabase(Map<String, dynamic> row) {
    final c = CachedStockMovement();
    c.movementId = row['id']?.toString() ?? '';
    c.itemId = row['item_id']?.toString();
    c.itemName = row['item_name']?.toString();
    c.movementType = row['movement_type']?.toString();
    c.quantity = (row['quantity'] as num?)?.toDouble() ?? 0;
    c.reason = row['reason']?.toString();
    c.staffId = row['staff_id']?.toString();
    c.createdAt = row['created_at'] != null ? DateTime.tryParse(row['created_at'].toString()) : null;
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': movementId,
      'item_id': itemId,
      'item_name': itemName,
      'movement_type': movementType,
      'quantity': quantity,
      'reason': reason,
      'staff_id': staffId,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
