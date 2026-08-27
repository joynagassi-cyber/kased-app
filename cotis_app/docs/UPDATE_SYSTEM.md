# Système de Mise à Jour Auto - Kased App

## Vue d'ensemble

Ce système permet de distribuer des mises à jour de l'application Android sans passer par le Google Play Store, en utilisant directement **GitHub Releases**.

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   GitHub API    │────▶│   Flutter App    │────▶│   Android       │
│   Releases      │     │   (UpdateService)│     │   Installer     │
│                 │     │ • Vérif. version │     │   (Native)      │
│ • tag_name      │     │ • Téléchargement │     │                 │
│ • assets APK    │     │ • Installation   │     │ • FileProvider  │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

## Configuration GitHub

### Repository

- **Owner** : `joynagassi-cyber`
- **Repo** : `kased-app`
- **API** : `https://api.github.com/repos/joynagassi-cyber/kased-app/releases/latest`

### Format des versions

Les tags GitHub suivent le format : `vMAJOR.MINOR.PATCH+BUILDCODE`

Exemple : `v1.1.9+3`
- `versionName` = `1.1.9`
- `versionCode` = `3`

### Structure de la Release GitHub

Chaque release doit contenir :
- **Tag name** : `vX.Y.Z+W` (ex: `v1.1.9+3`)
- **Asset APK** : `kased-vX.Y.Z+W.apk`
- **Body** : Changelog au format Markdown

```markdown
## Quoi de neuf dans v1.1.9+3

### Nouvelles fonctionnalités
- Barre de filtrage avancée pour la liste des membres
- Tri par nom, date d'adhésion, statut actif/inactif
- Barre de filtrage pour la gestion des cultes
- Correction navigation après création d'un membre

### Corrections
- ...
```

## Fonctionnement

### Cycle de vie

1. **Au démarrage** : Le provider interroge l'API GitHub `releases/latest`
2. **Parsing** : Extrait `tag_name` et calcule `versionCode`
3. **Comparaison** : Si `versionCode > localVersionCode` → MAJ disponible
4. **Dialogue** : Modal apparaît avec changelog (blockant si `force_update: true`)
5. **Téléchargement** : Direct depuis `browser_download_url` de l'asset APK
6. **Installation** : Lancement de l'Intent Android natif

### Permissions requises

Ajoutées automatiquement dans `AndroidManifest.xml` :
```xml
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>
```

### Vérification de sécurité

- L'APK est téléchargé depuis GitHub CDN (fiable)
- Stocké dans `/storage/emulated/0/Download/Kased-vX.Y.Z.apk`
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
// state.value?.update?.versionName => "1.1.9"
// state.value?.isRequired => true si force_update
```

## Intégration dans le code

### Fichiers clés

```
lib/core/updates/
├── app_update_model.dart    # Modèles de données
├── update_config.dart       # Configuration GitHub API
└── update_service.dart      # Logique métier (API GitHub)

lib/providers/
├── update_provider.dart     # Provider Riverpod
└── update_provider.g.dart   # Code généré
```

### update_config.dart

```dart
class UpdateConfig {
  static const String repoOwner = 'joynagassi-cyber';
  static const String repoName = 'kased-app';
  static const String githubReleasesUrl =
      'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';
  static const String lastSeenVersionCodeKey = 'update_last_seen_version_code';
}
```

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

## Déploiement

### 1. Modifier la version

**Fichier** : `pubspec.yaml`
```yaml
version: 1.2.0+1  # format: MAJOR.MINOR.PATCH+BUILDCODE
```

### 2. Construire l'APK

```bash
cd cotis_app
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

Output : `build/app/outputs/apk/release/app-arm64-v8a-release.apk`

### 3. Créer la Release GitHub

Via l'interface GitHub ou la CLI :

```bash
# Créer un tag
git tag v1.2.0+1
git push origin v1.2.0+1

# Créer la release via gh CLI
gh release create v1.2.0+1 \
  --title "Kased v1.2.0+1" \
  --notes "## Quoi de neuf dans v1.2.0+1

### Nouvelles fonctionnalités
- Feature 1
- Feature 2" \
  build/app/outputs/apk/release/app-arm64-v8a-release.apk \
  --name "kased-v1.2.0+1.apk"
```

### 4. Vérifier

```bash
# Voir la release
gh release view v1.2.0+1

# Tester l'API
gh api repos/joynagassi-cyber/kased-app/releases/latest
```

## Tests

### Test unitaire du service

```dart
test('checkForUpdate returns available when remote version is higher', () async {
  final service = UpdateService();
  final result = await service.checkForUpdate();
  expect(result.hasUpdate, isTrue);
});
```

### Test de l'API GitHub

```bash
# Vérifier que la release est accessible
gh api repos/joynagassi-cyber/kased-app/releases/latest \
  --jq '{tag_name: .tag_name, assets: [.assets[] | {name: .name}]}'
```

## Limitations et notes

1. **Android 8+** : L'installation automatique nécessite `REQUEST_INSTALL_PACKAGES`
2. **Android 11+** : Peut nécessiter `MANAGE_EXTERNAL_STORAGE` pour écrire dans Download
3. **Installation** : L'utilisateur doit accepter l'installation des sources inconnues
4. **iOS** : Non supporté (APK uniquement)
5. **GitHub API** : Limité à 60 requêtes/heure sans authentification, 5000 avec token

## Résolution des problèmes

### Problème : Badge "NEW" n'apparaît pas
Vérifier que :
- Le tag GitHub existe au format `vX.Y.Z+W`
- L'APK est bien un asset de la release
- `versionCode` est supérieur à la version locale

### Problème : "Permission denied"
```bash
adb shell pm grant com.kasedapp android.permission.MANAGE_EXTERNAL_STORAGE
```

### Problème : "Installation bloque"
Vérifier que :
- `REQUEST_INSTALL_PACKAGES` est présent dans AndroidManifest
- L'utilisateur a autorisé "Sources inconnues" dans les paramètres

### Problème : Release non trouvée
```bash
# Vérifier la release
gh release list --limit 5

# Vérifier les assets
gh api repos/joynagassi-cyber/kased-app/releases/latest --jq '.assets'
```

## Versioning

Format du tag GitHub : `vMAJOR.MINOR.PATCH+BUILDCODE`

Exemple : `v1.2.3+1`
- `versionName` = `1.2.3`
- `versionCode` = `1`

Note : Le `versionCode` dans le tag correspond au build number dans `pubspec.yaml`, pas au code de version calculé (MAJOR * 1000000 + MINOR * 1000 + PATCH * 1 + BUILD).
