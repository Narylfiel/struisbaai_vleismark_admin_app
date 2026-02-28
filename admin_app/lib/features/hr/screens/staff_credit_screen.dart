import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/core/services/auth_service.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/features/hr/models/staff_credit.dart';
import 'package:admin_app/features/hr/services/staff_credit_repository.dart';
import 'package:admin_app/shared/widgets/form_widgets.dart';

/// H3: Staff Credit screen — staff selector, balance (green/red), history table with running balance, FAB Add Credit Entry.
class StaffCreditScreen extends StatefulWidget {
  const StaffCreditScreen({super.key, this.isEmbedded = false});
  final bool isEmbedded;

  @override
  State<StaffCreditScreen> createState() => _StaffCreditScreenState();
}

class _StaffCreditScreenState extends State<StaffCreditScreen> {
  final _client = SupabaseService.client;
  final _repo = StaffCreditRepository();

  List<Map<String, dynamic>> _staffList = [];
  String? _selectedStaffId;
  List<StaffCredit> _credits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    try {
      final data = await _client
          .from('staff_profiles')
          .select('id, full_name')
          .eq('is_active', true)
          .order('full_name');
      if (mounted) setState(() => _staffList = List<Map<String, dynamic>>.from(data));
    } catch (_) {}
  }

  Future<void> _loadCredits() async {
    if (_selectedStaffId == null) {
      setState(() => _credits = []);
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final list = await _repo.getCredits(staffId: _selectedStaffId, outstandingOnly: false);
      if (mounted) setState(() => _credits = list);
    } catch (e) {
      if (mounted) setState(() => _credits = []);
    }
    if (mounted) setState(() => _loading = false);
  }

  double get _currentBalance {
    return _credits.fold<double>(0, (sum, c) => sum + c.amount);
  }

  /// Entries oldest-first with running balance per row
  List<({StaffCredit credit, double runningBalance})> get _entriesWithRunningBalance {
    final sorted = List<StaffCredit>.from(_credits)
      ..sort((a, b) => a.grantedDate.compareTo(b.grantedDate));
    double running = 0;
    return sorted.map((c) {
      running += c.amount;
      return (credit: c, runningBalance: running);
    }).toList();
  }

  void _openAddEntry() async {
    final userId = AuthService().currentStaffId;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in with PIN to add credit'), backgroundColor: AppColors.warning),
      );
      return;
    }
    String? staffId = _selectedStaffId;
    StaffCreditType type = StaffCreditType.salaryAdvance;
    final amountController = TextEditingController();
    bool chargeToStaff = true; // true = [+] staff owes company, false = [-] company owes staff
    final notesController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Add credit entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FormWidgets.dropdownFormField<String>(
                  label: 'Staff',
                  value: staffId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('— Select staff —')),
                    ..._staffList.map((s) => DropdownMenuItem(value: s['id'] as String?, child: Text(s['full_name']?.toString() ?? ''))),
                  ],
                  onChanged: (v) => setDialog(() => staffId = v),
                ),
                const SizedBox(height: 12),
                FormWidgets.dropdownFormField<StaffCreditType>(
                  label: 'Type',
                  value: type,
                  items: const [
                    DropdownMenuItem(value: StaffCreditType.salaryAdvance, child: Text('Advance')),
                    DropdownMenuItem(value: StaffCreditType.meatPurchase, child: Text('Meat Purchase')),
                    DropdownMenuItem(value: StaffCreditType.deduction, child: Text('Deduction')),
                    DropdownMenuItem(value: StaffCreditType.repayment, child: Text('Repayment')),
                    DropdownMenuItem(value: StaffCreditType.other, child: Text('Other')),
                  ],
                  onChanged: (v) => setDialog(() => type = v ?? StaffCreditType.salaryAdvance),
                ),
                const SizedBox(height: 12),
                FormWidgets.textFormField(
                  label: 'Amount (R)',
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                const Text('Direction', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: chargeToStaff,
                      onChanged: (v) => setDialog(() => chargeToStaff = true),
                      activeColor: AppColors.primary,
                    ),
                    const Text('Charge to staff [+]'),
                    const SizedBox(width: 16),
                    Radio<bool>(
                      value: false,
                      groupValue: chargeToStaff,
                      onChanged: (v) => setDialog(() => chargeToStaff = false),
                      activeColor: AppColors.primary,
                    ),
                    const Text('Pay to staff [-]'),
                  ],
                ),
                const SizedBox(height: 12),
                FormWidgets.textFormField(
                  label: 'Notes',
                  controller: notesController,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: staffId == null || amountController.text.trim().isEmpty ? null : () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || staffId == null) return;
    final selectedStaffId = staffId!;
    final amountAbs = double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0;
    if (amountAbs <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amount must be greater than 0')));
      return;
    }
    final signedAmount = chargeToStaff ? amountAbs : -amountAbs;
    final typeLabel = type.displayLabel;
    final reason = notesController.text.trim().isEmpty ? typeLabel : '$typeLabel — ${notesController.text.trim()}';

    try {
      await _repo.create(
        staffId: selectedStaffId,
        creditType: type,
        amount: signedAmount,
        reason: reason,
        grantedDate: DateTime.now(),
        grantedBy: userId,
        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credit entry saved'), backgroundColor: AppColors.success));
        _loadCredits();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = _currentBalance;
    final balanceColor = balance > 0 ? AppColors.success : (balance < 0 ? AppColors.error : AppColors.textSecondary);
    final entries = _entriesWithRunningBalance;

    final bodyContent = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Staff', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedStaffId,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('— Select staff —')),
                    ..._staffList.map((s) => DropdownMenuItem(value: s['id'] as String, child: Text(s['full_name']?.toString() ?? ''))),
                  ],
                  onChanged: (v) => setState(() { _selectedStaffId = v; _loadCredits(); }),
                ),
                if (_selectedStaffId != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Text('Balance: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Text('R ${balance.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: balanceColor)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          if (_selectedStaffId == null)
            const Expanded(child: Center(child: Text('Select a staff member to view credit history.')))
          else if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.surfaceBg,
              child: Row(
                children: [
                  SizedBox(width: 100, child: Text('Date', style: _headerStyle)),
                  Expanded(flex: 2, child: Text('Reason', style: _headerStyle)),
                  SizedBox(width: 100, child: Text('Amount', style: _headerStyle)),
                  SizedBox(width: 110, child: Text('Running balance', style: _headerStyle)),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: entries.isEmpty
                  ? const Center(child: Text('No credit entries'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: entries.length,
                      itemBuilder: (_, i) {
                        final e = entries[i];
                        final amt = e.credit.amount;
                        final amtColor = amt >= 0 ? AppColors.success : AppColors.error;
                        final amtStr = amt >= 0 ? '+R ${amt.toStringAsFixed(2)}' : '-R ${(-amt).toStringAsFixed(2)}';
                        final runColor = e.runningBalance >= 0 ? AppColors.success : (e.runningBalance < 0 ? AppColors.error : AppColors.textSecondary);
                        final dateStr = e.credit.grantedDate.toString().substring(0, 10);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              SizedBox(width: 100, child: Text(dateStr)),
                              Expanded(flex: 2, child: Text(e.credit.reason, overflow: TextOverflow.ellipsis)),
                              SizedBox(width: 100, child: Text(amtStr, style: TextStyle(color: amtColor, fontWeight: FontWeight.w600))),
                              SizedBox(width: 110, child: Text('R ${e.runningBalance.toStringAsFixed(2)}', style: TextStyle(color: runColor, fontWeight: FontWeight.w500))),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ],
      );

    if (widget.isEmbedded) {
      return Stack(
        children: [
          bodyContent,
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: _openAddEntry,
              icon: const Icon(Icons.add),
              label: const Text('Add credit entry'),
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: bodyContent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddEntry,
        icon: const Icon(Icons.add),
        label: const Text('Add credit entry'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  static const _headerStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary);
}
