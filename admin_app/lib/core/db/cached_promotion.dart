import 'package:isar/isar.dart';

part 'cached_promotion.g.dart';

@collection
class CachedPromotion {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String promotionId;

  late String name;
  String? promoType;
  String? status;
  double? discountValue;
  DateTime? startDate;
  DateTime? endDate;
  late bool isActive;
  late DateTime cachedAt;

  CachedPromotion();

  factory CachedPromotion.fromSupabase(Map<String, dynamic> row) {
    final c = CachedPromotion();
    c.promotionId = row['id']?.toString() ?? '';
    c.name = row['name']?.toString() ?? '';
    c.promoType = row['promo_type']?.toString() ?? row['type']?.toString();
    c.status = row['status']?.toString();
    c.discountValue = (row['discount_value'] as num?)?.toDouble();
    c.startDate = row['start_date'] != null ? DateTime.tryParse(row['start_date'].toString()) : null;
    c.endDate = row['end_date'] != null ? DateTime.tryParse(row['end_date'].toString()) : null;
    c.isActive = row['is_active'] == true || row['is_active'] == 'true';
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  Map<String, dynamic> toMap() => {
        'id': promotionId,
        'name': name,
        'promo_type': promoType,
        'status': status,
        'discount_value': discountValue,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'is_active': isActive,
      };
}
