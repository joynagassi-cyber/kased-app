import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/core/isar_local_cache.dart';
import 'package:kased_app/core/services/notification_coordinator.dart';
import 'package:kased_app/core/services/stats_service.dart';
import 'package:kased_app/core/services/sync_service.dart';
import 'package:kased_app/core/sync/device_service.dart';
import 'package:kased_app/core/utils/uuid.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/sync_operation.dart';
import 'package:kased_app/providers/isar_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_data_provider.g.dart';

class AppState {
  final List<Membre> membres;
  final List<Culte> cultes;
  final List<Cotisation> cotisations;
  final Map<String, dynamic>? dashboard;
  final bool isLoading;
  final bool isOffline;
  final String? error;

  AppState({
    this.membres = const [],
    this.cultes = const [],
    this.cotisations = const [],
    this.dashboard,
    this.isLoading = false,
    this.isOffline = false,
    this.error,
  });

  AppState copyWith({
    List<Membre>? membres,
    List<Culte>? cultes,
    List<Cotisation>? cotisations,
    Map<String, dynamic>? dashboard,
    bool? isLoading,
    bool? isOffline,
    String? error,
  }) {
    return AppState(
      membres: membres ?? this.membres,
      cultes: cultes ?? this.cultes,
      cotisations: cotisations ?? this.cotisations,
      dashboard: dashboard ?? this.dashboard,
      isLoading: isLoading ?? this.isLoading,
      isOffline: isOffline ?? this.isOffline,
      error: error,
    );
  }
}

@riverpod
class AppData extends _$AppData {
  late InsForgeService _api;
  late LocalCache _cache;
  late SyncService _syncService;
  late StatsService _statsService;
  StreamSubscription? _connectivitySubscription;

  @visibleForTesting
  set api(InsForgeService a) => _api = a;
  @visibleForTesting
  set cache(LocalCache c) => _cache = c;
  @visibleForTesting
  set syncService(SyncService s) => _syncService = s;
  @visibleForTesting
  set statsService(StatsService s) => _statsService = s;

