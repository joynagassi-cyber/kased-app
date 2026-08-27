import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kased_app/core/insforge/insforge_service_port.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/core/realtime/realtime_handler.dart';
import 'package:kased_app/core/services/notification_coordinator.dart';
import 'package:kased_app/core/services/push_notify_service.dart';
import 'package:kased_app/core/services/stats_service.dart';
import 'package:kased_app/core/services/sync_service.dart';
import 'package:kased_app/core/sync/device_service_port.dart';
import 'package:kased_app/store/app_state.dart';
import 'package:kased_app/store/app_state_helpers.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/store/handlers/culte_handler.dart';
import 'package:kased_app/store/handlers/cotisation_handler.dart';
import 'package:kased_app/store/handlers/member_handler.dart';
import 'package:kased_app/store/kased_action.dart';

/// Store centralisé de l'application Kased.
///
/// Interface : [dispatch] reçoit une [KasedAction] et transforme l'[AppState].
/// Les handlers internes gèrent la logique métier de chaque domain.
///
/// Le provider Riverpod ([KasedApp]) est un adaptateur fin qui connecte le
/// store au cycle de vie Flutter.
class KasedStore {
  // ── State ──────────────────────────────────────────────────────────────────

  AppState _state = AppState();
  AppState get state => _state;

  // ── Dependencies ───────────────────────────────────────────────────────────

  final LocalCache cache;
  final InsForgeServicePort api;
  final SyncService syncService;
  final StatsService statsService;
  final DeviceServicePort deviceService;
  final NotificationCoordinator notifCoordinator;

  // ── Handlers ───────────────────────────────────────────────────────────────

  late MemberHandler _memberHandler;
  late CulteHandler _culteHandler;
  late CotisationHandler _cotisationHandler;
  RealtimeHandler? _realtimeHandler;

  bool _isSyncing = false;
  String? _currentUserEmail;
  String? _currentUserToken;

  KasedStore({
    required this.api,
    required this.cache,
    required this.syncService,
    required this.statsService,
    required this.deviceService,
    required this.notifCoordinator,
  }) {
    _memberHandler = MemberHandler(
      cache: cache,
      api: api,
      deviceService: deviceService,
      notifCoordinator: notifCoordinator,
      onLoadDashboard: () => _handleLoadDashboard(),
      onPush: (event, label, {extra}) => _notifierPush(event, label, extra: extra),
    );
    _culteHandler = CulteHandler(
      cache: cache,
      api: api,
      deviceService: deviceService,
      notifCoordinator: notifCoordinator,
      onLoadDashboard: () => _handleLoadDashboard(),
      onPush: (event, label, {extra}) => _notifierPush(event, label, extra: extra),
    );
    _cotisationHandler = CotisationHandler(
      cache: cache,
      api: api,
      deviceService: deviceService,
      notifCoordinator: notifCoordinator,
      onPush: (event, label, {extra}) => _notifierPush(event, label, extra: extra),
      onGetMembres: () => cache.getAllMembres(),
      onGetCotisations: () => cache.getAllCotisations(),
    );
  }

  /// Connecte le handler temps réel avec les identifiants de l'utilisateur.
  void connectRealtime({required String token, required String email}) {
    if (_currentUserEmail == email && _currentUserToken == token) return;
    _currentUserEmail = email;
    _currentUserToken = token;
    _realtimeHandler?.disconnect();
    _realtimeHandler = RealtimeHandler();
    _realtimeHandler!.initPatchEngine(cache);
    _realtimeHandler!.connectWithAuth(
      token: token,
      email: email,
      onReload: () async {
        // Recharger les données après un événement temps réel
        await reloadFromCache();
      },
    );
  }

