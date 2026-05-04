import 'package:intl/intl.dart';
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
  ///   Account, Date, Description, Reference, Amount, Fees, Balance
  /// Date format: DD/MM/YYYY (4-digit year)
  /// Skips: 'Balance brought forward', 'Total:', 'Account,' header row,
  ///        blank rows.
  /// Fees-only rows (Amount=0.00): uses Fees value as amount.
  List<Map<String, dynamic>> parseCapitecCsv(String csvContent) {
    final lines = csvContent.split('\n');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final results = <Map<String, dynamic>>[];

    for (final line in lines) {
      final trimmed = line.trim();

      // Skip blank rows
      if (trimmed.isEmpty) continue;

      // Skip metadata rows
      if (trimmed.startsWith('Balance brought forward')) continue;
      if (trimmed.startsWith('Total:')) continue;
      if (trimmed.startsWith('Account,')) continue;

      // Parse CSV columns (handle quoted fields)
      final cols = _splitCsvLine(trimmed);
      if (cols.length < 7) continue;

      // Column mapping:
      // [0] Account → ignore
      // [1] Date → post_date & trans_date
      // [2] Description → description
      // [3] Reference → reference
      // [4] Amount → amount
      // [5] Fees → fees
      // [6] Balance → balance

      final rawDateStr = cols[1].trim();
      final description = cols[2].trim();
      final reference = cols[3].trim();
      final amountStr = cols[4].trim();
      final feesStr = cols[5].trim();
      final balanceStr = cols[6].trim();

      // Skip if description is empty
      if (description.isEmpty) continue;

      // Parse date — format DD/MM/YYYY
      DateTime? parsedDate;
      try {
        parsedDate = dateFormat.parse(rawDateStr);
      } catch (_) {
        continue;
      }
      if (parsedDate == null) continue;

      final dateStr = parsedDate.toIso8601String().substring(0, 10);

      // Parse amounts (already signed in CSV)
      final amount = double.tryParse(
          amountStr.replaceAll(RegExp(r'[^\d.\-]'), ''));
      final fees = double.tryParse(
          feesStr.replaceAll(RegExp(r'[^\d.\-]'), '')) ?? 0.0;
      final balance = double.tryParse(
          balanceStr.replaceAll(RegExp(r'[^\d.\-]'), ''));

      // Fee-only row: amount == 0.0 && fees != 0.0, use fees as amount
      final finalAmount = (amount == 0.0 && fees != 0.0) ? fees : amount;

      // Skip if still no amount
      if (finalAmount == null) continue;

      // Auto-coding rules (priority order: 1-7, first match wins)
      String? accountCode;
      String? notes;
      String status = 'unmatched';

      final descLower = description.toLowerCase();
      final refLower = reference.toLowerCase();

      // Rule 1: Bank charges (auto-code + auto-status)
      if (descLower.contains('month s/fee') ||
          descLower.contains('sms notification fee') ||
          descLower.contains('cash fee') ||
          refLower.contains('service fee') ||
          refLower.contains('notification fee')) {
        accountCode = '6400';
        notes = 'Bank charge — auto-coded';
        status = 'manually_coded';
      }
      // Rule 2: Old POS software fee (Willow)
      else if (refLower.contains('willow') && descLower.contains('debit order')) {
        accountCode = '6300';
        notes = 'Old POS system fee (Willow) — auto-coded';
        status = 'manually_coded';
      }
      // Rule 3: POS card settlements (flag only)
      else if (refLower.contains('possettle') && finalAmount > 0) {
        accountCode = null;
        notes = 'Capitec card settlement — match to till session';
        status = 'unmatched';
      }
      // Rule 4: Business account payments (flag only)
      else if ((descLower.contains('retail cr transfer') ||
                descLower.contains('cr trf') ||
                descLower.contains('inward eft credit')) &&
          finalAmount > 0 &&
          !refLower.contains('possettle')) {
        accountCode = '1100';
        notes = 'Business account payment received — verify customer';
        status = 'unmatched';
      }
      // Rule 5: Supplier payments (flag only)
      else if ((refLower.contains('elim slaghuis') ||
                refLower.contains('ice box') ||
                refLower.contains('primal masters') ||
                refLower.contains('crown national') ||
                refLower.contains('avocet scales') ||
                refLower.contains('cape agulhas sanitation') ||
                refLower.contains('mat overberg') ||
                refLower.contains('charlies transport')) &&
          finalAmount < 0) {
        accountCode = '5000';
        notes = 'Supplier payment — match to invoice';
        status = 'unmatched';
      }
      // Rule 6: Salary payments (flag only)
      else if ((refLower.contains('sbvm salary') || refLower.contains('salary')) &&
          finalAmount < 0) {
        accountCode = '6000';
        notes = 'Salary payment — match to payroll ledger';
        status = 'unmatched';
      }
      // Rule 7: Directors loan (flag only)
      else if ((refLower.contains('directors loan') ||
                refLower.contains('directors loan acc') ||
                refLower.contains('directods loan')) &&
          finalAmount < 0) {
        accountCode = '2400';
        notes = 'Directors loan withdrawal — verify with accountant';
        status = 'unmatched';
      }

      results.add({
        'post_date': dateStr,
        'trans_date': dateStr,
        'description': description,
        'reference': (reference.isEmpty) ? null : reference,
        'fees': fees,
        'amount': finalAmount,
        'balance': balance,
        'account_code': accountCode,
        'notes': notes,
        'status': status,
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
}
