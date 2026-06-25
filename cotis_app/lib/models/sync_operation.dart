import 'package:isar/isar.dart';

part 'sync_operation.g.dart';

@collection
class SyncOperation {
  Id isarId = Isar.autoIncrement;

  late String operationId;
  late String type; // 'CREATE', 'UPDATE', 'DELETE', 'RESTORE'
  late String entityType; // 'membre', 'culte', 'cotisation'
  late String entityId;
  late String payloadJson;
  late DateTime createdAt;
  DateTime? updatedAt;
  late String deviceId;
  int retryCount = 0;
  bool isSynced = false;
  bool hasFailed = false;
  String? lastError;
}
