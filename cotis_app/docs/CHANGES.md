# Fichiers Modifiés — Système de Mise à Jour

## Fichiers Créés

### 1. Core Updates
- `lib/core/updates/app_update_model.dart` — Modèles de données
- `lib/core/updates/update_config.dart` — Configuration URLs
- `lib/core/updates/update_service.dart` — Service de vérification/téléchargement/installation

### 2. Providers
- `lib/providers/update_provider.dart` — Provider Riverpod
- `lib/providers/update_provider.g.dart` — Code généré

### 3. Widgets
- `lib/widgets/update_dialog.dart` — Dialogue UI de mise à jour

### 4. Android Native
- `android/app/src/main/kotlin/com/kasedapp/AppUpdatePlugin.kt` — Plugin natif
- `android/app/src/main/res/xml/file_paths.xml` — FileProvider config

### 5. Documentation
- `docs/UPDATE_SYSTEM.md` — Documentation technique
- `docs/UPDATE_GUIDE.md` — Guide opérationnel
- `docs/DEPLOYMENT_CHECKLIST.md` — Checklist
- `docs/manifest.json` — Exemple de manifeste
- `docs/adr/ADR-001-update-system.md` — ADR

## Fichiers Modifiés

### 1. Configuration
- `pubspec.yaml` — Ajout de `apk_installer: ^0.0.4`

### 2. Android
- `android/app/src/main/AndroidManifest.xml` — Permissions + FileProvider
- `android/app/src/main/kotlin/com/kasedapp/MainActivity.kt` — Enregistrement plugin

### 3. Application
- `lib/main.dart` — Intégration provider + UpdateCheckWrapper
- `lib/screens/profile/profile_screen.dart` — Badge MAJ

## Dépendances Ajoutées

```yaml
dependencies:
  apk_installer: ^0.0.4  # Installation APK via plugin natif
```

## Permissions Ajoutées (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
```

## Components Clés

| Composant | Fichier | Rôle |
|-----------|---------|------|
| UpdateService | `lib/core/updates/update_service.dart` | Vérification, téléchargement, installation |
| UpdateNotifier | `lib/providers/update_provider.dart` | Provider Riverpod, state management |
| UpdateDialog | `lib/widgets/update_dialog.dart` | UI dialogue modal |
| AppUpdatePlugin | `android/.../AppUpdatePlugin.kt` | Installation native APK |

## URLs InsForge

- **Bucket** : `app-updates`
- **Manifest** : `https://pu74z8pe.us-east.insforge.app/api/storage/object/public/app-updates/manifest.json`
- **APK** : `https://pu74z8pe.us-east.insforge.app/api/storage/object/public/app-updates/X.Y.Z.apk`

## Méthodes Publics

### UpdateService
```dart
Future<AppUpdateCheckResult> checkForUpdate()
Future<String?> downloadApk({required AppUpdate update, void Function(int, int)? onProgress})
Future<bool> installApk(String apkPath)
```

### UpdateNotifier (Provider)
```dart
Future<void> checkNow()
Future<bool> downloadAndInstall(AppUpdate update)
```

## Intégration dans main.dart

```dart
// Import
import 'providers/update_provider.dart';
import 'widgets/update_dialog.dart';
import 'core/updates/app_update_model.dart';

// Dans build()
final updateState = ref.watch(updateNotifierProvider);

// UpdateCheckWrapper affiche le dialogue
builder: (context, child) {
  return UpdateCheckWrapper(
    updateState: updateState,
    child: OneSignalVerificationGate(child: child!),
  );
}
```

## Intégration dans profile_screen.dart

```dart
// Section "Application"
_UpdateBadge(colorScheme: colorScheme),

// Widget _UpdateBadge affichant le badge "NEW" si MAJ disponible
```
