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
    r'availableLoyaltyApp': PropertySchema(
      id: 0,
      name: r'availableLoyaltyApp',
      type: IsarType.bool,
    ),
    r'availableOnline': PropertySchema(
      id: 1,
      name: r'availableOnline',
      type: IsarType.bool,
    ),
    r'availablePos': PropertySchema(
      id: 2,
      name: r'availablePos',
      type: IsarType.bool,
    ),
    r'averageCost': PropertySchema(
      id: 3,
      name: r'averageCost',
      type: IsarType.double,
    ),
    r'barcode': PropertySchema(
      id: 4,
      name: r'barcode',
      type: IsarType.string,
    ),
    r'barcodePrefix': PropertySchema(
      id: 5,
      name: r'barcodePrefix',
      type: IsarType.string,
    ),
    r'cachedAt': PropertySchema(
      id: 6,
      name: r'cachedAt',
      type: IsarType.dateTime,
    ),
    r'categoryId': PropertySchema(
      id: 7,
      name: r'categoryId',
      type: IsarType.string,
    ),
    r'costPrice': PropertySchema(
      id: 8,
      name: r'costPrice',
      type: IsarType.double,
    ),
    r'currentStock': PropertySchema(
      id: 9,
      name: r'currentStock',
      type: IsarType.double,
    ),
    r'isActive': PropertySchema(
      id: 10,
      name: r'isActive',
      type: IsarType.bool,
    ),
    r'itemId': PropertySchema(
      id: 11,
      name: r'itemId',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 12,
      name: r'name',
      type: IsarType.string,
    ),
    r'pluCode': PropertySchema(
      id: 13,
      name: r'pluCode',
      type: IsarType.long,
    ),
    r'posDisplayName': PropertySchema(
      id: 14,
      name: r'posDisplayName',
      type: IsarType.string,
    ),
    r'reorderLevel': PropertySchema(
      id: 15,
      name: r'reorderLevel',
      type: IsarType.double,
    ),
    r'scaleItem': PropertySchema(
      id: 16,
      name: r'scaleItem',
      type: IsarType.bool,
    ),
    r'sellPrice': PropertySchema(
      id: 17,
      name: r'sellPrice',
      type: IsarType.double,
    ),
    r'stockControlType': PropertySchema(
      id: 18,
      name: r'stockControlType',
      type: IsarType.string,
    ),
    r'stockOnHandFresh': PropertySchema(
      id: 19,
      name: r'stockOnHandFresh',
      type: IsarType.double,
    ),
    r'stockOnHandFrozen': PropertySchema(
      id: 20,
      name: r'stockOnHandFrozen',
      type: IsarType.double,
    ),
    r'targetMarginPct': PropertySchema(
      id: 21,
      name: r'targetMarginPct',
      type: IsarType.double,
    ),
    r'unitType': PropertySchema(
      id: 22,
      name: r'unitType',
      type: IsarType.string,
    ),
    r'vatGroup': PropertySchema(
      id: 23,
      name: r'vatGroup',
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
    final value = object.barcode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.barcodePrefix;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.categoryId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.itemId.length * 3;
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.posDisplayName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.stockControlType.length * 3;
  bytesCount += 3 + object.unitType.length * 3;
  {
    final value = object.vatGroup;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _cachedInventoryItemSerialize(
  CachedInventoryItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.availableLoyaltyApp);
  writer.writeBool(offsets[1], object.availableOnline);
  writer.writeBool(offsets[2], object.availablePos);
  writer.writeDouble(offsets[3], object.averageCost);
  writer.writeString(offsets[4], object.barcode);
  writer.writeString(offsets[5], object.barcodePrefix);
  writer.writeDateTime(offsets[6], object.cachedAt);
  writer.writeString(offsets[7], object.categoryId);
  writer.writeDouble(offsets[8], object.costPrice);
  writer.writeDouble(offsets[9], object.currentStock);
  writer.writeBool(offsets[10], object.isActive);
  writer.writeString(offsets[11], object.itemId);
  writer.writeString(offsets[12], object.name);
  writer.writeLong(offsets[13], object.pluCode);
  writer.writeString(offsets[14], object.posDisplayName);
  writer.writeDouble(offsets[15], object.reorderLevel);
  writer.writeBool(offsets[16], object.scaleItem);
  writer.writeDouble(offsets[17], object.sellPrice);
  writer.writeString(offsets[18], object.stockControlType);
  writer.writeDouble(offsets[19], object.stockOnHandFresh);
  writer.writeDouble(offsets[20], object.stockOnHandFrozen);
  writer.writeDouble(offsets[21], object.targetMarginPct);
  writer.writeString(offsets[22], object.unitType);
  writer.writeString(offsets[23], object.vatGroup);
}

CachedInventoryItem _cachedInventoryItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedInventoryItem();
  object.availableLoyaltyApp = reader.readBoolOrNull(offsets[0]);
  object.availableOnline = reader.readBoolOrNull(offsets[1]);
  object.availablePos = reader.readBoolOrNull(offsets[2]);
  object.averageCost = reader.readDoubleOrNull(offsets[3]);
  object.barcode = reader.readStringOrNull(offsets[4]);
  object.barcodePrefix = reader.readStringOrNull(offsets[5]);
  object.cachedAt = reader.readDateTime(offsets[6]);
  object.categoryId = reader.readStringOrNull(offsets[7]);
  object.costPrice = reader.readDoubleOrNull(offsets[8]);
  object.currentStock = reader.readDouble(offsets[9]);
  object.id = id;
  object.isActive = reader.readBool(offsets[10]);
  object.itemId = reader.readString(offsets[11]);
  object.name = reader.readString(offsets[12]);
  object.pluCode = reader.readLong(offsets[13]);
  object.posDisplayName = reader.readStringOrNull(offsets[14]);
  object.reorderLevel = reader.readDoubleOrNull(offsets[15]);
  object.scaleItem = reader.readBoolOrNull(offsets[16]);
  object.sellPrice = reader.readDoubleOrNull(offsets[17]);
  object.stockControlType = reader.readString(offsets[18]);
  object.stockOnHandFresh = reader.readDoubleOrNull(offsets[19]);
  object.stockOnHandFrozen = reader.readDoubleOrNull(offsets[20]);
  object.targetMarginPct = reader.readDoubleOrNull(offsets[21]);
  object.unitType = reader.readString(offsets[22]);
  object.vatGroup = reader.readStringOrNull(offsets[23]);
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
      return (reader.readBoolOrNull(offset)) as P;
    case 1:
      return (reader.readBoolOrNull(offset)) as P;
    case 2:
      return (reader.readBoolOrNull(offset)) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readDoubleOrNull(offset)) as P;
    case 9:
      return (reader.readDouble(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readLong(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readDoubleOrNull(offset)) as P;
    case 16:
      return (reader.readBoolOrNull(offset)) as P;
    case 17:
      return (reader.readDoubleOrNull(offset)) as P;
    case 18:
      return (reader.readString(offset)) as P;
    case 19:
      return (reader.readDoubleOrNull(offset)) as P;
    case 20:
      return (reader.readDoubleOrNull(offset)) as P;
    case 21:
      return (reader.readDoubleOrNull(offset)) as P;
    case 22:
      return (reader.readString(offset)) as P;
    case 23:
      return (reader.readStringOrNull(offset)) as P;
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
      availableLoyaltyAppIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'availableLoyaltyApp',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      availableLoyaltyAppIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'availableLoyaltyApp',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      availableLoyaltyAppEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'availableLoyaltyApp',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      availableOnlineIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'availableOnline',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      availableOnlineIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'availableOnline',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      availableOnlineEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'availableOnline',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      availablePosIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'availablePos',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      availablePosIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'availablePos',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      availablePosEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'availablePos',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      averageCostIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'averageCost',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      averageCostIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'averageCost',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      averageCostEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'averageCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      averageCostGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'averageCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      averageCostLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'averageCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      averageCostBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'averageCost',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      barcodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'barcode',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      barcodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'barcode',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      barcodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'barcode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      barcodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'barcode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      barcodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'barcode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      barcodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'barcode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      barcodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'barcode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      barcodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'barcode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      barcodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'barcode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      barcodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'barcode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      barcodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'barcode',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      barcodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'barcode',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      barcodePrefixIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'barcodePrefix',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      barcodePrefixIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'barcodePrefix',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      barcodePrefixEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'barcodePrefix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      barcodePrefixGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'barcodePrefix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      barcodePrefixLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'barcodePrefix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      barcodePrefixBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'barcodePrefix',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      barcodePrefixStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'barcodePrefix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      barcodePrefixEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'barcodePrefix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      barcodePrefixContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'barcodePrefix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      barcodePrefixMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'barcodePrefix',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      barcodePrefixIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'barcodePrefix',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      barcodePrefixIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'barcodePrefix',
        value: '',
      ));
    });
  }

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
      costPriceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'costPrice',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      costPriceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'costPrice',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      costPriceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'costPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      costPriceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'costPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      costPriceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'costPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      costPriceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'costPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
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
      posDisplayNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'posDisplayName',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      posDisplayNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'posDisplayName',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      posDisplayNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'posDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      posDisplayNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'posDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      posDisplayNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'posDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      posDisplayNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'posDisplayName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      posDisplayNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'posDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      posDisplayNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'posDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      posDisplayNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'posDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      posDisplayNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'posDisplayName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      posDisplayNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'posDisplayName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      posDisplayNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'posDisplayName',
        value: '',
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
      scaleItemIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'scaleItem',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      scaleItemIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'scaleItem',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      scaleItemEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scaleItem',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      sellPriceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sellPrice',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      sellPriceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sellPrice',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      sellPriceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sellPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      sellPriceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sellPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      sellPriceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sellPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      sellPriceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sellPrice',
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
      targetMarginPctIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'targetMarginPct',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      targetMarginPctIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'targetMarginPct',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      targetMarginPctEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetMarginPct',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      targetMarginPctGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetMarginPct',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      targetMarginPctLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetMarginPct',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      targetMarginPctBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetMarginPct',
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

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      vatGroupIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'vatGroup',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      vatGroupIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'vatGroup',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      vatGroupEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vatGroup',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      vatGroupGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'vatGroup',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      vatGroupLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'vatGroup',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      vatGroupBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'vatGroup',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      vatGroupStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'vatGroup',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      vatGroupEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'vatGroup',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      vatGroupContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'vatGroup',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      vatGroupMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'vatGroup',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      vatGroupIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vatGroup',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      vatGroupIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'vatGroup',
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
      sortByAvailableLoyaltyApp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availableLoyaltyApp', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByAvailableLoyaltyAppDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availableLoyaltyApp', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByAvailableOnline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availableOnline', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByAvailableOnlineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availableOnline', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByAvailablePos() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availablePos', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByAvailablePosDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availablePos', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByAverageCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'averageCost', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByAverageCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'averageCost', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByBarcode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'barcode', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByBarcodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'barcode', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByBarcodePrefix() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'barcodePrefix', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByBarcodePrefixDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'barcodePrefix', Sort.desc);
    });
  }

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
      sortByCostPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'costPrice', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByCostPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'costPrice', Sort.desc);
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
      sortByPosDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'posDisplayName', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByPosDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'posDisplayName', Sort.desc);
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
      sortByScaleItem() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scaleItem', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByScaleItemDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scaleItem', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortBySellPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellPrice', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortBySellPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellPrice', Sort.desc);
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
      sortByTargetMarginPct() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetMarginPct', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByTargetMarginPctDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetMarginPct', Sort.desc);
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

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByVatGroup() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vatGroup', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByVatGroupDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vatGroup', Sort.desc);
    });
  }
}

