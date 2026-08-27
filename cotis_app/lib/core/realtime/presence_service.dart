import 'package:flutter/foundation.dart';
import 'package:kased_app/core/realtime/realtime_models.dart';
import 'package:kased_app/core/realtime/realtime_service.dart';

/// Service de gestion de la présence des utilisateurs.
///
/// Suit les appareils connectés et leur statut (en ligne / hors ligne).
class PresenceService {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final Map<String, DevicePresence> _devices = {};
  final List<PresenceChangeHandler> _listeners = [];

  Map<String, DevicePresence> get devices => Map.unmodifiable(_devices);
  int get onlineCount =>
      _devices.values.where((d) => d.isOnline).length;
  int get totalUsers => _devices.values.map((d) => d.userEmail).toSet().length;

  bool get hasAnyUser => _devices.isNotEmpty;

  /// Initialise le service et s'abonne aux événements de présence.
  void init() {
    RealtimeService().addPresenceListener(_onPresenceUpdate);
  }

  /// Met à jour la présence d'un appareil.
  void _onPresenceUpdate(DevicePresence presence) {
    debugPrint(
        '[Presence] Update: ${presence.userEmail} sur ${presence.deviceId} (${presence.platform})');
    _devices[presence.deviceId] = presence;

    // Notifier les écouteurs
    for (final listener in _listeners) {
      listener(presence);
    }
  }

  /// Marque un appareil comme hors ligne (après timeout).
  void markOffline(String deviceId) {
    final presence = _devices[deviceId];
    if (presence != null) {
      final offline = presence.copyWith(
        lastActivity: DateTime.now().subtract(const Duration(minutes: 2)),
      );
      _devices[deviceId] = offline;
      for (final listener in _listeners) {
        listener(offline);
      }
    }
  }

  /// Ajoute un écouteur de changements de présence.
  void addListener(PresenceChangeHandler listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  /// Supprime un écouteur.
  void removeListener(PresenceChangeHandler listener) {
    _listeners.remove(listener);
  }

  /// Supprime les appareils hors ligne depuis plus de [timeout].
  void cleanup({Duration timeout = const Duration(minutes: 2)}) {
    final now = DateTime.now();
    _devices.removeWhere((id, presence) {
      final isOffline =
          now.difference(presence.lastActivity) > timeout && !presence.isOnline;
      if (isOffline) {
        debugPrint('[Presence] Cleanup: ${presence.userEmail} (${id})');
      }
      return isOffline;
    });
  }
}
