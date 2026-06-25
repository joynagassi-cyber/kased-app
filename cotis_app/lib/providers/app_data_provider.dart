import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/core/isar_local_cache.dart';
import 'package:kased_app/core/sync/sync_manager.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/sync_operation.dart';
import 'package:kased_app/core/utils/uuid.dart';
import 'package:kased_app/core/sync/device_service.dart';
import 'package:kased_app/providers/isar_provider.dart';
import 'package:kased_app/core/notifications/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:convert';

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

class DashboardStats {
  final int totalMembres;
  final int totalCultes;
  final double totalCollecte;
  final int membresEnRetard;
  final double totalDu;

  DashboardStats({
    required this.totalMembres,
    required this.totalCultes,
    required this.totalCollecte,
    required this.membresEnRetard,
    required this.totalDu,
  });
}

class MembreRetard {
  final Membre membre;
  final int nombreRetards;
  final double montantDu;
  final List<Culte> cultesManquants;
  final DateTime? dernierPaiement;

  MembreRetard({
    required this.membre,
    required this.nombreRetards,
    required this.montantDu,
    this.cultesManquants = const [],
    this.dernierPaiement,
  });
}

@riverpod
class AppData extends _$AppData {
  late InsForgeService _api;
  late LocalCache _cache;
  late SyncManager _syncManager;
  StreamSubscription? _connectivitySubscription;
  DateTime?
      _lastSyncAt; // Throttle : on ne sync pas plus d’une fois toutes les 5 min
  static const _syncThrottle = Duration(minutes: 5);

  @visibleForTesting
  set api(InsForgeService a) => _api = a;
  @visibleForTesting
  set cache(LocalCache c) => _cache = c;

