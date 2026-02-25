import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../models/supplier.dart';
import '../services/supplier_repository.dart';

/// Blueprint §4.6: Create/Edit Supplier — Name, Contact Person, Phone, Email, Address, Payment Terms, BBBEE Level, Active.
class SupplierFormScreen extends StatefulWidget {
  final Supplier? supplier;

  const SupplierFormScreen({super.key, this.supplier});

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _paymentTermsController = TextEditingController();
  final _bbbeeLevelController = TextEditingController();
  late bool _isActive;
  bool _saving = false;
  final _repo = SupplierRepository();

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      _nameController.text = widget.supplier!.name;
      _contactPersonController.text = widget.supplier!.contactPerson ?? '';
      _phoneController.text = widget.supplier!.phone ?? '';
      _emailController.text = widget.supplier!.email ?? '';
      _addressController.text = widget.supplier!.address ?? '';
      _paymentTermsController.text = widget.supplier!.paymentTerms ?? '';
      _bbbeeLevelController.text = widget.supplier!.bbbeeLevel ?? '';
      _isActive = widget.supplier!.isActive;
    } else {
      _isActive = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _paymentTermsController.dispose();
    _bbbeeLevelController.dispose();
    super.dispose();
  }

  Future<void> _confirmDeleteSupplier(Supplier supplier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete supplier?'),
        content: Text('Delete ${supplier.name}? This cannot be undone.'),
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
      await _repo.deleteSupplier(supplier.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      if (widget.supplier != null) {
        final updated = Supplier(
          id: widget.supplier!.id,
          name: _nameController.text.trim(),
          contactPerson: _contactPersonController.text.trim().isEmpty ? null : _contactPersonController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          paymentTerms: _paymentTermsController.text.trim().isEmpty ? null : _paymentTermsController.text.trim(),
          bbbeeLevel: _bbbeeLevelController.text.trim().isEmpty ? null : _bbbeeLevelController.text.trim(),
          isActive: _isActive,
          createdAt: widget.supplier!.createdAt,
          updatedAt: DateTime.now(),
        );
        await _repo.updateSupplier(updated);
      } else {
        final created = Supplier(
          id: '',
          name: _nameController.text.trim(),
          contactPerson: _contactPersonController.text.trim().isEmpty ? null : _contactPersonController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          paymentTerms: _paymentTermsController.text.trim().isEmpty ? null : _paymentTermsController.text.trim(),
          bbbeeLevel: _bbbeeLevelController.text.trim().isEmpty ? null : _bbbeeLevelController.text.trim(),
          isActive: _isActive,
        );
        await _repo.createSupplier(created);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier saved'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.supplier != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit supplier' : 'Add supplier'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (isEditing && widget.supplier != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDeleteSupplier(widget.supplier!),
              tooltip: 'Delete supplier',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormWidgets.textFormField(
                controller: _nameController,
                label: 'Name',
                hint: 'e.g. Karan Beef',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                prefixIcon: const Icon(Icons.business),
              ),
              const SizedBox(height: 16),
              FormWidgets.textFormField(
                controller: _contactPersonController,
                label: 'Contact person',
                hint: 'e.g. Johan van Wyk',
                prefixIcon: const Icon(Icons.person),
              ),
              const SizedBox(height: 16),
              FormWidgets.textFormField(
                controller: _phoneController,
                label: 'Phone',
                hint: '012 345 6789',
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone),
              ),
              const SizedBox(height: 16),
              FormWidgets.textFormField(
                controller: _emailController,
                label: 'Email',
                hint: 'orders@karanbeef.co.za',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email),
              ),
              const SizedBox(height: 16),
              FormWidgets.textFormField(
                controller: _addressController,
                label: 'Address',
                hint: 'Industrial Park, Pretoria',
                maxLines: 2,
                prefixIcon: const Icon(Icons.location_on),
              ),
              const SizedBox(height: 16),
              FormWidgets.textFormField(
                controller: _paymentTermsController,
                label: 'Payment terms',
                hint: 'COD / 7 days / 14 days / 30 days',
                prefixIcon: const Icon(Icons.payment),
              ),
              const SizedBox(height: 16),
              FormWidgets.textFormField(
                controller: _bbbeeLevelController,
                label: 'BBBEE level',
                hint: 'e.g. Level 2',
                prefixIcon: const Icon(Icons.badge),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                activeColor: AppColors.primary,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _saving
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
