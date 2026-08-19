import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:kased_app/core/services/sync_service.dart';
import 'package:kased_app/core/services/notification_coordinator.dart';
import 'package:kased_app/core/utils/uuid.dart';
import 'package:kased_app/core/sync/device_service_port.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/sync_operation.dart';
import 'package:kased_app/models/corbeille_item.dart';
import 'package:kased_app/providers/app_data_provider.dart';

/// Exception lancee quand un culte est introuvable.
class CulteNotFoundException implements Exception {
  final String culteId;
  CulteNotFoundException(this.culteId);
  @override
  String toString() => "Culte introuvable: $culteId";
}

/// Exception lancee quand on tente de modifier un culte verrouille.
class CulteLockedException implements Exception {
  final String culteId;
  CulteLockedException(this.culteId);
  @override
  String toString() => "Culte verrouille (plus de 30 jours): $culteId";
}

/// Controleur dedie au cycle de vie des cultes.
///
/// Responsabilites :
/// - Creation de cultes (avec generation automatique des cotisations)
/// - Mise a jour de cultes (avec garde de verrouillage 30 jours)
/// - Suppression soft de cultes (deplacement vers la corbeille)
class CulteController {
  final LocalCache _cache;
  final InsForgeService _api;
  final SyncService _syncService;
  final DeviceServicePort _deviceService;
  final void Function(AppState) onStateChanged;

  CulteController({
    required LocalCache cache,
    required InsForgeService api,
    required SyncService syncService,
    required DeviceServicePort deviceService,
    required this.onStateChanged,
  })  : _cache = cache,
        _api = api,
        _syncService = syncService,
        _deviceService = deviceService;

  /// Cree un nouveau culte et genere automatiquement des cotisations
  /// non payees pour tous les membres actifs.
  Future<Culte> addCulte({
    required DateTime date,
    String? titre,
    required double montant,
  }) async {
    final culteId = UuidUtils.generate();
    final deviceId = await _deviceService.getDeviceId();
    final now = DateTime.now();
    final newCulte = Culte()
      ..id = culteId
      ..dateCulte = date
      ..titre = titre
      ..montantCotisation = montant
      ..deviceId = deviceId
      ..createdAt = now
      ..updatedAt = now;

    final membres = await _cache.getAllMembres();
    final activeMembres = membres.where((m) => m.isActive).toList();
    newCulte.memberIds = activeMembres.map((m) => m.id).toList();
    final localCotisations = activeMembres.map((m) {
      return Cotisation()
        ..id = UuidUtils.generate()
        ..culteId = culteId
        ..membreId = m.id
        ..montantObligatoire = montant
        ..montantPaye = 0.0
        ..montantDon = 0.0
        ..statut = StatutCotisation.nonPaye
        ..deviceId = deviceId
        ..createdAt = now;
    }).toList();

    final syncOp = SyncOperation()
      ..operationId = UuidUtils.generate()
      ..type = 'CREATE'
      ..entityType = 'culte'
      ..entityId = culteId
      ..payloadJson = jsonEncode(newCulte.toJson())
      ..createdAt = now
      ..deviceId = deviceId;

    // 1. Sauvegarde locale atomique
    await _cache.saveCulteWithCotisations(newCulte, localCotisations);
    await _cache.saveSyncOp(syncOp);
    for (final c in localCotisations) {
      final cotSyncOp = SyncOperation()
        ..operationId = UuidUtils.generate()
        ..type = 'CREATE'
        ..entityType = 'cotisation'
        ..entityId = c.id
        ..payloadJson = jsonEncode(c.toJson())
        ..createdAt = now
        ..deviceId = deviceId;
      await _cache.saveSyncOp(cotSyncOp);
    }

    NotificationCoordinator.notifierCreationCulte(newCulte);

    // 2. Reseau
    try {
      await _api.createCulte(newCulte.toJson());
      // Succes reseau : supprimer toutes les operations sync (deja appliquees)
      await _cache.deleteSyncOp(syncOp.isarId);
      // Supprimer aussi les ops des cotisations creees
      for (final c in localCotisations) {
        final pendingOps = await _cache.getPendingSyncOps();
        final cotOp = pendingOps.where((op) => op.entityId == c.id).toList();
        for (final op in cotOp) {
          await _cache.deleteSyncOp(op.isarId);
        }
      }
    } catch (e) {
      debugPrint(
          '[CulteController] addCulte reseau echoue, mise en file deja effectuee: $e');
    }

    return newCulte;
  }

