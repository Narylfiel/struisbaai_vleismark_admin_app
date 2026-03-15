import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/core/services/supabase_service.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen(
      {super.key, this.embedded = false});
  final bool embedded;
  @override
  State<AnnouncementScreen> createState() =>
      _AnnouncementScreenState();
}

class _AnnouncementScreenState
    extends State<AnnouncementScreen>
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
            Tab(icon: Icon(Icons.edit, size: 18),
                text: 'New Announcement'),
            Tab(icon: Icon(Icons.history, size: 18),
                text: 'History'),
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
  String _audience = 'all';
  DateTime? _endDate;
  File? _pickedImage;
  bool _sending = false;

  static const _audienceOptions = [
    ('all',    'All Members'),
    ('bronze', 'Bronze+'),
    ('silver', 'Silver+'),
    ('gold',   'Gold+'),
    ('elite',  'Elite+'),
    ('vip',    'VIP Only'),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85);
    if (x != null && mounted) {
      setState(() => _pickedImage = File(x.path));
    }
  }

  Future<void> _publish() async {
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
      String? imageUrl;
      if (_pickedImage != null) {
        try {
          final path =
              'announcements/${DateTime.now()
              .millisecondsSinceEpoch}.jpg';
          await _client.storage
              .from('product-images')
              .upload(path, _pickedImage!);
          imageUrl = _client.storage
              .from('product-images')
              .getPublicUrl(path);
        } catch (_) {}
      }

      await _client.from('announcements').insert({
        'title': title,
        'content': body,
        'target_audience': _audience,
        'is_active': true,
        'image_url': imageUrl,
        'end_date': _endDate != null
            ? _endDate!.toIso8601String()
                .substring(0, 10)
            : null,
        'created_at': DateTime.now()
            .toIso8601String(),
      });

      if (mounted) {
        _titleCtrl.clear();
        _bodyCtrl.clear();
        setState(() {
          _pickedImage = null;
          _endDate = null;
          _audience = 'all';
          _sending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Announcement published to '
              'Loyalty App'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                ErrorHandler.friendlyMessage(e)),
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
          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.green
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Colors.green
                      .withValues(alpha: 0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.phone_android,
                  size: 16, color: Colors.green),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Announcements are published directly '
                  'to the Struisbaai Vleismark loyalty '
                  'app. Customers will see them in the '
                  'News section.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.green),
                ),
              ),
            ]),
          ),

          // Title
          TextFormField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Title *',
              hintText:
                  'e.g. Weekend Special — Rump Steak',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Body
          TextField(
            controller: _bodyCtrl,
            maxLines: 6,
            maxLength: 1500,
            decoration: const InputDecoration(
              labelText: 'Message *',
              hintText:
                  'Tell your customers about the '
                  'special or announcement...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),

          // Image picker
          Row(children: [
            const Text('Image (optional)',
                style: TextStyle(
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            if (_pickedImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_pickedImage!,
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(
                    () => _pickedImage = null),
              ),
            ] else
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(
                    Icons.add_photo_alternate),
                label: const Text('Add image'),
              ),
          ]),
          const SizedBox(height: 16),

          // Audience
          const Text('Who sees this?',
              style: TextStyle(
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _audienceOptions.map((opt) {
              final selected = _audience == opt.$1;
              return ChoiceChip(
                label: Text(opt.$2),
                selected: selected,
                selectedColor: AppColors.primary
                    .withValues(alpha: 0.15),
                onSelected: (_) => setState(
                    () => _audience = opt.$1),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // End date
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _endDate == null
                  ? 'Expiry date (optional)'
                  : 'Expires: ${_endDate!.day}/'
                      '${_endDate!.month}/'
                      '${_endDate!.year}',
            ),
            subtitle: const Text(
              'Leave empty to show indefinitely',
              style: TextStyle(fontSize: 11),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_endDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear,
                        size: 18),
                    onPressed: () => setState(
                        () => _endDate = null),
                  ),
                IconButton(
                  icon: const Icon(
                      Icons.calendar_today,
                      size: 18),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now()
                          .add(const Duration(
                              days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) {
                      setState(() => _endDate = d);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Publish button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _publish,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white))
                  : const Icon(
                      Icons.publish_rounded),
              label: Text(
                _sending
                    ? 'Publishing...'
                    : 'Publish to Loyalty App',
                style: const TextStyle(
                    fontWeight: FontWeight.w700),
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
  State<_HistoryTab> createState() =>
      _HistoryTabState();
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
          .from('announcements')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      if (mounted) {
        setState(() {
          _history =
              List<Map<String, dynamic>>.from(res);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deactivate(String id) async {
    await _client
        .from('announcements')
        .update({'is_active': false})
        .eq('id', id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator());
    }
    if (_history.isEmpty) {
      return const Center(
          child: Text(
              'No announcements published yet.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final row = _history[i];
          final createdAt = row['created_at'] != null
              ? DateTime.tryParse(
                  row['created_at'].toString())
              : null;
          final endDate = row['end_date'] != null
              ? DateTime.tryParse(
                  row['end_date'].toString())
              : null;
          final isActive =
              row['is_active'] as bool? ?? false;
          final audience =
              row['target_audience']
                  ?.toString() ??
                  'all';

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        row['title']?.toString() ??
                            '—',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        isActive
                            ? 'Live'
                            : 'Inactive',
                        style: const TextStyle(
                            fontSize: 10),
                      ),
                      backgroundColor: isActive
                          ? AppColors.success
                              .withValues(alpha: 0.15)
                          : AppColors.border,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize:
                          MaterialTapTargetSize
                              .shrinkWrap,
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () =>
                            _deactivate(
                                row['id'].toString()),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              AppColors.error,
                          padding:
                              const EdgeInsets
                                  .symmetric(
                                  horizontal: 8),
                        ),
                        child: const Text(
                            'Deactivate',
                            style: TextStyle(
                                fontSize: 11)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    row['content']?.toString() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors
                            .textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(
                        Icons.people_outline,
                        size: 12,
                        color:
                            AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      audience == 'all'
                          ? 'All members'
                          : '${audience[0].toUpperCase()}${audience.substring(1)}+',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors
                              .textSecondary),
                    ),
                    const SizedBox(width: 12),
                    if (createdAt != null) ...[
                      const Icon(Icons.calendar_today,
                          size: 12,
                          color: AppColors
                              .textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors
                                .textSecondary),
                      ),
                    ],
                    if (endDate != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        'Expires ${endDate.day}/${endDate.month}/${endDate.year}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.orange),
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
