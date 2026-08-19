import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:kased_app/core/logic/cotisation_logic.dart';
import 'package:kased_app/core/services/notification_coordinator.dart';
import 'package:kased_app/core/utils/uuid.dart';
import 'package:kased_app/core/sync/device_service_port.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/sync_operation.dart';
import 'package:kased_app/providers/app_data_provider.dart';

/// Exception lancee quand un culte est introuvable lors d'un paiement.
class CulteIntrouvableException implements Exception {
  final String culteId;
  CulteIntrouvableException(this.culteId);
  @override
  String toString() => "Culte introuvable: $culteId";
}

/// Exception lancee quand un paiement est inferieur au montant obligatoire.
class MontantInsuffisantException implements Exception {
  final double montant;
  final double montantObligatoire;
  MontantInsuffisantException(this.montant, this.montantObligatoire);
  @override
  String toString() =>
      'Le montant paye doit etre au moins egal au montant obligatoire (${montantObligatoire}F)';
}

/// Exception lancee quand on tente de modifier un paiement verrouille.
class PaiementVerrouilleException implements Exception {
  final String message;
  PaiementVerrouilleException(this.message);
  @override
  String toString() => message;
}

/// Controleur dedie a la gestion des cotisations et paiements.
///
/// Responsabilites :
/// - Enregistrement de paiements personnalises
/// - Toggle de paiement (retrocompatibilite)
/// - Mise a jour en masse de statuts
/// - Marquage d'absences
/// - Paiements en avance pour plusieurs cultes
class CotisationController {
  final LocalCache _cache;
  final InsForgeService _api;
  final DeviceServicePort _deviceService;
  final void Function(AppState) onStateChanged;

  CotisationController({
    required LocalCache cache,
    required InsForgeService api,
    required DeviceServicePort deviceService,
    required this.onStateChanged,
  })  : _cache = cache,
        _api = api,
        _deviceService = deviceService;

