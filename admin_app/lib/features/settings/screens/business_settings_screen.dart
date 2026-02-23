import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/features/settings/services/settings_repository.dart';
import 'package:admin_app/features/settings/screens/tax_settings_screen.dart';
import 'package:admin_app/features/settings/screens/scale_settings_screen.dart';
import 'package:admin_app/features/settings/screens/notification_settings_screen.dart';

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
                const ScaleSettingsScreen(embedded: true),
                const TaxSettingsScreen(embedded: true),
                const NotificationSettingsScreen(embedded: true),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
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

