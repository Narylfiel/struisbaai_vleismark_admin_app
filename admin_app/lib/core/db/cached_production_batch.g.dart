// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_production_batch.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedProductionBatchCollection on Isar {
  IsarCollection<CachedProductionBatch> get cachedProductionBatchs =>
      this.collection();
}

const CachedProductionBatchSchema = CollectionSchema(
  name: r'CachedProductionBatch',
  id: 5615618272507492858,
  properties: {
    r'actualQuantity': PropertySchema(
      id: 0,
      name: r'actualQuantity',
      type: IsarType.double,
    ),
    r'batchId': PropertySchema(
      id: 1,
      name: r'batchId',
      type: IsarType.string,
    ),
    r'batchNumber': PropertySchema(
      id: 2,
      name: r'batchNumber',
      type: IsarType.string,
    ),
    r'cachedAt': PropertySchema(
      id: 3,
      name: r'cachedAt',
      type: IsarType.dateTime,
    ),
    r'completedAt': PropertySchema(
      id: 4,
      name: r'completedAt',
      type: IsarType.dateTime,
    ),
    r'completedBy': PropertySchema(
      id: 5,
      name: r'completedBy',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 6,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'isSplitParent': PropertySchema(
      id: 7,
      name: r'isSplitParent',
      type: IsarType.bool,
    ),
    r'notes': PropertySchema(
      id: 8,
      name: r'notes',
      type: IsarType.string,
    ),
    r'outputProductId': PropertySchema(
      id: 9,
      name: r'outputProductId',
      type: IsarType.string,
    ),
    r'outputProductName': PropertySchema(
      id: 10,
      name: r'outputProductName',
      type: IsarType.string,
    ),
    r'parentBatchId': PropertySchema(
      id: 11,
      name: r'parentBatchId',
      type: IsarType.string,
    ),
    r'plannedQuantity': PropertySchema(
      id: 12,
      name: r'plannedQuantity',
      type: IsarType.double,
    ),
    r'recipeId': PropertySchema(
      id: 13,
      name: r'recipeId',
      type: IsarType.string,
    ),
    r'recipeName': PropertySchema(
      id: 14,
      name: r'recipeName',
      type: IsarType.string,
    ),
    r'splitNote': PropertySchema(
      id: 15,
      name: r'splitNote',
      type: IsarType.string,
    ),
    r'startedAt': PropertySchema(
      id: 16,
      name: r'startedAt',
      type: IsarType.dateTime,
    ),
    r'startedBy': PropertySchema(
      id: 17,
      name: r'startedBy',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 18,
      name: r'status',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 19,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _cachedProductionBatchEstimateSize,
  serialize: _cachedProductionBatchSerialize,
  deserialize: _cachedProductionBatchDeserialize,
  deserializeProp: _cachedProductionBatchDeserializeProp,
  idName: r'id',
  indexes: {
    r'batchId': IndexSchema(
      id: -5468368523860846432,
      name: r'batchId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'batchId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cachedProductionBatchGetId,
  getLinks: _cachedProductionBatchGetLinks,
  attach: _cachedProductionBatchAttach,
  version: '3.1.0+1',
);

int _cachedProductionBatchEstimateSize(
  CachedProductionBatch object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.batchId.length * 3;
  {
    final value = object.batchNumber;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.completedBy;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.outputProductId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.outputProductName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.parentBatchId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.recipeId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.recipeName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.splitNote;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.startedBy;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.status.length * 3;
  return bytesCount;
}

void _cachedProductionBatchSerialize(
  CachedProductionBatch object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.actualQuantity);
  writer.writeString(offsets[1], object.batchId);
  writer.writeString(offsets[2], object.batchNumber);
  writer.writeDateTime(offsets[3], object.cachedAt);
  writer.writeDateTime(offsets[4], object.completedAt);
  writer.writeString(offsets[5], object.completedBy);
  writer.writeDateTime(offsets[6], object.createdAt);
  writer.writeBool(offsets[7], object.isSplitParent);
  writer.writeString(offsets[8], object.notes);
  writer.writeString(offsets[9], object.outputProductId);
  writer.writeString(offsets[10], object.outputProductName);
  writer.writeString(offsets[11], object.parentBatchId);
  writer.writeDouble(offsets[12], object.plannedQuantity);
  writer.writeString(offsets[13], object.recipeId);
  writer.writeString(offsets[14], object.recipeName);
  writer.writeString(offsets[15], object.splitNote);
  writer.writeDateTime(offsets[16], object.startedAt);
  writer.writeString(offsets[17], object.startedBy);
  writer.writeString(offsets[18], object.status);
  writer.writeDateTime(offsets[19], object.updatedAt);
}

CachedProductionBatch _cachedProductionBatchDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedProductionBatch();
  object.actualQuantity = reader.readDoubleOrNull(offsets[0]);
  object.batchId = reader.readString(offsets[1]);
  object.batchNumber = reader.readStringOrNull(offsets[2]);
  object.cachedAt = reader.readDateTime(offsets[3]);
  object.completedAt = reader.readDateTimeOrNull(offsets[4]);
  object.completedBy = reader.readStringOrNull(offsets[5]);
  object.createdAt = reader.readDateTimeOrNull(offsets[6]);
  object.id = id;
  object.isSplitParent = reader.readBool(offsets[7]);
  object.notes = reader.readStringOrNull(offsets[8]);
  object.outputProductId = reader.readStringOrNull(offsets[9]);
  object.outputProductName = reader.readStringOrNull(offsets[10]);
  object.parentBatchId = reader.readStringOrNull(offsets[11]);
  object.plannedQuantity = reader.readDoubleOrNull(offsets[12]);
  object.recipeId = reader.readStringOrNull(offsets[13]);
  object.recipeName = reader.readStringOrNull(offsets[14]);
  object.splitNote = reader.readStringOrNull(offsets[15]);
  object.startedAt = reader.readDateTimeOrNull(offsets[16]);
  object.startedBy = reader.readStringOrNull(offsets[17]);
  object.status = reader.readString(offsets[18]);
  object.updatedAt = reader.readDateTimeOrNull(offsets[19]);
  return object;
}

P _cachedProductionBatchDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readDoubleOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 17:
      return (reader.readStringOrNull(offset)) as P;
    case 18:
      return (reader.readString(offset)) as P;
    case 19:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedProductionBatchGetId(CachedProductionBatch object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedProductionBatchGetLinks(
    CachedProductionBatch object) {
  return [];
}

void _cachedProductionBatchAttach(
    IsarCollection<dynamic> col, Id id, CachedProductionBatch object) {
  object.id = id;
}

extension CachedProductionBatchByIndex
    on IsarCollection<CachedProductionBatch> {
  Future<CachedProductionBatch?> getByBatchId(String batchId) {
    return getByIndex(r'batchId', [batchId]);
  }

  CachedProductionBatch? getByBatchIdSync(String batchId) {
    return getByIndexSync(r'batchId', [batchId]);
  }

  Future<bool> deleteByBatchId(String batchId) {
    return deleteByIndex(r'batchId', [batchId]);
  }

  bool deleteByBatchIdSync(String batchId) {
    return deleteByIndexSync(r'batchId', [batchId]);
  }

  Future<List<CachedProductionBatch?>> getAllByBatchId(
      List<String> batchIdValues) {
    final values = batchIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'batchId', values);
  }

  List<CachedProductionBatch?> getAllByBatchIdSync(List<String> batchIdValues) {
    final values = batchIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'batchId', values);
  }

  Future<int> deleteAllByBatchId(List<String> batchIdValues) {
    final values = batchIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'batchId', values);
  }

  int deleteAllByBatchIdSync(List<String> batchIdValues) {
    final values = batchIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'batchId', values);
  }

  Future<Id> putByBatchId(CachedProductionBatch object) {
    return putByIndex(r'batchId', object);
  }

  Id putByBatchIdSync(CachedProductionBatch object, {bool saveLinks = true}) {
    return putByIndexSync(r'batchId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByBatchId(List<CachedProductionBatch> objects) {
    return putAllByIndex(r'batchId', objects);
  }

  List<Id> putAllByBatchIdSync(List<CachedProductionBatch> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'batchId', objects, saveLinks: saveLinks);
  }
}

extension CachedProductionBatchQueryWhereSort
    on QueryBuilder<CachedProductionBatch, CachedProductionBatch, QWhere> {
  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CachedProductionBatchQueryWhere on QueryBuilder<CachedProductionBatch,
    CachedProductionBatch, QWhereClause> {
  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterWhereClause>
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

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterWhereClause>
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

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterWhereClause>
      batchIdEqualTo(String batchId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'batchId',
        value: [batchId],
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterWhereClause>
      batchIdNotEqualTo(String batchId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'batchId',
              lower: [],
              upper: [batchId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'batchId',
              lower: [batchId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'batchId',
              lower: [batchId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'batchId',
              lower: [],
              upper: [batchId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CachedProductionBatchQueryFilter on QueryBuilder<
    CachedProductionBatch, CachedProductionBatch, QFilterCondition> {
  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> actualQuantityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'actualQuantity',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> actualQuantityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'actualQuantity',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> actualQuantityEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'actualQuantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> actualQuantityGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'actualQuantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> actualQuantityLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'actualQuantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> actualQuantityBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'actualQuantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> batchIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'batchId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> batchIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'batchId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> batchIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'batchId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> batchIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'batchId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> batchIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'batchId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> batchIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'batchId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
          QAfterFilterCondition>
      batchIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'batchId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
          QAfterFilterCondition>
      batchIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'batchId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> batchIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'batchId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> batchIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'batchId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> batchNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'batchNumber',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> batchNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'batchNumber',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> batchNumberEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'batchNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> batchNumberGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'batchNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> batchNumberLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'batchNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> batchNumberBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'batchNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> batchNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'batchNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> batchNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'batchNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
          QAfterFilterCondition>
      batchNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'batchNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
          QAfterFilterCondition>
      batchNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'batchNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> batchNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'batchNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> batchNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'batchNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> cachedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> cachedAtGreaterThan(
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

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> cachedAtLessThan(
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

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> cachedAtBetween(
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

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> completedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'completedAt',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> completedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'completedAt',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> completedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> completedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> completedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> completedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'completedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> completedByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'completedBy',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> completedByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'completedBy',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> completedByEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> completedByGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'completedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> completedByLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'completedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> completedByBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'completedBy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> completedByStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'completedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> completedByEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'completedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
          QAfterFilterCondition>
      completedByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'completedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
          QAfterFilterCondition>
      completedByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'completedBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> completedByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> completedByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'completedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> createdAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> createdAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> createdAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> createdAtGreaterThan(
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

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> createdAtLessThan(
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

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> createdAtBetween(
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

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> idBetween(
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

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> isSplitParentEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSplitParent',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> notesEqualTo(
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

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> notesGreaterThan(
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

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> notesLessThan(
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

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> notesBetween(
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

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> notesStartsWith(
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

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> notesEndsWith(
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

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
          QAfterFilterCondition>
      notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
          QAfterFilterCondition>
      notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> outputProductIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'outputProductId',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> outputProductIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'outputProductId',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> outputProductIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'outputProductId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> outputProductIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'outputProductId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> outputProductIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'outputProductId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> outputProductIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'outputProductId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> outputProductIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'outputProductId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> outputProductIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'outputProductId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
          QAfterFilterCondition>
      outputProductIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'outputProductId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
          QAfterFilterCondition>
      outputProductIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'outputProductId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> outputProductIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'outputProductId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> outputProductIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'outputProductId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> outputProductNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'outputProductName',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> outputProductNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'outputProductName',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> outputProductNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'outputProductName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> outputProductNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'outputProductName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> outputProductNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'outputProductName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> outputProductNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'outputProductName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> outputProductNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'outputProductName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> outputProductNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'outputProductName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
          QAfterFilterCondition>
      outputProductNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'outputProductName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
          QAfterFilterCondition>
      outputProductNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'outputProductName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> outputProductNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'outputProductName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> outputProductNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'outputProductName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> parentBatchIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'parentBatchId',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> parentBatchIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'parentBatchId',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> parentBatchIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parentBatchId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> parentBatchIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'parentBatchId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> parentBatchIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'parentBatchId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> parentBatchIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'parentBatchId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> parentBatchIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'parentBatchId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> parentBatchIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'parentBatchId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
          QAfterFilterCondition>
      parentBatchIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'parentBatchId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
          QAfterFilterCondition>
      parentBatchIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'parentBatchId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> parentBatchIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parentBatchId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> parentBatchIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'parentBatchId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> plannedQuantityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'plannedQuantity',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> plannedQuantityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'plannedQuantity',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> plannedQuantityEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'plannedQuantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> plannedQuantityGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'plannedQuantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> plannedQuantityLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'plannedQuantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> plannedQuantityBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'plannedQuantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> recipeIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'recipeId',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> recipeIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'recipeId',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> recipeIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recipeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> recipeIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'recipeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> recipeIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'recipeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> recipeIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'recipeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> recipeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'recipeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> recipeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'recipeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
          QAfterFilterCondition>
      recipeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'recipeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
          QAfterFilterCondition>
      recipeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'recipeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> recipeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recipeId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> recipeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'recipeId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> recipeNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'recipeName',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> recipeNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'recipeName',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> recipeNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recipeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> recipeNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'recipeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> recipeNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'recipeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> recipeNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'recipeName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> recipeNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'recipeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> recipeNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'recipeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
          QAfterFilterCondition>
      recipeNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'recipeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
          QAfterFilterCondition>
      recipeNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'recipeName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> recipeNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recipeName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> recipeNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'recipeName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> splitNoteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'splitNote',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> splitNoteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'splitNote',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> splitNoteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'splitNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> splitNoteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'splitNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> splitNoteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'splitNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> splitNoteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'splitNote',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> splitNoteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'splitNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> splitNoteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'splitNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
          QAfterFilterCondition>
      splitNoteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'splitNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
          QAfterFilterCondition>
      splitNoteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'splitNote',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> splitNoteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'splitNote',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> splitNoteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'splitNote',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> startedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'startedAt',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> startedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'startedAt',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> startedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> startedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> startedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> startedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> startedByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'startedBy',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> startedByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'startedBy',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> startedByEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> startedByGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> startedByLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> startedByBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startedBy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> startedByStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'startedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> startedByEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'startedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
          QAfterFilterCondition>
      startedByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'startedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
          QAfterFilterCondition>
      startedByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'startedBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> startedByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> startedByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'startedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> statusEqualTo(
    String value, {
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

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> statusGreaterThan(
    String value, {
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

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> statusLessThan(
    String value, {
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

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> statusBetween(
    String lower,
    String upper, {
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

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> statusStartsWith(
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

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> statusEndsWith(
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

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
          QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
          QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> updatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> updatedAtGreaterThan(
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

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> updatedAtLessThan(
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

  QueryBuilder<CachedProductionBatch, CachedProductionBatch,
      QAfterFilterCondition> updatedAtBetween(
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

extension CachedProductionBatchQueryObject on QueryBuilder<
    CachedProductionBatch, CachedProductionBatch, QFilterCondition> {}

extension CachedProductionBatchQueryLinks on QueryBuilder<CachedProductionBatch,
    CachedProductionBatch, QFilterCondition> {}

extension CachedProductionBatchQuerySortBy
    on QueryBuilder<CachedProductionBatch, CachedProductionBatch, QSortBy> {
  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByActualQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualQuantity', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByActualQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualQuantity', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByBatchId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchId', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByBatchIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchId', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByBatchNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchNumber', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByBatchNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchNumber', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByCompletedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedBy', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByCompletedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedBy', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByIsSplitParent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSplitParent', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByIsSplitParentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSplitParent', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByOutputProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputProductId', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByOutputProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputProductId', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByOutputProductName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputProductName', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByOutputProductNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputProductName', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByParentBatchId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentBatchId', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByParentBatchIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentBatchId', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByPlannedQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plannedQuantity', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByPlannedQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plannedQuantity', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByRecipeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recipeId', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByRecipeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recipeId', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByRecipeName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recipeName', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByRecipeNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recipeName', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortBySplitNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'splitNote', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortBySplitNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'splitNote', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByStartedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedBy', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByStartedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedBy', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension CachedProductionBatchQuerySortThenBy
    on QueryBuilder<CachedProductionBatch, CachedProductionBatch, QSortThenBy> {
  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByActualQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualQuantity', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByActualQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualQuantity', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByBatchId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchId', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByBatchIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchId', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByBatchNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchNumber', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByBatchNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchNumber', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByCompletedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedBy', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByCompletedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedBy', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByIsSplitParent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSplitParent', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByIsSplitParentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSplitParent', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByOutputProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputProductId', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByOutputProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputProductId', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByOutputProductName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputProductName', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByOutputProductNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputProductName', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByParentBatchId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentBatchId', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByParentBatchIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentBatchId', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByPlannedQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plannedQuantity', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByPlannedQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plannedQuantity', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByRecipeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recipeId', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByRecipeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recipeId', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByRecipeName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recipeName', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByRecipeNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recipeName', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenBySplitNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'splitNote', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenBySplitNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'splitNote', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByStartedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedBy', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByStartedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedBy', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension CachedProductionBatchQueryWhereDistinct
    on QueryBuilder<CachedProductionBatch, CachedProductionBatch, QDistinct> {
  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QDistinct>
      distinctByActualQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'actualQuantity');
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QDistinct>
      distinctByBatchId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'batchId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QDistinct>
      distinctByBatchNumber({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'batchNumber', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QDistinct>
      distinctByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedAt');
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QDistinct>
      distinctByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completedAt');
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QDistinct>
      distinctByCompletedBy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completedBy', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QDistinct>
      distinctByIsSplitParent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSplitParent');
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QDistinct>
      distinctByNotes({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QDistinct>
      distinctByOutputProductId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'outputProductId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QDistinct>
      distinctByOutputProductName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'outputProductName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QDistinct>
      distinctByParentBatchId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'parentBatchId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QDistinct>
      distinctByPlannedQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'plannedQuantity');
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QDistinct>
      distinctByRecipeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recipeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QDistinct>
      distinctByRecipeName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recipeName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QDistinct>
      distinctBySplitNote({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'splitNote', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QDistinct>
      distinctByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startedAt');
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QDistinct>
      distinctByStartedBy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startedBy', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QDistinct>
      distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedProductionBatch, CachedProductionBatch, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension CachedProductionBatchQueryProperty on QueryBuilder<
    CachedProductionBatch, CachedProductionBatch, QQueryProperty> {
  QueryBuilder<CachedProductionBatch, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedProductionBatch, double?, QQueryOperations>
      actualQuantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'actualQuantity');
    });
  }

  QueryBuilder<CachedProductionBatch, String, QQueryOperations>
      batchIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'batchId');
    });
  }

  QueryBuilder<CachedProductionBatch, String?, QQueryOperations>
      batchNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'batchNumber');
    });
  }

  QueryBuilder<CachedProductionBatch, DateTime, QQueryOperations>
      cachedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedAt');
    });
  }

  QueryBuilder<CachedProductionBatch, DateTime?, QQueryOperations>
      completedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completedAt');
    });
  }

  QueryBuilder<CachedProductionBatch, String?, QQueryOperations>
      completedByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completedBy');
    });
  }

  QueryBuilder<CachedProductionBatch, DateTime?, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<CachedProductionBatch, bool, QQueryOperations>
      isSplitParentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSplitParent');
    });
  }

  QueryBuilder<CachedProductionBatch, String?, QQueryOperations>
      notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<CachedProductionBatch, String?, QQueryOperations>
      outputProductIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'outputProductId');
    });
  }

  QueryBuilder<CachedProductionBatch, String?, QQueryOperations>
      outputProductNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'outputProductName');
    });
  }

  QueryBuilder<CachedProductionBatch, String?, QQueryOperations>
      parentBatchIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'parentBatchId');
    });
  }

  QueryBuilder<CachedProductionBatch, double?, QQueryOperations>
      plannedQuantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'plannedQuantity');
    });
  }

  QueryBuilder<CachedProductionBatch, String?, QQueryOperations>
      recipeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recipeId');
    });
  }

  QueryBuilder<CachedProductionBatch, String?, QQueryOperations>
      recipeNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recipeName');
    });
  }

  QueryBuilder<CachedProductionBatch, String?, QQueryOperations>
      splitNoteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'splitNote');
    });
  }

  QueryBuilder<CachedProductionBatch, DateTime?, QQueryOperations>
      startedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startedAt');
    });
  }

  QueryBuilder<CachedProductionBatch, String?, QQueryOperations>
      startedByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startedBy');
    });
  }

  QueryBuilder<CachedProductionBatch, String, QQueryOperations>
      statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<CachedProductionBatch, DateTime?, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
