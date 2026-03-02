import 'package:isar/isar.dart';

part 'cached_invoice.g.dart';

@collection
class CachedInvoice {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  late String invoiceId;
  late String invoiceNumber;
  String? accountId;
  String? accountName;
  DateTime? invoiceDate;
  DateTime? dueDate;
  late double total;
  String? status;
  late DateTime cachedAt;

  CachedInvoice();

  factory CachedInvoice.fromSupabase(Map<String, dynamic> row) {
    final c = CachedInvoice();
    c.invoiceId = row['id']?.toString() ?? '';
    c.invoiceNumber = row['invoice_number']?.toString() ?? '';
    c.accountId = row['account_id']?.toString();
    c.accountName = row['account_name']?.toString();
    c.invoiceDate = row['invoice_date'] != null ? DateTime.tryParse(row['invoice_date'].toString()) : null;
    c.dueDate = row['due_date'] != null ? DateTime.tryParse(row['due_date'].toString()) : null;
    c.total = (row['total'] as num?)?.toDouble() ?? 0;
    c.status = row['status']?.toString();
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': invoiceId,
      'invoice_number': invoiceNumber,
      'account_id': accountId,
      'account_name': accountName,
      'invoice_date': invoiceDate?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'total': total,
      'status': status,
    };
  }
}
