import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';

/// Repository for bank reconciliation — Phase 1 (manual entry).
/// Handles bank_transactions and bank_reconciliation_matches tables.
class BankReconciliationRepository {
  final SupabaseClient _client;

  BankReconciliationRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  // ── Bank Transactions ─────────────────────────────────────────

  /// Load all bank transactions ordered by post_date desc.
  Future<List<Map<String, dynamic>>> getTransactions({
    String? status,
    DateTime? from,
    DateTime? to,
  }) async {
    // Filters must be applied on PostgrestFilterBuilder,
    // before select() returns a PostgrestTransformBuilder.
    var q = _client
        .from('bank_transactions')
        .select('*, bank_reconciliation_matches(id, match_type, matched_amount, account_code, notes)');

    if (status != null && status.isNotEmpty) {
      q = q.eq('status', status);
    }
    if (from != null) {
      q = q.gte('post_date', from.toIso8601String().substring(0, 10));
    }
    if (to != null) {
      q = q.lte('post_date', to.toIso8601String().substring(0, 10));
    }

    final rows = await q.order('post_date', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Insert a new bank transaction. Returns the created row.
  Future<Map<String, dynamic>> createTransaction({
    required DateTime postDate,
    required DateTime transDate,
    required String description,
    String? reference,
    required double fees,
    required double amount,
    double? balance,
    String? createdBy,
  }) async {
    final row = await _client
        .from('bank_transactions')
        .insert({
          'post_date': postDate.toIso8601String().substring(0, 10),
          'trans_date': transDate.toIso8601String().substring(0, 10),
          'description': description.trim(),
          'reference': reference?.trim(),
          'fees': fees,
          'amount': amount,
          'balance': balance,
          'status': 'unmatched',
          'created_by': createdBy,
        })
        .select()
        .single();
    return Map<String, dynamic>.from(row);
  }

  /// Update status and optional account_code on a transaction.
  Future<void> updateTransactionStatus({
    required String id,
    required String status,
    String? accountCode,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (accountCode != null) payload['account_code'] = accountCode;
    if (notes != null) payload['notes'] = notes;
    await _client
        .from('bank_transactions')
        .update(payload)
        .eq('id', id);
  }

  /// Delete a bank transaction (and its matches via CASCADE).
  Future<void> deleteTransaction(String id) async {
    await _client
        .from('bank_transactions')
        .delete()
        .eq('id', id);
  }

  // ── Matching ──────────────────────────────────────────────────

  /// Create a match between a bank transaction and a system record.
  /// Also updates the bank_transaction status to 'matched' or
  /// 'manually_coded' depending on match_type.
  Future<void> createMatch({
    required String bankTransactionId,
    required String matchType,
    String? matchedRecordId,
    required double matchedAmount,
    required String accountCode,
    String? notes,
    String? createdBy,
  }) async {
    await _client.from('bank_reconciliation_matches').insert({
      'bank_transaction_id': bankTransactionId,
      'match_type': matchType,
      'matched_record_id': matchedRecordId,
      'matched_amount': matchedAmount,
      'account_code': accountCode,
      'notes': notes,
      'created_by': createdBy,
    });

    final newStatus =
        matchType == 'manual' ? 'manually_coded' : 'matched';
    await updateTransactionStatus(
      id: bankTransactionId,
      status: newStatus,
      accountCode: accountCode,
      notes: notes,
    );
  }

  /// Delete a match and reset the bank transaction to 'unmatched'.
  Future<void> deleteMatch({
    required String matchId,
    required String bankTransactionId,
  }) async {
    await _client
        .from('bank_reconciliation_matches')
        .delete()
        .eq('id', matchId);
    await updateTransactionStatus(
      id: bankTransactionId,
      status: 'unmatched',
    );
  }

  // ── Candidate matches ─────────────────────────────────────────

  /// Find supplier invoices whose total is close to [amount]
  /// within [tolerancePct] percent. Returns up to 10 candidates.
  Future<List<Map<String, dynamic>>> findSupplierInvoiceCandidates({
    required double amount,
    double tolerancePct = 5.0,
  }) async {
    final abs = amount.abs();
    final low = abs * (1 - tolerancePct / 100);
    final high = abs * (1 + tolerancePct / 100);
    final rows = await _client
        .from('supplier_invoices')
        .select('id, invoice_number, total, invoice_date, suppliers(name)')
        .gte('total', low)
        .lte('total', high)
        .inFilter('status', ['approved', 'received'])
        .order('invoice_date', ascending: false)
        .limit(10);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Find ledger entries whose debit or credit is close to [amount].
  Future<List<Map<String, dynamic>>> findLedgerCandidates({
    required double amount,
    double tolerancePct = 5.0,
  }) async {
    final abs = amount.abs();
    final low = abs * (1 - tolerancePct / 100);
    final high = abs * (1 + tolerancePct / 100);
    // Check debit side for payments, credit side for receipts
    final field = amount < 0 ? 'debit' : 'credit';
    final rows = await _client
        .from('ledger_entries')
        .select('id, account_code, description, entry_date, debit, credit, reference')
        .gte(field, low)
        .lte(field, high)
        .order('entry_date', ascending: false)
        .limit(10);
    return List<Map<String, dynamic>>.from(rows);
  }

  // ── Summary ───────────────────────────────────────────────────

  /// Returns reconciliation summary counts and totals.
  Future<Map<String, dynamic>> getSummary() async {
    final rows = await _client
        .from('bank_transactions')
        .select('status, amount, fees');

    final all = List<Map<String, dynamic>>.from(rows);

    double totalIn = 0;
    double totalOut = 0;
    double totalFees = 0;
    int matched = 0;
    int unmatched = 0;
    int manuallyCoded = 0;
    int excluded = 0;

    for (final r in all) {
      final amt = (r['amount'] as num?)?.toDouble() ?? 0;
      final fee = (r['fees'] as num?)?.toDouble() ?? 0;
      final status = r['status']?.toString() ?? 'unmatched';

      if (amt > 0) totalIn += amt;
      if (amt < 0) totalOut += amt.abs();
      totalFees += fee.abs();

      switch (status) {
        case 'matched': matched++; break;
        case 'unmatched': unmatched++; break;
        case 'manually_coded': manuallyCoded++; break;
        case 'excluded': excluded++; break;
      }
    }

    return {
      'total': all.length,
      'matched': matched,
      'unmatched': unmatched,
      'manually_coded': manuallyCoded,
      'excluded': excluded,
      'total_in': totalIn,
      'total_out': totalOut,
      'total_fees': totalFees,
    };
  }

  /// Load chart of accounts for the account picker dropdown.
  Future<List<Map<String, dynamic>>> getChartOfAccounts() async {
    final rows = await _client
        .from('chart_of_accounts')
        .select('id, code, name, account_type')
        .order('code');
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Parse a Capitec Business CSV export and return a list of
  /// transaction maps ready for bulk insert.
  ///
  /// Expected columns (in order):
  ///   Post Date, Trans. Date, Description, Reference, Fees, Amount, Balance
  /// Date format: DD/MM/YY
  /// Skips: header row, blank rows, 'Balance brought forward' rows,
  ///        'Fee Total' rows, 'VAT @' rows.
  /// Fees-only rows (Amount blank): uses Fees value as amount.
  List<Map<String, dynamic>> parseCapitecCsv(String csvContent) {
    final lines = csvContent
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final results = <Map<String, dynamic>>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Skip header row
      if (line.toLowerCase().startsWith('post date') ||
          line.toLowerCase().startsWith('post,date')) {
        continue;
      }

      // Parse CSV columns (handle quoted fields)
      final cols = _splitCsvLine(line);
      if (cols.length < 3) continue;

      final description = cols.length > 2 ? cols[2].trim() : '';

      // Skip summary/metadata rows
      if (description.isEmpty) continue;
      if (description.toLowerCase().contains('balance brought forward')) {
        continue;
      }
      if (description.toLowerCase().contains('fee total')) continue;
      if (description.toLowerCase().contains('vat @')) continue;
      if (description.toLowerCase().contains('interest rate')) continue;

      // Parse dates — format DD/MM/YY
      final postDate = _parseCapitecDate(cols[0].trim());
      final transDate = _parseCapitecDate(
          cols.length > 1 ? cols[1].trim() : cols[0].trim());
      if (postDate == null) continue;

      final reference = cols.length > 3 ? cols[3].trim() : null;
      final feesStr = cols.length > 4 ? cols[4].trim() : '';
      final amountStr = cols.length > 5 ? cols[5].trim() : '';
      final balanceStr = cols.length > 6 ? cols[6].trim() : '';

      final fees = double.tryParse(
              feesStr.replaceAll(RegExp(r'[^\d.\-]'), '')) ??
          0.0;
      var amount = double.tryParse(
          amountStr.replaceAll(RegExp(r'[^\d.\-]'), ''));
      final balance = double.tryParse(
          balanceStr.replaceAll(RegExp(r'[^\d.\-]'), ''));

      // Fees-only row: amount blank, use fees value as amount
      if (amount == null && fees != 0) {
        amount = fees;
      }

      // Skip if still no amount
      if (amount == null) continue;

      results.add({
        'post_date': postDate.toIso8601String().substring(0, 10),
        'trans_date': (transDate ?? postDate)
            .toIso8601String()
            .substring(0, 10),
        'description': description,
        'reference': (reference == null || reference.isEmpty)
            ? null
            : reference,
        'fees': fees,
        'amount': amount,
        'balance': balance,
        'status': 'unmatched',
      });
    }

    return results;
  }

  /// Bulk insert parsed CSV rows. Skips rows where the same
  /// post_date + description + amount already exists (dedup).
  /// Returns count of rows inserted.
  Future<int> importCsvRows({
    required List<Map<String, dynamic>> rows,
    required String createdBy,
  }) async {
    if (rows.isEmpty) return 0;

    // Load existing transactions for dedup check
    final existing = await _client
        .from('bank_transactions')
        .select('post_date, description, amount');
    final existingKeys = <String>{};
    for (final e in existing as List) {
      final key =
          '${e['post_date']}_${e['description']}_${e['amount']}';
      existingKeys.add(key);
    }

    final toInsert = <Map<String, dynamic>>[];
    for (final row in rows) {
      final key =
          '${row['post_date']}_${row['description']}_${row['amount']}';
      if (!existingKeys.contains(key)) {
        toInsert.add({...row, 'created_by': createdBy});
      }
    }

    if (toInsert.isEmpty) return 0;

    await _client.from('bank_transactions').insert(toInsert);
    return toInsert.length;
  }

  /// Split a CSV line respecting quoted fields.
  List<String> _splitCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if (c == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(c);
      }
    }
    result.add(buffer.toString());
    return result;
  }

  /// Parse Capitec date format DD/MM/YY.
  DateTime? _parseCapitecDate(String raw) {
    if (raw.isEmpty) return null;
    final parts = raw.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    var year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    // Two-digit year: 00–49 → 2000–2049, 50–99 → 1950–1999
    if (year < 100) year += year < 50 ? 2000 : 1900;
    return DateTime(year, month, day);
  }
}
