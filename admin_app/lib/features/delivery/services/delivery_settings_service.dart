import 'package:admin_app/core/services/base_service.dart';

class DeliverySettingsService extends BaseService {
  Future<Map<String, dynamic>> fetchSettings() async {
    final response = await executeQuery(
      () => client
          .from('delivery_settings')
          .select()
          .limit(1)
          .maybeSingle(),
      operationName: 'Fetch delivery settings',
    );
    return Map<String, dynamic>.from(response ?? <String, dynamic>{});
  }

  Future<void> updateSettings({
    required String id,
    required double deliveryFee,
    required double minOrderValue,
    required int autoCancelDays,
    required bool isActive,
    String? updatedBy,
  }) async {
    final updates = <String, dynamic>{
      'delivery_fee': deliveryFee,
      'min_order_value': minOrderValue,
      'auto_cancel_days': autoCancelDays,
      'is_active': isActive,
    };
    if (updatedBy != null && updatedBy.isNotEmpty) {
      updates['updated_by'] = updatedBy;
    }

    await executeQuery(
      () => client.from('delivery_settings').update(updates).eq('id', id),
      operationName: 'Update delivery settings',
    );
  }
}
