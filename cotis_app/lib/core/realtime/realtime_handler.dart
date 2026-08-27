import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/core/realtime/realtime_models.dart';
import 'package:kased_app/core/realtime/realtime_patch_engine.dart';
import 'package:kased_app/core/realtime/realtime_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'realtime_handler.g.dart';

/// Callback type pour notifier le caller qu'un reload est nécessaire.
typedef ReloadCallback = Future<void> Function();

/// Gestionnaire d'événements temps réel.
///
/// Reçoit les événements du [RealtimeService] et :
/// 1. Applique un patch local via [RealtimePatchEngine]
/// 2. Déclenche un reload si nécessaire
///
/// Le provider est keepAlive car il doit persister pendant toute la durée
/// de l'application.
@Riverpod(keepAlive: true)
class RealtimeHandler extends _$RealtimeHandler {
  late RealtimeService _realtime;
  late RealtimePatchEngine _patchEngine;
  ReloadCallback? _reloadCallback;

  @override
  bool build() => false;

  RealtimeHandler() {
    _realtime = RealtimeService();
    _realtime.addListener(_handleEvent);
  }

  /// Initialise le patch engine avec le cache (à appeler après build).
  void initPatchEngine(LocalCache cache) {
    _patchEngine = RealtimePatchEngine(
      cache: cache,
      onPatchApplied: _onPatchApplied,
    );
  }

  /// Connecte le service realtime avec l'authentification.
  void connectWithAuth({
    required String token,
    required String email,
    ReloadCallback? onReload,
  }) {
    debugPrint('[RealtimeHandler] Connexion avec auth: $email');
    _reloadCallback = onReload;
    _realtime.connect(token: token, email: email);
  }

  /// Déconnecte le service realtime.
  void disconnect() {
    _reloadCallback = null;
    _realtime.disconnect();
  }

  /// Gère un événement temps réel reçu.
  void _handleEvent(RealtimeEvent event) async {
    debugPrint('[RealtimeHandler] Event: ${event.action} ${event.table} ${event.id}');
    _patchEngine.apply(event);
    _notifyReload();
  }

  /// Notifie qu'un patch a été appliqué (pour mise à jour UI).
  void _onPatchApplied() {
    debugPrint('[RealtimeHandler] Patch appliqué, reload demandé');
  }

  /// Notifie le caller qu'un rechargement est nécessaire.
  void _notifyReload() {
    _reloadCallback?.call();
  }
}
