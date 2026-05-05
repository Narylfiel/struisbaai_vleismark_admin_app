import 'package:isar/isar.dart';

part 'cached_business_account.g.dart';

@collection
class CachedBusinessAccount {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  late String accountId;
  late String name;
  String? accountType;
  String? email;
  String? phone;
  late double balance;
  double? creditLimit;
  late bool isActive;
  late DateTime cachedAt;

  CachedBusinessAccount();

  factory CachedBusinessAccount.fromSupabase(Map<String, dynamic> row) {
    final c = CachedBusinessAccount();
    c.accountId = row['id']?.toString() ?? '';
    c.name = row['name']?.toString() ?? '';
    c.accountType = row['account_type']?.toString();
    c.email = row['email']?.toString();
    c.phone = row['phone']?.toString();
    c.balance = (row['balance'] as num?)?.toDouble() ?? 0;
    c.creditLimit = (row['credit_limit'] as num?)?.toDouble();
    c.isActive = row['is_active'] == true;
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': accountId,
      'name': name,
      'account_type': accountType,
      'email': email,
      'phone': phone,
      'balance': balance,
      'credit_limit': creditLimit,
      'is_active': isActive,
    };
  }
}
