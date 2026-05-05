import 'package:isar/isar.dart';

part 'cached_carcass_intake.g.dart';

@collection
class CachedCarcassIntake {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String intakeId;

  DateTime? intakeDate;
  String? species;
  String? supplierId;
  String? supplierName;
  double? weightIn;
  String? status;
  String? jobType;
  late DateTime cachedAt;

  CachedCarcassIntake();

  factory CachedCarcassIntake.fromSupabase(Map<String, dynamic> row) {
    final c = CachedCarcassIntake();
    c.intakeId = row['id']?.toString() ?? '';
    c.intakeDate = row['intake_date'] != null ? DateTime.tryParse(row['intake_date'].toString()) : null;
    c.species = row['species']?.toString();
    c.supplierId = row['supplier_id']?.toString();
    c.supplierName = row['supplier_name']?.toString();
    c.weightIn = (row['weight_in'] as num?)?.toDouble();
    c.status = row['status']?.toString();
    c.jobType = row['job_type']?.toString();
    c.cachedAt = DateTime.now().toUtc();
    return c;
  }

  Map<String, dynamic> toMap() => {
        'id': intakeId,
        'intake_date': intakeDate?.toIso8601String(),
        'species': species,
        'supplier_id': supplierId,
        'supplier_name': supplierName,
        'weight_in': weightIn,
        'status': status,
        'job_type': jobType,
      };
}
