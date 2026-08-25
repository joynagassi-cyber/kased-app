import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:kased_app/core/logic/cotisation_logic.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/core/services/notification_coordinator.dart';
import 'package:kased_app/core/services/push_notify_service.dart';
import 'package:kased_app/core/services/stats_service.dart';
import 'package:kased_app/core/services/sync_service.dart';
import 'package:kased_app/core/sync/device_service_port.dart';
import 'package:kased_app/core/utils/uuid.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/controllers/cotisation_controller.dart';
import 'package:kased_app/controllers/culte_controller.dart';
import 'package:kased_app/controllers/membre_controller.dart';
import 'package:kased_app/controllers/system_controller.dart';
import 'package:kased_app/models/sync_operation.dart';
import 'package:kased_app/store/app_state.dart';
import 'package:kased_app/store/app_state_helpers.dart';
import 'package:kased_app/store/kased_action.dart';

/// Store centralisé de l'application Kased.
///
/// Interface : [dispatch] reçoit une [KasedAction] et transforme l'[AppState].
/// Les handlers internes (MembreHandler, CulteHandler, etc.) gèrent la logique
/// métier de chaque domain.
///
/// Le provider Riverpod ([KasedApp]) est un adaptateur fin qui connecte le
/// store au cycle de vie Flutter.
class KasedStore {
  // ── State ──────────────────────────────────────────────────────────────────

  AppState _state = AppState();
  AppState get state => _state;

  // ── Dependencies ───────────────────────────────────────────────────────────

  final InsForgeService api;
  final LocalCache cache;
  final SyncService syncService;
  final StatsService statsService;
  final DeviceServicePort deviceService;
  final NotificationCoordinator notifCoordinator;

  // Controllers (délégués pour les écritures avec sync ops)
  late MembreController _membreController;
  late CulteController _culteController;
  late CotisationController _cotisationController;
  late SystemController _systemController;

  bool _isSyncing = false;

