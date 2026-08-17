import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:kased_app/core/services/sync_service.dart';
import 'package:kased_app/core/services/notification_coordinator.dart';
import 'package:kased_app/core/utils/uuid.dart';
import 'package:kased_app/core/sync/device_service.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/sync_operation.dart';
import 'package:kased_app/models/corbeille_item.dart';
import 'package:kased_app/providers/app_data_provider.dart';

/// Exception lancée quand un membre est introuvable.
class MembreNotFoundException implements Exception {
  final String membreId;
  MembreNotFoundException(this.membreId);
  @override
  String toString() => "Membre introuvable: $membreId";
}

/// Contrôleur dédié au cycle de vie des membres.
///
/// Responsabilités :
/// - Création, mise à jour, suppression (soft-delete) de membres
/// - Paiements en avance
/// - Génération des cotisations initiales pour les cultes futurs
///
/// Ce contrôleur ne dépend PAS de Riverpod — il reçoit toutes ses
/// dépendances via le constructeur et communique avec AppState
/// via un callback [onStateChanged].
class MembreController {
  final LocalCache _cache;
  final InsForgeService _api;
  final SyncService _syncService;
  final void Function(AppState) onStateChanged;

  MembreController({
    required LocalCache cache,
    required InsForgeService api,
    required SyncService syncService,
    required this.onStateChanged,
  })  : _cache = cache,
        _api = api,
        _syncService = syncService;

  /// Crée un nouveau membre et génère automatiquement des cotisations
  /// pour tous les cultes futurs (postérieurs à la date d'adhésion).
  Future<Membre> addMembre({
    required String nom,
    required String prenom,
    required DateTime dateAdhesion,
    DateTime? dateNaissance,
    String? telephone,
    String? notes,
  }) async {
    final newId = UuidUtils.generate();
    final deviceId = await DeviceService.getDeviceId();
    final now = DateTime.now();

    final newMembre = Membre()
      ..id = newId
      ..nom = nom
      ..prenom = prenom
      ..dateAdhesion = dateAdhesion
      ..dateNaissance = dateNaissance
      ..telephone = telephone
      ..notes = notes
      ..isActive = true
      ..deviceId = deviceId
      ..createdAt = now
      ..updatedAt = now;

    final syncOp = SyncOperation()
      ..operationId = UuidUtils.generate()
      ..type = 'CREATE'
      ..entityType = 'membre'
      ..entityId = newId
      ..payloadJson = jsonEncode(newMembre.toJson())
      ..createdAt = now
      ..deviceId = deviceId;

    // 1. Sauvegarde locale atomique (membre + SyncOp)
    await _cache.saveMembreWithSyncOp(newMembre, syncOp);

    // Notification anniversaire et création
    NotificationCoordinator.planifierAnniversaireMembre(newMembre);
    NotificationCoordinator.notifierCreationMembre(newMembre);

    // 2. Tentative de synchronisation réseau
    try {
      await _api.createMembre(newMembre.toJson());
      // Succès réseau : supprimer l'opération sync (déjà appliquée)
      await _cache.deleteSyncOp(syncOp.isarId);
    } catch (e) {
      debugPrint('[MembreController] addMembre réseau échoué, mise en file: $e');
      await _syncService.queueSyncOperation(
          'CREATE', 'membre', newId, newMembre.toJson());
    }

    return newMembre;
  }

  /// Met à jour partiellement un membre existant.
  Future<void> updateMembre({
    required String id,
    String? nom,
    String? prenom,
    DateTime? dateAdhesion,
    DateTime? dateNaissance,
    String? telephone,
    String? notes,
    bool? isActive,
  }) async {
    final membres = await _cache.getAllMembres();
    final existing = membres.firstWhere(
      (m) => m.id == id,
      orElse: () => throw MembreNotFoundException(id),
    );

    final deviceId = await DeviceService.getDeviceId();
    final now = DateTime.now();
    final updated = Membre()
      ..id = existing.id
      ..nom = nom ?? existing.nom
      ..prenom = prenom ?? existing.prenom
      ..dateAdhesion = dateAdhesion ?? existing.dateAdhesion
      ..dateNaissance = dateNaissance ?? existing.dateNaissance
      ..telephone = telephone ?? existing.telephone
      ..notes = notes ?? existing.notes
      ..isActive = isActive ?? existing.isActive
      ..deviceId = deviceId
      ..createdAt = existing.createdAt
      ..version = existing.version + 1
      ..updatedAt = now;

    final syncOp = SyncOperation()
      ..operationId = UuidUtils.generate()
      ..type = 'UPDATE'
      ..entityType = 'membre'
      ..entityId = id
      ..payloadJson = jsonEncode(updated.toJson())
      ..createdAt = now
      ..deviceId = deviceId;

    // 1. Sauvegarde locale atomique
    await _cache.saveMembreWithSyncOp(updated, syncOp);

    // Notifications anniversaire
    if (updated.dateNaissance != null) {
      NotificationCoordinator.planifierAnniversaireMembre(updated);
    } else {
      NotificationCoordinator.annulerAnniversaireMembre(id);
    }

    // 2. Réseau
    try {
      await _api.updateMembre(id, updated.toJson());
      // Succès réseau : supprimer l'opération sync (déjà appliquée)
      await _cache.deleteSyncOp(syncOp.isarId);
    } catch (e) {
      debugPrint('[MembreController] updateMembre réseau échoué: $e');
      await _syncService.queueSyncOperation(
          'UPDATE', 'membre', id, updated.toJson());
    }
  }

