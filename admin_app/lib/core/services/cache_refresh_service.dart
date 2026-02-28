import 'dart:async';
import 'package:admin_app/core/db/cached_category.dart';
import 'package:admin_app/core/db/cached_inventory_item.dart';
import 'package:admin_app/core/db/cached_production_batch.dart';
import 'package:admin_app/core/db/cached_transaction.dart';
import 'package:admin_app/core/db/cached_hunter_job.dart';
import 'package:admin_app/core/db/isar_service.dart';
import 'package:admin_app/core/services/connectivity_service.dart';
import 'package:admin_app/core/services/offline_queue_service.dart';
import 'package:admin_app/core/services/supabase_service.dart';

/// When connectivity goes from offline to online, refreshes inventory, categories, and production batches cache in background.
/// Call [start] once at app startup (e.g. from main after IsarService.init).
class CacheRefreshService {
  CacheRefreshService._();
  static final CacheRefreshService _instance = CacheRefreshService._();
  factory CacheRefreshService() => _instance;

  StreamSubscription<bool>? _subscription;
  bool? _lastConnected;

  void start() {
    _subscription?.cancel();
    _lastConnected = ConnectivityService().isConnected;
    _subscription = ConnectivityService().connectionStatus.listen((connected) {
      if (connected && _lastConnected == false) {
        _refreshAll();
      }
      _lastConnected = connected;
    });
  }

  Future<void> _refreshAll() async {
    try {
      final client = SupabaseService.client;
      final cats = await client
          .from('categories')
          .select('id, name, active')
          .order('sort_order');
      final categories = (cats as List)
          .map((c) => CachedCategory.fromSupabase(Map<String, dynamic>.from(c as Map)))
          .toList();
      await IsarService.saveCategories(categories);

      final items = await client
          .from('inventory_items')
          .select(
            'id, name, plu_code, current_stock, stock_on_hand_fresh, stock_on_hand_frozen, '
            'reorder_level, unit_type, stock_control_type, category_id, is_active',
          )
          .order('name');
      final inventoryItems = (items as List)
          .map((i) => CachedInventoryItem.fromSupabase(Map<String, dynamic>.from(i as Map)))
          .toList();
      await IsarService.saveInventoryItems(inventoryItems);

      await _refreshProductionBatches(client);
      await _refreshTransactions(client);
      await _refreshHunterJobs(client);
      await OfflineQueueService().processQueue();
    } catch (_) {
      // Silent; next reconnect or screen load will retry
    }
  }

  /// Fetch last 100 batches or last 30 days (whichever is fewer), save to Isar.
  Future<void> _refreshProductionBatches(dynamic client) async {
    final thirtyDaysAgo = DateTime.now().toUtc().subtract(const Duration(days: 30)).toIso8601String();
    final batchRows = await client
        .from('production_batches')
        .select()
        .gte('created_at', thirtyDaysAgo)
        .order('created_at', ascending: false)
        .limit(100);
    final batchList = List<Map<String, dynamic>>.from(batchRows as List);
    if (batchList.isEmpty) {
      await IsarService.saveProductionBatches([]);
      return;
    }
    final recipeIds = batchList.map((b) => b['recipe_id']?.toString()).whereType<String>().toSet().toList();
    final productIds = batchList.map((b) => b['output_product_id']?.toString()).whereType<String>().toSet().toList();
    final recipeNameById = <String, String>{};
    final productNameById = <String, String>{};
    if (recipeIds.isNotEmpty) {
      final recipes = await client.from('recipes').select('id, name').inFilter('id', recipeIds);
      for (final r in recipes as List) {
        final m = Map<String, dynamic>.from(r as Map);
        recipeNameById[m['id']?.toString() ?? ''] = m['name']?.toString() ?? '';
      }
    }
    if (productIds.isNotEmpty) {
      final products = await client.from('inventory_items').select('id, name').inFilter('id', productIds);
      for (final p in products as List) {
        final m = Map<String, dynamic>.from(p as Map);
        productNameById[m['id']?.toString() ?? ''] = m['name']?.toString() ?? '';
      }
    }
    final batches = batchList.map((row) {
      final recipeId = row['recipe_id']?.toString();
      final outId = row['output_product_id']?.toString();
      return CachedProductionBatch.fromSupabase(
        row,
        recipeName: recipeId != null ? recipeNameById[recipeId] : null,
        outputProductName: outId != null ? productNameById[outId] : null,
      );
    }).toList();
    await IsarService.saveProductionBatches(batches);
  }

  /// Fetch last 7 days or 500 transactions (whichever is fewer), save to Isar.
  Future<void> _refreshTransactions(dynamic client) async {
    final sevenDaysAgo = DateTime.now().toUtc().subtract(const Duration(days: 7)).toIso8601String();
    final rows = await client
        .from('transactions')
        .select('''
          id, created_at, total_amount, cost_amount, payment_method,
          till_session_id, staff_id, account_id, receipt_number,
          is_voided, is_refund, profiles(full_name)
        ''')
        .gte('created_at', sevenDaysAgo)
        .order('created_at', ascending: false)
        .limit(500);
    final list = List<Map<String, dynamic>>.from(rows as List);
    final items = list.map((row) {
      final profiles = row['profiles'];
      String? staffName;
      if (profiles is Map) staffName = profiles['full_name']?.toString();
      return CachedTransaction.fromSupabase(row, staffName: staffName);
    }).toList();
    await IsarService.saveTransactions(items);
  }

  /// Fetch last 14 days or 200 hunter jobs (whichever is fewer), save to Isar.
  Future<void> _refreshHunterJobs(dynamic client) async {
    final fourteenDaysAgo = DateTime.now().toUtc().subtract(const Duration(days: 14)).toIso8601String();
    final rows = await client
        .from('hunter_jobs')
        .select()
        .gte('created_at', fourteenDaysAgo)
        .order('created_at', ascending: false)
        .limit(200);
    final list = List<Map<String, dynamic>>.from(rows as List);
    final items = list.map((row) => CachedHunterJob.fromSupabase(row)).toList();
    await IsarService.saveHunterJobs(items);
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}
