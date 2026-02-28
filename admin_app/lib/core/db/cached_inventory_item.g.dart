// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_inventory_item.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedInventoryItemCollection on Isar {
  IsarCollection<CachedInventoryItem> get cachedInventoryItems =>
      this.collection();
}

const CachedInventoryItemSchema = CollectionSchema(
  name: r'CachedInventoryItem',
  id: -6173601866538559616,
  properties: {
    r'cachedAt': PropertySchema(
      id: 0,
      name: r'cachedAt',
      type: IsarType.dateTime,
    ),
    r'categoryId': PropertySchema(
      id: 1,
      name: r'categoryId',
      type: IsarType.string,
    ),
    r'currentStock': PropertySchema(
      id: 2,
      name: r'currentStock',
      type: IsarType.double,
    ),
    r'isActive': PropertySchema(
      id: 3,
      name: r'isActive',
      type: IsarType.bool,
    ),
    r'itemId': PropertySchema(
      id: 4,
      name: r'itemId',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 5,
      name: r'name',
      type: IsarType.string,
    ),
    r'pluCode': PropertySchema(
      id: 6,
      name: r'pluCode',
      type: IsarType.long,
    ),
    r'reorderLevel': PropertySchema(
      id: 7,
      name: r'reorderLevel',
      type: IsarType.double,
    ),
    r'stockControlType': PropertySchema(
      id: 8,
      name: r'stockControlType',
      type: IsarType.string,
    ),
    r'stockOnHandFresh': PropertySchema(
      id: 9,
      name: r'stockOnHandFresh',
      type: IsarType.double,
    ),
    r'stockOnHandFrozen': PropertySchema(
      id: 10,
      name: r'stockOnHandFrozen',
      type: IsarType.double,
    ),
    r'unitType': PropertySchema(
      id: 11,
      name: r'unitType',
      type: IsarType.string,
    )
  },
  estimateSize: _cachedInventoryItemEstimateSize,
  serialize: _cachedInventoryItemSerialize,
  deserialize: _cachedInventoryItemDeserialize,
  deserializeProp: _cachedInventoryItemDeserializeProp,
  idName: r'id',
  indexes: {
    r'itemId': IndexSchema(
      id: -5342806140158601489,
      name: r'itemId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'itemId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cachedInventoryItemGetId,
  getLinks: _cachedInventoryItemGetLinks,
  attach: _cachedInventoryItemAttach,
  version: '3.1.0+1',
);

int _cachedInventoryItemEstimateSize(
  CachedInventoryItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.categoryId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.itemId.length * 3;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.stockControlType.length * 3;
  bytesCount += 3 + object.unitType.length * 3;
  return bytesCount;
}

void _cachedInventoryItemSerialize(
  CachedInventoryItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.cachedAt);
  writer.writeString(offsets[1], object.categoryId);
  writer.writeDouble(offsets[2], object.currentStock);
  writer.writeBool(offsets[3], object.isActive);
  writer.writeString(offsets[4], object.itemId);
  writer.writeString(offsets[5], object.name);
  writer.writeLong(offsets[6], object.pluCode);
  writer.writeDouble(offsets[7], object.reorderLevel);
  writer.writeString(offsets[8], object.stockControlType);
  writer.writeDouble(offsets[9], object.stockOnHandFresh);
  writer.writeDouble(offsets[10], object.stockOnHandFrozen);
  writer.writeString(offsets[11], object.unitType);
}

CachedInventoryItem _cachedInventoryItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedInventoryItem();
  object.cachedAt = reader.readDateTime(offsets[0]);
  object.categoryId = reader.readStringOrNull(offsets[1]);
  object.currentStock = reader.readDouble(offsets[2]);
  object.id = id;
  object.isActive = reader.readBool(offsets[3]);
  object.itemId = reader.readString(offsets[4]);
  object.name = reader.readString(offsets[5]);
  object.pluCode = reader.readLong(offsets[6]);
  object.reorderLevel = reader.readDoubleOrNull(offsets[7]);
  object.stockControlType = reader.readString(offsets[8]);
  object.stockOnHandFresh = reader.readDoubleOrNull(offsets[9]);
  object.stockOnHandFrozen = reader.readDoubleOrNull(offsets[10]);
  object.unitType = reader.readString(offsets[11]);
  return object;
}

