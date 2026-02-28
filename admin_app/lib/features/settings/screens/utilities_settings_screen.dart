import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/features/settings/services/settings_repository.dart';

/// Utilities & Costs — electricity rate for dryer cost tracking.
class UtilitiesSettingsScreen extends StatefulWidget {
  const UtilitiesSettingsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<UtilitiesSettingsScreen> createState() => _UtilitiesSettingsScreenState();
}

class _UtilitiesSettingsScreenState extends State<UtilitiesSettingsScreen> {
  final _repo = SettingsRepository();
  final _rateController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _lastUpdated;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rate = await _repo.getElectricityRate();
      final config = await _repo.getElectricityRateConfig();
      if (mounted) {
        _rateController.text = rate.toString();
        final updated = config?['updated_at']?.toString();
        _lastUpdated = updated != null ? _formatUpdated(updated) : null;
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatUpdated(String iso) {
    try {
      final d = DateTime.tryParse(iso);
      if (d != null) {
        return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
            '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {}
    return iso;
  }

  Future<void> _save() async {
    final rate = double.tryParse(_rateController.text);
    if (rate == null || rate < 0) {
      setState(() => _error = 'Enter a valid rate (R/kWh)');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repo.updateElectricityRate(rate);
      if (mounted) {
        _lastUpdated = _formatUpdated(DateTime.now().toIso8601String());
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Electricity rate saved'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorHandler.friendlyMessage(e);
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Utilities & Costs',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        const Text(
          'Update when Eskom tariff changes.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _rateController,
          decoration: const InputDecoration(
            labelText: 'Electricity rate (R/kWh)',
            border: OutlineInputBorder(),
            hintText: 'e.g. 2.50',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 12),
        if (_lastUpdated != null)
          Text(
            'Last updated: $_lastUpdated',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(fontSize: 12, color: AppColors.danger),
          ),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