  KasedStore({
    required this.api,
    required this.cache,
    required this.syncService,
    required this.statsService,
    required this.deviceService,
    required this.notifCoordinator,
  }) {
    // Initialize controllers (they don't use onStateChanged anymore)
    _membreController = MembreController(
      cache: cache,
      api: api,
      syncService: syncService,
      deviceService: deviceService,
      onStateChanged: (_) {}, // Not used
    );
    _culteController = CulteController(
      cache: cache,
      api: api,
      syncService: syncService,
      deviceService: deviceService,
      onStateChanged: (_) {},
    );
    _cotisationController = CotisationController(
      cache: cache,
      api: api,
      deviceService: deviceService,
      onStateChanged: (_) {},
    );
    _systemController = SystemController(
      cache: cache,
      api: api,
      syncService: syncService,
      statsService: statsService,
      onStateChanged: (_) {},
    );
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Dispatch une action. Le store applique la transformation et notifie.
  Future<void> dispatch(KasedAction action) async {
    try {
      switch (action) {
        // Members
        case CreateMember():
          await _handleCreateMember(action);
        case UpdateMember():
          await _handleUpdateMember(action);
        case AddPaymentAdvance():
          await _handleAddPaymentAdvance(action);
        case DeleteMember():
          await _handleDeleteMember(action);
        case RestoreMember():
          await _handleRestoreMember(action);
        // Cultes
        case CreateCulte():
          await _handleCreateCulte(action);
        case UpdateCulte():
          await _handleUpdateCulte(action);
        case DeleteCulte():
          await _handleDeleteCulte(action);
        case RestoreCulte():
          await _handleRestoreCulte(action);
        // Cotisations
        case RegisterPayment():
          await _handleRegisterPayment(action);
        case MarkAbsent():
          await _handleMarkAbsent(action);
        case BulkSetPaiements():
          await _handleBulkSetPaiements(action);
        case TogglePaiement():
          await _handleTogglePaiement(action);
        case PaySeveralCultesInAdvance():
          await _handlePaySeveralCultesInAdvance(action);
        // Sync
        case SyncData():
          await _handleSyncData();
        case LoadDashboard():
          await _handleLoadDashboard();
        // Corbeille
        case PermanentlyDelete():
          await _handlePermanentlyDelete(action);
        case EmptyTrash():
          await _handleEmptyTrash();
        // Queries (read-only)
        case GetHistoriqueMembre():
          await _handleGetHistorique(action);
        case GetCotisationsDuCulte():
          await _handleGetCotisationsDuCulte(action);
      }
    } catch (e, stack) {
      debugPrint('[KasedStore] Error dispatching $action: $e\n$stack');
      _state = _state.copyWith(error: e.toString());
    }
  }

  // ── Membre Handlers ────────────────────────────────────────────────────────

  Future<void> _handleCreateMember(CreateMember action) async {
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

    _state = withSortedMembres(_state, [..._state.membres, newMembre]);

    NotificationCoordinator.planifierAnniversaireMembre(newMembre);
    notifCoordinator.notifierCreationMembreFull(newMembre);
    unawaited(_notifierPush('membre_ajoute', newMembre.nomComplet));
    await _handleLoadDashboard();
  }

  Future<void> _handleUpdateMember(UpdateMember action) async {
    final membre = _state.membres.firstWhere(
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

    _state = AppState(
      membres: updateMembreInList(_state.membres, action.id, updated),
      cultes: _state.cultes,
      cotisations: _state.cotisations,
      dashboard: _state.dashboard,
      isLoading: _state.isLoading,
      isOffline: _state.isOffline,
      error: null,
    );
    await cache.saveMembre(updated);

    if (updated.dateNaissance != null) {
      NotificationCoordinator.planifierAnniversaireMembre(updated);
    } else {
      NotificationCoordinator.annulerAnniversaireMembre(action.id);
    }
    unawaited(_notifierPush('membre_modifie', updated.nomComplet));
  }

  Future<void> _handleAddPaymentAdvance(AddPaymentAdvance action) async {
    final membre = _state.membres.firstWhere(
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

    _state = AppState(
      membres: updateMembreInList(_state.membres, action.membreId, updated),
      cultes: _state.cultes,
      cotisations: _state.cotisations,
      dashboard: _state.dashboard,
      isLoading: _state.isLoading,
      isOffline: _state.isOffline,
      error: null,
    );
    await cache.saveMembre(updated);
    notifCoordinator.notifierPaiementAvanceFull(action.montant, updated.nomComplet);
    unawaited(_notifierPush('paiement_avance', updated.nomComplet));
  }

  Future<void> _handleDeleteMember(DeleteMember action) async {
    final membres = _state.membres.where((m) => m.id != action.id).toList();
    _state = _state.copyWith(membres: membres);
    await cache.deleteMembreById(action.id);
    NotificationCoordinator.annulerAnniversaireMembre(action.id);
    unawaited(_notifierPush('membre_supprime', action.id));
  }

  Future<void> _handleRestoreMember(RestoreMember action) async {
    // Recharger depuis le cache
    final allMembres = await cache.getAllMembres();
    final allCultes = await cache.getAllCultes();
    final allCotisations = await cache.getAllCotisations();
    _state = withFullData(_state, membres: allMembres, cultes: allCultes, cotisations: allCotisations);
    try {
      await api.updateMembre(action.id, {'is_active': true});
    } catch (e) {
      debugPrint('[KasedStore] restaurer membre réseau échoué: $e');
    }
  }

  // ── Culte Handlers ─────────────────────────────────────────────────────────

  Future<void> _handleCreateCulte(CreateCulte action) async {
    // TODO: Use CulteController for full logic (cotisation generation, sync ops)
    // For now, direct implementation
    final newCulte = Culte()
      ..id = UuidUtils.generate()
      ..dateCulte = action.date
      ..titre = action.titre
      ..montantCotisation = action.montant
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    _state = AppState(
      membres: _state.membres,
      cultes: addCulteSorted(_state.cultes, newCulte),
      cotisations: _state.cotisations,
      dashboard: _state.dashboard,
      isLoading: _state.isLoading,
      isOffline: _state.isOffline,
      error: null,
    );
    await cache.saveCulte(newCulte);
    notifCoordinator.notifierCreationCulteFull(newCulte);
    await _handleLoadDashboard();
    unawaited(_notifierPush('culte_cree', _formatDate(newCulte.dateCulte)));
  }

  Future<void> _handleUpdateCulte(UpdateCulte action) async {
    final existing = _state.cultes.firstWhere(
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

    _state = AppState(
      membres: _state.membres,
      cultes: updateCulteInList(_state.cultes, action.id, updated),
      cotisations: _state.cotisations,
      dashboard: _state.dashboard,
      isLoading: _state.isLoading,
      isOffline: _state.isOffline,
      error: null,
    );
    await cache.saveCulte(updated);
    await _handleLoadDashboard();
  }

  Future<void> _handleDeleteCulte(DeleteCulte action) async {
    // TODO: Soft delete with corbeille
    final cultes = _state.cultes.where((c) => c.id != action.id).toList();
    _state = _state.copyWith(cultes: cultes);
    await cache.deleteCulteById(action.id);
  }

  Future<void> _handleRestoreCulte(RestoreCulte action) async {
    final allMembres = await cache.getAllMembres();
    final allCultes = await cache.getAllCultes();
    final allCotisations = await cache.getAllCotisations();
    _state = withFullData(_state, membres: allMembres, cultes: allCultes, cotisations: allCotisations);
    try {
      await api.createCulte({'id': action.id});
    } catch (e) {
      debugPrint('[KasedStore] restaurer culte réseau échoué: $e');
    }
  }

  // ── Cotisation Handlers ────────────────────────────────────────────────────

  Future<void> _handleRegisterPayment(RegisterPayment action) async {
    final previousState = _state;
    final culte = previousState.cultes.firstWhere(
      (c) => c.id == action.culteId,
      orElse: () => throw Exception('Culte introuvable'),
    );
    final isOlderThan30Days =
        DateTime.now().difference(culte.dateCulte).inDays > 30;

    var existingCotisation = previousState.cotisations.firstWhere(
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

    final isNewCotisation = existingCotisation.montantPaye == 0 &&
        existingCotisation.statut == StatutCotisation.nonPaye &&
        existingCotisation.membreId == action.membreId;

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

    List<Cotisation> updatedCotisations;
    if (isNewCotisation) {
      updatedCotisations = [...previousState.cotisations, updatedCotisation];
    } else {
      updatedCotisations = previousState.cotisations
          .map((c) => c.membreId == action.membreId && c.culteId == action.culteId
              ? updatedCotisation
              : c)
          .toList();
    }

    _state = previousState.copyWith(cotisations: updatedCotisations);
    await cache.saveCotisation(updatedCotisation);

    // Consommer l'avance si don = 0
    if (montantDon == 0) {
      final membre = previousState.membres.firstWhere(
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

        _state = AppState(
          membres: updateMembreInList(_state.membres, membre.id, updatedMembre),
          cultes: _state.cultes,
          cotisations: _state.cotisations,
          dashboard: _state.dashboard,
          isLoading: _state.isLoading,
          isOffline: _state.isOffline,
          error: null,
        );
        await cache.saveMembre(updatedMembre);
        try {
          await api.consommerAvancePourCulte(membreId: membre.id, culteId: action.culteId);
        } catch (e) {
          debugPrint('[KasedStore] consommerAvance réseau échoué: $e');
        }
      }
    }

    unawaited(_notifierPush(
      statut == StatutCotisation.enAvance ? 'cotisation_en_avance' : 'cotisation_payee',
      '${previousState.membres.firstWhere((m) => m.id == action.membreId).nomComplet} — culte du ${_formatDate(culte.dateCulte)}',
      extra: action.montant.toStringAsFixed(0),
    ));
  }

  Future<void> _handleMarkAbsent(MarkAbsent action) async {
    final previousState = _state;
    final cultes = previousState.cultes.where((c) => c.id == action.culteId).toList();
    final isOlderThan30Days = cultes.isNotEmpty &&
        DateTime.now().difference(cultes.first.dateCulte).inDays > 30;

    var existingCotisation = previousState.cotisations.firstWhere(
      (c) => c.membreId == action.membreId && c.culteId == action.culteId,
      orElse: () => Cotisation()
        ..id = UuidUtils.generate()
        ..membreId = action.membreId
        ..culteId = action.culteId
        ..montantObligatoire = cultes.isNotEmpty ? cultes.first.montantCotisation : 50.0
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

    List<Cotisation> updatedCotisations;
    if (existingCotisation.statut == StatutCotisation.nonPaye && existingCotisation.membreId == action.membreId) {
      // Existante → remplacer
      updatedCotisations = previousState.cotisations
          .map((c) => c.membreId == action.membreId && c.culteId == action.culteId
              ? updatedCotisation
              : c)
          .toList();
    } else {
      updatedCotisations = [...previousState.cotisations, updatedCotisation];
    }

    _state = previousState.copyWith(cotisations: updatedCotisations);
    await cache.saveCotisation(updatedCotisation);
    unawaited(_notifierPush('cotisation_absente', _nomMembre(previousState, action.membreId) ?? 'un membre'));
  }

  Future<({int success, int total})> _handleBulkSetPaiements(BulkSetPaiements action) async {
    final previousState = _state;
    if (action.membreIds.isEmpty) return (success: 0, total: 0);

    List<Cotisation> updatedCotisations = List.from(previousState.cotisations);

    for (final membreId in action.membreIds) {
      final cotisation = updatedCotisations.firstWhere(
        (c) => c.membreId == membreId && c.culteId == action.culteId,
        orElse: () => throw Exception('Cotisation introuvable pour $membreId'),
      );

      final now = DateTime.now();
      final updated = cotisation.copyWith(
        statut: action.newStatut,
        montantPaye: action.newStatut == StatutCotisation.paye ? cotisation.montantObligatoire : 0.0,
        updatedAt: now,
      );
      updatedCotisations = updatedCotisations
          .map((c) => c.id == cotisation.id ? updated : c)
          .toList();
      await cache.saveCotisation(updated);
    }

    _state = previousState.copyWith(cotisations: updatedCotisations);

    final success = action.membreIds.length;
    final actionText = action.newStatut == StatutCotisation.paye ? 'payé(s)' : 'annulé(s)';
    notifCoordinator.notifierPaiementsEnMasseFull(success, actionText);
    unawaited(_notifierPush('cotisations_bulk', '$success paiement(s) $actionText', extra: action.newStatut.name));

    return (success: success, total: action.membreIds.length);
  }

  Future<void> _handleTogglePaiement(TogglePaiement action) async {
    final culte = _state.cultes.firstWhere(
      (c) => c.id == action.culteId,
      orElse: () => throw Exception('Culte introuvable'),
    );
    await dispatch(RegisterPayment(
      membreId: action.membreId,
      culteId: action.culteId,
      montant: culte.montantCotisation,
    ));
  }

  Future<void> _handlePaySeveralCultesInAdvance(PaySeveralCultesInAdvance action) async {
    final previousState = _state;
    if (action.culteIds.isEmpty) return;

    final now = DateTime.now();
    final deviceId = await deviceService.getDeviceId();
    final montantParCulte = (action.montantTotal / action.culteIds.length).roundToDouble();

    List<Cotisation> updatedCotisations = List.from(previousState.cotisations);

    for (final culteId in action.culteIds) {
      final culte = previousState.cultes.firstWhereOrNull(
        (c) => c.id == culteId && !c.isDeleted,
      );
      if (culte == null) continue;

      var existingCotisation = updatedCotisations.firstWhere(
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
      final updated = existingCotisation.copyWith(
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

    // Créditer le membre
    final membre = previousState.membres.firstWhere(
      (m) => m.id == action.membreId,
      orElse: () => throw Exception('Membre introuvable'),
    );
    final updatedMembre = Membre()
      ..id = membre.id
      ..nom = membre.nom
      ..prenom = membre.prenom
      ..dateAdhesion = membre.dateAdhesion
      ..dateNaissance = membre.dateNaissance
      ..montantEnAvance = membre.montantEnAvance + action.montantTotal
      ..totalDons = membre.totalDons
      ..telephone = membre.telephone
      ..notes = membre.notes
      ..isActive = membre.isActive
      ..deviceId = deviceId
      ..createdAt = membre.createdAt
      ..version = membre.version + 1
      ..updatedAt = now;

    _state = AppState(
      membres: updateMembreInList(_state.membres, action.membreId, updatedMembre),
      cultes: _state.cultes,
      cotisations: updatedCotisations,
      dashboard: _state.dashboard,
      isLoading: _state.isLoading,
      isOffline: _state.isOffline,
      error: null,
    );
    await cache.saveMembre(updatedMembre);
    await cache.saveAllCotisations(updatedCotisations);

    try {
      await api.consignerPaiementEnAvance(
        membreId: action.membreId,
        culteIds: action.culteIds,
        montantTotal: action.montantTotal,
      );
    } catch (e) {
      debugPrint('[KasedStore] payerPlusieursCultesEnAvance réseau échoué: $e');
    }

    notifCoordinator.notifierPaiementAvanceFull(action.montantTotal, membre.nomComplet);
    unawaited(_notifierPush('cotisation_en_avance', membre.nomComplet));
  }

  // ── Sync Handler ───────────────────────────────────────────────────────────

  Future<void> _handleSyncData() async {
    if (_state.isOffline || _isSyncing) return;
    _isSyncing = true;
    _state = _state.copyWith(isLoading: true);

    final result = await syncService.syncData(isOffline: _state.isOffline);
    _isSyncing = false;

    if (result == null) {
      _state = _state.copyWith(isLoading: false);
      return;
    }

    if (!result.success) {
      _state = _state.copyWith(isLoading: false, error: result.error);
      return;
    }

    _state = withFullData(
      _state,
      membres: result.mergedMembres,
      cultes: result.mergedCultes,
      cotisations: result.mergedCotisations,
    );
    _state = _state.copyWith(isLoading: false, error: null);
    NotificationCoordinator.planifierAnniversairesMembres(result.mergedMembres);
  }

  Future<void> _handleLoadDashboard() async {
    try {
      final dashboardData = await statsService.fetchDashboard(api);
      _state = _state.copyWith(dashboard: dashboardData);
    } catch (e) {
      debugPrint('[KasedStore] Erreur chargement dashboard: $e');
    }
  }

  // ── Corbeille Handlers ─────────────────────────────────────────────────────

  Future<void> _handlePermanentlyDelete(PermanentlyDelete action) async {
    await cache.deleteCorbeilleItem(action.isarId);
  }

  Future<void> _handleEmptyTrash() async {
    await cache.deleteAllCorbeilleItems();
    final membres = await cache.getAllMembres();
    final cultes = await cache.getAllCultes();
    final cotisations = await cache.getAllCotisations();
    _state = withFullData(_state, membres: membres, cultes: cultes, cotisations: cotisations);
  }

  // ── Query Handlers ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _handleGetHistorique(GetHistoriqueMembre action) async {
    try {
      return await api.getHistoriqueMembre(action.membreId);
    } catch (e) {
      debugPrint('[KasedStore] Erreur chargement historique: $e');
      return [];
    }
  }

  Future<List<Cotisation>> _handleGetCotisationsDuCulte(GetCotisationsDuCulte action) async {
    try {
      final data = await api.getCotisationsDuCulte(action.culteId);
      return data.map((json) => Cotisation.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[KasedStore] Erreur chargement cotisations: $e');
      return [];
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String? _nomMembre(AppState state, String? membreId) {
    if (membreId == null) return null;
    return state.membres
        .firstWhereOrNull((m) => m.id == membreId)?.nomComplet;
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  Future<void> _notifierPush(
    String event,
    String entityLabel, {
    String? extra,
  }) async {
    await PushNotifyService.notifier(
      event: event,
      entityLabel: entityLabel,
      actorEmail: null, // TODO: get from auth
      actorName: null,
      token: null,
      extra: extra,
    );
  }

  /// Recharge l'état complet depuis le cache local.
  Future<void> reloadFromCache() async {
    final membres = await cache.getAllMembres();
    final cultes = await cache.getAllCultes();
    final cotisations = await cache.getAllCotisations();
    _state = withFullData(_state, membres: membres, cultes: cultes, cotisations: cotisations);
  }
}
