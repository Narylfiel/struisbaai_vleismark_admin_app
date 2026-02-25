import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';

/// Search-based product picker. Never loads all products; queries with LIMIT 20, min 2 chars.
class ProductSearchPicker extends StatefulWidget {
  final String label;
  final List<Map<String, dynamic>> selectedProducts;
  final Function(Map<String, dynamic>) onAdd;
  final Function(String) onRemove;
  final bool singleSelect;
  final bool readOnly;

  const ProductSearchPicker({
    super.key,
    required this.label,
    required this.selectedProducts,
    required this.onAdd,
    required this.onRemove,
    this.singleSelect = false,
    this.readOnly = false,
  });

  @override
  State<ProductSearchPicker> createState() => _ProductSearchPickerState();
}

class _ProductSearchPickerState extends State<ProductSearchPicker> {
  final _client = SupabaseService.client;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;
  bool _categoriesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final r = await _client
          .from('categories')
          .select('id, name')
          .eq('is_active', true)
          .order('name');
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(r as List);
          _categoriesLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _categoriesLoaded = true);
    }
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim();
    if (q.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    _runSearch(q);
  }

  Future<void> _runSearch(String query) async {
    setState(() => _searching = true);
    try {
      final pattern = '%$query%';
      var q = _client
          .from('inventory_items')
          .select('id, name, plu_code, category_id')
          .eq('is_active', true);
      if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
        q = q.eq('category_id', _selectedCategoryId!);
      }
      final r = await q.or('name.ilike.$pattern,plu_code.ilike.$pattern').limit(20);
      if (mounted) {
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(r as List);
          _searching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _onCategoryChanged(String? id) {
    setState(() => _selectedCategoryId = id);
    final q = _searchController.text.trim();
    if (q.length >= 2) _runSearch(q);
  }

  String _categoryName(String? id) {
    if (id == null) return 'All';
    for (final c in _categories) {
      if (c['id']?.toString() == id) return c['name'] as String? ?? 'All';
    }
    return 'All';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        if (!widget.readOnly) ...[
          Row(
            children: [
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  hint: const Text('All categories'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All categories')),
                    ..._categories.map((c) {
                      final name = c['name'] as String? ?? '';
                      return DropdownMenuItem<String>(
                        value: c['id'] as String?,
                        child: Text(name.length > 18 ? '${name.substring(0, 18)}…' : name),
                      );
                    }),
                  ],
                  onChanged: _categoriesLoaded ? _onCategoryChanged : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Search by name or PLU (min 2 chars)',
                    isDense: true,
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                  onChanged: (_) => _onSearchChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_searchController.text.trim().length >= 2)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _searching
                  ? const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (_, i) {
                        final p = _searchResults[i];
                        final id = p['id'] as String?;
                        final name = p['name'] as String? ?? '';
                        final plu = p['plu_code']?.toString() ?? '';
                        final alreadySelected = id != null &&
                            widget.selectedProducts.any((s) => s['id']?.toString() == id);
                        return ListTile(
                          dense: true,
                          title: Text(name),
                          subtitle: plu.isNotEmpty ? Text('PLU: $plu') : null,
                          onTap: alreadySelected || widget.readOnly
                              ? null
                              : () {
                                  if (widget.singleSelect) {
                                    for (final s in widget.selectedProducts) {
                                      widget.onRemove(s['id']?.toString() ?? '');
                                    }
                                  }
                                  widget.onAdd(p);
                                  _searchController.clear();
                                  setState(() => _searchResults = []);
                                },
                        );
                      },
                    ),
            ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.selectedProducts.map((p) {
            final id = p['id']?.toString() ?? '';
            final name = p['name'] as String? ?? id;
            return Chip(
              label: Text(name.length > 24 ? '${name.substring(0, 24)}…' : name),
              deleteIcon: widget.readOnly ? null : const Icon(Icons.close, size: 18),
              onDeleted: widget.readOnly ? null : () => widget.onRemove(id),
            );
          }).toList(),
        ),
      ],
    );
  }
}
