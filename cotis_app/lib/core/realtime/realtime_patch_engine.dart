import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/core/realtime/realtime_models.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/cotisation.dart';

/// Callback type for immediate UI state refresh after a patch.
typedef ImmediateUpdateCallback = void Function();

/// Moteur de patch pour les événements temps réel.
///
/// Applique localement chaque événement reçu sans recharger toute la base.
/// Garantit la cohérence locale immédiate tout en attendant la synchro complète.
class RealtimePatchEngine {
  final LocalCache _cache;
  final void Function() _onPatchApplied;
  final ImmediateUpdateCallback? _onImmediateUpdate;

  RealtimePatchEngine({
    required LocalCache cache,
    required void Function() onPatchApplied,
    ImmediateUpdateCallback? onImmediateUpdate,
  })  : _cache = cache,
        _onPatchApplied = onPatchApplied,
        _onImmediateUpdate = onImmediateUpdate;

  /// Applique un événement temps réel localement.
  ///
  /// Le patch n'est appliqué que si l'événement est plus récent que la donnée
  /// locale (timestamp guard), évitant les régressions.
  Future<void> apply(RealtimeEvent event) async {
    debugPrint('[PatchEngine] Applying: ${event.action} ${event.table} ${event.id}');

    // Timestamp guard : ignorer les événements périmés
    final stale = await _isStale(_cache, event);
    if (stale) {
      debugPrint('[PatchEngine] Stale event ignored: ${event.id}');
      return;
    }

    try {
      switch (event.table) {
        case 'membres':
          await _applyMember(event);
          break;
        case 'cultes':
          await _applyCulte(event);
          break;
        case 'cotisations':
          await _applyCotisation(event);
          break;
        default:
          debugPrint('[PatchEngine] Unknown table: ${event.table}');
      }
      _onImmediateUpdate?.call();
      _onPatchApplied();
    } catch (e, stack) {
      debugPrint('[PatchEngine] Error applying patch: $e\n$stack');
    }
  }

  /// Vérifie si l'événement est plus ancien que la donnée locale.
  /// Retourne true si l'événement DOIT être ignoré (stale).
  static Future<bool> _isStale(LocalCache cache, RealtimeEvent event) async {
    // Si l'entité n'existe pas localement, l'événement n'est pas stale
    bool existsLocally = false;
    switch (event.table) {
      case 'membres':
        final membres = await cache.getAllMembres();
        existsLocally = membres.any((m) => m.id == event.id);
        break;
      case 'cultes':
        final cultes = await cache.getAllCultes();
        existsLocally = cultes.any((c) => c.id == event.id);
        break;
      case 'cotisations':
        final cotisations = await cache.getAllCotisations();
        existsLocally = cotisations.any((c) => c.id == event.id);
        break;
      default:
        return false;
    }

    // Nouvelle entité → pas stale
    if (!existsLocally) return false;

    // Pas de timestamp dans l'événement → on applique (pas de moyen de vérifier)
    final eventData = event.data;
    if (eventData == null) return false;

    final String? eventUpdatedAt = eventData['updated_at'] as String? ??
        eventData['updatedAt'] as String?;
    if (eventUpdatedAt == null) return false;

    final DateTime eventTime = DateTime.tryParse(eventUpdatedAt) ?? DateTime.now();

    switch (event.table) {
      case 'membres':
        final membres = await cache.getAllMembres();
        final local = membres.firstWhere(
          (m) => m.id == event.id,
          orElse: () => Membre()..updatedAt = DateTime.utc(1970, 1, 1),
        );
        final localTime = local.updatedAt ?? DateTime.utc(1970, 1, 1);
        return eventTime.isBefore(localTime);
      case 'cultes':
        final cultes = await cache.getAllCultes();
        final local = cultes.firstWhere(
          (c) => c.id == event.id,
          orElse: () => Culte()..updatedAt = DateTime.utc(1970, 1, 1),
        );
        final localTime = local.updatedAt ?? DateTime.utc(1970, 1, 1);
        return eventTime.isBefore(localTime);
      case 'cotisations':
        final cotisations = await cache.getAllCotisations();
        final local = cotisations.firstWhere(
          (c) => c.id == event.id,
          orElse: () => Cotisation()..updatedAt = DateTime.utc(1970, 1, 1),
        );
        final localTime = local.updatedAt ?? DateTime.utc(1970, 1, 1);
        return eventTime.isBefore(localTime);
      default:
        return false;
    }
  }

  Future<void> _applyMember(RealtimeEvent event) async {
    final data = event.data;
    switch (event.action) {
      case 'create':
      case 'update':
        if (data == null) return;
        final membre = Membre.fromJson(data);
        await _cache.saveMembre(membre);
        break;
      case 'delete':
        if (event.id.isEmpty) return;
        await _cache.deleteMembreById(event.id);
        break;
      default:
        debugPrint('[PatchEngine] Unknown member action: ${event.action}');
    }
  }

  Future<void> _applyCulte(RealtimeEvent event) async {
    final data = event.data;
    switch (event.action) {
      case 'create':
      case 'update':
        if (data == null) return;
        final culte = Culte.fromJson(data);
        await _cache.saveCulte(culte);
        break;
      case 'delete':
        if (event.id.isEmpty) return;
        await _cache.deleteCulteById(event.id);
        break;
      default:
        debugPrint('[PatchEngine] Unknown culte action: ${event.action}');
    }
  }

  Future<void> _applyCotisation(RealtimeEvent event) async {
    final data = event.data;
    switch (event.action) {
      case 'create':
      case 'update':
        if (data == null) return;
        final cotisation = Cotisation.fromJson(data);
        await _cache.saveCotisation(cotisation);
        break;
      case 'delete':
        // Pas de delete direct pour les cotisations, ignorer
        break;
      default:
        debugPrint('[PatchEngine] Unknown cotisation action: ${event.action}');
    }
  }
}
