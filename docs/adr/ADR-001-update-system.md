# ADR-001 : Système de Mise à Jour Auto (InsForge Storage)

## État
Accepté

## Contexte
L'application Kased doit pouvoir recevoir des mises à jour sans passer par Google Play Store, car elle est distribuée en side-load (APK direct). Le système doit être autonome, sécurisé, et facile à maintenir.

## Décision
Implémenter un système de mise à jour auto utilisant **InsForge Storage** comme CDN pour héberger les APKs et un manifeste JSON de version.

### Architecture
```
┌─────────────────────────────────────────────────────────────────────────┐
│                         INSFORGE STORAGE                                │
│  Bucket: app-updates (public)                                           │
│  ├── manifest.json      → Version, URL APK, changelog, force_update    │
│  └── X.Y.Z.apk          → Fichier APK téléchargeable                   │
└─────────────────────────────────────────────────────────────────────────┘
                              │
                              ▼ GET /api/storage/object/public/...
┌─────────────────────────────────────────────────────────────────────────┐
│                         FLUTTER APP                                     │
│  1. UpdateService.checkForUpdate()                                     │
│     → GET manifest.json → Compare versionCode local vs distant         │
│  2. UpdateService.downloadApk()                                        │
│     → GET APK → Stockage local (Download/) → SHA-256 verification      │
│  3. UpdateService.installApk()                                         │
│     → MethodChannel → AppUpdatePlugin.kt → Intent d'installation       │
└─────────────────────────────────────────────────────────────────────────┘
```

## Composants

### 1. Modèles (`lib/core/updates/app_update_model.dart`)
```dart
class AppUpdate {
  final String versionName;    // "1.2.0"
  final int versionCode;       // 1020001
  final String downloadUrl;    // URL APK
  final String changelog;      // Texte des changements
  final bool forceUpdate;      // true = bloque l'app
  final String? sha256;        // Hash pour vérification
}

class AppUpdateCheckResult {
  final UpdateStatus status;   // none, available, required, error
  final AppUpdate? update;
}
```

### 2. Configuration (`lib/core/updates/update_config.dart`)
```dart
class UpdateConfig {
  static const String bucket = 'app-updates';
  static const String manifestFileName = 'manifest.json';
  
  // URLs inspirées de InsForgeConfig
  static String get manifestUrl => 
    '${InsForgeConfig.baseUrl}/api/storage/object/public/$bucket/$manifestFileName';
}
```

### 3. Service (`lib/core/updates/update_service.dart`)
```dart
class UpdateService {
  final Dio _dio;  // Avec headers InsForge
  
  // 1. Vérifier version
  Future<AppUpdateCheckResult> checkForUpdate();
  
  // 2. Télécharger APK avec progression
  Future<String?> downloadApk({
    required AppUpdate update,
    void Function(int, int)? onProgress,
  });
  
  // 3. Installer via MethodChannel
  Future<bool> installApk(String apkPath);
}
```

### 4. Provider Riverpod (`lib/providers/update_provider.dart`)
```dart
@Riverpod(keepAlive: true)
class UpdateNotifier extends _$UpdateNotifier {
  // Vérif auto au démarrage + toutes les 6h
  // Stocke lastSeenVersionCode dans SharedPreferences
  
  Future<bool> downloadAndInstall(AppUpdate update);
}
```

### 5. UI (`lib/widgets/update_dialog.dart`)
- Dialogue modal avec changelog
- Barre de progression pendant téléchargement
- Bouton "Mettre à jour" / "Plus tard"
- Bloquant si `forceUpdate: true`

### 6. Plugin Natif (`android/.../AppUpdatePlugin.kt`)
```kotlin
class AppUpdatePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
  // installApk → FileProvider → Intent.ACTION_VIEW
}
```

## Workflow de Déploiement

### Étape 1: Modifier la version dans le code Flutter
```yaml
# pubspec.yaml
version: 1.2.0+1  # X.Y.Z+W
```

