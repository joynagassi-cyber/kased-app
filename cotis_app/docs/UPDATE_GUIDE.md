# Guide Opérationnel — Mise à Jour Kased App

> **Ce guide est destiné à l'agent Claude Code.** Suivez ces étapes à la lettre pour maintenir le système de mise à jour.

## Quick Reference

### Commandes Essentielles

```bash
# Builder l'APK
cd cotis_app
flutter build apk --release --target-platform android-arm64 --split-per-abi

# Uploader sur InsForge
npx @insforge/cli storage upload <fichier> --bucket app-updates

# Vérifier le bucket
npx @insforge/cli storage list-objects app-updates

# Analyser le code
flutter analyze lib/core/updates/ lib/providers/update_provider.dart
```

### URLs Clés

| Élément | URL |
|---------|-----|
| Manifest | `https://pu74z8pe.us-east.insforge.app/api/storage/object/public/app-updates/manifest.json` |
| Bucket | `app-updates` |
| Projjet InsForge | `pu74z8pe.us-east.insforge.app` |

### Fichiers Modifiés à Chaque MAJ

```
pubspec.yaml                              # version: X.Y.Z+W
docs/manifest.json                        # version_code, download_url, changelog
build/app/outputs/apk/release/*.apk       # APK généré
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

### 3. Calcul SHA-256 (optionnel mais recommandé)
```bash
sha256sum build/app/outputs/apk/release/app-arm64-v8a-release.apk
# Copier le hash pour le manifeste
```

### 4. Mise à jour du manifeste
**Fichier** : `cotis_app/docs/manifest.json`

```json
{
  "version_name": "1.2.0",
  "version_code": 1020001,
  "download_url": "https://pu74z8pe.us-east.insforge.app/api/storage/object/public/app-updates/1.2.0.apk",
  "changelog": "• Feature 1\n• Bug fix 2",
  "force_update": false,
  "published_at": "2026-08-26T10:00:00Z",
  "sha256": "calculé_étape_3"
}
```

**Formule version_code** : `MAJOR * 1000000 + MINOR * 1000 + PATCH * 1 + BUILD`

### 5. Upload sur InsForge
```bash
# Upload APK
npx @insforge/cli storage upload cotis_app/docs/1.2.0.apk \
  --bucket app-updates \
  --file build/app/outputs/apk/release/app-arm64-v8a-release.apk

# Upload manifest
npx @insforge/cli storage upload cotis_app/docs/manifest.json \
  --bucket app-updates
```

### 6. Vérification
```bash
# Liste des fichiers
npx @insforge/cli storage list-objects app-updates

# Test du manifeste
curl -s "https://pu74z8pe.us-east.insforge.app/api/storage/object/public/app-updates/manifest.json"
```

### 7. Test sur appareil
```bash
# Installer l'APK
adb install build/app/outputs/apk/release/app-arm64-v8a-release.apk

# Ouvrir l'app et vérifier le badge "NEW" dans Profil
```

## Structure des Fichiers

```
cotis_app/
├── lib/
│   ├── core/
│   │   └── updates/
│   │       ├── app_update_model.dart    # Modèles de données
│   │       ├── update_config.dart       # Configuration URLs
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
    ├── manifest.json                  # Manifeste exemple
    ├── UPDATE_SYSTEM.md               # Doc technique
    └── adr/
        └── ADR-001-update-system.md   # Architecture decision record
```

## Vérifications Avant Commit

```bash
cd cotis_app

# 1. Analyser
flutter analyze

# 2. Tester (si tests existent)
flutter test

# 3. Vérifier les imports
grep -r "update_provider" lib/ --include="*.dart"

# 4. Vérifier le manifeste JSON
cat docs/manifest.json | python -m json.tool
```

## Commandes Utiles InsForge

```bash
# Voir la config du projet
npx @insforge/cli current

# Voir les buckets
npx @insforge/cli storage buckets

# Lister les objets d'un bucket
npx @insforge/cli storage list-objects <bucket>

# Télécharger un objet
npx @insforge/cli storage download <key> --bucket <bucket>

# Supprimer un objet
npx @insforge/cli storage delete <key> --bucket <bucket>
```

## Problèmes Courants

| Symptôme | Cause | Solution |
|----------|-------|----------|
| Badge "NEW" n'apparaît pas | version_code pas augmenté | Vérifier manifest.json |
| "Manifest non trouvé" | Bucket inexistant | `npx @insforge/cli storage buckets` |
| Téléchargement échoue | URL APK invalide | Vérifier download_url dans manifest |
| Installation bloquée | Sources inconnues | Paramètres → Sécurité |
| Analyse flutter échoue | Import manquant | Vérifier pubspec.yaml |

## Notes Techniques

1. **Le provider se vérifie toutes les 6 heures** automatiquement
2. **Au redémarrage**, vérification manuelle via `didChangeAppLifecycleState`
3. **Le SHA-256** est optionnel mais recommandé pour la sécurité
4. **force_update: true** bloque l'app jusqu'à installation
5. **SharedPreferences** stocke le dernier versionCode vu (clé: `update_last_seen_version_code`)

## Variables d'Environnement

Aucune variable d'environnement spécifique. Les URLs sont hardcodées dans `InsForgeConfig`.

## Dépendances

```yaml
# pubspec.yaml
dependencies:
  apk_installer: ^0.0.4  # Ajouté pour le système de MAJ
```

## Liens

- **Documentation technique** : `docs/UPDATE_SYSTEM.md`
- **Architecture** : `docs/adr/ADR-001-update-system.md`
- **Bucket InsForge** : `app-updates`
- **Projet** : `pu74z8pe.us-east.insforge.app`
