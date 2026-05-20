import 'package:isar/isar.dart';

part 'corbeille_item.g.dart';

@collection
class CorbeilleItem {
  Id isarId = Isar.autoIncrement;

  late String entityId; // UUID de l'entité supprimée
  late String entityType; // 'culte', 'membre'
  late String payloadJson; // Données JSON complètes de l'entité (permet une restauration parfaite)
  late DateTime deletedAt;
}
