import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/core/services/supabase_service.dart';

/// M2: Notification Settings — alert toggles, thresholds, WhatsApp.
/// Load/save from business_settings as json object.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final _client = SupabaseService.client;
  final _whatsappController = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  final _alerts = {
    'low_stock_alerts': true,
    'shrinkage_alerts': true,
    'payroll_reminder': true,
    'leave_notifications': true,
    'overdue_invoice_alerts': true,
    'document_expiry_warnings': true,
  };
  double _lowStockBuffer = 10;
  double _shrinkageThreshold = 15;
  int _invoiceOverdueDays = 30;
  int _documentExpiryDays = 30;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final row = await _client
          .from('business_settings')
          .select('setting_value')
          .eq('setting_key', 'notification_config')
          .maybeSingle();
      final data = row?['setting_value'];
      if (data is Map) {
        final m = Map<String, dynamic>.from(data);
        for (final k in _alerts.keys) {
          if (m[k] != null) _alerts[k] = m[k] == true;
        }
        _lowStockBuffer = (m['low_stock_buffer'] as num?)?.toDouble() ?? 10;
        _shrinkageThreshold = (m['shrinkage_threshold'] as num?)?.toDouble() ?? 15;
        _invoiceOverdueDays = (m['invoice_overdue_days'] as num?)?.toInt() ?? 30;
        _documentExpiryDays = (m['document_expiry_days'] as num?)?.toInt() ?? 30;
      }
      final whatsappRow = await _client
          .from('business_settings')
          .select('setting_value')
          .eq('setting_key', 'admin_whatsapp_number')
          .maybeSingle();
      if (whatsappRow?['setting_value'] != null) {
        _whatsappController.text = whatsappRow!['setting_value'].toString();
      }
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final config = {
        ..._alerts,
        'low_stock_buffer': _lowStockBuffer,
        'shrinkage_threshold': _shrinkageThreshold,
        'invoice_overdue_days': _invoiceOverdueDays,
        'document_expiry_days': _documentExpiryDays,
      };
      await _client.from('business_settings').upsert(
        {'setting_key': 'notification_config', 'setting_value': config},
        onConflict: 'setting_key',
      );
      await _client.from('business_settings').upsert(
        {'setting_key': 'admin_whatsapp_number', 'setting_value': _whatsappController.text.trim()},
        onConflict: 'setting_key',
      );
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification settings saved'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _testWhatsApp() async {
    var num = _whatsappController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (num.startsWith('0')) num = '27${num.substring(1)}';
    else if (!num.startsWith('27')) num = '27$num';
    if (num.length < 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid WhatsApp number'), backgroundColor: AppColors.warning),
      );
      return;
    }
    final uri = Uri.parse('https://wa.me/$num?text=${Uri.encodeComponent('Test alert from Admin App')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
          _switchTile('Low Stock Alerts', 'low_stock_alerts', [
            if (_alerts['low_stock_alerts'] == true)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Low stock buffer: ${_lowStockBuffer.toInt()}%', style: const TextStyle(fontSize: 12)),
                    Slider(
                      value: _lowStockBuffer,
                      min: 0,
                      max: 50,
                      divisions: 10,
                      onChanged: (v) => setState(() => _lowStockBuffer = v),
                    ),
                  ],
                ),
              ),
          ]),
          _switchTile('Shrinkage Alerts', 'shrinkage_alerts', [
            if (_alerts['shrinkage_alerts'] == true)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Shrinkage threshold: ${_shrinkageThreshold.toInt()}%', style: const TextStyle(fontSize: 12)),
                    Slider(
                      value: _shrinkageThreshold,
                      min: 0,
                      max: 30,
                      divisions: 30,
                      onChanged: (v) => setState(() => _shrinkageThreshold = v),
                    ),
                  ],
                ),
              ),
          ]),
          _switchTile('Payroll Reminder', 'payroll_reminder', []),
          _switchTile('Leave Notifications', 'leave_notifications', []),
          _switchTile('Overdue Invoice Alerts', 'overdue_invoice_alerts', [
            if (_alerts['overdue_invoice_alerts'] == true)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: DropdownButtonFormField<int>(
                  value: _invoiceOverdueDays,
                  decoration: const InputDecoration(labelText: 'Invoice overdue after', border: OutlineInputBorder(), isDense: true),
                  items: const [
                    DropdownMenuItem(value: 7, child: Text('7 days')),
                    DropdownMenuItem(value: 14, child: Text('14 days')),
                    DropdownMenuItem(value: 30, child: Text('30 days')),
                    DropdownMenuItem(value: 60, child: Text('60 days')),
                  ],
                  onChanged: (v) => setState(() => _invoiceOverdueDays = v ?? 30),
                ),
              ),
          ]),
          _switchTile('Document Expiry Warnings', 'document_expiry_warnings', [
            if (_alerts['document_expiry_warnings'] == true)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: DropdownButtonFormField<int>(
                  value: _documentExpiryDays,
                  decoration: const InputDecoration(labelText: 'Document expiry warning', border: OutlineInputBorder(), isDense: true),
                  items: const [
                    DropdownMenuItem(value: 14, child: Text('14 days')),
                    DropdownMenuItem(value: 30, child: Text('30 days')),
                    DropdownMenuItem(value: 60, child: Text('60 days')),
                    DropdownMenuItem(value: 90, child: Text('90 days')),
                  ],
                  onChanged: (v) => setState(() => _documentExpiryDays = v ?? 30),
                ),
              ),
          ]),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          TextFormField(
            controller: _whatsappController,
            decoration: const InputDecoration(
              labelText: 'Admin WhatsApp number',
              hintText: '27821234567 — no + prefix',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _testWhatsApp,
            icon: const Icon(Icons.chat, size: 18),
            label: const Text('Test'),
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

  Widget _switchTile(String title, String key, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(title),
          value: _alerts[key] ?? false,
          onChanged: (v) => setState(() => _alerts[key] = v),
          activeColor: AppColors.primary,
        ),
        ...children,
      ],
    );
  }
}
