# Documentation Complète — Système de Mise à Jour Kased App

## Vue d'ensemble

Ce document sert de **référence complète** pour l'agent Claude Code afin de maintenir et faire évoluer le système de mise à jour auto de l'application Kased.

---

## 📁 Structure du Projet

```
cotis_app/
├── lib/
│   ├── core/
│   │   └── updates/                    # NOUVEAU — Système de MAJ
│   │       ├── app_update_model.dart   # Modèles de données
│   │       ├── update_config.dart      # Configuration URLs
│   │       └── update_service.dart     # Service de vérification/téléchargement
│   │
│   ├── providers/
│   │   ├── update_provider.dart        # Provider Riverpod
│   │   └── update_provider.g.dart      # Code généré (ne pas modifier)
│   │
│   └── widgets/
│       └── update_dialog.dart          # Dialogue UI
│
├── android/
│   └── app/
│       └── src/
│           └── main/
│               ├── kotlin/com/kasedapp/
│               │   ├── AppUpdatePlugin.kt    # Plugin natif installation
│               │   └── MainActivity.kt       # Enregistrement plugin
│               └── res/xml/
│                   └── file_paths.xml        # FileProvider config
│
├── docs/
│   ├── UPDATE_SYSTEM.md              # Documentation technique complète
│   ├── UPDATE_GUIDE.md               # Guide opérationnel (à jour !)
│   ├── DEPLOYMENT_CHECKLIST.md       # Checklist de déploiement
│   └── manifest.json                 # Exemple de manifeste
│
└── pubspec.yaml                      # Dépendances (apk_installer ajouté)
```

---

## 🔧 Commandes Essentielles

### Build & Upload

```bash
# 1. Builder l'APK
cd cotis_app
flutter build apk --release --target-platform android-arm64 --split-per-abi

# 2. Upload APK sur InsForge
npx @insforge/cli storage upload docs/1.2.0.apk --bucket app-updates

# 3. Upload manifeste
npx @insforge/cli storage upload docs/manifest.json --bucket app-updates

# 4. Vérifier
npx @insforge/cli storage list-objects app-updates
```

### Analyse & Tests

```bash
# Analyser le code
flutter analyze lib/core/updates/ lib/providers/update_provider.dart lib/widgets/update_dialog.dart

# Lancer les tests
flutter test

# Générer les fichiers .g.dart après modification
dart run build_runner build --delete-conflicting-outputs
```

### InsForge

```bash
# Vérifier la config du projet
npx @insforge/cli current

# Voir les buckets
npx @insforge/cli storage buckets

# Télécharger un objet
npx @insforge/cli storage download manifest.json --bucket app-updates
```

---

## 📝 Configuration InsForge

### Bucket
- **Nom** : `app-updates`
- **Type** : Public
- **URL de base** : `https://pu74z8pe.us-east.insforge.app`

### URLs des fichiers
```
Manifest : https://pu74z8pe.us-east.insforge.app/api/storage/object/public/app-updates/manifest.json
APK      : https://pu74z8pe.us-east.insforge.app/api/storage/object/public/app-updates/X.Y.Z.apk
```

### Clés API
- **Anon Key** : `anon_75c09927569e3aab8c78e8bf1a69c194bb41e0f231366e46911ffb14dca8881d`
- **Project ID** : `f42181ca-bc1a-4351-92e8-c9e206dc708b`
- **Region** : `us-east`

---

## 🔄 Workflow de Déploiement

### Étape 1 : Modifier la version
**Fichier** : `pubspec.yaml`
```yaml
version: 1.2.0+1  # MAJOR.MINOR.PATCH+BUILDCODE
```

### Étape 2 : Calculer le version_code
```
version_code = MAJOR * 1000000 + MINOR * 1000 + PATCH * 1 + BUILD
```
Exemple : v1.2.3 build 1 → `1*1000000 + 2*1000 + 3*1 + 1 = 1002004`

