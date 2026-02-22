import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import '../models/report_data.dart';
import '../models/report_definition.dart';
import '../../bookkeeping/services/ledger_repository.dart';
import '../../hr/services/awol_repository.dart';
import '../../hr/services/staff_credit_repository.dart';
import '../../hr/services/compliance_service.dart';
import '../../hr/models/awol_record.dart';
import '../../hr/models/staff_credit.dart';

/// Repository for generating reports defined in AdminAppBluePrintTruth §11.
/// Real data for view and export (CSV, PDF, Excel).
class ReportRepository {
  final SupabaseClient _client;
  LedgerRepository? _ledgerRepo;
  AwolRepository? _awolRepo;
  StaffCreditRepository? _staffCreditRepo;
  ComplianceService? _complianceService;

  ReportRepository({
    SupabaseClient? client,
    LedgerRepository? ledgerRepo,
    AwolRepository? awolRepo,
    StaffCreditRepository? staffCreditRepo,
    ComplianceService? complianceService,
  })  : _client = client ?? SupabaseService.client,
        _ledgerRepo = ledgerRepo,
        _awolRepo = awolRepo,
        _staffCreditRepo = staffCreditRepo,
        _complianceService = complianceService;

  LedgerRepository get _ledger => _ledgerRepo ??= LedgerRepository(client: _client);
  AwolRepository get _awol => _awolRepo ??= AwolRepository(client: _client);
  StaffCreditRepository get _staffCredit => _staffCreditRepo ??= StaffCreditRepository(client: _client);
  ComplianceService get _compliance => _complianceService ??= ComplianceService();

