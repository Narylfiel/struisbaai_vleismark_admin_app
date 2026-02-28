import 'package:isar/isar.dart';

part 'cached_hunter_job.g.dart';

/// Isar collection for hunter jobs cached for offline list view.
@collection
class CachedHunterJob {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String jobId;

  String? hunterName;
  String? contactPhone;
  String? species;
  double? estimatedWeight;
  String? status;
  double? chargeTotal;
  double? totalAmount;
  String? notes;
  DateTime? createdAt;
  DateTime? updatedAt;
  late DateTime cachedAt;

  CachedHunterJob();

  /// From Supabase hunter_jobs row.
  factory CachedHunterJob.fromSupabase(Map<String, dynamic> row) {
    final c = CachedHunterJob();
    c.jobId = row['id']?.toString() ?? '';
    c.hunterName = row['hunter_name']?.toString();
    c.contactPhone = row['contact_phone']?.toString();
    c.species = row['species']?.toString();
    c.estimatedWeight = (row['estimated_weight'] ?? row['weight_in'] as num?)?.toDouble();
    c.status = row['status']?.toString();
    c.chargeTotal = (row['charge_total'] as num?)?.toDouble();
    c.totalAmount = (row['total_amount'] as num?)?.toDouble();
    c.notes = row['processing_instructions']?.toString() ?? row['notes']?.toString();
    c.createdAt = row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null;
    c.updatedAt = row['updated_at'] != null ? DateTime.tryParse(row['updated_at'] as String) : null;
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  Map<String, dynamic> toListMap() {
    return {
      'id': jobId,
      'hunter_name': hunterName,
      'contact_phone': contactPhone,
      'species': species,
      'estimated_weight': estimatedWeight,
      'weight_in': estimatedWeight,
      'status': status,
      'charge_total': chargeTotal,
      'total_amount': totalAmount,
      'processing_instructions': notes,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