  /// Met a jour un culte existant.
  /// Lance [CulteLockedException] si le culte a plus de 30 jours.
  Future<void> updateCulte({
    required String id,
    DateTime? dateCulte,
    String? titre,
    double? montantCotisation,
    String? notes,
  }) async {
    final cultes = await _cache.getAllCultes();
    final existing = cultes.firstWhere(
      (c) => c.id == id,
      orElse: () => throw CulteNotFoundException(id),
    );

    // Verrouillage a 30 jours : interdit de modifier un culte passe
    final isOlderThan30Days =
        DateTime.now().difference(existing.dateCulte).inDays > 30;
    if (isOlderThan30Days) {
      throw CulteLockedException(id);
    }

    final updated = Culte()
      ..id = existing.id
      ..dateCulte = dateCulte ?? existing.dateCulte
      ..titre = titre ?? existing.titre
      ..montantCotisation = montantCotisation ?? existing.montantCotisation
      ..notes = notes ?? existing.notes
      ..updatedAt = DateTime.now();

    // Mise a jour optimiste des cotisations liees si le montant a change
    List<Cotisation> updatedCotisations = [];
    if (montantCotisation != null &&
        montantCotisation != existing.montantCotisation) {
      final allCotisations = await _cache.getAllCotisations();
      updatedCotisations = allCotisations.map((c) {
        if (c.culteId == id) {
          return c.copyWith(
            montantObligatoire: montantCotisation,
            montantDon: c.montantPaye >= montantCotisation
                ? c.montantPaye - montantCotisation
                : 0.0,
          );
        }
        return c;
      }).toList();
    }

    // 1. Sauvegarde locale
    final cotisationsToUpdate = (montantCotisation != null &&
            montantCotisation != existing.montantCotisation)
        ? updatedCotisations.where((c) => c.culteId == id).toList()
        : null;
    await _cache.updateCulteAndCotisations(updated, cotisationsToUpdate);

    // 2. Reseau
    try {
      await _api.updateCulte(id, updated.toJson());
      if (montantCotisation != null &&
          montantCotisation != existing.montantCotisation) {
        final toUpdate =
            updatedCotisations.where((c) => c.culteId == id).toList();
        for (final c in toUpdate) {
          await _syncService.queueSyncOperation(
              'UPDATE', 'cotisation', c.id, c.toJson());
        }
      }
    } catch (e) {
      debugPrint('[CulteController] updateCulte reseau echoue: $e');
      await _syncService.queueSyncOperation(
          'UPDATE', 'culte', id, updated.toJson());
      if (montantCotisation != null &&
          montantCotisation != existing.montantCotisation) {
        final toUpdate =
            updatedCotisations.where((c) => c.culteId == id).toList();
        for (final c in toUpdate) {
          await _syncService.queueSyncOperation(
              'UPDATE', 'cotisation', c.id, c.toJson());
        }
      }
    }
  }

  /// Supprime soft un culte (deplacement vers la corbeille).
  /// Lance [CulteLockedException] si le culte a plus de 30 jours.
  Future<void> deleteCulte(String id) async {
    final cultes = await _cache.getAllCultes();
    final existingList = cultes.where((c) => c.id == id);
    if (existingList.isNotEmpty &&
        DateTime.now().difference(existingList.first.dateCulte).inDays > 30) {
      throw CulteLockedException(id);
    }
    final existing = existingList.isNotEmpty
        ? existingList.first
        : cultes.firstWhere((c) => c.id == id, orElse: () => throw CulteNotFoundException(id));

    final deviceId = await _deviceService.getDeviceId();
    final now = DateTime.now();

    // Soft delete
    existing.isDeleted = true;
    existing.deletedAt = now;
    existing.deletedBy = deviceId;
    existing.version++;

    // Soft delete des cotisations liees
    final allCotisations = await _cache.getAllCotisations();
    final cotisations = allCotisations.where((c) => c.culteId == id).toList();
    for (final c in cotisations) {
      c.isDeleted = true;
      c.deletedAt = now;
      c.deletedBy = deviceId;
    }

    final syncOp = SyncOperation()
      ..operationId = UuidUtils.generate()
      ..type = 'DELETE'
      ..entityType = 'culte'
      ..entityId = id
      ..payloadJson = jsonEncode(existing.toJson())
      ..createdAt = now
      ..deviceId = deviceId;

    // Sauvegarder dans la corbeille
    final culteCorbeilleItem = CorbeilleItem()
      ..entityId = id
      ..entityType = 'culte'
      ..payloadJson = jsonEncode(existing.toJson())
      ..deletedAt = now
      ..updatedAt = existing.updatedAt;
    await _cache.saveCorbeilleItem(culteCorbeilleItem);

    await _cache.softDeleteCulteWithSyncOp(existing, cotisations, syncOp);

    // 2. Reseau
    try {
      await _api.deleteCulte(id);
      // Succes reseau : supprimer l'operation sync (deja appliquee)
      await _cache.deleteSyncOp(syncOp.isarId);
    } catch (e) {
      debugPrint('[CulteController] deleteCulte reseau echoue: $e');
      await _syncService.queueSyncOperation('DELETE', 'culte', id, {});
    }
  }
}
