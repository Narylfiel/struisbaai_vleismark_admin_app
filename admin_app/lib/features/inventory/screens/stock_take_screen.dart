import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../models/stock_take_entry.dart';
import '../models/stock_take_session.dart';
import '../services/stock_take_repository.dart';

/// Blueprint §4.7: Stock-take — list sessions, start session, count entry UI, submit/approve.
class StockTakeScreen extends StatefulWidget {
  const StockTakeScreen({super.key});

  @override
  State<StockTakeScreen> createState() => _StockTakeScreenState();
}

class _StockTakeScreenState extends State<StockTakeScreen> {
  final _repo = StockTakeRepository();
  final _supabase = SupabaseService.client;

  List<StockTakeSession> _sessions = [];
  StockTakeSession? _currentSession;
  List<StockTakeEntry> _entries = [];
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _items = [];
  String? _selectedLocationId;
  final Map<String, TextEditingController> _actualControllers = {};
  bool _loadingSessions = true;
  bool _loadingEntries = false;
  bool _saving = false;
  String? _scannedItemId;
  final ScrollController _countListScrollController = ScrollController();
  final FocusNode _scanFocusNode = FocusNode();
  final GlobalKey _scrollToKey = GlobalKey();

  String? get _userId => _supabase.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _loadSessionsAndOpen();
  }

  @override
  void dispose() {
    _countListScrollController.dispose();
    _scanFocusNode.dispose();
    for (final c in _actualControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Lookup product by barcode: inventory_items WHERE barcode = ? OR plu_code = ?
  Future<Map<String, dynamic>?> _lookupByBarcode(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return null;
    try {
      var row = await _supabase
          .from('inventory_items')
          .select('id, name, plu_code, barcode')
          .eq('barcode', trimmed)
          .eq('is_active', true)
          .maybeSingle();
      if (row != null) return row;
      final pluNum = int.tryParse(trimmed);
      if (pluNum != null) {
        row = await _supabase
            .from('inventory_items')
            .select('id, name, plu_code, barcode')
            .eq('plu_code', pluNum)
            .eq('is_active', true)
            .maybeSingle();
      }
      return row;
    } catch (_) {
      return null;
    }
  }

  Future<void> _openBarcodeScanner() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const _BarcodeScannerOverlay(),
      ),
    );
    if (barcode == null || barcode.isEmpty || !mounted) return;
    final item = await _lookupByBarcode(barcode);
    if (!mounted) return;
    if (item == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No product found for barcode $barcode'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    final id = item['id'] as String?;
    if (id == null) return;
    final index = _items.indexWhere((e) => e['id'] == id);
    if (index < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product found but not in current count list.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() => _scannedItemId = id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _scannedItemId != id) return;
      try {
        final ctx = _scrollToKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx, alignment: 0.3, duration: const Duration(milliseconds: 300));
        }
        _scanFocusNode.requestFocus();
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted) setState(() => _scannedItemId = null);
        });
      } catch (_) {}
    });
  }

  Future<void> _loadLocations() async {
    try {
      final r = await _supabase
          .from('stock_locations')
          .select('id, name')
          .eq('is_active', true)
          .order('name');
      setState(() => _locations = List<Map<String, dynamic>>.from(r));
    } catch (_) {
      setState(() => _locations = []);
    }
  }

  Future<void> _loadSessionsAndOpen() async {
    setState(() => _loadingSessions = true);
    try {
      final sessions = await _repo.getSessions();
      final open = await _repo.getOpenSession();
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _currentSession = open;
          _loadingSessions = false;
        });
        if (open != null) {
          _loadEntries(open.id);
          _loadItemsForCount();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sessions = [];
          _currentSession = null;
          _loadingSessions = false;
        });
      }
    }
  }

  Future<void> _loadEntries(String sessionId) async {
    setState(() => _loadingEntries = true);
    try {
      final list = await _repo.getEntriesBySession(sessionId);
      if (mounted) setState(() {
        _entries = list;
        _loadingEntries = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingEntries = false);
    }
  }

  Future<void> _loadItemsForCount() async {
    try {
      final r = await _supabase
          .from('inventory_items')
          .select('id, name, plu_code, current_stock, stock_on_hand_fresh, stock_on_hand_frozen')
          .eq('is_active', true)
          .order('plu_code');
      final list = List<Map<String, dynamic>>.from(r);
      if (mounted) {
        setState(() => _items = list);
        for (final item in list) {
          final id = item['id'] as String?;
          if (id != null && !_actualControllers.containsKey(id)) {
            _actualControllers[id] = TextEditingController();
          }
        }
      }
    } catch (_) {
      if (mounted) setState(() => _items = []);
    }
  }

  /// C1: Single source of truth — current_stock only.
  double _expectedForItem(Map<String, dynamic> item) {
    return (item['current_stock'] as num?)?.toDouble() ?? 0;
  }

  Future<void> _startStockTake() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to start a stock-take')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final session = await _repo.createSession(startedBy: _userId);
      await _repo.setSessionStatus(session.id, StockTakeSessionStatus.inProgress.dbValue);
      if (mounted) {
        await _loadSessionsAndOpen();
        _loadItemsForCount();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock-take started')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start: $e')),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _saveCounts() async {
    if (_currentSession == null) return;
    final sessionId = _currentSession!.id;
    int saved = 0;
    setState(() => _saving = true);
    try {
      for (final item in _items) {
        final itemId = item['id'] as String?;
        if (itemId == null) continue;
        final text = _actualControllers[itemId]?.text?.trim();
        if (text == null || text.isEmpty) continue;
        final actual = double.tryParse(text);
        if (actual == null) continue;
        final expected = _expectedForItem(item);
        await _repo.saveEntry(
          sessionId: sessionId,
          itemId: itemId,
          locationId: _selectedLocationId,
          expectedQuantity: expected,
          actualQuantity: actual,
          countedBy: _userId,
          deviceId: null,
        );
        saved++;
      }
      if (mounted) {
        await _loadEntries(sessionId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved $saved count(s)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _submitForApproval() async {
    if (_currentSession == null) return;
    setState(() => _saving = true);
    try {
      await _repo.setSessionStatus(
        _currentSession!.id,
        StockTakeSessionStatus.pendingApproval.dbValue,
      );
      if (mounted) {
        await _loadSessionsAndOpen();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submitted for approval')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submit failed: $e')),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _approveSession() async {
    if (_currentSession == null || _userId == null) return;
    setState(() => _saving = true);
    try {
      await _repo.approveSession(_currentSession!.id, _userId!);
      if (mounted) {
        await _loadSessionsAndOpen();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock-take approved; stock adjusted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approve failed: $e')),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  void _closeCurrentSession() {
    setState(() => _currentSession = null);
    _loadSessionsAndOpen();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingSessions) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_currentSession == null) ...[
            _buildSessionList(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _saving ? null : _startStockTake,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Stock-Take'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ] else ...[
            _buildCurrentSessionHeader(),
            const SizedBox(height: 16),
            _buildCountSection(),
            const SizedBox(height: 24),
            _buildEntriesList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sessions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (_sessions.isEmpty)
              const Text(
                'No stock-take sessions yet. Start one to begin counting.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _sessions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final s = _sessions[i];
                  return ListTile(
                    title: Text('Session ${s.startedAt != null ? _formatDate(s.startedAt!) : s.id.substring(0, 8)}'),
                    subtitle: Text('Status: ${s.status.displayLabel}'),
                    trailing: s.status == StockTakeSessionStatus.open ||
                            s.status == StockTakeSessionStatus.inProgress
                        ? TextButton(
                            onPressed: () {
                              setState(() => _currentSession = s);
                              _loadEntries(s.id);
                              _loadItemsForCount();
                            },
                            child: const Text('Open'),
                          )
                        : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSessionHeader() {
    final s = _currentSession!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current session: ${_formatDate(s.startedAt ?? DateTime.now())}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Status: ${s.status.displayLabel}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (s.status == StockTakeSessionStatus.inProgress) ...[
              TextButton(
                onPressed: _saving ? null : _submitForApproval,
                child: const Text('Submit for approval'),
              ),
              TextButton(
                onPressed: _saving ? null : _closeCurrentSession,
                child: const Text('Close view'),
              ),
            ],
            if (s.status == StockTakeSessionStatus.pendingApproval) ...[
              ElevatedButton(
                onPressed: _saving ? null : _approveSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Approve'),
              ),
              TextButton(
                onPressed: _closeCurrentSession,
                child: const Text('Close view'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCountSection() {
    if (_currentSession == null ||
        _currentSession!.status != StockTakeSessionStatus.inProgress) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Enter counts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _openBarcodeScanner,
                  icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                  tooltip: 'Scan barcode to locate product',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Location:', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                DropdownButton<String?>(
                  value: _selectedLocationId,
                  hint: const Text('Default / All'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Default / All')),
                    ..._locations.map((loc) {
                      final id = loc['id'] as String?;
                      final name = loc['name'] as String? ?? '';
                      return DropdownMenuItem<String?>(value: id, child: Text(name));
                    }),
                  ],
                  onChanged: (v) => setState(() => _selectedLocationId = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_items.isEmpty)
              const Text('No active items to count.', style: TextStyle(color: AppColors.textSecondary))
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.builder(
                  controller: _countListScrollController,
                  shrinkWrap: true,
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final item = _items[i];
                    final id = item['id'] as String? ?? '';
                    final name = item['name'] as String? ?? '';
                    final plu = item['plu_code']?.toString() ?? '';
                    final expected = _expectedForItem(item);
                    final isScanned = _scannedItemId == id;
                    _actualControllers[id] ??= TextEditingController();
                    return Padding(
                      key: isScanned ? _scrollToKey : null,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Container(
                        decoration: isScanned
                            ? BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              )
                            : null,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text('$plu', overflow: TextOverflow.ellipsis),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(name, overflow: TextOverflow.ellipsis),
                            ),
                            SizedBox(
                              width: 60,
                              child: Text(expected.toStringAsFixed(2),
                                  style: const TextStyle(color: AppColors.textSecondary)),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                focusNode: isScanned ? _scanFocusNode : null,
                                controller: _actualControllers[id],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Actual',
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _saving ? null : _saveCounts,
              icon: _saving ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ) : const Icon(Icons.save),
              label: const Text('Save counts'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Session entries',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (_loadingEntries)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ))
            else if (_entries.isEmpty)
              const Text(
                'No counts saved yet. Enter actual quantities above and Save counts.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _entries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final e = _entries[i];
                  final nameMap = <String, String>{};
                  for (final m in _items) {
                    final id = m['id'] as String?;
                    if (id != null) nameMap[id] = m['name'] as String? ?? id;
                  }
                  final itemName = nameMap[e.itemId] ?? e.itemId;
                  final variance = e.variance ?? 0;
                  final varianceColor = variance > 0
                      ? AppColors.success
                      : variance < 0
                          ? AppColors.warning
                          : AppColors.textSecondary;
                  return ListTile(
                    title: Text(itemName),
                    subtitle: Text(
                      'Expected: ${e.expectedQuantity.toStringAsFixed(2)} '
                      'Actual: ${e.actualQuantity?.toStringAsFixed(2) ?? "—"} '
                      'Variance: ${e.variance?.toStringAsFixed(2) ?? "—"}',
                    ),
                    trailing: e.variance != null
                        ? Text(
                            (variance >= 0 ? '+' : '') + variance.toStringAsFixed(2),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: varianceColor,
                            ),
                          )
                        : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

/// Full-screen barcode scanner overlay. On detect, pops with barcode raw value.
class _BarcodeScannerOverlay extends StatefulWidget {
  const _BarcodeScannerOverlay();

  @override
  State<_BarcodeScannerOverlay> createState() => _BarcodeScannerOverlayState();
}

class _BarcodeScannerOverlayState extends State<_BarcodeScannerOverlay> {
  bool _alreadyPopped = false;

  void _onDetect(BarcodeCapture capture) {
    if (_alreadyPopped) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    _alreadyPopped = true;
    Navigator.of(context).pop(raw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan barcode'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: MobileScanner(
        onDetect: _onDetect,
      ),
    );
  }
}