### Étape 3 : Builder
```bash
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

### Étape 4 : Mettre à jour le manifeste
**Fichier** : `docs/manifest.json`
```json
{
  "version_name": "1.2.0",
  "version_code": 1020001,
  "download_url": "https://pu74z8pe.us-east.insforge.app/api/storage/object/public/app-updates/1.2.0.apk",
  "changelog": "• Feature 1\n• Bug fix 2",
  "force_update": false,
  "published_at": "2026-08-26T10:00:00Z",
  "sha256": ""
}
```

### Étape 5 : Upload
```bash
npx @insforge/cli storage upload docs/X.Y.Z.apk --bucket app-updates
npx @insforge/cli storage upload docs/manifest.json --bucket app-updates
```

### Étape 6 : Vérifier
```bash
npx @insforge/cli storage list-objects app-updates
curl -s "https://pu74z8pe.us-east.insforge.app/api/storage/object/public/app-updates/manifest.json"
```

---

## 🎯 Intégration dans l'Application

### main.dart
```dart
// Import ajouté
import 'providers/update_provider.dart';
import 'widgets/update_dialog.dart';
import 'core/updates/app_update_model.dart';

// Dans KasedApp.build()
final updateState = ref.watch(updateNotifierProvider);

// UpdateCheckWrapper affiche le dialogue si MAJ disponible
```

### profile_screen.dart
```dart
// Badge ajouté dans la section "Application"
_UpdateBadge(colorScheme: colorScheme)
```

---

## 📊 Comportement du Système

### Vérification
- **Au démarrage** : Vérification automatique
- **Périodique** : Toutes les 6 heures
- **Au retour au premier plan** : Vérification manuelle

### UI
- **Badge** : Apparaît dans l'écran Profil avec badge "NEW"
- **Dialogue** : Apparaît au démarrage si MAJ disponible
- **Bloquant** : Si `force_update: true`, l'utilisateur ne peut pas fermer

### Téléchargement
- Stockage : `/storage/emulated/0/Download/Kased-vX.Y.Z.apk`
- Vérification SHA-256 si présente dans le manifeste
- Progression affichée dans le dialogue

---

## 🔐 Permissions Android

### AndroidManifest.xml
```xml
<!-- Ajoutés automatiquement -->
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" 
                   android:maxSdkVersion="32"/>
```

### FileProvider
Configuré dans `file_paths.xml` pour l'installation sécurisée des APKs.

---

## 🐛 Dépannage

### Problème : Badge "NEW" n'apparaît pas
**Diagnostic** :
```bash
# Vérifier que le manifeste est accessible
curl -s "https://pu74z8pe.us-east.insforge.app/api/storage/object/public/app-updates/manifest.json"

# Vérifier le bucket
npx @insforge/cli storage list-objects app-updates
```
**Solution** : S'assurer que `version_code` dans le manifeste est supérieur au `buildNumber` dans `pubspec.yaml`

### Problème : Téléchargement échoue
**Diagnostic** :
```bash
# Vérifier que l'APK existe
npx @insforge/cli storage list-objects app-updates
```
**Solution** : Vérifier que le `download_url` dans le manifeste pointe vers un fichier existant

### Problème : Installation échoue
**Solution** : L'utilisateur doit activer "Sources inconnues" dans Paramètres → Sécurité

---

## 📚 Documentation de Référence

| Fichier | Contenu |
|---------|---------|
| `docs/UPDATE_SYSTEM.md` | Documentation technique complète |
| `docs/UPDATE_GUIDE.md` | Guide opérationnel |
| `docs/DEPLOYMENT_CHECKLIST.md` | Checklist de déploiement |
| `docs/adr/ADR-001-update-system.md` | Architecture Decision Record |
| `docs/manifest.json` | Exemple de manifeste |

---

## ✅ Checklist Avant Commit

- [ ] `flutter analyze` passe sans erreur
- [ ] `flutter test` passe
- [ ] Version dans `pubspec.yaml` mise à jour
- [ ] `version_code` dans manifeste supérieur à l'ancien
- [ ] APK uploadé sur InsForge
- [ ] Manifest uploadé sur InsForge
- [ ] Test sur appareil physique effectué

---

## 📝 Notes pour l'Agent Claude Code

1. **Toujours vérifier** `flutter analyze` avant de valider
2. **Ne jamais modifier** les fichiers `.g.dart` manuellement
3. **Toujours augmenter** `version_code` à chaque release
4. **Garder le changelog** à jour dans le manifeste
5. **Tester sur appareil** avant de considérer la MAJ comme prête

---

**Dernière mise à jour** : 2026-08-26  
**Auteur** : Claude Code (agent)  
**Version du système** : 1.0.0
