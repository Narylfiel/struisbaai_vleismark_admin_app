// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_payroll_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedPayrollEntryCollection on Isar {
  IsarCollection<CachedPayrollEntry> get cachedPayrollEntrys =>
      this.collection();
}

const CachedPayrollEntrySchema = CollectionSchema(
  name: r'CachedPayrollEntry',
  id: 765109850398763002,
  properties: {
    r'cachedAt': PropertySchema(
      id: 0,
      name: r'cachedAt',
      type: IsarType.dateTime,
    ),
    r'deductions': PropertySchema(
      id: 1,
      name: r'deductions',
      type: IsarType.double,
    ),
    r'entryId': PropertySchema(
      id: 2,
      name: r'entryId',
      type: IsarType.string,
    ),
    r'grossPay': PropertySchema(
      id: 3,
      name: r'grossPay',
      type: IsarType.double,
    ),
    r'netPay': PropertySchema(
      id: 4,
      name: r'netPay',
      type: IsarType.double,
    ),
    r'payPeriodEnd': PropertySchema(
      id: 5,
      name: r'payPeriodEnd',
      type: IsarType.dateTime,
    ),
    r'payPeriodStart': PropertySchema(
      id: 6,
      name: r'payPeriodStart',
      type: IsarType.dateTime,
    ),
    r'staffId': PropertySchema(
      id: 7,
      name: r'staffId',
      type: IsarType.string,
    ),
    r'staffName': PropertySchema(
      id: 8,
      name: r'staffName',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 9,
      name: r'status',
      type: IsarType.string,
    )
  },
  estimateSize: _cachedPayrollEntryEstimateSize,
  serialize: _cachedPayrollEntrySerialize,
  deserialize: _cachedPayrollEntryDeserialize,
  deserializeProp: _cachedPayrollEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'entryId': IndexSchema(
      id: 3733379884318738402,
      name: r'entryId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'entryId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cachedPayrollEntryGetId,
  getLinks: _cachedPayrollEntryGetLinks,
  attach: _cachedPayrollEntryAttach,
  version: '3.1.0+1',
);

int _cachedPayrollEntryEstimateSize(
  CachedPayrollEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.entryId.length * 3;
  {
    final value = object.staffId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.staffName;
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

void _cachedPayrollEntrySerialize(
  CachedPayrollEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.cachedAt);
  writer.writeDouble(offsets[1], object.deductions);
  writer.writeString(offsets[2], object.entryId);
  writer.writeDouble(offsets[3], object.grossPay);
  writer.writeDouble(offsets[4], object.netPay);
  writer.writeDateTime(offsets[5], object.payPeriodEnd);
  writer.writeDateTime(offsets[6], object.payPeriodStart);
  writer.writeString(offsets[7], object.staffId);
  writer.writeString(offsets[8], object.staffName);
  writer.writeString(offsets[9], object.status);
}

CachedPayrollEntry _cachedPayrollEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedPayrollEntry();
  object.cachedAt = reader.readDateTime(offsets[0]);
  object.deductions = reader.readDouble(offsets[1]);
  object.entryId = reader.readString(offsets[2]);
  object.grossPay = reader.readDouble(offsets[3]);
  object.id = id;
  object.netPay = reader.readDouble(offsets[4]);
  object.payPeriodEnd = reader.readDateTimeOrNull(offsets[5]);
  object.payPeriodStart = reader.readDateTimeOrNull(offsets[6]);
  object.staffId = reader.readStringOrNull(offsets[7]);
  object.staffName = reader.readStringOrNull(offsets[8]);
  object.status = reader.readStringOrNull(offsets[9]);
  return object;
}

P _cachedPayrollEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedPayrollEntryGetId(CachedPayrollEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedPayrollEntryGetLinks(
    CachedPayrollEntry object) {
  return [];
}

void _cachedPayrollEntryAttach(
    IsarCollection<dynamic> col, Id id, CachedPayrollEntry object) {
  object.id = id;
}

extension CachedPayrollEntryByIndex on IsarCollection<CachedPayrollEntry> {
  Future<CachedPayrollEntry?> getByEntryId(String entryId) {
    return getByIndex(r'entryId', [entryId]);
  }

  CachedPayrollEntry? getByEntryIdSync(String entryId) {
    return getByIndexSync(r'entryId', [entryId]);
  }

  Future<bool> deleteByEntryId(String entryId) {
    return deleteByIndex(r'entryId', [entryId]);
  }

  bool deleteByEntryIdSync(String entryId) {
    return deleteByIndexSync(r'entryId', [entryId]);
  }

  Future<List<CachedPayrollEntry?>> getAllByEntryId(
      List<String> entryIdValues) {
    final values = entryIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'entryId', values);
  }

  List<CachedPayrollEntry?> getAllByEntryIdSync(List<String> entryIdValues) {
    final values = entryIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'entryId', values);
  }

  Future<int> deleteAllByEntryId(List<String> entryIdValues) {
    final values = entryIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'entryId', values);
  }

  int deleteAllByEntryIdSync(List<String> entryIdValues) {
    final values = entryIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'entryId', values);
  }

  Future<Id> putByEntryId(CachedPayrollEntry object) {
    return putByIndex(r'entryId', object);
  }

  Id putByEntryIdSync(CachedPayrollEntry object, {bool saveLinks = true}) {
    return putByIndexSync(r'entryId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByEntryId(List<CachedPayrollEntry> objects) {
    return putAllByIndex(r'entryId', objects);
  }

  List<Id> putAllByEntryIdSync(List<CachedPayrollEntry> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'entryId', objects, saveLinks: saveLinks);
  }
}

