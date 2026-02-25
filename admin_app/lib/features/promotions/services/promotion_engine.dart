import '../models/promotion.dart';
import '../models/promotion_product.dart';
import 'promotion_repository.dart';

/// One item in the basket (for engine evaluation).
class BasketItem {
  final String inventoryItemId;
  final double quantity;
  final double weightKg;
  final double unitPrice;
  final String? categoryId;

  const BasketItem({
    required this.inventoryItemId,
    this.quantity = 1,
    this.weightKg = 0,
    this.unitPrice = 0,
    this.categoryId,
  });

  double get lineTotal => quantity * unitPrice;
}

/// Result of evaluating a promotion against a basket — applicable with calculated reward.
class ApplicablePromotion {
  final Promotion promotion;
  final String summary; // e.g. "15% off", "Buy 2 Get 1 Free"
  final double? discountAmount;
  final bool manualApply;

  const ApplicablePromotion({
    required this.promotion,
    required this.summary,
    this.discountAmount,
    this.manualApply = false,
  });
}

/// Service for POS and loyalty app to evaluate which promotions apply to a basket.
class PromotionEngine {
  final PromotionRepository _repo = PromotionRepository();

  /// Load all active promotions for the given channel, then evaluate triggers and audience.
  Future<List<ApplicablePromotion>> evaluateBasket({
    required List<BasketItem> items,
    required double totalAmount,
    required String channel, // 'pos', 'loyalty_app', 'online'
    String? customerId,
    String? loyaltyTier,
  }) async {
    final promotions = await _repo.getAll(activeOnly: true);
    final now = DateTime.now();
    final dayIndex = now.weekday; // 1=Mon .. 7=Sun
    final dayLabels = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final currentDay = dayLabels[dayIndex - 1];
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final applicable = <ApplicablePromotion>[];

    for (final p in promotions) {
      if (!p.channels.contains(channel)) continue;
      if (!_matchesAudience(p, loyaltyTier)) continue;
      if (p.endDate != null && now.isAfter(DateTime(p.endDate!.year, p.endDate!.month, p.endDate!.day, 23, 59, 59))) continue;
      if (p.usageLimit != null && p.usageCount >= p.usageLimit!) continue;

      switch (p.promotionType) {
        case PromotionType.bogo:
          if (_triggerBogo(p, items)) {
            applicable.add(ApplicablePromotion(promotion: p, summary: _rewardSummary(p)));
          }
          break;
        case PromotionType.bundle:
          if (_triggerBundle(p, items)) {
            applicable.add(ApplicablePromotion(promotion: p, summary: _rewardSummary(p)));
          }
          break;
        case PromotionType.spendThreshold:
          if (_triggerSpendThreshold(p, totalAmount)) {
            applicable.add(ApplicablePromotion(promotion: p, summary: _rewardSummary(p), discountAmount: _calcSpendDiscount(p, totalAmount)));
          }
          break;
        case PromotionType.weightThreshold:
          if (_triggerWeightThreshold(p, items)) {
            applicable.add(ApplicablePromotion(promotion: p, summary: _rewardSummary(p)));
          }
          break;
        case PromotionType.timeBased:
          if (_triggerTimeBased(p, currentDay, currentTime)) {
            applicable.add(ApplicablePromotion(promotion: p, summary: _rewardSummary(p)));
          }
          break;
        case PromotionType.pointsMultiplier:
          applicable.add(ApplicablePromotion(promotion: p, summary: _rewardSummary(p)));
          break;
        case PromotionType.custom:
          final manual = p.triggerConfig['manual_apply'] == true;
          applicable.add(ApplicablePromotion(promotion: p, summary: p.triggerConfig['custom_rule']?.toString() ?? 'Custom', manualApply: manual));
          break;
      }
    }
    return applicable;
  }

  bool _matchesAudience(Promotion p, String? loyaltyTier) {
    if (p.audience.contains('all')) return true;
    if (loyaltyTier != null && p.audience.contains(loyaltyTier)) return true;
    return p.audience.contains('staff_only') || p.audience.contains('new_customers'); // caller can refine
  }

  bool _triggerBogo(Promotion p, List<BasketItem> items) {
    final buy = (p.triggerConfig['buy_quantity'] as num?)?.toInt() ?? 2;
    final triggerIds = p.products.where((e) => e.role == PromotionProductRole.triggerItem).map((e) => e.inventoryItemId).toSet();
    int count = 0;
    for (final i in items) {
      if (triggerIds.contains(i.inventoryItemId)) count += i.quantity.toInt();
    }
    return count >= buy;
  }

  bool _triggerBundle(Promotion p, List<BasketItem> items) {
    final allRequired = p.triggerConfig['all_required'] == true;
    final bundleIds = p.products.where((e) => e.role == PromotionProductRole.bundleItem).map((e) => e.inventoryItemId).toList();
    if (bundleIds.isEmpty) return false;
    final inBasket = items.map((e) => e.inventoryItemId).toSet();
    if (allRequired) {
      return bundleIds.every((id) => inBasket.contains(id));
    }
    return bundleIds.any((id) => inBasket.contains(id));
  }

  bool _triggerSpendThreshold(Promotion p, double totalAmount) {
    final minSpend = (p.triggerConfig['min_spend'] as num?)?.toDouble() ?? 0;
    return totalAmount >= minSpend;
  }

  double? _calcSpendDiscount(Promotion p, double totalAmount) {
    final pct = (p.rewardConfig['value'] as num?)?.toDouble() ?? (p.rewardConfig['discount_pct'] as num?)?.toDouble();
    if (pct != null) return totalAmount * (pct / 100);
    final fixed = (p.rewardConfig['value'] as num?)?.toDouble();
    return fixed;
  }

  bool _triggerWeightThreshold(Promotion p, List<BasketItem> items) {
    final minKg = (p.triggerConfig['min_weight_kg'] as num?)?.toDouble() ?? 0;
    double totalKg = 0;
    for (final i in items) totalKg += i.weightKg * i.quantity;
    return totalKg >= minKg;
  }

  bool _triggerTimeBased(Promotion p, String currentDay, String currentTime) {
    if (p.daysOfWeek.isNotEmpty && !p.daysOfWeek.any((d) => d.toLowerCase().startsWith(currentDay.substring(0, 2)))) return false;
    final start = p.startTime ?? p.triggerConfig['start_time'] as String?;
    final end = p.endTime ?? p.triggerConfig['end_time'] as String?;
    if (start != null && end != null && (currentTime.compareTo(start) < 0 || currentTime.compareTo(end) > 0)) return false;
    return true;
  }

  String _rewardSummary(Promotion p) {
    final type = p.rewardConfig['type'] as String?;
    switch (type) {
      case 'free_item':
        return 'Free item';
      case 'discount_pct':
        final v = p.rewardConfig['value'];
        return '${v ?? 0}% off';
      case 'discount_rand':
        final v = p.rewardConfig['value'];
        return 'R${v ?? 0} off';
      case 'points_multiplier':
        final m = p.rewardConfig['multiplier'];
        return '${m ?? 1}x points';
      case 'digital_voucher':
        return 'Digital voucher';
      case 'partner_voucher':
        return 'Partner voucher';
      case 'custom':
        return p.rewardConfig['description']?.toString() ?? 'Custom';
      default:
        return 'Reward';
    }
  }
}
