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
  late String id;

  @Index()
  late String membreId;

  @Index()
  late String culteId;

  @Enumerated(EnumType.name)
  late StatutCotisation statut;

  // NOUVEAUX CHAMPS pour le support des paiements personnalisés/dons
  double montantObligatoire = 50.0; // Montant requis pour être à jour (fixé par le culte)
  double montantPaye = 0.0;         // Montant effectivement payé par le membre
  double montantDon = 0.0;          // Montant du don (excedent: montantPaye - montantObligatoire, si positif)

  DateTime? datePaiement;
  String? notes;
  DateTime? updatedAt;
  DateTime createdAt = DateTime.now();
  int version = 1;
  String deviceId = '';
  bool isDeleted = false;
  DateTime? deletedAt;
  String? deletedBy;

  @Index(composite: [CompositeIndex('culteId')], unique: true)
  String get uniqueKey => '${membreId}_$culteId';

  @ignore
  bool get estPaye =>
      statut == StatutCotisation.absent ? false : montantPaye >= montantObligatoire;

  @ignore
  bool get estEnRetard =>
      statut == StatutCotisation.absent ? false : montantPaye < montantObligatoire;

  // Helper for JSON (InsForge)
  Map<String, dynamic> toJson() => {
    'membre_id': membreId,
    'culte_id': culteId,
    'statut': _statutToString(statut),
    'montant_obligatoire': montantObligatoire,
    'montant_paye': montantPaye,
    'montant_don': montantDon,
    if (datePaiement != null) 'date_paiement': datePaiement!.toIso8601String(),
    if (notes != null) 'notes': notes,
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'version': version,
    'device_id': deviceId,
    'is_deleted': isDeleted,
    if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    if (deletedBy != null) 'deleted_by': deletedBy,
  };

  static Cotisation fromJson(Map<String, dynamic> json) {
    return Cotisation()
      ..id = json['id'] as String
      ..membreId = json['membre_id'] as String
      ..culteId = json['culte_id'] as String
      ..statut = _stringToStatut(json['statut'] as String)
      ..montantObligatoire = (json['montant_obligatoire'] as num?)?.toDouble() ?? 50.0
      ..montantPaye = (json['montant_paye'] as num?)?.toDouble() ?? 0.0
      ..montantDon = (json['montant_don'] as num?)?.toDouble() ?? 0.0
      ..datePaiement = json['date_paiement'] == null
          ? null
          : DateTime.parse(json['date_paiement'] as String)
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

  Cotisation copyWith({
    String? id,
    String? membreId,
    String? culteId,
    StatutCotisation? statut,
    double? montantObligatoire,
    double? montantPaye,
    double? montantDon,
    DateTime? datePaiement,
    String? notes,
    DateTime? updatedAt,
    int? version,
  }) {
    return Cotisation()
      ..id = id ?? this.id
      ..membreId = membreId ?? this.membreId
      ..culteId = culteId ?? this.culteId
      ..statut = statut ?? this.statut
      ..montantObligatoire = montantObligatoire ?? this.montantObligatoire
      ..montantPaye = montantPaye ?? this.montantPaye
      ..montantDon = montantDon ?? this.montantDon
      ..datePaiement = datePaiement ?? this.datePaiement
      ..notes = notes ?? this.notes
      ..updatedAt = updatedAt ?? this.updatedAt
      ..createdAt = this.createdAt
      ..version = version ?? this.version + 1
      ..deviceId = this.deviceId
      ..isDeleted = this.isDeleted;
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
