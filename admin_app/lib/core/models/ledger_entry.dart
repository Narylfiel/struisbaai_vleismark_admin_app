import 'base_model.dart';

/// Blueprint §9: ledger_entries as single financial truth.
/// Each row is one leg of double-entry: date, account, debit/credit, reference, source.
class LedgerEntry extends BaseModel {
  final DateTime entryDate;
  final String accountCode;
  final String accountName;
  final double debit;
  final double credit;
  final String description;
  final String? referenceType;
  final String? referenceId;
  final String? source;
  final Map<String, dynamic>? metadata;
  final String recordedBy;

  const LedgerEntry({
    required super.id,
    required this.entryDate,
    required this.accountCode,
    required this.accountName,
    this.debit = 0,
    this.credit = 0,
    this.description = '',
    this.referenceType,
    this.referenceId,
    this.source,
    this.metadata,
    required this.recordedBy,
    super.createdAt,
    super.updatedAt,
  });

  /// Single amount: positive = debit, negative = credit (for convenience).
  double get amount => debit > 0 ? debit : -credit;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entry_date': entryDate.toIso8601String().substring(0, 10),
      'account_code': accountCode,
      'account_name': accountName,
      'debit': debit,
      'credit': credit,
      'description': description,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'source': source,
      'metadata': metadata,
      'recorded_by': recordedBy,
    };
  }

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      id: json['id'] as String,
      entryDate: json['entry_date'] != null
          ? DateTime.parse(json['entry_date'] as String)
          : DateTime.now(),
      accountCode: json['account_code'] as String? ?? '',
      accountName: json['account_name'] as String? ?? '',
      debit: (json['debit'] as num?)?.toDouble() ?? 0,
      credit: (json['credit'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String? ?? '',
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
      source: json['source'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      recordedBy: json['recorded_by'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  bool validate() {
    return accountCode.isNotEmpty && recordedBy.isNotEmpty && (debit >= 0 && credit >= 0);
  }

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (accountCode.isEmpty) errors.add('Account code is required');
    if (recordedBy.isEmpty) errors.add('Recorded by is required');
    if (debit < 0 || credit < 0) errors.add('Debit and credit must be non-negative');
    return errors;
  }
}