  /// Enregistre un paiement personnalise pour un membre sur un culte.
  /// Gere la consommation d'avance et le suivi des dons.
  Future<void> enregistrerPaiement({
    required String membreId,
    required String culteId,
    required double montant,
  }) async {
    final cultes = await _cache.getAllCultes();
    final culte = cultes.firstWhereOrNull((c) => c.id == culteId);
    if (culte == null) {
      throw CulteIntrouvableException(culteId);
    }

    // Verification du verrouillage apres 30 jours (si deja paye)
    final isOlderThan30Days =
        DateTime.now().difference(culte.dateCulte).inDays > 30;

    final cotisations = await _cache.getAllCotisations();
    var existingCotisation = cotisations.firstWhereOrNull(
      (c) => c.membreId == membreId && c.culteId == culteId,
    );

    final bool isNewCotisation = existingCotisation == null;
    if (isNewCotisation) {
      existingCotisation = Cotisation()
        ..id = UuidUtils.generate()
        ..membreId = membreId
        ..culteId = culteId
        ..montantObligatoire = culte.montantCotisation
        ..montantPaye = 0.0
        ..montantDon = 0.0
        ..statut = StatutCotisation.nonPaye;
    }

    // Verification du verrouillage apres 30 jours (si deja paye)
    if (isOlderThan30Days && existingCotisation.estPaye) {
      throw PaiementVerrouilleException("Le paiement est verrouille apres 30 jours.");
    }

    // Validation : le montant doit etre au moins egal au montant obligatoire
    if (montant < existingCotisation.montantObligatoire) {
      throw MontantInsuffisantException(
          montant, existingCotisation.montantObligatoire);
    }

    // Calcul du don (excedent)
    final montantDon = montant - existingCotisation.montantObligatoire;

    // Determination du statut : enAvance si paiement avant le culte, paye sinon
    final datePaiement = DateTime.now();
    final statut = CotisationLogic.determinerStatut(
      datePaiement: datePaiement,
      dateCulte: culte.dateCulte,
    );

    // Mise a jour de la cotisation
    final updatedCotisation = existingCotisation.copyWith(
      montantPaye: montant,
      montantDon: montantDon,
      statut: statut,
      datePaiement: montant >= existingCotisation.montantObligatoire
          ? datePaiement
          : null,
      updatedAt: DateTime.now(),
    );

    // Persister immediatement dans Isar
    await _cache.saveCotisation(updatedCotisation);

    // Consommer l'avance du membre si paiement complet (pas de don)
    if (montantDon == 0) {
      final membres = await _cache.getAllMembres();
      final membre = membres.firstWhereOrNull(
        (m) => m.id == membreId,
      );
      if (membre != null && membre.montantEnAvance >= montant) {
        final deviceId = await _deviceService.getDeviceId();
        final now = DateTime.now();
        final updatedMembre = Membre()
          ..id = membre.id
          ..nom = membre.nom
          ..prenom = membre.prenom
          ..dateAdhesion = membre.dateAdhesion
          ..dateNaissance = membre.dateNaissance
          ..montantEnAvance = membre.montantEnAvance - montant
          ..totalDons = membre.totalDons
          ..telephone = membre.telephone
          ..notes = membre.notes
          ..isActive = membre.isActive
          ..deviceId = deviceId
          ..createdAt = membre.createdAt
          ..version = membre.version + 1
          ..updatedAt = now;
        final syncOp = SyncOperation()
          ..operationId = UuidUtils.generate()
          ..type = 'UPDATE'
          ..entityType = 'membre'
          ..entityId = membreId
          ..payloadJson = jsonEncode(updatedMembre.toJson())
          ..createdAt = now
          ..deviceId = deviceId;
        await _cache.saveMembreWithSyncOp(updatedMembre, syncOp);
        // Synchroniser l'avance consommee
        try {
          await _api.consommerAvancePourCulte(
            membreId: membreId,
            culteId: culteId,
          );
          await _cache.deleteSyncOp(syncOp.isarId);
        } catch (e) {
          debugPrint('[CotisationController] consommerAvance reseau echoue: $e');
        }
      }
    }

    // Mettre a jour le total des dons du membre si un don a ete enregistre
    if (montantDon > 0) {
      final membres = await _cache.getAllMembres();
      final membreWithDon = membres.firstWhereOrNull(
        (m) => m.id == membreId,
      );
      if (membreWithDon != null && membreWithDon.totalDons < montantDon) {
        final deviceId = await _deviceService.getDeviceId();
        final now = DateTime.now();
        final updatedMembre = Membre()
          ..id = membreWithDon.id
          ..nom = membreWithDon.nom
          ..prenom = membreWithDon.prenom
          ..dateAdhesion = membreWithDon.dateAdhesion
          ..dateNaissance = membreWithDon.dateNaissance
          ..montantEnAvance = membreWithDon.montantEnAvance
          ..totalDons = membreWithDon.totalDons + montantDon
          ..telephone = membreWithDon.telephone
          ..notes = membreWithDon.notes
          ..isActive = membreWithDon.isActive
          ..deviceId = deviceId
          ..createdAt = membreWithDon.createdAt
          ..version = membreWithDon.version + 1
          ..updatedAt = now;
        final syncOp = SyncOperation()
          ..operationId = UuidUtils.generate()
          ..type = 'UPDATE'
          ..entityType = 'membre'
          ..entityId = membreId
          ..payloadJson = jsonEncode(updatedMembre.toJson())
          ..createdAt = now
          ..deviceId = deviceId;
        await _cache.saveMembreWithSyncOp(updatedMembre, syncOp);
      }
      final membreNom = membreWithDon?.nomComplet ?? membreId;
      NotificationCoordinator.notifierDonEnregistre(montantDon, membreId, membreNom: membreNom);
    }

    // Synchroniser avec le serveur
    try {
      if (isNewCotisation) {
        await _api
            .createCotisations([updatedCotisation.toJson()])
            .timeout(const Duration(seconds: 15));
      } else {
        await _api
            .updateCotisation(
                updatedCotisation.id, updatedCotisation.toJson())
            .timeout(const Duration(seconds: 15));
      }
    } catch (e) {
      debugPrint(
          '[CotisationController] enregistrerPaiement reseau echoue, etat local conserve: $e');
      await _cache.saveSyncOp(SyncOperation()
        ..operationId = UuidUtils.generate()
        ..type = 'UPDATE'
        ..entityType = 'cotisation'
        ..entityId = updatedCotisation.id
        ..payloadJson = jsonEncode(updatedCotisation.toJson())
        ..createdAt = DateTime.now()
        ..deviceId = await _deviceService.getDeviceId());
    }
  }

