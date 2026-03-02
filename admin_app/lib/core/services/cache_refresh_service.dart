import 'dart:async';
import 'package:admin_app/core/db/cached_category.dart';
import 'package:admin_app/core/db/cached_inventory_item.dart';
import 'package:admin_app/core/db/cached_production_batch.dart';
import 'package:admin_app/core/db/cached_transaction.dart';
import 'package:admin_app/core/db/cached_hunter_job.dart';
import 'package:admin_app/core/db/cached_supplier.dart';
import 'package:admin_app/core/db/cached_recipe.dart';
import 'package:admin_app/core/db/cached_dryer_batch.dart';
import 'package:admin_app/core/db/cached_promotion.dart';
import 'package:admin_app/core/db/cached_modifier_group.dart';
import 'package:admin_app/core/db/cached_modifier_item.dart';
import 'package:admin_app/core/db/cached_yield_template.dart';
import 'package:admin_app/core/db/cached_carcass_intake.dart';
import 'package:admin_app/core/db/cached_hunter_service_config.dart';
import 'package:admin_app/core/db/cached_leave_request.dart';
import 'package:admin_app/core/db/cached_timecard.dart';
import 'package:admin_app/core/db/cached_compliance_record.dart';
import 'package:admin_app/core/db/cached_equipment_asset.dart';
import 'package:admin_app/core/db/cached_business_account.dart';
import 'package:admin_app/core/db/cached_invoice.dart';
import 'package:admin_app/core/db/cached_ledger_entry.dart';
import 'package:admin_app/core/db/cached_audit_log.dart';
import 'package:admin_app/core/db/cached_stock_movement.dart';
import 'package:admin_app/core/db/cached_customer.dart';
import 'package:admin_app/core/db/cached_staff_credit.dart';
import 'package:admin_app/core/db/cached_awol_record.dart';
import 'package:admin_app/core/db/cached_payroll_entry.dart';
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
      await _refreshSuppliers(client);
      await _refreshRecipes(client);
      await _refreshDryerBatches(client);
      await _refreshPromotions(client);
      await _refreshModifierGroups(client);
      await _refreshModifierItems(client);
      await _refreshYieldTemplates(client);
      await _refreshCarcassIntakes(client);
      await _refreshHunterServiceConfigs(client);
      await _refreshLeaveRequests(client);
      await _refreshTimecards(client);
      await _refreshComplianceRecords(client);
      await _refreshEquipmentAssets(client);
      await _refreshBusinessAccounts(client);
      await _refreshInvoices(client);
      await _refreshLedgerEntries(client);
      await _refreshAuditLogs(client);
      await _refreshStockMovements(client);
      await _refreshCustomers(client);
      await _refreshStaffCredits(client);
      await _refreshAwolRecords(client);
      await _refreshPayrollEntries(client);
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

  /// Fetch all suppliers and save to Isar.
  Future<void> _refreshSuppliers(dynamic client) async {
    final rows = await client
        .from('suppliers')
        .select('id, name, contact_name, phone, email, account_number, is_active')
        .order('name');
    final list = (rows as List)
        .map((r) => CachedSupplier.fromSupabase(Map<String, dynamic>.from(r as Map)))
        .toList();
    await IsarService.saveSuppliers(list);
  }

  Future<void> _refreshRecipes(dynamic client) async {
    try {
      final rows = await client.from('recipes').select('*').order('name');
      final list = (rows as List).map((r) => CachedRecipe.fromSupabase(Map<String, dynamic>.from(r as Map))).toList();
      await IsarService.saveRecipes(list);
    } catch (_) {}
  }

  Future<void> _refreshDryerBatches(dynamic client) async {
    try {
      final rows = await client.from('dryer_batches').select('*').order('id', ascending: false).limit(200);
      final list = <CachedDryerBatch>[];
      for (final r in rows as List) {
        final row = Map<String, dynamic>.from(r as Map);
        final mapped = <String, dynamic>{
          'id': row['id'],
          'status': row['status'],
          'start_date': row['started_at'] ?? row['start_date'],
          'end_date': row['completed_at'] ?? row['end_date'],
          'weight_in': row['input_weight_kg'] ?? row['weight_in'],
          'weight_out': row['output_weight_kg'] ?? row['weight_out'],
          'notes': row['notes'],
          'output_product_id': row['output_product_id'],
          'output_product_name': row['product_name'],
        };
        final in_ = (row['input_weight_kg'] ?? row['weight_in']) as num?;
        final out_ = (row['output_weight_kg'] ?? row['weight_out']) as num?;
        if (in_ != null && out_ != null && in_.toDouble() > 0) {
          mapped['shrinkage_pct'] = ((in_.toDouble() - out_.toDouble()) / in_.toDouble()) * 100;
        }
        list.add(CachedDryerBatch.fromSupabase(mapped));
      }
      await IsarService.saveDryerBatches(list);
    } catch (_) {}
  }

  Future<void> _refreshPromotions(dynamic client) async {
    try {
      final rows = await client.from('promotions').select('*').order('name').limit(200);
      final list = (rows as List).map((r) => CachedPromotion.fromSupabase(Map<String, dynamic>.from(r as Map))).toList();
      await IsarService.savePromotions(list);
    } catch (_) {}
  }

  Future<void> _refreshModifierGroups(dynamic client) async {
    try {
      final rows = await client.from('modifier_groups').select('*').order('name');
      final list = (rows as List).map((r) => CachedModifierGroup.fromSupabase(Map<String, dynamic>.from(r as Map))).toList();
      await IsarService.saveModifierGroups(list);
    } catch (_) {}
  }

  Future<void> _refreshModifierItems(dynamic client) async {
    try {
      final rows = await client.from('modifier_items').select('*').order('name');
      final list = (rows as List).map((r) => CachedModifierItem.fromSupabase(Map<String, dynamic>.from(r as Map))).toList();
      await IsarService.saveModifierItems(list);
    } catch (_) {}
  }

  Future<void> _refreshYieldTemplates(dynamic client) async {
    try {
      final rows = await client.from('yield_templates').select('*').order('name');
      final list = (rows as List).map((r) => CachedYieldTemplate.fromSupabase(Map<String, dynamic>.from(r as Map))).toList();
      await IsarService.saveYieldTemplates(list);
    } catch (_) {}
  }

  Future<void> _refreshCarcassIntakes(dynamic client) async {
    try {
      final thirtyDaysAgo = DateTime.now().toUtc().subtract(const Duration(days: 30)).toIso8601String();
      final rows = await client.from('carcass_intakes').select('*').gte('created_at', thirtyDaysAgo).order('created_at', ascending: false).limit(200);
      final list = (rows as List).map((r) => CachedCarcassIntake.fromSupabase(Map<String, dynamic>.from(r as Map))).toList();
      await IsarService.saveCarcassIntakes(list);
    } catch (_) {}
  }

  Future<void> _refreshHunterServiceConfigs(dynamic client) async {
    try {
      final rows = await client.from('hunter_services').select('*').order('species');
      final list = (rows as List).map((r) => CachedHunterServiceConfig.fromSupabase(Map<String, dynamic>.from(r as Map))).toList();
      await IsarService.saveHunterServiceConfigs(list);
    } catch (_) {}
  }

  Future<void> _refreshLeaveRequests(dynamic client) async {
    try {
      final thirtyDaysAgo = DateTime.now().toUtc().subtract(const Duration(days: 30)).toIso8601String();
      final rows = await client.from('leave_requests').select('*').gte('created_at', thirtyDaysAgo).order('created_at', ascending: false).limit(200);
      final list = (rows as List).map((r) => CachedLeaveRequest.fromSupabase(Map<String, dynamic>.from(r as Map))).toList();
      await IsarService.saveLeaveRequests(list);
    } catch (_) {}
  }

  Future<void> _refreshTimecards(dynamic client) async {
    try {
      final thirtyDaysAgo = DateTime.now().toUtc().subtract(const Duration(days: 30)).toIso8601String();
      final rows = await client.from('timecards').select('*').gte('shift_date', thirtyDaysAgo).order('shift_date', ascending: false).limit(200);
      final list = (rows as List).map((r) => CachedTimecard.fromSupabase(Map<String, dynamic>.from(r as Map))).toList();
      await IsarService.saveTimecards(list);
    } catch (_) {}
  }

  Future<void> _refreshComplianceRecords(dynamic client) async {
    try {
      final rows = await client.from('compliance_records').select('*').order('expiry_date');
      final list = (rows as List).map((r) => CachedComplianceRecord.fromSupabase(Map<String, dynamic>.from(r as Map))).toList();
      await IsarService.saveComplianceRecords(list);
    } catch (_) {}
  }

  Future<void> _refreshEquipmentAssets(dynamic client) async {
    try {
      final rows = await client.from('equipment_assets').select('*').order('name');
      final list = (rows as List).map((r) => CachedEquipmentAsset.fromSupabase(Map<String, dynamic>.from(r as Map))).toList();
      await IsarService.saveEquipmentAssets(list);
    } catch (_) {}
  }

  Future<void> _refreshBusinessAccounts(dynamic client) async {
    try {
      final rows = await client.from('business_accounts').select('*').order('name');
      final list = (rows as List).map((r) => CachedBusinessAccount.fromSupabase(Map<String, dynamic>.from(r as Map))).toList();
      await IsarService.saveBusinessAccounts(list);
    } catch (_) {}
  }

  Future<void> _refreshInvoices(dynamic client) async {
    try {
      final thirtyDaysAgo = DateTime.now().toUtc().subtract(const Duration(days: 30)).toIso8601String();
      final rows = await client.from('customer_invoices').select('*, business_accounts(id, name)').gte('invoice_date', thirtyDaysAgo).order('invoice_date', ascending: false).limit(200);
      final list = (rows as List).map((r) {
        final row = Map<String, dynamic>.from(r as Map);
        final ba = row['business_accounts'];
        row['account_name'] = (ba is Map) ? (ba['name']?.toString()) : null;
        return CachedInvoice.fromSupabase(row);
      }).toList();
      await IsarService.saveInvoices(list);
    } catch (_) {}
  }

  Future<void> _refreshLedgerEntries(dynamic client) async {
    try {
      final thirtyDaysAgo = DateTime.now().toUtc().subtract(const Duration(days: 30)).toIso8601String();
      final rows = await client.from('ledger_entries').select('*').gte('entry_date', thirtyDaysAgo).order('entry_date', ascending: false).limit(200);
      final list = (rows as List).map((r) => CachedLedgerEntry.fromSupabase(Map<String, dynamic>.from(r as Map))).toList();
      await IsarService.saveLedgerEntries(list);
    } catch (_) {}
  }

  Future<void> _refreshAuditLogs(dynamic client) async {
    try {
      final thirtyDaysAgo = DateTime.now().toUtc().subtract(const Duration(days: 30)).toIso8601String();
      final rows = await client.from('audit_log').select('*').gte('created_at', thirtyDaysAgo).order('created_at', ascending: false).limit(200);
      final list = (rows as List).map((r) => CachedAuditLog.fromSupabase(Map<String, dynamic>.from(r as Map))).toList();
      await IsarService.saveAuditLogs(list);
    } catch (_) {}
  }

  Future<void> _refreshStockMovements(dynamic client) async {
    try {
      final thirtyDaysAgo = DateTime.now().toUtc().subtract(const Duration(days: 30)).toIso8601String();
      final rows = await client.from('stock_movements').select('*').gte('created_at', thirtyDaysAgo).order('created_at', ascending: false).limit(200);
      final list = (rows as List).map((r) => CachedStockMovement.fromSupabase(Map<String, dynamic>.from(r as Map))).toList();
      await IsarService.saveStockMovements(list);
    } catch (_) {}
  }

  Future<void> _refreshCustomers(dynamic client) async {
    try {
      final rows = await client.from('loyalty_customers').select('*').order('name').limit(500);
      final list = (rows as List).map((r) {
        final row = Map<String, dynamic>.from(r as Map);
        row['tags'] = row['tags'] != null ? (row['tags'] is String ? row['tags'] : row['tags'].toString()) : null;
        return CachedCustomer.fromSupabase(row);
      }).toList();
      await IsarService.saveCustomers(list);
    } catch (_) {}
  }

  Future<void> _refreshStaffCredits(dynamic client) async {
    try {
      final thirtyDaysAgo = DateTime.now().toUtc().subtract(const Duration(days: 90)).toIso8601String();
      final rows = await client.from('staff_credit').select('*').gte('credit_date', thirtyDaysAgo).order('credit_date', ascending: false).limit(200);
      final list = (rows as List).map((r) => CachedStaffCredit.fromSupabase(Map<String, dynamic>.from(r as Map))).toList();
      await IsarService.saveStaffCredits(list);
    } catch (_) {}
  }

  Future<void> _refreshAwolRecords(dynamic client) async {
    try {
      final thirtyDaysAgo = DateTime.now().toUtc().subtract(const Duration(days: 90)).toIso8601String();
      final rows = await client.from('awol_records').select('*').gte('awol_date', thirtyDaysAgo).order('awol_date', ascending: false).limit(200);
      final list = (rows as List).map((r) => CachedAwolRecord.fromSupabase(Map<String, dynamic>.from(r as Map))).toList();
      await IsarService.saveAwolRecords(list);
    } catch (_) {}
  }

  Future<void> _refreshPayrollEntries(dynamic client) async {
    try {
      final thirtyDaysAgo = DateTime.now().toUtc().subtract(const Duration(days: 90)).toIso8601String();
      final rows = await client.from('payroll_entries').select('*').gte('pay_period_end', thirtyDaysAgo).order('pay_period_end', ascending: false).limit(200);
      final list = (rows as List).map((r) => CachedPayrollEntry.fromSupabase(Map<String, dynamic>.from(r as Map))).toList();
      await IsarService.savePayrollEntries(list);
    } catch (_) {}
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}
