import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import '../services/delivery_zone_service.dart';

class DeliveryZoneScreen extends StatefulWidget {
  const DeliveryZoneScreen({super.key});

  @override
  State<DeliveryZoneScreen> createState() => _DeliveryZoneScreenState();
}

class _DeliveryZoneScreenState extends State<DeliveryZoneScreen> {
  final DeliveryZoneService _service = DeliveryZoneService();

  bool _isLoading = true;
  String? _error;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _zones = [];
  String? _selectedZoneId;
  List<Map<String, dynamic>> _streets = [];

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  Future<void> _loadZones() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final zones = await _service.fetchZones();
      String? selected = _selectedZoneId;
      if (selected == null ||
          zones.every((z) => (z['id']?.toString() ?? '') != selected)) {
        selected = zones.isEmpty ? null : zones.first['id']?.toString();
      }

      List<Map<String, dynamic>> streets = [];
      if (selected != null && selected.isNotEmpty) {
        streets = await _service.fetchStreets(selected);
      }

      if (!mounted) return;
      setState(() {
        _zones = zones;
        _selectedZoneId = selected;
        _streets = streets;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectZone(String zoneId) async {
    setState(() => _selectedZoneId = zoneId);
    await _loadStreets(zoneId);
  }

  Future<void> _loadStreets(String zoneId) async {
    try {
      final streets = await _service.fetchStreets(zoneId);
      if (!mounted) return;
      setState(() => _streets = streets);
    } catch (e) {
      _snack('Failed to load streets: $e', isError: true);
    }
  }

  Future<void> _showAddZoneDialog() async {
    final suburbController = TextEditingController();
    final sortController = TextEditingController(text: '${_zones.length + 1}');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Delivery Zone'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: suburbController,
                  decoration: const InputDecoration(
                    labelText: 'Suburb name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sortController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sort order',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final suburb = suburbController.text.trim();
                final sortOrder = int.tryParse(sortController.text.trim());
                if (suburb.isEmpty || sortOrder == null) {
                  _snack('Suburb and valid sort order are required', isError: true);
                  return;
                }
                setState(() => _isSubmitting = true);
                try {
                  await _service.createZone(
                    suburbName: suburb,
                    sortOrder: sortOrder,
                  );
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  _snack('Zone created');
                  await _loadZones();
                } catch (e) {
                  _snack('Failed to create zone: $e', isError: true);
                } finally {
                  if (mounted) setState(() => _isSubmitting = false);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddStreetDialog() async {
    final zoneId = _selectedZoneId;
    if (zoneId == null || zoneId.isEmpty) {
      _snack('Select a zone first', isError: true);
      return;
    }

    final streetController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Street'),
          content: TextField(
            controller: streetController,
            decoration: const InputDecoration(
              labelText: 'Street name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final street = streetController.text.trim();
                if (street.isEmpty) {
                  _snack('Street name is required', isError: true);
                  return;
                }
                setState(() => _isSubmitting = true);
                try {
                  await _service.createStreet(zoneId: zoneId, streetName: street);
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  _snack('Street created');
                  await _loadStreets(zoneId);
                } catch (e) {
                  _snack('Failed to create street: $e', isError: true);
                } finally {
                  if (mounted) setState(() => _isSubmitting = false);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleZoneActive(Map<String, dynamic> zone) async {
    final id = zone['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final active = zone['is_active'] == true;
    setState(() => _isSubmitting = true);
    try {
      await _service.updateZone(zoneId: id, isActive: !active);
      await _loadZones();
    } catch (e) {
      _snack('Failed to update zone: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _toggleStreetActive(Map<String, dynamic> street) async {
    final id = street['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final active = street['is_active'] == true;
    setState(() => _isSubmitting = true);
    try {
      await _service.updateStreet(streetId: id, isActive: !active);
      final zoneId = _selectedZoneId;
      if (zoneId != null) await _loadStreets(zoneId);
    } catch (e) {
      _snack('Failed to update street: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snack(String message, {bool isError = false}) {
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
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: _isLoading
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
              : Row(
                  children: [
                    Expanded(
                      child: _ZonesPane(
                        zones: _zones,
                        selectedZoneId: _selectedZoneId,
                        isSubmitting: _isSubmitting,
                        onRefresh: _loadZones,
                        onAddZone: _showAddZoneDialog,
                        onSelectZone: _selectZone,
                        onToggleZoneActive: _toggleZoneActive,
                      ),
                    ),
                    const VerticalDivider(width: 1, color: AppColors.border),
                    Expanded(
                      child: _StreetsPane(
                        selectedZoneId: _selectedZoneId,
                        streets: _streets,
                        isSubmitting: _isSubmitting,
                        onAddStreet: _showAddStreetDialog,
                        onToggleStreetActive: _toggleStreetActive,
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _ZonesPane extends StatelessWidget {
  final List<Map<String, dynamic>> zones;
  final String? selectedZoneId;
  final bool isSubmitting;
  final Future<void> Function() onRefresh;
  final VoidCallback onAddZone;
  final ValueChanged<String> onSelectZone;
  final Future<void> Function(Map<String, dynamic>) onToggleZoneActive;

  const _ZonesPane({
    required this.zones,
    required this.selectedZoneId,
    required this.isSubmitting,
    required this.onRefresh,
    required this.onAddZone,
    required this.onSelectZone,
    required this.onToggleZoneActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PaneHeader(
          title: 'Delivery Zones',
          onRefresh: onRefresh,
          action: ElevatedButton.icon(
            onPressed: isSubmitting ? null : onAddZone,
            icon: const Icon(Icons.add),
            label: const Text('Add Zone'),
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: zones.isEmpty
              ? const Center(child: Text('No zones configured'))
              : ListView.builder(
                  itemCount: zones.length,
                  itemBuilder: (context, index) {
                    final zone = zones[index];
                    final id = zone['id']?.toString() ?? '';
                    final isSelected = id == selectedZoneId;
                    final isActive = zone['is_active'] == true;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
                      title: Text(zone['suburb_name']?.toString() ?? 'Unnamed zone'),
                      subtitle: Text('Sort: ${zone['sort_order'] ?? '-'}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: isActive,
                            onChanged:
                                isSubmitting ? null : (_) => onToggleZoneActive(zone),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isActive ? Icons.check_circle : Icons.cancel,
                            color: isActive ? AppColors.success : AppColors.error,
                            size: 18,
                          ),
                        ],
                      ),
                      onTap: id.isEmpty ? null : () => onSelectZone(id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StreetsPane extends StatelessWidget {
  final String? selectedZoneId;
  final List<Map<String, dynamic>> streets;
  final bool isSubmitting;
  final VoidCallback onAddStreet;
  final Future<void> Function(Map<String, dynamic>) onToggleStreetActive;

  const _StreetsPane({
    required this.selectedZoneId,
    required this.streets,
    required this.isSubmitting,
    required this.onAddStreet,
    required this.onToggleStreetActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PaneHeader(
          title: 'Delivery Streets',
          onRefresh: null,
          action: ElevatedButton.icon(
            onPressed:
                isSubmitting || selectedZoneId == null ? null : onAddStreet,
            icon: const Icon(Icons.add_road),
            label: const Text('Add Street'),
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: selectedZoneId == null
              ? const Center(child: Text('Select a zone to manage streets'))
              : streets.isEmpty
                  ? const Center(child: Text('No streets configured'))
                  : ListView.builder(
                      itemCount: streets.length,
                      itemBuilder: (context, index) {
                        final street = streets[index];
                        final isActive = street['is_active'] == true;
                        return ListTile(
                          title: Text(
                            street['street_name']?.toString() ?? 'Unnamed street',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: isActive,
                                onChanged: isSubmitting
                                    ? null
                                    : (_) => onToggleStreetActive(street),
                              ),
                              Icon(
                                isActive ? Icons.check_circle : Icons.cancel,
                                color: isActive ? AppColors.success : AppColors.error,
                                size: 18,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _PaneHeader extends StatelessWidget {
  final String title;
  final Future<void> Function()? onRefresh;
  final Widget action;

  const _PaneHeader({
    required this.title,
    required this.onRefresh,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardBg,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (onRefresh != null)
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
          action,
        ],
      ),
    );
  }
}
