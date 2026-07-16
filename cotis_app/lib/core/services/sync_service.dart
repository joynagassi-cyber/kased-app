import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/core/sync/sync_manager.dart';
import 'package:kased_app/core/constants.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/sync_operation.dart';
import 'package:kased_app/core/utils/uuid.dart';
import 'package:kased_app/core/sync/device_service.dart';

/// Résultat complet d'une opération de synchronisation.
///
/// Inclut les données mergées post-sync pour que le provider
/// puisse mettre à jour son état sans refaire les appels.
class SyncDataResult {
  final bool success;
  final List<Membre> mergedMembres;
  final List<Culte> mergedCultes;
  final List<Cotisation> mergedCotisations;
  final Map<String, dynamic>? dashboard;
  final String? error;

  const SyncDataResult({
    required this.success,
    this.mergedMembres = const [],
    this.mergedCultes = const [],
    this.mergedCotisations = const [],
    this.dashboard,
    this.error,
  });
}

/// Service de coordination de la synchronisation offline → cloud.
///
/// Responsabilités :
/// - Gestion du throttling ([_shouldSync], [_lastSyncAt])
/// - Anti-réentrance (une seule sync à la fois)
/// - Exécution du sync via [SyncManager]
/// - Rechargement local post-sync
/// - File d'attente d'opérations ([queueSyncOperation])
class SyncService {
  final InsForgeService _api;
  final LocalCache _cache;
  final SyncManager _syncManager;

  DateTime? _lastSyncAt;
  static const _syncThrottle = Duration(minutes: 5);

  SyncService(this._api, this._cache)
      : _syncManager = SyncManager(_api, _cache);

  /// Retourne true si le dernier sync date de plus de [_syncThrottle].
  bool shouldSync() {
    if (_lastSyncAt == null) return true;
    return DateTime.now().difference(_lastSyncAt!) > _syncThrottle;
  }

  /// Timestamp du dernier sync (pour vérification/réinitialisation).
  DateTime? get lastSyncAt => _lastSyncAt;

  /// Force la réinitialisation du timestamp (utile pour les tests).
  @visibleForTesting
  void resetLastSyncAt() => _lastSyncAt = null;

  /// Retourne le SyncManager sous-jacent (pour tests ou accès avancés).
  @visibleForTesting
  SyncManager get syncManager => _syncManager;

  /// Exécute une synchronisation complète.
  ///
  /// Retourne [SyncDataResult] avec les données mergées en cas de succès,
  /// ou un résultat d'erreur. Retourne `null` si offline ou déjà en cours.
  Future<SyncDataResult?> syncData({required bool isOffline}) async {
    if (isOffline) return null;

    final result = await _syncManager.runSync(
      isOffline: isOffline,
      lastSyncAt: _lastSyncAt,
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
      debugPrint('[SyncService] Erreur chargement dashboard post-sync: $e');
    }

    _lastSyncAt = DateTime.now();

    return SyncDataResult(
      success: true,
      mergedMembres: mergedMembres,
      mergedCultes: mergedCultes,
      mergedCotisations: mergedCotisations,
      dashboard: dashboardData,
    );
  }

  /// Ajoute une opération à la file d'attente de synchronisation.
  Future<void> queueSyncOperation(
    String type,
    String entityType,
    String entityId,
    Map<String, dynamic> payload,
  ) async {
    final now = DateTime.now();
    final deviceId = await DeviceService.getDeviceId();
    final op = SyncOperation()
      ..operationId = UuidUtils.generate()
      ..type = type
      ..entityType = entityType
      ..entityId = entityId
      ..payloadJson = jsonEncode(payload)
      ..createdAt = now
      ..updatedAt = now
      ..deviceId = deviceId;

    await _cache.saveSyncOp(op);
  }
}
