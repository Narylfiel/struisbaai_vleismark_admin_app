// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_hunter_job.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedHunterJobCollection on Isar {
  IsarCollection<CachedHunterJob> get cachedHunterJobs => this.collection();
}

const CachedHunterJobSchema = CollectionSchema(
  name: r'CachedHunterJob',
  id: 4031978972058353603,
  properties: {
    r'cachedAt': PropertySchema(
      id: 0,
      name: r'cachedAt',
      type: IsarType.dateTime,
    ),
    r'chargeTotal': PropertySchema(
      id: 1,
      name: r'chargeTotal',
      type: IsarType.double,
    ),
    r'contactPhone': PropertySchema(
      id: 2,
      name: r'contactPhone',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'estimatedWeight': PropertySchema(
      id: 4,
      name: r'estimatedWeight',
      type: IsarType.double,
    ),
    r'hunterName': PropertySchema(
      id: 5,
      name: r'hunterName',
      type: IsarType.string,
    ),
    r'jobId': PropertySchema(
      id: 6,
      name: r'jobId',
      type: IsarType.string,
    ),
    r'notes': PropertySchema(
      id: 7,
      name: r'notes',
      type: IsarType.string,
    ),
    r'species': PropertySchema(
      id: 8,
      name: r'species',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 9,
      name: r'status',
      type: IsarType.string,
    ),
    r'totalAmount': PropertySchema(
      id: 10,
      name: r'totalAmount',
      type: IsarType.double,
    ),
    r'updatedAt': PropertySchema(
      id: 11,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _cachedHunterJobEstimateSize,
  serialize: _cachedHunterJobSerialize,
  deserialize: _cachedHunterJobDeserialize,
  deserializeProp: _cachedHunterJobDeserializeProp,
  idName: r'id',
  indexes: {
    r'jobId': IndexSchema(
      id: 7916160552736803877,
      name: r'jobId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'jobId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cachedHunterJobGetId,
  getLinks: _cachedHunterJobGetLinks,
  attach: _cachedHunterJobAttach,
  version: '3.1.0+1',
);

int _cachedHunterJobEstimateSize(
  CachedHunterJob object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.contactPhone;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.hunterName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.jobId.length * 3;
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.species;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.status;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _cachedHunterJobSerialize(
  CachedHunterJob object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.cachedAt);
  writer.writeDouble(offsets[1], object.chargeTotal);
  writer.writeString(offsets[2], object.contactPhone);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeDouble(offsets[4], object.estimatedWeight);
  writer.writeString(offsets[5], object.hunterName);
  writer.writeString(offsets[6], object.jobId);
  writer.writeString(offsets[7], object.notes);
  writer.writeString(offsets[8], object.species);
  writer.writeString(offsets[9], object.status);
  writer.writeDouble(offsets[10], object.totalAmount);
  writer.writeDateTime(offsets[11], object.updatedAt);
}

CachedHunterJob _cachedHunterJobDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedHunterJob();
  object.cachedAt = reader.readDateTime(offsets[0]);
  object.chargeTotal = reader.readDoubleOrNull(offsets[1]);
  object.contactPhone = reader.readStringOrNull(offsets[2]);
  object.createdAt = reader.readDateTimeOrNull(offsets[3]);
  object.estimatedWeight = reader.readDoubleOrNull(offsets[4]);
  object.hunterName = reader.readStringOrNull(offsets[5]);
  object.id = id;
  object.jobId = reader.readString(offsets[6]);
  object.notes = reader.readStringOrNull(offsets[7]);
  object.species = reader.readStringOrNull(offsets[8]);
  object.status = reader.readStringOrNull(offsets[9]);
  object.totalAmount = reader.readDoubleOrNull(offsets[10]);
  object.updatedAt = reader.readDateTimeOrNull(offsets[11]);
  return object;
}

P _cachedHunterJobDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readDoubleOrNull(offset)) as P;
    case 11:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedHunterJobGetId(CachedHunterJob object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedHunterJobGetLinks(CachedHunterJob object) {
  return [];
}

void _cachedHunterJobAttach(
    IsarCollection<dynamic> col, Id id, CachedHunterJob object) {
  object.id = id;
}

extension CachedHunterJobByIndex on IsarCollection<CachedHunterJob> {
  Future<CachedHunterJob?> getByJobId(String jobId) {
    return getByIndex(r'jobId', [jobId]);
  }

  CachedHunterJob? getByJobIdSync(String jobId) {
    return getByIndexSync(r'jobId', [jobId]);
  }

  Future<bool> deleteByJobId(String jobId) {
    return deleteByIndex(r'jobId', [jobId]);
  }

  bool deleteByJobIdSync(String jobId) {
    return deleteByIndexSync(r'jobId', [jobId]);
  }

  Future<List<CachedHunterJob?>> getAllByJobId(List<String> jobIdValues) {
    final values = jobIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'jobId', values);
  }

  List<CachedHunterJob?> getAllByJobIdSync(List<String> jobIdValues) {
    final values = jobIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'jobId', values);
  }

  Future<int> deleteAllByJobId(List<String> jobIdValues) {
    final values = jobIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'jobId', values);
  }

  int deleteAllByJobIdSync(List<String> jobIdValues) {
    final values = jobIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'jobId', values);
  }

  Future<Id> putByJobId(CachedHunterJob object) {
    return putByIndex(r'jobId', object);
  }

  Id putByJobIdSync(CachedHunterJob object, {bool saveLinks = true}) {
    return putByIndexSync(r'jobId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByJobId(List<CachedHunterJob> objects) {
    return putAllByIndex(r'jobId', objects);
  }

  List<Id> putAllByJobIdSync(List<CachedHunterJob> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'jobId', objects, saveLinks: saveLinks);
  }
}

