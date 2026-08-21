// AppNotification is persisted via SharedPreferences in notifications_provider.
// This model is kept for type compatibility but is NOT an Isar collection.

class AppNotification {
  late String id;
  late String titre;
  late String message;
  late DateTime date;
  bool isLue = false;
  String? typeEvenement; // 'paiement', 'culte', 'membre'
  String? entiteId; // UUID liée à l'événement
}
