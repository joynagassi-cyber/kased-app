// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paiement.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPaiementCollection on Isar {
  IsarCollection<Paiement> get paiements => this.collection();
}

const PaiementSchema = CollectionSchema(
  name: r'Paiement',
  id: 7524929244091311515,
  properties: {
    r'culteId': PropertySchema(
      id: 0,
      name: r'culteId',
      type: IsarType.string,
    ),
    r'datePaiement': PropertySchema(
      id: 1,
      name: r'datePaiement',
      type: IsarType.dateTime,
    ),
    r'id': PropertySchema(
      id: 2,
      name: r'id',
      type: IsarType.string,
    ),
    r'membreId': PropertySchema(
      id: 3,
      name: r'membreId',
      type: IsarType.string,
    ),
    r'montant': PropertySchema(
      id: 4,
      name: r'montant',
      type: IsarType.double,
    ),
    r'uniqueKey': PropertySchema(
      id: 5,
      name: r'uniqueKey',
      type: IsarType.string,
    )
  },
  estimateSize: _paiementEstimateSize,
  serialize: _paiementSerialize,
  deserialize: _paiementDeserialize,
  deserializeProp: _paiementDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'id': IndexSchema(
      id: -3268401673993471357,
      name: r'id',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'id',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'membreId': IndexSchema(
      id: -4827539301882621589,
      name: r'membreId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'membreId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'culteId': IndexSchema(
      id: 7218953392516278964,
      name: r'culteId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'culteId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'uniqueKey_culteId': IndexSchema(
      id: 2363571498557449324,
      name: r'uniqueKey_culteId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'uniqueKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'culteId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _paiementGetId,
  getLinks: _paiementGetLinks,
  attach: _paiementAttach,
  version: '3.1.0+1',
);

int _paiementEstimateSize(
  Paiement object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.culteId.length * 3;
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.membreId.length * 3;
  bytesCount += 3 + object.uniqueKey.length * 3;
  return bytesCount;
}

void _paiementSerialize(
  Paiement object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.culteId);
  writer.writeDateTime(offsets[1], object.datePaiement);
  writer.writeString(offsets[2], object.id);
  writer.writeString(offsets[3], object.membreId);
  writer.writeDouble(offsets[4], object.montant);
  writer.writeString(offsets[5], object.uniqueKey);
}

Paiement _paiementDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Paiement();
  object.culteId = reader.readString(offsets[0]);
  object.datePaiement = reader.readDateTime(offsets[1]);
  object.id = reader.readString(offsets[2]);
  object.isarId = id;
  object.membreId = reader.readString(offsets[3]);
  object.montant = reader.readDouble(offsets[4]);
  return object;
}

P _paiementDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _paiementGetId(Paiement object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _paiementGetLinks(Paiement object) {
  return [];
}

void _paiementAttach(IsarCollection<dynamic> col, Id id, Paiement object) {
  object.isarId = id;
}

extension PaiementByIndex on IsarCollection<Paiement> {
  Future<Paiement?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  Paiement? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<Paiement?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<Paiement?> getAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'id', values);
  }

  Future<int> deleteAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'id', values);
  }

  int deleteAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'id', values);
  }

  Future<Id> putById(Paiement object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(Paiement object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<Paiement> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<Paiement> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }

  Future<Paiement?> getByUniqueKeyCulteId(String uniqueKey, String culteId) {
    return getByIndex(r'uniqueKey_culteId', [uniqueKey, culteId]);
  }

  Paiement? getByUniqueKeyCulteIdSync(String uniqueKey, String culteId) {
    return getByIndexSync(r'uniqueKey_culteId', [uniqueKey, culteId]);
  }

  Future<bool> deleteByUniqueKeyCulteId(String uniqueKey, String culteId) {
    return deleteByIndex(r'uniqueKey_culteId', [uniqueKey, culteId]);
  }

  bool deleteByUniqueKeyCulteIdSync(String uniqueKey, String culteId) {
    return deleteByIndexSync(r'uniqueKey_culteId', [uniqueKey, culteId]);
  }

  Future<List<Paiement?>> getAllByUniqueKeyCulteId(
      List<String> uniqueKeyValues, List<String> culteIdValues) {
    final len = uniqueKeyValues.length;
    assert(culteIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([uniqueKeyValues[i], culteIdValues[i]]);
    }

    return getAllByIndex(r'uniqueKey_culteId', values);
  }

  List<Paiement?> getAllByUniqueKeyCulteIdSync(
      List<String> uniqueKeyValues, List<String> culteIdValues) {
    final len = uniqueKeyValues.length;
    assert(culteIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([uniqueKeyValues[i], culteIdValues[i]]);
    }

    return getAllByIndexSync(r'uniqueKey_culteId', values);
  }

  Future<int> deleteAllByUniqueKeyCulteId(
      List<String> uniqueKeyValues, List<String> culteIdValues) {
    final len = uniqueKeyValues.length;
    assert(culteIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([uniqueKeyValues[i], culteIdValues[i]]);
    }

    return deleteAllByIndex(r'uniqueKey_culteId', values);
  }

  int deleteAllByUniqueKeyCulteIdSync(
      List<String> uniqueKeyValues, List<String> culteIdValues) {
    final len = uniqueKeyValues.length;
    assert(culteIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([uniqueKeyValues[i], culteIdValues[i]]);
    }

    return deleteAllByIndexSync(r'uniqueKey_culteId', values);
  }

  Future<Id> putByUniqueKeyCulteId(Paiement object) {
    return putByIndex(r'uniqueKey_culteId', object);
  }

  Id putByUniqueKeyCulteIdSync(Paiement object, {bool saveLinks = true}) {
    return putByIndexSync(r'uniqueKey_culteId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUniqueKeyCulteId(List<Paiement> objects) {
    return putAllByIndex(r'uniqueKey_culteId', objects);
  }

  List<Id> putAllByUniqueKeyCulteIdSync(List<Paiement> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'uniqueKey_culteId', objects,
        saveLinks: saveLinks);
  }
}

