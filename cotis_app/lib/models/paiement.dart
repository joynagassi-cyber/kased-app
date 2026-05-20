import 'package:isar/isar.dart';

part 'paiement.g.dart';

@collection
class Paiement {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id; // UUID from InsForge

  @Index()
  late String membreId; // UUID of the member

  @Index()
  late String culteId; // UUID of the culte

  late DateTime datePaiement;
  double montant = 50.0;

  @Index(composite: [CompositeIndex('culteId')], unique: true)
  String get uniqueKey => '${membreId}_$culteId';

  // Helper for JSON (InsForge)
  Map<String, dynamic> toJson() => {
    'membre_id': membreId,
    'culte_id': culteId,
    'date_paiement': datePaiement.toIso8601String(),
    'montant': montant,
  };

  static Paiement fromJson(Map<String, dynamic> json) {
    return Paiement()
      ..id = json['id'] as String
      ..membreId = json['membre_id'] as String
      ..culteId = json['culte_id'] as String
      ..datePaiement = DateTime.parse(json['date_paiement'] as String)
      ..montant = (json['montant'] as num?)?.toDouble() ?? 50.0;
  }
}
