import 'package:isar/isar.dart';

part 'membre.g.dart';

@collection
class Membre {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id; // UUID from InsForge

  late String nom;
  late String prenom;
  late DateTime dateAdhesion; // Renommé de dateInscription
  DateTime? dateNaissance;
  String? telephone;
  String? notes;
  bool isActive = true; // Renommé de isActif

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
      ..isActive = json['is_active'] as bool? ?? true;
  }
}
