import 'package:isar/isar.dart';

part 'cached_staff_profile.g.dart';

/// Isar collection for staff profiles cached for offline PIN auth.
/// Replaces SharedPreferences cached_staff_profiles and pin_screen JSON file.
@collection
class CachedStaffProfile {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String staffId;

  late String fullName;
  late String role;
  late bool isActive;
  @Index()
  late String pinHash;
  late DateTime cachedAt;

  CachedStaffProfile();

  /// From Supabase row (profiles or staff_profiles): id, full_name, role, is_active, pin_hash
  factory CachedStaffProfile.fromSupabase(Map<String, dynamic> row) {
    final c = CachedStaffProfile();
    c.staffId = row['id']?.toString() ?? '';
    c.fullName = row['full_name']?.toString() ?? row['name']?.toString() ?? '';
    c.role = row['role']?.toString() ?? '';
    c.isActive = row['is_active'] == true || row['is_active'] == 'true';
    c.pinHash = row['pin_hash']?.toString() ?? '';
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  /// To map compatible with auth_service / pin_screen (id, full_name/name, role, is_active, pin_hash)
  Map<String, dynamic> toAuthMap() => {
        'id': staffId,
        'full_name': fullName,
        'name': fullName,
        'role': role,
        'is_active': isActive,
        'pin_hash': pinHash,
      };
}
