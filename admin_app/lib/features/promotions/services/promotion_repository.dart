import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../models/promotion.dart';
import '../models/promotion_product.dart';

class PromotionRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// Format time string to HH:mm:ss for DB.
  static String? _formatTimeForDb(String? t) {
    if (t == null || t.trim().isEmpty) return null;
    final parts = t.trim().split(':');
    final h = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 0) : 0;
    final m = parts.length >= 2 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:00';
  }

  /// Build promotions insert/update payload with exact DB column names.
  Map<String, dynamic> _promotionPayload(Promotion promo, {bool forInsert = false}) {
    final payload = <String, dynamic>{
      'name': promo.name,
      'description': promo.description,
      'status': promo.status.dbValue,
      'promotion_type': promo.promotionType.dbValue,
      'trigger_config': promo.triggerConfig,
      'reward_config': promo.rewardConfig,
      'audience': promo.audience,
      'channels': promo.channels,
      'start_date': promo.startDate != null ? promo.startDate!.toIso8601String().substring(0, 10) : null,
      'end_date': promo.endDate != null ? promo.endDate!.toIso8601String().substring(0, 10) : null,
      'start_time': _formatTimeForDb(promo.startTime),
      'end_time': _formatTimeForDb(promo.endTime),
      'days_of_week': promo.daysOfWeek,
      'usage_limit': promo.usageLimit,
      'usage_count': promo.usageCount,
      'requires_manual_activation': promo.requiresManualActivation,
      'created_by': promo.createdBy,
    };
    if (!forInsert) {
      payload['updated_at'] = DateTime.now().toIso8601String();
    }
    if (forInsert && promo.id.isNotEmpty) {
      payload['id'] = promo.id;
    }
    return payload;
  }

  /// Build promotion_products insert payload: only promotion_id, inventory_item_id, role, quantity.
  Map<String, dynamic> _productPayload(PromotionProduct p, String promotionId) {
    return {
      'promotion_id': promotionId,
      'inventory_item_id': p.inventoryItemId,
      'role': p.role.dbValue,
      'quantity': (p.quantity).toDouble(),
    };
  }

  /// Get all promotions, optionally only active. Joins promotion_products.
  Future<List<Promotion>> getAll({bool activeOnly = false}) async {
    var query = _client.from('promotions').select();
    if (activeOnly) {
      query = query.eq('status', 'active');
    }
    final response = await query.order('created_at', ascending: false);
    final list = (response as List).map((e) => Promotion.fromJson(e as Map<String, dynamic>)).toList();
    for (final p in list) {
      p.products = await getProductsForPromotion(p.id);
    }
    return list;
  }

  /// Get promotion_products for a promotion (used after select).
  Future<List<PromotionProduct>> getProductsForPromotion(String promotionId) async {
    final response = await _client
        .from('promotion_products')
        .select()
        .eq('promotion_id', promotionId);
    return (response as List).map((e) => PromotionProduct.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Promotion?> getById(String id) async {
    final response = await _client.from('promotions').select().eq('id', id).maybeSingle();
    if (response == null) return null;
    final promo = Promotion.fromJson(response as Map<String, dynamic>);
    promo.products = await getProductsForPromotion(id);
    return promo;
  }

  /// Create promotion and its promotion_products. Returns created promotion with id.
  Future<Promotion> create(Promotion promo, List<PromotionProduct> products) async {
    final payload = _promotionPayload(promo, forInsert: true);
    try {
      final response = await _client.from('promotions').insert(payload).select().single();
      final created = Promotion.fromJson(response as Map<String, dynamic>);
      final promoId = created.id;
      for (final p in products) {
        final row = _productPayload(p, promoId);
        try {
          await _client.from('promotion_products').insert(row);
        } catch (e) {
          debugPrint('Promotion product insert error: $e');
          rethrow;
        }
      }
      created.products = await getProductsForPromotion(promoId);
      return created;
    } catch (e) {
      debugPrint('Promotion save error: $e');
      rethrow;
    }
  }

  /// Update promotion and replace promotion_products.
  Future<Promotion> update(Promotion promo, List<PromotionProduct> products) async {
    try {
      final payload = _promotionPayload(promo, forInsert: false);
      await _client.from('promotions').update(payload).eq('id', promo.id);
    } catch (e) {
      debugPrint('Promotion update error: $e');
      rethrow;
    }
    await _client.from('promotion_products').delete().eq('promotion_id', promo.id);
    for (final p in products) {
      final row = _productPayload(p, promo.id);
      try {
        await _client.from('promotion_products').insert(row);
      } catch (e) {
        debugPrint('Promotion product insert error: $e');
        rethrow;
      }
    }
    final updated = await getById(promo.id);
    return updated ?? promo;
  }

  Future<Promotion> activate(String id) async {
    final response = await _client.from('promotions').update({'status': 'active', 'updated_at': DateTime.now().toIso8601String()}).eq('id', id).select().single();
    return Promotion.fromJson(response as Map<String, dynamic>);
  }

  Future<Promotion> pause(String id) async {
    final response = await _client.from('promotions').update({'status': 'paused', 'updated_at': DateTime.now().toIso8601String()}).eq('id', id).select().single();
    return Promotion.fromJson(response as Map<String, dynamic>);
  }

  Future<Promotion> cancel(String id) async {
    final response = await _client.from('promotions').update({'status': 'cancelled', 'updated_at': DateTime.now().toIso8601String()}).eq('id', id).select().single();
    return Promotion.fromJson(response as Map<String, dynamic>);
  }

  /// Hard delete only if status == draft. Cascade deletes promotion_products.
  Future<void> delete(String id) async {
    final row = await _client.from('promotions').select('status').eq('id', id).maybeSingle();
    if (row == null) return;
    if ((row['status'] as String?) != 'draft') {
      throw StateError('Can only delete promotions with status draft');
    }
    await _client.from('promotion_products').delete().eq('promotion_id', id);
    await _client.from('promotions').delete().eq('id', id);
  }
}
