// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_staff_credit.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedStaffCreditCollection on Isar {
  IsarCollection<CachedStaffCredit> get cachedStaffCredits => this.collection();
}

const CachedStaffCreditSchema = CollectionSchema(
  name: r'CachedStaffCredit',
  id: 450310128416461304,
  properties: {
    r'amount': PropertySchema(
      id: 0,
      name: r'amount',
      type: IsarType.double,
    ),
    r'balance': PropertySchema(
      id: 1,
      name: r'balance',
      type: IsarType.double,
    ),
    r'cachedAt': PropertySchema(
      id: 2,
      name: r'cachedAt',
      type: IsarType.dateTime,
    ),
    r'creditDate': PropertySchema(
      id: 3,
      name: r'creditDate',
      type: IsarType.dateTime,
    ),
    r'creditId': PropertySchema(
      id: 4,
      name: r'creditId',
      type: IsarType.string,
    ),
    r'reason': PropertySchema(
      id: 5,
      name: r'reason',
      type: IsarType.string,
    ),
    r'staffId': PropertySchema(
      id: 6,
      name: r'staffId',
      type: IsarType.string,
    ),
    r'staffName': PropertySchema(
      id: 7,
      name: r'staffName',
      type: IsarType.string,
    )
  },
  estimateSize: _cachedStaffCreditEstimateSize,
  serialize: _cachedStaffCreditSerialize,
  deserialize: _cachedStaffCreditDeserialize,
  deserializeProp: _cachedStaffCreditDeserializeProp,
  idName: r'id',
  indexes: {
    r'creditId': IndexSchema(
      id: 5024021477983091308,
      name: r'creditId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'creditId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cachedStaffCreditGetId,
  getLinks: _cachedStaffCreditGetLinks,
  attach: _cachedStaffCreditAttach,
  version: '3.1.0+1',
);

int _cachedStaffCreditEstimateSize(
  CachedStaffCredit object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.creditId.length * 3;
  {
    final value = object.reason;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
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
  return bytesCount;
}

void _cachedStaffCreditSerialize(
  CachedStaffCredit object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.amount);
  writer.writeDouble(offsets[1], object.balance);
  writer.writeDateTime(offsets[2], object.cachedAt);
  writer.writeDateTime(offsets[3], object.creditDate);
  writer.writeString(offsets[4], object.creditId);
  writer.writeString(offsets[5], object.reason);
  writer.writeString(offsets[6], object.staffId);
  writer.writeString(offsets[7], object.staffName);
}

CachedStaffCredit _cachedStaffCreditDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedStaffCredit();
  object.amount = reader.readDouble(offsets[0]);
  object.balance = reader.readDouble(offsets[1]);
  object.cachedAt = reader.readDateTime(offsets[2]);
  object.creditDate = reader.readDateTimeOrNull(offsets[3]);
  object.creditId = reader.readString(offsets[4]);
  object.id = id;
  object.reason = reader.readStringOrNull(offsets[5]);
  object.staffId = reader.readStringOrNull(offsets[6]);
  object.staffName = reader.readStringOrNull(offsets[7]);
  return object;
}

P _cachedStaffCreditDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedStaffCreditGetId(CachedStaffCredit object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedStaffCreditGetLinks(
    CachedStaffCredit object) {
  return [];
}

void _cachedStaffCreditAttach(
    IsarCollection<dynamic> col, Id id, CachedStaffCredit object) {
  object.id = id;
}

extension CachedStaffCreditByIndex on IsarCollection<CachedStaffCredit> {
  Future<CachedStaffCredit?> getByCreditId(String creditId) {
    return getByIndex(r'creditId', [creditId]);
  }

  CachedStaffCredit? getByCreditIdSync(String creditId) {
    return getByIndexSync(r'creditId', [creditId]);
  }

  Future<bool> deleteByCreditId(String creditId) {
    return deleteByIndex(r'creditId', [creditId]);
  }

  bool deleteByCreditIdSync(String creditId) {
    return deleteByIndexSync(r'creditId', [creditId]);
  }

  Future<List<CachedStaffCredit?>> getAllByCreditId(
      List<String> creditIdValues) {
    final values = creditIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'creditId', values);
  }

  List<CachedStaffCredit?> getAllByCreditIdSync(List<String> creditIdValues) {
    final values = creditIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'creditId', values);
  }

  Future<int> deleteAllByCreditId(List<String> creditIdValues) {
    final values = creditIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'creditId', values);
  }

  int deleteAllByCreditIdSync(List<String> creditIdValues) {
    final values = creditIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'creditId', values);
  }

  Future<Id> putByCreditId(CachedStaffCredit object) {
    return putByIndex(r'creditId', object);
  }

  Id putByCreditIdSync(CachedStaffCredit object, {bool saveLinks = true}) {
    return putByIndexSync(r'creditId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCreditId(List<CachedStaffCredit> objects) {
    return putAllByIndex(r'creditId', objects);
  }

  List<Id> putAllByCreditIdSync(List<CachedStaffCredit> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'creditId', objects, saveLinks: saveLinks);
  }
}

