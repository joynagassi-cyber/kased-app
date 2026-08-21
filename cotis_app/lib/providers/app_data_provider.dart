import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:kased_app/core/logic/cotisation_logic.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/core/isar_local_cache.dart';
import 'package:kased_app/core/realtime/realtime_service.dart';
import 'package:kased_app/core/services/notification_coordinator.dart';
import 'notifications_provider.dart';
import 'package:kased_app/core/services/push_notify_service.dart';
import 'package:kased_app/core/services/stats_service.dart';
import 'package:kased_app/core/services/sync_service.dart';
import 'package:kased_app/core/sync/device_service_port.dart';
import 'package:kased_app/core/utils/uuid.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/sync_operation.dart';
import 'package:kased_app/models/corbeille_item.dart';
import 'package:kased_app/providers/auth_provider.dart';
import 'package:kased_app/providers/isar_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';


import 'package:kased_app/controllers/membre_controller.dart';
import 'package:kased_app/controllers/culte_controller.dart';
import 'package:kased_app/controllers/cotisation_controller.dart';
import 'package:kased_app/controllers/system_controller.dart';
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
  late RealtimeService _realtimeService;
  late MembreController _membreController;
  late CulteController _culteController;
  late CotisationController _cotisationController;
  late SystemController _systemController;
  late DeviceServicePort _deviceServicePort;
  late NotificationCoordinator _notifCoordinator;
  StreamSubscription? _connectivitySubscription;

  @visibleForTesting
  set api(InsForgeService a) => _api = a;
  @visibleForTesting
  set cache(LocalCache c) => _cache = c;
  @visibleForTesting
  set syncService(SyncService s) => _syncService = s;
  @visibleForTesting
  set statsService(StatsService s) => _statsService = s;
  @visibleForTesting
  set deviceServicePort(DeviceServicePort d) => _deviceServicePort = d;

  @visibleForTesting
  set membreController(MembreController c) => _membreController = c;
  @visibleForTesting
  set culteController(CulteController c) => _culteController = c;
  @visibleForTesting
  set cotisationController(CotisationController c) => _cotisationController = c;
  @visibleForTesting
  set systemController(SystemController c) => _systemController = c;

  @override
  FutureOr<AppState> build() async {
    _api = ref.watch(insForgeServiceProvider);
    final isar = await ref.watch(isarProvider.future);
    _cache = IsarLocalCache(isar);
    _deviceServicePort = RealDeviceService();
    _syncService = SyncService(_api, _cache);
    _statsService = StatsService();
    _realtimeService = RealtimeService();

    // Notification coordinator — connect system + in-app notifications
    _notifCoordinator = NotificationCoordinator(
      onInAppNotify: ({required titre, required message, required typeEvenement, entiteId}) {
        ref.read(notificationsProvider.notifier).ajouter(
          titre: titre,
          message: message,
          typeEvenement: typeEvenement,
          entiteId: entiteId,
        );
      },
    );

    // Initialize controllers
    _membreController = MembreController(
      cache: _cache,
      api: _api,
      syncService: _syncService,
      deviceService: _deviceServicePort,
      onStateChanged: (appState) => state = AsyncValue.data(appState),
    );
    _culteController = CulteController(
      cache: _cache,
      api: _api,
      syncService: _syncService,
      deviceService: _deviceServicePort,
      onStateChanged: (appState) => state = AsyncValue.data(appState),
    );
    _cotisationController = CotisationController(
      cache: _cache,
      api: _api,
      deviceService: _deviceServicePort,
      onStateChanged: (appState) => state = AsyncValue.data(appState),
    );
    _systemController = SystemController(
      cache: _cache,
      api: _api,
      syncService: _syncService,
      statsService: _statsService,
      onStateChanged: (appState) => state = AsyncValue.data(appState),
    );

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

    // Écouter les événements temps réel → forcer un rechargement
    _realtimeService.addListener((event) {
      if (state.value?.isOffline != true) {
        debugPrint('[AppData] Événement realtime reçu → rechargement (${event.table}: ${event.action})');
        syncData();
      }
    });

    ref.onDispose(() {
      _connectivitySubscription?.cancel();
      _realtimeService.removeListener((event) {});
      _realtimeService.disconnect();
    });

    // S'abonner aux changements d'auth pour connecter/déconnecter le realtime
    ref.listen(authProvider, (previous, next) {
      if (next.isAuthenticated && next.token != null && next.userEmail != null) {
        debugPrint('[AppData] Auth connecté, initialization du realtime');
        _realtimeService.connect(
          token: next.token!,
          email: next.userEmail!,
        );
      } else if (!next.isAuthenticated) {
        debugPrint('[AppData] Auth déconnecté, déconnexion du realtime');
        _realtimeService.disconnect();
      }
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

    // Charger les notifications depuis Isar
    return initialState;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // NOTIFICATIONS PUSH MULTI-UTILISATEURS (OneSignal)
  // ──────────────────────────────────────────────────────────────────────────

  /// Envoie une notification push aux AUTRES utilisateurs (jamais à soi-même,
  /// la fonction serveur exclut l'acteur). Non bloquant : un échec d'envoi
  /// n'interrompt jamais l'action en cours.
  Future<void> _notifierPush(
    String event,
    String entityLabel, {
    String? extra,
  }) async {
    final auth = ref.read(authProvider);
    await PushNotifyService.notifier(
      event: event,
      entityLabel: entityLabel,
      actorEmail: auth.userEmail,
      actorName: auth.userName,
      token: auth.token,
      extra: extra,
    );
  }

  String? _nomMembre(String? membreId) {
    if (membreId == null) return null;
    return state.value?.membres
        .firstWhereOrNull((m) => m.id == membreId)?.nomComplet;
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

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
        membresEnAvance: 0,
        montantEnAvance: 0.0,
      );
    }
    return _statsService.getDashboardStats(stateValue);
  }

  /// Charge l'objectif mensuel et le retourne.
  Future<double> getObjectifMensuel() => StatsService.loadObjectifMensuel();

  /// Met à jour l'objectif mensuel et retourne le nouveau DashboardStats.
  Future<DashboardStats> updateObjectifMensuel(double montant) async {
    await StatsService.saveObjectifMensuel(montant);
    return getDashboardStats();
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
    final newMembre = await _membreController.addMembre(
      nom: nom,
      prenom: prenom,
      dateAdhesion: dateAdhesion,
      dateNaissance: dateNaissance,
      telephone: telephone,
      notes: notes,
    );

    // Generate initial cotisations for future cultes
    await _cotisationController.generateInitialCotisationsForMembre(newMembre);

    // Update state with new membre
    final current = state.value ?? AppState();
    state = AsyncValue.data(current.copyWith(
      membres: [...current.membres, newMembre]
        ..sort((a, b) => a.nom.compareTo(b.nom)),
    ));

    NotificationCoordinator.planifierAnniversaireMembre(newMembre);
    _notifCoordinator.notifierCreationMembreFull(newMembre);
    await loadDashboard();
    unawaited(_notifierPush('membre_ajoute', newMembre.nomComplet));

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
    await _membreController.updateMembre(
      id: id,
      nom: nom,
      prenom: prenom,
      dateAdhesion: dateAdhesion,
      dateNaissance: dateNaissance,
      telephone: telephone,
      notes: notes,
      isActive: isActive,
    );

    // Update state
    final current = state.value;
    if (current == null) return;

    final membres = current.membres;
    final existing = membres.firstWhere((m) => m.id == id, orElse: () => throw Exception('Membre introuvable: $id'));
    final updated = Membre()
      ..id = existing.id
      ..nom = nom ?? existing.nom
      ..prenom = prenom ?? existing.prenom
      ..dateAdhesion = dateAdhesion ?? existing.dateAdhesion
      ..dateNaissance = dateNaissance ?? existing.dateNaissance
      ..telephone = telephone ?? existing.telephone
      ..notes = notes ?? existing.notes
      ..isActive = isActive ?? existing.isActive
      ..deviceId = existing.deviceId
      ..createdAt = existing.createdAt
      ..version = existing.version + 1
      ..updatedAt = DateTime.now();

    final sortedMembres = [...membres.where((m) => m.id != id), updated]
      ..sort((a, b) => a.nom.compareTo(b.nom));
    state = AsyncValue.data(current.copyWith(membres: sortedMembres));

    if (updated.dateNaissance != null) {
      NotificationCoordinator.planifierAnniversaireMembre(updated);
    } else {
      NotificationCoordinator.annulerAnniversaireMembre(id);
    }
    unawaited(_notifierPush('membre_modifie', updated.nomComplet));
  }

  /// Ajoute un paiement par avance pour un membre.
  /// Le montant est ajouté au solde en avance du membre.
  /// Ce solde sera consommé automatiquement lors des prochains cultes.
  Future<void> ajouterPaiementAvance({
    required String membreId,
    required double montant,
    String? notes,
  }) async {
    final current = state.value;
    if (current == null) return;

    final existing = current.membres.firstWhere(
      (m) => m.id == membreId,
      orElse: () => throw Exception('Membre introuvable'),
    );
    final deviceId = await _deviceServicePort.getDeviceId();
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

    final membres = [
      ...current.membres.where((m) => m.id != membreId),
      updated,
    ]..sort((a, b) => a.nom.compareTo(b.nom));

    state = AsyncValue.data(current.copyWith(membres: membres));

    // 2. Réseau
    try {
      await _api.updateMembre(membreId, updated.toJson());
      // Succès réseau : supprimer l'opération sync (déjà appliquée)
      await _cache.deleteSyncOp(syncOp.isarId);
    } catch (e) {
      debugPrint('[AppData] ajouterPaiementAvance réseau échoué: $e');
      await _syncService.queueSyncOperation(
          'UPDATE', 'membre', membreId, updated.toJson());
    }
    
    // Notification
    _notifCoordinator.notifierPaiementAvanceFull(montant, updated.nomComplet);
  }

  Future<void> deleteMembre(String id) async {
    await _membreController.deleteMembre(id);

    // Update state
    final current = state.value;
    if (current == null) return;

    state = AsyncValue.data(current.copyWith(
      membres: current.membres.where((m) => m.id != id).toList(),
    ));

    await loadDashboard();
    unawaited(_notifierPush('membre_supprime', id));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CULTES
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> addCulte({
    required DateTime date,
    String? titre,
    required double montant,
  }) async {
    final newCulte = await _culteController.addCulte(
      date: date,
      titre: titre,
      montant: montant,
    );

    // Update state
    final current = state.value ?? AppState();
    // Reload cotisations from cache since controller may have created new ones
    final newCotisations = await _cache.getAllCotisations();
    final mergedCotisations = [...current.cotisations];
    for (final c in newCotisations) {
      if (!mergedCotisations.any((existing) => existing.id == c.id)) {
        mergedCotisations.add(c);
      }
    }
    // Reload membres from cache since controller may have deducted avance
    final updatedMembres = await _cache.getAllMembres();
    state = AsyncValue.data(current.copyWith(
      cultes: [newCulte, ...current.cultes]
        ..sort((a, b) => b.dateCulte.compareTo(a.dateCulte)),
      cotisations: mergedCotisations,
      membres: updatedMembres,
    ));

    _notifCoordinator.notifierCreationCulteFull(newCulte);
    await loadDashboard();
    unawaited(_notifierPush('culte_cree', _formatDate(newCulte.dateCulte)));
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

    final existing = current.cultes.firstWhere((c) => c.id == id, orElse: () => throw Exception('Culte introuvable: $id'));

    // Verrouillage à 30 jours : interdit de modifier un culte passé
    final isOlderThan30Days =
        DateTime.now().difference(existing.dateCulte).inDays > 30;
    if (isOlderThan30Days) {
      throw Exception(
          "Impossible de modifier un culte dont la date remonte à plus de 30 jours.");
    }

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
          : current.cultes.firstWhere((c) => c.id == id, orElse: () => throw Exception('Culte introuvable'));
      final deviceId = await _deviceServicePort.getDeviceId();
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

      // Sauvegarder dans la corbeille
      final culteCorbeilleItem = CorbeilleItem()
        ..entityId = id
        ..entityType = 'culte'
        ..payloadJson = jsonEncode(existing.toJson())
        ..deletedAt = now
        ..updatedAt = existing.updatedAt;
      await _cache.saveCorbeilleItem(culteCorbeilleItem);

      await _cache.softDeleteCulteWithSyncOp(existing, cotisations, syncOp);

      state = AsyncValue.data(current.copyWith(
        cultes: current.cultes.where((c) => c.id != id).toList(),
        // Cotisations are KEPT — historical payment data must be preserved
        // cotisations: current.cotisations.where((c) => c.culteId != id).toList(),
      ));

      await loadDashboard();

      // 2. Réseau
      try {
        await _api.deleteCulte(id);
        // Succès réseau : supprimer l'opération sync (déjà appliquée)
        await _cache.deleteSyncOp(syncOp.isarId);
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

    // Détermination du statut : enAvance si paiement avant le culte, paye sinon
    final datePaiement = DateTime.now();
    final statut = CotisationLogic.determinerStatut(
      datePaiement: datePaiement,
      dateCulte: culte.dateCulte,
    );

    // Mise à jour de la cotisation
    final updatedCotisation = existingCotisation.copyWith(
      montantPaye: montant,
      montantDon: montantDon,
      statut: statut,
      datePaiement: montant >= existingCotisation.montantObligatoire
          ? datePaiement
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

    // Consommer l'avance du membre si paiement complet (pas de don)
    if (montantDon == 0) {
      final membre = previousState.membres.firstWhereOrNull(
        (m) => m.id == membreId,
      );
      if (membre != null && membre.montantEnAvance >= montant) {
        // Le membre a assez d'avance → consommer
        final deviceId = await _deviceServicePort.getDeviceId();
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
        final updatedMembres = [
          ...state.value!.membres.where((m) => m.id != membreId),
          updatedMembre,
        ]..sort((a, b) => a.nom.compareTo(b.nom));
        state = AsyncValue.data(state.value!.copyWith(membres: updatedMembres));
        // Synchroniser l'avance consommée
        try {
          await _api.consommerAvancePourCulte(
            membreId: membreId,
            culteId: culteId,
          );
          await _cache.deleteSyncOp(syncOp.isarId);
        } catch (e) {
          debugPrint('[AppData] consommerAvance réseau échoué: $e');
        }
      }
    }

    // Mettre à jour le total des dons du membre si un don a été enregistré
    if (montantDon > 0) {
      final currentAfterCot = state.value ?? previousState;
      final membreWithDon = currentAfterCot.membres.firstWhereOrNull(
        (m) => m.id == membreId,
      );
      if (membreWithDon != null && membreWithDon.totalDons < montantDon) {
        // Le membre n'a pas encore ce don comptabilisé — ajouter la différence
        final deviceId = await _deviceServicePort.getDeviceId();
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
        final updatedMembres = [
          ...currentAfterCot.membres.where((m) => m.id != membreId),
          updatedMembre,
        ]..sort((a, b) => a.nom.compareTo(b.nom));
        state = AsyncValue.data(currentAfterCot.copyWith(membres: updatedMembres));
      }
      final membreNom = membreWithDon?.nomComplet ?? membreId;
      _notifCoordinator.notifierDonEnregistreFull(montantDon, membreNom);
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

    // Notification push aux autres utilisateurs (non bloquant)
    final nomMembrePaye = _nomMembre(membreId);
    final labelCulte = 'culte du ${_formatDate(culte.dateCulte)}';
    unawaited(_notifierPush(
      updatedCotisation.statut == StatutCotisation.paye
          ? 'cotisation_payee'
          : 'cotisation_modifiee',
      nomMembrePaye != null ? '$nomMembrePaye — $labelCulte' : labelCulte,
      extra: montant.toStringAsFixed(0),
    ));
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
    _notifCoordinator.notifierPaiementsEnMasseFull(success, actionText);

    // Notification push aux autres utilisateurs (non bloquant)
    unawaited(_notifierPush(
      'cotisations_bulk',
      '$success paiement(s) $actionText',
      extra: newStatut.name,
    ));

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

    // Notification push aux autres utilisateurs (non bloquant)
    unawaited(_notifierPush(
      'cotisation_absente',
      _nomMembre(membreId) ?? 'un membre',
    ));
  }

  /// Paye plusieurs cultes en avance pour un membre en un seul geste.
  ///
  /// Crée automatiquement une cotisation `enAvance` pour chaque culte
  /// sélectionné, avec le montant proportionnel.
  Future<void> payerPlusieursCultesEnAvance({
    required String membreId,
    required List<String> culteIds,
    required double montantTotal,
  }) async {
    final previousState = state.value;
    if (previousState == null || culteIds.isEmpty) return;

    final now = DateTime.now();
    final deviceId = await _deviceServicePort.getDeviceId();
    final montantParCulte = (montantTotal / culteIds.length).roundToDouble();

    final updatedCotisations = List<Cotisation>.from(previousState.cotisations);
    final syncOps = <SyncOperation>[];

    for (final culteId in culteIds) {
      final culte = previousState.cultes.firstWhereOrNull(
        (c) => c.id == culteId && !c.isDeleted,
      );
      if (culte == null) continue;

      var existingCotisation = updatedCotisations.firstWhereOrNull(
        (c) => c.membreId == membreId && c.culteId == culteId,
      );

      final isNewCotisation = existingCotisation == null;
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

      // Déterminer le statut : enAvance si culte futur
      final statut = CotisationLogic.determinerStatut(
        datePaiement: now,
        dateCulte: culte.dateCulte,
      );

      final montantPartiel = montantParCulte;
      final updated = existingCotisation.copyWith(
        montantPaye: montantPartiel,
        montantDon: 0.0,
        statut: statut,
        datePaiement: now,
        updatedAt: now,
      );

      if (isNewCotisation) {
        updatedCotisations.add(updated);
      } else {
        final index = updatedCotisations.indexWhere(
          (c) => c.id == updated.id,
        );
        if (index != -1) {
          updatedCotisations[index] = updated;
        }
      }

      // Créer l'opération de sync
      final syncOp = SyncOperation()
        ..operationId = UuidUtils.generate()
        ..type = isNewCotisation ? 'CREATE' : 'UPDATE'
        ..entityType = 'cotisation'
        ..entityId = updated.id
        ..payloadJson = jsonEncode(updated.toJson())
        ..createdAt = now
        ..deviceId = deviceId;
      syncOps.add(syncOp);
    }

    // Mettre à jour l'état
    state = AsyncValue.data(previousState.copyWith(
      cotisations: updatedCotisations,
    ));

    // Créditer le membre : ajouter le montant total à son avance
    final membre = previousState.membres.firstWhereOrNull(
      (m) => m.id == membreId,
    );
    if (membre != null) {
      final deviceId = await _deviceServicePort.getDeviceId();
      final now = DateTime.now();
      final updatedMembre = Membre()
        ..id = membre.id
        ..nom = membre.nom
        ..prenom = membre.prenom
        ..dateAdhesion = membre.dateAdhesion
        ..dateNaissance = membre.dateNaissance
        ..montantEnAvance = membre.montantEnAvance + montantTotal
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
      final updatedMembres = [
        ...previousState.membres.where((m) => m.id != membreId),
        updatedMembre,
      ]..sort((a, b) => a.nom.compareTo(b.nom));
      state = AsyncValue.data(state.value!.copyWith(membres: updatedMembres));
    }

    // Sauvegarder localement
    await _cache.saveAllCotisations(updatedCotisations);
    for (final op in syncOps) {
      await _cache.saveSyncOp(op);
    }

    // Synchroniser avec le serveur (RPC qui gère tout : crédit + cotisations)
    try {
      await _api.consignerPaiementEnAvance(
        membreId: membreId,
        culteIds: culteIds,
        montantTotal: montantTotal,
      );
      // Supprimer l'opération sync du membre (déjà appliquée)
      final ops = await _cache.getPendingSyncOps();
      final membreOp = ops.where((op) => op.entityId == membreId).toList();
      for (final op in membreOp) {
        await _cache.deleteSyncOp(op.isarId);
      }
      // Supprimer aussi les ops des cotisations
      for (final op in syncOps) {
        await _cache.deleteSyncOp(op.isarId);
      }
    } catch (e) {
      debugPrint(
          '[AppData] payerPlusieursCultesEnAvance réseau échoué, état local conservé: $e');
    }

    // Notification
    final notifMembre = previousState.membres.firstWhereOrNull(
      (m) => m.id == membreId,
    );
    final culteLabels = culteIds
        .map((id) => previousState.cultes.firstWhereOrNull((c) => c.id == id))
        .whereType<Culte>()
        .map((c) => c.dateFormatee)
        .join(', ');
    _notifCoordinator.notifierPaiementAvanceFull(montantTotal, notifMembre?.nomComplet ?? membreId);
    unawaited(_notifierPush(
      'cotisation_en_avance',
      notifMembre?.nomComplet ?? membreId,
      extra: '$montantTotal.toStringAsFixed(0)F pour $culteLabels',
    ));
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
    await _systemController.viderCorbeille();
  }
}
