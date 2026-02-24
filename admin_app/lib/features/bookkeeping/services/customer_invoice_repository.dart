import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import '../models/customer_invoice.dart';

/// Customer invoices — table customer_invoices only.
class CustomerInvoiceRepository {
  final SupabaseClient _client;

  CustomerInvoiceRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  Future<List<CustomerInvoice>> getAll({String? status}) async {
    var q = _client.from('customer_invoices').select('*, business_accounts(id, name)');
    if (status != null && status.isNotEmpty) {
      q = q.eq('status', status);
    }
    final list = await q.order('created_at', ascending: false);
    final invoices = (list as List)
        .map((e) => CustomerInvoice.fromJson(e as Map<String, dynamic>))
        .toList();
    return invoices;
  }

  Future<CustomerInvoice?> getById(String id) async {
    final row = await _client
        .from('customer_invoices')
        .select('*, business_accounts(id, name)')
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return CustomerInvoice.fromJson(row as Map<String, dynamic>);
  }

  Future<String> nextInvoiceNumber() async {
    final prefix =
        'CINV-${DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '')}-';
    final list = await _client
        .from('customer_invoices')
        .select('invoice_number')
        .like('invoice_number', '$prefix%')
        .order('invoice_number', ascending: false)
        .limit(1);
    if (list.isEmpty) return '${prefix}001';
    final last = list.first['invoice_number'] as String? ?? '';
    final numPart = last.length > prefix.length
        ? int.tryParse(last.substring(prefix.length)) ?? 0
        : 0;
    return '$prefix${(numPart + 1).toString().padLeft(3, '0')}';
  }

  Future<CustomerInvoice> create(CustomerInvoice invoice) async {
    final data = Map<String, dynamic>.from(invoice.toJson())
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at')
      ..remove('account_name');
    final row = await _client
        .from('customer_invoices')
        .insert(data)
        .select()
        .single();
    return CustomerInvoice.fromJson(row as Map<String, dynamic>);
  }

  Future<CustomerInvoice> update(CustomerInvoice invoice) async {
    final data = Map<String, dynamic>.from(invoice.toJson())
      ..remove('account_name');
    final row = await _client
        .from('customer_invoices')
        .update(data)
        .eq('id', invoice.id)
        .select()
        .single();
    return CustomerInvoice.fromJson(row as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _client.from('customer_invoices').delete().eq('id', id);
  }
}
