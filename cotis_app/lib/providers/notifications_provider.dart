import 'dart:async';

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kased_app/models/app_notification.dart';

class NotificationsState {
  final List<AppNotification> liste;
  const NotificationsState({this.liste = const []});

  int get nbNonLues => liste.where((n) => !n.isLue).length;
}

class NotificationsNotifier extends Notifier<NotificationsState> {
  static const _prefsKey = 'kased_notifications_v1';

  @override
  NotificationsState build() => const NotificationsState();

  /// Charge les notifications depuis SharedPreferences.
  Future<void> chargerDepuisPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final list = jsonDecode(jsonString) as List;
        final notifs = list
            .map((e) => AppNotification()
              ..id = e['id'] as String
              ..titre = e['titre'] as String
              ..message = e['message'] as String
              ..date = DateTime.parse(e['date'] as String)
              ..isLue = e['isLue'] as bool? ?? false
              ..typeEvenement = e['typeEvenement'] as String?
              ..entiteId = e['entiteId'] as String?)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        state = NotificationsState(liste: notifs);
      }
    } catch (e) {
      debugPrint('[Notifications] Erreur chargement prefs: $e');
    }
  }

  /// Sauvegarde les notifications dans SharedPreferences.
  Future<void> _sauvegarderPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = state.liste.map((n) => {
        'id': n.id,
        'titre': n.titre,
        'message': n.message,
        'date': n.date.toIso8601String(),
        'isLue': n.isLue,
        'typeEvenement': n.typeEvenement,
        'entiteId': n.entiteId,
      }).toList();
      await prefs.setString(_prefsKey, jsonEncode(list));
    } catch (e) {
      debugPrint('[Notifications] Erreur sauvegarde prefs: $e');
    }
  }

  Future<void> ajouter({
    required String titre,
    required String message,
    required String typeEvenement,
    String? entiteId,
  }) async {
    final notif = AppNotification()
      ..id = DateTime.now().millisecondsSinceEpoch.toString()
      ..titre = titre
      ..message = message
      ..date = DateTime.now()
      ..isLue = false
      ..typeEvenement = typeEvenement
      ..entiteId = entiteId;

    state = NotificationsState(liste: [notif, ...state.liste]);
    await _sauvegarderPrefs();
  }

  void marquerLue(String id) {
    final list = state.liste.map((n) {
      if (n.id == id) return n..isLue = true;
      return n;
    }).toList();
    state = NotificationsState(liste: list);
    unawaited(_sauvegarderPrefs());
  }

  void marquerToutesLues() {
    state = NotificationsState(
      liste: state.liste.map((n) => n..isLue = true).toList(),
    );
    unawaited(_sauvegarderPrefs());
  }

  void supprimer(String id) {
    final list = state.liste.where((n) => n.id != id).toList();
    state = NotificationsState(liste: list);
    unawaited(_sauvegarderPrefs());
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(
  NotificationsNotifier.new,
);
