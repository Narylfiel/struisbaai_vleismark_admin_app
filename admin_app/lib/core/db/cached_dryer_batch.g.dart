// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_dryer_batch.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedDryerBatchCollection on Isar {
  IsarCollection<CachedDryerBatch> get cachedDryerBatchs => this.collection();
}

const CachedDryerBatchSchema = CollectionSchema(
  name: r'CachedDryerBatch',
  id: 1902634686514813604,
  properties: {
    r'batchId': PropertySchema(
      id: 0,
      name: r'batchId',
      type: IsarType.string,
    ),
    r'cachedAt': PropertySchema(
      id: 1,
      name: r'cachedAt',
      type: IsarType.dateTime,
    ),
    r'endDate': PropertySchema(
      id: 2,
      name: r'endDate',
      type: IsarType.dateTime,
    ),
    r'notes': PropertySchema(
      id: 3,
      name: r'notes',
      type: IsarType.string,
    ),
    r'outputProductId': PropertySchema(
      id: 4,
      name: r'outputProductId',
      type: IsarType.string,
    ),
    r'outputProductName': PropertySchema(
      id: 5,
      name: r'outputProductName',
      type: IsarType.string,
    ),
    r'shrinkagePct': PropertySchema(
      id: 6,
      name: r'shrinkagePct',
      type: IsarType.double,
    ),
    r'startDate': PropertySchema(
      id: 7,
      name: r'startDate',
      type: IsarType.dateTime,
    ),
    r'status': PropertySchema(
      id: 8,
      name: r'status',
      type: IsarType.string,
    ),
    r'weightIn': PropertySchema(
      id: 9,
      name: r'weightIn',
      type: IsarType.double,
    ),
    r'weightOut': PropertySchema(
      id: 10,
      name: r'weightOut',
      type: IsarType.double,
    )
  },
  estimateSize: _cachedDryerBatchEstimateSize,
  serialize: _cachedDryerBatchSerialize,
  deserialize: _cachedDryerBatchDeserialize,
  deserializeProp: _cachedDryerBatchDeserializeProp,
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
  getId: _cachedDryerBatchGetId,
  getLinks: _cachedDryerBatchGetLinks,
  attach: _cachedDryerBatchAttach,
  version: '3.1.0+1',
);

int _cachedDryerBatchEstimateSize(
  CachedDryerBatch object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.batchId.length * 3;
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
    final value = object.status;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _cachedDryerBatchSerialize(
  CachedDryerBatch object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.batchId);
  writer.writeDateTime(offsets[1], object.cachedAt);
  writer.writeDateTime(offsets[2], object.endDate);
  writer.writeString(offsets[3], object.notes);
  writer.writeString(offsets[4], object.outputProductId);
  writer.writeString(offsets[5], object.outputProductName);
  writer.writeDouble(offsets[6], object.shrinkagePct);
  writer.writeDateTime(offsets[7], object.startDate);
  writer.writeString(offsets[8], object.status);
  writer.writeDouble(offsets[9], object.weightIn);
  writer.writeDouble(offsets[10], object.weightOut);
}

CachedDryerBatch _cachedDryerBatchDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedDryerBatch();
  object.batchId = reader.readString(offsets[0]);
  object.cachedAt = reader.readDateTime(offsets[1]);
  object.endDate = reader.readDateTimeOrNull(offsets[2]);
  object.id = id;
  object.notes = reader.readStringOrNull(offsets[3]);
  object.outputProductId = reader.readStringOrNull(offsets[4]);
  object.outputProductName = reader.readStringOrNull(offsets[5]);
  object.shrinkagePct = reader.readDoubleOrNull(offsets[6]);
  object.startDate = reader.readDateTimeOrNull(offsets[7]);
  object.status = reader.readStringOrNull(offsets[8]);
  object.weightIn = reader.readDoubleOrNull(offsets[9]);
  object.weightOut = reader.readDoubleOrNull(offsets[10]);
  return object;
}

