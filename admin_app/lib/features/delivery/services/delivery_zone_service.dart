import 'package:admin_app/core/services/base_service.dart';

class DeliveryZoneService extends BaseService {
  Future<List<Map<String, dynamic>>> fetchZones() async {
    final response = await executeQuery(
      () => client.from('delivery_zones').select().order('sort_order'),
      operationName: 'Fetch delivery zones',
    );
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchStreets(String zoneId) async {
    final response = await executeQuery(
      () => client
          .from('delivery_streets')
          .select()
          .eq('zone_id', zoneId)
          .order('street_name'),
      operationName: 'Fetch delivery streets',
    );
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createZone({
    required String suburbName,
    required int sortOrder,
  }) async {
    await executeQuery(
      () => client.from('delivery_zones').insert({
        'suburb_name': suburbName.trim(),
        'sort_order': sortOrder,
        'is_active': true,
      }),
      operationName: 'Create delivery zone',
    );
  }

  Future<void> updateZone({
    required String zoneId,
    String? suburbName,
    int? sortOrder,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};
    if (suburbName != null) updates['suburb_name'] = suburbName.trim();
    if (sortOrder != null) updates['sort_order'] = sortOrder;
    if (isActive != null) updates['is_active'] = isActive;
    if (updates.isEmpty) return;

    await executeQuery(
      () => client.from('delivery_zones').update(updates).eq('id', zoneId),
      operationName: 'Update delivery zone',
    );
  }

  Future<void> createStreet({
    required String zoneId,
    required String streetName,
  }) async {
    await executeQuery(
      () => client.from('delivery_streets').insert({
        'zone_id': zoneId,
        'street_name': streetName.trim(),
        'is_active': true,
      }),
      operationName: 'Create delivery street',
    );
  }

  Future<void> updateStreet({
    required String streetId,
    String? streetName,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};
    if (streetName != null) updates['street_name'] = streetName.trim();
    if (isActive != null) updates['is_active'] = isActive;
    if (updates.isEmpty) return;

    await executeQuery(
      () => client.from('delivery_streets').update(updates).eq('id', streetId),
      operationName: 'Update delivery street',
    );
  }

  Future<void> deleteStreet(String streetId) async {
    await executeQuery(
      () => client.from('delivery_streets').delete().eq('id', streetId),
      operationName: 'Delete delivery street',
    );
  }
}
