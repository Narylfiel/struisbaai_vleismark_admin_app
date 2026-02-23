import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/supabase_service.dart';

/// M2: Scale Settings — model, connection, COM port, baud rate.
/// Load/save from business_settings key-value.
class ScaleSettingsScreen extends StatefulWidget {
  const ScaleSettingsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ScaleSettingsScreen> createState() => _ScaleSettingsScreenState();
}

class _ScaleSettingsScreenState extends State<ScaleSettingsScreen> {
  final _client = SupabaseService.client;
  final _comPortController = TextEditingController();
  String _scaleModel = 'None';
  String _connection = 'Bluetooth';
  String _baudRate = '9600';
  bool _loading = true;
  bool _saving = false;

  static const _models = ['None', 'DIGI DS-700', 'CAS SW-1W', 'Adam CBC', 'Other'];
  static const _baudRates = ['9600', '19200', '38400', '115200'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _comPortController.dispose();
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
        _scaleModel = map['scale_model']?.toString() ?? 'None';
        _connection = map['scale_connection']?.toString() ?? 'Bluetooth';
        _comPortController.text = map['scale_com_port']?.toString() ?? '';
        _baudRate = map['scale_baud_rate']?.toString() ?? '9600';
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final items = [
        {'setting_key': 'scale_model', 'setting_value': _scaleModel},
        {'setting_key': 'scale_connection', 'setting_value': _connection},
        {'setting_key': 'scale_com_port', 'setting_value': _comPortController.text.trim()},
        {'setting_key': 'scale_baud_rate', 'setting_value': _baudRate},
      ];
      for (final item in items) {
        await _client.from('business_settings').upsert(
          {'setting_key': item['setting_key'], 'setting_value': item['setting_value']},
          onConflict: 'setting_key',
        );
      }
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scale settings saved'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  void _testConnection() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scale hardware integration coming in a future update.'), backgroundColor: AppColors.info),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Scale integration is available for future configuration. All weights are currently entered manually.',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: _scaleModel,
            decoration: const InputDecoration(
              labelText: 'Scale Model',
              border: OutlineInputBorder(),
            ),
            items: _models.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setState(() => _scaleModel = v ?? 'None'),
          ),
          const SizedBox(height: 16),
          const Text('Connection', style: TextStyle(fontWeight: FontWeight.w500)),
          Row(
            children: [
              Radio<String>(
                value: 'Bluetooth',
                groupValue: _connection,
                onChanged: (v) => setState(() => _connection = v!),
              ),
              const Text('Bluetooth'),
              Radio<String>(
                value: 'USB',
                groupValue: _connection,
                onChanged: (v) => setState(() => _connection = v!),
              ),
              const Text('USB'),
              Radio<String>(
                value: 'Serial',
                groupValue: _connection,
                onChanged: (v) => setState(() => _connection = v!),
              ),
              const Text('Serial'),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _comPortController,
            decoration: const InputDecoration(
              labelText: 'COM Port / Device ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _baudRate,
            decoration: const InputDecoration(
              labelText: 'Baud Rate',
              border: OutlineInputBorder(),
            ),
            items: _baudRates.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
            onChanged: (v) => setState(() => _baudRate = v ?? '9600'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              OutlinedButton(
                onPressed: _testConnection,
                child: const Text('Test Connection'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
