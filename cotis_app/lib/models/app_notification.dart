import 'package:isar/isar.dart';

part 'app_notification.g.dart';

@collection
class AppNotification {
  Id isarId = Isar.autoIncrement;

  late String id;
  late String titre;
  late String message;
  late DateTime date;
  bool isLue = false;
  String? typeEvenement; // 'paiement', 'culte', 'membre'
  String? entiteId; // UUID liée à l'événement
}