extension PaiementQueryWhereSort on QueryBuilder<Paiement, Paiement, QWhere> {
  QueryBuilder<Paiement, Paiement, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PaiementQueryWhere on QueryBuilder<Paiement, Paiement, QWhereClause> {
  QueryBuilder<Paiement, Paiement, QAfterWhereClause> isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterWhereClause> isarIdNotEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterWhereClause> isarIdGreaterThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterWhereClause> isarIdLessThan(Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterWhereClause> idEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterWhereClause> idNotEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterWhereClause> membreIdEqualTo(
      String membreId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'membreId',
        value: [membreId],
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterWhereClause> membreIdNotEqualTo(
      String membreId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'membreId',
              lower: [],
              upper: [membreId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'membreId',
              lower: [membreId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'membreId',
              lower: [membreId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'membreId',
              lower: [],
              upper: [membreId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterWhereClause> culteIdEqualTo(
      String culteId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'culteId',
        value: [culteId],
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterWhereClause> culteIdNotEqualTo(
      String culteId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'culteId',
              lower: [],
              upper: [culteId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'culteId',
              lower: [culteId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'culteId',
              lower: [culteId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'culteId',
              lower: [],
              upper: [culteId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterWhereClause>
      uniqueKeyEqualToAnyCulteId(String uniqueKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uniqueKey_culteId',
        value: [uniqueKey],
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterWhereClause>
      uniqueKeyNotEqualToAnyCulteId(String uniqueKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uniqueKey_culteId',
              lower: [],
              upper: [uniqueKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uniqueKey_culteId',
              lower: [uniqueKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uniqueKey_culteId',
              lower: [uniqueKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uniqueKey_culteId',
              lower: [],
              upper: [uniqueKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterWhereClause> uniqueKeyCulteIdEqualTo(
      String uniqueKey, String culteId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uniqueKey_culteId',
        value: [uniqueKey, culteId],
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterWhereClause>
      uniqueKeyEqualToCulteIdNotEqualTo(String uniqueKey, String culteId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uniqueKey_culteId',
              lower: [uniqueKey],
              upper: [uniqueKey, culteId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uniqueKey_culteId',
              lower: [uniqueKey, culteId],
              includeLower: false,
              upper: [uniqueKey],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uniqueKey_culteId',
              lower: [uniqueKey, culteId],
              includeLower: false,
              upper: [uniqueKey],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uniqueKey_culteId',
              lower: [uniqueKey],
              upper: [uniqueKey, culteId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension PaiementQueryFilter
    on QueryBuilder<Paiement, Paiement, QFilterCondition> {
  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> culteIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'culteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> culteIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'culteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> culteIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'culteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> culteIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'culteId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> culteIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'culteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> culteIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'culteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> culteIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'culteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> culteIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'culteId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> culteIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'culteId',
        value: '',
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> culteIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'culteId',
        value: '',
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> datePaiementEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'datePaiement',
        value: value,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition>
      datePaiementGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'datePaiement',
        value: value,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> datePaiementLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'datePaiement',
        value: value,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> datePaiementBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'datePaiement',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> idContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> idMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> isarIdEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> membreIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'membreId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> membreIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'membreId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> membreIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'membreId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> membreIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'membreId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> membreIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'membreId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> membreIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'membreId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> membreIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'membreId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> membreIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'membreId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> membreIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'membreId',
        value: '',
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> membreIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'membreId',
        value: '',
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> montantEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'montant',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> montantGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'montant',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> montantLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'montant',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> montantBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'montant',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> uniqueKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uniqueKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> uniqueKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uniqueKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> uniqueKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uniqueKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> uniqueKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uniqueKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> uniqueKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uniqueKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> uniqueKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uniqueKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> uniqueKeyContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uniqueKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> uniqueKeyMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uniqueKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition> uniqueKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uniqueKey',
        value: '',
      ));
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterFilterCondition>
      uniqueKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uniqueKey',
        value: '',
      ));
    });
  }
}

extension PaiementQueryObject
    on QueryBuilder<Paiement, Paiement, QFilterCondition> {}

extension PaiementQueryLinks
    on QueryBuilder<Paiement, Paiement, QFilterCondition> {}

extension PaiementQuerySortBy on QueryBuilder<Paiement, Paiement, QSortBy> {
  QueryBuilder<Paiement, Paiement, QAfterSortBy> sortByCulteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'culteId', Sort.asc);
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterSortBy> sortByCulteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'culteId', Sort.desc);
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterSortBy> sortByDatePaiement() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'datePaiement', Sort.asc);
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterSortBy> sortByDatePaiementDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'datePaiement', Sort.desc);
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterSortBy> sortByMembreId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'membreId', Sort.asc);
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterSortBy> sortByMembreIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'membreId', Sort.desc);
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterSortBy> sortByMontant() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'montant', Sort.asc);
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterSortBy> sortByMontantDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'montant', Sort.desc);
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterSortBy> sortByUniqueKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.asc);
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterSortBy> sortByUniqueKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.desc);
    });
  }
}

extension PaiementQuerySortThenBy
    on QueryBuilder<Paiement, Paiement, QSortThenBy> {
  QueryBuilder<Paiement, Paiement, QAfterSortBy> thenByCulteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'culteId', Sort.asc);
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterSortBy> thenByCulteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'culteId', Sort.desc);
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterSortBy> thenByDatePaiement() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'datePaiement', Sort.asc);
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterSortBy> thenByDatePaiementDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'datePaiement', Sort.desc);
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterSortBy> thenByMembreId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'membreId', Sort.asc);
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterSortBy> thenByMembreIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'membreId', Sort.desc);
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterSortBy> thenByMontant() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'montant', Sort.asc);
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterSortBy> thenByMontantDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'montant', Sort.desc);
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterSortBy> thenByUniqueKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.asc);
    });
  }

  QueryBuilder<Paiement, Paiement, QAfterSortBy> thenByUniqueKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.desc);
    });
  }
}

