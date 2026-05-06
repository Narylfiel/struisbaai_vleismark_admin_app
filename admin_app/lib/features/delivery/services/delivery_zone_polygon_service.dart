import 'package:latlong2/latlong.dart';
import 'package:admin_app/core/services/base_service.dart';
import '../models/delivery_zone_polygon.dart';

class DeliveryZonePolygonService extends BaseService {
  Future<List<DeliveryZonePolygon>> fetchZones() async {
    final response = await executeQuery(
      () => client
          .from('delivery_zones_polygon')
          .select()
          .order('created_at'),
      operationName: 'Fetch polygon delivery zones',
    );
    return (response as List)
        .map((z) => DeliveryZonePolygon.fromJson(z as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveZone(DeliveryZonePolygon zone) async {
    await executeQuery(
      () => client.from('delivery_zones_polygon').insert({
        'name': zone.name,
        'polygon': zone.polygonToJson(),
        'delivery_fee': zone.deliveryFee,
        'minimum_order': zone.minimumOrder,
        'delivery_day': zone.deliveryDay,
        'is_active': zone.isActive,
        'color': zone.color,
        'description': zone.description,
      }),
      operationName: 'Save polygon delivery zone',
    );
  }

  Future<void> updateZone(DeliveryZonePolygon zone) async {
    await executeQuery(
      () => client.from('delivery_zones_polygon').update({
        'name': zone.name,
        'polygon': zone.polygonToJson(),
        'delivery_fee': zone.deliveryFee,
        'minimum_order': zone.minimumOrder,
        'delivery_day': zone.deliveryDay,
        'is_active': zone.isActive,
        'color': zone.color,
        'description': zone.description,
      }).eq('id', zone.id),
      operationName: 'Update polygon delivery zone',
    );
  }

  /// Updates only the polygon coordinates for an existing zone.
  Future<void> updatePolygon(String id, List<LatLng> polygon) async {
    final points =
        polygon.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList();
    await executeQuery(
      () => client
          .from('delivery_zones_polygon')
          .update({'polygon': points})
          .eq('id', id),
      operationName: 'Update zone polygon',
    );
  }

  Future<void> toggleActive(String id, {required bool isActive}) async {
    await executeQuery(
      () => client
          .from('delivery_zones_polygon')
          .update({'is_active': isActive})
          .eq('id', id),
      operationName: 'Toggle zone active',
    );
  }

  Future<void> deleteZone(String id) async {
    await executeQuery(
      () => client.from('delivery_zones_polygon').delete().eq('id', id),
      operationName: 'Delete polygon delivery zone',
    );
  }
}
