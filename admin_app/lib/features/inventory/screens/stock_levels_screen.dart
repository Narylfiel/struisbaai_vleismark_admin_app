import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/admin_config.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/supabase_service.dart';

/// Blueprint §4.4: Stock Levels — table view of all products across locations.
/// C1: Single source of truth — display uses current_stock (updated by POS trigger).
class StockLevelsScreen extends StatefulWidget {
  const StockLevelsScreen({super.key});

  @override
  State<StockLevelsScreen> createState() => _StockLevelsScreenState();
}

class _StockLevelsScreenState extends State<StockLevelsScreen> {
  final _supabase = SupabaseService.client;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String _filter = 'all'; // all | low | ok

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _supabase
          .from('inventory_items')
          .select('id, name, plu_code, current_stock, stock_on_hand_fresh, stock_on_hand_frozen, reorder_level, reorder_point, unit_type')
          .eq('is_active', true)
          .order('name');
      setState(() => _items = List<Map<String, dynamic>>.from(res));
    } catch (e) {
      debugPrint('Stock levels load: $e');
    }
    setState(() => _isLoading = false);
  }

  /// C1: Single source of truth — current_stock only (POS trigger updates it).
  double _onHand(Map<String, dynamic> p) {
    return (p['current_stock'] as num?)?.toDouble() ?? 0;
  }

  double _reorderLevel(Map<String, dynamic> p) {
    return (p['reorder_level'] as num?)?.toDouble() ?? (p['reorder_point'] as num?)?.toDouble() ?? 0;
  }

  String _status(Map<String, dynamic> p) {
    final onHand = _onHand(p);
    final reorder = _reorderLevel(p);
    if (reorder <= 0) return 'OK';
    return onHand <= reorder ? 'LOW' : 'OK';
  }

  bool _isLow(Map<String, dynamic> p) => _status(p) == 'LOW';

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'low') return _items.where(_isLow).toList();
    if (_filter == 'ok') return _items.where((p) => !_isLow(p)).toList();
    return _items;
  }

  @override
  Widget build(BuildContext context) {
    final unit = 'kg'; // could come from first item's unit_type
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          color: AppColors.cardBg,
          child: Row(
            children: [
              const Text('Stock Levels', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 24),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'all', label: Text('All'), icon: Icon(Icons.list, size: 16)),
                  ButtonSegment(value: 'low', label: Text('Low'), icon: Icon(Icons.warning, size: 16)),
                  ButtonSegment(value: 'ok', label: Text('OK'), icon: Icon(Icons.check_circle, size: 16)),
                ],
                selected: {_filter},
                onSelectionChanged: (s) => setState(() => _filter = s.first),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _isLoading ? null : _load,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          color: AppColors.surfaceBg,
          child: const Row(
            children: [
              SizedBox(width: 60, child: Text('PLU', style: _headerStyle)),
              SizedBox(width: 12),
              Expanded(flex: 3, child: Text('PRODUCT', style: _headerStyle)),
              SizedBox(width: 12),
              SizedBox(width: 90, child: Text('ON HAND', style: _headerStyle)),
              SizedBox(width: 12),
              SizedBox(width: 80, child: Text('FRESH', style: _headerStyle)),
              SizedBox(width: 12),
              SizedBox(width: 80, child: Text('FROZEN', style: _headerStyle)),
              SizedBox(width: 12),
              SizedBox(width: 90, child: Text('REORDER', style: _headerStyle)),
              SizedBox(width: 12),
              SizedBox(width: 80, child: Text('STATUS', style: _headerStyle)),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _filtered.isEmpty
                  ? Center(
                      child: Text(
                        _items.isEmpty ? 'No active products' : 'No items match filter',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (_, i) {
                        final p = _filtered[i];
                        final onHand = _onHand(p); // C1: current_stock only
                        final fresh = (p['stock_on_hand_fresh'] as num?)?.toDouble() ?? 0;
                        final frozen = (p['stock_on_hand_frozen'] as num?)?.toDouble() ?? 0;
                        final reorder = _reorderLevel(p);
                        final low = reorder > 0 && onHand <= reorder;
                        final unitType = p['unit_type']?.toString() ?? 'kg';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              SizedBox(width: 60, child: Text('${p['plu_code'] ?? '—'}', style: const TextStyle(fontWeight: FontWeight.w600))),
                              const SizedBox(width: 12),
                              Expanded(flex: 3, child: Text(p['name'] ?? '—')),
                              const SizedBox(width: 12),
                              SizedBox(width: 90, child: Text('${onHand.toStringAsFixed(AdminConfig.stockKgDecimals)} $unitType')),
                              const SizedBox(width: 12),
                              SizedBox(width: 80, child: Text('${fresh.toStringAsFixed(AdminConfig.stockKgDecimals)} $unitType')),
                              const SizedBox(width: 12),
                              SizedBox(width: 80, child: Text('${frozen.toStringAsFixed(AdminConfig.stockKgDecimals)} $unitType')),
                              const SizedBox(width: 12),
                              SizedBox(width: 90, child: Text('${reorder.toStringAsFixed(AdminConfig.stockKgDecimals)} $unitType')),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 80,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: low ? AppColors.warning.withOpacity(0.15) : AppColors.success.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    low ? 'LOW' : 'OK',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: low ? AppColors.warning : AppColors.success,
                                    ),
                                  ),
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

const _headerStyle = TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.bold,
  color: AppColors.textSecondary,
  letterSpacing: 0.5,
);
