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
    r'isBestSeller': PropertySchema(
      id: 11,
      name: r'isBestSeller',
      type: IsarType.bool,
    ),
    r'isFeatured': PropertySchema(
      id: 12,
      name: r'isFeatured',
      type: IsarType.bool,
    ),
    r'itemId': PropertySchema(
      id: 13,
      name: r'itemId',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 14,
      name: r'name',
      type: IsarType.string,
    ),
    r'onlineAllergens': PropertySchema(
      id: 15,
      name: r'onlineAllergens',
      type: IsarType.string,
    ),
    r'onlineCookingTips': PropertySchema(
      id: 16,
      name: r'onlineCookingTips',
      type: IsarType.string,
    ),
    r'onlineDisplayName': PropertySchema(
      id: 17,
      name: r'onlineDisplayName',
      type: IsarType.string,
    ),
    r'onlineImageUrl': PropertySchema(
      id: 18,
      name: r'onlineImageUrl',
      type: IsarType.string,
    ),
    r'onlineIngredients': PropertySchema(
      id: 19,
      name: r'onlineIngredients',
      type: IsarType.string,
    ),
    r'onlineMinStockThreshold': PropertySchema(
      id: 20,
      name: r'onlineMinStockThreshold',
      type: IsarType.double,
    ),
    r'onlineSortOrder': PropertySchema(
      id: 21,
      name: r'onlineSortOrder',
      type: IsarType.long,
    ),
    r'onlineWeightDescription': PropertySchema(
      id: 22,
      name: r'onlineWeightDescription',
      type: IsarType.string,
    ),
    r'parentStockItemId': PropertySchema(
      id: 23,
      name: r'parentStockItemId',
      type: IsarType.string,
    ),
    r'pluCode': PropertySchema(
      id: 24,
      name: r'pluCode',
      type: IsarType.long,
    ),
    r'posDisplayName': PropertySchema(
      id: 25,
      name: r'posDisplayName',
      type: IsarType.string,
    ),
    r'reorderLevel': PropertySchema(
      id: 26,
      name: r'reorderLevel',
      type: IsarType.double,
    ),
    r'scaleItem': PropertySchema(
      id: 27,
      name: r'scaleItem',
      type: IsarType.bool,
    ),
    r'sellPrice': PropertySchema(
      id: 28,
      name: r'sellPrice',
      type: IsarType.double,
    ),
    r'stockControlType': PropertySchema(
      id: 29,
      name: r'stockControlType',
      type: IsarType.string,
    ),
    r'stockDeductionQty': PropertySchema(
      id: 30,
      name: r'stockDeductionQty',
      type: IsarType.double,
    ),
    r'stockDeductionUnit': PropertySchema(
      id: 31,
      name: r'stockDeductionUnit',
      type: IsarType.string,
    ),
    r'stockOnHandFresh': PropertySchema(
      id: 32,
      name: r'stockOnHandFresh',
      type: IsarType.double,
    ),
    r'stockOnHandFrozen': PropertySchema(
      id: 33,
      name: r'stockOnHandFrozen',
      type: IsarType.double,
    ),
    r'targetMarginPct': PropertySchema(
      id: 34,
      name: r'targetMarginPct',
      type: IsarType.double,
    ),
    r'unitType': PropertySchema(
      id: 35,
      name: r'unitType',
      type: IsarType.string,
    ),
    r'vatGroup': PropertySchema(
      id: 36,
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
    final value = object.onlineAllergens;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.onlineCookingTips;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.onlineDisplayName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.onlineImageUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.onlineIngredients;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.onlineWeightDescription;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.parentStockItemId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.posDisplayName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.stockControlType.length * 3;
  {
    final value = object.stockDeductionUnit;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
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
  writer.writeBool(offsets[11], object.isBestSeller);
  writer.writeBool(offsets[12], object.isFeatured);
  writer.writeString(offsets[13], object.itemId);
  writer.writeString(offsets[14], object.name);
  writer.writeString(offsets[15], object.onlineAllergens);
  writer.writeString(offsets[16], object.onlineCookingTips);
  writer.writeString(offsets[17], object.onlineDisplayName);
  writer.writeString(offsets[18], object.onlineImageUrl);
  writer.writeString(offsets[19], object.onlineIngredients);
  writer.writeDouble(offsets[20], object.onlineMinStockThreshold);
  writer.writeLong(offsets[21], object.onlineSortOrder);
  writer.writeString(offsets[22], object.onlineWeightDescription);
  writer.writeString(offsets[23], object.parentStockItemId);
  writer.writeLong(offsets[24], object.pluCode);
  writer.writeString(offsets[25], object.posDisplayName);
  writer.writeDouble(offsets[26], object.reorderLevel);
  writer.writeBool(offsets[27], object.scaleItem);
  writer.writeDouble(offsets[28], object.sellPrice);
  writer.writeString(offsets[29], object.stockControlType);
  writer.writeDouble(offsets[30], object.stockDeductionQty);
  writer.writeString(offsets[31], object.stockDeductionUnit);
  writer.writeDouble(offsets[32], object.stockOnHandFresh);
  writer.writeDouble(offsets[33], object.stockOnHandFrozen);
  writer.writeDouble(offsets[34], object.targetMarginPct);
  writer.writeString(offsets[35], object.unitType);
  writer.writeString(offsets[36], object.vatGroup);
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
  object.isBestSeller = reader.readBoolOrNull(offsets[11]);
  object.isFeatured = reader.readBoolOrNull(offsets[12]);
  object.itemId = reader.readString(offsets[13]);
  object.name = reader.readString(offsets[14]);
  object.onlineAllergens = reader.readStringOrNull(offsets[15]);
  object.onlineCookingTips = reader.readStringOrNull(offsets[16]);
  object.onlineDisplayName = reader.readStringOrNull(offsets[17]);
  object.onlineImageUrl = reader.readStringOrNull(offsets[18]);
  object.onlineIngredients = reader.readStringOrNull(offsets[19]);
  object.onlineMinStockThreshold = reader.readDoubleOrNull(offsets[20]);
  object.onlineSortOrder = reader.readLongOrNull(offsets[21]);
  object.onlineWeightDescription = reader.readStringOrNull(offsets[22]);
  object.parentStockItemId = reader.readStringOrNull(offsets[23]);
  object.pluCode = reader.readLong(offsets[24]);
  object.posDisplayName = reader.readStringOrNull(offsets[25]);
  object.reorderLevel = reader.readDoubleOrNull(offsets[26]);
  object.scaleItem = reader.readBoolOrNull(offsets[27]);
  object.sellPrice = reader.readDoubleOrNull(offsets[28]);
  object.stockControlType = reader.readString(offsets[29]);
  object.stockDeductionQty = reader.readDoubleOrNull(offsets[30]);
  object.stockDeductionUnit = reader.readStringOrNull(offsets[31]);
  object.stockOnHandFresh = reader.readDoubleOrNull(offsets[32]);
  object.stockOnHandFrozen = reader.readDoubleOrNull(offsets[33]);
  object.targetMarginPct = reader.readDoubleOrNull(offsets[34]);
  object.unitType = reader.readString(offsets[35]);
  object.vatGroup = reader.readStringOrNull(offsets[36]);
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
      return (reader.readBoolOrNull(offset)) as P;
    case 12:
      return (reader.readBoolOrNull(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readStringOrNull(offset)) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    case 19:
      return (reader.readStringOrNull(offset)) as P;
    case 20:
      return (reader.readDoubleOrNull(offset)) as P;
    case 21:
      return (reader.readLongOrNull(offset)) as P;
    case 22:
      return (reader.readStringOrNull(offset)) as P;
    case 23:
      return (reader.readStringOrNull(offset)) as P;
    case 24:
      return (reader.readLong(offset)) as P;
    case 25:
      return (reader.readStringOrNull(offset)) as P;
    case 26:
      return (reader.readDoubleOrNull(offset)) as P;
    case 27:
      return (reader.readBoolOrNull(offset)) as P;
    case 28:
      return (reader.readDoubleOrNull(offset)) as P;
    case 29:
      return (reader.readString(offset)) as P;
    case 30:
      return (reader.readDoubleOrNull(offset)) as P;
    case 31:
      return (reader.readStringOrNull(offset)) as P;
    case 32:
      return (reader.readDoubleOrNull(offset)) as P;
    case 33:
      return (reader.readDoubleOrNull(offset)) as P;
    case 34:
      return (reader.readDoubleOrNull(offset)) as P;
    case 35:
      return (reader.readString(offset)) as P;
    case 36:
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
      isBestSellerIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isBestSeller',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      isBestSellerIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isBestSeller',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      isBestSellerEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isBestSeller',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      isFeaturedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isFeatured',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      isFeaturedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isFeatured',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      isFeaturedEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isFeatured',
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
      onlineAllergensIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'onlineAllergens',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineAllergensIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'onlineAllergens',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineAllergensEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'onlineAllergens',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineAllergensGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'onlineAllergens',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineAllergensLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'onlineAllergens',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineAllergensBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'onlineAllergens',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineAllergensStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'onlineAllergens',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineAllergensEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'onlineAllergens',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineAllergensContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'onlineAllergens',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineAllergensMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'onlineAllergens',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineAllergensIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'onlineAllergens',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineAllergensIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'onlineAllergens',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineCookingTipsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'onlineCookingTips',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineCookingTipsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'onlineCookingTips',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineCookingTipsEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'onlineCookingTips',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineCookingTipsGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'onlineCookingTips',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineCookingTipsLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'onlineCookingTips',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineCookingTipsBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'onlineCookingTips',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineCookingTipsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'onlineCookingTips',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineCookingTipsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'onlineCookingTips',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineCookingTipsContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'onlineCookingTips',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineCookingTipsMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'onlineCookingTips',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineCookingTipsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'onlineCookingTips',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineCookingTipsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'onlineCookingTips',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineDisplayNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'onlineDisplayName',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineDisplayNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'onlineDisplayName',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineDisplayNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'onlineDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineDisplayNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'onlineDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineDisplayNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'onlineDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineDisplayNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'onlineDisplayName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineDisplayNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'onlineDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineDisplayNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'onlineDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineDisplayNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'onlineDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineDisplayNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'onlineDisplayName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineDisplayNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'onlineDisplayName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineDisplayNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'onlineDisplayName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineImageUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'onlineImageUrl',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineImageUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'onlineImageUrl',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineImageUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'onlineImageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineImageUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'onlineImageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineImageUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'onlineImageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineImageUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'onlineImageUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineImageUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'onlineImageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineImageUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'onlineImageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineImageUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'onlineImageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineImageUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'onlineImageUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineImageUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'onlineImageUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineImageUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'onlineImageUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineIngredientsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'onlineIngredients',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineIngredientsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'onlineIngredients',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineIngredientsEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'onlineIngredients',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineIngredientsGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'onlineIngredients',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineIngredientsLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'onlineIngredients',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineIngredientsBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'onlineIngredients',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineIngredientsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'onlineIngredients',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineIngredientsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'onlineIngredients',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineIngredientsContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'onlineIngredients',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineIngredientsMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'onlineIngredients',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineIngredientsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'onlineIngredients',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineIngredientsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'onlineIngredients',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineMinStockThresholdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'onlineMinStockThreshold',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineMinStockThresholdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'onlineMinStockThreshold',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineMinStockThresholdEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'onlineMinStockThreshold',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineMinStockThresholdGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'onlineMinStockThreshold',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineMinStockThresholdLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'onlineMinStockThreshold',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineMinStockThresholdBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'onlineMinStockThreshold',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineSortOrderIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'onlineSortOrder',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineSortOrderIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'onlineSortOrder',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineSortOrderEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'onlineSortOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineSortOrderGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'onlineSortOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineSortOrderLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'onlineSortOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineSortOrderBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'onlineSortOrder',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineWeightDescriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'onlineWeightDescription',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineWeightDescriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'onlineWeightDescription',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineWeightDescriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'onlineWeightDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineWeightDescriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'onlineWeightDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineWeightDescriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'onlineWeightDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineWeightDescriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'onlineWeightDescription',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineWeightDescriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'onlineWeightDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineWeightDescriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'onlineWeightDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineWeightDescriptionContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'onlineWeightDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineWeightDescriptionMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'onlineWeightDescription',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineWeightDescriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'onlineWeightDescription',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      onlineWeightDescriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'onlineWeightDescription',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      parentStockItemIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'parentStockItemId',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      parentStockItemIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'parentStockItemId',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      parentStockItemIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parentStockItemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      parentStockItemIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'parentStockItemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      parentStockItemIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'parentStockItemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      parentStockItemIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'parentStockItemId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      parentStockItemIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'parentStockItemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      parentStockItemIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'parentStockItemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      parentStockItemIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'parentStockItemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      parentStockItemIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'parentStockItemId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      parentStockItemIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parentStockItemId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      parentStockItemIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'parentStockItemId',
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
      stockDeductionQtyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'stockDeductionQty',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockDeductionQtyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'stockDeductionQty',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockDeductionQtyEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stockDeductionQty',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockDeductionQtyGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stockDeductionQty',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockDeductionQtyLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stockDeductionQty',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockDeductionQtyBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stockDeductionQty',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockDeductionUnitIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'stockDeductionUnit',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockDeductionUnitIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'stockDeductionUnit',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockDeductionUnitEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stockDeductionUnit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockDeductionUnitGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stockDeductionUnit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockDeductionUnitLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stockDeductionUnit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockDeductionUnitBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stockDeductionUnit',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockDeductionUnitStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'stockDeductionUnit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockDeductionUnitEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'stockDeductionUnit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockDeductionUnitContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'stockDeductionUnit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockDeductionUnitMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'stockDeductionUnit',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockDeductionUnitIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stockDeductionUnit',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterFilterCondition>
      stockDeductionUnitIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'stockDeductionUnit',
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
      sortByIsBestSeller() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBestSeller', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByIsBestSellerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBestSeller', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByIsFeatured() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFeatured', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByIsFeaturedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFeatured', Sort.desc);
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
      sortByOnlineAllergens() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineAllergens', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByOnlineAllergensDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineAllergens', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByOnlineCookingTips() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineCookingTips', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByOnlineCookingTipsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineCookingTips', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByOnlineDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineDisplayName', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByOnlineDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineDisplayName', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByOnlineImageUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineImageUrl', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByOnlineImageUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineImageUrl', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByOnlineIngredients() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineIngredients', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByOnlineIngredientsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineIngredients', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByOnlineMinStockThreshold() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineMinStockThreshold', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByOnlineMinStockThresholdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineMinStockThreshold', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByOnlineSortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineSortOrder', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByOnlineSortOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineSortOrder', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByOnlineWeightDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineWeightDescription', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByOnlineWeightDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineWeightDescription', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByParentStockItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentStockItemId', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByParentStockItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentStockItemId', Sort.desc);
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
      sortByStockDeductionQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockDeductionQty', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByStockDeductionQtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockDeductionQty', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByStockDeductionUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockDeductionUnit', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      sortByStockDeductionUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockDeductionUnit', Sort.desc);
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
      thenByIsBestSeller() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBestSeller', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByIsBestSellerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBestSeller', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByIsFeatured() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFeatured', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByIsFeaturedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFeatured', Sort.desc);
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
      thenByOnlineAllergens() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineAllergens', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByOnlineAllergensDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineAllergens', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByOnlineCookingTips() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineCookingTips', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByOnlineCookingTipsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineCookingTips', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByOnlineDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineDisplayName', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByOnlineDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineDisplayName', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByOnlineImageUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineImageUrl', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByOnlineImageUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineImageUrl', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByOnlineIngredients() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineIngredients', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByOnlineIngredientsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineIngredients', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByOnlineMinStockThreshold() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineMinStockThreshold', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByOnlineMinStockThresholdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineMinStockThreshold', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByOnlineSortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineSortOrder', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByOnlineSortOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineSortOrder', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByOnlineWeightDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineWeightDescription', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByOnlineWeightDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlineWeightDescription', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByParentStockItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentStockItemId', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByParentStockItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentStockItemId', Sort.desc);
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
      thenByStockDeductionQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockDeductionQty', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByStockDeductionQtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockDeductionQty', Sort.desc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByStockDeductionUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockDeductionUnit', Sort.asc);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QAfterSortBy>
      thenByStockDeductionUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockDeductionUnit', Sort.desc);
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
      distinctByIsBestSeller() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isBestSeller');
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByIsFeatured() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFeatured');
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
      distinctByOnlineAllergens({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'onlineAllergens',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByOnlineCookingTips({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'onlineCookingTips',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByOnlineDisplayName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'onlineDisplayName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByOnlineImageUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'onlineImageUrl',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByOnlineIngredients({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'onlineIngredients',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByOnlineMinStockThreshold() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'onlineMinStockThreshold');
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByOnlineSortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'onlineSortOrder');
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByOnlineWeightDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'onlineWeightDescription',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByParentStockItemId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'parentStockItemId',
          caseSensitive: caseSensitive);
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
      distinctByStockDeductionQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stockDeductionQty');
    });
  }

  QueryBuilder<CachedInventoryItem, CachedInventoryItem, QDistinct>
      distinctByStockDeductionUnit({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stockDeductionUnit',
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

  QueryBuilder<CachedInventoryItem, bool?, QQueryOperations>
      isBestSellerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isBestSeller');
    });
  }

  QueryBuilder<CachedInventoryItem, bool?, QQueryOperations>
      isFeaturedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFeatured');
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

  QueryBuilder<CachedInventoryItem, String?, QQueryOperations>
      onlineAllergensProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'onlineAllergens');
    });
  }

  QueryBuilder<CachedInventoryItem, String?, QQueryOperations>
      onlineCookingTipsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'onlineCookingTips');
    });
  }

  QueryBuilder<CachedInventoryItem, String?, QQueryOperations>
      onlineDisplayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'onlineDisplayName');
    });
  }

  QueryBuilder<CachedInventoryItem, String?, QQueryOperations>
      onlineImageUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'onlineImageUrl');
    });
  }

  QueryBuilder<CachedInventoryItem, String?, QQueryOperations>
      onlineIngredientsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'onlineIngredients');
    });
  }

  QueryBuilder<CachedInventoryItem, double?, QQueryOperations>
      onlineMinStockThresholdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'onlineMinStockThreshold');
    });
  }

  QueryBuilder<CachedInventoryItem, int?, QQueryOperations>
      onlineSortOrderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'onlineSortOrder');
    });
  }

  QueryBuilder<CachedInventoryItem, String?, QQueryOperations>
      onlineWeightDescriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'onlineWeightDescription');
    });
  }

  QueryBuilder<CachedInventoryItem, String?, QQueryOperations>
      parentStockItemIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'parentStockItemId');
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
      stockDeductionQtyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stockDeductionQty');
    });
  }

  QueryBuilder<CachedInventoryItem, String?, QQueryOperations>
      stockDeductionUnitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stockDeductionUnit');
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
