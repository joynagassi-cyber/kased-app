import 'package:isar/isar.dart';

part 'cotisation.g.dart';

enum StatutCotisation {
  nonPaye,   // Culte passé, pas encore payé
  paye,      // Payé (le jour même ou en rattrapage)
  absent,    // Membre absent ce dimanche
  enAvance   // Payé AVANT la date du culte
}

@collection
class Cotisation {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id; // UUID from InsForge

  @Index()
  late String membreId; // UUID of the member

  @Index()
  late String culteId; // UUID of the culte

  @Enumerated(EnumType.name)
  late StatutCotisation statut;

  double montant = 50.0;
  DateTime? datePaiement;
  String? notes;

  @Index(composite: [CompositeIndex('culteId')], unique: true)
  String get uniqueKey => '${membreId}_$culteId';

  @ignore
  bool get estPaye => statut == StatutCotisation.paye || statut == StatutCotisation.enAvance;

  @ignore
  bool get estEnRetard => statut == StatutCotisation.nonPaye;

  // Helper for JSON (InsForge)
  Map<String, dynamic> toJson() => {
    'membre_id': membreId,
    'culte_id': culteId,
    'statut': _statutToString(statut),
    'montant': montant,
    if (datePaiement != null) 'date_paiement': datePaiement!.toIso8601String(),
    if (notes != null) 'notes': notes,
  };

  static Cotisation fromJson(Map<String, dynamic> json) {
    return Cotisation()
      ..id = json['id'] as String
      ..membreId = json['membre_id'] as String
      ..culteId = json['culte_id'] as String
      ..statut = _stringToStatut(json['statut'] as String)
      ..montant = (json['montant'] as num?)?.toDouble() ?? 50.0
      ..datePaiement = json['date_paiement'] == null
          ? null
          : DateTime.parse(json['date_paiement'] as String)
      ..notes = json['notes'] as String?;
  }

  Cotisation copyWith({
    String? id,
    String? membreId,
    String? culteId,
    StatutCotisation? statut,
    double? montant,
    DateTime? datePaiement,
    String? notes,
  }) {
    return Cotisation()
      ..id = id ?? this.id
      ..membreId = membreId ?? this.membreId
      ..culteId = culteId ?? this.culteId
      ..statut = statut ?? this.statut
      ..montant = montant ?? this.montant
      ..datePaiement = datePaiement ?? this.datePaiement
      ..notes = notes ?? this.notes;
  }

  static String _statutToString(StatutCotisation statut) {
    switch (statut) {
      case StatutCotisation.nonPaye:
        return 'non_paye';
      case StatutCotisation.paye:
        return 'paye';
      case StatutCotisation.absent:
        return 'absent';
      case StatutCotisation.enAvance:
        return 'en_avance';
    }
  }

  static StatutCotisation _stringToStatut(String statut) {
    switch (statut) {
      case 'non_paye':
        return StatutCotisation.nonPaye;
      case 'paye':
        return StatutCotisation.paye;
      case 'absent':
        return StatutCotisation.absent;
      case 'en_avance':
        return StatutCotisation.enAvance;
      default:
        return StatutCotisation.nonPaye;
    }
  }
}
