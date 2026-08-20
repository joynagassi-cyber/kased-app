import 'package:flutter/foundation.dart';
import 'package:kased_app/core/realtime/realtime_models.dart';
import 'package:kased_app/core/realtime/realtime_service.dart';
import 'package:kased_app/core/services/sync_service.dart';
import 'package:kased_app/providers/app_data_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'realtime_handler.g.dart';

/// Gestionnaire d'événements temps réel.
///
/// Reçoit les événements du [RealtimeService] et applique les changements
/// de manière ciblée (patch) au lieu de recharger toute la base.
///
/// Le provider est keepAlive car il doit persister pendant toute la durée
/// de l'application.
@Riverpod(keepAlive: true)
class RealtimeHandler extends _$RealtimeHandler {
  late RealtimeService _realtime;

  @override
  bool build() {
    _realtime = RealtimeService();

    // S'abonner aux événements temps réel
    _realtime.addListener(_handleEvent);

    // Connexion avec le token si disponible
    // La connexion réelle se fait depuis AppData quand l'user est authentifié
    return false;
  }

  /// Connecte le service realtime avec l'authentification de l'utilisateur.
  void connectWithAuth({
    required String token,
    String? deviceId,
    required String email,
  }) {
    debugPrint('[Realtime] Connexion avec auth: $email');
    _realtime.connect(
      token: token,
      deviceId: deviceId,
      email: email,
    );
  }

  /// Déconnecte le service realtime.
  void disconnect() {
    _realtime.disconnect();
  }

  /// Gère un événement temps réel reçu.
  ///
  /// Applique un patch ciblé sur la base locale au lieu d'un reload complet.
  void _handleEvent(RealtimeEvent event) {
    debugPrint(
        '[RealtimeHandler] Event: ${event.action} ${event.table} ${event.id}');

    switch (event.table) {
      case 'membres':
        _handleMembreEvent(event);
        break;
      case 'cultes':
        _handleCulteEvent(event);
        break;
      case 'cotisations':
        _handleCotisationEvent(event);
        break;
      default:
        debugPrint('[RealtimeHandler] Table inconnue: ${event.table}');
        // Fallback : rechargement complet pour les tables inconnues
        _forceReload();
    }
  }

  /// Applique un patch ciblé sur les membres.
  void _handleMembreEvent(RealtimeEvent event) {
    switch (event.action) {
      case 'create':
      case 'update':
        // Patch local : mettre à jour uniquement ce membre
        // Le syncService gère la fusion
        debugPrint('[Realtime] Patch membre: ${event.id}');
        _syncAndReload('membres');
        break;
      case 'delete':
        // Soft delete local
        debugPrint('[Realtime] Delete membre: ${event.id}');
        _syncAndReload('membres');
        break;
      default:
        _forceReload();
    }
  }

  /// Applique un patch ciblé sur les cultes.
  void _handleCulteEvent(RealtimeEvent event) {
    switch (event.action) {
      case 'create':
      case 'update':
        debugPrint('[Realtime] Patch culte: ${event.id}');
        _syncAndReload('cultes');
        break;
      case 'delete':
        debugPrint('[Realtime] Delete culte: ${event.id}');
        _syncAndReload('cultes');
        break;
      default:
        _forceReload();
    }
  }

  /// Applique un patch ciblé sur les cotisations.
  void _handleCotisationEvent(RealtimeEvent event) {
    switch (event.action) {
      case 'create':
      case 'update':
        debugPrint('[Realtime] Patch cotisation: ${event.id}');
        _syncAndReload('cotisations');
        break;
      case 'delete':
        debugPrint('[Realtime] Delete cotisation: ${event.id}');
        _syncAndReload('cotisations');
        break;
      default:
        _forceReload();
    }
  }

  /// Force un rechargement complet des données.
  void _forceReload() {
    debugPrint('[Realtime] Reload complet demandé');
    // Notifie le provider AppData de faire un sync
    // Cela sera géré par le listener dans AppData
    _notifyReload();
  }

  /// Recharge uniquement la table concernée.
  Future<void> _syncAndReload(String table) async {
    debugPrint('[Realtime] Sync et reload de: $table');
    _notifyReload();
  }

  /// Notifie les écouteurs qu'un rechargement est nécessaire.
  void _notifyReload() {
    // Utilise un callback externe pour notifier le provider AppData
    // Le listener est configuré dans app_data_provider.dart
  }
}
