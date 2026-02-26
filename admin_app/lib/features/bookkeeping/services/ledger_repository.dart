import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/audit_service.dart';
import '../../../core/models/ledger_entry.dart';

/// Blueprint §9: ledger_entries as single financial truth.
/// Every financial event (POS sale, invoice, payment received, waste, donation) must create ledger entries.
class LedgerRepository {
  final SupabaseClient _client;

  LedgerRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Create a single ledger entry (one leg of double-entry). Call twice for full double-entry.
  Future<LedgerEntry> createEntry({
    required DateTime date,
    required String accountCode,
    required String accountName,
    required double debit,
    required double credit,
    required String description,
    String? referenceType,
    String? referenceId,
    String? source,
    Map<String, dynamic>? metadata,
    required String recordedBy,
  }) async {
    if (debit < 0 || credit < 0) {
      throw ArgumentError('Debit and credit must be non-negative');
    }
    final row = {
      'entry_date': date.toIso8601String().substring(0, 10),
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
    final response = await _client
        .from('ledger_entries')
        .insert(row)
        .select()
        .single();
    return LedgerEntry.fromJson(response as Map<String, dynamic>);
  }

  /// Create both legs of a double-entry in one call (same reference_id/source).
  Future<void> createDoubleEntry({
    required DateTime date,
    required String debitAccountCode,
    required String debitAccountName,
    required String creditAccountCode,
    required String creditAccountName,
    required double amount,
    required String description,
    String? referenceType,
    String? referenceId,
    String? source,
    Map<String, dynamic>? metadata,
    required String recordedBy,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Amount must be positive');
    }
    await createEntry(
      date: date,
      accountCode: debitAccountCode,
      accountName: debitAccountName,
      debit: amount,
      credit: 0,
      description: description,
      referenceType: referenceType,
      referenceId: referenceId,
      source: source,
      metadata: metadata,
      recordedBy: recordedBy,
    );
    await createEntry(
      date: date,
      accountCode: creditAccountCode,
      accountName: creditAccountName,
      debit: 0,
      credit: amount,
      description: description,
      referenceType: referenceType,
      referenceId: referenceId,
      source: source,
      metadata: metadata,
      recordedBy: recordedBy,
    );
    
    // Audit log - ledger entry posted
    await AuditService.log(
      action: 'CREATE',
      module: 'Bookkeeping',
      description: 'Ledger entry posted: $description - DR $debitAccountCode / CR $creditAccountCode R${amount.toStringAsFixed(2)}',
      entityType: 'LedgerEntry',
      entityId: referenceId,
    );
  }

  /// Get all ledger entries in a date range (for P&L, VAT, cash flow).
  Future<List<LedgerEntry>> getEntriesByDate(
    DateTime start,
    DateTime end,
  ) async {
    final startStr = start.toIso8601String().substring(0, 10);
    final endStr = end.toIso8601String().substring(0, 10);
    final response = await _client
        .from('ledger_entries')
        .select()
        .gte('entry_date', startStr)
        .lte('entry_date', endStr)
        .order('entry_date', ascending: true)
        .order('created_at', ascending: true);
    final list = List<Map<String, dynamic>>.from(response);
    return list.map((e) => LedgerEntry.fromJson(e)).toList();
  }

  /// Get entries by source (event type): pos_sale, invoice, payment_received, waste, donation, etc.
  Future<List<LedgerEntry>> getByType(String source) async {
    final response = await _client
        .from('ledger_entries')
        .select()
        .eq('source', source)
        .order('entry_date', ascending: false)
        .order('created_at', ascending: false)
        .limit(500);
    final list = List<Map<String, dynamic>>.from(response);
    return list.map((e) => LedgerEntry.fromJson(e)).toList();
  }

  /// Get entries by account code in date range (for account balance / VAT 2100).
  Future<List<LedgerEntry>> getEntriesByAccount(
    String accountCode,
    DateTime start,
    DateTime end,
  ) async {
    final startStr = start.toIso8601String().substring(0, 10);
    final endStr = end.toIso8601String().substring(0, 10);
    final response = await _client
        .from('ledger_entries')
        .select()
        .eq('account_code', accountCode)
        .gte('entry_date', startStr)
        .lte('entry_date', endStr)
        .order('entry_date', ascending: true);
    final list = List<Map<String, dynamic>>.from(response);
    return list.map((e) => LedgerEntry.fromJson(e)).toList();
  }

  /// P&L summary from ledger: sums by account_code for a period (revenue = credit side of income, COGS/expense = debit side).
  /// Returns map: account_code -> { debitTotal, creditTotal, net }.
  Future<Map<String, Map<String, double>>> getPnLSummary(
    DateTime start,
    DateTime end,
  ) async {
    final entries = await getEntriesByDate(start, end);
    final map = <String, Map<String, double>>{};
    for (final e in entries) {
      map.putIfAbsent(
        e.accountCode,
        () => {'debit': 0, 'credit': 0, 'net': 0},
      );
      map[e.accountCode]!['debit'] =
          (map[e.accountCode]!['debit']! + e.debit);
      map[e.accountCode]!['credit'] =
          (map[e.accountCode]!['credit']! + e.credit);
      map[e.accountCode]!['net'] =
          map[e.accountCode]!['credit']! - map[e.accountCode]!['debit']!;
    }
    return map;
  }

  /// VAT summary: output VAT (sales), input VAT (purchases), payable. Account 2100 = VAT Payable; credit = output, debit = input.
  Future<({double outputVat, double inputVat, double payable})> getVatSummary(
    DateTime start,
    DateTime end,
  ) async {
    final entries = await getEntriesByAccount('2100', start, end);
    double outputVat = 0;
    double inputVat = 0;
    for (final e in entries) {
      outputVat += e.credit;
      inputVat += e.debit;
    }
    final payable = outputVat - inputVat;
    return (outputVat: outputVat, inputVat: inputVat, payable: payable);
  }

  /// CoA balances derived from ledger_entries (Phase 4: single source of truth).
  /// Returns map: account_code -> balance (debit - credit; positive = asset/debit balance).
  Future<Map<String, double>> getAccountBalancesToDate(DateTime asOfDate) async {
    final endStr = asOfDate.toIso8601String().substring(0, 10);
    final response = await _client
        .from('ledger_entries')
        .select('account_code, debit, credit')
        .lte('entry_date', endStr);
    final map = <String, double>{};
    for (final row in response as List) {
      final code = row['account_code'] as String? ?? '';
      final debit = (row['debit'] as num?)?.toDouble() ?? 0;
      final credit = (row['credit'] as num?)?.toDouble() ?? 0;
      map[code] = (map[code] ?? 0) + debit - credit;
    }
    return map;
  }

  /// Cash flow summary: movements on 1000 (Cash) and 1100 (Bank) in period.
  Future<({double cashIn, double cashOut, double bankIn, double bankOut})> getCashFlowSummary(
    DateTime start,
    DateTime end,
  ) async {
    final entries = await getEntriesByDate(start, end);
    double cashIn = 0, cashOut = 0, bankIn = 0, bankOut = 0;
    for (final e in entries) {
      if (e.accountCode == '1000') {
        cashIn += e.debit;
        cashOut += e.credit;
      } else if (e.accountCode == '1100') {
        bankIn += e.debit;
        bankOut += e.credit;
      }
    }
    return (cashIn: cashIn, cashOut: cashOut, bankIn: bankIn, bankOut: bankOut);
  }

  /// Monthly cash flow for chart: returns list of {month, label, cashIn, cashOut, bankIn, bankOut, totalIn, totalOut, net}.
  Future<List<Map<String, dynamic>>> getCashFlowByMonth(int monthCount) async {
    final now = DateTime.now();
    final months = <Map<String, dynamic>>[];
    for (var i = monthCount - 1; i >= 0; i--) {
      final y = now.year;
      final m = now.month - i;
      int year = y;
      int month = m;
      if (m < 1) {
        year = y - 1;
        month = m + 12;
      }
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 0);
      final cf = await getCashFlowSummary(start, end);
      final totalIn = cf.cashIn + cf.bankIn;
      final totalOut = cf.cashOut + cf.bankOut;
      months.add({
        'month': '$year-${month.toString().padLeft(2, '0')}',
        'label': _monthLabel(month),
        'cashIn': cf.cashIn,
        'cashOut': cf.cashOut,
        'bankIn': cf.bankIn,
        'bankOut': cf.bankOut,
        'totalIn': totalIn,
        'totalOut': totalOut,
        'net': totalIn - totalOut,
      });
    }
    return months;
  }

  static String _monthLabel(int m) {
    const names = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return names[m - 1];
  }
}