P _cachedInventoryItemDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readDoubleOrNull(offset)) as P;
    case 10:
      return (reader.readDoubleOrNull(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedInventoryItemGetId(CachedInventoryItem object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedInventoryItemGetLinks(
    CachedInventoryItem object) {
  return [];
}

void _cachedInventoryItemAttach(
    IsarCollection<dynamic> col, Id id, CachedInventoryItem object) {
  object.id = id;
}

extension CachedInventoryItemByIndex on IsarCollection<CachedInventoryItem> {
  Future<CachedInventoryItem?> getByItemId(String itemId) {
    return getByIndex(r'itemId', [itemId]);
  }

  CachedInventoryItem? getByItemIdSync(String itemId) {
    return getByIndexSync(r'itemId', [itemId]);
  }

  Future<bool> deleteByItemId(String itemId) {
    return deleteByIndex(r'itemId', [itemId]);
  }

  bool deleteByItemIdSync(String itemId) {
    return deleteByIndexSync(r'itemId', [itemId]);
  }

  Future<List<CachedInventoryItem?>> getAllByItemId(List<String> itemIdValues) {
    final values = itemIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'itemId', values);
  }

  List<CachedInventoryItem?> getAllByItemIdSync(List<String> itemIdValues) {
    final values = itemIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'itemId', values);
  }

  Future<int> deleteAllByItemId(List<String> itemIdValues) {
    final values = itemIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'itemId', values);
  }

  int deleteAllByItemIdSync(List<String> itemIdValues) {
    final values = itemIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'itemId', values);
  }

  Future<Id> putByItemId(CachedInventoryItem object) {
    return putByIndex(r'itemId', object);
  }

  Id putByItemIdSync(CachedInventoryItem object, {bool saveLinks = true}) {
    return putByIndexSync(r'itemId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByItemId(List<CachedInventoryItem> objects) {
    return putAllByIndex(r'itemId', objects);
  }

  List<Id> putAllByItemIdSync(List<CachedInventoryItem> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'itemId', objects, saveLinks: saveLinks);
  }
}

extension CachedInventoryItemQueryWhereSort
    on QueryBuilder<CachedInventoryItem, CachedInventoryItem, QWhere> {
  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CachedInventoryItemQueryWhere
    on QueryBuilder<CachedInventoryItem, CachedInventoryItem, QWhereClause> {
  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterWhereClause>
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

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterWhereClause>
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

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterWhereClause>
      itemIdEqualTo(String itemId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'itemId',
        value: [itemId],
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterWhereClause>
      itemIdNotEqualTo(String itemId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'itemId',
              lower: [],
              upper: [itemId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'itemId',
              lower: [itemId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'itemId',
              lower: [itemId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'itemId',
              lower: [],
              upper: [itemId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CachedInventoryItemQueryFilter on QueryBuilder<CachedInventoryItem,
    CachedInventoryItem, QFilterCondition> {
  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      cachedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
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

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
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

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
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

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      categoryIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'categoryId',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      categoryIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'categoryId',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      categoryIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      categoryIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      categoryIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      categoryIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categoryId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      categoryIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      categoryIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      categoryIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      categoryIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      categoryIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      categoryIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      currentStockEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentStock',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      currentStockGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentStock',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      currentStockLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentStock',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      currentStockBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentStock',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
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

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
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

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
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

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      isActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isActive',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      itemIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'itemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      itemIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'itemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      itemIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'itemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      itemIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'itemId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      itemIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'itemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      itemIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'itemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      itemIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'itemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      itemIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'itemId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      itemIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'itemId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      itemIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'itemId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      pluCodeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pluCode',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      pluCodeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pluCode',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      pluCodeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pluCode',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      pluCodeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pluCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      reorderLevelIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'reorderLevel',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      reorderLevelIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'reorderLevel',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      reorderLevelEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reorderLevel',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      reorderLevelGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reorderLevel',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      reorderLevelLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reorderLevel',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      reorderLevelBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reorderLevel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockControlTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stockControlType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockControlTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stockControlType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockControlTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stockControlType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockControlTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stockControlType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockControlTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'stockControlType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockControlTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'stockControlType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockControlTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'stockControlType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockControlTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'stockControlType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockControlTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stockControlType',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockControlTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'stockControlType',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockOnHandFreshIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'stockOnHandFresh',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockOnHandFreshIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'stockOnHandFresh',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockOnHandFreshEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stockOnHandFresh',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockOnHandFreshGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stockOnHandFresh',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockOnHandFreshLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stockOnHandFresh',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockOnHandFreshBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stockOnHandFresh',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockOnHandFrozenIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'stockOnHandFrozen',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockOnHandFrozenIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'stockOnHandFrozen',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockOnHandFrozenEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stockOnHandFrozen',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockOnHandFrozenGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stockOnHandFrozen',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockOnHandFrozenLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stockOnHandFrozen',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockOnHandFrozenBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stockOnHandFrozen',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      unitTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unitType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      unitTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'unitType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      unitTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'unitType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      unitTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'unitType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      unitTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'unitType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      unitTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'unitType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      unitTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'unitType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      unitTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'unitType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      unitTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unitType',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      unitTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'unitType',
        value: '',
      ));
    });
  }
}

extension CachedInventoryItemQueryObject on QueryBuilder<CachedInventoryItem,
    CachedInventoryItem, QFilterCondition> {}

extension CachedInventoryItemQueryLinks on QueryBuilder<CachedInventoryItem,
    CachedInventoryItem, QFilterCondition> {}

extension CachedInventoryItemQuerySortBy
    on QueryBuilder<CachedInventoryItem, CachedInventoryItem, QSortBy> {
  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByCategoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByCurrentStock() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStock', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByCurrentStockDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStock', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemId', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemId', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByPluCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pluCode', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByPluCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pluCode', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByReorderLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reorderLevel', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByReorderLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reorderLevel', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByStockControlType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockControlType', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByStockControlTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockControlType', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByStockOnHandFresh() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockOnHandFresh', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByStockOnHandFreshDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockOnHandFresh', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByStockOnHandFrozen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockOnHandFrozen', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByStockOnHandFrozenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockOnHandFrozen', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByUnitType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitType', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByUnitTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitType', Sort.desc);
    });
  }
}

