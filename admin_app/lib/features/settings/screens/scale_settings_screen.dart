import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/features/settings/services/scale_sync_service.dart';

class ScaleSettingsScreen extends StatefulWidget {
  const ScaleSettingsScreen({super.key, this.embedded = false});
  final bool embedded;
  @override
  State<ScaleSettingsScreen> createState() => _ScaleSettingsScreenState();
}

class _ScaleSettingsScreenState extends State<ScaleSettingsScreen> {
  final _client = SupabaseService.client;
  final _pathController = TextEditingController();
  final _ipController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _syncing = false;
  DateTime? _lastSync;
  int _scaleItemCount = 0;
  int _missingShelfLife = 0;
  String _syncStatus = '';
  bool _syncSuccess = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pathController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Load settings
      final rows = await _client
          .from('business_settings')
          .select('scale_output_path, scale_ip_address, scale_last_sync')
          .limit(1)
          .single();

      // Load scale item stats
      final items = await _client
          .from('inventory_items')
          .select('scale_shelf_life')
          .eq('scale_item', true)
          .eq('is_active', true);

      final itemList = items as List;
      final missing = itemList
          .where((i) => i['scale_shelf_life'] == null)
          .length;

      if (mounted) {
        setState(() {
          _pathController.text =
              rows['scale_output_path']?.toString() ?? 'C:/Slp';
          _ipController.text =
              rows['scale_ip_address']?.toString() ?? '';
          final syncStr = rows['scale_last_sync']?.toString();
          _lastSync =
              syncStr != null ? DateTime.tryParse(syncStr) : null;
          _scaleItemCount = itemList.length;
          _missingShelfLife = missing;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final path = _pathController.text.trim();
      final ip = _ipController.text.trim();

      await _client.from('business_settings').update({
        'scale_output_path': path,
        'scale_ip_address': ip,
      }).gt('id', '00000000-0000-0000-0000-000000000000');

      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Scale settings saved'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ErrorHandler.friendlyMessage(e)),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _pingScale() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter a scale IP address first'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }
    try {
      final result = await Process.run(
        'ping',
        ['-n', '1', '-w', '1000', ip],
      );
      final success = result.exitCode == 0;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? '✓ Scale at $ip is reachable'
              : '✗ Scale at $ip did not respond'),
          backgroundColor:
              success ? AppColors.success : AppColors.error,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ping failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _sendToScale() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('ScaleLink path is not set'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send to Scale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$_scaleItemCount product(s) will be sent to the scale.'),
            if (_missingShelfLife > 0) ...[
              const SizedBox(height: 8),
              Text(
                '⚠ $_missingShelfLife item(s) have no shelf life set '
                '— will use 5-day default.',
                style: const TextStyle(color: AppColors.warning),
              ),
            ],
            const SizedBox(height: 8),
            const Text('ScaleLink Pro will be triggered automatically.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Send Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _syncing = true;
      _syncStatus = 'Fetching scale items...';
      _syncSuccess = false;
    });

    try {
      final service = ScaleSyncService(client: _client);

      setState(() => _syncStatus = 'Generating Update.csv...');
      final result = await service.generateAndSend(
        outputPath: path,
        onStatus: (msg) {
          if (mounted) setState(() => _syncStatus = msg);
        },
      );

      // Update last sync time
      await _client
          .from('business_settings')
          .update({'scale_last_sync': DateTime.now().toIso8601String()})
          .gt('id', '00000000-0000-0000-0000-000000000000');

      if (mounted) {
        setState(() {
          _syncing = false;
          _syncSuccess = result.success;
          _syncStatus = result.message;
          if (result.success) _lastSync = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _syncing = false;
          _syncSuccess = false;
          _syncStatus = ErrorHandler.friendlyMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final lastSyncText = _lastSync == null
        ? 'Never'
        : DateFormat('dd MMM yyyy HH:mm').format(_lastSync!);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status tiles ──────────────────────────────────────
          Row(
            children: [
              _StatTile(
                label: 'Scale Items',
                value: '$_scaleItemCount',
                icon: Icons.scale,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              _StatTile(
                label: 'Missing Shelf Life',
                value: '$_missingShelfLife',
                icon: Icons.warning_amber_rounded,
                color: _missingShelfLife > 0
                    ? AppColors.warning
                    : AppColors.success,
              ),
              const SizedBox(width: 12),
              _StatTile(
                label: 'Last Sync',
                value: lastSyncText,
                icon: Icons.sync,
                color: AppColors.info,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── ScaleLink path ────────────────────────────────────
          const Text('ScaleLink Pro Folder Path',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          const Text(
            'Folder where ScaleLink Pro is installed '
            '(Update.csv will be written here)',
            style: TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _pathController,
            decoration: const InputDecoration(
              hintText: 'C:/Slp',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.folder_outlined),
            ),
          ),
          const SizedBox(height: 20),

          // ── Scale IP address ──────────────────────────────────
          const Text('Scale IP Address',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          const Text(
            'Reference only — ScaleLink Pro manages the connection. '
            'Use Ping to verify the scale is reachable.',
            style: TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ipController,
                  decoration: const InputDecoration(
                    hintText: '192.168.1.x',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.router_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _pingScale,
                icon: const Icon(Icons.network_ping, size: 18),
                label: const Text('Ping'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Save settings ─────────────────────────────────────
          Row(
            children: [
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Save Settings'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          // ── Send to Scale ─────────────────────────────────────
          const Text('Send PLU Data to Scale',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          const Text(
            'Generates Update.csv from all active scale items '
            'and triggers ScaleLink Pro to send to the Ishida scale.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          if (_syncStatus.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_syncSuccess
                        ? AppColors.success
                        : _syncing
                            ? AppColors.info
                            : AppColors.error)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (_syncSuccess
                          ? AppColors.success
                          : _syncing
                              ? AppColors.info
                              : AppColors.error)
                      .withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  if (_syncing)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.info),
                    )
                  else
                    Icon(
                      _syncSuccess
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      size: 16,
                      color: _syncSuccess
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _syncStatus,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          ElevatedButton.icon(
            onPressed: _syncing ? null : _sendToScale,
            icon: _syncing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send, size: 18),
            label: Text(_syncing ? 'Sending...' : 'Send to Scale'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
