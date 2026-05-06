import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/auth_service.dart';
import '../services/delivery_settings_service.dart';

class DeliverySettingsScreen extends StatefulWidget {
  const DeliverySettingsScreen({super.key});

  @override
  State<DeliverySettingsScreen> createState() => _DeliverySettingsScreenState();
}

class _DeliverySettingsScreenState extends State<DeliverySettingsScreen> {
  final DeliverySettingsService _service = DeliverySettingsService();
  final TextEditingController _deliveryFeeController = TextEditingController();
  final TextEditingController _minOrderValueController =
      TextEditingController();
  final TextEditingController _autoCancelDaysController =
      TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String? _settingsId;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _deliveryFeeController.dispose();
    _minOrderValueController.dispose();
    _autoCancelDaysController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final settings = await _service.fetchSettings();
      if (!mounted) return;

      _settingsId = settings['id']?.toString();
      _isActive = (settings['is_active'] as bool?) ?? true;
      _deliveryFeeController.text =
          ((settings['delivery_fee'] as num?)?.toDouble() ?? 0.0)
              .toStringAsFixed(2);
      _minOrderValueController.text =
          ((settings['min_order_value'] as num?)?.toDouble() ?? 0.0)
              .toStringAsFixed(2);
      _autoCancelDaysController.text =
          ((settings['auto_cancel_days'] as num?)?.toInt() ?? 1).toString();

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final id = _settingsId;
    if (id == null || id.isEmpty) {
      _showSnack('No delivery settings row found', isError: true);
      return;
    }

    final deliveryFee = double.tryParse(_deliveryFeeController.text.trim());
    final minOrderValue = double.tryParse(_minOrderValueController.text.trim());
    final autoCancelDays = int.tryParse(_autoCancelDaysController.text.trim());

    if (deliveryFee == null ||
        minOrderValue == null ||
        autoCancelDays == null) {
      _showSnack('Please enter valid numeric values', isError: true);
      return;
    }
    if (deliveryFee < 0 || minOrderValue < 0 || autoCancelDays < 1) {
      _showSnack(
        'Delivery fee and minimum value must be >= 0, auto-cancel days must be >= 1',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _service.updateSettings(
        id: id,
        deliveryFee: deliveryFee,
        minOrderValue: minOrderValue,
        autoCancelDays: autoCancelDays,
        isActive: _isActive,
        updatedBy: AuthService().currentStaffId,
      );
      _showSnack('Delivery settings saved');
      await _loadSettings();
    } catch (e) {
      _showSnack('Failed to save settings: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          Container(
            color: AppColors.cardBg,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Delivery Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadSettings,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _error != null
                    ? Center(
                        child: Text(
                          'Error: $_error',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      )
                    : Align(
                        alignment: Alignment.topCenter,
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(
                            isMobile ? 12 : 24,
                            isMobile ? 12 : 24,
                            isMobile ? 12 : 24,
                            24 + MediaQuery.viewInsetsOf(context).bottom,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Global Delivery Configuration',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: _deliveryFeeController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      decoration: const InputDecoration(
                                        labelText: 'Delivery fee (R)',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _minOrderValueController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      decoration: const InputDecoration(
                                        labelText: 'Minimum order value (R)',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _autoCancelDaysController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Auto-cancel days',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SwitchListTile(
                                      value: _isActive,
                                      contentPadding: EdgeInsets.zero,
                                      title: const Text('Delivery enabled'),
                                      subtitle: const Text(
                                        'Disable to stop new delivery orders system-wide',
                                      ),
                                      onChanged: _isSaving
                                          ? null
                                          : (value) =>
                                              setState(() => _isActive = value),
                                    ),
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: isMobile
                                          ? Alignment.centerLeft
                                          : Alignment.centerRight,
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            _isSaving ? null : _saveSettings,
                                        icon: _isSaving
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Icon(Icons.save),
                                        label: Text(
                                            _isSaving ? 'Saving...' : 'Save'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