P _cachedDryerBatchDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readDoubleOrNull(offset)) as P;
    case 10:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedDryerBatchGetId(CachedDryerBatch object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedDryerBatchGetLinks(CachedDryerBatch object) {
  return [];
}

void _cachedDryerBatchAttach(
    IsarCollection<dynamic> col, Id id, CachedDryerBatch object) {
  object.id = id;
}

extension CachedDryerBatchByIndex on IsarCollection<CachedDryerBatch> {
  Future<CachedDryerBatch?> getByBatchId(String batchId) {
    return getByIndex(r'batchId', [batchId]);
  }

  CachedDryerBatch? getByBatchIdSync(String batchId) {
    return getByIndexSync(r'batchId', [batchId]);
  }

  Future<bool> deleteByBatchId(String batchId) {
    return deleteByIndex(r'batchId', [batchId]);
  }

  bool deleteByBatchIdSync(String batchId) {
    return deleteByIndexSync(r'batchId', [batchId]);
  }

  Future<List<CachedDryerBatch?>> getAllByBatchId(List<String> batchIdValues) {
    final values = batchIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'batchId', values);
  }

  List<CachedDryerBatch?> getAllByBatchIdSync(List<String> batchIdValues) {
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

  Future<Id> putByBatchId(CachedDryerBatch object) {
    return putByIndex(r'batchId', object);
  }

  Id putByBatchIdSync(CachedDryerBatch object, {bool saveLinks = true}) {
    return putByIndexSync(r'batchId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByBatchId(List<CachedDryerBatch> objects) {
    return putAllByIndex(r'batchId', objects);
  }

  List<Id> putAllByBatchIdSync(List<CachedDryerBatch> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'batchId', objects, saveLinks: saveLinks);
  }
}

extension CachedDryerBatchQueryWhereSort
    on QueryBuilder<CachedDryerBatch, CachedDryerBatch, QWhere> {
  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CachedDryerBatchQueryWhere
    on QueryBuilder<CachedDryerBatch, CachedDryerBatch, QWhereClause> {
  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterWhereClause>
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterWhereClause> idBetween(
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterWhereClause>
      batchIdEqualTo(String batchId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'batchId',
        value: [batchId],
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterWhereClause>
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

extension CachedDryerBatchQueryFilter
    on QueryBuilder<CachedDryerBatch, CachedDryerBatch, QFilterCondition> {
  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      batchIdEqualTo(
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      batchIdGreaterThan(
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      batchIdLessThan(
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      batchIdBetween(
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      batchIdStartsWith(
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      batchIdEndsWith(
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      batchIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'batchId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      batchIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'batchId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      batchIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'batchId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      batchIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'batchId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      cachedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      endDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'endDate',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      endDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'endDate',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      endDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      endDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      endDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      endDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      outputProductIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'outputProductId',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      outputProductIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'outputProductId',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      outputProductIdEqualTo(
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      outputProductIdGreaterThan(
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      outputProductIdLessThan(
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      outputProductIdBetween(
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      outputProductIdStartsWith(
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      outputProductIdEndsWith(
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      outputProductIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'outputProductId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      outputProductIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'outputProductId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      outputProductIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'outputProductId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      outputProductIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'outputProductId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      outputProductNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'outputProductName',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      outputProductNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'outputProductName',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      outputProductNameEqualTo(
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      outputProductNameGreaterThan(
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      outputProductNameLessThan(
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      outputProductNameBetween(
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      outputProductNameStartsWith(
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      outputProductNameEndsWith(
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      outputProductNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'outputProductName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      outputProductNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'outputProductName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      outputProductNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'outputProductName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      outputProductNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'outputProductName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      shrinkagePctIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'shrinkagePct',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      shrinkagePctIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'shrinkagePct',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      shrinkagePctEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'shrinkagePct',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      shrinkagePctGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'shrinkagePct',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      shrinkagePctLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'shrinkagePct',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      shrinkagePctBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'shrinkagePct',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      startDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'startDate',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      startDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'startDate',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      startDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      startDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      startDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      startDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      statusIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'status',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      statusIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'status',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      weightInIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'weightIn',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      weightInIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'weightIn',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
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

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      weightOutIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'weightOut',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      weightOutIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'weightOut',
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      weightOutEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weightOut',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      weightOutGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weightOut',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      weightOutLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weightOut',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterFilterCondition>
      weightOutBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weightOut',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension CachedDryerBatchQueryObject
    on QueryBuilder<CachedDryerBatch, CachedDryerBatch, QFilterCondition> {}

extension CachedDryerBatchQueryLinks
    on QueryBuilder<CachedDryerBatch, CachedDryerBatch, QFilterCondition> {}

extension CachedDryerBatchQuerySortBy
    on QueryBuilder<CachedDryerBatch, CachedDryerBatch, QSortBy> {
  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      sortByBatchId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchId', Sort.asc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      sortByBatchIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchId', Sort.desc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      sortByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      sortByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      sortByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.asc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      sortByEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.desc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      sortByOutputProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputProductId', Sort.asc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      sortByOutputProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputProductId', Sort.desc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      sortByOutputProductName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputProductName', Sort.asc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      sortByOutputProductNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputProductName', Sort.desc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      sortByShrinkagePct() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shrinkagePct', Sort.asc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      sortByShrinkagePctDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shrinkagePct', Sort.desc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      sortByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      sortByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      sortByWeightIn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightIn', Sort.asc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      sortByWeightInDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightIn', Sort.desc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      sortByWeightOut() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightOut', Sort.asc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      sortByWeightOutDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightOut', Sort.desc);
    });
  }
}

extension CachedDryerBatchQuerySortThenBy
    on QueryBuilder<CachedDryerBatch, CachedDryerBatch, QSortThenBy> {
  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      thenByBatchId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchId', Sort.asc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      thenByBatchIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchId', Sort.desc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      thenByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      thenByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      thenByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.asc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      thenByEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.desc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      thenByOutputProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputProductId', Sort.asc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      thenByOutputProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputProductId', Sort.desc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      thenByOutputProductName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputProductName', Sort.asc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      thenByOutputProductNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputProductName', Sort.desc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      thenByShrinkagePct() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shrinkagePct', Sort.asc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      thenByShrinkagePctDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shrinkagePct', Sort.desc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      thenByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      thenByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      thenByWeightIn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightIn', Sort.asc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      thenByWeightInDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightIn', Sort.desc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      thenByWeightOut() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightOut', Sort.asc);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QAfterSortBy>
      thenByWeightOutDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightOut', Sort.desc);
    });
  }
}

extension CachedDryerBatchQueryWhereDistinct
    on QueryBuilder<CachedDryerBatch, CachedDryerBatch, QDistinct> {
  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QDistinct> distinctByBatchId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'batchId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QDistinct>
      distinctByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedAt');
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QDistinct>
      distinctByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endDate');
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QDistinct> distinctByNotes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QDistinct>
      distinctByOutputProductId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'outputProductId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QDistinct>
      distinctByOutputProductName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'outputProductName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QDistinct>
      distinctByShrinkagePct() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'shrinkagePct');
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QDistinct>
      distinctByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startDate');
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QDistinct>
      distinctByWeightIn() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weightIn');
    });
  }

  QueryBuilder<CachedDryerBatch, CachedDryerBatch, QDistinct>
      distinctByWeightOut() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weightOut');
    });
  }
}

extension CachedDryerBatchQueryProperty
    on QueryBuilder<CachedDryerBatch, CachedDryerBatch, QQueryProperty> {
  QueryBuilder<CachedDryerBatch, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedDryerBatch, String, QQueryOperations> batchIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'batchId');
    });
  }

  QueryBuilder<CachedDryerBatch, DateTime, QQueryOperations>
      cachedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedAt');
    });
  }

  QueryBuilder<CachedDryerBatch, DateTime?, QQueryOperations>
      endDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endDate');
    });
  }

  QueryBuilder<CachedDryerBatch, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<CachedDryerBatch, String?, QQueryOperations>
      outputProductIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'outputProductId');
    });
  }

  QueryBuilder<CachedDryerBatch, String?, QQueryOperations>
      outputProductNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'outputProductName');
    });
  }

  QueryBuilder<CachedDryerBatch, double?, QQueryOperations>
      shrinkagePctProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shrinkagePct');
    });
  }

  QueryBuilder<CachedDryerBatch, DateTime?, QQueryOperations>
      startDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startDate');
    });
  }

  QueryBuilder<CachedDryerBatch, String?, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<CachedDryerBatch, double?, QQueryOperations> weightInProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weightIn');
    });
  }

  QueryBuilder<CachedDryerBatch, double?, QQueryOperations>
      weightOutProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weightOut');
    });
  }
}
