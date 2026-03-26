import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:admin_app/core/services/supabase_service.dart';
import '../config/edge_pipeline_config.dart';

/// Invokes staff Edge Functions (x-edge-secret).
class EdgePipelineClient {
  EdgePipelineClient._();
  static final instance = EdgePipelineClient._();
  static const _uuid = Uuid();

  SupabaseClient get _client => SupabaseService.client;

  Map<String, String> get _headers => {
        'x-edge-secret': EdgePipelineConfig.edgeFunctionSecret,
      };

  void _assertReady() {
    if (!EdgePipelineConfig.canUseEdgePipeline) {
      throw StateError(
        'Edge pipeline requires USE_EDGE_PIPELINE=true and EDGE_FUNCTION_SECRET',
      );
    }
  }

  Future<Map<String, dynamic>> adminPostSupplierLedger({
    required String invoiceId,
    required List<Map<String, dynamic>> ledgerRows,
    Map<String, dynamic>? invoicePatch,
  }) async {
    _assertReady();
    final correlationId = _uuid.v4();
    final res = await _client.functions.invoke(
      'admin_post_supplier_ledger',
      body: {
        'correlation_id': correlationId,
        'invoice_id': invoiceId,
        'ledger_rows': ledgerRows,
        if (invoicePatch != null) 'invoice_patch': invoicePatch,
      },
      headers: _headers,
    );
    return _parse(res, correlationId, 'admin_post_supplier_ledger');
  }

  Future<Map<String, dynamic>> ledgerSubmitEntry({
    required Map<String, dynamic> entry,
  }) async {
    _assertReady();
    final correlationId = _uuid.v4();
    final res = await _client.functions.invoke(
      'ledger_submit_entry',
      body: {
        'correlation_id': correlationId,
        'entry': entry,
      },
      headers: _headers,
    );
    return _parse(res, correlationId, 'ledger_submit_entry');
  }

  Future<Map<String, dynamic>> stockAdjust({
    required Map<String, dynamic> movement,
  }) async {
    _assertReady();
    final correlationId = _uuid.v4();
    final res = await _client.functions.invoke(
      'stock_adjust',
      body: {
        'correlation_id': correlationId,
        'movement': movement,
      },
      headers: _headers,
    );
    return _parse(res, correlationId, 'stock_adjust');
  }

  Map<String, dynamic> _parse(
    FunctionResponse res,
    String correlationId,
    String fn,
  ) {
    final data = res.data;
    if (data is Map) {
      final m = Map<String, dynamic>.from(data as Map);
      if (m['error'] != null) {
        throw Exception('$fn: ${m['error']} (correlation_id=$correlationId)');
      }
      return m;
    }
    if (kDebugMode) {
      debugPrint('[EdgePipeline] $fn unexpected: $data');
    }
    return {'ok': true, 'correlation_id': correlationId};
  }
}
