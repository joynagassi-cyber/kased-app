import 'package:isar/isar.dart';

part 'corbeille_item.g.dart';

@collection
class CorbeilleItem {
  Id isarId = Isar.autoIncrement;

  @Index()
  late String entityId; // UUID de l'entité supprimée

  @Index()
  late String entityType; // 'culte', 'membre'

  late String payloadJson; // Données JSON complètes de l'entité (permet une restauration parfaite)

  @Index()
  late DateTime deletedAt;

  DateTime? updatedAt; // Dernière modification (extrait du payload)

  DateTime get derniereModification => updatedAt ?? deletedAt;
}
