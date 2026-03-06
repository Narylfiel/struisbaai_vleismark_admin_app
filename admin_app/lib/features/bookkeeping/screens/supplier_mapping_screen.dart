import 'package:flutter/material.dart';
import '../../../core/services/supplier_mapping_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Screen to review and resolve unmapped supplier invoice line items.
/// Also shows all existing mappings for editing.
class SupplierMappingScreen extends StatefulWidget {
  /// If provided, shows only unmapped items from this invoice.
  final String? invoiceId;
  final List<Map<String, dynamic>>? pendingItems;
  final String? supplierId;
  final String? supplierName;
  final VoidCallback? onMappingsComplete;

  const SupplierMappingScreen({
    super.key,
    this.invoiceId,
    this.pendingItems,
    this.supplierId,
    this.supplierName,
    this.onMappingsComplete,
  });

  @override
  State<SupplierMappingScreen> createState() =>
      _SupplierMappingScreenState();
}

class _SupplierMappingScreenState extends State<SupplierMappingScreen>
    with SingleTickerProviderStateMixin {
  final _mappingService = SupplierMappingService();
  late TabController _tabController;

  List<MappedLineItem> _pendingItems = [];
  List<SupplierItemMapping> _allMappings = [];
  List<CoaAccount> _accounts = [];
  List<Map<String, dynamic>> _inventoryItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final accounts = await _mappingService.getChartOfAccounts();
      final allMappings = await _mappingService.getAllMappings(
          supplierId: widget.supplierId);
      final invResult = await Supabase.instance.client
          .from('inventory_items')
          .select('id, name, sku, unit')
          .eq('is_active', true)
          .order('name');
      final invItems =
          (invResult as List).map((e) => e as Map<String, dynamic>).toList();

      List<MappedLineItem> pending = [];
      if (widget.pendingItems != null) {
        pending = await _mappingService.applyMappings(
          lineItems: widget.pendingItems!,
          supplierId: widget.supplierId,
        );
      }

      if (mounted) {
        setState(() {
          _accounts = accounts;
          _allMappings = allMappings;
          _inventoryItems = invItems;
          _pendingItems = pending;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount =
        _pendingItems.where((i) => i.isPending).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.supplierName != null
            ? 'Item Mappings — ${widget.supplierName}'
            : 'Supplier Item Mappings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: pendingCount > 0
                  ? 'Needs Mapping ($pendingCount)'
                  : 'All Mapped ✓',
              icon: Icon(pendingCount > 0
                  ? Icons.warning_amber_outlined
                  : Icons.check_circle_outline,
                  size: 16),
            ),
            const Tab(
              text: 'All Mappings',
              icon: Icon(Icons.list_alt, size: 16),
            ),
          ],
        ),
        actions: [
          if (pendingCount == 0 && widget.onMappingsComplete != null)
            FilledButton.icon(
              onPressed: widget.onMappingsComplete,
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Done — Approve Invoice'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _PendingMappingsTab(
                  items: _pendingItems,
                  accounts: _accounts,
                  inventoryItems: _inventoryItems,
                  supplierId: widget.supplierId,
                  mappingService: _mappingService,
                  onMappingSaved: _load,
                ),
                _AllMappingsTab(
                  mappings: _allMappings,
                  accounts: _accounts,
                  inventoryItems: _inventoryItems,
                  supplierId: widget.supplierId,
                  mappingService: _mappingService,
                  onChanged: _load,
                ),
              ],
            ),
    );
  }
}

// ── Pending Mappings Tab ──────────────────────────────────────────

class _PendingMappingsTab extends StatelessWidget {
  final List<MappedLineItem> items;
  final List<CoaAccount> accounts;
  final List<Map<String, dynamic>> inventoryItems;
  final String? supplierId;
  final SupplierMappingService mappingService;
  final VoidCallback onMappingSaved;

  const _PendingMappingsTab({
    required this.items,
    required this.accounts,
    required this.inventoryItems,
    this.supplierId,
    required this.mappingService,
    required this.onMappingSaved,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 48),
            SizedBox(height: 12),
            Text('No items to map',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('All line items are mapped',
                style: TextStyle(color: Color(0xFF666666))),
          ],
        ),
      );
    }

    final pending = items.where((i) => i.isPending).toList();
    final mapped = items.where((i) => !i.isPending).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pending.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Text(
              '${pending.length} item${pending.length == 1 ? '' : 's'} '
              'need mapping before this invoice can be approved.',
              style: TextStyle(color: Colors.orange.shade800),
            ),
          ),
          const SizedBox(height: 16),
          ...pending.map((item) => _MappingCard(
                item: item,
                accounts: accounts,
                inventoryItems: inventoryItems,
                supplierId: supplierId,
                mappingService: mappingService,
                onSaved: onMappingSaved,
              )),
        ],
        if (mapped.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Already mapped (${mapped.length})',
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF444444))),
          const SizedBox(height: 8),
          ...mapped.map((item) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.check_circle,
                      color: Color(0xFF2E7D32), size: 20),
                  title: Text(item.description,
                      style: const TextStyle(fontSize: 13)),
                  subtitle: Text(item.mappingLabel,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF2E7D32))),
                  trailing: Text(
                    'R ${item.lineTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              )),
        ],
      ],
    );
  }
}

