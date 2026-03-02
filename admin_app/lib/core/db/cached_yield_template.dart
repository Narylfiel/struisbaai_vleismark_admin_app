import 'package:isar/isar.dart';

part 'cached_yield_template.g.dart';

@collection
class CachedYieldTemplate {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String templateId;

  late String name;
  String? species;
  String? cuts; // JSON
  late DateTime cachedAt;

  CachedYieldTemplate();

  factory CachedYieldTemplate.fromSupabase(Map<String, dynamic> row) {
    final c = CachedYieldTemplate();
    c.templateId = row['id']?.toString() ?? '';
    c.name = row['name']?.toString() ?? '';
    c.species = row['species']?.toString();
    c.cuts = row['cuts'] != null ? (row['cuts'] is String ? row['cuts'] as String? : null) : null;
    if (c.cuts == null && row['cuts'] != null) c.cuts = row['cuts'].toString();
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  Map<String, dynamic> toMap() => {
        'id': templateId,
        'name': name,
        'species': species,
        'cuts': cuts,
      };
}
