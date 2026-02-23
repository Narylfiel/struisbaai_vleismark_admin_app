import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/models/stock_movement.dart';
import '../services/inventory_repository.dart';
import '../../../core/services/auth_service.dart';
import '../../bookkeeping/services/ledger_repository.dart';

/// Blueprint §4.5: Stock lifecycle UI — Waste, Transfer, Freezer, Donation, Sponsorship, Stock Take, Movement History.
/// Every financial event (waste, donation, sponsorship) creates ledger entries (Blueprint §9).

final _repo = InventoryRepository();
final _auth = AuthService();
final _ledger = LedgerRepository();

/// Opens stock actions picker dialog, then the chosen action dialog.
void showStockActionsMenu(
  BuildContext context, {
  required Map<String, dynamic> product,
  required VoidCallback onDone,
}) {
  final itemId = product['id'] as String?;
  if (itemId == null) return;
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Stock action'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionTile(
              icon: Icons.delete_outline,
              label: 'Waste',
              onTap: () {
                Navigator.pop(ctx);
                showWasteDialog(context, product: product, onDone: onDone);
              },
            ),
            _ActionTile(
              icon: Icons.swap_horiz,
              label: 'Transfer',
              onTap: () {
                Navigator.pop(ctx);
                showTransferDialog(context, product: product, onDone: onDone);
              },
            ),
            _ActionTile(
              icon: Icons.ac_unit,
              label: 'Move to Freezer',
              onTap: () {
                Navigator.pop(ctx);
                showFreezerDialog(context, product: product, onDone: onDone);
              },
            ),
            _ActionTile(
              icon: Icons.volunteer_activism,
              label: 'Donation',
              onTap: () {
                Navigator.pop(ctx);
                showDonationDialog(context, product: product, onDone: onDone);
              },
            ),
            _ActionTile(
              icon: Icons.celebration,
              label: 'Sponsorship',
              onTap: () {
                Navigator.pop(ctx);
                showSponsorshipDialog(context, product: product, onDone: onDone);
              },
            ),
            _ActionTile(
              icon: Icons.tune,
              label: 'Stock Take Adjustment',
              onTap: () {
                Navigator.pop(ctx);
                showStockTakeDialog(context, product: product, onDone: onDone);
              },
            ),
            _ActionTile(
              icon: Icons.history,
              label: 'Movement History',
              onTap: () {
                Navigator.pop(ctx);
                showMovementHistoryDialog(context, product: product);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      onTap: onTap,
    );
  }
}

void showWasteDialog(
  BuildContext context, {
  required Map<String, dynamic> product,
  required VoidCallback onDone,
}) {
  showDialog(
    context: context,
    builder: (_) => _WasteDialog(product: product, onDone: onDone),
  );
}

void showTransferDialog(
  BuildContext context, {
  required Map<String, dynamic> product,
  required VoidCallback onDone,
}) {
  showDialog(
    context: context,
    builder: (_) => _TransferDialog(product: product, onDone: onDone),
  );
}

void showFreezerDialog(
  BuildContext context, {
  required Map<String, dynamic> product,
  required VoidCallback onDone,
}) {
  showDialog(
    context: context,
    builder: (_) => _FreezerDialog(product: product, onDone: onDone),
  );
}

void showDonationDialog(
  BuildContext context, {
  required Map<String, dynamic> product,
  required VoidCallback onDone,
}) {
  showDialog(
    context: context,
    builder: (_) => _DonationDialog(product: product, onDone: onDone),
  );
}

void showSponsorshipDialog(
  BuildContext context, {
  required Map<String, dynamic> product,
  required VoidCallback onDone,
}) {
  showDialog(
    context: context,
    builder: (_) => _SponsorshipDialog(product: product, onDone: onDone),
  );
}

void showStockTakeDialog(
  BuildContext context, {
  required Map<String, dynamic> product,
  required VoidCallback onDone,
}) {
  showDialog(
    context: context,
    builder: (_) => _StockTakeDialog(product: product, onDone: onDone),
  );
}

void showMovementHistoryDialog(
  BuildContext context, {
  required Map<String, dynamic> product,
}) {
  showDialog(
    context: context,
    builder: (_) => _MovementHistoryDialog(product: product),
  );
}

