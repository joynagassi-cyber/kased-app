import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kased_app/core/realtime/realtime_models.dart';
import 'package:kased_app/core/realtime/realtime_service.dart';
import 'package:kased_app/store/kased_action.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'realtime_handler.g.dart';

/// Callback type pour notifier le caller qu'un reload est nécessaire.
typedef ReloadCallback = Future<void> Function();

/// Gestionnaire d'événements temps réel.
///
/// Reçoit les événements du [RealtimeService] et déclenche un reload
/// via un callback configuré au moment de la connexion.
///
/// Le provider est keepAlive car il doit persister pendant toute la durée
/// de l'application.
@Riverpod(keepAlive: true)
class RealtimeHandler extends _$RealtimeHandler {
  late RealtimeService _realtime;
  ReloadCallback? _reloadCallback;

  @override
  bool build() {
    _realtime = RealtimeService();
    _realtime.addListener(_handleEvent);
    return false;
  }

  /// Connecte le service realtime avec l'authentification et un callback de reload.
  void connectWithAuth({
    required String token,
    String? deviceId,
    required String email,
    ReloadCallback? onReload,
  }) {
    debugPrint('[Realtime] Connexion avec auth: $email');
    _reloadCallback = onReload;
    _realtime.connect(
      token: token,
      deviceId: deviceId,
      email: email,
    );
  }

  /// Déconnecte le service realtime.
  void disconnect() {
    _reloadCallback = null;
    _realtime.disconnect();
  }

  /// Gère un événement temps réel reçu.
  void _handleEvent(RealtimeEvent event) {
    debugPrint('[RealtimeHandler] Event: ${event.action} ${event.table} ${event.id}');

    switch (event.table) {
      case 'membres':
        _syncAndReload();
        break;
      case 'cultes':
        _syncAndReload();
        break;
      case 'cotisations':
        _syncAndReload();
        break;
      default:
        debugPrint('[RealtimeHandler] Table inconnue, reload complet: ${event.table}');
        _syncAndReload();
    }
  }

  /// Notifie le caller qu'un rechargement est nécessaire.
  void _notifyReload() {
    debugPrint('[Realtime] Notifying reload...');
    _reloadCallback?.call();
  }

  /// Recharge les données (appelé pour tous les événements).
  Future<void> _syncAndReload() async {
    debugPrint('[Realtime] Sync et reload demandé');
    _notifyReload();
  }
}
