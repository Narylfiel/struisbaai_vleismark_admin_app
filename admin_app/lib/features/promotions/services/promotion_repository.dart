import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../models/promotion.dart';
import '../models/promotion_product.dart';

class PromotionRepository {
  final SupabaseClient _client = SupabaseService.client;

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
    final payload = promo.toJson();
    payload.remove('id'); // let DB generate or use uuid in app
    final insertId = promo.id.isEmpty ? null : promo.id;
    if (insertId != null) payload['id'] = insertId;
    final response = await _client.from('promotions').insert(payload).select().single();
    final created = Promotion.fromJson(response as Map<String, dynamic>);
    final promoId = created.id;
    for (final p in products) {
      final row = p.toJson();
      row['promotion_id'] = promoId;
      row.remove('id');
      await _client.from('promotion_products').insert(row);
    }
    created.products = await getProductsForPromotion(promoId);
    return created;
  }

  /// Update promotion and replace promotion_products.
  Future<Promotion> update(Promotion promo, List<PromotionProduct> products) async {
    await _client.from('promotions').update(promo.toJson()).eq('id', promo.id);
    await _client.from('promotion_products').delete().eq('promotion_id', promo.id);
    for (final p in products) {
      final row = p.toJson();
      row['promotion_id'] = promo.id;
      if (row['id'] == null || row['id'] == '') row.remove('id');
      await _client.from('promotion_products').insert(row);
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
