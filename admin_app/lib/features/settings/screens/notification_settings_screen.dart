import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/responsive/responsive_breakpoints.dart';
import 'package:admin_app/core/responsive/responsive_widgets.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import '../../../core/services/email_service.dart';

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
  final _emailService = EmailService();
  final _smtpHostController = TextEditingController();
  final _smtpPortController = TextEditingController(text: '465');
  final _smtpUsernameController = TextEditingController();
  final _smtpPasswordController = TextEditingController();
  final _smtpFromNameController = TextEditingController();
  bool _smtpLoading = false;
  bool _smtpTesting = false;
  bool _smtpObscure = true;

  // Break alert config
  int _shortBreakThreshold = 5;
  int _overrunThreshold = 45;
  bool _enablePosAlerts = true;
  bool _enableEmailAlerts = true;
  final _alertEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _whatsappController.dispose();
    _alertEmailController.dispose();
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
      final breakRow = await _client
          .from('business_settings')
          .select('setting_value')
          .eq('setting_key', 'break_alert_config')
          .maybeSingle();
      final breakCfg = breakRow?['setting_value'];
      if (breakCfg is Map) {
        _shortBreakThreshold =
            (breakCfg['short_break_threshold_minutes'] as num?)?.toInt() ?? 5;
        _overrunThreshold =
            (breakCfg['break_overrun_threshold_minutes'] as num?)?.toInt() ?? 45;
        _enablePosAlerts = breakCfg['enable_pos_alerts'] == true;
        _enableEmailAlerts = breakCfg['enable_email_alerts'] == true;
        _alertEmailController.text =
            breakCfg['alert_email'] as String? ?? '';
      }
      await _loadSmtpSettings();
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

      await _upsertSetting('notification_config', config);
      await _upsertSetting(
        'admin_whatsapp_number',
        _whatsappController.text.trim(),
      );
      await _upsertSetting('break_alert_config', {
        'short_break_threshold_minutes': _shortBreakThreshold,
        'break_overrun_threshold_minutes': _overrunThreshold,
        'enable_pos_alerts': _enablePosAlerts,
        'enable_email_alerts': _enableEmailAlerts,
        'alert_email': _alertEmailController.text.trim(),
      });

      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification settings saved'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.friendlyMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Safe upsert for business_settings — works without a unique
  /// constraint on setting_key by doing select → update or insert.
  Future<void> _upsertSetting(String key, dynamic value) async {
    final existing = await _client
        .from('business_settings')
        .select('id')
        .eq('setting_key', key)
        .maybeSingle();
    if (existing != null) {
      await _client
          .from('business_settings')
          .update({'setting_value': value})
          .eq('setting_key', key);
    } else {
      await _client
          .from('business_settings')
          .insert({'setting_key': key, 'setting_value': value});
    }
  }

  Future<void> _testWhatsApp() async {
    var num = _whatsappController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (num.startsWith('0')) {
      num = '27${num.substring(1)}';
    } else if (!num.startsWith('27')) num = '27$num';
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

  Future<void> _loadSmtpSettings() async {
    final creds = await _emailService.loadCredentials();
    if (mounted) {
      setState(() {
        _smtpHostController.text = creds['host'] ?? 'mail.struisbaai-slaghuis.co.za';
        _smtpPortController.text = creds['port'] ?? '465';
        _smtpUsernameController.text = creds['username'] ?? 'leon@struisbaai-slaghuis.co.za';
        _smtpPasswordController.text = creds['password'] ?? '';
        _smtpFromNameController.text = creds['from_name'] ?? 'Struisbaai Vleismark';
      });
    }
  }

  Future<void> _saveSmtpSettings() async {
    setState(() => _smtpLoading = true);
    try {
      await _emailService.saveCredentials(
        host: _smtpHostController.text.trim(),
        port: int.tryParse(_smtpPortController.text.trim()) ?? 465,
        username: _smtpUsernameController.text.trim(),
        password: _smtpPasswordController.text,
        fromName: _smtpFromNameController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Email settings saved'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Save failed: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _smtpLoading = false);
    }
  }

  Future<void> _testSmtpConnection() async {
    setState(() => _smtpTesting = true);
    final result = await _emailService.testConnection();
    if (mounted) {
      setState(() => _smtpTesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['success'] == true
              ? 'Connection successful'
              : 'Connection failed: ${result['error']}'),
          backgroundColor: result['success'] == true
              ? AppColors.success
              : AppColors.error,
        ),
      );
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
                  initialValue: _invoiceOverdueDays,
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
                  initialValue: _documentExpiryDays,
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
          const Text(
            'Break & Staff Alerts',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Alerts appear on the POS screen when a staff member '
            'takes a suspiciously short break or overruns their break time.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Show alerts on POS screen'),
            value: _enablePosAlerts,
            onChanged: (v) => setState(() => _enablePosAlerts = v),
            activeThumbColor: AppColors.primary,
            dense: true,
          ),
          SwitchListTile(
            title: const Text('Email alerts to manager'),
            value: _enableEmailAlerts,
            onChanged: (v) => setState(() => _enableEmailAlerts = v),
            activeThumbColor: AppColors.primary,
            dense: true,
          ),
          if (_enableEmailAlerts) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _alertEmailController,
              decoration: const InputDecoration(
                labelText: 'Alert recipient email',
                hintText: 'manager@yourbusiness.co.za',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Short break threshold: $_shortBreakThreshold min',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Slider(
            value: _shortBreakThreshold.toDouble(),
            min: 1,
            max: 15,
            divisions: 14,
            label: '$_shortBreakThreshold min',
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _shortBreakThreshold = v.toInt()),
          ),
          Text(
            'Break overrun alert after: $_overrunThreshold min',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Slider(
            value: _overrunThreshold.toDouble(),
            min: 15,
            max: 90,
            divisions: 15,
            label: '$_overrunThreshold min',
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _overrunThreshold = v.toInt()),
          ),
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
          const SizedBox(height: 24),
          const Text('Email / Invoice Delivery',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text(
              'SMTP credentials for sending customer invoices automatically. '
              'Password is stored securely on this device only.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          ResponsiveBreakpoints.isPhoneLayout(context)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _smtpHostController,
                      decoration: const InputDecoration(
                          labelText: 'SMTP Host', isDense: true),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _smtpPortController,
                      decoration:
                          const InputDecoration(labelText: 'Port', isDense: true),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _smtpHostController,
                        decoration: const InputDecoration(
                            labelText: 'SMTP Host', isDense: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        controller: _smtpPortController,
                        decoration: const InputDecoration(
                            labelText: 'Port', isDense: true),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _smtpUsernameController,
            decoration: const InputDecoration(
                labelText: 'Email address (username)', isDense: true),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _smtpPasswordController,
            decoration: InputDecoration(
              labelText: 'Password',
              isDense: true,
              suffixIcon: IconButton(
                icon: Icon(
                    _smtpObscure ? Icons.visibility_off : Icons.visibility,
                    size: 18),
                onPressed: () =>
                    setState(() => _smtpObscure = !_smtpObscure),
              ),
            ),
            obscureText: _smtpObscure,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _smtpFromNameController,
            decoration: const InputDecoration(
                labelText: 'From name (shown to recipient)', isDense: true),
          ),
          const SizedBox(height: 12),
          AdaptiveActionRow(
            children: [
              OutlinedButton.icon(
                onPressed: _smtpTesting ? null : _testSmtpConnection,
                icon: _smtpTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.wifi_tethering, size: 16),
                label: Text(_smtpTesting ? 'Testing…' : 'Test connection'),
              ),
              FilledButton.icon(
                onPressed: _smtpLoading ? null : _saveSmtpSettings,
                icon: _smtpLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, size: 16),
                label: Text(_smtpLoading ? 'Saving…' : 'Save email settings'),
              ),
            ],
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
          activeThumbColor: AppColors.primary,
        ),
        ...children,
      ],
    );
  }
}
