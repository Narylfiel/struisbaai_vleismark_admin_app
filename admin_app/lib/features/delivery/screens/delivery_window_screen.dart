import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import '../services/delivery_window_service.dart';

class DeliveryWindowScreen extends StatefulWidget {
  const DeliveryWindowScreen({super.key});

  @override
  State<DeliveryWindowScreen> createState() => _DeliveryWindowScreenState();
}

class _DeliveryWindowScreenState extends State<DeliveryWindowScreen> {
  final DeliveryWindowService _service = DeliveryWindowService();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  List<Map<String, dynamic>> _windows = [];
  final Map<String, int> _heldOrderCounts = {};

  @override
  void initState() {
    super.initState();
    _loadWindows();
  }

  Future<void> _loadWindows() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rows = await _service.fetchWindows();
      final counts = <String, int>{};
      for (final row in rows) {
        final id = row['id']?.toString();
        if (id == null || id.isEmpty) continue;
        counts[id] = await _service.countHeldOrders(id);
      }

      if (!mounted) return;
      setState(() {
        _windows = rows;
        _heldOrderCounts
          ..clear()
          ..addAll(counts);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openCreateDialog() async {
    final titleController = TextEditingController();
    DateTime? deliveryDate;
    DateTime? opensAt;
    DateTime? closesAt;

    Future<void> pickDeliveryDate(StateSetter setDialog) async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now.subtract(const Duration(days: 365)),
        lastDate: now.add(const Duration(days: 365 * 2)),
      );
      if (picked != null) setDialog(() => deliveryDate = picked);
    }

    Future<void> pickDateTime({
      required bool isOpen,
      required StateSetter setDialog,
    }) async {
      final base = deliveryDate ?? DateTime.now();
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: base,
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      );
      if (pickedDate == null) return;
      if (!mounted) return;

      final pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
      );
      if (pickedTime == null) return;

      final dateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      setDialog(() {
        if (isOpen) {
          opensAt = dateTime;
        } else {
          closesAt = dateTime;
        }
      });
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            return AlertDialog(
              title: const Text('Create Window'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PickerTile(
                      label: 'Delivery date',
                      value: _formatDate(deliveryDate),
                      onTap: () => pickDeliveryDate(setDialog),
                    ),
                    const SizedBox(height: 8),
                    _PickerTile(
                      label: 'Opens at',
                      value: _formatDateTime(opensAt),
                      onTap: () => pickDateTime(isOpen: true, setDialog: setDialog),
                    ),
                    const SizedBox(height: 8),
                    _PickerTile(
                      label: 'Closes at',
                      value: _formatDateTime(closesAt),
                      onTap: () =>
                          pickDateTime(isOpen: false, setDialog: setDialog),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty ||
                        deliveryDate == null ||
                        opensAt == null ||
                        closesAt == null) {
                      _snack('Please complete all fields', isError: true);
                      return;
                    }
                    if (!closesAt!.isAfter(opensAt!)) {
                      _snack('Closes at must be after opens at', isError: true);
                      return;
                    }

                    try {
                      await _service.createWindow(
                        title: title,
                        deliveryDate: deliveryDate!,
                        opensAt: opensAt!,
                        closesAt: closesAt!,
                      );
                      if (!mounted) return;
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      _snack('Delivery window created');
                      await _loadWindows();
                    } catch (e) {
                      _snack('Failed to create window: $e', isError: true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _applyStatus(String id, String status) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      if (status == 'confirmed') {
        await _service.confirmWindow(id);
        _snack('Window confirmed');
      } else {
        await _service.updateWindowStatus(id, status);
        _snack('Window updated');
      }
      await _loadWindows();
    } catch (e) {
      _snack('Action failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Window'),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.cardBg,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Delivery Windows',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadWindows,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _error != null
                    ? Center(
                        child: Text(
                          'Error: $_error',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      )
                    : _windows.isEmpty
                        ? const Center(child: Text('No delivery windows yet'))
                        : RefreshIndicator(
                            onRefresh: _loadWindows,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _windows.length,
                              itemBuilder: (context, index) {
                                final w = _windows[index];
                                final id = w['id']?.toString() ?? '';
                                final status = (w['status'] as String?) ?? 'draft';
                                final heldCount = _heldOrderCounts[id] ?? 0;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                (w['title'] as String?) ?? 'Untitled window',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            _StatusBadge(status: status),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text('Delivery date: ${w['delivery_date'] ?? '-'}'),
                                        Text(
                                          'Opens: ${_formatIsoDateTime(w['opens_at']?.toString())}',
                                        ),
                                        Text(
                                          'Closes: ${_formatIsoDateTime(w['closes_at']?.toString())}',
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Held orders: $heldCount',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: _actionButtons(
                                            status: status,
                                            onOpen: () => _applyStatus(id, 'open'),
                                            onConfirm: () => _applyStatus(id, 'confirmed'),
                                            onClose: () => _applyStatus(id, 'closed'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  List<Widget> _actionButtons({
    required String status,
    required VoidCallback onOpen,
    required VoidCallback onConfirm,
    required VoidCallback onClose,
  }) {
    if (status == 'draft') {
      return [
        ElevatedButton(
          onPressed: _isSubmitting ? null : onOpen,
          child: const Text('Open Window'),
        ),
      ];
    }
    if (status == 'open') {
      return [
        ElevatedButton(
          onPressed: _isSubmitting ? null : onConfirm,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Confirm Delivery'),
        ),
        OutlinedButton(
          onPressed: _isSubmitting ? null : onClose,
          child: const Text('Close Window'),
        ),
      ];
    }
    if (status == 'confirmed') {
      return [
        OutlinedButton(
          onPressed: _isSubmitting ? null : onClose,
          child: const Text('Close Window'),
        ),
      ];
    }
    return const [];
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Select date & time';
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatIsoDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return _formatDateTime(dt.toLocal());
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'draft' => ('Draft', AppColors.textSecondary),
      'open' => ('Open', AppColors.info),
      'confirmed' => ('Confirmed', AppColors.success),
      'closed' => ('Closed', AppColors.warning),
      'cancelled' => ('Cancelled', AppColors.error),
      _ => (status, AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PickerTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(value),
                ],
              ),
            ),
            const Icon(Icons.calendar_month, size: 18),
          ],
        ),
      ),
    );
  }
}
