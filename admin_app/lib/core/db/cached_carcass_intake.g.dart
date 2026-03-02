// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_carcass_intake.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedCarcassIntakeCollection on Isar {
  IsarCollection<CachedCarcassIntake> get cachedCarcassIntakes =>
      this.collection();
}

const CachedCarcassIntakeSchema = CollectionSchema(
  name: r'CachedCarcassIntake',
  id: -4251162066943581772,
  properties: {
    r'cachedAt': PropertySchema(
      id: 0,
      name: r'cachedAt',
      type: IsarType.dateTime,
    ),
    r'intakeDate': PropertySchema(
      id: 1,
      name: r'intakeDate',
      type: IsarType.dateTime,
    ),
    r'intakeId': PropertySchema(
      id: 2,
      name: r'intakeId',
      type: IsarType.string,
    ),
    r'jobType': PropertySchema(
      id: 3,
      name: r'jobType',
      type: IsarType.string,
    ),
    r'species': PropertySchema(
      id: 4,
      name: r'species',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 5,
      name: r'status',
      type: IsarType.string,
    ),
    r'supplierId': PropertySchema(
      id: 6,
      name: r'supplierId',
      type: IsarType.string,
    ),
    r'supplierName': PropertySchema(
      id: 7,
      name: r'supplierName',
      type: IsarType.string,
    ),
    r'weightIn': PropertySchema(
      id: 8,
      name: r'weightIn',
      type: IsarType.double,
    )
  },
  estimateSize: _cachedCarcassIntakeEstimateSize,
  serialize: _cachedCarcassIntakeSerialize,
  deserialize: _cachedCarcassIntakeDeserialize,
  deserializeProp: _cachedCarcassIntakeDeserializeProp,
  idName: r'id',
  indexes: {
    r'intakeId': IndexSchema(
      id: 8049441451066735704,
      name: r'intakeId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'intakeId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cachedCarcassIntakeGetId,
  getLinks: _cachedCarcassIntakeGetLinks,
  attach: _cachedCarcassIntakeAttach,
  version: '3.1.0+1',
);

int _cachedCarcassIntakeEstimateSize(
  CachedCarcassIntake object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.intakeId.length * 3;
  {
    final value = object.jobType;
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
  {
    final value = object.supplierId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.supplierName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _cachedCarcassIntakeSerialize(
  CachedCarcassIntake object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.cachedAt);
  writer.writeDateTime(offsets[1], object.intakeDate);
  writer.writeString(offsets[2], object.intakeId);
  writer.writeString(offsets[3], object.jobType);
  writer.writeString(offsets[4], object.species);
  writer.writeString(offsets[5], object.status);
  writer.writeString(offsets[6], object.supplierId);
  writer.writeString(offsets[7], object.supplierName);
  writer.writeDouble(offsets[8], object.weightIn);
}

CachedCarcassIntake _cachedCarcassIntakeDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedCarcassIntake();
  object.cachedAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.intakeDate = reader.readDateTimeOrNull(offsets[1]);
  object.intakeId = reader.readString(offsets[2]);
  object.jobType = reader.readStringOrNull(offsets[3]);
  object.species = reader.readStringOrNull(offsets[4]);
  object.status = reader.readStringOrNull(offsets[5]);
  object.supplierId = reader.readStringOrNull(offsets[6]);
  object.supplierName = reader.readStringOrNull(offsets[7]);
  object.weightIn = reader.readDoubleOrNull(offsets[8]);
  return object;
}

P _cachedCarcassIntakeDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedCarcassIntakeGetId(CachedCarcassIntake object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedCarcassIntakeGetLinks(
    CachedCarcassIntake object) {
  return [];
}

void _cachedCarcassIntakeAttach(
    IsarCollection<dynamic> col, Id id, CachedCarcassIntake object) {
  object.id = id;
}

extension CachedCarcassIntakeByIndex on IsarCollection<CachedCarcassIntake> {
  Future<CachedCarcassIntake?> getByIntakeId(String intakeId) {
    return getByIndex(r'intakeId', [intakeId]);
  }

  CachedCarcassIntake? getByIntakeIdSync(String intakeId) {
    return getByIndexSync(r'intakeId', [intakeId]);
  }

  Future<bool> deleteByIntakeId(String intakeId) {
    return deleteByIndex(r'intakeId', [intakeId]);
  }

  bool deleteByIntakeIdSync(String intakeId) {
    return deleteByIndexSync(r'intakeId', [intakeId]);
  }

  Future<List<CachedCarcassIntake?>> getAllByIntakeId(
      List<String> intakeIdValues) {
    final values = intakeIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'intakeId', values);
  }

  List<CachedCarcassIntake?> getAllByIntakeIdSync(List<String> intakeIdValues) {
    final values = intakeIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'intakeId', values);
  }

  Future<int> deleteAllByIntakeId(List<String> intakeIdValues) {
    final values = intakeIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'intakeId', values);
  }

  int deleteAllByIntakeIdSync(List<String> intakeIdValues) {
    final values = intakeIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'intakeId', values);
  }

  Future<Id> putByIntakeId(CachedCarcassIntake object) {
    return putByIndex(r'intakeId', object);
  }

  Id putByIntakeIdSync(CachedCarcassIntake object, {bool saveLinks = true}) {
    return putByIndexSync(r'intakeId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByIntakeId(List<CachedCarcassIntake> objects) {
    return putAllByIndex(r'intakeId', objects);
  }

  List<Id> putAllByIntakeIdSync(List<CachedCarcassIntake> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'intakeId', objects, saveLinks: saveLinks);
  }
}

