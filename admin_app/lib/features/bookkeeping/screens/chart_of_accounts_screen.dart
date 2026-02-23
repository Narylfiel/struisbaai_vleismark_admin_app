import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/supabase_service.dart';

/// H6: Chart of Accounts — tree by type (Assets | Liabilities | Equity | Income | Expenses),
/// ExpansionTile, Add/Edit, delete check (ledger_entries by account_code), Import Standard SA.
/// Rule: SupabaseService.client only.
/// [embedded] true when used inside Bookkeeping tab (no AppBar).
class ChartOfAccountsScreen extends StatefulWidget {
  const ChartOfAccountsScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<ChartOfAccountsScreen> createState() => _ChartOfAccountsScreenState();
}

class _ChartOfAccountsScreenState extends State<ChartOfAccountsScreen> {
  final _client = SupabaseService.client;

  List<Map<String, dynamic>> _accounts = [];
  bool _loading = true;

  static const List<String> _types = ['asset', 'liability', 'equity', 'income', 'expense'];
  /// Remote has both code/name and account_code/account_name; use either.
  static String _code(Map<String, dynamic> a) => a['account_code'] as String? ?? a['code'] as String? ?? '';
  static String _name(Map<String, dynamic> a) => a['account_name'] as String? ?? a['name'] as String? ?? '';