extension CachedPayrollEntryQueryWhereSort
    on QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QWhere> {
  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CachedPayrollEntryQueryWhere
    on QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QWhereClause> {
  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterWhereClause>
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

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterWhereClause>
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

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterWhereClause>
      entryIdEqualTo(String entryId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'entryId',
        value: [entryId],
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterWhereClause>
      entryIdNotEqualTo(String entryId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'entryId',
              lower: [],
              upper: [entryId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'entryId',
              lower: [entryId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'entryId',
              lower: [entryId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'entryId',
              lower: [],
              upper: [entryId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CachedPayrollEntryQueryFilter
    on QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QFilterCondition> {
  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      cachedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
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

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
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

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
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

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      deductionsEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deductions',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      deductionsGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deductions',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      deductionsLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deductions',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      deductionsBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deductions',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      entryIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'entryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      entryIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'entryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      entryIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'entryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      entryIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'entryId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      entryIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'entryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      entryIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'entryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      entryIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'entryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      entryIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'entryId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      entryIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'entryId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      entryIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'entryId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      grossPayEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'grossPay',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      grossPayGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'grossPay',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      grossPayLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'grossPay',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      grossPayBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'grossPay',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
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

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
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

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
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

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      netPayEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'netPay',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      netPayGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'netPay',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      netPayLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'netPay',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      netPayBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'netPay',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      payPeriodEndIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'payPeriodEnd',
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      payPeriodEndIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'payPeriodEnd',
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      payPeriodEndEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payPeriodEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      payPeriodEndGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'payPeriodEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      payPeriodEndLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'payPeriodEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      payPeriodEndBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'payPeriodEnd',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      payPeriodStartIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'payPeriodStart',
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      payPeriodStartIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'payPeriodStart',
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      payPeriodStartEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payPeriodStart',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      payPeriodStartGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'payPeriodStart',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      payPeriodStartLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'payPeriodStart',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      payPeriodStartBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'payPeriodStart',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      staffIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'staffId',
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      staffIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'staffId',
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      staffIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'staffId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      staffIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'staffId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      staffIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'staffId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      staffIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'staffId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      staffIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'staffId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      staffIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'staffId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      staffIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'staffId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      staffIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'staffId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      staffIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'staffId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      staffIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'staffId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      staffNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'staffName',
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      staffNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'staffName',
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      staffNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'staffName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      staffNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'staffName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      staffNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'staffName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      staffNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'staffName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      staffNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'staffName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      staffNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'staffName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      staffNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'staffName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      staffNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'staffName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      staffNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'staffName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      staffNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'staffName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      statusIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'status',
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      statusIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'status',
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
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

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
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

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
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

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
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

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
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

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
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

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }
}

extension CachedPayrollEntryQueryObject
    on QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QFilterCondition> {}

extension CachedPayrollEntryQueryLinks
    on QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QFilterCondition> {}

extension CachedPayrollEntryQuerySortBy
    on QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QSortBy> {
  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      sortByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      sortByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      sortByDeductions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deductions', Sort.asc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      sortByDeductionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deductions', Sort.desc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      sortByEntryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryId', Sort.asc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      sortByEntryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryId', Sort.desc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      sortByGrossPay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grossPay', Sort.asc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      sortByGrossPayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grossPay', Sort.desc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      sortByNetPay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netPay', Sort.asc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      sortByNetPayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netPay', Sort.desc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      sortByPayPeriodEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payPeriodEnd', Sort.asc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      sortByPayPeriodEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payPeriodEnd', Sort.desc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      sortByPayPeriodStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payPeriodStart', Sort.asc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      sortByPayPeriodStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payPeriodStart', Sort.desc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      sortByStaffId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffId', Sort.asc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      sortByStaffIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffId', Sort.desc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      sortByStaffName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffName', Sort.asc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      sortByStaffNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffName', Sort.desc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }
}

extension CachedPayrollEntryQuerySortThenBy
    on QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QSortThenBy> {
  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      thenByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      thenByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      thenByDeductions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deductions', Sort.asc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      thenByDeductionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deductions', Sort.desc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      thenByEntryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryId', Sort.asc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      thenByEntryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryId', Sort.desc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      thenByGrossPay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grossPay', Sort.asc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      thenByGrossPayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grossPay', Sort.desc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      thenByNetPay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netPay', Sort.asc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      thenByNetPayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netPay', Sort.desc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      thenByPayPeriodEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payPeriodEnd', Sort.asc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      thenByPayPeriodEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payPeriodEnd', Sort.desc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      thenByPayPeriodStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payPeriodStart', Sort.asc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      thenByPayPeriodStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payPeriodStart', Sort.desc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      thenByStaffId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffId', Sort.asc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      thenByStaffIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffId', Sort.desc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      thenByStaffName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffName', Sort.asc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      thenByStaffNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffName', Sort.desc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }
}

extension CachedPayrollEntryQueryWhereDistinct
    on QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QDistinct> {
  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QDistinct>
      distinctByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedAt');
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QDistinct>
      distinctByDeductions() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deductions');
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QDistinct>
      distinctByEntryId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entryId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QDistinct>
      distinctByGrossPay() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'grossPay');
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QDistinct>
      distinctByNetPay() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'netPay');
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QDistinct>
      distinctByPayPeriodEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payPeriodEnd');
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QDistinct>
      distinctByPayPeriodStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payPeriodStart');
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QDistinct>
      distinctByStaffId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'staffId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QDistinct>
      distinctByStaffName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'staffName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QDistinct>
      distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }
}

extension CachedPayrollEntryQueryProperty
    on QueryBuilder<CachedPayrollEntry, CachedPayrollEntry, QQueryProperty> {
  QueryBuilder<CachedPayrollEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedPayrollEntry, DateTime, QQueryOperations>
      cachedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedAt');
    });
  }

  QueryBuilder<CachedPayrollEntry, double, QQueryOperations>
      deductionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deductions');
    });
  }

  QueryBuilder<CachedPayrollEntry, String, QQueryOperations> entryIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entryId');
    });
  }

  QueryBuilder<CachedPayrollEntry, double, QQueryOperations>
      grossPayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'grossPay');
    });
  }

  QueryBuilder<CachedPayrollEntry, double, QQueryOperations> netPayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'netPay');
    });
  }

  QueryBuilder<CachedPayrollEntry, DateTime?, QQueryOperations>
      payPeriodEndProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payPeriodEnd');
    });
  }

  QueryBuilder<CachedPayrollEntry, DateTime?, QQueryOperations>
      payPeriodStartProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payPeriodStart');
    });
  }

  QueryBuilder<CachedPayrollEntry, String?, QQueryOperations>
      staffIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'staffId');
    });
  }

  QueryBuilder<CachedPayrollEntry, String?, QQueryOperations>
      staffNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'staffName');
    });
  }

  QueryBuilder<CachedPayrollEntry, String?, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }
}
