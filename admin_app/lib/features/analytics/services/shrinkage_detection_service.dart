import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// OPERATIONAL SHRINKAGE DETECTION ENGINE
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// Detects abnormal weight loss per product by comparing:
/// - EXPECTED USAGE: Sales quantity (from transaction_items)
/// - ACTUAL USAGE: Stock deductions (from stock_movements where type='sale')
/// - SHRINKAGE: difference = actual_usage - expected_usage
///
/// Time windows: Daily or rolling 7-day
/// Thresholds: Absolute (> 0.3kg) and percentage (> 5%)
///
/// This is READ-ONLY analytics. No database writes.
/// ═══════════════════════════════════════════════════════════════════════════

/// Shrinkage status levels
enum ShrinkageStatus { normal, warning, critical }

/// DTO for product-level shrinkage data
class ProductShrinkage {
  final String productId;
  final String productName;
  final double expectedQty;      // From transaction_items (sales)
  final double actualQty;        // From stock_movements (deductions)
  final double shrinkageQty;     // actual - expected (positive = loss)
  final double shrinkagePercent; // (shrinkage / expected) * 100
  final ShrinkageStatus status;
  final double shrinkageValue;   // Monetary value (shrinkageQty × avg_cost)
  final DateTime windowStart;
  final DateTime windowEnd;

  const ProductShrinkage({
    required this.productId,
    required this.productName,
    required this.expectedQty,
    required this.actualQty,
    required this.shrinkageQty,
    required this.shrinkagePercent,
    required this.status,
    required this.shrinkageValue,
    required this.windowStart,
    required this.windowEnd,
  });

  /// Factory from database row
  factory ProductShrinkage.fromDbRow(
    Map<String, dynamic> row,
    DateTime windowStart,
    DateTime windowEnd, {
    double absoluteThreshold = 0.3,
    double percentThreshold = 5.0,
  }) {
    final expected = (row['expected_qty'] as num?)?.toDouble() ?? 0.0;
    final actual = (row['actual_qty'] as num?)?.toDouble() ?? 0.0;
    final shrinkage = actual - expected; // Positive = more deducted than sold
    final avgCost = (row['average_cost'] as num?)?.toDouble() ?? 0.0;
    
    // Calculate percentage (handle division by zero)
    double percent = 0.0;
    if (expected > 0) {
      percent = (shrinkage.abs() / expected) * 100;
    } else if (actual > 0) {
      // No sales but stock was deducted = 100% shrinkage
      percent = 100.0;
    }

    // Determine status
    ShrinkageStatus status = ShrinkageStatus.normal;
    if (shrinkage.abs() > absoluteThreshold || percent > percentThreshold) {
      status = shrinkage.abs() > absoluteThreshold * 2 || percent > percentThreshold * 2
          ? ShrinkageStatus.critical
          : ShrinkageStatus.warning;
    }

    return ProductShrinkage(
      productId: row['product_id']?.toString() ?? '',
      productName: row['product_name']?.toString() ?? 'Unknown',
      expectedQty: expected,
      actualQty: actual,
      shrinkageQty: shrinkage,
      shrinkagePercent: percent,
      status: status,
      shrinkageValue: shrinkage.abs() * avgCost,
      windowStart: windowStart,
      windowEnd: windowEnd,
    );
  }

  /// JSON serialization for caching/transmission
  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'product_name': productName,
    'expected_qty': expectedQty,
    'actual_qty': actualQty,
    'shrinkage_qty': shrinkageQty,
    'shrinkage_percent': shrinkagePercent,
    'status': status.name,
    'shrinkage_value': shrinkageValue,
    'window_start': windowStart.toIso8601String(),
    'window_end': windowEnd.toIso8601String(),
  };
}

/// Summary of shrinkage across all products
class ShrinkageSummary {
  final List<ProductShrinkage> products;
  final double totalShrinkageQty;
  final double totalShrinkageValue;
  final int warningCount;
  final int criticalCount;
  final DateTime windowStart;
  final DateTime windowEnd;

  const ShrinkageSummary({
    required this.products,
    required this.totalShrinkageQty,
    required this.totalShrinkageValue,
    required this.warningCount,
    required this.criticalCount,
    required this.windowStart,
    required this.windowEnd,
  });

  /// Top N products by shrinkage quantity (worst offenders)
  List<ProductShrinkage> topByQuantity(int n) {
    final sorted = List<ProductShrinkage>.from(products)
      ..sort((a, b) => b.shrinkageQty.abs().compareTo(a.shrinkageQty.abs()));
    return sorted.take(n).toList();
  }

  /// Top N products by shrinkage value (money lost)
  List<ProductShrinkage> topByValue(int n) {
    final sorted = List<ProductShrinkage>.from(products)
      ..sort((a, b) => b.shrinkageValue.compareTo(a.shrinkageValue));
    return sorted.take(n).toList();
  }

