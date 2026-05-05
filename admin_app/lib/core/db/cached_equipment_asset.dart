import 'package:isar/isar.dart';

part 'cached_equipment_asset.g.dart';

@collection
class CachedEquipmentAsset {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String assetId;

  late String name;
  String? serialNumber;
  DateTime? purchaseDate;
  double? purchasePrice;
  double? currentValue;
  double? depreciationRate;
  String? status;
  DateTime? lastServiceDate;
  late DateTime cachedAt;

  CachedEquipmentAsset();

  factory CachedEquipmentAsset.fromSupabase(Map<String, dynamic> row) {
    final c = CachedEquipmentAsset();
    c.assetId = row['id']?.toString() ?? '';
    c.name = row['name']?.toString() ?? '';
    c.serialNumber = row['serial_number']?.toString();
    c.purchaseDate = row['purchase_date'] != null ? DateTime.tryParse(row['purchase_date'].toString()) : null;
    c.purchasePrice = (row['purchase_price'] as num?)?.toDouble();
    c.currentValue = (row['current_value'] as num?)?.toDouble();
    c.depreciationRate = (row['depreciation_rate'] as num?)?.toDouble();
    c.status = row['status']?.toString();
    c.lastServiceDate = row['last_service_date'] != null ? DateTime.tryParse(row['last_service_date'].toString()) : null;
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  Map<String, dynamic> toMap() => {
        'id': assetId,
        'name': name,
        'serial_number': serialNumber,
        'purchase_date': purchaseDate?.toIso8601String(),
        'purchase_price': purchasePrice,
        'current_value': currentValue,
        'depreciation_rate': depreciationRate,
        'status': status,
        'last_service_date': lastServiceDate?.toIso8601String(),
      };
}
