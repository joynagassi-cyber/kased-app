# Guide Opérationnel — Mise à Jour Kased App

> **Ce guide est destiné à l'agent Claude Code.** Suivez ces étapes à la lettre pour maintenir le système de mise à jour.

## Quick Reference

### Commandes Essentielles

```bash
# Builder l'APK
cd cotis_app
flutter build apk --release --target-platform android-arm64 --split-per-abi

# Créer la release GitHub
gh release create v1.2.0+1 \
  --title "Kased v1.2.0+1" \
  --notes "Changelog..." \
  build/app/outputs/apk/release/app-arm64-v8a-release.apk \
  --name "kased-v1.2.0+1.apk"

# Vérifier la release
gh release view v1.2.0+1

# Analyser le code
flutter analyze lib/core/updates/ lib/providers/update_provider.dart
```

### URLs Clés

| Élément | URL |
|---------|-----|
| API GitHub Releases | `https://api.github.com/repos/joynagassi-cyber/kased-app/releases/latest` |
| Download APK | `https://github.com/joynagassi-cyber/kased-app/releases/download/vX.Y.Z+W/kased-vX.Y.Z+W.apk` |
| Page Release | `https://github.com/joynagassi-cyber/kased-app/releases/tag/vX.Y.Z+W` |

### Fichiers Modifiés à Chaque MAJ

```
pubspec.yaml                              # version: X.Y.Z+W
```

## Workflow Complet

### 1. Préparation (avant build)
```bash
# Vérifier que tout est à jour
cd cotis_app
flutter pub get
flutter analyze

# Modifier la version
# Fichier: pubspec.yaml
version: X.Y.Z+W  # Ex: 1.2.0+1
```

### 2. Build
```bash
flutter build apk --release --target-platform android-arm64 --split-per-abi
# Output: build/app/outputs/apk/release/app-arm64-v8a-release.apk
```

### 3. Création de la Release GitHub
```bash
# Créer un tag git
git tag v1.2.0+1
git push origin v1.2.0+1

# Créer la release avec l'APK en asset
gh release create v1.2.0+1 \
  --title "Kased v1.2.0+1" \
  --notes "## Quoi de neuf dans v1.2.0+1

### Nouvelles fonctionnalités
- Feature 1
- Feature 2

### Corrections
- Bug fix 1
" \
  build/app/outputs/apk/release/app-arm64-v8a-release.apk \
  --name "kased-v1.2.0+1.apk"
```

### 4. Vérification
```bash
# Liste des releases
gh release list --limit 5

# Détails de la dernière release
gh release view --json tagName,url,assets

# Test API
gh api repos/joynagassi-cyber/kased-app/releases/latest
```

### 5. Test sur appareil
```bash
# Télécharger l'APK
gh release download v1.2.0+1 -d . --pattern "*.apk"

# Installer
adb install kased-v1.2.0+1.apk

# Ouvrir l'app et vérifier le badge "NEW" dans Profil
```

## Structure des Fichiers

```
cotis_app/
├── lib/
│   ├── core/
│   │   └── updates/
│   │       ├── app_update_model.dart    # Modèles de données
│   │       ├── update_config.dart       # Configuration GitHub API
│   │       └── update_service.dart      # Logique métier
│   ├── providers/
│   │   ├── update_provider.dart         # Provider Riverpod
│   │   └── update_provider.g.dart       # Code généré
│   └── widgets/
│       └── update_dialog.dart           # UI dialogue
├── android/
│   └── app/
│       └── src/
│           └── main/
│               ├── kotlin/
│               │   └── com/kasedapp/
│               │       ├── AppUpdatePlugin.kt    # Plugin natif
│               │       └── MainActivity.kt       # Enregistrement plugin
│               └── res/
│                   └── xml/
│                       └── file_paths.xml        # FileProvider config
└── docs/
    ├── UPDATE_SYSTEM.md               # Doc technique
    ├── UPDATE_GUIDE.md                # Ce fichier
    └── README-UPDATE.md               # Quick start
```

## Vérifications Avant Commit

```bash
cd cotis_app

# 1. Analyser
flutter analyze

# 2. Tester (si tests existent)
flutter test

# 3. Vérifier le provider
grep -r "update_provider" lib/ --include="*.dart"
```

## Problèmes Courants

| Symptôme | Cause | Solution |
|----------|-------|----------|
| Badge "NEW" n'apparaît pas | Tag GitHub mal formaté | Vérifier `vX.Y.Z+W` |
| "Release non trouvée" | API GitHub 404 | Vérifier la release existe |
| Téléchargement échoue | Asset APK manquant | Vérifier l'asset dans la release |
| Installation bloquée | Sources inconnues | Paramètres → Sécurité |
| Analyse flutter échoue | Import manquant | Vérifier pubspec.yaml |

## Notes Techniques

1. **Le provider se vérifie toutes les 6 heures** automatiquement
2. **Au redémarrage**, vérification manuelle via `didChangeAppLifecycleState`
3. **Le changelog** est extrait du body de la release GitHub
4. **force_update: false** par défaut (GitHub ne supporte pas force_update)
5. **SharedPreferences** stocke le dernier versionCode vu (clé: `update_last_seen_version_code`)

## Variables d'Environnement

Aucune variable d'environnement spécifique. L'API GitHub est publique.

## Dépendances

```yaml
# pubspec.yaml
dependencies:
  apk_installer: ^0.0.4  # Plugin natif pour installation APK
```

## Liens

- **Documentation technique** : `docs/UPDATE_SYSTEM.md`
- **Quick start** : `docs/README-UPDATE.md`
- **Repository GitHub** : `https://github.com/joynagassi-cyber/kased-app`
- **API GitHub** : `https://docs.github.com/en/rest/releases`
