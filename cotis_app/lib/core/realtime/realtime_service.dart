import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../insforge/insforge_config.dart';
import 'realtime_models.dart';

/// Type de callback pour les événements temps réel.
typedef RealtimeEventHandler = void Function(RealtimeEvent event);

/// Type de callback pour les changements de présence.
typedef PresenceChangeHandler = void Function(DevicePresence presence);

/// Service de synchronisation en temps réel via Socket.IO.
///
/// Fonctionnalités :
/// - Connexion avec token JWT authentifié (canal privé par utilisateur)
/// - Événements ciblés (create/update/delete) par table
/// - Patchs locaux au lieu de reload complet
/// - Suivi de présence des appareils connectés
/// - Reconnexion automatique avec exponential backoff
/// - deviceId persisté dans SharedPreferences
class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  IO.Socket? _socket;
  final List<RealtimeEventHandler> _eventHandlers = [];
  final List<PresenceChangeHandler> _presenceHandlers = [];
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const _reconnectDelayMs = 1000;
  static const _heartbeatIntervalMs = 30000;
  static const _deviceIdKey = 'kased_realtime_device_id';

  /// ID de l'appareil actuel (persisté)
  String? _deviceId;
  String? _currentUserEmail;
  String? _currentToken;

  bool get isConnected => _isConnected;
  String? get deviceId => _deviceId;
  String? get currentUserEmail => _currentUserEmail;
  String? get currentToken => _currentToken;

  /// Charge ou génère un deviceId persisté.
  Future<String> _getOrLoadDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    try {
      final prefs = await SharedPreferences.getInstance();
      _deviceId = prefs.getString(_deviceIdKey);
      if (_deviceId == null) {
        _deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString(_deviceIdKey, _deviceId!);
      }
    } catch (e) {
      debugPrint('[Realtime] Failed to load device ID: $e');
      _deviceId = 'device-fallback-${DateTime.now().microsecond}';
    }
    return _deviceId!;
  }

  /// Connecte le socket avec l'authentification utilisateur.
  ///
  /// [token] : token JWT de l'utilisateur connecté (null = mode anon).
  /// [email] : email de l'utilisateur (pour la présence).
  /// Note : le deviceId est chargé/persisté automatiquement.
  Future<void> connect({
    String? token,
    String? email,
  }) async {
    if (_socket != null) {
      await disconnect();
    }

    _currentToken = token;
    _currentUserEmail = email;

    final deviceId = await _getOrLoadDeviceId();
    final useToken = token ?? InsForgeConfig.effectiveAnonKey;

    final opts = IO.OptionBuilder()
        .setTransports(['websocket'])
        .setQuery({
          'token': useToken,
          'deviceId': deviceId,
          'platform': kIsWeb ? 'web' : 'mobile',
        })
        .setAuth({'token': useToken})
        .setExtraHeaders({
          'deviceId': deviceId,
          'email': email ?? '',
        })
        .build();

    _socket = IO.io(InsForgeConfig.baseUrl, opts);

    _socket!.onConnect((_) {
      debugPrint('[Realtime] Connecté à ${InsForgeConfig.baseUrl}');
      _isConnected = true;
      _reconnectAttempts = 0;
      // Souscrire aux canaux publics et privés
      _socket!.emit('realtime:subscribe', {'channel': 'kased:all'});
      _socket!.emit('realtime:subscribe', {'channel': 'kased:private'});
      _socket!.emit('realtime:subscribe', {'channel': 'kased:membres'});
      _socket!.emit('realtime:subscribe', {'channel': 'kased:cultes'});
      _socket!.emit('realtime:subscribe', {'channel': 'kased:cotisations'});
      _startHeartbeat();
    });

    _socket!.onDisconnect((_) {
      debugPrint('[Realtime] Déconnecté');
      _isConnected = false;
    });

    _socket!.onError((data) {
      debugPrint('[Realtime] Error: $data');
    });

    // Événement générique de changement de données
    _socket!.on('data_changed', (data) {
      debugPrint('[Realtime] data_changed: $data');
      _handleDataEvent(data);
    });

    // Événements spécifiques par table
    _socket!.on('kased:membres:changed', (data) {
      debugPrint('[Realtime] membres:changed: $data');
      _handleDataEvent(data);
    });
    _socket!.on('kased:membres:deleted', (data) {
      debugPrint('[Realtime] membres:deleted: $data');
      _handleDataEvent(data);
    });
    _socket!.on('kased:cultes:changed', (data) {
      debugPrint('[Realtime] cultes:changed: $data');
      _handleDataEvent(data);
    });
    _socket!.on('kased:cultes:deleted', (data) {
      debugPrint('[Realtime] cultes:deleted: $data');
      _handleDataEvent(data);
    });
    _socket!.on('kased:cotisations:changed', (data) {
      debugPrint('[Realtime] cotisations:changed: $data');
      _handleDataEvent(data);
    });
    _socket!.on('kased:cotisations:deleted', (data) {
      debugPrint('[Realtime] cotisations:deleted: $data');
      _handleDataEvent(data);
    });

    // Événement de présence
    _socket!.on('presence:update', (data) {
      debugPrint('[Realtime] presence:update: $data');
      _handlePresenceUpdate(data);
    });

    // Reconnexion automatique
    _socket!.onReconnectAttempt((attempt) {
      _reconnectAttempts = attempt;
      final delay = _reconnectDelayMs * (1 << attempt.clamp(0, 5));
      debugPrint(
          '[Realtime] Reconnexion tentative $_reconnectAttempts dans ${delay}ms');
    });

    _socket!.onReconnect((_) {
      debugPrint('[Realtime] Reconnecté après $_reconnectAttempts tentatives');
      _isConnected = true;
      _reconnectAttempts = 0;
      _socket!.emit('realtime:subscribe', {'channel': 'kased:all'});
      _socket!.emit('realtime:subscribe', {'channel': 'kased:private'});
      _socket!.emit('realtime:subscribe', {'channel': 'kased:membres'});
      _socket!.emit('realtime:subscribe', {'channel': 'kased:cultes'});
      _socket!.emit('realtime:subscribe', {'channel': 'kased:cotisations'});
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

  /// Envoie un heartbeat pour maintenir la présence active.
  void _startHeartbeat() {
    Timer.periodic(const Duration(milliseconds: _heartbeatIntervalMs), (_) {
      if (_isConnected && _socket != null) {
        _socket!.emit('heartbeat', {
          'deviceId': _deviceId,
          'email': _currentUserEmail,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  /// Parse un événement de données et notifie les écouteurs.
  void _handleDataEvent(dynamic rawData) {
    Map<String, dynamic> data;
    if (rawData is Map) {
      data = Map<String, dynamic>.from(rawData);
    } else if (rawData is String) {
      try {
        data = jsonDecode(rawData) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('[Realtime] Erreur parsing event: $e');
        return;
      }
    } else {
      return;
    }

    final event = RealtimeEvent.fromJson(data);
    debugPrint(
        '[Realtime] Event: ${event.action} sur ${event.table} (id: ${event.id})');

    // Notifier tous les écouteurs
    for (final handler in _eventHandlers) {
      handler(event);
    }
  }

  /// Parse un événement de présence.
  void _handlePresenceUpdate(dynamic data) {
    if (data is! Map) return;

    final presence = DevicePresence(
      deviceId: data['deviceId'] as String? ?? '',
      userEmail: data['email'] as String? ?? '',
      connectedAt: DateTime.tryParse(data['connectedAt'] as String? ?? '') ??
          DateTime.now(),
      lastActivity: DateTime.tryParse(data['lastActivity'] as String? ?? '') ??
          DateTime.now(),
      platform: data['platform'] as String? ?? 'unknown',
    );

    for (final handler in _presenceHandlers) {
      handler(presence);
    }
  }

  // ── Listeners ─────────────────────────────────────────────────────────────

  /// Ajoute un écouteur d'événements temps réel.
  void addListener(RealtimeEventHandler listener) {
    if (!_eventHandlers.contains(listener)) {
      _eventHandlers.add(listener);
    }
  }

  /// Supprime un écouteur d'événements temps réel.
  void removeListener(RealtimeEventHandler listener) {
    _eventHandlers.remove(listener);
  }

  /// Ajoute un écouteur de changements de présence.
  void addPresenceListener(PresenceChangeHandler listener) {
    if (!_presenceHandlers.contains(listener)) {
      _presenceHandlers.add(listener);
    }
  }

  /// Supprime un écouteur de présence.
  void removePresenceListener(PresenceChangeHandler listener) {
    _presenceHandlers.remove(listener);
  }
}