  /// Ajoute un paiement par avance pour un membre.
  /// Le montant est ajouté au solde en avance du membre.
  Future<void> ajouterPaiementAvance({
    required String membreId,
    required double montant,
    String? notes,
  }) async {
    final membres = await _cache.getAllMembres();
    final existing = membres.firstWhere(
      (m) => m.id == membreId,
      orElse: () => throw MembreNotFoundException(membreId),
    );
    final deviceId = await DeviceService.getDeviceId();
    final now = DateTime.now();

    final updated = Membre()
      ..id = existing.id
      ..nom = existing.nom
      ..prenom = existing.prenom
      ..dateAdhesion = existing.dateAdhesion
      ..dateNaissance = existing.dateNaissance
      ..montantEnAvance = existing.montantEnAvance + montant
      ..telephone = existing.telephone
      ..notes = notes ?? existing.notes
      ..isActive = existing.isActive
      ..deviceId = deviceId
      ..createdAt = existing.createdAt
      ..version = existing.version + 1
      ..updatedAt = now;

    final syncOp = SyncOperation()
      ..operationId = UuidUtils.generate()
      ..type = 'UPDATE'
      ..entityType = 'membre'
      ..entityId = membreId
      ..payloadJson = jsonEncode(updated.toJson())
      ..createdAt = now
      ..deviceId = deviceId;

    // 1. Sauvegarde locale atomique
    await _cache.saveMembreWithSyncOp(updated, syncOp);

    // 2. Réseau
    try {
      await _api.updateMembre(membreId, updated.toJson());
      // Succès réseau : supprimer l'opération sync (déjà appliquée)
      await _cache.deleteSyncOp(syncOp.isarId);
    } catch (e) {
      debugPrint('[MembreController] ajouterPaiementAvance réseau échoué: $e');
      await _syncService.queueSyncOperation(
          'UPDATE', 'membre', membreId, updated.toJson());
    }

    // Notification
    NotificationCoordinator.notifierPaiementAvance(montant, updated.nomComplet);
  }

  /// Supprime soft un membre (déplacement vers la corbeille).
  Future<void> deleteMembre(String id) async {
    final membres = await _cache.getAllMembres();
    final existing = membres.firstWhere(
      (m) => m.id == id,
      orElse: () => throw MembreNotFoundException(id),
    );
    final deviceId = await DeviceService.getDeviceId();
    final now = DateTime.now();

    // Soft delete : marquer comme supprimé, ne pas effacer physiquement
    existing.isDeleted = true;
    existing.deletedAt = now;
    existing.deletedBy = deviceId;
    existing.version++;

    final syncOp = SyncOperation()
      ..operationId = UuidUtils.generate()
      ..type = 'DELETE'
      ..entityType = 'membre'
      ..entityId = id
      ..payloadJson = jsonEncode(existing.toJson())
      ..createdAt = now
      ..deviceId = deviceId;

    // Sauvegarder dans la corbeille
    final corbeilleItem = CorbeilleItem()
      ..entityId = id
      ..entityType = 'membre'
      ..payloadJson = jsonEncode(existing.toJson())
      ..deletedAt = now
      ..updatedAt = existing.updatedAt;
    await _cache.saveCorbeilleItem(corbeilleItem);

    await _cache.softDeleteMembreWithSyncOp(existing, syncOp);

    NotificationCoordinator.annulerAnniversaireMembre(id);

    // 2. Réseau
    try {
      await _api.deleteMembre(id);
      // Succès réseau : supprimer l'opération sync (déjà appliquée)
      await _cache.deleteSyncOp(syncOp.isarId);
    } catch (e) {
      debugPrint('[MembreController] deleteMembre réseau échoué: $e');
      await _syncService.queueSyncOperation('DELETE', 'membre', id, {});
    }
  }
}
