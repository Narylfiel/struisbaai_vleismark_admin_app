import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for generating reports defined in AdminAppBluePrintTruth Module 11.
/// Handles data aggregation and formatting for exports.
class ReportRepository {
  final SupabaseClient _client;

  ReportRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ═════════════════════════════════════════════════════════
  // REPORT AGGREGATORS (Direct to Supabase queries/RPCs)
  // ═════════════════════════════════════════════════════════

  /// Daily Sales Summary
  Future<List<Map<String, dynamic>>> getDailySales(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day).toIso8601String();
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
      
      final response = await _client
          .from('sales_transactions')
          .select()
          .gte('created_at', start)
          .lte('created_at', end)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Inventory Valuation (On Demand)
  Future<List<Map<String, dynamic>>> getInventoryValuation() async {
    try {
      final response = await _client
          .from('inventory_items')
          .select('id, name, current_stock, cost_price, selling_price, category_id')
          .gt('current_stock', 0)
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Shrinkage Report (Weekly)
  Future<List<Map<String, dynamic>>> getShrinkageReport(DateTime startDate, DateTime endDate) async {
    try {
      final response = await _client
          .from('shrinkage_alerts')
          .select()
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Staff Hours / Timecards
  Future<List<Map<String, dynamic>>> getStaffHours(DateTime startDate, DateTime endDate) async {
    try {
      final response = await _client
          .from('timecards')
          .select('*, staff_profiles(full_name)')
          .gte('clock_in', startDate.toIso8601String())
          .lte('clock_in', endDate.toIso8601String())
          .order('clock_in', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Supplier Spend (Monthly)
  Future<List<Map<String, dynamic>>> getSupplierSpend(DateTime startDate, DateTime endDate) async {
    try {
      // Typically an RPC grouping by supplier from incoming invoices/stock_movements
      final response = await _client.rpc('calculate_supplier_spend', params: {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      });
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      return [];
    }
  }

  /// Audit Trail (Security/Overrides)
  Future<List<Map<String, dynamic>>> getAuditTrail(DateTime startDate, DateTime endDate) async {
    try {
      final response = await _client
          .from('audit_log')
          .select()
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false)
          .limit(100); // Limit to prevent crashing on large date ranges
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // ═════════════════════════════════════════════════════════
  // EXPORT FORMATTERS (Raw CSV generators)
  // ═════════════════════════════════════════════════════════
  
  String generateCSV(List<Map<String, dynamic>> data, List<String> headers, List<String> keys) {
    if (data.isEmpty) return 'No data available for this range.';
    
    final StringBuffer buffer = StringBuffer();
    buffer.writeln(headers.join(','));
    
    for (var row in data) {
      List<String> values = [];
      for (var key in keys) {
        String val = row[key]?.toString() ?? '';
        // Escape commas for CSV
        if (val.contains(',')) val = '"$val"';
        values.add(val);
      }
      buffer.writeln(values.join(','));
    }
    return buffer.toString();
  }
}
