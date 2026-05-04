import '../../../core/models/base_model.dart';

/// Blueprint §4.6: Supplier Management — Name, Contact Person, Phone, Email, Address, Payment Terms, BBBEE Level, Active.
/// `supplier_type`: DB `supplier_type` — stock | service | utilities | rent | mixed.
class Supplier extends BaseModel {
  final String name;
  /// Maps to `supplier_type`: controls invoice mapping behaviour (Phase 1+).
  final String supplierType;
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
    this.supplierType = 'stock',
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

  /// DB columns: id, name, supplier_type, contact_name, phone, email, account_number, notes, is_active, created_at, updated_at, vat_number, address, city, postal_code, payment_terms, bank_name, bank_account, bank_branch_code, bbbee_level.
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'supplier_type': supplierType,
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
    final rawType = json['supplier_type']?.toString().trim();
    return Supplier(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      supplierType:
          (rawType != null && rawType.isNotEmpty) ? rawType : 'stock',
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

  Supplier copyWith({
    String? id,
    String? name,
    String? supplierType,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? paymentTerms,
    String? bbbeeLevel,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      supplierType: supplierType ?? this.supplierType,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      bbbeeLevel: bbbeeLevel ?? this.bbbeeLevel,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
