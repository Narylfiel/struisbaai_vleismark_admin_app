import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/core/services/auth_service.dart';
import 'package:admin_app/core/db/isar_service.dart';
import 'package:admin_app/core/services/connectivity_service.dart';
import 'package:admin_app/core/services/offline_queue_service.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/features/hr/models/staff_credit.dart';
import 'package:admin_app/features/hr/services/staff_profile_repository.dart';
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
  List<Map<String, dynamic>> _pendingAdvances = [];
  bool _loading = true;
  bool _loadingAdvances = true;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _loadStaff();
    _loadAdvances();
  }

  Future<void> _loadAdvances() async {
    setState(() => _loadingAdvances = true);
    try {
      if (!ConnectivityService().isConnected) {
        if (mounted) setState(() => _pendingAdvances = []);
        setState(() => _loadingAdvances = false);
        return;
      }
      final data = await _client
          .from('staff_requests')
          .select('id, staff_id, amount_requested, advance_reason, created_at, staff_profiles!staff_id(full_name)')
          .eq('request_type', 'salary_advance')
          .eq('status', 'pending')
          .order('created_at', ascending: true);
      
      if (mounted) setState(() => _pendingAdvances = List<Map<String, dynamic>>.from(data));
    } catch (_) {
      if (mounted) setState(() => _pendingAdvances = []);
    }
    if (mounted) setState(() => _loadingAdvances = false);
  }

  Future<void> _loadStaff() async {
    try {
      if (!ConnectivityService().isConnected) {
        final cached = await IsarService.getAllStaffProfiles();
        if (mounted) setState(() => _staffList = cached.map((c) => {'id': c.staffId, 'full_name': c.fullName}).toList());
        return;
      }
      final data = await StaffProfileRepository(client: _client)
          .getAll(isActive: true);
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
      if (!ConnectivityService().isConnected) {
        _isOffline = true;
        final cached = await IsarService.getAllStaffCredits();
        final list = cached
            .where((c) => c.staffId == _selectedStaffId)
            .map((c) => StaffCredit.fromJson({
                  'id': c.creditId,
                  'staff_id': c.staffId,
                  'credit_type': 'salary_advance',
                  'credit_amount': c.amount,
                  'reason': c.reason,
                  'granted_date': c.creditDate?.toIso8601String(),
                  'staff_profiles': {'full_name': c.staffName},
                }))
            .toList();
        if (mounted) setState(() => _credits = list);
        setState(() => _loading = false);
        return;
      }
      _isOffline = false;
      final list = await _repo.getCredits(staffId: _selectedStaffId, outstandingOnly: false);
      if (mounted) setState(() => _credits = list);
    } catch (e) {
      if (mounted) setState(() => _credits = []);
    }
    if (mounted) setState(() => _loading = false);
  }

  double get _meatPending {
    return _credits.where((c) => c.creditType == StaffCreditType.meatPurchase && (c.status == StaffCreditStatus.pending || c.status == StaffCreditStatus.partial)).fold<double>(0, (sum, c) => sum + c.amount);
  }

  double get _advancePending {
    return _credits.where((c) => c.creditType == StaffCreditType.salaryAdvance && (c.status == StaffCreditStatus.pending || c.status == StaffCreditStatus.partial)).fold<double>(0, (sum, c) => sum + c.amount);
  }

  double get _totalOutstanding {
    return _meatPending + _advancePending;
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
    DateTime selectedDate = DateTime.now();

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
                StatefulBuilder(
                  builder: (ctx2, setDate) => InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx2,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialog(() => selectedDate = picked);
                        setDate(() {});
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                        isDense: true,
                      ),
                      child: Text(
                        '${selectedDate.year}-'
                        '${selectedDate.month.toString().padLeft(2, '0')}-'
                        '${selectedDate.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
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
      if (!ConnectivityService().isConnected) {
        await OfflineQueueService().addToQueue('add_staff_credit', {
          'staff_id': selectedStaffId,
          'credit_type': type.dbValue,
          'credit_amount': signedAmount,
          'reason': reason,
          'granted_date': selectedDate.toIso8601String(),
          'granted_by': userId,
          'notes': notesController.text.trim().isEmpty ? null : notesController.text.trim(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved — will sync when back online.'), backgroundColor: AppColors.success));
          _loadCredits();
        }
        return;
      }
      final deductFrom = _calculateDeductionDate(selectedDate)
          .toIso8601String()
          .substring(0, 10);

      await _repo.create(
        staffId: selectedStaffId,
        creditType: type,
        amount: signedAmount,
        reason: reason,
        grantedDate: selectedDate,
        grantedBy: userId,
        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
        deductFrom: deductFrom,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credit entry saved'), backgroundColor: AppColors.success));
        _loadCredits();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error));
    }
  }

  void _approveAdvance(Map<String, dynamic> request) async {
    final staffName = request['staff_profiles']?['full_name'] as String? ?? 'Staff';
    final requestedAmt = (request['amount_requested'] as num?)?.toDouble() ?? 0.0;
    final amtController = TextEditingController(text: requestedAmt.toString());
    
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Advance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Staff: $staffName'),
            const SizedBox(height: 4),
            Text('Requested: R ${requestedAmt.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            FormWidgets.textFormField(
              label: 'Amount to approve (R)',
              controller: amtController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 6),
            const Text('Staff will be notified of approved amount', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Approve')),
        ],
      ),
    );

    if (saved != true) return;

    final approvedAmt = double.tryParse(amtController.text.replaceAll(',', '.')) ?? 0;
    if (approvedAmt <= 0) return;

    try {
      final currentUserId = AuthService().currentStaffId;
      if (currentUserId == null) return;

      await _client.rpc(
        'approve_advance_request',
        params: {
          'p_request_id': request['id'] as String,
          'p_amount': approvedAmt,
          'p_reviewer_id': currentUserId,
        },
      );

      _loadAdvances();
      if (_selectedStaffId == request['staff_id']) _loadCredits();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Advance approved — R${approvedAmt.toStringAsFixed(2)} added to $staffName\'s credit'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error));
    }
  }

  void _declineAdvance(Map<String, dynamic> request) async {
    final staffName = request['staff_profiles']?['full_name'] as String? ?? 'Staff';
    final requestedAmt = (request['amount_requested'] as num?)?.toDouble() ?? 0.0;
    final reasonController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Advance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Staff: $staffName | R ${requestedAmt.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            FormWidgets.textFormField(
              label: 'Reason for declining (owner only)',
              controller: reasonController,
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (saved != true) return;

    final reason = reasonController.text.trim();
    if (reason.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A reason is required to decline'), backgroundColor: AppColors.error));
      return;
    }

    try {
      final currentUserId = AuthService().currentStaffId;
      if (currentUserId == null) return;

      await _client.from('staff_requests').update({
        'status': 'declined',
        'decline_reason': reason,
        'reviewed_by': currentUserId,
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', request['id']);

      _loadAdvances();

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request declined'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error));
    }
  }

  void _openUpdateStatus(StaffCredit credit) async {
    if (AuthService().currentRole != 'owner') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Only owners can change status'), backgroundColor: AppColors.error));
      return;
    }

    StaffCreditStatus status = credit.status;
    final staffName = _staffList.firstWhere((s) => s['id'] == credit.staffId, orElse: () => {'full_name': 'Unknown'})['full_name'];

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Update Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Staff: $staffName', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${credit.creditType.displayLabel} | ${credit.grantedDate.toString().substring(0, 10)} | R ${credit.amount.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              const Text('Status:', style: TextStyle(fontWeight: FontWeight.w600)),
              RadioListTile<StaffCreditStatus>(
                title: const Text('Pending'),
                value: StaffCreditStatus.pending,
                groupValue: status,
                onChanged: (v) => setDialog(() => status = v!),
                dense: true,
              ),
              RadioListTile<StaffCreditStatus>(
                title: const Text('Deducted'),
                value: StaffCreditStatus.deducted,
                groupValue: status,
                onChanged: (v) => setDialog(() => status = v!),
                dense: true,
              ),
              RadioListTile<StaffCreditStatus>(
                title: const Text('Partial'),
                value: StaffCreditStatus.partial,
                groupValue: status,
                onChanged: (v) => setDialog(() => status = v!),
                dense: true,
              ),
              RadioListTile<StaffCreditStatus>(
                title: const Text('Cleared'),
                value: StaffCreditStatus.cleared,
                groupValue: status,
                onChanged: (v) => setDialog(() => status = v!),
                dense: true,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (saved != true || status == credit.status) return;

    try {
      await _repo.updateStatus(
        credit.id, 
        status, 
        paidDate: status == StaffCreditStatus.cleared || status == StaffCreditStatus.deducted ? DateTime.now() : null
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated'), backgroundColor: AppColors.success));
        _loadCredits();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error));
    }
  }

  Color _typeColor(StaffCreditType type) {
    switch (type) {
      case StaffCreditType.meatPurchase: return const Color(0xFFFFB300);
      case StaffCreditType.salaryAdvance: return const Color(0xFF1E88E5);
      case StaffCreditType.deduction: return AppColors.error;
      case StaffCreditType.repayment: return AppColors.success;
      case StaffCreditType.loan: return const Color(0xFFE65100);
      case StaffCreditType.other: return AppColors.textSecondary;
    }
  }

  Future<void> _editDeductFrom(StaffCredit credit) async {
    final staffData = _staffList.firstWhere(
      (s) => s['id'] == credit.staffId,
      orElse: () => <String, dynamic>{},
    );
    final staffName =
        staffData['full_name'] as String? ?? 'Unknown';
    DateTime initialDate = credit.grantedDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select any date in the target month',
    );

    if (picked == null || !mounted) return;

    final newDeductFrom =
        _calculateDeductionDate(picked)
            .toIso8601String()
            .substring(0, 10);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Deduction Period'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Staff: $staffName'),
            const SizedBox(height: 8),
            const Text('Change deduction period to:'),
            const SizedBox(height: 4),
            Text(
              _formatDeductFrom(newDeductFrom),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await _client
          .from('staff_credit')
          .update({'deduct_from': newDeductFrom})
          .eq('id', credit.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Deduction period updated to: $newDeductFrom'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadCredits();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatDeductFrom(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month]} ${date.year}';
  }

  DateTime _calculateDeductionDate(DateTime grantedDate) {
    // Last day of the month the credit was granted.
    // Works for all pay frequencies (weekly no longer used).
    return DateTime(grantedDate.year, grantedDate.month + 1, 0);
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entriesWithRunningBalance;
    final isOwner = AuthService().currentRole == 'owner';

    final bodyContent = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PENDING ADVANCE REQUESTS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                if (_loadingAdvances)
                  const CircularProgressIndicator(color: AppColors.primary)
                else if (_pendingAdvances.isEmpty)
                  const Text('No pending advance requests', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic))
                else
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _pendingAdvances.length,
                      itemBuilder: (_, i) {
                        final req = _pendingAdvances[i];
                        final reqAmt = (req['amount_requested'] as num?)?.toDouble() ?? 0.0;
                        final staffName = req['staff_profiles']?['full_name'] as String? ?? 'Unknown';
                        final reason = req['advance_reason'] as String? ?? 'No reason provided';
                        final dateStr = req['created_at'] != null ? req['created_at'].toString().substring(0, 10) : '';

                        return Container(
                          width: 280,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(staffName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis)),
                                  Text('R ${reqAmt.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E88E5))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Submitted: $dateStr', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              Expanded(child: Text('Reason: $reason', style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
                              if (isOwner) ...[
                                const Divider(height: 10, color: AppColors.border),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => _declineAdvance(req),
                                      style: TextButton.styleFrom(foregroundColor: AppColors.error, minimumSize: const Size(60, 30), padding: const EdgeInsets.symmetric(horizontal: 8)),
                                      child: const Text('DECLINE', style: TextStyle(fontSize: 11)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _approveAdvance(req),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, minimumSize: const Size(70, 30), padding: const EdgeInsets.symmetric(horizontal: 8)),
                                      child: const Text('APPROVE', style: TextStyle(fontSize: 11)),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 24),
                
                const Text('Staff', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStaffId,
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
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Meat purchases (pending):', style: TextStyle(color: AppColors.textSecondary)),
                            Text('R ${_meatPending.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFFFB300), fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Advances (pending):', style: TextStyle(color: AppColors.textSecondary)),
                            Text('R ${_advancePending.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF1E88E5), fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, color: AppColors.border),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total outstanding:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('R ${_totalOutstanding.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _totalOutstanding > 0 ? AppColors.error : AppColors.success)),
                          ],
                        ),
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
              child: const Row(
                children: [
                  SizedBox(width: 100, child: Text('Date', style: _headerStyle)),
                  Expanded(flex: 2, child: Text('Reason', style: _headerStyle)),
                  SizedBox(width: 110, child: Text('Type', style: _headerStyle)),
                  SizedBox(width: 90, child: Text('Status', style: _headerStyle)),
                  SizedBox(width: 130, child: Text('Deduct from', style: _headerStyle)),
                  SizedBox(width: 100, child: Text('Amount', style: _headerStyle)),
                  SizedBox(width: 110, child: Text('Running balance', style: _headerStyle)),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Text(
                        _isOffline ? 'No cached data available. Connect to the internet to load data.' : 'No credit entries',
                        style: const TextStyle(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                      itemCount: entries.length,
                      itemBuilder: (_, i) {
                        final e = entries[i];
                        final amt = e.credit.amount;
                        final amtColor = amt >= 0 ? AppColors.success : AppColors.error;
                        final amtStr = amt >= 0 ? '+R ${amt.toStringAsFixed(2)}' : '-R ${(-amt).toStringAsFixed(2)}';
                        final runColor = e.runningBalance >= 0 ? AppColors.success : (e.runningBalance < 0 ? AppColors.error : AppColors.textSecondary);
                        final dateStr = e.credit.grantedDate.toString().substring(0, 10);
                        return InkWell(
                          onTap: () => _openUpdateStatus(e.credit),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                SizedBox(width: 100, child: Text(dateStr)),
                                Expanded(flex: 2, child: Text(e.credit.reason, overflow: TextOverflow.ellipsis)),
                                SizedBox(width: 110, child: Text(e.credit.creditType.displayLabel, style: TextStyle(color: _typeColor(e.credit.creditType), fontSize: 12))),
                                SizedBox(width: 90, child: Align(alignment: Alignment.centerLeft, child: _StatusChip(status: e.credit.status))),
                                SizedBox(
                                  width: 130,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _formatDeductFrom(e.credit.deductFrom),
                                          style: TextStyle(
                                            color: e.credit.status == StaffCreditStatus.pending
                                                ? const Color(0xFFFFB300)
                                                : AppColors.textSecondary,
                                            fontSize: 11,
                                            fontWeight:
                                                e.credit.status == StaffCreditStatus.pending
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _editDeductFrom(e.credit),
                                        child: const Padding(
                                          padding: EdgeInsets.only(left: 4),
                                          child: Icon(
                                            Icons.edit,
                                            size: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 100, child: Text(amtStr, style: TextStyle(color: amtColor, fontWeight: FontWeight.w600))),
                                SizedBox(width: 110, child: Text('R ${e.runningBalance.toStringAsFixed(2)}', style: TextStyle(color: runColor, fontWeight: FontWeight.w500))),
                              ],
                            ),
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

class _StatusChip extends StatelessWidget {
  final StaffCreditStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    switch (status) {
      case StaffCreditStatus.pending:
        bg = const Color(0xFFFFB300); text = Colors.black; break;
      case StaffCreditStatus.deducted:
        bg = AppColors.success; text = Colors.white; break;
      case StaffCreditStatus.partial:
        bg = const Color(0xFFE65100); text = Colors.white; break;
      case StaffCreditStatus.cleared:
        bg = Colors.grey; text = Colors.white; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(status.displayLabel, style: TextStyle(color: text, fontSize: 11)),
    );
  }
}
