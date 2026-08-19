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

/// Exception lancee quand une operation sync est deja en cours.
class SyncEnCoursException implements Exception {
  SyncEnCoursException();
  @override
  String toString() => "Synchronisation deja en cours";
}

/// Controleur dedie aux operations systeme : sync, stats, corbeille.
///
/// Responsabilites :
/// - Synchronisation offline → cloud
/// - Chargement des statistiques du dashboard
/// - Calcul des retards membres
/// - Operations de corbeille (restauration, suppression definitive)
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
        _syncService = syncService,
        _statsService = statsService;

  /// Execute une synchronisation complete.
  Future<SyncDataResult?> syncData({required bool isOffline}) async {
    if (isOffline) return null;

    final result = await _syncService.syncData(
      isOffline: isOffline,
    );

    if (result == null) {
      // Sync deja en cours
      return null;
    }

    if (!result.success) {
      return SyncDataResult(
        success: false,
        error: result.error,
      );
    }

    // Recharger depuis Isar apres merge
    final mergedMembres = await _cache.getAllMembres();
    final mergedCultes = await _cache.getAllCultes();
    final mergedCotisations = await _cache.getAllCotisations();

    // Le dashboard est servi par InsForge (reponse API agregee)
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

  /// Charge les donnees du dashboard depuis l'API.
  Future<void> loadDashboard() async {
    try {
      // Note: this is called by AppData which handles state update
    } catch (e) {
      debugPrint('[SystemController] Erreur chargement dashboard: $e');
    }
    
  }

  /// Calcule les statistiques du dashboard a partir de l'etat local.
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

  /// Charge les membres a jour depuis l'API.
  Future<List<Map<String, dynamic>>> loadMembresAJour() async {
    try {
      return await _api.getMembresAJour();
    } catch (e) {
      debugPrint('[SystemController] Erreur chargement membres a jour: $e');
      return [];
    }
  }

  /// Calcule les membres en retard a partir de l'etat local.
  List<Map<String, dynamic>> getRetardsMembresLocally(AppState state) {
    return _statsService.getRetardsMembresLocally(state);
  }

  /// Charge l'objectif mensuel depuis SharedPreferences.
  Future<double> getObjectifMensuel() => StatsService.loadObjectifMensuel();

  /// Met a jour l'objectif mensuel.
  Future<void> updateObjectifMensuel(double montant) async {
    await StatsService.saveObjectifMensuel(montant);
  }

  /// Restaure un element depuis la corbeille.
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
            '[SystemController] restaurerElement membre reseau echoue, mis en file: $e');
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
            '[SystemController] restaurerElement culte reseau echoue, mis en file: $e');
        await _syncService.queueSyncOperation(
            'CREATE', 'culte', culte.id, culte.toJson());
      }
    }
  }

  /// Supprime definitivement un element de la corbeille.
  Future<void> supprimerDefinitivement(int isarId) async {
    await _cache.deleteCorbeilleItem(isarId);
  }

  /// Vide toute la corbeille.
  Future<void> viderCorbeille() async {
    await _cache.deleteAllCorbeilleItems();
  }
}
