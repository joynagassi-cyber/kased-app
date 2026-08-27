/// Configuration dédiée au système de mise à jour auto.
///
/// Les mises à jour sont vérifiées directement sur GitHub Releases.
library;

class UpdateConfig {
  UpdateConfig._();

  /// Repository GitHub pour les releases.
  static const String repoOwner = 'joynagassi-cyber';
  static const String repoName = 'kased-app';

  /// URL de l'API GitHub pour récupérer les dernières releases.
  static const String githubReleasesUrl =
      'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';

  /// Pattern pour extraire le version code du build number (format: x.x.x+code).
  static const String versionPattern = r'\+(\d+)$';

  /// Clé SharedPreferences pour stocker le code de version vu.
  static const String lastSeenVersionCodeKey = 'update_last_seen_version_code';

  /// Nom du fichier APK dans la release GitHub.
  static String apkAssetName(String versionName) =>
      'kased-$versionName.apk';
}