extension CachedInventoryItemQuerySortThenBy
    on QueryBuilder<CachedInventoryItem, CachedInventoryItem, QSortThenBy> {
  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByAvailableLoyaltyApp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availableLoyaltyApp', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByAvailableLoyaltyAppDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availableLoyaltyApp', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByAvailableOnline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availableOnline', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByAvailableOnlineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availableOnline', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByAvailablePos() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availablePos', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByAvailablePosDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availablePos', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByAverageCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'averageCost', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByAverageCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'averageCost', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByBarcode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'barcode', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByBarcodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'barcode', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByBarcodePrefix() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'barcodePrefix', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByBarcodePrefixDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'barcodePrefix', Sort.desc);
    });
  }

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
      thenByCostPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'costPrice', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByCostPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'costPrice', Sort.desc);
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
      thenByPosDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'posDisplayName', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByPosDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'posDisplayName', Sort.desc);
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
      thenByScaleItem() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scaleItem', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByScaleItemDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scaleItem', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenBySellPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellPrice', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenBySellPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellPrice', Sort.desc);
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
      thenByTargetMarginPct() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetMarginPct', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByTargetMarginPctDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetMarginPct', Sort.desc);
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

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByVatGroup() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vatGroup', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByVatGroupDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vatGroup', Sort.desc);
    });
  }
}

