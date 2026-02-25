import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/features/hunter/models/hunter_job.dart';

/// Creates a parked_sale record when a hunter job status becomes 'ready'.
/// reference: HJ-{first 8 chars of job id}
/// line_items built from services_list + materials_list with prices from linked inventory_items.
/// inventory_items selling price column: sell_price (per schema; not selling_price).
Future<String?> createParkedSaleForJob(String jobId) async {
  final client = SupabaseService.client;

  // Load job with services (for linked inventory_item prices)
  final jobRes = await client
      .from('hunter_jobs')
      .select('*')
      .eq('id', jobId)
      .maybeSingle();
  if (jobRes == null) return null;
  final job = Map<String, dynamic>.from(jobRes as Map);

  final reference = hunterJobDisplayNumber(jobId);
  final customerName = job['hunter_name']?.toString() ?? job['customer_name']?.toString() ?? '';
  final customerPhone = job['contact_phone']?.toString() ?? job['customer_phone']?.toString() ?? '';

  final lineItems = <Map<String, dynamic>>[];
  num subtotal = 0;

  // services_list: [{"service_id": "uuid", "name": "Processing", "quantity": 1, "notes": ""}]
  final servicesList = job['services_list'];
  if (servicesList is List) {
    for (final entry in servicesList) {
      final map = entry is Map ? Map<String, dynamic>.from(entry as Map) : <String, dynamic>{};
      final serviceId = map['service_id']?.toString();
      final name = map['name']?.toString() ?? 'Service';
      final qty = (map['quantity'] as num?)?.toDouble() ?? 1.0;
      if (serviceId == null) continue;
      // Get service and linked inventory_item for price
      num unitPrice = 0;
      final srv = await client.from('hunter_services').select('base_price, price_per_kg, inventory_item_id').eq('id', serviceId).maybeSingle();
      if (srv != null) {
        final s = Map<String, dynamic>.from(srv as Map);
        final invId = s['inventory_item_id']?.toString();
        if (invId != null) {
          final inv = await client.from('inventory_items').select('sell_price').eq('id', invId).maybeSingle();
          if (inv != null) unitPrice = (inv['sell_price'] as num?)?.toDouble() ?? 0;
        }
        if (unitPrice == 0) {
          final base = (s['base_price'] as num?)?.toDouble() ?? 0;
          final perKg = (s['price_per_kg'] as num?)?.toDouble() ?? 0;
          final estWeight = (job['estimated_weight'] as num?)?.toDouble() ?? (job['animal_count'] as num?)?.toDouble() ?? 1;
          unitPrice = base + (perKg * estWeight);
        }
      }
      final lineTotal = (unitPrice * qty).toDouble();
      subtotal += lineTotal;
      lineItems.add({
        'item_id': serviceId,
        'name': name,
        'quantity': qty,
        'unit_price': unitPrice.toDouble(),
        'line_total': lineTotal,
      });
    }
  }

  // materials_list: [{"item_id": "uuid", "name": "Spice Mix", "quantity": 500, "unit": "g"}]
  final materialsList = job['materials_list'];
  if (materialsList is List) {
    for (final entry in materialsList) {
      final map = entry is Map ? Map<String, dynamic>.from(entry as Map) : <String, dynamic>{};
      final itemId = map['item_id']?.toString();
      final name = map['name']?.toString() ?? 'Material';
      final qty = (map['quantity'] as num?)?.toDouble() ?? 1.0;
      if (itemId == null) continue;
      final inv = await client.from('inventory_items').select('sell_price').eq('id', itemId).maybeSingle();
      num unitPrice = 0;
      if (inv != null) unitPrice = (inv['sell_price'] as num?)?.toDouble() ?? 0;
      final lineTotal = (unitPrice * qty).toDouble();
      subtotal += lineTotal;
      lineItems.add({
        'item_id': itemId,
        'name': name,
        'quantity': qty,
        'unit_price': unitPrice.toDouble(),
        'line_total': lineTotal,
      });
    }
  }

  // If no line items from lists, build minimal from legacy job data so POS has something
  if (lineItems.isEmpty) {
    final charge = (job['charge_total'] ?? job['total_amount'] ?? job['quoted_price'] as num?)?.toDouble() ?? 0;
    lineItems.add({
      'item_id': jobId,
      'name': 'Hunter processing',
      'quantity': 1,
      'unit_price': charge,
      'line_total': charge,
    });
    subtotal = charge;
  }

  await client.from('parked_sales').insert({
    'reference': reference,
    'source': 'hunter',
    'hunter_job_id': jobId,
    'customer_name': customerName,
    'customer_phone': customerPhone,
    'line_items': lineItems,
    'subtotal': subtotal,
    'status': 'parked',
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  });

  return reference;
}
