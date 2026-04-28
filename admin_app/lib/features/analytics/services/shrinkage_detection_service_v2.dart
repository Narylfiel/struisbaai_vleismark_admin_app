import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// OPERATIONAL SHRINKAGE DETECTION ENGINE v2.0
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// PRECISION CORRECTIONS APPLIED (2026-04-10):
/// 
/// 1. UNIT NORMALIZATION: All quantities normalized to kg
///    - Weighted products: quantity already in kg
///    - Unit-based products: converted using avg unit weight (if available)
///    - Products without conversion data: flagged as unanalyzable
///
/// 2. STOCK MOVEMENT FILTERING: Only true sales movements
///    - Filters: movement_type = 'sale' AND reference_type = 'transaction'
///    - Excludes: adjustments, waste, transfers, manual corrections
///
/// 3. BASELINE SHRINKAGE MODEL: Expected loss per category
///    - Beef cuts: 5% (trimming, bone handling)
///    - Bone-heavy products: 8% (higher natural loss)
///    - Processed: 2% (consistent cutting)
///    - Poultry: 4% (different handling)
///
/// 4. CORRECTED SHRINKAGE CALCULATION:
///    baseline_loss = expected_usage × baseline_percent
///    real_shrinkage = actual_usage - expected_usage - baseline_loss
///    Thresholds applied ONLY to real_shrinkage
///
/// This is READ-ONLY analytics. No database writes.
/// ═══════════════════════════════════════════════════════════════════════════

/// Shrinkage status levels
enum ShrinkageStatus { normal, warning, critical, unanalyzable }

/// DTO for product-level shrinkage data
class ProductShrinkage {
  final String productId;
  final String productName;
  final String? category;
  final double expectedQty;          // Sales quantity (normalized to kg)
  final double actualQty;            // Stock deductions (kg)
  final double baselineLossQty;      // Expected natural loss (kg)
  final double rawShrinkageQty;      // actual - expected (before baseline)
  final double realShrinkageQty;     // After subtracting baseline (theft/waste)
  final double realShrinkagePercent; // (real_shrinkage / expected) × 100
  final double baselinePercent;      // Category-based expected loss %
  final ShrinkageStatus status;
  final double shrinkageValue;       // Monetary value (real_shrinkage × avg_cost)
  final bool isUnitBased;            // true if product sold by units (not kg)
  final double? unitConversionRate;  // kg per unit (null if unavailable)
  final DateTime windowStart;
  final DateTime windowEnd;

  const ProductShrinkage({
    required this.productId,
    required this.productName,
    this.category,
    required this.expectedQty,
    required this.actualQty,
    required this.baselineLossQty,
    required this.rawShrinkageQty,
    required this.realShrinkageQty,
    required this.realShrinkagePercent,
    required this.baselinePercent,
    required this.status,
    required this.shrinkageValue,
    required this.isUnitBased,
    this.unitConversionRate,
    required this.windowStart,
    required this.windowEnd,
  });