extension PaiementQueryWhereDistinct
    on QueryBuilder<Paiement, Paiement, QDistinct> {
  QueryBuilder<Paiement, Paiement, QDistinct> distinctByCulteId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'culteId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Paiement, Paiement, QDistinct> distinctByDatePaiement() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'datePaiement');
    });
  }

  QueryBuilder<Paiement, Paiement, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Paiement, Paiement, QDistinct> distinctByMembreId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'membreId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Paiement, Paiement, QDistinct> distinctByMontant() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'montant');
    });
  }

  QueryBuilder<Paiement, Paiement, QDistinct> distinctByUniqueKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uniqueKey', caseSensitive: caseSensitive);
    });
  }
}

extension PaiementQueryProperty
    on QueryBuilder<Paiement, Paiement, QQueryProperty> {
  QueryBuilder<Paiement, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<Paiement, String, QQueryOperations> culteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'culteId');
    });
  }

  QueryBuilder<Paiement, DateTime, QQueryOperations> datePaiementProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'datePaiement');
    });
  }

  QueryBuilder<Paiement, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Paiement, String, QQueryOperations> membreIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'membreId');
    });
  }

  QueryBuilder<Paiement, double, QQueryOperations> montantProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'montant');
    });
  }

  QueryBuilder<Paiement, String, QQueryOperations> uniqueKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uniqueKey');
    });
  }
}
