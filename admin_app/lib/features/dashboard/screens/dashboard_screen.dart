import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;

  // Stats
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

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadSalesStats(),
        _loadAlerts(),
        _loadClockInStatus(),
      ]);
    } catch (e) {
      debugPrint('Dashboard error: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadSalesStats() async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day).toIso8601String();
    final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();
    final yesterdayStart = DateTime(today.year, today.month, today.day - 1).toIso8601String();
    final yesterdayEnd = DateTime(today.year, today.month, today.day - 1, 23, 59, 59).toIso8601String();

    try {
      // Today's transactions
      final todayTxns = await _supabase
          .from('transactions')
          .select('total_amount, cost_amount')
          .gte('created_at', todayStart)
          .lte('created_at', todayEnd);

      // Yesterday's transactions
      final yesterdayTxns = await _supabase
          .from('transactions')
          .select('total_amount')
          .gte('created_at', yesterdayStart)
          .lte('created_at', yesterdayEnd);

      double todayTotal = 0;
      double todayCost = 0;
      for (final t in todayTxns) {
        todayTotal += (t['total_amount'] as num?)?.toDouble() ?? 0;
        todayCost += (t['cost_amount'] as num?)?.toDouble() ?? 0;
      }

      double yesterdayTotal = 0;
      for (final t in yesterdayTxns) {
        yesterdayTotal += (t['total_amount'] as num?)?.toDouble() ?? 0;
      }

      final count = todayTxns.length;
      final avg = count > 0 ? todayTotal / count : 0.0;
      final margin = todayTotal > 0
          ? ((todayTotal - todayCost) / todayTotal) * 100
          : 0.0;
      final change = yesterdayTotal > 0
          ? ((todayTotal - yesterdayTotal) / yesterdayTotal) * 100
          : 0.0;

      setState(() {
        _todaySales = todayTotal;
        _transactionCount = count;
        _avgBasket = avg;
        _grossMargin = margin;
        _salesChange = change;
      });
    } catch (e) {
      // transactions table may not exist yet (POS not built)
      debugPrint('Sales stats: $e');
    }
  }

  Future<void> _loadAlerts() async {
    try {
      final shrinkage = await _supabase
          .from('shrinkage_alerts')
          .select('*')
          .eq('resolved', false)
          .order('created_at', ascending: false)
          .limit(5);
      _shrinkageAlerts = List<Map<String, dynamic>>.from(shrinkage);
    } catch (e) {
      debugPrint('Shrinkage alerts: $e');
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
    }

    try {
      final overdue = await _supabase
          .from('business_accounts')
          .select('business_name, balance, credit_terms')
          .eq('active', true)
          .gt('balance', 0)
          .limit(5);
      _overdueAccounts = List<Map<String, dynamic>>.from(overdue);
    } catch (e) {
      debugPrint('Overdue accounts: $e');
    }

    try {
      final leave = await _supabase
          .from('leave_requests')
          .select('*, profiles(full_name)')
          .eq('status', 'pending')
          .limit(5);
      _pendingLeave = List<Map<String, dynamic>>.from(leave);
    } catch (e) {
      debugPrint('Leave requests: $e');
    }
  }

  Future<void> _loadClockInStatus() async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day).toIso8601String();

      final allStaff = await _supabase
          .from('profiles')
          .select('id, full_name, role')
          .eq('active', true)
          .inFilter('role', ['cashier', 'blockman', 'manager', 'owner']);

      final todayCards = await _supabase
          .from('timecards')
          .select('employee_id, clock_in')
          .gte('clock_in', todayStart);

      final clockedInIds = todayCards.map((t) => t['employee_id']).toSet();

      final inList = <Map<String, dynamic>>[];
      final outList = <Map<String, dynamic>>[];

      for (final staff in allStaff) {
        if (clockedInIds.contains(staff['id'])) {
          final card = todayCards.firstWhere(
              (t) => t['employee_id'] == staff['id']);
          inList.add({...staff, 'clock_in': card['clock_in']});
        } else {
          outList.add(staff);
        }
      }

      setState(() {
        _clockedIn = inList;
        _notClockedIn = outList;
      });
    } catch (e) {
      debugPrint('Clock-in status: $e');
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
            sub: 'sales today',
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
                ..._shrinkageAlerts.map((a) => _AlertRow(
                      color: AppColors.dashAlertRed,
                      icon: Icons.warning,
                      text: 'Shrinkage: ${a['item_name'] ?? 'Unknown item'}',
                    )),
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
                          'Overdue: ${a['business_name']} — R ${(a['balance'] as num).toStringAsFixed(2)}',
                    )),
                ..._pendingLeave.map((a) => _AlertRow(
                      color: AppColors.dashAlertBlue,
                      icon: Icons.event_available,
                      text:
                          'Leave: ${a['profiles']?['full_name'] ?? 'Staff'} (pending)',
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