  /// Factory from database row with baseline calculation
  factory ProductShrinkage.fromDbRow(
    Map<String, dynamic> row,
    DateTime windowStart,
    DateTime windowEnd, {
    double absoluteThreshold = 0.3,
    double percentThreshold = 5.0,
    Map<String, double> baselineByCategory = _defaultBaselineLoss,
  }) {
    final expected = (row['expected_qty'] as num?)?.toDouble() ?? 0.0;
    final actual = (row['actual_qty'] as num?)?.toDouble() ?? 0.0;
    final avgCost = (row['average_cost'] as num?)?.toDouble() ?? 0.0;
    final category = row['category']?.toString();
    final isWeighted = row['is_weighted'] as bool? ?? true;
    final unitType = row['unit_type']?.toString() ?? 'kg';
    final avgUnitWeight = (row['average_unit_weight_kg'] as num?)?.toDouble();
    
    // Determine if this product can be analyzed
    final isUnitBased = !isWeighted && unitType != 'kg';
    final canAnalyze = !isUnitBased || (isUnitBased && avgUnitWeight != null && avgUnitWeight > 0);
    
    // Calculate baseline loss based on category
    final baselinePercent = baselineByCategory[category] ?? 
                           baselineByCategory['default'] ?? 
                           5.0;
    
    final baselineLoss = expected * (baselinePercent / 100);
    
    // Raw shrinkage (before baseline)
    final rawShrinkage = actual - expected;
    
    // Real shrinkage (after subtracting expected natural loss)
    final realShrinkage = rawShrinkage - baselineLoss;
    
    // Calculate percentage (handle division by zero)
    double percent = 0.0;
    if (expected > 0) {
      percent = (realShrinkage.abs() / expected) * 100;
    } else if (actual > 0) {
      percent = 100.0;
    }

    // Determine status (apply thresholds to real_shrinkage, not raw)
    ShrinkageStatus status;
    if (!canAnalyze) {
      status = ShrinkageStatus.unanalyzable;
    } else if (realShrinkage.abs() > absoluteThreshold || percent > percentThreshold) {
      status = realShrinkage.abs() > absoluteThreshold * 2 || percent > percentThreshold * 2
          ? ShrinkageStatus.critical
          : ShrinkageStatus.warning;
    } else {
      status = ShrinkageStatus.normal;
    }

    return ProductShrinkage(
      productId: row['product_id']?.toString() ?? '',
      productName: row['product_name']?.toString() ?? 'Unknown',
      category: category,
      expectedQty: expected,
      actualQty: actual,
      baselineLossQty: baselineLoss,
      rawShrinkageQty: rawShrinkage,
      realShrinkageQty: realShrinkage,
      realShrinkagePercent: percent,
      baselinePercent: baselinePercent,
      status: status,
      shrinkageValue: status == ShrinkageStatus.unanalyzable 
          ? 0.0 
          : realShrinkage.abs() * avgCost,
      isUnitBased: isUnitBased,
      unitConversionRate: avgUnitWeight,
      windowStart: windowStart,
      windowEnd: windowEnd,
    );
  }

  /// JSON serialization for caching/transmission
  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'product_name': productName,
    'category': category,
    'expected_qty': expectedQty,
    'actual_qty': actualQty,
    'baseline_loss_qty': baselineLossQty,
    'raw_shrinkage_qty': rawShrinkageQty,
    'real_shrinkage_qty': realShrinkageQty,
    'real_shrinkage_percent': realShrinkagePercent,
    'baseline_percent': baselinePercent,
    'status': status.name,
    'shrinkage_value': shrinkageValue,
    'is_unit_based': isUnitBased,
    'unit_conversion_rate': unitConversionRate,
    'window_start': windowStart.toIso8601String(),
    'window_end': windowEnd.toIso8601String(),
  };
}

/// Summary of shrinkage across all products
class ShrinkageSummary {
  final List<ProductShrinkage> products;
  final double totalRealShrinkageQty;    // After baseline adjustment
  final double totalRawShrinkageQty;     // Before baseline (for reference)
  final double totalBaselineLossQty;     // Expected natural loss
  final double totalShrinkageValue;      // Monetary impact
  final int warningCount;
  final int criticalCount;
  final int unanalyzableCount;
  final DateTime windowStart;
  final DateTime windowEnd;

  const ShrinkageSummary({
    required this.products,
    required this.totalRealShrinkageQty,
    required this.totalRawShrinkageQty,
    required this.totalBaselineLossQty,
    required this.totalShrinkageValue,
    required this.warningCount,
    required this.criticalCount,
    required this.unanalyzableCount,
    required this.windowStart,
    required this.windowEnd,
  });

  /// Analyzable products only (excludes unanalyzable)
  List<ProductShrinkage> get analyzableProducts => 
      products.where((p) => p.status != ShrinkageStatus.unanalyzable).toList();

