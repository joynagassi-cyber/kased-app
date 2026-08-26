/// Modèle de donnée pour le manifeste de mise à jour.
///
/// Ce fichier définit la structure JSON attendue par le serveur InsForge
/// pour décrire une nouvelle version disponible.
library;

/// Statut de la mise à jour.
enum UpdateStatus {
  /// Aucune mise à jour disponible.
  none,

  /// Une mise à jour est disponible mais n'est pas encore obligatoire.
  available,

  /// Une mise à jour est obligatoire (force_update: true).
  required,

  /// Vérification en cours.
  checking,

  /// Erreur lors de la vérification.
  error,
}

/// Représente une version disponible d'une application.
class AppUpdate {
  /// Numéro de version au format semver (ex: "1.2.0").
  final String versionName;

  /// Numéro de build (ex: 5).
  final int versionCode;

  /// URL directe vers le fichier APK (ou bundle).
  final String downloadUrl;

  /// Changements apportés dans cette version.
  final String changelog;

  /// Indique si cette mise à jour est obligatoire.
  final bool forceUpdate;

  /// Date de publication de cette version.
  final DateTime? publishedAt;

  /// SHA-256 du fichier APK pour vérification d'intégrité.
  /// Peut être null si non fourni par le serveur.
  final String? sha256;

  const AppUpdate({
    required this.versionName,
    required this.versionCode,
    required this.downloadUrl,
    required this.changelog,
    this.forceUpdate = false,
    this.publishedAt,
    this.sha256,
  });

  /// Crée une instance depuis un JSON brut (format InsForge).
  factory AppUpdate.fromJson(Map<String, dynamic> json) {
    return AppUpdate(
      versionName: json['version_name'] as String? ?? '',
      versionCode: int.tryParse(json['version_code']?.toString() ?? '0') ?? 0,
      downloadUrl: json['download_url'] as String? ?? '',
      changelog: json['changelog'] as String? ?? '',
      forceUpdate: json['force_update'] as bool? ?? false,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
      sha256: json['sha256'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version_name': versionName,
      'version_code': versionCode,
      'download_url': downloadUrl,
      'changelog': changelog,
      'force_update': forceUpdate,
      'published_at': publishedAt?.toIso8601String(),
      'sha256': sha256,
    };
  }

  AppUpdate copyWith({
    String? versionName,
    int? versionCode,
    String? downloadUrl,
    String? changelog,
    bool? forceUpdate,
    DateTime? publishedAt,
    String? sha256,
  }) {
    return AppUpdate(
      versionName: versionName ?? this.versionName,
      versionCode: versionCode ?? this.versionCode,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      changelog: changelog ?? this.changelog,
      forceUpdate: forceUpdate ?? this.forceUpdate,
      publishedAt: publishedAt ?? this.publishedAt,
      sha256: sha256 ?? this.sha256,
    );
  }
}

/// Résultat complet de la vérification de mise à jour.
class AppUpdateCheckResult {
  final UpdateStatus status;
  final AppUpdate? update;
  final String? errorMessage;

  const AppUpdateCheckResult({
    this.status = UpdateStatus.none,
    this.update,
    this.errorMessage,
  });

  factory AppUpdateCheckResult.checking() =>
      const AppUpdateCheckResult(status: UpdateStatus.checking);

  factory AppUpdateCheckResult.error(String message) =>
      AppUpdateCheckResult(status: UpdateStatus.error, errorMessage: message);

  factory AppUpdateCheckResult.available(AppUpdate update) =>
      AppUpdateCheckResult(status: update.forceUpdate ? UpdateStatus.required : UpdateStatus.available, update: update);

  factory AppUpdateCheckResult.none() =>
      const AppUpdateCheckResult(status: UpdateStatus.none);

  bool get isRequired => status == UpdateStatus.required;
  bool get isAvailable => status == UpdateStatus.available;
  bool get isChecking => status == UpdateStatus.checking;
  bool get isError => status == UpdateStatus.error;
  bool get hasUpdate => isRequired || isAvailable;
}
