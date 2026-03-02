// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_hunter_service_config.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedHunterServiceConfigCollection on Isar {
  IsarCollection<CachedHunterServiceConfig> get cachedHunterServiceConfigs =>
      this.collection();
}

const CachedHunterServiceConfigSchema = CollectionSchema(
  name: r'CachedHunterServiceConfig',
  id: 2674113340581678910,
  properties: {
    r'baseRate': PropertySchema(
      id: 0,
      name: r'baseRate',
      type: IsarType.double,
    ),
    r'cachedAt': PropertySchema(
      id: 1,
      name: r'cachedAt',
      type: IsarType.dateTime,
    ),
    r'configId': PropertySchema(
      id: 2,
      name: r'configId',
      type: IsarType.string,
    ),
    r'cutOptions': PropertySchema(
      id: 3,
      name: r'cutOptions',
      type: IsarType.string,
    ),
    r'isActive': PropertySchema(
      id: 4,
      name: r'isActive',
      type: IsarType.bool,
    ),
    r'perKgRate': PropertySchema(
      id: 5,
      name: r'perKgRate',
      type: IsarType.double,
    ),
    r'species': PropertySchema(
      id: 6,
      name: r'species',
      type: IsarType.string,
    )
  },
  estimateSize: _cachedHunterServiceConfigEstimateSize,
  serialize: _cachedHunterServiceConfigSerialize,
  deserialize: _cachedHunterServiceConfigDeserialize,
  deserializeProp: _cachedHunterServiceConfigDeserializeProp,
  idName: r'id',
  indexes: {
    r'configId': IndexSchema(
      id: 7164334513802924883,
      name: r'configId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'configId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cachedHunterServiceConfigGetId,
  getLinks: _cachedHunterServiceConfigGetLinks,
  attach: _cachedHunterServiceConfigAttach,
  version: '3.1.0+1',
);

int _cachedHunterServiceConfigEstimateSize(
  CachedHunterServiceConfig object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.configId.length * 3;
  {
    final value = object.cutOptions;
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
  return bytesCount;
}

void _cachedHunterServiceConfigSerialize(
  CachedHunterServiceConfig object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.baseRate);
  writer.writeDateTime(offsets[1], object.cachedAt);
  writer.writeString(offsets[2], object.configId);
  writer.writeString(offsets[3], object.cutOptions);
  writer.writeBool(offsets[4], object.isActive);
  writer.writeDouble(offsets[5], object.perKgRate);
  writer.writeString(offsets[6], object.species);
}

CachedHunterServiceConfig _cachedHunterServiceConfigDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedHunterServiceConfig();
  object.baseRate = reader.readDouble(offsets[0]);
  object.cachedAt = reader.readDateTime(offsets[1]);
  object.configId = reader.readString(offsets[2]);
  object.cutOptions = reader.readStringOrNull(offsets[3]);
  object.id = id;
  object.isActive = reader.readBool(offsets[4]);
  object.perKgRate = reader.readDouble(offsets[5]);
  object.species = reader.readStringOrNull(offsets[6]);
  return object;
}

P _cachedHunterServiceConfigDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedHunterServiceConfigGetId(CachedHunterServiceConfig object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedHunterServiceConfigGetLinks(
    CachedHunterServiceConfig object) {
  return [];
}

void _cachedHunterServiceConfigAttach(
    IsarCollection<dynamic> col, Id id, CachedHunterServiceConfig object) {
  object.id = id;
}

extension CachedHunterServiceConfigByIndex
    on IsarCollection<CachedHunterServiceConfig> {
  Future<CachedHunterServiceConfig?> getByConfigId(String configId) {
    return getByIndex(r'configId', [configId]);
  }

  CachedHunterServiceConfig? getByConfigIdSync(String configId) {
    return getByIndexSync(r'configId', [configId]);
  }

  Future<bool> deleteByConfigId(String configId) {
    return deleteByIndex(r'configId', [configId]);
  }

  bool deleteByConfigIdSync(String configId) {
    return deleteByIndexSync(r'configId', [configId]);
  }

  Future<List<CachedHunterServiceConfig?>> getAllByConfigId(
      List<String> configIdValues) {
    final values = configIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'configId', values);
  }

  List<CachedHunterServiceConfig?> getAllByConfigIdSync(
      List<String> configIdValues) {
    final values = configIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'configId', values);
  }

  Future<int> deleteAllByConfigId(List<String> configIdValues) {
    final values = configIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'configId', values);
  }

  int deleteAllByConfigIdSync(List<String> configIdValues) {
    final values = configIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'configId', values);
  }

  Future<Id> putByConfigId(CachedHunterServiceConfig object) {
    return putByIndex(r'configId', object);
  }

  Id putByConfigIdSync(CachedHunterServiceConfig object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'configId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByConfigId(List<CachedHunterServiceConfig> objects) {
    return putAllByIndex(r'configId', objects);
  }

  List<Id> putAllByConfigIdSync(List<CachedHunterServiceConfig> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'configId', objects, saveLinks: saveLinks);
  }
}

