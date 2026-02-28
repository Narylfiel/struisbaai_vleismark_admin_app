import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/services/supabase_service.dart';
import '../models/promotion.dart';
import '../models/promotion_product.dart';
import '../services/promotion_repository.dart';
import '../widgets/product_search_picker.dart';

/// Multi-step form: Basic info → Trigger → Reward → Audience & Channels → Schedule.
class PromotionFormScreen extends StatefulWidget {
  final Promotion? promotion;
  final bool viewOnly;

  const PromotionFormScreen({super.key, this.promotion, this.viewOnly = false});

  @override
  State<PromotionFormScreen> createState() => _PromotionFormScreenState();
}

class _PromotionFormScreenState extends State<PromotionFormScreen> {
  final _repo = PromotionRepository();
  final _client = SupabaseService.client;
  final _formKey = GlobalKey<FormState>();

  int _step = 0;
  bool _saving = false;
  List<Map<String, dynamic>> _inventoryItems = [];
  bool _loadingInventory = true;

  // Step 1
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  PromotionType _promotionType = PromotionType.bogo;
  bool _requiresManualActivation = false;

  // Step 2 — trigger
  final _buyQtyController = TextEditingController(text: '2');
  final _getQtyController = TextEditingController(text: '1');
  List<Map<String, dynamic>> _triggerProducts = [];
  List<Map<String, dynamic>> _rewardProducts = [];
  List<Map<String, dynamic>> _bundleProducts = [];
  List<Map<String, dynamic>> _weightProducts = [];
  List<Map<String, dynamic>> _pointsProducts = [];
  bool _bundleAllRequired = true;
  final _minSpendController = TextEditingController();
  final _minWeightController = TextEditingController();
  List<String> _daysOfWeek = [];
  final _startTimeController = TextEditingController(text: '14:00');
  final _endTimeController = TextEditingController(text: '17:00');
  final _customRuleController = TextEditingController();
  bool _customManualApply = true;
  final _pointsMultiplierController = TextEditingController(text: '3');

  // Step 3 — reward
  String _rewardType = 'free_item';
  final _rewardDiscountPctController = TextEditingController();
  final _rewardDiscountRandController = TextEditingController();
  final _rewardMultiplierController = TextEditingController(text: '3');
  final _voucherValueController = TextEditingController();
  final _partnerNameController = TextEditingController();
  final _partnerCodeController = TextEditingController();
  final _rewardCustomDescController = TextEditingController();

  // Step 4
  List<String> _audience = ['all'];
  List<String> _channels = ['pos'];

  // Step 5
  DateTime? _startDate;
  DateTime? _endDate;
  final _usageLimitController = TextEditingController();

