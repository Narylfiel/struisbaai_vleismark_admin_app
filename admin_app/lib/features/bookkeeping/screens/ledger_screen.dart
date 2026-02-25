import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/auth_service.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/export_service.dart';
import 'package:admin_app/core/models/ledger_entry.dart';
import 'package:admin_app/features/bookkeeping/services/ledger_repository.dart';

/// H6: Ledger screen — date range + account filter, table, New Journal Entry, Export CSV.
/// Rule: SupabaseService.client only.
/// [embedded] true when used inside Bookkeeping tab (no AppBar).
class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  final _client = SupabaseService.client;
  final _ledger = LedgerRepository();
  final _export = ExportService();

  List<LedgerEntry> _entries = [];
  List<Map<String, dynamic>> _accounts = [];
  bool _loading = true;
  DateTime _start = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _end = DateTime.now();
  String? _selectedAccountCode; // null = All
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _load();
  }

  Future<void> _loadAccounts() async {
    try {
      final res = await _client
          .from('chart_of_accounts')
          .select('id, code, name, account_code, account_name, account_type')
          .eq('is_active', true)
          .order('code');
      if (mounted) setState(() => _accounts = List<Map<String, dynamic>>.from(res));
    } catch (e) {
      debugPrint('Ledger load accounts: $e');
    }
  }

  static String _accCode(Map<String, dynamic> a) => a['account_code'] as String? ?? a['code'] as String? ?? '';
  static String _accName(Map<String, dynamic> a) => a['account_name'] as String? ?? a['name'] as String? ?? '';

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      if (_selectedAccountCode == null || _selectedAccountCode!.isEmpty) {
        final list = await _ledger.getEntriesByDate(_start, _end);
        setState(() => _entries = list);
      } else {
        final list = await _ledger.getEntriesByAccount(_selectedAccountCode!, _start, _end);
        setState(() => _entries = list);
      }
    } catch (e) {
      debugPrint('Ledger load: $e');
      setState(() => _entries = []);
    }
    setState(() => _loading = false);
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _start, end: _end),
    );
    if (range != null && mounted) {
      setState(() {
        _start = range.start;
        _end = range.end;
      });
      _load();
    }
  }

  /// Running balance only when a single account is selected (cumulative oldest to newest).
  double _runningBalanceAt(int index) {
    if (_selectedAccountCode == null || _selectedAccountCode!.isEmpty) return double.nan;
    double balance = 0;
    for (var i = 0; i <= index; i++) {
      final e = _entries[i];
      balance += e.debit - e.credit;
    }
    return balance;
  }

  void _openNewJournalEntry() async {
    final staffId = AuthService().currentStaffId;
    if (staffId == null || staffId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in with PIN to record journal entries'), backgroundColor: AppColors.warning),
      );
      return;
    }
    final date = DateTime.now();
    final dateCtrl = TextEditingController(text: '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}');
    final descCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    String? debitCode;
    String? creditCode;
    final debitAmountCtrl = TextEditingController(text: '0');
    final creditAmountCtrl = TextEditingController(text: '0');
    DateTime pickedDate = date;

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialog) {
            final debitAmt = double.tryParse(debitAmountCtrl.text) ?? 0;
            final creditAmt = double.tryParse(creditAmountCtrl.text) ?? 0;
            final unbalanced = (debitAmt - creditAmt).abs() > 0.001;

            return AlertDialog(
              title: const Text('New Journal Entry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: dateCtrl,
                      decoration: const InputDecoration(labelText: 'Date'),
                      readOnly: true,
                      onTap: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: pickedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d != null) {
                          pickedDate = d;
                          dateCtrl.text = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                          setDialog(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: refCtrl,
                      decoration: const InputDecoration(labelText: 'Reference (optional)'),
                    ),
                    const SizedBox(height: 16),
                    const Text('DEBIT', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<String>(
                      value: debitCode,
                      decoration: const InputDecoration(labelText: 'Account'),
                      items: _accounts
                          .map((a) => DropdownMenuItem<String>(
                                value: _accCode(a),
                                child: Text('${_accCode(a)} ${_accName(a)}'),
                              ))
                          .toList(),
                      onChanged: (v) => setDialog(() => debitCode = v),
                    ),
                    TextField(
                      controller: debitAmountCtrl,
                      decoration: const InputDecoration(labelText: 'Amount'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setDialog(() {}),
                    ),
                    const SizedBox(height: 16),
                    const Text('CREDIT', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<String>(
                      value: creditCode,
                      decoration: const InputDecoration(labelText: 'Account'),
                      items: _accounts
                          .map((a) => DropdownMenuItem<String>(
                                value: _accCode(a),
                                child: Text('${_accCode(a)} ${_accName(a)}'),
                              ))
                          .toList(),
                      onChanged: (v) => setDialog(() => creditCode = v),
                    ),
                    TextField(
                      controller: creditAmountCtrl,
                      decoration: const InputDecoration(labelText: 'Amount'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setDialog(() {}),
                    ),
                    if (unbalanced && (debitAmt > 0 || creditAmt > 0))
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Debits (R ${debitAmt.toStringAsFixed(2)}) ≠ Credits (R ${creditAmt.toStringAsFixed(2)}). Must balance.',
                          style: const TextStyle(color: AppColors.error, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: unbalanced || debitCode == null || creditCode == null || (debitAmt <= 0 && creditAmt <= 0)
                      ? null
                      : () async {
                          final debitName = _accounts.where((a) => _accCode(a) == debitCode).isEmpty ? debitCode! : _accName(_accounts.firstWhere((a) => _accCode(a) == debitCode));
                          final creditName = _accounts.where((a) => _accCode(a) == creditCode).isEmpty ? creditCode! : _accName(_accounts.firstWhere((a) => _accCode(a) == creditCode));
                          try {
                            await _ledger.createDoubleEntry(
                              date: pickedDate,
                              debitAccountCode: debitCode!,
                              debitAccountName: debitName,
                              creditAccountCode: creditCode!,
                              creditAccountName: creditName,
                              amount: debitAmt,
                              description: descCtrl.text.trim().isEmpty ? 'Journal entry' : descCtrl.text.trim(),
                              referenceType: refCtrl.text.trim().isEmpty ? null : 'adjustment',
                              referenceId: null,
                              source: 'manual_journal',
                              metadata: null,
                              recordedBy: AuthService().getCurrentStaffId(),
                            );
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              _load();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Journal entry saved'), backgroundColor: AppColors.success));
                            }
                          } catch (e) {
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e'), backgroundColor: AppColors.error));
                          }
                        },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      const columns = ['Date', 'Account Name', 'Description', 'Reference', 'Debit', 'Credit', 'Running Balance'];
      final data = <Map<String, dynamic>>[];
      for (var i = 0; i < _entries.length; i++) {
        final e = _entries[i];
        final ref = e.referenceType != null ? '${e.referenceType}${e.referenceId != null ? ': ${e.referenceId}' : ''}' : '';
        final balance = _selectedAccountCode != null && _selectedAccountCode!.isNotEmpty ? _runningBalanceAt(i) : null;
        data.add({
          'Date': '${e.entryDate.day.toString().padLeft(2, '0')}/${e.entryDate.month.toString().padLeft(2, '0')}/${e.entryDate.year}',
          'Account Name': e.accountName,
          'Description': e.description,
          'Reference': ref,
          'Debit': e.debit > 0 ? e.debit.toStringAsFixed(2) : '',
          'Credit': e.credit > 0 ? e.credit.toStringAsFixed(2) : '',
          'Running Balance': balance != null ? balance.toStringAsFixed(2) : '',
        });
      }
      final fileName = 'ledger_${_start.toIso8601String().substring(0, 10)}_${_end.toIso8601String().substring(0, 10)}.csv';
      final path = await _export.saveCsvToFile(suggestedFileName: fileName, data: data, columns: columns);
      if (mounted && path != null) {
        final shortName = path.split(RegExp(r'[/\\]')).last;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to Downloads/$shortName'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.error));
    }
    if (mounted) setState(() => _exporting = false);
  }

  static const _hStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary);

  @override
  Widget build(BuildContext context) {
    final startStr = '${_start.day.toString().padLeft(2, '0')}/${_start.month.toString().padLeft(2, '0')}/${_start.year}';
    final endStr = '${_end.day.toString().padLeft(2, '0')}/${_end.month.toString().padLeft(2, '0')}/${_end.year}';
    final showBalance = _selectedAccountCode != null && _selectedAccountCode!.isNotEmpty;

    final filterBar = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surfaceBg,
      child: Row(
        children: [
          TextButton.icon(
            onPressed: _loading ? null : _pickDateRange,
            icon: const Icon(Icons.calendar_month, size: 18),
            label: Text('$startStr – $endStr'),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String>(
              value: _selectedAccountCode,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Account', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
              items: [
                const DropdownMenuItem(value: null, child: Text('All', overflow: TextOverflow.ellipsis)),
                ..._accounts.map((a) => DropdownMenuItem<String>(
                      value: _accCode(a),
                      child: Text('${_accCode(a)} ${_accName(a)}', maxLines: 1, overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: (v) {
                setState(() => _selectedAccountCode = v);
                _load();
              },
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _openNewJournalEntry,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Journal Entry'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _exporting || _entries.isEmpty ? null : _exportCsv,
            icon: _exporting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download, size: 18),
            label: const Text('Export CSV'),
          ),
        ],
      ),
    );

    final body = Column(
        children: [
          filterBar,
          const Divider(height: 1, color: AppColors.border),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppColors.surfaceBg,
            child: Row(
              children: [
                SizedBox(width: 90, child: Text('Date', style: _hStyle)),
                const SizedBox(width: 8),
                SizedBox(width: 100, child: Text('Account Name', style: _hStyle)),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: Text('Description', style: _hStyle)),
                const SizedBox(width: 8),
                SizedBox(width: 80, child: Text('Reference', style: _hStyle)),
                const SizedBox(width: 8),
                SizedBox(width: 80, child: Text('Debit', style: _hStyle)),
                const SizedBox(width: 8),
                SizedBox(width: 80, child: Text('Credit', style: _hStyle)),
                if (showBalance) ...[const SizedBox(width: 8), SizedBox(width: 90, child: Text('Running Balance', style: _hStyle))],
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _entries.isEmpty
                    ? const Center(child: Text('No ledger entries in this period'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: _entries.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                        itemBuilder: (_, i) {
                          final e = _entries[i];
                          final dateStr = '${e.entryDate.day.toString().padLeft(2, '0')}/${e.entryDate.month.toString().padLeft(2, '0')}/${e.entryDate.year}';
                          final refStr = e.referenceType ?? '';
                          final balance = showBalance ? _runningBalanceAt(i) : null;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                SizedBox(width: 90, child: Text(dateStr, style: const TextStyle(fontSize: 12))),
                                const SizedBox(width: 8),
                                SizedBox(width: 100, child: Text(e.accountName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                const SizedBox(width: 8),
                                Expanded(flex: 2, child: Text(e.description, style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                const SizedBox(width: 8),
                                SizedBox(width: 80, child: Text(refStr, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                const SizedBox(width: 8),
                                SizedBox(width: 80, child: Text(e.debit > 0 ? 'R ${e.debit.toStringAsFixed(2)}' : '—', style: const TextStyle(fontSize: 12))),
                                const SizedBox(width: 8),
                                SizedBox(width: 80, child: Text(e.credit > 0 ? 'R ${e.credit.toStringAsFixed(2)}' : '—', style: const TextStyle(fontSize: 12))),
                                if (showBalance && balance != null) ...[const SizedBox(width: 8), SizedBox(width: 90, child: Text('R ${balance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)))],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      );

    if (widget.embedded) {
      return body;
    }
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Ledger'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: body,
    );
  }
}
