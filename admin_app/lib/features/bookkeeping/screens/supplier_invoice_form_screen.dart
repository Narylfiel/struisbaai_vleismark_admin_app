import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../inventory/models/supplier.dart';
import '../../inventory/services/supplier_repository.dart';
import '../models/supplier_invoice.dart';
import '../services/supplier_invoice_repository.dart';

/// Supplier invoice — manual entry; saves to supplier_invoices with line_items jsonb.
class SupplierInvoiceFormScreen extends StatefulWidget {
  final SupplierInvoice? invoice;

  const SupplierInvoiceFormScreen({super.key, this.invoice});

  @override
  State<SupplierInvoiceFormScreen> createState() => _SupplierInvoiceFormScreenState();
}

class _LineRow {
  final TextEditingController description = TextEditingController();
  final TextEditingController quantity = TextEditingController(text: '1');
  final TextEditingController unitPrice = TextEditingController(text: '0');

  void dispose() {
    description.dispose();
    quantity.dispose();
    unitPrice.dispose();
  }
}

class _SupplierInvoiceFormScreenState extends State<SupplierInvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = SupplierInvoiceRepository();
  final _supplierRepo = SupplierRepository();
  final _invoiceNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final _taxAmountController = TextEditingController(text: '0');
  final _invoiceDateController = TextEditingController();
  final _dueDateController = TextEditingController();

  List<Supplier> _suppliers = [];
  String? _selectedSupplierId;
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now();
  final List<_LineRow> _lineRows = [];
  bool _loading = true;
  bool _saving = false;

  void _updateDateDisplays() {
    _invoiceDateController.text = _formatDate(_invoiceDate);
    _dueDateController.text = _formatDate(_dueDate);
  }

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    try {
      final suppliers = await _supplierRepo.getSuppliers(activeOnly: true);
      if (widget.invoice != null) {
        final inv = widget.invoice!;
        _invoiceNumberController.text = inv.invoiceNumber;
        _notesController.text = inv.notes ?? '';
        _selectedSupplierId = inv.supplierId;
        _invoiceDate = inv.invoiceDate;
        _dueDate = inv.dueDate;
        _taxAmountController.text = inv.taxAmount.toStringAsFixed(2);
        for (final item in inv.lineItems) {
          final row = _LineRow();
          row.description.text = item['description']?.toString() ?? '';
          row.quantity.text = (item['quantity'] as num?)?.toString() ?? '1';
          row.unitPrice.text = (item['unit_price'] as num?)?.toStringAsFixed(2) ?? '0';
          _lineRows.add(row);
        }
      } else {
        final nextNum = await _repo.nextInvoiceNumber();
        _invoiceNumberController.text = nextNum;
      }
      if (_lineRows.isEmpty) _addLineRow();
      _updateDateDisplays();
      setState(() => _suppliers = suppliers);
    } catch (e) {
      debugPrint('Supplier invoice form load: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Load failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addLineRow() {
    setState(() => _lineRows.add(_LineRow()));
  }

  void _removeLineRow(int index) {
    if (_lineRows.length <= 1) return;
    _lineRows[index].dispose();
    setState(() => _lineRows.removeAt(index));
  }

  double _subtotal() {
    double sum = 0;
    for (final row in _lineRows) {
      final q = double.tryParse(row.quantity.text) ?? 0;
      final p = double.tryParse(row.unitPrice.text) ?? 0;
      sum += q * p;
    }
    return sum;
  }

  double _taxAmount() => double.tryParse(_taxAmountController.text) ?? 0;

  double _total() => _subtotal() + _taxAmount();

  List<Map<String, dynamic>> _buildLineItems() {
    final items = <Map<String, dynamic>>[];
    for (final row in _lineRows) {
      final desc = row.description.text.trim();
      if (desc.isEmpty) continue;
      items.add({
        'description': desc,
        'quantity': double.tryParse(row.quantity.text) ?? 0,
        'unit_price': double.tryParse(row.unitPrice.text) ?? 0,
      });
    }
    return items;
  }

  Future<void> _saveDraft() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final createdBy = AuthService().getCurrentStaffId();
    if (createdBy.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in with PIN to save invoices'), backgroundColor: AppColors.error),
      );
      return;
    }
    final subtotal = _subtotal();
    final taxAmount = _taxAmount();
    final total = _total();
    final lineItems = _buildLineItems();

    setState(() => _saving = true);
    try {
      if (widget.invoice != null) {
        final inv = widget.invoice!;
        if (inv.status != SupplierInvoiceStatus.draft) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Only draft invoices can be edited'), backgroundColor: AppColors.warning),
          );
          return;
        }
        final updated = SupplierInvoice(
          id: inv.id,
          invoiceNumber: _invoiceNumberController.text.trim(),
          supplierId: _selectedSupplierId,
          invoiceDate: _invoiceDate,
          dueDate: _dueDate,
          lineItems: lineItems,
          subtotal: subtotal,
          taxAmount: taxAmount,
          total: total,
          status: inv.status,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          createdBy: inv.createdBy,
          createdAt: inv.createdAt,
          updatedAt: DateTime.now(),
        );
        await _repo.update(updated);
      } else {
        final created = SupplierInvoice(
          id: '',
          invoiceNumber: _invoiceNumberController.text.trim(),
          supplierId: _selectedSupplierId,
          invoiceDate: _invoiceDate,
          dueDate: _dueDate,
          lineItems: lineItems,
          subtotal: subtotal,
          taxAmount: taxAmount,
          total: total,
          status: SupplierInvoiceStatus.draft,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          createdBy: createdBy,
        );
        await _repo.create(created);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _notesController.dispose();
    _taxAmountController.dispose();
    _invoiceDateController.dispose();
    _dueDateController.dispose();
    for (final row in _lineRows) row.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoice != null ? 'Edit supplier invoice' : 'New supplier invoice'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _invoiceNumberController,
                      decoration: const InputDecoration(labelText: 'Invoice number'),
                      validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSupplierId,
                      decoration: const InputDecoration(labelText: 'Supplier'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('— None —')),
                        ..._suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                      ],
                      onChanged: (v) => setState(() => _selectedSupplierId = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _invoiceDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d != null) setState(() { _invoiceDate = d; _updateDateDisplays(); });
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _invoiceDateController,
                          decoration: const InputDecoration(labelText: 'Invoice date'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _dueDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d != null) setState(() { _dueDate = d; _updateDateDisplays(); });
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _dueDateController,
                          decoration: const InputDecoration(labelText: 'Due date'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Line items', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...List.generate(_lineRows.length, (i) {
                final row = _lineRows[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: row.description,
                          decoration: const InputDecoration(labelText: 'Description', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          controller: row.quantity,
                          decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: TextFormField(
                          controller: row.unitPrice,
                          decoration: const InputDecoration(labelText: 'Unit price', isDense: true),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      if (_lineRows.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
                          onPressed: () => _removeLineRow(i),
                        ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: _addLineRow,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add line'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _taxAmountController,
                decoration: const InputDecoration(labelText: 'Tax amount'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              Text('Subtotal: R ${_subtotal().toStringAsFixed(2)} | Tax: R ${_taxAmount().toStringAsFixed(2)} | Total: R ${_total().toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveDraft,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _saving
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save draft'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
