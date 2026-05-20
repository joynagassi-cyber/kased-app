import 'package:isar/isar.dart';

part 'sync_operation.g.dart';

@collection
class SyncOperation {
  Id isarId = Isar.autoIncrement;

  late String type; // 'CREATE', 'UPDATE', 'DELETE'
  late String entityType; // 'membre', 'culte', 'cotisation'
  late String entityId; // UUID de l'entité concernée
  late String payloadJson; // JSON contenant les données de l'opération
  late DateTime createdAt;
  DateTime? updatedAt; // Timestamp pour résolution de conflits (dernière modif client)
}
