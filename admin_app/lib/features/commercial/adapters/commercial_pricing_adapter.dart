/// Maps [commercial_actions] rows to the Dynamic Pricing tab shape
/// (`supplier_price_changes` / inventory fallback maps) without recalculating economics.
class CommercialPricingAdapter {
  CommercialPricingAdapter._();

  static Map<String, dynamic> fromRow(Map<String, dynamic> row) {
    final m = Map<String, dynamic>.from(row);
    final name = _productName(m);
    final current = _formatMoney(
      _double(m, const [
        'current_sell_price',
        'current_price',
        'sell_price',
        'baseline_sell_price',
      ]),
    );
    final suggested = _formatMoney(
      _double(m, const [
        'suggested_price',
        'recommended_sell_price',
        'proposed_sell_price',
        'model_suggested_price',
      ]),
    );
    final profit = _double(m, const [
      'predicted_profit',
      'predicted_net_profit',
      'model_predicted_profit',
    ]);
    final validation = (m['validation_status'] ?? m['accounting_validation_status'])
            ?.toString() ??
        '';
    final flagged = validation.toUpperCase() == 'FLAGGED';
    final priority = _double(m, const ['portfolio_priority_score']);
    final demand = _double(m, const [
      'predicted_demand_delta_pct',
      'demand_delta_pct',
      'elasticity_demand_pct',
    ]);

    final pct = _headerPercentMeta(
      demand: demand,
      portfolioPriority: priority,
    );

    return {
      'id': m['id']?.toString() ?? '',
      'product_name': name,
      'supplier_name': 'Commercial',
      'percentage_increase': pct.text,
      '__percentage_type': pct.kind,
      'current_sell_price': current,
      'suggested_sell_price': suggested,
      'margin_impact': profit != null
          ? 'Pred. profit: R ${profit.toStringAsFixed(2)}'
          : '—',
      '__from_commercial': true,
      '__source': 'commercial',
      '__validation_flagged': flagged,
    };
  }

  static String _productName(Map<String, dynamic> m) {
    final direct = m['product_name'] as String? ?? m['item_name'] as String?;
    if (direct != null && direct.isNotEmpty) return direct;
    final inv = m['inventory_items'];
    if (inv is Map && inv['name'] != null) {
      return inv['name'].toString();
    }
    return 'Product';
  }

  static double? _double(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      if (v is num) return v.toDouble();
      final p = double.tryParse(v.toString());
      if (p != null) return p;
    }
    return null;
  }

  static String _formatMoney(double? v) {
    if (v == null) return '—';
    return v.toStringAsFixed(2);
  }

  /// Header line uses `(+X%)` — prefer demand delta when present; else portfolio score.
  static _PctMeta _headerPercentMeta({
    required double? demand,
    required double? portfolioPriority,
  }) {
    if (demand != null && demand.isFinite) {
      return _PctMeta(demand.toStringAsFixed(1), 'demand');
    }
    if (portfolioPriority != null && portfolioPriority.isFinite) {
      return _PctMeta(portfolioPriority.toStringAsFixed(2), 'score');
    }
    return const _PctMeta('0', 'score');
  }
}

class _PctMeta {
  const _PctMeta(this.text, this.kind);
  final String text;
  /// `demand` | `score` — for debugging / future use; UI uses [text] only.
  final String kind;
}
