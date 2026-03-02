import 'package:isar/isar.dart';

part 'cached_customer.g.dart';

@collection
class CachedCustomer {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  late String customerId;
  late String name;
  String? phone;
  String? email;
  String? notes;
  String? tags;
  late DateTime cachedAt;

  CachedCustomer();

  factory CachedCustomer.fromSupabase(Map<String, dynamic> row) {
    final c = CachedCustomer();
    c.customerId = row['id']?.toString() ?? '';
    c.name = row['name']?.toString() ?? '';
    c.phone = row['phone']?.toString();
    c.email = row['email']?.toString();
    c.notes = row['notes']?.toString();
    if (row['tags'] != null) c.tags = row['tags'] is String ? row['tags'] as String : row['tags'].toString();
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  Map<String, dynamic> toMap() => {'id': customerId, 'name': name, 'phone': phone, 'email': email, 'notes': notes, 'tags': tags};
}
