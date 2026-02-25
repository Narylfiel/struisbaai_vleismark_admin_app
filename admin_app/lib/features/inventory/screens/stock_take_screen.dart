import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/admin_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/export_service.dart';
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

  /// PIN-based auth: use AuthService, not Supabase auth.
  String get _staffId => AuthService().getCurrentStaffId();
  bool get _isOwnerOrManager =>
      AuthService().currentRole == 'owner' || AuthService().currentRole == 'manager';
  bool get _isOwner => AuthService().currentRole == 'owner';

  /// Map sessionId -> startedByName
  Map<String, String> _startedByName = {};
  /// Map sessionId -> (counted, total, varianceValue)
  Map<String, ({int counted, int total, double? varianceValue})> _sessionStats = {};

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

      final totalItemsList = await _supabase
          .from('inventory_items')
          .select('id')
          .eq('is_active', true);
      final totalItemsCount = (totalItemsList as List).length;

      final startedByIds = sessions
          .where((s) => s.startedBy != null && s.startedBy!.isNotEmpty)
          .map((s) => s.startedBy!)
          .toSet();
      final startedByName = await _repo.getStaffNamesForIds(startedByIds);

      final stats = <String, ({int counted, int total, double? varianceValue})>{};
      for (final s in sessions) {
        final entries = await _repo.getEntriesBySession(s.id);
        final withItems = await _repo.getEntriesWithItems(s.id);
        int counted = 0;
        double? varianceValue;
        for (final e in entries) {
          if (e.actualQuantity != null) counted++;
        }
        for (final row in withItems) {
          final v = (row['variance'] as num?)?.toDouble();
          final inv = row['inventory_items'];
          final price = (inv is Map ? (inv['sell_price'] as num?)?.toDouble() : null);
          if (v != null && price != null) {
            varianceValue = (varianceValue ?? 0) + (v * price);
          }
        }
        stats[s.id] = (counted: counted, total: totalItemsCount, varianceValue: varianceValue);
      }

      if (mounted) {
        setState(() {
          _sessions = sessions;
          _currentSession = open;
          _startedByName = startedByName;
          _sessionStats = stats;
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
    if (!AuthService().isLoggedIn || _staffId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to start a stock-take')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final session = await _repo.createSession(startedBy: _staffId);
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
          countedBy: _staffId,
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
    if (_currentSession == null || _staffId.isEmpty) return;
    setState(() => _saving = true);
    try {
      await _repo.approveSession(_currentSession!.id, _staffId);
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

  Future<void> _confirmDeleteSession(StockTakeSession session) async {
    if (!_isOwner) return;
    final name = session.startedAt != null ? _formatDate(session.startedAt!) : session.id.substring(0, 8);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete session?'),
        content: const Text(
          'Delete this stock take session? All counts will be lost. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _repo.deleteSession(session.id);
      if (mounted) {
        await _loadSessionsAndOpen();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _cancelSession(StockTakeSession session) async {
    if (session.status != StockTakeSessionStatus.open && session.status != StockTakeSessionStatus.inProgress) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel session?'),
        content: const Text('Cancel this stock take? Counts will be preserved but session will be marked cancelled.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, cancel')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _repo.setSessionStatus(session.id, StockTakeSessionStatus.cancelled.dbValue);
      if (mounted) await _loadSessionsAndOpen();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppColors.danger));
    }
  }

  Future<void> _rejectSession(StockTakeSession session) async {
    if (!_isOwnerOrManager) return;
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject stock take'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'e.g. Recount needed - discrepancies found',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await _repo.rejectSession(session.id, reason);
      if (mounted) {
        await _loadSessionsAndOpen();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rejected — staff can recount')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppColors.danger));
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _approveSessionFromList(StockTakeSession session) async {
    if (!_isOwnerOrManager || _staffId.isEmpty) return;
    setState(() => _saving = true);
    try {
      await _repo.approveSession(session.id, _staffId);
      if (mounted) {
        await _loadSessionsAndOpen();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock take approved')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppColors.danger));
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _openViewEntries(StockTakeSession session) async {
    final entries = await _repo.getEntriesWithItems(session.id);
    if (!mounted) return;
    final sorted = List<Map<String, dynamic>>.from(entries);
    sorted.sort((a, b) {
      final va = ((a['variance'] as num?)?.toDouble() ?? 0).abs();
      final vb = ((b['variance'] as num?)?.toDouble() ?? 0).abs();
      return vb.compareTo(va);
    });
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => _SessionEntriesViewScreen(
          session: session,
          initialEntries: sorted,
          canEdit: session.status != StockTakeSessionStatus.approved,
          repository: _repo,
        ),
      ),
    );
    if (mounted) await _loadSessionsAndOpen();
  }

  Future<void> _exportSessionCsv(StockTakeSession session) async {
    try {
      final entries = await _repo.getEntriesWithItems(session.id);
      final sorted = List<Map<String, dynamic>>.from(entries);
      sorted.sort((a, b) {
        final va = ((a['variance'] as num?)?.toDouble() ?? 0).abs();
        final vb = ((b['variance'] as num?)?.toDouble() ?? 0).abs();
        return vb.compareTo(va);
      });
      final data = sorted.asMap().entries.map((e) {
        final i = e.key + 1;
        final r = e.value;
        final inv = r['inventory_items'];
        final name = inv is Map ? (inv['name'] as String? ?? '') : '';
        final plu = inv is Map ? (inv['plu_code']?.toString() ?? '') : '';
        final exp = (r['expected_quantity'] as num?)?.toDouble() ?? 0;
        final act = (r['actual_quantity'] as num?)?.toDouble();
        final v = (r['variance'] as num?)?.toDouble();
        final vPct = exp != 0 && v != null ? (v / exp * 100) : null;
        return {
          '#': i,
          'PLU': plu,
          'Product': name,
          'Expected': exp.toStringAsFixed(AdminConfig.stockKgDecimals),
          'Counted': act?.toStringAsFixed(AdminConfig.stockKgDecimals) ?? '',
          'Variance': v?.toStringAsFixed(AdminConfig.stockKgDecimals) ?? '',
          'Variance %': vPct != null ? '${vPct.toStringAsFixed(1)}%' : '',
        };
      }).toList();
      final date = DateTime.now().toIso8601String().split('T')[0];
      final file = await ExportService().exportToCsv(
        fileName: 'stock_take_${session.id.substring(0, 8)}_$date',
        data: data,
        columns: ['#', 'PLU', 'Product', 'Expected', 'Counted', 'Variance', 'Variance %'],
      );
      await Share.shareXFiles([XFile(file.path)], text: 'Stock take export');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.danger));
      }
    }
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
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final s = _sessions[i];
                  final stats = _sessionStats[s.id];
                  final startedByName = s.startedBy != null ? _startedByName[s.startedBy!] ?? 'Unknown' : '—';
                  return _buildSessionCard(s, stats, startedByName);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(
    StockTakeSession s,
    ({int counted, int total, double? varianceValue})? stats,
    String startedByName,
  ) {
    final counted = stats?.counted ?? 0;
    final total = stats?.total ?? 0;
    final varianceVal = stats?.varianceValue;
    return GestureDetector(
      onLongPress: _isOwner ? () => _confirmDeleteSession(s) : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(s.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    s.status.displayLabel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _statusColor(s.status)),
                  ),
                ),
                const Spacer(),
                if (_isOwner)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                    onPressed: () => _confirmDeleteSession(s),
                    tooltip: 'Delete',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Session ${s.startedAt != null ? _formatDate(s.startedAt!) : s.id.substring(0, 8)}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            Text('Started by: $startedByName', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            if (stats != null) ...[
              const SizedBox(height: 4),
              Text('$counted / $total products', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              if (varianceVal != null)
                Text('Variance: R ${varianceVal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sessionActionButtons(s),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(StockTakeSessionStatus status) {
    switch (status) {
      case StockTakeSessionStatus.open: return AppColors.info;
      case StockTakeSessionStatus.inProgress: return AppColors.primary;
      case StockTakeSessionStatus.pendingApproval: return AppColors.warning;
      case StockTakeSessionStatus.approved: return AppColors.success;
      case StockTakeSessionStatus.cancelled: return AppColors.textSecondary;
    }
  }

  List<Widget> _sessionActionButtons(StockTakeSession s) {
    final list = <Widget>[];
    switch (s.status) {
      case StockTakeSessionStatus.open:
        list.addAll([
          FilledButton.icon(
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('Continue counting'),
            onPressed: () {
              setState(() => _currentSession = s);
              _loadEntries(s.id);
              _loadItemsForCount();
            },
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.cancel, size: 16),
            label: const Text('Cancel'),
            onPressed: () => _cancelSession(s),
          ),
        ]);
        break;
      case StockTakeSessionStatus.inProgress:
        list.addAll([
          FilledButton.icon(
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('Continue counting'),
            onPressed: () {
              setState(() => _currentSession = s);
              _loadEntries(s.id);
              _loadItemsForCount();
            },
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Submit for approval'),
            onPressed: _saving ? null : () async {
              setState(() => _currentSession = s);
              await _submitForApproval();
            },
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.cancel, size: 16),
            label: const Text('Cancel'),
            onPressed: () => _cancelSession(s),
          ),
        ]);
        break;
      case StockTakeSessionStatus.pendingApproval:
        list.add(OutlinedButton.icon(
          icon: const Icon(Icons.visibility, size: 16),
          label: const Text('View entries'),
          onPressed: () => _openViewEntries(s),
        ));
        if (_isOwnerOrManager) {
          list.addAll([
            FilledButton.icon(
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Approve'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: _saving ? null : () => _approveSessionFromList(s),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
              onPressed: () => _rejectSession(s),
            ),
          ]);
        }
        break;
      case StockTakeSessionStatus.approved:
        list.addAll([
          OutlinedButton.icon(
            icon: const Icon(Icons.visibility, size: 16),
            label: const Text('View entries'),
            onPressed: () => _openViewEntries(s),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Export CSV'),
            onPressed: () => _exportSessionCsv(s),
          ),
        ]);
        break;
      case StockTakeSessionStatus.cancelled:
        list.add(OutlinedButton.icon(
          icon: const Icon(Icons.visibility, size: 16),
          label: const Text('View entries'),
          onPressed: () => _openViewEntries(s),
        ));
        break;
    }
    return list;
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
                  final canEdit = _currentSession != null &&
                      _currentSession!.status != StockTakeSessionStatus.approved;
                  return ListTile(
                    title: Text(itemName),
                    subtitle: Text(
                      'Expected: ${e.expectedQuantity.toStringAsFixed(2)} '
                      'Actual: ${e.actualQuantity?.toStringAsFixed(2) ?? "—"} '
                      'Variance: ${e.variance?.toStringAsFixed(2) ?? "—"}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (e.variance != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              (variance >= 0 ? '+' : '') + variance.toStringAsFixed(2),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: varianceColor,
                              ),
                            ),
                          ),
                        if (canEdit)
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _showEditEntryDialog(e, itemName),
                          ),
                      ],
                    ),
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

  Future<void> _showEditEntryDialog(StockTakeEntry entry, String productName) async {
    final controller = TextEditingController(text: entry.actualQuantity?.toStringAsFixed(AdminConfig.stockKgDecimals) ?? '');
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Correct count for $productName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Expected: ${entry.expectedQuantity.toStringAsFixed(AdminConfig.stockKgDecimals)}'),
            const SizedBox(height: 4),
            Text('Current count: ${entry.actualQuantity?.toStringAsFixed(AdminConfig.stockKgDecimals) ?? '—'}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Corrected quantity'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim());
              if (v != null) Navigator.pop(ctx, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || !mounted || _currentSession == null) return;
    try {
      await _repo.updateEntryActualQuantity(entry.id, result);
      await _loadEntries(_currentSession!.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Count updated')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppColors.danger));
    }
  }
}

/// View session entries — product list with variance, edit (if not approved), export.
class _SessionEntriesViewScreen extends StatefulWidget {
  final StockTakeSession session;
  final List<Map<String, dynamic>> initialEntries;
  final bool canEdit;
  final StockTakeRepository repository;

  const _SessionEntriesViewScreen({
    required this.session,
    required this.initialEntries,
    required this.canEdit,
    required this.repository,
  });

  @override
  State<_SessionEntriesViewScreen> createState() => _SessionEntriesViewScreenState();
}

class _SessionEntriesViewScreenState extends State<_SessionEntriesViewScreen> {
  late List<Map<String, dynamic>> _entries;

  @override
  void initState() {
    super.initState();
    _entries = widget.initialEntries;
  }

  Future<void> _refreshEntries() async {
    final list = await widget.repository.getEntriesWithItems(widget.session.id);
    final sorted = List<Map<String, dynamic>>.from(list);
    sorted.sort((a, b) {
      final va = ((a['variance'] as num?)?.toDouble() ?? 0).abs();
      final vb = ((b['variance'] as num?)?.toDouble() ?? 0).abs();
      return vb.compareTo(va);
    });
    if (mounted) setState(() => _entries = sorted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Entries — ${widget.session.status.displayLabel}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportCsv(context),
            tooltip: 'Export CSV',
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _entries.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final r = _entries[i];
          final inv = r['inventory_items'];
          final name = inv is Map ? (inv['name'] as String? ?? '') : '';
          final plu = inv is Map ? (inv['plu_code']?.toString() ?? '') : '';
          final exp = (r['expected_quantity'] as num?)?.toDouble() ?? 0;
          final act = (r['actual_quantity'] as num?)?.toDouble();
          final v = (r['variance'] as num?)?.toDouble();
          final vPct = exp != 0 && v != null ? (v / exp * 100) : null;
          final entry = StockTakeEntry.fromJson(r as Map<String, dynamic>);
          return ListTile(
            title: Text(name),
            subtitle: Text('PLU: $plu • Expected: ${exp.toStringAsFixed(AdminConfig.stockKgDecimals)} | Counted: ${act?.toStringAsFixed(AdminConfig.stockKgDecimals) ?? '—'} | Variance: ${v?.toStringAsFixed(AdminConfig.stockKgDecimals) ?? '—'}${vPct != null ? ' (${vPct.toStringAsFixed(1)}%)' : ''}'),
            trailing: widget.canEdit
                ? IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showEditDialog(context, entry, name),
                  )
                : null,
          );
        },
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, StockTakeEntry entry, String productName) async {
    final controller = TextEditingController(text: entry.actualQuantity?.toStringAsFixed(AdminConfig.stockKgDecimals) ?? '');
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Correct count for $productName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Expected: ${entry.expectedQuantity.toStringAsFixed(AdminConfig.stockKgDecimals)}'),
            const SizedBox(height: 4),
            Text('Current count: ${entry.actualQuantity?.toStringAsFixed(AdminConfig.stockKgDecimals) ?? '—'}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Corrected quantity'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim());
              if (v != null) Navigator.pop(ctx, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null) return;
    try {
      await widget.repository.updateEntryActualQuantity(entry.id, result);
      await _refreshEntries();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _exportCsv(BuildContext context) async {
    try {
      final data = _entries.asMap().entries.map((e) {
        final i = e.key + 1;
        final r = e.value;
        final inv = r['inventory_items'];
        final name = inv is Map ? (inv['name'] as String? ?? '') : '';
        final plu = inv is Map ? (inv['plu_code']?.toString() ?? '') : '';
        final exp = (r['expected_quantity'] as num?)?.toDouble() ?? 0;
        final act = (r['actual_quantity'] as num?)?.toDouble();
        final v = (r['variance'] as num?)?.toDouble();
        final vPct = exp != 0 && v != null ? (v / exp * 100) : null;
        return {
          '#': i,
          'PLU': plu,
          'Product': name,
          'Expected': exp.toStringAsFixed(AdminConfig.stockKgDecimals),
          'Counted': act?.toStringAsFixed(AdminConfig.stockKgDecimals) ?? '',
          'Variance': v?.toStringAsFixed(AdminConfig.stockKgDecimals) ?? '',
          'Variance %': vPct != null ? '${vPct.toStringAsFixed(1)}%' : '',
        };
      }).toList();
      final date = DateTime.now().toIso8601String().split('T')[0];
      final file = await ExportService().exportToCsv(
        fileName: 'stock_take_${widget.session.id.substring(0, 8)}_$date',
        data: data,
        columns: ['#', 'PLU', 'Product', 'Expected', 'Counted', 'Variance', 'Variance %'],
      );
      await Share.shareXFiles([XFile(file.path)], text: 'Stock take export');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.danger));
      }
    }
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
