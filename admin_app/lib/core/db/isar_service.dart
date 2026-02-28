import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'cached_staff_profile.dart';
import 'cached_inventory_item.dart';
import 'cached_category.dart';
import 'cached_production_batch.dart';
import 'cached_transaction.dart';
import 'cached_hunter_job.dart';
import 'pending_write.dart';

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
      [CachedStaffProfileSchema, CachedInventoryItemSchema, CachedCategorySchema, CachedProductionBatchSchema, CachedTransactionSchema, CachedHunterJobSchema, PendingWriteSchema],
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

  // ─── Inventory items (offline stock levels) ───────────────────────────────

  static const Duration _inventoryCacheStale = Duration(minutes: 30);

  /// Save all inventory items; replaces existing cache.
  static Future<void> saveInventoryItems(List<CachedInventoryItem> items) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedInventoryItems.clear();
      if (items.isNotEmpty) {
        await db.cachedInventoryItems.putAll(items);
      }
    });
  }

  /// All cached inventory items. [includeInactive] false filters to isActive == true.
  static Future<List<CachedInventoryItem>> getAllInventoryItems(bool includeInactive) async {
    final db = _isar;
    if (db == null) return [];
    final list = await db.cachedInventoryItems.where().findAll();
    if (includeInactive) return list;
    return list.where((e) => e.isActive).toList();
  }

  /// True if inventory cache is older than 30 minutes or empty.
  static Future<bool> isInventoryItemsCacheStale() async {
    final list = await getAllInventoryItems(true);
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final p in list) {
      if (newest == null || p.cachedAt.isAfter(newest)) newest = p.cachedAt;
    }
    if (newest == null) return true;
    return DateTime.now().toUtc().difference(newest) > _inventoryCacheStale;
  }

  // ─── Categories (offline stock levels filter) ─────────────────────────────

  /// Save all categories; replaces existing cache.
  static Future<void> saveCategories(List<CachedCategory> categories) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedCategorys.clear();
      if (categories.isNotEmpty) {
        await db.cachedCategorys.putAll(categories);
      }
    });
  }

  /// All cached categories.
  static Future<List<CachedCategory>> getAllCategories() async {
    final db = _isar;
    if (db == null) return [];
    return db.cachedCategorys.where().findAll();
  }

  /// True if categories cache is older than 30 minutes or empty.
  static Future<bool> isCategoriesCacheStale() async {
    final list = await getAllCategories();
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final c in list) {
      if (newest == null || c.cachedAt.isAfter(newest)) newest = c.cachedAt;
    }
    if (newest == null) return true;
    return DateTime.now().toUtc().difference(newest) > _inventoryCacheStale;
  }

  // ─── Production batches (offline list) ───────────────────────────────────

  /// Save production batches; replaces existing cache. Limit to last 100 or last 30 days (caller should pass trimmed list).
  static Future<void> saveProductionBatches(List<CachedProductionBatch> batches) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedProductionBatchs.clear();
      if (batches.isNotEmpty) {
        await db.cachedProductionBatchs.putAll(batches);
      }
    });
  }

  /// Cached batches, optionally filtered by status, ordered by startedAt descending (then createdAt).
  static Future<List<CachedProductionBatch>> getProductionBatches(String? statusFilter) async {
    final db = _isar;
    if (db == null) return [];
    var list = await db.cachedProductionBatchs.where().findAll();
    list.sort((a, b) {
      final aAt = a.startedAt ?? a.createdAt ?? DateTime(0);
      final bAt = b.startedAt ?? b.createdAt ?? DateTime(0);
      return bAt.compareTo(aAt);
    });
    if (statusFilter != null && statusFilter.isNotEmpty) {
      list = list.where((b) => b.status == statusFilter).toList();
    }
    return list;
  }

  /// True if production batch cache is older than 30 minutes or empty.
  static Future<bool> isProductionBatchCacheStale() async {
    final list = await getProductionBatches(null);
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final b in list) {
      if (newest == null || b.cachedAt.isAfter(newest)) newest = b.cachedAt;
    }
    if (newest == null) return true;
    return DateTime.now().toUtc().difference(newest) > _inventoryCacheStale;
  }

  // ─── Transactions (offline list) ────────────────────────────────────────

  /// Save transactions; replaces existing cache for the scope we store.
  static Future<void> saveTransactions(List<CachedTransaction> items) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedTransactions.clear();
      if (items.isNotEmpty) {
        await db.cachedTransactions.putAll(items);
      }
    });
  }

  /// Cached transactions, optionally filtered by date range, payment method, staff. Order by createdAt descending.
  static Future<List<CachedTransaction>> getTransactions(
    DateTime? from,
    DateTime? to,
    String? paymentMethod,
    String? staffId,
  ) async {
    final db = _isar;
    if (db == null) return [];
    var list = await db.cachedTransactions.where().findAll();
    list.sort((a, b) {
      final aAt = a.createdAt ?? DateTime(0);
      final bAt = b.createdAt ?? DateTime(0);
      return bAt.compareTo(aAt);
    });
    if (from != null) {
      list = list.where((t) => t.createdAt != null && !t.createdAt!.isBefore(from)).toList();
    }
    if (to != null) {
      list = list.where((t) => t.createdAt != null && !t.createdAt!.isAfter(to)).toList();
    }
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      list = list.where((t) => t.paymentMethod == paymentMethod).toList();
    }
    if (staffId != null && staffId.isNotEmpty) {
      list = list.where((t) => t.staffId == staffId).toList();
    }
    return list;
  }

  /// True if transaction cache is older than 30 minutes or empty.
  static Future<bool> isTransactionCacheStale() async {
    final list = await getTransactions(null, null, null, null);
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final t in list) {
      if (t.cachedAt.isAfter(newest ?? DateTime(0))) newest = t.cachedAt;
    }
    if (newest == null) return true;
    return DateTime.now().toUtc().difference(newest) > _inventoryCacheStale;
  }

  // ─── Hunter jobs (offline list) ─────────────────────────────────────────

  static Future<void> saveHunterJobs(List<CachedHunterJob> items) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedHunterJobs.clear();
      if (items.isNotEmpty) {
        await db.cachedHunterJobs.putAll(items);
      }
    });
  }

  /// [statusFilter] null = all; 'completed' = completed only; '!completed' = active (not completed).
  static Future<List<CachedHunterJob>> getHunterJobs(String? statusFilter) async {
    final db = _isar;
    if (db == null) return [];
    var list = await db.cachedHunterJobs.where().findAll();
    list.sort((a, b) {
      final aAt = a.createdAt ?? DateTime(0);
      final bAt = b.createdAt ?? DateTime(0);
      return bAt.compareTo(aAt);
    });
    if (statusFilter != null && statusFilter.isNotEmpty) {
      if (statusFilter == '!completed') {
        list = list.where((j) => j.status != 'completed').toList();
      } else {
        list = list.where((j) => j.status == statusFilter).toList();
      }
    }
    return list;
  }

  static Future<bool> isHunterJobCacheStale() async {
    final list = await getHunterJobs(null);
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final j in list) {
      if (j.cachedAt.isAfter(newest ?? DateTime(0))) newest = j.cachedAt;
    }
    if (newest == null) return true;
    return DateTime.now().toUtc().difference(newest) > _inventoryCacheStale;
  }
}
