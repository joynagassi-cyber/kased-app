/// Service de vérification et téléchargement des mises à jour.
///
/// Ce service vérifie directement sur GitHub Releases.
/// 1. Récupère la dernière release via l'API GitHub
/// 2. Compare la version distante avec la version locale
/// 3. Télécharge l'APK depuis GitHub
/// 4. Installe l'APK automatiquement via un MethodChannel natif
library;

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app_update_model.dart';
import 'update_config.dart';

class UpdateService {
  static const MethodChannel _channel = MethodChannel('kased_app/update');

  final Dio _dio;

  UpdateService({Dio? dio}) : _dio = dio ?? Dio(
        BaseOptions(
          headers: {'Accept': 'application/json'},
        ),
      );

  // ── Vérification de version ────────────────────────────────────────────────

  /// Vérifie s'il existe une nouvelle version sur GitHub Releases.
  Future<AppUpdateCheckResult> checkForUpdate() async {
    try {
      final localInfo = await PackageInfo.fromPlatform();
      final localVersionCode = _parseVersionCode(localInfo.buildNumber);
      final localVersionName = localInfo.version;

      debugPrint(
          '[UpdateService] Version locale : $localVersionName (code=$localVersionCode)');

      // Récupérer la dernière release GitHub
      final response = await _dio
          .get(UpdateConfig.githubReleasesUrl)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('[UpdateService] Release GitHub non trouvée (status=${response.statusCode})');
        return AppUpdateCheckResult.none();
      }

      final Map<String, dynamic> json = response.data;
      
      // Extraire la version depuis tag_name (format: v1.1.9+3)
      final String tagName = json['tag_name'] as String? ?? '';
      if (tagName.isEmpty) {
        debugPrint('[UpdateService] Tag name vide dans la release');
        return AppUpdateCheckResult.none();
      }

      // Parser la version: "v1.1.9+3" → versionName="1.1.9", versionCode=3
      final String versionStr = tagName.startsWith('v') 
          ? tagName.substring(1) 
          : tagName;
      
      final int plusIndex = versionStr.lastIndexOf('+');
      String versionName;
      int versionCode;
      
      if (plusIndex > 0) {
        versionName = versionStr.substring(0, plusIndex);
        versionCode = int.tryParse(versionStr.substring(plusIndex + 1)) ?? 0;
      } else {
        versionName = versionStr;
        versionCode = 0;
      }

      debugPrint('[UpdateService] Version distante : $versionName (code=$versionCode)');

      if (versionCode == 0 || versionCode <= localVersionCode) {
        debugPrint('[UpdateService] Aucune mise à jour disponible');
        return AppUpdateCheckResult.none();
      }

      // Trouver l'asset APK dans la release
      final List<dynamic> assets = json['assets'] ?? [];
      String? downloadUrl;

      for (final asset in assets) {
        final String name = asset['name'] as String? ?? '';
        if (name.endsWith('.apk')) {
          downloadUrl = asset['browser_download_url'] as String?;
          break;
        }
      }

      if (downloadUrl == null || downloadUrl.isEmpty) {
        debugPrint('[UpdateService] Aucun APK trouvé dans la release');
        return AppUpdateCheckResult.none();
      }

      // Construire l'objet AppUpdate
      final update = AppUpdate(
        versionName: versionName,
        versionCode: versionCode,
        downloadUrl: downloadUrl,
        changelog: json['body'] as String? ?? '',
        forceUpdate: false, // GitHub releases ne supportent pas force_update
        publishedAt: json['published_at'] != null
            ? DateTime.tryParse(json['published_at'] as String)
            : null,
      );

      debugPrint('[UpdateService] Mise à jour disponible : $versionName');
      return AppUpdateCheckResult.available(update);
    } on DioException catch (e) {
      debugPrint('[UpdateService] Erreur vérification : ${e.message}');
      return AppUpdateCheckResult.none();
    } catch (e) {
      debugPrint('[UpdateService] Erreur inattendue : $e');
      return AppUpdateCheckResult.none();
    }
  }

  // ── Téléchargement ─────────────────────────────────────────────────────────

  /// Télécharge l'APK de la release GitHub et retourne le chemin local.
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
          final dir = await getExternalStorageDirectory();
          appDir = dir?.path ?? '/storage/emulated/0/Download';
        } else {
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

      debugPrint('[UpdateService] APK téléchargé : ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('[UpdateService] Erreur téléchargement : $e');
      return null;
    }
  }

  // ── Installation ───────────────────────────────────────────────────────────

  /// Installe l'APK téléchargé via le MethodChannel natif.
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
