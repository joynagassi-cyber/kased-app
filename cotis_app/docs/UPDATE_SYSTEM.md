# Système de Mise à Jour Auto - Kased App

## Vue d'ensemble

Ce système permet de distribuer des mises à jour de l'application Android sans passer par le Google Play Store, en utilisant InsForge Storage.

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   InsForge      │────▶│   Flutter App    │────▶│   Android       │
│   Storage       │     │   (UpdateService)│     │   Installer     │
│                 │     │                  │     │   (Native)      │
│ • manifest.json │     │ • Vérif. version │     │                 │
│ • APK files     │     │ • Téléchargement │     │ • FileProvider  │
│                 │     │ • Installation   │     │ • Intent system │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

## Configuration InsForge

### 1. Créer un bucket Storage

Sur votre instance InsForge, créer un bucket nommé `app-updates` :

```bash
# Via l'interface InsForge ou API
```

### 2. Structure du manifest

Créer un fichier `manifest.json` dans le bucket `app-updates` :

```json
{
  "version_name": "1.2.0",
  "version_code": 1020001,
  "download_url": "https://pu74z8pe.us-east.insforge.app/api/storage/object/public/app-updates/1.2.0.apk",
  "changelog": "• Correction de bugs mineurs\n• Améliorations des performances\n• Nouvelle fonctionnalité de synchronisation",
  "force_update": false,
  "published_at": "2026-08-26T10:00:00Z",
  "sha256": ""
}
```

**Champs obligatoires :**
- `version_name` : Version sémantique (ex: "1.2.0")
- `version_code` : Code entier pour comparaison (ex: 1020001 = v1.2.0 build 1)
- `download_url` : URL complète vers l'APK
- `changelog` : Description des changements (texte brut avec \n)
- `force_update` : true = bloque l'app jusqu'à mise à jour

**Champ optionnel :**
- `sha256` : Hash SHA-256 de l'APK pour vérification d'intégrité

### 3. Upload des APK

```bash
# Upload du manifest
insforge storage upload app-updates/manifest.json docs/UPDATE_MANIFEST_EXAMPLE.md

# Upload de l'APK
insforge storage upload app-updates/1.2.0.apk build/app/outputs/apk/release/app-release.apk
```

## Fonctionnement

### Cycle de vie

1. **Au démarrage** : Le provider vérifie la version distante vs locale
2. **Si MAJ disponible** : 
   - Dialogue modal apparaît (blockant si `force_update: true`)
   - Badge "NEW" dans l'écran Profil
3. **Téléchargement** : Progression affichée dans le dialogue
4. **Installation** : Lancement de l'Intent Android natif

### Permissions requises

Ajoutées automatiquement dans `AndroidManifest.xml` :
```xml
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>
```

### Vérification de sécurité

- Le SHA-256 est vérifié automatiquement si présent dans le manifest
- L'APK est stocké dans `/storage/emulated/0/Download/Kased-vX.Y.Z.apk`
- FileProvider sécurise l'accès au fichier pour l'installation

## API du Service

### Vérifier une mise à jour

```dart
final result = await ref.read(updateNotifierProvider.notifier).checkNow();
```

### Télécharger et installer

```dart
final success = await ref.read(updateNotifierProvider.notifier)
    .downloadAndInstall(update);
```

### État du provider

```dart
final state = ref.watch(updateNotifierProvider);
// state.value?.hasUpdate => true s'il y a une MAJ
// state.value?.update?.versionName => "1.2.0"
// state.value?.isRequired => true si force_update
```

## Intégration dans le code

### main.dart
- Import du provider et du dialogue
- Vérification au lancement et au retour au premier plan
- `UpdateCheckWrapper` affiche le dialogue si nécessaire

### profile_screen.dart
- Badge `_UpdateBadge` affiché dans la section "Application"
- Indique si une MAJ est disponible avec badge "NEW"

### Android
- `AppUpdatePlugin.kt` : Plugin natif pour l'installation
- `MainActivity.kt` : Enregistrement du plugin
- `file_paths.xml` : Configuration FileProvider

## Tests

### Test unitaire du service

```dart
test('checkForUpdate returns available when remote version is higher', () async {
  final service = UpdateService(dio: mockDio);
  final result = await service.checkForUpdate();
  expect(result.hasUpdate, true);
});
```

### Mock du service

```dart
// Dans les tests, injecter un mock
final mockService = MockUpdateService();
ref.overrideWithProvider(updateNotifierProvider, MockUpdateNotifierProvider(mockService));
```

## Déploiement

### 1. Construire l'APK

```bash
cd cotis_app
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

### 2. Upload sur InsForge

```bash
# Upload APK
insforge storage upload app-updates/1.2.0.apk build/app/outputs/apk/release/app-arm64-v8a-release.apk

# Upload manifest (avec nouvelle version)
insforge storage upload app-updates/manifest.json docs/UPDATE_MANIFEST_EXAMPLE.md
```

### 3. Vérifier

Lancer l'application et vérifier :
- Le badge "NEW" apparaît dans le profil
- Le dialogue de mise à jour s'affiche au démarrage
- Le téléchargement et l'installation fonctionnent

## Limitations et notes

1. **Android 8+** : L'installation automatique nécessite `REQUEST_INSTALL_PACKAGES`
2. **Android 11+** : Peut nécessiter `MANAGE_EXTERNAL_STORAGE` pour écrire dans Download
3. **Installation** : L'utilisateur doit accepter l'installation des inconnus dans les paramètres Android
4. **iOS** : Non supporté (APK uniquement)

## Résolution des problèmes

### Problème : "Permission denied"
```bash
adb shell pm grant com.kasedapp android.permission.MANAGE_EXTERNAL_STORAGE
```

### Problème : "Installation bloque"
Vérifier que :
- `REQUEST_INSTALL_PACKAGES` est présent dans AndroidManifest
- L'utilisateur a autorisé "Sources inconnues" dans les paramètres

### Problème : Manifest non trouvé
Vérifier que :
- Le bucket `app-updates` existe sur InsForge
- Le fichier `manifest.json` est dans le bucket
- L'URL est accessible publiquement

## Versioning

Format du `version_code` : `MAJOR * 1000000 + MINOR * 1000 + PATCH * 1 + BUILD`

Exemple : v1.2.3 build 1 = `1002003`
