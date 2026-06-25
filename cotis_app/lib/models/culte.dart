import 'package:isar/isar.dart';

part 'culte.g.dart';

@collection
class Culte {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  late DateTime dateCulte;
  String? titre;
  double montantCotisation = 50.0;
  String? notes;
  DateTime? updatedAt;
  DateTime createdAt = DateTime.now();
  int version = 1;
  String deviceId = '';
  bool isDeleted = false;
  DateTime? deletedAt;
  String? deletedBy;

  @ignore
  String get dateFormatee {
    const mois = ['Janvier','Février','Mars','Avril','Mai','Juin',
                   'Juillet','Août','Septembre','Octobre','Novembre','Décembre'];
    final wd = dateCulte.weekday;
    final nomJour = wd == 7 ? 'Dimanche' : ['Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi'][wd-1];
    return '$nomJour ${dateCulte.day} ${mois[dateCulte.month - 1]} ${dateCulte.year}';
  }

  // Helper for JSON (InsForge)
  Map<String, dynamic> toJson() => {
    'date_culte': dateCulte.toIso8601String().substring(0, 10),
    if (titre != null) 'titre': titre,
    'montant_cotisation': montantCotisation,
    if (notes != null) 'notes': notes,
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'version': version,
    'device_id': deviceId,
    'is_deleted': isDeleted,
    if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    if (deletedBy != null) 'deleted_by': deletedBy,
  };

  static Culte fromJson(Map<String, dynamic> json) {
    return Culte()
      ..id = json['id'] as String
      ..dateCulte = DateTime.parse(json['date_culte'] as String)
      ..titre = json['titre'] as String?
      ..montantCotisation = (json['montant_cotisation'] as num?)?.toDouble() ?? 50.0
      ..notes = json['notes'] as String?
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
