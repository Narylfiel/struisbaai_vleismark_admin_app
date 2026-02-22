import '../../../core/models/base_model.dart';

/// Blueprint §5.6: Dryer batch ingredient — spices, vinegar, casings used.
class DryerBatchIngredient extends BaseModel {
  final String batchId;
  final String inventoryItemId;
  final double quantityUsed;
  final DateTime? addedAt;

  const DryerBatchIngredient({
    required super.id,
    required this.batchId,
    required this.inventoryItemId,
    required this.quantityUsed,
    this.addedAt,
    super.createdAt,
    super.updatedAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_id': batchId,
      'inventory_item_id': inventoryItemId,
      'quantity_used': quantityUsed,
      'added_at': addedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory DryerBatchIngredient.fromJson(Map<String, dynamic> json) {
    return DryerBatchIngredient(
      id: json['id'] as String,
      batchId: json['batch_id'] as String? ?? '',
      inventoryItemId: json['inventory_item_id'] as String? ?? '',
      quantityUsed: (json['quantity_used'] as num?)?.toDouble() ?? 0,
      addedAt: json['added_at'] != null
          ? DateTime.tryParse(json['added_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  bool validate() =>
      batchId.isNotEmpty &&
      inventoryItemId.isNotEmpty &&
      quantityUsed >= 0;

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (batchId.isEmpty) errors.add('Batch is required');
    if (inventoryItemId.isEmpty) errors.add('Item is required');
    if (quantityUsed < 0) errors.add('Quantity must be non-negative');
    return errors;
  }
}
