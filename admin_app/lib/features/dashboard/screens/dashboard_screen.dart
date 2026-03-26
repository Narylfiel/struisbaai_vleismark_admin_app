import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/db/isar_service.dart';
import 'package:admin_app/core/services/connectivity_service.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/permission_service.dart';
import 'package:admin_app/core/constants/permissions.dart';
import 'package:admin_app/features/hr/services/leave_repository.dart';
import 'package:admin_app/features/hr/services/timecard_repository.dart';
import 'package:admin_app/features/inventory/screens/product_list_screen.dart';
import 'package:admin_app/features/reports/screens/report_hub_screen.dart';
import '../services/dashboard_repository.dart';
import '../services/dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = SupabaseService.client;
  final _dashboardRepo = DashboardRepository();
  /// Single instance so pricing alert cache (5 min TTL) in [DashboardService] is effective.
  late final DashboardService _dashboardPricingService =
      DashboardService(_supabase);
  final _ps = PermissionService();

  bool _isLoading = true;
  bool _isOffline = false;
  int _cachedInventoryCount = 0;
  int _cachedTransactionCountToday = 0;

  // Permission getters
  bool get _canSeeFinancials   => _ps.can(Permissions.seeFinancials);
  bool get _canSeeChartAmounts => _ps.can(Permissions.seeChartAmounts);
  bool get _canSeeChartCounts  => _ps.can(Permissions.seeChartCounts);
  bool get _canSeeAlerts       => _ps.can(Permissions.seeAlerts);
  bool get _canSeeTopProducts  => _ps.can(Permissions.seeTopProducts);
  bool get _canSeeTopRevenue   => _ps.can(Permissions.seeTopRevenue);

  // Stats from transactions (blueprint §3.2: Today's Sales, Transaction Count, Avg Basket, Gross Margin)
  double _todaySales = 0;
  double _salesChange = 0;
  int _transactionCount = 0;
  double _avgBasket = 0;
  double _grossMargin = 0;

  // Online Orders stats
  int _pendingOnlineOrders = 0;
  int _readyOnlineOrders = 0;

  // Alerts
  List<Map<String, dynamic>> _shrinkageAlerts = [];
  List<Map<String, dynamic>> _reorderAlerts = [];
  List<Map<String, dynamic>> _overdueAccounts = [];
  List<Map<String, dynamic>> _pendingLeave = [];
  /// Pricing intelligence alerts (same pipeline as report — [DashboardService]).
  List<Map<String, dynamic>> _pricingAlerts = [];
  bool _loadingPricingAlerts = true;

  // Clock-in status
  List<Map<String, dynamic>> _clockedIn = [];
  List<Map<String, dynamic>> _notClockedIn = [];

  // H5: 7-day sales chart
  List<Map<String, dynamic>> _sevenDaySales = [];
  Map<String, int> _weeklyTransactionCounts = {};
  RealtimeChannel? _transactionsChannel;
  RealtimeChannel? _onlineOrdersChannel;

  // Top products
  List<Map<String,dynamic>> _topProducts = [];
  bool _isLoadingTopProducts = false;
  String _topProductsMode = 'revenue';

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    if (ConnectivityService().isConnected) {
      _subscribeTransactions();
      _subscribeOnlineOrders();
      if (_canSeeTopProducts) {
        if (!_canSeeTopRevenue) _topProductsMode = 'quantity';
        _loadTopProducts();
      }
    }
  }

  @override
  void dispose() {
    _transactionsChannel?.unsubscribe();
    _onlineOrdersChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeTransactions() {
    _transactionsChannel = _supabase.channel('dashboard-transactions').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'transactions',
      callback: (_) {
        if (mounted) _loadDashboard();
      },
    ).subscribe();
  }

  void _subscribeOnlineOrders() {
    _onlineOrdersChannel = _supabase.channel('dashboard-online-orders').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'online_orders',
      callback: (_) {
        if (mounted) _loadOnlineOrdersStats();
      },
    ).subscribe();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final isConnected = ConnectivityService().isConnected;
    if (!isConnected) {
      try {
        final items = await IsarService.getAllInventoryItems(false);
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = todayStart.add(const Duration(days: 1));
        final tx = await IsarService.getTransactions(todayStart, todayEnd, null, null);
        if (mounted) {
          setState(() {
            _isOffline = true;
            _cachedInventoryCount = items.length;
            _cachedTransactionCountToday = tx.length;
            _isLoading = false;
            _loadingPricingAlerts = false;
            _pricingAlerts = [];
          });
        }
      } catch (e) {
        debugPrint('Dashboard offline load: $e');
        if (mounted) {
          setState(() {
            _isOffline = true;
            _isLoading = false;
            _loadingPricingAlerts = false;
            _pricingAlerts = [];
          });
        }
      }
      return;
    }
    setState(() => _isOffline = false);
    try {
      await Future.wait([
        _loadSalesStats(),
        _load7DaySales(),
        _loadAlerts(),
        _loadPricingAlerts(),
        _loadClockInStatus(),
        _loadOnlineOrdersStats(),
      ]);
    } catch (e) {
      debugPrint('Dashboard error: $e');
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _load7DaySales() async {
    try {
      final data = await _dashboardRepo.getLast7DaysSales();
      if (!mounted) return;
      setState(() => _sevenDaySales = data);
    } catch (e) {
      debugPrint('7-day sales: $e');
    }
  }

  Future<void> _loadSalesStats() async {
    try {
      final stats = await _dashboardRepo.getTodayStats();
      if (!mounted) return;
      setState(() {
        _todaySales = stats.todayTotal;
        _transactionCount = stats.transactionCount;
        _avgBasket = stats.avgBasket;
        _grossMargin = stats.grossMarginPct;
        _salesChange = stats.salesChangePct;
      });
    } catch (e) {
      // transactions table may not exist yet (POS not built)
      debugPrint('Dashboard transaction stats: $e');
    }
  }

  Future<void> _loadOnlineOrdersStats() async {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    try {
      final pendingRes = await _supabase
          .from('online_orders')
          .select('id')
          .inFilter('status', ['pending_cod', 'pending_payment', 'confirmed', 'packing'])
          .gte('collection_date', todayStr);

      final readyRes = await _supabase
          .from('online_orders')
          .select('id')
          .eq('status', 'ready')
          .gte('collection_date', todayStr);

      if (!mounted) return;
      setState(() {
        _pendingOnlineOrders = (pendingRes as List).length;
        _readyOnlineOrders = (readyRes as List).length;
      });
    } catch (e) {
      debugPrint('Dashboard online orders stats: $e');
      if (mounted) {
        setState(() {
          _pendingOnlineOrders = 0;
          _readyOnlineOrders = 0;
        });
      }
    }
  }

  Future<void> _loadAlerts() async {
    try {
      // Blueprint §10.1: unresolved alerts; schema has resolved (boolean) and item_name for display
      final shrinkage = await _supabase
          .from('shrinkage_alerts')
          .select('id, item_name, gap_percentage, shrinkage_percentage, status, resolved, created_at')
          .or('resolved.eq.false,resolved.is.null')
          .order('created_at', ascending: false)
          .limit(5);
      _shrinkageAlerts = List<Map<String, dynamic>>.from(shrinkage);
    } catch (e) {
      debugPrint('Shrinkage alerts: $e');
      _shrinkageAlerts = [];
      try {
        final fallback = await _supabase
            .from('shrinkage_alerts')
            .select()
            .eq('resolved', false)
            .order('created_at', ascending: false)
            .limit(5);
        _shrinkageAlerts = List<Map<String, dynamic>>.from(fallback);
      } catch (_) {}
    }

    try {
      final reorder = await _supabase
          .from('reorder_recommendations')
          .select('*, inventory_items(name)')
          .eq('auto_resolved', false)
          .order('days_of_stock', ascending: true)
          .limit(5);
      _reorderAlerts = List<Map<String, dynamic>>.from(reorder);
    } catch (e) {
      debugPrint('Reorder alerts: $e');
      _reorderAlerts = [];
    }

    try {
      final overdue = await _supabase
          .from('business_accounts')
          .select('name, balance, credit_terms_days')
          .eq('is_active', true)
          .gt('balance', 0)
          .limit(5);
      _overdueAccounts = List<Map<String, dynamic>>.from(overdue);
    } catch (e) {
      debugPrint('Overdue accounts: $e');
      _overdueAccounts = [];
    }

    try {
      final leaveRepo = LeaveRepository(client: _supabase);
      final leave = await leaveRepo.getAll(status: 'pending');
      final limited = leave.take(5);
      _pendingLeave = limited.map((row) {
        final staffProfiles = row['staff_profiles'];
        if (staffProfiles is Map) {
          return {
            ...row,
            'staff_profiles': {'full_name': staffProfiles['full_name']},
          };
        }
        return row;
      }).toList();
    } catch (e) {
      debugPrint('Leave requests: $e');
      _pendingLeave = [];
    }
  }

  /// Reuses [ReportRepository.getPricingIntelligenceRowsForAlerts] + [AlertService] (read-only).
  Future<void> _loadPricingAlerts() async {
    if (!_canSeeAlerts) {
      if (mounted) {
        setState(() {
          _pricingAlerts = [];
          _loadingPricingAlerts = false;
        });
      }
      return;
    }
    if (mounted) setState(() => _loadingPricingAlerts = true);
    try {
      final alerts = await _dashboardPricingService.getAlerts();
      if (!mounted) return;
      setState(() {
        _pricingAlerts = alerts;
        _loadingPricingAlerts = false;
      });
    } catch (e) {
      debugPrint('Pricing alerts: $e');
      if (mounted) {
        setState(() {
          _pricingAlerts = [];
          _loadingPricingAlerts = false;
        });
      }
    }
  }

  Future<void> _loadClockInStatus() async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day).toIso8601String();

      final allStaff = await _supabase
          .from('staff_profiles')
          .select('id, full_name, role')
          .eq('is_active', true)
          .inFilter('role', ['cashier', 'blockman', 'manager', 'owner']);

      final todayStartDt = DateTime.tryParse(todayStart);
      final todayCards = List<Map<String, dynamic>>.from(
        (await TimecardRepository(
                client: _supabase)
            .getAll(
              from: today,
              to: today,
            ))
            .where((c) {
              final ci = c['clock_in'];
              if (ci == null || todayStartDt == null) return false;
              final clockIn = DateTime.tryParse(ci.toString());
              if (clockIn == null) return false;
              return !clockIn.isBefore(todayStartDt);
            })
            .map((c) => <String, dynamic>{
                  'staff_id': c['staff_id'],
                  'clock_in': c['clock_in'],
                })
            .toList(),
      );

      final clockedInIds = todayCards
          .map((t) => t['staff_id'])
          .whereType<String>()
          .toSet();

      final inList = <Map<String, dynamic>>[];
      final outList = <Map<String, dynamic>>[];

      for (final staff in allStaff) {
        final sid = staff['id'] as String?;
        if (sid != null && clockedInIds.contains(sid)) {
          final matching = todayCards.where((t) => t['staff_id'] == sid).toList();
          if (matching.isNotEmpty) {
            inList.add({...staff, 'clock_in': matching.first['clock_in']});
          } else {
            outList.add(staff);
          }
        } else {
          outList.add(staff);
        }
      }

      if (mounted) {
        setState(() {
          _clockedIn = inList;
          _notClockedIn = outList;
        });
      }
    } catch (e) {
      debugPrint('Clock-in status: $e');
      if (mounted) {
        setState(() {
          _clockedIn = [];
          _notClockedIn = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        title: Row(
          children: [
            const Spacer(),
            Text(
              _formattedDate(),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              tooltip: 'Refresh dashboard',
              onPressed: _refreshDashboard,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _isOffline
              ? _buildOfflineDashboard()
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsRow(),
                        const SizedBox(height: 24),
                        if (_canSeeChartAmounts)
                          _build7DayChart()
                        else if (_canSeeChartCounts)
                          _buildTransactionCountChart(),
                        if (_canSeeChartAmounts || _canSeeChartCounts)
                          const SizedBox(height: 24),
                        if (_canSeeTopProducts)
                          _buildTopProductsWidget(),
                        if (_canSeeTopProducts)
                          const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_canSeeAlerts) ...[
                              Expanded(flex: 3, child: _buildAlerts()),
                              const SizedBox(width: 16),
                            ],
                            Expanded(
                              flex: _canSeeAlerts ? 2 : 1,
                              child: _buildClockInStatus(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Widget _buildOfflineDashboard() {
    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cloud_off, color: AppColors.warning, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Offline — showing cached data',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'CACHED INVENTORY',
                    value: '$_cachedInventoryCount',
                    sub: 'products in cache',
                    subColor: AppColors.textSecondary,
                    icon: Icons.inventory_2,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: "TODAY'S TRANSACTIONS",
                    value: '$_cachedTransactionCountToday',
                    sub: 'from cache',
                    subColor: AppColors.textSecondary,
                    icon: Icons.receipt_long,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.textSecondary, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Dashboard data from cache — connect for live updates. Live charts and alerts require internet connection.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build7DayChart() {
    if (_sevenDaySales.isEmpty) return const SizedBox.shrink();
    final data = _sevenDaySales.map((e) => _DaySalesPoint(
      e['label'] as String? ?? '',
      (e['total'] as num?)?.toDouble() ?? 0,
    )).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'SALES (LAST 7 DAYS)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                labelStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                majorGridLines: const MajorGridLines(width: 0),
              ),
              primaryYAxis: NumericAxis(
                labelFormat: 'R {value}',
                labelStyle: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                axisLine: const AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
              ),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <CartesianSeries<_DaySalesPoint, String>>[
                ColumnSeries<_DaySalesPoint, String>(
                  dataSource: data,
                  xValueMapper: (_DaySalesPoint p, _) => p.label,
                  yValueMapper: (_DaySalesPoint p, _) => p.total,
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        if (_canSeeFinancials)
          Expanded(
            child: _StatCard(
              title: "TODAY'S SALES",
              value: 'R ${_todaySales.toStringAsFixed(2)}',
              sub: '${_salesChange >= 0 ? '+' : ''}${_salesChange.toStringAsFixed(1)}% vs yesterday',
              subColor: _salesChange >= 0 ? AppColors.success : AppColors.error,
              icon: Icons.point_of_sale,
              color: AppColors.dashSales,
            ),
          ),
        if (_canSeeFinancials)
          const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'TRANSACTIONS',
            value: '$_transactionCount',
            sub: 'transactions today',
            subColor: AppColors.textSecondary,
            icon: Icons.receipt_long,
            color: AppColors.info,
          ),
        ),
        if (_canSeeFinancials)
          const SizedBox(width: 12),
        if (_canSeeFinancials)
          Expanded(
            child: _StatCard(
              title: 'AVG BASKET',
              value: 'R ${_avgBasket.toStringAsFixed(2)}',
              sub: 'per transaction',
              subColor: AppColors.textSecondary,
              icon: Icons.shopping_basket,
              color: AppColors.accent,
            ),
          ),
        const SizedBox(width: 12),
        // Online Orders tile
        Expanded(
          child: _StatCard(
            title: 'ONLINE ORDERS',
            value: '${_pendingOnlineOrders + _readyOnlineOrders}',
            sub: (_pendingOnlineOrders + _readyOnlineOrders) == 0
                ? 'No active orders'
                : '$_pendingOnlineOrders Pending · $_readyOnlineOrders Ready',
            subColor: _pendingOnlineOrders > 0
                ? AppColors.warning
                : _readyOnlineOrders > 0
                    ? AppColors.success
                    : AppColors.textSecondary,
            icon: Icons.shopping_bag,
            color: _pendingOnlineOrders > 0
                ? AppColors.warning
                : _readyOnlineOrders > 0
                    ? AppColors.success
                    : AppColors.info,
          ),
        ),
        if (_canSeeFinancials)
          const SizedBox(width: 12),
        if (_canSeeFinancials)
          Expanded(
            child: _StatCard(
              title: 'GROSS MARGIN',
              value: '${_grossMargin.toStringAsFixed(1)}%',
              sub: 'today',
              subColor: _grossMargin >= 30 ? AppColors.success : AppColors.warning,
              icon: Icons.trending_up,
              color: AppColors.dashMargin,
            ),
          ),
      ],
    );
  }

  void _handleAlertTap(Map<String, dynamic> alert) {
    final raw = alert['inventory_item_id'];
    String? itemId;
    if (raw != null) {
      final s = raw.toString();
      if (s.isNotEmpty && s != 'unknown') itemId = s;
    }
    if (itemId != null) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ProductListScreen(openInventoryItemId: itemId),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const ReportHubScreen(
          initialReportKey: 'pricing_intelligence',
        ),
      ),
    );
  }

  Widget _buildAlerts() {
    final sortedPricing = List<Map<String, dynamic>>.from(_pricingAlerts);
    const severityOrder = <String, int>{'high': 0, 'medium': 1};
    sortedPricing.sort((a, b) {
      final sa = a['severity']?.toString();
      final sb = b['severity']?.toString();
      return (severityOrder[sa] ?? 99).compareTo(severityOrder[sb] ?? 99);
    });

    final hasAlerts = _loadingPricingAlerts ||
        sortedPricing.isNotEmpty ||
        _shrinkageAlerts.isNotEmpty ||
        _reorderAlerts.isNotEmpty ||
        _overdueAccounts.isNotEmpty ||
        _pendingLeave.isNotEmpty;

    return _DashCard(
      title: 'ALERTS',
      icon: Icons.notifications_active,
      child: hasAlerts
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_loadingPricingAlerts)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Loading pricing alerts…',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                if (!_loadingPricingAlerts && sortedPricing.isNotEmpty)
                  ...sortedPricing.take(5).map((alert) {
                    final severity = alert['severity']?.toString();
                    final color = severity == 'high'
                        ? AppColors.error
                        : AppColors.warning;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => _handleAlertTap(alert),
                            hoverColor:
                                AppColors.primary.withValues(alpha: 0.06),
                            splashColor:
                                AppColors.primary.withValues(alpha: 0.12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 4,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color: color, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      alert['message']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ..._shrinkageAlerts.map((a) {
                      final name = a['item_name']?.toString().trim();
                      final gapPct = a['gap_percentage'] ?? a['shrinkage_percentage'];
                      final label = name != null && name.isNotEmpty
                          ? name
                          : (gapPct != null ? 'Gap ${(gapPct is num ? gapPct : double.tryParse(gapPct.toString()) ?? 0).toStringAsFixed(1)}%' : 'Shrinkage alert');
                      return _AlertRow(
                        color: AppColors.dashAlertRed,
                        icon: Icons.warning,
                        text: 'Shrinkage: $label',
                      );
                    }),
                ..._reorderAlerts.map((a) => _AlertRow(
                      color: AppColors.warning,
                      icon: Icons.inventory,
                      text:
                          'Reorder: ${a['inventory_items']?['name'] ?? 'Item'} — ${a['days_of_stock']?.toStringAsFixed(1) ?? '?'} days left',
                    )),
                ..._overdueAccounts.map((a) => _AlertRow(
                      color: AppColors.warning,
                      icon: Icons.account_balance_wallet,
                      text:
                          'Overdue: ${a['name']} — R ${(a['balance'] as num).toStringAsFixed(2)}',
                    )),
                ..._pendingLeave.map((a) => _AlertRow(
                      color: AppColors.dashAlertBlue,
                      icon: Icons.event_available,
                      text:
                          'Leave: ${a['staff_profiles']?['full_name'] ?? 'Staff'} (pending)',
                    )),
              ],
            )
          : const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 18),
                  SizedBox(width: 8),
                  Text('No alerts — all clear',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
    );
  }

  Widget _buildClockInStatus() {
    return _DashCard(
      title: 'CLOCK-IN STATUS',
      icon: Icons.access_time,
      child: Column(
        children: [
          ..._clockedIn.map((s) => _ClockRow(
                name: s['full_name'],
                role: s['role'],
                clockIn: s['clock_in'],
                isClockedIn: true,
              )),
          ..._notClockedIn.map((s) => _ClockRow(
                name: s['full_name'],
                role: s['role'],
                clockIn: null,
                isClockedIn: false,
              )),
          if (_clockedIn.isEmpty && _notClockedIn.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No staff profiles found',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionCountChart() {
    if (_weeklyTransactionCounts.isEmpty) return const SizedBox.shrink();
    
    final data = _weeklyTransactionCounts.entries.map((e) => _DayCountPoint(
      e.key.substring(8, 10), // Extract day from YYYY-MM-DD
      e.value,
    )).toList();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              const Text(
                'TRANSACTIONS (LAST 7 DAYS)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              primaryYAxis: NumericAxis(
                labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              series: <CartesianSeries>[
                ColumnSeries<_DayCountPoint, String>(
                  dataSource: data,
                  xValueMapper: (_DayCountPoint p, _) => p.label,
                  yValueMapper: (_DayCountPoint p, _) => p.count,
                  color: AppColors.info,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadWeeklyTransactionCounts() async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final data = await _supabase
          .from('transactions')
          .select('created_at')
          .gte('created_at', sevenDaysAgo.toIso8601String());

      final Map<String, int> counts = {};
      for (final t in (data as List)) {
        final date = DateTime.parse(t['created_at']).toLocal();
        final key = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
        counts[key] = (counts[key] ?? 0) + 1;
      }
      if (mounted) setState(() => _weeklyTransactionCounts = counts);
    } catch (e) {
      debugPrint('[DASHBOARD] Transaction count chart error: $e');
    }
  }

  Widget _buildTopProductsWidget() {
    return Card(
      color: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                const Text('TOP 5 PRODUCTS',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5)),
                const Spacer(),
                if (_canSeeTopRevenue)
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'revenue', label: Text('Revenue')),
                      ButtonSegment(value: 'quantity', label: Text('Qty')),
                    ],
                    selected: {_topProductsMode},
                    onSelectionChanged: (val) {
                      setState(() => _topProductsMode = val.first);
                      _loadTopProducts();
                    },
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                else
                  Text('By Quantity',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingTopProducts)
              const Center(child: CircularProgressIndicator())
            else if (_topProducts.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No sales data for today',
                      style: TextStyle(color: Colors.grey[500])),
                ),
              )
            else
              ..._topProducts.asMap().entries.map((entry) {
                return _buildTopProductRow(entry.key + 1, entry.value);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductRow(int rank, Map<String,dynamic> product) {
    final rankColors = {
      1: Colors.amber,
      2: Colors.grey[400]!,
      3: Colors.brown[300]!,
    };
    final rankColor = rankColors[rank] ?? Colors.grey[200]!;
    final isTopThree = rank <= 3;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rankColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isTopThree ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name']?.toString() ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'PLU ${product['plu_code']}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
          if (_canSeeTopRevenue && _topProductsMode == 'revenue')
            Text(
              'R ${((product['total_revenue'] as num?) ?? 0).toStringAsFixed(2)}',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.green[700]),
            )
          else
            Text(
              '${((product['total_qty'] as num?) ?? 0).toStringAsFixed(1)} ${product['unit_type'] ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  Future<void> _loadTopProducts() async {
    if (!_canSeeTopProducts) return;
    setState(() => _isLoadingTopProducts = true);
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      // Step 1: Get today's transaction IDs
      final txData = await _supabase
          .from('transactions')
          .select('id')
          .gte('created_at', startOfDay.toIso8601String());

      final txIds = (txData as List).map((t) => t['id'] as String).toList();

      if (txIds.isEmpty) {
        setState(() {
          _topProducts = [];
          _isLoadingTopProducts = false;
        });
        return;
      }

      // Step 2: Get transaction items for those transactions
      final itemData = await _supabase
          .from('transaction_items')
          .select('''
            quantity, line_total,
            inventory_items(plu_code, name, unit_type)
          ''')
          .inFilter('transaction_id', txIds);

      // Step 3: Group by product client-side
      final Map<String, Map<String,dynamic>> grouped = {};
      for (final item in (itemData as List)) {
        final inv = item['inventory_items'] as Map<String,dynamic>?;
        if (inv == null) continue;
        final plu = inv['plu_code']?.toString() ?? 'unknown';
        grouped.putIfAbsent(plu, () => {
          'plu_code': inv['plu_code'],
          'name': inv['name'] ?? 'Unknown',
          'unit_type': inv['unit_type'] ?? '',
          'total_qty': 0.0,
          'total_revenue': 0.0,
        });
        grouped[plu]!['total_qty'] =
            (grouped[plu]!['total_qty'] as double) +
            ((item['quantity'] as num?)?.toDouble() ?? 0.0);
        grouped[plu]!['total_revenue'] =
            (grouped[plu]!['total_revenue'] as double) +
            ((item['line_total'] as num?)?.toDouble() ?? 0.0);
      }

      // Step 4: Sort and take top 5
      final list = grouped.values.toList();
      if (_topProductsMode == 'revenue') {
        list.sort((a, b) => (b['total_revenue'] as double)
            .compareTo(a['total_revenue'] as double));
      } else {
        list.sort((a, b) =>
            (b['total_qty'] as double).compareTo(a['total_qty'] as double));
      }

      setState(() => _topProducts = list.take(5).toList());
    } catch (e) {
      debugPrint('[TOP PRODUCTS] Error: $e');
      setState(() => _topProducts = []);
    } finally {
      setState(() => _isLoadingTopProducts = false);
    }
  }

  void _refreshDashboard() {
    _loadSalesStats();
    if (_canSeeChartAmounts) _load7DaySales();
    if (_canSeeChartCounts && !_canSeeChartAmounts) _loadWeeklyTransactionCounts();
    if (_canSeeAlerts) {
      _loadAlerts();
      _loadPricingAlerts();
    }
    _loadClockInStatus();
    if (_canSeeTopProducts) _loadTopProducts();
  }
}

// ── Reusable widgets ──────────────────────────────────────────

class _DaySalesPoint {
  final String label;
  final double total;
  _DaySalesPoint(this.label, this.total);
}

class _DayCountPoint {
  final String label;
  final int count;
  _DayCountPoint(this.label, this.count);
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String sub;
  final Color subColor;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.sub,
    required this.subColor,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: TextStyle(fontSize: 11, color: subColor),
          ),
        ],
      ),
    );
  }
}

class _DashCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DashCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _AlertRow({
    required this.color,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockRow extends StatelessWidget {
  final String name;
  final String role;
  final String? clockIn;
  final bool isClockedIn;

  const _ClockRow({
    required this.name,
    required this.role,
    required this.clockIn,
    required this.isClockedIn,
  });

  String _formatTime(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 10,
            color: isClockedIn ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            isClockedIn ? _formatTime(clockIn) : 'Not in',
            style: TextStyle(
              fontSize: 12,
              color: isClockedIn ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
