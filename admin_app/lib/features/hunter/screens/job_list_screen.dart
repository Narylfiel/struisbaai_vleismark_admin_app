import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/features/hunter/screens/job_intake_screen.dart';
import 'package:admin_app/features/hunter/screens/job_process_screen.dart';
import 'package:admin_app/features/hunter/screens/job_summary_screen.dart';
import 'dart:math';

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
                Tab(icon: Icon(Icons.assignment, size: 18), text: 'Active Jobs'),
                Tab(icon: Icon(Icons.history, size: 18), text: 'Completed Jobs'),
                Tab(icon: Icon(Icons.settings_applications, size: 18), text: 'Services Config'),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _JobsTab(isCompleted: false),
                _JobsTab(isCompleted: true),
                _ServicesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 1 & 2: JOBS (ACTIVE & COMPLETED)
// ══════════════════════════════════════════════════════════════════

class _JobsTab extends StatefulWidget {
  final bool isCompleted;
  const _JobsTab({required this.isCompleted});

  @override
  State<_JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<_JobsTab> {
  final _supabase = SupabaseService.client;
  List<Map<String, dynamic>> _jobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      var query = _supabase.from('hunter_jobs').select('*');
      if (widget.isCompleted) {
        query = query.eq('status', 'Completed');
      } else {
        query = query.neq('status', 'Completed');
      }
      final data = await query.order('created_at', ascending: false);
      setState(() => _jobs = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Jobs load: $e');
    }
    setState(() => _isLoading = false);
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'Intake': return AppColors.info;
      case 'Processing': return AppColors.warning;
      case 'Ready for Collection': return AppColors.success;
      case 'Completed': return AppColors.textSecondary;
      default: return AppColors.textLight;
    }
  }

  /// H1: FAB → job_intake_screen (new job).
  void _openJobForm() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const JobIntakeScreen()),
    ).then((_) => _load());
  }

  /// H1: Tap row → job_process_screen (intake/processing) or job_summary_screen (ready/collected).
  void _openJobDetails(Map<String, dynamic> job) {
    final status = (job['status'] as String?)?.toLowerCase() ?? '';
    final isProcess = status == 'intake' || status == 'processing' ||
        job['status'] == 'Intake' || job['status'] == 'Processing';
    final isSummary = status == 'ready' || status == 'collected' ||
        job['status'] == 'Ready for Collection' || job['status'] == 'Completed';
    if (isProcess) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => JobProcessScreen(job: job)),
      ).then((_) => _load());
    } else if (isSummary) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => JobSummaryScreen(job: job)),
      ).then((_) => _load());
    } else {
      showDialog(
        context: context,
        builder: (_) => _JobDetailsDialog(job: job, onSaved: _load),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!widget.isCompleted)
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.cardBg,
            child: Row(
              children: [
                const Text('Active Hunter Jobs', 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _openJobForm,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Job'),
                ),
              ],
            ),
          ),
        const Divider(height: 1, color: AppColors.border),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          color: AppColors.surfaceBg,
          child: const Row(children: [
            SizedBox(width: 120, child: Text('JOB #', style: _h)),
            SizedBox(width: 16),
            Expanded(flex: 2, child: Text('CUSTOMER', style: _h)),
            SizedBox(width: 16),
            Expanded(child: Text('ANIMAL INFO', style: _h)),
            SizedBox(width: 16),
            SizedBox(width: 100, child: Text('EST TOTAL', style: _h)),
            SizedBox(width: 16),
            SizedBox(width: 120, child: Text('STATUS', style: _h)),
            SizedBox(width: 16),
            SizedBox(width: 80, child: Text('ACTIONS', style: _h)),
          ]),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _jobs.isEmpty
                  ? Center(
                      child: Text(
                        widget.isCompleted ? 'No completed jobs' : 'No active jobs',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: _jobs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (_, i) {
                        final job = _jobs[i];
                        final status = job['status'] as String? ?? 'Intake';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(children: [
                            SizedBox(width: 120, child: Text(job['job_number'] ?? '—', style: const TextStyle(fontWeight: FontWeight.bold))),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2, 
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(job['customer_name'] ?? job['client_name'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(job['customer_phone'] ?? job['client_contact'] ?? '—', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              )
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text('${job['animal_type'] ?? 'Unknown'} - ${(job['estimated_weight'] as num?)?.toStringAsFixed(1) ?? (job['estimated_weight_kg'] as num?)?.toStringAsFixed(1) ?? '0.0'} kg')
                            ),
                            const SizedBox(width: 16),
                            SizedBox(width: 100, child: Text('R ${((job['total_amount'] ?? job['quoted_price'] ?? job['final_price']) as num?)?.toStringAsFixed(2) ?? '0.00'}')),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 120, 
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(status, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: _statusColor(status), fontWeight: FontWeight.bold)),
                              )
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 80, 
                              child: IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 16), onPressed: () => _openJobDetails(job)),
                            ),
                          ]),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// NEW JOB INTAKE DIALOG
