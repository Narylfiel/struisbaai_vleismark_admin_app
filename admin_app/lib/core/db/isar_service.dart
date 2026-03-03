import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'cached_staff_profile.dart';
import 'cached_inventory_item.dart';
import 'cached_category.dart';
import 'cached_production_batch.dart';
import 'cached_transaction.dart';
import 'cached_hunter_job.dart';
import 'cached_supplier.dart';
import 'cached_recipe.dart';
import 'cached_dryer_batch.dart';
import 'cached_promotion.dart';
import 'cached_modifier_group.dart';
import 'cached_modifier_item.dart';
import 'cached_yield_template.dart';
import 'cached_carcass_intake.dart';
import 'cached_hunter_service_config.dart';
import 'cached_leave_request.dart';
import 'cached_timecard.dart';
import 'cached_compliance_record.dart';
import 'cached_equipment_asset.dart';
import 'cached_business_account.dart';
import 'cached_invoice.dart';
import 'cached_ledger_entry.dart';
import 'cached_audit_log.dart';
import 'cached_stock_movement.dart';
import 'cached_customer.dart';
import 'cached_staff_credit.dart';
import 'cached_awol_record.dart';
import 'cached_payroll_entry.dart';
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
      [
        CachedStaffProfileSchema,
        CachedInventoryItemSchema,
        CachedCategorySchema,
        CachedProductionBatchSchema,
        CachedTransactionSchema,
        CachedHunterJobSchema,
        CachedSupplierSchema,
        CachedRecipeSchema,
        CachedDryerBatchSchema,
        CachedPromotionSchema,
        CachedModifierGroupSchema,
        CachedModifierItemSchema,
        CachedYieldTemplateSchema,
        CachedCarcassIntakeSchema,
        CachedHunterServiceConfigSchema,
        CachedLeaveRequestSchema,
        CachedTimecardSchema,
        CachedComplianceRecordSchema,
        CachedEquipmentAssetSchema,
        CachedBusinessAccountSchema,
        CachedInvoiceSchema,
        CachedLedgerEntrySchema,
        CachedAuditLogSchema,
        CachedStockMovementSchema,
        CachedCustomerSchema,
        CachedStaffCreditSchema,
        CachedAwolRecordSchema,
        CachedPayrollEntrySchema,
        PendingWriteSchema,
      ],
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

  static const Duration _inventoryCacheStale = Duration(hours: 4);
  static const Duration _financialCacheStale = Duration(minutes: 5);
  static const Duration _referenceCacheStale = Duration(minutes: 60);

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

  /// True if inventory cache is older than TTL or empty.
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

  /// Force cache bust — deletes all cached inventory items so next load
  /// fetches fresh from Supabase regardless of TTL.
  static Future<void> clearInventoryItemsCache() async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedInventoryItems.clear();
    });
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

  static Future<CachedHunterJob?> getHunterJobById(String jobId) async {
    final db = _isar;
    if (db == null) return null;
    return db.cachedHunterJobs.getByJobId(jobId);
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

  // ─── Suppliers (offline list) ────────────────────────────────────────────

  /// Save all suppliers; replaces existing cache.
  static Future<void> saveSuppliers(List<CachedSupplier> suppliers) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedSuppliers.clear();
      if (suppliers.isNotEmpty) {
        await db.cachedSuppliers.putAll(suppliers);
      }
    });
  }

  /// All cached suppliers. [includeInactive] false filters to isActive == true.
  static Future<List<CachedSupplier>> getAllSuppliers(bool includeInactive) async {
    final db = _isar;
    if (db == null) return [];
    final list = await db.cachedSuppliers.where().findAll();
    if (includeInactive) return list;
    return list.where((e) => e.isActive).toList();
  }

  /// True if suppliers cache is older than 30 minutes or empty.
  static Future<bool> isSuppliersCacheStale() async {
    final list = await getAllSuppliers(true);
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final s in list) {
      if (newest == null || s.cachedAt.isAfter(newest)) newest = s.cachedAt;
    }
    if (newest == null) return true;
    return DateTime.now().toUtc().difference(newest) > _inventoryCacheStale;
  }

  // ─── Recipes ─────────────────────────────────────────────────────────────

  static Future<void> saveRecipes(List<CachedRecipe> items) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedRecipes.clear();
      if (items.isNotEmpty) await db.cachedRecipes.putAll(items);
    });
  }

  static Future<List<CachedRecipe>> getAllRecipes(bool includeInactive) async {
    final db = _isar;
    if (db == null) return [];
    final list = await db.cachedRecipes.where().findAll();
    if (includeInactive) return list;
    return list.where((e) => e.isActive).toList();
  }

  static Future<bool> isRecipesCacheStale() async {
    final list = await getAllRecipes(true);
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final r in list) {
      if (newest == null || r.cachedAt.isAfter(newest)) newest = r.cachedAt;
    }
    return newest == null || DateTime.now().toUtc().difference(newest) > _inventoryCacheStale;
  }

  // ─── Dryer batches ──────────────────────────────────────────────────────

  static Future<void> saveDryerBatches(List<CachedDryerBatch> items) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedDryerBatchs.clear();
      if (items.isNotEmpty) await db.cachedDryerBatchs.putAll(items);
    });
  }

  static Future<List<CachedDryerBatch>> getAllDryerBatches() async {
    final db = _isar;
    if (db == null) return [];
    final list = await db.cachedDryerBatchs.where().findAll();
    list.sort((a, b) => (b.startDate ?? DateTime(0)).compareTo(a.startDate ?? DateTime(0)));
    return list;
  }

  static Future<bool> isDryerBatchCacheStale() async {
    final list = await getAllDryerBatches();
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final b in list) {
      if (newest == null || b.cachedAt.isAfter(newest)) newest = b.cachedAt;
    }
    return newest == null || DateTime.now().toUtc().difference(newest) > _inventoryCacheStale;
  }

  // ─── Promotions ──────────────────────────────────────────────────────────

  static Future<void> savePromotions(List<CachedPromotion> items) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedPromotions.clear();
      if (items.isNotEmpty) await db.cachedPromotions.putAll(items);
    });
  }

  static Future<List<CachedPromotion>> getAllPromotions(bool includeInactive) async {
    final db = _isar;
    if (db == null) return [];
    final list = await db.cachedPromotions.where().findAll();
    if (includeInactive) return list;
    return list.where((e) => e.isActive).toList();
  }

  static Future<bool> isPromotionsCacheStale() async {
    final list = await getAllPromotions(true);
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final p in list) {
      if (newest == null || p.cachedAt.isAfter(newest)) newest = p.cachedAt;
    }
    return newest == null || DateTime.now().toUtc().difference(newest) > _inventoryCacheStale;
  }

  // ─── Modifier groups (reference) ──────────────────────────────────────────

  static Future<void> saveModifierGroups(List<CachedModifierGroup> items) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedModifierGroups.clear();
      if (items.isNotEmpty) await db.cachedModifierGroups.putAll(items);
    });
  }

  static Future<List<CachedModifierGroup>> getAllModifierGroups() async {
    final db = _isar;
    if (db == null) return [];
    return db.cachedModifierGroups.where().findAll();
  }

  static Future<bool> isModifierGroupsCacheStale() async {
    final list = await getAllModifierGroups();
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final g in list) {
      if (newest == null || g.cachedAt.isAfter(newest)) newest = g.cachedAt;
    }
    return newest == null || DateTime.now().toUtc().difference(newest) > _referenceCacheStale;
  }

  // ─── Modifier items (reference) ─────────────────────────────────────────────

  static Future<void> saveModifierItems(List<CachedModifierItem> items) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedModifierItems.clear();
      if (items.isNotEmpty) await db.cachedModifierItems.putAll(items);
    });
  }

  static Future<List<CachedModifierItem>> getAllModifierItems(String? modifierGroupId) async {
    final db = _isar;
    if (db == null) return [];
    var list = await db.cachedModifierItems.where().findAll();
    if (modifierGroupId != null && modifierGroupId.isNotEmpty) {
      list = list.where((i) => i.modifierGroupId == modifierGroupId).toList();
    }
    return list;
  }

  static Future<bool> isModifierItemsCacheStale() async {
    final list = await getAllModifierItems(null);
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final i in list) {
      if (newest == null || i.cachedAt.isAfter(newest)) newest = i.cachedAt;
    }
    return newest == null || DateTime.now().toUtc().difference(newest) > _referenceCacheStale;
  }

  // ─── Yield templates (reference) ───────────────────────────────────────────

  static Future<void> saveYieldTemplates(List<CachedYieldTemplate> items) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedYieldTemplates.clear();
      if (items.isNotEmpty) await db.cachedYieldTemplates.putAll(items);
    });
  }

  static Future<List<CachedYieldTemplate>> getAllYieldTemplates() async {
    final db = _isar;
    if (db == null) return [];
    return db.cachedYieldTemplates.where().findAll();
  }

  static Future<bool> isYieldTemplatesCacheStale() async {
    final list = await getAllYieldTemplates();
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final t in list) {
      if (newest == null || t.cachedAt.isAfter(newest)) newest = t.cachedAt;
    }
    return newest == null || DateTime.now().toUtc().difference(newest) > _referenceCacheStale;
  }

  // ─── Carcass intakes ──────────────────────────────────────────────────────

  static Future<void> saveCarcassIntakes(List<CachedCarcassIntake> items) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedCarcassIntakes.clear();
      if (items.isNotEmpty) await db.cachedCarcassIntakes.putAll(items);
    });
  }

  static Future<List<CachedCarcassIntake>> getAllCarcassIntakes() async {
    final db = _isar;
    if (db == null) return [];
    final list = await db.cachedCarcassIntakes.where().findAll();
    list.sort((a, b) => (b.intakeDate ?? DateTime(0)).compareTo(a.intakeDate ?? DateTime(0)));
    return list;
  }

  static Future<bool> isCarcassIntakeCacheStale() async {
    final list = await getAllCarcassIntakes();
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final c in list) {
      if (newest == null || c.cachedAt.isAfter(newest)) newest = c.cachedAt;
    }
    return newest == null || DateTime.now().toUtc().difference(newest) > _inventoryCacheStale;
  }

  // ─── Hunter service config (reference) ─────────────────────────────────────

  static Future<void> saveHunterServiceConfigs(List<CachedHunterServiceConfig> items) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedHunterServiceConfigs.clear();
      if (items.isNotEmpty) await db.cachedHunterServiceConfigs.putAll(items);
    });
  }

  static Future<List<CachedHunterServiceConfig>> getAllHunterServiceConfigs(bool includeInactive) async {
    final db = _isar;
    if (db == null) return [];
    final list = await db.cachedHunterServiceConfigs.where().findAll();
    if (includeInactive) return list;
    return list.where((e) => e.isActive).toList();
  }

  static Future<bool> isHunterServiceConfigCacheStale() async {
    final list = await getAllHunterServiceConfigs(true);
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final c in list) {
      if (newest == null || c.cachedAt.isAfter(newest)) newest = c.cachedAt;
    }
    return newest == null || DateTime.now().toUtc().difference(newest) > _referenceCacheStale;
  }

  // ─── Leave requests ──────────────────────────────────────────────────────

  static Future<void> saveLeaveRequests(List<CachedLeaveRequest> items) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedLeaveRequests.clear();
      if (items.isNotEmpty) await db.cachedLeaveRequests.putAll(items);
    });
  }

  static Future<List<CachedLeaveRequest>> getAllLeaveRequests() async {
    final db = _isar;
    if (db == null) return [];
    final list = await db.cachedLeaveRequests.where().findAll();
    list.sort((a, b) => (b.startDate ?? DateTime(0)).compareTo(a.startDate ?? DateTime(0)));
    return list;
  }

  static Future<bool> isLeaveRequestCacheStale() async {
    final list = await getAllLeaveRequests();
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final r in list) {
      if (newest == null || r.cachedAt.isAfter(newest)) newest = r.cachedAt;
    }
    return newest == null || DateTime.now().toUtc().difference(newest) > _inventoryCacheStale;
  }

  // ─── Timecards ────────────────────────────────────────────────────────────

  static Future<void> saveTimecards(List<CachedTimecard> items) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedTimecards.clear();
      if (items.isNotEmpty) await db.cachedTimecards.putAll(items);
    });
  }

  static Future<List<CachedTimecard>> getAllTimecards() async {
    final db = _isar;
    if (db == null) return [];
    final list = await db.cachedTimecards.where().findAll();
    list.sort((a, b) => (b.shiftDate ?? DateTime(0)).compareTo(a.shiftDate ?? DateTime(0)));
    return list;
  }

  static Future<bool> isTimecardCacheStale() async {
    final list = await getAllTimecards();
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final t in list) {
      if (newest == null || t.cachedAt.isAfter(newest)) newest = t.cachedAt;
    }
    return newest == null || DateTime.now().toUtc().difference(newest) > _inventoryCacheStale;
  }

  // ─── Compliance records ──────────────────────────────────────────────────

  static Future<void> saveComplianceRecords(List<CachedComplianceRecord> items) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedComplianceRecords.clear();
      if (items.isNotEmpty) await db.cachedComplianceRecords.putAll(items);
    });
  }

  static Future<List<CachedComplianceRecord>> getAllComplianceRecords() async {
    final db = _isar;
    if (db == null) return [];
    return db.cachedComplianceRecords.where().findAll();
  }

  static Future<bool> isComplianceRecordCacheStale() async {
    final list = await getAllComplianceRecords();
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final r in list) {
      if (newest == null || r.cachedAt.isAfter(newest)) newest = r.cachedAt;
    }
    return newest == null || DateTime.now().toUtc().difference(newest) > _inventoryCacheStale;
  }

  // ─── Equipment assets (reference) ───────────────────────────────────────────

  static Future<void> saveEquipmentAssets(List<CachedEquipmentAsset> items) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedEquipmentAssets.clear();
      if (items.isNotEmpty) await db.cachedEquipmentAssets.putAll(items);
    });
  }

  static Future<List<CachedEquipmentAsset>> getAllEquipmentAssets() async {
    final db = _isar;
    if (db == null) return [];
    return db.cachedEquipmentAssets.where().findAll();
  }

  static Future<bool> isEquipmentAssetCacheStale() async {
    final list = await getAllEquipmentAssets();
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final e in list) {
      if (newest == null || e.cachedAt.isAfter(newest)) newest = e.cachedAt;
    }
    return newest == null || DateTime.now().toUtc().difference(newest) > _referenceCacheStale;
  }

  // ─── Business accounts ────────────────────────────────────────────────────

  static Future<void> saveBusinessAccounts(List<CachedBusinessAccount> items) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedBusinessAccounts.clear();
      if (items.isNotEmpty) await db.cachedBusinessAccounts.putAll(items);
    });
  }

  static Future<List<CachedBusinessAccount>> getAllBusinessAccounts(bool includeInactive) async {
    final db = _isar;
    if (db == null) return [];
    final list = await db.cachedBusinessAccounts.where().findAll();
    if (includeInactive) return list;
    return list.where((e) => e.isActive).toList();
  }

  static Future<bool> isBusinessAccountCacheStale() async {
    final list = await getAllBusinessAccounts(true);
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final a in list) {
      if (newest == null || a.cachedAt.isAfter(newest)) newest = a.cachedAt;
    }
    return newest == null || DateTime.now().toUtc().difference(newest) > _inventoryCacheStale;
  }

  // ─── Invoices (financial) ─────────────────────────────────────────────────

  static Future<void> saveInvoices(List<CachedInvoice> items) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedInvoices.clear();
      if (items.isNotEmpty) await db.cachedInvoices.putAll(items);
    });
  }

  static Future<List<CachedInvoice>> getAllInvoices() async {
    final db = _isar;
    if (db == null) return [];
    final list = await db.cachedInvoices.where().findAll();
    list.sort((a, b) => (b.invoiceDate ?? DateTime(0)).compareTo(a.invoiceDate ?? DateTime(0)));
    return list;
  }

  static Future<bool> isInvoiceCacheStale() async {
    final list = await getAllInvoices();
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final i in list) {
      if (newest == null || i.cachedAt.isAfter(newest)) newest = i.cachedAt;
    }
    return newest == null || DateTime.now().toUtc().difference(newest) > _financialCacheStale;
  }

  // ─── Ledger entries (financial) ────────────────────────────────────────────

  static Future<void> saveLedgerEntries(List<CachedLedgerEntry> items) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedLedgerEntrys.clear();
      if (items.isNotEmpty) await db.cachedLedgerEntrys.putAll(items);
    });
  }

  static Future<List<CachedLedgerEntry>> getAllLedgerEntries() async {
    final db = _isar;
    if (db == null) return [];
    final list = await db.cachedLedgerEntrys.where().findAll();
    list.sort((a, b) => (b.entryDate ?? DateTime(0)).compareTo(a.entryDate ?? DateTime(0)));
    return list;
  }

  static Future<bool> isLedgerEntryCacheStale() async {
    final list = await getAllLedgerEntries();
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final e in list) {
      if (newest == null || e.cachedAt.isAfter(newest)) newest = e.cachedAt;
    }
    return newest == null || DateTime.now().toUtc().difference(newest) > _financialCacheStale;
  }

  // ─── Audit log ────────────────────────────────────────────────────────────

  static Future<void> saveAuditLogs(List<CachedAuditLog> items) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedAuditLogs.clear();
      if (items.isNotEmpty) await db.cachedAuditLogs.putAll(items);
    });
  }

  static Future<List<CachedAuditLog>> getAllAuditLogs() async {
    final db = _isar;
    if (db == null) return [];
    final list = await db.cachedAuditLogs.where().findAll();
    list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return list;
  }

  static Future<bool> isAuditLogCacheStale() async {
    final list = await getAllAuditLogs();
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final l in list) {
      if (newest == null || l.cachedAt.isAfter(newest)) newest = l.cachedAt;
    }
    return newest == null || DateTime.now().toUtc().difference(newest) > _inventoryCacheStale;
  }

  // ─── Stock movements ──────────────────────────────────────────────────────

  static Future<void> saveStockMovements(List<CachedStockMovement> items) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedStockMovements.clear();
      if (items.isNotEmpty) await db.cachedStockMovements.putAll(items);
    });
  }

  static Future<List<CachedStockMovement>> getAllStockMovements() async {
    final db = _isar;
    if (db == null) return [];
    final list = await db.cachedStockMovements.where().findAll();
    list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return list;
  }

  static Future<bool> isStockMovementCacheStale() async {
    final list = await getAllStockMovements();
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final m in list) {
      if (newest == null || m.cachedAt.isAfter(newest)) newest = m.cachedAt;
    }
    return newest == null || DateTime.now().toUtc().difference(newest) > _inventoryCacheStale;
  }

  // ─── Customers ────────────────────────────────────────────────────────────

  static Future<void> saveCustomers(List<CachedCustomer> items) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedCustomers.clear();
      if (items.isNotEmpty) await db.cachedCustomers.putAll(items);
    });
  }

  static Future<List<CachedCustomer>> getAllCustomers() async {
    final db = _isar;
    if (db == null) return [];
    return db.cachedCustomers.where().findAll();
  }

  static Future<bool> isCustomerCacheStale() async {
    final list = await getAllCustomers();
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final c in list) {
      if (newest == null || c.cachedAt.isAfter(newest)) newest = c.cachedAt;
    }
    return newest == null || DateTime.now().toUtc().difference(newest) > _inventoryCacheStale;
  }

  // ─── Staff credits ────────────────────────────────────────────────────────

  static Future<void> saveStaffCredits(List<CachedStaffCredit> items) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedStaffCredits.clear();
      if (items.isNotEmpty) await db.cachedStaffCredits.putAll(items);
    });
  }

  static Future<List<CachedStaffCredit>> getAllStaffCredits() async {
    final db = _isar;
    if (db == null) return [];
    final list = await db.cachedStaffCredits.where().findAll();
    list.sort((a, b) => (b.creditDate ?? DateTime(0)).compareTo(a.creditDate ?? DateTime(0)));
    return list;
  }

  static Future<bool> isStaffCreditCacheStale() async {
    final list = await getAllStaffCredits();
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final c in list) {
      if (newest == null || c.cachedAt.isAfter(newest)) newest = c.cachedAt;
    }
    return newest == null || DateTime.now().toUtc().difference(newest) > _inventoryCacheStale;
  }

  // ─── AWOL records ────────────────────────────────────────────────────────

  static Future<void> saveAwolRecords(List<CachedAwolRecord> items) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedAwolRecords.clear();
      if (items.isNotEmpty) await db.cachedAwolRecords.putAll(items);
    });
  }

  static Future<List<CachedAwolRecord>> getAllAwolRecords() async {
    final db = _isar;
    if (db == null) return [];
    final list = await db.cachedAwolRecords.where().findAll();
    list.sort((a, b) => (b.awolDate ?? DateTime(0)).compareTo(a.awolDate ?? DateTime(0)));
    return list;
  }

  static Future<bool> isAwolRecordCacheStale() async {
    final list = await getAllAwolRecords();
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final r in list) {
      if (newest == null || r.cachedAt.isAfter(newest)) newest = r.cachedAt;
    }
    return newest == null || DateTime.now().toUtc().difference(newest) > _inventoryCacheStale;
  }

  // ─── Payroll entries ──────────────────────────────────────────────────────

  static Future<void> savePayrollEntries(List<CachedPayrollEntry> items) async {
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async {
      await db.cachedPayrollEntrys.clear();
      if (items.isNotEmpty) await db.cachedPayrollEntrys.putAll(items);
    });
  }

  static Future<List<CachedPayrollEntry>> getAllPayrollEntries() async {
    final db = _isar;
    if (db == null) return [];
    final list = await db.cachedPayrollEntrys.where().findAll();
    list.sort((a, b) => (b.payPeriodEnd ?? DateTime(0)).compareTo(a.payPeriodEnd ?? DateTime(0)));
    return list;
  }

  static Future<bool> isPayrollEntryCacheStale() async {
    final list = await getAllPayrollEntries();
    if (list.isEmpty) return true;
    DateTime? newest;
    for (final e in list) {
      if (newest == null || e.cachedAt.isAfter(newest)) newest = e.cachedAt;
    }
    return newest == null || DateTime.now().toUtc().difference(newest) > _inventoryCacheStale;
  }
}
