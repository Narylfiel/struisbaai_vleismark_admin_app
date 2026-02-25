import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import '../services/dashboard_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = SupabaseService.client;
  final _dashboardRepo = DashboardRepository();

  bool _isLoading = true;

  // Stats from transactions (blueprint §3.2: Today's Sales, Transaction Count, Avg Basket, Gross Margin)
  double _todaySales = 0;
  double _salesChange = 0;
  int _transactionCount = 0;
  double _avgBasket = 0;
  double _grossMargin = 0;

  // Alerts
  List<Map<String, dynamic>> _shrinkageAlerts = [];
  List<Map<String, dynamic>> _reorderAlerts = [];
  List<Map<String, dynamic>> _overdueAccounts = [];
  List<Map<String, dynamic>> _pendingLeave = [];

  // Clock-in status
  List<Map<String, dynamic>> _clockedIn = [];
  List<Map<String, dynamic>> _notClockedIn = [];

  // H5: 7-day sales chart
  List<Map<String, dynamic>> _sevenDaySales = [];
  RealtimeChannel? _transactionsChannel;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _subscribeTransactions();
  }

  @override
  void dispose() {
    _transactionsChannel?.unsubscribe();
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

  Future<void> _loadDashboard() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadSalesStats(),
        _load7DaySales(),
        _loadAlerts(),
        _loadClockInStatus(),
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
      final leave = await _supabase
          .from('leave_requests')
          .select('*, staff_profiles!staff_id(full_name)')
          .eq('status', 'pending')
          .limit(5);
      _pendingLeave = List<Map<String, dynamic>>.from(leave);
    } catch (e) {
      debugPrint('Leave requests: $e');
      _pendingLeave = [];
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

      final todayCards = List<Map<String, dynamic>>.from(
          await _supabase
              .from('timecards')
              .select('staff_id, clock_in')
              .gte('clock_in', todayStart));

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats row
                    _buildStatsRow(),
                    const SizedBox(height: 24),

                    // H5: 7-day sales chart
                    _build7DayChart(),
                    const SizedBox(height: 24),

                    // Alerts + Clock-in
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildAlerts()),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: _buildClockInStatus()),
                      ],
                    ),
                  ],
                ),
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
        const SizedBox(width: 12),
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

  Widget _buildAlerts() {
    final hasAlerts = _shrinkageAlerts.isNotEmpty ||
        _reorderAlerts.isNotEmpty ||
        _overdueAccounts.isNotEmpty ||
        _pendingLeave.isNotEmpty;

    return _DashCard(
      title: 'ALERTS',
      icon: Icons.notifications_active,
      child: hasAlerts
          ? Column(
              children: [
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
}

// ── Reusable widgets ──────────────────────────────────────────

class _DaySalesPoint {
  final String label;
  final double total;
  _DaySalesPoint(this.label, this.total);
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
