import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../insforge/insforge_service.dart';
import '../local_cache.dart';
import '../constants.dart';
import '../../models/culte.dart';
import '../../models/membre.dart';
import '../../models/cotisation.dart';
import '../../models/sync_operation.dart';

/// Résultat d'une opération de synchronisation.
class SyncResult {
  final bool success;
  final int operationsPushed;
  final int operationsFailed;
  final int? membresRemote, cultesRemote, cotisationsRemote;
  final String? error;

  const SyncResult({
    required this.success,
    required this.operationsPushed,
    required this.operationsFailed,
    this.membresRemote,
    this.cultesRemote,
    this.cotisationsRemote,
    this.error,
  });
}

/// Orchestrateur de synchronisation offline → cloud.
///
/// Responsabilités :
/// - Pousser la queue [SyncOperation] vers le serveur avec retry exponentiel
/// - Récupérer l'état distant (membres / cultes / cotisations / dashboard)
/// - Appliquer le merge côté Isar (via `LocalCache.mergeFromCloud`) en
///   protégeant les entités avec des ops en attente
///
/// Anti-réentrance : un seul [runSync] à la fois.
class SyncManager {
  final InsForgeService _api;
  final LocalCache _cache;
  bool _isSyncing = false;

  SyncManager(this._api, this._cache);

  bool get isSyncing => _isSyncing;

  /// Exécute une synchronisation complète. Renvoie null si une synchro est
  /// déjà en cours (`isOffline`), sinon un [SyncResult].
  Future<SyncResult?> runSync({
    required bool isOffline,
    Duration throttle = KasedConstants.syncThrottle,
    DateTime? lastSyncAt,
  }) async {
    if (isOffline) return null;
    if (_isSyncing) return null;

    _isSyncing = true;
    try {
      return await _doSync(lastSyncAt: lastSyncAt);
    } finally {
      _isSyncing = false;
    }
  }

  Future<SyncResult> _doSync({DateTime? lastSyncAt}) async {
    int pushed = 0;
    int failed = 0;

    try {
      // 1. Pousser la queue
      final pendingOps = await _cache.getPendingSyncOps();
      final pendingMembreIds = <String>{};
      final pendingCulteIds = <String>{};
      final pendingCotisationIds = <String>{};

      for (final op in pendingOps) {
        try {
          await _pushOperationWithRetry(op);
          pushed++;
          // Ajouter temporairement aux pending pour protéger le merge
          if (op.entityType == 'membre') {
            pendingMembreIds.add(op.entityId);
          } else if (op.entityType == 'culte') {
            pendingCulteIds.add(op.entityId);
          } else if (op.entityType == 'cotisation') {
            pendingCotisationIds.add(op.entityId);
          }

          await _cache.deleteSyncOp(op.isarId);
          // Retirer de la protection après suppression réussie
          if (op.entityType == 'membre')
            pendingMembreIds.remove(op.entityId);
          else if (op.entityType == 'culte')
            pendingCulteIds.remove(op.entityId);
          else if (op.entityType == 'cotisation')
            pendingCotisationIds.remove(op.entityId);
        } catch (e) {
          failed++;
          debugPrint(
              'Sync: op ${op.isarId} définitivement échouée après ${KasedConstants.syncMaxRetries} tentatives: $e');
          // Continuer avec l'opération suivante (ne pas bloquer toute la queue).
        }
      }

      // 2. Fetch from Cloud
      final remoteMembresJson = await _api.getAllMembres();
      final remoteCultesJson = await _api.getCultes(
        page: 1,
        pageSize: KasedConstants.defaultPageSize,
      );
      final remoteCotisationsJson = await _api.getCotisations();
      // dashboardData est récupéré par AppData après runSync() pour préserver
      // son cycle de vie (cache local Isar des stats). On le fetch ici seulement
      // si l'appelant le demande.

      final remoteMembres =
          remoteMembresJson.map((j) => Membre.fromJson(j)).toList();
      final remoteCultes =
          remoteCultesJson.map((j) => Culte.fromJson(j)).toList();
      final remoteCotisations =
          remoteCotisationsJson.map((j) => Cotisation.fromJson(j)).toList();

      // 3. Merge local ↔ cloud (protégé par les pending)
      await _cache.mergeFromCloud(
        cloudMembres: remoteMembres,
        cloudCultes: remoteCultes,
        cloudCotisations: remoteCotisations,
        pendingMembreIds: pendingMembreIds,
        pendingCulteIds: pendingCulteIds,
        pendingCotisationIds: pendingCotisationIds,
      );

      return SyncResult(
        success: true,
        operationsPushed: pushed,
        operationsFailed: failed,
        membresRemote: remoteMembres.length,
        cultesRemote: remoteCultes.length,
        cotisationsRemote: remoteCotisations.length,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        operationsPushed: pushed,
        operationsFailed: failed,
        error: 'Erreur de synchronisation: $e',
      );
    }
  }

  /// Pousse une seule [SyncOperation] vers le serveur avec retry exponentiel.
  Future<void> _pushOperationWithRetry(SyncOperation op) async {
    int delaySeconds = 1;

    for (int attempt = 0;
        attempt < KasedConstants.syncMaxRetries;
        attempt++) {
      try {
        final payload =
            jsonDecode(op.payloadJson) as Map<String, dynamic>;
        payload['updated_at'] = op.updatedAt?.toIso8601String() ??
            op.createdAt.toIso8601String();

        if (op.entityType == 'membre') {
          if (op.type == 'CREATE') {
            await _api.createMembre(payload);
          } else if (op.type == 'UPDATE') {
            await _api.updateMembre(op.entityId, payload);
          } else if (op.type == 'DELETE') {
            await _api.deleteMembre(op.entityId);
          }
        } else if (op.entityType == 'culte') {
          if (op.type == 'CREATE') {
            await _api.createCulte(payload);
          } else if (op.type == 'UPDATE') {
            await _api.updateCulte(op.entityId, payload);
          } else if (op.type == 'DELETE') {
            await _api.deleteCulte(op.entityId);
          }
        } else if (op.entityType == 'cotisation') {
          if (op.type == 'CREATE') {
            await _api.createCotisations([payload]);
          } else if (op.type == 'UPDATE') {
            await _api.updateCotisation(op.entityId, payload);
          }
        }
        return; // Succès
      } catch (e) {
        if (attempt < KasedConstants.syncMaxRetries - 1) {
          debugPrint(
              'Sync: op ${op.isarId} tentative ${attempt + 1}/${KasedConstants.syncMaxRetries} échouée, '
              'nouvel essai dans ${delaySeconds}s: $e');
          await Future.delayed(Duration(seconds: delaySeconds));
          delaySeconds *= 2; // Backoff exponentiel
        } else {
          rethrow;
        }
      }
    }
  }
}