  /// Garde la fonction togglePaiement pour compatibilite arriere.
  Future<void> togglePaiement({
    required String membreId,
    required String culteId,
  }) async {
    final cultes = await _cache.getAllCultes();
    final culte = cultes.firstWhereOrNull((c) => c.id == culteId);
    if (culte == null) return;

    await enregistrerPaiement(
      membreId: membreId,
      culteId: culteId,
      montant: culte.montantCotisation,
    );
  }

  /// Met a jour le statut de TOUTES les cotisations d'un culte.
  Future<({int success, int total})> bulkSetPaiements({
    required String culteId,
    required StatutCotisation newStatut,
    required List<String> membreIds,
  }) async {
    final cotisations = await _cache.getAllCotisations();
    final cultes = await _cache.getAllCultes();
    final culte = cultes.firstWhereOrNull((c) => c.id == culteId);
    final montantObligatoire = culte?.montantCotisation ?? 50.0;

    // Mise a jour optimiste immediate
    final updatedCotisations = cotisations.map((c) {
      if (c.culteId == culteId && membreIds.contains(c.membreId)) {
        double montantPaye = 0.0;
        double montantDon = 0.0;
        DateTime? datePaiement;
        if (newStatut == StatutCotisation.paye ||
            newStatut == StatutCotisation.enAvance) {
          montantPaye = montantObligatoire;
          montantDon = 0.0;
          datePaiement = DateTime.now();
        } else if (newStatut == StatutCotisation.nonPaye) {
          montantPaye = 0.0;
          montantDon = 0.0;
          datePaiement = null;
        }
        return c.copyWith(
          statut: newStatut,
          montantPaye: montantPaye,
          montantDon: montantDon,
          datePaiement: datePaiement,
          updatedAt: DateTime.now(),
        );
      }
      return c;
    }).toList();

    final toUpdateLocally = updatedCotisations
        .where((c) => c.culteId == culteId && membreIds.contains(c.membreId))
        .toList();
    await _cache.saveAllCotisations(toUpdateLocally);

    int success = 0;
    try {
      for (var i = 0; i < membreIds.length; i += 5) {
        final chunk = membreIds.skip(i).take(5).toList();
        final results = await Future.wait(
          chunk.map((membreId) async {
            final cotisationToUpdate = updatedCotisations.firstWhereOrNull(
              (c) => c.membreId == membreId && c.culteId == culteId,
            );
            if (cotisationToUpdate == null) return false;
            try {
              await _api.updateCotisation(
                  cotisationToUpdate.id, cotisationToUpdate.toJson());
              return true;
            } catch (e) {
              await _cache.saveSyncOp(SyncOperation()
                ..operationId = UuidUtils.generate()
                ..type = 'UPDATE'
                ..entityType = 'cotisation'
                ..entityId = cotisationToUpdate.id
                ..payloadJson = jsonEncode(cotisationToUpdate.toJson())
                ..createdAt = DateTime.now()
                ..deviceId = await _deviceService.getDeviceId());
              return false;
            }
          }),
        );
        success += results.where((r) => r).length;
      }
    } catch (e) {
      debugPrint(
          '[CotisationController] bulkSetPaiements reseau echoue, etat local conserve: $e');
    }

    // Notification de mise a jour des paiements
    final actionText =
        newStatut == StatutCotisation.paye ? 'paye(s)' : 'annule(s)';
    NotificationCoordinator.notifierPaiementsEnMasse(success, actionText);

    return (success: success, total: membreIds.length);
  }

