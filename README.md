# 📱 Kased App - Gestion des Cotisations d'Église

Application Flutter pour la gestion des cotisations et des membres d'église.

![Version](https://img.shields.io/badge/version-2.0.5-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Platform](https://img.shields.io/badge/platform-Android-green)

---

## 🎯 Fonctionnalités

- ✅ **Authentification Google** - Connexion sécurisée avec Google Sign-In
- ✅ **Gestion des Membres** - Ajout, modification, suppression des membres
- ✅ **Gestion des Cultes** - Création et suivi des cultes
- ✅ **Gestion des Cotisations** - Suivi des paiements avec statuts (payé, non payé, absent, en avance)
- ✅ **Dashboard** - Statistiques globales en temps réel
- ✅ **Retards** - Liste des membres en retard avec montants dus
- ✅ **Historique** - Historique complet des cotisations par membre
- ✅ **Synchronisation** - Sync automatique avec le backend InsForge
- ✅ **Mode Offline** - Cache local avec Isar

---

## 🚀 Démarrage Rapide

### Prérequis

- Flutter 3.x
- Android Studio ou VS Code
- JDK 17+
- Android SDK (API 21+)

### Installation

```bash
# 1. Cloner le projet
git clone <url-du-repo>
cd Terrain-app

# 2. Installer les dépendances
cd cotis_app
flutter pub get

# 3. Lancer l'application
flutter run
```

---

## 📚 Documentation

La documentation complète est organisée dans le dossier `docs/` :

### 📖 Guides Essentiels

- [**Guide de Démarrage Rapide**](docs/01-guides/QUICK_START.md) - Commencer rapidement
- [**Commandes Utiles**](docs/01-guides/COMMANDES.md) - Toutes les commandes Flutter
- [**État Final du Projet**](docs/01-guides/STATUS_FINAL.md) - État actuel et prochaines étapes

### 🔧 Build & Déploiement

- [**Guide de Build Release**](docs/06-build-deploy/BUILD_RELEASE_GUIDE.md) - Compiler l'APK signé
- [**Configuration Keystore**](docs/06-build-deploy/KEYSTORE_SETUP.md) - Créer le keystore
- [**Fix Gradle**](docs/06-build-deploy/FIX_GRADLE_BUILD.md) - Résoudre les problèmes Gradle

### 🎨 Design & UI

- [**Résumé Visuel**](docs/04-design-ui/RESUME_VISUEL.md) - Système de design
- [**Logos**](docs/05-logos/) - Intégration des logos (Google, Kased)
- [**Prototypes HTML**](docs/09-prototypes-html/) - Maquettes HTML

### 🏗️ Architecture

- [**Architecture**](docs/08-architecture/ARCHITECTURE.md) - Architecture de l'application
- [**Exemples de Code**](docs/08-architecture/CODE_EXAMPLES.md) - Patterns et exemples

### 🔐 Authentification

- [**Implémentation Auth**](docs/03-authentication/AUTHENTICATION_IMPLEMENTATION.md) - Google Sign-In

### 📦 Migration

- [**Guide de Migration**](docs/02-migration/MIGRATION_GUIDE.md) - Migration v1 → v2
- [**Résumé Migration**](docs/02-migration/MIGRATION_COMPLETE.md) - Synthèse complète

### ✅ Tests

- [**Rapport de Validation**](docs/07-tests/RAPPORT_VALIDATION_KASED.md) - Tests SQL (15/15)
- [**Résumé des Tests**](docs/07-tests/TESTS_COMPLETE_SUMMARY.md) - Tous les tests

---

## 🏗️ Structure du Projet

```
Terrain-app/
├── cotis_app/                 # Application Flutter
│   ├── lib/
│   │   ├── core/             # Services, thème, utils
│   │   ├── models/           # Modèles de données (Isar)
│   │   ├── providers/        # State management (Riverpod)
│   │   ├── screens/          # Écrans de l'application
│   │   ├── services/         # Services (InsForge, Isar)
│   │   └── widgets/          # Widgets réutilisables
│   ├── android/              # Configuration Android
│   └── assets/               # Images, logos
├── docs/                      # Documentation complète
│   ├── 01-guides/            # Guides utilisateur
│   ├── 02-migration/         # Documentation migration
│   ├── 03-authentication/    # Documentation auth
│   ├── 04-design-ui/         # Design et UI
│   ├── 05-logos/             # Logos et icônes
│   ├── 06-build-deploy/      # Build et déploiement
│   ├── 07-tests/             # Tests et validation
│   ├── 08-architecture/      # Architecture
│   └── 09-prototypes-html/   # Prototypes HTML
└── README.md                  # Ce fichier
```

---

## 🛠️ Technologies Utilisées

### Frontend
- **Flutter** 3.x - Framework UI
- **Dart** 3.x - Langage de programmation
- **Riverpod** 2.6.1 - State management
- **Go Router** 12.1.3 - Navigation
- **Isar** 3.1.0 - Base de données locale

### Backend
- **InsForge** - Backend-as-a-Service
- **PostgreSQL** - Base de données
- **PostgREST** - API REST automatique

### Authentification
- **Google Sign-In** 6.3.0 - Authentification Google
- **Firebase Core** 2.32.0 - Services Firebase

### UI/UX
- **Google Fonts** 6.3.3 - Polices (DM Sans, Syne)
- **FL Chart** 0.68.0 - Graphiques
- **Flutter Slidable** 3.1.2 - Swipe actions

---

## 📱 Compiler l'Application

### Mode Debug (Test)

```bash
cd cotis_app
flutter run
```

### Mode Release (Production)

```bash
# APK ARM64 (recommandé - 20-25 MB)
flutter build apk --release --target-platform android-arm64 --split-per-abi

# App Bundle pour Play Store (15-20 MB)
flutter build appbundle --release
```

**Voir** : [Guide de Build Release](docs/06-build-deploy/BUILD_RELEASE_GUIDE.md)

---

## 🔐 Configuration

### 1. Backend InsForge

Configurez votre backend dans `lib/core/config/insforge_config.dart` :

```dart
static const String baseUrl = 'https://your-app.region.insforge.app';
static const String anonKey = 'your-anon-key';
```

### 2. Google Sign-In

Ajoutez vos fichiers de configuration :
- `android/app/google-services.json` (Firebase)
- Client ID OAuth configuré dans Google Cloud Console

### 3. Keystore (Pour Release)

Le keystore est déjà configuré :
- **Fichier** : `android/app/kased-release-key.jks`
- **Mot de passe** : `Kased2026Secure!`

**Voir** : [Configuration Keystore](docs/06-build-deploy/KEYSTORE_SETUP.md)

---

## 🧪 Tests

```bash
# Analyse de code
flutter analyze

# Tests unitaires
flutter test

# Tests d'intégration
flutter test integration_test/
```

---

## 📊 Statistiques du Projet

| Métrique            | Valeur          |
| ------------------- | --------------- |
| **Lignes de code**  | ~15 000         |
| **Fichiers Dart**   | ~50             |
| **Écrans**          | 15+             |
| **Widgets**         | 30+             |
| **Tests SQL**       | 15/15 ✅         |
| **Qualité du code** | 100% (0 issues) |

---

## 🎨 Design

### Couleurs

- **Primary** : #1246C8 (Bleu Kased)
- **Success** : #10B981 (Vert)
- **Warning** : #F59E0B (Orange)
- **Danger** : #EF4444 (Rouge)

### Typographie

- **Titres** : Syne (700-800)
- **Corps** : DM Sans (400-700)

### Logo

- **Logo Kased** : `assets/images/kased_logo.png`
- **Logo Google** : CustomPainter vectoriel

---

## 📝 Changelog

Voir [CHANGELOG.md](CHANGELOG.md) pour l'historique complet des versions.

### Version Actuelle : 2.0.5 (4 mai 2026)

- ✅ Corrections finales de code (0 issues)
- ✅ Configuration Gradle corrigée
- ✅ Keystore créé et configuré
- ✅ Documentation complète organisée

---

## 🤝 Contribution

Ce projet est développé pour la gestion des cotisations d'église. Pour toute question ou suggestion, contactez l'équipe de développement.

---

## 📄 Licence

Propriétaire - Kased App © 2026

---

## 🙏 Remerciements

- **Kiro AI Assistant** - Développement et documentation
- **Équipe Kased** - Vision et feedback
- **Communauté Flutter** - Outils et packages

---

## 📞 Support

Pour toute question :
- 📧 Email : support@kasedapp.com
- 📱 WhatsApp : +243 XXX XXX XXX
- 🌐 Site web : https://kasedapp.com

---

**Fait avec ❤️ pour la communauté d'église**
