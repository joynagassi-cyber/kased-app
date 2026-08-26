import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/core/logic/cotisation_logic.dart';
import 'package:kased_app/core/services/notification_coordinator.dart';
import 'package:kased_app/core/services/push_notify_service.dart';
import 'package:kased_app/core/sync/device_service_port.dart';
import 'package:kased_app/core/utils/uuid.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/store/kased_action.dart';

/// Handler dédié aux actions [CotisationAction].
class CotisationHandler {
  final LocalCache cache;
  final InsForgeService api;
  final DeviceServicePort deviceService;
  final NotificationCoordinator notifCoordinator;
  final Future<void> Function(String event, String label, {String? extra}) onPush;
  final Future<List<Membre>> Function() onGetMembres;
  final Future<List<Cotisation>> Function() onGetCotisations;

  CotisationHandler({
    required this.cache,
    required this.api,
    required this.deviceService,
    required this.notifCoordinator,
    required this.onPush,
    required this.onGetMembres,
    required this.onGetCotisations,
  });

  Future<void> handle(RegisterPayment action) async {
    final culte = (await cache.getAllCultes()).firstWhere(
      (c) => c.id == action.culteId,
      orElse: () => throw Exception('Culte introuvable'),
    );
    final cotisations = await onGetCotisations();
    final membres = await onGetMembres();

    var existingCotisation = cotisations.firstWhere(
      (c) => c.membreId == action.membreId && c.culteId == action.culteId,
      orElse: () => Cotisation()
        ..id = UuidUtils.generate()
        ..membreId = action.membreId
        ..culteId = action.culteId
        ..montantObligatoire = culte.montantCotisation
        ..montantPaye = 0.0
        ..montantDon = 0.0
        ..statut = StatutCotisation.nonPaye,
    );

    final isOlderThan30Days =
        DateTime.now().difference(culte.dateCulte).inDays > 30;

    if (isOlderThan30Days && existingCotisation.estPaye) {
      throw Exception('Le paiement est verrouillé après 30 jours.');
    }

    if (action.montant < existingCotisation.montantObligatoire) {
      throw Exception(
        'Le montant payé doit être au moins égal au montant obligatoire (${existingCotisation.montantObligatoire}F)',
      );
    }

    final montantDon = action.montant - existingCotisation.montantObligatoire;
    final datePaiement = DateTime.now();
    final statut = CotisationLogic.determinerStatut(
      datePaiement: datePaiement,
      dateCulte: culte.dateCulte,
    );

    final updatedCotisation = existingCotisation.copyWith(
      montantPaye: action.montant,
      montantDon: montantDon,
      statut: statut,
      datePaiement: action.montant >= existingCotisation.montantObligatoire ? datePaiement : null,
      updatedAt: DateTime.now(),
    );

    await cache.saveCotisation(updatedCotisation);

    if (montantDon == 0) {
      final membre = membres.firstWhere(
        (m) => m.id == action.membreId,
        orElse: () => throw Exception('Membre introuvable'),
      );
      if (membre.montantEnAvance >= action.montant) {
        final deviceId = await deviceService.getDeviceId();
        final now = DateTime.now();
        final updatedMembre = Membre()
          ..id = membre.id
          ..nom = membre.nom
          ..prenom = membre.prenom
          ..dateAdhesion = membre.dateAdhesion
          ..dateNaissance = membre.dateNaissance
          ..montantEnAvance = membre.montantEnAvance - action.montant
          ..totalDons = membre.totalDons
          ..telephone = membre.telephone
          ..notes = membre.notes
          ..isActive = membre.isActive
          ..deviceId = deviceId
          ..createdAt = membre.createdAt
          ..version = membre.version + 1
          ..updatedAt = now;
        await cache.saveMembre(updatedMembre);
        try {
          await api.consommerAvancePourCulte(membreId: membre.id, culteId: action.culteId);
        } catch (e) {
          debugPrint('[CotisationHandler] consommerAvance réseau échoué: $e');
        }
      }
    }

    unawaited(onPush(
      statut == StatutCotisation.enAvance ? 'cotisation_en_avance' : 'cotisation_payee',
      '${membres.firstWhere((m) => m.id == action.membreId).nomComplet} — culte du ${culte.dateCulte.day}/${culte.dateCulte.month}',
      extra: action.montant.toStringAsFixed(0),
    ));
  }

