/// Service de synchronisation en temps réel via Socket.IO.
///
/// Écoute les événements de la base InsForge (membres, cultes, cotisations)
/// et notifie le provider [AppData] pour recharger les données.
///
/// Canal principal : `kased:all` (tous les événements)
/// Canaux spécifiques : `kased:membres`, `kased:cultes`, `kased:cotisations`
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../insforge/insforge_config.dart';

/// Service WebSocket pour la synchro temps réel InsForge → Flutter.
///
/// Utilise le protocole Socket.IO natif d'InsForge avec authentification
/// via token JWT (utilisateur connecté) ou clé anon (hors connexion).
class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  IO.Socket? _socket;
  final List<VoidCallback> _listeners = [];
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 10;

  bool get isConnected => _isConnected;

  /// Connecte le socket et s'abonne au canal `kased:all`.
  Future<void> connect({String? token}) async {
    if (_socket != null) {
      await disconnect();
    }

    final opts = IO.OptionBuilder()
        .setTransports(['websocket'])
        .setQuery({'token': token ?? InsForgeConfig.effectiveAnonKey})
        .setAuth({'token': token ?? InsForgeConfig.effectiveAnonKey})
        .build();

    _socket = IO.io(InsForgeConfig.baseUrl, opts);

    _socket!.onConnect((_) {
      debugPrint('[Realtime] Connecté à ${InsForgeConfig.baseUrl}');
      _isConnected = true;
      _reconnectAttempts = 0;
      _socket!.emit('realtime:subscribe', {'channel': 'kased:all'});
    });

    _socket!.onDisconnect((_) {
      debugPrint('[Realtime] Déconnecté');
      _isConnected = false;
    });

    _socket!.onError((data) {
      debugPrint('[Realtime] Error: $data');
    });

    // Écouter les événements de donnée
    _socket!.on('data_changed', (data) {
      debugPrint('[Realtime] data_changed: $data');
      _notifyListeners();
    });

    // Canaux spécifiques par table
    _socket!.on('kased:membres:changed', (_) => _notifyListeners());
    _socket!.on('kased:membres:deleted', (_) => _notifyListeners());
    _socket!.on('kased:cultes:changed', (_) => _notifyListeners());
    _socket!.on('kased:cultes:deleted', (_) => _notifyListeners());
    _socket!.on('kased:cotisations:changed', (_) => _notifyListeners());
    _socket!.on('kased:cotisations:deleted', (_) => _notifyListeners());

    // Reconnexion automatique
    _socket!.onReconnectAttempt((attempt) {
      _reconnectAttempts = attempt;
      debugPrint(
          '[Realtime] Reconnexion tentative $_reconnectAttempts/$_maxReconnectAttempts');
    });

    _socket!.onReconnect((_) {
      debugPrint('[Realtime] Reconnecté après $_reconnectAttempts tentatives');
      _isConnected = true;
      _reconnectAttempts = 0;
      _socket!.emit('realtime:subscribe', {'channel': 'kased:all'});
    });

    _socket!.onReconnectError((data) {
      debugPrint('[Realtime] Erreur reconnexion: $data');
      _isConnected = false;
    });

    _socket!.connect();
  }

  /// Déconnecte le socket.
  Future<void> disconnect() async {
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _reconnectAttempts = 0;
    debugPrint('[Realtime] Déconnecté (manuel)');
  }

  /// Ajoute un écouteur appelé à chaque événement reçu.
  void addListener(VoidCallback listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  /// Supprime un écouteur.
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
}
