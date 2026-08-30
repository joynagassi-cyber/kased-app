---
title: "Getting Started"
description: "Installation, configuration et premiers pas avec Kased App"
---

# Getting Started

Guide d'installation et de configuration pour développer et lancer Kased App.

## Prérequis

| Outil | Version | Pourquoi |
|-------|---------|----------|
| Flutter SDK | >= 3.10.0 | Framework UI |
| Dart SDK | >= 3.0.0 | Langage |
| Android Studio | Latest | Émulateur + outils |
| Java JDK | 21 (Temurin) | Build Android |
| git | Latest | Contrôle de version |

```bash
# Vérifier l'installation
flutter doctor -v
```

## Installation

### 1. Cloner le repository

```bash
git clone https://github.com/joynagassi-cyber/kased-app.git
cd kased-app/cotis_app
```

### 2. Installer les dépendances

```bash
flutter pub get
```

### 3. Configuration des secrets (développement)

Les secrets sont injectés via `--dart-define` au moment du build/run.

```bash
# Variables obligatoires
export INSFORGE_BASE_URL="https://pu74z8pe.us-east.insforge.app"
export INSFORGE_ANON_KEY="anon_75c09927..."
export GOOGLE_AUTH_BRIDGE_URL="${INSFORGE_BASE_URL}/functions/google-auth-bridge"
export SENTRY_DSN=""  # Optionnel pour le dev

# Lancer l'application
flutter run \
  --dart-define=INSFORGE_BASE_URL=$INSFORGE_BASE_URL \
  --dart-define=INSFORGE_ANON_KEY=$INSFORGE_ANON_KEY \
  --dart-define=GOOGLE_AUTH_BRIDGE_URL=$GOOGLE_AUTH_BRIDGE_URL \
  --dart-define=SENTRY_DSN=$SENTRY_DSN
```

### 4. Générer le code

Les fichiers `.g.dart` sont générés par `build_runner` :

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Fichiers générés :**
- `lib/core/insforge/insforge_service.g.dart`
- `lib/core/router/app_router.g.dart`
- `lib/core/realtime/realtime_handler.g.dart`
- `lib/providers/*.g.dart`
- `lib/services/auth_service.g.dart`
- `lib/models/*.g.dart` (Isar)

## Structure du Projet

```
cotis_app/
├── lib/
│   ├── main.dart                    # Point d'entrée
│   ├── core/
│   │   ├── insforge/               # Service API InsForge
│   │   ├── realtime/               # Synchronisation Socket.IO
│   │   ├── sync/                   # Gestion sync offline
│   │   ├── router/                 # Navigation GoRouter
│   │   ├── services/               # Services utilitaires
│   │   ├── isar_local_cache.dart   # Implémentation Isar
│   │   ├── local_cache.dart        # Interface abstraction
│   │   ├── logic/                  # Logique métier pure
│   │   ├── preferences/            # SharedPreferences
│   │   ├── updates/                # Auto-update
│   │   ├── theme/                  # Design system
│   │   └── constants.dart          # Valeurs magiques
│   ├── models/                     # Entités Isar
│   ├── providers/                  # Providers Riverpod
│   ├── store/                      # State management
│   │   ├── kased_store.dart
│   │   ├── kased_action.dart
│   │   └── handlers/               # Handlers métier
│   ├── screens/                    # Écrans
│   └── widgets/                    # Composants réutilisables
├── functions/
│   └── google-auth-bridge.js       # Fonction serveur InsForge
├── test/
│   ├── unit/                       # Tests unitaires
│   └── widget/                     # Tests widgets
└── pubspec.yaml
```

## Commands Utiles

```bash
# Développement
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define=INSFORGE_BASE_URL=... --dart-define=INSFORGE_ANON_KEY=...

# Analyse statique
flutter analyze
flutter analyze --no-fatal-warnings

# Tests
flutter test test/unit/
flutter test test/widget/

# Build APK
flutter build apk --release \
  --dart-define=INSFORGE_BASE_URL=... \
  --dart-define=INSFORGE_ANON_KEY=... \
  --dart-define=SENTRY_DSN=...

# Vérification
flutter doctor -v
flutter clean && flutter pub get
```

## Configuration des Secrets (Production)

Les secrets sont stockés dans les GitHub Secrets du repository :

| Secret | Usage | Requis |
|--------|-------|--------|
| `INSFORGE_URL` | URL du backend InsForge | ✅ Obligatoire |
| `INSFORGE_ANON_KEY` | Clé API anon pour les appels publics | ✅ Obligatoire |
| `GOOGLE_WEB_CLIENT_ID` | Web Client ID Google OAuth | ✅ Obligatoire |
| `GOOGLE_SERVER_CLIENT_ID` | Android Client ID pour Google Sign-In | ✅ Obligatoire |
| `GOOGLE_AUTH_BRIDGE_URL` | URL du bridge Google Auth | ✅ Obligatoire |
| `SENTRY_DSN` | DSN Sentry pour le monitoring | ❌ Optionnel |
| `UPLOAD_KEYSTORE_B64` | Keystore de signature (base64) | ✅ Obligatoire |
| `KEYSTORE_PASSWORD` | Mot de passe du keystore | ✅ Obligatoire |
| `KEY_ALIAS` | Alias de la clé | ✅ Obligatoire |
| `KEY_PASSWORD` | Mot de passe de la clé | ✅ Obligatoire |
| `ONESIGNAL_REST_API_KEY` | Clé API OneSignal pour les push | ⚠️ Recommandé |

### Ajouter un secret GitHub

```bash
# Via la CLI GitHub
gh secret set INSFORGE_URL --body "https://your-instance.insforge.app"
gh secret set INSFORGE_ANON_KEY --body "anon_xxxxx..."

# Ou via l'interface GitHub
# Settings → Secrets and variables → Actions → New repository secret
```

## Debugging

### Logs

Tous les logs utilisent `debugPrint()` avec des préfixes :

```
[AUTH]     — Provider auth, login, logout
[REALTIME] — Connexion Socket.IO, événements
[PatchEngine] — Appliquer patchs locaux
[Sync]     — Opérations de synchronisation
[InsForge] — Appels API, erreurs 401
[UpdateService] — Vérification mises à jour
```

### Activation du logging Dio

Le logging des requêtes HTTP est activé automatiquement en mode debug (`kDebugMode`).

### Vérification de la sync

```dart
// Dans les logs, cherchez :
// [Sync] Operation push...
// [Realtime] Event normalized: ...
```

## Dépannage

| Problème | Solution |
|----------|----------|
| `flutter pub get` échoue | Vérifier la version Flutter >= 3.10.0 |
| Erreur build_runner | Supprimer les fichiers `.g.dart` existants avec `--delete-conflicting-outputs` |
| Erreur Isar | Vérifier que `part 'model.g.dart'` existe après chaque import Isar |
| Erreur Google Sign-In | Vérifier que `GOOGLE_SERVER_CLIENT_ID` pointe vers le client Android, pas Web |
| Erreur 403 Google Auth | Vérifier l'audience du token Google (doit matcher le Android Client ID) |
| Erreur 401 InsForge | Vérifier que `INSFORGE_ANON_KEY` est correct |
| Erreur keystore | Générer un nouveau keystore avec `keytool` |

## Prochaines Étapes

- [Architecture](Architecture) — Comprendre l'architecture en profondeur
- [Data Models](Data-Models) — Explorer les modèles de données
- [State Management](State-Management) — Maîtriser le state management
- [Deployment](Deployment) — Configurer le CI/CD
