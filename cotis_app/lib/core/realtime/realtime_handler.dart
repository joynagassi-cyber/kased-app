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

/// Callback type pour mise à jour UI immédiate (sans recharger du serveur).
typedef ImmediateUpdateCallback = void Function();

/// Délai minimum entre deux reloads consécutifs (30s).
const _reloadDebounceDelay = Duration(seconds: 30);

/// Gestionnaire d'événements temps réel.
///
/// Reçoit les événements du [RealtimeService] et :
/// 1. Applique un patch local via [RealtimePatchEngine]
/// 2. Déclenche un reload si nécessaire (debounce 30s)
///
/// Le provider est keepAlive car il doit persister pendant toute la durée
/// de l'application.
@Riverpod(keepAlive: true)
class RealtimeHandler extends _$RealtimeHandler {
  late RealtimeService _realtime;
  late RealtimePatchEngine _patchEngine;
  ReloadCallback? _reloadCallback;
  ImmediateUpdateCallback? _immediateUpdateCallback;
  DateTime? _lastReloadAt;
  Timer? _reloadDebounceTimer;

  @override
  bool build() => false;

  RealtimeHandler() {
    _realtime = RealtimeService();
    _realtime.addListener(_handleEvent);
  }

  /// Initialise le patch engine avec le cache.
  void initPatchEngine(LocalCache cache) {
    _patchEngine = RealtimePatchEngine(
      cache: cache,
      onPatchApplied: _onPatchApplied,
      onImmediateUpdate: _immediateUpdateCallback,
    );
  }

  /// Connecte le service realtime avec l'authentification.
  void connectWithAuth({
    required String token,
    required String email,
    ReloadCallback? onReload,
    ImmediateUpdateCallback? onImmediateUpdate,
  }) {
    debugPrint('[RealtimeHandler] Connexion avec auth: $email');
    _reloadCallback = onReload;
    _immediateUpdateCallback = onImmediateUpdate;
    _realtime.connect(token: token, email: email);
  }

  /// Déconnecte le service realtime.
  void disconnect() {
    _reloadCallback = null;
    _immediateUpdateCallback = null;
    _reloadDebounceTimer?.cancel();
    _realtime.disconnect();
  }

  /// Gère un événement temps réel reçu.
  void _handleEvent(RealtimeEvent event) async {
    debugPrint('[RealtimeHandler] Event: ${event.action} ${event.table} ${event.id}');
    _patchEngine.apply(event);
    _scheduleReload();
  }

  /// Programme un reload avec debounce de 30s.
  void _scheduleReload() {
    final now = DateTime.now();
    final timeSinceLastReload = _lastReloadAt == null
        ? _reloadDebounceDelay
        : now.difference(_lastReloadAt!);

    if (timeSinceLastReload >= _reloadDebounceDelay) {
      // Pas de debounce nécessaire, reload immédiat
      _performReload();
    } else {
      // Programmer le reload au bout du délai restant
      final delay = _reloadDebounceDelay - timeSinceLastReload;
      _reloadDebounceTimer?.cancel();
      _reloadDebounceTimer = Timer(delay, _performReload);
    }
  }

  void _performReload() async {
    _lastReloadAt = DateTime.now();
    _reloadCallback?.call();
  }

  /// Notifie qu'un patch a été appliqué (pour mise à jour UI).
  void _onPatchApplied() {
    debugPrint('[RealtimeHandler] Patch appliqué, reload programmé');
  }
}
