import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kased_app/models/app_notification.dart';

class NotificationsState {
  final List<AppNotification> liste;
  const NotificationsState({this.liste = const []});

  int get nbNonLues => liste.where((n) => !n.isLue).length;
}

class NotificationsNotifier extends Notifier<NotificationsState> {
  @override
  NotificationsState build() => const NotificationsState();

  void ajouter({
    required String titre,
    required String message,
    required String typeEvenement,
    String? entiteId,
  }) {
    final notif = AppNotification()
      ..id = DateTime.now().millisecondsSinceEpoch.toString()
      ..titre = titre
      ..message = message
      ..date = DateTime.now()
      ..isLue = false
      ..typeEvenement = typeEvenement
      ..entiteId = entiteId;

    state = NotificationsState(liste: [notif, ...state.liste]);
  }

  void marquerLue(int index) {
    final list = [...state.liste];
    if (index < list.length) {
      list[index] = list[index]..isLue = true;
      state = NotificationsState(liste: list);
    }
  }

  void marquerToutesLues() {
    state = NotificationsState(
      liste: state.liste.map((n) => n..isLue = true).toList(),
    );
  }

  void supprimer(int index) {
    final list = [...state.liste];
    if (index < list.length) {
      list.removeAt(index);
      state = NotificationsState(liste: list);
    }
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(
  NotificationsNotifier.new,
);
