import 'package:isar/isar.dart';

part 'cached_ledger_entry.g.dart';

@collection
class CachedLedgerEntry {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  late String entryId;
  String? accountId;
  DateTime? entryDate;
  String? description;
  late double debit;
  late double credit;
  String? reference;
  late DateTime cachedAt;

  CachedLedgerEntry();

  factory CachedLedgerEntry.fromSupabase(Map<String, dynamic> row) {
    final c = CachedLedgerEntry();
    c.entryId = row['id']?.toString() ?? '';
    c.accountId = row['account_id']?.toString();
    c.entryDate = row['entry_date'] != null ? DateTime.tryParse(row['entry_date'].toString()) : null;
    c.description = row['description']?.toString();
    c.debit = (row['debit'] as num?)?.toDouble() ?? 0;
    c.credit = (row['credit'] as num?)?.toDouble() ?? 0;
    c.reference = row['reference']?.toString();
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': entryId,
      'account_id': accountId,
      'entry_date': entryDate?.toIso8601String(),
      'description': description,
      'debit': debit,
      'credit': credit,
      'reference': reference,
    };
  }
}
