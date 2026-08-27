import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/core/realtime/realtime_models.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/cotisation.dart';

/// Moteur de patch pour les événements temps réel.
///
/// Applique localement chaque événement reçu sans recharger toute la base.
/// Garantit la cohérence locale immédiate tout en attendant la synchro complète.
class RealtimePatchEngine {
  final LocalCache _cache;
  final void Function() _onPatchApplied;

  RealtimePatchEngine({
    required LocalCache cache,
    required void Function() onPatchApplied,
  })  : _cache = cache,
        _onPatchApplied = onPatchApplied;

  /// Applique un événement temps réel localement.
  Future<void> apply(RealtimeEvent event) async {
    debugPrint('[PatchEngine] Applying: ${event.action} ${event.table} ${event.id}');
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
      _onPatchApplied();
    } catch (e, stack) {
      debugPrint('[PatchEngine] Error applying patch: $e\n$stack');
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
        await _cache.deleteMembreById(event.id);
        break;
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
        await _cache.deleteCulteById(event.id);
        break;
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
    }
  }
}