extension CachedInventoryItemQuerySortThenBy
    on QueryBuilder<CachedInventoryItem, CachedInventoryItem, QSortThenBy> {
  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByCategoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByCurrentStock() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStock', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByCurrentStockDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStock', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemId', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemId', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByPluCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pluCode', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByPluCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pluCode', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByReorderLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reorderLevel', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByReorderLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reorderLevel', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByStockControlType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockControlType', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByStockControlTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockControlType', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByStockOnHandFresh() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockOnHandFresh', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByStockOnHandFreshDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockOnHandFresh', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByStockOnHandFrozen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockOnHandFrozen', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByStockOnHandFrozenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockOnHandFrozen', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByUnitType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitType', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByUnitTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitType', Sort.desc);
    });
  }
}

extension CachedInventoryItemQueryWhereDistinct
    on QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct> {
  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedAt');
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByCategoryId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByCurrentStock() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentStock');
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByItemId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'itemId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByPluCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pluCode');
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByReorderLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reorderLevel');
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByStockControlType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stockControlType',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByStockOnHandFresh() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stockOnHandFresh');
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByStockOnHandFrozen() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stockOnHandFrozen');
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByUnitType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unitType', caseSensitive: caseSensitive);
    });
  }
}

extension CachedInventoryItemQueryProperty
    on QueryBuilder<CachedInventoryItem, CachedInventoryItem, QQueryProperty> {
  QueryBuilder<CachedInventoryItem, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedInventoryItem, DateTime, QQueryOperations>
      cachedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedAt');
    });
  }

  QueryBuilder<CachedInventoryItem, String?, QQueryOperations>
      categoryIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryId');
    });
  }

  QueryBuilder<CachedInventoryItem, double, QQueryOperations>
      currentStockProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentStock');
    });
  }

  QueryBuilder<CachedInventoryItem, bool, QQueryOperations> isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<CachedInventoryItem, String, QQueryOperations> itemIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'itemId');
    });
  }

  QueryBuilder<CachedInventoryItem, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<CachedInventoryItem, int, QQueryOperations> pluCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pluCode');
    });
  }

  QueryBuilder<CachedInventoryItem, double?, QQueryOperations>
      reorderLevelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reorderLevel');
    });
  }

  QueryBuilder<CachedInventoryItem, String, QQueryOperations>
      stockControlTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stockControlType');
    });
  }

  QueryBuilder<CachedInventoryItem, double?, QQueryOperations>
      stockOnHandFreshProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stockOnHandFresh');
    });
  }

  QueryBuilder<CachedInventoryItem, double?, QQueryOperations>
      stockOnHandFrozenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stockOnHandFrozen');
    });
  }

  QueryBuilder<CachedInventoryItem, String, QQueryOperations>
      unitTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unitType');
    });
  }
}
