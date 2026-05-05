import 'package:admin_app/core/services/base_service.dart';
import 'package:admin_app/core/config/edge_pipeline_config.dart';

class DeliveryWindowService extends BaseService {
  Future<List<Map<String, dynamic>>> fetchWindows() async {
    final response = await executeQuery(
      () => client
          .from('delivery_windows')
          .select()
          .order('delivery_date', ascending: false),
      operationName: 'Fetch delivery windows',
    );
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createWindow({
    required String title,
    required DateTime deliveryDate,
    required DateTime opensAt,
    required DateTime closesAt,
  }) async {
    await executeQuery(
      () => client.from('delivery_windows').insert({
        'title': title.trim(),
        'delivery_date': deliveryDate.toIso8601String().split('T')[0],
        'opens_at': opensAt.toIso8601String(),
        'closes_at': closesAt.toIso8601String(),
        'status': 'draft',
      }),
      operationName: 'Create delivery window',
    );
  }

  Future<void> updateWindowStatus(String id, String status) async {
    final current = await executeQuery(
      () => client
          .from('delivery_windows')
          .select('id, status')
          .eq('id', id)
          .maybeSingle(),
      operationName: 'Fetch current delivery window status',
    );

    if (current == null) {
      throw Exception('Delivery window not found');
    }

    final currentStatus = (current['status'] as String?) ?? '';
    if (!_isValidTransition(currentStatus, status)) {
      throw Exception(
        'Invalid status transition: $currentStatus -> $status',
      );
    }

    final updates = <String, dynamic>{'status': status};
    if (status == 'confirmed') {
      updates['confirmed_at'] = DateTime.now().toIso8601String();
    }

    await executeQuery(
      () => client.from('delivery_windows').update(updates).eq('id', id),
      operationName: 'Update delivery window status',
    );
  }

  Future<int> countHeldOrders(String windowId) async {
    final response = await executeQuery(
      () => client
          .from('online_orders')
          .select('id')
          .eq('delivery_window_id', windowId)
          .eq('status', 'delivery_hold'),
      operationName: 'Count held orders for delivery window',
    );

    return (response as List).length;
  }

  /// Confirms the window via Edge Function (single authority: updates window,
  /// promotes held orders, sends notifications). Do not call
  /// [updateWindowStatus] for `'confirmed'` — the function only matches
  /// `draft` / `open` rows.
  Future<void> confirmWindow(String windowId) async {
    if (!EdgePipelineConfig.hasSecret) {
      throw Exception(
        'Missing EDGE_FUNCTION_SECRET. Provide it via --dart-define=EDGE_FUNCTION_SECRET=...',
      );
    }

    final response = await executeQuery(
      () => client.functions.invoke(
        'confirm-delivery-window',
        body: {'windowId': windowId},
        headers: {'x-admin-secret': EdgePipelineConfig.edgeFunctionSecret},
      ),
      operationName: 'Confirm delivery window',
    );

    final data = response.data;
    if (data is! Map) {
      throw Exception('Invalid response from confirm-delivery-window');
    }
    final map = Map<String, dynamic>.from(data);
    if (map['confirmed'] == true) {
      return;
    }
    final err = map['error']?.toString();
    if (err != null && err.isNotEmpty) {
      throw Exception(err);
    }
    final errs = map['errors'];
    if (errs is List && errs.isNotEmpty) {
      throw Exception(errs.map((e) => e.toString()).join('; '));
    }
    throw Exception('Window confirmation failed');
  }

  bool _isValidTransition(String from, String to) {
    if (to == 'cancelled') return true;
    return switch (from) {
      'draft' => to == 'open',
      'open' => to == 'confirmed' || to == 'closed',
      'confirmed' => to == 'closed',
      _ => false,
    };
  }
}