  static const Map<String, String> _typeLabels = {
    'asset': 'Assets',
    'liability': 'Liabilities',
    'equity': 'Equity',
    'income': 'Income',
    'expense': 'Expenses',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _client.from('chart_of_accounts').select('*').order('code');
      setState(() => _accounts = List<Map<String, dynamic>>.from(res));
    } catch (e) {
      debugPrint('Chart of accounts: $e');
      setState(() => _accounts = []);
    }
    setState(() => _loading = false);
  }

  /// Children of [parentId] (null = top-level by type).
  List<Map<String, dynamic>> _childrenOf(String? parentId, String type) {
    return _accounts.where((a) {
      final t = a['account_type'] as String?;
      final p = a['parent_id'] as String?;
      if (t != type) return false;
      return (parentId == null && p == null) || (parentId != null && p == parentId);
    }).toList()
      ..sort((a, b) => (_code(a)).compareTo(_code(b)));
  }

  Future<void> _addOrEditAccount([Map<String, dynamic>? existing]) async {
    final codeCtrl = TextEditingController(text: existing != null ? _code(existing) : null);
    final nameCtrl = TextEditingController(text: existing != null ? _name(existing) : null);
    var type = existing?['account_type']?.toString() ?? 'expense';
    String? parentId = existing?['parent_id']?.toString();
    var isActive = existing?['is_active'] != false;

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialog) {
            final typeAccounts = _accounts.where((a) => a['account_type'] == type).toList();
            return AlertDialog(
              title: Text(existing == null ? 'Add Account' : 'Edit Account'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(labelText: 'Code'),
                      enabled: existing == null,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: _types.map((t) => DropdownMenuItem(value: t, child: Text(_typeLabels[t] ?? t))).toList(),
                      onChanged: existing == null ? (v) => setDialog(() => type = v ?? type) : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: parentId,
                      decoration: const InputDecoration(labelText: 'Parent Account (optional)'),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('— None —')),
                        ...typeAccounts
                            .where((a) => a['id'] != existing?['id'])
                            .map((a) => DropdownMenuItem<String>(
                                  value: a['id'] as String?,
                                  child: Text('${_code(a)} ${_name(a)}'),
                                )),
                      ],
                      onChanged: (v) => setDialog(() => parentId = v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Active'),
                        const SizedBox(width: 8),
                        Switch(value: isActive, onChanged: (v) => setDialog(() => isActive = v)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                if (existing != null)
                  TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: ctx,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete account?'),
                          content: const Text('If this account has ledger transactions you will only be able to deactivate it.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Cancel')),
                            ElevatedButton(onPressed: () => Navigator.pop(_, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (confirm != true || !ctx.mounted) return;
                      final code = _code(existing);
                      if (code.isEmpty) return;
                      try {
                        final refs = await _client.from('ledger_entries').select('id').eq('account_code', code).limit(1);
                        if (refs != null && (refs as List).isNotEmpty) {
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cannot delete — has transactions. Deactivate instead.'), backgroundColor: AppColors.warning),
                            );
                          }
                          return;
                        }
                        await _client.from('chart_of_accounts').delete().eq('id', existing['id']);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          _load();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deleted'), backgroundColor: AppColors.success));
                        }
                      } catch (e) {
                        if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                      }
                    },
                    child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                  ),
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final code = codeCtrl.text.trim();
                    final name = nameCtrl.text.trim();
                    if (code.isEmpty || name.isEmpty) return;
                    try {
                      if (existing != null) {
                        await _client.from('chart_of_accounts').update({
                          'name': name,
                          'account_name': name,
                          'account_type': type,
                          'parent_id': parentId,
                          'is_active': isActive,
                        }).eq('id', existing['id']);
                      } else {
                        await _client.from('chart_of_accounts').insert({
                          'code': code,
                          'name': name,
                          'account_code': code,
                          'account_name': name,
                          'account_type': type,
                          'parent_id': parentId,
                          'is_active': isActive,
                          'sort_order': _accounts.length,
                        });
                      }
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        _load();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved'), backgroundColor: AppColors.success));
                      }
                    } catch (e) {
                      if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
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

  Future<void> _importStandardSA() async {
    if (_accounts.isNotEmpty) return;
    const rows = [
      {'code': '1000', 'name': 'Cash/Bank', 'account_type': 'asset'},
      {'code': '1100', 'name': 'Accounts Receivable', 'account_type': 'asset'},
      {'code': '2000', 'name': 'Accounts Payable', 'account_type': 'liability'},
      {'code': '2100', 'name': 'VAT Control', 'account_type': 'liability'},
      {'code': '3000', 'name': 'Owner Equity', 'account_type': 'equity'},
      {'code': '4000', 'name': 'Sales Revenue', 'account_type': 'income'},
      {'code': '5000', 'name': 'Cost of Goods Sold', 'account_type': 'expense'},
      {'code': '6000', 'name': 'Salaries & Wages', 'account_type': 'expense'},
      {'code': '6100', 'name': 'Rent', 'account_type': 'expense'},
      {'code': '6200', 'name': 'Utilities', 'account_type': 'expense'},
      {'code': '6300', 'name': 'Other Expenses', 'account_type': 'expense'},
    ];
    try {
      for (final row in rows) {
        final code = row['code'] as String;
        final name = row['name'] as String;
        await _client.from('chart_of_accounts').insert({
          ...row,
          'account_code': code,
          'account_name': name,
          'is_active': true,
          'sort_order': 0,
        });
      }
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Standard SA chart imported'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> acc) async {
    final id = acc['id'];
    final current = acc['is_active'] != false;
    try {
      await _client.from('chart_of_accounts').update({'is_active': !current}).eq('id', id);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(current ? 'Deactivated' : 'Activated'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  Widget _buildAccountRow(Map<String, dynamic> acc, {int indent = 0}) {
    final code = _code(acc).isEmpty ? '—' : _code(acc);
    final name = _name(acc).isEmpty ? '—' : _name(acc);
    final isActive = acc['is_active'] != false;
    final type = acc['account_type'] as String? ?? '';
    final id = acc['id'] as String?;
    final children = _childrenOf(id, type);

    if (children.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(left: 16.0 + (indent * 24.0)),
        child: ListTile(
          dense: true,
          title: Row(
            children: [
              SizedBox(width: 64, child: Text(code, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
              const SizedBox(width: 12),
              Expanded(child: Text(name, style: const TextStyle(fontSize: 12))),
              Switch(
                value: isActive,
                onChanged: (v) async {
                  if (!v) {
                    final refs = await _client.from('ledger_entries').select('id').eq('account_code', code).limit(1);
                    if (refs != null && (refs as List).isNotEmpty && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Account has transactions; deactivating hides it from new entries.'), backgroundColor: AppColors.info),
                      );
                    }
                  }
                  _toggleActive(acc);
                },
              ),
            ],
          ),
          onTap: () => _addOrEditAccount(acc),
        ),
      );
    }
    return ExpansionTile(
      initiallyExpanded: true,
      title: InkWell(
        onTap: () => _addOrEditAccount(acc),
        child: Row(
          children: [
            SizedBox(width: 64, child: Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            const SizedBox(width: 12),
            Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12))),
            Switch(
              value: isActive,
              onChanged: (v) => _toggleActive(acc),
            ),
          ],
        ),
      ),
      children: children.map((c) => _buildAccountRow(c, indent: indent + 1)).toList(),
    );
  }

  Widget _buildBody() {
    final content = _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : _accounts.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Chart of accounts is empty.', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _importStandardSA,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Import Standard SA Chart'),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: _types.map((type) {
                  final roots = _childrenOf(null, type);
                  if (roots.isEmpty) return const SizedBox.shrink();
                  return ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(_typeLabels[type] ?? type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    children: roots.map((r) => _buildAccountRow(r)).toList(),
                  );
                }).toList(),
              );
    return content;
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildBody();
    if (widget.embedded) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surfaceBg,
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _accounts.isEmpty && !_loading ? _importStandardSA : null,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Import Standard SA Chart'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _addOrEditAccount(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Account'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(child: content),
        ],
      );
    }
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Chart of Accounts'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _accounts.isEmpty && !_loading ? _importStandardSA : null,
            icon: const Icon(Icons.upload_file, size: 18, color: Colors.white70),
            label: const Text('Import Standard SA Chart', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: content,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditAccount(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
