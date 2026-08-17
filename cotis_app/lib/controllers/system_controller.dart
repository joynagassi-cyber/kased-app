import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:kased_app/core/services/sync_service.dart';
import 'package:kased_app/core/services/stats_service.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/providers/app_data_provider.dart';

/// Exception lancée quand une opération sync est déjà en cours.
class SyncEnCoursException implements Exception {
  SyncEnCoursException();
  @override
  String toString() => "Synchronisation déjà en cours";
}

/// Contrôleur dédié aux opérations système : sync, stats, corbeille.
///
/// Responsabilités :
/// - Synchronisation offline → cloud
/// - Chargement des statistiques du dashboard
/// - Calcul des retards membres
/// - Opérations de corbeille (restauration, suppression définitive)
class SystemController {
  final LocalCache _cache;
  final InsForgeService _api;
  final SyncService _syncService;
  final StatsService _statsService;
  final void Function(AppState) onStateChanged;

  SystemController({
    required LocalCache cache,
    required InsForgeService api,
    required SyncService syncService,
    required StatsService statsService,
    required this.onStateChanged,
  })  : _cache = cache,
        _api = api,
        _syncManager = syncManager,
        _statsService = statsService;

  /// Exécute une synchronisation complète.
  Future<SyncDataResult?> syncData({required bool isOffline}) async {
    if (isOffline) return null;

    final result = await _syncManager.runSync(
      isOffline: isOffline,
    );

    if (result == null) {
      // Sync déjà en cours
      return null;
    }

    if (!result.success) {
      return SyncDataResult(
        success: false,
        error: result.error,
      );
    }

    // Recharger depuis Isar après merge
    final mergedMembres = await _cache.getAllMembres();
    final mergedCultes = await _cache.getAllCultes();
    final mergedCotisations = await _cache.getAllCotisations();

    // Le dashboard est servi par InsForge (réponse API agrégée)
    Map<String, dynamic>? dashboardData;
    try {
      dashboardData = await _api.getDashboard();
    } catch (e) {
      debugPrint('[SystemController] Erreur chargement dashboard post-sync: $e');
    }

    return SyncDataResult(
      success: true,
      mergedMembres: mergedMembres,
      mergedCultes: mergedCultes,
      mergedCotisations: mergedCotisations,
      dashboard: dashboardData,
    );
  }

  /// Charge les données du dashboard depuis l'API.
  Future<void> loadDashboard() async {
    try {
      final dashboardData = await _api.getDashboard();
      // Note: this is called by AppData which handles state update
    } catch (e) {
      debugPrint('[SystemController] Erreur chargement dashboard: $e');
    }
    return {};
  }

  /// Calcule les statistiques du dashboard à partir de l'état local.
  DashboardStats getDashboardStats(AppState state) {
    return _statsService.getDashboardStats(state);
  }

  /// Charge les membres en retard depuis l'API.
  Future<List<Map<String, dynamic>>> loadRetardsMembres() async {
    try {
      return await _api.getRetardsMembres();
    } catch (e) {
      debugPrint('[SystemController] Erreur chargement retards: $e');
      return [];
    }
  }

  /// Charge les membres à jour depuis l'API.
  Future<List<Map<String, dynamic>>> loadMembresAJour() async {
    try {
      return await _api.getMembresAJour();
    } catch (e) {
      debugPrint('[SystemController] Erreur chargement membres à jour: $e');
      return [];
    }
  }

  /// Calcule les membres en retard à partir de l'état local.
  List<Map<String, dynamic>> getRetardsMembresLocally(AppState state) {
    return _statsService.getRetardsMembresLocally(state);
  }

  /// Charge l'objectif mensuel depuis SharedPreferences.
  Future<double> getObjectifMensuel() => StatsService.loadObjectifMensuel();

  /// Met à jour l'objectif mensuel.
  Future<void> updateObjectifMensuel(double montant) async {
    await StatsService.saveObjectifMensuel(montant);
  }

  /// Restaure un élément depuis la corbeille.
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
            '[SystemController] restaurerElement membre réseau échoué, mis en file: $e');
        await _syncManager.queueSyncOperation(
            'UPDATE', 'membre', membre.id, {'is_active': true});
      }
    } else if (item.entityType == 'culte') {
      final culte = Culte.fromJson(payload);

      await _cache.restoreCulteAndDeleteCorbeilleItem(culte, isarId);

      try {
        await _api.createCulte(culte.toJson());
      } catch (e) {
        debugPrint(
            '[SystemController] restaurerElement culte réseau échoué, mis en file: $e');
        await _syncManager.queueSyncOperation(
            'CREATE', 'culte', culte.id, culte.toJson());
      }
    }
  }

  /// Supprime définitivement un élément de la corbeille.
  Future<void> supprimerDefinitivement(int isarId) async {
    await _cache.deleteCorbeilleItem(isarId);
  }

  /// Vide toute la corbeille.
  Future<void> viderCorbeille() async {
    await _cache.deleteAllCorbeilleItems();
  }
}
