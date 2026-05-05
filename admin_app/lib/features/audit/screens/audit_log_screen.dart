import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/features/audit/services/audit_repository.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final _repo = AuditRepository();
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  // Filter States
  String? _dateRangeStart;
  String? _dateRangeEnd;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _staffController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedAction = 'All';
  String _selectedSource = 'All';
  List<String> _actionTypes = ['All'];
  static const List<String> _sourceTypes = [
    'All',
    'HR',
    'POS',
    'Accounts',
    'Compliance',
    'Other',
  ];

  int _currentLimit = 50;

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _load();
  }

  Future<void> _loadFilters() async {
    final acts = await _repo.getDistinctActions();
    if (mounted) {
      setState(() => _actionTypes = acts);
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    
    final data = await _repo.getAuditLogs(
      dateRangeStart: _dateRangeStart,
      dateRangeEnd: _dateRangeEnd,
      actionType: _selectedAction == 'All' ? null : _selectedAction,
      staffMember: _staffController.text,
      searchText: _searchController.text.trim(),
      limit: _currentLimit,
      offset: 0,
    );

    final sourceFiltered = data.where(_matchesSourceFilter).toList();

    if (mounted) {
      setState(() {
        _logs = sourceFiltered;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.cardBg,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateRangeStart = picked.start.toIso8601String();
        // Set to end of day
        _dateRangeEnd = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59).toIso8601String();
        _dateController.text = '${picked.start.toLocal().toString().split(' ')[0]} to ${picked.end.toLocal().toString().split(' ')[0]}';
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _dateRangeStart = null;
      _dateRangeEnd = null;
      _dateController.clear();
      _staffController.clear();
      _searchController.clear();
      _selectedAction = 'All';
      _selectedSource = 'All';
      _currentLimit = 50;
    });
    _load();
  }

  void _loadMore() {
    setState(() => _currentLimit += 50);
    _load();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _staffController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSourceFilter(Map<String, dynamic> log) {
    if (_selectedSource == 'All') return true;

    final module = (log['module']?.toString() ?? '').trim();
    final tableName = (log['table_name']?.toString() ?? '').trim();

    switch (_selectedSource) {
      case 'HR':
        return module == 'HR' ||
            {
              'timecards',
              'timecard_breaks',
              'leave_requests',
              'staff_profiles',
              'payroll_entries',
            }.contains(tableName);
      case 'POS':
        return module == 'POS' ||
            {'transactions', 'transaction_items'}.contains(tableName);
      case 'Accounts':
        return module == 'Accounts' ||
            {'ledger_entries', 'account_transactions'}.contains(tableName);
      case 'Compliance':
        return tableName == 'compliance_records';
      case 'Other':
        return !_matchesNamedSource(module, tableName);
      default:
        return true;
    }
  }

  bool _matchesNamedSource(String module, String tableName) {
    if (module == 'HR' || module == 'POS' || module == 'Accounts') return true;
    if (tableName == 'compliance_records') return true;
    if ({
      'timecards',
      'timecard_breaks',
      'leave_requests',
      'staff_profiles',
      'payroll_entries',
    }.contains(tableName)) {
      return true;
    }
    if ({'transactions', 'transaction_items'}.contains(tableName)) return true;
    if ({'ledger_entries', 'account_transactions'}.contains(tableName)) {
      return true;
    }
    return false;
  }

  String _deriveModule(Map<String, dynamic> log) {
    final module = (log['module']?.toString() ?? '').trim();
    if (module.isNotEmpty) return module;
    final tableName = (log['table_name']?.toString() ?? '').trim();
    if ({
      'timecards',
      'timecard_breaks',
      'staff_profiles',
      'leave_requests',
      'payroll_entries',
    }.contains(tableName)) {
      return 'HR';
    }
    if ({'transactions', 'transaction_items'}.contains(tableName)) return 'POS';
    if ({'ledger_entries', 'account_transactions'}.contains(tableName)) {
      return 'Accounts';
    }
    if (tableName == 'compliance_records') return 'Compliance';
    return tableName.isNotEmpty ? tableName : '—';
  }

  String _shortId(dynamic value) {
    final str = value?.toString() ?? '';
    if (str.isEmpty) return '';
    return str.length <= 8 ? str : str.substring(0, 8);
  }

  String _buildDetails(Map<String, dynamic> log) {
    final details = (log['details']?.toString() ?? '').trim();
    if (details.isNotEmpty) return details;
    final description = (log['description']?.toString() ?? '').trim();
    if (description.isNotEmpty) return description;
    final hasOld = log['old_value'] != null;
    final hasNew = log['new_value'] != null;
    if (hasOld || hasNew) {
      final tableName = (log['table_name']?.toString() ?? '').trim();
      final table = tableName.isNotEmpty ? tableName : 'unknown_table';
      return 'Changed: $table record';
    }
    return '—';
  }

  String _buildRecord(Map<String, dynamic> log) {
    final entityType = (log['entity_type']?.toString() ?? '').trim();
    final entityId = _shortId(log['entity_id']);
    if (entityType.isNotEmpty || entityId.isNotEmpty) {
      final left = entityType.isNotEmpty ? entityType : 'Entity';
      final right = entityId.isNotEmpty ? entityId : '—';
      return '$left $right';
    }
    final tableName = (log['table_name']?.toString() ?? '').trim();
    final recordId = _shortId(log['record_id']);
    if (tableName.isNotEmpty || recordId.isNotEmpty) {
      final left = tableName.isNotEmpty ? tableName : 'table';
      final right = recordId.isNotEmpty ? recordId : '—';
      return '$left $right';
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Audit Log Viewer'),
        backgroundColor: AppColors.cardBg,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surfaceBg,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    onTap: _pickDateRange,
                    decoration: const InputDecoration(labelText: 'Date Range', prefixIcon: Icon(Icons.date_range)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Action Type', prefixIcon: Icon(Icons.list)),
                    initialValue: _selectedAction,
                    items: _actionTypes.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedAction = val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Source / Module', prefixIcon: Icon(Icons.apps)),
                    initialValue: _selectedSource,
                    items: _sourceTypes
                        .map((source) => DropdownMenuItem(
                              value: source,
                              child: Text(source),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSource = val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _staffController,
                    decoration: const InputDecoration(labelText: 'Staff Name', prefixIcon: Icon(Icons.person)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search details...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(onPressed: _load, child: const Text('FILTER')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: _clearFilters, child: const Text('CLEAR')),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            color: AppColors.surfaceBg,
            child: const Row(children: [
              SizedBox(width: 160, child: Text('DATE / TIME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
              SizedBox(width: 16),
              SizedBox(width: 120, child: Text('ACTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
              SizedBox(width: 16),
              SizedBox(width: 110, child: Text('MODULE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
              SizedBox(width: 16),
              SizedBox(width: 120, child: Text('WHO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
              SizedBox(width: 16),
              SizedBox(width: 120, child: Text('AUTHORIZED BY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
              SizedBox(width: 16),
              Expanded(child: Text('DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
              SizedBox(width: 16),
              SizedBox(width: 170, child: Text('RECORD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
            ]),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? const Center(child: Text('No audit entries found.'))
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              itemCount: _logs.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                              itemBuilder: (_, i) {
                                final log = _logs[i];
                                
                                // Format datetime nicer if Iso8601 parsing allows
                                String dtStr = log['created_at']?.toString() ?? '—';
                                try {
                                  final dt = DateTime.parse(dtStr).toLocal();
                                  dtStr = '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
                                } catch (_) {}

                                final staffName =
                                    (log['staff_name']?.toString() ?? '').trim();
                                final staffIdShort = _shortId(log['staff_id']);
                                final whoText = staffName.isNotEmpty
                                    ? staffName
                                    : (staffIdShort.isNotEmpty ? staffIdShort : '—');
                                final authorisedName =
                                    (log['authorised_name']?.toString() ?? '').trim();
                                final detailsText = _buildDetails(log);
                                final moduleText = _deriveModule(log);
                                final recordText = _buildRecord(log);

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(width: 160, child: Text(dtStr, style: const TextStyle(fontWeight: FontWeight.w500))),
                                    const SizedBox(width: 16),
                                    SizedBox(width: 120, child: Text(log['action'] ?? '—', style: const TextStyle(fontWeight: FontWeight.bold))),
                                    const SizedBox(width: 16),
                                    SizedBox(width: 110, child: Text(moduleText)),
                                    const SizedBox(width: 16),
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        whoText,
                                        style: staffName.isEmpty && staffIdShort.isNotEmpty
                                            ? const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontStyle: FontStyle.italic,
                                              )
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        authorisedName.isNotEmpty
                                            ? authorisedName
                                            : '—',
                                        style: const TextStyle(
                                            color: AppColors.success),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        detailsText,
                                        softWrap: true,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    SizedBox(width: 170, child: Text(recordText)),
                                  ],
                                );
                              },
                            ),
                          ),
                          // Pagination Control
                          if (_logs.length >= _currentLimit)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextButton(
                                onPressed: _loadMore,
                                child: Text('Load Next 50 Records (Showing ${_logs.length})'),
                              ),
                            )
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
