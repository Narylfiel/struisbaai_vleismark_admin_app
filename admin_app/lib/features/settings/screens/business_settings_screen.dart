import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/features/settings/services/settings_repository.dart';
import 'package:admin_app/features/settings/screens/tax_settings_screen.dart';
import 'package:admin_app/features/settings/screens/scale_settings_screen.dart';
import 'package:admin_app/features/settings/screens/notification_settings_screen.dart';
import 'package:admin_app/features/settings/screens/utilities_settings_screen.dart';
import 'package:admin_app/features/settings/screens/user_management_screen.dart';
import '../../../core/services/email_service.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/google_drive_service.dart';
import '../../../core/services/local_invoice_service.dart';
import 'package:file_picker/file_picker.dart';

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          Container(
            color: AppColors.cardBg,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(icon: Icon(Icons.business, size: 18), text: 'Business Info'),
                Tab(icon: Icon(Icons.monitor_weight, size: 18), text: 'Scale / HW'),
                Tab(icon: Icon(Icons.request_quote, size: 18), text: 'Tax Rates'),
                Tab(icon: Icon(Icons.notifications_active, size: 18), text: 'Notifications'),
                Tab(icon: Icon(Icons.bolt, size: 18), text: 'Utilities'),
                Tab(icon: Icon(Icons.manage_accounts, size: 18), text: 'Users'),
                Tab(icon: Icon(Icons.email_outlined, size: 18), text: 'Email'),
                Tab(icon: Icon(Icons.auto_awesome, size: 18), text: 'AI'),
                Tab(icon: Icon(Icons.folder_shared_outlined, size: 18), text: 'Drive'),
                Tab(icon: Icon(Icons.shopping_bag, size: 18), text: 'Online Shop'),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _BusinessTab(),
                const ScaleSettingsScreen(embedded: true),
                const TaxSettingsScreen(embedded: true),
                const NotificationSettingsScreen(embedded: true),
                const UtilitiesSettingsScreen(embedded: true),
                const UserManagementScreen(embedded: true),
                const _EmailSettingsTab(),
                const _AiSettingsTab(),
                const _DriveSettingsTab(),
                _OnlineShopTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 1: BUSINESS PROFILE
// ══════════════════════════════════════════════════════════════════
class _BusinessTab extends StatefulWidget {
  @override
  State<_BusinessTab> createState() => _BusinessTabState();
}

class _BusinessTabState extends State<_BusinessTab> {
  final _repo = SettingsRepository();
  bool _isLoading = true;

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _vatController = TextEditingController();
  final _phoneController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _repo.getBusinessSettings();
    if (mounted) {
      setState(() {
        _nameController.text = data['business_name']?.toString() ?? '';
        _addressController.text = data['address']?.toString() ?? '';
        _vatController.text = data['vat_number']?.toString() ?? '';
        _phoneController.text = data['phone']?.toString() ?? '';
        _startTimeController.text = data['bcea_start_time']?.toString() ?? '07:00';
        _endTimeController.text = data['bcea_end_time']?.toString() ?? '17:00';
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await _repo.updateBusinessSettings({
        'business_name': _nameController.text,
        'address': _addressController.text,
        'vat_number': _vatController.text,
        'phone': _phoneController.text,
        'bcea_start_time': _startTimeController.text,
        'bcea_end_time': _endTimeController.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Business Settings Saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.friendlyMessage(e))));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Business Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Business Name')),
        const SizedBox(height: 8),
        TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address')),
        const SizedBox(height: 8),
        TextFormField(controller: _vatController, decoration: const InputDecoration(labelText: 'VAT Number')),
        const SizedBox(height: 8),
        TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
        const SizedBox(height: 24),
        const Text('Operational Hours (BCEA Base)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _startTimeController, decoration: const InputDecoration(labelText: 'Start Time (HH:MM)'))),
            const SizedBox(width: 16),
            Expanded(child: TextFormField(controller: _endTimeController, decoration: const InputDecoration(labelText: 'End Time (HH:MM)'))),
          ],
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(onPressed: _save, child: const Text('SAVE SETTINGS')),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 7: EMAIL / INVOICE DELIVERY
// ══════════════════════════════════════════════════════════════════
class _EmailSettingsTab extends StatefulWidget {
  const _EmailSettingsTab();

  @override
  State<_EmailSettingsTab> createState() => _EmailSettingsTabState();
}

class _EmailSettingsTabState extends State<_EmailSettingsTab> {
  final _emailService = EmailService();
  final _smtpHostController = TextEditingController();
  final _smtpPortController = TextEditingController(text: '465');
  final _smtpUsernameController = TextEditingController();
  final _smtpPasswordController = TextEditingController();
  final _smtpFromNameController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _testing = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _smtpHostController.dispose();
    _smtpPortController.dispose();
    _smtpUsernameController.dispose();
    _smtpPasswordController.dispose();
    _smtpFromNameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final creds = await _emailService.loadCredentials();
    if (mounted) {
      setState(() {
        _smtpHostController.text =
            creds['host']?.isNotEmpty == true
                ? creds['host']!
                : 'mail.struisbaai-slaghuis.co.za';
        _smtpPortController.text = creds['port'] ?? '465';
        _smtpUsernameController.text =
            creds['username']?.isNotEmpty == true
                ? creds['username']!
                : 'leon@struisbaai-slaghuis.co.za';
        _smtpPasswordController.text = creds['password'] ?? '';
        _smtpFromNameController.text =
            creds['from_name']?.isNotEmpty == true
                ? creds['from_name']!
                : 'Struisbaai Vleismark';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
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
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _test() async {
    setState(() => _testing = true);
    final result = await _emailService.testConnection();
    if (mounted) {
      setState(() => _testing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['success'] == true
              ? '✓ Connection successful'
              : 'Connection failed: ${result['error']}'),
          backgroundColor: result['success'] == true
              ? const Color(0xFF2E7D32)
              : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Email / Invoice Delivery',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          'Configure SMTP to automatically email tax invoices to account '
          'customers when a POS sale is completed. '
          'Your password is stored securely on this device only — '
          'it is never uploaded to the server.',
          style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
        ),
        const SizedBox(height: 24),
        const Text('SMTP Server',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _smtpHostController,
                decoration: const InputDecoration(
                  labelText: 'SMTP Host',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              child: TextFormField(
                controller: _smtpPortController,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _smtpUsernameController,
          decoration: const InputDecoration(
            labelText: 'Email address (username)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _smtpPasswordController,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'Password',
            border: const OutlineInputBorder(),
            isDense: true,
            suffixIcon: IconButton(
              icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  size: 18),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _smtpFromNameController,
          decoration: const InputDecoration(
            labelText: 'From name (shown to recipient)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _testing ? null : _test,
              icon: _testing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.wifi_tethering, size: 16),
              label: Text(_testing ? 'Testing…' : 'Test connection'),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, size: 16),
              label: Text(_saving ? 'Saving…' : 'Save email settings'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),
        const Text('How it works',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text(
          '1. When the POS completes a sale for an account customer, '
          'an invoice is automatically created.\n'
          '2. When you open the Bookkeeping screen, any unsent invoices '
          'are emailed automatically.\n'
          '3. A PDF tax invoice is attached — compliant with the '
          'SA VAT Act 89 of 1991.\n'
          '4. Delivery status is tracked on each invoice.',
          style: TextStyle(fontSize: 12, color: Color(0xFF444444), height: 1.6),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 8: AI SETTINGS
// ══════════════════════════════════════════════════════════════════
class _AiSettingsTab extends StatefulWidget {
  const _AiSettingsTab();

  @override
  State<_AiSettingsTab> createState() => _AiSettingsTabState();
}

class _AiSettingsTabState extends State<_AiSettingsTab> {
  final _aiService = AiService();
  final _keyController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _testing = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final key = await _aiService.loadApiKey();
    if (mounted) {
      setState(() {
        _keyController.text = key ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _aiService.saveApiKey(_keyController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI key saved'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _test() async {
    setState(() => _testing = true);
    try {
      final result = await _aiService.prompt(
        'Reply with exactly this text and nothing else: '
        'Gemini connection successful',
      );
      if (mounted) {
        setState(() => _testing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.contains('successful')
                ? '✓ Gemini connected successfully'
                : 'Unexpected response: $result'),
            backgroundColor: result.contains('successful')
                ? const Color(0xFF2E7D32)
                : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _testing = false);
        final msg = e.toString();
        final friendlyMsg = msg.contains('429')
            ? '✓ API key is valid — rate limit hit, wait 30 seconds and retry'
            : msg.contains('403') || msg.contains('API_KEY_INVALID')
                ? 'Invalid API key — check your key in AI Studio'
                : 'Connection failed: $msg';
        final color = msg.contains('429')
            ? Colors.orange
            : Colors.red;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyMsg),
            backgroundColor: color,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('AI Assistant (Gemini)',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          'Gemini powers supplier invoice scanning, smart reorder '
          'suggestions, pricing analysis, and more. '
          'Free tier: 1,500 requests/day. '
          'Get your key at aistudio.google.com. '
          'Your key is stored securely on this device only.',
          style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _keyController,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'Gemini API Key',
            border: const OutlineInputBorder(),
            isDense: true,
            hintText: 'AIza...',
            suffixIcon: IconButton(
              icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  size: 18),
              onPressed: () =>
                  setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _testing ? null : _test,
              icon: _testing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2))
                  : const Icon(Icons.bolt, size: 16),
              label: Text(_testing ? 'Testing…' : 'Test connection'),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white))
                  : const Icon(Icons.save, size: 16),
              label: Text(_saving ? 'Saving…' : 'Save key'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),
        const Text('AI features available',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text(
          '• Supplier invoice scanning — photo or PDF → auto-fills form\n'
          '• Reorder suggestions — AI analyses stock levels and history\n'
          '• Pricing analysis — suggests sell prices for target margin\n'
          '• Demand forecasting — predicts stock needs for events\n'
          '• More features coming as the app grows',
          style: TextStyle(
              fontSize: 12,
              color: Color(0xFF444444),
              height: 1.7),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 9: GOOGLE DRIVE SYNC
// ══════════════════════════════════════════════════════════════════
class _DriveSettingsTab extends StatefulWidget {
  const _DriveSettingsTab();

  @override
  State<_DriveSettingsTab> createState() => _DriveSettingsTabState();
}

class _DriveSettingsTabState extends State<_DriveSettingsTab> {
  final _driveService = GoogleDriveService();
  final _localService = LocalInvoiceService();
  final _folderIdController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _testing = false;
  bool _enabled = false;
  String _importSource = 'drive';
  String? _localFolderPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _folderIdController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final folderId = await _driveService.loadFolderId();
    final enabled = await _driveService.isEnabled();
    final importSource = await _driveService.getImportSource();
    final localPath = await _localService.getFolderPath();
    if (mounted) {
      setState(() {
        _folderIdController.text = folderId ?? '';
        _enabled = enabled;
        _importSource = importSource;
        _localFolderPath = localPath;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _driveService.saveFolderId(
          _folderIdController.text.trim());
      await _driveService.setEnabled(_enabled);
      await _driveService.setImportSource(_importSource);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Drive settings saved'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _browseFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null && path.isNotEmpty) {
      await _localService.setFolderPath(path);
      setState(() => _localFolderPath = path);
    }
  }

  Future<void> _clearProcessedFiles() async {
    await _localService.clearProcessed();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processed file list cleared'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    }
  }

  Future<void> _test() async {
    setState(() => _testing = true);
    await _driveService.saveFolderId(
        _folderIdController.text.trim());
    final result = await _driveService.testConnection();
    if (mounted) {
      setState(() => _testing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['success'] == true
              ? '✓ ${result['message']}'
              : 'Failed: ${result['error']}'),
          backgroundColor: result['success'] == true
              ? const Color(0xFF2E7D32)
              : Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // ── Invoice Import Source Toggle ─────────────────────────────
        const Text('Invoice Import Source',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Choose where to scan for supplier invoices.',
          style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
        ),
        const SizedBox(height: 16),
        RadioListTile<String>(
          title: const Text('Google Drive'),
          subtitle: const Text('Scan a Google Drive folder automatically'),
          value: 'drive',
          groupValue: _importSource,
          onChanged: (v) {
            if (v != null) {
              setState(() => _importSource = v);
              _driveService.setImportSource(v);
            }
          },
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<String>(
          title: const Text('Local Folder on this PC'),
          subtitle: const Text('Scan a folder on this computer'),
          value: 'local',
          groupValue: _importSource,
          onChanged: (v) {
            if (v != null) {
              setState(() => _importSource = v);
              _driveService.setImportSource(v);
            }
          },
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),

        // ── Drive Settings (shown only when drive selected) ─────────────
        if (_importSource == 'drive') ...[
          const Text('Google Drive Sync',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'Drop supplier invoice PDFs or photos into a shared '
            'Google Drive folder. The app will scan the folder '
            'automatically, extract invoice data using Gemini AI, '
            'and create pending supplier invoices for review.',
            style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Enable Drive sync'),
            subtitle: const Text(
                'Scan folder for new invoices when Bookkeeping opens'),
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _folderIdController,
            decoration: const InputDecoration(
              labelText: 'Google Drive Folder ID',
              border: OutlineInputBorder(),
              isDense: true,
              hintText: '1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs',
              helperText:
                  'Copy from Drive URL: drive.google.com/drive/folders/FOLDER_ID',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _testing ? null : _test,
                icon: _testing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2))
                    : const Icon(Icons.wifi_tethering, size: 16),
                label: Text(_testing ? 'Testing…' : 'Test connection'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white))
                    : const Icon(Icons.save, size: 16),
                label: Text(_saving ? 'Saving…' : 'Save settings'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          const Text('Setup instructions',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text(
            '1. Create a folder in Google Drive named "Supplier Invoices"\n'
            '2. Share the folder with the service account email '
            '(found in assets/secrets/google_service_account.json → client_email)\n'
            '3. Give the service account Viewer access\n'
            '4. Copy the folder ID from the Drive URL and paste above\n'
            '5. Enable sync and save\n'
            '6. Drop PDF or image invoices into the folder — '
            'they will be scanned next time Bookkeeping opens',
            style: TextStyle(
                fontSize: 12,
                color: Color(0xFF444444),
                height: 1.7),
          ),
        ],

        // ── Local Folder Settings (shown only when local selected) ───────
        if (_importSource == 'local') ...[
          const Text('Local Folder Settings',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'Scan a local folder on this computer for supplier invoice PDFs.',
            style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 24),
          if (_localFolderPath != null && _localFolderPath!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _localFolderPath!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'No folder selected',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton.icon(
            onPressed: _browseFolder,
            icon: const Icon(Icons.folder_open, size: 18),
            label: const Text('Browse...'),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _clearProcessedFiles,
            icon: const Icon(Icons.clear_all, size: 16),
            label: const Text('Clear processed files list'),
          ),
          const SizedBox(height: 8),
          const Text(
            'This will allow previously processed invoices to be scanned again.',
            style: TextStyle(fontSize: 11, color: Color(0xFF666666)),
          ),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 10: ONLINE SHOP
// ══════════════════════════════════════════════════════════════════
class _OnlineShopTab extends StatefulWidget {
  @override
  State<_OnlineShopTab> createState() => _OnlineShopTabState();
}

class _OnlineShopTabState extends State<_OnlineShopTab> {
  final _repo = SettingsRepository();
  bool _isLoading = true;
  bool _onlineShopEnabled = false;
  bool _deliveryEnabled = false;
  final _collectionTimeController = TextEditingController();
  final _deliveryTimeController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _deliveryFeeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _repo.getBusinessSettings();
      if (mounted) {
        setState(() {
          final onlineShopValue = settings['online_shop_enabled'];
          _onlineShopEnabled = onlineShopValue == true || onlineShopValue == 'true';
          final deliveryValue = settings['delivery_enabled'];
          _deliveryEnabled = deliveryValue == true || deliveryValue == 'true';
          _collectionTimeController.text = settings['collection_time'] ?? 'Same day (before 2pm)';
          _deliveryTimeController.text = settings['delivery_time'] ?? 'Next day delivery';
          _minOrderController.text = (settings['min_order_amount'] ?? 0).toString();
          _deliveryFeeController.text = (settings['delivery_fee'] ?? 0).toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load online shop settings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _repo.updateBusinessSettings({
        'online_shop_enabled': _onlineShopEnabled,
        'delivery_enabled': _deliveryEnabled,
        'collection_time': _collectionTimeController.text.trim(),
        'delivery_time': _deliveryTimeController.text.trim(),
        'min_order_amount': double.tryParse(_minOrderController.text) ?? 0,
        'delivery_fee': double.tryParse(_deliveryFeeController.text) ?? 0,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Online Shop settings saved'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enable/Disable Online Shop
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Online Shop Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Enable Online Shop'),
                    subtitle: const Text('Allow customers to order through the loyalty app'),
                    value: _onlineShopEnabled,
                    onChanged: (value) => setState(() => _onlineShopEnabled = value),
                    activeThumbColor: AppColors.success,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Collection Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Collection Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _collectionTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Collection Time Description',
                      hintText: 'e.g. Same day (before 2pm)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _minOrderController,
                    decoration: const InputDecoration(
                      labelText: 'Minimum Order Amount (R)',
                      hintText: '0',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Delivery Settings (Hidden until enabled by developer)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delivery Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '⚠️ Delivery is disabled until enabled by a developer',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _deliveryTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Time Description',
                      hintText: 'e.g. Next day delivery',
                      border: OutlineInputBorder(),
                    ),
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _deliveryFeeController,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Fee (R)',
                      hintText: '0',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: false,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _collectionTimeController.dispose();
    _deliveryTimeController.dispose();
    _minOrderController.dispose();
    _deliveryFeeController.dispose();
    super.dispose();
  }
}

