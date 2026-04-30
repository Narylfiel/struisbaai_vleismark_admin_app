import 'dart:async';
import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/core/services/auth_service.dart';
import 'package:admin_app/core/services/connectivity_service.dart';
import 'package:admin_app/core/db/isar_service.dart';
import 'package:admin_app/core/db/cached_staff_profile.dart';
import 'package:admin_app/core/db/cached_timecard.dart';
import 'package:admin_app/core/db/cached_leave_request.dart';
import 'package:admin_app/core/db/cached_awol_record.dart';
import 'package:admin_app/core/db/cached_compliance_record.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/audit_service.dart';
import 'package:admin_app/core/services/permission_service.dart';
import 'package:admin_app/core/constants/permissions.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:admin_app/features/hr/models/awol_record.dart';
import 'package:admin_app/features/hr/services/awol_repository.dart';
import 'package:admin_app/features/hr/services/compliance_service.dart';
import 'package:admin_app/features/hr/services/staff_profile_repository.dart';
import 'package:admin_app/features/hr/services/timecard_repository.dart';
import 'package:admin_app/features/hr/screens/staff_credit_screen.dart';
import 'package:admin_app/features/hr/screens/payroll_screen.dart';
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
    _tabController = TabController(length: 8, vsync: this);
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
                Tab(icon: Icon(Icons.notifications_active, size: 18), text: 'Break Alerts'),
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
                PayrollScreen(isEmbedded: true),
                _AwolTab(),
                _StaffCreditTab(),
                _ComplianceTab(),
                _BreakAlertsTab(),
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
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      // DATABASE-FIRST: Fetch from Supabase FIRST (always fresh data)
      try {
        _isOffline = false;
        final data = await StaffProfileRepository(client: _supabase)
            .getAll(isActive: _showInactive ? null : true);
        setState(() => _staff = List<Map<String, dynamic>>.from(data));
        
        // Update cache in background (non-blocking)
        final staffProfiles = (data as List).map((item) {
          final m = Map<String, dynamic>.from(item as Map);
          return CachedStaffProfile.fromSupabase(m);
        }).toList();
        IsarService.saveStaffProfiles(staffProfiles);
      } catch (e) {
        // Fallback to cache if database fails (safety net)
        _isOffline = true;
        final cached = await IsarService.getAllStaffProfiles();
        var list = cached.map((c) {
          final m = c.toAuthMap();
          m['phone'] = null;
          m['email'] = null;
          m['employment_type'] = 'hourly';
          m['hourly_rate'] = 0;
          m['monthly_salary'] = 0;
          m['pay_frequency'] = null;
          m['hire_date'] = null;
          m['max_discount_pct'] = null;
          return m;
        }).toList();
        if (!_showInactive) list = list.where((m) => m['is_active'] == true).toList();
        setState(() => _staff = list);
      }
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
                                  backgroundColor: _roleColor(s['role']).withValues(alpha: 0.15),
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
                                  color: _roleColor(s['role']).withValues(alpha: 0.1),
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
                                      ? AppColors.success.withValues(alpha: 0.1)
                                      : AppColors.error.withValues(alpha: 0.1),
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
        Text(
          _isOffline ? 'No cached data available. Connect to the internet to load data.' : 'No staff members yet',
          style: const TextStyle(fontSize: 18, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _isOffline ? null : () => _openStaff(null),
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
  bool _isOffline = false;
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
      // DATABASE-FIRST: Fetch from Supabase FIRST
      try {
        final data = await StaffProfileRepository(client: _supabase)
            .getAll(isActive: true);
        setState(() => _staff = List<Map<String, dynamic>>.from(data));
      } catch (e) {
        // Fallback to cache if database fails
        final cached = await IsarService.getAllStaffProfiles();
        setState(() => _staff = cached.map((c) => {'id': c.staffId, 'full_name': c.fullName}).toList());
      }
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
        final m = DateTime(_selectedDate.year, _selectedDate.month, 1);
        rangeStart = m.toIso8601String().substring(0, 10);
        rangeEnd = DateTime(_selectedDate.year, _selectedDate.month + 1, 0)
            .toIso8601String()
            .substring(0, 10);
      }

      // DATABASE-FIRST: Fetch from Supabase FIRST
      try {
        _isOffline = false;
        final timeRepo = TimecardRepository(client: _supabase);
        final periodStart = DateTime.parse(rangeStart);
        final periodEnd = DateTime.parse(rangeEnd);
        final rawCards = await timeRepo.getAll(
          staffId: _selectedStaffId,
          from: periodStart,
          to: periodEnd,
        );

        final rangeStartDt = DateTime.parse('${rangeStart}T00:00:00');
        final rangeEndDt = DateTime.parse('${rangeEnd}T23:59:59');

        final cards = rawCards
            .where((c) {
              final ci = c['clock_in'];
              final clockIn = ci != null ? DateTime.tryParse(ci.toString()) : null;
              if (clockIn == null) return false;
              return !clockIn.isBefore(rangeStartDt) &&
                  !clockIn.isAfter(rangeEndDt);
            })
            .map((c) {
              final staffProfiles = c['staff_profiles'];
              if (staffProfiles is Map) {
                return {
                  ...c,
                  'staff_profiles': {
                    ...Map<String, dynamic>.from(staffProfiles),
                    'hourly_rate': (staffProfiles)['hourly_rate'],
                  },
                };
              }
              return c;
            })
            .toList()
          ..sort((a, b) {
            final ai = DateTime.tryParse(a['clock_in']?.toString() ?? '');
            final bi = DateTime.tryParse(b['clock_in']?.toString() ?? '');
            final aDt = ai ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDt = bi ?? DateTime.fromMillisecondsSinceEpoch(0);
            return aDt.compareTo(bDt);
          });

        setState(() => _timecards = cards);
        
        // Update cache in background
        final cachedTimecards = cards.map((item) {
          return CachedTimecard.fromSupabase(item);
        }).toList();
        unawaited(IsarService.saveTimecards(cachedTimecards));
      } catch (e, stackTrace) {
        // Fallback to cache if database fails
        debugPrint('TIMECARDS DB ERROR: $e');
        debugPrint('STACK: $stackTrace');
        _isOffline = true;
        final cached = await IsarService.getAllTimecards();
        final rangeStartDt = DateTime.parse('${rangeStart}T00:00:00');
        final rangeEndDt = DateTime.parse('${rangeEnd}T23:59:59');
        var cards = cached
            .where((c) =>
                c.clockIn != null &&
                !c.clockIn!.isBefore(rangeStartDt) &&
                !c.clockIn!.isAfter(rangeEndDt) &&
                (_selectedStaffId == null || c.staffId == _selectedStaffId))
            .map((c) {
          final m = c.toMap();
          m['staff_profiles'] = {'full_name': c.staffName, 'role': null, 'hourly_rate': null};
          m['breaks'] = <Map<String, dynamic>>[];
          m['total_hours'] = c.totalHours;
          m['overtime_hours'] = 0;
          m['regular_hours'] = c.totalHours;
          m['sunday_hours'] = 0;
          return m;
        }).toList();
        cards.sort((a, b) => (a['clock_in'] as String? ?? '').compareTo(b['clock_in'] as String? ?? ''));
        setState(() => _timecards = cards);
      }
    } catch (e) {
      debugPrint('Timecards load: $e');
    }
    setState(() => _isLoading = false);
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
    final breaks = (t['timecard_breaks'] as List?)?.cast<Map<String,dynamic>>() ?? [];
    return s + breaks.fold<int>(0,
        (bs, b) => bs + ((b['break_duration_minutes'] as num?)?.toInt() ?? 0));
  });

  // Navigate date/week/month
  void _prev() {
    setState(() {
      if (_viewMode == 'daily') {
        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      } else if (_viewMode == 'weekly') {
        _weekStart = _weekStart.subtract(const Duration(days: 7));
      } else {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
      }
    });
    _load();
  }

  void _next() {
    setState(() {
      if (_viewMode == 'daily') {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
      } else if (_viewMode == 'weekly') {
        _weekStart = _weekStart.add(const Duration(days: 7));
      } else {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
      }
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
                      Text(
                        _isOffline ? 'No cached data available. Connect to the internet to load data.' : 'No timecards for $_rangeLabel',
                        style: const TextStyle(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ]),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: _timecards.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (_, i) {
                      final t = _timecards[i];
                      // Read from timecard_breaks (source of truth)
                      // Legacy columns are not written by clock-in app
                      final breaks = (t['timecard_breaks'] as List?)
                              ?.cast<Map<String, dynamic>>()
                              .toList() ??
                          [];
                      final b1Start = breaks.isNotEmpty
                          ? breaks[0]['break_start'] as String?
                          : null;
                      final b1End = breaks.isNotEmpty
                          ? breaks[0]['break_end'] as String?
                          : null;
                      final b2Start = breaks.length > 1
                          ? breaks[1]['break_start'] as String?
                          : null;
                      final b2End = breaks.length > 1
                          ? breaks[1]['break_end'] as String?
                          : null;
                      final b3Start = breaks.length > 2
                          ? breaks[2]['break_start'] as String?
                          : null;
                      final b3End = breaks.length > 2
                          ? breaks[2]['break_end'] as String?
                          : null;

                      final totalBreakMins = (t['break_minutes'] as num?)?.toInt() ?? 0;

                      final regHrs =
                          (t['regular_hours'] as num?)?.toDouble() ?? 0;
                      final otHrs =
                          (t['overtime_hours'] as num?)?.toDouble() ?? 0;
                      final isOpen = t['clock_out'] == null;
                      // BCEA violation: any single break > 60 min (check break_detail JSON if needed)
                      // For now, use total break time as proxy
                      final longBreak = totalBreakMins > 60;

                      final rowColor = longBreak
                          ? AppColors.error.withValues(alpha: 0.04)
                          : (otHrs > 0 && !(t['overtime_approved'] as bool? ?? false))
                              ? AppColors.warning.withValues(alpha: 0.04)
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
                              _breakCell(b1Start, 56),
                              const SizedBox(width: 4),
                              // BRK 1 IN
                              _breakCell(b1End, 56,
                                  isOnBreak: b1Start != null && b1End == null),
                              const SizedBox(width: 8),
                              // BRK 2 OUT
                              _breakCell(b2Start, 56),
                              const SizedBox(width: 4),
                              // BRK 2 IN
                              _breakCell(b2End, 56,
                                  isOnBreak: b2Start != null && b2End == null),
                              const SizedBox(width: 8),
                              // BRK 3 OUT
                              _breakCell(b3Start, 56),
                              const SizedBox(width: 4),
                              // BRK 3 IN
                              _breakCell(b3End, 56,
                                  isOnBreak: b3Start != null && b3End == null),
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
                                    : (t['requires_approval'] as bool? ?? false) &&
                                            !(t['overtime_approved'] as bool? ?? false)
                                        ? _badge('OT PENDING', AppColors.warning)
                                        : longBreak
                                            ? _badge('LONG BREAK', AppColors.error)
                                            : _badge('COMPLETE', AppColors.info),
                              ),
                              // EDIT BUTTON — managers and owners only
                              if (PermissionService().can(Permissions.manageHr)) ...[
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 32,
                                  child: IconButton(
                                    icon: const Icon(Icons.edit, size: 16),
                                    color: AppColors.textSecondary,
                                    tooltip: 'Edit timecard',
                                    padding: EdgeInsets.zero,
                                    onPressed: () => _openEditTimecard(t),
                                  ),
                                ),
                              ],
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
          color: color.withValues(alpha: 0.1),
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

  Future<void> _openEditTimecard(Map<String, dynamic> t) async {
    final staffName = t['staff_profiles']?['full_name'] ?? 'Staff';
    final timecardId = t['id'] as String;

    // Pre-fill controllers with existing values (HH:mm format)
    String formatTime(String? iso) {
      if (iso == null) return '';
      final d = DateTime.parse(iso).toLocal();
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }

    final clockInCtrl    = TextEditingController(text: formatTime(t['clock_in']));
    final clockOutCtrl   = TextEditingController(text: formatTime(t['clock_out']));
    final b1StartCtrl    = TextEditingController(text: formatTime(t['break_1_start']));
    final b1EndCtrl      = TextEditingController(text: formatTime(t['break_1_end']));
    final b2StartCtrl    = TextEditingController(text: formatTime(t['break_2_start']));
    final b2EndCtrl      = TextEditingController(text: formatTime(t['break_2_end']));
    final b3StartCtrl    = TextEditingController(text: formatTime(t['break_3_start']));
    final b3EndCtrl      = TextEditingController(text: formatTime(t['break_3_end']));
    final reasonCtrl     = TextEditingController();

    bool isSaving = false;
    String? errorMsg;

    // Helper: parse HH:mm on the timecard's shift_date into a timestamptz string
    // shiftDate is already a String like '2026-04-11'
    String? parseToIso(String hhmm, String shiftDate) {
      if (hhmm.trim().isEmpty) return null;
      final parts = hhmm.trim().split(':');
      if (parts.length != 2) return null;
      return '${shiftDate}T${parts[0].padLeft(2,'0')}:${parts[1].padLeft(2,'0')}:00+02:00';
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.edit_calendar, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Edit Timecard — $staffName',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (errorMsg != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(errorMsg!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Shift date (read-only label)
                  Text(
                    'Shift: ${t['shift_date'] ?? ''}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  // Clock in / out row
                  Row(children: [
                    Expanded(
                      child: FormWidgets.textFormField(
                        label: 'Clock In (HH:MM)',
                        controller: clockInCtrl,
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FormWidgets.textFormField(
                        label: 'Clock Out (HH:MM)',
                        controller: clockOutCtrl,
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Breaks',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  // Break 1
                  Row(children: [
                    Expanded(
                      child: FormWidgets.textFormField(
                        label: 'Break 1 Out',
                        controller: b1StartCtrl,
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FormWidgets.textFormField(
                        label: 'Break 1 In',
                        controller: b1EndCtrl,
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  // Break 2
                  Row(children: [
                    Expanded(
                      child: FormWidgets.textFormField(
                        label: 'Break 2 Out',
                        controller: b2StartCtrl,
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FormWidgets.textFormField(
                        label: 'Break 2 In',
                        controller: b2EndCtrl,
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  // Break 3
                  Row(children: [
                    Expanded(
                      child: FormWidgets.textFormField(
                        label: 'Break 3 Out',
                        controller: b3StartCtrl,
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FormWidgets.textFormField(
                        label: 'Break 3 In',
                        controller: b3EndCtrl,
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  // Reason — required
                  FormWidgets.textFormField(
                    label: 'Reason for edit (required)',
                    controller: reasonCtrl,
                    keyboardType: TextInputType.text,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      // Validate reason
                      if (reasonCtrl.text.trim().isEmpty) {
                        setDialogState(
                            () => errorMsg = 'Please enter a reason for this edit.');
                        return;
                      }

                      final shiftDate = t['shift_date'] as String? ?? '';

                      // Build update payload — only include non-empty fields
                      final newData = <String, dynamic>{
                        if (clockInCtrl.text.trim().isNotEmpty)
                          'clock_in': parseToIso(clockInCtrl.text, shiftDate),
                        if (clockOutCtrl.text.trim().isNotEmpty)
                          'clock_out': parseToIso(clockOutCtrl.text, shiftDate),
                        'break_1_start': b1StartCtrl.text.trim().isEmpty
                            ? null
                            : parseToIso(b1StartCtrl.text, shiftDate),
                        'break_1_end': b1EndCtrl.text.trim().isEmpty
                            ? null
                            : parseToIso(b1EndCtrl.text, shiftDate),
                        'break_2_start': b2StartCtrl.text.trim().isEmpty
                            ? null
                            : parseToIso(b2StartCtrl.text, shiftDate),
                        'break_2_end': b2EndCtrl.text.trim().isEmpty
                            ? null
                            : parseToIso(b2EndCtrl.text, shiftDate),
                        'break_3_start': b3StartCtrl.text.trim().isEmpty
                            ? null
                            : parseToIso(b3StartCtrl.text, shiftDate),
                        'break_3_end': b3EndCtrl.text.trim().isEmpty
                            ? null
                            : parseToIso(b3EndCtrl.text, shiftDate),
                        // Recalculate break_minutes from filled breaks
                        'break_minutes': _calcBreakMinutes(
                          b1StartCtrl.text, b1EndCtrl.text,
                          b2StartCtrl.text, b2EndCtrl.text,
                          b3StartCtrl.text, b3EndCtrl.text,
                          shiftDate,
                        ),
                        // Audit trail
                        'edited_by': SupabaseService.client.auth.currentUser?.id,
                        'edited_at': DateTime.now().toIso8601String(),
                        'edit_reason': reasonCtrl.text.trim(),
                      };

                      setDialogState(() => isSaving = true);
                      try {
                        final timeRepo = TimecardRepository(client: SupabaseService.client);
                        await timeRepo.update(timecardId, newData);

                        // Write to audit log
                        await AuditService.log(
                          action: 'UPDATE',
                          module: 'HR',
                          description:
                              'Timecard corrected for $staffName on $shiftDate. Reason: ${reasonCtrl.text.trim()}',
                          entityType: 'Timecard',
                          entityId: timecardId,
                          oldValues: {
                            'clock_in': t['clock_in'],
                            'clock_out': t['clock_out'],
                            'break_1_start': t['break_1_start'],
                            'break_1_end': t['break_1_end'],
                            'break_2_start': t['break_2_start'],
                            'break_2_end': t['break_2_end'],
                            'break_3_start': t['break_3_start'],
                            'break_3_end': t['break_3_end'],
                          },
                          newValues: newData,
                        );

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          _load(); // refresh the list
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Timecard updated successfully'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          isSaving = false;
                          errorMsg = 'Save failed: ${e.toString()}';
                        });
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );

    // Dispose controllers
    for (final c in [
      clockInCtrl, clockOutCtrl,
      b1StartCtrl, b1EndCtrl,
      b2StartCtrl, b2EndCtrl,
      b3StartCtrl, b3EndCtrl,
      reasonCtrl,
    ]) {
      c.dispose();
    }
  }

  /// Calculates total break minutes from HH:MM string pairs
  int _calcBreakMinutes(
    String b1s, String b1e,
    String b2s, String b2e,
    String b3s, String b3e,
    String shiftDate,
  ) {
    int mins = 0;
    for (final pair in [
      [b1s, b1e],
      [b2s, b2e],
      [b3s, b3e],
    ]) {
      final s = pair[0].trim();
      final e = pair[1].trim();
      if (s.isEmpty || e.isEmpty) continue;
      try {
        final sp = s.split(':');
        final ep = e.split(':');
        final start = DateTime(2000, 1, 1,
            int.parse(sp[0]), int.parse(sp[1]));
        final end = DateTime(2000, 1, 1,
            int.parse(ep[0]), int.parse(ep[1]));
        final diff = end.difference(start).inMinutes;
        if (diff > 0) mins += diff;
      } catch (_) {}
    }
    return mins;
  }
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
  
  // Combined leave records (history + pending/rejected requests)
  List<Map<String, dynamic>> _allLeaveRecords = [];
  bool _isLoading = true;
  bool _isOffline = false;
  
  // Filters
  String _statusFilter = 'All'; // All, Pending, Approved, Rejected, Admin entries
  String? _selectedStaffFilter; // null = all staff
  String? _selectedTypeFilter; // null = all types
  
  // Staff list for filters and record leave
  List<Map<String, dynamic>> _allStaff = [];
  
  // Record leave card state
  String? _recordLeaveStaffId;
  Map<String, dynamic>? _selectedStaffBalance;
  bool _loadingBalance = false;

  @override
  void initState() {
    super.initState();
    _loadAllStaff();
    _loadAllLeaveRecords();
  }

  Future<void> _loadAllStaff() async {
    try {
      // DATABASE-FIRST: Fetch from Supabase FIRST
      try {
        final staff = await StaffProfileRepository(client: _supabase)
            .getAll(isActive: true);
        
        if (mounted) {
          setState(() {
            _allStaff = List<Map<String, dynamic>>.from(staff);
          });
        }
      } catch (e) {
        // Fallback to cache if database fails
        final cached = await IsarService.getAllStaffProfiles();
        if (mounted) {
          setState(() {
            _allStaff = cached.map((c) => {
              'id': c.staffId,
              'full_name': c.fullName,
            }).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load staff: $e');
    }
  }

  Future<void> _loadAllLeaveRecords() async {
    setState(() => _isLoading = true);
    try {
      // DATABASE-FIRST: Fetch from Supabase FIRST
      try {
        _isOffline = false;
        
        // Load leave_history (all approved + admin entries)
        final history = await _supabase
            .from('leave_history')
            .select('*, staff_profiles!staff_id(full_name)')
            .order('start_date', ascending: false);
        
        // Load staff_requests (pending + rejected only)
        final requests = await _supabase
            .from('staff_requests')
            .select('*, staff_profiles!staff_id(full_name)')
            .eq('request_type', 'leave')
            .inFilter('status', ['pending', 'declined'])
            .order('created_at', ascending: false);
        
        // Tag records with type
        final taggedHistory = (history as List).map((r) {
          final record = r as Map<String, dynamic>;
          return {
            ...record,
            'record_type': 'leave_history',
            'display_status': record['source'] == 'admin_entry' ? 'Admin entry' : 'Approved',
          };
        }).toList();
        
        final taggedRequests = (requests as List).map((r) {
          final record = r as Map<String, dynamic>;
          return {
            ...record,
            'record_type': 'staff_request',
            'display_status': record['status'] == 'pending' ? 'Pending' : 'Declined',
            // Map staff_request fields to match leave_history format for display
            'leave_type': record['leave_type'],
            'start_date': record['leave_start_date'],
            'end_date': record['leave_end_date'],
            'days_taken': record['days_requested'],
            'notes': record['leave_notes'],
          };
        }).toList();
        
        setState(() {
          _allLeaveRecords = [...taggedHistory, ...taggedRequests];
        });
        
        // Update cache in background
        final cachedRequests = (requests as List).map((item) {
          return CachedLeaveRequest.fromSupabase(Map<String, dynamic>.from(item as Map));
        }).toList();
        unawaited(IsarService.saveLeaveRequests(cachedRequests));
      } catch (e) {
        // Fallback to cache if database fails
        _isOffline = true;
        final cached = await IsarService.getAllLeaveRequests();
        final list = cached.map((c) {
          final m = c.toMap();
          m['staff_profiles'] = {'full_name': c.staffName};
          m['record_type'] = 'staff_request';
          return m;
        }).toList();
        setState(() {
          _allLeaveRecords = list;
        });
      }
    } catch (e) {
      debugPrint('Leave load error: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadStaffBalance(String staffId) async {
    setState(() => _loadingBalance = true);
    try {
      if (!ConnectivityService().isConnected) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot load balance while offline'), backgroundColor: AppColors.warning),
          );
        }
        return;
      }

      final balance = await _supabase
          .from('leave_balances')
          .select('*')
          .eq('staff_id', staffId)
          .maybeSingle();
      
      if (mounted) {
        setState(() {
          _selectedStaffBalance = balance;
        });
      }
    } catch (e) {
      debugPrint('Failed to load staff balance: $e');
    }
    setState(() => _loadingBalance = false);
  }

  List<Map<String, dynamic>> get _filteredRecords {
    var filtered = _allLeaveRecords;
    
    // Status filter
    if (_statusFilter != 'All') {
      filtered = filtered.where((r) {
        final status = r['display_status'] as String?;
        return status == _statusFilter;
      }).toList();
    }
    
    // Staff filter
    if (_selectedStaffFilter != null) {
      filtered = filtered.where((r) => r['staff_id'] == _selectedStaffFilter).toList();
    }
    
    // Type filter
    if (_selectedTypeFilter != null) {
      filtered = filtered.where((r) => r['leave_type'] == _selectedTypeFilter).toList();
    }
    
    // Sort by date (most recent first)
    filtered.sort((a, b) {
      final aDate = a['start_date'] as String? ?? '';
      final bDate = b['start_date'] as String? ?? '';
      return bDate.compareTo(aDate);
    });
    
    return filtered;
  }

  Future<void> _handleApprove(Map<String, dynamic> r) async {
    final staffId = r['staff_id'] as String;
    final leaveType = r['leave_type'] as String;
    final startDate = r['start_date'] as String;
    final endDate = r['end_date'] as String;
    final days = r['days_taken'] as num;
    final notes = r['notes'] as String?;
    final requestId = r['id'] as String;
    
    try {
      // Update staff_requests status
      await _supabase.from('staff_requests').update({
        'status': 'approved',
        'reviewed_by': AuthService().getCurrentStaffId(),
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', requestId);
      
      // DIRECT-WRITE: no Edge function exists yet for this table. Review before 060.
      // Insert to leave_history
      await _supabase.from('leave_history').insert({
        'staff_id': staffId,
        'leave_type': leaveType,
        'start_date': startDate,
        'end_date': endDate,
        'days_taken': days,
        'source': 'staff_request',
        'source_request_id': requestId,
        'recorded_by': AuthService().getCurrentStaffId(),
        'notes': notes,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave approved'), backgroundColor: AppColors.success),
        );
      }
      
      _loadAllLeaveRecords();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleReject(Map<String, dynamic> r) async {
    final staffName = r['staff_profiles']?['full_name'] ?? 'Staff';
    final dateStr = '${r['start_date']} → ${r['end_date']}';
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Leave Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$staffName ($dateStr)', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            FormWidgets.textFormField(
              label: 'Reason (staff will see this)',
              controller: notesController,
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final reason = notesController.text.trim();
    if (reason.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A reason is required'), backgroundColor: AppColors.error),
        );
      }
      return;
    }

    try {
      await _supabase.from('staff_requests').update({
        'status': 'declined',
        'leave_decline_reason': reason,
        'reviewed_by': AuthService().getCurrentStaffId(),
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', r['id']);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave rejected'), backgroundColor: AppColors.warning),
        );
      }
      
      _loadAllLeaveRecords();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleDelete(Map<String, dynamic> r) async {
    final staffName = r['staff_profiles']?['full_name'] ?? 'Staff';
    final leaveType = _formatLeaveType(r['leave_type'] as String? ?? '');
    final dateStr = '${r['start_date']} → ${r['end_date']}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Leave Entry'),
        content: Text('Delete $leaveType for $staffName ($dateStr)?\n\nThis will restore their leave balance.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _supabase.from('leave_history').delete().eq('id', r['id']);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave entry deleted'), backgroundColor: AppColors.success),
        );
      }
      
      _loadAllLeaveRecords();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showRecordLeaveDialog(String leaveType) {
    if (_recordLeaveStaffId == null) return;
    
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();
    final daysController = TextEditingController();
    final notesController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(leaveType == 'sick' ? 'Record Sick Leave' : 'Record Family Responsibility Leave'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FormWidgets.dateFormField(
                  label: 'Start Date',
                  controller: startDateController,
                  context: ctx,
                  firstDate: DateTime(2020),
                ),
                const SizedBox(height: 12),
                FormWidgets.dateFormField(
                  label: 'End Date',
                  controller: endDateController,
                  context: ctx,
                  firstDate: DateTime(2020),
                ),
                const SizedBox(height: 12),
                FormWidgets.textFormField(
                  label: 'Days',
                  controller: daysController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                FormWidgets.textFormField(
                  label: 'Notes (optional)',
                  controller: notesController,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSaving ? null : () async {
                setDialogState(() => isSaving = true);
                
                try {
                  // Parse dates from DD/MM/YYYY format
                  final startDateText = startDateController.text.trim();
                  final endDateText = endDateController.text.trim();

                  DateTime? startDate;
                  DateTime? endDate;

                  if (startDateText.isNotEmpty) {
                    final parts = startDateText.split('/');
                    if (parts.length == 3) {
                      startDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                    }
                  }

                  if (endDateText.isNotEmpty) {
                    final parts = endDateText.split('/');
                    if (parts.length == 3) {
                      endDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                    }
                  }

                  if (startDate == null || endDate == null) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid date format'), backgroundColor: AppColors.error),
                      );
                    }
                    return;
                  }

                  final days = int.tryParse(daysController.text);
                  if (days == null || days <= 0) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid days'), backgroundColor: AppColors.error),
                      );
                    }
                    return;
                  }

                  // Convert dates to YYYY-MM-DD format
                  final startDateStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
                  final endDateStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

                  // DIRECT-WRITE: no Edge function exists yet for this table. Review before 060.
                  // Insert to leave_history
                  await _supabase.from('leave_history').insert({
                    'staff_id': _recordLeaveStaffId,
                    'leave_type': leaveType,
                    'start_date': startDateStr,
                    'end_date': endDateStr,
                    'days_taken': days,
                    'source': 'admin_entry',
                    'source_request_id': null,
                    'recorded_by': AuthService().getCurrentStaffId(),
                    'notes': notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  });

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Leave recorded'), backgroundColor: AppColors.success),
                    );
                  }
                  
                  _loadAllLeaveRecords();
                  if (_recordLeaveStaffId != null) {
                    _loadStaffBalance(_recordLeaveStaffId!);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to record leave: $e'), backgroundColor: AppColors.error),
                    );
                  }
                } finally {
                  setDialogState(() => isSaving = false);
                }
              },
              child: isSaving ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ) : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Main area: full-width table
        Expanded(
          child: Column(
            children: [
              // Header with filters
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                color: AppColors.cardBg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Leave Management',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                    ),
                    // Filter dropdowns row
                    Row(
                      children: [
                        // Staff filter
                        SizedBox(
                          width: 200,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedStaffFilter,
                            decoration: const InputDecoration(
                              labelText: 'Staff',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All Staff')),
                              ..._allStaff.map((s) => DropdownMenuItem(
                                value: s['id'],
                                child: Text(s['full_name'], style: const TextStyle(fontSize: 13)),
                              )),
                            ],
                            onChanged: (v) => setState(() => _selectedStaffFilter = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Type filter
                        SizedBox(
                          width: 180,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedTypeFilter,
                            decoration: const InputDecoration(
                              labelText: 'Type',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('All Types')),
                              DropdownMenuItem(value: 'annual', child: Text('Annual')),
                              DropdownMenuItem(value: 'sick', child: Text('Sick')),
                              DropdownMenuItem(value: 'family_responsibility', child: Text('Family')),
                              DropdownMenuItem(value: 'unpaid', child: Text('Unpaid')),
                            ],
                            onChanged: (v) => setState(() => _selectedTypeFilter = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              // Table
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _filteredRecords.isEmpty
                        ? Center(
                            child: Text(
                              _isOffline ? 'No cached data available' : 'No leave records found',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredRecords.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final r = _filteredRecords[i];
                              final status = r['display_status'] as String? ?? '';
                              final isPending = status == 'Pending';
                              final isAdminEntry = r['record_type'] == 'leave_history' && r['source'] == 'admin_entry';
                              
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isPending
                                        ? AppColors.warning.withValues(alpha: 0.4)
                                        : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        r['staff_profiles']?['full_name'] ?? '—',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        _formatLeaveType(r['leave_type'] as String? ?? ''),
                                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${r['start_date']} → ${r['end_date']}',
                                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        '${r['days_taken']} day${(r['days_taken'] as num?) == 1 ? '' : 's'}',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 100,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(fontSize: 11, color: _getStatusColor(status)),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    if (isPending) ...[
                                      ElevatedButton(
                                        onPressed: () => _handleApprove(r),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.success,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                                        child: const Text('Approve', style: TextStyle(fontSize: 12)),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        onPressed: () => _handleReject(r),
                                        style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                                        child: const Text('Reject', style: TextStyle(fontSize: 12)),
                                      ),
                                    ] else if (isAdminEntry) ...[
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20),
                                        color: AppColors.error,
                                        onPressed: () => _handleDelete(r),
                                        tooltip: 'Delete',
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: AppColors.border),
        // Right sidebar
        SizedBox(
          width: 220,
          child: Column(
            children: [
              // Status filter card
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.cardBg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Status Filter',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    ...['All', 'Pending', 'Approved', 'Rejected', 'Admin entry'].map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => setState(() => _statusFilter = s),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _statusFilter == s ? AppColors.primary.withValues(alpha: 0.1) : null,
                            side: BorderSide(
                              color: _statusFilter == s ? AppColors.primary : AppColors.border,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text(s, style: TextStyle(
                            fontSize: 11,
                            color: _statusFilter == s ? AppColors.primary : AppColors.textSecondary,
                          )),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              // Record leave card
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.cardBg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Record Leave',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _recordLeaveStaffId,
                      decoration: const InputDecoration(
                        hintText: 'Select staff...',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _allStaff.map((s) => DropdownMenuItem<String>(
                        value: s['id'] as String,
                        child: Text(s['full_name'] as String, style: const TextStyle(fontSize: 12)),
                      )).toList(),
                      onChanged: (v) {
                        setState(() {
                          _recordLeaveStaffId = v;
                          _selectedStaffBalance = null;
                        });
                        if (v != null) _loadStaffBalance(v);
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _recordLeaveStaffId == null ? null : () => _showRecordLeaveDialog('sick'),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                        child: const Text('Record Sick Leave', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _recordLeaveStaffId == null ? null : () => _showRecordLeaveDialog('family_responsibility'),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                        child: const Text('Record Family Leave', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              // Balances card
              if (_recordLeaveStaffId != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.cardBg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Leave Balances',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      if (_loadingBalance)
                        const Center(child: CircularProgressIndicator())
                      else if (_selectedStaffBalance != null) ...[
                        _balanceRow('Annual', (_selectedStaffBalance!['annual_leave_balance'] as num?)?.toDouble() ?? 0),
                        const SizedBox(height: 8),
                        _balanceRow('Sick', (_selectedStaffBalance!['sick_leave_balance'] as num?)?.toDouble() ?? 0),
                        const SizedBox(height: 8),
                        _balanceRow('Family', (_selectedStaffBalance!['family_leave_balance'] as num?)?.toDouble() ?? 0),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _balanceRow(String label, double days) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        Text('${days.toStringAsFixed(1)}d',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  String _formatLeaveType(String type) {
    switch (type) {
      case 'annual':
        return 'Annual Leave';
      case 'sick':
        return 'Sick Leave';
      case 'family_responsibility':
        return 'Family Responsibility';
      case 'unpaid':
        return 'Unpaid Leave';
      default:
        return type;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return AppColors.warning;
      case 'Approved':
        return AppColors.success;
      case 'Rejected':
        return AppColors.error;
      case 'Admin entry':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }
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
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _load();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    try {
      // DATABASE-FIRST: Fetch from Supabase FIRST
      try {
        final data = await StaffProfileRepository(client: SupabaseService.client)
            .getAll(isActive: true);
        if (mounted) setState(() => _staff = List<Map<String, dynamic>>.from(data));
      } catch (e) {
        // Fallback to cache if database fails
        final cached = await IsarService.getAllStaffProfiles();
        if (mounted) setState(() => _staff = cached.map((c) => {'id': c.staffId, 'full_name': c.fullName}).toList());
      }
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // DATABASE-FIRST: Fetch from Supabase FIRST
      try {
        _isOffline = false;
        final list = await _repo.getRecords();
        if (mounted) setState(() => _records = list);
        
        // Update cache in background
        final cachedRecords = list.map((record) {
          return CachedAwolRecord.fromSupabase(record.toJson());
        }).toList();
        IsarService.saveAwolRecords(cachedRecords);
      } catch (e) {
        // Fallback to cache if database fails
        _isOffline = true;
        final cached = await IsarService.getAllAwolRecords();
        final list = cached
            .where((c) => c.awolDate != null)
            .map((c) => AwolRecord.fromJson({
                  'id': c.recordId,
                  'staff_id': c.staffId ?? '',
                  'awol_date': c.awolDate!.toIso8601String(),
                  'notified_owner_manager': false,
                  'resolution': c.resolved ? 'returned' : 'pending',
                  'written_warning_issued': false,
                  'notes': c.notes,
                  'recorded_by': '',
                  'staff_profiles': {'full_name': c.staffName},
                }))
            .toList();
        list.sort((a, b) => b.awolDate.compareTo(a.awolDate));
        if (mounted) setState(() => _records = list);
      }
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
        expectedStartTime: DateTime(2000, 1, 1, expectedStart.hour, expectedStart.minute),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error),
      );
      }
    }
  }

  void _openEditAwol(AwolRecord record) async {
    final ctx = context;
    DateTime awolDate = record.awolDate;
    final notesController = TextEditingController(text: record.notes ?? '');
    final notifiedWhoController = TextEditingController(text: record.notifiedWho ?? '');
    bool notified = record.notifiedOwnerManager;
    AwolResolution resolution = record.resolution;
    bool writtenWarning = record.writtenWarningIssued;

    final result = await showDialog<bool>(
      context: ctx,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Edit AWOL Record'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Staff: ${record.staffName ?? record.staffId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: awolDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setDialog(() => awolDate = d);
                  },
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text('Date: ${awolDate.day}/${awolDate.month}/${awolDate.year}'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AwolResolution>(
                  initialValue: resolution,
                  decoration: const InputDecoration(labelText: 'Resolution'),
                  items: AwolResolution.values.map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r.dbValue),
                  )).toList(),
                  onChanged: (v) => setDialog(() => resolution = v ?? AwolResolution.pending),
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
                SwitchListTile(
                  title: const Text('Written warning issued'),
                  value: writtenWarning,
                  onChanged: (v) => setDialog(() => writtenWarning = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    try {
      await _repo.update(
        id: record.id,
        awolDate: awolDate,
        resolution: resolution,
        notifiedOwnerManager: notified,
        notifiedWho: notifiedWhoController.text.trim().isEmpty ? null : notifiedWhoController.text.trim(),
        writtenWarningIssued: writtenWarning,
        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AWOL record updated'), backgroundColor: AppColors.success),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _openResolveAwol(AwolRecord record) async {
    final ctx = context;
    AwolResolution resolution = AwolResolution.returned;
    final notesController = TextEditingController(text: record.notes ?? '');
    bool writtenWarning = record.writtenWarningIssued;

    final result = await showDialog<bool>(
      context: ctx,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Resolve AWOL'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Staff: ${record.staffName ?? record.staffId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Date: ${record.awolDate.day}/${record.awolDate.month}/${record.awolDate.year}'),
                const SizedBox(height: 16),
                DropdownButtonFormField<AwolResolution>(
                  initialValue: resolution,
                  decoration: const InputDecoration(labelText: 'Resolution'),
                  items: [
                    AwolResolution.returned,
                    AwolResolution.resigned,
                    AwolResolution.dismissed,
                  ].map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r.dbValue),
                  )).toList(),
                  onChanged: (v) => setDialog(() => resolution = v ?? AwolResolution.returned),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Written warning issued'),
                  value: writtenWarning,
                  onChanged: (v) => setDialog(() => writtenWarning = v),
                ),
                const SizedBox(height: 12),
                FormWidgets.textFormField(
                  label: 'Resolution notes',
                  controller: notesController,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Resolve'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    try {
      await _repo.update(
        id: record.id,
        resolution: resolution,
        writtenWarningIssued: writtenWarning,
        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AWOL record resolved'), backgroundColor: AppColors.success),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error),
        );
      }
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
          child: const Row(children: [
            Expanded(flex: 2, child: Text('STAFF', style: _awolH)),
            SizedBox(width: 100, child: Text('DATE', style: _awolH)),
            SizedBox(width: 100, child: Text('RESOLUTION', style: _awolH)),
            SizedBox(width: 80, child: Text('NOTIFIED', style: _awolH)),
            Expanded(child: Text('NOTES', style: _awolH)),
            SizedBox(width: 100, child: Text('ACTIONS', style: _awolH)),
          ]),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _records.isEmpty
                  ? Center(
                      child: Text(
                        _isOffline ? 'No cached data available. Connect to the internet to load data.' : 'No AWOL records',
                        style: const TextStyle(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    )
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
                              SizedBox(
                                width: 100,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      tooltip: 'Edit',
                                      onPressed: () => _openEditAwol(r),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.check_circle, size: 18),
                                      tooltip: 'Resolve',
                                      onPressed: r.resolution == AwolResolution.pending ? () => _openResolveAwol(r) : null,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      color: r.resolution == AwolResolution.pending ? AppColors.success : AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
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
  bool _isOffline = false;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // DATABASE-FIRST: Fetch from Supabase FIRST
      try {
        _isOffline = false;
        final list = await _service.getBceaCompliance(_month);
        if (mounted) setState(() => _items = list);
        
        // Update cache in background
        final cachedRecords = list.map((item) {
          return CachedComplianceRecord.fromSupabase({
            'id': item.id,
            'document_type': item.title,
            'notes': item.detail,
            'staff_id': item.staffId,
            'staff_name': item.staffName,
            'expiry_date': null,
          });
        }).toList();
        IsarService.saveComplianceRecords(cachedRecords);
      } catch (e) {
        // Fallback to cache if database fails
        _isOffline = true;
        final cached = await IsarService.getAllComplianceRecords();
        final list = cached
            .map((c) => ComplianceItem(
                  id: c.recordId,
                  status: ComplianceStatus.info,
                  title: c.documentType ?? 'Document',
                  detail: c.notes ?? c.expiryDate?.toString() ?? '',
                  staffId: c.staffId,
                  staffName: c.staffName,
                ))
            .toList();
        if (mounted) setState(() => _items = list);
      }
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
                      if (_items.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _isOffline ? 'No cached data available. Connect to the internet to load data.' : 'No compliance items for this month.',
                              style: const TextStyle(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
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
  bool _canClockIn = true;

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
    _tabController = TabController(length: 4, vsync: this);
    if (widget.staff != null) {
      _populate(widget.staff!);
      _loadLeaveData();
    }
  }

  // Leave data
  Map<String, dynamic>? _leaveBalance;
  List<Map<String, dynamic>> _leaveHistory = [];
  bool _isLoadingLeave = false;

  Future<void> _loadLeaveData() async {
    if (widget.staff == null) return;
    final staffId = widget.staff!['id'];

    setState(() => _isLoadingLeave = true);
    try {
      // Load balance
      final balance = await _supabase
          .from('leave_balances')
          .select('*')
          .eq('staff_id', staffId)
          .maybeSingle();

      // Load history
      final history = await _supabase
          .from('leave_history')
          .select('*')
          .eq('staff_id', staffId)
          .order('start_date', ascending: false);

      setState(() {
        _leaveBalance = balance;
        _leaveHistory = List<Map<String, dynamic>>.from(history ?? []);
      });
    } catch (e) {
      debugPrint('Failed to load leave data: $e');
    } finally {
      setState(() => _isLoadingLeave = false);
    }
  }

  void _showRecordLeaveDialog(String leaveType) {
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();
    final daysController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(leaveType == 'sick' ? 'Record Sick Leave' : 'Record Family Responsibility Leave'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FormWidgets.dateFormField(
                  label: 'Start Date',
                  controller: startDateController,
                  context: ctx,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                ),
                const SizedBox(height: 16),
                FormWidgets.dateFormField(
                  label: 'End Date',
                  controller: endDateController,
                  context: ctx,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                ),
                const SizedBox(height: 16),
                FormWidgets.textFormField(
                  label: 'Days',
                  controller: daysController,
                  keyboardType: TextInputType.number,
                  hint: 'Auto-calculated',
                ),
                const SizedBox(height: 16),
                FormWidgets.textFormField(
                  label: 'Notes (optional)',
                  controller: notesController,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                // Parse dates from DD/MM/YYYY format
                final startDateText = startDateController.text.trim();
                final endDateText = endDateController.text.trim();

                DateTime? startDate;
                DateTime? endDate;

                if (startDateText.isNotEmpty) {
                  final parts = startDateText.split('/');
                  if (parts.length == 3) {
                    startDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                  }
                }

                if (endDateText.isNotEmpty) {
                  final parts = endDateText.split('/');
                  if (parts.length == 3) {
                    endDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                  }
                }

                final days = int.tryParse(daysController.text);

                if (startDate == null || endDate == null || days == null || days <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields'), backgroundColor: AppColors.error),
                  );
                  return;
                }

                try {
                  // DIRECT-WRITE: no Edge function exists yet for this table. Review before 060.
                  await _supabase.from('leave_history').insert({
                    'staff_id': widget.staff!['id'],
                    'leave_type': leaveType,
                    'start_date': startDate.toIso8601String().substring(0, 10),
                    'end_date': endDate.toIso8601String().substring(0, 10),
                    'days_taken': days,
                    'source': 'admin_entry',
                    'source_request_id': null,
                    'recorded_by': AuthService().getCurrentStaffId(),
                    'notes': notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  });

                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Leave recorded successfully'), backgroundColor: AppColors.success),
                    );
                    Navigator.pop(ctx);
                  }
                  _loadLeaveData(); // Reload balances
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to record leave: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLeaveType(String? type) {
    switch (type) {
      case 'annual':
        return 'Annual Leave';
      case 'sick':
        return 'Sick Leave';
      case 'family_responsibility':
        return 'Family Responsibility';
      case 'unpaid':
        return 'Unpaid';
      default:
        return type ?? 'Unknown';
    }
  }

  Widget _buildLeaveTab() {
    if (widget.staff == null) {
      return const Center(child: Text('Save staff member first to view leave data'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SECTION A - Leave Balances
          const Text('Leave Balances', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: _isLoadingLeave
                ? const Center(child: CircularProgressIndicator())
                : _leaveBalance == null
                    ? const Text('No balance data yet', style: TextStyle(color: AppColors.textSecondary))
                    : Column(
                        children: [
                          _balanceRow('Annual Leave', _leaveBalance!['annual_leave_balance']),
                          const SizedBox(height: 8),
                          _balanceRow('Sick Leave', _leaveBalance!['sick_leave_balance']),
                          const SizedBox(height: 8),
                          _balanceRow('Family Responsibility', _leaveBalance!['family_leave_balance']),
                        ],
                      ),
          ),
          const SizedBox(height: 24),

          // SECTION B - Record Leave
          const Text('Record Leave', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _showRecordLeaveDialog('sick'),
                icon: const Icon(Icons.sick, size: 18),
                label: const Text('Record Sick Leave'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _showRecordLeaveDialog('family_responsibility'),
                icon: const Icon(Icons.family_restroom, size: 18),
                label: const Text('Record Family Responsibility Leave'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // SECTION C - Leave History
          const Text('Leave History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _isLoadingLeave
              ? const Center(child: CircularProgressIndicator())
              : _leaveHistory.isEmpty
                  ? const Text('No leave history yet', style: TextStyle(color: AppColors.textSecondary))
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _leaveHistory.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final record = _leaveHistory[i];
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
                              Row(
                                children: [
                                  Text(
                                    _formatLeaveType(record['leave_type']),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: record['source'] == 'admin_entry'
                                          ? Colors.grey.withValues(alpha: 0.2)
                                          : AppColors.primary.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      record['source'] == 'admin_entry' ? 'Admin entry' : 'Staff request',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: record['source'] == 'admin_entry'
                                            ? Colors.grey[700]
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${record['start_date']} to ${record['end_date']}',
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                              if (record['notes'] != null && record['notes'].toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  record['notes'].toString(),
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }

  Widget _balanceRow(String label, dynamic days) {
    final daysNum = (days as num?)?.toDouble() ?? 0.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(
          '${daysNum.toStringAsFixed(1)} days remaining',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: daysNum > 0 ? AppColors.textPrimary : AppColors.error,
          ),
        ),
      ],
    );
  }

  void _populate(Map<String, dynamic> s) {
    _nameController.text = s['full_name'] ?? '';
    _phoneController.text = s['phone'] ?? '';
    _emailController.text = s['email'] ?? '';
    _idNumberController.text = s['id_number'] ?? '';
    _role = s['role'] ?? 'cashier';
    _isActive = s['is_active'] ?? true;
    _canClockIn = s['can_clock_in'] ?? true;
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
    final staffId = staff['id'];
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

      // Audit log - staff deactivation
      await AuditService.log(
        action: 'DELETE',
        module: 'HR',
        description: 'Staff member deactivated: $name',
        entityType: 'Staff',
        entityId: staffId,
      );

      widget.onSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.danger),
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
      'can_clock_in': _canClockIn,
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
        final result = await _supabase
            .from('staff_profiles')
            .insert(data)
            .select()
            .single();

        // Sync to profiles table (used for admin app login)
        try {
          // DIRECT-WRITE: no Edge function exists yet for this table. Review before 060.
          await _supabase.from('profiles').insert({
            'id': result['id'],
            'full_name': data['full_name'],
            'role': data['role'],
            'pin_hash': data['pin_hash'],
            'is_active': data['is_active'] ?? true,
            'active': data['is_active'] ?? true,
          });
        } catch (e) {
          debugPrint('profiles sync failed (insert): $e');
        }

        // Audit log - staff creation
        await AuditService.log(
          action: 'CREATE',
          module: 'HR',
          description: 'Staff member created: ${data['full_name']} (${data['role']})',
          entityType: 'Staff',
          entityId: result['id'],
          newValues: data,
        );
        // Create leave balance record for new staff
      } else {
        await _supabase
            .from('staff_profiles')
            .update(data)
            .eq('id', widget.staff!['id']);

        // Sync to profiles table (used for admin app login)
        // Only sync fields that profiles cares about
        try {
          final profileSync = <String, dynamic>{
            'full_name': data['full_name'],
            'role': data['role'],
            'is_active': data['is_active'],
            'active': data['is_active'],
          };
          // Only sync pin_hash if PIN was changed
          if (_pinController.text.isNotEmpty && data['pin_hash'] != null) {
            profileSync['pin_hash'] = data['pin_hash'];
          }
          await _supabase
              .from('profiles')
              .update(profileSync)
              .eq('id', widget.staff!['id']);
        } catch (e) {
          debugPrint('profiles sync failed (update): $e');
        }

        // Audit log - staff update
        await AuditService.log(
          action: 'UPDATE',
          module: 'HR',
          description: 'Staff member updated: ${data['full_name']}',
          entityType: 'Staff',
          entityId: widget.staff!['id'],
          oldValues: widget.staff,
          newValues: data,
        );
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error),
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
              Tab(text: 'Leave'),
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
                _buildLeaveTab(),
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
                const SizedBox(width: 16),
                Switch(
                  value: _canClockIn,
                  onChanged: (v) => setState(() => _canClockIn = v),
                  activeThumbColor: AppColors.primary,
                ),
                const Text('Can use Clock-In App',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
            color: AppColors.info.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
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
            color: AppColors.warning.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
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

// ══════════════════════════════════════════════════════════════════
// TAB 8: BREAK ALERTS
// ══════════════════════════════════════════════════════════════════

class _BreakAlertsTab extends StatefulWidget {
  const _BreakAlertsTab();
  @override
  State<_BreakAlertsTab> createState() => _BreakAlertsTabState();
}

class _BreakAlertsTabState extends State<_BreakAlertsTab> {
  final _supabase = SupabaseService.client;
  List<Map<String, dynamic>> _alerts = [];
  List<Map<String, dynamic>> _staff = [];
  bool _isLoading = true;
  String? _selectedStaffId;
  String? _selectedAlertType;
  Map<String, Map<String, int>> _monthlySummary = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final staffData = await _supabase
          .from('staff_profiles')
          .select('id, full_name')
          .eq('is_active', true)
          .order('full_name');

      var query = _supabase
          .from('staff_alerts')
          .select('*, staff_profiles!staff_alerts_staff_id_fkey(full_name)');

      if (_selectedStaffId != null) {
        query = query.eq('staff_id', _selectedStaffId!);
      }
      if (_selectedAlertType != null) {
        query = query.eq('alert_type', _selectedAlertType!);
      }

      final alertsData = List<Map<String, dynamic>>.from(
        await query.order('triggered_at', ascending: false),
      );

      _buildMonthlySummary(alertsData);

      if (!mounted) return;
      setState(() {
        _staff = List<Map<String, dynamic>>.from(staffData);
        _alerts = alertsData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[BREAK ALERTS TAB] load error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _buildMonthlySummary(List<Map<String, dynamic>> alerts) {
    _monthlySummary = {};
    final firstOfMonth =
        DateTime(DateTime.now().year, DateTime.now().month);
    for (final a in alerts) {
      final raw = a['triggered_at'] as String?;
      if (raw == null) continue;
      final dt = DateTime.tryParse(raw)?.toLocal();
      if (dt == null || dt.isBefore(firstOfMonth)) continue;
      final name =
          (a['staff_profiles'] as Map?)?['full_name'] as String? ?? '?';
      final type = a['alert_type'] as String? ?? '';
      _monthlySummary.putIfAbsent(name, () => {});
      _monthlySummary[name]!
          .update(type, (c) => c + 1, ifAbsent: () => 1);
    }
  }

  String _typeLabel(String t) => switch (t) {
        'short_break' => 'Short Break',
        'break_overrun' => 'Break Overrun',
        'missed_clockout' => 'Missed Clock-Out',
        _ => t,
      };

  Color _statusColor(String s) => switch (s) {
        'pending' => AppColors.warning,
        'acknowledged' => AppColors.info,
        'dismissed' => AppColors.textSecondary,
        'expired' => AppColors.error,
        _ => AppColors.textSecondary,
      };

  String _fmtDt(String? raw) {
    if (raw == null) return '—';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Monthly summary
        if (_monthlySummary.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.surfaceBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This Month',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                ..._monthlySummary.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${e.key}: '
                        '${e.value['short_break'] ?? 0} short  '
                        '${e.value['break_overrun'] ?? 0} overrun  '
                        '${e.value['missed_clockout'] ?? 0} missed',
                        style: const TextStyle(fontSize: 13),
                      ),
                    )),
              ],
            ),
          ),

        // Filters
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          child: Row(children: [
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String?>(
                initialValue: _selectedStaffId,
                decoration: const InputDecoration(
                    labelText: 'Staff', isDense: true),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('All Staff')),
                  ..._staff.map((s) => DropdownMenuItem(
                        value: s['id'] as String,
                        child: Text(
                            s['full_name'] as String? ?? '—',
                            overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (v) {
                  setState(() => _selectedStaffId = v);
                  _loadData();
                },
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String?>(
                initialValue: _selectedAlertType,
                decoration: const InputDecoration(
                    labelText: 'Alert Type', isDense: true),
                items: const [
                  DropdownMenuItem(
                      value: null, child: Text('All Types')),
                  DropdownMenuItem(
                      value: 'short_break',
                      child: Text('Short Break')),
                  DropdownMenuItem(
                      value: 'break_overrun',
                      child: Text('Break Overrun')),
                  DropdownMenuItem(
                      value: 'missed_clockout',
                      child: Text('Missed Clock-Out')),
                ],
                onChanged: (v) {
                  setState(() => _selectedAlertType = v);
                  _loadData();
                },
              ),
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh'),
            ),
          ]),
        ),

        // Table
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _alerts.isEmpty
                  ? const Center(
                      child: Text('No break alerts found',
                          style: TextStyle(
                              color: AppColors.textSecondary)))
                  : SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowHeight: 36,
                          dataRowMinHeight: 40,
                          dataRowMaxHeight: 56,
                          columns: const [
                            DataColumn(
                                label: Text('DATE',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            AppColors.textSecondary))),
                            DataColumn(
                                label: Text('STAFF',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            AppColors.textSecondary))),
                            DataColumn(
                                label: Text('TYPE',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            AppColors.textSecondary))),
                            DataColumn(
                                label: Text('DETAILS',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            AppColors.textSecondary))),
                            DataColumn(
                                label: Text('STATUS',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            AppColors.textSecondary))),
                          ],
                          rows: _alerts.map((a) {
                            final staffName =
                                (a['staff_profiles'] as Map?)?[
                                        'full_name'] as String? ??
                                    '—';
                            final alertType =
                                a['alert_type'] as String? ?? '';
                            final status =
                                a['status'] as String? ?? '';
                            return DataRow(cells: [
                              DataCell(Text(
                                  _fmtDt(
                                      a['triggered_at'] as String?),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color:
                                          AppColors.textSecondary))),
                              DataCell(Text(staffName,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight.w600))),
                              DataCell(Text(
                                  _typeLabel(alertType),
                                  style: const TextStyle(
                                      fontSize: 13))),
                              DataCell(SizedBox(
                                width: 260,
                                child: Text(
                                    a['body'] as String? ?? '—',
                                    style: const TextStyle(
                                        fontSize: 12),
                                    overflow:
                                        TextOverflow.ellipsis,
                                    maxLines: 2),
                              )),
                              DataCell(Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(status)
                                      .withValues(alpha: 0.15),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _statusColor(status)),
                                ),
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}