// ─── Waste ───────────────────────────────────────────────────────────────

class _WasteDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onDone;

  const _WasteDialog({required this.product, required this.onDone});

  @override
  State<_WasteDialog> createState() => _WasteDialogState();
}

class _WasteDialogState extends State<_WasteDialog> {
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final qty = double.tryParse(_quantityController.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity')),
      );
      return;
    }
    final staffId = _auth.currentStaffId;
    if (staffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not logged in')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final movement = await _repo.recordMovement(
        itemId: widget.product['id'] as String,
        movementType: MovementType.waste,
        quantity: qty,
        performedBy: staffId,
        notes: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
        metadata: {'reason': _reasonController.text.trim()},
      );
      final cost = (widget.product['cost_price'] as num?)?.toDouble() ?? 0;
      final amount = qty * cost;
      if (amount > 0) {
        await _ledger.createDoubleEntry(
          date: DateTime.now(),
          debitAccountCode: '5300',
          debitAccountName: 'Shrinkage / Waste',
          creditAccountCode: '1300',
          creditAccountName: 'Inventory (Meat)',
          amount: amount,
          description: 'Waste: ${widget.product['name']}',
          referenceType: 'adjustment',
          referenceId: movement.id,
          source: 'waste',
          metadata: {'reason': _reasonController.text.trim()},
          recordedBy: staffId,
        );
      }
      widget.onDone();
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waste recorded')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.product['name'] ?? 'Product';
    return _DialogShell(
      title: 'Record Waste',
      subtitle: name,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _quantityController,
            decoration: const InputDecoration(
              labelText: 'Quantity',
              hintText: '0.000',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}$')),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              hintText: 'e.g. Spoilage, damage',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _loading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Record Waste'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Transfer ────────────────────────────────────────────────────────────

class _TransferDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onDone;

  const _TransferDialog({required this.product, required this.onDone});

  @override
  State<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<_TransferDialog> {
  final _quantityController = TextEditingController();
  List<Map<String, dynamic>> _locations = [];
  String? _fromId;
  String? _toId;
  bool _loading = false;
  bool _loadingLocations = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final r = await SupabaseService.client
          .from('stock_locations')
          .select('id, name')
          .eq('is_active', true)
          .order('name');
      setState(() {
        _locations = List<Map<String, dynamic>>.from(r);
        _loadingLocations = false;
      });
    } catch (_) {
      setState(() => _loadingLocations = false);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final qty = double.tryParse(_quantityController.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity')),
      );
      return;
    }
    if (_fromId == null || _toId == null || _fromId == _toId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select different From and To locations')),
      );
      return;
    }
    final staffId = _auth.currentStaffId;
    if (staffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not logged in')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await _repo.transferStock(
        itemId: widget.product['id'] as String,
        quantity: qty,
        locationFromId: _fromId!,
        locationToId: _toId!,
        performedBy: staffId,
      );
      widget.onDone();
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transfer recorded')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      title: 'Transfer Between Locations',
      subtitle: widget.product['name'] ?? 'Product',
      child: _loadingLocations
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    hintText: '0.000',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}$')),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _fromId,
                  decoration: const InputDecoration(
                    labelText: 'From location',
                    border: OutlineInputBorder(),
                  ),
                  items: _locations
                      .map((l) => DropdownMenuItem(
                            value: l['id'] as String,
                            child: Text(l['name'] as String? ?? ''),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _fromId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _toId,
                  decoration: const InputDecoration(
                    labelText: 'To location',
                    border: OutlineInputBorder(),
                  ),
                  items: _locations
                      .map((l) => DropdownMenuItem(
                            value: l['id'] as String,
                            child: Text(l['name'] as String? ?? ''),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _toId = v),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _loading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Record Transfer'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

// ─── Freezer ──────────────────────────────────────────────────────────────

class _FreezerDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onDone;

  const _FreezerDialog({required this.product, required this.onDone});

  @override
  State<_FreezerDialog> createState() => _FreezerDialogState();
}

class _FreezerDialogState extends State<_FreezerDialog> {
  final _quantityController = TextEditingController(text: '');
  final _pctController = TextEditingController(text: '100');
  bool _loading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _pctController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final qty = double.tryParse(_quantityController.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity')),
      );
      return;
    }
    final pct = double.tryParse(_pctController.text);
    if (pct == null || pct < 0 || pct > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Markdown % must be 0–100')),
      );
      return;
    }
    final staffId = _auth.currentStaffId;
    if (staffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not logged in')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await _repo.recordMovement(
        itemId: widget.product['id'] as String,
        movementType: MovementType.freezer,
        quantity: qty,
        performedBy: staffId,
        metadata: {'markdown_pct': pct},
      );
      widget.onDone();
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Move to freezer recorded')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      title: 'Move to Freezer',
      subtitle: widget.product['name'] ?? 'Product',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _quantityController,
            decoration: const InputDecoration(
              labelText: 'Quantity to move',
              hintText: '0.000',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}$')),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pctController,
            decoration: const InputDecoration(
              labelText: 'Markdown % (0–100)',
              hintText: '100',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _loading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Move to Freezer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Donation ─────────────────────────────────────────────────────────────

class _DonationDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onDone;

  const _DonationDialog({required this.product, required this.onDone});

  @override
  State<_DonationDialog> createState() => _DonationDialogState();
}

class _DonationDialogState extends State<_DonationDialog> {
  final _quantityController = TextEditingController();
  final _recipientController = TextEditingController();
  final _typeController = TextEditingController();
  final _valueController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _loading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _recipientController.dispose();
    _typeController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final qty = double.tryParse(_quantityController.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity')),
      );
      return;
    }
    final staffId = _auth.currentStaffId;
    if (staffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not logged in')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final movement = await _repo.recordMovement(
        itemId: widget.product['id'] as String,
        movementType: MovementType.donation,
        quantity: qty,
        performedBy: staffId,
        notes: _recipientController.text.trim().isEmpty
            ? null
            : 'Recipient: ${_recipientController.text.trim()}',
        metadata: {
          'recipient': _recipientController.text.trim(),
          'type': _typeController.text.trim(),
          'value': double.tryParse(_valueController.text),
          'date': _date.toIso8601String(),
        },
      );
      final cost = (widget.product['cost_price'] as num?)?.toDouble() ?? 0;
      final amount = qty * cost;
      if (amount > 0) {
        await _ledger.createDoubleEntry(
          date: DateTime.now(),
          debitAccountCode: '6510',
          debitAccountName: 'Donations',
          creditAccountCode: '1300',
          creditAccountName: 'Inventory (Meat)',
          amount: amount,
          description: 'Donation: ${widget.product['name']} to ${_recipientController.text.trim()}',
          referenceType: 'adjustment',
          referenceId: movement.id,
          source: 'donation',
          metadata: {'recipient': _recipientController.text.trim()},
          recordedBy: staffId,
        );
      }
      widget.onDone();
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donation recorded')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      title: 'Record Donation',
      subtitle: widget.product['name'] ?? 'Product',
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                hintText: '0.000',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}$')),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _recipientController,
              decoration: const InputDecoration(
                labelText: 'Recipient',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(
                labelText: 'Type (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valueController,
              decoration: const InputDecoration(
                labelText: 'Estimated value (optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Date'),
              subtitle: Text(_date.toString().substring(0, 10)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Record Donation'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sponsorship ──────────────────────────────────────────────────────────

class _SponsorshipDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onDone;

  const _SponsorshipDialog({required this.product, required this.onDone});

  @override
  State<_SponsorshipDialog> createState() => _SponsorshipDialogState();
}

class _SponsorshipDialogState extends State<_SponsorshipDialog> {
  final _quantityController = TextEditingController();
  final _recipientController = TextEditingController();
  final _eventController = TextEditingController();
  final _descController = TextEditingController();
  final _valueController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _loading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _recipientController.dispose();
    _eventController.dispose();
    _descController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final qty = double.tryParse(_quantityController.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity')),
      );
      return;
    }
    final staffId = _auth.currentStaffId;
    if (staffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not logged in')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final movement = await _repo.recordMovement(
        itemId: widget.product['id'] as String,
        movementType: MovementType.sponsorship,
        quantity: qty,
        performedBy: staffId,
        notes: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        metadata: {
          'recipient': _recipientController.text.trim(),
          'event': _eventController.text.trim(),
          'date': _date.toIso8601String(),
          'estimated_value': double.tryParse(_valueController.text),
        },
      );
      final cost = (widget.product['cost_price'] as num?)?.toDouble() ?? 0;
      final amount = qty * cost;
      if (amount > 0) {
        await _ledger.createDoubleEntry(
          date: DateTime.now(),
          debitAccountCode: '6500',
          debitAccountName: 'Marketing & Sponsorship',
          creditAccountCode: '1300',
          creditAccountName: 'Inventory (Meat)',
          amount: amount,
          description: 'Sponsorship: ${widget.product['name']} — ${_eventController.text.trim()}',
          referenceType: 'adjustment',
          referenceId: movement.id,
          source: 'sponsorship',
          metadata: {'recipient': _recipientController.text.trim(), 'event': _eventController.text.trim()},
          recordedBy: staffId,
        );
      }
      widget.onDone();
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sponsorship recorded')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      title: 'Record Sponsorship',
      subtitle: widget.product['name'] ?? 'Product',
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                hintText: '0.000',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}$')),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _recipientController,
              decoration: const InputDecoration(
                labelText: 'Recipient',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _eventController,
              decoration: const InputDecoration(
                labelText: 'Event',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valueController,
              decoration: const InputDecoration(
                labelText: 'Estimated value (optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Date'),
              subtitle: Text(_date.toString().substring(0, 10)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Record Sponsorship'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stock Take ───────────────────────────────────────────────────────────

class _StockTakeDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onDone;

  const _StockTakeDialog({required this.product, required this.onDone});

  @override
  State<_StockTakeDialog> createState() => _StockTakeDialogState();
}

class _StockTakeDialogState extends State<_StockTakeDialog> {
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final cur = widget.product['current_stock'];
    double onHand;
    if (cur != null && cur is num) {
      onHand = (cur as num).toDouble();
    } else {
      final fresh = (widget.product['stock_on_hand_fresh'] as num?)?.toDouble() ?? 0;
      final frozen = (widget.product['stock_on_hand_frozen'] as num?)?.toDouble() ?? 0;
      onHand = fresh + frozen;
    }
    _quantityController.text = onHand.toStringAsFixed(3);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final actual = double.tryParse(_quantityController.text);
    if (actual == null || actual < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity')),
      );
      return;
    }
    final staffId = _auth.currentStaffId;
    if (staffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not logged in')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await _repo.adjustStock(
        itemId: widget.product['id'] as String,
        actualQuantity: actual,
        performedBy: staffId,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      widget.onDone();
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock take adjustment saved')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      title: 'Stock Take Adjustment',
      subtitle: widget.product['name'] ?? 'Product',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _quantityController,
            decoration: const InputDecoration(
              labelText: 'Actual count',
              hintText: '0.000',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}$')),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _loading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Adjustment'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Movement History ────────────────────────────────────────────────────

class _MovementHistoryDialog extends StatefulWidget {
  final Map<String, dynamic> product;

  const _MovementHistoryDialog({required this.product});

  @override
  State<_MovementHistoryDialog> createState() => _MovementHistoryDialogState();
}

class _MovementHistoryDialogState extends State<_MovementHistoryDialog> {
  List<StockMovement> _movements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final itemId = widget.product['id'] as String?;
    if (itemId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final list = await _repo.getMovementHistory(itemId);
      setState(() {
        _movements = list;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.product['name'] ?? 'Product';
    return _DialogShell(
      title: 'Movement History',
      subtitle: name,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _movements.isEmpty
              ? const Center(child: Text('No movements yet'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _movements.length,
                  itemBuilder: (_, i) {
                    final m = _movements[i];
                    return ListTile(
                      title: Text(
                        '${m.movementType.dbValue} — ${m.quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        '${m.performedAt?.toIso8601String() ?? ''} ${m.notes ?? ''}',
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
    );
  }
}

// ─── Shell ────────────────────────────────────────────────────────────────

class _DialogShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _DialogShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.inventory_2, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
