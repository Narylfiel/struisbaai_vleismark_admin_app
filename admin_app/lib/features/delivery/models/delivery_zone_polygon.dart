import 'package:latlong2/latlong.dart';

/// Admin-side polygon delivery zone model.
/// Uses latlong2.LatLng (not google_maps_flutter) — works on Windows desktop.
class DeliveryZonePolygon {
  final String id;
  final String name;
  final List<LatLng> polygon;
  final double deliveryFee;
  final double minimumOrder;
  final String? deliveryDay;
  final bool isActive;
  final String color;
  final String? description;

  const DeliveryZonePolygon({
    required this.id,
    required this.name,
    required this.polygon,
    required this.deliveryFee,
    required this.minimumOrder,
    this.deliveryDay,
    required this.isActive,
    required this.color,
    this.description,
  });

  factory DeliveryZonePolygon.fromJson(Map<String, dynamic> json) {
    final rawPolygon = json['polygon'] as List<dynamic>? ?? [];
    final points = rawPolygon
        .map((p) => LatLng(
              (p['lat'] as num).toDouble(),
              (p['lng'] as num).toDouble(),
            ))
        .toList();
    return DeliveryZonePolygon(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      polygon: points,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 110.0,
      minimumOrder: (json['minimum_order'] as num?)?.toDouble() ?? 500.0,
      deliveryDay: json['delivery_day'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      color: json['color'] as String? ?? '#E53935',
      description: json['description'] as String?,
    );
  }

  List<Map<String, dynamic>> polygonToJson() {
    return polygon
        .map((p) => {'lat': p.latitude, 'lng': p.longitude})
        .toList();
  }

  /// Returns true only when the polygon has at least 3 vertices.
  bool get hasPolygon => polygon.length >= 3;

  DeliveryZonePolygon copyWith({
    String? id,
    String? name,
    List<LatLng>? polygon,
    double? deliveryFee,
    double? minimumOrder,
    String? deliveryDay,
    bool? isActive,
    String? color,
    String? description,
  }) {
    return DeliveryZonePolygon(
      id: id ?? this.id,
      name: name ?? this.name,
      polygon: polygon ?? this.polygon,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      minimumOrder: minimumOrder ?? this.minimumOrder,
      deliveryDay: deliveryDay ?? this.deliveryDay,
      isActive: isActive ?? this.isActive,
      color: color ?? this.color,
      description: description ?? this.description,
    );
  }
}
