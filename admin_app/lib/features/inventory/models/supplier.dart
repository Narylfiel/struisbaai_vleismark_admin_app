import '../../../core/models/base_model.dart';

/// Blueprint §4.6: Supplier Management — Name, Contact Person, Phone, Email, Address, Payment Terms, BBBEE Level, Active.
class Supplier extends BaseModel {
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final String? paymentTerms;
  final String? bbbeeLevel;
  final bool isActive;

  const Supplier({
    required super.id,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.paymentTerms,
    this.bbbeeLevel,
    this.isActive = true,
    super.createdAt,
    super.updatedAt,
  });

  /// DB columns: id, name, contact_name, phone, email, account_number, notes, is_active, created_at, updated_at, vat_number, address, city, postal_code, payment_terms, bank_name, bank_account, bank_branch_code, bbbee_level.
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contact_name': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'payment_terms': paymentTerms,
      'bbbee_level': bbbeeLevel,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      contactPerson: json['contact_name'] as String? ?? json['contact_person'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      paymentTerms: json['payment_terms'] as String?,
      bbbeeLevel: json['bbbee_level'] as String?,
      isActive: json['is_active'] as bool? ?? json['active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  bool validate() => name.trim().isNotEmpty;

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (name.trim().isEmpty) errors.add('Supplier name is required');
    return errors;
  }
}
