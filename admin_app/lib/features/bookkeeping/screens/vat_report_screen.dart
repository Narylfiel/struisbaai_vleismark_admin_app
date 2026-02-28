import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/core/services/export_service.dart';
import 'package:admin_app/features/bookkeeping/services/ledger_repository.dart';

/// H7: VAT 201 Report — bi-monthly period pairs, Output/Input VAT, Net VAT payable/refundable.
class VatReportScreen extends StatefulWidget {
  const VatReportScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<VatReportScreen> createState() => _VatReportScreenState();
}

class _VatReportScreenState extends State<VatReportScreen> {
  final LedgerRepository _ledger = LedgerRepository();
  final ExportService _export = ExportService();
  // Bi-monthly: Jan-Feb=1, Mar-Apr=3, May-Jun=5, Jul-Aug=7, Sep-Oct=9, Nov-Dec=11
  int _periodMonth = 1; // 1, 3, 5, 7, 9, 11
  int _periodYear = DateTime.now().year;
  bool _loading = true;
  double _outputVat = 0, _inputVat = 0, _vatPayable = 0;

  static const _bimonthlyPairs = [
    (1, 2, 'Jan-Feb'),
    (3, 4, 'Mar-Apr'),
    (5, 6, 'May-Jun'),
    (7, 8, 'Jul-Aug'),
    (9, 10, 'Sep-Oct'),
    (11, 12, 'Nov-Dec'),
  ];

  @override
  void initState() {
    super.initState();
    _alignToCurrentBiMonth();
    _load();
  }

  void _alignToCurrentBiMonth() {
    final now = DateTime.now();
    final m = now.month;
    if (m <= 2) {
      _periodMonth = 1;
      _periodYear = now.year;
    } else if (m <= 4) {
      _periodMonth = 3;
      _periodYear = now.year;
    } else if (m <= 6) {
      _periodMonth = 5;
      _periodYear = now.year;
    } else if (m <= 8) {
      _periodMonth = 7;
      _periodYear = now.year;
    } else if (m <= 10) {
      _periodMonth = 9;
      _periodYear = now.year;
    } else {
      _periodMonth = 11;
      _periodYear = now.year;
    }
  }

  DateTime get _periodStart => DateTime(_periodYear, _periodMonth, 1);
  DateTime get _periodEnd => DateTime(_periodYear, _periodMonth + 1, 0);
  String get _periodLabel {
    final pair = _bimonthlyPairs.firstWhere((p) => p.$1 == _periodMonth, orElse: () => (1, 2, 'Jan-Feb'));
    return '${pair.$3} $_periodYear';
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final vat = await _ledger.getVatSummary(_periodStart, _periodEnd);
      if (mounted) setState(() {
        _outputVat = vat.outputVat;
        _inputVat = vat.inputVat;
        _vatPayable = vat.payable;
        _loading = false;
      });
    } catch (e) {
      debugPrint('VAT load: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectPeriod(int month, int year) {
    setState(() {
      _periodMonth = month;
      _periodYear = year;
    });
    _load();
  }

  Future<void> _exportPdf() async {
    try {
      final data = [
        {'Item': 'Output VAT (collected from customers)', 'Amount': _outputVat},
        {'Item': 'Input VAT (paid to suppliers)', 'Amount': _inputVat},
        {'Item': _vatPayable >= 0 ? 'VAT Payable to SARS' : 'VAT Refundable', 'Amount': _vatPayable.abs()},
      ];
      final file = await _export.exportToPdf(
        fileName: 'vat201_${_periodYear}_${_periodMonth.toString().padLeft(2, '0')}',
        title: 'VAT 201 Return',
        subtitle: _periodLabel,
        data: data,
        columns: const ['Item', 'Amount'],
        columnHeaders: const {'Item': 'Item', 'Amount': 'Amount (R)'},
      );
      if (mounted) await _export.shareFile(file, 'VAT 201 Return — $_periodLabel');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    final isPayable = _vatPayable >= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('VAT 201 Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 24),
              SizedBox(
                width: 90,
                child: DropdownButtonFormField<int>(
                  value: _periodYear,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: List.generate(5, (i) => DateTime.now().year - i).map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                  onChanged: (y) => y != null ? _selectPeriod(_periodMonth, y) : null,
                ),
              ),
              const SizedBox(width: 16),
              Wrap(
                spacing: 8,
                children: _bimonthlyPairs.map((pair) {
                  return FilterChip(
                    label: Text(pair.$3),
                    selected: _periodMonth == pair.$1,
                    onSelected: (_) => _selectPeriod(pair.$1, _periodYear),
                  );
                }).toList(),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _exportPdf,
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('Export PDF'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('VAT 201 Return — $_periodLabel', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text('From ledger entries (account 2100)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const Divider(height: 32),
                  _vatRow('Output VAT (collected from customers)', _outputVat),
                  _vatRow('Input VAT (paid to suppliers)', _inputVat),
                  const Divider(),
                  if (isPayable)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('VAT PAYABLE TO SARS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('R ${_vatPayable.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.error)),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('VAT REFUNDABLE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('R ${_vatPayable.abs().toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.success)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vatRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('R ${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