  @override
  FutureOr<AppState> build() async {
    _api = ref.watch(insForgeServiceProvider);
    final isar = await ref.watch(isarProvider.future);
    _cache = IsarLocalCache(isar);
    _syncManager = SyncManager(_api, _cache);

    // Micro-délai artificiel de 150ms pour permettre au framework de rendre l'état "loading" au démarrage local (Isar)
    await Future.delayed(const Duration(milliseconds: 150));

    // Surveiller la connectivité
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final isOffline = results.contains(ConnectivityResult.none);
      final current = state.value ?? AppState();
      state = AsyncValue.data(current.copyWith(isOffline: isOffline));
      if (!isOffline && _shouldSync()) {
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
    for (final membre in localMembres) {
      if (membre.dateNaissance != null) {
        unawaited(NotificationService.planifierAnniversaire(membre));
      }
    }

    final initialState = AppState(
      membres: localMembres,
      cultes: localCultes,
      cotisations: localCotisations,
    );

    // Sync automatique différée de 3 secondes après le chargement
    // (laisse le temps à l'UI de s'afficher avant de contacter le réseau)
    Future.delayed(const Duration(seconds: 3), () {
      if (_shouldSync()) syncData();
    });

    return initialState;
  }

  /// Retourne true si le dernier sync date de plus de [_syncThrottle].
  bool _shouldSync() {
    if (_lastSyncAt == null) return true;
    return DateTime.now().difference(_lastSyncAt!) > _syncThrottle;
  }

  Future<void> syncData() async {
    if (state.value?.isOffline ?? true) return;

    final current = state.value ?? AppState();
    state = AsyncValue.data(current.copyWith(isLoading: true));

    // Délégation à SyncManager — gère le guard anti-réentrance, le retry
    // exponentiel des ops en attente et le merge distant.
    final result = await _syncManager.runSync(
      isOffline: state.value?.isOffline ?? true,
      lastSyncAt: _lastSyncAt,
    );

    if (result == null) {
      // Sync déjà en cours ou offline → on remet juste isLoading à false.
      state = AsyncValue.data((state.value ?? AppState())
          .copyWith(isLoading: false));
      return;
    }

    if (!result.success) {
      state = AsyncValue.data((state.value ?? AppState())
          .copyWith(isLoading: false, error: result.error));
      return;
    }

    // Recharger depuis Isar après merge
    final mergedMembres = await _cache.getAllMembres();
    final mergedCultes = await _cache.getAllCultes();
    final mergedCotisations = await _cache.getAllCotisations();

    // Le dashboard est servi par InsForge (réponse API agrégée).
    final dashboardData = await _api.getDashboard();

    state = AsyncValue.data((state.value ?? AppState()).copyWith(
      membres: mergedMembres,
      cultes: mergedCultes,
      cotisations: mergedCotisations,
      dashboard: dashboardData,
      isLoading: false,
      error: null,
    ));

    // Planifier les notifications anniversaires pour les membres mergés.
    for (final membre in mergedMembres) {
      if (membre.dateNaissance != null) {
        unawaited(NotificationService.planifierAnniversaire(membre));
      }
    }

    _lastSyncAt = DateTime.now();
  }

  // --- DASHBOARD ---

  Future<void> loadDashboard() async {
    try {
      final dashboardData = await _api.getDashboard();
      final current = state.value ?? AppState();
      state = AsyncValue.data(current.copyWith(dashboard: dashboardData));
    } catch (e) {
      debugPrint('Erreur chargement dashboard: $e');
    }
  }

  Future<List<Map<String, dynamic>>> loadRetardsMembres() async {
    try {
      return await _api.getRetardsMembres();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> loadMembresAJour() async {
    try {
      return await _api.getMembresAJour();
    } catch (e) {
      return [];
    }
  }

  Future<void> _queueSyncOperation(String type, String entityType,
      String entityId, Map<String, dynamic> payload) async {
    final now = DateTime.now();
    final op = SyncOperation()
      ..type = type
      ..entityType = entityType
      ..entityId = entityId
      ..payloadJson = jsonEncode(payload)
      ..createdAt = now
      ..updatedAt = now; // Timestamp pour résolution de conflits

    await _cache.saveSyncOp(op);
  }

  // --- MEMBRES ---

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

    if (newMembre.dateNaissance != null) {
      unawaited(NotificationService.planifierAnniversaire(newMembre));
    }

    // Notification de création de membre
    unawaited(NotificationService.showNotification(
      title: 'Nouveau membre ajouté',
      body: '${newMembre.prenom} ${newMembre.nom} a été ajouté',
    ));

    await loadDashboard();

    // 2. Tentative de synchronisation réseau
    try {
      await _api.createMembre(newMembre.toJson());
    } catch (e) {
      debugPrint('[AppData] addMembre réseau échoué, mise en file: $e');
      await _queueSyncOperation('CREATE', 'membre', newId, newMembre.toJson());
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

    if (updated.dateNaissance != null) {
      unawaited(NotificationService.planifierAnniversaire(updated));
    } else {
      unawaited(NotificationService.annulerAnniversaire(id));
    }

    // 2. Réseau
    try {
      await _api.updateMembre(id, updated.toJson());
    } catch (e) {
      debugPrint('[AppData] updateMembre réseau échoué: $e');
      await _queueSyncOperation('UPDATE', 'membre', id, updated.toJson());
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
      unawaited(NotificationService.annulerAnniversaire(id));

      state = AsyncValue.data(current.copyWith(
        membres: current.membres.where((m) => m.id != id).toList(),
        cotisations:
            current.cotisations.where((c) => c.membreId != id).toList(),
      ));

      await loadDashboard();

      try {
        await _api.deleteMembre(id);
      } catch (e) {
        debugPrint('[AppData] deleteMembre réseau échoué: $e');
        await _queueSyncOperation('DELETE', 'membre', id, {});
      }
    } catch (e) {
      rethrow;
    }
  }

  // --- CULTES ---

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

     // Notification de création de culte
     final titreCulte = titre != null ? ' : $titre' : '';
     unawaited(NotificationService.showNotification(
       title: 'Nouveau culte${titreCulte.isNotEmpty ? titreCulte : ''}',
       body: 'Culte du ${DateFormat('dd/MM/yyyy').format(date)} ajouté',
     ));

    await loadDashboard();

    // 2. Réseau
    try {
      await _api.createCulte(newCulte.toJson());
    } catch (e) {
      debugPrint('[AppData] addCulte réseau échoué, mise en file déjà effectuee: $e');
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
             montantDon: c.montantPaye >= montantCotisation ? c.montantPaye - montantCotisation : 0.0,
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

    state = AsyncValue.data(current.copyWith(
      cultes: cultes,
      cotisations: updatedCotisations,
    ));

    await loadDashboard();

    // 2. Réseau
    try {
      await _api.updateCulte(id, updated.toJson());
      // Si le montant a changé, on doit aussi update les cotisations côté serveur
      if (montantCotisation != null &&
          montantCotisation != existing.montantCotisation) {
        // Option simple : update via un appel générique (si implémenté dans _api) ou via une queue
        // Ici on file dans la queue car c'est plus safe pour un batch d'updates non défini dans _api
        final toUpdate =
            updatedCotisations.where((c) => c.culteId == id).toList();
        for (final c in toUpdate) {
          await _queueSyncOperation('UPDATE', 'cotisation', c.id, c.toJson());
        }
      }
    } catch (e) {
      debugPrint('[AppData] updateCulte réseau échoué: $e');
      await _queueSyncOperation('UPDATE', 'culte', id, updated.toJson());
      if (montantCotisation != null &&
          montantCotisation != existing.montantCotisation) {
        final toUpdate =
            updatedCotisations.where((c) => c.culteId == id).toList();
        for (final c in toUpdate) {
          await _queueSyncOperation('UPDATE', 'cotisation', c.id, c.toJson());
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
          DateTime.now().difference(existingList.first.dateCulte).inDays > 30) {
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
        cotisations: current.cotisations.where((c) => c.culteId != id).toList(),
      ));

      await loadDashboard();

      // 2. Réseau
      try {
        await _api.deleteCulte(id);
      } catch (e) {
        debugPrint('[AppData] deleteCulte réseau échoué: $e');
        await _queueSyncOperation('DELETE', 'culte', id, {});
      }
    } catch (e) {
      rethrow;
    }
  }

  // --- COTISATIONS ---

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
     final isOlderThan30Days = DateTime.now().difference(culte.dateCulte).inDays > 30;

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
       throw Exception('Le montant payé doit être au moins égal au montant obligatoire (${existingCotisation.montantObligatoire}F)');
     }

     // Calcul du don (excédent)
     final montantDon = montant - existingCotisation.montantObligatoire;

     // Mise à jour de la cotisation
     final updatedCotisation = existingCotisation.copyWith(
       montantPaye: montant,
       montantDon: montantDon,
       statut: montant >= existingCotisation.montantObligatoire ? StatutCotisation.paye : StatutCotisation.nonPaye,
       datePaiement: montant >= existingCotisation.montantObligatoire ? DateTime.now() : null,
       updatedAt: DateTime.now(),
     );

     // Mise à jour optimiste immédiate
     final updatedCotisations = isNewCotisation
         ? [...previousState.cotisations, updatedCotisation]
         : previousState.cotisations.map((c) {
             if (c.membreId == membreId && c.culteId == culteId) {
               return updatedCotisation;
             }
             return c;
           }).toList();

     state = AsyncValue.data(
         previousState.copyWith(cotisations: updatedCotisations));

     // Persister immédiatement dans Isar
     await _cache.saveCotisation(updatedCotisation);

     // Notification de mise à jour des paiements (si un don a été fait)
     if (montantDon > 0) {
       unawaited(NotificationService.showNotification(
         title: 'Don enregistré',
         body: 'Un don de ${montantDon.toStringAsFixed(0)}F a été enregistré pour le membre $membreId.',
       ));
     }

     // Synchroniser avec le serveur
     try {
       if (isNewCotisation) {
         await _api.createCotisations([updatedCotisation.toJson()]).timeout(
             const Duration(seconds: 15));
       } else {
         // Nous n'avons pas de méthode spécifique pour mettre à jour le montant personnalisé,
         // donc nous utilisons une mise à jour générique de la cotisation.
         // Nous supposons que le backend a une endpoint pour mettre à jour une cotisation.
         // Si ce n'est pas le cas, nous devrons créer une telle endpoint ou utiliser la file d'attente.
         await _api.updateCotisation(updatedCotisation.id, updatedCotisation.toJson())
             .timeout(const Duration(seconds: 15));
       }
     } catch (e) {
       debugPrint(
           '[AppData] enregistrerPaiementPersonnel réseau échoué, état local conservé: $e');
       await _queueSyncOperation('UPDATE', 'cotisation', updatedCotisation.id,
           updatedCotisation.toJson());
     }
   }

   // Garder la fonction togglePaiement pour compatibilité arrière (optionnel)
   // Elle peut être utilisée pour basculer vers le montant exact de l'obligation
   Future<void> togglePaiement({
     required String membreId,
     required String culteId,
   }) async {
     // Utiliser le montant obligatoire comme montant de paiement
     final previousState = state.value;
     if (previousState == null) return;

     final culte = previousState.cultes.firstWhereOrNull((c) => c.id == culteId);
     if (culte == null) return;

     await enregistrerPaiementPersonnel(
       membreId: membreId,
       culteId: culteId,
       montant: culte.montantCotisation,
     );
   }

    /// Met à jour le statut de TOUTES les cotisations d'un culte.
    /// Retourne le nombre de succès et le nombre total.
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
          // Determine montantPaye and montantDon based on newStatut
          double montantPaye = 0.0;
          double montantDon = 0.0;
          DateTime? datePaiement;
          if (newStatut == StatutCotisation.paye || newStatut == StatutCotisation.enAvance) {
            // When marking as paid, we set the amount paid to at least the obligatoire amount.
            // For bulk operation, we assume exact payment of obligatoire (no excess).
            final culte = previousState.cultes.firstWhereOrNull((c) => c.id == culteId);
            final montantObligatoire = culte?.montantCotisation ?? 50.0;
            montantPaye = montantObligatoire;
            montantDon = 0.0;
            datePaiement = DateTime.now();
          } else if (newStatut == StatutCotisation.nonPaye) {
            montantPaye = 0.0;
            montantDon = 0.0;
            datePaiement = null;
          } else if (newStatut == StatutCotisation.absent) {
            // Absent: no payment, status unchanged for montant?
            // Keep existing montantPaye and montantDon? But absent means not paid, so we should zero out?
            // Actually absent is a separate status: the member was absent, so they don't owe anything.
            // We'll set montantPaye = 0, montantDon = 0, but keep the statut as absent.
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
            chunk.map(
              (membreId) async {
                 final cotisationToUpdate = updatedCotisations.firstWhereOrNull(
                     (c) => c.membreId == membreId && c.culteId == culteId,
                 );
                if (cotisationToUpdate == null) {
                  // This should not happen, but if it does, we skip and count as failure.
                  return false;
                }
                try {
                  await _api.updateCotisation(cotisationToUpdate.id, cotisationToUpdate.toJson());
                  return true;
                } catch (e) {
                  await _queueSyncOperation('UPDATE', 'cotisation', cotisationToUpdate.id, cotisationToUpdate.toJson());
                  return false;
                }
              },
            ),
          );
          success += results.where((r) => r).length;
        }
      } catch (e) {
        debugPrint(
            '[AppData] bulkSetPaiements réseau échoué, état local conservé: $e');
      }

      // Notification de mise à jour des paiements
      if (success > 0) {
        final actionText = newStatut == StatutCotisation.paye ? 'payé(s)' : 'annulé(s)';
        unawaited(NotificationService.showNotification(
          title: 'Paiements mis à jour',
          body: '$success paiement(s) $actionText',
        ));
      }

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
        : previousState.cotisations.map((c) {
            if (c.membreId == membreId && c.culteId == culteId) {
              return updatedCotisation;
            }
            return c;
          }).toList();

    state = AsyncValue.data(
        previousState.copyWith(cotisations: updatedCotisations));

    await _cache.saveCotisation(updatedCotisation);

    try {
      if (isNewCotisation) {
        await _api.createCotisations([updatedCotisation.toJson()]).timeout(
            const Duration(seconds: 15));
      } else {
        await _api
            .marquerAbsent(membreId: membreId, culteId: culteId)
            .timeout(const Duration(seconds: 15));
      }
    } catch (e) {
      debugPrint(
          '[AppData] marquerAbsent réseau échoué, état local conservé: $e');
      await _queueSyncOperation('UPDATE', 'cotisation', updatedCotisation.id,
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

  // --- STATS ---

   /// Calcule les statistiques localement à partir des données Isar.
   /// Fonctionne en offline et est toujours à jour après un togglePaiement.
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

     final membres = stateValue.membres;
     final cultes = stateValue.cultes;
     final cotisations = stateValue.cotisations;

     // Collecte cumulée de tous les cultes (montant effectivement payé)
     final totalCollecte = cotisations
         .where((c) => c.estPaye)
         .fold<double>(0, (sum, c) => sum + c.montantPaye);

     // Membres en retard = ont au moins une cotisation non payée sur un culte passé
     final now = DateTime.now();
     final cultesPassesIds =
         cultes.where((c) => c.dateCulte.isBefore(now)).map((c) => c.id).toSet();

     final membresEnRetardIds = cotisations
         .where((c) =>
             cultesPassesIds.contains(c.culteId) &&
             c.estEnRetard) // using the new getter
         .map((c) => c.membreId)
         .toSet();

     // Total dû = somme du montant restant à payer (obligatoire - payé) sur cultes passés
     final totalDu = cotisations
         .where((c) =>
             cultesPassesIds.contains(c.culteId) &&
             c.estEnRetard)
         .fold<double>(0, (sum, c) => sum + (c.montantObligatoire - c.montantPaye));

     return DashboardStats(
       totalMembres: membres.where((m) => m.isActive).length,
       totalCultes: cultes.length,
       totalCollecte: totalCollecte,
       membresEnRetard: membresEnRetardIds.length,
       totalDu: totalDu,
     );
   }

   /// Calcule les membres en retard localement depuis Isar.
   /// Fonctionne parfaitement en offline et en online.
   List<Map<String, dynamic>> getRetardsMembresLocally() {
     final stateValue = state.value;
     if (stateValue == null) return [];

     final membres = stateValue.membres;
     final cultes = stateValue.cultes;
     final cotisations = stateValue.cotisations;

     final now = DateTime.now();
     final cultesPassesIds =
         cultes.where((c) => c.dateCulte.isBefore(now)).map((c) => c.id).toSet();

     final result = <Map<String, dynamic>>[];

     for (final membre in membres.where((m) => m.isActive)) {
       // Cotisations non payées sur cultes passés
       final retardsCotisations = cotisations
           .where((c) =>
               c.membreId == membre.id &&
               cultesPassesIds.contains(c.culteId) &&
               c.estEnRetard) // using the new getter
           .toList();

       if (retardsCotisations.isEmpty) continue;

       // Dernier paiement effectué
       final payedCotisations = cotisations
           .where((c) =>
               c.membreId == membre.id && c.estPaye && c.datePaiement != null)
           .toList()
         ..sort((a, b) => b.datePaiement!.compareTo(a.datePaiement!));

       final dernierPaiement = payedCotisations.isNotEmpty
           ? payedCotisations.first.datePaiement
           : null;

       final montantDu =
           retardsCotisations.fold<double>(0, (sum, c) => sum + (c.montantObligatoire - c.montantPaye));

       result.add({
         'membre_id': membre.id,
         'nom': membre.nom,
         'prenom': membre.prenom,
         'cultes_en_retard': retardsCotisations.length,
         'montant_du_fcfa': montantDu,
         'dernier_paiement': dernierPaiement?.toIso8601String(),
       });
     }

     // Trier par montant dû décroissant
     result.sort((a, b) => (b['montant_du_fcfa'] as double)
         .compareTo(a['montant_du_fcfa'] as double));
     return result;
   }

  Future<void> restaurerElement(int isarId) async {
    final item = await _cache.getCorbeilleItem(isarId);
    if (item == null) return;

    final payload = jsonDecode(item.payloadJson);

    if (item.entityType == 'membre') {
      final membre = Membre.fromJson(payload);
      membre.isActive = true;

      // 1. Push cloud d'abord (pour que le sync ne ré-écrase pas)
      try {
        await _api.updateMembre(membre.id, {'is_active': true});
      } catch (e) {
        await _queueSyncOperation(
            'UPDATE', 'membre', membre.id, {'is_active': true});
      }

      // 2. Restauration locale
      await _cache.restoreMembreAndDeleteCorbeilleItem(membre, isarId);
    } else if (item.entityType == 'culte') {
      final culte = Culte.fromJson(payload);

      try {
        await _api.createCulte(culte.toJson());
      } catch (e) {
        await _queueSyncOperation('CREATE', 'culte', culte.id, culte.toJson());
      }

      await _cache.restoreCulteAndDeleteCorbeilleItem(culte, isarId);
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
}