  /// Only products with issues (warning or critical)
  List<ProductShrinkage> get anomalies => 
      products.where((p) => p.status != ShrinkageStatus.normal).toList();
}

class ShrinkageDetectionService {
  final SupabaseClient _client;

  ShrinkageDetectionService({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Absolute threshold in kg (default: 300g)
  static const double defaultAbsoluteThreshold = 0.3;
  
  /// Percentage threshold (default: 5%)
  static const double defaultPercentThreshold = 5.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // CORE DETECTION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Detect shrinkage for a specific date (daily aggregation)
  Future<ShrinkageSummary> detectDaily(
    DateTime date, {
    double absoluteThreshold = defaultAbsoluteThreshold,
    double percentThreshold = defaultPercentThreshold,
  }) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    
    return _detectShrinkage(
      start: start,
      end: end,
      absoluteThreshold: absoluteThreshold,
      percentThreshold: percentThreshold,
    );
  }

  /// Detect shrinkage over a rolling window (default: last 7 days)
  Future<ShrinkageSummary> detectRollingWindow(
    int days, {
    DateTime? endDate,
    double absoluteThreshold = defaultAbsoluteThreshold,
    double percentThreshold = defaultPercentThreshold,
  }) async {
    final end = endDate ?? DateTime.now();
    final start = end.subtract(Duration(days: days));
    
    return _detectShrinkage(
      start: start,
      end: end,
      absoluteThreshold: absoluteThreshold,
      percentThreshold: percentThreshold,
    );
  }

  /// Detect shrinkage comparing yesterday vs same day last week
  /// Useful for detecting day-of-week anomalies (e.g., every Friday has shrinkage)
  Future<ShrinkageSummary> detectWeekOverWeek({
    double absoluteThreshold = defaultAbsoluteThreshold,
    double percentThreshold = defaultPercentThreshold,
  }) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final lastWeekSameDay = yesterday.subtract(const Duration(days: 7));
    
    // Get both windows
    final yesterdayData = await detectDaily(yesterday, 
        absoluteThreshold: absoluteThreshold, 
        percentThreshold: percentThreshold);
    final lastWeekData = await detectDaily(lastWeekSameDay,
        absoluteThreshold: absoluteThreshold,
        percentThreshold: percentThreshold);
    
    // Compare and flag significant changes
    final changes = <ProductShrinkage>[];
    double totalQtyChange = 0;
    double totalValueChange = 0;
    int warningCount = 0;
    int criticalCount = 0;
    
    for (final yest in yesterdayData.products) {
      final lastWeek = lastWeekData.products
          .firstWhere((p) => p.productId == yest.productId, 
              orElse: () => ProductShrinkage(
                productId: yest.productId,
                productName: yest.productName,
                expectedQty: 0,
                actualQty: 0,
                shrinkageQty: 0,
                shrinkagePercent: 0,
                status: ShrinkageStatus.normal,
                shrinkageValue: 0,
                windowStart: lastWeekSameDay,
                windowEnd: lastWeekSameDay,
              ));
      
      final qtyChange = yest.shrinkageQty - lastWeek.shrinkageQty;
      final valueChange = yest.shrinkageValue - lastWeek.shrinkageValue;
      
      // Only include if there's a significant change or current issue
      if (qtyChange.abs() > absoluteThreshold * 0.5 || 
          yest.status != ShrinkageStatus.normal) {
        changes.add(ProductShrinkage(
          productId: yest.productId,
          productName: yest.productName,
          expectedQty: yest.expectedQty,
          actualQty: yest.actualQty,
          shrinkageQty: qtyChange,
          shrinkagePercent: yest.shrinkagePercent,
          status: yest.status,
          shrinkageValue: valueChange,
          windowStart: yesterdayData.windowStart,
          windowEnd: yesterdayData.windowEnd,
        ));
        
        totalQtyChange += qtyChange.abs();
        totalValueChange += valueChange.abs();
        if (yest.status == ShrinkageStatus.warning) warningCount++;
        if (yest.status == ShrinkageStatus.critical) criticalCount++;
      }
    }
    
    return ShrinkageSummary(
      products: changes,
      totalShrinkageQty: totalQtyChange,
      totalShrinkageValue: totalValueChange,
      warningCount: warningCount,
      criticalCount: criticalCount,
      windowStart: yesterdayData.windowStart,
      windowEnd: yesterdayData.windowEnd,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL QUERY ENGINE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Core shrinkage detection query - single optimized query
  Future<ShrinkageSummary> _detectShrinkage({
    required DateTime start,
    required DateTime end,
    required double absoluteThreshold,
    required double percentThreshold,
  }) async {
    try {
      // Single efficient query joining both sources
      final response = await _client.rpc('calculate_operational_shrinkage', params: {
        'start_date': start.toIso8601String(),
        'end_date': end.toIso8601String(),
      });
      
      if (response == null || (response as List).isEmpty) {
        return ShrinkageSummary(
          products: [],
          totalShrinkageQty: 0,
          totalShrinkageValue: 0,
          warningCount: 0,
          criticalCount: 0,
          windowStart: start,
          windowEnd: end,
        );
      }
      
      final products = (response)
          .map((row) => ProductShrinkage.fromDbRow(
            Map<String, dynamic>.from(row as Map),
            start,
            end,
            absoluteThreshold: absoluteThreshold,
            percentThreshold: percentThreshold,
          ))
          .where((p) => p.expectedQty > 0 || p.actualQty > 0) // Only products with activity
          .toList();
      
      // Calculate totals
      double totalQty = 0;
      double totalValue = 0;
      int warnings = 0;
      int critical = 0;
      
      for (final p in products) {
        totalQty += p.shrinkageQty.abs();
        totalValue += p.shrinkageValue;
        if (p.status == ShrinkageStatus.warning) warnings++;
        if (p.status == ShrinkageStatus.critical) critical++;
      }
      
      return ShrinkageSummary(
        products: products,
        totalShrinkageQty: totalQty,
        totalShrinkageValue: totalValue,
        warningCount: warnings,
        criticalCount: critical,
        windowStart: start,
        windowEnd: end,
      );
      
    } catch (e) {
      debugPrint('[SHRINKAGE] RPC failed, using fallback query: $e');
      // Fallback to client-side aggregation if RPC not available
      return _detectShrinkageFallback(
        start: start,
        end: end,
        absoluteThreshold: absoluteThreshold,
        percentThreshold: percentThreshold,
      );
    }
  }

  /// Fallback implementation using client-side aggregation
  /// Used when RPC is not available in the database
  Future<ShrinkageSummary> _detectShrinkageFallback({
    required DateTime start,
    required DateTime end,
    required double absoluteThreshold,
    required double percentThreshold,
  }) async {
    try {
      // Fetch sales data (expected usage)
      final salesData = await _fetchSalesByProduct(start, end);
      
      // Fetch stock movements (actual usage)
      final stockData = await _fetchStockMovementsByProduct(start, end);
      
      // Fetch inventory data for costs
      final costData = await _fetchInventoryCosts();
      
      // Merge and calculate shrinkage
      final allProductIds = {...salesData.keys, ...stockData.keys};
      final products = <ProductShrinkage>[];
      
      for (final productId in allProductIds) {
        final expected = salesData[productId]?['qty'] ?? 0.0;
        final actual = stockData[productId]?['qty'] ?? 0.0;
        final productName = salesData[productId]?['name'] ?? 
                           stockData[productId]?['name'] ?? 
                           'Unknown';
        final avgCost = costData[productId] ?? 0.0;
        
        // Skip products with no activity
        if (expected == 0 && actual == 0) continue;
        
        final shrinkage = actual - expected;
        double percent = 0.0;
        if (expected > 0) {
          percent = (shrinkage.abs() / expected) * 100;
        } else if (actual > 0) {
          percent = 100.0;
        }
        
        ShrinkageStatus status = ShrinkageStatus.normal;
        if (shrinkage.abs() > absoluteThreshold || percent > percentThreshold) {
          status = shrinkage.abs() > absoluteThreshold * 2 || percent > percentThreshold * 2
              ? ShrinkageStatus.critical
              : ShrinkageStatus.warning;
        }
        
        products.add(ProductShrinkage(
          productId: productId,
          productName: productName,
          expectedQty: expected,
          actualQty: actual,
          shrinkageQty: shrinkage,
          shrinkagePercent: percent,
          status: status,
          shrinkageValue: shrinkage.abs() * avgCost,
          windowStart: start,
          windowEnd: end,
        ));
      }
      
      // Calculate totals
      double totalQty = 0;
      double totalValue = 0;
      int warnings = 0;
      int critical = 0;
      
      for (final p in products) {
        totalQty += p.shrinkageQty.abs();
        totalValue += p.shrinkageValue;
        if (p.status == ShrinkageStatus.warning) warnings++;
        if (p.status == ShrinkageStatus.critical) critical++;
      }
      
      return ShrinkageSummary(
        products: products,
        totalShrinkageQty: totalQty,
        totalShrinkageValue: totalValue,
        warningCount: warnings,
        criticalCount: critical,
        windowStart: start,
        windowEnd: end,
      );
      
    } catch (e) {
      debugPrint('[SHRINKAGE] Fallback query failed: $e');
      return ShrinkageSummary(
        products: [],
        totalShrinkageQty: 0,
        totalShrinkageValue: 0,
        warningCount: 0,
        criticalCount: 0,
        windowStart: start,
        windowEnd: end,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATA FETCHING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch sales quantities by product from transaction_items
  Future<Map<String, Map<String, dynamic>>> _fetchSalesByProduct(
    DateTime start,
    DateTime end,
  ) async {
    final response = await _client
        .from('transaction_items')
        .select('''
          inventory_item_id,
          quantity,
          inventory_items!inner(id, name)
        ''')
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String())
        .not('inventory_item_id', 'is', null);
    
    final result = <String, Map<String, dynamic>>{};
    
    for (final row in response as List) {
      final id = row['inventory_item_id']?.toString();
      if (id == null) continue;
      
      final qty = (row['quantity'] as num?)?.toDouble() ?? 0.0;
      final inventoryData = row['inventory_items'] as Map<String, dynamic>?;
      final name = inventoryData?['name']?.toString() ?? 'Unknown';
      
      if (!result.containsKey(id)) {
        result[id] = {'qty': 0.0, 'name': name};
      }
      result[id]!['qty'] = (result[id]!['qty'] as double) + qty;
    }
    
    return result;
  }

  /// Fetch stock movement quantities by product (sales only)
  Future<Map<String, Map<String, dynamic>>> _fetchStockMovementsByProduct(
    DateTime start,
    DateTime end,
  ) async {
    final response = await _client
        .from('stock_movements')
        .select('''
          item_id,
          quantity,
          movement_type,
          inventory_items!inner(id, name)
        ''')
        .eq('movement_type', 'sale') // Sales only
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String());
    
    final result = <String, Map<String, dynamic>>{};
    
    for (final row in response as List) {
      final id = row['item_id']?.toString();
      if (id == null) continue;
      
      // quantity is negative for out movements, so we negate it to get positive usage
      final qty = -(row['quantity'] as num?)?.toDouble() ?? 0.0;
      final inventoryData = row['inventory_items'] as Map<String, dynamic>?;
      final name = inventoryData?['name']?.toString() ?? 'Unknown';
      
      if (!result.containsKey(id)) {
        result[id] = {'qty': 0.0, 'name': name};
      }
      result[id]!['qty'] = (result[id]!['qty'] as double) + qty;
    }
    
    return result;
  }

  /// Fetch average costs for all inventory items
  Future<Map<String, double>> _fetchInventoryCosts() async {
    final response = await _client
        .from('inventory_items')
        .select('id, average_cost, cost_price');
    
    final result = <String, double>{};
    
    for (final row in response as List) {
      final id = row['id']?.toString();
      if (id == null) continue;
      
      final avgCost = (row['average_cost'] as num?)?.toDouble() ??
                      (row['cost_price'] as num?)?.toDouble() ??
                      0.0;
      result[id] = avgCost;
    }
    
    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Quick check for today's shrinkage issues
  Future<List<ProductShrinkage>> getTodayAnomalies({
    double absoluteThreshold = defaultAbsoluteThreshold,
    double percentThreshold = defaultPercentThreshold,
  }) async {
    final today = DateTime.now();
    final summary = await detectDaily(
      today,
      absoluteThreshold: absoluteThreshold,
      percentThreshold: percentThreshold,
    );
    return summary.anomalies;
  }

  /// Get trending products (increasing shrinkage over time)
  Future<List<Map<String, dynamic>>> getTrendingIssues(int days) async {
    final results = <Map<String, dynamic>>[];
    
    // Compare today vs previous days
    final today = await detectDaily(DateTime.now());
    final yesterday = await detectDaily(DateTime.now().subtract(const Duration(days: 1)));
    
    for (final product in today.products.where((p) => p.status != ShrinkageStatus.normal)) {
      final prev = yesterday.products
          .firstWhere((p) => p.productId == product.productId,
              orElse: () => ProductShrinkage(
                productId: product.productId,
                productName: product.productName,
                expectedQty: 0,
                actualQty: 0,
                shrinkageQty: 0,
                shrinkagePercent: 0,
                status: ShrinkageStatus.normal,
                shrinkageValue: 0,
                windowStart: yesterday.windowStart,
                windowEnd: yesterday.windowEnd,
              ));
      
      final change = product.shrinkageQty - prev.shrinkageQty;
      if (change > 0.1) { // Significant increase
        results.add({
          'product': product.toJson(),
          'trend': 'increasing',
          'change_qty': change,
          'change_percent': prev.shrinkageQty > 0 
              ? (change / prev.shrinkageQty) * 100 
              : double.infinity,
        });
      }
    }
    
    return results;
  }
}
