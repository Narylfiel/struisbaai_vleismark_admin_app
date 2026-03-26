import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import '../models/report_data.dart';
import '../models/report_definition.dart';
import 'alert_service.dart';
import '../../bookkeeping/services/ledger_repository.dart';
import '../../hr/services/awol_repository.dart';
import '../../hr/services/staff_credit_repository.dart';
import '../../hr/services/compliance_service.dart';
import '../../hr/models/awol_record.dart';

double _reportMoney(double x) => (x * 100).roundToDouble() / 100;

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
    String? staffId,
    String? paymentMethod,
  }) async {
    final def = ReportDefinitions.byKey(reportKey);
    final title = def?.title ?? reportKey;
    final startStr = start.toIso8601String().substring(0, 10);
    final endStr = end.toIso8601String().substring(0, 10);
    final subtitle = '$startStr to $endStr';

    switch (reportKey) {
      case 'daily_sales': {
        final date = singleDate ?? start;
        List<Map<String, dynamic>> rows = await getDailySales(date);
        if (paymentMethod != null && paymentMethod.isNotEmpty) {
          rows = rows
              .where((r) =>
                  r['payment_method']?.toString().toLowerCase() ==
                  paymentMethod.toLowerCase())
              .toList();
        }
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
          monetaryColumns: const {'total_amount'},
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
          monetaryColumns: const {'total_amount'},
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
          monetaryColumns: const {'debit', 'credit', 'net'},
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
          monetaryColumns: const {'amount'},
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
          monetaryColumns: const {'amount'},
        );
      }
      case 'staff_hours': {
        final rows = await getStaffHours(start, end, staffId: staffId);
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
          'total_deductions': (r['uif_employee'] as num? ?? 0) +
              (r['advance_deduction'] as num? ?? 0) +
              (r['meat_purchase_deduction'] as num? ?? 0) +
              (r['other_deductions'] as num? ?? 0),
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
          monetaryColumns: const {'gross_pay', 'total_deductions', 'net_pay'},
        );
      }
      case 'inventory_valuation': {
        final rows = await getInventoryValuation();
        final data = rows.map((r) {
          final fresh = (r['stock_on_hand_fresh'] as num?)?.toDouble() ?? 0;
          final frozen = (r['stock_on_hand_frozen'] as num?)?.toDouble() ?? 0;
          final totalStock = fresh + frozen;
          final costPrice = (r['cost_price'] as num?)?.toDouble() ?? 0;
          return {
            'name': r['name'],
            'stock_fresh': fresh,
            'stock_frozen': frozen,
            'total_stock': totalStock,
            'cost_price': costPrice,
            'sell_price': (r['sell_price'] as num?)?.toDouble() ?? 0,
            'value': totalStock * costPrice,
          };
        }).toList();
        return ReportData(
          data: data,
          columns: ['name', 'stock_fresh', 'stock_frozen', 'total_stock', 'cost_price', 'sell_price', 'value'],
          columnHeaders: {
            'name': 'Product',
            'stock_fresh': 'Fresh (kg)',
            'stock_frozen': 'Frozen (kg)',
            'total_stock': 'Total Stock',
            'cost_price': 'Cost (R)',
            'sell_price': 'Sell Price (R)',
            'value': 'Stock Value (R)'
          },
          summary: {'Total Stock Value': data.fold<double>(0, (s, r) => s + ((r['value'] as num?)?.toDouble() ?? 0))},
          title: title,
          subtitle: 'As at $endStr',
          monetaryColumns: const {'cost_price', 'sell_price', 'value'},
        );
      }
      case 'shrinkage': {
        final rows = await getShrinkageReport(start, end);
        final data = rows.map((r) => {
          'created_at': r['created_at']?.toString().substring(0, 10),
          'product_name': r['item_name'] ?? r['product_id'],
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
          monetaryColumns: const {'theoretical_stock', 'actual_stock', 'gap_amount'},
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
            monetaryColumns: const {'total_amount'},
          );
        }
        final keys = rows.isNotEmpty ? rows.first.keys.toList() : ['supplier_id', 'total_amount'];
        final headers = {for (var k in keys) k: k.toString().replaceAll('_', ' ')};
        return ReportData(data: rows, columns: keys, columnHeaders: headers, title: title, subtitle: subtitle, monetaryColumns: const {'total_amount'});
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
          monetaryColumns: const {'amount'},
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
          monetaryColumns: const {'debit', 'credit'},
        );
      case 'product_performance':
        final rows = await _getProductPerformance(start, end);
        return ReportData(
          data: rows,
          columns: rows.isNotEmpty ? rows.first.keys.toList() : ['product_name', 'quantity_sold', 'revenue'],
          columnHeaders: {'product_name': 'Product', 'quantity_sold': 'Qty Sold', 'revenue': 'Revenue'},
          title: title,
          subtitle: subtitle,
          monetaryColumns: const {'revenue'},
        );
      case 'pricing_intelligence': {
        final rows = await getPricingIntelligenceRowsForAlerts(start, end);
        rows.sort(
          (a, b) => ((b['profit'] as num?)?.toDouble() ?? 0.0)
              .compareTo((a['profit'] as num?)?.toDouble() ?? 0.0),
        );
        final totalRev = _reportMoney(
          rows.fold<double>(
            0,
            (s, r) => s + ((r['revenue'] as num?)?.toDouble() ?? 0),
          ),
        );
        final totalCostSum = _reportMoney(
          rows.fold<double>(
            0,
            (s, r) => s + ((r['cost'] as num?)?.toDouble() ?? 0),
          ),
        );
        final totalProf = _reportMoney(totalRev - totalCostSum);
        final overallMarginPct =
            totalRev > 0 ? _reportMoney((totalProf / totalRev) * 100) : 0.0;
        final alerts = AlertService.generateAlerts(rows);
        return ReportData(
          data: rows,
          alerts: alerts,
          columns: rows.isNotEmpty
              ? rows.first.keys.toList()
              : [
                  'inventory_item_id',
                  'product_name',
                  'quantity',
                  'revenue',
                  'cost',
                  'profit',
                  'margin',
                  'actual_margin',
                  'list_margin',
                  'margin_flag',
                  'profit_flag',
                  'recommendation',
                  'price_vs_cost',
                  'price_position',
                  'markup_pct',
                  'markup_flag',
                ],
          columnHeaders: {
            'inventory_item_id': 'Item ID',
            'product_name': 'Product',
            'quantity': 'Qty Sold',
            'revenue': 'Revenue (R)',
            'cost': 'Cost (WAC) (R)',
            'profit': 'Profit (R)',
            'margin': 'Margin %',
            'actual_margin': 'Actual margin %',
            'list_margin': 'List / theoretical margin %',
            'margin_flag': 'Margin band',
            'profit_flag': 'Profit / loss',
            'recommendation': 'Recommendation',
            'price_vs_cost': 'List price vs WAC (R)',
            'price_position': 'Price vs cost',
            'markup_pct': 'Markup % (on cost)',
            'markup_flag': 'Markup level',
          },
          summary: {
            'Total Revenue': totalRev,
            'Total Cost (WAC)': totalCostSum,
            'Total Profit': totalProf,
            'Overall margin %': overallMarginPct,
          },
          title: title,
          subtitle: subtitle,
          monetaryColumns: const {'revenue', 'cost', 'profit', 'price_vs_cost'},
          totalRevenue: totalRev,
          totalCost: totalCostSum,
          totalProfit: totalProf,
          marginPercentage: overallMarginPct,
        );
      }
      case 'profit_analysis': {
        final rows = await _getProfitAnalysisByProduct(start, end);
        final totalRev = _reportMoney(
          rows.fold<double>(
            0,
            (s, r) => s + ((r['revenue'] as num?)?.toDouble() ?? 0),
          ),
        );
        final totalCostSum = _reportMoney(
          rows.fold<double>(
            0,
            (s, r) => s + ((r['cost'] as num?)?.toDouble() ?? 0),
          ),
        );
        final totalProf = _reportMoney(totalRev - totalCostSum);
        final overallMarginPct =
            totalRev > 0 ? _reportMoney((totalProf / totalRev) * 100) : 0.0;
        return ReportData(
          data: rows,
          columns: rows.isNotEmpty
              ? rows.first.keys.toList()
              : [
                  'inventory_item_id',
                  'product_name',
                  'quantity',
                  'revenue',
                  'cost',
                  'profit',
                  'margin',
                ],
          columnHeaders: {
            'inventory_item_id': 'Item ID',
            'product_name': 'Product',
            'quantity': 'Qty Sold',
            'revenue': 'Revenue (R)',
            'cost': 'Cost (WAC) (R)',
            'profit': 'Profit (R)',
            'margin': 'Margin %',
          },
          summary: {
            'Total Revenue': totalRev,
            'Total Cost (WAC)': totalCostSum,
            'Total Profit': totalProf,
            'Overall margin %': overallMarginPct,
          },
          title: title,
          subtitle: subtitle,
          monetaryColumns: const {'revenue', 'cost', 'profit'},
          totalRevenue: totalRev,
          totalCost: totalCostSum,
          totalProfit: totalProf,
          marginPercentage: overallMarginPct,
        );
      }
      case 'customer_loyalty':
        final rows = await _getCustomerLoyalty();
        return ReportData(
          data: rows,
          columns: rows.isNotEmpty ? rows.first.keys.toList() : ['name', 'tier', 'spend'],
          columnHeaders: {'name': 'Customer', 'tier': 'Tier', 'spend': 'Spend'},
          title: title,
          subtitle: subtitle,
          monetaryColumns: const {'spend'},
        );
      case 'hunter_jobs':
        final rows = await _getHunterJobs(start, end);
        final data = rows.map((r) => {
          'job_date': r['job_date'],
          'hunter_name': r['hunter_name'] ?? '—',
          'species': r['species'] ?? r['animal_count']?.toString() ?? '—',
          'weight_in': r['weight_in'],
          'status': r['status'] ?? '—',
          'charge_total': r['charge_total'] ?? r['total_amount'] ?? 0,
          'paid': r['paid'] == true ? 'Yes' : 'No',
        }).toList();
        return ReportData(
          data: data,
          columns: ['job_date', 'hunter_name', 'species', 'weight_in', 'status', 'charge_total', 'paid'],
          columnHeaders: {
            'job_date': 'Date',
            'hunter_name': 'Hunter',
            'species': 'Species',
            'weight_in': 'Weight (kg)',
            'status': 'Status',
            'charge_total': 'Charge (R)',
            'paid': 'Paid',
          },
          summary: {
            'Total Jobs': data.length,
            'Total Revenue': data.fold<double>(0, (s, r) => s + ((r['charge_total'] as num?)?.toDouble() ?? 0)),
            'Unpaid': data.where((r) => r['paid'] == 'No').length,
          },
          title: title,
          subtitle: subtitle,
          monetaryColumns: const {'charge_total'},
        );
      case 'stock_movement': {
        return await _getStockMovementReport(start, end, title, subtitle);
      }
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

  Future<List<Map<String, dynamic>>> _getPayrollInRange(DateTime start, DateTime end, {String? staffId}) async {
    try {
      final startStr = start.toIso8601String().substring(0, 10);
      final endStr = end.toIso8601String().substring(0, 10);
      final periods = await _client
          .from('payroll_periods')
          .select('id, start_date, end_date, status, total_gross, total_deductions, total_net')
          .gte('end_date', startStr)
          .lte('end_date', endStr)
          .order('end_date', ascending: false);
      if ((periods as List).isEmpty) return [];
      final list = <Map<String, dynamic>>[];
      for (final p in periods as List) {
        var q = _client
            .from('payroll_entries')
            .select('*, staff_profiles!payroll_entries_staff_id_fkey(full_name)')
            .eq('period_id', p['id']);
        if (staffId != null) q = q.eq('staff_id', staffId);
        final entries = await q.order('staff_id');
        for (final e in entries as List) {
          final row = Map<String, dynamic>.from(e as Map<String, dynamic>);
          row['period_end'] = p['end_date'];
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
          .select('quantity, unit_price, inventory_item_id, '
              'inventory_items!transaction_items_inventory_item_id_fkey(name), '
              'transactions!transaction_items_transaction_id_fkey(created_at)')
          .gte('transactions.created_at', start.toIso8601String())
          .lte('transactions.created_at', end.toIso8601String())
          .not('transactions.created_at', 'is', null)
          .limit(1000);
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

  /// Read-only profit / margin by [inventory_item_id]: revenue from [transaction_items],
  /// cost uses historical [transaction_items.cost_price] first, with WAC fallback.
  Future<List<Map<String, dynamic>>> _getProfitAnalysisByProduct(
    DateTime start,
    DateTime end,
  ) async {
    double safeNum(dynamic v, [double fallback = 0]) {
      if (v == null) return fallback;
      if (v is num) {
        final d = v.toDouble();
        return d.isFinite ? d : fallback;
      }
      return fallback;
    }

    try {
      final rows = await _client
          .from('transaction_items')
          .select(
            // IMPORTANT:
            // Financial calculations must NEVER derive quantity from money.
            // Always use transaction-level totals for correctness.
            'quantity, line_total, cost_price, inventory_item_id, product_name, '
            'inventory_items!transaction_items_inventory_item_id_fkey(name, average_cost), '
            'transactions!transaction_items_transaction_id_fkey(id, is_refund, total_amount, cost_amount, created_at)',
          )
          .gte('transactions.created_at', start.toIso8601String())
          .lte('transactions.created_at', end.toIso8601String())
          .not('transactions.created_at', 'is', null)
          .limit(5000);

      // Transaction-level financial aggregation:
      // - Revenue/Cost/Profit come only from transactions.total_amount and
      //   transactions.cost_amount (signed by transactions.is_refund).
      // - We allocate those transaction totals across items proportionally
      //   to abs(transaction_items.line_total) for product-level reporting.

      // Pass 1: compute per-transaction abs(line_total) denominator.
      final txAgg = <String, Map<String, dynamic>>{};
      for (final raw in rows as List) {
        final r = Map<String, dynamic>.from(raw as Map);
        final tx = r['transactions'];
        if (tx is! Map) continue;
        final txId = tx['id']?.toString();
        if (txId == null) continue;

        final isRefund = tx['is_refund'] == true;
        final totalAmount = safeNum(tx['total_amount']);
        final costAmount = safeNum(tx['cost_amount']);
        final signedTotal = isRefund ? -totalAmount : totalAmount;
        final signedCost = isRefund ? -costAmount : costAmount;

        final absLineTotal = safeNum(r['line_total']).abs();

        final agg = txAgg.putIfAbsent(txId, () => {
          'signed_total_amount': signedTotal,
          'signed_cost_amount': signedCost,
          'abs_line_total': 0.0,
          'item_count': 0,
        });

        agg['abs_line_total'] = safeNum(agg['abs_line_total']) + absLineTotal;
        agg['item_count'] = (agg['item_count'] as int? ?? 0) + 1;
      }

      // Pass 2: allocate signed transaction totals to product groups.
      final grouped = <String, Map<String, dynamic>>{};
      for (final raw in rows as List) {
        final r = Map<String, dynamic>.from(raw as Map);
        final tx = r['transactions'];
        if (tx is! Map) continue;
        final txId = tx['id']?.toString();
        if (txId == null) continue;

        final txRow = txAgg[txId];
        if (txRow == null) continue;

        final inventoryItem = r['inventory_items'];
        final productNameFromInventory = inventoryItem is Map
            ? (inventoryItem['name']?.toString() ?? 'Unknown')
            : 'Unknown';
        final productNameFromTi =
            r['product_name']?.toString() ?? productNameFromInventory;
        final itemId = r['inventory_item_id']?.toString() ?? productNameFromTi;

        final absLine = safeNum(r['line_total']).abs();
        final absLineTotal = safeNum(txRow['abs_line_total']);
        final itemCount = txRow['item_count'] as int? ?? 0;
        final share = absLineTotal > 0
            ? (absLine / absLineTotal)
            : (itemCount > 0 ? (1.0 / itemCount) : 0.0);

        final signedTotalAmount = safeNum(txRow['signed_total_amount']);
        final signedCostAmount = safeNum(txRow['signed_cost_amount']);

        final revenue = _reportMoney(share * signedTotalAmount);
        final cost = _reportMoney(share * signedCostAmount);
        final profit = _reportMoney(revenue - cost);

        // Quantity is allowed for volume metrics only; refunds have quantity=0.
        final quantity = safeNum(r['quantity']);

        // Weighted avg cost per unit for recommendation math.
        // For refunds (quantity=0), this prevents division-by-zero/instability.
        final costPrice = safeNum(r['cost_price']);
        final costPerUnitWeight = absLine;

        grouped.putIfAbsent(
          itemId,
          () => <String, dynamic>{
            'inventory_item_id': itemId,
            'product_name': productNameFromTi,
            'quantity': 0.0,
            'revenue': 0.0,
            'cost': 0.0,
            'profit': 0.0,
            'avg_cost_per_unit_weighted_sum': 0.0,
            'avg_cost_per_unit_weight': 0.0,
          },
        );

        final group = grouped[itemId]!;
        group['quantity'] = safeNum(group['quantity']) + quantity;
        group['revenue'] = _reportMoney(safeNum(group['revenue']) + revenue);
        group['cost'] = _reportMoney(safeNum(group['cost']) + cost);
        group['profit'] = _reportMoney(safeNum(group['profit']) + profit);
        group['avg_cost_per_unit_weighted_sum'] =
            safeNum(group['avg_cost_per_unit_weighted_sum']) +
                (costPrice * costPerUnitWeight);
        group['avg_cost_per_unit_weight'] = safeNum(group['avg_cost_per_unit_weight']) +
            costPerUnitWeight;
      }

      final list = grouped.values.map((group) {
        final revenueTotal = safeNum(group['revenue']);
        final profitTotal = safeNum(group['profit']);
        final marginVal = revenueTotal != 0 &&
                revenueTotal.isFinite &&
                profitTotal.isFinite
            ? _reportMoney((profitTotal / revenueTotal) * 100)
            : 0.0;

        final weightSum = safeNum(group['avg_cost_per_unit_weight']);
        final avgCostPerUnit = weightSum > 0
            ? (safeNum(group['avg_cost_per_unit_weighted_sum']) / weightSum)
            : 0.0;

        return {
          'inventory_item_id': group['inventory_item_id'],
          'product_name': group['product_name'],
          'quantity': safeNum(group['quantity']),
          'revenue': revenueTotal,
          'cost': safeNum(group['cost']),
          'profit': profitTotal,
          'margin': marginVal,
          // Used only by recommendation math; safe for sales and refunds.
          'avg_cost_per_unit': avgCostPerUnit,
        };
      }).toList();

      list.sort(
        (a, b) => safeNum(b['revenue']).compareTo(safeNum(a['revenue'])),
      );
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Read-only: catalog [sell_price] for pricing intelligence (list vs WAC). No writes.
  Future<Map<String, double?>> _fetchSellPricesByItemId(
    Set<String> itemIds,
  ) async {
    if (itemIds.isEmpty) return {};
    final out = <String, double?>{};
    final ids = itemIds.toList();
    const chunk = 100;
    for (var i = 0; i < ids.length; i += chunk) {
      final slice = ids.sublist(
        i,
        i + chunk > ids.length ? ids.length : i + chunk,
      );
      try {
        final response = await _client
            .from('inventory_items')
            .select('id, sell_price')
            .inFilter('id', slice);
        for (final raw in response as List) {
          final m = Map<String, dynamic>.from(raw as Map);
          final id = m['id']?.toString();
          if (id == null) continue;
          out[id] = (m['sell_price'] as num?)?.toDouble();
        }
      } catch (_) {
        // leave missing ids absent
      }
    }
    return out;
  }

  /// Read-only: same enriched rows as [pricing_intelligence] (before profit sort).
  /// Used by dashboard alerts — delegates to [_getProfitAnalysisByProduct] →
  /// [_fetchSellPricesByItemId] → [_buildPricingIntelligenceRows]; no duplicated logic.
  Future<List<Map<String, dynamic>>> getPricingIntelligenceRowsForAlerts(
    DateTime start,
    DateTime end,
  ) async {
    final base = await _getProfitAnalysisByProduct(start, end);
    final ids = base
        .map((r) => r['inventory_item_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty && id != 'unknown')
        .toSet();
    final sellPrices = await _fetchSellPricesByItemId(ids);
    return _buildPricingIntelligenceRows(base, sellPrices);
  }

  /// Extends [base] rows from [_getProfitAnalysisByProduct] with flags and text
  /// recommendations. Read-only; no duplicate transaction queries.
  ///
  /// Revenue and realized [margin] in [base] come only from [transaction_items]:
  /// [line_total], or [quantity] × [unit_price] when [line_total] is absent.
  /// Catalog [inventory_items.sell_price] appears only via [sellPriceById] for
  /// [list_margin] and list-vs-WAC helpers — never mixed with transaction pricing.
  List<Map<String, dynamic>> _buildPricingIntelligenceRows(
    List<Map<String, dynamic>> base,
    Map<String, double?> sellPriceById,
  ) {
    // IMPORTANT:
    // unit_price = actual sale price (transaction_items; aggregated into [base])
    // sell_price = configured product price (inventory_items; [sellPriceById] only)
    // DO NOT mix these sources.

    const lowMarginThreshold = 20.0;
    const highMarginThreshold = 40.0;
    const criticalMarginThreshold = 10.0;

    double safeNum(dynamic v, [double fallback = 0]) {
      if (v == null) return fallback;
      if (v is num) {
        final d = v.toDouble();
        return d.isFinite ? d : fallback;
      }
      return fallback;
    }

    final itemCount = base.length;
    final sortedByRevenue = List<Map<String, dynamic>>.from(base);
    sortedByRevenue.sort(
      (a, b) => safeNum(b['revenue']).compareTo(safeNum(a['revenue'])),
    );

    final topPerformerIds = <String>{};
    if (itemCount >= 8 && sortedByRevenue.isNotEmpty) {
      final thresholdIndex =
          (itemCount * 0.25).floor().clamp(0, sortedByRevenue.length - 1);
      final thresholdRevenue =
          safeNum(sortedByRevenue[thresholdIndex]['revenue']);
      for (final row in base) {
        if (safeNum(row['revenue']) >= thresholdRevenue) {
          final tid = row['inventory_item_id']?.toString() ?? '';
          if (tid.isNotEmpty) topPerformerIds.add(tid);
        }
      }
    } else {
      for (var i = 0; i < sortedByRevenue.length && i < 2; i++) {
        final tid = sortedByRevenue[i]['inventory_item_id']?.toString() ?? '';
        if (tid.isNotEmpty) topPerformerIds.add(tid);
      }
    }

    return base.map((row) {
      final id = row['inventory_item_id']?.toString() ?? '';
      final profit = safeNum(row['profit']);
      final margin = safeNum(row['margin']);
      final quantity = safeNum(row['quantity']);
      final cost = safeNum(row['cost']);
      // IMPORTANT:
      // Financial-only refunds have quantity=0; never divide cost by 1.0.
      // If quantity is zero, fall back to transaction-allocated avg cost per unit.
      final quantityAbs = quantity.abs();
      final avgCostPerUnitFromRow = safeNum(row['avg_cost_per_unit']);
      final avgCostPerUnit = (quantityAbs > 0)
          ? (cost.abs() / quantityAbs)
          : avgCostPerUnitFromRow;
      final avgCostPerUnitSafe = avgCostPerUnit.isFinite ? avgCostPerUnit : 0.0;

      final String marginFlag;
      if (margin < lowMarginThreshold) {
        marginFlag = 'low';
      } else if (margin >= highMarginThreshold) {
        marginFlag = 'high';
      } else {
        marginFlag = 'healthy';
      }

      final profitFlag = profit < 0 ? 'loss' : 'profit';

      final strongPerformer =
          topPerformerIds.contains(id) && margin >= highMarginThreshold;

      final String recommendation;
      if (profit < 0) {
        recommendation =
            'Loss-making — increase price or reduce cost urgently';
      } else if (margin < criticalMarginThreshold) {
        recommendation = 'Increase price or reduce cost';
      } else if (margin < lowMarginThreshold) {
        recommendation = 'Monitor pricing';
      } else if (strongPerformer) {
        recommendation = 'Strong performer — maintain pricing';
      } else {
        recommendation = 'Healthy margin';
      }

      // margin = actual realized margin (from sales)
      // list_margin = theoretical margin based on sell_price
      // markup_pct = markup based on cost (sell_price vs WAC per unit)
      // Catalog list price (inventory_items.sell_price) — not transaction_items.unit_price.
      final sellPrice = sellPriceById[id];
      // NOTE:
      // sell_price must be > 0 to be considered valid.
      // Invalid or null values are ignored to prevent incorrect margin calculations.
      final validSellPrice =
          (sellPrice != null && sellPrice > 0) ? sellPrice : null;

      double? listMarginPct;
      if (validSellPrice != null) {
        final lm = ((validSellPrice - avgCostPerUnitSafe) / validSellPrice) * 100;
        listMarginPct = lm.isFinite ? lm : null;
      }

      double? markupPct;
      if (validSellPrice != null && avgCostPerUnitSafe > 0) {
        final mu =
            ((validSellPrice - avgCostPerUnitSafe) / avgCostPerUnitSafe) * 100;
        markupPct = mu.isFinite ? mu : null;
      }

      final markupFlag = (markupPct != null && markupPct > 100)
          ? 'very_high'
          : 'normal';

      double? priceVsCostRaw;
      String? pricePosition;
      if (validSellPrice != null && quantityAbs > 0) {
        final pvc = validSellPrice - avgCostPerUnitSafe;
        if (pvc.isFinite) priceVsCostRaw = pvc;
        if (validSellPrice < avgCostPerUnitSafe) {
          pricePosition = 'underpriced';
        } else if (listMarginPct != null && listMarginPct.isFinite) {
          pricePosition = listMarginPct >= 50 ? 'premium' : 'healthy';
        }
      }

      return <String, dynamic>{
        ...row,
        'actual_margin': _reportMoney(margin),
        'list_margin':
            listMarginPct != null ? _reportMoney(listMarginPct) : null,
        'markup_pct': markupPct != null ? _reportMoney(markupPct) : null,
        'markup_flag': markupFlag,
        'margin_flag': marginFlag,
        'profit_flag': profitFlag,
        'recommendation': recommendation,
        'price_vs_cost':
            priceVsCostRaw != null ? _reportMoney(priceVsCostRaw) : null,
        'price_position': pricePosition,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getCustomerLoyalty() async {
    try {
      final rows = await _client.from('loyalty_customers').select().order('total_spend', ascending: false).limit(100);
      return (rows as List).map((r) => {
        'name': r['full_name'],
        'tier': r['loyalty_tier'] ?? '—',
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
          .select('id, job_date, hunter_name, contact_phone, species, weight_in, status, charge_total, paid, animal_count')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .order('created_at', ascending: false)
          .limit(200);
      return List<Map<String, dynamic>>.from(rows);
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
          .select('id, name, stock_on_hand_fresh, stock_on_hand_frozen, cost_price, sell_price')
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

  Future<List<Map<String, dynamic>>> getStaffHours(DateTime startDate, DateTime endDate, {String? staffId}) async {
    try {
      var q = _client
          .from('timecards')
          .select('*, staff_profiles(full_name)')
          .gte('clock_in', startDate.toIso8601String())
          .lte('clock_in', endDate.toIso8601String());
      if (staffId != null) q = q.eq('staff_id', staffId);
      final response = await q.order('clock_in', ascending: false);
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

  /// Stock Movement Report — shows inventory changes from received supplier
  /// invoices in the given date range, with opening/closing stock and source.
  Future<ReportData> _getStockMovementReport(
    DateTime start,
    DateTime end,
    String title,
    String subtitle,
  ) async {
    try {
      // Fetch all 'in' movements from supplier invoices in the date range
      final movements = await _client
          .from('stock_movements')
          .select(
            'item_id, quantity, reference_id, created_at, '
            'inventory_items(name, current_stock), '
            'supplier_invoices:reference_id(invoice_number, total_amount, tax_amount, suppliers(name))',
          )
          .eq('movement_type', 'in')
          .eq('reference_type', 'supplier_invoice')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .order('created_at', ascending: true);

      if ((movements as List).isEmpty) {
        // No movements — still return summary from approved invoices
        final invoices = await _client
            .from('supplier_invoices')
            .select('invoice_number, total_amount, tax_amount, suppliers(name)')
            .eq('status', 'received')
            .gte('created_at', start.toIso8601String())
            .lte('created_at', end.toIso8601String());

        final invList = invoices as List;
        final totalAP = invList.fold<double>(
            0, (s, r) => s + ((r['total_amount'] as num?)?.toDouble() ?? 0));
        final totalVAT = invList.fold<double>(
            0, (s, r) => s + ((r['tax_amount'] as num?)?.toDouble() ?? 0));

        return ReportData(
          data: [],
          columns: ['product', 'opening', 'received', 'closing', 'source'],
          columnHeaders: {
            'product': 'Product',
            'opening': 'Opening',
            'received': 'Received',
            'closing': 'Closing',
            'source': 'Source Invoice',
          },
          summary: {
            'Invoices processed': invList.length,
            'Items updated': 0,
            'Total AP': totalAP,
            'VAT claimed': totalVAT,
          },
          title: title,
          subtitle: subtitle,
          monetaryColumns: const {},
        );
      }

      // Aggregate received quantity per product
      final byProduct = <String, Map<String, dynamic>>{};
      for (final m in movements as List) {
        final itemId = m['item_id']?.toString() ?? '';
        final itemInfo = m['inventory_items'];
        final name = (itemInfo is Map ? itemInfo['name'] : null)?.toString() ?? itemId;
        final currentStock = (itemInfo is Map
            ? (itemInfo['current_stock'] as num?)?.toDouble()
            : null) ?? 0.0;
        final qty = (m['quantity'] as num?)?.toDouble() ?? 0;

        // Source invoice label
        final invInfo = m['supplier_invoices'];
        String sourceLabel = '—';
        if (invInfo is Map) {
          final supplierInfo = invInfo['suppliers'];
          final supplierName = (supplierInfo is Map
              ? supplierInfo['name']
              : null)?.toString() ?? '';
          final invNum = invInfo['invoice_number']?.toString() ?? '';
          sourceLabel = [supplierName, invNum]
              .where((s) => s.isNotEmpty)
              .join(' ');
        }

        if (byProduct.containsKey(itemId)) {
          byProduct[itemId]!['received'] =
              (byProduct[itemId]!['received'] as double) + qty;
          // Append additional invoice sources if different
          final existing = byProduct[itemId]!['source'] as String;
          if (sourceLabel != '—' && !existing.contains(sourceLabel)) {
            byProduct[itemId]!['source'] = '$existing; $sourceLabel';
          }
        } else {
          byProduct[itemId] = {
            'product': name,
            'current_stock': currentStock,
            'received': qty,
            'source': sourceLabel,
          };
        }
      }

      // Build rows: opening = current_stock - received (approximate)
      final rows = byProduct.values.map((p) {
        final received = p['received'] as double;
        final current = p['current_stock'] as double;
        final opening = (current - received).clamp(0.0, double.infinity);
        return {
          'product': p['product'],
          'opening': opening,
          'received': received,
          'closing': current,
          'source': p['source'],
        };
      }).toList();

      // Summary: fetch invoice-level totals for the period
      final invoices = await _client
          .from('supplier_invoices')
          .select('id, total_amount, tax_amount')
          .eq('status', 'received')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());

      final invList = invoices as List;
      final totalAP = invList.fold<double>(
          0, (s, r) => s + ((r['total_amount'] as num?)?.toDouble() ?? 0));
      final totalVAT = invList.fold<double>(
          0, (s, r) => s + ((r['tax_amount'] as num?)?.toDouble() ?? 0));

      // Expense entries = ledger rows for these invoices
      int expenseEntries = 0;
      try {
        final invoiceIds = invList.map((r) => r['id']?.toString()).whereType<String>().toList();
        if (invoiceIds.isNotEmpty) {
          final ledger = await _client
              .from('journal_entries')
              .select('id')
              .eq('reference_type', 'supplier_invoice')
              .inFilter('reference_id', invoiceIds);
          expenseEntries = (ledger as List).length;
        }
      } catch (_) {
        // journal_entries table may use a different name — silently ignore
      }

      return ReportData(
        data: rows,
        columns: ['product', 'opening', 'received', 'closing', 'source'],
        columnHeaders: {
          'product': 'Product',
          'opening': 'Opening',
          'received': 'Received',
          'closing': 'Closing',
          'source': 'Source Invoice',
        },
        summary: {
          'Invoices processed': invList.length,
          'Items updated': rows.length,
          'Expense entries': expenseEntries,
          'VAT claimed': totalVAT,
          'Total AP': totalAP,
        },
        title: title,
        subtitle: subtitle,
        monetaryColumns: const {'closing'},
      );
    } catch (e) {
      return ReportData(
        data: [],
        columns: ['product', 'opening', 'received', 'closing', 'source'],
        columnHeaders: {
          'product': 'Product',
          'opening': 'Opening',
          'received': 'Received',
          'closing': 'Closing',
          'source': 'Source Invoice',
        },
        summary: {'Error': e.toString()},
        title: title,
        subtitle: subtitle,
      );
    }
  }
}
