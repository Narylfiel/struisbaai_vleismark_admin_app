import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/core/services/supabase_service.dart';

/// M2: Tax Settings — VAT, reporting period, income tax provision.
/// Load/save from business_settings key-value.
class TaxSettingsScreen extends StatefulWidget {
  const TaxSettingsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<TaxSettingsScreen> createState() => _TaxSettingsScreenState();
}

class _TaxSettingsScreenState extends State<TaxSettingsScreen> {
  final _client = SupabaseService.client;
  final _vatNumberController = TextEditingController();
  final _incomeTaxController = TextEditingController();
  final _vatRateController = TextEditingController();
  String _vatPeriod = 'Jan-Feb (Period 1)';
  bool _loading = true;
  bool _saving = false;

  static const _vatPeriods = [
    'Jan-Feb (Period 1)',
    'Mar-Apr (Period 2)',
    'May-Jun (Period 3)',
    'Jul-Aug (Period 4)',
    'Sep-Oct (Period 5)',
    'Nov-Dec (Period 6)',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _vatNumberController.dispose();
    _incomeTaxController.dispose();
    _vatRateController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await _client.from('business_settings').select('setting_key, setting_value');
      final map = <String, dynamic>{};
      for (final r in rows as List) {
        final k = r['setting_key']?.toString();
        if (k != null) map[k] = r['setting_value'];
      }
      if (mounted) setState(() {
        _vatRateController.text = (_parseDouble(map['vat_rate']) ?? 15).toString();
        _vatNumberController.text = map['vat_number']?.toString() ?? '';
        _vatPeriod = map['vat_reporting_period']?.toString() ?? _vatPeriods[0];
        _incomeTaxController.text = map['income_tax_provision_pct']?.toString() ?? '';
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final vatRate = double.tryParse(_vatRateController.text) ?? 15;
      final items = [
        {'setting_key': 'vat_rate', 'setting_value': vatRate},
        {'setting_key': 'vat_number', 'setting_value': _vatNumberController.text.trim()},
        {'setting_key': 'vat_reporting_period', 'setting_value': _vatPeriod},
        {'setting_key': 'income_tax_provision_pct', 'setting_value': _incomeTaxController.text.trim().isEmpty ? null : double.tryParse(_incomeTaxController.text)},
      ];
      for (final item in items) {
        await _client.from('business_settings').upsert(
          {'setting_key': item['setting_key'], 'setting_value': item['setting_value']},
          onConflict: 'setting_key',
        );
      }
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tax settings saved'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tax Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 120,
                child: TextFormField(
                  controller: _vatRateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'VAT Rate',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text('% — South Africa', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _vatNumberController,
            decoration: const InputDecoration(
              labelText: 'VAT Registration Number',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _vatPeriods.contains(_vatPeriod) ? _vatPeriod : _vatPeriods[0],
            decoration: const InputDecoration(
              labelText: 'VAT Reporting Period',
              border: OutlineInputBorder(),
            ),
            items: _vatPeriods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (v) => setState(() => _vatPeriod = v ?? _vatPeriods[0]),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _incomeTaxController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Income Tax Provision % (optional)',
              hintText: 'For monthly tax accrual',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Text('Currency: ', style: TextStyle(color: AppColors.textSecondary)),
              Text('ZAR — South African Rand', style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save'),
          ),
        ],
      ),
    );
  }
}
