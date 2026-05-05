import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/features/loyalty/services/tier_config_service.dart';
import 'package:flutter/material.dart';

class TierConfigScreen extends StatefulWidget {
  const TierConfigScreen({super.key});

  @override
  State<TierConfigScreen> createState() => _TierConfigScreenState();
}

class _TierConfigScreenState extends State<TierConfigScreen> {
  final TierConfigService _service = TierConfigService();
  final List<_TierEditorState> _tiers = <_TierEditorState>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTiers();
  }

  @override
  void dispose() {
    for (final tier in _tiers) {
      tier.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTiers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows = await _service.fetchTiers();
      final loaded = rows.map((row) => _TierEditorState.fromRow(row)).toList();
      if (!mounted) return;

      for (final tier in _tiers) {
        tier.dispose();
      }

      setState(() {
        _tiers
          ..clear()
          ..addAll(loaded);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorHandler.friendlyMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _saveTier(_TierEditorState tier) async {
    final pointsRequired = int.tryParse(tier.pointsRequiredController.text.trim());
    final decayResetPoints =
        int.tryParse(tier.decayResetController.text.trim());
    final pointsMultiplier =
        double.tryParse(tier.pointsMultiplierController.text.trim());

    if (pointsRequired == null || decayResetPoints == null || pointsMultiplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid numeric values before saving.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => tier.saving = true);
    try {
      final updates = <String, dynamic>{
        'points_required': pointsRequired,
        'decay_reset_points': decayResetPoints,
        'is_active': tier.isActive,
        'perks': {
          'birthday_message': tier.birthdayMessageController.text.trim(),
          'birthday_reward_description':
              tier.birthdayRewardController.text.trim(),
          'discount_percentage': tier.discountPercentage,
          'points_multiplier': pointsMultiplier,
          'early_access': tier.earlyAccess,
          'perks_description': tier.perksDescriptions
              .map((controller) => controller.text.trim())
              .where((item) => item.isNotEmpty)
              .toList(),
        },
      };

      await _service.updateTier(tier.id, updates);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${tier.tierLabel} saved successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.friendlyMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => tier.saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadTiers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_tiers.isEmpty) {
      return const Center(
        child: Text(
          'No tiers found in loyalty_tier_config.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTiers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tiers.length,
        itemBuilder: (context, index) {
          final tier = _tiers[index];
          return _buildTierCard(tier);
        },
      ),
    );
  }

  Widget _buildTierCard(_TierEditorState tier) {
    final swatchColor = _hexToColor(tier.colorHex);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        side: BorderSide(color: AppColors.border),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Row(
          children: [
            Expanded(
              child: Text(
                tier.tierLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: swatchColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.borderDark),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              tier.colorHex,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        subtitle: Text(
          'Key: ${tier.tierKey} · Sort: ${tier.sortOrder}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: tier.pointsRequiredController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Points required',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: tier.decayResetController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Decay reset points',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tier active'),
                  value: tier.isActive,
                  activeThumbColor: AppColors.primary,
                  onChanged: (value) => setState(() => tier.isActive = value),
                ),
                const Divider(color: AppColors.border),
                const SizedBox(height: 4),
                const Text(
                  'Perks',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: tier.birthdayMessageController,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Birthday message',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: tier.birthdayRewardController,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Birthday reward description',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: tier.pointsMultiplierController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Points multiplier',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Early access'),
                  value: tier.earlyAccess,
                  activeThumbColor: AppColors.primary,
                  onChanged: (value) => setState(() => tier.earlyAccess = value),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Perks description list',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...tier.perksDescriptions.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final controller = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: 'Perk ${idx + 1}',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => setState(() {
                            controller.dispose();
                            tier.perksDescriptions.removeAt(idx);
                          }),
                          icon: const Icon(Icons.remove_circle_outline),
                          color: AppColors.error,
                          tooltip: 'Remove perk',
                        ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () => setState(
                    () => tier.perksDescriptions.add(TextEditingController()),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add perk item'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: tier.saving ? null : () => _saveTier(tier),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: tier.saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(tier.saving ? 'Saving...' : 'Save ${tier.tierLabel}'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    final normalized = hex.replaceAll('#', '').trim();
    if (normalized.length != 6) return AppColors.primary;
    final parsed = int.tryParse('FF$normalized', radix: 16);
    if (parsed == null) return AppColors.primary;
    return Color(parsed);
  }
}

class _TierEditorState {
  final String id;
  final String tierKey;
  final String tierLabel;
  final int sortOrder;
  final String colorHex;
  final double discountPercentage;
  bool isActive;
  bool earlyAccess;
  bool saving;

  final TextEditingController pointsRequiredController;
  final TextEditingController decayResetController;
  final TextEditingController birthdayMessageController;
  final TextEditingController birthdayRewardController;
  final TextEditingController pointsMultiplierController;
  final List<TextEditingController> perksDescriptions;

  _TierEditorState({
    required this.id,
    required this.tierKey,
    required this.tierLabel,
    required this.sortOrder,
    required this.colorHex,
    required this.discountPercentage,
    required this.isActive,
    required this.earlyAccess,
    required this.pointsRequiredController,
    required this.decayResetController,
    required this.birthdayMessageController,
    required this.birthdayRewardController,
    required this.pointsMultiplierController,
    required this.perksDescriptions,
  }) : saving = false;

  factory _TierEditorState.fromRow(Map<String, dynamic> row) {
    final perks = (row['perks'] is Map<String, dynamic>)
        ? row['perks'] as Map<String, dynamic>
        : <String, dynamic>{};
    final perksListRaw = perks['perks_description'];
    final perksList = perksListRaw is List
        ? perksListRaw.map((item) => item.toString()).toList()
        : <String>[];

    return _TierEditorState(
      id: row['id']?.toString() ?? '',
      tierKey: row['tier_key']?.toString() ?? '',
      tierLabel: row['tier_label']?.toString() ??
          row['tier_key']?.toString() ??
          'Tier',
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      colorHex: row['color_hex']?.toString() ?? '#8B1A1A',
      discountPercentage: (perks['discount_percentage'] as num?)?.toDouble() ?? 0,
      isActive: row['is_active'] as bool? ?? true,
      earlyAccess: perks['early_access'] as bool? ?? false,
      pointsRequiredController: TextEditingController(
        text: ((row['points_required'] as num?)?.toInt() ?? 0).toString(),
      ),
      decayResetController: TextEditingController(
        text: ((row['decay_reset_points'] as num?)?.toInt() ?? 0).toString(),
      ),
      birthdayMessageController: TextEditingController(
        text: perks['birthday_message']?.toString() ?? '',
      ),
      birthdayRewardController: TextEditingController(
        text: perks['birthday_reward_description']?.toString() ?? '',
      ),
      pointsMultiplierController: TextEditingController(
        text: ((perks['points_multiplier'] as num?)?.toDouble() ?? 1.0)
            .toString(),
      ),
      perksDescriptions: perksList.isEmpty
          ? <TextEditingController>[TextEditingController()]
          : perksList.map((item) => TextEditingController(text: item)).toList(),
    );
  }

  void dispose() {
    pointsRequiredController.dispose();
    decayResetController.dispose();
    birthdayMessageController.dispose();
    birthdayRewardController.dispose();
    pointsMultiplierController.dispose();
    for (final controller in perksDescriptions) {
      controller.dispose();
    }
  }
}