extension CachedCarcassIntakeQueryWhereSort
    on QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QWhere> {
  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CachedCarcassIntakeQueryWhere
    on QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QWhereClause> {
  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterWhereClause>
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

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterWhereClause>
      intakeIdEqualTo(String intakeId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'intakeId',
        value: [intakeId],
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterWhereClause>
      intakeIdNotEqualTo(String intakeId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'intakeId',
              lower: [],
              upper: [intakeId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'intakeId',
              lower: [intakeId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'intakeId',
              lower: [intakeId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'intakeId',
              lower: [],
              upper: [intakeId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CachedCarcassIntakeQueryFilter on QueryBuilder<CachedCarcassIntake,
    CachedCarcassIntake, QFilterCondition> {
  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      cachedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
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

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
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

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
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

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
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

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
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

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
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

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      intakeDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'intakeDate',
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      intakeDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'intakeDate',
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      intakeDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'intakeDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      intakeDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'intakeDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      intakeDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'intakeDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      intakeDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'intakeDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      intakeIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'intakeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      intakeIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'intakeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      intakeIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'intakeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      intakeIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'intakeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      intakeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'intakeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      intakeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'intakeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      intakeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'intakeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      intakeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'intakeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      intakeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'intakeId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      intakeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'intakeId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      jobTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'jobType',
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      jobTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'jobType',
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      jobTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jobType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      jobTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'jobType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      jobTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'jobType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      jobTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'jobType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      jobTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'jobType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      jobTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'jobType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      jobTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'jobType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      jobTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'jobType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      jobTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jobType',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      jobTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'jobType',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      speciesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'species',
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      speciesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'species',
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
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

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
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

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
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

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
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

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
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

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
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

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      speciesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'species',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      speciesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'species',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      speciesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'species',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      speciesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'species',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      statusIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'status',
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      statusIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'status',
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
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

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
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

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
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

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
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

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
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

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
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

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      supplierIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'supplierId',
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      supplierIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'supplierId',
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      supplierIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'supplierId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      supplierIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'supplierId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      supplierIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'supplierId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      supplierIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'supplierId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      supplierIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'supplierId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      supplierIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'supplierId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      supplierIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'supplierId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      supplierIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'supplierId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      supplierIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'supplierId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      supplierIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'supplierId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      supplierNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'supplierName',
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      supplierNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'supplierName',
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      supplierNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'supplierName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      supplierNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'supplierName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      supplierNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'supplierName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      supplierNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'supplierName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      supplierNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'supplierName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      supplierNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'supplierName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      supplierNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'supplierName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      supplierNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'supplierName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      supplierNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'supplierName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      supplierNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'supplierName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      weightInIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'weightIn',
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      weightInIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'weightIn',
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      weightInEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weightIn',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      weightInGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weightIn',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      weightInLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weightIn',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterFilterCondition>
      weightInBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weightIn',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension CachedCarcassIntakeQueryObject on QueryBuilder<CachedCarcassIntake,
    CachedCarcassIntake, QFilterCondition> {}

extension CachedCarcassIntakeQueryLinks on QueryBuilder<CachedCarcassIntake,
    CachedCarcassIntake, QFilterCondition> {}

extension CachedCarcassIntakeQuerySortBy
    on QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QSortBy> {
  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      sortByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      sortByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      sortByIntakeDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intakeDate', Sort.asc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      sortByIntakeDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intakeDate', Sort.desc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      sortByIntakeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intakeId', Sort.asc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      sortByIntakeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intakeId', Sort.desc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      sortByJobType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobType', Sort.asc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      sortByJobTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobType', Sort.desc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      sortBySpecies() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'species', Sort.asc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      sortBySpeciesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'species', Sort.desc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      sortBySupplierId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.asc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      sortBySupplierIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.desc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      sortBySupplierName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierName', Sort.asc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      sortBySupplierNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierName', Sort.desc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      sortByWeightIn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightIn', Sort.asc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      sortByWeightInDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightIn', Sort.desc);
    });
  }
}

extension CachedCarcassIntakeQuerySortThenBy
    on QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QSortThenBy> {
  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      thenByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      thenByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      thenByIntakeDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intakeDate', Sort.asc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      thenByIntakeDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intakeDate', Sort.desc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      thenByIntakeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intakeId', Sort.asc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      thenByIntakeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intakeId', Sort.desc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      thenByJobType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobType', Sort.asc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      thenByJobTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobType', Sort.desc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      thenBySpecies() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'species', Sort.asc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      thenBySpeciesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'species', Sort.desc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      thenBySupplierId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.asc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      thenBySupplierIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.desc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      thenBySupplierName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierName', Sort.asc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      thenBySupplierNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierName', Sort.desc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      thenByWeightIn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightIn', Sort.asc);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QAfterSortBy>
      thenByWeightInDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightIn', Sort.desc);
    });
  }
}

extension CachedCarcassIntakeQueryWhereDistinct
    on QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QDistinct> {
  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QDistinct>
      distinctByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedAt');
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QDistinct>
      distinctByIntakeDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'intakeDate');
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QDistinct>
      distinctByIntakeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'intakeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QDistinct>
      distinctByJobType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'jobType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QDistinct>
      distinctBySpecies({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'species', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QDistinct>
      distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QDistinct>
      distinctBySupplierId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'supplierId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QDistinct>
      distinctBySupplierName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'supplierName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QDistinct>
      distinctByWeightIn() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weightIn');
    });
  }
}

extension CachedCarcassIntakeQueryProperty
    on QueryBuilder<CachedCarcassIntake, CachedCarcassIntake, QQueryProperty> {
  QueryBuilder<CachedCarcassIntake, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedCarcassIntake, DateTime, QQueryOperations>
      cachedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedAt');
    });
  }

  QueryBuilder<CachedCarcassIntake, DateTime?, QQueryOperations>
      intakeDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'intakeDate');
    });
  }

  QueryBuilder<CachedCarcassIntake, String, QQueryOperations>
      intakeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'intakeId');
    });
  }

  QueryBuilder<CachedCarcassIntake, String?, QQueryOperations>
      jobTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'jobType');
    });
  }

  QueryBuilder<CachedCarcassIntake, String?, QQueryOperations>
      speciesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'species');
    });
  }

  QueryBuilder<CachedCarcassIntake, String?, QQueryOperations>
      statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<CachedCarcassIntake, String?, QQueryOperations>
      supplierIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'supplierId');
    });
  }

  QueryBuilder<CachedCarcassIntake, String?, QQueryOperations>
      supplierNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'supplierName');
    });
  }

  QueryBuilder<CachedCarcassIntake, double?, QQueryOperations>
      weightInProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weightIn');
    });
  }
}
