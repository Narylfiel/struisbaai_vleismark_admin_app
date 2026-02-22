import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../inventory/models/supplier.dart';
import '../../inventory/services/supplier_repository.dart';
import '../models/invoice.dart';
import '../models/invoice_line_item.dart';
import '../services/invoice_repository.dart';

/// Blueprint §9.1: Manual invoice entry — supplier, dates, line items; save as draft.
class InvoiceFormScreen extends StatefulWidget {
  final Invoice? invoice;

  const InvoiceFormScreen({super.key, this.invoice});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
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

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceRepository = InvoiceRepository();
  final _supplierRepository = SupplierRepository();
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
      final suppliers = await _supplierRepository.getSuppliers(activeOnly: true);
      if (widget.invoice != null) {
        final inv = widget.invoice!;
        _invoiceNumberController.text = inv.invoiceNumber;
        _notesController.text = inv.notes ?? '';
        _selectedSupplierId = inv.supplierId;
        _invoiceDate = inv.invoiceDate;
        _dueDate = inv.dueDate;
        _taxAmountController.text = inv.taxAmount.toStringAsFixed(2);
        final items = await _invoiceRepository.getLineItems(inv.id);
        for (final item in items) {
          final row = _LineRow();
          row.description.text = item.description;
          row.quantity.text = item.quantity == item.quantity.roundToDouble()
              ? item.quantity.toInt().toString()
              : item.quantity.toString();
          row.unitPrice.text = item.unitPrice.toStringAsFixed(2);
          _lineRows.add(row);
        }
      } else {
        final nextNum = await _invoiceRepository.nextInvoiceNumber();
        _invoiceNumberController.text = nextNum;
      }
      if (_lineRows.isEmpty) _addLineRow();
      _updateDateDisplays();
      setState(() => _suppliers = suppliers);
    } catch (e) {
      debugPrint('Invoice form load: $e');
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

  Future<void> _saveDraft() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final createdBy = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (createdBy.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to save'), backgroundColor: AppColors.error),
      );
      return;
    }
    final subtotal = _subtotal();
    final taxAmount = _taxAmount();
    final total = _total();
    final lineItems = <InvoiceLineItem>[];
    for (final row in _lineRows) {
      final desc = row.description.text.trim();
      if (desc.isEmpty) continue;
      lineItems.add(InvoiceLineItem(
        id: '',
        invoiceId: '',
        description: desc,
        quantity: double.tryParse(row.quantity.text) ?? 0,
        unitPrice: double.tryParse(row.unitPrice.text) ?? 0,
      ));
    }

    setState(() => _saving = true);
    try {
      if (widget.invoice != null) {
        final inv = widget.invoice!;
        if (inv.status != InvoiceStatus.draft) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Only draft invoices can be edited'), backgroundColor: AppColors.warning),
          );
          return;
        }
        final updated = Invoice(
          id: inv.id,
          invoiceNumber: _invoiceNumberController.text.trim(),
          supplierId: _selectedSupplierId,
          accountId: inv.accountId,
          invoiceDate: _invoiceDate,
          dueDate: _dueDate,
          subtotal: subtotal,
          taxAmount: taxAmount,
          totalAmount: total,
          status: inv.status,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          createdBy: inv.createdBy,
          createdAt: inv.createdAt,
          updatedAt: DateTime.now(),
        );
        await _invoiceRepository.update(updated);
        await _invoiceRepository.saveLineItems(inv.id, lineItems);
      } else {
        await _invoiceRepository.create(
          invoiceNumber: _invoiceNumberController.text.trim(),
          supplierId: _selectedSupplierId,
          accountId: null,
          invoiceDate: _invoiceDate,
          dueDate: _dueDate,
          subtotal: subtotal,
          taxAmount: taxAmount,
          totalAmount: total,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          createdBy: createdBy,
          lineItems: lineItems.isEmpty ? null : lineItems,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice saved as draft'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context, true);
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

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

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
    final isEditing = widget.invoice != null;
    final canEdit = !isEditing || widget.invoice!.status == InvoiceStatus.draft;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit invoice' : 'Add invoice (manual)'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: FormWidgets.textFormField(
                      label: 'Invoice number',
                      controller: _invoiceNumberController,
                      hint: 'e.g. INV-20250222-001',
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      enabled: canEdit,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FormWidgets.dropdownFormField<String>(
                      label: 'Supplier',
                      value: _selectedSupplierId,
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('— Select supplier —')),
                        ..._suppliers.map((s) => DropdownMenuItem<String>(value: s.id, child: Text(s.name))),
                      ],
                      onChanged: (v) { if (canEdit) setState(() => _selectedSupplierId = v); },
                      enabled: canEdit,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: FormWidgets.textFormField(
                      label: 'Invoice date',
                      controller: _invoiceDateController,
                      hint: 'Select date',
                      enabled: false,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FormWidgets.textFormField(
                      label: 'Due date',
                      controller: _dueDateController,
                      hint: 'Select date',
                      enabled: false,
                    ),
                  ),
                ],
              ),
              if (canEdit)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _invoiceDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              _invoiceDate = picked;
                              _updateDateDisplays();
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text('Set invoice date'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dueDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              _dueDate = picked;
                              _updateDateDisplays();
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text('Set due date'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              const Text('Line items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Container(
                      color: AppColors.surfaceBg,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          const Expanded(flex: 3, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          SizedBox(width: 100, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                          SizedBox(width: 100, child: Text('Unit price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    ...List.generate(_lineRows.length, (i) {
                      final row = _lineRows[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: FormWidgets.textFormField(
                                label: '',
                                controller: row.description,
                                hint: 'Item description',
                                enabled: canEdit,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 100,
                              child: FormWidgets.textFormField(
                                label: '',
                                controller: row.quantity,
                                hint: '1',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
                                enabled: canEdit,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 100,
                              child: FormWidgets.textFormField(
                                label: '',
                                controller: row.unitPrice,
                                hint: '0.00',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
                                enabled: canEdit,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: canEdit && _lineRows.length > 1 ? () => _removeLineRow(i) : null,
                              icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                              tooltip: 'Remove line',
                            ),
                          ],
                        ),
                      );
                    }),
                    if (canEdit)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _addLineRow,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add line'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FormWidgets.textFormField(
                label: 'Tax amount (e.g. VAT)',
                controller: _taxAmountController,
                hint: '0',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
                enabled: canEdit,
              ),
              const SizedBox(height: 16),
              Card(
                color: AppColors.surfaceBg,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Subtotal: R ${_subtotal().toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 24),
                      Text('Tax: R ${_taxAmount().toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 24),
                      Text('Total: R ${_total().toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              if (canEdit) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: FormWidgets.textFormField(
                        label: 'Notes',
                        controller: _notesController,
                        hint: 'Optional notes',
                        maxLines: 2,
                        enabled: canEdit,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _saveDraft,
                      icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save, size: 18),
                      label: Text(_saving ? 'Saving…' : 'Save as draft'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
