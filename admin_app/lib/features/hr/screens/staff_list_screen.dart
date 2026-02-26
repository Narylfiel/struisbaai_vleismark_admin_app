import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/auth_service.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:admin_app/features/hr/models/awol_record.dart';
import 'package:admin_app/features/hr/models/staff_credit.dart';
import 'package:admin_app/features/hr/services/awol_repository.dart';
import 'package:admin_app/features/hr/services/staff_credit_repository.dart';
import 'package:admin_app/features/hr/services/compliance_service.dart';
import 'package:admin_app/features/hr/screens/staff_credit_screen.dart';
import 'package:admin_app/shared/widgets/form_widgets.dart';

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
    _tabController = TabController(length: 7, vsync: this);
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
                Tab(icon: Icon(Icons.warning_amber, size: 18), text: 'AWOL'),
                Tab(icon: Icon(Icons.credit_card, size: 18), text: 'Staff Credit'),
                Tab(icon: Icon(Icons.verified_user, size: 18), text: 'Compliance'),
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
                _AwolTab(),
                _StaffCreditTab(),
                _ComplianceTab(),
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
  final _supabase = SupabaseService.client;
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
      var query = _supabase.from('staff_profiles').select(
          'id, full_name, role, phone, email, employment_type, hourly_rate, '
          'monthly_salary, pay_frequency, hire_date, is_active, max_discount_pct');
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
      case 'butchery_assistant': return AppColors.textSecondary;
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
                  activeThumbColor: AppColors.primary,
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
                                (s['pay_frequency'] as String? ?? '—').toUpperCase(),
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
  final _supabase = SupabaseService.client;
  List<Map<String, dynamic>> _timecards = [];
  List<Map<String, dynamic>> _staff = [];
  bool _isLoading = true;
  String? _selectedStaffId;
  String _viewMode = 'daily'; // daily | weekly | monthly
  DateTime _selectedDate = DateTime.now();
  DateTime _weekStart = _monday(DateTime.now());

  static DateTime _monday(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

  @override
  void initState() {
    super.initState();
    _loadStaff();
    _load();
  }

  Future<void> _loadStaff() async {
    try {
      final data = await _supabase
          .from('staff_profiles')
          .select('id, full_name')
          .eq('is_active', true)
          .order('full_name');
      setState(() => _staff = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Staff: $e');
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      String rangeStart, rangeEnd;
      if (_viewMode == 'daily') {
        rangeStart = _selectedDate.toIso8601String().substring(0, 10);
        rangeEnd = rangeStart;
      } else if (_viewMode == 'weekly') {
        rangeStart = _weekStart.toIso8601String().substring(0, 10);
        rangeEnd = _weekStart
            .add(const Duration(days: 6))
            .toIso8601String()
            .substring(0, 10);
      } else {
        // monthly
        final m = DateTime(_selectedDate.year, _selectedDate.month, 1);
        rangeStart = m.toIso8601String().substring(0, 10);
        rangeEnd = DateTime(_selectedDate.year, _selectedDate.month + 1, 0)
            .toIso8601String()
            .substring(0, 10);
      }

      var q = _supabase
          .from('timecards')
          .select('*, staff_profiles!timecards_staff_id_fkey(full_name, role, hourly_rate)')
          .gte('clock_in', '${rangeStart}T00:00:00')
          .lte('clock_in', '${rangeEnd}T23:59:59');
      if (_selectedStaffId != null) q = q.eq('staff_id', _selectedStaffId!);
      final cards =
          List<Map<String, dynamic>>.from(await q.order('clock_in'));

      // Fetch all breaks in one batch
      if (cards.isNotEmpty) {
        final ids = cards.map((t) => t['id'] as String).toList();
        final breaks = List<Map<String, dynamic>>.from(
          await _supabase
              .from('timecard_breaks')
              .select('*')
              .inFilter('timecard_id', ids)
              .order('break_start'),
        );
        for (final c in cards) {
          c['breaks'] = breaks
              .where((b) => b['timecard_id'] == c['id'])
              .toList();
        }
      } else {
        for (final c in cards) {
          c['breaks'] = <Map<String, dynamic>>[];
        }
      }

      setState(() => _timecards = cards);
    } catch (e) {
      debugPrint('Timecards load: $e');
    }
    setState(() => _isLoading = false);
  }

  // Format full date + time: "06 Feb 07:28"
  String _fmtDT(String? dt) {
    if (dt == null) return '—';
    final d = DateTime.parse(dt).toLocal();
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day.toString().padLeft(2,'0')} ${months[d.month-1]} '
        '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
  }

  // Format time only: "10:15"
  String _fmtT(String? dt) {
    if (dt == null) return '—';
    final d = DateTime.parse(dt).toLocal();
    return '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
  }

  // Format date only: "06 Feb"
  String _fmtDate(String? dt) {
    if (dt == null) return '—';
    final d = DateTime.parse(dt).toLocal();
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day.toString().padLeft(2,'0')} ${months[d.month-1]}';
  }

  String _fmtBreakDur(int mins) {
    if (mins <= 0) return '—';
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  double get _totalHours => _timecards.fold(
      0, (s, t) => s + ((t['total_hours'] as num?)?.toDouble() ?? 0));
  double get _totalOT => _timecards.fold(
      0, (s, t) => s + ((t['overtime_hours'] as num?)?.toDouble() ?? 0));
  int get _totalBreakMins => _timecards.fold(0, (s, t) {
    final breaks = (t['breaks'] as List?)?.cast<Map<String,dynamic>>() ?? [];
    return s + breaks.fold<int>(0,
        (bs, b) => bs + ((b['break_duration_minutes'] as num?)?.toInt() ?? 0));
  });

  // Navigate date/week/month
  void _prev() {
    setState(() {
      if (_viewMode == 'daily') {
        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      } else if (_viewMode == 'weekly') _weekStart = _weekStart.subtract(const Duration(days: 7));
      else _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
    });
    _load();
  }

  void _next() {
    setState(() {
      if (_viewMode == 'daily') {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
      } else if (_viewMode == 'weekly') _weekStart = _weekStart.add(const Duration(days: 7));
      else _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    });
    _load();
  }

  String get _rangeLabel {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    if (_viewMode == 'daily') {
      return '${_selectedDate.day} ${months[_selectedDate.month-1]} ${_selectedDate.year}';
    } else if (_viewMode == 'weekly') {
      final end = _weekStart.add(const Duration(days: 6));
      return '${_weekStart.day} ${months[_weekStart.month-1]} — '
          '${end.day} ${months[end.month-1]} ${end.year}';
    } else {
      return '${months[_selectedDate.month-1]} ${_selectedDate.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Toolbar ─────────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        color: AppColors.cardBg,
        child: Row(children: [
          // View mode toggle
          ...['daily', 'weekly', 'monthly'].map((m) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ChoiceChip(
              label: Text(m[0].toUpperCase() + m.substring(1),
                  style: const TextStyle(fontSize: 12)),
              selected: _viewMode == m,
              onSelected: (_) { setState(() => _viewMode = m); _load(); },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                  color: _viewMode == m ? Colors.white : AppColors.textSecondary),
            ),
          )),
          const SizedBox(width: 8),
          // Date navigation
          IconButton(icon: const Icon(Icons.chevron_left, size: 20), onPressed: _prev),
          Text(_rangeLabel,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          IconButton(icon: const Icon(Icons.chevron_right, size: 20), onPressed: _next),
          const SizedBox(width: 8),
          // Staff filter
          DropdownButton<String>(
            value: _selectedStaffId,
            hint: const Text('All Staff', style: TextStyle(fontSize: 13)),
            underline: const SizedBox(),
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Staff')),
              ..._staff.map((s) => DropdownMenuItem(
                  value: s['id'] as String, child: Text(s['full_name'] as String))),
            ],
            onChanged: (v) { setState(() => _selectedStaffId = v); _load(); },
          ),
          const Spacer(),
          _sumChip('Shifts', '${_timecards.length}', AppColors.textSecondary),
          const SizedBox(width: 20),
          _sumChip('Total Hrs', '${_totalHours.toStringAsFixed(2)}h', AppColors.textPrimary),
          const SizedBox(width: 20),
          _sumChip('Total Break', _fmtBreakDur(_totalBreakMins), AppColors.info),
          const SizedBox(width: 20),
          _sumChip('Overtime', '${_totalOT.toStringAsFixed(2)}h',
              _totalOT > 0 ? AppColors.warning : AppColors.textSecondary),
        ]),
      ),
      const Divider(height: 1, color: AppColors.border),

      // ── Column header row — FIXED COLUMNS per blueprint ─────────
      // DATE | STAFF | CLOCK IN | BRK1 OUT | BRK1 IN | BRK2 OUT | BRK2 IN | BRK3 OUT | BRK3 IN | CLOCK OUT | TOTAL BRK | REG HRS | OT HRS
      Container(
        color: AppColors.surfaceBg,
        child: const SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              SizedBox(width: 70,  child: Text('DATE',      style: _hS)),
              SizedBox(width: 8),
              SizedBox(width: 110, child: Text('STAFF',     style: _hS)),
              SizedBox(width: 8),
              SizedBox(width: 72,  child: Text('CLOCK IN',  style: _hS)),
              SizedBox(width: 8),
              SizedBox(width: 56,  child: Text('BRK 1\nOUT', style: _hS)),
              SizedBox(width: 4),
              SizedBox(width: 56,  child: Text('BRK 1\nIN',  style: _hS)),
              SizedBox(width: 8),
              SizedBox(width: 56,  child: Text('BRK 2\nOUT', style: _hS)),
              SizedBox(width: 4),
              SizedBox(width: 56,  child: Text('BRK 2\nIN',  style: _hS)),
              SizedBox(width: 8),
              SizedBox(width: 56,  child: Text('BRK 3\nOUT', style: _hS)),
              SizedBox(width: 4),
              SizedBox(width: 56,  child: Text('BRK 3\nIN',  style: _hS)),
              SizedBox(width: 8),
              SizedBox(width: 72,  child: Text('CLOCK OUT', style: _hS)),
              SizedBox(width: 8),
              SizedBox(width: 68,  child: Text('TOTAL BRK', style: _hS)),
              SizedBox(width: 8),
              SizedBox(width: 60,  child: Text('REG HRS',   style: _hS)),
              SizedBox(width: 8),
              SizedBox(width: 60,  child: Text('OT HRS',    style: _hS)),
              SizedBox(width: 8),
              SizedBox(width: 80,  child: Text('STATUS',    style: _hS)),
            ]),
          ),
        ),
      ),
      const Divider(height: 1, color: AppColors.border),

      // ── Data rows ───────────────────────────────────────────────
      Expanded(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _timecards.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.access_time, size: 48, color: AppColors.border),
                      const SizedBox(height: 12),
                      Text('No timecards for $_rangeLabel',
                          style: const TextStyle(color: AppColors.textSecondary)),
                    ]),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: _timecards.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (_, i) {
                      final t = _timecards[i];
                      final breaks = (t['breaks'] as List?)
                              ?.cast<Map<String, dynamic>>() ??
                          [];

                      // Up to 3 breaks
                      final b1 = breaks.isNotEmpty ? breaks[0] : null;
                      final b2 = breaks.length > 1 ? breaks[1] : null;
                      final b3 = breaks.length > 2 ? breaks[2] : null;

                      final totalBreakMins = breaks.fold<int>(
                          0,
                          (s, b) =>
                              s +
                              ((b['break_duration_minutes'] as num?)
                                      ?.toInt() ??
                                  0));

                      final regHrs =
                          (t['regular_hours'] as num?)?.toDouble() ?? 0;
                      final otHrs =
                          (t['overtime_hours'] as num?)?.toDouble() ?? 0;
                      final isOpen = t['clock_out'] == null;
                      final needsApproval =
                          t['requires_approval'] as bool? ?? false;
                      final otApproved =
                          t['overtime_approved'] as bool? ?? false;

                      // BCEA violation: any single break > 60 min
                      final longBreak = breaks.any((b) =>
                          ((b['break_duration_minutes'] as num?)?.toInt() ??
                              0) >
                          60);

                      final rowColor = longBreak
                          ? AppColors.error.withOpacity(0.04)
                          : (otHrs > 0 && !otApproved)
                              ? AppColors.warning.withOpacity(0.04)
                              : Colors.transparent;

                      return Container(
                        color: rowColor,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 9),
                            child: Row(children: [
                              // DATE
                              SizedBox(
                                width: 70,
                                child: Text(_fmtDate(t['clock_in']),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                              ),
                              const SizedBox(width: 8),
                              // STAFF
                              SizedBox(
                                width: 110,
                                child: Text(
                                  t['staff_profiles']?['full_name'] ?? '—',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // CLOCK IN
                              SizedBox(
                                width: 72,
                                child: Text(_fmtT(t['clock_in']),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textPrimary)),
                              ),
                              const SizedBox(width: 8),
                              // BRK 1 OUT
                              _breakCell(b1?['break_start'], 56),
                              const SizedBox(width: 4),
                              // BRK 1 IN
                              _breakCell(b1?['break_end'], 56,
                                  isOnBreak: b1 != null && b1['break_end'] == null),
                              const SizedBox(width: 8),
                              // BRK 2 OUT
                              _breakCell(b2?['break_start'], 56),
                              const SizedBox(width: 4),
                              // BRK 2 IN
                              _breakCell(b2?['break_end'], 56,
                                  isOnBreak: b2 != null && b2['break_end'] == null),
                              const SizedBox(width: 8),
                              // BRK 3 OUT
                              _breakCell(b3?['break_start'], 56),
                              const SizedBox(width: 4),
                              // BRK 3 IN
                              _breakCell(b3?['break_end'], 56,
                                  isOnBreak: b3 != null && b3['break_end'] == null),
                              const SizedBox(width: 8),
                              // CLOCK OUT
                              SizedBox(
                                width: 72,
                                child: Text(
                                  isOpen ? '● Active' : _fmtT(t['clock_out']),
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: isOpen
                                          ? AppColors.success
                                          : AppColors.textPrimary,
                                      fontWeight: isOpen
                                          ? FontWeight.bold
                                          : FontWeight.normal),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // TOTAL BREAK
                              SizedBox(
                                width: 68,
                                child: Text(
                                  _fmtBreakDur(totalBreakMins),
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: longBreak
                                          ? AppColors.error
                                          : totalBreakMins > 0
                                              ? AppColors.info
                                              : AppColors.textSecondary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // REG HRS
                              SizedBox(
                                width: 60,
                                child: Text(
                                  regHrs > 0
                                      ? regHrs.toStringAsFixed(2)
                                      : '—',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // OT HRS
                              SizedBox(
                                width: 60,
                                child: Text(
                                  otHrs > 0
                                      ? otHrs.toStringAsFixed(2)
                                      : '—',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: otHrs > 0
                                          ? AppColors.warning
                                          : AppColors.textSecondary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // STATUS
                              SizedBox(
                                width: 80,
                                child: isOpen
                                    ? _badge('CLOCKED IN', AppColors.success)
                                    : needsApproval && !otApproved
                                        ? _badge('OT PENDING', AppColors.warning)
                                        : longBreak
                                            ? _badge('LONG BREAK', AppColors.error)
                                            : _badge('COMPLETE', AppColors.info),
                              ),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    ]);
  }

  /// A single break time cell — shows time or '---' if no data
  Widget _breakCell(String? dt, double width, {bool isOnBreak = false}) {
    return SizedBox(
      width: width,
      child: Text(
        isOnBreak ? '●' : _fmtT(dt),
        style: TextStyle(
          fontSize: 12,
          color: isOnBreak
              ? AppColors.warning
              : dt != null
                  ? AppColors.textPrimary
                  : AppColors.border,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _sumChip(String label, String value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      Text(value,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: color),
          textAlign: TextAlign.center),
    );
  }

  static const _hS = TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.bold,
      color: AppColors.textSecondary,
      letterSpacing: 0.4,
      height: 1.3);
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
  final _supabase = SupabaseService.client;
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
      // DB stores status lowercase: 'pending', 'approved', 'rejected'
      final requests = await _supabase
          .from('leave_requests')
          .select('*, staff_profiles!staff_id(full_name, role)')
          .eq('status', _filter.toLowerCase())
          .order('created_at', ascending: false);
      final balances = await _supabase
          .from('leave_balances')
          .select('*, staff_profiles!staff_id(full_name)')
          .order('staff_id');
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
    // DB CHECK expects lowercase: 'pending', 'approved', 'rejected'
    final statusLower = status.toLowerCase();
    await _supabase.from('leave_requests').update({
      'status': statusLower,
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
                          final isPending = r['status'] == 'pending';
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
                                  r['staff_profiles']?['full_name'] ?? '—',
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
                    Text(b['staff_profiles']?['full_name'] ?? '—',
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
  final _supabase = SupabaseService.client;
  final List<Map<String, dynamic>> _periods = [];
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
      // payroll_entries has staff_id, pay_period_start, pay_period_end, etc. (no period_id)
      // Load payroll from staff + timecards for current month
      await _loadCurrentPayroll();
    } catch (e) {
      debugPrint('Payroll: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadCurrentPayroll() async {
    // Get current month's data
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    try {
      final staff = await _supabase
          .from('staff_profiles')
          .select('id, full_name, role, employment_type, hourly_rate, monthly_salary, pay_frequency')
          .eq('is_active', true)
          .order('full_name');

      final timecards = await _supabase
          .from('timecards')
          .select('staff_id, total_hours, regular_hours, overtime_hours, sunday_hours')
          .gte('clock_in', monthStart.toIso8601String())
          .not('clock_out', 'is', null);

      // Build payroll summary per staff
      final summary = <Map<String, dynamic>>[];
      for (final s in List<Map<String, dynamic>>.from(staff)) {
        final empTimecards = List<Map<String, dynamic>>.from(timecards)
            .where((t) => t['staff_id'] == s['id'])
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
                              (e['pay_frequency'] as String? ?? '—').toUpperCase(),
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
// TAB 5: AWOL / Absconding (Blueprint §7.3a)
// ══════════════════════════════════════════════════════════════════

class _AwolTab extends StatefulWidget {
  const _AwolTab();
  @override
  State<_AwolTab> createState() => _AwolTabState();
}

class _AwolTabState extends State<_AwolTab> {
  final _repo = AwolRepository();
  List<AwolRecord> _records = [];
  List<Map<String, dynamic>> _staff = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    try {
      final data = await SupabaseService.client
          .from('staff_profiles')
          .select('id, full_name')
          .eq('is_active', true)
          .order('full_name');
      if (mounted) setState(() => _staff = List<Map<String, dynamic>>.from(data));
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.getRecords();
      if (mounted) setState(() => _records = list);
    } catch (e) {
      debugPrint('AWOL load: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _openRecordAwol() async {
    // C8: Use AuthService (PIN login), not Supabase Auth — Owner logged in via PIN has currentStaffId set
    final userId = AuthService().currentStaffId;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in with PIN to record AWOL'), backgroundColor: AppColors.warning),
      );
      return;
    }
    String? staffId;
    DateTime awolDate = DateTime.now();
    TimeOfDay? expectedStart = const TimeOfDay(hour: 7, minute: 0);
    bool notified = false;
    final notifiedWhoController = TextEditingController();
    final notesController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Record AWOL'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FormWidgets.dropdownFormField<String>(
                  label: 'Staff',
                  value: staffId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('— Select staff —')),
                    ..._staff.map((s) => DropdownMenuItem(value: s['id'] as String, child: Text(s['full_name'] ?? ''))),
                  ],
                  onChanged: (v) { setDialog(() => staffId = v); },
                ),
                const SizedBox(height: 12),
                FormWidgets.textFormField(
                  label: 'AWOL date',
                  controller: TextEditingController(text: '${awolDate.day}/${awolDate.month}/${awolDate.year}'),
                  enabled: false,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(context: ctx, initialDate: awolDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (d != null) setDialog(() => awolDate = d);
                  },
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('Set date'),
                ),
                const SizedBox(height: 12),
                FormWidgets.textFormField(
                  label: 'Notes',
                  controller: notesController,
                  maxLines: 2,
                ),
                SwitchListTile(
                  title: const Text('Notified owner/manager'),
                  value: notified,
                  onChanged: (v) => setDialog(() => notified = v),
                ),
                if (notified)
                  FormWidgets.textFormField(
                    label: 'Who was notified',
                    controller: notifiedWhoController,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: staffId == null ? null : () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result != true || staffId == null) return;
    try {
      await _repo.create(
        staffId: staffId!,
        awolDate: awolDate,
        expectedStartTime: expectedStart != null ? DateTime(2000, 1, 1, expectedStart.hour, expectedStart.minute) : null,
        notifiedOwnerManager: notified,
        notifiedWho: notifiedWhoController.text.trim().isEmpty ? null : notifiedWhoController.text.trim(),
        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
        recordedBy: userId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AWOL recorded'), backgroundColor: AppColors.success),
        );
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.cardBg,
          child: Row(
            children: [
              const Text('AWOL / Absconding records', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _openRecordAwol,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Record AWOL'),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          color: AppColors.surfaceBg,
          child: Row(children: [
            Expanded(flex: 2, child: Text('STAFF', style: _awolH)),
            SizedBox(width: 100, child: Text('DATE', style: _awolH)),
            SizedBox(width: 100, child: Text('RESOLUTION', style: _awolH)),
            SizedBox(width: 80, child: Text('NOTIFIED', style: _awolH)),
            Expanded(child: Text('NOTES', style: _awolH)),
          ]),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _records.isEmpty
                  ? const Center(child: Text('No AWOL records'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _records.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (_, i) {
                        final r = _records[i];
                        final dateStr = '${r.awolDate.day}/${r.awolDate.month}/${r.awolDate.year}';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text(r.staffName ?? r.staffId, style: const TextStyle(fontWeight: FontWeight.w600))),
                              SizedBox(width: 100, child: Text(dateStr)),
                              SizedBox(width: 100, child: Text(r.resolution.dbValue)),
                              SizedBox(width: 80, child: Text(r.notifiedOwnerManager ? 'Yes' : 'No')),
                              Expanded(child: Text(r.notes ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

const _awolH = TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5);
const _creditH = TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5);

// ══════════════════════════════════════════════════════════════════
// TAB 6: Staff Credit (Blueprint §7.5)
// ══════════════════════════════════════════════════════════════════

class _StaffCreditTab extends StatelessWidget {
  const _StaffCreditTab();

  @override
  Widget build(BuildContext context) {
    return const StaffCreditScreen(isEmbedded: true);
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 7: BCEA Compliance (Blueprint §7.6)
// ══════════════════════════════════════════════════════════════════

class _ComplianceTab extends StatefulWidget {
  const _ComplianceTab();
  @override
  State<_ComplianceTab> createState() => _ComplianceTabState();
}

class _ComplianceTabState extends State<_ComplianceTab> {
  final _service = ComplianceService();
  List<ComplianceItem> _items = [];
  bool _loading = true;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _service.getBceaCompliance(_month);
      if (mounted) setState(() => _items = list);
    } catch (e) {
      debugPrint('Compliance load: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Color _statusColor(ComplianceStatus s) {
    switch (s) {
      case ComplianceStatus.ok:
        return AppColors.success;
      case ComplianceStatus.warning:
        return AppColors.warning;
      case ComplianceStatus.error:
        return AppColors.error;
      case ComplianceStatus.info:
        return AppColors.info;
    }
  }

  IconData _statusIcon(ComplianceStatus s) {
    switch (s) {
      case ComplianceStatus.ok:
        return Icons.check_circle;
      case ComplianceStatus.warning:
        return Icons.warning_amber;
      case ComplianceStatus.error:
        return Icons.error;
      case ComplianceStatus.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.cardBg,
          child: Row(
            children: [
              const Text('BCEA Compliance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _month,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) {
                    setState(() => _month = DateTime(d.year, d.month, 1));
                    _load();
                  }
                },
                icon: const Icon(Icons.calendar_month, size: 18),
                label: Text('${_month.year}-${_month.month.toString().padLeft(2, '0')}'),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Compliance status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      ..._items.map((item) => Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Icon(_statusIcon(item.status), color: _statusColor(item.status), size: 28),
                              title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(item.detail, style: const TextStyle(fontSize: 13)),
                            ),
                          )),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
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
  final _supabase = SupabaseService.client;
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
    _payFrequency = s['pay_frequency'] ?? 'weekly';
    _bankNameController.text = s['bank_name'] ?? '';
    _bankAccController.text = s['bank_account'] ?? '';
    _bankBranchController.text = s['bank_branch_code'] ?? '';
    if (s['hire_date'] != null) {
      _startDate = DateTime.tryParse(s['hire_date']);
    }
  }

  Future<void> _confirmDeactivateStaff(Map<String, dynamic> staff) async {
    final name = staff['full_name'] as String? ?? 'this staff member';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete staff?'),
        content: Text(
          'Delete $name? This cannot be undone. This will prevent staff from logging in.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _isSaving = true);
    try {
      await _supabase
          .from('staff_profiles')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', staff['id']);
      widget.onSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
      'pay_frequency': _payFrequency,
      'max_discount_pct': double.tryParse(_maxDiscountController.text) ?? 0,
      'bank_name': _bankNameController.text.trim(),
      'bank_account': _bankAccController.text.trim(),
      'bank_branch_code': _bankBranchController.text.trim(),
      'hire_date': _startDate?.toIso8601String().substring(0, 10),
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Hash PIN if provided
    if (_pinController.text.isNotEmpty) {
      final bytes = utf8.encode(_pinController.text);
      data['pin_hash'] = sha256.convert(bytes).toString();
    }

    try {
      if (widget.staff == null) {
        await _supabase.from('staff_profiles').insert(data);
        // Create leave balance record for new staff
      } else {
        await _supabase
            .from('staff_profiles')
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
              if (widget.staff != null && AuthService().currentRole == 'owner')
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                  onPressed: _isSaving ? null : () => _confirmDeactivateStaff(widget.staff!),
                  tooltip: 'Deactivate staff',
                ),
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
                  activeThumbColor: AppColors.success,
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
                initialValue: _role,
                decoration: const InputDecoration(isDense: true),
                items: const [
                  DropdownMenuItem(value: 'owner', child: Text('Owner')),
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                  DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                  DropdownMenuItem(value: 'blockman', child: Text('Blockman')),
                  DropdownMenuItem(value: 'butchery_assistant', child: Text('Butchery Assistant')),
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
                initialValue: _empType,
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
                initialValue: _payFrequency,
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