  @override
  FutureOr<AppState> build() async {
    _api = ref.watch(insForgeServiceProvider);
    final isar = await ref.watch(isarProvider.future);
    _cache = IsarLocalCache(isar);
    _syncService = SyncService(_api, _cache);
    _statsService = StatsService();

    // Micro-délai artificiel de 150ms pour permettre au framework de
    // rendre l'état "loading" au démarrage local (Isar)
    await Future.delayed(const Duration(milliseconds: 150));

    // Surveiller la connectivité
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final isOffline = results.contains(ConnectivityResult.none);
      final current = state.value ?? AppState();
      state = AsyncValue.data(current.copyWith(isOffline: isOffline));
      if (!isOffline && _syncService.shouldSync()) {
        syncData();
      }
    });

    ref.onDispose(() {
      _connectivitySubscription?.cancel();
    });

    // Charger d'abord les données locales
    final localMembres = await _cache.getAllMembres();
    final localCultes = await _cache.getAllCultes();
    final localCotisations = await _cache.getAllCotisations();

    // Purger la corbeille locale (éléments de plus de 30 jours)
    final limitePurge = DateTime.now().subtract(const Duration(days: 30));
    await _cache.purgeOldCorbeilleItems(limitePurge);

    // Planifier les notifications d'anniversaire
    NotificationCoordinator.planifierAnniversairesMembres(localMembres);

    final initialState = AppState(
      membres: localMembres,
      cultes: localCultes,
      cotisations: localCotisations,
    );

    // Sync automatique différée de 3 secondes après le chargement
    Future.delayed(const Duration(seconds: 3), () {
      if (_syncService.shouldSync()) syncData();
    });

    return initialState;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SYNC
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> syncData() async {
    if (state.value?.isOffline ?? true) return;

    final current = state.value ?? AppState();
    state = AsyncValue.data(current.copyWith(isLoading: true));

    final result = await _syncService.syncData(
      isOffline: state.value?.isOffline ?? true,
    );

    if (result == null) {
      // Sync déjà en cours ou offline → on remet juste isLoading à false
      state = AsyncValue.data(
          (state.value ?? AppState()).copyWith(isLoading: false));
      return;
    }

    if (!result.success) {
      state = AsyncValue.data((state.value ?? AppState())
          .copyWith(isLoading: false, error: result.error));
      return;
    }

    state = AsyncValue.data((state.value ?? AppState()).copyWith(
      membres: result.mergedMembres,
      cultes: result.mergedCultes,
      cotisations: result.mergedCotisations,
      dashboard: result.dashboard,
      isLoading: false,
      error: null,
    ));

    // Planifier les notifications anniversaires pour les membres mergés
    NotificationCoordinator.planifierAnniversairesMembres(result.mergedMembres);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DASHBOARD / STATS (délégation à StatsService)
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> loadDashboard() async {
    try {
      final dashboardData = await _statsService.fetchDashboard(_api);
      final current = state.value ?? AppState();
      state = AsyncValue.data(current.copyWith(dashboard: dashboardData));
    } catch (e) {
      debugPrint('Erreur chargement dashboard: $e');
    }
  }

  Future<List<Map<String, dynamic>>> loadRetardsMembres() async {
    return _statsService.loadRetardsMembres(_api);
  }

  Future<List<Map<String, dynamic>>> loadMembresAJour() async {
    return _statsService.loadMembresAJour(_api);
  }

  DashboardStats getDashboardStats() {
    final stateValue = state.value;
    if (stateValue == null) {
      return DashboardStats(
        totalMembres: 0,
        totalCultes: 0,
        totalCollecte: 0,
        membresEnRetard: 0,
        totalDu: 0,
      );
    }
    return _statsService.getDashboardStats(stateValue);
  }

  List<Map<String, dynamic>> getRetardsMembresLocally() {
    final stateValue = state.value;
    if (stateValue == null) return [];
    return _statsService.getRetardsMembresLocally(stateValue);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // MEMBRES
  // ──────────────────────────────────────────────────────────────────────────

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

    final current = state.value ?? AppState();
    state = AsyncValue.data(current.copyWith(
      membres: [...current.membres, newMembre]
        ..sort((a, b) => a.nom.compareTo(b.nom)),
    ));

    // Notification anniversaire et création
    NotificationCoordinator.planifierAnniversaireMembre(newMembre);
    NotificationCoordinator.notifierCreationMembre(newMembre);

    await loadDashboard();

    // 2. Tentative de synchronisation réseau
    try {
      await _api.createMembre(newMembre.toJson());
    } catch (e) {
      debugPrint('[AppData] addMembre réseau échoué, mise en file: $e');
      await _syncService.queueSyncOperation(
          'CREATE', 'membre', newId, newMembre.toJson());
    }

    return newMembre;
  }

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
    final current = state.value;
    if (current == null) return;

    final existing = current.membres.firstWhere((m) => m.id == id);
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

    final membres = [
      ...current.membres.where((m) => m.id != id),
      updated,
    ]..sort((a, b) => a.nom.compareTo(b.nom));

    state = AsyncValue.data(current.copyWith(membres: membres));

    // Notifications anniversaire
    if (updated.dateNaissance != null) {
      NotificationCoordinator.planifierAnniversaireMembre(updated);
    } else {
      NotificationCoordinator.annulerAnniversaireMembre(id);
    }

    // 2. Réseau
    try {
      await _api.updateMembre(id, updated.toJson());
    } catch (e) {
      debugPrint('[AppData] updateMembre réseau échoué: $e');
      await _syncService.queueSyncOperation(
          'UPDATE', 'membre', id, updated.toJson());
    }
  }

  Future<void> deleteMembre(String id) async {
    final current = state.value;
    if (current == null) return;
    try {
      final existing = current.membres.firstWhere((m) => m.id == id);
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

      await _cache.softDeleteMembreWithSyncOp(existing, syncOp);

      NotificationCoordinator.annulerAnniversaireMembre(id);

      state = AsyncValue.data(current.copyWith(
        membres: current.membres.where((m) => m.id != id).toList(),
        cotisations: current.cotisations.where((c) => c.membreId != id).toList(),
      ));

      await loadDashboard();

      try {
        await _api.deleteMembre(id);
      } catch (e) {
        debugPrint('[AppData] deleteMembre réseau échoué: $e');
        await _syncService.queueSyncOperation('DELETE', 'membre', id, {});
      }
    } catch (e) {
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CULTES
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> addCulte({
    required DateTime date,
    String? titre,
    required double montant,
  }) async {
    final culteId = UuidUtils.generate();
    final deviceId = await DeviceService.getDeviceId();
    final now = DateTime.now();
    final newCulte = Culte()
      ..id = culteId
      ..dateCulte = date
      ..titre = titre
      ..montantCotisation = montant
      ..deviceId = deviceId
      ..createdAt = now
      ..updatedAt = now;

    final activeMembres =
        state.value?.membres.where((m) => m.isActive).toList() ?? [];
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

    final current = state.value ?? AppState();
    state = AsyncValue.data(current.copyWith(
      cultes: [newCulte, ...current.cultes]
        ..sort((a, b) => b.dateCulte.compareTo(a.dateCulte)),
      cotisations: [...current.cotisations, ...localCotisations],
    ));

    NotificationCoordinator.notifierCreationCulte(newCulte);

    await loadDashboard();

    // 2. Réseau
    try {
      await _api.createCulte(newCulte.toJson());
    } catch (e) {
      debugPrint(
          '[AppData] addCulte réseau échoué, mise en file déjà effectuee: $e');
    }
  }

  Future<void> updateCulte({
    required String id,
    DateTime? dateCulte,
    String? titre,
    double? montantCotisation,
    String? notes,
  }) async {
    final current = state.value;
    if (current == null) return;

    final existing = current.cultes.firstWhere((c) => c.id == id);
    final updated = Culte()
      ..id = existing.id
      ..dateCulte = dateCulte ?? existing.dateCulte
      ..titre = titre ?? existing.titre
      ..montantCotisation = montantCotisation ?? existing.montantCotisation
      ..notes = notes ?? existing.notes
      ..updatedAt = DateTime.now();

    // Mise à jour optimiste des cotisations liées si le montant a changé
    List<Cotisation> updatedCotisations = current.cotisations;
    if (montantCotisation != null &&
        montantCotisation != existing.montantCotisation) {
      updatedCotisations = current.cotisations.map((c) {
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

    final cultes = [
      ...current.cultes.where((c) => c.id != id),
      updated,
    ]..sort((a, b) => b.dateCulte.compareTo(a.dateCulte));

    state = AsyncValue.data(
        current.copyWith(cultes: cultes, cotisations: updatedCotisations));

    await loadDashboard();

    // 2. Réseau
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
      debugPrint('[AppData] updateCulte réseau échoué: $e');
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

  Future<void> deleteCulte(String id) async {
    final current = state.value;
    if (current == null) return;
    try {
      final existingList = current.cultes.where((c) => c.id == id);
      if (existingList.isNotEmpty &&
          DateTime.now().difference(existingList.first.dateCulte).inDays >
              30) {
        throw Exception(
            "Impossible de supprimer un culte de plus de 30 jours.");
      }
      final existing = existingList.isNotEmpty
          ? existingList.first
          : current.cultes.firstWhere((c) => c.id == id);
      final deviceId = await DeviceService.getDeviceId();
      final now = DateTime.now();

      // Soft delete
      existing.isDeleted = true;
      existing.deletedAt = now;
      existing.deletedBy = deviceId;
      existing.version++;

      // Soft delete des cotisations liées
      final cotisations =
          current.cotisations.where((c) => c.culteId == id).toList();
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

      await _cache.softDeleteCulteWithSyncOp(existing, cotisations, syncOp);

      state = AsyncValue.data(current.copyWith(
        cultes: current.cultes.where((c) => c.id != id).toList(),
        cotisations:
            current.cotisations.where((c) => c.culteId != id).toList(),
      ));

      await loadDashboard();

      // 2. Réseau
      try {
        await _api.deleteCulte(id);
      } catch (e) {
        debugPrint('[AppData] deleteCulte réseau échoué: $e');
        await _syncService.queueSyncOperation('DELETE', 'culte', id, {});
      }
    } catch (e) {
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // COTISATIONS
  // ──────────────────────────────────────────────────────────────────────────

  Future<List<Cotisation>> getCotisationsDuCulte(String culteId) async {
    try {
      final data = await _api.getCotisationsDuCulte(culteId);
      return data.map((json) => Cotisation.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Erreur chargement cotisations: $e');
      return [];
    }
  }

  Future<void> enregistrerPaiementPersonnel({
    required String membreId,
    required String culteId,
    required double montant,
  }) async {
    final previousState = state.value;
    if (previousState == null) return;

    final cultes = previousState.cultes.where((c) => c.id == culteId);
    if (cultes.isEmpty) {
      throw Exception('Culte introuvable');
    }
    final culte = cultes.first;
    final isOlderThan30Days =
        DateTime.now().difference(culte.dateCulte).inDays > 30;

    // Chercher une cotisation existante, ou en créer une nouvelle
    var existingCotisation = previousState.cotisations.firstWhereOrNull(
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

    // Vérification du verrouillage après 30 jours (si déjà payé)
    if (isOlderThan30Days && existingCotisation.estPaye) {
      throw Exception("Le paiement est verrouillé après 30 jours.");
    }

    // Validation : le montant doit être au moins égal au montant obligatoire
    if (montant < existingCotisation.montantObligatoire) {
      throw Exception(
          'Le montant payé doit être au moins égal au montant obligatoire (${existingCotisation.montantObligatoire}F)');
    }

    // Calcul du don (excédent)
    final montantDon = montant - existingCotisation.montantObligatoire;

    // Mise à jour de la cotisation
    final updatedCotisation = existingCotisation.copyWith(
      montantPaye: montant,
      montantDon: montantDon,
      statut: montant >= existingCotisation.montantObligatoire
          ? StatutCotisation.paye
          : StatutCotisation.nonPaye,
      datePaiement: montant >= existingCotisation.montantObligatoire
          ? DateTime.now()
          : null,
      updatedAt: DateTime.now(),
    );

    // Mise à jour optimiste immédiate
    final updatedCotisations = isNewCotisation
        ? [...previousState.cotisations, updatedCotisation]
        : previousState.cotisations
            .map((c) {
              if (c.membreId == membreId && c.culteId == culteId) {
                return updatedCotisation;
              }
              return c;
            })
            .toList();

    state = AsyncValue.data(
        previousState.copyWith(cotisations: updatedCotisations));

    // Persister immédiatement dans Isar
    await _cache.saveCotisation(updatedCotisation);

    // Notification de don
    if (montantDon > 0) {
      NotificationCoordinator.notifierDonEnregistre(montantDon, membreId);
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
          '[AppData] enregistrerPaiementPersonnel réseau échoué, état local conservé: $e');
      await _syncService.queueSyncOperation(
          'UPDATE', 'cotisation', updatedCotisation.id,
          updatedCotisation.toJson());
    }
  }

  /// Garde la fonction togglePaiement pour compatibilité arrière.
  Future<void> togglePaiement({
    required String membreId,
    required String culteId,
  }) async {
    final previousState = state.value;
    if (previousState == null) return;

    final culte =
        previousState.cultes.firstWhereOrNull((c) => c.id == culteId);
    if (culte == null) return;

    await enregistrerPaiementPersonnel(
      membreId: membreId,
      culteId: culteId,
      montant: culte.montantCotisation,
    );
  }

  /// Met à jour le statut de TOUTES les cotisations d'un culte.
  Future<({int success, int total})> bulkSetPaiements({
    required String culteId,
    required StatutCotisation newStatut,
    required List<String> membreIds,
  }) async {
    final previousState = state.value;
    if (previousState == null) return (success: 0, total: 0);

    // Mise à jour optimiste immédiate (UI répond instantanément)
    final updatedCotisations = previousState.cotisations.map((c) {
      if (c.culteId == culteId && membreIds.contains(c.membreId)) {
        double montantPaye = 0.0;
        double montantDon = 0.0;
        DateTime? datePaiement;
        if (newStatut == StatutCotisation.paye ||
            newStatut == StatutCotisation.enAvance) {
          final culte =
              previousState.cultes.firstWhereOrNull((c) => c.id == culteId);
          final montantObligatoire = culte?.montantCotisation ?? 50.0;
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

    state = AsyncValue.data(
        previousState.copyWith(cotisations: updatedCotisations));

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
              await _syncService.queueSyncOperation(
                  'UPDATE', 'cotisation', cotisationToUpdate.id,
                  cotisationToUpdate.toJson());
              return false;
            }
          }),
        );
        success += results.where((r) => r).length;
      }
    } catch (e) {
      debugPrint(
          '[AppData] bulkSetPaiements réseau échoué, état local conservé: $e');
    }

    // Notification de mise à jour des paiements
    final actionText =
        newStatut == StatutCotisation.paye ? 'payé(s)' : 'annulé(s)';
    NotificationCoordinator.notifierPaiementsEnMasse(success, actionText);

    return (success: success, total: membreIds.length);
  }

  Future<void> marquerAbsent({
    required String membreId,
    required String culteId,
  }) async {
    final previousState = state.value;
    if (previousState == null) return;

    final cultes = previousState.cultes.where((c) => c.id == culteId);
    final isOlderThan30Days = cultes.isNotEmpty &&
        DateTime.now().difference(cultes.first.dateCulte).inDays > 30;

    var existingCotisation = previousState.cotisations.firstWhereOrNull(
      (c) => c.membreId == membreId && c.culteId == culteId,
    );

    final bool isNewCotisation = existingCotisation == null;
    if (isNewCotisation) {
      existingCotisation = Cotisation()
        ..id = UuidUtils.generate()
        ..membreId = membreId
        ..culteId = culteId
        ..montantObligatoire =
            cultes.isNotEmpty ? cultes.first.montantCotisation : 50.0
        ..montantPaye = 0.0
        ..montantDon = 0.0
        ..statut = StatutCotisation.nonPaye;
    }

    if (isOlderThan30Days && existingCotisation.estPaye) {
      throw Exception(
          "Impossible de marquer absent un membre ayant déjà payé pour un culte verrouillé.");
    }

    final updatedCotisation = existingCotisation.copyWith(
      statut: StatutCotisation.absent,
      montantPaye: 0.0,
      montantDon: 0.0,
      id: existingCotisation.id,
      updatedAt: DateTime.now(),
    );

    final updatedCotisations = isNewCotisation
        ? [...previousState.cotisations, updatedCotisation]
        : previousState.cotisations
            .map((c) {
              if (c.membreId == membreId && c.culteId == culteId) {
                return updatedCotisation;
              }
              return c;
            })
            .toList();

    state = AsyncValue.data(
        previousState.copyWith(cotisations: updatedCotisations));

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
          '[AppData] marquerAbsent réseau échoué, état local conservé: $e');
      await _syncService.queueSyncOperation(
          'UPDATE', 'cotisation', updatedCotisation.id,
          updatedCotisation.toJson());
    }
  }

  Future<List<Map<String, dynamic>>> getHistoriqueMembre(
      String membreId) async {
    try {
      return await _api.getHistoriqueMembre(membreId);
    } catch (e) {
      return [];
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CORBEILLE
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> restaurerElement(int isarId) async {
    final item = await _cache.getCorbeilleItem(isarId);
    if (item == null) return;

    final payload = jsonDecode(item.payloadJson);

    if (item.entityType == 'membre') {
      final membre = Membre.fromJson(payload);
      membre.isActive = true;

      await _cache.restoreMembreAndDeleteCorbeilleItem(membre, isarId);

      try {
        await _api.updateMembre(membre.id, {'is_active': true});
      } catch (e) {
        debugPrint(
            '[AppData] restaurerElement membre réseau échoué, mis en file: $e');
        await _syncService.queueSyncOperation(
            'UPDATE', 'membre', membre.id, {'is_active': true});
      }
    } else if (item.entityType == 'culte') {
      final culte = Culte.fromJson(payload);

      await _cache.restoreCulteAndDeleteCorbeilleItem(culte, isarId);

      try {
        await _api.createCulte(culte.toJson());
      } catch (e) {
        debugPrint(
            '[AppData] restaurerElement culte réseau échoué, mis en file: $e');
        await _syncService.queueSyncOperation(
            'CREATE', 'culte', culte.id, culte.toJson());
      }
    }

    // Recharger l'état local sans appel réseau destructif
    final membres = await _cache.getAllMembres();
    final cultes = await _cache.getAllCultes();
    final cotisations = await _cache.getAllCotisations();
    state = AsyncValue.data((state.value ?? AppState()).copyWith(
      membres: membres,
      cultes: cultes,
      cotisations: cotisations,
    ));
  }

  Future<void> supprimerDefinitivement(int isarId) async {
    await _cache.deleteCorbeilleItem(isarId);
  }

  Future<void> viderCorbeille() async {
    await _cache.deleteAllCorbeilleItems();
  }
}