  /// Marque un membre comme absent pour un culte donne.
  Future<void> marquerAbsent({
    required String membreId,
    required String culteId,
  }) async {
    final cultes = await _cache.getAllCultes();
    final culte = cultes.firstWhereOrNull((c) => c.id == culteId);
    if (culte == null) return;

    final isOlderThan30Days =
        DateTime.now().difference(culte.dateCulte).inDays > 30;

    final cotisations = await _cache.getAllCotisations();
    var existingCotisation = cotisations.firstWhereOrNull(
      (c) => c.membreId == membreId && c.culteId == culteId,
    );

    final bool isNewCotisation = existingCotisation == null;
    if (isNewCotisation) {
      existingCotisation = Cotisation()
        ..id = UuidUtils.generate()
        ..membreId = membreId
        ..culteId = culteId
        ..montantObligatoire = culte.montantCotisation
        ..montantPaye = 0.0
        ..montantDon = 0.0
        ..statut = StatutCotisation.nonPaye;
    }

    if (isOlderThan30Days && existingCotisation.estPaye) {
      throw PaiementVerrouilleException(
          "Impossible de marquer absent un membre ayant deja paye pour un culte verrouille.");
    }

    final updatedCotisation = existingCotisation.copyWith(
      statut: StatutCotisation.absent,
      montantPaye: 0.0,
      montantDon: 0.0,
      id: existingCotisation.id,
      updatedAt: DateTime.now(),
    );

    await _cache.saveCotisation(updatedCotisation);

    try {
      if (isNewCotisation) {
        await _api
            .createCotisations([updatedCotisation.toJson()])
            .timeout(const Duration(seconds: 15));
      } else {
        await _api
            .marquerAbsent(membreId: membreId, culteId: culteId)
            .timeout(const Duration(seconds: 15));
      }
    } catch (e) {
      debugPrint(
          '[CotisationController] marquerAbsent reseau echoue, etat local conserve: $e');
      await _cache.saveSyncOp(SyncOperation()
        ..operationId = UuidUtils.generate()
        ..type = 'UPDATE'
        ..entityType = 'cotisation'
        ..entityId = updatedCotisation.id
        ..payloadJson = jsonEncode(updatedCotisation.toJson())
        ..createdAt = DateTime.now()
        ..deviceId = await _deviceService.getDeviceId());
    }
  }

  /// Recupere l'historique des paiements d'un membre.
  Future<List<Map<String, dynamic>>> getHistoriqueMembre(
      String membreId) async {
    try {
      return await _api.getHistoriqueMembre(membreId);
    } catch (e) {
      debugPrint('Erreur chargement historique: $e');
      return [];
    }
  }

  /// Genere les cotisations initiales pour un nouveau membre.
  /// Crée une cotisation non payee pour chaque culte futur.
  Future<void> generateInitialCotisationsForMembre(Membre membre) async {
    final cultes = await _cache.getAllCultes();
    final deviceId = await _deviceService.getDeviceId();
    final now = DateTime.now();

    for (final culte in cultes) {
      // Ne créer que pour les cultes futurs
      if (culte.isDeleted || culte.dateCulte.isBefore(membre.createdAt)) continue;

      final cotisation = Cotisation()
        ..id = UuidUtils.generate()
        ..membreId = membre.id
        ..culteId = culte.id
        ..montantObligatoire = culte.montantCotisation
        ..montantPaye = 0.0
        ..montantDon = 0.0
        ..statut = StatutCotisation.nonPaye
        ..deviceId = deviceId
        ..createdAt = now;

      await _cache.saveCotisation(cotisation);
    }
  }
}
