import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'cached_staff_profile.dart';

/// Singleton Isar service. Open once at app startup; register all collections here.
class IsarService {
  IsarService._();
  static final IsarService _instance = IsarService._();
  static IsarService get instance => _instance;

  static Isar? _isar;
  static bool _initialized = false;

  /// Opened Isar instance. Null until [init] has been called successfully.
  static Isar? get isar => _isar;

  /// True after [init] completed successfully.
  static bool get isInitialized => _initialized;

  /// Open Isar once at app startup. Call from main() before runApp.
  /// Uses application support directory for the database file.
  static Future<void> init() async {
    if (_initialized && _isar != null) return;
    final dir = await getApplicationSupportDirectory();
    _isar = await Isar.open(
      [CachedStaffProfileSchema],
      directory: dir.path,
    );
    _initialized = true;
  }

  // ─── Staff profiles (offline PIN auth) ───────────────────────────────────

  /// Save all staff profiles; replaces existing cached profiles.
  static Future<void> saveStaffProfiles(List<CachedStaffProfile> profiles) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedStaffProfiles.clear();
      if (profiles.isNotEmpty) {
        await db.cachedStaffProfiles.putAll(profiles);
      }
    });
  }

  /// Save or update a single staff profile (e.g. after online login).
  static Future<void> saveStaffProfile(CachedStaffProfile profile) async {
    final db = _isar;
    if (db == null) return;
    profile.cachedAt = DateTime.now().toUtc();
    await db.writeTxn(() async {
      await db.cachedStaffProfiles.put(profile);
    });
  }

  /// Find cached profile by PIN hash and active status. Returns null if not found.
  static Future<CachedStaffProfile?> getStaffProfileByPinHash(String pinHash) async {
    final list = await getAllStaffProfiles();
    try {
      return list.firstWhere((p) => p.pinHash == pinHash && p.isActive);
    } catch (_) {
      return null;
    }
  }

  /// All cached staff profiles (for offline list / exists check).
  static Future<List<CachedStaffProfile>> getAllStaffProfiles() async {
    final db = _isar;
    if (db == null) return [];
    return db.cachedStaffProfiles.where().findAll();
  }

  /// True if cache has at least one profile.
  static Future<bool> hasCachedStaff() async {
    final list = await getAllStaffProfiles();
    return list.isNotEmpty;
  }

  /// True if oldest cached profile is older than 24 hours.
  static Future<bool> isStaffCacheStale() async {
    final list = await getAllStaffProfiles();
    if (list.isEmpty) return true;
    DateTime? oldest;
    for (final p in list) {
      if (oldest == null || p.cachedAt.isBefore(oldest)) oldest = p.cachedAt;
    }
    if (oldest == null) return true;
    return DateTime.now().toUtc().difference(oldest).inHours >= 24;
  }
}
