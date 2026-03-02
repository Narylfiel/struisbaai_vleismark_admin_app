import 'package:isar/isar.dart';

part 'cached_hunter_service_config.g.dart';

@collection
class CachedHunterServiceConfig {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  late String configId;
  String? species;
  late double baseRate;
  late double perKgRate;
  late bool isActive;
  String? cutOptions;
  late DateTime cachedAt;

  CachedHunterServiceConfig();

  factory CachedHunterServiceConfig.fromSupabase(Map<String, dynamic> row) {
    final c = CachedHunterServiceConfig();
    c.configId = row['id']?.toString() ?? '';
    c.species = row['species']?.toString();
    c.baseRate = (row['base_rate'] as num?)?.toDouble() ?? 0;
    c.perKgRate = (row['per_kg_rate'] as num?)?.toDouble() ?? 0;
    c.isActive = row['is_active'] == true || row['is_active'] == 'true';
    if (row['cut_options'] != null) c.cutOptions = row['cut_options'] is String ? row['cut_options'] as String : row['cut_options'].toString();
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  Map<String, dynamic> toMap() => {'id': configId, 'species': species, 'base_rate': baseRate, 'per_kg_rate': perKgRate, 'is_active': isActive, 'cut_options': cutOptions};
}