// ── Mapping Card ──────────────────────────────────────────────────

class _MappingCard extends StatefulWidget {
  final MappedLineItem item;
  final List<CoaAccount> accounts;
  final List<Map<String, dynamic>> inventoryItems;
  final String? supplierId;
  final SupplierMappingService mappingService;
  final VoidCallback onSaved;

  const _MappingCard({
    required this.item,
    required this.accounts,
    required this.inventoryItems,
    this.supplierId,
    required this.mappingService,
    required this.onSaved,
  });

  @override
  State<_MappingCard> createState() => _MappingCardState();
}

class _MappingCardState extends State<_MappingCard> {
  CoaAccount? _selectedAccount;
  Map<String, dynamic>? _selectedInventoryItem;
  bool _updateStock = false;
  bool _saving = false;
  bool _applyToAll = true;

  Future<void> _save() async {
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.mappingService.saveMapping(
        supplierDescription: widget.item.description,
        accountCode: _selectedAccount!.code,
        supplierId: _applyToAll ? null : widget.supplierId,
        inventoryItemId:
            _selectedInventoryItem?['id']?.toString(),
        updateStock: _updateStock &&
            _selectedInventoryItem != null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Mapped "${widget.item.description}" → '
                '${_selectedAccount!.displayName}'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Save failed: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInventoryAccount = _selectedAccount != null &&
        (_selectedAccount!.code == '1200');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.orange.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline,
                    color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.item.description,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Text(
                  'R ${widget.item.lineTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Text(
              'Qty: ${widget.item.quantity} × '
              'R ${widget.item.unitPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 12),
            const Text('Post to account:',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<CoaAccount>(
              initialValue: _selectedAccount,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                hintText: 'Select account...',
              ),
              items: widget.accounts
                  .map((a) => DropdownMenuItem(
                        value: a,
                        child: Text(a.displayName,
                            style: const TextStyle(fontSize: 13)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedAccount = v;
                if (v?.code != '1200') {
                  _selectedInventoryItem = null;
                  _updateStock = false;
                }
              }),
            ),
            if (isInventoryAccount) ...[
              const SizedBox(height: 10),
              const Text('Link to inventory product:',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<Map<String, dynamic>>(
                initialValue: _selectedInventoryItem,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  hintText: 'Select product (optional)...',
                ),
                items: widget.inventoryItems
                    .map((i) => DropdownMenuItem(
                          value: i,
                          child: Text(
                              '${i['name']} (${i['sku'] ?? ''})',
                              style:
                                  const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedInventoryItem = v),
              ),
              if (_selectedInventoryItem != null)
                CheckboxListTile(
                  value: _updateStock,
                  onChanged: (v) =>
                      setState(() => _updateStock = v ?? false),
                  title: const Text('Update stock quantity on approval',
                      style: TextStyle(fontSize: 13)),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
            ],
            const SizedBox(height: 10),
            CheckboxListTile(
              value: _applyToAll,
              onChanged: (v) =>
                  setState(() => _applyToAll = v ?? true),
              title: const Text(
                  'Remember for all suppliers (not just this one)',
                  style: TextStyle(fontSize: 12)),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white))
                    : const Icon(Icons.save, size: 16),
                label: Text(_saving ? 'Saving…' : 'Save mapping'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── All Mappings Tab ──────────────────────────────────────────────

class _AllMappingsTab extends StatelessWidget {
  final List<SupplierItemMapping> mappings;
  final List<CoaAccount> accounts;
  final List<Map<String, dynamic>> inventoryItems;
  final String? supplierId;
  final SupplierMappingService mappingService;
  final VoidCallback onChanged;

  const _AllMappingsTab({
    required this.mappings,
    required this.accounts,
    required this.inventoryItems,
    this.supplierId,
    required this.mappingService,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (mappings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.list_alt, size: 48, color: Color(0xFFAAAAAA)),
            SizedBox(height: 12),
            Text('No mappings yet',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 4),
            Text('Mappings are created when you process invoices',
                style: TextStyle(color: Color(0xFF666666))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mappings.length,
      itemBuilder: (context, index) {
        final m = mappings[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              m.isInventory
                  ? Icons.inventory_2_outlined
                  : Icons.account_balance_outlined,
              color: m.isInventory
                  ? const Color(0xFF1565C0)
                  : const Color(0xFF2E7D32),
              size: 20,
            ),
            title: Text(m.supplierDescription,
                style: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${m.accountCode} — ${m.accountName ?? ''}',
                    style: const TextStyle(fontSize: 12)),
                if (m.inventoryItemName != null)
                  Text('Stock: ${m.inventoryItemName}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1565C0))),
                if (m.supplierId == null)
                  const Text('Global mapping',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888888))),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.red, size: 18),
              tooltip: 'Delete mapping',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete mapping?'),
                    content: Text(
                        'Remove mapping for '
                        '"${m.supplierDescription}"?'),
                    actions: [
                      TextButton(
                          onPressed: () =>
                              Navigator.pop(ctx, false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () =>
                              Navigator.pop(ctx, true),
                          child: const Text('Delete')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await mappingService.deleteMapping(m.id);
                  onChanged();
                }
              },
            ),
          ),
        );
      },
    );
  }
}