extension CachedStaffCreditQueryWhereSort
    on QueryBuilder<CachedStaffCredit, CachedStaffCredit, QWhere> {
  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CachedStaffCreditQueryWhere
    on QueryBuilder<CachedStaffCredit, CachedStaffCredit, QWhereClause> {
  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterWhereClause>
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

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterWhereClause>
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

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterWhereClause>
      creditIdEqualTo(String creditId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'creditId',
        value: [creditId],
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterWhereClause>
      creditIdNotEqualTo(String creditId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'creditId',
              lower: [],
              upper: [creditId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'creditId',
              lower: [creditId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'creditId',
              lower: [creditId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'creditId',
              lower: [],
              upper: [creditId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CachedStaffCreditQueryFilter
    on QueryBuilder<CachedStaffCredit, CachedStaffCredit, QFilterCondition> {
  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      amountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      amountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      amountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      amountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      balanceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'balance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      balanceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'balance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      balanceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'balance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      balanceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'balance',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      cachedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
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

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
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

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
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

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      creditDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'creditDate',
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      creditDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'creditDate',
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      creditDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'creditDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      creditDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'creditDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      creditDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'creditDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      creditDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'creditDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      creditIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'creditId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      creditIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'creditId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      creditIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'creditId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      creditIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'creditId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      creditIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'creditId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      creditIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'creditId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      creditIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'creditId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      creditIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'creditId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      creditIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'creditId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      creditIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'creditId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
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

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
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

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
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

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      reasonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'reason',
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      reasonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'reason',
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      reasonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      reasonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      reasonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      reasonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reason',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      reasonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'reason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      reasonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'reason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      reasonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'reason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      reasonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'reason',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      reasonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reason',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      reasonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'reason',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      staffIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'staffId',
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      staffIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'staffId',
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
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

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
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

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
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

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
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

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
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

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
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

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      staffIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'staffId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      staffIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'staffId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      staffIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'staffId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      staffIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'staffId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      staffNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'staffName',
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      staffNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'staffName',
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
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

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
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

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
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

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
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

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
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

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
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

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      staffNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'staffName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      staffNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'staffName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      staffNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'staffName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterFilterCondition>
      staffNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'staffName',
        value: '',
      ));
    });
  }
}

extension CachedStaffCreditQueryObject
    on QueryBuilder<CachedStaffCredit, CachedStaffCredit, QFilterCondition> {}

extension CachedStaffCreditQueryLinks
    on QueryBuilder<CachedStaffCredit, CachedStaffCredit, QFilterCondition> {}

extension CachedStaffCreditQuerySortBy
    on QueryBuilder<CachedStaffCredit, CachedStaffCredit, QSortBy> {
  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      sortByBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.asc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      sortByBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.desc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      sortByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      sortByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      sortByCreditDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creditDate', Sort.asc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      sortByCreditDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creditDate', Sort.desc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      sortByCreditId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creditId', Sort.asc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      sortByCreditIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creditId', Sort.desc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      sortByReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reason', Sort.asc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      sortByReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reason', Sort.desc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      sortByStaffId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffId', Sort.asc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      sortByStaffIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffId', Sort.desc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      sortByStaffName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffName', Sort.asc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      sortByStaffNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffName', Sort.desc);
    });
  }
}

extension CachedStaffCreditQuerySortThenBy
    on QueryBuilder<CachedStaffCredit, CachedStaffCredit, QSortThenBy> {
  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      thenByBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.asc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      thenByBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.desc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      thenByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      thenByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      thenByCreditDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creditDate', Sort.asc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      thenByCreditDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creditDate', Sort.desc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      thenByCreditId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creditId', Sort.asc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      thenByCreditIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creditId', Sort.desc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      thenByReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reason', Sort.asc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      thenByReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reason', Sort.desc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      thenByStaffId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffId', Sort.asc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      thenByStaffIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffId', Sort.desc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      thenByStaffName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffName', Sort.asc);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QAfterSortBy>
      thenByStaffNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffName', Sort.desc);
    });
  }
}

extension CachedStaffCreditQueryWhereDistinct
    on QueryBuilder<CachedStaffCredit, CachedStaffCredit, QDistinct> {
  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QDistinct>
      distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QDistinct>
      distinctByBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'balance');
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QDistinct>
      distinctByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedAt');
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QDistinct>
      distinctByCreditDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'creditDate');
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QDistinct>
      distinctByCreditId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'creditId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QDistinct>
      distinctByReason({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reason', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QDistinct>
      distinctByStaffId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'staffId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedStaffCredit, CachedStaffCredit, QDistinct>
      distinctByStaffName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'staffName', caseSensitive: caseSensitive);
    });
  }
}

extension CachedStaffCreditQueryProperty
    on QueryBuilder<CachedStaffCredit, CachedStaffCredit, QQueryProperty> {
  QueryBuilder<CachedStaffCredit, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedStaffCredit, double, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<CachedStaffCredit, double, QQueryOperations> balanceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'balance');
    });
  }

  QueryBuilder<CachedStaffCredit, DateTime, QQueryOperations>
      cachedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedAt');
    });
  }

  QueryBuilder<CachedStaffCredit, DateTime?, QQueryOperations>
      creditDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'creditDate');
    });
  }

  QueryBuilder<CachedStaffCredit, String, QQueryOperations> creditIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'creditId');
    });
  }

  QueryBuilder<CachedStaffCredit, String?, QQueryOperations> reasonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reason');
    });
  }

  QueryBuilder<CachedStaffCredit, String?, QQueryOperations> staffIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'staffId');
    });
  }

  QueryBuilder<CachedStaffCredit, String?, QQueryOperations>
      staffNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'staffName');
    });
  }
}
