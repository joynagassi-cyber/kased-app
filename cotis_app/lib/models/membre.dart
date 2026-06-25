import 'package:isar/isar.dart';

part 'membre.g.dart';

@collection
class Membre {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  late String nom;
  late String prenom;
  late DateTime dateAdhesion;
  DateTime? dateNaissance;
  String? telephone;
  String? notes;
  bool isActive = true;
  DateTime? updatedAt;
  DateTime createdAt = DateTime.now();
  int version = 1;
  String deviceId = '';
  bool isDeleted = false;
  DateTime? deletedAt;
  String? deletedBy;

  @ignore
  String get nomComplet => '$prenom $nom'.trim();

  @ignore
  String get initiales {
    if (prenom.isEmpty && nom.isEmpty) return '?';
    final p = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final n = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    return '$p$n';
  }

  @ignore
  bool get anniversaireAujourdHui {
    final birth = dateNaissance;
    if (birth == null) return false;
    final now = DateTime.now();
    return now.month == birth.month && now.day == birth.day;
  }

  @ignore
  int? get age {
    final birth = dateNaissance;
    if (birth == null) return null;
    final now = DateTime.now();
    var value = now.year - birth.year;
    final birthdayThisYear = DateTime(now.year, birth.month, birth.day);
    if (birthdayThisYear.isAfter(now)) {
      value -= 1;
    }
    return value;
  }

  // Helper for JSON (InsForge)
  Map<String, dynamic> toJson() => {
    'nom': nom,
    'prenom': prenom,
    'date_adhesion': dateAdhesion.toIso8601String().substring(0, 10),
    if (dateNaissance != null) 'date_naissance': dateNaissance!.toIso8601String().substring(0, 10),
    if (telephone != null) 'telephone': telephone,
    if (notes != null) 'notes': notes,
    'is_active': isActive,
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'version': version,
    'device_id': deviceId,
    'is_deleted': isDeleted,
    if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    if (deletedBy != null) 'deleted_by': deletedBy,
  };

  static Membre fromJson(Map<String, dynamic> json) {
    return Membre()
      ..id = json['id'] as String
      ..nom = json['nom'] as String
      ..prenom = json['prenom'] as String
      ..dateAdhesion = DateTime.parse(json['date_adhesion'] as String)
      ..dateNaissance = json['date_naissance'] == null
          ? null
          : DateTime.parse(json['date_naissance'] as String)
      ..telephone = json['telephone'] as String?
      ..notes = json['notes'] as String?
      ..isActive = json['is_active'] as bool? ?? true
      ..updatedAt = json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String)
      ..createdAt = json['created_at'] == null
          ? DateTime.now()
          : DateTime.parse(json['created_at'] as String)
      ..version = (json['version'] as num?)?.toInt() ?? 1
      ..deviceId = json['device_id'] as String? ?? ''
      ..isDeleted = json['is_deleted'] as bool? ?? false
      ..deletedAt = json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String)
      ..deletedBy = json['deleted_by'] as String?;
  }
}
