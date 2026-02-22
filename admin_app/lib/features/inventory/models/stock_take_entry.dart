import '../../../core/models/base_model.dart';

/// Blueprint §4.7: Stock-take entry — per (session, item, location); expected vs actual; multi-device device_id.
class StockTakeEntry extends BaseModel {
  final String sessionId;
  final String itemId;
  final String? locationId;
  final double expectedQuantity;
  final double? actualQuantity;
  final double? variance;
  final String? countedBy;
  final String? deviceId;

  const StockTakeEntry({
    required super.id,
    required this.sessionId,
    required this.itemId,
    this.locationId,
    this.expectedQuantity = 0,
    this.actualQuantity,
    this.variance,
    this.countedBy,
    this.deviceId,
    super.createdAt,
    super.updatedAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'item_id': itemId,
      'location_id': locationId,
      'expected_quantity': expectedQuantity,
      'actual_quantity': actualQuantity,
      'variance': variance,
      'counted_by': countedBy,
      'device_id': deviceId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory StockTakeEntry.fromJson(Map<String, dynamic> json) {
    return StockTakeEntry(
      id: json['id'] as String,
      sessionId: json['session_id'] as String? ?? '',
      itemId: json['item_id'] as String? ?? '',
      locationId: json['location_id'] as String?,
      expectedQuantity: (json['expected_quantity'] as num?)?.toDouble() ?? 0,
      actualQuantity: (json['actual_quantity'] as num?)?.toDouble(),
      variance: (json['variance'] as num?)?.toDouble(),
      countedBy: json['counted_by'] as String?,
      deviceId: json['device_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  bool validate() => sessionId.isNotEmpty && itemId.isNotEmpty;

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (sessionId.isEmpty) errors.add('Session is required');
    if (itemId.isEmpty) errors.add('Item is required');
    return errors;
  }
}