  static const List<String> _audienceOptions = ['all', 'loyalty_bronze', 'loyalty_silver', 'loyalty_gold', 'loyalty_platinum', 'loyalty_elite', 'staff_only', 'new_customers'];
  static const List<String> _channelOptions = ['pos', 'loyalty_app', 'online'];
  static const List<String> _dayOptions = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  @override
  void initState() {
    super.initState();
    if (widget.promotion != null) {
      final p = widget.promotion!;
      _nameController.text = p.name;
      _descController.text = p.description ?? '';
      _promotionType = p.promotionType;
      _requiresManualActivation = p.requiresManualActivation;
      _buyQtyController.text = (p.triggerConfig['buy_quantity'] ?? 2).toString();
      _getQtyController.text = (p.triggerConfig['get_quantity'] ?? 1).toString();
      final triggerIds = p.products.where((e) => e.role == PromotionProductRole.triggerItem).map((e) => e.inventoryItemId).toList();
      final rewardIds = p.products.where((e) => e.role == PromotionProductRole.rewardItem).map((e) => e.inventoryItemId).toList();
      final bundleIds = p.products.where((e) => e.role == PromotionProductRole.bundleItem).map((e) => e.inventoryItemId).toList();
      _loadProductMaps(p.promotionType, triggerIds, rewardIds, bundleIds);
      _bundleAllRequired = p.triggerConfig['all_required'] == true;
      _minSpendController.text = (p.triggerConfig['min_spend'] ?? '').toString();
      _minWeightController.text = (p.triggerConfig['min_weight_kg'] ?? '').toString();
      _daysOfWeek = List.from(p.daysOfWeek);
      _startTimeController.text = p.startTime ?? p.triggerConfig['start_time']?.toString() ?? '14:00';
      _endTimeController.text = p.endTime ?? p.triggerConfig['end_time']?.toString() ?? '17:00';
      _customRuleController.text = p.triggerConfig['custom_rule']?.toString() ?? '';
      _customManualApply = p.triggerConfig['manual_apply'] == true;
      _pointsMultiplierController.text = (p.triggerConfig['multiplier'] ?? 3).toString();
      _rewardType = p.rewardConfig['type'] as String? ?? 'free_item';
      _rewardDiscountPctController.text = (p.rewardConfig['value'] ?? p.rewardConfig['discount_pct'] ?? '').toString();
      _rewardDiscountRandController.text = (p.rewardConfig['value'] ?? '').toString();
      _rewardMultiplierController.text = (p.rewardConfig['multiplier'] ?? 3).toString();
      _voucherValueController.text = (p.rewardConfig['value'] ?? '').toString();
      _partnerNameController.text = p.rewardConfig['partner_name']?.toString() ?? '';
      _partnerCodeController.text = p.rewardConfig['voucher_code']?.toString() ?? '';
      _rewardCustomDescController.text = p.rewardConfig['description']?.toString() ?? '';
      _audience = List.from(p.audience);
      _channels = List.from(p.channels);
      _startDate = p.startDate;
      _endDate = p.endDate;
      _usageLimitController.text = p.usageLimit?.toString() ?? '';
    }
  }

