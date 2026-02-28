import 'package:isar/isar.dart';

part 'cached_category.g.dart';

/// Isar collection for categories cached for offline stock levels filter.
@collection
class CachedCategory {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String categoryId;

  late String name;
  late bool isActive;
  late DateTime cachedAt;

  CachedCategory();

  /// From Supabase categories row (id, name, active).
  factory CachedCategory.fromSupabase(Map<String, dynamic> row) {
    final c = CachedCategory();
    c.categoryId = row['id']?.toString() ?? '';
    c.name = row['name']?.toString() ?? '';
    c.isActive = row['active'] == true || row['active'] == 'true';
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  /// To map for dropdown (id, name).
  Map<String, dynamic> toMap() => {'id': categoryId, 'name': name};
}
