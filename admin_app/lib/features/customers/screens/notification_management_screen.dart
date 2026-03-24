import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/core/services/supabase_service.dart';

class NotificationManagementScreen extends StatefulWidget {
  const NotificationManagementScreen({super.key});
  @override
  State<NotificationManagementScreen> createState() =>
      _NotificationManagementScreenState();
}

class _NotificationManagementScreenState
    extends State<NotificationManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: AppColors.surfaceBg,
        child: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.add_alert, size: 18), text: 'Send Notification'),
            Tab(icon: Icon(Icons.history, size: 18), text: 'History'),
          ],
        ),
      ),
      const Divider(height: 1, color: AppColors.border),
      Expanded(
        child: TabBarView(
          controller: _tabController,
          children: const [
            _ComposeTab(),
            _HistoryTab(),
          ],
        ),
      ),
    ]);
  }
}

class _ComposeTab extends StatefulWidget {
  const _ComposeTab();
  @override
  State<_ComposeTab> createState() => _ComposeTabState();
}

class _ComposeTabState extends State<_ComposeTab> {
  final _client = SupabaseService.client;
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _notificationType = 'custom';
  String _recipientMode = 'tier';
  String? _selectedTier;
  String? _selectedCustomerId;
  DateTime _scheduledFor = DateTime.now();
  bool _sending = false;
  List<String> _availableTiers = [];
  List<Map<String, dynamic>> _customers = [];

  static const _notificationTypes = [
    ('promotion', 'Promotion', 'Exclusive deal just for you', 'Check the Deals tab for your latest offer'),
    ('announcement', 'Announcement', 'Important update from Struisbaai Vleismark', 'We have an important update. Check the News tab'),
    ('birthday', 'Birthday', 'Happy Birthday!', 'Wishing you a wonderful day. Enjoy a special treat from us'),
    ('tier_upgrade', 'Tier Upgrade', 'Congratulations — you\'ve been upgraded!', 'You\'ve reached a new loyalty tier. Check your new benefits'),
    ('points_expiry', 'Points Expiry', 'Your points are expiring soon', 'Log in to use your points before they expire'),
    ('custom', 'Custom', '', ''),
  ];

  @override
  void initState() {
    super.initState();
    _loadTiers();
    _loadCustomers();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTiers() async {
    try {
      final response = await _client
          .from('loyalty_customers')
          .select('loyalty_tier')
          .eq('active', true);
      final tiers = <String>{};
      for (final row in response as List) {
        final tier = row['loyalty_tier'] as String?;
        if (tier != null && tier.isNotEmpty) {
          tiers.add(tier);
        }
      }
      if (mounted) {
        setState(() {
          _availableTiers = tiers.toList()..sort();
          if (_availableTiers.isNotEmpty) {
            _selectedTier = _availableTiers.first;
          }
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _loadCustomers() async {
    try {
      final response = await _client
          .from('loyalty_customers')
          .select('id, full_name, loyalty_tier')
          .eq('active', true)
          .order('full_name');
      if (mounted) {
        setState(() {
          _customers = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  void _onTypeChanged(String? type) {
    if (type == null) return;
    setState(() {
      _notificationType = type;
      final template = _notificationTypes.firstWhere((t) => t.$1 == type);
      _titleCtrl.text = template.$3;
      _bodyCtrl.text = template.$4;
    });
  }

  Future<void> _send() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title and message are required'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      List<String> customerIds = [];
      
      if (_recipientMode == 'tier' && _selectedTier != null) {
        final response = await _client
            .from('loyalty_customers')
            .select('id')
            .eq('loyalty_tier', _selectedTier!)
            .eq('active', true);
        customerIds = (response as List).map((r) => r['id'] as String).toList();
      } else if (_recipientMode == 'individual' && _selectedCustomerId != null) {
        customerIds = [_selectedCustomerId!];
      }

      if (customerIds.isEmpty) {
        throw Exception('No recipients selected');
      }

      for (final customerId in customerIds) {
        await _client.from('loyalty_notifications').insert({
          'customer_id': customerId,
          'notification_type': _notificationType,
          'title': title,
          'body': body,
          'scheduled_for': _scheduledFor.toIso8601String().substring(0, 10),
          'status': 'pending',
        });
      }

      if (mounted) {
        _titleCtrl.clear();
        _bodyCtrl.clear();
        setState(() {
          _notificationType = 'custom';
          _sending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${customerIds.length} notification(s) sent'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.friendlyMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.phone_android, size: 16, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Notifications are sent to customers in the loyalty app. They will see them in their notifications screen.',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ]),
          ),

          const Text('Notification Type', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _notificationType,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _notificationTypes.map((t) {
              return DropdownMenuItem(value: t.$1, child: Text(t.$2));
            }).toList(),
            onChanged: _onTypeChanged,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Title *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _bodyCtrl,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Message *',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),

          const Text('Send To', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('By Tier', style: TextStyle(fontSize: 13)),
                  value: 'tier',
                  groupValue: _recipientMode,
                  onChanged: (v) => setState(() => _recipientMode = v!),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Individual', style: TextStyle(fontSize: 13)),
                  value: 'individual',
                  groupValue: _recipientMode,
                  onChanged: (v) => setState(() => _recipientMode = v!),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_recipientMode == 'tier')
            DropdownButtonFormField<String>(
              value: _selectedTier,
              decoration: const InputDecoration(
                labelText: 'Loyalty Tier',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _availableTiers.map((tier) {
                return DropdownMenuItem(
                  value: tier,
                  child: Text(tier[0].toUpperCase() + tier.substring(1)),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedTier = v),
            )
          else
            DropdownButtonFormField<String>(
              value: _selectedCustomerId,
              decoration: const InputDecoration(
                labelText: 'Customer',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _customers.map((c) {
                return DropdownMenuItem(
                  value: c['id'] as String,
                  child: Text(
                    '${c['full_name']} (${c['loyalty_tier']})',
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedCustomerId = v),
            ),
          const SizedBox(height: 16),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Scheduled for: ${_scheduledFor.day}/${_scheduledFor.month}/${_scheduledFor.year}',
            ),
            subtitle: const Text(
              'Notifications are sent immediately but dated for this day',
              style: TextStyle(fontSize: 11),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_today, size: 18),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _scheduledFor,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (d != null) {
                  setState(() => _scheduledFor = d);
                }
              },
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _send,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send),
              label: Text(
                _sending ? 'Sending...' : 'Send Notification',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatefulWidget {
  const _HistoryTab();
  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  final _client = SupabaseService.client;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _client
          .from('loyalty_notifications')
          .select('*, loyalty_customers!inner(full_name)')
          .order('created_at', ascending: false)
          .limit(100);
      if (mounted) {
        setState(() {
          _history = List<Map<String, dynamic>>.from(res);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_history.isEmpty) {
      return const Center(child: Text('No notifications sent yet.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final row = _history[i];
          final createdAt = row['created_at'] != null
              ? DateTime.tryParse(row['created_at'].toString())
              : null;
          final status = row['status'] as String? ?? 'pending';
          final customerName = row['loyalty_customers']?['full_name'] ?? 'Unknown';

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        row['title']?.toString() ?? '—',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        status == 'pending' ? 'Unread' : 'Read',
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: status == 'pending'
                          ? AppColors.warning.withValues(alpha: 0.15)
                          : AppColors.success.withValues(alpha: 0.15),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    row['body']?.toString() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.person_outline, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      customerName,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.category_outlined, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      row['notification_type']?.toString() ?? 'custom',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    if (createdAt != null) ...[
                      const Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
