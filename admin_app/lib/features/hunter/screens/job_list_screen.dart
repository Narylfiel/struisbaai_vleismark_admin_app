import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/features/hunter/models/hunter_job.dart';
import 'package:admin_app/features/hunter/screens/job_intake_screen.dart';
import 'package:admin_app/features/hunter/services/parked_sale_repository.dart';
import 'package:admin_app/features/hunter/screens/job_process_screen.dart';
import 'package:admin_app/features/hunter/screens/job_summary_screen.dart';

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
        query = query.eq('status', 'completed');
      } else {
        query = query.neq('status', 'completed');
      }
      final data = await query.order('created_at', ascending: false);
      setState(() => _jobs = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Jobs load: $e');
    }
    setState(() => _isLoading = false);
  }

  Color _statusColor(String? status) {
    final v = hunterJobStatusToDbValue(status);
    switch (v) {
      case 'intake': return AppColors.info;
      case 'processing': return AppColors.warning;
      case 'ready': return AppColors.success;
      case 'completed': return AppColors.textSecondary;
      case 'cancelled': return AppColors.danger;
      default: return AppColors.textLight;
    }
  }

  /// H1: FAB → job_intake_screen (new job).
  void _openJobForm() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const JobIntakeScreen()),
    ).then((_) => _load());
  }

  /// Edit job
  void _editJob(Map<String, dynamic> job) {
    final statusDb = hunterJobStatusToDbValue(job['status'] as String?);
    if (statusDb != 'intake' && statusDb != 'processing') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only intake or in_progress jobs can be edited.'), backgroundColor: AppColors.warning),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => JobIntakeScreen(existingJob: job)),
    ).then((_) => _load());
  }
  
  /// Delete job (owner only)
  Future<void> _confirmDeleteJob(Map<String, dynamic> job) async {
    final jobNumber = hunterJobDisplayNumber(job['id']?.toString());
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete job?'),
        content: Text('Delete job $jobNumber? This cannot be undone.'),
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
    try {
      await _supabase.from('hunter_jobs').delete().eq('id', job['id']);
      if (mounted) {
        await _load();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    }
  }

  /// H1: Tap row → job_process_screen (intake/processing) or job_summary_screen (ready/completed).
  Future<void> _confirmCancelJob(Map<String, dynamic> job) async {
    final statusDb = hunterJobStatusToDbValue(job['status'] as String?);
    if (statusDb != 'intake') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only intake jobs can be cancelled.'), backgroundColor: AppColors.danger),
      );
      return;
    }
    final name = hunterJobDisplayNumber(job['id']?.toString()) ?? job['hunter_name']?.toString() ?? 'Job';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel job?'),
        content: Text('Delete $name? This cannot be undone.'),
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
    try {
      await _supabase.from('hunter_jobs').update({'status': 'cancelled'}).eq('id', job['id']);
      if (mounted) {
        await _load();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    }
  }

  void _openJobDetails(Map<String, dynamic> job) {
    final status = hunterJobStatusToDbValue(job['status'] as String?);
    final isProcess = status == 'intake' || status == 'processing';
    final isSummary = status == 'ready' || status == 'completed';
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
            SizedBox(width: 120, child: Text('ACTIONS', style: _h)),
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
                        final statusDb = job['status'] as String? ?? 'intake';
                        final statusLabel = HunterJobStatusExt.fromDb(statusDb).displayLabel;
                        final canCancel = statusDb == 'intake';
                        final isCancelled = statusDb == 'cancelled';
                        final rowContent = Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(children: [
                            SizedBox(width: 120, child: Text(hunterJobDisplayNumber(job['id']?.toString()), style: const TextStyle(fontWeight: FontWeight.bold))),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2, 
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(job['hunter_name'] ?? job['customer_name'] ?? job['client_name'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(job['contact_phone'] ?? job['customer_phone'] ?? job['client_contact'] ?? '—', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              )
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text('${job['animal_type'] ?? 'Unknown'} - ${((job['estimated_weight'] ?? job['estimated_weight_kg']) as num?)?.toStringAsFixed(1) ?? '0.0'} kg')
                            ),
                            const SizedBox(width: 16),
                            SizedBox(width: 100, child: Text('R ${((job['total_amount'] ?? job['charge_total'] ?? job['quoted_price'] ?? job['final_price']) as num?)?.toStringAsFixed(2) ?? '0.00'}')),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 120, 
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: _statusColor(statusDb).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(statusLabel, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: _statusColor(statusDb), fontWeight: FontWeight.bold)),
                              )
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 120, 
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 16),
                                    onPressed: () => _editJob(job),
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                                    onPressed: () => _confirmDeleteJob(job),
                                    tooltip: 'Delete',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                                    onPressed: () => _openJobDetails(job),
                                    tooltip: 'Details',
                                  ),
                                ],
                              ),
                            ),
                          ]),
                        );
                        return InkWell(
                          onLongPress: canCancel ? () => _confirmCancelJob(job) : null,
                          child: isCancelled
                              ? Opacity(opacity: 0.6, child: rowContent)
                              : rowContent,
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
      final w = double.tryParse(_weightCtrl.text) ?? 0.0;
      double estTotal = 0;
      for (final sId in _selectedServices) {
        final s = _services.firstWhere((x) => x['id'] == sId);
        final base = (s['base_price'] as num?)?.toDouble() ?? 0.0;
        final perKg = (s['price_per_kg'] as num?)?.toDouble() ?? 0.0;
        estTotal += base + (w * perKg);
      }

      final res = await _supabase.from('hunter_jobs').insert({
        'hunter_name': _nameCtrl.text.trim(),
        'contact_phone': _phoneCtrl.text.trim(),
        'customer_name': _nameCtrl.text,
        'customer_phone': _phoneCtrl.text,
        'animal_type': _animalCtrl.text,
        'species': _animalCtrl.text.trim().isEmpty ? null : _animalCtrl.text.trim(),
        'estimated_weight': w,
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        'charge_total': estTotal,
        'total_amount': estTotal,
        'status': 'intake',
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
                      final base = (s['base_price'] as num?)?.toDouble() ?? 0;
                      final perKg = (s['price_per_kg'] as num?)?.toDouble();
                      final priceLabel = perKg != null && perKg > 0
                          ? (base > 0 ? 'R $base + R $perKg/kg' : 'R $perKg/kg')
                          : 'R $base';
                      return CheckboxListTile(
                        title: Text('${s['name']} ($priceLabel)'),
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
    _status = hunterJobStatusToDbValue(widget.job['status'] as String?);
    _loadProcesses();
  }

  Future<void> _loadProcesses() async {
    try {
      final res = await _supabase.from('hunter_job_processes')
          .select('*, hunter_services!inner(name, base_price, price_per_kg)')
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

  Future<void> _updateStatus(String newStatusDb) async {
    try {
      await _supabase.from('hunter_jobs').update({'status': newStatusDb}).eq('id', widget.job['id']);
      setState(() => _status = newStatusDb);
      if (newStatusDb == 'ready') {
        final ref = await createParkedSaleForJob(widget.job['id'] as String);
        if (mounted && ref != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Job ready — parked sale $ref created for POS')),
          );
        }
      }
      widget.onSaved();
    } catch (e) {
      debugPrint('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Job: ${hunterJobDisplayNumber(widget.job['id']?.toString())}'),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Customer: ${widget.job['hunter_name'] ?? widget.job['customer_name'] ?? widget.job['client_name'] ?? '—'}', style: const TextStyle(fontWeight: FontWeight.bold))),
                Text('Status: ${HunterJobStatusExt.fromDb(_status).displayLabel}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            Text('Animal: ${widget.job['animal_type'] ?? '—'} (${widget.job['estimated_weight'] ?? widget.job['estimated_weight_kg'] ?? '—'} kg)'),
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
                      final isCompleted = (p['status'] as String?)?.toLowerCase() == 'completed';
                      return ListTile(
                        leading: Icon(isCompleted ? Icons.check_circle : Icons.radio_button_unchecked, color: isCompleted ? AppColors.success : AppColors.textLight),
                        title: Text('${srv['name'] ?? '—'}'),
                        subtitle: Text('Status: ${(p['status'] as String?) ?? '—'}'),
                        trailing: isCompleted ? const Text('Done', style: TextStyle(color: AppColors.success)) : ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => JobProcessScreen(job: widget.job)),
                            ).then((_) => widget.onSaved());
                          },
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
        if (_status == 'intake') ElevatedButton(onPressed: () => _updateStatus('processing'), child: const Text('START PROCESSING')),
        if (_status == 'processing') ElevatedButton(onPressed: () => _updateStatus('ready'), child: const Text('MARK READY')),
        if (_status == 'ready') ElevatedButton(onPressed: () => _updateStatus('completed'), child: const Text('COMPLETE & INVOICE', style: TextStyle(backgroundColor: AppColors.success, color: Colors.white))),
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
      final data = await _supabase.from('hunter_services').select('*').order('name');
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

  Future<void> _confirmDeleteService(Map<String, dynamic> s) async {
    final name = s['name']?.toString() ?? 'Service';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete service?'),
        content: Text('Delete $name? This cannot be undone.'),
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
    if (ok != true || !mounted) return;
    try {
      await _supabase.from('hunter_services').update({'is_active': false}).eq('id', s['id']);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
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
            SizedBox(width: 140, child: Text('PRICING', style: _h)),
            SizedBox(width: 16),
            SizedBox(width: 80, child: Text('STATUS', style: _h)),
            SizedBox(width: 16),
            SizedBox(width: 100, child: Text('ACTIONS', style: _h)),
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
                        final base = (s['base_price'] as num?)?.toDouble() ?? 0;
                        final perKg = (s['price_per_kg'] as num?)?.toDouble();
                        final rateStr = perKg != null && perKg > 0
                            ? (base > 0 ? 'R $base + R $perKg/kg' : 'R $perKg/kg')
                            : 'R $base';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(children: [
                            Expanded(flex: 2, child: Text(s['name'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w600))),
                            const SizedBox(width: 16),
                            SizedBox(width: 140, child: Text(rateStr, overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 16),
                            SizedBox(width: 80, child: Text(active ? 'Active' : 'Inactive', style: TextStyle(color: active ? AppColors.success : AppColors.error, fontSize: 12))),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 100,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit, size: 16), onPressed: () => _openService(s), tooltip: 'Edit'),
                                  IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger), onPressed: () => _confirmDeleteService(s), tooltip: 'Delete'),
                                ],
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
  final _basePriceCtrl = TextEditingController();
  final _pricePerKgCtrl = TextEditingController();

  bool _isActive = true;
  bool _isSaving = false;
  String? _linkedProductId;
  Map<String, dynamic>? _linkedProduct; // {id, name, plu_code, sell_price} for display
  String? _serviceCategory;
  List<Map<String, dynamic>> _inventoryItems = [];
  final _productSearchCtrl = TextEditingController();
  List<Map<String, dynamic>> _cutOptions = []; // [{"name": "Chops"}, {"name": "Steaks"}]

  static const List<String> _serviceCategoryOptions = [
    'processing', 'packaging', 'spice', 'extra', 'casing', 'other',
  ];

  @override
  void initState() {
    super.initState();
    _loadInventoryItems();
    if (widget.service != null) {
      final s = widget.service!;
      _nameCtrl.text = s['name'] ?? '';
      _basePriceCtrl.text = (s['base_price'] ?? '').toString();
      _pricePerKgCtrl.text = (s['price_per_kg'] ?? '').toString();
      _isActive = s['is_active'] ?? true;
      _linkedProductId = s['inventory_item_id']?.toString();
      _serviceCategory = s['service_category']?.toString();
      final opts = s['cut_options'];
      if (opts is List) {
        for (final o in opts) {
          if (o is Map && o['name'] != null) {
            _cutOptions.add({'name': o['name'].toString()});
          } else if (o is String && o.isNotEmpty) {
            _cutOptions.add({'name': o});
          }
        }
      }
      if (_cutOptions.isEmpty) _cutOptions.add({'name': ''});
    } else {
      _cutOptions.add({'name': ''});
    }
  }

  @override
  void dispose() {
    _productSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInventoryItems() async {
    try {
      final res = await _supabase
          .from('inventory_items')
          .select('id, name, plu_code, sell_price')
          .eq('is_active', true)
          .order('name');
      setState(() => _inventoryItems = List<Map<String, dynamic>>.from(res));
      if (_linkedProductId != null && _linkedProduct == null) {
        final match = _inventoryItems.cast<Map<String, dynamic>?>().firstWhere(
          (x) => x!['id']?.toString() == _linkedProductId,
          orElse: () => null,
        );
        if (match != null) setState(() => _linkedProduct = match);
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final cutOptionsPayload = _cutOptions
        .map((c) => c['name']?.toString()?.trim())
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .map((s) => {'name': s})
        .toList();
    final payload = {
      'name': _nameCtrl.text.trim(),
      'base_price': double.tryParse(_basePriceCtrl.text) ?? 0.0,
      'price_per_kg': double.tryParse(_pricePerKgCtrl.text),
      'is_active': _isActive,
      'inventory_item_id': _linkedProductId,
      'service_category': _serviceCategory,
      'cut_options': cutOptionsPayload.isEmpty ? null : cutOptionsPayload,
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Service name'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 8),
              TextFormField(controller: _basePriceCtrl, decoration: const InputDecoration(labelText: 'Base price (R)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 8),
              TextFormField(controller: _pricePerKgCtrl, decoration: const InputDecoration(labelText: 'Price per kg (R) — optional'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 12),
              const Text('Linked Product', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String?>(
                value: _linkedProductId,
                decoration: const InputDecoration(
                  hintText: 'Search by name or PLU — link to product so pricing stays in sync',
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ..._inventoryItems.map((i) => DropdownMenuItem<String?>(
                    value: i['id']?.toString(),
                    child: Text('${i['plu_code'] ?? '—'} ${i['name'] ?? '—'}', overflow: TextOverflow.ellipsis),
                  )),
                ],
                onChanged: (v) {
                  setState(() {
                    _linkedProductId = v;
                    _linkedProduct = v == null ? null : _inventoryItems.cast<Map<String, dynamic>?>().firstWhere(
                      (x) => x!['id']?.toString() == v,
                      orElse: () => null,
                    );
                  });
                },
              ),
              if (_linkedProduct != null) ...[
                const SizedBox(height: 4),
                Text('PLU ${_linkedProduct!['plu_code'] ?? '—'} • R ${(_linkedProduct!['sell_price'] as num?)?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
              const SizedBox(height: 12),
              const Text('Cut options', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 4),
              ..._cutOptions.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: e.value['name']?.toString(),
                        decoration: const InputDecoration(hintText: 'e.g. Chops, Steaks, Mince', isDense: true),
                        onChanged: (v) => _cutOptions[e.key]['name'] = v,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.danger),
                      onPressed: () {
                        setState(() {
                          final idx = e.key;
                          if (idx < _cutOptions.length) {
                            _cutOptions.removeAt(idx);
                            if (_cutOptions.isEmpty) _cutOptions.add({'name': ''});
                          }
                        });
                      },
                    ),
                  ],
                ),
              )),
              OutlinedButton.icon(
                onPressed: () => setState(() => _cutOptions.add({'name': ''})),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add cut option'),
              ),
              const SizedBox(height: 12),
              const Text('Service Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String?>(
                value: _serviceCategory,
                decoration: const InputDecoration(isDense: true),
                hint: const Text('Select category'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ..._serviceCategoryOptions.map((c) => DropdownMenuItem<String?>(value: c, child: Text(c[0].toUpperCase() + c.substring(1)))),
                ],
                onChanged: (v) => setState(() => _serviceCategory = v),
              ),
              const SizedBox(height: 8),
              SwitchListTile(title: const Text('Active'), value: _isActive, onChanged: (v) => setState(() => _isActive = v!)),
            ],
          ),
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
