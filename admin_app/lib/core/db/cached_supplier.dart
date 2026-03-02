import 'package:isar/isar.dart';

part 'cached_supplier.g.dart';

/// Isar collection for suppliers cached for offline supplier list.
@collection
class CachedSupplier {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String supplierId;

  late String name;
  String? contactName;
  String? phone;
  String? email;
  String? accountNumber;
  late bool isActive;
  late DateTime cachedAt;

  CachedSupplier();

  /// From Supabase suppliers row (id, name, contact_name, phone, email, account_number, is_active).
  factory CachedSupplier.fromSupabase(Map<String, dynamic> row) {
    final c = CachedSupplier();
    c.supplierId = row['id']?.toString() ?? '';
    c.name = row['name']?.toString() ?? '';
    c.contactName = row['contact_name']?.toString() ?? row['contact_person']?.toString();
    c.phone = row['phone']?.toString();
    c.email = row['email']?.toString();
    c.accountNumber = row['account_number']?.toString();
    c.isActive = row['is_active'] == true || row['is_active'] == 'true' || (row['active'] != false && row['active'] != 'false');
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  /// To Supplier-like map for list screen.
  Map<String, dynamic> toMap() => {
        'id': supplierId,
        'name': name,
        'contact_name': contactName,
        'phone': phone,
        'email': email,
        'account_number': accountNumber,
        'is_active': isActive,
      };
}
