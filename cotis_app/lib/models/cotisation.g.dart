// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cotisation.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCotisationCollection on Isar {
  IsarCollection<Cotisation> get cotisations => this.collection();
}

const CotisationSchema = CollectionSchema(
  name: r'Cotisation',
  id: -3683500818952589794,
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
    r'notes': PropertySchema(
      id: 5,
      name: r'notes',
      type: IsarType.string,
    ),
    r'statut': PropertySchema(
      id: 6,
      name: r'statut',
      type: IsarType.string,
      enumMap: _CotisationstatutEnumValueMap,
    ),
    r'uniqueKey': PropertySchema(
      id: 7,
      name: r'uniqueKey',
      type: IsarType.string,
    )
  },
  estimateSize: _cotisationEstimateSize,
  serialize: _cotisationSerialize,
  deserialize: _cotisationDeserialize,
  deserializeProp: _cotisationDeserializeProp,
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
  getId: _cotisationGetId,
  getLinks: _cotisationGetLinks,
  attach: _cotisationAttach,
  version: '3.1.0+1',
);

int _cotisationEstimateSize(
  Cotisation object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.culteId.length * 3;
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.membreId.length * 3;
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.statut.name.length * 3;
  bytesCount += 3 + object.uniqueKey.length * 3;
  return bytesCount;
}

void _cotisationSerialize(
  Cotisation object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.culteId);
  writer.writeDateTime(offsets[1], object.datePaiement);
  writer.writeString(offsets[2], object.id);
  writer.writeString(offsets[3], object.membreId);
  writer.writeDouble(offsets[4], object.montant);
  writer.writeString(offsets[5], object.notes);
  writer.writeString(offsets[6], object.statut.name);
  writer.writeString(offsets[7], object.uniqueKey);
}

Cotisation _cotisationDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Cotisation();
  object.culteId = reader.readString(offsets[0]);
  object.datePaiement = reader.readDateTimeOrNull(offsets[1]);
  object.id = reader.readString(offsets[2]);
  object.isarId = id;
  object.membreId = reader.readString(offsets[3]);
  object.montant = reader.readDouble(offsets[4]);
  object.notes = reader.readStringOrNull(offsets[5]);
  object.statut =
      _CotisationstatutValueEnumMap[reader.readStringOrNull(offsets[6])] ??
          StatutCotisation.nonPaye;
  return object;
}

P _cotisationDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (_CotisationstatutValueEnumMap[reader.readStringOrNull(offset)] ??
          StatutCotisation.nonPaye) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _CotisationstatutEnumValueMap = {
  r'nonPaye': r'nonPaye',
  r'paye': r'paye',
  r'absent': r'absent',
  r'enAvance': r'enAvance',
};
const _CotisationstatutValueEnumMap = {
  r'nonPaye': StatutCotisation.nonPaye,
  r'paye': StatutCotisation.paye,
  r'absent': StatutCotisation.absent,
  r'enAvance': StatutCotisation.enAvance,
};