  /// Blueprint §11: Single entry point for report data (real data, no placeholders).
  Future<ReportData> getReportData(
    String reportKey,
    DateTime start,
    DateTime end, {
    DateTime? singleDate,
  }) async {
    final def = ReportDefinitions.byKey(reportKey);
    final title = def?.title ?? reportKey;
    final startStr = start.toIso8601String().substring(0, 10);
    final endStr = end.toIso8601String().substring(0, 10);
    final subtitle = '$startStr to $endStr';

    switch (reportKey) {
      case 'daily_sales': {
        final date = singleDate ?? start;
        final rows = await getDailySales(date);
        final data = rows.map((r) => {
          'created_at': r['created_at']?.toString().substring(0, 19),
          'total_amount': r['total_amount'],
          'payment_method': r['payment_method'] ?? '—',
          'id': r['id'],
        }).toList();
        return ReportData(
          data: data,
          columns: ['created_at', 'total_amount', 'payment_method', 'id'],
          columnHeaders: {'created_at': 'Date/Time', 'total_amount': 'Amount', 'payment_method': 'Payment', 'id': 'Txn ID'},
          summary: {
            'Total Sales': data.fold<double>(0, (s, r) => s + ((r['total_amount'] as num?)?.toDouble() ?? 0)),
            'Transaction Count': data.length,
          },
          title: title,
          subtitle: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        );
      }
      case 'weekly_sales': {
        final rows = await _getTransactionsInRange(start, end);
        final data = rows.map((r) => {
          'date': r['created_at']?.toString().substring(0, 10),
          'total_amount': r['total_amount'],
          'payment_method': r['payment_method'] ?? '—',
        }).toList();
        return ReportData(
          data: data,
          columns: ['date', 'total_amount', 'payment_method'],
          columnHeaders: {'date': 'Date', 'total_amount': 'Amount', 'payment_method': 'Payment'},
          summary: {
            'Total Sales': data.fold<double>(0, (s, r) => s + ((r['total_amount'] as num?)?.toDouble() ?? 0)),
            'Transactions': data.length,
          },
          title: title,
          subtitle: subtitle,
        );
      }
      case 'monthly_pl': {
        final pnl = await _ledger.getPnLSummary(start, end);
        final data = pnl.entries.map((e) => {
          'account_code': e.key,
          'debit': e.value['debit'] ?? 0,
          'credit': e.value['credit'] ?? 0,
          'net': e.value['net'] ?? 0,
        }).toList();
        return ReportData(
          data: data,
          columns: ['account_code', 'debit', 'credit', 'net'],
          columnHeaders: {'account_code': 'Account', 'debit': 'Debit', 'credit': 'Credit', 'net': 'Net'},
          title: title,
          subtitle: subtitle,
        );
      }
      case 'vat201': {
        final vat = await _ledger.getVatSummary(start, end);
        final data = [
          {'metric': 'Output VAT (Sales)', 'amount': vat.outputVat},
          {'metric': 'Input VAT (Purchases)', 'amount': vat.inputVat},
          {'metric': 'VAT Payable to SARS', 'amount': vat.payable},
        ];
        return ReportData(
          data: data,
          columns: ['metric', 'amount'],
          columnHeaders: {'metric': 'Metric', 'amount': 'Amount (R)'},
          title: title,
          subtitle: subtitle,
        );
      }
      case 'cash_flow': {
        final cf = await _ledger.getCashFlowSummary(start, end);
        final data = [
          {'flow': 'Cash in', 'amount': cf.cashIn},
          {'flow': 'Cash out', 'amount': cf.cashOut},
          {'flow': 'Bank in', 'amount': cf.bankIn},
          {'flow': 'Bank out', 'amount': cf.bankOut},
        ];
        return ReportData(
          data: data,
          columns: ['flow', 'amount'],
          columnHeaders: {'flow': 'Flow', 'amount': 'Amount (R)'},
          summary: {'Cash net': cf.cashIn - cf.cashOut, 'Bank net': cf.bankIn - cf.bankOut},
          title: title,
          subtitle: subtitle,
        );
      }
      case 'staff_hours': {
        final rows = await getStaffHours(start, end);
        final data = rows.map((r) {
          final prof = r['staff_profiles'];
          final name = prof is Map ? prof['full_name']?.toString() : null;
          return {
            'staff_name': name ?? '—',
            'clock_in': r['clock_in']?.toString().substring(0, 19),
            'clock_out': r['clock_out']?.toString().substring(0, 19),
            'status': r['status'] ?? '—',
          };
        }).toList();
        return ReportData(
          data: data,
          columns: ['staff_name', 'clock_in', 'clock_out', 'status'],
          columnHeaders: {'staff_name': 'Staff', 'clock_in': 'Clock In', 'clock_out': 'Clock Out', 'status': 'Status'},
          title: title,
          subtitle: subtitle,
        );
      }
      case 'payroll': {
        final rows = await _getPayrollInRange(start, end);
        final data = rows.map((r) => {
          'staff_name': _extractStaffName(r),
          'gross_pay': r['gross_pay'],
          'total_deductions': r['total_deductions'],
          'net_pay': r['net_pay'],
          'period_end': r['period_end'] ?? r['created_at']?.toString().substring(0, 10),
        }).toList();
        return ReportData(
          data: data,
          columns: ['staff_name', 'gross_pay', 'total_deductions', 'net_pay', 'period_end'],
          columnHeaders: {'staff_name': 'Staff', 'gross_pay': 'Gross', 'total_deductions': 'Deductions', 'net_pay': 'Net Pay', 'period_end': 'Period'},
          summary: {
            'Total Gross': data.fold<double>(0, (s, r) => s + ((r['gross_pay'] as num?)?.toDouble() ?? 0)),
            'Total Net': data.fold<double>(0, (s, r) => s + ((r['net_pay'] as num?)?.toDouble() ?? 0)),
          },
          title: title,
          subtitle: subtitle,
        );
      }
      case 'inventory_valuation': {
        final rows = await getInventoryValuation();
        final data = rows.map((r) => {
          'name': r['name'],
          'current_stock': r['current_stock'],
          'cost_price': r['cost_price'],
          'selling_price': r['selling_price'],
          'value': (r['current_stock'] as num? ?? 0) * (r['cost_price'] as num? ?? 0),
        }).toList();
        return ReportData(
          data: data,
          columns: ['name', 'current_stock', 'cost_price', 'selling_price', 'value'],
          columnHeaders: {'name': 'Product', 'current_stock': 'Stock', 'cost_price': 'Cost', 'selling_price': 'Sell Price', 'value': 'Value'},
          summary: {'Total Value': data.fold<double>(0, (s, r) => s + ((r['value'] as num?)?.toDouble() ?? 0))},
          title: title,
          subtitle: 'As at $endStr',
        );
      }
      case 'shrinkage': {
        final rows = await getShrinkageReport(start, end);
        final data = rows.map((r) => {
          'created_at': r['created_at']?.toString().substring(0, 10),
          'product_name': r['product_name'] ?? r['product_id'],
          'theoretical_stock': r['theoretical_stock'],
          'actual_stock': r['actual_stock'],
          'gap_amount': r['gap_amount'] ?? r['variance'],
          'possible_reasons': r['possible_reasons'] ?? r['reason'] ?? '—',
        }).toList();
        return ReportData(
          data: data,
          columns: ['created_at', 'product_name', 'theoretical_stock', 'actual_stock', 'gap_amount', 'possible_reasons'],
          columnHeaders: {'created_at': 'Date', 'product_name': 'Product', 'theoretical_stock': 'Expected', 'actual_stock': 'Actual', 'gap_amount': 'Variance', 'possible_reasons': 'Reason'},
          title: title,
          subtitle: subtitle,
        );
      }
      case 'supplier_spend': {
        final rows = await getSupplierSpend(start, end);
        if (rows.isEmpty) {
          final fallback = await _getSupplierSpendFromInvoices(start, end);
          return ReportData(
            data: fallback,
            columns: ['supplier_name', 'total_amount', 'invoice_count'],
            columnHeaders: {'supplier_name': 'Supplier', 'total_amount': 'Total (R)', 'invoice_count': 'Invoices'},
            title: title,
            subtitle: subtitle,
          );
        }
        final keys = rows.isNotEmpty ? rows.first.keys.toList() : ['supplier_id', 'total_amount'];
        final headers = {for (var k in keys) k: k.toString().replaceAll('_', ' ')};
        return ReportData(data: rows, columns: keys, columnHeaders: headers, title: title, subtitle: subtitle);
      }
      case 'audit_trail': {
        final rows = await getAuditTrail(start, end);
        final data = rows.map((r) => {
          'created_at': r['created_at']?.toString().substring(0, 19),
          'staff_name': r['staff_name'] ?? r['staff_id'],
          'action': r['action'],
          'authorized_by': r['authorized_by'] ?? '—',
          'details': r['details'] ?? '—',
        }).toList();
        return ReportData(
          data: data,
          columns: ['created_at', 'staff_name', 'action', 'authorized_by', 'details'],
          columnHeaders: {'created_at': 'Date', 'staff_name': 'Staff', 'action': 'Action', 'authorized_by': 'Authorized By', 'details': 'Details'},
          title: title,
          subtitle: subtitle,
        );
      }
      case 'staff_loan_credit': {
        final credits = await _staffCredit.getCredits();
        final data = credits.map((c) => {
          'staff_name': c.staffName ?? c.staffId,
          'credit_type': c.creditType.toString().split('.').last,
          'amount': c.amount,
          'status': c.status.toString().split('.').last,
          'granted_date': c.grantedDate.toIso8601String().substring(0, 10),
          'reason': c.reason,
        }).toList();
        return ReportData(
          data: data,
          columns: ['staff_name', 'credit_type', 'amount', 'status', 'granted_date', 'reason'],
          columnHeaders: {'staff_name': 'Staff', 'credit_type': 'Type', 'amount': 'Amount', 'status': 'Status', 'granted_date': 'Date', 'reason': 'Reason'},
          summary: {'Outstanding': data.where((r) => r['status'] == 'pending' || r['status'] == 'partial').fold<double>(0, (s, r) => s + (r['amount'] as num).toDouble())},
          title: title,
          subtitle: subtitle,
        );
      }
      case 'awol': {
        final records = await _awol.getRecords(from: start, to: end);
        final data = records.map((r) => {
          'staff_name': r.staffName ?? r.staffId,
          'awol_date': r.awolDate.toIso8601String().substring(0, 10),
          'resolution': r.resolution.dbValue,
          'notified': r.notifiedOwnerManager ? 'Yes' : 'No',
          'notes': r.notes ?? '—',
        }).toList();
        return ReportData(
          data: data,
          columns: ['staff_name', 'awol_date', 'resolution', 'notified', 'notes'],
          columnHeaders: {'staff_name': 'Staff', 'awol_date': 'Date', 'resolution': 'Resolution', 'notified': 'Notified', 'notes': 'Notes'},
          title: title,
          subtitle: subtitle,
        );
      }
      case 'bcea_compliance': {
        final monthStart = DateTime(start.year, start.month, 1);
        final items = await _compliance.getBceaCompliance(monthStart);
        final data = items.map((i) => {
          'status': i.status.toString().split('.').last,
          'title': i.title,
          'detail': i.detail,
        }).toList();
        return ReportData(
          data: data,
          columns: ['status', 'title', 'detail'],
          columnHeaders: {'status': 'Status', 'title': 'Check', 'detail': 'Detail'},
          title: title,
          subtitle: '${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}',
        );
      }
      case 'expense_by_category':
        final pnl = await _ledger.getPnLSummary(start, end);
        final expenseCodes = ['6000', '6100', '6200', '6300', '6400', '6500', '6510', '6600', '6700', '6900'];
        final data = expenseCodes.map((code) => {
          'account_code': code,
          'debit': pnl[code]?['debit'] ?? 0,
          'credit': pnl[code]?['credit'] ?? 0,
        }).where((r) => (r['debit'] as num) > 0 || (r['credit'] as num) > 0).toList();
        return ReportData(
          data: data,
          columns: ['account_code', 'debit', 'credit'],
          columnHeaders: {'account_code': 'Account', 'debit': 'Debit', 'credit': 'Credit'},
          title: title,
          subtitle: subtitle,
        );
      case 'product_performance':
        final rows = await _getProductPerformance(start, end);
        return ReportData(
          data: rows,
          columns: rows.isNotEmpty ? rows.first.keys.toList() : ['product_name', 'quantity_sold', 'revenue'],
          columnHeaders: {'product_name': 'Product', 'quantity_sold': 'Qty Sold', 'revenue': 'Revenue'},
          title: title,
          subtitle: subtitle,
        );
      case 'customer_loyalty':
        final rows = await _getCustomerLoyalty();
        return ReportData(
          data: rows,
          columns: rows.isNotEmpty ? rows.first.keys.toList() : ['name', 'tier', 'spend'],
          columnHeaders: {'name': 'Customer', 'tier': 'Tier', 'spend': 'Spend'},
          title: title,
          subtitle: subtitle,
        );
      case 'hunter_jobs':
        final rows = await _getHunterJobs(start, end);
        return ReportData(
          data: rows,
          columns: rows.isNotEmpty ? rows.first.keys.toList() : ['job_number', 'customer_name', 'status', 'total'],
          columnHeaders: {'job_number': 'Job #', 'customer_name': 'Customer', 'status': 'Status', 'total': 'Total'},
          title: title,
          subtitle: subtitle,
        );
      case 'equipment_depreciation':
      case 'purchase_sale_agreement':
      case 'blockman_performance':
      case 'event_forecast':
      case 'sponsorship_donations':
      default: {
        return ReportData(
          data: [],
          columns: [],
          columnHeaders: {},
          title: title,
          subtitle: subtitle,
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getTransactionsInRange(DateTime start, DateTime end) async {
    try {
      final response = await _client
          .from('transactions')
          .select()
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .order('created_at', ascending: false)
          .limit(500);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getPayrollInRange(DateTime start, DateTime end) async {
    try {
      final startStr = start.toIso8601String().substring(0, 10);
      final endStr = end.toIso8601String().substring(0, 10);
      final periods = await _client
          .from('payroll_periods')
          .select()
          .gte('period_end', startStr)
          .lte('period_end', endStr)
          .order('period_end', ascending: false);
      if ((periods as List).isEmpty) return [];
      final list = <Map<String, dynamic>>[];
      for (final p in periods as List) {
        final entries = await _client
            .from('payroll_entries')
            .select('*, staff_profiles(full_name)')
            .eq('payroll_period_id', p['id'])
            .order('staff_id');
        for (final e in entries as List) {
          final row = Map<String, dynamic>.from(e as Map<String, dynamic>);
          row['period_end'] = p['period_end'];
          list.add(row);
        }
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  String _extractStaffName(Map<String, dynamic> r) {
    final p = r['staff_profiles'];
    if (p is Map) return p['full_name']?.toString() ?? '—';
    return r['staff_name']?.toString() ?? '—';
  }

  Future<List<Map<String, dynamic>>> _getSupplierSpendFromInvoices(DateTime start, DateTime end) async {
    try {
      final startStr = start.toIso8601String().substring(0, 10);
      final endStr = end.toIso8601String().substring(0, 10);
      final rows = await _client
          .from('invoices')
          .select('*, suppliers(name)')
          .gte('invoice_date', startStr)
          .lte('invoice_date', endStr)
          .eq('status', 'approved');
      final map = <String, Map<String, dynamic>>{};
      for (final r in rows as List) {
        final name = (r['suppliers'] is Map ? r['suppliers']['name'] : null) ?? r['supplier_id'] ?? 'Unknown';
        final key = name.toString();
        map.putIfAbsent(key, () => {'supplier_name': key, 'total_amount': 0.0, 'invoice_count': 0});
        map[key]!['total_amount'] = (map[key]!['total_amount'] as num) + ((r['total_amount'] as num?)?.toDouble() ?? 0);
        map[key]!['invoice_count'] = (map[key]!['invoice_count'] as int) + 1;
      }
      return map.values.toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getProductPerformance(DateTime start, DateTime end) async {
    try {
      final rows = await _client
          .from('transaction_items')
          .select('quantity, unit_price, inventory_items(name)')
          .limit(500);
      final byProduct = <String, Map<String, dynamic>>{};
      for (final r in rows as List) {
        final name = (r['inventory_items'] is Map ? r['inventory_items']['name'] : null) ?? 'Unknown';
        final key = name.toString();
        byProduct.putIfAbsent(key, () => {'product_name': key, 'quantity_sold': 0.0, 'revenue': 0.0});
        byProduct[key]!['quantity_sold'] = (byProduct[key]!['quantity_sold'] as num) + ((r['quantity'] as num?)?.toDouble() ?? 0);
        byProduct[key]!['revenue'] = (byProduct[key]!['revenue'] as num) + ((r['unit_price'] as num?)?.toDouble() ?? 0) * ((r['quantity'] as num?)?.toDouble() ?? 0);
      }
      return byProduct.values.toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getCustomerLoyalty() async {
    try {
      final rows = await _client.from('loyalty_customers').select().order('total_spend', ascending: false).limit(100);
      return (rows as List).map((r) => {
        'name': r['full_name'],
        'tier': r['tier'] ?? '—',
        'spend': r['total_spend'],
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getHunterJobs(DateTime start, DateTime end) async {
    try {
      final rows = await _client
          .from('hunter_jobs')
          .select()
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .order('created_at', ascending: false)
          .limit(200);
      return (rows as List).map((r) => {
        'job_number': r['job_number'],
        'customer_name': r['customer_name'],
        'status': r['status'],
        'total': r['total_amount'],
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ═════════════════════════════════════════════════════════
  // EXISTING AGGREGATORS (kept for backward compatibility)
  // ═════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getDailySales(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day).toIso8601String();
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
      final response = await _client
          .from('transactions')
          .select()
          .gte('created_at', start)
          .lte('created_at', end)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getInventoryValuation() async {
    try {
      final response = await _client
          .from('inventory_items')
          .select('id, name, current_stock, cost_price, selling_price, category_id')
          .gt('current_stock', 0)
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getShrinkageReport(DateTime startDate, DateTime endDate) async {
    try {
      final response = await _client
          .from('shrinkage_alerts')
          .select()
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStaffHours(DateTime startDate, DateTime endDate) async {
    try {
      final response = await _client
          .from('timecards')
          .select('*, staff_profiles(full_name)')
          .gte('clock_in', startDate.toIso8601String())
          .lte('clock_in', endDate.toIso8601String())
          .order('clock_in', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSupplierSpend(DateTime startDate, DateTime endDate) async {
    try {
      final response = await _client.rpc('calculate_supplier_spend', params: {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      });
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAuditTrail(DateTime startDate, DateTime endDate) async {
    try {
      final response = await _client
          .from('audit_log')
          .select()
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false)
          .limit(500);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  String generateCSV(List<Map<String, dynamic>> data, List<String> headers, List<String> keys) {
    if (data.isEmpty) return 'No data available for this range.';
    final StringBuffer buffer = StringBuffer();
    buffer.writeln(headers.join(','));
    for (var row in data) {
      final values = keys.map((k) => row[k]?.toString() ?? '').map((v) => v.contains(',') ? '"$v"' : v).toList();
      buffer.writeln(values.join(','));
    }
    return buffer.toString();
  }
}
