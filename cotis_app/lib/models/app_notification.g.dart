// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_notification.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAppNotificationCollection on Isar {
  IsarCollection<AppNotification> get appNotifications => this.collection();
}

const AppNotificationSchema = CollectionSchema(
  name: r'AppNotification',
  id: 7576332975032865864,
  properties: {
    r'date': PropertySchema(
      id: 0,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'entiteId': PropertySchema(
      id: 1,
      name: r'entiteId',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 2,
      name: r'id',
      type: IsarType.string,
    ),
    r'isLue': PropertySchema(
      id: 3,
      name: r'isLue',
      type: IsarType.bool,
    ),
    r'message': PropertySchema(
      id: 4,
      name: r'message',
      type: IsarType.string,
    ),
    r'titre': PropertySchema(
      id: 5,
      name: r'titre',
      type: IsarType.string,
    ),
    r'typeEvenement': PropertySchema(
      id: 6,
      name: r'typeEvenement',
      type: IsarType.string,
    )
  },
  estimateSize: _appNotificationEstimateSize,
  serialize: _appNotificationSerialize,
  deserialize: _appNotificationDeserialize,
  deserializeProp: _appNotificationDeserializeProp,
  idName: r'isarId',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _appNotificationGetId,
  getLinks: _appNotificationGetLinks,
  attach: _appNotificationAttach,
  version: '3.1.0+1',
);

int _appNotificationEstimateSize(
  AppNotification object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.entiteId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.message.length * 3;
  bytesCount += 3 + object.titre.length * 3;
  {
    final value = object.typeEvenement;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _appNotificationSerialize(
  AppNotification object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.date);
  writer.writeString(offsets[1], object.entiteId);
  writer.writeString(offsets[2], object.id);
  writer.writeBool(offsets[3], object.isLue);
  writer.writeString(offsets[4], object.message);
  writer.writeString(offsets[5], object.titre);
  writer.writeString(offsets[6], object.typeEvenement);
}

AppNotification _appNotificationDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AppNotification();
  object.date = reader.readDateTime(offsets[0]);
  object.entiteId = reader.readStringOrNull(offsets[1]);
  object.id = reader.readString(offsets[2]);
  object.isLue = reader.readBool(offsets[3]);
  object.isarId = id;
  object.message = reader.readString(offsets[4]);
  object.titre = reader.readString(offsets[5]);
  object.typeEvenement = reader.readStringOrNull(offsets[6]);
  return object;
}

P _appNotificationDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _appNotificationGetId(AppNotification object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _appNotificationGetLinks(AppNotification object) {
  return [];
}

void _appNotificationAttach(
    IsarCollection<dynamic> col, Id id, AppNotification object) {
  object.isarId = id;
}

extension AppNotificationQueryWhereSort
    on QueryBuilder<AppNotification, AppNotification, QWhere> {
  QueryBuilder<AppNotification, AppNotification, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AppNotificationQueryWhere
    on QueryBuilder<AppNotification, AppNotification, QWhereClause> {
  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause>
      isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause>
      isarIdNotEqualTo(Id isarId) {
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

  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause>
      isarIdBetween(
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
}

extension AppNotificationQueryFilter
    on QueryBuilder<AppNotification, AppNotification, QFilterCondition> {
  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      dateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      entiteIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'entiteId',
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      entiteIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'entiteId',
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      entiteIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'entiteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      entiteIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'entiteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      entiteIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'entiteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      entiteIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'entiteId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      entiteIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'entiteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      entiteIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'entiteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      entiteIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'entiteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      entiteIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'entiteId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      entiteIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'entiteId',
        value: '',
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      entiteIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'entiteId',
        value: '',
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      idEqualTo(
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

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      idStartsWith(
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

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      idEndsWith(
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

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      isLueEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isLue',
        value: value,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      isarIdGreaterThan(
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

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      isarIdLessThan(
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

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      isarIdBetween(
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

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      messageEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      messageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      messageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      messageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'message',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      messageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      messageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      messageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      messageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'message',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      messageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'message',
        value: '',
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      messageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'message',
        value: '',
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      titreEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'titre',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      titreGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'titre',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      titreLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'titre',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      titreBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'titre',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      titreStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'titre',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      titreEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'titre',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      titreContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'titre',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      titreMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'titre',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      titreIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'titre',
        value: '',
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      titreIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'titre',
        value: '',
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      typeEvenementIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'typeEvenement',
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      typeEvenementIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'typeEvenement',
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      typeEvenementEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'typeEvenement',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      typeEvenementGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'typeEvenement',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      typeEvenementLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'typeEvenement',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      typeEvenementBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'typeEvenement',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      typeEvenementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'typeEvenement',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      typeEvenementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'typeEvenement',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      typeEvenementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'typeEvenement',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      typeEvenementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'typeEvenement',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      typeEvenementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'typeEvenement',
        value: '',
      ));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
      typeEvenementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'typeEvenement',
        value: '',
      ));
    });
  }
}

extension AppNotificationQueryObject
    on QueryBuilder<AppNotification, AppNotification, QFilterCondition> {}

extension AppNotificationQueryLinks
    on QueryBuilder<AppNotification, AppNotification, QFilterCondition> {}

extension AppNotificationQuerySortBy
    on QueryBuilder<AppNotification, AppNotification, QSortBy> {
  QueryBuilder<AppNotification, AppNotification, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
      sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
      sortByEntiteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entiteId', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
      sortByEntiteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entiteId', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy> sortByIsLue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLue', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
      sortByIsLueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLue', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy> sortByMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
      sortByMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy> sortByTitre() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'titre', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
      sortByTitreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'titre', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
      sortByTypeEvenement() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeEvenement', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
      sortByTypeEvenementDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeEvenement', Sort.desc);
    });
  }
}

extension AppNotificationQuerySortThenBy
    on QueryBuilder<AppNotification, AppNotification, QSortThenBy> {
  QueryBuilder<AppNotification, AppNotification, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
      thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
      thenByEntiteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entiteId', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
      thenByEntiteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entiteId', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy> thenByIsLue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLue', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
      thenByIsLueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLue', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy> thenByMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
      thenByMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy> thenByTitre() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'titre', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
      thenByTitreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'titre', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
      thenByTypeEvenement() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeEvenement', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
      thenByTypeEvenementDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeEvenement', Sort.desc);
    });
  }
}

extension AppNotificationQueryWhereDistinct
    on QueryBuilder<AppNotification, AppNotification, QDistinct> {
  QueryBuilder<AppNotification, AppNotification, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<AppNotification, AppNotification, QDistinct> distinctByEntiteId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entiteId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QDistinct> distinctByIsLue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isLue');
    });
  }

  QueryBuilder<AppNotification, AppNotification, QDistinct> distinctByMessage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'message', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QDistinct> distinctByTitre(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'titre', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QDistinct>
      distinctByTypeEvenement({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'typeEvenement',
          caseSensitive: caseSensitive);
    });
  }
}

extension AppNotificationQueryProperty
    on QueryBuilder<AppNotification, AppNotification, QQueryProperty> {
  QueryBuilder<AppNotification, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<AppNotification, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<AppNotification, String?, QQueryOperations> entiteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entiteId');
    });
  }

  QueryBuilder<AppNotification, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AppNotification, bool, QQueryOperations> isLueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isLue');
    });
  }

  QueryBuilder<AppNotification, String, QQueryOperations> messageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'message');
    });
  }

  QueryBuilder<AppNotification, String, QQueryOperations> titreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'titre');
    });
  }

  QueryBuilder<AppNotification, String?, QQueryOperations>
      typeEvenementProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'typeEvenement');
    });
  }
}
