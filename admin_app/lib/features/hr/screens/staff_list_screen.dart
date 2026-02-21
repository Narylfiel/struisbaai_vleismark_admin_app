import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          Container(
            color: AppColors.cardBg,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(icon: Icon(Icons.people, size: 18), text: 'Staff Profiles'),
                Tab(icon: Icon(Icons.access_time, size: 18), text: 'Timecards'),
                Tab(icon: Icon(Icons.beach_access, size: 18), text: 'Leave'),
                Tab(icon: Icon(Icons.payments, size: 18), text: 'Payroll'),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _StaffProfilesTab(),
                _TimecardsTab(),
                _LeaveTab(),
                _PayrollTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 1: STAFF PROFILES
// ══════════════════════════════════════════════════════════════════

class _StaffProfilesTab extends StatefulWidget {
  const _StaffProfilesTab();
  @override
  State<_StaffProfilesTab> createState() => _StaffProfilesTabState();
}

class _StaffProfilesTabState extends State<_StaffProfilesTab> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _staff = [];
  bool _isLoading = true;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      var query = _supabase.from('profiles').select(
          'id, full_name, role, phone, email, employment_type, hourly_rate, '
          'monthly_salary, payroll_frequency, start_date, is_active, max_discount_pct');
      if (!_showInactive) query = query.eq('is_active', true);
      final data = await query.order('full_name');
      setState(() => _staff = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Staff load: $e');
    }
    setState(() => _isLoading = false);
  }

  void _openStaff(Map<String, dynamic>? staff) {
    showDialog(
      context: context,
      builder: (_) => _StaffFormDialog(staff: staff, onSaved: _load),
    );
  }

  Color _roleColor(String? role) {
    switch (role) {
      case 'owner': return const Color(0xFF7B1FA2);
      case 'manager': return AppColors.primary;
      case 'blockman': return AppColors.warning;
      case 'cashier': return AppColors.info;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          color: AppColors.cardBg,
          child: Row(
            children: [
              Row(children: [
                Switch(
                  value: _showInactive,
                  onChanged: (v) { setState(() => _showInactive = v); _load(); },
                  activeColor: AppColors.primary,
                ),
                const Text('Show inactive',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ]),
              const Spacer(),
              Text('${_staff.length} staff members',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _openStaff(null),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Add Staff'),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          color: AppColors.surfaceBg,
          child: const Row(children: [
            Expanded(flex: 2, child: Text('NAME', style: _h)),
            SizedBox(width: 12),
            SizedBox(width: 90, child: Text('ROLE', style: _h)),
            SizedBox(width: 12),
            Expanded(child: Text('PHONE', style: _h)),
            SizedBox(width: 12),
            SizedBox(width: 100, child: Text('PAY TYPE', style: _h)),
            SizedBox(width: 12),
            SizedBox(width: 90, child: Text('RATE', style: _h)),
            SizedBox(width: 12),
            SizedBox(width: 80, child: Text('FREQUENCY', style: _h)),
            SizedBox(width: 12),
            SizedBox(width: 70, child: Text('STATUS', style: _h)),
            SizedBox(width: 12),
            SizedBox(width: 60, child: Text('ACTIONS', style: _h)),
          ]),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _staff.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _staff.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (_, i) {
                        final s = _staff[i];
                        final isActive = s['is_active'] as bool? ?? true;
                        final empType = s['employment_type'] as String? ?? 'hourly';
                        final rate = empType == 'hourly'
                            ? 'R ${(s['hourly_rate'] as num?)?.toStringAsFixed(2) ?? '0.00'}/hr'
                            : 'R ${(s['monthly_salary'] as num?)?.toStringAsFixed(2) ?? '0.00'}/mo';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(children: [
                            Expanded(
                              flex: 2,
                              child: Row(children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: _roleColor(s['role']).withOpacity(0.15),
                                  child: Text(
                                    (s['full_name'] as String? ?? '?')[0].toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: _roleColor(s['role'])),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(s['full_name'] ?? '—',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary)),
                                ),
                              ]),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 90,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _roleColor(s['role']).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  (s['role'] as String? ?? '—').toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _roleColor(s['role'])),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(s['phone'] ?? '—',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 100,
                              child: Text(
                                empType == 'hourly' ? 'Hourly' : empType == 'weekly_salary' ? 'Weekly Salary' : 'Monthly Salary',
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 90,
                              child: Text(rate,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 80,
                              child: Text(
                                (s['payroll_frequency'] as String? ?? '—').toUpperCase(),
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 70,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.success.withOpacity(0.1)
                                      : AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isActive ? AppColors.success : AppColors.error),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 60,
                              child: IconButton(
                                icon: const Icon(Icons.edit, size: 16),
                                color: AppColors.primary,
                                onPressed: () => _openStaff(s),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ]),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.people_outline, size: 64, color: AppColors.border),
        const SizedBox(height: 16),
        const Text('No staff members yet',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => _openStaff(null),
          icon: const Icon(Icons.person_add),
          label: const Text('Add First Staff Member'),
        ),
      ]),
    );
  }

  static const _h = TextStyle(
      fontSize: 10, fontWeight: FontWeight.bold,
      color: AppColors.textSecondary, letterSpacing: 0.5);
}

// ══════════════════════════════════════════════════════════════════
// TAB 2: TIMECARDS
// ══════════════════════════════════════════════════════════════════

class _TimecardsTab extends StatefulWidget {
  const _TimecardsTab();
  @override
  State<_TimecardsTab> createState() => _TimecardsTabState();
}

class _TimecardsTabState extends State<_TimecardsTab> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _timecards = [];
  List<Map<String, dynamic>> _staff = [];
  bool _isLoading = true;
  String? _selectedStaffId;
  DateTime _weekStart = _getMonday(DateTime.now());

  static DateTime _getMonday(DateTime d) {
    return d.subtract(Duration(days: d.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _loadStaff();
    _loadTimecards();
  }

  Future<void> _loadStaff() async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('id, full_name')
          .eq('is_active', true)
          .order('full_name');
      setState(() => _staff = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Staff: $e');
    }
  }

  Future<void> _loadTimecards() async {
    setState(() => _isLoading = true);
    try {
      final weekEnd = _weekStart.add(const Duration(days: 6));
      var query = _supabase
          .from('timecards')
          .select('*, profiles(full_name, role, hourly_rate)')
          .gte('clock_in', _weekStart.toIso8601String())
          .lte('clock_in', '${weekEnd.toIso8601String().substring(0, 10)}T23:59:59')
          .order('clock_in', ascending: false);
      if (_selectedStaffId != null) {
        query = query.eq('employee_id', _selectedStaffId!);
      }
      final data = await query;
      setState(() => _timecards = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Timecards: $e');
    }
    setState(() => _isLoading = false);
  }

  String _formatDateTime(String? dt) {
    if (dt == null) return '—';
    final d = DateTime.parse(dt).toLocal();
    return '${d.day}/${d.month} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  double get _totalHours => _timecards.fold(
      0, (sum, t) => sum + ((t['total_hours'] as num?)?.toDouble() ?? 0));
  double get _totalOT => _timecards.fold(
      0, (sum, t) => sum + ((t['overtime_hours'] as num?)?.toDouble() ?? 0));

  @override
  Widget build(BuildContext context) {
    final weekEnd = _weekStart.add(const Duration(days: 6));

    return Column(children: [
      // Toolbar
      Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        color: AppColors.cardBg,
        child: Row(children: [
          // Week navigation
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));
              _loadTimecards();
            },
          ),
          Text(
            '${_weekStart.day}/${_weekStart.month} — ${weekEnd.day}/${weekEnd.month}/${weekEnd.year}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));
              _loadTimecards();
            },
          ),
          const SizedBox(width: 16),
          // Staff filter
          DropdownButton<String>(
            value: _selectedStaffId,
            hint: const Text('All Staff'),
            underline: const SizedBox(),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Staff')),
              ..._staff.map((s) => DropdownMenuItem(
                  value: s['id'] as String, child: Text(s['full_name'] as String))),
            ],
            onChanged: (v) { setState(() => _selectedStaffId = v); _loadTimecards(); },
          ),
          const Spacer(),
          // Summary chips
          _chip('Total Hours', '${_totalHours.toStringAsFixed(1)}h', AppColors.info),
          const SizedBox(width: 12),
          _chip('Overtime', '${_totalOT.toStringAsFixed(1)}h',
              _totalOT > 0 ? AppColors.warning : AppColors.textSecondary),
          const SizedBox(width: 12),
          _chip('Entries', '${_timecards.length}', AppColors.textSecondary),
        ]),
      ),
      const Divider(height: 1, color: AppColors.border),
      // Header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        color: AppColors.surfaceBg,
        child: const Row(children: [
          Expanded(flex: 2, child: Text('STAFF MEMBER', style: _hStyle)),
          SizedBox(width: 12),
          SizedBox(width: 130, child: Text('CLOCK IN', style: _hStyle)),
          SizedBox(width: 12),
          SizedBox(width: 130, child: Text('CLOCK OUT', style: _hStyle)),
          SizedBox(width: 12),
          SizedBox(width: 70, child: Text('TOTAL', style: _hStyle)),
          SizedBox(width: 12),
          SizedBox(width: 70, child: Text('OVERTIME', style: _hStyle)),
          SizedBox(width: 12),
          SizedBox(width: 90, child: Text('STATUS', style: _hStyle)),
        ]),
      ),
      const Divider(height: 1, color: AppColors.border),
      Expanded(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _timecards.isEmpty
                ? const Center(
                    child: Text('No timecards for this period',
                        style: TextStyle(color: AppColors.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _timecards.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (_, i) {
                      final t = _timecards[i];
                      final hours = (t['total_hours'] as num?)?.toDouble() ?? 0;
                      final ot = (t['overtime_hours'] as num?)?.toDouble() ?? 0;
                      final needsApproval = t['requires_approval'] as bool? ?? false;
                      final otApproved = t['overtime_approved'] as bool? ?? false;
                      final isOpen = t['clock_out'] == null;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              t['profiles']?['full_name'] ?? '—',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 130,
                            child: Text(_formatDateTime(t['clock_in']),
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 130,
                            child: Text(
                              isOpen ? '● Active' : _formatDateTime(t['clock_out']),
                              style: TextStyle(
                                fontSize: 13,
                                color: isOpen ? AppColors.success : AppColors.textPrimary,
                                fontWeight: isOpen ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 70,
                            child: Text(
                              isOpen ? '—' : '${hours.toStringAsFixed(1)}h',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 70,
                            child: Text(
                              ot > 0 ? '${ot.toStringAsFixed(1)}h' : '—',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: ot > 0 ? AppColors.warning : AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 90,
                            child: isOpen
                                ? _statusBadge('CLOCKED IN', AppColors.success)
                                : needsApproval && !otApproved
                                    ? _statusBadge('OT PENDING', AppColors.warning)
                                    : _statusBadge('COMPLETE', AppColors.info),
                          ),
                        ]),
                      );
                    },
                  ),
      ),
    ]);
  }

  Widget _chip(String label, String value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          textAlign: TextAlign.center),
    );
  }

  static const _hStyle = TextStyle(
      fontSize: 10, fontWeight: FontWeight.bold,
      color: AppColors.textSecondary, letterSpacing: 0.5);
}

