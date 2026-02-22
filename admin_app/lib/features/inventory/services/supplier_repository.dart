import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import '../models/supplier.dart';

/// Blueprint §4.6: Supplier Management. CRUD only.
class SupplierRepository {
  final SupabaseClient _client;

  SupplierRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  Future<List<Supplier>> getSuppliers({bool activeOnly = false}) async {
    var q = _client.from('suppliers').select();
    if (activeOnly) {
      q = q.eq('is_active', true);
    }
    final list = await q.order('name');
    return (list as List)
        .map((e) => Supplier.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Supplier?> getSupplier(String id) async {
    final row = await _client
        .from('suppliers')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return Supplier.fromJson(row as Map<String, dynamic>);
  }

  Future<Supplier> createSupplier(Supplier supplier) async {
    final data = Map<String, dynamic>.from(supplier.toJson())
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');
    final response = await _client
        .from('suppliers')
        .insert(data)
        .select()
        .single();
    return Supplier.fromJson(response as Map<String, dynamic>);
  }

  Future<Supplier> updateSupplier(Supplier supplier) async {
    final data = Map<String, dynamic>.from(supplier.toJson())
      ..remove('id')
      ..remove('created_at');
    final response = await _client
        .from('suppliers')
        .update(data)
        .eq('id', supplier.id)
        .select()
        .single();
    return Supplier.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteSupplier(String id) async {
    await _client.from('suppliers').delete().eq('id', id);
  }
}
