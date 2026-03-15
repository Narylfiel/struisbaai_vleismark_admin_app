import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../models/promotion.dart';
import '../models/promotion_product.dart';
import '../services/promotion_repository.dart';
import '../widgets/product_search_picker.dart';

class PromotionFormScreen extends StatefulWidget {
  final Promotion? promotion;
  final bool viewOnly;
  const PromotionFormScreen(
      {super.key, this.promotion, this.viewOnly = false});
  @override
  State<PromotionFormScreen> createState() =>
      _PromotionFormScreenState();
}

class _PromotionFormScreenState
    extends State<PromotionFormScreen> {
  final _repo = PromotionRepository();
  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  bool _saving = false;

  // ── Step 1: Basic ──────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _promoType = 'weekly_special';
  // promoType values:
  // weekly_special | buy_x_get_y | spend_reward |
  // points_multiplier | birthday_reward | early_access

  // ── Step 2: Trigger ────────────────────────────────
  // weekly_special
  List<Map<String, dynamic>> _specialProducts = [];
  String _discountMode = 'rand'; // 'rand' or 'pct'
  final _discountValueCtrl = TextEditingController();

  // buy_x_get_y
  List<Map<String, dynamic>> _buyProducts = [];
  List<Map<String, dynamic>> _getProducts = [];
  final _buyQtyCtrl = TextEditingController(text: '2');
  final _getQtyCtrl = TextEditingController(text: '1');
  final _getWeightCtrl = TextEditingController();
  String _getMode = 'qty'; // 'qty' or 'weight'

  // spend_reward
  final _minSpendCtrl = TextEditingController(text: '500');
  String _spendRewardType = 'points';
  // 'points' | 'free_product' | 'discount_pct' | 'discount_rand'
  final _spendRewardValueCtrl = TextEditingController();
  List<Map<String, dynamic>> _spendRewardProducts = [];

  // points_multiplier
  List<Map<String, dynamic>> _multiplierProducts = [];
  final _multiplierCtrl = TextEditingController(text: '2');

  // birthday_reward — no products needed, owner sets per customer
  String _birthdayRewardType = 'free_product';
  final _birthdayValueCtrl = TextEditingController();
  List<Map<String, dynamic>> _birthdayProducts = [];

  // ── Step 3: Audience & Schedule ────────────────────
  List<String> _audience = ['all'];
  DateTime? _startDate;
  DateTime? _endDate;
  bool _earlyAccessEnabled = false;
  int _earlyAccessHours = 24;

  // ── Margin warning state ───────────────────────────
  double? _calculatedMarginPct;
  bool _marginWarning = false;
  List<Map<String, dynamic>> _slowMovers = [];
  bool _loadingSlowMovers = false;

  static const _audienceOptions = [
    'all', 'bronze', 'silver', 'gold', 'elite', 'vip',
  ];

  static const _promoTypes = [
    ('weekly_special',    '🥩 Weekly Special'),
    ('buy_x_get_y',       '🎁 Buy X Get Y Free'),
    ('spend_reward',      '💳 Spend & Earn'),
    ('points_multiplier', '⭐ Double/Triple Points'),
    ('birthday_reward',   '🎂 Birthday Reward'),
    ('early_access',      '🔓 Early Access (VIP/Elite)'),
  ];

  @override
  void initState() {
    super.initState();
    _loadSlowMovers();
    if (widget.promotion != null) _populateFromExisting();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _discountValueCtrl.dispose();
    _buyQtyCtrl.dispose();
    _getQtyCtrl.dispose();
    _getWeightCtrl.dispose();
    _minSpendCtrl.dispose();
    _spendRewardValueCtrl.dispose();
    _multiplierCtrl.dispose();
    _birthdayValueCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSlowMovers() async {
    setState(() => _loadingSlowMovers = true);
    try {
      final client = SupabaseService.client;
      // Slow movers: active products where current_stock
      // is above reorder level but haven't moved
      // (use stock > 0 AND slow_mover flag if available,
      // else top 10 highest stock items)
      final res = await client
          .from('inventory_items')
          .select('id, name, current_stock, sell_price, '
              'cost_price, target_margin_pct, plu_code')
          .eq('is_active', true)
          .gt('current_stock', 0)
          .order('current_stock', ascending: false)
          .limit(10);
      if (mounted) {
        setState(() {
          _slowMovers =
              List<Map<String, dynamic>>.from(res as List);
          _loadingSlowMovers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSlowMovers = false);
    }
  }

  void _populateFromExisting() {
    final p = widget.promotion!;
    _nameCtrl.text = p.name;
    _descCtrl.text = p.description ?? '';
    _audience = List.from(p.audience);
    _startDate = p.startDate;
    _endDate = p.endDate;
    final tc = p.triggerConfig;
    final rc = p.rewardConfig;
    switch (p.promotionType.dbValue) {
      case 'spend_threshold':
        _promoType = 'spend_reward';
        _minSpendCtrl.text =
            (tc['min_spend'] ?? 500).toString();
        _spendRewardType = rc['type'] ?? 'points';
        _spendRewardValueCtrl.text =
            (rc['value'] ?? '').toString();
        break;
      case 'bogo':
        _promoType = 'buy_x_get_y';
        _buyQtyCtrl.text =
            (tc['buy_quantity'] ?? 2).toString();
        _getQtyCtrl.text =
            (tc['get_quantity'] ?? 1).toString();
        break;
      case 'points_multiplier':
        _promoType = 'points_multiplier';
        _multiplierCtrl.text =
            (tc['multiplier'] ?? 2).toString();
        break;
      default:
        _promoType = 'weekly_special';
        _discountMode =
            rc['discount_mode'] ?? 'rand';
        _discountValueCtrl.text =
            (rc['value'] ?? '').toString();
    }
  }

  void _recalcMargin() {
    if (_promoType != 'weekly_special' &&
        _promoType != 'buy_x_get_y') {
      setState(() {
        _calculatedMarginPct = null;
        _marginWarning = false;
      });
      return;
    }
    final products = _promoType == 'weekly_special'
        ? _specialProducts
        : _buyProducts;
    if (products.isEmpty) return;

    final product = products.first;
    final sell =
        (product['sell_price'] as num?)?.toDouble() ?? 0;
    final cost =
        (product['cost_price'] as num?)?.toDouble() ??
            (product['average_cost'] as num?)?.toDouble() ??
            0;
    if (sell == 0 || cost == 0) return;

    double netPrice = sell;
    if (_promoType == 'weekly_special') {
      final val = double.tryParse(
              _discountValueCtrl.text) ??
          0;
      if (_discountMode == 'rand') {
        netPrice = sell - val;
      } else {
        netPrice = sell * (1 - val / 100);
      }
    }

    if (netPrice <= 0) {
      setState(() {
        _calculatedMarginPct = 0;
        _marginWarning = true;
      });
      return;
    }

    final margin = ((netPrice - cost) / netPrice) * 100;
    final targetMargin =
        (product['target_margin_pct'] as num?)
                ?.toDouble() ??
            20.0;

    setState(() {
      _calculatedMarginPct = margin;
      _marginWarning = margin < targetMargin;
    });
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please enter a promotion name in Step 1')));
      setState(() => _step = 0);
      return;
    }
    if (_marginWarning) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('⚠️ Margin Warning'),
          content: Text(
            'This promotion drops margin to '
            '${_calculatedMarginPct?.toStringAsFixed(1)}%'
            ' which is below your target.\n\n'
            'Do you want to save anyway?',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save Anyway')),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _saving = true);
    try {
      final promo = _buildPromotion();
      final products = _buildProducts(promo.id);
      Promotion result;
      if (widget.promotion?.id.isNotEmpty == true) {
        result = await _repo.update(promo, products);
      } else {
        result = await _repo.create(promo, products);
      }
      if (mounted) {
        Navigator.of(context).pop(result);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Promotion saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Promotion _buildPromotion() {
    Map<String, dynamic> trigger = {};
    Map<String, dynamic> reward = {};
    PromotionType type = PromotionType.custom;

    switch (_promoType) {
      case 'weekly_special':
        type = PromotionType.spendThreshold;
        trigger = {};
        reward = {
          'type': _discountMode == 'rand'
              ? 'discount_rand'
              : 'discount_pct',
          'discount_mode': _discountMode,
          'value': double.tryParse(
                  _discountValueCtrl.text) ??
              0,
        };
        break;
      case 'buy_x_get_y':
        type = PromotionType.bogo;
        trigger = {
          'buy_quantity':
              int.tryParse(_buyQtyCtrl.text) ?? 2,
          'get_quantity':
              int.tryParse(_getQtyCtrl.text) ?? 1,
          'get_mode': _getMode,
          'get_weight_kg': _getMode == 'weight'
              ? double.tryParse(_getWeightCtrl.text)
              : null,
        };
        reward = {'type': 'free_item'};
        break;
      case 'spend_reward':
        type = PromotionType.spendThreshold;
        trigger = {
          'min_spend':
              double.tryParse(_minSpendCtrl.text) ??
                  500,
        };
        reward = {
          'type': _spendRewardType,
          'value': double.tryParse(
                  _spendRewardValueCtrl.text) ??
              0,
        };
        break;
      case 'points_multiplier':
        type = PromotionType.pointsMultiplier;
        trigger = {
          'multiplier':
              int.tryParse(_multiplierCtrl.text) ?? 2,
        };
        reward = {
          'type': 'points_multiplier',
          'multiplier':
              int.tryParse(_multiplierCtrl.text) ?? 2,
        };
        break;
      case 'birthday_reward':
        type = PromotionType.custom;
        trigger = {'birthday': true};
        reward = {
          'type': _birthdayRewardType,
          'value': double.tryParse(
                  _birthdayValueCtrl.text) ??
              0,
        };
        break;
      case 'early_access':
        type = PromotionType.timeBased;
        trigger = {
          'early_access': true,
          'hours_before': _earlyAccessHours,
        };
        reward = {'type': 'early_access'};
        break;
    }

    return Promotion(
      id: widget.promotion?.id ?? '',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.isEmpty
          ? null
          : _descCtrl.text.trim(),
      status: widget.promotion?.status ??
          PromotionStatus.draft,
      promotionType: type,
      triggerConfig: trigger,
      rewardConfig: reward,
      audience: _audience,
      channels: const ['loyalty_app'],
      startDate: _startDate,
      endDate: _endDate,
      usageCount:
          widget.promotion?.usageCount ?? 0,
    );
  }

  List<PromotionProduct> _buildProducts(
      String promotionId) {
    final list = <PromotionProduct>[];
    void add(List<Map<String, dynamic>> items,
        PromotionProductRole role) {
      for (final p in items) {
        final id = p['id']?.toString();
        if (id != null) {
          list.add(PromotionProduct(
            id: '',
            promotionId: promotionId,
            inventoryItemId: id,
            role: role,
            quantity: 1,
          ));
        }
      }
    }

    switch (_promoType) {
      case 'weekly_special':
        add(_specialProducts,
            PromotionProductRole.triggerItem);
        break;
      case 'buy_x_get_y':
        add(_buyProducts,
            PromotionProductRole.triggerItem);
        add(_getProducts,
            PromotionProductRole.rewardItem);
        break;
      case 'spend_reward':
        add(_spendRewardProducts,
            PromotionProductRole.rewardItem);
        break;
      case 'points_multiplier':
        add(_multiplierProducts,
            PromotionProductRole.triggerItem);
        break;
      case 'birthday_reward':
        add(_birthdayProducts,
            PromotionProductRole.rewardItem);
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(widget.viewOnly
            ? 'View Promotion'
            : widget.promotion == null
                ? 'New Promotion'
                : 'Edit Promotion'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _step,
          onStepContinue: () {
            if (_step < 2)
              setState(() => _step++);
            else
              _save();
          },
          onStepCancel: () {
            if (_step > 0)
              setState(() => _step--);
            else
              Navigator.of(context).pop();
          },
          controlsBuilder: (ctx, details) => Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(children: [
              ElevatedButton(
                  onPressed:
                      _saving ? null : details.onStepContinue,
                  child: Text(
                      _step == 2 ? 'Save' : 'Next')),
              const SizedBox(width: 12),
              TextButton(
                  onPressed: details.onStepCancel,
                  child: Text(
                      _step == 0 ? 'Cancel' : 'Back')),
            ]),
          ),
          steps: [
            Step(
                title: const Text('Promotion type'),
                content: _buildStep1(),
                isActive: _step >= 0,
                state: _step > 0
                    ? StepState.complete
                    : StepState.indexed),
            Step(
                title: const Text('Details & products'),
                content: _buildStep2(),
                isActive: _step >= 1,
                state: _step > 1
                    ? StepState.complete
                    : StepState.indexed),
            Step(
                title: const Text('Audience & schedule'),
                content: _buildStep3(),
                isActive: _step >= 2,
                state: StepState.indexed),
          ],
        ),
      ),
    );
  }

  // ── STEP 1: Choose type ─────────────────────────────
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Slow movers suggestion panel
        if (_slowMovers.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Colors.amber.withValues(
                      alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.auto_awesome,
                      size: 16, color: Colors.amber),
                  SizedBox(width: 6),
                  Text('Smart suggestions',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ]),
                const SizedBox(height: 6),
                const Text(
                  'These products have high stock — '
                  'consider featuring them in a promotion:',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.black54),
                ),
                const SizedBox(height: 8),
                ..._slowMovers.take(3).map((item) {
                  final name =
                      item['name'] as String? ?? '';
                  final stock =
                      (item['current_stock'] as num?)
                              ?.toDouble() ??
                          0;
                  final sell =
                      (item['sell_price'] as num?)
                              ?.toDouble() ??
                          0;
                  final cost =
                      (item['cost_price'] as num?)
                              ?.toDouble() ??
                          0;
                  final margin = sell > 0 && cost > 0
                      ? ((sell - cost) / sell * 100)
                      : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(
                        bottom: 4),
                    child: Row(children: [
                      const Icon(Icons.inventory_2,
                          size: 14,
                          color: Colors.orange),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(
                              '$name — '
                              '${stock.toStringAsFixed(1)}kg in stock, '
                              '${margin.toStringAsFixed(0)}% margin',
                              style: const TextStyle(
                                  fontSize: 11))),
                    ]),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Promo type selector
        const Text('Choose promotion type',
            style: TextStyle(
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ..._promoTypes.map((t) {
          final isSelected = _promoType == t.$1;
          return GestureDetector(
            onTap: widget.viewOnly
                ? null
                : () => setState(
                    () => _promoType = t.$1),
            child: Container(
              margin:
                  const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                        .withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius:
                    BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(children: [
                Text(t.$2,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primary
                          : Colors.black87,
                    )),
              ]),
            ),
          );
        }),

        const SizedBox(height: 12),
        TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
              labelText: 'Promotion name *'),
          readOnly: widget.viewOnly,
          validator: (v) =>
              v?.trim().isEmpty == true
                  ? 'Required'
                  : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descCtrl,
          decoration: const InputDecoration(
              labelText:
                  'Description (shown to customers)'),
          maxLines: 2,
          readOnly: widget.viewOnly,
        ),
      ],
    );
  }

  // ── STEP 2: Details based on type ──────────────────
  Widget _buildStep2() {
    switch (_promoType) {
      case 'weekly_special':
        return _buildWeeklySpecial();
      case 'buy_x_get_y':
        return _buildBuyXGetY();
      case 'spend_reward':
        return _buildSpendReward();
      case 'points_multiplier':
        return _buildPointsMultiplier();
      case 'birthday_reward':
        return _buildBirthdayReward();
      case 'early_access':
        return _buildEarlyAccess();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWeeklySpecial() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductSearchPicker(
          label: 'Product on special *',
          selectedProducts: _specialProducts,
          onAdd: (p) {
            setState(
                () => _specialProducts = [p]);
            _recalcMargin();
          },
          onRemove: (_) {
            setState(() => _specialProducts = []);
            _recalcMargin();
          },
          singleSelect: true,
          readOnly: widget.viewOnly,
        ),
        const SizedBox(height: 16),
        const Text('Discount type',
            style: TextStyle(
                fontWeight: FontWeight.w500)),
        Row(children: [
          Radio<String>(
            value: 'rand',
            groupValue: _discountMode,
            onChanged: widget.viewOnly
                ? null
                : (v) => setState(() {
                      _discountMode = v!;
                      _recalcMargin();
                    }),
          ),
          const Text('R off (e.g. R10 off)'),
          const SizedBox(width: 16),
          Radio<String>(
            value: 'pct',
            groupValue: _discountMode,
            onChanged: widget.viewOnly
                ? null
                : (v) => setState(() {
                      _discountMode = v!;
                      _recalcMargin();
                    }),
          ),
          const Text('% off (e.g. 10% off)'),
        ]),
        TextFormField(
          controller: _discountValueCtrl,
          decoration: InputDecoration(
            labelText: _discountMode == 'rand'
                ? 'Amount off (R)'
                : 'Percentage off (%)',
            prefixText:
                _discountMode == 'rand' ? 'R' : null,
            suffixText:
                _discountMode == 'pct' ? '%' : null,
          ),
          keyboardType: TextInputType.number,
          readOnly: widget.viewOnly,
          onChanged: (_) => _recalcMargin(),
          validator: (v) =>
              v?.trim().isEmpty == true
                  ? 'Required'
                  : null,
        ),
        const SizedBox(height: 12),
        _buildMarginIndicator(),
      ],
    );
  }

  Widget _buildBuyXGetY() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductSearchPicker(
          label: 'Customer buys (trigger product)',
          selectedProducts: _buyProducts,
          onAdd: (p) => setState(
              () => _buyProducts = [
                    ..._buyProducts,
                    p
                  ]),
          onRemove: (id) => setState(() =>
              _buyProducts = _buyProducts
                  .where(
                      (x) => x['id'] != id)
                  .toList()),
          readOnly: widget.viewOnly,
        ),
        const SizedBox(height: 12),
        Row(children: [
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: _buyQtyCtrl,
              decoration: const InputDecoration(
                  labelText: 'Buy qty'),
              keyboardType: TextInputType.number,
              readOnly: widget.viewOnly,
            ),
          ),
          const Padding(
            padding:
                EdgeInsets.symmetric(horizontal: 12),
            child: Text('get'),
          ),
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: _getQtyCtrl,
              decoration: const InputDecoration(
                  labelText: 'Get qty'),
              keyboardType: TextInputType.number,
              readOnly: widget.viewOnly,
            ),
          ),
          const Padding(
            padding:
                EdgeInsets.symmetric(horizontal: 8),
            child: Text('free'),
          ),
        ]),
        const SizedBox(height: 12),
        ProductSearchPicker(
          label: 'Free product (leave empty = same)',
          selectedProducts: _getProducts,
          onAdd: (p) =>
              setState(() => _getProducts = [p]),
          onRemove: (_) =>
              setState(() => _getProducts = []),
          singleSelect: true,
          readOnly: widget.viewOnly,
        ),
        _buildMarginIndicator(),
      ],
    );
  }

  Widget _buildSpendReward() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _minSpendCtrl,
          decoration: const InputDecoration(
            labelText: 'Minimum spend to qualify',
            prefixText: 'R',
          ),
          keyboardType: TextInputType.number,
          readOnly: widget.viewOnly,
          validator: (v) =>
              v?.trim().isEmpty == true
                  ? 'Required'
                  : null,
        ),
        const SizedBox(height: 16),
        const Text('Reward type',
            style: TextStyle(
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _spendRewardType,
          decoration: const InputDecoration(
              labelText: 'What does the customer get?'),
          items: const [
            DropdownMenuItem(
                value: 'points',
                child: Text('Bonus points')),
            DropdownMenuItem(
                value: 'free_product',
                child: Text('Free product')),
            DropdownMenuItem(
                value: 'discount_pct',
                child: Text('Percentage discount')),
            DropdownMenuItem(
                value: 'discount_rand',
                child: Text('Rand discount')),
          ],
          onChanged: widget.viewOnly
              ? null
              : (v) => setState(
                  () => _spendRewardType = v!),
        ),
        const SizedBox(height: 12),
        if (_spendRewardType == 'points')
          TextFormField(
            controller: _spendRewardValueCtrl,
            decoration: const InputDecoration(
                labelText: 'Bonus points to award'),
            keyboardType: TextInputType.number,
            readOnly: widget.viewOnly,
          ),
        if (_spendRewardType == 'discount_pct')
          TextFormField(
            controller: _spendRewardValueCtrl,
            decoration: const InputDecoration(
                labelText: 'Discount percentage',
                suffixText: '%'),
            keyboardType: TextInputType.number,
            readOnly: widget.viewOnly,
          ),
        if (_spendRewardType == 'discount_rand')
          TextFormField(
            controller: _spendRewardValueCtrl,
            decoration: const InputDecoration(
                labelText: 'Discount amount',
                prefixText: 'R'),
            keyboardType: TextInputType.number,
            readOnly: widget.viewOnly,
          ),
        if (_spendRewardType == 'free_product') ...[
          const SizedBox(height: 8),
          ProductSearchPicker(
            label: 'Free product',
            selectedProducts: _spendRewardProducts,
            onAdd: (p) => setState(
                () => _spendRewardProducts = [p]),
            onRemove: (_) => setState(
                () => _spendRewardProducts = []),
            singleSelect: true,
            readOnly: widget.viewOnly,
          ),
        ],
      ],
    );
  }

  Widget _buildPointsMultiplier() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductSearchPicker(
          label: 'Products earning bonus points '
              '(leave empty = all products)',
          selectedProducts: _multiplierProducts,
          onAdd: (p) => setState(() =>
              _multiplierProducts = [
                ..._multiplierProducts,
                p
              ]),
          onRemove: (id) => setState(() =>
              _multiplierProducts =
                  _multiplierProducts
                      .where((x) => x['id'] != id)
                      .toList()),
          readOnly: widget.viewOnly,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _multiplierCtrl,
          decoration: const InputDecoration(
            labelText: 'Points multiplier',
            helperText:
                '2 = double points, 3 = triple points',
          ),
          keyboardType: TextInputType.number,
          readOnly: widget.viewOnly,
          validator: (v) =>
              v?.trim().isEmpty == true
                  ? 'Required'
                  : null,
        ),
      ],
    );
  }

  Widget _buildBirthdayReward() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.pink
                .withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: Colors.pink
                    .withValues(alpha: 0.3)),
          ),
          child: const Text(
            '🎂 Birthday rewards are set per customer '
            'in the Customers module. This promotion '
            'defines the default reward options '
            'available to assign.',
            style: TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _birthdayRewardType,
          decoration: const InputDecoration(
              labelText: 'Default birthday reward'),
          items: const [
            DropdownMenuItem(
                value: 'free_product',
                child: Text('Free product '
                    '(e.g. 200g boerewors)')),
            DropdownMenuItem(
                value: 'discount_pct',
                child: Text('% off entire purchase')),
            DropdownMenuItem(
                value: 'points',
                child: Text('Bonus points')),
          ],
          onChanged: widget.viewOnly
              ? null
              : (v) => setState(
                  () => _birthdayRewardType = v!),
        ),
        const SizedBox(height: 12),
        if (_birthdayRewardType == 'free_product')
          ProductSearchPicker(
            label: 'Birthday free product',
            selectedProducts: _birthdayProducts,
            onAdd: (p) =>
                setState(() => _birthdayProducts = [p]),
            onRemove: (_) => setState(
                () => _birthdayProducts = []),
            singleSelect: true,
            readOnly: widget.viewOnly,
          ),
        if (_birthdayRewardType == 'discount_pct')
          TextFormField(
            controller: _birthdayValueCtrl,
            decoration: const InputDecoration(
                labelText: 'Discount percentage',
                suffixText: '%'),
            keyboardType: TextInputType.number,
            readOnly: widget.viewOnly,
          ),
        if (_birthdayRewardType == 'points')
          TextFormField(
            controller: _birthdayValueCtrl,
            decoration: const InputDecoration(
                labelText: 'Bonus points'),
            keyboardType: TextInputType.number,
            readOnly: widget.viewOnly,
          ),
      ],
    );
  }

  Widget _buildEarlyAccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary
                .withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.primary
                    .withValues(alpha: 0.2)),
          ),
          child: const Text(
            '🔓 Early Access gives selected tiers '
            '(e.g. Gold, Elite, VIP) the ability to '
            'see and claim specials before other '
            'customers. Set the audience in Step 3.',
            style: TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(height: 16),
        const Text('How many hours early?',
            style: TextStyle(
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [12, 24, 48].map((h) {
            return ChoiceChip(
              label: Text('${h}h early'),
              selected: _earlyAccessHours == h,
              onSelected: widget.viewOnly
                  ? null
                  : (v) {
                      if (v) {
                        setState(
                            () => _earlyAccessHours = h);
                      }
                    },
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── STEP 3: Audience & Schedule ─────────────────────
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Loyalty app only notice
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green
                .withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: Colors.green
                    .withValues(alpha: 0.3)),
          ),
          child: const Row(children: [
            Icon(Icons.phone_android,
                size: 16, color: Colors.green),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'All promotions are exclusive to the '
                'Struisbaai Vleismark loyalty app. '
                'No app = no deals.',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.green),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        const Text('Who can see this promotion?',
            style: TextStyle(
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _audienceOptions.map((a) {
            final label = switch (a) {
              'all'    => 'All Members',
              'bronze' => 'Bronze+',
              'silver' => 'Silver+',
              'gold'   => 'Gold+',
              'elite'  => 'Elite+',
              'vip'    => 'VIP Only',
              _        => a,
            };
            return FilterChip(
              label: Text(label),
              selected: _audience.contains(a),
              onSelected: widget.viewOnly
                  ? null
                  : (v) => setState(() {
                        if (v)
                          _audience.add(a);
                        else
                          _audience.remove(a);
                        if (_audience.isEmpty)
                          _audience = ['all'];
                      }),
            );
          }).toList(),
        ),

        if (_promoType != 'birthday_reward') ...[
          const SizedBox(height: 20),
          const Text('Schedule (optional)',
              style: TextStyle(
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(_startDate == null
                    ? 'Start date'
                    : 'From: ${_startDate!.day}/'
                        '${_startDate!.month}/'
                        '${_startDate!.year}'),
                trailing: const Icon(
                    Icons.calendar_today, size: 18),
                onTap: widget.viewOnly
                    ? null
                    : () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate:
                              _startDate ?? DateTime.now(),
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                        );
                        if (d != null) {
                          setState(() => _startDate = d);
                        }
                      },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(_endDate == null
                    ? 'End date'
                    : 'Until: ${_endDate!.day}/'
                        '${_endDate!.month}/'
                        '${_endDate!.year}'),
                trailing: const Icon(
                    Icons.calendar_today, size: 18),
                onTap: widget.viewOnly
                    ? null
                    : () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate:
                              _endDate ?? DateTime.now(),
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                        );
                        if (d != null) {
                          setState(() => _endDate = d);
                        }
                      },
              ),
            ),
          ]),
        ],

        const SizedBox(height: 16),
        // Summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text('Summary',
                  style: TextStyle(
                      fontWeight:
                          FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Name: ${_nameCtrl.text}'),
              Text('Type: $_promoType'
                  .replaceAll('_', ' ')),
              Text(
                  'Audience: ${_audience.join(", ")}'),
              Text(
                  'Channel: Loyalty App only'),
              if (_promoType == 'birthday_reward')
                const Text(
                    'Schedule: Ongoing — triggers on customer birthday month',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.black54)),
              if (_promoType != 'birthday_reward') ...[
                if (_startDate != null)
                  Text('Start: ${_startDate!.day}/'
                      '${_startDate!.month}/'
                      '${_startDate!.year}'),
                if (_endDate != null)
                  Text('Until: ${_endDate!.day}/'
                      '${_endDate!.month}/'
                      '${_endDate!.year}'),
                if (_startDate == null && _endDate == null)
                  const Text('Schedule: No end date — runs until cancelled',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.black54)),
              ],
              if (_calculatedMarginPct != null)
                Text(
                  'Margin after discount: '
                  '${_calculatedMarginPct!.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: _marginWarning
                        ? AppColors.error
                        : Colors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMarginIndicator() {
    if (_calculatedMarginPct == null)
      return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _marginWarning
            ? AppColors.error.withValues(alpha: 0.08)
            : Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _marginWarning
              ? AppColors.error.withValues(alpha: 0.4)
              : Colors.green.withValues(alpha: 0.4),
        ),
      ),
      child: Row(children: [
        Icon(
          _marginWarning
              ? Icons.warning_amber
              : Icons.check_circle_outline,
          color: _marginWarning
              ? AppColors.error
              : Colors.green,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _marginWarning
                ? '⚠️ Margin after discount: '
                    '${_calculatedMarginPct!.toStringAsFixed(1)}% '
                    '— below your 20% target. '
                    'You can still save but will be warned.'
                : '✅ Margin after discount: '
                    '${_calculatedMarginPct!.toStringAsFixed(1)}% '
                    '— looks good.',
            style: TextStyle(
              fontSize: 12,
              color: _marginWarning
                  ? AppColors.error
                  : Colors.green,
            ),
          ),
        ),
      ]),
    );
  }
}