extension CachedInventoryItemQueryWhereDistinct
    on QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct> {
  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByAvailableLoyaltyApp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'availableLoyaltyApp');
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByAvailableOnline() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'availableOnline');
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByAvailablePos() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'availablePos');
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByAverageCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'averageCost');
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByBarcode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'barcode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByBarcodePrefix({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'barcodePrefix',
          caseSensitive: caseSensitive);
    });
  }

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
      distinctByCostPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'costPrice');
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
      distinctByPosDisplayName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'posDisplayName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByReorderLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reorderLevel');
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByScaleItem() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scaleItem');
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctBySellPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sellPrice');
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
      distinctByTargetMarginPct() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'targetMarginPct');
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByUnitType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unitType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByVatGroup({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vatGroup', caseSensitive: caseSensitive);
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

  QueryBuilder<CachedInventoryItem, bool?, QQueryOperations>
      availableLoyaltyAppProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'availableLoyaltyApp');
    });
  }

  QueryBuilder<CachedInventoryItem, bool?, QQueryOperations>
      availableOnlineProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'availableOnline');
    });
  }

  QueryBuilder<CachedInventoryItem, bool?, QQueryOperations>
      availablePosProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'availablePos');
    });
  }

  QueryBuilder<CachedInventoryItem, double?, QQueryOperations>
      averageCostProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'averageCost');
    });
  }

  QueryBuilder<CachedInventoryItem, String?, QQueryOperations>
      barcodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'barcode');
    });
  }

  QueryBuilder<CachedInventoryItem, String?, QQueryOperations>
      barcodePrefixProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'barcodePrefix');
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

  QueryBuilder<CachedInventoryItem, double?, QQueryOperations>
      costPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'costPrice');
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

  QueryBuilder<CachedInventoryItem, String?, QQueryOperations>
      posDisplayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'posDisplayName');
    });
  }

  QueryBuilder<CachedInventoryItem, double?, QQueryOperations>
      reorderLevelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reorderLevel');
    });
  }

  QueryBuilder<CachedInventoryItem, bool?, QQueryOperations>
      scaleItemProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scaleItem');
    });
  }

  QueryBuilder<CachedInventoryItem, double?, QQueryOperations>
      sellPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sellPrice');
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

  QueryBuilder<CachedInventoryItem, double?, QQueryOperations>
      targetMarginPctProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targetMarginPct');
    });
  }

  QueryBuilder<CachedInventoryItem, String, QQueryOperations>
      unitTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unitType');
    });
  }

  QueryBuilder<CachedInventoryItem, String?, QQueryOperations>
      vatGroupProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vatGroup');
    });
  }
}
