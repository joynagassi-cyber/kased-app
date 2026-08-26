import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/core/services/notification_coordinator.dart';
import 'package:kased_app/core/services/push_notify_service.dart';
import 'package:kased_app/core/sync/device_service_port.dart';
import 'package:kased_app/core/utils/uuid.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/sync_operation.dart';
import 'package:kased_app/store/app_state.dart';
import 'package:kased_app/store/app_state_helpers.dart';
import 'package:kased_app/store/kased_action.dart';

/// Handler dédié aux actions [MemberAction].
class MemberHandler {
  final LocalCache cache;
  final InsForgeService api;
  final DeviceServicePort deviceService;
  final NotificationCoordinator notifCoordinator;
  final Future<void> Function() onLoadDashboard;
  final Future<void> Function(String event, String label, {String? extra}) onPush;

  MemberHandler({
    required this.cache,
    required this.api,
    required this.deviceService,
    required this.notifCoordinator,
    required this.onLoadDashboard,
    required this.onPush,
  });

  Future<void> createMember action) async {
    final deviceId = await deviceService.getDeviceId();
    final now = DateTime.now();
    final newMembre = Membre()
      ..id = UuidUtils.generate()
      ..nom = action.nom
      ..prenom = action.prenom
      ..dateAdhesion = action.dateAdhesion
      ..dateNaissance = action.dateNaissance
      ..telephone = action.telephone
      ..notes = action.notes
      ..isActive = true
      ..deviceId = deviceId
      ..createdAt = now
      ..updatedAt = now;

    final syncOp = SyncOperation()
      ..operationId = UuidUtils.generate()
      ..type = 'CREATE'
      ..entityType = 'membre'
      ..entityId = newMembre.id
      ..payloadJson = jsonEncode(newMembre.toJson())
      ..createdAt = now
      ..deviceId = deviceId;

    await cache.saveMembreWithSyncOp(newMembre, syncOp);

    try {
      await api.createMembre(newMembre.toJson());
      await cache.deleteSyncOp(syncOp.isarId);
    } catch (e) {
      debugPrint('[MemberHandler] createMembre réseau échoué: $e');
    }

    NotificationCoordinator.planifierAnniversaireMembre(newMembre);
    notifCoordinator.notifierCreationMembreFull(newMembre);
    await onPush('membre_ajoute', newMembre.nomComplet);
    await onLoadDashboard();
  }

  Future<void> updateMember action) async {
    final membre = (await cache.getAllMembres()).firstWhere(
      (m) => m.id == action.id,
      orElse: () => throw Exception('Membre introuvable: ${action.id}'),
    );
    final deviceId = await deviceService.getDeviceId();
    final now = DateTime.now();

    final updated = Membre()
      ..id = membre.id
      ..nom = action.nom ?? membre.nom
      ..prenom = action.prenom ?? membre.prenom
      ..dateAdhesion = action.dateAdhesion ?? membre.dateAdhesion
      ..dateNaissance = action.dateNaissance ?? membre.dateNaissance
      ..telephone = action.telephone ?? membre.telephone
      ..notes = action.notes ?? membre.notes
      ..isActive = action.isActive ?? membre.isActive
      ..deviceId = deviceId
      ..createdAt = membre.createdAt
      ..version = membre.version + 1
      ..updatedAt = now;

    final syncOp = SyncOperation()
      ..operationId = UuidUtils.generate()
      ..type = 'UPDATE'
      ..entityType = 'membre'
      ..entityId = action.id
      ..payloadJson = jsonEncode(updated.toJson())
      ..createdAt = now
      ..deviceId = deviceId;

    await cache.saveMembreWithSyncOp(updated, syncOp);

    try {
      await api.updateMembre(action.id, updated.toJson());
      await cache.deleteSyncOp(syncOp.isarId);
    } catch (e) {
      debugPrint('[MemberHandler] updateMembre réseau échoué: $e');
    }

    if (updated.dateNaissance != null) {
      NotificationCoordinator.planifierAnniversaireMembre(updated);
    } else {
      NotificationCoordinator.annulerAnniversaireMembre(action.id);
    }
    unawaited(onPush('membre_modifie', updated.nomComplet));
  }

  Future<void> addPaymentAdvance action) async {
    final membre = (await cache.getAllMembres()).firstWhere(
      (m) => m.id == action.membreId,
      orElse: () => throw Exception('Membre introuvable'),
    );
    final deviceId = await deviceService.getDeviceId();
    final now = DateTime.now();

    final updated = Membre()
      ..id = membre.id
      ..nom = membre.nom
      ..prenom = membre.prenom
      ..dateAdhesion = membre.dateAdhesion
      ..dateNaissance = membre.dateNaissance
      ..montantEnAvance = membre.montantEnAvance + action.montant
      ..telephone = membre.telephone
      ..notes = action.notes ?? membre.notes
      ..isActive = membre.isActive
      ..deviceId = deviceId
      ..createdAt = membre.createdAt
      ..version = membre.version + 1
      ..updatedAt = now;

    final syncOp = SyncOperation()
      ..operationId = UuidUtils.generate()
      ..type = 'UPDATE'
      ..entityType = 'membre'
      ..entityId = action.membreId
      ..payloadJson = jsonEncode(updated.toJson())
      ..createdAt = now
      ..deviceId = deviceId;

    await cache.saveMembreWithSyncOp(updated, syncOp);

    try {
      await api.updateMembre(action.membreId, updated.toJson());
      await cache.deleteSyncOp(syncOp.isarId);
    } catch (e) {
      debugPrint('[MemberHandler] addPaymentAdvance réseau échoué: $e');
    }

    notifCoordinator.notifierPaiementAvanceFull(action.montant, updated.nomComplet);
    await onPush('paiement_avance', updated.nomComplet);
  }

  Future<void> deleteMember action) async {
    final membres = (await cache.getAllMembres()).where((m) => m.id != action.id).toList();
    await cache.deleteMembreById(action.id);
    NotificationCoordinator.annulerAnniversaireMembre(action.id);
    unawaited(onPush('membre_supprime', action.id));
  }

  Future<void> restoreMember action) async {
    try {
      await api.updateMembre(action.id, {'is_active': true});
    } catch (e) {
      debugPrint('[MemberHandler] restaurer membre réseau échoué: $e');
    }
  }
}
