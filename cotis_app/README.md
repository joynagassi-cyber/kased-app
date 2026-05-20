# Kased

Gestion de cotisations d'église — Application Flutter multiplateforme.

## Stack technique

| Couche | Technologie |
|--------|-------------|
| Frontend | Flutter 3.10+ / Dart 3.0+ |
| State management | Riverpod (avec code generation) |
| Navigation | GoRouter 17.x |
| Base locale | Isar 3.x (chiffrée AES-256) |
| Backend | InsForge BaaS (PostgreSQL + PostgREST) |
| Auth | Email/Password + Google OAuth |
| Monitoring | Sentry |
| CI/CD | GitHub Actions |

## Prérequis

- Flutter SDK ≥ 3.10.0
- Dart SDK ≥ 3.0.0

## Configuration

```bash
# Clés backend (OBLIGATOIRE — fournies par l'équipe)
flutter run --dart-define=INSFORGE_URL=<url> --dart-define=INSFORGE_KEY=<cle> --dart-define=SENTRY_DSN=<dsn>
```

## Installation

```bash
flutter pub get
```

## Lancer l'application

```bash
flutter run --dart-define=INSFORGE_URL=<url> --dart-define=INSFORGE_KEY=<cle>
```

## Tests

```bash
# Tests unitaires et widgets
flutter test test/unit/ test/widget/

# Tests E2E (nécessite un environnement complet)
flutter test test/e2e/
```

## Build production

```bash
flutter build apk --release \
  --dart-define=INSFORGE_URL=<url> \
  --dart-define=INSFORGE_KEY=<cle> \
  --dart-define=SENTRY_DSN=<dsn>
```

## Architecture

```
lib/
├── core/           # Services, logique métier, thème, routes
│   ├── insforge/   # Backend InsForge (Dio)
│   ├── isar/       # Cache local Isar
│   ├── theme/      # AppTheme, MotionTokens
│   └── router/     # GoRouter config
├── models/         # Entités Isar + JSON
├── providers/      # Riverpod (état global)
├── screens/        # Pages (onboarding, dashboard, etc.)
└── widgets/        # Composants réutilisables

test/
├── unit/           # Tests unitaires (logique métier)
├── widget/         # Tests widgets (UI)
└── e2e/            # Tests d'intégration
```
