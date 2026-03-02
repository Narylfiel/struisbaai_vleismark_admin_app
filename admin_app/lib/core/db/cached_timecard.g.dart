// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_timecard.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedTimecardCollection on Isar {
  IsarCollection<CachedTimecard> get cachedTimecards => this.collection();
}

const CachedTimecardSchema = CollectionSchema(
  name: r'CachedTimecard',
  id: 7285280212343900052,
  properties: {
    r'breakMinutes': PropertySchema(
      id: 0,
      name: r'breakMinutes',
      type: IsarType.long,
    ),
    r'cachedAt': PropertySchema(
      id: 1,
      name: r'cachedAt',
      type: IsarType.dateTime,
    ),
    r'clockIn': PropertySchema(
      id: 2,
      name: r'clockIn',
      type: IsarType.dateTime,
    ),
    r'clockOut': PropertySchema(
      id: 3,
      name: r'clockOut',
      type: IsarType.dateTime,
    ),
    r'shiftDate': PropertySchema(
      id: 4,
      name: r'shiftDate',
      type: IsarType.dateTime,
    ),
    r'staffId': PropertySchema(
      id: 5,
      name: r'staffId',
      type: IsarType.string,
    ),
    r'staffName': PropertySchema(
      id: 6,
      name: r'staffName',
      type: IsarType.string,
    ),
    r'timecardId': PropertySchema(
      id: 7,
      name: r'timecardId',
      type: IsarType.string,
    ),
    r'totalHours': PropertySchema(
      id: 8,
      name: r'totalHours',
      type: IsarType.double,
    )
  },
  estimateSize: _cachedTimecardEstimateSize,
  serialize: _cachedTimecardSerialize,
  deserialize: _cachedTimecardDeserialize,
  deserializeProp: _cachedTimecardDeserializeProp,
  idName: r'id',
  indexes: {
    r'timecardId': IndexSchema(
      id: -8220269173601680626,
      name: r'timecardId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'timecardId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cachedTimecardGetId,
  getLinks: _cachedTimecardGetLinks,
  attach: _cachedTimecardAttach,
  version: '3.1.0+1',
);

int _cachedTimecardEstimateSize(
  CachedTimecard object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
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
  bytesCount += 3 + object.timecardId.length * 3;
  return bytesCount;
}

void _cachedTimecardSerialize(
  CachedTimecard object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.breakMinutes);
  writer.writeDateTime(offsets[1], object.cachedAt);
  writer.writeDateTime(offsets[2], object.clockIn);
  writer.writeDateTime(offsets[3], object.clockOut);
  writer.writeDateTime(offsets[4], object.shiftDate);
  writer.writeString(offsets[5], object.staffId);
  writer.writeString(offsets[6], object.staffName);
  writer.writeString(offsets[7], object.timecardId);
  writer.writeDouble(offsets[8], object.totalHours);
}

CachedTimecard _cachedTimecardDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedTimecard();
  object.breakMinutes = reader.readLong(offsets[0]);
  object.cachedAt = reader.readDateTime(offsets[1]);
  object.clockIn = reader.readDateTimeOrNull(offsets[2]);
  object.clockOut = reader.readDateTimeOrNull(offsets[3]);
  object.id = id;
  object.shiftDate = reader.readDateTimeOrNull(offsets[4]);
  object.staffId = reader.readStringOrNull(offsets[5]);
  object.staffName = reader.readStringOrNull(offsets[6]);
  object.timecardId = reader.readString(offsets[7]);
  object.totalHours = reader.readDoubleOrNull(offsets[8]);
  return object;
}

