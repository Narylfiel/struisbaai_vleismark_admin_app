import '../../../core/models/base_model.dart';

DateTime? _parseDateTime(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());

/// Blueprint §5.6: Dryer batch — Biltong/Droewors/Chilli Bites; input → output; weight loss tracking.
/// DB CHECK: loading, drying, complete (no cancelled).
enum DryerBatchStatus {
  loading,
  drying,
  complete,
}

extension DryerBatchStatusExt on DryerBatchStatus {
  String get dbValue {
    switch (this) {
      case DryerBatchStatus.loading:
        return 'loading';
      case DryerBatchStatus.drying:
        return 'drying';
      case DryerBatchStatus.complete:
        return 'complete';
    }
  }

  /// User-friendly label for UI (DB value is lowercase).
  String get displayLabel {
    switch (this) {
      case DryerBatchStatus.loading:
        return 'Loading';
      case DryerBatchStatus.drying:
        return 'In Dryer';
      case DryerBatchStatus.complete:
        return 'Complete';
    }
  }

  static DryerBatchStatus fromDb(String? value) {
    switch (value) {
      case 'loading':
        return DryerBatchStatus.loading;
      case 'drying':
        return DryerBatchStatus.drying;
      case 'complete':
        return DryerBatchStatus.complete;
      default:
        return DryerBatchStatus.drying;
    }
  }
}

/// Blueprint: Biltong / Droewors / Chilli Bites / Other
enum DryerType {
  biltong,
  droewors,
  jerky,
  chilliBites,
  other,
}

extension DryerTypeExt on DryerType {
  String get dbValue {
    switch (this) {
      case DryerType.biltong:
        return 'biltong';
      case DryerType.droewors:
        return 'droewors';
      case DryerType.jerky:
        return 'jerky';
      case DryerType.chilliBites:
        return 'chilli_bites';
      case DryerType.other:
        return 'other';
    }
  }

  static DryerType fromDb(String? value) {
    switch (value) {
      case 'droewors':
        return DryerType.droewors;
      case 'jerky':
        return DryerType.jerky;
      case 'chilli_bites':
        return DryerType.chilliBites;
      case 'other':
        return DryerType.other;
      default:
        return DryerType.biltong;
    }
  }
}

class DryerBatch extends BaseModel {
  final String batchNumber;
  final String productName;
  final double inputWeightKg;
  final double? outputWeightKg;
  final DryerType dryerType;
  final DryerBatchStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? processedBy;
  final String? notes;
  /// Blueprint: Raw material (e.g. beef topside)
  final String? inputProductId;
  /// Blueprint: Finished product (e.g. biltong PLU)
  final String? outputProductId;
  final String? recipeId;

  const DryerBatch({
    required super.id,
    required this.batchNumber,
    required this.productName,
    required this.inputWeightKg,
    this.outputWeightKg,
    this.dryerType = DryerType.biltong,
    this.status = DryerBatchStatus.drying, // default; DB allows loading, drying, complete
    this.startedAt,
    this.completedAt,
    this.processedBy,
    this.notes,
    this.inputProductId,
    this.outputProductId,
    this.recipeId,
    super.createdAt,
    super.updatedAt,
  });

  double? get shrinkagePct {
    if (inputWeightKg <= 0 || outputWeightKg == null) return null;
    return ((inputWeightKg - outputWeightKg!) / inputWeightKg) * 100;
  }

  double? get yieldPct {
    if (inputWeightKg <= 0 || outputWeightKg == null) return null;
    return (outputWeightKg! / inputWeightKg) * 100;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_number': batchNumber,
      'product_name': productName,
      'input_weight_kg': inputWeightKg,
      'output_weight_kg': outputWeightKg,
      'dryer_type': dryerType.dbValue,
      'status': status.dbValue,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'processed_by': processedBy,
      'notes': notes,
      'input_product_id': inputProductId,
      'output_product_id': outputProductId,
      'recipe_id': recipeId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory DryerBatch.fromJson(Map<String, dynamic> json) {
    return DryerBatch(
      id: json['id'] as String,
      batchNumber: json['batch_number'] as String? ?? '',
      productName: json['product_name'] as String? ?? '',
      inputWeightKg: ((json['input_weight_kg'] ?? json['weight_in']) as num?)?.toDouble() ?? 0,
      outputWeightKg: ((json['output_weight_kg'] ?? json['weight_out']) as num?)?.toDouble(),
      dryerType: DryerTypeExt.fromDb(json['dryer_type'] as String?),
      status: DryerBatchStatusExt.fromDb(json['status'] as String?),
      startedAt: _parseDateTime(json['started_at']) ?? _parseDateTime(json['start_date']),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      processedBy: json['processed_by'] as String?,
      notes: json['notes'] as String?,
      inputProductId: json['input_product_id'] as String?,
      outputProductId: json['output_product_id'] as String?,
      recipeId: json['recipe_id'] as String?,
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
      batchNumber.trim().isNotEmpty &&
      productName.trim().isNotEmpty &&
      inputWeightKg > 0;

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (batchNumber.trim().isEmpty) errors.add('Batch number is required');
    if (productName.trim().isEmpty) errors.add('Product name is required');
    if (inputWeightKg <= 0) errors.add('Input weight must be positive');
    return errors;
  }
}
