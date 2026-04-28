import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:intl/intl.dart';

class CampaignManagerScreen extends StatefulWidget {
  const CampaignManagerScreen({super.key, this.embedded = false});
  final bool embedded;
  @override
  State<CampaignManagerScreen> createState() => _CampaignManagerScreenState();
}

class _CampaignManagerScreenState extends State<CampaignManagerScreen>
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
    return Column(
      children: [
        Container(
          color: AppColors.cardBg,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(icon: Icon(Icons.campaign, size: 16), text: 'Campaigns'),
              Tab(icon: Icon(Icons.receipt_long, size: 16), text: 'Orders'),
              Tab(icon: Icon(Icons.share, size: 16), text: 'Referrals'),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _CampaignsTab(),
              _OrdersTab(),
              _ReferralsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 1: CAMPAIGNS
// ══════════════════════════════════════════════════════════════════

class _CampaignsTab extends StatefulWidget {
  const _CampaignsTab();
  @override
  State<_CampaignsTab> createState() => _CampaignsTabState();
}

class _CampaignsTabState extends State<_CampaignsTab> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _campaigns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _db
          .from('custom_reward_campaigns')
          .select()
          .order('created_at', ascending: false);
      if (mounted) setState(() => _campaigns = List<Map<String, dynamic>>.from(res));
    } catch (e) {
      debugPrint('[CAMPAIGNS] Load failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setStatus(String id, String status) async {
    try {
      // If activating, deactivate all others first
      if (status == 'active') {
        await _db
            .from('custom_reward_campaigns')
            .update({'status': 'closed'})
            .neq('id', id)
            .eq('status', 'active');
      }
      await _db
          .from('custom_reward_campaigns')
          .update({'status': status})
          .eq('id', id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (_) => _CampaignDialog(
        onSave: (data) async {
          await _db.from('custom_reward_campaigns').insert(data);
          _load();
        },
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> campaign) {
    showDialog(
      context: context,
      builder: (_) => _CampaignDialog(
        existing: campaign,
        onSave: (data) async {
          await _db
              .from('custom_reward_campaigns')
              .update(data)
              .eq('id', campaign['id']);
          _load();
        },
      ),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Custom Boerewors Campaigns',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              ElevatedButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Campaign'),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _campaigns.isEmpty
                  ? const Center(child: Text('No campaigns yet.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _campaigns.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final c = _campaigns[i];
                        final status = c['status'] as String? ?? 'draft';
                        final isActive = status == 'active';
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.success
                                  : AppColors.border,
                              width: isActive ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      c['name'] ?? '—',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  _StatusChip(status: status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 16,
                                runSpacing: 4,
                                children: [
                                  _InfoChip(
                                    icon: Icons.people,
                                    label: '${c['max_slots']} slots',
                                  ),
                                  _InfoChip(
                                    icon: Icons.scale,
                                    label: 'Min ${c['min_kg']} kg',
                                  ),
                                  _InfoChip(
                                    icon: Icons.discount,
                                    label: '${c['discount_value']}% off',
                                  ),
                                  _InfoChip(
                                    icon: Icons.access_time,
                                    label:
                                        '${c['collection_days_min']}–${c['collection_days_max']} days',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (_) => _IngredientsDialog(
                                        campaignId:   c['id'] as String,
                                        campaignName: c['name'] as String? ?? '',
                                      ),
                                    ),
                                    icon: const Icon(
                                        Icons.restaurant_menu, size: 14),
                                    label: const Text('Ingredients'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _showEditDialog(c),
                                    icon: const Icon(Icons.edit, size: 14),
                                    label: const Text('Edit'),
                                  ),
                                  const SizedBox(width: 8),
                                  if (!isActive)
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _setStatus(c['id'], 'active'),
                                      icon: const Icon(Icons.play_arrow,
                                          size: 14),
                                      label: const Text('Set Active'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                      ),
                                    )
                                  else
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _setStatus(c['id'], 'closed'),
                                      icon: const Icon(Icons.stop, size: 14),
                                      label: const Text('Close'),
                                    ),
                                ],
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

// ── Campaign create/edit dialog ───────────────────────────────────
class _CampaignDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const _CampaignDialog({this.existing, required this.onSave});

  @override
  State<_CampaignDialog> createState() => _CampaignDialogState();
}

class _CampaignDialogState extends State<_CampaignDialog> {
  final _nameCtrl         = TextEditingController();
  final _maxSlotsCtrl     = TextEditingController();
  final _minKgCtrl        = TextEditingController();
  final _discountCtrl     = TextEditingController();
  final _collMinCtrl      = TextEditingController();
  final _collMaxCtrl      = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text     = e['name'] ?? '';
      _maxSlotsCtrl.text = '${e['max_slots'] ?? 5}';
      _minKgCtrl.text    = '${e['min_kg'] ?? 5}';
      _discountCtrl.text = '${e['discount_value'] ?? 20}';
      _collMinCtrl.text  = '${e['collection_days_min'] ?? 3}';
      _collMaxCtrl.text  = '${e['collection_days_max'] ?? 5}';
    } else {
      _maxSlotsCtrl.text = '5';
      _minKgCtrl.text    = '5';
      _discountCtrl.text = '20';
      _collMinCtrl.text  = '3';
      _collMaxCtrl.text  = '5';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _maxSlotsCtrl.dispose();
    _minKgCtrl.dispose();
    _discountCtrl.dispose();
    _collMinCtrl.dispose();
    _collMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.onSave({
        'name':                 _nameCtrl.text.trim(),
        'target_tier':          'vip',
        'max_slots':            int.tryParse(_maxSlotsCtrl.text) ?? 5,
        'min_kg':               double.tryParse(_minKgCtrl.text) ?? 5.0,
        'discount_type':        'percent_off',
        'discount_value':       double.tryParse(_discountCtrl.text) ?? 20.0,
        'collection_days_min':  int.tryParse(_collMinCtrl.text) ?? 3,
        'collection_days_max':  int.tryParse(_collMaxCtrl.text) ?? 5,
        if (widget.existing == null) 'status': 'draft',
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null
          ? 'Edit Campaign'
          : 'New Campaign'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Field(label: 'Campaign name', ctrl: _nameCtrl),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Field(label: 'Max slots', ctrl: _maxSlotsCtrl, numeric: true)),
              const SizedBox(width: 12),
              Expanded(child: _Field(label: 'Min kg', ctrl: _minKgCtrl, numeric: true)),
            ]),
            const SizedBox(height: 12),
            _Field(label: 'VIP discount %', ctrl: _discountCtrl, numeric: true),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Field(label: 'Collection min days', ctrl: _collMinCtrl, numeric: true)),
              const SizedBox(width: 12),
              Expanded(child: _Field(label: 'Collection max days', ctrl: _collMaxCtrl, numeric: true)),
            ]),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 2: ORDERS
// ══════════════════════════════════════════════════════════════════

class _OrdersTab extends StatefulWidget {
  const _OrdersTab();
  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _db
          .from('custom_reward_orders')
          .select('''
            id, boerewors_name, kg_ordered, price_total,
            status, paid_at, fulfilled_at, customer_vision,
            payfast_reference,
            loyalty_customers (full_name, phone, whatsapp)
          ''')
          .order('paid_at', ascending: false)
          .limit(100);
      if (mounted) setState(() => _orders = List<Map<String, dynamic>>.from(res));
    } catch (e) {
      debugPrint('[ORDERS] Load failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markFulfilled(String id) async {
    await _db
        .from('custom_reward_orders')
        .update({
          'status':       'fulfilled',
          'fulfilled_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.cardBg,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_orders.length} orders',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _orders.isEmpty
                  ? const Center(child: Text('No orders yet.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final o = _orders[i];
                        final customer = o['loyalty_customers']
                            as Map<String, dynamic>?;
                        final status = o['status'] as String? ?? 'paid';
                        final paidAt = o['paid_at'] != null
                            ? DateFormat('d MMM y')
                                .format(DateTime.parse(o['paid_at']))
                            : '—';
                        final isFulfilled = status == 'fulfilled';

                        return Container(
                          padding: const EdgeInsets.all(16),
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
                                  Expanded(
                                    child: Text(
                                      o['boerewors_name'] ?? '—',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  _StatusChip(status: status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                customer?['full_name'] ?? '—',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary),
                              ),
                              Text(
                                customer?['whatsapp'] ??
                                    customer?['phone'] ??
                                    '—',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 16,
                                runSpacing: 4,
                                children: [
                                  _InfoChip(
                                    icon: Icons.scale,
                                    label:
                                        '${o['kg_ordered'] ?? 0} kg',
                                  ),
                                  _InfoChip(
                                    icon: Icons.payments,
                                    label:
                                        'R${(o['price_total'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                  ),
                                  _InfoChip(
                                    icon: Icons.calendar_today,
                                    label: paidAt,
                                  ),
                                ],
                              ),
                              if ((o['customer_vision'] as String?)
                                      ?.isNotEmpty ==
                                  true) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceBg,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: AppColors.border),
                                  ),
                                  child: Text(
                                    '"${o['customer_vision']}"',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                              if (!isFulfilled) ...[
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _markFulfilled(o['id']),
                                    icon: const Icon(Icons.check,
                                        size: 14),
                                    label: const Text('Mark Fulfilled'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
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
// TAB 3: REFERRALS LEADERBOARD
// ══════════════════════════════════════════════════════════════════

class _ReferralsTab extends StatefulWidget {
  const _ReferralsTab();
  @override
  State<_ReferralsTab> createState() => _ReferralsTabState();
}

class _ReferralsTabState extends State<_ReferralsTab> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _leaderboard = [];
  bool _loading = true;
  String? _approvedWinnerId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Get all converted referrals with referrer details
      final res = await _db
          .from('referrals')
          .select('''
            referrer_id,
            loyalty_customers!referrals_referrer_id_fkey (
              id, full_name, phone, whatsapp, membership_number
            )
          ''')
          .eq('status', 'converted')
          .order('created_at', ascending: false);

      // Group by referrer and count
      final Map<String, Map<String, dynamic>> grouped = {};
      for (final r in res as List) {
        final rid = r['referrer_id'] as String;
        if (!grouped.containsKey(rid)) {
          grouped[rid] = {
            'referrer_id': rid,
            'customer': r['loyalty_customers'],
            'count': 0,
          };
        }
        grouped[rid]!['count'] = (grouped[rid]!['count'] as int) + 1;
      }

      // Sort by count descending
      final sorted = grouped.values.toList()
        ..sort((a, b) =>
            (b['count'] as int).compareTo(a['count'] as int));

      if (mounted) setState(() => _leaderboard = sorted);
    } catch (e) {
      debugPrint('[REFERRALS] Load failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly referral leaderboard',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.surfaceBg,
          child: const Row(
            children: [
              Icon(Icons.info_outline,
                  size: 14, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tap "Approve Gift" on the top referrer to record your monthly thank-you. This does not notify the customer automatically.',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _leaderboard.isEmpty
                  ? const Center(
                      child: Text('No successful referrals this month.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _leaderboard.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final entry = _leaderboard[i];
                        final customer = entry['customer']
                            as Map<String, dynamic>?;
                        final count = entry['count'] as int;
                        final rid = entry['referrer_id'] as String;
                        final isApproved = _approvedWinnerId == rid;
                        final isFirst = i == 0;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isFirst
                                ? AppColors.accent.withValues(alpha: 0.06)
                                : AppColors.cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isFirst
                                  ? AppColors.accent
                                  : AppColors.border,
                              width: isFirst ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isFirst
                                      ? AppColors.accent
                                      : AppColors.surfaceBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isFirst
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customer?['full_name'] ?? '—',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      customer?['membership_number'] ??
                                          '',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$count',
                                    style: const TextStyle(
                                      fontFamily: 'Georgia',
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'referrals',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              if (isFirst) ...[
                                const SizedBox(width: 12),
                                isApproved
                                    ? Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.success
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                              color: AppColors.success),
                                        ),
                                        child: const Text(
                                          '✓ Gift approved',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.success,
                                          ),
                                        ),
                                      )
                                    : ElevatedButton(
                                        onPressed: () => setState(() =>
                                            _approvedWinnerId = rid),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.accent,
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8),
                                        ),
                                        child: const Text(
                                          'Approve Gift',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ),
                              ],
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
// SHARED WIDGETS
// ══════════════════════════════════════════════════════════════════

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'active'    => (AppColors.success, 'Active'),
      'paid'      => (AppColors.primary, 'Paid'),
      'fulfilled' => (AppColors.success, 'Fulfilled'),
      'closed'    => (AppColors.textSecondary, 'Closed'),
      'cancelled' => (AppColors.error, 'Cancelled'),
      _           => (AppColors.textSecondary, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final bool numeric;
  const _Field(
      {required this.label, required this.ctrl, this.numeric = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// INGREDIENT MANAGER DIALOG
// ══════════════════════════════════════════════════════════════════

class _IngredientsDialog extends StatefulWidget {
  final String campaignId;
  final String campaignName;
  const _IngredientsDialog({
    required this.campaignId,
    required this.campaignName,
  });

  @override
  State<_IngredientsDialog> createState() => _IngredientsDialogState();
}

class _IngredientsDialogState extends State<_IngredientsDialog>
    with SingleTickerProviderStateMixin {
  final _db = Supabase.instance.client;
  late TabController _tabController;

  List<Map<String, dynamic>> _meatBases    = [];
  List<Map<String, dynamic>> _profiles     = [];
  List<Map<String, dynamic>> _addons       = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _db
          .from('custom_reward_ingredients')
          .select()
          .eq('campaign_id', widget.campaignId)
          .order('sort_order');

      final all = List<Map<String, dynamic>>.from(res);
      if (mounted) {
        setState(() {
        _meatBases = all.where((i) =>
            i['ingredient_type'] == 'meat_base').toList();
        _profiles  = all.where((i) =>
            i['ingredient_type'] == 'spice_profile').toList();
        _addons    = all.where((i) =>
            i['ingredient_type'] == 'spice_addon').toList();
        _loading   = false;
      });
      }
    } catch (e) {
      debugPrint('[INGREDIENTS] Load failed: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addIngredient(String type) async {
    final nameCtrl  = TextEditingController();
    final priceCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add ${_typeLabel(type)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Name',
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Price per kg (R)',
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (confirmed == true && nameCtrl.text.trim().isNotEmpty) {
      final existingCount = type == 'meat_base'
          ? _meatBases.length
          : type == 'spice_profile'
              ? _profiles.length
              : _addons.length;
      await _db.from('custom_reward_ingredients').insert({
        'campaign_id':     widget.campaignId,
        'ingredient_type': type,
        'name':            nameCtrl.text.trim(),
        'price_per_kg':    double.tryParse(priceCtrl.text) ?? 0.0,
        'sort_order':      existingCount + 1,
        'active':          true,
      });
      _load();
    }
  }

  Future<void> _editIngredient(Map<String, dynamic> ingredient) async {
    final nameCtrl  = TextEditingController(
        text: ingredient['name'] as String? ?? '');
    final priceCtrl = TextEditingController(
        text: (ingredient['price_per_kg'] as num?)?.toStringAsFixed(2) ?? '0.00');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Ingredient'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Name',
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Price per kg (R)',
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _db
          .from('custom_reward_ingredients')
          .update({
            'name':        nameCtrl.text.trim(),
            'price_per_kg': double.tryParse(priceCtrl.text) ?? 0.0,
          })
          .eq('id', ingredient['id']);
      _load();
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> ingredient) async {
    final current = ingredient['active'] as bool? ?? true;
    await _db
        .from('custom_reward_ingredients')
        .update({'active': !current})
        .eq('id', ingredient['id']);
    _load();
  }

  String _typeLabel(String type) => switch (type) {
    'meat_base'     => 'Meat Base',
    'spice_profile' => 'Spice Profile',
    'spice_addon'   => 'Spice Add-on',
    _               => type,
  };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SizedBox(
        width: 560,
        height: 560,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: const BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(14)),
                border: Border(
                    bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ingredients',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          widget.campaignName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Meat Bases'),
                Tab(text: 'Spice Profiles'),
                Tab(text: 'Spice Add-ons'),
              ],
            ),
            const Divider(height: 1, color: AppColors.border),
            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _IngredientList(
                          items:      _meatBases,
                          type:       'meat_base',
                          onAdd:      () => _addIngredient('meat_base'),
                          onEdit:     _editIngredient,
                          onToggle:   _toggleActive,
                        ),
                        _IngredientList(
                          items:      _profiles,
                          type:       'spice_profile',
                          onAdd:      () => _addIngredient('spice_profile'),
                          onEdit:     _editIngredient,
                          onToggle:   _toggleActive,
                        ),
                        _IngredientList(
                          items:      _addons,
                          type:       'spice_addon',
                          onAdd:      () => _addIngredient('spice_addon'),
                          onEdit:     _editIngredient,
                          onToggle:   _toggleActive,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String type;
  final VoidCallback onAdd;
  final Function(Map<String, dynamic>) onEdit;
  final Function(Map<String, dynamic>) onToggle;

  const _IngredientList({
    required this.items,
    required this.type,
    required this.onAdd,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${items.length} items',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Text(
                    'No items yet. Tap Add to create one.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (_, i) {
                    final item    = items[i];
                    final isActive = item['active'] as bool? ?? true;
                    final price   = (item['price_per_kg'] as num?)
                            ?.toStringAsFixed(2) ??
                        '0.00';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'] as String? ?? '—',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isActive
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                    decoration: isActive
                                        ? null
                                        : TextDecoration.lineThrough,
                                  ),
                                ),
                                Text(
                                  'R$price / kg',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => onEdit(item),
                            child: const Text('Edit'),
                          ),
                          TextButton(
                            onPressed: () => onToggle(item),
                            style: TextButton.styleFrom(
                              foregroundColor: isActive
                                  ? AppColors.error
                                  : AppColors.success,
                            ),
                            child: Text(isActive ? 'Disable' : 'Enable'),
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
