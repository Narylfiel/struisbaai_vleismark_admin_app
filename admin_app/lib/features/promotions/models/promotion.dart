import '../../../core/models/base_model.dart';
import 'promotion_product.dart';

/// Status lifecycle: draft → active → paused → expired → cancelled.
enum PromotionStatus {
  draft,
  active,
  paused,
  expired,
  cancelled,
}

extension PromotionStatusExt on PromotionStatus {
  String get dbValue {
    switch (this) {
      case PromotionStatus.draft:
        return 'draft';
      case PromotionStatus.active:
        return 'active';
      case PromotionStatus.paused:
        return 'paused';
      case PromotionStatus.expired:
        return 'expired';
      case PromotionStatus.cancelled:
        return 'cancelled';
    }
  }

  static PromotionStatus fromDb(String? value) {
    switch (value) {
      case 'draft':
        return PromotionStatus.draft;
      case 'active':
        return PromotionStatus.active;
      case 'paused':
        return PromotionStatus.paused;
      case 'expired':
        return PromotionStatus.expired;
      case 'cancelled':
        return PromotionStatus.cancelled;
      default:
        return PromotionStatus.draft;
    }
  }
}

/// Promotion types and their trigger_config structure (see spec).
enum PromotionType {
  bogo,
  bundle,
  spendThreshold,
  weightThreshold,
  timeBased,
  pointsMultiplier,
  custom,
}

extension PromotionTypeExt on PromotionType {
  String get dbValue {
    switch (this) {
      case PromotionType.bogo:
        return 'bogo';
      case PromotionType.bundle:
        return 'bundle';
      case PromotionType.spendThreshold:
        return 'spend_threshold';
      case PromotionType.weightThreshold:
        return 'weight_threshold';
      case PromotionType.timeBased:
        return 'time_based';
      case PromotionType.pointsMultiplier:
        return 'points_multiplier';
      case PromotionType.custom:
        return 'custom';
    }
  }

  static PromotionType fromDb(String? value) {
    switch (value) {
      case 'bogo':
        return PromotionType.bogo;
      case 'bundle':
        return PromotionType.bundle;
      case 'spend_threshold':
        return PromotionType.spendThreshold;
      case 'weight_threshold':
        return PromotionType.weightThreshold;
      case 'time_based':
        return PromotionType.timeBased;
      case 'points_multiplier':
        return PromotionType.pointsMultiplier;
      case 'custom':
        return PromotionType.custom;
      default:
        return PromotionType.custom;
    }
  }
}

/// Promotion model — matches DB: promotions table.
class Promotion extends BaseModel {
  final String name;
  final String? description;
  final PromotionStatus status;
  final PromotionType promotionType;
  /// JSON structure depends on promotion_type (e.g. bogo: buy_quantity, get_quantity).
  final Map<String, dynamic> triggerConfig;
  /// Reward definition (e.g. type: free_item, discount_pct, etc.).
  final Map<String, dynamic> rewardConfig;
  /// Multi-select array: all, loyalty_*, staff_only, new_customers.
  final List<String> audience;
  /// Multi-select array: pos, loyalty_app, online.
  final List<String> channels;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? startTime; // e.g. "14:00"
  final String? endTime;
  /// Comma or array: days of week (0=Sun..6=Sat or Mon-Sun labels).
  final List<String> daysOfWeek;
  final int? usageLimit;
  final int usageCount;
  final bool requiresManualActivation;
  final String? createdBy;
  /// Filled by repository when loading (join promotion_products).
  List<PromotionProduct> products = [];

  Promotion({
    required super.id,
    required this.name,
    this.description,
    this.status = PromotionStatus.draft,
    required this.promotionType,
    this.triggerConfig = const {},
    this.rewardConfig = const {},
    this.audience = const ['all'],
    this.channels = const ['pos'],
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.daysOfWeek = const [],
    this.usageLimit,
    this.usageCount = 0,
    this.requiresManualActivation = false,
    this.createdBy,
    super.createdAt,
    super.updatedAt,
  });

  /// status == active AND within date/time range (and usage limit if set).
  bool get isCurrentlyActive {
    if (status != PromotionStatus.active) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(DateTime(startDate!.year, startDate!.month, startDate!.day))) return false;
    if (endDate != null && now.isAfter(DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59))) return false;
    if (usageLimit != null && usageCount >= usageLimit!) return false;
    return true;
  }

  /// If end_date has passed, show as Expired regardless of status.
  String get displayStatus {
    if (endDate != null && DateTime.now().isAfter(DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59))) {
      return 'Expired';
    }
    return status.dbValue[0].toUpperCase() + status.dbValue.substring(1);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status.dbValue,
      'promotion_type': promotionType.dbValue,
      'trigger_config': triggerConfig,
      'reward_config': rewardConfig,
      'audience': audience,
      'channels': channels,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'days_of_week': daysOfWeek,
      'usage_limit': usageLimit,
      'usage_count': usageCount,
      'requires_manual_activation': requiresManualActivation,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Promotion.fromJson(Map<String, dynamic> json) {
    List<String> listFrom(dynamic v) {
      if (v == null) return [];
      if (v is List) return v.map((e) => e.toString()).toList();
      if (v is String) return v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      return [];
    }
    return Promotion(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      status: PromotionStatusExt.fromDb(json['status'] as String?),
      promotionType: PromotionTypeExt.fromDb(json['promotion_type'] as String?),
      triggerConfig: (json['trigger_config'] is Map<String, dynamic>) ? json['trigger_config'] as Map<String, dynamic> : (json['trigger_config'] != null ? Map<String, dynamic>.from(json['trigger_config'] as Map) : {}),
      rewardConfig: (json['reward_config'] is Map<String, dynamic>) ? json['reward_config'] as Map<String, dynamic> : (json['reward_config'] != null ? Map<String, dynamic>.from(json['reward_config'] as Map) : {}),
      audience: listFrom(json['audience']),
      channels: listFrom(json['channels']),
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date'] as String) : null,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      daysOfWeek: listFrom(json['days_of_week']),
      usageLimit: (json['usage_limit'] as num?)?.toInt(),
      usageCount: (json['usage_count'] as num?)?.toInt() ?? 0,
      requiresManualActivation: json['requires_manual_activation'] as bool? ?? false,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  @override
  bool validate() => name.trim().isNotEmpty;

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (name.trim().isEmpty) errors.add('Name is required');
    return errors;
  }

  Promotion copyWith({
    String? id,
    String? name,
    String? description,
    PromotionStatus? status,
    PromotionType? promotionType,
    Map<String, dynamic>? triggerConfig,
    Map<String, dynamic>? rewardConfig,
    List<String>? audience,
    List<String>? channels,
    DateTime? startDate,
    DateTime? endDate,
    String? startTime,
    String? endTime,
    List<String>? daysOfWeek,
    int? usageLimit,
    int? usageCount,
    bool? requiresManualActivation,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Promotion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      promotionType: promotionType ?? this.promotionType,
      triggerConfig: triggerConfig ?? this.triggerConfig,
      rewardConfig: rewardConfig ?? this.rewardConfig,
      audience: audience ?? this.audience,
      channels: channels ?? this.channels,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      usageLimit: usageLimit ?? this.usageLimit,
      usageCount: usageCount ?? this.usageCount,
      requiresManualActivation: requiresManualActivation ?? this.requiresManualActivation,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