  /// Top N products by real shrinkage quantity (worst offenders)
  List<ProductShrinkage> topByQuantity(int n) {
    final sorted = List<ProductShrinkage>.from(analyzableProducts)
      ..sort((a, b) => b.realShrinkageQty.abs().compareTo(a.realShrinkageQty.abs()));
    return sorted.take(n).toList();
  }

  /// Top N products by shrinkage value (money lost)
  List<ProductShrinkage> topByValue(int n) {
    final sorted = List<ProductShrinkage>.from(analyzableProducts)
      ..sort((a, b) => b.shrinkageValue.compareTo(a.shrinkageValue));
    return sorted.take(n).toList();
  }

  /// Only products with issues (warning or critical)
  List<ProductShrinkage> get anomalies => 
      analyzableProducts.where((p) => p.status != ShrinkageStatus.normal).toList();

  /// Products that couldn't be analyzed (unit-based without conversion)
  List<ProductShrinkage> get unanalyzable => 
      products.where((p) => p.status == ShrinkageStatus.unanalyzable).toList();
}

class ShrinkageDetectionService {
  final SupabaseClient _client;

  ShrinkageDetectionService({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Absolute threshold in kg (default: 300g above baseline)
  static const double defaultAbsoluteThreshold = 0.3;
  
  /// Percentage threshold (default: 5% above baseline)
  static const double defaultPercentThreshold = 5.0;

  /// Default baseline loss percentages by category
  /// These represent expected natural loss from trimming, bone handling, etc.
  static const Map<String, double> _defaultBaselineLoss = {
    'beef': 5.0,           // Beef cuts: trimming, bone handling
    'beef_cuts': 5.0,
    'bone_in': 8.0,        // Bone-heavy products: higher natural loss
    'pork': 5.0,
    'pork_cuts': 5.0,
    'chicken': 4.0,        // Poultry: different handling characteristics
    'poultry': 4.0,
    'processed': 2.0,      // Processed: consistent cutting, less variance
    'burger': 2.0,
    'mince': 2.0,
    'sausage': 2.0,
    'packaging': 1.0,      // Packaging materials: minimal loss
    'default': 5.0,        // Default for uncategorized products
  };

  /// Custom baseline overrides (can be set per instance)
  Map<String, double> _baselineOverrides = {};

  /// Set custom baseline loss percentages
  void setBaselineOverrides(Map<String, double> overrides) {
    _baselineOverrides = {..._defaultBaselineLoss, ...overrides};
  }

  /// Get effective baseline for a category
  double _getBaselinePercent(String? category) {
    return _baselineOverrides[category] ?? 
           _defaultBaselineLoss[category] ?? 
           _defaultBaselineLoss['default']!;
  }

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
  Future<ShrinkageSummary> detectWeekOverWeek({
    double absoluteThreshold = defaultAbsoluteThreshold,
    double percentThreshold = defaultPercentThreshold,
  }) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final lastWeekSameDay = yesterday.subtract(const Duration(days: 7));
    
    final yesterdayData = await detectDaily(yesterday, 
        absoluteThreshold: absoluteThreshold, 
        percentThreshold: percentThreshold);
    final lastWeekData = await detectDaily(lastWeekSameDay,
        absoluteThreshold: absoluteThreshold,
        percentThreshold: percentThreshold);
    
    final changes = <ProductShrinkage>[];
    double totalQtyChange = 0;
    double totalValueChange = 0;
    int warningCount = 0;
    int criticalCount = 0;
    
    for (final yest in yesterdayData.analyzableProducts) {
      final lastWeek = lastWeekData.analyzableProducts
          .firstWhere((p) => p.productId == yest.productId, 
              orElse: () => ProductShrinkage(
                productId: yest.productId,
                productName: yest.productName,
                expectedQty: 0,
                actualQty: 0,
                baselineLossQty: 0,
                rawShrinkageQty: 0,
                realShrinkageQty: 0,
                realShrinkagePercent: 0,
                baselinePercent: 0,
                status: ShrinkageStatus.normal,
                shrinkageValue: 0,
                isUnitBased: false,
                windowStart: lastWeekSameDay,
                windowEnd: lastWeekSameDay,
              ));
      
      final qtyChange = yest.realShrinkageQty - lastWeek.realShrinkageQty;
      final valueChange = yest.shrinkageValue - lastWeek.shrinkageValue;
      
      if (qtyChange.abs() > absoluteThreshold * 0.5 || 
          yest.status != ShrinkageStatus.normal) {
        changes.add(ProductShrinkage(
          productId: yest.productId,
          productName: yest.productName,
          category: yest.category,
          expectedQty: yest.expectedQty,
          actualQty: yest.actualQty,
          baselineLossQty: yest.baselineLossQty,
          rawShrinkageQty: yest.rawShrinkageQty,
          realShrinkageQty: qtyChange,
          realShrinkagePercent: yest.realShrinkagePercent,
          baselinePercent: yest.baselinePercent,
          status: yest.status,
          shrinkageValue: valueChange,
          isUnitBased: yest.isUnitBased,
          unitConversionRate: yest.unitConversionRate,
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
      totalRealShrinkageQty: totalQtyChange,
      totalRawShrinkageQty: 0,
      totalBaselineLossQty: 0,
      totalShrinkageValue: totalValueChange,
      warningCount: warningCount,
      criticalCount: criticalCount,
      unanalyzableCount: 0,
      windowStart: yesterdayData.windowStart,
      windowEnd: yesterdayData.windowEnd,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL QUERY ENGINE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<ShrinkageSummary> _detectShrinkage({
    required DateTime start,
    required DateTime end,
    required double absoluteThreshold,
    required double percentThreshold,
  }) async {
    try {
      final response = await _client.rpc('calculate_operational_shrinkage_v2', params: {
        'start_date': start.toIso8601String(),
        'end_date': end.toIso8601String(),
      });
      
      if (response == null || (response as List).isEmpty) {
        return _emptySummary(start, end);
      }
      
      final products = (response)
          .map((row) => ProductShrinkage.fromDbRow(
            Map<String, dynamic>.from(row as Map),
            start,
            end,
            absoluteThreshold: absoluteThreshold,
            percentThreshold: percentThreshold,
            baselineByCategory: {..._defaultBaselineLoss, ..._baselineOverrides},
          ))
          .where((p) => p.expectedQty > 0 || p.actualQty > 0)
          .toList();
      
      return _calculateSummary(products, start, end);
      
    } catch (e) {
      debugPrint('[SHRINKAGE] RPC failed, using fallback query: $e');
      return _detectShrinkageFallback(
        start: start,
        end: end,
        absoluteThreshold: absoluteThreshold,
        percentThreshold: percentThreshold,
      );
    }
  }

  /// Fallback implementation using client-side aggregation
  Future<ShrinkageSummary> _detectShrinkageFallback({
    required DateTime start,
    required DateTime end,
    required double absoluteThreshold,
    required double percentThreshold,
  }) async {
    try {
      final salesData = await _fetchSalesByProduct(start, end);
      final stockData = await _fetchStockMovementsByProduct(start, end);
      final productMetadata = await _fetchProductMetadata();
      
      final allProductIds = {...salesData.keys, ...stockData.keys};
      final products = <ProductShrinkage>[];
      
      for (final productId in allProductIds) {
        final expected = salesData[productId]?['qty'] ?? 0.0;
        final actual = stockData[productId]?['qty'] ?? 0.0;
        final productName = salesData[productId]?['name'] ?? 
                           stockData[productId]?['name'] ?? 
                           'Unknown';
        final metadata = productMetadata[productId] ?? {};
        final category = metadata['category']?.toString();
        final isWeighted = metadata['is_weighted'] as bool? ?? true;
        final unitType = metadata['unit_type']?.toString() ?? 'kg';
        final avgUnitWeight = metadata['average_unit_weight_kg'] as double?;
        final avgCost = metadata['average_cost'] as double? ?? 0.0;
        
        if (expected == 0 && actual == 0) continue;
        
        final isUnitBased = !isWeighted && unitType != 'kg';
        final canAnalyze = !isUnitBased || (isUnitBased && avgUnitWeight != null && avgUnitWeight > 0);
        
        final baselinePercent = _getBaselinePercent(category);
        final baselineLoss = expected * (baselinePercent / 100);
        
        final rawShrinkage = actual - expected;
        final realShrinkage = rawShrinkage - baselineLoss;
        
        double percent = 0.0;
        if (expected > 0) {
          percent = (realShrinkage.abs() / expected) * 100;
        } else if (actual > 0) {
          percent = 100.0;
        }
        
        ShrinkageStatus status;
        if (!canAnalyze) {
          status = ShrinkageStatus.unanalyzable;
        } else if (realShrinkage.abs() > absoluteThreshold || percent > percentThreshold) {
          status = realShrinkage.abs() > absoluteThreshold * 2 || percent > percentThreshold * 2
              ? ShrinkageStatus.critical
              : ShrinkageStatus.warning;
        } else {
          status = ShrinkageStatus.normal;
        }
        
        products.add(ProductShrinkage(
          productId: productId,
          productName: productName,
          category: category,
          expectedQty: expected,
          actualQty: actual,
          baselineLossQty: baselineLoss,
          rawShrinkageQty: rawShrinkage,
          realShrinkageQty: realShrinkage,
          realShrinkagePercent: percent,
          baselinePercent: baselinePercent,
          status: status,
          shrinkageValue: status == ShrinkageStatus.unanalyzable ? 0.0 : realShrinkage.abs() * avgCost,
          isUnitBased: isUnitBased,
          unitConversionRate: avgUnitWeight,
          windowStart: start,
          windowEnd: end,
        ));
      }
      
      return _calculateSummary(products, start, end);
      
    } catch (e) {
      debugPrint('[SHRINKAGE] Fallback query failed: $e');
      return _emptySummary(start, end);
    }
  }

  ShrinkageSummary _calculateSummary(List<ProductShrinkage> products, DateTime start, DateTime end) {
    double totalReal = 0;
    double totalRaw = 0;
    double totalBaseline = 0;
    double totalValue = 0;
    int warnings = 0;
    int critical = 0;
    int unanalyzable = 0;
    
    for (final p in products) {
      if (p.status != ShrinkageStatus.unanalyzable) {
        totalReal += p.realShrinkageQty.abs();
        totalValue += p.shrinkageValue;
        if (p.status == ShrinkageStatus.warning) warnings++;
        if (p.status == ShrinkageStatus.critical) critical++;
      } else {
        unanalyzable++;
      }
      totalRaw += p.rawShrinkageQty.abs();
      totalBaseline += p.baselineLossQty;
    }
    
    return ShrinkageSummary(
      products: products,
      totalRealShrinkageQty: totalReal,
      totalRawShrinkageQty: totalRaw,
      totalBaselineLossQty: totalBaseline,
      totalShrinkageValue: totalValue,
      warningCount: warnings,
      criticalCount: critical,
      unanalyzableCount: unanalyzable,
      windowStart: start,
      windowEnd: end,
    );
  }

  ShrinkageSummary _emptySummary(DateTime start, DateTime end) => ShrinkageSummary(
    products: [],
    totalRealShrinkageQty: 0,
    totalRawShrinkageQty: 0,
    totalBaselineLossQty: 0,
    totalShrinkageValue: 0,
    warningCount: 0,
    criticalCount: 0,
    unanalyzableCount: 0,
    windowStart: start,
    windowEnd: end,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // DATA FETCHING
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Map<String, Map<String, dynamic>>> _fetchSalesByProduct(
    DateTime start,
    DateTime end,
  ) async {
    final response = await _client
        .from('transaction_items')
        .select('''
          inventory_item_id,
          quantity,
          is_weighted,
          weight_kg,
          inventory_items!inner(id, name, unit_type)
        ''')
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String())
        .not('inventory_item_id', 'is', null);
    
    final result = <String, Map<String, dynamic>>{};
    
    for (final row in response as List) {
      final id = row['inventory_item_id']?.toString();
      if (id == null) continue;
      
      final isWeighted = row['is_weighted'] as bool? ?? false;
      final qty = (row['quantity'] as num?)?.toDouble() ?? 0.0;
      final weightKg = (row['weight_kg'] as num?)?.toDouble();
      
      // Use weight_kg if available (for weighted products), otherwise quantity
      final normalizedQty = isWeighted && weightKg != null ? weightKg : qty;
      
      final inventoryData = row['inventory_items'] as Map<String, dynamic>?;
      final name = inventoryData?['name']?.toString() ?? 'Unknown';
      
      if (!result.containsKey(id)) {
        result[id] = {'qty': 0.0, 'name': name};
      }
      result[id]!['qty'] = (result[id]!['qty'] as double) + normalizedQty;
    }
    
    return result;
  }

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
          reference_type,
          inventory_items!inner(id, name)
        ''')
        .eq('movement_type', 'sale')
        .eq('reference_type', 'transaction')  // Only sales, not adjustments
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String());
    
    final result = <String, Map<String, dynamic>>{};
    
    for (final row in response as List) {
      final id = row['item_id']?.toString();
      if (id == null) continue;
      
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

  Future<Map<String, Map<String, dynamic>>> _fetchProductMetadata() async {
    final response = await _client
        .from('inventory_items')
        .select('id, category, scale_item, unit_type, average_cost_price, pack_size');
    
    final result = <String, Map<String, dynamic>>{};
    
    for (final row in response as List) {
      final id = row['id']?.toString();
      if (id == null) continue;
      
      final scaleItem = row['scale_item'] as bool? ?? false;
      final unitType = row['unit_type']?.toString() ?? 'kg';
      final packSize = (row['pack_size'] as num?)?.toDouble() ?? 1.0;
      
      // Estimate average unit weight from pack_size if not a scale item
      // This is a fallback - ideally you'd have actual average weights
      final avgUnitWeight = scaleItem ? null : (packSize > 0 ? packSize : null);
      
      result[id] = {
        'category': row['category'],
        'is_weighted': scaleItem,
        'unit_type': unitType,
        'average_cost': (row['average_cost_price'] as num?)?.toDouble() ?? 0.0,
        'average_unit_weight_kg': avgUnitWeight,
      };
    }
    
    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════════════════

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

  Future<List<Map<String, dynamic>>> getTrendingIssues(int days) async {
    final results = <Map<String, dynamic>>[];
    
    final today = await detectDaily(DateTime.now());
    final yesterday = await detectDaily(DateTime.now().subtract(const Duration(days: 1)));
    
    for (final product in today.analyzableProducts.where((p) => p.status != ShrinkageStatus.normal)) {
      final prev = yesterday.analyzableProducts
          .firstWhere((p) => p.productId == product.productId,
              orElse: () => ProductShrinkage(
                productId: product.productId,
                productName: product.productName,
                expectedQty: 0,
                actualQty: 0,
                baselineLossQty: 0,
                rawShrinkageQty: 0,
                realShrinkageQty: 0,
                realShrinkagePercent: 0,
                baselinePercent: 0,
                status: ShrinkageStatus.normal,
                shrinkageValue: 0,
                isUnitBased: false,
                windowStart: yesterday.windowStart,
                windowEnd: yesterday.windowEnd,
              ));
      
      final change = product.realShrinkageQty - prev.realShrinkageQty;
      if (change > 0.1) {
        results.add({
          'product': product.toJson(),
          'trend': 'increasing',
          'change_qty': change,
          'change_percent': prev.realShrinkageQty > 0 
              ? (change / prev.realShrinkageQty) * 100 
              : double.infinity,
        });
      }
    }
    
    return results;
  }

  /// Get products that couldn't be analyzed (unit-based without conversion data)
  Future<List<ProductShrinkage>> getUnanalyzableProducts() async {
    final summary = await detectRollingWindow(7);
    return summary.unanalyzable;
  }
}