### Étape 2: Builder l'APK
```bash
cd cotis_app
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

### Étape 3: Calculer le SHA-256 (optionnel mais recommandé)
```bash
sha256sum build/app/outputs/apk/release/app-arm64-v8a-release.apk
```

### Étape 4: Mettre à jour le manifeste
```json
{
  "version_name": "1.2.0",
  "version_code": 1020001,
  "download_url": "https://pu74z8pe.us-east.insforge.app/api/storage/object/public/app-updates/1.2.0.apk",
  "changelog": "• Correction de bugs\n• Nouvelle feature",
  "force_update": false,
  "published_at": "2026-08-26T10:00:00Z",
  "sha256": "abc123..."
}
```

**Formule version_code** : `MAJOR * 1000000 + MINOR * 1000 + PATCH * 1 + BUILD`
- Ex: v1.2.3 build 1 = `1*1000000 + 2*1000 + 3*1 + 1 = 1002004`

### Étape 5: Uploader sur InsForge
```bash
# Upload APK
npx @insforge/cli storage upload cotis_app/docs/1.2.0.apk \
  --bucket app-updates \
  --file build/app/outputs/apk/release/app-arm64-v8a-release.apk

# Upload manifest
npx @insforge/cli storage upload cotis_app/docs/manifest.json \
  --bucket app-updates
```

### Étape 6: Vérifier
```bash
# Vérifier que le manifeste est accessible
curl -s "https://pu74z8pe.us-east.insforge.app/api/storage/object/public/app-updates/manifest.json"

# Lister les objets
npx @insforge/cli storage list-objects app-updates
```

## Permissions Requises (Android)

### AndroidManifest.xml
```xml
<!-- Déjà ajouté automatiquement -->
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" 
                   android:maxSdkVersion="32"/>
```

### FileProvider (déjà configuré)
```xml
<!-- AndroidManifest.xml -->
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.flutter.fileprovider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/file_paths" />
</provider>
```

## Tests Unitaires

### Tester le service (mock)
```dart
test('checkForUpdate returns available when remote version is higher', () async {
  final mockDio = MockDio();
  when(mockDio.get(any)).thenAnswer((_) async => Response(
    data: {'version_code': 1020001, 'download_url': '...'},
    statusCode: 200,
  ));
  
  final service = UpdateService(dio: mockDio);
  final result = await service.checkForUpdate();
  
  expect(result.hasUpdate, true);
  expect(result.update?.versionName, '1.2.0');
});
```

## Monitoring & Debug

### Logs importantes
```
[UpdateService] Version locale : 1.1.9 (code=1019001)
[UpdateService] Version distante : 1.2.0 (code=1020001)
[UpdateService] Mise à jour disponible : 1.2.0
[UpdateService] Téléchargement : 45%
[UpdateService] APK téléchargé : /storage/emulated/0/Download/Kased-v1.2.0.apk
[UpdateService] Installation lancée
```

### Vérifier l'état local
```dart
// Dans un widget
final state = ref.watch(updateNotifierProvider);
debugPrint('Status: ${state.value?.status}');
debugPrint('Has update: ${state.value?.hasUpdate}');
```

## Dépannage

### Problème : "Manifest non trouvé"
**Cause** : Bucket inexistant ou fichier manquant
```bash
# Vérifier le bucket
npx @insforge/cli storage list-objects app-updates

# Vérifier le fichier
npx @insforge/cli storage download manifest.json --bucket app-updates
```

### Problème : "Permission denied"
**Cause** : Permissions Android manquantes
```bash
# Demander manuellement (ADB)
adb shell pm grant com.kasedapp android.permission.MANAGE_EXTERNAL_STORAGE
```

### Problème : "Installation échouée"
**Cause** : Sources inconnues désactivées
**Solution** : Demander à l'utilisateur d'activer dans Paramètres → Sécurité

### Problème : Version ne change pas
**Cause** : version_code pas augmenté
**Solution** : Vérifier la formule de calcul du version_code

## Fichiers Clés à Modifier

| Tâche | Fichier(s) |
|-------|-----------|
| Changer la version | `pubspec.yaml` |
| Modifier le manifeste | `docs/manifest.json` |
| Ajouter une feature MAJ | `lib/core/updates/` |
| Modifier l'UI dialogue | `lib/widgets/update_dialog.dart` |
| Changer le comportement | `lib/providers/update_provider.dart` |

## Bonnes Pratiques

1. **Toujours augmenter version_code** à chaque release
2. **Garder le changelog** à jour dans le manifeste
3. **Utiliser SHA-256** pour vérifier l'intégrité des APKs
4. **Ne pas utiliser force_update** sauf pour les correctifs critiques
5. **Tester sur appareil physique** avant production

## Historique

| Date | Version | Changement |
|------|---------|-----------|
| 2026-08-26 | 1.0.0 | Création du système |

---

**Voir aussi** :
- `docs/UPDATE_SYSTEM.md` — Documentation technique complète
- `lib/core/updates/` — Code source
- `android/app/src/main/kotlin/com/kasedapp/AppUpdatePlugin.kt` — Plugin natif
