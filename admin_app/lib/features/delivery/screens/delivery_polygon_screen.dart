import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/responsive/responsive_breakpoints.dart';
import '../models/delivery_zone_polygon.dart';
import '../services/delivery_zone_polygon_service.dart';

/// Six preset colours for zone polygon rendering.
const _kPresetColors = [
  '#E53935', // Red
  '#1E88E5', // Blue
  '#43A047', // Green
  '#FB8C00', // Orange
  '#8E24AA', // Purple
  '#00ACC1', // Cyan
];

Color _hexToColor(String hex) {
  try {
    return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
  } catch (_) {
    return Colors.red;
  }
}

class DeliveryPolygonScreen extends StatefulWidget {
  const DeliveryPolygonScreen({super.key});

  @override
  State<DeliveryPolygonScreen> createState() => _DeliveryPolygonScreenState();
}

class _DeliveryPolygonScreenState extends State<DeliveryPolygonScreen> {
  final _service = DeliveryZonePolygonService();
  final _mapController = MapController();

  List<DeliveryZonePolygon> _zones = [];
  bool _isLoading = true;
  String? _error;

  DeliveryZonePolygon? _selectedZone;
  bool _drawingMode = false;
  List<LatLng> _drawingPoints = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // ── Data loading ────────────────────────────────────────────────────────────