P _cachedTimecardDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedTimecardGetId(CachedTimecard object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedTimecardGetLinks(CachedTimecard object) {
  return [];
}

void _cachedTimecardAttach(
    IsarCollection<dynamic> col, Id id, CachedTimecard object) {
  object.id = id;
}

extension CachedTimecardByIndex on IsarCollection<CachedTimecard> {
  Future<CachedTimecard?> getByTimecardId(String timecardId) {
    return getByIndex(r'timecardId', [timecardId]);
  }

  CachedTimecard? getByTimecardIdSync(String timecardId) {
    return getByIndexSync(r'timecardId', [timecardId]);
  }

  Future<bool> deleteByTimecardId(String timecardId) {
    return deleteByIndex(r'timecardId', [timecardId]);
  }

  bool deleteByTimecardIdSync(String timecardId) {
    return deleteByIndexSync(r'timecardId', [timecardId]);
  }

  Future<List<CachedTimecard?>> getAllByTimecardId(
      List<String> timecardIdValues) {
    final values = timecardIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'timecardId', values);
  }

  List<CachedTimecard?> getAllByTimecardIdSync(List<String> timecardIdValues) {
    final values = timecardIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'timecardId', values);
  }

  Future<int> deleteAllByTimecardId(List<String> timecardIdValues) {
    final values = timecardIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'timecardId', values);
  }

  int deleteAllByTimecardIdSync(List<String> timecardIdValues) {
    final values = timecardIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'timecardId', values);
  }

  Future<Id> putByTimecardId(CachedTimecard object) {
    return putByIndex(r'timecardId', object);
  }

  Id putByTimecardIdSync(CachedTimecard object, {bool saveLinks = true}) {
    return putByIndexSync(r'timecardId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByTimecardId(List<CachedTimecard> objects) {
    return putAllByIndex(r'timecardId', objects);
  }

  List<Id> putAllByTimecardIdSync(List<CachedTimecard> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'timecardId', objects, saveLinks: saveLinks);
  }
}

