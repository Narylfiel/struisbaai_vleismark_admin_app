import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:admin_app/features/reports/services/alert_service.dart';
import 'package:admin_app/features/reports/services/report_repository.dart';

/// Dashboard read-only helpers: reuses [ReportRepository] pricing pipeline + [AlertService].
///
/// In-memory cache (5 min TTL), normalized calendar range (last 7 full days through end of today).
class DashboardService {
  DashboardService(this._client);

  final SupabaseClient _client;

  List<Map<String, dynamic>>? _cachedAlerts;
  DateTime? _lastFetch;

  static const Duration _cacheTtl = Duration(minutes: 5);

  /// Same rules as [pricing_intelligence] + [AlertService]; range is fixed for dashboard consistency.
  Future<List<Map<String, dynamic>>> getAlerts() async {
    final now = DateTime.now();
    if (_cachedAlerts != null &&
        _lastFetch != null &&
        now.difference(_lastFetch!) < _cacheTtl) {
      return List<Map<String, dynamic>>.from(_cachedAlerts!);
    }

    final to = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final from =
        DateTime(to.year, to.month, to.day).subtract(const Duration(days: 7));

    final reportRepo = ReportRepository(client: _client);
    final rows = await reportRepo.getPricingIntelligenceRowsForAlerts(from, to);
    final alerts = AlertService.generateAlerts(rows);
    _cachedAlerts = List<Map<String, dynamic>>.from(alerts);
    _lastFetch = now;
    return List<Map<String, dynamic>>.from(alerts);
  }
}
