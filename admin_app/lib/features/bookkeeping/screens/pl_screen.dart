import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/core/services/export_service.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/features/bookkeeping/services/ledger_repository.dart';
/// H7: P&L Screen — period selector, compare toggle, export PDF/Excel.
class PLScreen extends StatefulWidget {
  const PLScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PLScreen> createState() => _PLScreenState();
}

class _PLScreenState extends State<PLScreen> {
  final LedgerRepository _ledger = LedgerRepository();
  final ExportService _export = ExportService();
  DateTime _periodStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _periodEnd = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  bool _compareWithPrev = false;
  bool _loading = true;
  Map<String, Map<String, double>> _pnlSummary = {};
  Map<String, Map<String, double>> _prevPnlSummary = {};

  static const _incomeCodes = ['4000', '4100', '4200'];
  static const _cogsCodes = ['5000', '5100', '5200', '5300'];
  static const _expenseCodes = ['6000', '6100', '6200', '6300', '6400', '6500', '6510', '6600', '6700', '6900'];
  static const _accountLabels = {
    '4000': 'Meat Sales (POS)',
    '4100': 'Hunter Processing Fees',
    '4200': 'Other Income',
    '5000': 'Meat Purchases',
    '5100': 'Spices & Casings',
    '5200': 'Packaging Materials',
    '5300': 'Shrinkage / Waste',
    '6000': 'Salaries & Wages',
    '6100': 'Rent',
    '6200': 'Electricity',
    '6300': 'Equipment Maintenance',
    '6400': 'Insurance',
    '6500': 'Marketing & Sponsorship',
    '6510': 'Donations',
    '6600': 'Transport & Fuel',
    '6700': 'Purchase Sale Repayments',
    '6900': 'Sundry Expenses',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final pnl = await _ledger.getPnLSummary(_periodStart, _periodEnd);
      Map<String, Map<String, double>> prevPnl = {};
      if (_compareWithPrev) {
        final prevStart = DateTime(_periodStart.year, _periodStart.month - 1, 1);
        final prevEnd = DateTime(_periodStart.year, _periodStart.month, 0);
        prevPnl = await _ledger.getPnLSummary(prevStart, prevEnd);
      }
      if (mounted) setState(() {
        _pnlSummary = pnl;
        _prevPnlSummary = prevPnl;
        _loading = false;
      });
    } catch (e) {
      debugPrint('P&L load: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  double _revenueTotal() {
    double t = 0;
    for (final code in _incomeCodes) t += _pnlSummary[code]?['credit'] ?? 0;
    return t;
  }

  double _cogsTotal() {
    double t = 0;
    for (final code in _cogsCodes) t += _pnlSummary[code]?['debit'] ?? 0;
    return t;
  }

  double _expensesTotal() {
    double t = 0;
    for (final code in _expenseCodes) t += _pnlSummary[code]?['debit'] ?? 0;
    return t;
  }

  double _prevRevenueTotal() {
    double t = 0;
    for (final code in _incomeCodes) t += _prevPnlSummary[code]?['credit'] ?? 0;
    return t;
  }

  double _prevCogsTotal() {
    double t = 0;
    for (final code in _cogsCodes) t += _prevPnlSummary[code]?['debit'] ?? 0;
    return t;
  }

  double _prevExpensesTotal() {
    double t = 0;
    for (final code in _expenseCodes) t += _prevPnlSummary[code]?['debit'] ?? 0;
    return t;
  }

  void _setPeriod(String preset) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;
    switch (preset) {
      case 'this_month':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case 'last_month':
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0);
        break;
      case 'this_quarter':
        final q = ((now.month - 1) / 3).floor() * 3 + 1;
        start = DateTime(now.year, q, 1);
        end = DateTime(now.year, q + 3, 0);
        break;
      case 'this_year':
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31);
        break;
      case 'custom':
        _showCustomPeriodPicker();
        return;
      default:
        return;
    }
    setState(() {
      _periodStart = start;
      _periodEnd = end;
    });
    _load();
  }

  Future<void> _showCustomPeriodPicker() async {
    final start = await showDatePicker(
      context: context,
      initialDate: _periodStart,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (start == null || !mounted) return;
    final end = await showDatePicker(
      context: context,
      initialDate: _periodEnd.isBefore(start) ? start : _periodEnd,
      firstDate: start,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (end == null || !mounted) return;
    if (end.isBefore(start)) return;
    setState(() {
      _periodStart = start;
      _periodEnd = end;
    });
    _load();
  }

  Future<void> _exportPdf() async {
    try {
      final data = _buildExportData();
      final file = await _export.exportToPdf(
        fileName: 'pl_${_periodStart.year}${_periodStart.month.toString().padLeft(2, '0')}',
        title: 'Profit & Loss Statement',
        subtitle: '${_formatDate(_periodStart)} to ${_formatDate(_periodEnd)}',
        data: data,
        columns: const ['section', 'account', 'amount'],
        columnHeaders: const {'section': 'Section', 'account': 'Account', 'amount': 'Amount (R)'},
        summary: {
          'Gross Revenue': _revenueTotal(),
          'COGS': _cogsTotal(),
          'Gross Profit': _revenueTotal() - _cogsTotal(),
          'Operating Expenses': _expensesTotal(),
          'Net Profit': _revenueTotal() - _cogsTotal() - _expensesTotal(),
        },
      );
      if (mounted) await _export.shareFile(file, 'P&L Statement');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _exportExcel() async {
    try {
      final data = _buildExportData();
      final file = await _export.exportToExcel(
        fileName: 'pl_${_periodStart.year}${_periodStart.month.toString().padLeft(2, '0')}',
        data: data,
        columns: const ['section', 'account', 'amount'],
        columnHeaders: const {'section': 'Section', 'account': 'Account', 'amount': 'Amount (R)'},
        sheetName: 'P&L',
      );
      if (mounted) await _export.shareFile(file, 'P&L Statement');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error),
        );
      }
    }
  }

  List<Map<String, dynamic>> _buildExportData() {
    final rows = <Map<String, dynamic>>[];
    for (final code in _incomeCodes) {
      final credit = _pnlSummary[code]?['credit'] ?? 0;
      if (credit != 0) rows.add({'section': 'Income', 'account': _accountLabels[code] ?? code, 'amount': credit});
    }
    rows.add({'section': 'Income', 'account': 'Gross Revenue', 'amount': _revenueTotal()});
    for (final code in _cogsCodes) {
      final debit = _pnlSummary[code]?['debit'] ?? 0;
      if (debit != 0) rows.add({'section': 'COGS', 'account': _accountLabels[code] ?? code, 'amount': debit});
    }
    rows.add({'section': 'COGS', 'account': 'Total COGS', 'amount': _cogsTotal()});
    rows.add({'section': 'Summary', 'account': 'Gross Profit', 'amount': _revenueTotal() - _cogsTotal()});
    for (final code in _expenseCodes) {
      final debit = _pnlSummary[code]?['debit'] ?? 0;
      if (debit != 0) rows.add({'section': 'OpEx', 'account': _accountLabels[code] ?? code, 'amount': debit});
    }
    rows.add({'section': 'OpEx', 'account': 'Total Operating Expenses', 'amount': _expensesTotal()});
    rows.add({'section': 'Summary', 'account': 'Net Profit / Loss', 'amount': _revenueTotal() - _cogsTotal() - _expensesTotal()});
    return rows;
  }

  String _formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _periodLabel() {
    if (_periodStart.year == _periodEnd.year && _periodStart.month == _periodEnd.month) {
      return '${_periodStart.year}-${_periodStart.month.toString().padLeft(2, '0')}';
    }
    return '${_formatDate(_periodStart)} to ${_formatDate(_periodEnd)}';
  }

  String _prevPeriodLabel() {
    final prevStart = DateTime(_periodStart.year, _periodStart.month - 1, 1);
    final prevEnd = DateTime(_periodStart.year, _periodStart.month, 0);
    return '${prevStart.year}-${prevStart.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    final revenue = _revenueTotal();
    final cogs = _cogsTotal();
    final grossProfit = revenue - cogs;
    final grossPct = revenue > 0 ? (grossProfit / revenue * 100) : 0.0;
    final expenses = _expensesTotal();
    final netProfit = grossProfit - expenses;
    final netPct = revenue > 0 ? (netProfit / revenue * 100) : 0.0;
    final prevRevenue = _prevRevenueTotal();
    final prevCogs = _prevCogsTotal();
    final prevExpenses = _prevExpensesTotal();
    final prevGross = prevRevenue - prevCogs;
    final prevNet = prevGross - prevExpenses;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Wrap(
                spacing: 8,
                children: [
                  _periodChip('This Month', 'this_month'),
                  _periodChip('Last Month', 'last_month'),
                  _periodChip('This Quarter', 'this_quarter'),
                  _periodChip('This Year', 'this_year'),
                  _periodChip('Custom', 'custom'),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Compare with prev period', style: TextStyle(fontSize: 12)),
                      Switch(
                        value: _compareWithPrev,
                        onChanged: (v) => setState(() {
                          _compareWithPrev = v;
                          _load();
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _exportPdf,
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('Export PDF'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _exportExcel,
                    icon: const Icon(Icons.table_chart, size: 18),
                    label: const Text('Export Excel'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PROFIT & LOSS STATEMENT', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Period: $_periodLabel', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  if (_compareWithPrev) Text('vs $_prevPeriodLabel', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  const Divider(height: 32),
                  if (_compareWithPrev)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          Row(
                            children: [
                              SizedBox(width: 100, child: Text(_prevPeriodLabel(), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
                              SizedBox(width: 100, child: Text(_periodLabel(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  _sectionHeader('INCOME'),
                  ..._incomeCodes.map((code) => _dataRow(_accountLabels[code] ?? code, _pnlSummary[code]?['credit'] ?? 0, _compareWithPrev ? (_prevPnlSummary[code]?['credit'] ?? 0) : null)),
                  _subtotalRow('Gross Revenue', revenue, _compareWithPrev ? prevRevenue : null),
                  const SizedBox(height: 24),
                  _sectionHeader('COST OF GOODS SOLD'),
                  ..._cogsCodes.map((code) => _dataRow(_accountLabels[code] ?? code, _pnlSummary[code]?['debit'] ?? 0, _compareWithPrev ? (_prevPnlSummary[code]?['debit'] ?? 0) : null)),
                  const Divider(),
                  _boldRow('GROSS PROFIT', grossProfit, grossPct, AppColors.info, _compareWithPrev ? prevGross : null),
                  const SizedBox(height: 24),
                  _sectionHeader('OPERATING EXPENSES'),
                  ..._expenseCodes.map((code) => _dataRow(_accountLabels[code] ?? code, _pnlSummary[code]?['debit'] ?? 0, _compareWithPrev ? (_prevPnlSummary[code]?['debit'] ?? 0) : null)),
                  const Divider(),
                  _subtotalRow('Total Operating Expenses', expenses, _compareWithPrev ? prevExpenses : null),
                  const SizedBox(height: 24),
                  _boldRow('NET PROFIT / LOSS', netProfit, netPct, netProfit >= 0 ? AppColors.success : AppColors.error, _compareWithPrev ? prevNet : null),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isPeriodSelected(String value) {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    switch (value) {
      case 'this_month':
        return _periodStart == DateTime(now.year, now.month, 1) && _periodEnd == lastDayOfMonth;
      case 'last_month':
        return _periodStart == DateTime(now.year, now.month - 1, 1) && _periodEnd == DateTime(now.year, now.month, 0);
      case 'this_quarter':
        final q = ((now.month - 1) / 3).floor() * 3 + 1;
        return _periodStart == DateTime(now.year, q, 1) && _periodEnd == DateTime(now.year, q + 3, 0);
      case 'this_year':
        return _periodStart == DateTime(now.year, 1, 1) && _periodEnd == DateTime(now.year, 12, 31);
      default:
        return false;
    }
  }

  Widget _periodChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _isPeriodSelected(value),
      onSelected: (_) => _setPeriod(value),
    );
  }

  Widget _sectionHeader(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
  );

  Widget _dataRow(String label, double amount, double? prevAmount) {
    if (amount == 0 && (prevAmount == null || prevAmount == 0)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              if (_compareWithPrev && prevAmount != null)
                SizedBox(width: 100, child: Text('R ${prevAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textSecondary))),
              SizedBox(width: 100, child: Text('R ${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _subtotalRow(String label, double amount, double? prevAmount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              if (_compareWithPrev && prevAmount != null)
                SizedBox(width: 100, child: Text('R ${prevAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
              SizedBox(width: 100, child: Text('R ${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _boldRow(String label, double amount, double pct, Color color, double? prevAmount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          Row(
            children: [
              if (_compareWithPrev && prevAmount != null)
                SizedBox(width: 100, child: Text('R ${prevAmount.toStringAsFixed(2)}', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
              SizedBox(width: 100, child: Text('R ${amount.toStringAsFixed(2)} (${pct.toStringAsFixed(1)}%)', style: TextStyle(fontWeight: FontWeight.bold, color: color))),
            ],
          ),
        ],
      ),
    );
  }
}