  Future<void> _loadProductMaps(PromotionType type, List<String> triggerIds, List<String> rewardIds, List<String> bundleIds) async {
    final allIds = {...triggerIds, ...rewardIds, ...bundleIds};
    if (allIds.isEmpty) return;
    try {
      final r = await _client
          .from('inventory_items')
          .select('id, name, plu_code, category_id')
          .inFilter('id', allIds.toList());
      final list = List<Map<String, dynamic>>.from(r as List);
      if (!mounted) return;
      setState(() {
        _triggerProducts = list.where((m) => triggerIds.contains(m['id']?.toString())).toList();
        _rewardProducts = list.where((m) => rewardIds.contains(m['id']?.toString())).toList();
        _bundleProducts = list.where((m) => bundleIds.contains(m['id']?.toString())).toList();
        if (type == PromotionType.weightThreshold) {
          _weightProducts = List.from(_triggerProducts);
          _triggerProducts = [];
        } else if (type == PromotionType.pointsMultiplier) {
          _pointsProducts = List.from(_triggerProducts);
          _triggerProducts = [];
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _buyQtyController.dispose();
    _getQtyController.dispose();
    _minSpendController.dispose();
    _minWeightController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _customRuleController.dispose();
    _pointsMultiplierController.dispose();
    _rewardDiscountPctController.dispose();
    _rewardDiscountRandController.dispose();
    _rewardMultiplierController.dispose();
    _voucherValueController.dispose();
    _partnerNameController.dispose();
    _partnerCodeController.dispose();
    _rewardCustomDescController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildTriggerConfig() {
    switch (_promotionType) {
      case PromotionType.bogo:
        return {'buy_quantity': int.tryParse(_buyQtyController.text) ?? 2, 'get_quantity': int.tryParse(_getQtyController.text) ?? 1};
      case PromotionType.bundle:
        return {'all_required': _bundleAllRequired};
      case PromotionType.spendThreshold:
        return {'min_spend': double.tryParse(_minSpendController.text) ?? 0, 'discount_pct': double.tryParse(_rewardDiscountPctController.text)};
      case PromotionType.weightThreshold:
        return {'min_weight_kg': double.tryParse(_minWeightController.text) ?? 0};
      case PromotionType.timeBased:
        return {'happy_hour': true, 'start_time': _startTimeController.text, 'end_time': _endTimeController.text};
      case PromotionType.pointsMultiplier:
        return {'multiplier': int.tryParse(_pointsMultiplierController.text) ?? 3};
      case PromotionType.custom:
        return {'custom_rule': _customRuleController.text.trim(), 'manual_apply': _customManualApply};
    }
  }

  Map<String, dynamic> _buildRewardConfig() {
    switch (_rewardType) {
      case 'free_item':
        final id = _rewardProducts.isNotEmpty ? _rewardProducts.first['id']?.toString() : null;
        return {'type': 'free_item', 'item_id': id, 'quantity': 1};
      case 'discount_pct':
        return {'type': 'discount_pct', 'value': double.tryParse(_rewardDiscountPctController.text) ?? 0};
      case 'discount_rand':
        return {'type': 'discount_rand', 'value': double.tryParse(_rewardDiscountRandController.text) ?? 0};
      case 'points_multiplier':
        return {'type': 'points_multiplier', 'multiplier': int.tryParse(_rewardMultiplierController.text) ?? 3};
      case 'digital_voucher':
        return {'type': 'digital_voucher', 'voucher_type': 'loyalty_reward', 'value': double.tryParse(_voucherValueController.text) ?? 0};
      case 'partner_voucher':
        return {'type': 'partner_voucher', 'partner_name': _partnerNameController.text.trim(), 'voucher_code': _partnerCodeController.text.trim()};
      case 'custom':
        return {'type': 'custom', 'description': _rewardCustomDescController.text.trim()};
      default:
        return {'type': 'free_item'};
    }
  }

  List<PromotionProduct> _buildProducts(String promotionId) {
    final list = <PromotionProduct>[];
    for (final p in _triggerProducts) {
      final id = p['id']?.toString();
      if (id != null) list.add(PromotionProduct(id: '', promotionId: promotionId, inventoryItemId: id, role: PromotionProductRole.triggerItem, quantity: 1));
    }
    for (final p in _rewardProducts) {
      final id = p['id']?.toString();
      if (id != null) list.add(PromotionProduct(id: '', promotionId: promotionId, inventoryItemId: id, role: PromotionProductRole.rewardItem, quantity: 1));
    }
    for (final p in _bundleProducts) {
      final id = p['id']?.toString();
      if (id != null) list.add(PromotionProduct(id: '', promotionId: promotionId, inventoryItemId: id, role: PromotionProductRole.bundleItem, quantity: 1));
    }
    for (final p in _weightProducts) {
      final id = p['id']?.toString();
      if (id != null) list.add(PromotionProduct(id: '', promotionId: promotionId, inventoryItemId: id, role: PromotionProductRole.triggerItem, quantity: 1));
    }
    for (final p in _pointsProducts) {
      final id = p['id']?.toString();
      if (id != null) list.add(PromotionProduct(id: '', promotionId: promotionId, inventoryItemId: id, role: PromotionProductRole.triggerItem, quantity: 1));
    }
    return list;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    setState(() => _saving = true);
    try {
      final promo = Promotion(
        id: widget.promotion?.id ?? '',
        name: _nameController.text.trim(),
        description: _descController.text.isEmpty ? null : _descController.text.trim(),
        status: widget.promotion?.status ?? PromotionStatus.draft,
        promotionType: _promotionType,
        triggerConfig: _buildTriggerConfig(),
        rewardConfig: _buildRewardConfig(),
        audience: _audience,
        channels: _channels,
        startDate: _startDate,
        endDate: _endDate,
        startTime: _startTimeController.text.isEmpty ? null : _startTimeController.text,
        endTime: _endTimeController.text.isEmpty ? null : _endTimeController.text,
        daysOfWeek: _daysOfWeek,
        usageLimit: int.tryParse(_usageLimitController.text),
        usageCount: widget.promotion?.usageCount ?? 0,
        requiresManualActivation: _requiresManualActivation,
      );
      final products = _buildProducts(promo.id);
      Promotion created;
      if (widget.promotion != null && widget.promotion!.id.isNotEmpty) {
        created = await _repo.update(promo, products);
      } else {
        created = await _repo.create(promo, products);
      }
      if (mounted) {
        Navigator.of(context).pop(created);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promotion saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.friendlyMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(widget.viewOnly ? 'View Promotion' : (widget.promotion == null ? 'New Promotion' : 'Edit Promotion')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _step,
          onStepContinue: () {
            if (_step < 4) setState(() => _step++);
            else _save();
          },
          onStepCancel: () {
            if (_step > 0) setState(() => _step--);
            else Navigator.of(context).pop();
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  ElevatedButton(onPressed: _saving ? null : details.onStepContinue, child: Text(_step == 4 ? 'Save' : 'Next')),
                  const SizedBox(width: 12),
                  TextButton(onPressed: details.onStepCancel, child: Text(_step == 0 ? 'Cancel' : 'Back')),
                ],
              ),
            );
          },
          steps: [
            Step(title: const Text('Basic info'), content: _buildStep1(), isActive: _step >= 0, state: _step > 0 ? StepState.complete : StepState.indexed),
            Step(title: const Text('Trigger'), content: _buildStep2(), isActive: _step >= 1, state: _step > 1 ? StepState.complete : StepState.indexed),
            Step(title: const Text('Reward'), content: _buildStep3(), isActive: _step >= 2, state: _step > 2 ? StepState.complete : StepState.indexed),
            Step(title: const Text('Audience & Channels'), content: _buildStep4(), isActive: _step >= 3, state: _step > 3 ? StepState.complete : StepState.indexed),
            Step(title: const Text('Schedule'), content: _buildStep5(), isActive: _step >= 4, state: StepState.indexed),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name *'),
            readOnly: widget.viewOnly,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descController,
            decoration: const InputDecoration(labelText: 'Description (optional)'),
            maxLines: 2,
            readOnly: widget.viewOnly,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<PromotionType>(
            value: _promotionType,
            decoration: const InputDecoration(labelText: 'Promotion type'),
            items: PromotionType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.dbValue.replaceAll('_', ' ')))).toList(),
            onChanged: widget.viewOnly ? null : (v) => setState(() => _promotionType = v!),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Require manual activation by staff at POS'),
            value: _requiresManualActivation,
            onChanged: widget.viewOnly ? null : (v) => setState(() => _requiresManualActivation = v),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    if (_promotionType == PromotionType.bogo) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox(width: 80, child: TextFormField(controller: _buyQtyController, decoration: const InputDecoration(labelText: 'Buy'), keyboardType: TextInputType.number, readOnly: widget.viewOnly)),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('get')),
                SizedBox(width: 80, child: TextFormField(controller: _getQtyController, decoration: const InputDecoration(labelText: 'Get free'), keyboardType: TextInputType.number, readOnly: widget.viewOnly)),
              ],
            ),
            const SizedBox(height: 16),
            ProductSearchPicker(
              label: 'Trigger products (buy these)',
              selectedProducts: _triggerProducts,
              onAdd: (p) => setState(() => _triggerProducts = [..._triggerProducts, p]),
              onRemove: (id) => setState(() => _triggerProducts = _triggerProducts.where((x) => x['id']?.toString() != id).toList()),
              readOnly: widget.viewOnly,
            ),
            const SizedBox(height: 16),
            ProductSearchPicker(
              label: 'Reward product (free)',
              selectedProducts: _rewardProducts,
              onAdd: (p) => setState(() => _rewardProducts = [p]),
              onRemove: (_) => setState(() => _rewardProducts = []),
              singleSelect: true,
              readOnly: widget.viewOnly,
            ),
          ],
        ),
      );
    }
    if (_promotionType == PromotionType.bundle) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              title: const Text('All products required in basket'),
              value: _bundleAllRequired,
              onChanged: widget.viewOnly ? null : (v) => setState(() => _bundleAllRequired = v!),
            ),
            ProductSearchPicker(
              label: 'Bundle products',
              selectedProducts: _bundleProducts,
              onAdd: (p) => setState(() => _bundleProducts = [..._bundleProducts, p]),
              onRemove: (id) => setState(() => _bundleProducts = _bundleProducts.where((x) => x['id']?.toString() != id).toList()),
              readOnly: widget.viewOnly,
            ),
          ],
        ),
      );
    }
    if (_promotionType == PromotionType.spendThreshold) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _minSpendController,
              decoration: const InputDecoration(labelText: 'Minimum spend (R)'),
              keyboardType: TextInputType.number,
              readOnly: widget.viewOnly,
            ),
          ],
        ),
      );
    }
    if (_promotionType == PromotionType.weightThreshold) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _minWeightController,
              decoration: const InputDecoration(labelText: 'Minimum weight (kg)'),
              keyboardType: TextInputType.number,
              readOnly: widget.viewOnly,
            ),
            const SizedBox(height: 16),
            ProductSearchPicker(
              label: 'Products / category filter',
              selectedProducts: _weightProducts,
              onAdd: (p) => setState(() => _weightProducts = [..._weightProducts, p]),
              onRemove: (id) => setState(() => _weightProducts = _weightProducts.where((x) => x['id']?.toString() != id).toList()),
              readOnly: widget.viewOnly,
            ),
          ],
        ),
      );
    }
    if (_promotionType == PromotionType.timeBased) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Days of week', style: TextStyle(fontWeight: FontWeight.w500)),
            Wrap(
              spacing: 8,
              children: _dayOptions.map((d) => FilterChip(
                label: Text(d.toUpperCase().substring(0, 2)),
                selected: _daysOfWeek.contains(d),
                onSelected: widget.viewOnly ? null : (v) => setState(() {
                  if (v) _daysOfWeek.add(d); else _daysOfWeek.remove(d);
                }),
              )).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(controller: _startTimeController, decoration: const InputDecoration(labelText: 'Start time (HH:mm)'), readOnly: widget.viewOnly),
            const SizedBox(height: 8),
            TextFormField(controller: _endTimeController, decoration: const InputDecoration(labelText: 'End time (HH:mm)'), readOnly: widget.viewOnly),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: widget.viewOnly ? null : () => setState(() { _startTimeController.text = '14:00'; _endTimeController.text = '17:00'; _daysOfWeek = ['mon','tue','wed','thu','fri']; }),
              icon: const Icon(Icons.schedule),
              label: const Text('Happy hour (14:00–17:00 Mon–Fri)'),
            ),
          ],
        ),
      );
    }
    if (_promotionType == PromotionType.pointsMultiplier) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _pointsMultiplierController,
              decoration: const InputDecoration(labelText: 'Multiplier (e.g. 3x points)'),
              keyboardType: TextInputType.number,
              readOnly: widget.viewOnly,
            ),
            const SizedBox(height: 16),
            ProductSearchPicker(
              label: 'Products / category filter',
              selectedProducts: _pointsProducts,
              onAdd: (p) => setState(() => _pointsProducts = [..._pointsProducts, p]),
              onRemove: (id) => setState(() => _pointsProducts = _pointsProducts.where((x) => x['id']?.toString() != id).toList()),
              readOnly: widget.viewOnly,
            ),
          ],
        ),
      );
    }
    // custom
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _customRuleController,
            decoration: const InputDecoration(labelText: 'Describe the custom rule'),
            maxLines: 2,
            readOnly: widget.viewOnly,
          ),
          SwitchListTile(
            title: const Text('Staff must manually apply at POS'),
            value: _customManualApply,
            onChanged: widget.viewOnly ? null : (v) => setState(() => _customManualApply = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: _rewardType,
            decoration: const InputDecoration(labelText: 'Reward type'),
            items: ['free_item', 'discount_pct', 'discount_rand', 'points_multiplier', 'digital_voucher', 'partner_voucher', 'custom']
                .map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ')))).toList(),
            onChanged: widget.viewOnly ? null : (v) => setState(() => _rewardType = v!),
          ),
          if (_rewardType == 'free_item') ...[
            const SizedBox(height: 16),
            ProductSearchPicker(
              label: 'Free product',
              selectedProducts: _rewardProducts,
              onAdd: (p) => setState(() => _rewardProducts = [p]),
              onRemove: (_) => setState(() => _rewardProducts = []),
              singleSelect: true,
              readOnly: widget.viewOnly,
            ),
          ],
          if (_rewardType == 'discount_pct') ...[
            const SizedBox(height: 16),
            TextFormField(controller: _rewardDiscountPctController, decoration: const InputDecoration(labelText: 'Percentage'), keyboardType: TextInputType.number, readOnly: widget.viewOnly),
          ],
          if (_rewardType == 'discount_rand') ...[
            const SizedBox(height: 16),
            TextFormField(controller: _rewardDiscountRandController, decoration: const InputDecoration(labelText: 'Amount (R)'), keyboardType: TextInputType.number, readOnly: widget.viewOnly),
          ],
          if (_rewardType == 'points_multiplier') ...[
            const SizedBox(height: 16),
            TextFormField(controller: _rewardMultiplierController, decoration: const InputDecoration(labelText: 'Multiplier'), keyboardType: TextInputType.number, readOnly: widget.viewOnly),
          ],
          if (_rewardType == 'digital_voucher') ...[
            const SizedBox(height: 16),
            TextFormField(controller: _voucherValueController, decoration: const InputDecoration(labelText: 'Voucher value'), keyboardType: TextInputType.number, readOnly: widget.viewOnly),
          ],
          if (_rewardType == 'partner_voucher') ...[
            const SizedBox(height: 16),
            TextFormField(controller: _partnerNameController, decoration: const InputDecoration(labelText: 'Partner name'), readOnly: widget.viewOnly),
            TextFormField(controller: _partnerCodeController, decoration: const InputDecoration(labelText: 'Voucher code template'), readOnly: widget.viewOnly),
          ],
          if (_rewardType == 'custom') ...[
            const SizedBox(height: 16),
            TextFormField(controller: _rewardCustomDescController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2, readOnly: widget.viewOnly),
          ],
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Audience', style: TextStyle(fontWeight: FontWeight.w500)),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _audienceOptions.map((a) {
              final label = a == 'all' ? 'All Customers' : a.replaceFirst('loyalty_', 'Loyalty ').replaceAll('_', ' ');
              return FilterChip(
                label: Text(label),
                selected: _audience.contains(a),
                onSelected: widget.viewOnly ? null : (v) => setState(() {
                  if (v) _audience.add(a); else _audience.remove(a);
                  if (_audience.isEmpty) _audience = ['all'];
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text('Channels', style: TextStyle(fontWeight: FontWeight.w500)),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _channelOptions.map((c) => FilterChip(
              label: Text(c == 'pos' ? 'POS' : c == 'loyalty_app' ? 'Loyalty App' : 'Online'),
              selected: _channels.contains(c),
              onSelected: widget.viewOnly ? null : (v) => setState(() {
                if (v) _channels.add(c); else _channels.remove(c);
                if (_channels.isEmpty) _channels = ['pos'];
              }),
            )).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Online Orders channel will apply when online ordering is added in future.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildStep5() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(_startDate == null ? 'Start date (optional)' : 'Start: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: widget.viewOnly ? null : () async {
              final d = await showDatePicker(context: context, initialDate: _startDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
              if (d != null) setState(() => _startDate = d);
            },
          ),
          ListTile(
            title: Text(_endDate == null ? 'End date (optional)' : 'End: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: widget.viewOnly ? null : () async {
              final d = await showDatePicker(context: context, initialDate: _endDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
              if (d != null) setState(() => _endDate = d);
            },
          ),
          TextFormField(
            controller: _usageLimitController,
            decoration: const InputDecoration(labelText: 'Usage limit (optional, total uses)'),
            keyboardType: TextInputType.number,
            readOnly: widget.viewOnly,
          ),
          const SizedBox(height: 24),
          const Text('Summary', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Name: ${_nameController.text}'),
          Text('Type: ${_promotionType.dbValue}'),
          Text('Reward: ${_rewardType}'),
          Text('Audience: ${_audience.join(", ")}'),
          Text('Channels: ${_channels.join(", ")}'),
          if (_startDate != null) Text('Start: $_startDate'),
          if (_endDate != null) Text('End: $_endDate'),
        ],
      ),
    );
  }
}
