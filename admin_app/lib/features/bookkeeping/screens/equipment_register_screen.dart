import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/audit_service.dart';

/// M7: Equipment Register — list assets, add/edit, depreciation (Dart), service log.
class EquipmentRegisterScreen extends StatefulWidget {
  const EquipmentRegisterScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<EquipmentRegisterScreen> createState() => _EquipmentRegisterScreenState();
}

class _EquipmentRegisterScreenState extends State<EquipmentRegisterScreen> {
  final _client = SupabaseService.client;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await _client
          .from('equipment_register')
          .select('*')
          .order('description');
      if (mounted) {
        setState(() {
          _items = List<Map<String, dynamic>>.from(rows as List);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Current value: straight_line = cost - (cost * rate/100 * years); diminishing = cost * pow(1 - rate/100, years). Floor 0.
  double _currentValue(Map<String, dynamic> r) {
    final cost = (r['purchase_price'] as num?)?.toDouble() ?? 0;
    final purchaseDate = r['purchase_date'] != null
        ? DateTime.tryParse(r['purchase_date'].toString().substring(0, 10))
        : null;
    if (purchaseDate == null || cost <= 0) return cost;
    final years = DateTime.now().difference(purchaseDate).inDays / 365.0;
    if (years <= 0) return cost;
    final rate = (r['depreciation_rate'] as num?)?.toDouble();
    final usefulLife = (r['useful_life_years'] as num?)?.toInt();
    final effectiveRate = rate ?? (usefulLife != null && usefulLife > 0 ? 100.0 / usefulLife : 0);
    /// DB: straight_line, declining_balance, diminishing
    final method = r['depreciation_method']?.toString() ?? 'straight_line';
    double current;
    if (method == 'declining_balance' || method == 'diminishing') {
      current = cost * math.pow(1 - effectiveRate / 100, years);
    } else {
      current = cost - (cost * effectiveRate / 100 * years);
    }
    return current < 0 ? 0 : current;
  }

  /// DB: active, under_repair, written_off
  Color _statusColor(String? status) {
    switch (status) {
      case 'active':
        return AppColors.success;
      case 'under_repair':
        return AppColors.warning;
      case 'written_off':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  /// Friendly label for status. DB: active, under_repair, written_off.
  String _statusDisplayLabel(String? status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'under_repair':
        return 'Under Repair';
      case 'written_off':
        return 'Written Off';
      default:
        return status?.replaceAll('_', ' ') ?? '—';
    }
  }

  void _openForm({Map<String, dynamic>? item}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _EquipmentFormDialog(
        client: _client,
        item: item,
      ),
    );
    if (result == true && mounted) _load();
  }

  Future<void> _recordService(String id, String notes) async {
    try {
      final row = await _client.from('equipment_register').select('service_log').eq('id', id).maybeSingle();
      List<dynamic> log = [];
      if (row != null && row['service_log'] != null) {
        log = List<dynamic>.from(row['service_log'] as List);
      }
      log.add({'date': DateTime.now().toIso8601String().substring(0, 10), 'notes': notes});
      await _client.from('equipment_register').update({'service_log': log}).eq('id', id);
      try {
        final item = _items.firstWhere(
          (e) => e['id'] == id,
          orElse: () => <String, dynamic>{},
        );
        AuditService.log(
          action: 'UPDATE',
          module: 'Bookkeeping',
          description: 'Service recorded for: ${item['description'] ?? id}',
          entityType: 'Equipment',
          entityId: id,
          newValues: {
            'service_notes': notes,
            'service_date': DateTime.now().toIso8601String().substring(0, 10),
          },
        );
      } catch (_) {}
      if (mounted) _load();
    } catch (e, stack) {
      debugPrint('DATABASE WRITE FAILED: equipment_register service log update');
      debugPrint(e.toString());
      debugPrint(stack.toString());
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Equipment Register', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add equipment'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _items.isEmpty
              ? const Center(child: Text('No equipment registered'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Serial #')),
                        DataColumn(label: Text('Location')),
                        DataColumn(label: Text('Purchase Date')),
                        DataColumn(label: Text('Cost (R)')),
                        DataColumn(label: Text('Current Value (R)')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: SizedBox.shrink()),
                      ],
                      rows: _items.map((r) {
                        final id = r['id'] as String?;
                        final expanded = _expandedId == id;
                        final status = r['status']?.toString() ?? 'active';
                        return DataRow(
                          onSelectChanged: (_) => _openForm(item: r),
                          cells: [
                            DataCell(Text(r['description']?.toString() ?? '—', style: const TextStyle(fontWeight: FontWeight.w500))),
                            DataCell(Text(r['asset_number']?.toString() ?? '—')),
                            DataCell(Text(r['location']?.toString() ?? '—')),
                            DataCell(Text((r['purchase_date']?.toString() ?? '').length >= 10 ? (r['purchase_date'].toString().substring(0, 10)) : '—')),
                            DataCell(Text('${(r['purchase_price'] as num?)?.toStringAsFixed(2) ?? '0.00'}')),
                            DataCell(Text('${_currentValue(r).toStringAsFixed(2)}')),
                            DataCell(Chip(
                              label: Text(_statusDisplayLabel(status), style: const TextStyle(fontSize: 11)),
                              backgroundColor: _statusColor(status).withValues(alpha: 0.2),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            )),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _openForm(item: r),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                                  onPressed: () => setState(() => _expandedId = expanded ? null : id),
                                  tooltip: 'Service log',
                                ),
                              ],
                            )),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
        if (_expandedId != null) ...[
          const Divider(height: 1, color: AppColors.border),
          _buildServiceLogSection(_expandedId!),
        ],
      ],
    );
  }

  Widget _buildServiceLogSection(String id) {
    Map<String, dynamic>? item;
    try {
      item = _items.firstWhere((e) => e['id'] == id);
    } catch (_) {}
    if (item == null) return const SizedBox.shrink();
    final log = item['service_log'];
    List<Map<String, dynamic>> entries = [];
    if (log is List) {
      for (final e in log) {
        if (e is Map) entries.add(Map<String, dynamic>.from(e));
      }
    }
    entries.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surfaceBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Service log', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: () async {
                  final notes = await showDialog<String>(
                    context: context,
                    builder: (ctx) {
                      final ctrl = TextEditingController();
                      return AlertDialog(
                        title: const Text('Record service'),
                        content: TextField(
                          controller: ctrl,
                          decoration: const InputDecoration(labelText: 'Notes'),
                          maxLines: 3,
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                            child: const Text('Save'),
                          ),
                        ],
                      );
                    },
                  );
                  if (notes != null && notes.isNotEmpty) await _recordService(id, notes);
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Record service'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            const Text('No service entries', style: TextStyle(color: AppColors.textSecondary))
          else
            ...entries.take(20).map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 100, child: Text((e['date'] ?? '').toString(), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                      Expanded(child: Text((e['notes'] ?? '').toString(), style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

class _EquipmentFormDialog extends StatefulWidget {
  final dynamic client;
  final Map<String, dynamic>? item;

  const _EquipmentFormDialog({required this.client, this.item});

  @override
  State<_EquipmentFormDialog> createState() => _EquipmentFormDialogState();
}

class _EquipmentFormDialogState extends State<_EquipmentFormDialog> {
  final _nameController = TextEditingController();
  final _serialController = TextEditingController();
  final _locationController = TextEditingController();
  final _purchaseDateController = TextEditingController();
  final _priceController = TextEditingController();
  final _rateController = TextEditingController();
  /// DB: straight_line, declining_balance, diminishing
  String _method = 'straight_line';
  String _status = 'active';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      _nameController.text = item['description']?.toString() ?? '';
      _serialController.text = item['asset_number']?.toString() ?? '';
      _locationController.text = item['location']?.toString() ?? '';
      _purchaseDateController.text = (item['purchase_date']?.toString() ?? '').substring(0, 10);
      _priceController.text = (item['purchase_price'] as num?)?.toString() ?? '';
      _rateController.text = (item['depreciation_rate'] as num?)?.toString() ?? '';
      _method = item['depreciation_method']?.toString() ?? 'straight_line';
      _status = item['status']?.toString() ?? 'active';
    } else {
      _purchaseDateController.text = DateTime.now().toIso8601String().substring(0, 10);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serialController.dispose();
    _locationController.dispose();
    _purchaseDateController.dispose();
    _priceController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    final serial = _serialController.text.trim();
    if (serial.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Serial number is required')));
      return;
    }
    final price = double.tryParse(_priceController.text);
    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valid purchase price required')));
      return;
    }
    final rate = double.tryParse(_rateController.text);
    final purchaseDate = _purchaseDateController.text.trim();
    if (purchaseDate.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase date required')));
      return;
    }
    setState(() => _saving = true);
    try {
      final years = (rate != null && rate > 0) ? (100 / rate).round() : 10;
      /// DB values only: straight_line, declining_balance, diminishing
      final method = _method;
      final data = {
        'description': name,
        'asset_number': serial,
        'location': _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        'purchase_date': purchaseDate,
        'purchase_price': price,
        'depreciation_rate': rate,
        'depreciation_method': method,
        'useful_life_years': years,
        'status': _status,
        'category': 'Equipment',
      };
      String? entityId;
      if (widget.item != null) {
        await widget.client
            .from('equipment_register')
            .update(data)
            .eq('id', widget.item!['id']);
        entityId = widget.item!['id'] as String?;
        try {
          AuditService.log(
            action: 'UPDATE',
            module: 'Bookkeeping',
            description: 'Equipment updated: ${data['description']}',
            entityType: 'Equipment',
            entityId: entityId,
            oldValues: {
              'description': widget.item!['description'],
              'status': widget.item!['status'],
              'purchase_price': widget.item!['purchase_price'],
            },
            newValues: {
              'description': data['description'],
              'status': data['status'],
              'purchase_price': data['purchase_price'],
            },
          );
        } catch (_) {}
      } else {
        final result = await widget.client
            .from('equipment_register')
            .insert(data)
            .select('id')
            .single();
        entityId = result['id'] as String?;
        try {
          AuditService.log(
            action: 'CREATE',
            module: 'Bookkeeping',
            description: 'Equipment added: ${data['description']}',
            entityType: 'Equipment',
            entityId: entityId,
            newValues: {
              'description': data['description'],
              'purchase_price': data['purchase_price'],
              'purchase_date': data['purchase_date'],
              'status': data['status'],
            },
          );
        } catch (_) {}
      }
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item != null ? 'Edit equipment' : 'Add equipment'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _serialController,
                decoration: const InputDecoration(labelText: 'Serial number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _purchaseDateController,
                decoration: const InputDecoration(labelText: 'Purchase date (YYYY-MM-DD)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Purchase price (R)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _rateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Depreciation rate %', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              const Align(alignment: Alignment.centerLeft, child: Text('Depreciation method')),
              Row(
                children: [
                  Radio<String>(value: 'straight_line', groupValue: _method, onChanged: (v) => setState(() => _method = v!)),
                  const Text('Straight line'),
                  Radio<String>(value: 'declining_balance', groupValue: _method, onChanged: (v) => setState(() => _method = v!)),
                  const Text('Declining Balance'),
                  Radio<String>(value: 'diminishing', groupValue: _method, onChanged: (v) => setState(() => _method = v!)),
                  const Text('Diminishing'),
                ],
              ),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'under_repair', child: Text('Under Repair')),
                  DropdownMenuItem(value: 'written_off', child: Text('Written Off')),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'active'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save')),
      ],
    );
  }
}