// ══════════════════════════════════════════════════════════════════

class _JobFormDialog extends StatefulWidget {
  final VoidCallback onSaved;
  const _JobFormDialog({required this.onSaved});

  @override
  State<_JobFormDialog> createState() => _JobFormDialogState();
}

class _JobFormDialogState extends State<_JobFormDialog> {
  final _supabase = SupabaseService.client;
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _animalCtrl = TextEditingController(text: 'Springbok');
  final _weightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _depositCtrl = TextEditingController(text: '500');

  List<Map<String, dynamic>> _services = [];
  final List<String> _selectedServices = [];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final res = await _supabase.from('hunter_services').select('*').eq('is_active', true);
      setState(() {
        _services = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one service')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final jobNo = 'HNT-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2,'0')}${DateTime.now().day.toString().padLeft(2,'0')}-${Random().nextInt(999).toString().padLeft(3,'0')}';
      
      final w = double.tryParse(_weightCtrl.text) ?? 0.0;
      double estTotal = 0;
      for (final sId in _selectedServices) {
        final s = _services.firstWhere((x) => x['id'] == sId);
        final rate = (s['rate'] as num?)?.toDouble() ?? 0.0;
        estTotal += (w * rate); // Rough estimate
      }

      final res = await _supabase.from('hunter_jobs').insert({
        'job_number': jobNo,
        'customer_name': _nameCtrl.text,
        'customer_phone': _phoneCtrl.text,
        'customer_email': _emailCtrl.text,
        'animal_type': _animalCtrl.text,
        'estimated_weight': w,
        'notes': _notesCtrl.text,
        'deposit_paid': double.tryParse(_depositCtrl.text) ?? 0.0,
        'total_amount': estTotal,
        'status': 'Intake'
      }).select().single();

      final jobId = res['id'];
      