extension CachedTimecardQueryWhereSort
    on QueryBuilder<CachedTimecard, CachedTimecard, QWhere> {
  QueryBuilder<CachedTimecard, CachedTimecard, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CachedTimecardQueryWhere
    on QueryBuilder<CachedTimecard, CachedTimecard, QWhereClause> {
  QueryBuilder<CachedTimecard, CachedTimecard, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterWhereClause> idBetween(
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

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterWhereClause>
      timecardIdEqualTo(String timecardId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'timecardId',
        value: [timecardId],
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterWhereClause>
      timecardIdNotEqualTo(String timecardId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timecardId',
              lower: [],
              upper: [timecardId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timecardId',
              lower: [timecardId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timecardId',
              lower: [timecardId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timecardId',
              lower: [],
              upper: [timecardId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CachedTimecardQueryFilter
    on QueryBuilder<CachedTimecard, CachedTimecard, QFilterCondition> {
  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      breakMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'breakMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      breakMinutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'breakMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      breakMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'breakMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      breakMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'breakMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      cachedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
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

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
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

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
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

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      clockInIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'clockIn',
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      clockInIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'clockIn',
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      clockInEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clockIn',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      clockInGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'clockIn',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      clockInLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'clockIn',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      clockInBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'clockIn',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      clockOutIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'clockOut',
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      clockOutIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'clockOut',
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      clockOutEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clockOut',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      clockOutGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'clockOut',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      clockOutLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'clockOut',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      clockOutBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'clockOut',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
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

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
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

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition> idBetween(
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

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      shiftDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'shiftDate',
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      shiftDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'shiftDate',
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      shiftDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'shiftDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      shiftDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'shiftDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      shiftDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'shiftDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      shiftDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'shiftDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      staffIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'staffId',
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      staffIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'staffId',
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
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

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
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

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
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

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
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

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
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

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
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

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      staffIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'staffId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      staffIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'staffId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      staffIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'staffId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      staffIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'staffId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      staffNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'staffName',
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      staffNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'staffName',
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
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

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
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

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
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

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
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

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
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

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
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

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      staffNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'staffName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      staffNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'staffName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      staffNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'staffName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      staffNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'staffName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      timecardIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timecardId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      timecardIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timecardId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      timecardIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timecardId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      timecardIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timecardId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      timecardIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'timecardId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      timecardIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'timecardId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      timecardIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'timecardId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      timecardIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'timecardId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      timecardIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timecardId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      timecardIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'timecardId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      totalHoursIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'totalHours',
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      totalHoursIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'totalHours',
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      totalHoursEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalHours',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      totalHoursGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalHours',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      totalHoursLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalHours',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterFilterCondition>
      totalHoursBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalHours',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension CachedTimecardQueryObject
    on QueryBuilder<CachedTimecard, CachedTimecard, QFilterCondition> {}

extension CachedTimecardQueryLinks
    on QueryBuilder<CachedTimecard, CachedTimecard, QFilterCondition> {}

extension CachedTimecardQuerySortBy
    on QueryBuilder<CachedTimecard, CachedTimecard, QSortBy> {
  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy>
      sortByBreakMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'breakMinutes', Sort.asc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy>
      sortByBreakMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'breakMinutes', Sort.desc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy> sortByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy>
      sortByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy> sortByClockIn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clockIn', Sort.asc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy>
      sortByClockInDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clockIn', Sort.desc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy> sortByClockOut() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clockOut', Sort.asc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy>
      sortByClockOutDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clockOut', Sort.desc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy> sortByShiftDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shiftDate', Sort.asc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy>
      sortByShiftDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shiftDate', Sort.desc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy> sortByStaffId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffId', Sort.asc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy>
      sortByStaffIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffId', Sort.desc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy> sortByStaffName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffName', Sort.asc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy>
      sortByStaffNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffName', Sort.desc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy>
      sortByTimecardId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timecardId', Sort.asc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy>
      sortByTimecardIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timecardId', Sort.desc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy>
      sortByTotalHours() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalHours', Sort.asc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy>
      sortByTotalHoursDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalHours', Sort.desc);
    });
  }
}

extension CachedTimecardQuerySortThenBy
    on QueryBuilder<CachedTimecard, CachedTimecard, QSortThenBy> {
  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy>
      thenByBreakMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'breakMinutes', Sort.asc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy>
      thenByBreakMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'breakMinutes', Sort.desc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy> thenByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy>
      thenByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy> thenByClockIn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clockIn', Sort.asc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy>
      thenByClockInDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clockIn', Sort.desc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy> thenByClockOut() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clockOut', Sort.asc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy>
      thenByClockOutDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clockOut', Sort.desc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy> thenByShiftDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shiftDate', Sort.asc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy>
      thenByShiftDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shiftDate', Sort.desc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy> thenByStaffId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffId', Sort.asc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy>
      thenByStaffIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffId', Sort.desc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy> thenByStaffName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffName', Sort.asc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy>
      thenByStaffNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffName', Sort.desc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy>
      thenByTimecardId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timecardId', Sort.asc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy>
      thenByTimecardIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timecardId', Sort.desc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy>
      thenByTotalHours() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalHours', Sort.asc);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QAfterSortBy>
      thenByTotalHoursDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalHours', Sort.desc);
    });
  }
}

extension CachedTimecardQueryWhereDistinct
    on QueryBuilder<CachedTimecard, CachedTimecard, QDistinct> {
  QueryBuilder<CachedTimecard, CachedTimecard, QDistinct>
      distinctByBreakMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'breakMinutes');
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QDistinct> distinctByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedAt');
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QDistinct> distinctByClockIn() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'clockIn');
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QDistinct> distinctByClockOut() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'clockOut');
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QDistinct>
      distinctByShiftDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'shiftDate');
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QDistinct> distinctByStaffId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'staffId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QDistinct> distinctByStaffName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'staffName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QDistinct> distinctByTimecardId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timecardId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedTimecard, CachedTimecard, QDistinct>
      distinctByTotalHours() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalHours');
    });
  }
}

extension CachedTimecardQueryProperty
    on QueryBuilder<CachedTimecard, CachedTimecard, QQueryProperty> {
  QueryBuilder<CachedTimecard, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedTimecard, int, QQueryOperations> breakMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'breakMinutes');
    });
  }

  QueryBuilder<CachedTimecard, DateTime, QQueryOperations> cachedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedAt');
    });
  }

  QueryBuilder<CachedTimecard, DateTime?, QQueryOperations> clockInProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'clockIn');
    });
  }

  QueryBuilder<CachedTimecard, DateTime?, QQueryOperations> clockOutProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'clockOut');
    });
  }

  QueryBuilder<CachedTimecard, DateTime?, QQueryOperations>
      shiftDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shiftDate');
    });
  }

  QueryBuilder<CachedTimecard, String?, QQueryOperations> staffIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'staffId');
    });
  }

  QueryBuilder<CachedTimecard, String?, QQueryOperations> staffNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'staffName');
    });
  }

  QueryBuilder<CachedTimecard, String, QQueryOperations> timecardIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timecardId');
    });
  }

  QueryBuilder<CachedTimecard, double?, QQueryOperations> totalHoursProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalHours');
    });
  }
}
