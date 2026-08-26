/// Service de vérification et téléchargement des mises à jour.
///
/// Ce service :
/// 1. Récupère le manifeste JSON depuis InsForge Storage
/// 2. Compare la version distante avec la version locale
/// 3. Télécharge l'APK si une MAJ est disponible
/// 4. Installe l'APK automatiquement via un MethodChannel natif
library;

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

import 'app_update_model.dart';
import 'update_config.dart';

class UpdateService {
  static const MethodChannel _channel = MethodChannel('kased_app/update');

  final Dio _dio;

  UpdateService({Dio? dio}) : _dio = dio ?? Dio();

  // ── Vérification de version ────────────────────────────────────────────────

  /// Vérifie s'il existe une nouvelle version et la compare à la version locale.
  ///
  /// Retourne un [AppUpdateCheckResult] contenant le statut et l'update si applicable.
  /// La comparaison de version utilise le [versionCode] (entier), pas le nom de version.
  Future<AppUpdateCheckResult> checkForUpdate() async {
    try {
      final localInfo = await PackageInfo.fromPlatform();
      final localVersionCode = _parseVersionCode(localInfo.buildNumber);
      final localVersionName = localInfo.version;

      debugPrint(
          '[UpdateService] Version locale : $localVersionName (code=$localVersionCode)');

      final response = await _dio
          .get(UpdateConfig.manifestUrl)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('[UpdateService] Manifest non trouvé (status=${response.statusCode})');
        return AppUpdateCheckResult.none();
      }

      // Le manifest peut être un objet direct ou contenu dans un champ "data"
      Map<String, dynamic> json;
      final data = response.data;
      if (data is Map) {
        json = data.cast<String, dynamic>();
      } else if (data is String) {
        json = jsonDecode(data) as Map<String, dynamic>;
      } else {
        return AppUpdateCheckResult.none();
      }

      final update = AppUpdate.fromJson(json);

      if (update.versionCode == 0 || update.downloadUrl.isEmpty) {
        debugPrint('[UpdateService] Manifest invalide (versionCode=0 ou url vide)');
        return AppUpdateCheckResult.none();
      }

      debugPrint(
          '[UpdateService] Version distante : ${update.versionName} (code=${update.versionCode})');

      if (update.versionCode <= localVersionCode) {
        debugPrint('[UpdateService] Aucune mise à jour disponible');
        return AppUpdateCheckResult.none();
      }

      debugPrint('[UpdateService] Mise à jour disponible : ${update.versionName}');
      return AppUpdateCheckResult.available(update);
    } on DioException catch (e) {
      debugPrint('[UpdateService] Erreur vérification : ${e.message}');
      // Timeout ou erreur réseau → on ne bloque pas l'app
      return AppUpdateCheckResult.none();
    } catch (e) {
      debugPrint('[UpdateService] Erreur inattendue : $e');
      return AppUpdateCheckResult.none();
    }
  }

  // ── Téléchargement ─────────────────────────────────────────────────────────

  /// Télécharge l'APK de l'update et retourne le chemin local.
  ///
  /// Le pourcentage de progression est émis via le callback [onProgress].
  /// Retourne null si le téléchargement échoue.
  Future<String?> downloadApk({
    required AppUpdate update,
    void Function(int downloaded, int total)? onProgress,
  }) async {
    try {
      // Demander la permission STORAGE pour Android < 13
      if (Platform.isAndroid) {
        final storagePerm = await Permission.storage.request();
        if (!storagePerm.isGranted) {
          debugPrint('[UpdateService] Permission storage refusée');
          return null;
        }
      }

      // Utiliser le répertoire download pour Android 13+
      final String appDir;
      if (Platform.isAndroid) {
        if (await Permission.manageExternalStorage.request().isGranted) {
          // Android 13+ avec permission managée
          final dir = await getExternalStorageDirectory();
          appDir = dir?.path ?? '/storage/emulated/0/Download';
        } else {
          // Fallback : répertoire download
          appDir = '/storage/emulated/0/Download';
        }
      } else {
        final dir = await getApplicationSupportDirectory();
        appDir = dir.path;
      }

      final file = File('$appDir/Kased-v${update.versionName}.apk');

      await _dio.download(
        update.downloadUrl,
        file.path,
        onReceiveProgress: (received, total) {
          if (onProgress != null && total > 0) {
            onProgress(received, total);
          }
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 10),
          followRedirects: true,
          maxRedirects: 5,
        ),
      );

      // Vérification SHA-256 si fournie
      if (update.sha256 != null && update.sha256!.isNotEmpty) {
        final bytes = await file.readAsBytes();
        final hash = sha256.convert(bytes).toString();
        if (hash != update.sha256!) {
          debugPrint('[UpdateService] Vérification SHA-256 échouée, suppression de l\'APK');
          await file.delete();
          return null;
        }
      }

      debugPrint('[UpdateService] APK téléchargé : ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('[UpdateService] Erreur téléchargement : $e');
      return null;
    }
  }

  // ── Installation ───────────────────────────────────────────────────────────

  /// Installe l'APK téléchargé via le MethodChannel natif.
  ///
  /// Retourne true si l'installation a été lancée avec succès.
  Future<bool> installApk(String apkPath) async {
    try {
      final file = File(apkPath);
      if (!await file.exists()) {
        debugPrint('[UpdateService] Fichier APK introuvable : $apkPath');
        return false;
      }

      debugPrint('[UpdateService] Installation lancée : $apkPath');
      final result = await _channel.invokeMethod('installApk', {
        'apkPath': apkPath,
      });
      return result == true;
    } catch (e) {
      debugPrint('[UpdateService] Erreur installation : $e');
      return false;
    }
  }
}

// ── Helper pour parser le version code ───────────────────────────────────────

int _parseVersionCode(String buildNumber) {
  final parsed = int.tryParse(buildNumber);
  return parsed ?? 0;
}
