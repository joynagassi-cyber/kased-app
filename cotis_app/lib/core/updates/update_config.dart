/// Configuration dédiée au système de mise à jour auto.
///
/// Les URLs pointent vers l'API InsForge Storage avec authentification.
/// Le manifeste JSON est servi par l'API publique du bucket.
/// Les APK sont servis par l'API publique du bucket.
library;

import '../insforge/insforge_config.dart';

class UpdateConfig {
  UpdateConfig._();

  /// Bucket InsForge où sont stockés les fichiers de mise à jour.
  static const String bucket = 'app-updates';

  /// Nom du fichier manifeste dans le bucket.
  static const String manifestFileName = 'manifest.json';

  /// Extension des fichiers APK.
  static const String apkExtension = '.apk';

  /// Retourne l'URL API du manifeste JSON.
  /// Utilise le header apikey pour l'accès public au bucket.
  static String get manifestUrl =>
      '${InsForgeConfig.baseUrl}/api/storage/object/public/$bucket/$manifestFileName';

  /// Retourne l'URL API d'un APK pour une version donnée.
  static String apkUrl(String versionName) =>
      '${InsForgeConfig.baseUrl}/api/storage/object/public/$bucket/${versionName}$apkExtension';

  /// Clé SharedPreferences pour stocker le code de version vu.
  static const String lastSeenVersionCodeKey = 'update_last_seen_version_code';
}
