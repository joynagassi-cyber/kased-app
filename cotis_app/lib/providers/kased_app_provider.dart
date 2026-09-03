import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:kased_app/core/isar_local_cache.dart';
import 'package:kased_app/core/services/notification_coordinator.dart';
import 'package:kased_app/core/services/stats_service.dart';
import 'package:kased_app/core/services/sync_service.dart';
import 'package:kased_app/core/sync/device_service_port.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/providers/isar_provider.dart';
import 'package:kased_app/providers/notifications_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kased_app/store/app_state.dart';
import 'package:kased_app/store/kased_action.dart';
import 'package:kased_app/store/kased_store.dart';
import 'package:kased_app/providers/auth_provider.dart';

export 'package:kased_app/store/app_state.dart';

part 'kased_app_provider.g.dart';

/// Provider Riverpod adaptateur pour [KasedStore].
///
/// Ce provider est un adaptateur fin (~80 lignes) qui :
/// 1. Initialise le store avec les dépendances (cache, API, sync, etc.)
/// 2. Charge l'état initial depuis le cache Isar
/// 3. Lance un sync différé de 3 secondes
/// 4. Écoute les changements de connectivité
/// 5. Délégue tous les appels au store via [dispatch]
///
/// Les screens utilisent ce provider au lieu d'[appDataProvider].
@Riverpod(keepAlive: true)
class KasedApp extends _$KasedApp {
  late KasedStore _store;
  StreamSubscription? _connectivitySubscription;

  @visibleForTesting
  set store(KasedStore s) => _store = s;

