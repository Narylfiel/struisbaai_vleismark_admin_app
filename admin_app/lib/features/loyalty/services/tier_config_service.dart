import 'package:admin_app/core/services/base_service.dart';

class TierConfigService extends BaseService {
  Future<List<Map<String, dynamic>>> fetchTiers() async {
    final response = await executeQuery(
      () => client
          .from('loyalty_tier_config')
          .select()
          .order('sort_order', ascending: true),
      operationName: 'Fetch tier configuration',
    );

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateTier(String id, Map<String, dynamic> updates) async {
    await executeQuery(
      () => client.from('loyalty_tier_config').update(updates).eq('id', id),
      operationName: 'Update tier configuration',
    );
  }
}
