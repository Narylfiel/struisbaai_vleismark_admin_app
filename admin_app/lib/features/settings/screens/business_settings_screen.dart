import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/features/settings/services/settings_repository.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _BusinessTab(),
                _ScaleTab(),
                _TaxTab(),
                _NotificationTab(),
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
        _nameController.text = data['business_name'] ?? '';
        _addressController.text = data['address'] ?? '';
        _vatController.text = data['vat_number'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _startTimeController.text = data['bcea_start_time'] ?? '07:00';
        _endTimeController.text = data['bcea_end_time'] ?? '17:00';
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
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
      setState(() => _isLoading = false);
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
// TAB 2: SCALE / HW INTEGRATION
// ══════════════════════════════════════════════════════════════════
class _ScaleTab extends StatefulWidget {
  @override
  State<_ScaleTab> createState() => _ScaleTabState();
}

class _ScaleTabState extends State<_ScaleTab> {
  final _repo = SettingsRepository();
  bool _isLoading = true;

  String _primaryMode = 'Price-embedded';
  final _pluController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _repo.getScaleConfig();
    if (mounted) {
      setState(() {
        _primaryMode = data['primary_mode'] ?? 'Price-embedded';
        _pluController.text = data['plu_digits']?.toString() ?? '4';
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    await _repo.updateScaleConfig({
      'primary_mode': _primaryMode,
      'plu_digits': int.tryParse(_pluController.text) ?? 4,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scale HW Config Saved')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Ishida Scale Integration (Network)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Primary Barcode Target Mode'),
          value: _primaryMode,
          items: const [
            DropdownMenuItem(value: 'Price-embedded', child: Text('Price-embedded (21 Prefix)')),
            DropdownMenuItem(value: 'Weight-embedded', child: Text('Weight-embedded (20 Prefix)')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _primaryMode = v);
          },
        ),
        const SizedBox(height: 8),
        TextFormField(controller: _pluController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'PLU Digits (Requires 4 or 5)')),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(onPressed: _save, child: const Text('SAVE SCALE HW CONFIG')),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 3: TAX RULES
// ══════════════════════════════════════════════════════════════════
class _TaxTab extends StatefulWidget {
  @override
  State<_TaxTab> createState() => _TaxTabState();
}

class _TaxTabState extends State<_TaxTab> {
  final _repo = SettingsRepository();
  bool _isLoading = true;
  List<Map<String, dynamic>> _taxes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _repo.getTaxRules();
    if (mounted) {
      setState(() {
        _taxes = data;
        _isLoading = false;
      });
    }
  }

  void _addTaxDialog() {
    final nameCtrl = TextEditingController();
    final percCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Tax Rule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name (e.g., Standard)')),
            TextFormField(controller: percCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Percentage (e.g., 15)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final perc = double.tryParse(percCtrl.text);
              if (nameCtrl.text.isNotEmpty && perc != null) {
                await _repo.createTaxRule(nameCtrl.text, perc);
                if (mounted) Navigator.pop(context);
                _load();
              }
            },
            child: const Text('SAVE')
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Global Tax Mappings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        if (_taxes.isEmpty)
          const Text('No tax settings configured in Supabase.')
        else
          ..._taxes.map((t) => Column(
                children: [
                  ListTile(
                    title: Text('${t['name'] ?? 'Unknown'} ( ${t['percentage'] ?? '0'}% )'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.error),
                      onPressed: () async {
                        await _repo.deleteTaxRule(t['id']?.toString() ?? '');
                        _load();
                      },
                    ),
                  ),
                  const Divider(),
                ],
              )),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(onPressed: _addTaxDialog, icon: const Icon(Icons.add), label: const Text('ADD TAX RATE')),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 4: NOTIFICATIONS
// ══════════════════════════════════════════════════════════════════
class _NotificationTab extends StatefulWidget {
  @override
  State<_NotificationTab> createState() => _NotificationTabState();
}

class _NotificationTabState extends State<_NotificationTab> {
  final _repo = SettingsRepository();
  bool _isLoading = true;
  List<Map<String, dynamic>> _configs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _repo.getSystemConfig();
    if (mounted) {
      setState(() {
        _configs = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggle(String id, bool val) async {
    await _repo.toggleNotification(id, val);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_configs.isEmpty) {
      return const Center(child: Text("No global notification / environment keys defined in DB."));
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: _configs.map((c) => Column(
        children: [
          ListTile(
            title: Text(c['key'] ?? 'Unknown Key'),
            subtitle: Text(c['description'] ?? 'System configuration environment flag.'),
            trailing: Switch(
              value: c['is_active'] == true,
              activeColor: AppColors.primary,
              onChanged: (val) => _toggle(c['id']?.toString() ?? '', val),
            ),
          ),
          const Divider(),
        ],
      )).toList(),
    );
  }
}
