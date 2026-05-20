import 'package:isar/isar.dart';

part 'culte.g.dart';

@collection
class Culte {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id; // UUID from InsForge

  late DateTime dateCulte; // Renommé de date
  String? titre;
  double montantCotisation = 50.0;
  String? notes; // Renommé de note

  @ignore
  String get dateFormatee {
    const mois = ['Jan','Fév','Mar','Avr','Mai','Jun',
                   'Jul','Aoû','Sep','Oct','Nov','Déc'];
    final wd = dateCulte.weekday;
    final nomJour = wd == 7 ? 'Dimanche' : ['Lun','Mar','Mer','Jeu','Ven','Sam'][wd-1];
    return '$nomJour ${dateCulte.day} ${mois[dateCulte.month - 1]} ${dateCulte.year}';
  }

  // Helper for JSON (InsForge)
  Map<String, dynamic> toJson() => {
    'date_culte': dateCulte.toIso8601String().substring(0, 10),
    if (titre != null) 'titre': titre,
    'montant_cotisation': montantCotisation,
    if (notes != null) 'notes': notes,
  };

  static Culte fromJson(Map<String, dynamic> json) {
    return Culte()
      ..id = json['id'] as String
      ..dateCulte = DateTime.parse(json['date_culte'] as String)
      ..titre = json['titre'] as String?
      ..montantCotisation = (json['montant_cotisation'] as num?)?.toDouble() ?? 50.0
      ..notes = json['notes'] as String?;
  }
}
