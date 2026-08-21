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

  /// IDs des membres actifs au moment de la création du culte.
  /// Les membres ajoutés après cette date n'apparaîtront pas dans l'UI du culte.
  /// Liste vide signifie ancien culte (avant cette correction) :
  /// l'UI utilise alors le fallback sur les cotisations.
  @Index()
  List<String> memberIds = [];

  @ignore
  String get dateFormatee => '   ';

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
    'member_ids': memberIds,
  };

  static Culte fromJson(Map<String, dynamic> json) {
    return Culte()
      ..id = json['id'] as String
      ..dateCulte = DateTime.tryParse(json['date_culte'] as String) ?? DateTime.now()
      ..titre = json['titre'] as String?
      ..montantCotisation = (json['montant_cotisation'] as num?)?.toDouble() ?? 50.0
      ..notes = json['notes'] as String?
      ..updatedAt = json['updated_at'] == null
          ? null
          : DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
      ..createdAt = json['created_at'] == null
          ? DateTime.now()
          : DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
      ..version = (json['version'] as num?)?.toInt() ?? 1
      ..deviceId = json['device_id'] as String? ?? ''
      ..isDeleted = json['is_deleted'] as bool? ?? false
      ..deletedAt = json['deleted_at'] == null
          ? null
          : DateTime.tryParse(json['deleted_at'] as String) ?? DateTime.now()
      ..deletedBy = json['deleted_by'] as String?
      ..memberIds = (json['member_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [];
  }
}