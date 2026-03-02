import 'package:isar/isar.dart';

part 'cached_dryer_batch.g.dart';

@collection
class CachedDryerBatch {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String batchId;

  String? status;
  DateTime? startDate;
  DateTime? endDate;
  double? weightIn;
  double? weightOut;
  double? shrinkagePct;
  String? notes;
  String? outputProductId;
  String? outputProductName;
  late DateTime cachedAt;

  CachedDryerBatch();

  factory CachedDryerBatch.fromSupabase(Map<String, dynamic> row) {
    final c = CachedDryerBatch();
    c.batchId = row['id']?.toString() ?? '';
    c.status = row['status']?.toString();
    c.startDate = row['start_date'] != null ? DateTime.tryParse(row['start_date'].toString()) : null;
    c.endDate = row['end_date'] != null ? DateTime.tryParse(row['end_date'].toString()) : null;
    c.weightIn = (row['weight_in'] as num?)?.toDouble();
    c.weightOut = (row['weight_out'] as num?)?.toDouble();
    c.shrinkagePct = (row['shrinkage_pct'] as num?)?.toDouble();
    c.notes = row['notes']?.toString();
    c.outputProductId = row['output_product_id']?.toString();
    c.outputProductName = row['output_product_name']?.toString();
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  Map<String, dynamic> toMap() => {
        'id': batchId,
        'status': status,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'weight_in': weightIn,
        'weight_out': weightOut,
        'shrinkage_pct': shrinkagePct,
        'notes': notes,
        'output_product_id': outputProductId,
        'output_product_name': outputProductName,
      };
}
