import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kased_app/core/insforge/insforge_service_port.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/core/services/notification_coordinator.dart';
import 'package:kased_app/core/sync/device_service_port.dart';
import 'package:kased_app/core/utils/uuid.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/sync_operation.dart';
import 'package:kased_app/store/kased_action.dart';

/// Handler dédié aux actions [CulteAction].
class CulteHandler {
  final LocalCache cache;
  final InsForgeServicePort api;
  final DeviceServicePort deviceService;
  final NotificationCoordinator notifCoordinator;
  final Future<void> Function() onLoadDashboard;
  final Future<void> Function(String event, String label, {String? extra}) onPush;

  CulteHandler({
    required this.cache,
    required this.api,
    required this.deviceService,
    required this.notifCoordinator,
    required this.onLoadDashboard,
    required this.onPush,
  });

  Future<void> createCulte(CreateCulte action) async {
    final newCulte = Culte()
      ..id = UuidUtils.generate()
      ..dateCulte = action.date
      ..titre = action.titre
      ..montantCotisation = action.montant
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    final deviceId = await deviceService.getDeviceId();
    final syncOp = SyncOperation()
      ..operationId = UuidUtils.generate()
      ..type = 'CREATE'
      ..entityType = 'culte'
      ..entityId = newCulte.id
      ..payloadJson = jsonEncode(newCulte.toJson())
      ..createdAt = newCulte.createdAt
      ..deviceId = deviceId;

    await cache.saveCulteWithSyncOp(newCulte, syncOp);

    try {
      await api.createCulte(newCulte.toJson());
      await cache.deleteSyncOp(syncOp.isarId);
    } catch (e) {
      debugPrint('[CulteHandler] createCulte réseau échoué: $e');
    }

    notifCoordinator.notifierCreationCulteFull(newCulte);
    await onLoadDashboard();
    unawaited(onPush('culte_cree', _formatDate(newCulte.dateCulte)));
  }

  Future<void> updateCulte(UpdateCulte action) async {
    final existing = (await cache.getAllCultes()).firstWhere(
      (c) => c.id == action.id,
      orElse: () => throw Exception('Culte introuvable: ${action.id}'),
    );

    final isOlderThan30Days =
        DateTime.now().difference(existing.dateCulte).inDays > 30;
    if (isOlderThan30Days) {
      throw Exception('Impossible de modifier un culte dont la date remonte à plus de 30 jours.');
    }

    final updated = Culte()
      ..id = existing.id
      ..dateCulte = action.dateCulte ?? existing.dateCulte
      ..titre = action.titre ?? existing.titre
      ..montantCotisation = action.montantCotisation ?? existing.montantCotisation
      ..notes = action.notes ?? existing.notes
      ..updatedAt = DateTime.now();

    final deviceId = await deviceService.getDeviceId();
    final syncOp = SyncOperation()
      ..operationId = UuidUtils.generate()
      ..type = 'UPDATE'
      ..entityType = 'culte'
      ..entityId = action.id
      ..payloadJson = jsonEncode(updated.toJson())
      ..createdAt = updated.updatedAt!
      ..deviceId = deviceId;

    await cache.saveCulteWithSyncOp(updated, syncOp);

    try {
      await api.updateCulte(action.id, updated.toJson());
      await cache.deleteSyncOp(syncOp.isarId);
    } catch (e) {
      debugPrint('[CulteHandler] updateCulte réseau échoué: $e');
    }

    await onLoadDashboard();
    notifCoordinator.notifierModificationCulteFull(updated);
    unawaited(onPush('culte_modifie', _formatDate(updated.dateCulte)));
  }

  Future<void> deleteCulte(DeleteCulte action) async {
    final culte = (await cache.getAllCultes()).firstWhere(
      (c) => c.id == action.id,
      orElse: () => Culte()..id = action.id,
    );
    if (culte.id.isEmpty) return;

    final deviceId = await deviceService.getDeviceId();
    final now = DateTime.now();

    // Récupérer les cotisations associées
    final cotisations = await cache.getAllCotisations();
    final culteCotisations = cotisations
        .where((c) => c.culteId == culte.id && !c.isDeleted)
        .toList();

    // Soft delete du culte
    final deletedCulte = Culte()
      ..id = culte.id
      ..dateCulte = culte.dateCulte
      ..titre = culte.titre
      ..montantCotisation = culte.montantCotisation
      ..memberIds = culte.memberIds
      ..createdAt = culte.createdAt
      ..updatedAt = now
      ..isDeleted = true
      ..deletedAt = now
      ..deletedBy = deviceId;

    // Créer une SyncOperation par cotisation à supprimer + une pour le culte
    final syncOps = <SyncOperation>[];

    // Sync op pour chaque cotisation
    for (final cotisation in culteCotisations) {
      final deletedCotisation = Cotisation()
        ..id = cotisation.id
        ..culteId = cotisation.culteId
        ..membreId = cotisation.membreId
        ..statut = cotisation.statut
        ..montantObligatoire = cotisation.montantObligatoire
        ..montantPaye = cotisation.montantPaye
        ..datePaiement = cotisation.datePaiement
        ..createdAt = cotisation.createdAt
        ..updatedAt = now
        ..isDeleted = true
        ..deletedAt = now
        ..deletedBy = deviceId;

      final syncOp = SyncOperation()
        ..operationId = UuidUtils.generate()
        ..type = 'DELETE'
        ..entityType = 'cotisation'
        ..entityId = cotisation.id
        ..payloadJson = jsonEncode(deletedCotisation.toJson())
        ..createdAt = now
        ..deviceId = deviceId;
      syncOps.add(syncOp);
    }

    // Sync op pour le culte
    final culteSyncOp = SyncOperation()
      ..operationId = UuidUtils.generate()
      ..type = 'DELETE'
      ..entityType = 'culte'
      ..entityId = culte.id
      ..payloadJson = jsonEncode(deletedCulte.toJson())
      ..createdAt = now
      ..deviceId = deviceId;
    syncOps.add(culteSyncOp);

    // Soft delete du culte + marquer les cotisations comme supprimées + save les sync ops
    await cache.softDeleteCulteWithCotisationsAndSyncOps(deletedCulte, culteCotisations, syncOps);

    // En ligne : supprimer aussi sur le serveur pour éviter un sync ultérieur
    try {
      await api.deleteCulte(culte.id);
      for (final cotisation in culteCotisations) {
        await api.deleteCotisation(cotisation.id);
      }
      // Supprimer les ops sync locales car déjà pushées
      for (final op in syncOps) {
        await cache.deleteSyncOp(op.isarId);
      }
    } catch (e) {
      debugPrint('[CulteHandler] deleteCulte réseau échoué (hors ligne ou erreur): $e');
    }

    unawaited(onPush('culte_supprime', culte.titre ?? culte.id));
  }

  Future<void> restoreCulte(RestoreCulte action) async {
    try {
      await api.createCulte({'id': action.id});
    } catch (e) {
      debugPrint('[CulteHandler] restaurer culte réseau échoué: $e');
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}