Id _cotisationGetId(Cotisation object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _cotisationGetLinks(Cotisation object) {
  return [];
}

void _cotisationAttach(IsarCollection<dynamic> col, Id id, Cotisation object) {
  object.isarId = id;
}

extension CotisationByIndex on IsarCollection<Cotisation> {
  Future<Cotisation?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  Cotisation? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<Cotisation?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<Cotisation?> getAllByIdSync(List<String> idValues) {
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

  Future<Id> putById(Cotisation object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(Cotisation object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<Cotisation> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<Cotisation> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }

  Future<Cotisation?> getByUniqueKeyCulteId(String uniqueKey, String culteId) {
    return getByIndex(r'uniqueKey_culteId', [uniqueKey, culteId]);
  }

  Cotisation? getByUniqueKeyCulteIdSync(String uniqueKey, String culteId) {
    return getByIndexSync(r'uniqueKey_culteId', [uniqueKey, culteId]);
  }

  Future<bool> deleteByUniqueKeyCulteId(String uniqueKey, String culteId) {
    return deleteByIndex(r'uniqueKey_culteId', [uniqueKey, culteId]);
  }

  bool deleteByUniqueKeyCulteIdSync(String uniqueKey, String culteId) {
    return deleteByIndexSync(r'uniqueKey_culteId', [uniqueKey, culteId]);
  }

  Future<List<Cotisation?>> getAllByUniqueKeyCulteId(
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

  List<Cotisation?> getAllByUniqueKeyCulteIdSync(
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

  Future<Id> putByUniqueKeyCulteId(Cotisation object) {
    return putByIndex(r'uniqueKey_culteId', object);
  }

  Id putByUniqueKeyCulteIdSync(Cotisation object, {bool saveLinks = true}) {
    return putByIndexSync(r'uniqueKey_culteId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUniqueKeyCulteId(List<Cotisation> objects) {
    return putAllByIndex(r'uniqueKey_culteId', objects);
  }

  List<Id> putAllByUniqueKeyCulteIdSync(List<Cotisation> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'uniqueKey_culteId', objects,
        saveLinks: saveLinks);
  }
}

extension CotisationQueryWhereSort
    on QueryBuilder<Cotisation, Cotisation, QWhere> {
  QueryBuilder<Cotisation, Cotisation, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CotisationQueryWhere
    on QueryBuilder<Cotisation, Cotisation, QWhereClause> {
  QueryBuilder<Cotisation, Cotisation, QAfterWhereClause> isarIdEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterWhereClause> isarIdNotEqualTo(
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

  QueryBuilder<Cotisation, Cotisation, QAfterWhereClause> isarIdGreaterThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterWhereClause> isarIdLessThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterWhereClause> isarIdBetween(
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

  QueryBuilder<Cotisation, Cotisation, QAfterWhereClause> idEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterWhereClause> idNotEqualTo(
      String id) {
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

  QueryBuilder<Cotisation, Cotisation, QAfterWhereClause> membreIdEqualTo(
      String membreId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'membreId',
        value: [membreId],
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterWhereClause> membreIdNotEqualTo(
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

  QueryBuilder<Cotisation, Cotisation, QAfterWhereClause> culteIdEqualTo(
      String culteId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'culteId',
        value: [culteId],
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterWhereClause> culteIdNotEqualTo(
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

  QueryBuilder<Cotisation, Cotisation, QAfterWhereClause>
      uniqueKeyEqualToAnyCulteId(String uniqueKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uniqueKey_culteId',
        value: [uniqueKey],
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterWhereClause>
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

  QueryBuilder<Cotisation, Cotisation, QAfterWhereClause>
      uniqueKeyCulteIdEqualTo(String uniqueKey, String culteId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uniqueKey_culteId',
        value: [uniqueKey, culteId],
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterWhereClause>
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

extension CotisationQueryFilter
    on QueryBuilder<Cotisation, Cotisation, QFilterCondition> {
  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> culteIdEqualTo(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition>
      culteIdGreaterThan(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> culteIdLessThan(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> culteIdBetween(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> culteIdStartsWith(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> culteIdEndsWith(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> culteIdContains(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> culteIdMatches(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> culteIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'culteId',
        value: '',
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition>
      culteIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'culteId',
        value: '',
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition>
      datePaiementIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'datePaiement',
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition>
      datePaiementIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'datePaiement',
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition>
      datePaiementEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'datePaiement',
        value: value,
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition>
      datePaiementGreaterThan(
    DateTime? value, {
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition>
      datePaiementLessThan(
    DateTime? value, {
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition>
      datePaiementBetween(
    DateTime? lower,
    DateTime? upper, {
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> idEqualTo(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> idStartsWith(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> idEndsWith(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> idContains(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> idMatches(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> isarIdEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> isarIdGreaterThan(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> isarIdLessThan(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> isarIdBetween(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> membreIdEqualTo(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition>
      membreIdGreaterThan(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> membreIdLessThan(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> membreIdBetween(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition>
      membreIdStartsWith(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> membreIdEndsWith(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> membreIdContains(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> membreIdMatches(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition>
      membreIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'membreId',
        value: '',
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition>
      membreIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'membreId',
        value: '',
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> montantEqualTo(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition>
      montantGreaterThan(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> montantLessThan(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> montantBetween(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> notesEqualTo(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> notesGreaterThan(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> notesLessThan(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> notesBetween(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> notesStartsWith(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> notesEndsWith(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> notesContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> notesMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition>
      notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> statutEqualTo(
    StatutCotisation value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'statut',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> statutGreaterThan(
    StatutCotisation value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'statut',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> statutLessThan(
    StatutCotisation value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'statut',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> statutBetween(
    StatutCotisation lower,
    StatutCotisation upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'statut',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> statutStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'statut',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> statutEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'statut',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> statutContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'statut',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> statutMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'statut',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> statutIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'statut',
        value: '',
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition>
      statutIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'statut',
        value: '',
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> uniqueKeyEqualTo(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition>
      uniqueKeyGreaterThan(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> uniqueKeyLessThan(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> uniqueKeyBetween(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition>
      uniqueKeyStartsWith(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> uniqueKeyEndsWith(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> uniqueKeyContains(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition> uniqueKeyMatches(
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

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition>
      uniqueKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uniqueKey',
        value: '',
      ));
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterFilterCondition>
      uniqueKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uniqueKey',
        value: '',
      ));
    });
  }
}

extension CotisationQueryObject
    on QueryBuilder<Cotisation, Cotisation, QFilterCondition> {}

extension CotisationQueryLinks
    on QueryBuilder<Cotisation, Cotisation, QFilterCondition> {}

extension CotisationQuerySortBy
    on QueryBuilder<Cotisation, Cotisation, QSortBy> {
  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> sortByCulteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'culteId', Sort.asc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> sortByCulteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'culteId', Sort.desc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> sortByDatePaiement() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'datePaiement', Sort.asc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> sortByDatePaiementDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'datePaiement', Sort.desc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> sortByMembreId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'membreId', Sort.asc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> sortByMembreIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'membreId', Sort.desc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> sortByMontant() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'montant', Sort.asc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> sortByMontantDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'montant', Sort.desc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> sortByStatut() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statut', Sort.asc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> sortByStatutDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statut', Sort.desc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> sortByUniqueKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.asc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> sortByUniqueKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.desc);
    });
  }
}

extension CotisationQuerySortThenBy
    on QueryBuilder<Cotisation, Cotisation, QSortThenBy> {
  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> thenByCulteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'culteId', Sort.asc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> thenByCulteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'culteId', Sort.desc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> thenByDatePaiement() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'datePaiement', Sort.asc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> thenByDatePaiementDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'datePaiement', Sort.desc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> thenByMembreId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'membreId', Sort.asc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> thenByMembreIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'membreId', Sort.desc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> thenByMontant() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'montant', Sort.asc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> thenByMontantDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'montant', Sort.desc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> thenByStatut() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statut', Sort.asc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> thenByStatutDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statut', Sort.desc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> thenByUniqueKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.asc);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QAfterSortBy> thenByUniqueKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.desc);
    });
  }
}

extension CotisationQueryWhereDistinct
    on QueryBuilder<Cotisation, Cotisation, QDistinct> {
  QueryBuilder<Cotisation, Cotisation, QDistinct> distinctByCulteId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'culteId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QDistinct> distinctByDatePaiement() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'datePaiement');
    });
  }

  QueryBuilder<Cotisation, Cotisation, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QDistinct> distinctByMembreId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'membreId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QDistinct> distinctByMontant() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'montant');
    });
  }

  QueryBuilder<Cotisation, Cotisation, QDistinct> distinctByNotes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QDistinct> distinctByStatut(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'statut', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Cotisation, Cotisation, QDistinct> distinctByUniqueKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uniqueKey', caseSensitive: caseSensitive);
    });
  }
}

extension CotisationQueryProperty
    on QueryBuilder<Cotisation, Cotisation, QQueryProperty> {
  QueryBuilder<Cotisation, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<Cotisation, String, QQueryOperations> culteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'culteId');
    });
  }

  QueryBuilder<Cotisation, DateTime?, QQueryOperations> datePaiementProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'datePaiement');
    });
  }

  QueryBuilder<Cotisation, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Cotisation, String, QQueryOperations> membreIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'membreId');
    });
  }

  QueryBuilder<Cotisation, double, QQueryOperations> montantProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'montant');
    });
  }

  QueryBuilder<Cotisation, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<Cotisation, StatutCotisation, QQueryOperations>
      statutProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'statut');
    });
  }

  QueryBuilder<Cotisation, String, QQueryOperations> uniqueKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uniqueKey');
    });
  }
}
