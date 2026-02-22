import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../models/supplier.dart';
import '../services/supplier_repository.dart';
import 'supplier_form_screen.dart';

/// Blueprint §4.6: Supplier Management — list suppliers, Add/Edit/Delete.
class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  final _repo = SupplierRepository();
  List<Supplier> _suppliers = [];
  bool _loading = true;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.getSuppliers();
      if (mounted) {
        setState(() {
          _suppliers = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _navigateToForm({Supplier? supplier}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierFormScreen(supplier: supplier),
      ),
    ).then((result) {
      if (result == true) _load();
    });
  }

  Future<void> _confirmDelete(Supplier supplier) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete supplier'),
        content: Text('Delete "${supplier.name}"?'),
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
    if (ok != true || !mounted) return;
    try {
      await _repo.deleteSupplier(supplier.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Supplier deleted'), backgroundColor: AppColors.success),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              'Error loading suppliers',
              style: const TextStyle(color: AppColors.danger, fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_suppliers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_shipping, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Suppliers',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add suppliers (e.g. Karan Beef). Link them to products in the product form.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add supplier'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(child: SizedBox()),
              ElevatedButton.icon(
                onPressed: () => _navigateToForm(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add supplier'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Contact')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Payment terms')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _suppliers.map((s) {
                  return DataRow(
                    cells: [
                      DataCell(Text(s.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Text(s.contactPerson ?? '—', style: const TextStyle(fontSize: 12))),
                      DataCell(Text(s.phone ?? '—', style: const TextStyle(fontSize: 12))),
                      DataCell(Text(s.email ?? '—', style: const TextStyle(fontSize: 12))),
                      DataCell(Text(s.paymentTerms ?? '—', style: const TextStyle(fontSize: 12))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: s.isActive ? AppColors.success : AppColors.danger,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            s.isActive ? 'Active' : 'Inactive',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      DataCell(
                        ActionButtonsWidget(
                          actions: [
                            ActionButtons.edit(onPressed: () => _navigateToForm(supplier: s), iconOnly: true),
                            ActionButtons.delete(onPressed: () => _confirmDelete(s), iconOnly: true),
                          ],
                          compact: true,
                          spacing: 8,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