      for (final sId in _selectedServices) {
        await _supabase.from('hunter_job_processes').insert({
          'job_id': jobId,
          'service_id': sId,
          'status': 'Pending'
        });
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Hunter Job Intake'),
      content: SizedBox(
        width: 600,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const Text('Customer Info', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name'), validator: (v) => v!.isEmpty ? 'Req' : null)),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'))),
                    ]),
                    const SizedBox(height: 16),
                    const Text('Animal Details', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: TextFormField(controller: _animalCtrl, decoration: const InputDecoration(labelText: 'Animal Type'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(controller: _weightCtrl, decoration: const InputDecoration(labelText: 'Est Weight (kg)'), keyboardType: TextInputType.number)),
                    ]),
                    const SizedBox(height: 8),
                    TextFormField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Notes / Requests'), maxLines: 2),
                    const SizedBox(height: 16),
                    const Text('Select Services', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._services.map((s) {
                      final id = s['id'] as String;
                      final isSelected = _selectedServices.contains(id);
                      final rate = s['rate'] ?? 0;
                      final rateType = s['rate_type'] == 'per_kg' ? '/ kg' : '/ pack';
                      return CheckboxListTile(
                        title: Text('${s['service_name']} (R $rate $rateType)'),
                        value: isSelected,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedServices.add(id);
                            } else {
                              _selectedServices.remove(id);
                            }
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 16),
                    TextFormField(controller: _depositCtrl, decoration: const InputDecoration(labelText: 'Deposit Paid (R)'), keyboardType: TextInputType.number),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        ElevatedButton(onPressed: _isSaving ? null : _save, child: const Text('CREATE JOB')),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// JOB DETAILS & PROCESSING DIALOG
// ══════════════════════════════════════════════════════════════════

class _JobDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> job;
  final VoidCallback onSaved;
  const _JobDetailsDialog({required this.job, required this.onSaved});

  @override
  State<_JobDetailsDialog> createState() => _JobDetailsDialogState();
}

class _JobDetailsDialogState extends State<_JobDetailsDialog> {
  final _supabase = SupabaseService.client;
  List<Map<String, dynamic>> _processes = [];
  bool _isLoading = true;
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.job['status'] ?? 'Intake';
    _loadProcesses();
  }

  Future<void> _loadProcesses() async {
    try {
      final res = await _supabase.from('hunter_job_processes')
          .select('*, hunter_services!inner(service_name, rate, rate_type)')
          .eq('job_id', widget.job['id'])
          .order('id');
      setState(() {
        _processes = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await _supabase.from('hunter_jobs').update({'status': newStatus}).eq('id', widget.job['id']);
      setState(() => _status = newStatus);
      widget.onSaved();
    } catch (e) {
      debugPrint('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Job: ${widget.job['job_number']}'),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Customer: ${widget.job['customer_name'] ?? widget.job['client_name'] ?? '—'}', style: const TextStyle(fontWeight: FontWeight.bold))),
                Text('Status: $_status', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            Text('Animal: ${widget.job['animal_type'] ?? '—'} (${(widget.job['estimated_weight'] ?? widget.job['estimated_weight_kg']) ?? '—'} kg)'),
            const SizedBox(height: 16),
            const Text('Processing Steps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _processes.length,
                    itemBuilder: (_, i) {
                      final p = _processes[i];
                      final srv = p['hunter_services'];
                      final isCompleted = p['status'] == 'Completed';
                      return ListTile(
                        leading: Icon(isCompleted ? Icons.check_circle : Icons.radio_button_unchecked, color: isCompleted ? AppColors.success : AppColors.textLight),
                        title: Text('${srv['service_name']}'),
                        subtitle: Text('Status: ${p['status']}'),
                        trailing: isCompleted ? const Text('Done', style: TextStyle(color: AppColors.success)) : ElevatedButton(
                          onPressed: () {}, // Would open step form
                          child: const Text('Process'),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
      actions: [
        if (_status == 'Intake') ElevatedButton(onPressed: () => _updateStatus('Processing'), child: const Text('START PROCESSING')),
        if (_status == 'Processing') ElevatedButton(onPressed: () => _updateStatus('Ready for Collection'), child: const Text('MARK READY')),
        if (_status == 'Ready for Collection') ElevatedButton(onPressed: () => _updateStatus('Completed'), child: const Text('COMPLETE & INVOICE', style: TextStyle(backgroundColor: AppColors.success, color: Colors.white))),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 3: SERVICES
// ══════════════════════════════════════════════════════════════════

class _ServicesTab extends StatefulWidget {
  const _ServicesTab();
  @override
  State<_ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<_ServicesTab> {
  final _supabase = SupabaseService.client;
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase.from('hunter_services').select('*').order('service_name');
      setState(() => _services = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Services load: $e');
    }
    setState(() => _isLoading = false);
  }

  void _openService(Map<String, dynamic>? service) {
    showDialog(
      context: context,
      builder: (_) => _ServiceFormDialog(service: service, onSaved: _load),
    );
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
              const Text('Hunter Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _openService(null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Service'),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          color: AppColors.surfaceBg,
          child: const Row(children: [
            Expanded(flex: 2, child: Text('SERVICE NAME', style: _h)),
            SizedBox(width: 16),
            SizedBox(width: 100, child: Text('RATE', style: _h)),
            SizedBox(width: 16),
            SizedBox(width: 80, child: Text('YIELD', style: _h)),
            SizedBox(width: 16),
            SizedBox(width: 80, child: Text('STATUS', style: _h)),
            SizedBox(width: 16),
            SizedBox(width: 60, child: Text('ACTIONS', style: _h)),
          ]),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _services.isEmpty
                  ? const Center(child: Text('No services configured'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: _services.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (_, i) {
                        final s = _services[i];
                        final active = s['is_active'] as bool? ?? true;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(children: [
                            Expanded(flex: 2, child: Text(s['service_name'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w600))),
                            const SizedBox(width: 16),
                            SizedBox(width: 100, child: Text('R ${s['rate']} / ${s['rate_type'] == 'per_kg' ? 'kg' : 'pack'}')),
                            const SizedBox(width: 16),
                            SizedBox(width: 80, child: Text('${s['expected_yield'] ?? '0'}%')),
                            const SizedBox(width: 16),
                            SizedBox(width: 80, child: Text(active ? 'Active' : 'Inactive', style: TextStyle(color: active ? AppColors.success : AppColors.error, fontSize: 12))),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 60,
                              child: IconButton(icon: const Icon(Icons.edit, size: 16), onPressed: () => _openService(s)),
                            ),
                          ]),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _ServiceFormDialog extends StatefulWidget {
  final Map<String, dynamic>? service;
  final VoidCallback onSaved;
  const _ServiceFormDialog({this.service, required this.onSaved});

  @override
  State<_ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<_ServiceFormDialog> {
  final _supabase = SupabaseService.client;
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _yieldCtrl = TextEditingController();
  final _minWtCtrl = TextEditingController();

  String _rateType = 'per_kg';
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      final s = widget.service!;
      _nameCtrl.text = s['service_name'] ?? '';
      _rateCtrl.text = (s['rate'] ?? '').toString();
      _yieldCtrl.text = (s['expected_yield'] ?? '').toString();
      _minWtCtrl.text = (s['min_weight'] ?? '').toString();
      _rateType = s['rate_type'] ?? 'per_kg';
      _isActive = s['is_active'] ?? true;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final payload = {
      'service_name': _nameCtrl.text,
      'rate_type': _rateType,
      'rate': double.tryParse(_rateCtrl.text) ?? 0.0,
      'expected_yield': double.tryParse(_yieldCtrl.text) ?? 0.0,
      'min_weight': double.tryParse(_minWtCtrl.text) ?? 0.0,
      'is_active': _isActive,
    };

    try {
      if (widget.service == null) {
        await _supabase.from('hunter_services').insert(payload);
      } else {
        await _supabase.from('hunter_services').update(payload).eq('id', widget.service!['id']);
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.service == null ? 'New Service' : 'Edit Service'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Service Name'), validator: (v) => v!.isEmpty ? 'Req' : null),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _rateType,
              decoration: const InputDecoration(labelText: 'Rate Type'),
              items: const [
                DropdownMenuItem(value: 'per_kg', child: Text('Per Kg')),
                DropdownMenuItem(value: 'per_pack', child: Text('Per Pack')),
              ],
              onChanged: (v) => setState(() => _rateType = v!),
            ),
            const SizedBox(height: 8),
            TextFormField(controller: _rateCtrl, decoration: const InputDecoration(labelText: 'Rate (R)'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextFormField(controller: _yieldCtrl, decoration: const InputDecoration(labelText: 'Expected Yield (%)'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            SwitchListTile(title: const Text('Active'), value: _isActive, onChanged: (v) => setState(() => _isActive = v)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        ElevatedButton(onPressed: _isSaving ? null : _save, child: const Text('SAVE')),
      ],
    );
  }
}

const _h = TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5);
