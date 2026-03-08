import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> customer;
  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late Map<String, dynamic> _customer;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _refreshCustomer();
  }

  Future<void> _refreshCustomer() async {
    setState(() => _loading = true);
    try {
      final res = await Supabase.instance.client
          .from('loyalty_customers')
          .select()
          .eq('id', _customer['id'])
          .single();
      if (mounted) setState(() => _customer = res);
    } catch (e) {
      debugPrint('[CUSTOMER] Refresh failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final membership = _customer['membership_number'] as String? ?? '';
    final name = _customer['full_name'] as String? ?? '—';
    final tier = _customer['loyalty_tier'] as String? ?? 'Member';
    final points = _customer['points_balance'] as int? ?? 0;
    final spend = (_customer['total_spend'] as num?)?.toDouble() ?? 0.0;
    final visits = _customer['visit_count'] as int? ?? 0;
    final email = _customer['email'] as String? ?? '';
    final phone = _customer['phone'] as String? ?? '';
    final whatsapp = _customer['whatsapp'] as String? ?? '';
    final birthday = _customer['birthday'] as String? ?? '';
    final isActive = _customer['active'] as bool? ?? true;
    final joinedAt = _customer['joined_at'] != null
        ? DateTime.parse(_customer['joined_at'] as String)
        : null;

    Color tierColor = AppColors.textSecondary;
    if (tier == 'VIP') tierColor = AppColors.accent;
    if (tier == 'Elite') tierColor = AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        title: Text(name,
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCustomer,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Status banner ──────────────────────────
                  if (!isActive)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: const Text('SUSPENDED',
                          style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                    ),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Left: Profile info ─────────────────
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _section('PROFILE', [
                              _infoRow('Name', name),
                              _infoRow('Tier', tier,
                                  valueColor: tierColor),
                              _infoRow('Status',
                                  isActive ? 'Active' : 'Suspended',
                                  valueColor: isActive
                                      ? AppColors.success
                                      : AppColors.error),
                              if (joinedAt != null)
                                _infoRow('Member Since',
                                    '${joinedAt.day}/${joinedAt.month}/${joinedAt.year}'),
                              if (birthday.isNotEmpty)
                                _infoRow('Birthday', birthday),
                            ]),
                            const SizedBox(height: 16),
                            _section('CONTACT', [
                              if (email.isNotEmpty)
                                _infoRow('Email', email),
                              if (phone.isNotEmpty)
                                _infoRow('Phone', phone),
                              if (whatsapp.isNotEmpty)
                                _infoRow('WhatsApp', whatsapp),
                            ]),
                            const SizedBox(height: 16),
                            _section('LOYALTY STATS', [
                              _infoRow('Points Balance',
                                  '$points pts'),
                              _infoRow('Total Spend',
                                  'R${spend.toStringAsFixed(2)}'),
                              _infoRow('Total Visits',
                                  '$visits visits'),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      // ── Right: Membership barcode ──────────
                      if (membership.isNotEmpty)
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  BarcodeWidget(
                                    barcode: Barcode.code128(),
                                    data: membership,
                                    width: 220,
                                    height: 80,
                                    drawText: false,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    membership,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Scan at POS to link loyalty',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: valueColor ?? AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
