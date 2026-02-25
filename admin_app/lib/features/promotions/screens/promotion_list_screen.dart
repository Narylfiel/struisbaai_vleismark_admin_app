import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/promotion.dart';
import '../models/promotion_product.dart';
import '../services/promotion_repository.dart';
import 'promotion_form_screen.dart';

class PromotionListScreen extends StatefulWidget {
  const PromotionListScreen({super.key});

  @override
  State<PromotionListScreen> createState() => _PromotionListScreenState();
}

class _PromotionListScreenState extends State<PromotionListScreen> with SingleTickerProviderStateMixin {
  final PromotionRepository _repo = PromotionRepository();
  late TabController _tabController;
  List<Promotion> _all = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.getAll();
      if (mounted) setState(() {
        _all = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Promotion> _filterByTab(int index) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (index) {
      case 0:
        return _all;
      case 1:
        return _all.where((p) => p.status == PromotionStatus.active && (p.endDate == null || !p.endDate!.isBefore(today))).toList();
      case 2:
        return _all.where((p) => p.status == PromotionStatus.draft).toList();
      case 3:
        return _all.where((p) {
          if (p.startDate == null) return false;
          return p.startDate!.isAfter(today);
        }).toList();
      case 4:
        return _all.where((p) => p.displayStatus == 'Expired' || p.status == PromotionStatus.expired || p.status == PromotionStatus.cancelled).toList();
      default:
        return _all;
    }
  }

  Color _typeColor(PromotionType t) {
    switch (t) {
      case PromotionType.bogo: return AppColors.catBeef;
      case PromotionType.bundle: return AppColors.catPork;
      case PromotionType.spendThreshold: return AppColors.catChicken;
      case PromotionType.weightThreshold: return AppColors.catLamb;
      case PromotionType.timeBased: return AppColors.catDrinks;
      case PromotionType.pointsMultiplier: return AppColors.catSpices;
      case PromotionType.custom: return AppColors.catOther;
    }
  }

  Color _statusColor(Promotion p) {
    if (p.displayStatus == 'Expired') return AppColors.error;
    switch (p.status) {
      case PromotionStatus.active: return AppColors.success;
      case PromotionStatus.draft: return AppColors.textSecondary;
      case PromotionStatus.paused: return AppColors.warning;
      case PromotionStatus.cancelled: return AppColors.error;
      case PromotionStatus.expired: return AppColors.error;
    }
  }

  String _typeLabel(PromotionType t) {
    switch (t) {
      case PromotionType.bogo: return 'BOGO';
      case PromotionType.bundle: return 'Bundle';
      case PromotionType.spendThreshold: return 'Spend';
      case PromotionType.weightThreshold: return 'Weight';
      case PromotionType.timeBased: return 'Time';
      case PromotionType.pointsMultiplier: return 'Points';
      case PromotionType.custom: return 'Custom';
    }
  }

  String _rewardSummary(Promotion p) {
    final type = p.rewardConfig['type'] as String?;
    if (type == 'discount_pct') return '${p.rewardConfig['value'] ?? 0}% off';
    if (type == 'discount_rand') return 'R${p.rewardConfig['value'] ?? 0} off';
    if (type == 'free_item') return 'Free item';
    if (type == 'points_multiplier') return '${p.rewardConfig['multiplier'] ?? 1}x points';
    if (p.promotionType == PromotionType.bogo) {
      final buy = p.triggerConfig['buy_quantity'] ?? 2;
      final get = p.triggerConfig['get_quantity'] ?? 1;
      return 'Buy $buy Get $get Free';
    }
    return 'Reward';
  }

  String _audienceLabel(String a) {
    if (a == 'all') return 'All Customers';
    if (a.startsWith('loyalty_')) return 'Loyalty: ${a.replaceFirst('loyalty_', '').toUpperCase()}';
    if (a == 'staff_only') return 'Staff only';
    if (a == 'new_customers') return 'New customers';
    return a;
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
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Active'),
                Tab(text: 'Draft'),
                Tab(text: 'Scheduled'),
                Tab(text: 'Expired'),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!, style: const TextStyle(color: AppColors.error)),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _load, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: List.generate(5, (i) => _buildList(_filterByTab(i))),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(context).push<Promotion>(
            MaterialPageRoute(builder: (_) => const PromotionFormScreen()),
          );
          if (created != null) _load();
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList(List<Promotion> list) {
    if (list.isEmpty) {
      return const Center(child: Text('No promotions in this tab', style: TextStyle(color: AppColors.textSecondary)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final p = list[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      ),
                      Chip(
                        label: Text(_typeLabel(p.promotionType), style: const TextStyle(fontSize: 11)),
                        backgroundColor: _typeColor(p.promotionType).withValues(alpha: 0.2),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(p.displayStatus, style: const TextStyle(fontSize: 11)),
                        backgroundColor: _statusColor(p).withValues(alpha: 0.2),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  if (p.audience.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: p.audience.take(3).map((a) => Chip(
                        label: Text(_audienceLabel(a), style: const TextStyle(fontSize: 10)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (p.channels.contains('pos')) const Icon(Icons.point_of_sale, size: 16, color: AppColors.textSecondary),
                      if (p.channels.contains('loyalty_app')) Padding(padding: const EdgeInsets.only(left: 4), child: const Icon(Icons.phone_android, size: 16, color: AppColors.textSecondary)),
                      if (p.channels.contains('online')) Padding(padding: const EdgeInsets.only(left: 4), child: const Icon(Icons.shopping_cart, size: 16, color: AppColors.textSecondary)),
                      const SizedBox(width: 12),
                      if (p.startDate != null || p.endDate != null)
                        Text(
                          '${p.startDate != null ? _fmtDate(p.startDate!) : '…'} – ${p.endDate != null ? _fmtDate(p.endDate!) : '…'}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      if (p.startTime != null && p.endTime != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text('${p.startTime} – ${p.endTime}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ),
                    ],
                  ),
                  if (p.usageLimit != null) ...[
                    const SizedBox(height: 4),
                    Text('Used ${p.usageCount} / ${p.usageLimit} times', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: 8),
                  Text(_rewardSummary(p), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  _buildActions(p),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.day} ${_month(d.month)}';

  String _month(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }

  Widget _buildActions(Promotion p) {
    final isDraft = p.status == PromotionStatus.draft;
    final isActive = p.status == PromotionStatus.active;
    final isPaused = p.status == PromotionStatus.paused;
    final isExpiredOrCancelled = p.displayStatus == 'Expired' || p.status == PromotionStatus.cancelled;

    if (isDraft) {
      return Row(
        children: [
          TextButton.icon(onPressed: () => _openForm(p), icon: const Icon(Icons.edit, size: 18), label: const Text('Edit')),
          TextButton.icon(onPressed: () => _activate(p.id), icon: const Icon(Icons.play_arrow, size: 18), label: const Text('Activate')),
          TextButton.icon(onPressed: () => _confirmDelete(p), icon: const Icon(Icons.delete, size: 18), label: const Text('Delete')),
        ],
      );
    }
    if (isActive) {
      return Row(
        children: [
          TextButton.icon(onPressed: () => _openForm(p), icon: const Icon(Icons.edit, size: 18), label: const Text('Edit')),
          TextButton.icon(onPressed: () => _pause(p.id), icon: const Icon(Icons.pause, size: 18), label: const Text('Pause')),
          TextButton.icon(onPressed: () => _cancel(p.id), icon: const Icon(Icons.cancel, size: 18), label: const Text('Cancel')),
        ],
      );
    }
    if (isPaused) {
      return Row(
        children: [
          TextButton.icon(onPressed: () => _openForm(p), icon: const Icon(Icons.edit, size: 18), label: const Text('Edit')),
          TextButton.icon(onPressed: () => _activate(p.id), icon: const Icon(Icons.play_arrow, size: 18), label: const Text('Activate')),
          TextButton.icon(onPressed: () => _cancel(p.id), icon: const Icon(Icons.cancel, size: 18), label: const Text('Cancel')),
        ],
      );
    }
    if (isExpiredOrCancelled) {
      return Row(
        children: [
          TextButton.icon(onPressed: () => _openForm(p, viewOnly: true), icon: const Icon(Icons.visibility, size: 18), label: const Text('View')),
          TextButton.icon(onPressed: () => _duplicate(p), icon: const Icon(Icons.copy, size: 18), label: const Text('Duplicate')),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _openForm(Promotion? p, {bool viewOnly = false}) async {
    final result = await Navigator.of(context).push<Promotion>(
      MaterialPageRoute(builder: (_) => PromotionFormScreen(promotion: p, viewOnly: viewOnly)),
    );
    if (result != null) _load();
  }

  Future<void> _activate(String id) async {
    try {
      await _repo.activate(id);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promotion activated')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _pause(String id) async {
    try {
      await _repo.pause(id);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promotion paused')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _cancel(String id) async {
    try {
      await _repo.cancel(id);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promotion cancelled')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _confirmDelete(Promotion p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete promotion?'),
        content: Text('Delete "${p.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.delete(p.id);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promotion deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _duplicate(Promotion p) async {
    final copy = Promotion(
      id: '',
      name: '${p.name} (copy)',
      description: p.description,
      status: PromotionStatus.draft,
      promotionType: p.promotionType,
      triggerConfig: Map.from(p.triggerConfig),
      rewardConfig: Map.from(p.rewardConfig),
      audience: List.from(p.audience),
      channels: List.from(p.channels),
      startDate: p.startDate,
      endDate: p.endDate,
      startTime: p.startTime,
      endTime: p.endTime,
      daysOfWeek: List.from(p.daysOfWeek),
      usageLimit: p.usageLimit,
      usageCount: 0,
      requiresManualActivation: p.requiresManualActivation,
    );
    final products = p.products.map((e) => PromotionProduct(
      id: '',
      promotionId: '',
      inventoryItemId: e.inventoryItemId,
      role: e.role,
      quantity: e.quantity,
    )).toList();
    try {
      await _repo.create(copy, products);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promotion duplicated')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
