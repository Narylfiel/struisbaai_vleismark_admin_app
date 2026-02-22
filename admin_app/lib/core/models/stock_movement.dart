import 'base_model.dart';

/// Blueprint §4.5: Stock lifecycle actions — every stock change creates a movement record.
/// §15: stock_movements — Production/Inventory (all types).
enum MovementType {
  in_,
  out,
  adjustment,
  transfer,
  waste,
  production,
  donation,
  sponsorship,
  staffMeal,
  freezer,
}

extension MovementTypeExt on MovementType {
  String get dbValue {
    switch (this) {
      case MovementType.in_:
        return 'in';
      case MovementType.out:
        return 'out';
      case MovementType.adjustment:
        return 'adjustment';
      case MovementType.transfer:
        return 'transfer';
      case MovementType.waste:
        return 'waste';
      case MovementType.production:
        return 'production';
      case MovementType.donation:
        return 'donation';
      case MovementType.sponsorship:
        return 'sponsorship';
      case MovementType.staffMeal:
        return 'staff_meal';
      case MovementType.freezer:
        return 'freezer';
    }
  }

  static MovementType fromDb(String? value) {
    switch (value) {
      case 'in':
        return MovementType.in_;
      case 'out':
        return MovementType.out;
      case 'adjustment':
        return MovementType.adjustment;
      case 'transfer':
        return MovementType.transfer;
      case 'waste':
        return MovementType.waste;
      case 'production':
        return MovementType.production;
      case 'donation':
        return MovementType.donation;
      case 'sponsorship':
        return MovementType.sponsorship;
      case 'staff_meal':
        return MovementType.staffMeal;
      case 'freezer':
        return MovementType.freezer;
      default:
        return MovementType.out;
    }
  }

  bool get reducesStock {
    return this == MovementType.out ||
        this == MovementType.waste ||
        this == MovementType.donation ||
        this == MovementType.sponsorship ||
        this == MovementType.staffMeal ||
        this == MovementType.freezer; // fresh reduced, frozen increased elsewhere
  }

  bool get increasesStock {
    return this == MovementType.in_ || this == MovementType.production;
  }
}

/// Stock movement record — blueprint §4.5, §15.
class StockMovement extends BaseModel {
  final String itemId;
  final MovementType movementType;
  final double quantity;
  final double? unitCost;
  final double? totalCost;
  final String? referenceType;
  final String? referenceId;
  final String? locationFromId;
  final String? locationToId;
  final String performedBy;
  final DateTime? performedAt;
  final String? notes;
  final Map<String, dynamic>? metadata;

  const StockMovement({
    required super.id,
    required this.itemId,
    required this.movementType,
    required this.quantity,
    this.unitCost,
    this.totalCost,
    this.referenceType,
    this.referenceId,
    this.locationFromId,
    this.locationToId,
    required this.performedBy,
    this.performedAt,
    this.notes,
    this.metadata,
    super.createdAt,
    super.updatedAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'movement_type': movementType.dbValue,
      'quantity': quantity,
      'unit_cost': unitCost,
      'total_cost': totalCost,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'location_from': locationFromId,
      'location_to': locationToId,
      'performed_by': performedBy,
      'performed_at': performedAt?.toIso8601String(),
      'notes': notes,
      'metadata': metadata,
    };
  }

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      movementType: MovementTypeExt.fromDb(json['movement_type'] as String?),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitCost: (json['unit_cost'] as num?)?.toDouble(),
      totalCost: (json['total_cost'] as num?)?.toDouble(),
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
      locationFromId: json['location_from'] as String?,
      locationToId: json['location_to'] as String?,
      performedBy: json['performed_by'] as String? ?? '',
      performedAt: json['performed_at'] != null
          ? DateTime.tryParse(json['performed_at'] as String)
          : null,
      notes: json['notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  bool validate() {
    return itemId.isNotEmpty && performedBy.isNotEmpty && quantity >= 0;
  }

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (itemId.isEmpty) errors.add('Item is required');
    if (performedBy.isEmpty) errors.add('Performed by is required');
    if (quantity < 0) errors.add('Quantity cannot be negative');
    return errors;
  }
}