  @override
  FutureOr<AppState> build() async {
    // Récupérer les dépendances
    final api = ref.watch(insForgeServiceProvider);
    final isar = await ref.watch(isarProvider.future);
    final cache = IsarLocalCache(isar);
    final deviceService = RealDeviceService();
    final syncService = SyncService(api, cache, deviceService: deviceService);
    final statsService = StatsService();

    // Notification coordinator
    final notifCoordinator = NotificationCoordinator(
      onInAppNotify: ({required titre, required message, required typeEvenement, entiteId}) {
        ref.read(notificationsProvider.notifier).ajouter(
          titre: titre,
          message: message,
          typeEvenement: typeEvenement,
          entiteId: entiteId,
        );
      },
    );

    _store = KasedStore(
      api: api,
      cache: cache,
      syncService: syncService,
      statsService: statsService,
      deviceService: deviceService,
      notifCoordinator: notifCoordinator,
    );

    // Micro-délai artificiel de 150ms pour permettre au framework de
    // rendre l'état "loading" au démarrage local (Isar)
    await Future.delayed(const Duration(milliseconds: 150));

    // Charger l'état initial depuis le cache
    await _store.reloadFromCache();

    // Écouter les changements d'état du store (dispatch + patches temps réel)
    // pour propager l'état mis à jour aux consommateurs Riverpod.
    _store.onStateChanged = (newState) {
      state = AsyncValue.data(newState);
    };

    // Surveiller la connectivité
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final isOffline = results.contains(ConnectivityResult.none);
      final current = state.value ?? AppState();
      state = AsyncValue.data(current.copyWith(isOffline: isOffline));
      if (!isOffline && syncService.shouldSync()) {
        _store.dispatch(SyncData());
      } else if (!isOffline) {
        // Vérifier async les ops en attente
        syncService.hasPendingOps().then((hasOps) {
          if (hasOps) _store.dispatch(SyncData());
        });
      }
    });

    // Connecter le temps réel si l'utilisateur est authentifié
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated && authState.token != null && authState.userEmail != null) {
      _store.connectRealtime(
        token: authState.token!,
        email: authState.userEmail!,
      );
    }

    // Écouter les changements d'authentification pour reconnecter/déconnecter
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.isAuthenticated && next.token != null && next.userEmail != null) {
        _store.connectRealtime(
          token: next.token!,
          email: next.userEmail!,
        );
      } else if (!next.isAuthenticated) {
        _store.disconnectRealtime();
      }
    });

    ref.onDispose(() {
      _connectivitySubscription?.cancel();
      _store.disconnectRealtime();
    });

    // Planifier un sync différé de 3 secondes après le chargement
    Future.delayed(const Duration(seconds: 3), () {
      if (_store.state.isOffline == false) {
        _store.dispatch(SyncData());
      }
    });

    return _store.state;
  }

  /// Dispatch une action vers le store.
  Future<void> dispatch(KasedAction action) async {
    await _store.dispatch(action);
  }

  /// Lire l'état actuel du store.
  AppState get snapshot => _store.state;

  // ── Méthodes déléguées (pour compatibilité avec l'ancien provider) ────────

  Future<Membre> addMembre({
    required String nom,
    required String prenom,
    required DateTime dateAdhesion,
    DateTime? dateNaissance,
    String? telephone,
    String? notes,
  }) async {
    await dispatch(CreateMember(
      nom: nom,
      prenom: prenom,
      dateAdhesion: dateAdhesion,
      dateNaissance: dateNaissance,
      telephone: telephone,
      notes: notes,
    ));
    // Retourner le membre depuis l'état
    return snapshot.membres.firstWhere(
      (m) => m.prenom == prenom && m.nom == nom,
      orElse: () => throw Exception('Membre non trouvé après création'),
    );
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
    await dispatch(UpdateMember(
      id: id,
      nom: nom,
      prenom: prenom,
      dateAdhesion: dateAdhesion,
      dateNaissance: dateNaissance,
      telephone: telephone,
      notes: notes,
      isActive: isActive,
    ));
  }

  Future<void> ajouterPaiementAvance({
    required String membreId,
    required double montant,
    String? notes,
  }) async {
    await dispatch(AddPaymentAdvance(
      membreId: membreId,
      montant: montant,
      notes: notes,
    ));
  }

  Future<void> deleteMembre(String id) async {
    await dispatch(DeleteMember(id));
  }

  Future<void> addCulte({
    required DateTime date,
    String? titre,
    required double montant,
  }) async {
    await dispatch(CreateCulte(
      date: date,
      titre: titre,
      montant: montant,
    ));
  }

  Future<void> updateCulte({
    required String id,
    DateTime? dateCulte,
    String? titre,
    double? montantCotisation,
    String? notes,
  }) async {
    await dispatch(UpdateCulte(
      id: id,
      dateCulte: dateCulte,
      titre: titre,
      montantCotisation: montantCotisation,
      notes: notes,
    ));
  }

  Future<void> deleteCulte(String id) async {
    await dispatch(DeleteCulte(id));
  }

  Future<void> enregistrerPaiementPersonnel({
    required String membreId,
    required String culteId,
    required double montant,
  }) async {
    await dispatch(RegisterPayment(
      membreId: membreId,
      culteId: culteId,
      montant: montant,
    ));
  }

  Future<void> togglePaiement({
    required String membreId,
    required String culteId,
  }) async {
    await dispatch(TogglePaiement(
      membreId: membreId,
      culteId: culteId,
    ));
  }

  Future<({int success, int total})> bulkSetPaiements({
    required String culteId,
    required StatutCotisation newStatut,
    required List<String> membreIds,
  }) async {
    await dispatch(BulkSetPaiements(
      culteId: culteId,
      newStatut: newStatut,
      membreIds: membreIds,
    ));
    return (success: membreIds.length, total: membreIds.length);
  }

  Future<void> marquerAbsent({
    required String membreId,
    required String culteId,
  }) async {
    await dispatch(MarkAbsent(
      membreId: membreId,
      culteId: culteId,
    ));
  }

  Future<void> payerPlusieursCultesEnAvance({
    required String membreId,
    required List<String> culteIds,
    required double montantTotal,
  }) async {
    await dispatch(PaySeveralCultesInAdvance(
      membreId: membreId,
      culteIds: culteIds,
      montantTotal: montantTotal,
    ));
  }

  Future<void> payerToutRetard(String membreId) async {
    await dispatch(PayAllRetards(membreId));
  }

  Future<void> syncData() async {
    await dispatch(SyncData());
  }

  Future<void> loadDashboard() async {
    await dispatch(LoadDashboard());
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
    return StatsService().getDashboardStats(stateValue);
  }

  List<Map<String, dynamic>> getRetardsMembresLocally() {
    final stateValue = state.value;
    if (stateValue == null) return [];
    return stateValue.retardsMembres;
  }

  Future<List<Map<String, dynamic>>> loadRetardsMembres() async {
    dispatch(GetRetardsMembres());
    final stateValue = state.value;
    return stateValue?.retardsMembres ?? [];
  }

  Future<List<Map<String, dynamic>>> loadMembresAJour() async {
    dispatch(GetMembresAJour());
    final stateValue = state.value;
    return stateValue?.membresAJour ?? [];
  }

  Future<double> getObjectifMensuel() => StatsService.loadObjectifMensuel();

  Future<DashboardStats> updateObjectifMensuel(double montant) async {
    await StatsService.saveObjectifMensuel(montant);
    return getDashboardStats();
  }

  Future<List<Map<String, dynamic>>> getHistoriqueMembre(String membreId) async {
    dispatch(GetHistoriqueMembre(membreId));
    final stateValue = state.value;
    if (stateValue?.historiqueMembreId == membreId) {
      return stateValue!.historiqueMembre;
    }
    return [];
  }

  Future<List<Cotisation>> getCotisationsDuCulte(String culteId) async {
    dispatch(GetCotisationsDuCulte(culteId));
    final stateValue = state.value;
    if (stateValue == null) return [];
    return stateValue.cotisations
        .where((c) => c.culteId == culteId)
        .toList();
  }

  Future<void> restaurerElement(int isarId) async {
    dispatch(RestoreFromTrash(isarId));
  }

  Future<void> supprimerDefinitivement(int isarId) async {
    dispatch(PermanentlyDelete(isarId));
  }

  Future<void> viderCorbeille() async {
    dispatch(EmptyTrash());
  }
}
