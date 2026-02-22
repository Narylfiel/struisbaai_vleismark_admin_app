import '../../../core/models/base_model.dart';

/// Blueprint §4.3: Modifier Group — e.g. Sauce Options.
/// POS shows this group as a pop-up when product has it linked.
class ModifierGroup extends BaseModel {
  final String name;
  final String? description;
  final bool isActive;
  final int sortOrder;
  /// Blueprint: Required? (optional = false)
  final bool required_;
  /// Blueprint: Allow Multiple? (pick one = false)
  final bool allowMultiple;
  /// Blueprint: Max Selections (e.g. 1)
  final int maxSelections;

  const ModifierGroup({
    required super.id,
    required this.name,
    this.description,
    this.isActive = true,
    this.sortOrder = 0,
    this.required_ = false,
    this.allowMultiple = false,
    this.maxSelections = 1,
    super.createdAt,
    super.updatedAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_active': isActive,
      'sort_order': sortOrder,
      'is_required': required_,
      'allow_multiple': allowMultiple,
      'max_selections': maxSelections,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory ModifierGroup.fromJson(Map<String, dynamic> json) {
    return ModifierGroup(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      required_: json['is_required'] as bool? ?? false,
      allowMultiple: json['allow_multiple'] as bool? ?? false,
      maxSelections: (json['max_selections'] as num?)?.toInt() ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  bool validate() => name.trim().isNotEmpty;

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (name.trim().isEmpty) errors.add('Group name is required');
    if (maxSelections < 1) errors.add('Max selections must be at least 1');
    return errors;
  }
}
