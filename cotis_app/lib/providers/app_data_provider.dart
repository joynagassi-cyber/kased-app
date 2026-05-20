import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/core/isar_local_cache.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/sync_operation.dart';
import 'package:kased_app/models/corbeille_item.dart';
import 'package:kased_app/core/utils/uuid.dart';
import 'package:kased_app/providers/isar_provider.dart';
import 'package:kased_app/core/notifications/notification_service.dart';
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
  StreamSubscription? _connectivitySubscription;
  DateTime? _lastSyncAt; // Throttle : on ne sync pas plus d’une fois toutes les 5 min
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

    try {
      final current = state.value ?? AppState();
      state = AsyncValue.data(current.copyWith(isLoading: true));

      // 1. Pousser les opérations en attente (Sync Queue)
      final pendingOps = await _cache.getPendingSyncOps();
      for (final op in pendingOps) {
        try {
          final payload = jsonDecode(op.payloadJson) as Map<String, dynamic>;
          // Résolution de conflits : inclure le timestamp client pour comparaison serveur
          payload['updated_at'] = op.updatedAt?.toIso8601String() ?? op.createdAt.toIso8601String();
          if (op.entityType == 'membre') {
            if (op.type == 'CREATE') await _api.createMembre(payload);
            else if (op.type == 'UPDATE') await _api.updateMembre(op.entityId, payload);
            else if (op.type == 'DELETE') await _api.deleteMembre(op.entityId);
          } else if (op.entityType == 'culte') {
            if (op.type == 'CREATE') await _api.createCulte(payload);
            else if (op.type == 'UPDATE') await _api.updateCulte(op.entityId, payload);
            else if (op.type == 'DELETE') await _api.deleteCulte(op.entityId);
          } else if (op.entityType == 'cotisation') {
            if (op.type == 'CREATE') {
               await _api.createCotisations([payload]);
            }
            else if (op.type == 'UPDATE') await _api.updateCotisation(op.entityId, payload);
          }
          await _cache.deleteSyncOp(op.isarId);
        } catch (e) {
          debugPrint('Erreur lors de la synchro de l\'opération ${op.isarId}: $e');
          // En cas d'erreur sur une opération, on s'arrête pour conserver l'ordre
          break;
        }
      }

      // 2. Fetch from Cloud (avec pagination automatique)
      final remoteMembresJson = await _api.getAllMembres();
      final remoteCultesJson = await _api.getCultes(page: 1, pageSize: 200);
      final remoteCotisationsJson = await _api.getCotisations();
      final dashboardData = await _api.getDashboard();

      final remoteMembres =
          remoteMembresJson.map((j) => Membre.fromJson(j)).toList();
      final remoteCultes =
          remoteCultesJson.map((j) => Culte.fromJson(j)).toList();
      final remoteCotisations =
          remoteCotisationsJson.map((j) => Cotisation.fromJson(j)).toList();

      // Update Local Cache
      await _cache.replaceAll(
        membres: remoteMembres,
        cultes: remoteCultes,
        cotisations: remoteCotisations,
      );

      state = AsyncValue.data((state.value ?? AppState()).copyWith(
        membres: remoteMembres,
        cultes: remoteCultes,
        cotisations: remoteCotisations,
        dashboard: dashboardData,
        isLoading: false,
      ));

      // Planifier les notifications
      for (final membre in remoteMembres) {
        if (membre.dateNaissance != null) {
          unawaited(NotificationService.planifierAnniversaire(membre));
        }
      }

      // Marquer le timestamp du dernier sync réussi
      _lastSyncAt = DateTime.now();
    } catch (e) {
      state = AsyncValue.data((state.value ?? AppState())
          .copyWith(isLoading: false, error: "Erreur de synchronisation: $e"));
    }
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

  Future<void> _queueSyncOperation(
      String type, String entityType, String entityId, Map<String, dynamic> payload) async {
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
    final newMembre = Membre()
      ..id = newId
      ..nom = nom
      ..prenom = prenom
      ..dateAdhesion = dateAdhesion
      ..dateNaissance = dateNaissance
      ..telephone = telephone
      ..notes = notes
      ..isActive = true;

    // 1. Sauvegarde locale immédiate
    await _cache.saveMembre(newMembre);

    final current = state.value ?? AppState();
    state = AsyncValue.data(current.copyWith(
      membres: [...current.membres, newMembre]
        ..sort((a, b) => a.nom.compareTo(b.nom)),
    ));

    if (newMembre.dateNaissance != null) {
      unawaited(NotificationService.planifierAnniversaire(newMembre));
    }

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
    final updated = Membre()
      ..id = existing.id
      ..nom = nom ?? existing.nom
      ..prenom = prenom ?? existing.prenom
      ..dateAdhesion = dateAdhesion ?? existing.dateAdhesion
      ..dateNaissance = dateNaissance ?? existing.dateNaissance
      ..telephone = telephone ?? existing.telephone
      ..notes = notes ?? existing.notes
      ..isActive = isActive ?? existing.isActive;

    // 1. Sauvegarde locale
    await _cache.saveMembre(updated);

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
      
      // Mettre dans la corbeille
      final corbeilleItem = CorbeilleItem()
        ..entityId = id
        ..entityType = 'membre'
        ..payloadJson = jsonEncode(existing.toJson())
        ..deletedAt = DateTime.now();

      // Suppression locale
      await _cache.deleteMembreAndSaveCorbeilleItem(id, corbeilleItem);
      unawaited(NotificationService.annulerAnniversaire(id));

      state = AsyncValue.data(current.copyWith(
        membres: current.membres.where((m) => m.id != id).toList(),
        cotisations:
            current.cotisations.where((c) => c.membreId != id).toList(),
      ));

      await loadDashboard();

      // Réseau
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
    
    final newCulte = Culte()
      ..id = culteId
      ..dateCulte = date
      ..titre = titre
      ..montantCotisation = montant;

    final activeMembres = state.value?.membres.where((m) => m.isActive).toList() ?? [];
    final localCotisations = activeMembres.map((m) {
      return Cotisation()
        ..id = UuidUtils.generate()
        ..culteId = culteId
        ..membreId = m.id
        ..montant = montant
        ..statut = StatutCotisation.nonPaye;
    }).toList();

    // 1. Sauvegarde locale
    await _cache.saveCulteWithCotisations(newCulte, localCotisations);

    final current = state.value ?? AppState();
    state = AsyncValue.data(current.copyWith(
      cultes: [newCulte, ...current.cultes]..sort((a, b) => b.dateCulte.compareTo(a.dateCulte)),
      cotisations: [...current.cotisations, ...localCotisations],
    ));

    await loadDashboard();

    // 2. Réseau
    try {
      await _api.createCulte(newCulte.toJson());
    } catch (e) {
      debugPrint('[AppData] addCulte réseau échoué, mise en file: $e');
      await _queueSyncOperation('CREATE', 'culte', culteId, newCulte.toJson());
      for (final c in localCotisations) {
        await _queueSyncOperation('CREATE', 'cotisation', c.id, c.toJson());
      }
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
      ..notes = notes ?? existing.notes;

    // Mise à jour optimiste des cotisations liées si le montant a changé
    List<Cotisation> updatedCotisations = current.cotisations;
    if (montantCotisation != null && montantCotisation != existing.montantCotisation) {
      updatedCotisations = current.cotisations.map((c) {
        if (c.culteId == id) {
          return c.copyWith(montant: montantCotisation);
        }
        return c;
      }).toList();
    }

    // 1. Sauvegarde locale
    final cotisationsToUpdate = (montantCotisation != null && montantCotisation != existing.montantCotisation)
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
      if (montantCotisation != null && montantCotisation != existing.montantCotisation) {
        // Option simple : update via un appel générique (si implémenté dans _api) ou via une queue
        // Ici on file dans la queue car c'est plus safe pour un batch d'updates non défini dans _api
        final toUpdate = updatedCotisations.where((c) => c.culteId == id).toList();
        for (final c in toUpdate) {
           await _queueSyncOperation('UPDATE', 'cotisation', c.id, c.toJson());
        }
      }
    } catch (e) {
      debugPrint('[AppData] updateCulte réseau échoué: $e');
      await _queueSyncOperation('UPDATE', 'culte', id, updated.toJson());
      if (montantCotisation != null && montantCotisation != existing.montantCotisation) {
        final toUpdate = updatedCotisations.where((c) => c.culteId == id).toList();
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
      if (existingList.isNotEmpty && DateTime.now().difference(existingList.first.dateCulte).inDays > 30) {
        throw Exception("Impossible de supprimer un culte de plus de 30 jours.");
      }
      final existing = existingList.isNotEmpty ? existingList.first : current.cultes.firstWhere((c) => c.id == id);
      
      final corbeilleItem = CorbeilleItem()
        ..entityId = id
        ..entityType = 'culte'
        ..payloadJson = jsonEncode(existing.toJson())
        ..deletedAt = DateTime.now();

      // Suppression locale (et des cotisations associées)
      await _cache.deleteCulteAndCotisationsAndSaveCorbeilleItem(id, corbeilleItem);

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

  Future<void> togglePaiement({
    required String membreId,
    required String culteId,
  }) async {
    final previousState = state.value;
    if (previousState == null) return;

    final cultes = previousState.cultes.where((c) => c.id == culteId);
    final isOlderThan30Days = cultes.isNotEmpty && DateTime.now().difference(cultes.first.dateCulte).inDays > 30;
    final existingCotisation = previousState.cotisations.firstWhere(
      (c) => c.membreId == membreId && c.culteId == culteId,
      orElse: () => Cotisation()..statut = StatutCotisation.nonPaye,
    );

    if (isOlderThan30Days && existingCotisation.estPaye) {
      throw Exception("Le paiement est verrouillé après 30 jours.");
    }

    Cotisation? updatedCotisation;
    // Mise à jour optimiste immédiate
    final updatedCotisations = previousState.cotisations.map((c) {
      if (c.membreId == membreId && c.culteId == culteId) {
        final newStatut =
            c.estPaye ? StatutCotisation.nonPaye : StatutCotisation.paye;
        updatedCotisation = c.copyWith(
          statut: newStatut,
          datePaiement:
              newStatut == StatutCotisation.paye ? DateTime.now() : null,
        );
        return updatedCotisation!;
      }
      return c;
    }).toList();

    state =
        AsyncValue.data(previousState.copyWith(cotisations: updatedCotisations));

    // Persister immédiatement dans Isar (offline-first)
    if (updatedCotisation != null) {
      await _cache.saveCotisation(updatedCotisation!);
    }

    // Synchroniser avec le serveur en arrière-plan
    try {
      await _api.togglePaiement(
        membreId: membreId,
        culteId: culteId,
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      // Erreur réseau : on garde l'état local, sera synchée au prochain reconnect
      debugPrint('[AppData] togglePaiement réseau échoué, état local conservé: $e');
      if (updatedCotisation != null) {
        await _queueSyncOperation('UPDATE', 'cotisation', updatedCotisation!.id, updatedCotisation!.toJson());
      }
    }
  }

  /// Met à jour le statut de TOUTES les cotisations d'un culte.
  /// Fonctionne par lots avec timeout pour éviter les spinners infinis.
  Future<void> bulkSetPaiements({
    required String culteId,
    required StatutCotisation newStatut,
    required List<String> membreIds,
  }) async {
    final previousState = state.value;
    if (previousState == null) return;

    // Mise à jour optimiste immédiate (UI répond instantanément)
    final updatedCotisations = previousState.cotisations.map((c) {
      if (c.culteId == culteId && membreIds.contains(c.membreId)) {
        return c.copyWith(
          statut: newStatut,
          datePaiement:
              newStatut == StatutCotisation.paye ? DateTime.now() : null,
        );
      }
      return c;
    }).toList();

    state =
        AsyncValue.data(previousState.copyWith(cotisations: updatedCotisations));

    // Mettre à jour la DB locale pour la persistance offline
    final toUpdateLocally = updatedCotisations
        .where((c) => c.culteId == culteId && membreIds.contains(c.membreId))
        .toList();
    await _cache.saveAllCotisations(toUpdateLocally);

    // Synchroniser avec le serveur en arrière-plan
    try {
      // Appels API en parallèle par petits lots avec Timeout
      for (var i = 0; i < membreIds.length; i += 5) {
        final chunk = membreIds.skip(i).take(5).toList();
        await Future.wait(
          chunk.map(
            (mid) => _api.setCotisationStatut(
              membreId: mid,
              culteId: culteId,
              statut: newStatut == StatutCotisation.paye ? 'paye' : 'non_paye',
            ).timeout(const Duration(seconds: 15)),
          ),
        );
      }
    } catch (e) {
      // Erreur réseau : état local déjà persisté dans Isar, mise en file d'attente
      debugPrint('[AppData] bulkSetPaiements réseau échoué, état local conservé: $e');
      for (final c in toUpdateLocally) {
        await _queueSyncOperation('UPDATE', 'cotisation', c.id, c.toJson());
      }
    }
  }

  Future<void> marquerAbsent({
    required String membreId,
    required String culteId,
  }) async {
    final previousState = state.value;
    if (previousState == null) return;

    final cultes = previousState.cultes.where((c) => c.id == culteId);
    final isOlderThan30Days = cultes.isNotEmpty && DateTime.now().difference(cultes.first.dateCulte).inDays > 30;
    final existingCotisation = previousState.cotisations.firstWhere(
      (c) => c.membreId == membreId && c.culteId == culteId,
      orElse: () => Cotisation()..statut = StatutCotisation.nonPaye,
    );

    if (isOlderThan30Days && existingCotisation.estPaye) {
      throw Exception("Impossible de marquer absent un membre ayant déjà payé pour un culte verrouillé.");
    }

    Cotisation? updatedCotisation;
    // Mise à jour optimiste immédiate
    final updatedCotisations = previousState.cotisations.map((c) {
      if (c.membreId == membreId && c.culteId == culteId) {
        updatedCotisation = c.copyWith(statut: StatutCotisation.absent);
        return updatedCotisation!;
      }
      return c;
    }).toList();

    state =
        AsyncValue.data(previousState.copyWith(cotisations: updatedCotisations));

    // Persister immédiatement dans Isar
    if (updatedCotisation != null) {
      await _cache.saveCotisation(updatedCotisation!);
    }

    try {
      await _api.marquerAbsent(
        membreId: membreId,
        culteId: culteId,
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('[AppData] marquerAbsent réseau échoué, état local conservé: $e');
      if (updatedCotisation != null) {
        await _queueSyncOperation('UPDATE', 'cotisation', updatedCotisation!.id, updatedCotisation!.toJson());
      }
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

    // Collecte cumulée de tous les cultes
    final totalCollecte = cotisations
        .where((c) => c.estPaye)
        .fold<double>(0, (sum, c) => sum + c.montant);

    // Membres en retard = ont au moins une cotisation non payée sur un culte passé
    final now = DateTime.now();
    final cultesPassesIds = cultes
        .where((c) => c.dateCulte.isBefore(now))
        .map((c) => c.id)
        .toSet();

    final membresEnRetardIds = cotisations
        .where((c) =>
            cultesPassesIds.contains(c.culteId) &&
            c.statut == StatutCotisation.nonPaye)
        .map((c) => c.membreId)
        .toSet();

    // Total dû = somme des cotisations non payées sur cultes passés
    final totalDu = cotisations
        .where((c) =>
            cultesPassesIds.contains(c.culteId) &&
            c.statut == StatutCotisation.nonPaye)
        .fold<double>(0, (sum, c) => sum + c.montant);

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
    final cultesPassesIds = cultes
        .where((c) => c.dateCulte.isBefore(now))
        .map((c) => c.id)
        .toSet();

    final result = <Map<String, dynamic>>[];

    for (final membre in membres.where((m) => m.isActive)) {
      // Cotisations non payées sur cultes passés
      final retardsCotisations = cotisations
          .where((c) =>
              c.membreId == membre.id &&
              cultesPassesIds.contains(c.culteId) &&
              c.statut == StatutCotisation.nonPaye)
          .toList();

      if (retardsCotisations.isEmpty) continue;

      // Dernier paiement effectué
      final payedCotisations = cotisations
          .where((c) =>
              c.membreId == membre.id &&
              c.estPaye &&
              c.datePaiement != null)
          .toList()
        ..sort((a, b) => b.datePaiement!.compareTo(a.datePaiement!));

      final dernierPaiement = payedCotisations.isNotEmpty
          ? payedCotisations.first.datePaiement
          : null;

      final montantDu =
          retardsCotisations.fold<double>(0, (sum, c) => sum + c.montant);

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
    result.sort((a, b) =>
        (b['montant_du_fcfa'] as double)
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

      await _cache.restoreMembreAndDeleteCorbeilleItem(membre, isarId);

      try {
        await _api.updateMembre(membre.id, {'is_active': true});
      } catch (e) {
        await _queueSyncOperation('UPDATE', 'membre', membre.id, {'is_active': true});
      }
    } else if (item.entityType == 'culte') {
      final culte = Culte.fromJson(payload);

      await _cache.restoreCulteAndDeleteCorbeilleItem(culte, isarId);

      try {
        await _api.createCulte(culte.toJson());
      } catch (e) {
        await _queueSyncOperation('CREATE', 'culte', culte.id, culte.toJson());
      }
    }

    await syncData();
  }
}

