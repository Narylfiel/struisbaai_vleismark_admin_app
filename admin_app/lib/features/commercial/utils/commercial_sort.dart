/// Deterministic ordering for [commercial_actions] rows: priority desc, then created_at desc.
class CommercialSort {
  CommercialSort._();

  static const double _kScoreEpsilon = 0.0001;

  static int createdAtMillis(Map<String, dynamic> m) {
    final v = m['created_at'];
    if (v == null) return 0;
    if (v is DateTime) return v.millisecondsSinceEpoch;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      return DateTime.tryParse(v)?.millisecondsSinceEpoch ?? 0;
    }
    return 0;
  }

  static double _priorityScore(Map<String, dynamic> m) {
    final v = m['portfolio_priority_score'];
    double x;
    if (v is num) {
      x = v.toDouble();
    } else {
      x = double.tryParse(v?.toString() ?? '') ?? 0;
    }
    if (x.isNaN || x.isInfinite) return 0;
    return x;
  }

  /// [portfolio_priority_score] DESC (epsilon tie-break), then [created_at] DESC.
  static int compareByPriorityThenCreated(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final sa = _priorityScore(a);
    final sb = _priorityScore(b);
    final d = sb - sa;
    if (d.abs() > _kScoreEpsilon) {
      return d > 0 ? 1 : -1;
    }
    final ta = createdAtMillis(a);
    final tb = createdAtMillis(b);
    final ca = ta < 0 ? 0 : ta;
    final cb = tb < 0 ? 0 : tb;
    return cb.compareTo(ca);
  }

  static void sortByPriority(List<Map<String, dynamic>> rows) {
    rows.sort(compareByPriorityThenCreated);
  }
}
