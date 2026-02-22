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
  
  String _selectedAction = 'All';
  List<String> _actionTypes = ['All'];

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
      limit: _currentLimit,
      offset: 0,
    );

    if (mounted) {
      setState(() {
        _logs = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
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
      _selectedAction = 'All';
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
    super.dispose();
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
                  child: TextFormField(
                    controller: _staffController,
                    decoration: const InputDecoration(labelText: 'Staff Name', prefixIcon: Icon(Icons.person)),
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
              SizedBox(width: 180, child: Text('ACTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
              SizedBox(width: 16),
              SizedBox(width: 120, child: Text('WHO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
              SizedBox(width: 16),
              SizedBox(width: 120, child: Text('AUTHORIZED BY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
              SizedBox(width: 16),
              Expanded(child: Text('DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
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

                                return Row(
                                  children: [
                                    SizedBox(width: 160, child: Text(dtStr, style: const TextStyle(fontWeight: FontWeight.w500))),
                                    const SizedBox(width: 16),
                                    SizedBox(width: 180, child: Text(log['action'] ?? '—', style: const TextStyle(fontWeight: FontWeight.bold))),
                                    const SizedBox(width: 16),
                                    SizedBox(width: 120, child: Text(log['staff_name'] ?? '—')),
                                    const SizedBox(width: 16),
                                    SizedBox(width: 120, child: Text(log['authorized_by'] ?? '—', style: const TextStyle(color: AppColors.success))),
                                    const SizedBox(width: 16),
                                    Expanded(child: Text(log['details'] ?? '—')),
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