  /// Déconnecte le handler temps réel (appelé au logout).
  void disconnectRealtime() {
    _realtimeHandler?.disconnect();
    _realtimeHandler = null;
    _currentUserEmail = null;
    _currentUserToken = null;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Dispatch une action. Le store applique la transformation et notifie.
  Future<void> dispatch(KasedAction action) async {
    try {
      switch (action) {
        // Members
        case CreateMember():
          await _memberHandler.createMember(action);
          final membres = await cache.getAllMembres();
          _state = _state.copyWith(membres: sortMembres(membres));
        case UpdateMember():
          await _memberHandler.updateMember(action);
          final membres2 = await cache.getAllMembres();
          _state = _state.copyWith(membres: sortMembres(membres2));
        case AddPaymentAdvance():
          await _memberHandler.addPaymentAdvance(action);
          final membres3 = await cache.getAllMembres();
          _state = _state.copyWith(membres: sortMembres(membres3));
        case DeleteMember():
          await _memberHandler.deleteMember(action);
          final membres4 = await cache.getAllMembres();
          _state = _state.copyWith(membres: membres4);
        case RestoreMember():
          await _memberHandler.restoreMember(action);
          final allMembres = await cache.getAllMembres();
          final allCultes = await cache.getAllCultes();
          final allCotisations = await cache.getAllCotisations();
          _state = withFullData(_state, membres: allMembres, cultes: allCultes, cotisations: allCotisations);
        // Cultes
        case CreateCulte():
          await _culteHandler.createCulte(action);
          final cultes = await cache.getAllCultes();
          _state = _state.copyWith(cultes: cultes);
        case UpdateCulte():
          await _culteHandler.updateCulte(action);
          final cultes2 = await cache.getAllCultes();
          _state = _state.copyWith(cultes: cultes2);
        case DeleteCulte():
          await _culteHandler.deleteCulte(action);
          final cultes3 = await cache.getAllCultes();
          _state = _state.copyWith(cultes: cultes3);
        case RestoreCulte():
          await _culteHandler.restoreCulte(action);
          final allM = await cache.getAllMembres();
          final allC = await cache.getAllCultes();
          final allCo = await cache.getAllCotisations();
          _state = withFullData(_state, membres: allM, cultes: allC, cotisations: allCo);
        // Cotisations
        case RegisterPayment():
          await _cotisationHandler.registerPayment(action);
          final cots = await cache.getAllCotisations();
          _state = _state.copyWith(cotisations: cots);
        case MarkAbsent():
          await _cotisationHandler.markAbsent(action);
          final cots2 = await cache.getAllCotisations();
          _state = _state.copyWith(cotisations: cots2);
        case BulkSetPaiements():
          await _cotisationHandler.bulkSetPaiements(action);
          final cots3 = await cache.getAllCotisations();
          _state = _state.copyWith(cotisations: cots3);
        case TogglePaiement():
          await _cotisationHandler.togglePaiement(action);
          final cots4 = await cache.getAllCotisations();
          _state = _state.copyWith(cotisations: cots4);
        case PaySeveralCultesInAdvance():
          await _cotisationHandler.paySeveralCultesInAdvance(action);
          final cots5 = await cache.getAllCotisations();
          final membres5 = await cache.getAllMembres();
          _state = _state.copyWith(cotisations: cots5, membres: membres5);
        // Sync
        case SyncData():
          await _handleSyncData();
        case LoadDashboard():
          await _handleLoadDashboard();
        // Corbeille
        case PermanentlyDelete():
          await cache.deleteCorbeilleItem(action.isarId);
        case EmptyTrash():
          await cache.deleteAllCorbeilleItems();
          final m = await cache.getAllMembres();
          final c = await cache.getAllCultes();
          final co = await cache.getAllCotisations();
          _state = withFullData(_state, membres: m, cultes: c, cotisations: co);
        // Corbeille restore
        case RestoreFromTrash():
          final item = await cache.getCorbeilleItem(action.isarId);
          if (item == null) return;
          final entityType = item.entityType;
          final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
          if (entityType == 'membre') {
            final membre = Membre.fromJson(payload);
            await cache.restoreMembreAndDeleteCorbeilleItem(membre, action.isarId);
            final membres = await cache.getAllMembres();
            _state = _state.copyWith(membres: sortMembres(membres));
            try {
              await api.updateMembre(membre.id, {'is_active': true});
            } catch (e) {
              debugPrint('[KasedStore] restaurer membre from trash reseau echoue: $e');
            }
          } else if (entityType == 'culte') {
            final culte = Culte.fromJson(payload);
            await cache.restoreCulteAndDeleteCorbeilleItem(culte, action.isarId);
            final cultes = await cache.getAllCultes();
            _state = _state.copyWith(cultes: cultes);
            try {
              await api.createCulte({'id': culte.id});
            } catch (e) {
              debugPrint('[KasedStore] restaurer culte from trash reseau echoue: $e');
            }
          }
        // Queries (read-only, state not mutated)
        case GetHistoriqueMembre():
          try {
            final historique = await api.getHistoriqueMembre(action.membreId);
            _state = _state.copyWith(
              historiqueMembre: historique,
              historiqueMembreId: action.membreId,
            );
          } catch (e) {
            debugPrint('[KasedStore] Erreur chargement historique: $e');
          }
        case GetCotisationsDuCulte():
          try {
            await api.getCotisationsDuCulte(action.culteId);
          } catch (e) {
            debugPrint('[KasedStore] Erreur chargement cotisations: $e');
          }
        case GetRetardsMembres():
          try {
            final retards = await statsService.loadRetardsMembres(api);
            _state = _state.copyWith(retardsMembres: retards);
          } catch (e) {
            debugPrint('[KasedStore] Erreur chargement retards: $e');
          }
        case GetMembresAJour():
          try {
            final membres = await statsService.loadMembresAJour(api);
            _state = _state.copyWith(membresAJour: membres);
          } catch (e) {
            debugPrint('[KasedStore] Erreur chargement membres a jour: $e');
          }
      }
    } catch (e, stack) {
      debugPrint('[KasedStore] Error dispatching $action: $e\n$stack');
      _state = _state.copyWith(error: e.toString());
    }
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _notifierPush(
    String event,
    String entityLabel, {
    String? extra,
  }) async {
    await PushNotifyService.notifier(
      event: event,
      entityLabel: entityLabel,
      actorEmail: null,
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
