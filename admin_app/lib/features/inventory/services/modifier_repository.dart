import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import '../models/modifier_group.dart';
import '../models/modifier_item.dart';

/// Blueprint §4.3: Modifier groups and items. CRUD only; no raw maps in API.
/// POS reads modifier_groups + modifier_items; product.modifier_group_ids links groups to products.
class ModifierRepository {
  final SupabaseClient _client;

  ModifierRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  // ---------- Modifier Groups ----------

  Future<List<ModifierGroup>> getGroups({bool activeOnly = false}) async {
    var q = _client.from('modifier_groups').select();
    if (activeOnly) {
      q = q.eq('is_active', true);
    }
    final list = await q.order('sort_order', ascending: true).order('name');
    return (list as List)
        .map((e) => ModifierGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ModifierGroup?> getGroup(String id) async {
    final row = await _client
        .from('modifier_groups')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return ModifierGroup.fromJson(row as Map<String, dynamic>);
  }

  Future<ModifierGroup> createGroup(ModifierGroup group) async {
    final data = Map<String, dynamic>.from(group.toJson())
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');
    final response = await _client
        .from('modifier_groups')
        .insert(data)
        .select()
        .single();
    return ModifierGroup.fromJson(response as Map<String, dynamic>);
  }

  Future<ModifierGroup> updateGroup(ModifierGroup group) async {
    final data = Map<String, dynamic>.from(group.toJson())
      ..remove('id')
      ..remove('created_at');
    final response = await _client
        .from('modifier_groups')
        .update(data)
        .eq('id', group.id)
        .select()
        .single();
    return ModifierGroup.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteGroup(String id) async {
    await _client.from('modifier_groups').delete().eq('id', id);
  }

  // ---------- Modifier Items ----------

  Future<List<ModifierItem>> getItemsByGroup(String groupId) async {
    final list = await _client
        .from('modifier_items')
        .select()
        .eq('group_id', groupId)
        .order('sort_order', ascending: true)
        .order('name');
    return (list as List)
        .map((e) => ModifierItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ModifierItem?> getItem(String id) async {
    final row = await _client
        .from('modifier_items')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return ModifierItem.fromJson(row as Map<String, dynamic>);
  }

  Future<ModifierItem> createItem(ModifierItem item) async {
    final data = Map<String, dynamic>.from(item.toJson())
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');
    final response = await _client
        .from('modifier_items')
        .insert(data)
        .select()
        .single();
    return ModifierItem.fromJson(response as Map<String, dynamic>);
  }

  Future<ModifierItem> updateItem(ModifierItem item) async {
    final data = Map<String, dynamic>.from(item.toJson())
      ..remove('id')
      ..remove('created_at');
    final response = await _client
        .from('modifier_items')
        .update(data)
        .eq('id', item.id)
        .select()
        .single();
    return ModifierItem.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteItem(String id) async {
    await _client.from('modifier_items').delete().eq('id', id);
  }
}
