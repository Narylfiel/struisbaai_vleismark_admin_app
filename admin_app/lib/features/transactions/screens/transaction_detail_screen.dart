import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/features/transactions/services/transaction_repository.dart';
import 'package:intl/intl.dart';

/// Read-only transaction detail. Opened from transaction list via Navigator.push.
class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final _repo = TransactionRepository();
  Map<String, dynamic>? _txn;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final detail = await _repo.getTransactionDetail(widget.transactionId);
      if (mounted) setState(() {
        _txn = detail;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _txn = null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Transaction detail'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _txn == null
              ? const Center(child: Text('Transaction not found', style: TextStyle(color: AppColors.textSecondary)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      if (_txn!['is_voided'] == true) _buildVoidBanner(),
                      if (_txn!['is_refund'] == true && _txn!['is_voided'] != true) _buildRefundBanner(),
                      const SizedBox(height: 16),
                      _buildLineItems(),
                      const SizedBox(height: 16),
                      _buildTotals(),
                      const SizedBox(height: 16),
                      _buildPayments(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    final t = _txn!;
    final createdAt = t['created_at'] != null ? DateTime.tryParse(t['created_at'] as String) : null;
    final dateStr = createdAt != null ? DateFormat('dd MMM yyyy').format(createdAt) : '—';
    final timeStr = createdAt != null ? DateFormat('HH:mm:ss').format(createdAt) : '—';
    final receiptNumber = t['receipt_number'] as String? ?? '—';
    final profiles = t['profiles'];
    String cashierName = '—';
    if (profiles is Map) cashierName = (profiles['full_name'] as String?) ?? '—';
    else if (profiles is List && profiles.isNotEmpty && profiles.first is Map) cashierName = ((profiles.first as Map)['full_name'] as String?) ?? '—';
    final paymentMethod = t['payment_method'] as String? ?? '—';
    final tillSessionId = t['till_session_id'] as String?;
    final tillStr = tillSessionId != null ? tillSessionId.toString().substring(0, 8) : '—';
    final accounts = t['business_accounts'];
    final accountName = (accounts is Map ? (accounts['name'] as String?) : null) ?? '—';
    final loyalty = t['loyalty_customers'];
    String loyaltyName = '—';
    if (loyalty is Map) {
      loyaltyName = (loyalty['full_name'] as String?) ?? (loyalty['customer_name'] as String?) ?? '—';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(dateStr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Text(timeStr, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          _row('Receipt', receiptNumber),
          _row('Cashier', cashierName),
          _row('Payment method', paymentMethod),
          _row('Till session', tillStr),
          if (accountName.isNotEmpty && accountName != '—') _row('Account', accountName),
          if (loyaltyName.isNotEmpty && loyaltyName != '—') _row('Loyalty customer', loyaltyName),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text('$label:', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildVoidBanner() {
    final reason = _txn!['void_reason'] as String? ?? '';
    final voidedByName = _txn!['voided_by_name'] as String? ?? '—';
    final voidedAt = _txn!['voided_at'] != null ? DateTime.tryParse(_txn!['voided_at'] as String) : null;
    final voidedAtStr = voidedAt != null ? DateFormat('dd MMM yyyy HH:mm').format(voidedAt) : '';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.error.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.error)),
      child: Row(
        children: [
          const Icon(Icons.cancel, color: AppColors.error, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('VOIDED', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.error)),
                if (reason.isNotEmpty) Text(reason, style: const TextStyle(fontSize: 12)),
                Text('By $voidedByName${voidedAtStr.isNotEmpty ? ' · $voidedAtStr' : ''}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundBanner() {
    final refundOfId = _txn!['refund_of_transaction_id'] as String?;
    final refStr = refundOfId != null ? refundOfId.toString().substring(0, 8) : '—';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.info.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.info)),
      child: Row(
        children: [
          const Icon(Icons.replay, color: AppColors.info, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text('REFUND of transaction $refStr', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.info))),
        ],
      ),
    );
  }

  Widget _buildLineItems() {
    final items = _txn!['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Line items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
          child: Table(
            columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1), 4: FlexColumnWidth(1)},
            border: TableBorder.symmetric(inside: const BorderSide(color: AppColors.border)),
            children: [
              TableRow(
                decoration: BoxDecoration(color: AppColors.surfaceBg),
                children: const [
                  Padding(padding: EdgeInsets.all(8), child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Disc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
              ...items.map((e) {
                final m = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map);
                final inv = m['inventory_items'];
                final productName = (inv is Map ? (inv['name'] as String?) : null) ?? '—';
                final qty = (m['quantity'] as num?)?.toDouble();
                final isWeighted = m['is_weighted'] == true;
                final weightKg = (m['weight_kg'] as num?)?.toDouble();
                final qtyStr = isWeighted && weightKg != null ? '${weightKg.toStringAsFixed(2)} kg' : (qty?.toStringAsFixed(2) ?? '—');
                final unitPrice = (m['unit_price'] as num?)?.toDouble() ?? 0;
                final discountAmount = (m['discount_amount'] as num?)?.toDouble() ?? 0;
                final lineTotal = (m['line_total'] as num?)?.toDouble() ?? 0;
                final mods = m['modifier_selections'];
                final modStr = mods is Map ? mods.toString() : (mods is List ? mods.join(', ') : '');
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(productName, style: const TextStyle(fontSize: 12)),
                          if (modStr.isNotEmpty) Text(modStr, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Padding(padding: const EdgeInsets.all(8), child: Text(qtyStr, style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(8), child: Text('R ${unitPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(8), child: Text(discountAmount > 0 ? 'R ${discountAmount.toStringAsFixed(2)}' : '—', style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(8), child: Text('R ${lineTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12))),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotals() {
    final totalAmount = (_txn!['total_amount'] as num?)?.toDouble() ?? 0;
    final discountTotal = (_txn!['discount_total'] as num?)?.toDouble() ?? 0;
    final costAmount = (_txn!['cost_amount'] as num?)?.toDouble() ?? 0;
    final subtotal = totalAmount + discountTotal;
    final margin = totalAmount - costAmount;
    final marginPct = totalAmount > 0 ? (margin / totalAmount * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          _totalRow('Subtotal', subtotal, prefix: 'R '),
          if (discountTotal > 0) _totalRow('Discount', -discountTotal, prefix: 'R '),
          _totalRow('Total', totalAmount, bold: true, prefix: 'R '),
          _totalRow('Cost', costAmount, prefix: 'R '),
          _totalRow('Gross margin', margin, bold: true, prefix: 'R '),
          _totalRow('Margin %', marginPct, suffix: '%'),
        ],
      ),
    );
  }

  Widget _totalRow(String label, num value, {bool bold = false, String prefix = '', String suffix = ''}) {
    final formatted = value is double ? value.toStringAsFixed(2) : value.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : null)),
          Text('$prefix$formatted$suffix', style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : null)),
        ],
      ),
    );
  }

  Widget _buildPayments() {
    final paymentMethod = _txn!['payment_method'] as String? ?? '—';
    final totalAmount = (_txn!['total_amount'] as num?)?.toDouble() ?? 0;
    final splits = _txn!['split_payments'] as List<dynamic>? ?? [];

    if (splits.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payments (split)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...splits.map((e) {
            final m = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map);
            final method = m['payment_method'] as String? ?? '—';
            final amount = (m['amount'] as num?)?.toDouble() ?? 0;
            final cardRef = m['card_reference'] as String?;
            final changeGiven = (m['change_given'] as num?)?.toDouble();
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(method, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('R ${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (cardRef != null && cardRef.isNotEmpty) Text('Card ref: $cardRef', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  if (changeGiven != null && changeGiven > 0) Text('Change: R ${changeGiven.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            );
          }),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(paymentMethod),
              Text('R ${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