extension CachedHunterJobQueryWhereSort
    on QueryBuilder<CachedHunterJob, CachedHunterJob, QWhere> {
  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CachedHunterJobQueryWhere
    on QueryBuilder<CachedHunterJob, CachedHunterJob, QWhereClause> {
  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterWhereClause>
      jobIdEqualTo(String jobId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'jobId',
        value: [jobId],
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterWhereClause>
      jobIdNotEqualTo(String jobId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'jobId',
              lower: [],
              upper: [jobId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'jobId',
              lower: [jobId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'jobId',
              lower: [jobId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'jobId',
              lower: [],
              upper: [jobId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CachedHunterJobQueryFilter
    on QueryBuilder<CachedHunterJob, CachedHunterJob, QFilterCondition> {
  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      cachedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      cachedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      cachedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      cachedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cachedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      chargeTotalIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'chargeTotal',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      chargeTotalIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'chargeTotal',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      chargeTotalEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chargeTotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      chargeTotalGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'chargeTotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      chargeTotalLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'chargeTotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      chargeTotalBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'chargeTotal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      contactPhoneIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'contactPhone',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      contactPhoneIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'contactPhone',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      contactPhoneEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contactPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      contactPhoneGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'contactPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      contactPhoneLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'contactPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      contactPhoneBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'contactPhone',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      contactPhoneStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'contactPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      contactPhoneEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'contactPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      contactPhoneContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'contactPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      contactPhoneMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'contactPhone',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      contactPhoneIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contactPhone',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      contactPhoneIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'contactPhone',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      createdAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      createdAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      createdAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      createdAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      createdAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      estimatedWeightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'estimatedWeight',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      estimatedWeightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'estimatedWeight',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      estimatedWeightEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'estimatedWeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      estimatedWeightGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'estimatedWeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      estimatedWeightLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'estimatedWeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      estimatedWeightBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'estimatedWeight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      hunterNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'hunterName',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      hunterNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'hunterName',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      hunterNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hunterName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      hunterNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hunterName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      hunterNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hunterName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      hunterNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hunterName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      hunterNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'hunterName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      hunterNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'hunterName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      hunterNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'hunterName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      hunterNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'hunterName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      hunterNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hunterName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      hunterNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'hunterName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      jobIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jobId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      jobIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'jobId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      jobIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'jobId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      jobIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'jobId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      jobIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'jobId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      jobIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'jobId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      jobIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'jobId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      jobIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'jobId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      jobIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jobId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      jobIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'jobId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      notesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      notesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      notesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      notesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      notesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      notesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      speciesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'species',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      speciesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'species',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      speciesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'species',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      speciesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'species',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      speciesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'species',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      speciesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'species',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      speciesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'species',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      speciesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'species',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      speciesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'species',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      speciesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'species',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      speciesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'species',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      speciesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'species',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      statusIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'status',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      statusIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'status',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      statusEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      statusGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      statusLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      statusBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      totalAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'totalAmount',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      totalAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'totalAmount',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      totalAmountEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      totalAmountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      totalAmountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      totalAmountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      updatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterFilterCondition>
      updatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CachedHunterJobQueryObject
    on QueryBuilder<CachedHunterJob, CachedHunterJob, QFilterCondition> {}

extension CachedHunterJobQueryLinks
    on QueryBuilder<CachedHunterJob, CachedHunterJob, QFilterCondition> {}

extension CachedHunterJobQuerySortBy
    on QueryBuilder<CachedHunterJob, CachedHunterJob, QSortBy> {
  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      sortByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      sortByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      sortByChargeTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chargeTotal', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      sortByChargeTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chargeTotal', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      sortByContactPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactPhone', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      sortByContactPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactPhone', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      sortByEstimatedWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimatedWeight', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      sortByEstimatedWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimatedWeight', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      sortByHunterName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hunterName', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      sortByHunterNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hunterName', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy> sortByJobId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobId', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      sortByJobIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobId', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy> sortBySpecies() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'species', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      sortBySpeciesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'species', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      sortByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      sortByTotalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension CachedHunterJobQuerySortThenBy
    on QueryBuilder<CachedHunterJob, CachedHunterJob, QSortThenBy> {
  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      thenByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      thenByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      thenByChargeTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chargeTotal', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      thenByChargeTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chargeTotal', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      thenByContactPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactPhone', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      thenByContactPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactPhone', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      thenByEstimatedWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimatedWeight', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      thenByEstimatedWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimatedWeight', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      thenByHunterName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hunterName', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      thenByHunterNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hunterName', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy> thenByJobId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobId', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      thenByJobIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobId', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy> thenBySpecies() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'species', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      thenBySpeciesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'species', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      thenByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      thenByTotalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension CachedHunterJobQueryWhereDistinct
    on QueryBuilder<CachedHunterJob, CachedHunterJob, QDistinct> {
  QueryBuilder<CachedHunterJob, CachedHunterJob, QDistinct>
      distinctByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedAt');
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QDistinct>
      distinctByChargeTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'chargeTotal');
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QDistinct>
      distinctByContactPhone({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contactPhone', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QDistinct>
      distinctByEstimatedWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'estimatedWeight');
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QDistinct>
      distinctByHunterName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hunterName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QDistinct> distinctByJobId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'jobId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QDistinct> distinctByNotes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QDistinct> distinctBySpecies(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'species', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QDistinct>
      distinctByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalAmount');
    });
  }

  QueryBuilder<CachedHunterJob, CachedHunterJob, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension CachedHunterJobQueryProperty
    on QueryBuilder<CachedHunterJob, CachedHunterJob, QQueryProperty> {
  QueryBuilder<CachedHunterJob, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedHunterJob, DateTime, QQueryOperations> cachedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedAt');
    });
  }

  QueryBuilder<CachedHunterJob, double?, QQueryOperations>
      chargeTotalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'chargeTotal');
    });
  }

  QueryBuilder<CachedHunterJob, String?, QQueryOperations>
      contactPhoneProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contactPhone');
    });
  }

  QueryBuilder<CachedHunterJob, DateTime?, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<CachedHunterJob, double?, QQueryOperations>
      estimatedWeightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'estimatedWeight');
    });
  }

  QueryBuilder<CachedHunterJob, String?, QQueryOperations>
      hunterNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hunterName');
    });
  }

  QueryBuilder<CachedHunterJob, String, QQueryOperations> jobIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'jobId');
    });
  }

  QueryBuilder<CachedHunterJob, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<CachedHunterJob, String?, QQueryOperations> speciesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'species');
    });
  }

  QueryBuilder<CachedHunterJob, String?, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<CachedHunterJob, double?, QQueryOperations>
      totalAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalAmount');
    });
  }

  QueryBuilder<CachedHunterJob, DateTime?, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
