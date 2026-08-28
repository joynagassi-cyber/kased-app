/// Provider Riverpod pour la gestion des mises à jour.
///
/// Ce provider vérifie périodiquement s'il existe une nouvelle version
/// sur GitHub Releases et gère l'état du processus de mise à jour
/// (vérification, téléchargement, installation).
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/updates/app_update_model.dart';
import '../core/updates/update_config.dart';
import '../core/updates/update_service.dart';

part 'update_provider.g.dart';

@Riverpod(keepAlive: true)
class UpdateNotifier extends _$UpdateNotifier {
  late final UpdateService _service;
  Timer? _checkTimer;

  @visibleForTesting
  set service(UpdateService s) => _service = s;

  @override
  Future<AppUpdateCheckResult> build() async {
    _service = UpdateService();

    // Vérification initiale au démarrage
    final result = await _checkAndUpdate();
    _scheduleNextCheck();

    return result;
  }

  Future<AppUpdateCheckResult> _checkAndUpdate() async {
    state = const AsyncValue.loading();

    final result = await _service.checkForUpdate();

    // Stocker le dernier code de version vu pour éviter les rappels constants
    if (result.hasUpdate) {
      final prefs = await SharedPreferences.getInstance();
      final lastSeen = prefs.getInt(UpdateConfig.lastSeenVersionCodeKey) ?? 0;
      if (lastSeen < result.update!.versionCode) {
        await prefs.setInt(UpdateConfig.lastSeenVersionCodeKey, result.update!.versionCode);
        debugPrint('[UpdateNotifier] Nouveau code de version enregistré: ${result.update!.versionCode}');
      }
    }

    state = AsyncValue.data(result);
    return result;
  }

  /// Programme la vérification suivante (toutes les 6 heures).
  void _scheduleNextCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(hours: 6), (_) async {
      if (state.hasValue && !state.value!.hasUpdate) {
        await _checkAndUpdate();
      }
    });
  }

  /// Déclenche manuellement une vérification.
  Future<void> checkNow() async {
    await _checkAndUpdate();
  }

  /// Télécharge l'APK et lance l'installation automatique.
  ///
  /// Retourne true si le téléchargement et l'installation ont réussi.
  Future<bool> downloadAndInstall(AppUpdate update) async {
    // Mettre à jour l'état pour refléter le téléchargement en cours
    state = AsyncValue.data(
      AppUpdateCheckResult.available(update),
    );

    // Télécharger l'APK avec suivi de progression
    String? apkPath;
    try {
      apkPath = await _service.downloadApk(
        update: update,
        onProgress: (received, total) {
          debugPrint('[UpdateService] Progression: ${(received / total * 100).toStringAsFixed(0)}%');
        },
      );

      if (apkPath == null) {
        debugPrint('[UpdateService] Échec du téléchargement');
        state = AsyncValue.error(
          Exception('Téléchargement échoué'),
          StackTrace.current,
        );
        return false;
      }

      // Installer l'APK
      final installed = await _service.installApk(apkPath);
      if (installed) {
        debugPrint('[UpdateService] Installation lancée avec succès');
      } else {
        debugPrint('[UpdateService] Échec de l\'installation');
        state = AsyncValue.error(
          Exception('Installation échouée'),
          StackTrace.current,
        );
      }
      return installed;
    } catch (e) {
      debugPrint('[UpdateService] Erreur download/install: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  void dispose() {
    _checkTimer?.cancel();
  }
}
