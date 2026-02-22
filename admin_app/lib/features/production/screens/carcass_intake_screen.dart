import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';

class CarcassIntakeScreen extends StatefulWidget {
  const CarcassIntakeScreen({super.key});

  @override
  State<CarcassIntakeScreen> createState() => _CarcassIntakeScreenState();
}

class _CarcassIntakeScreenState extends State<CarcassIntakeScreen>
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
                Tab(icon: Icon(Icons.list_alt, size: 18), text: 'Yield Templates'),
                Tab(icon: Icon(Icons.add_box, size: 18), text: 'Carcass Intake'),
                Tab(icon: Icon(Icons.cut, size: 18), text: 'Pending Breakdowns'),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _YieldTemplatesTab(),
                _CarcassIntakeTab(),
                _PendingBreakdownsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 1: YIELD TEMPLATES
// ══════════════════════════════════════════════════════════════════

class _YieldTemplatesTab extends StatefulWidget {
  const _YieldTemplatesTab();

  @override
  State<_YieldTemplatesTab> createState() => _YieldTemplatesTabState();
}

class _YieldTemplatesTabState extends State<_YieldTemplatesTab> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('yield_templates')
          .select('*')
          .order('carcass_type')
          .order('template_name');
      setState(() => _templates = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Templates error: $e');
    }
    setState(() => _isLoading = false);
  }

  void _openTemplate(Map<String, dynamic>? template) {
    showDialog(
      context: context,
      builder: (_) => _TemplateFormDialog(
        template: template,
        onSaved: _loadTemplates,
      ),
    );
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
              const Text(
                'Define how each carcass type breaks down into cuts. Templates drive yield calculations and blockman performance ratings.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _openTemplate(null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Template'),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _templates.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: _templates.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _TemplateCard(
                        template: _templates[i],
                        onEdit: () => _openTemplate(_templates[i]),
                        onRefresh: _loadTemplates,
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cut, size: 64, color: AppColors.border),
          const SizedBox(height: 16),
          const Text('No yield templates yet',
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          const Text(
            'Create templates for Beef Side, Whole Lamb, Pork Side, etc.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openTemplate(null),
            icon: const Icon(Icons.add),
            label: const Text('Create First Template'),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final Map<String, dynamic> template;
  final VoidCallback onEdit;
  final VoidCallback onRefresh;

  const _TemplateCard({
    required this.template,
    required this.onEdit,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final cuts = (template['cuts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final totalPct = cuts.fold<double>(
        0, (sum, c) => sum + ((c['yield_pct'] as num?)?.toDouble() ?? 0));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  template['carcass_type'] ?? '—',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                template['template_name'] ?? '—',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (totalPct - 100).abs() < 0.1
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Total: ${totalPct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: (totalPct - 100).abs() < 0.1
                        ? AppColors.success
                        : AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                color: AppColors.primary,
                onPressed: onEdit,
                tooltip: 'Edit',
              ),
            ],
          ),
          if (cuts.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: cuts.map((c) {
                final pct = (c['yield_pct'] as num?)?.toDouble() ?? 0;
                final sellable = c['sellable'] as bool? ?? true;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sellable
                        ? AppColors.success.withOpacity(0.07)
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: sellable
                          ? AppColors.success.withOpacity(0.3)
                          : AppColors.borderDark,
                    ),
                  ),
                  child: Text(
                    '${c['cut_name']} ${pct.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: sellable
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 2: CARCASS INTAKE
// ══════════════════════════════════════════════════════════════════

class _CarcassIntakeTab extends StatefulWidget {
  const _CarcassIntakeTab();

  @override
  State<_CarcassIntakeTab> createState() => _CarcassIntakeTabState();
}

class _CarcassIntakeTabState extends State<_CarcassIntakeTab> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _intakes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIntakes();
  }

  Future<void> _loadIntakes() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('carcass_intakes')
          .select('*, suppliers(name)')
          .order('created_at', ascending: false)
          .limit(50);
      setState(() => _intakes = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Intakes error: $e');
    }
    setState(() => _isLoading = false);
  }

  void _newIntake() {
    showDialog(
      context: context,
      builder: (_) => _IntakeFormDialog(onSaved: _loadIntakes),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'received': return AppColors.info;
      case 'in_progress': return AppColors.warning;
      case 'completed': return AppColors.success;
      case 'rejected': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          color: AppColors.cardBg,
          child: Row(
            children: [
              const Text('Digital Meat Hook — log every carcass received.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _newIntake,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Intake'),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          color: AppColors.surfaceBg,
          child: const Row(
            children: [
              SizedBox(width: 160, child: Text('REF', style: _hStyle)),
              SizedBox(width: 12),
              Expanded(child: Text('SUPPLIER', style: _hStyle)),
              SizedBox(width: 12),
              SizedBox(width: 140, child: Text('CARCASS TYPE', style: _hStyle)),
              SizedBox(width: 12),
              SizedBox(width: 90, child: Text('INV WEIGHT', style: _hStyle)),
              SizedBox(width: 12),
              SizedBox(width: 90, child: Text('ACT WEIGHT', style: _hStyle)),
              SizedBox(width: 12),
              SizedBox(width: 80, child: Text('VARIANCE', style: _hStyle)),
              SizedBox(width: 12),
              SizedBox(width: 90, child: Text('STATUS', style: _hStyle)),
              SizedBox(width: 12),
              SizedBox(width: 80, child: Text('DATE', style: _hStyle)),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _intakes.isEmpty
                  ? const Center(
                      child: Text('No intakes yet',
                          style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _intakes.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (_, i) {
                        final intake = _intakes[i];
                        final invW = (intake['invoice_weight'] as num?)?.toDouble() ?? 0;
                        final actW = (intake['actual_weight'] as num?)?.toDouble() ?? 0;
                        final variance = invW > 0 ? ((actW - invW) / invW * 100) : 0.0;
                        final status = intake['status'] as String? ?? 'received';
                        final date = intake['delivery_date'] != null
                            ? intake['delivery_date'].toString().substring(0, 10)
                            : '—';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 160,
                                child: Text(
                                  intake['reference_number'] ?? '—',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  intake['suppliers']?['name'] ?? intake['supplier_name'] ?? '—',
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.textPrimary),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 140,
                                child: Text(intake['carcass_type'] ?? '—',
                                    style: const TextStyle(
                                        fontSize: 13, color: AppColors.textPrimary)),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 90,
                                child: Text('${invW.toStringAsFixed(2)} kg',
                                    style: const TextStyle(
                                        fontSize: 13, color: AppColors.textSecondary)),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 90,
                                child: Text('${actW.toStringAsFixed(2)} kg',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary)),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  '${variance >= 0 ? '+' : ''}${variance.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: variance.abs() <= 2
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 90,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    status.replaceAll('_', ' ').toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _statusColor(status),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 80,
                                child: Text(date,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
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

  static const _hStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: AppColors.textSecondary,
      letterSpacing: 0.5);
}

// ══════════════════════════════════════════════════════════════════
// TAB 3: PENDING BREAKDOWNS
// ══════════════════════════════════════════════════════════════════

class _PendingBreakdownsTab extends StatefulWidget {
  const _PendingBreakdownsTab();

  @override
  State<_PendingBreakdownsTab> createState() => _PendingBreakdownsTabState();
}

class _PendingBreakdownsTabState extends State<_PendingBreakdownsTab> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _pending = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('carcass_intakes')
          .select('*, suppliers(name)')
          .inFilter('status', ['received', 'in_progress'])
          .order('created_at', ascending: false);
      setState(() => _pending = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Pending breakdowns error: $e');
    }
    setState(() => _isLoading = false);
  }

  void _startBreakdown(Map<String, dynamic> intake) {
    showDialog(
      context: context,
      builder: (_) => _BreakdownDialog(
        intake: intake,
        onSaved: _loadPending,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          color: AppColors.cardBg,
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.info),
              const SizedBox(width: 8),
              const Text(
                'Partial breakdowns supported — cut what is needed, leave the rest on the hook.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_pending.length} carcass${_pending.length == 1 ? '' : 'es'} pending',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _pending.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 64, color: AppColors.success),
                          SizedBox(height: 16),
                          Text('No pending breakdowns',
                              style: TextStyle(
                                  fontSize: 18, color: AppColors.textSecondary)),
                          SizedBox(height: 8),
                          Text('All carcasses have been broken down.',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: _pending.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final intake = _pending[i];
                        final actW =
                            (intake['actual_weight'] as num?)?.toDouble() ?? 0;
                        final remaining =
                            (intake['remaining_weight'] as num?)?.toDouble() ??
                                actW;
                        final pctDone = actW > 0
                            ? ((actW - remaining) / actW * 100)
                            : 0.0;
                        final isInProgress =
                            intake['status'] == 'in_progress';

                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isInProgress
                                  ? AppColors.warning.withOpacity(0.5)
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Status indicator
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isInProgress
                                      ? AppColors.warning.withOpacity(0.1)
                                      : AppColors.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isInProgress ? Icons.pending : Icons.inventory,
                                  color: isInProgress
                                      ? AppColors.warning
                                      : AppColors.info,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      intake['reference_number'] ?? '—',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${intake['carcass_type'] ?? '—'} — ${intake['suppliers']?['name'] ?? '—'}',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          'Total: ${actW.toStringAsFixed(2)} kg',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          'Remaining on hook: ${remaining.toStringAsFixed(2)} kg',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isInProgress
                                                ? AppColors.warning
                                                : AppColors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (isInProgress) ...[
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: pctDone / 100,
                                          backgroundColor:
                                              AppColors.border,
                                          valueColor:
                                              const AlwaysStoppedAnimation(
                                                  AppColors.warning),
                                          minHeight: 6,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${pctDone.toStringAsFixed(0)}% broken down',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: () => _startBreakdown(intake),
                                icon: Icon(
                                    isInProgress ? Icons.play_arrow : Icons.cut,
                                    size: 18),
                                label: Text(isInProgress
                                    ? 'Continue'
                                    : 'Start Breakdown'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isInProgress
                                      ? AppColors.warning
                                      : AppColors.primary,
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

// ══════════════════════════════════════════════════════════════════
// DIALOGS
// ══════════════════════════════════════════════════════════════════

class _TemplateFormDialog extends StatefulWidget {
  final Map<String, dynamic>? template;
  final VoidCallback onSaved;

  const _TemplateFormDialog({required this.template, required this.onSaved});

  @override
  State<_TemplateFormDialog> createState() => _TemplateFormDialogState();
}

class _TemplateFormDialogState extends State<_TemplateFormDialog> {
  final _supabase = Supabase.instance.client;
  final _nameController = TextEditingController();
  bool _isSaving = false;
  String _carcassType = 'Beef Side';

  final List<Map<String, dynamic>> _cuts = [];

  final _carcassTypes = [
    'Beef Side', 'Beef Quarter', 'Whole Lamb (Premium)',
    'Whole Lamb (AB Grade)', 'Whole Lamb (B3 Grade)',
    'Pork Side', 'Whole Pork', 'Game / Venison'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _nameController.text = widget.template!['template_name'] ?? '';
      _carcassType = widget.template!['carcass_type'] ?? 'Beef Side';
      final cuts = (widget.template!['cuts'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      for (final c in cuts) {
        _cuts.add({
          'cut_name': TextEditingController(text: c['cut_name'] ?? ''),
          'yield_pct': TextEditingController(
              text: (c['yield_pct'] as num?)?.toString() ?? ''),
          'sellable': c['sellable'] as bool? ?? true,
          'plu_code': TextEditingController(
              text: c['plu_code']?.toString() ?? ''),
        });
      }
    } else {
      _addDefaultBeefCuts();
    }
  }

  void _addDefaultBeefCuts() {
    final defaults = [
      {'name': 'T-Bone', 'pct': '10', 'sellable': true},
      {'name': 'Rump', 'pct': '12', 'sellable': true},
      {'name': 'Sirloin', 'pct': '8', 'sellable': true},
      {'name': 'Fillet', 'pct': '3', 'sellable': true},
      {'name': 'Mince', 'pct': '20', 'sellable': true},
      {'name': 'Stewing Beef', 'pct': '15', 'sellable': true},
      {'name': 'Brisket', 'pct': '8', 'sellable': true},
      {'name': 'Short Rib', 'pct': '5', 'sellable': true},
      {'name': 'Bone', 'pct': '12', 'sellable': false},
      {'name': 'Fat / Trimming', 'pct': '5', 'sellable': false},
      {'name': 'Moisture Loss', 'pct': '2', 'sellable': false},
    ];
    for (final d in defaults) {
      _cuts.add({
        'cut_name': TextEditingController(text: d['name'] as String),
        'yield_pct': TextEditingController(text: d['pct'] as String),
        'sellable': d['sellable'],
        'plu_code': TextEditingController(),
      });
    }
  }

  void _addCut() {
    setState(() {
      _cuts.add({
        'cut_name': TextEditingController(),
        'yield_pct': TextEditingController(),
        'sellable': true,
        'plu_code': TextEditingController(),
      });
    });
  }

  double get _totalPct => _cuts.fold(
      0,
      (sum, c) =>
          sum +
          (double.tryParse(
                  (c['yield_pct'] as TextEditingController).text) ??
              0));

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    final cutsData = _cuts.map((c) => {
          'cut_name': (c['cut_name'] as TextEditingController).text.trim(),
          'yield_pct': double.tryParse(
                  (c['yield_pct'] as TextEditingController).text) ??
              0,
          'sellable': c['sellable'],
          'plu_code': int.tryParse(
              (c['plu_code'] as TextEditingController).text),
        }).toList();

    final data = {
      'template_name': _nameController.text.trim(),
      'carcass_type': _carcassType,
      'cuts': cutsData,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      if (widget.template == null) {
        await _supabase.from('yield_templates').insert(data);
      } else {
        await _supabase
            .from('yield_templates')
            .update(data)
            .eq('id', widget.template!['id']);
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
  Widget build(BuildContext context) {
    final total = _totalPct;
    final isBalanced = (total - 100).abs() < 0.1;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 700,
        height: 680,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.cut, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    widget.template == null
                        ? 'New Yield Template'
                        : 'Edit Template',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            // Form fields
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Template Name',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Beef Side — Standard',
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Carcass Type',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _carcassType,
                          decoration: const InputDecoration(isDense: true),
                          items: _carcassTypes
                              .map((t) => DropdownMenuItem(
                                  value: t, child: Text(t)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _carcassType = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total %',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isBalanced
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isBalanced
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                        child: Text(
                          '${total.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isBalanced
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Cuts table header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              color: AppColors.surfaceBg,
              child: const Row(
                children: [
                  Expanded(flex: 3, child: Text('CUT NAME', style: _hdrStyle)),
                  SizedBox(width: 12),
                  SizedBox(width: 80, child: Text('YIELD %', style: _hdrStyle)),
                  SizedBox(width: 12),
                  SizedBox(width: 80, child: Text('PLU CODE', style: _hdrStyle)),
                  SizedBox(width: 12),
                  SizedBox(width: 80, child: Text('SELLABLE', style: _hdrStyle)),
                  SizedBox(width: 40),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            // Cuts list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: _cuts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final cut = _cuts[i];
                  return Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: cut['cut_name'] as TextEditingController,
                          decoration: const InputDecoration(
                              isDense: true, hintText: 'Cut name'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: cut['yield_pct'] as TextEditingController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                              isDense: true,
                              hintText: '0.0',
                              suffixText: '%'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: cut['plu_code'] as TextEditingController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              isDense: true, hintText: '1001'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 80,
                        child: Switch(
                          value: cut['sellable'] as bool,
                          onChanged: (v) =>
                              setState(() => cut['sellable'] = v),
                          activeThumbColor: AppColors.success,
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: AppColors.error),
                          onPressed: () =>
                              setState(() => _cuts.removeAt(i)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            // Footer
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _addCut,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Cut'),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Save Template'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _hdrStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: AppColors.textSecondary,
      letterSpacing: 0.5);
}

// ── Intake Form Dialog ────────────────────────────────────────────

class _IntakeFormDialog extends StatefulWidget {
  final VoidCallback onSaved;
  const _IntakeFormDialog({required this.onSaved});

  @override
  State<_IntakeFormDialog> createState() => _IntakeFormDialogState();
}

class _IntakeFormDialogState extends State<_IntakeFormDialog> {
  final _supabase = Supabase.instance.client;
  final _invoiceNumController = TextEditingController();
  final _invoiceWeightController = TextEditingController();
  final _actualWeightController = TextEditingController();
  final _notesController = TextEditingController();

  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _templates = [];
  String? _selectedSupplierId;
  String? _selectedTemplateId;
  String _carcassType = 'Beef Side';
  DateTime _deliveryDate = DateTime.now();
  bool _isSaving = false;

  final _carcassTypes = [
    'Beef Side', 'Beef Quarter', 'Whole Lamb (Premium)',
    'Whole Lamb (AB Grade)', 'Whole Lamb (B3 Grade)',
    'Pork Side', 'Whole Pork', 'Game / Venison'
  ];

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
    _invoiceWeightController.addListener(() => setState(() {}));
    _actualWeightController.addListener(() => setState(() {}));
  }

  Future<void> _loadSuppliers() async {
    try {
      final data = await _supabase
          .from('suppliers')
          .select('id, name')
          .order('name');
      setState(() => _suppliers = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Suppliers: $e');
    }
  }

  Future<void> _loadTemplates(String carcassType) async {
    try {
      final data = await _supabase
          .from('yield_templates')
          .select('id, template_name, carcass_type')
          .eq('carcass_type', carcassType)
          .order('template_name');
      setState(() {
        _templates = List<Map<String, dynamic>>.from(data);
        _selectedTemplateId = null;
      });
    } catch (e) {
      debugPrint('Templates: $e');
    }
  }

  double get _invoiceWeight =>
      double.tryParse(_invoiceWeightController.text) ?? 0;
  double get _actualWeight =>
      double.tryParse(_actualWeightController.text) ?? 0;
  double get _variance => _invoiceWeight > 0
      ? ((_actualWeight - _invoiceWeight) / _invoiceWeight * 100)
      : 0;

  Future<void> _save() async {
    if (_selectedSupplierId == null ||
        _invoiceWeightController.text.isEmpty ||
        _actualWeightController.text.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);

    final refNum =
        'INT-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    final data = {
      'reference_number': refNum,
      'supplier_id': _selectedSupplierId,
      'invoice_number': _invoiceNumController.text.trim(),
      'invoice_weight': _invoiceWeight,
      'actual_weight': _actualWeight,
      'remaining_weight': _actualWeight,
      'carcass_type': _carcassType,
      'yield_template_id': _selectedTemplateId,
      'delivery_date': _deliveryDate.toIso8601String().substring(0, 10),
      'status': 'received',
      'variance_pct': _variance,
      'notes': _notesController.text.trim(),
    };

    try {
      await _supabase.from('carcass_intakes').insert(data);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final varianceOk = _variance.abs() <= 2;
    final varianceBad = _variance.abs() > 5;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.add_box, color: AppColors.primary),
                  const SizedBox(width: 10),
                  const Text('New Carcass Intake',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 20),

              // Step 1: Delivery Details
              _sectionHeader('Step 1 — Delivery Details'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _dropdownField(
                      label: 'Supplier *',
                      value: _selectedSupplierId,
                      items: _suppliers
                          .map((s) => DropdownMenuItem(
                              value: s['id'] as String,
                              child: Text(s['name'] as String)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedSupplierId = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _textField(
                        label: 'Invoice Number',
                        controller: _invoiceNumController,
                        hint: 'e.g. KRN-2026-0412'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _dropdownField(
                      label: 'Carcass Type *',
                      value: _carcassType,
                      items: _carcassTypes
                          .map((t) =>
                              DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) {
                        setState(() => _carcassType = v!);
                        _loadTemplates(v!);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Delivery Date',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _deliveryDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(
                                  const Duration(days: 1)),
                            );
                            if (d != null) {
                              setState(() => _deliveryDate = d);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 16,
                                    color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                Text(
                                  _deliveryDate
                                      .toIso8601String()
                                      .substring(0, 10),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Step 2: Weighing
              _sectionHeader('Step 2 — Weighing'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _textField(
                        label: 'Invoice Weight (kg) *',
                        controller: _invoiceWeightController,
                        hint: '200.0',
                        isNumber: true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _textField(
                        label: 'Actual Weight (kg) *',
                        controller: _actualWeightController,
                        hint: '198.5',
                        isNumber: true),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Step 3: Variance
              if (_invoiceWeight > 0 && _actualWeight > 0) ...[
                _sectionHeader('Step 3 — Variance Check'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: varianceBad
                        ? AppColors.error.withOpacity(0.05)
                        : varianceOk
                            ? AppColors.success.withOpacity(0.05)
                            : AppColors.warning.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: varianceBad
                          ? AppColors.error.withOpacity(0.3)
                          : varianceOk
                              ? AppColors.success.withOpacity(0.3)
                              : AppColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _varianceStat(
                              'Invoice Weight',
                              '${_invoiceWeight.toStringAsFixed(2)} kg',
                              AppColors.textSecondary),
                          _varianceStat(
                              'Actual Weight',
                              '${_actualWeight.toStringAsFixed(2)} kg',
                              AppColors.textPrimary),
                          _varianceStat(
                              'Variance',
                              '${(_actualWeight - _invoiceWeight).toStringAsFixed(2)} kg (${_variance >= 0 ? '+' : ''}${_variance.toStringAsFixed(2)}%)',
                              varianceBad
                                  ? AppColors.error
                                  : varianceOk
                                      ? AppColors.success
                                      : AppColors.warning),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            varianceBad
                                ? Icons.error
                                : varianceOk
                                    ? Icons.check_circle
                                    : Icons.warning,
                            size: 16,
                            color: varianceBad
                                ? AppColors.error
                                : varianceOk
                                    ? AppColors.success
                                    : AppColors.warning,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            varianceBad
                                ? 'Significant shortfall detected — contact supplier'
                                : varianceOk
                                    ? 'Within tolerance (≤2%) — acceptable'
                                    : 'Minor discrepancy — flagged for review',
                            style: TextStyle(
                              fontSize: 12,
                              color: varianceBad
                                  ? AppColors.error
                                  : varianceOk
                                      ? AppColors.success
                                      : AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Step 4: Template
              _sectionHeader('Step 4 — Yield Template'),
              const SizedBox(height: 12),
              _dropdownField(
                label: 'Select Template (optional — can assign later)',
                value: _selectedTemplateId,
                items: _templates
                    .map((t) => DropdownMenuItem(
                        value: t['id'] as String,
                        child: Text(t['template_name'] as String)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedTemplateId = v),
              ),
              const SizedBox(height: 12),
              _textField(
                  label: 'Notes',
                  controller: _notesController,
                  hint: 'Optional — delivery notes, quality observations'),
              const SizedBox(height: 24),

              // Footer
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Save Intake'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : null,
          decoration: InputDecoration(hintText: hint, isDense: true),
        ),
      ],
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: const InputDecoration(isDense: true),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _varianceStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }
}

// ── Breakdown Dialog ──────────────────────────────────────────────

class _BreakdownDialog extends StatefulWidget {
  final Map<String, dynamic> intake;
  final VoidCallback onSaved;

  const _BreakdownDialog({required this.intake, required this.onSaved});

  @override
  State<_BreakdownDialog> createState() => _BreakdownDialogState();
}

class _BreakdownDialogState extends State<_BreakdownDialog> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _cuts = [];
  List<TextEditingController> _controllers = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPartial = true;
  final _remainingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    setState(() => _isLoading = true);
    final templateId = widget.intake['yield_template_id'];
    if (templateId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final data = await _supabase
          .from('yield_templates')
          .select('cuts')
          .eq('id', templateId)
          .single();

      final rawCuts =
          (data['cuts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final actualWeight =
          (widget.intake['actual_weight'] as num?)?.toDouble() ?? 0;

      setState(() {
        _cuts = rawCuts.map((c) {
          final pct = (c['yield_pct'] as num?)?.toDouble() ?? 0;
          return {
            ...c,
            'expected_kg': actualWeight * pct / 100,
          };
        }).toList();
        _controllers =
            List.generate(_cuts.length, (_) => TextEditingController());
        final remaining =
            (widget.intake['remaining_weight'] as num?)?.toDouble() ??
                actualWeight;
        _remainingController.text = remaining.toStringAsFixed(2);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Template load: $e');
      setState(() => _isLoading = false);
    }
  }

  double get _totalActual => _controllers.fold(
      0, (sum, c) => sum + (double.tryParse(c.text) ?? 0));

  double get _intakeWeight =>
      (widget.intake['actual_weight'] as num?)?.toDouble() ?? 0;

  double get _remaining =>
      double.tryParse(_remainingController.text) ?? 0;

  double get _accounted => _totalActual;
  double get _unaccounted => _intakeWeight - _remaining - _accounted;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final cutsLogged = <Map<String, dynamic>>[];
      for (int i = 0; i < _cuts.length; i++) {
        final actual = double.tryParse(_controllers[i].text);
        if (actual != null && actual > 0) {
          cutsLogged.add({
            'cut_name': _cuts[i]['cut_name'],
            'expected_kg': _cuts[i]['expected_kg'],
            'actual_kg': actual,
            'plu_code': _cuts[i]['plu_code'],
            'sellable': _cuts[i]['sellable'],
          });
        }
      }

      final status = _isPartial ? 'in_progress' : 'completed';
      await _supabase.from('carcass_intakes').update({
        'status': status,
        'remaining_weight': _remaining,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.intake['id']);

      await _supabase.from('carcass_cuts').insert(
        cutsLogged.map((c) => {
              'intake_id': widget.intake['id'],
              'cut_name': c['cut_name'],
              'expected_kg': c['expected_kg'],
              'actual_kg': c['actual_kg'],
              'plu_code': c['plu_code'],
              'sellable': c['sellable'],
              'breakdown_date': DateTime.now().toIso8601String(),
            }).toList(),
      );

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 780,
        height: 700,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.cut, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Carcass Breakdown — ${widget.intake['reference_number'] ?? ''}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary),
                        ),
                        Text(
                          '${widget.intake['carcass_type']} | ${_intakeWeight.toStringAsFixed(2)} kg',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Mode toggle
                  Row(
                    children: [
                      const Text('Partial Breakdown',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      Switch(
                        value: _isPartial,
                        onChanged: (v) => setState(() => _isPartial = v),
                        activeThumbColor: AppColors.warning,
                      ),
                    ],
                  ),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            if (_isLoading)
              const Expanded(
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary)))
            else if (_cuts.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No yield template assigned to this intake.\nAssign a template first in the Carcass Intake tab.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else ...[
              // Table header
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 10),
                color: AppColors.surfaceBg,
                child: const Row(
                  children: [
                    Expanded(flex: 2, child: Text('CUT', style: _bHdr)),
                    SizedBox(width: 12),
                    SizedBox(
                        width: 100,
                        child: Text('EXPECTED (kg)', style: _bHdr)),
                    SizedBox(width: 12),
                    SizedBox(
                        width: 120,
                        child: Text('ACTUAL (kg)', style: _bHdr)),
                    SizedBox(width: 12),
                    SizedBox(
                        width: 90, child: Text('VARIANCE', style: _bHdr)),
                    SizedBox(width: 12),
                    SizedBox(
                        width: 70, child: Text('SELLABLE', style: _bHdr)),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _cuts.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (_, i) {
                    final cut = _cuts[i];
                    final expected =
                        (cut['expected_kg'] as double?) ?? 0;
                    final actual =
                        double.tryParse(_controllers[i].text) ?? 0;
                    final variance =
                        expected > 0 ? ((actual - expected) / expected * 100) : 0.0;
                    final sellable = cut['sellable'] as bool? ?? true;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              cut['cut_name'] ?? '—',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: sellable
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 100,
                            child: Text(
                              '${expected.toStringAsFixed(2)} kg',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: _controllers[i],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                  isDense: true,
                                  hintText: '0.00',
                                  suffixText: 'kg'),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 90,
                            child: actual > 0
                                ? Text(
                                    '${variance >= 0 ? '+' : ''}${variance.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: variance.abs() <= 5
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  )
                                : const Text('—',
                                    style: TextStyle(
                                        color: AppColors.textSecondary)),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 70,
                            child: Text(
                              sellable ? 'Yes' : 'No',
                              style: TextStyle(
                                fontSize: 12,
                                color: sellable
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Summary bar
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                color: AppColors.surfaceBg,
                child: Row(
                  children: [
                    _summaryChip(
                        'Intake Weight',
                        '${_intakeWeight.toStringAsFixed(2)} kg',
                        AppColors.textPrimary),
                    const SizedBox(width: 24),
                    _summaryChip(
                        'Cuts Entered',
                        '${_accounted.toStringAsFixed(2)} kg',
                        AppColors.info),
                    const SizedBox(width: 24),
                    _summaryChip(
                        'Unaccounted',
                        '${_unaccounted.toStringAsFixed(2)} kg',
                        _unaccounted.abs() > _intakeWeight * 0.02
                            ? AppColors.error
                            : AppColors.success),
                    const Spacer(),
                    if (_isPartial) ...[
                      const Text('Remaining on hook:',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _remainingController,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          decoration: const InputDecoration(
                              isDense: true, suffixText: 'kg'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isPartial
                          ? AppColors.warning.withOpacity(0.1)
                          : AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _isPartial
                          ? '⚡ Partial — carcass stays on hook'
                          : '✅ Full — carcass fully broken down',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isPartial
                            ? AppColors.warning
                            : AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_isPartial
                            ? 'Save Partial Breakdown'
                            : 'Complete Breakdown'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary)),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }

  static const _bHdr = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: AppColors.textSecondary,
      letterSpacing: 0.5);
}