// ══════════════════════════════════════════════════════════════════
// TAB 3: LEAVE MANAGEMENT
// ══════════════════════════════════════════════════════════════════

class _LeaveTab extends StatefulWidget {
  const _LeaveTab();
  @override
  State<_LeaveTab> createState() => _LeaveTabState();
}

class _LeaveTabState extends State<_LeaveTab> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _balances = [];
  bool _isLoading = true;
  String _filter = 'Pending';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final requests = await _supabase
          .from('leave_requests')
          .select('*, profiles(full_name, role)')
          .eq('status', _filter)
          .order('created_at', ascending: false);
      final balances = await _supabase
          .from('leave_balances')
          .select('*, profiles(full_name)')
          .order('profiles(full_name)');
      setState(() {
        _requests = List<Map<String, dynamic>>.from(requests);
        _balances = List<Map<String, dynamic>>.from(balances);
      });
    } catch (e) {
      debugPrint('Leave: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updateStatus(String id, String status, String? notes) async {
    await _supabase.from('leave_requests').update({
      'status': status,
      'review_notes': notes,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // Left: requests
      Expanded(
        flex: 3,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            color: AppColors.cardBg,
            child: Row(children: [
              const Text('Leave Requests',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const Spacer(),
              ...['Pending', 'Approved', 'Rejected'].map((s) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(s),
                  selected: _filter == s,
                  onSelected: (_) { setState(() => _filter = s); _load(); },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                      color: _filter == s ? Colors.white : AppColors.textSecondary,
                      fontSize: 12),
                ),
              )),
            ]),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _requests.isEmpty
                    ? Center(
                        child: Text('No $_filter requests',
                            style: const TextStyle(color: AppColors.textSecondary)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _requests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final r = _requests[i];
                          final isPending = r['status'] == 'Pending';
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isPending
                                    ? AppColors.warning.withOpacity(0.4)
                                    : AppColors.border,
                              ),
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Row(children: [
                                Text(
                                  r['profiles']?['full_name'] ?? '—',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(r['leave_type'] ?? '—',
                                      style: const TextStyle(
                                          fontSize: 11, color: AppColors.info)),
                                ),
                                const Spacer(),
                                Text(
                                  '${r['total_days']} day${(r['total_days'] as num?) == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              Text(
                                '${r['start_date']} → ${r['end_date']}',
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.textSecondary),
                              ),
                              if (r['reason'] != null) ...[
                                const SizedBox(height: 4),
                                Text(r['reason'],
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.textSecondary)),
                              ],
                              if (isPending) ...[
                                const SizedBox(height: 12),
                                Row(children: [
                                  ElevatedButton(
                                    onPressed: () =>
                                        _updateStatus(r['id'], 'Approved', null),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8)),
                                    child: const Text('Approve'),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: () =>
                                        _updateStatus(r['id'], 'Rejected', null),
                                    child: const Text('Decline'),
                                  ),
                                ]),
                              ],
                            ]),
                          );
                        },
                      ),
          ),
        ]),
      ),
      const VerticalDivider(width: 1, color: AppColors.border),
      // Right: balances
      SizedBox(
        width: 280,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: AppColors.cardBg,
            child: const Row(children: [
              Text('Leave Balances',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
            ]),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _balances.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final b = _balances[i];
                final annual = (b['annual_leave_balance'] as num?)?.toDouble() ?? 0;
                final sick = (b['sick_leave_balance'] as num?)?.toDouble() ?? 0;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(b['profiles']?['full_name'] ?? '—',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    _balanceRow('Annual', annual, 21, AppColors.info),
                    const SizedBox(height: 4),
                    _balanceRow('Sick', sick, 30, AppColors.warning),
                    const SizedBox(height: 4),
                    _balanceRow('Family', 3, 3, AppColors.success),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _balanceRow(String label, double current, double max, Color color) {
    return Row(children: [
      SizedBox(
          width: 50,
          child: Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (current / max).clamp(0, 1),
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ),
      const SizedBox(width: 6),
      Text('${current.toStringAsFixed(1)}d',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 4: PAYROLL
// ══════════════════════════════════════════════════════════════════

class _PayrollTab extends StatefulWidget {
  const _PayrollTab();
  @override
  State<_PayrollTab> createState() => _PayrollTabState();
}

class _PayrollTabState extends State<_PayrollTab> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _periods = [];
  Map<String, dynamic>? _selectedPeriod;
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPeriods();
  }

  Future<void> _loadPeriods() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('payroll_entries')
          .select('period_id')
          .order('created_at', ascending: false);
      // For now show staff with calculated pay from timecards
      await _loadCurrentPayroll();
    } catch (e) {
      debugPrint('Payroll: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadCurrentPayroll() async {
    // Get current month's data
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    try {
      final staff = await _supabase
          .from('profiles')
          .select('id, full_name, role, employment_type, hourly_rate, monthly_salary, payroll_frequency')
          .eq('is_active', true)
          .order('full_name');

      final timecards = await _supabase
          .from('timecards')
          .select('employee_id, total_hours, regular_hours, overtime_hours, sunday_hours')
          .gte('clock_in', monthStart.toIso8601String())
          .not('clock_out', 'is', null);

      // Build payroll summary per staff
      final summary = <Map<String, dynamic>>[];
      for (final s in List<Map<String, dynamic>>.from(staff)) {
        final empTimecards = List<Map<String, dynamic>>.from(timecards)
            .where((t) => t['employee_id'] == s['id'])
            .toList();
        final totalHours = empTimecards.fold<double>(
            0, (sum, t) => sum + ((t['total_hours'] as num?)?.toDouble() ?? 0));
        final regHours = empTimecards.fold<double>(
            0, (sum, t) => sum + ((t['regular_hours'] as num?)?.toDouble() ?? 0));
        final otHours = empTimecards.fold<double>(
            0, (sum, t) => sum + ((t['overtime_hours'] as num?)?.toDouble() ?? 0));
        final sunHours = empTimecards.fold<double>(
            0, (sum, t) => sum + ((t['sunday_hours'] as num?)?.toDouble() ?? 0));

        final hourlyRate = (s['hourly_rate'] as num?)?.toDouble() ?? 0;
        final monthlySalary = (s['monthly_salary'] as num?)?.toDouble() ?? 0;
        final empType = s['employment_type'] as String? ?? 'hourly';

        double grossPay;
        if (empType == 'hourly') {
          grossPay = (regHours * hourlyRate) +
              (otHours * hourlyRate * 1.5) +
              (sunHours * hourlyRate * 2.0);
        } else {
          grossPay = monthlySalary;
        }

        // SA deductions
        final uif = grossPay * 0.01; // UIF 1%
        final netPay = grossPay - uif;

        summary.add({
          ...s,
          'total_hours': totalHours,
          'regular_hours': regHours,
          'overtime_hours': otHours,
          'sunday_hours': sunHours,
          'gross_pay': grossPay,
          'uif': uif,
          'net_pay': netPay,
        });
      }
      setState(() => _entries = summary);
    } catch (e) {
      debugPrint('Payroll calc: $e');
    }
  }

  double get _totalGross =>
      _entries.fold(0, (sum, e) => sum + ((e['gross_pay'] as num?)?.toDouble() ?? 0));
  double get _totalNet =>
      _entries.fold(0, (sum, e) => sum + ((e['net_pay'] as num?)?.toDouble() ?? 0));
  double get _totalUIF =>
      _entries.fold(0, (sum, e) => sum + ((e['uif'] as num?)?.toDouble() ?? 0));

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        color: AppColors.cardBg,
        child: Row(children: [
          Text(
            'Payroll Summary — ${months[now.month - 1]} ${now.year}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(width: 24),
          _payChip('Gross', 'R ${_totalGross.toStringAsFixed(2)}', AppColors.textPrimary),
          const SizedBox(width: 16),
          _payChip('UIF (1%)', 'R ${_totalUIF.toStringAsFixed(2)}', AppColors.error),
          const SizedBox(width: 16),
          _payChip('Net Pay', 'R ${_totalNet.toStringAsFixed(2)}', AppColors.success),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Owner Only',
                style: TextStyle(fontSize: 11, color: AppColors.warning,
                    fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
      const Divider(height: 1, color: AppColors.border),
      // Table header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        color: AppColors.surfaceBg,
        child: const Row(children: [
          Expanded(flex: 2, child: Text('STAFF MEMBER', style: _pHdr)),
          SizedBox(width: 12),
          SizedBox(width: 80, child: Text('TYPE', style: _pHdr)),
          SizedBox(width: 12),
          SizedBox(width: 70, child: Text('HRS', style: _pHdr)),
          SizedBox(width: 12),
          SizedBox(width: 60, child: Text('OT HRS', style: _pHdr)),
          SizedBox(width: 12),
          SizedBox(width: 100, child: Text('GROSS PAY', style: _pHdr)),
          SizedBox(width: 12),
          SizedBox(width: 80, child: Text('UIF (1%)', style: _pHdr)),
          SizedBox(width: 12),
          SizedBox(width: 100, child: Text('NET PAY', style: _pHdr)),
          SizedBox(width: 12),
          SizedBox(width: 80, child: Text('FREQUENCY', style: _pHdr)),
        ]),
      ),
      const Divider(height: 1, color: AppColors.border),
      Expanded(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _entries.isEmpty
                ? const Center(
                    child: Text('No staff found',
                        style: TextStyle(color: AppColors.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _entries.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (_, i) {
                      final e = _entries[i];
                      final gross = (e['gross_pay'] as num?)?.toDouble() ?? 0;
                      final uif = (e['uif'] as num?)?.toDouble() ?? 0;
                      final net = (e['net_pay'] as num?)?.toDouble() ?? 0;
                      final hours = (e['total_hours'] as num?)?.toDouble() ?? 0;
                      final ot = (e['overtime_hours'] as num?)?.toDouble() ?? 0;
                      final empType = e['employment_type'] as String? ?? 'hourly';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(children: [
                          Expanded(
                            flex: 2,
                            child: Text(e['full_name'] ?? '—',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 80,
                            child: Text(
                              empType == 'hourly' ? 'Hourly' : 'Salary',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 70,
                            child: Text(
                              empType == 'hourly' ? '${hours.toStringAsFixed(1)}h' : '—',
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 60,
                            child: Text(
                              ot > 0 ? '${ot.toStringAsFixed(1)}h' : '—',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: ot > 0 ? AppColors.warning : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 100,
                            child: Text('R ${gross.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 80,
                            child: Text('R ${uif.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.error)),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 100,
                            child: Text('R ${net.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success)),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 80,
                            child: Text(
                              (e['payroll_frequency'] as String? ?? '—').toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ),
                        ]),
                      );
                    },
                  ),
      ),
    ]);
  }

  Widget _payChip(String label, String value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  static const _pHdr = TextStyle(
      fontSize: 10, fontWeight: FontWeight.bold,
      color: AppColors.textSecondary, letterSpacing: 0.5);
}

// ══════════════════════════════════════════════════════════════════
// STAFF FORM DIALOG
// ══════════════════════════════════════════════════════════════════

class _StaffFormDialog extends StatefulWidget {
  final Map<String, dynamic>? staff;
  final VoidCallback onSaved;
  const _StaffFormDialog({required this.staff, required this.onSaved});

  @override
  State<_StaffFormDialog> createState() => _StaffFormDialogState();
}

class _StaffFormDialogState extends State<_StaffFormDialog>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  bool _isSaving = false;

  // Personal
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _idNumberController = TextEditingController();
  String _role = 'cashier';
  bool _isActive = true;

  // Employment
  final _hourlyRateController = TextEditingController();
  final _monthlySalaryController = TextEditingController();
  final _maxDiscountController = TextEditingController();
  String _empType = 'hourly';
  String _payFrequency = 'weekly';
  DateTime? _startDate;

  // Banking
  final _bankNameController = TextEditingController();
  final _bankAccController = TextEditingController();
  final _bankBranchController = TextEditingController();

  // PIN
  final _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.staff != null) _populate(widget.staff!);
  }

  void _populate(Map<String, dynamic> s) {
    _nameController.text = s['full_name'] ?? '';
    _phoneController.text = s['phone'] ?? '';
    _emailController.text = s['email'] ?? '';
    _idNumberController.text = s['id_number'] ?? '';
    _role = s['role'] ?? 'cashier';
    _isActive = s['is_active'] ?? true;
    _hourlyRateController.text = s['hourly_rate']?.toString() ?? '';
    _monthlySalaryController.text = s['monthly_salary']?.toString() ?? '';
    _maxDiscountController.text = s['max_discount_pct']?.toString() ?? '0';
    _empType = s['employment_type'] ?? 'hourly';
    _payFrequency = s['payroll_frequency'] ?? 'weekly';
    _bankNameController.text = s['bank_name'] ?? '';
    _bankAccController.text = s['bank_account'] ?? '';
    _bankBranchController.text = s['bank_branch_code'] ?? '';
    if (s['start_date'] != null) {
      _startDate = DateTime.tryParse(s['start_date']);
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    final data = <String, dynamic>{
      'full_name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'id_number': _idNumberController.text.trim(),
      'role': _role,
      'is_active': _isActive,
      'employment_type': _empType,
      'hourly_rate': double.tryParse(_hourlyRateController.text),
      'monthly_salary': double.tryParse(_monthlySalaryController.text),
      'payroll_frequency': _payFrequency,
      'max_discount_pct': double.tryParse(_maxDiscountController.text) ?? 0,
      'bank_name': _bankNameController.text.trim(),
      'bank_account': _bankAccController.text.trim(),
      'bank_branch_code': _bankBranchController.text.trim(),
      'start_date': _startDate?.toIso8601String().substring(0, 10),
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Hash PIN if provided
    if (_pinController.text.isNotEmpty) {
      final bytes = utf8.encode(_pinController.text);
      data['pin_hash'] = sha256.convert(bytes).toString();
    }

    try {
      if (widget.staff == null) {
        await _supabase.from('profiles').insert(data);
        // Create leave balance record for new staff
      } else {
        await _supabase
            .from('profiles')
            .update(data)
            .eq('id', widget.staff!['id']);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 660,
        height: 600,
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
            child: Row(children: [
              const Icon(Icons.person, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                widget.staff == null ? 'Add Staff Member' : 'Edit — ${widget.staff!['full_name']}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ]),
          ),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Personal'),
              Tab(text: 'Employment & Pay'),
              Tab(text: 'Banking'),
            ],
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPersonalTab(),
                _buildEmploymentTab(),
                _buildBankingTab(),
              ],
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border))),
            child: Row(children: [
              Row(children: [
                Switch(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  activeColor: AppColors.success,
                ),
                Text(_isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                        color: _isActive ? AppColors.success : AppColors.textSecondary)),
              ]),
              const Spacer(),
              OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(widget.staff == null ? 'Add Staff' : 'Save Changes'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildPersonalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Row(children: [
          Expanded(child: _field('Full Name *', _nameController, hint: 'Sarah Mokoena')),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Role', style: _labelStyle),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(isDense: true),
                items: const [
                  DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                  DropdownMenuItem(value: 'blockman', child: Text('Blockman')),
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                  DropdownMenuItem(value: 'owner', child: Text('Owner')),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _field('Phone', _phoneController, hint: '082 555 0001')),
          const SizedBox(width: 16),
          Expanded(child: _field('Email', _emailController, hint: 'sarah@email.com')),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _field('ID Number', _idNumberController, hint: '9501015012081')),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Start Date', style: _labelStyle),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2015),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _startDate = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      _startDate != null
                          ? _startDate!.toIso8601String().substring(0, 10)
                          : 'Select date',
                      style: TextStyle(
                          fontSize: 13,
                          color: _startDate != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        _field(
          widget.staff == null ? 'PIN (4 digits) *' : 'Change PIN (leave blank to keep)',
          _pinController,
          hint: '••••',
          isPassword: true,
          maxLength: 4,
          keyboardType: TextInputType.number,
          note: 'Used for POS login and Clock-In App',
        ),
      ]),
    );
  }

  Widget _buildEmploymentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Employment Type', style: _labelStyle),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _empType,
                decoration: const InputDecoration(isDense: true),
                items: const [
                  DropdownMenuItem(value: 'hourly', child: Text('Hourly')),
                  DropdownMenuItem(value: 'weekly_salary', child: Text('Weekly Salary')),
                  DropdownMenuItem(value: 'monthly_salary', child: Text('Monthly Salary')),
                ],
                onChanged: (v) => setState(() => _empType = v!),
              ),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Payroll Frequency', style: _labelStyle),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _payFrequency,
                decoration: const InputDecoration(isDense: true),
                items: const [
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                ],
                onChanged: (v) => setState(() => _payFrequency = v!),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          if (_empType == 'hourly') ...[
            Expanded(
              child: _field('Hourly Rate (R)', _hourlyRateController,
                  hint: '45.00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  note: 'OT = 1.5x | Sunday = 2.0x (BCEA)'),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
          ] else ...[
            Expanded(
              child: _field('Monthly Salary (R)', _monthlySalaryController,
                  hint: '8000.00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
          ],
        ]),
        const SizedBox(height: 16),
        _field('Max Discount % at POS', _maxDiscountController,
            hint: '5',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            note: 'Discounts above this % require manager override'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.info.withOpacity(0.2)),
          ),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SA BCEA Compliance',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.info)),
            SizedBox(height: 6),
            Text('• Max 45 ordinary hours/week\n• Max 10 hours/day\n• OT capped at 10h/week\n• 12h minimum rest between shifts\n• Annual leave: 21 days/year (1.75 days/month accrual)',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.6)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildBankingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: const Row(children: [
            Icon(Icons.lock_outline, size: 14, color: AppColors.warning),
            SizedBox(width: 6),
            Text('Banking details are stored securely for payroll EFT payments only.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ),
        const SizedBox(height: 16),
        _field('Bank Name', _bankNameController, hint: 'e.g. FNB, ABSA, Standard Bank'),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _field('Account Number', _bankAccController, hint: '1234567890')),
          const SizedBox(width: 16),
          Expanded(child: _field('Branch Code', _bankBranchController, hint: '250655')),
        ]),
      ]),
    );
  }

  Widget _field(String label, TextEditingController controller, {
    String? hint, String? note, bool isPassword = false,
    TextInputType? keyboardType, int? maxLength,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: _labelStyle),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        maxLength: maxLength,
        decoration: InputDecoration(
          hintText: hint, isDense: true, counterText: ''),
      ),
      if (note != null) ...[
        const SizedBox(height: 4),
        Text(note, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    ]);
  }

  static const _labelStyle = TextStyle(
      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary);
}