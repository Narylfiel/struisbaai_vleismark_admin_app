import 'package:isar/isar.dart';

part 'cached_modifier_group.g.dart';

@collection
class CachedModifierGroup {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String groupId;

  late String name;
  String? description;
  late bool isRequired;
  late int minSelections;
  late int maxSelections;
  late DateTime cachedAt;

  CachedModifierGroup();

  factory CachedModifierGroup.fromSupabase(Map<String, dynamic> row) {
    final c = CachedModifierGroup();
    c.groupId = row['id']?.toString() ?? '';
    c.name = row['name']?.toString() ?? '';
    c.description = row['description']?.toString();
    c.isRequired = row['is_required'] == true || row['is_required'] == 'true';
    c.minSelections = (row['min_selections'] as num?)?.toInt() ?? 0;
    c.maxSelections = (row['max_selections'] as num?)?.toInt() ?? 1;
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  Map<String, dynamic> toMap() => {
        'id': groupId,
        'name': name,
        'description': description,
        'is_required': isRequired,
        'min_selections': minSelections,
        'max_selections': maxSelections,
      };
}