  Future<void> handle(MarkAbsent action) async {
    final cultes = await cache.getAllCultes();
    final cotisations = await onGetCotisations();
    final membres = await onGetMembres();

    final culte = cultes.firstWhere(
      (c) => c.id == action.culteId,
      orElse: () => throw Exception('Culte introuvable'),
    );
    final isOlderThan30Days =
        DateTime.now().difference(culte.dateCulte).inDays > 30;

    var existingCotisation = cotisations.firstWhere(
      (c) => c.membreId == action.membreId && c.culteId == action.culteId,
      orElse: () => Cotisation()
        ..id = UuidUtils.generate()
        ..membreId = action.membreId
        ..culteId = action.culteId
        ..montantObligatoire = culte.montantCotisation
        ..montantPaye = 0.0
        ..montantDon = 0.0
        ..statut = StatutCotisation.nonPaye,
    );

    if (isOlderThan30Days && existingCotisation.estPaye) {
      throw Exception('Impossible de marquer absent un membre ayant déjà payé pour un culte verrouillé.');
    }

    final updatedCotisation = existingCotisation.copyWith(
      statut: StatutCotisation.absent,
      montantPaye: 0.0,
      montantDon: 0.0,
      updatedAt: DateTime.now(),
    );

    await cache.saveCotisation(updatedCotisation);
    final membre = membres.firstWhere(
      (m) => m.id == action.membreId,
      orElse: () => throw Exception('Membre introuvable'),
    );
    unawaited(onPush('cotisation_absente', membre.nomComplet));
  }

  Future<({int success, int total})> handle(BulkSetPaiements action) async {
    final cotisations = await onGetCotisations();
    List<Cotisation> updatedCotisations = List.from(cotisations);

    for (final membreId in action.membreIds) {
      final cotisation = updatedCotisations.firstWhere(
        (c) => c.membreId == membreId && c.culteId == action.culteId,
        orElse: () => throw Exception('Cotisation introuvable pour $membreId'),
      );

      final updated = cotisation.copyWith(
        statut: action.newStatut,
        montantPaye: action.newStatut == StatutCotisation.paye ? cotisation.montantObligatoire : 0.0,
        updatedAt: DateTime.now(),
      );
      updatedCotisations = updatedCotisations
          .map((c) => c.id == cotisation.id ? updated : c)
          .toList();
      await cache.saveCotisation(updated);
    }

    final success = action.membreIds.length;
    final actionText = action.newStatut == StatutCotisation.paye ? 'payé(s)' : 'annulé(s)';
    notifCoordinator.notifierPaiementsEnMasseFull(success, actionText);
    unawaited(onPush('cotisations_bulk', '$success paiement(s) $actionText', extra: action.newStatut.name));

    return (success: success, total: action.membreIds.length);
  }

  Future<void> handle(PaySeveralCultesInAdvance action) async {
    final cultes = await cache.getAllCultes();
    final cotisations = await onGetCotisations();
    final membres = await onGetMembres();
    final deviceId = await deviceService.getDeviceId();
    final now = DateTime.now();

    List<Cotisation> updatedCotisations = List.from(cotisations);

    for (final culteId in action.culteIds) {
      final culte = cultes.firstWhere(
        (c) => c.id == culteId && !c.isDeleted,
        orElse: () => null,
      );
      if (culte == null) continue;

      var existing = updatedCotisations.firstWhere(
        (c) => c.membreId == action.membreId && c.culteId == culteId,
        orElse: () => Cotisation()
          ..id = UuidUtils.generate()
          ..membreId = action.membreId
          ..culteId = culteId
          ..montantObligatoire = culte.montantCotisation
          ..montantPaye = 0.0
          ..montantDon = 0.0
          ..statut = StatutCotisation.nonPaye,
      );

      final statut = CotisationLogic.determinerStatut(datePaiement: now, dateCulte: culte.dateCulte);
      final montantParCulte = (action.montantTotal / action.culteIds.length).roundToDouble();
      final updated = existing.copyWith(
        montantPaye: montantParCulte,
        montantDon: 0.0,
        statut: statut,
        datePaiement: now,
        updatedAt: now,
      );

      final index = updatedCotisations.indexWhere((c) => c.id == updated.id);
      if (index != -1) {
        updatedCotisations[index] = updated;
      } else {
        updatedCotisations.add(updated);
      }
      await cache.saveCotisation(updated);
    }

    await cache.saveAllCotisations(updatedCotisations);
    try {
      await api.consignerPaiementEnAvance(
        membreId: action.membreId,
        culteIds: action.culteIds,
        montantTotal: action.montantTotal,
      );
    } catch (e) {
      debugPrint('[CotisationHandler] payerPlusieursCultesEnAvance réseau échoué: $e');
    }

    final membre = membres.firstWhere(
      (m) => m.id == action.membreId,
      orElse: () => throw Exception('Membre introuvable'),
    );
    notifCoordinator.notifierPaiementAvanceFull(action.montantTotal, membre.nomComplet);
    unawaited(onPush('cotisation_en_avance', membre.nomComplet));
  }
}
