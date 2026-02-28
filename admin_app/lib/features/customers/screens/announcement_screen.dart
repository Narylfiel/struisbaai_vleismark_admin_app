import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/core/services/supabase_service.dart';

/// M1: Announcement screen — Compose + History tabs.
/// WhatsApp/SMS channels, recipient selector, customer_announcements.
class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen>
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
    return Column(
      children: [
        Container(
          color: AppColors.surfaceBg,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(icon: Icon(Icons.edit, size: 18), text: 'Compose'),
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
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 1: COMPOSE
// ══════════════════════════════════════════════════════════════════

class _ComposeTab extends StatefulWidget {
  const _ComposeTab();

  @override
  State<_ComposeTab> createState() => _ComposeTabState();
}

class _ComposeTabState extends State<_ComposeTab> {
  final _client = SupabaseService.client;
  final _bodyController = TextEditingController();
  static const _maxChars = 1500;
  String _channel = 'WhatsApp';
  String _recipientMode = 'all'; // all | by_tag | manual
  Set<String> _selectedTags = {};
  Set<String> _selectedCustomerIds = {};
  File? _pickedImage;
  List<Map<String, dynamic>> _customers = [];
  List<String> _distinctTags = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _bodyController.addListener(() => setState(() {}));
    _loadCustomers();
  }

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _loading = true);
    try {
      final res = await _client.from('loyalty_customers').select('id, full_name, customer_name, phone_number, tags').eq('is_active', true);
      final list = List<Map<String, dynamic>>.from(res);
      final tags = <String>{};
      for (final c in list) {
        final t = c['tags'];
        if (t is List) {
          for (final x in t) tags.add(x.toString());
        }
      }
      if (mounted) setState(() {
        _customers = list;
        _distinctTags = tags.toList()..sort();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x != null && mounted) setState(() => _pickedImage = File(x.path));
  }

  List<Map<String, dynamic>> get _recipients {
    if (_recipientMode == 'all') return _customers;
    if (_recipientMode == 'by_tag') {
      return _customers.where((c) {
        final t = c['tags'] as List? ?? [];
        return t.any((x) => _selectedTags.contains(x.toString()));
      }).toList();
    }
    return _customers.where((c) => _selectedCustomerIds.contains(c['id']?.toString())).toList();
  }

  List<String> get _recipientPhones {
    return _recipients
        .map((c) => (c['phone_number'] ?? c['phone'] ?? '').toString().trim())
        .where((p) => p.isNotEmpty && p.length >= 10)
        .map((p) => p.replaceAll(RegExp(r'[^0-9]'), ''))
        .where((p) => p.length >= 10)
        .toList();
  }

  Future<void> _send() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message body is required'), backgroundColor: AppColors.warning),
      );
      return;
    }
    final phones = _recipientPhones;
    if (phones.isEmpty && _recipientMode != 'all') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recipients with phone numbers selected'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      String? imageUrl;
      if (_pickedImage != null) {
        try {
          final path = 'announcements/${DateTime.now().millisecondsSinceEpoch}.jpg';
          await _client.storage.from('product-images').upload(path, _pickedImage!);
          imageUrl = _client.storage.from('product-images').getPublicUrl(path);
        } catch (_) {}
      }

      final title = body.length > 60 ? body.substring(0, 60) : body;
      await _client.from('customer_announcements').insert({
        'title': title,
        'body': body,
        'channel': _channel,
        'recipient_count': phones.isEmpty ? _recipients.length : phones.length,
        'status': 'sent',
        'sent_at': DateTime.now().toIso8601String(),
        'image_url': imageUrl,
      });

      if (_channel == 'WhatsApp' || _channel == 'Both') {
        for (final phone in phones) {
          final clean = phone.startsWith('0') ? '27${phone.substring(1)}' : phone;
          final uri = Uri.parse('https://wa.me/$clean?text=${Uri.encodeComponent(body)}');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }
      if (_channel == 'SMS' || _channel == 'Both') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS: use your phone to send. Recipients saved.'), backgroundColor: AppColors.info),
        );
      }

      if (mounted) {
        _bodyController.clear();
        setState(() {
          _pickedImage = null;
          _sending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Announcement sent to ${phones.isEmpty ? _recipients.length : phones.length} recipients'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _recipients.length;
    final phoneCount = _recipientPhones.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _bodyController,
            maxLines: 6,
            maxLength: _maxChars,
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText: 'Enter your announcement message...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          Row(
            children: [
              Text('${_bodyController.text.length}/$_maxChars', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const Spacer(),
              if (_pickedImage != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_pickedImage!, height: 60, width: 60, fit: BoxFit.cover),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _pickedImage = null)),
              ] else
                TextButton.icon(onPressed: _pickImage, icon: const Icon(Icons.add_photo_alternate), label: const Text('Add image')),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _channel,
            decoration: const InputDecoration(labelText: 'Channel', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'WhatsApp', child: Text('WhatsApp')),
              DropdownMenuItem(value: 'SMS', child: Text('SMS')),
              DropdownMenuItem(value: 'Both', child: Text('Both')),
            ],
            onChanged: (v) => setState(() => _channel = v ?? 'WhatsApp'),
          ),
          const SizedBox(height: 24),
          const Text('Recipients', style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Radio<String>(value: 'all', groupValue: _recipientMode, onChanged: (v) => setState(() => _recipientMode = v!)),
              const Text('All Customers'),
              Radio<String>(value: 'by_tag', groupValue: _recipientMode, onChanged: (v) => setState(() => _recipientMode = v!)),
              const Text('By Tag'),
              Radio<String>(value: 'manual', groupValue: _recipientMode, onChanged: (v) => setState(() => _recipientMode = v!)),
              const Text('Manual Select'),
            ],
          ),
          if (_recipientMode == 'by_tag') ...[
            Wrap(
              spacing: 8,
              children: _distinctTags.map((tag) {
                final sel = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: sel,
                  onSelected: (v) => setState(() {
                    if (v) _selectedTags.add(tag); else _selectedTags.remove(tag);
                  }),
                );
              }).toList(),
            ),
          ],
          if (_recipientMode == 'manual') ...[
            SizedBox(
              height: 200,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _customers.length,
                      itemBuilder: (_, i) {
                        final c = _customers[i];
                        final id = c['id']?.toString() ?? '';
                        final name = c['full_name'] ?? c['customer_name'] ?? 'Unknown';
                        final sel = _selectedCustomerIds.contains(id);
                        return CheckboxListTile(
                          value: sel,
                          title: Text(name),
                          subtitle: Text(c['phone_number']?.toString() ?? ''),
                          onChanged: (v) => setState(() {
                            if (v == true) _selectedCustomerIds.add(id);
                            else _selectedCustomerIds.remove(id);
                          }),
                        );
                      },
                    ),
            ),
          ],
          const SizedBox(height: 8),
          Text('$count recipients selected${phoneCount != count ? ' ($phoneCount with phone)' : ''}', style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _sending ? null : _send,
            icon: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
            label: Text(_sending ? 'Sending...' : 'Send'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 2: HISTORY
// ══════════════════════════════════════════════════════════════════

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
      final res = await _client.from('customer_announcements').select().order('sent_at', ascending: false);
      if (mounted) setState(() {
        _history = List<Map<String, dynamic>>.from(res);
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_history.isEmpty) return const Center(child: Text('No announcements sent yet.'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(3),
          2: FlexColumnWidth(0.8),
          3: FlexColumnWidth(0.6),
          4: FlexColumnWidth(0.8),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: AppColors.surfaceBg),
            children: const [
              Padding(padding: EdgeInsets.all(8), child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Padding(padding: EdgeInsets.all(8), child: Text('Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Padding(padding: EdgeInsets.all(8), child: Text('Channel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Padding(padding: EdgeInsets.all(8), child: Text('Recipients', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Padding(padding: EdgeInsets.all(8), child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            ],
          ),
          ..._history.map((row) {
            final sentAt = row['sent_at'] != null ? DateTime.tryParse(row['sent_at'].toString()) : null;
            final dateStr = sentAt != null ? '${sentAt.day}/${sentAt.month}/${sentAt.year}' : '—';
            final preview = (row['body'] ?? row['title'] ?? '').toString();
            final previewStr = preview.length > 80 ? '${preview.substring(0, 80)}...' : preview;
            final status = row['status']?.toString() ?? 'sent';
            return TableRow(
              children: [
                Padding(padding: const EdgeInsets.all(8), child: Text(dateStr)),
                Padding(padding: const EdgeInsets.all(8), child: Text(previewStr, maxLines: 2, overflow: TextOverflow.ellipsis)),
                Padding(padding: const EdgeInsets.all(8), child: Text(row['channel']?.toString() ?? '—')),
                Padding(padding: const EdgeInsets.all(8), child: Text('${row['recipient_count'] ?? 0}')),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Chip(
                    label: Text(status),
                    backgroundColor: status == 'sent' ? AppColors.success.withOpacity(0.2) : AppColors.textSecondary.withOpacity(0.2),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