extension CachedHunterServiceConfigQueryWhereSort on QueryBuilder<
    CachedHunterServiceConfig, CachedHunterServiceConfig, QWhere> {
  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CachedHunterServiceConfigQueryWhere on QueryBuilder<
    CachedHunterServiceConfig, CachedHunterServiceConfig, QWhereClause> {
  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterWhereClause> idBetween(
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

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterWhereClause> configIdEqualTo(String configId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'configId',
        value: [configId],
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterWhereClause> configIdNotEqualTo(String configId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'configId',
              lower: [],
              upper: [configId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'configId',
              lower: [configId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'configId',
              lower: [configId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'configId',
              lower: [],
              upper: [configId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CachedHunterServiceConfigQueryFilter on QueryBuilder<
    CachedHunterServiceConfig, CachedHunterServiceConfig, QFilterCondition> {
  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> baseRateEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'baseRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> baseRateGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'baseRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> baseRateLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'baseRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> baseRateBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'baseRate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> cachedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
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

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
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

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
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

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> configIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'configId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> configIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'configId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> configIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'configId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> configIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'configId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> configIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'configId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> configIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'configId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
          QAfterFilterCondition>
      configIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'configId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
          QAfterFilterCondition>
      configIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'configId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> configIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'configId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> configIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'configId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> cutOptionsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cutOptions',
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> cutOptionsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cutOptions',
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> cutOptionsEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cutOptions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> cutOptionsGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cutOptions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> cutOptionsLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cutOptions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> cutOptionsBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cutOptions',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> cutOptionsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cutOptions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> cutOptionsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cutOptions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
          QAfterFilterCondition>
      cutOptionsContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cutOptions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
          QAfterFilterCondition>
      cutOptionsMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cutOptions',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> cutOptionsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cutOptions',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> cutOptionsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cutOptions',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
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

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
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

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
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

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> isActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isActive',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> perKgRateEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'perKgRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> perKgRateGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'perKgRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> perKgRateLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'perKgRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> perKgRateBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'perKgRate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> speciesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'species',
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> speciesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'species',
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> speciesEqualTo(
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

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> speciesGreaterThan(
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

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> speciesLessThan(
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

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> speciesBetween(
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

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> speciesStartsWith(
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

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> speciesEndsWith(
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

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
          QAfterFilterCondition>
      speciesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'species',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
          QAfterFilterCondition>
      speciesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'species',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> speciesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'species',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterFilterCondition> speciesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'species',
        value: '',
      ));
    });
  }
}

extension CachedHunterServiceConfigQueryObject on QueryBuilder<
    CachedHunterServiceConfig, CachedHunterServiceConfig, QFilterCondition> {}

extension CachedHunterServiceConfigQueryLinks on QueryBuilder<
    CachedHunterServiceConfig, CachedHunterServiceConfig, QFilterCondition> {}

extension CachedHunterServiceConfigQuerySortBy on QueryBuilder<
    CachedHunterServiceConfig, CachedHunterServiceConfig, QSortBy> {
  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> sortByBaseRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseRate', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> sortByBaseRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseRate', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> sortByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> sortByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> sortByConfigId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configId', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> sortByConfigIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configId', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> sortByCutOptions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cutOptions', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> sortByCutOptionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cutOptions', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> sortByPerKgRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perKgRate', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> sortByPerKgRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perKgRate', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> sortBySpecies() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'species', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> sortBySpeciesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'species', Sort.desc);
    });
  }
}

extension CachedHunterServiceConfigQuerySortThenBy on QueryBuilder<
    CachedHunterServiceConfig, CachedHunterServiceConfig, QSortThenBy> {
  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> thenByBaseRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseRate', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> thenByBaseRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseRate', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> thenByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> thenByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> thenByConfigId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configId', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> thenByConfigIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configId', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> thenByCutOptions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cutOptions', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> thenByCutOptionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cutOptions', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> thenByPerKgRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perKgRate', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> thenByPerKgRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perKgRate', Sort.desc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> thenBySpecies() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'species', Sort.asc);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig,
      QAfterSortBy> thenBySpeciesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'species', Sort.desc);
    });
  }
}

extension CachedHunterServiceConfigQueryWhereDistinct on QueryBuilder<
    CachedHunterServiceConfig, CachedHunterServiceConfig, QDistinct> {
  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig, QDistinct>
      distinctByBaseRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'baseRate');
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig, QDistinct>
      distinctByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedAt');
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig, QDistinct>
      distinctByConfigId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'configId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig, QDistinct>
      distinctByCutOptions({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cutOptions', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig, QDistinct>
      distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig, QDistinct>
      distinctByPerKgRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'perKgRate');
    });
  }

  QueryBuilder<CachedHunterServiceConfig, CachedHunterServiceConfig, QDistinct>
      distinctBySpecies({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'species', caseSensitive: caseSensitive);
    });
  }
}

extension CachedHunterServiceConfigQueryProperty on QueryBuilder<
    CachedHunterServiceConfig, CachedHunterServiceConfig, QQueryProperty> {
  QueryBuilder<CachedHunterServiceConfig, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedHunterServiceConfig, double, QQueryOperations>
      baseRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'baseRate');
    });
  }

  QueryBuilder<CachedHunterServiceConfig, DateTime, QQueryOperations>
      cachedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedAt');
    });
  }

  QueryBuilder<CachedHunterServiceConfig, String, QQueryOperations>
      configIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'configId');
    });
  }

  QueryBuilder<CachedHunterServiceConfig, String?, QQueryOperations>
      cutOptionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cutOptions');
    });
  }

  QueryBuilder<CachedHunterServiceConfig, bool, QQueryOperations>
      isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<CachedHunterServiceConfig, double, QQueryOperations>
      perKgRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'perKgRate');
    });
  }

  QueryBuilder<CachedHunterServiceConfig, String?, QQueryOperations>
      speciesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'species');
    });
  }
}
