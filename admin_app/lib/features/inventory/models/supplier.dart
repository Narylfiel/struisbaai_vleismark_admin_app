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

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contact_person': contactPerson,
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
      contactPerson: json['contact_person'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      paymentTerms: json['payment_terms'] as String?,
      bbbeeLevel: json['bbbee_level'] as String?,
      isActive: json['is_active'] as bool? ?? true,
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