  Future<void> _loadZones() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final zones = await _service.fetchZones();
      if (!mounted) return;
      setState(() {
        _zones = zones;
        _isLoading = false;
        // Keep selected zone in sync after reload.
        if (_selectedZone != null) {
          final updated = zones.where((z) => z.id == _selectedZone!.id);
          _selectedZone = updated.isNotEmpty ? updated.first : null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Map interaction ─────────────────────────────────────────────────────────

  void _onMapTap(TapPosition _, LatLng point) {
    if (!_drawingMode) return;
    setState(() => _drawingPoints.add(point));
  }

  // ── Zone selection ──────────────────────────────────────────────────────────

  void _selectZone(DeliveryZonePolygon zone) {
    setState(() {
      _selectedZone = zone;
      _drawingMode = false;
      // Pre-load existing polygon so admin can refine it.
      _drawingPoints = List.from(zone.polygon);
    });
  }

  void _enterDrawingMode() => setState(() => _drawingMode = true);

  void _undoPoint() {
    if (_drawingPoints.isEmpty) return;
    setState(() => _drawingPoints.removeLast());
  }

  void _clearDrawing() => setState(() => _drawingPoints.clear());

  // ── Save polygon ────────────────────────────────────────────────────────────

  Future<void> _savePolygon() async {
    if (_selectedZone == null || _drawingPoints.length < 3) return;
    setState(() => _isSaving = true);
    try {
      await _service.updatePolygon(_selectedZone!.id, _drawingPoints);
      await _loadZones();
      if (!mounted) return;
      setState(() {
        _drawingMode = false;
        _isSaving = false;
      });
      _showSnack('Polygon saved successfully', Colors.green);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack('Failed to save: $e', AppColors.error);
    }
  }

  // ── Zone management ─────────────────────────────────────────────────────────

  Future<void> _toggleActive(DeliveryZonePolygon zone) async {
    try {
      await _service.toggleActive(zone.id, isActive: !zone.isActive);
      await _loadZones();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to update: $e', AppColors.error);
    }
  }

  Future<void> _deleteZone(DeliveryZonePolygon zone) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Zone'),
        content: Text(
            'Delete "${zone.name}"? This cannot be undone.\n\nCustomers in this area will no longer be validated against this polygon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteZone(zone.id);
      if (_selectedZone?.id == zone.id) {
        setState(() {
          _selectedZone = null;
          _drawingPoints.clear();
          _drawingMode = false;
        });
      }
      await _loadZones();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to delete: $e', AppColors.error);
    }
  }

  void _showNewZoneDialog() {
    final nameCtrl = TextEditingController();
    final feeCtrl = TextEditingController(text: '110.00');
    final minOrderCtrl = TextEditingController(text: '500.00');
    final dayCtrl = TextEditingController(text: 'Monthly delivery');
    final descCtrl = TextEditingController();
    String selectedColor = _kPresetColors.first;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('New Delivery Zone'),
          content: SizedBox(
            width: ResponsiveBreakpoints.dialogContentMaxWidth(ctx, desktopMax: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Zone Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: feeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Delivery Fee (R)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: minOrderCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Minimum Order (R)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: dayCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Day',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'e.g. Durbanville, Brackenfell, Cape Gate area',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Zone Colour',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _kPresetColors.map((hex) {
                      final color = _hexToColor(hex);
                      final isSelected = hex == selectedColor;
                      return GestureDetector(
                        onTap: () => setDialog(() => selectedColor = hex),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.black87
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      setDialog(() => isSaving = true);
                      try {
                        final zone = DeliveryZonePolygon(
                          id: '',
                          name: nameCtrl.text.trim(),
                          polygon: const [],
                          deliveryFee:
                              double.tryParse(feeCtrl.text) ?? 110.0,
                          minimumOrder:
                              double.tryParse(minOrderCtrl.text) ?? 500.0,
                          deliveryDay: dayCtrl.text.trim().isEmpty
                              ? null
                              : dayCtrl.text.trim(),
                          isActive: true,
                          color: selectedColor,
                          description: descCtrl.text.trim().isEmpty
                              ? null
                              : descCtrl.text.trim(),
                        );
                        await _service.saveZone(zone);
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _loadZones();
                      } catch (e) {
                        setDialog(() => isSaving = false);
                        if (ctx.mounted) {
                          _showSnack(
                              'Failed to create zone: $e', AppColors.error);
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Create Zone'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Map layer builders ──────────────────────────────────────────────────────

  List<Polygon> _buildZonePolygons() {
    return _zones.where((z) => z.hasPolygon).map((z) {
      final color = _hexToColor(z.color);
      final isSelected = _selectedZone?.id == z.id;
      return Polygon(
        points: z.polygon,
        color: color.withAlpha(isSelected ? 70 : 35),
        borderColor: color,
        borderStrokeWidth: isSelected ? 3.0 : 2.0,
      );
    }).toList();
  }

  /// In-progress drawing polygon lines.
  List<Polyline> _buildDrawingPolylines() {
    if (_drawingPoints.length < 2) return [];
    final lines = <Polyline>[
      Polyline(
        points: _drawingPoints,
        color: Colors.blue,
        strokeWidth: 2.5,
      ),
    ];
    // Closing line back to origin (shown faintly when 3+ points).
    if (_drawingPoints.length >= 3) {
      lines.add(Polyline(
        points: [_drawingPoints.last, _drawingPoints.first],
        color: Colors.blue.withAlpha(100),
        strokeWidth: 1.5,
      ));
    }
    return lines;
  }

  /// Numbered vertex markers — tap a marker to remove that point.
  List<Marker> _buildDrawingMarkers() {
    return _drawingPoints.asMap().entries.map((e) {
      final index = e.key;
      final point = e.value;
      final isFirst = index == 0;
      return Marker(
        point: point,
        width: 26,
        height: 26,
        child: GestureDetector(
          onTap: () => setState(() => _drawingPoints.removeAt(index)),
          child: Tooltip(
            message: isFirst
                ? 'First point — tap to remove'
                : 'Point ${index + 1} — tap to remove',
            child: Container(
              decoration: BoxDecoration(
                color: isFirst ? Colors.orange : Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4)
                ],
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _loadZones, child: const Text('Retry')),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            ResponsiveBreakpoints.isPhoneLayout(context);
        if (!stacked) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSidePanel(fixedWidth: 280),
              const VerticalDivider(width: 1, color: AppColors.border),
              Expanded(child: _buildMapArea()),
            ],
          );
        }
        final mapHeight = math
            .min(
              constraints.maxHeight * 0.4,
              320.0,
            )
            .clamp(220.0, 360.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: mapHeight,
              width: double.infinity,
              child: ClipRect(child: _buildMapArea()),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: _buildSidePanel(fullBleedWidth: true),
            ),
          ],
        );
      },
    );
  }

  // ── Side panel ──────────────────────────────────────────────────────────────

  Widget _buildSidePanel({
    double? fixedWidth,
    bool fullBleedWidth = false,
  }) {
    return Container(
      width: fullBleedWidth ? double.infinity : fixedWidth ?? 280,
      color: AppColors.cardBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Zones',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_zones.length} zone${_zones.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showNewZoneDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Zone'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Zone list
          Expanded(
            child: _zones.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_outlined,
                            size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        Text('No zones yet',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('Use "New Zone" to create one',
                            style: TextStyle(
                                color: Colors.grey[300], fontSize: 11)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _zones.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (_, i) {
                      final zone = _zones[i];
                      return _ZoneListTile(
                        zone: zone,
                        isSelected: _selectedZone?.id == zone.id,
                        onTap: () => _selectZone(zone),
                        onToggleActive: () => _toggleActive(zone),
                        onDelete: () => _deleteZone(zone),
                      );
                    },
                  ),
          ),
          // OSM attribution required by terms of use
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: AppColors.border,
            child: const Text(
              '© OpenStreetMap contributors',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ── Map area ────────────────────────────────────────────────────────────────

  Widget _buildMapArea() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(-33.9249, 18.4241),
            initialZoom: 11,
            onTap: _drawingMode ? _onMapTap : null,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.butcheryos.admin',
            ),
            PolygonLayer(polygons: _buildZonePolygons()),
            if (_drawingPoints.isNotEmpty) ...[
              PolylineLayer(polylines: _buildDrawingPolylines()),
              MarkerLayer(markers: _buildDrawingMarkers()),
            ],
          ],
        ),

        // Drawing mode hint banner (top-left)
        if (_drawingMode)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6)
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Click map to add polygon points',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

        // Drawing controls card (top-right, shown when zone selected)
        if (_selectedZone != null)
          Positioned(
            top: 12,
            right: 12,
            child: _buildDrawingControls(),
          ),
      ],
    );
  }

  // ── Drawing controls card ───────────────────────────────────────────────────

  Widget _buildDrawingControls() {
    final canSave = _drawingPoints.length >= 3;

    return Container(
      padding: const EdgeInsets.all(14),
      constraints: const BoxConstraints(maxWidth: 220),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zone name row
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _hexToColor(_selectedZone!.color),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _selectedZone!.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (!_drawingMode) ...[
            ElevatedButton.icon(
              onPressed: _enterDrawingMode,
              icon: const Icon(Icons.edit_location_alt, size: 15),
              label: Text(_selectedZone!.hasPolygon
                  ? 'Edit Polygon'
                  : 'Draw Polygon'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
            if (_selectedZone!.hasPolygon)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${_selectedZone!.polygon.length} points saved',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
          ] else ...[
            // Point counter badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: canSave
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: canSave
                      ? Colors.green.shade300
                      : Colors.orange.shade300,
                ),
              ),
              child: Text(
                _drawingPoints.isEmpty
                    ? 'Click map to start'
                    : _drawingPoints.length < 3
                        ? '${_drawingPoints.length} point${_drawingPoints.length == 1 ? '' : 's'} — need 3+'
                        : '${_drawingPoints.length} points ✓',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: canSave
                      ? Colors.green.shade800
                      : Colors.orange.shade800,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),

            // Undo / Clear row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _drawingPoints.isEmpty ? null : _undoPoint,
                    icon: const Icon(Icons.undo, size: 14),
                    label: const Text('Undo',
                        style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _drawingPoints.isEmpty ? null : _clearDrawing,
                    icon: const Icon(Icons.clear, size: 14),
                    label: const Text('Clear',
                        style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Cancel / Save row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _drawingMode = false;
                      _drawingPoints = List.from(_selectedZone!.polygon);
                    }),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        canSave && !_isSaving ? _savePolygon : null,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save, size: 14),
                    label: const Text('Save',
                        style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Zone list tile ─────────────────────────────────────────────────────────────

class _ZoneListTile extends StatelessWidget {
  final DeliveryZonePolygon zone;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const _ZoneListTile({
    required this.zone,
    required this.isSelected,
    required this.onTap,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: isSelected
            ? AppColors.primary.withAlpha(15)
            : Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _hexToColor(zone.color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    zone.name,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Active/inactive badge (tappable)
                GestureDetector(
                  onTap: onToggleActive,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: zone.isActive
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: zone.isActive
                            ? Colors.green.shade300
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      zone.isActive ? 'Active' : 'Off',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: zone.isActive
                            ? Colors.green.shade700
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Delete button
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline,
                        size: 15, color: Colors.grey.shade400),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  zone.hasPolygon
                      ? Icons.check_circle_outline
                      : Icons.radio_button_unchecked,
                  size: 12,
                  color: zone.hasPolygon
                      ? Colors.green.shade600
                      : Colors.orange.shade400,
                ),
                const SizedBox(width: 4),
                Text(
                  zone.hasPolygon
                      ? '${zone.polygon.length} points'
                      : 'No polygon drawn',
                  style: TextStyle(
                    fontSize: 11,
                    color: zone.hasPolygon
                        ? Colors.green.shade600
                        : Colors.orange.shade400,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'R${zone.deliveryFee.toStringAsFixed(0)} delivery',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
            if (zone.description != null &&
                zone.description!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                zone.description!,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
