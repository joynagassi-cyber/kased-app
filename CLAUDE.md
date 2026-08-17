# Kased App — Contexte de Développement

## Tech Stack

- **Flutter 3.x** / **Dart 3.x**
- **Riverpod 2.6** — state management (`@riverpod` generator, `part` files)
- **GoRouter 17** — navigation (deep links, auth-redirect)
- **Isar 3** — base de données locale (annotations `@collection`, `part 'model.g.dart'`)
- **InsForge** — backend-as-a-service (PostgreSQL + PostgREST + fonctions serverless)
- **OneSignal** — push notifications multi-utilisateurs
- **Dio + dio_retry_plus** — HTTP avec retry exponentiel
- **FL Chart** — graphiques
- **flutter_slidable** — actions au swipe
- **flutter_animate** — animations

## Commands

```bash
cd cotis_app
flutter pub get               # installer les dépendances
flutter run                   # debug mode
flutter analyze               # vérification statique (0 errors/warnings requis)
flutter test                  # tests unitaires
flutter test integration_test/ # tests d'intégration
flutter build apk --release --target-platform android-arm64 --split-per-abi  # APK ARM64
flutter build appbundle --release  # AAB pour Play Store
dart run build_runner build --delete-conflicting-outputs  # regénérer les fichiers .g.dart
```

## Architecture du Projet

```
cotis_app/lib/
├── main.dart               # Point d'entrée, init Firebase / OneSignal / Notifications
├── core/
│   ├── insforge/           # InsForgeConfig + InsForgeService (API calls)
│   ├── router/             # AppRouter (GoRouter, auth guards, routes)
│   ├── theme/              # AppTheme (light/dark, couleurs, typographie)
│   ├── sync/               # SyncManager + DeviceService (offline-first)
│   ├── services/           # SyncService, StatsService, PushNotifyService
│   ├── preferences/        # AppPrefs (SharedPreferences)
│   ├── logic/              # CotisationLogic (logique métier pure, testable)
│   ├── local_cache.dart    # Cache Isar (get/set membres, cultes, cotisations)
│   ├── isar_local_cache.dart
│   ├── constants.dart      # KasedConstants (valeurs magiques centralisées)
│   └── utils/              # UUID, formatters, helpers
├── models/                 # Membre, Culte, Cotisation, CorbeilleItem, SyncOperation
├── providers/              # AppDataProvider, AuthProvider, ThemeProvider, etc.
├── screens/                # Onboarding, Login, Signup, Dashboard, Membres, Cultes, Stats, Retards, Profile, Corbeille
├── services/               # AuthService (Google Sign-In wrapper)
└── widgets/                # KasedCard, KasedAvatar, StatCard, EmptyState, etc.
```

## Code Conventions

### Modèle de données (Isar)
```dart
import 'package:isar/isar.dart';
part 'membre.g.dart';

@collection
class Membre {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id; // UUID utilisé comme clé InsForge

  late String nom;
  late String prenom;
  DateTime? dateNaissance;
  double montantEnAvance = 0.0;
  bool isActive = true;
  bool isDeleted = false;
  DateTime? deletedAt;

  @ignore
  String get nomComplet => '$prenom $nom'.trim();
}
```
- Toujours `part 'nom.g.dart'` après l'import Isar
- Les champs calculés utilisent `@ignore`
- UUID comme clé métier, `isarId` pour l'ID interne

### Providers Riverpod
```dart
part 'app_data_provider.g.dart';

@riverpod
class AppData extends _$AppData {
  // Initialisation dans $asyncValue ou build() selon besoin
  // Utiliser ref.watch / ref.read pour souscrire aux dépendances
}
```
- Générer avec `build_runner` après modification
- `@visibleForTesting` pour injecter des mocks

### Navigation GoRouter
- Les routes protégées sont dans `routes: []` du `GoRouter`
- Le `redirect` gère l'authentification : `/onboarding` → `/login` → `/dashboard`
- Transitions : `FadeSlidePage` (fade + slide 4% horizontal)
- `rootNavigatorKey` global pour les dialogues overlay

### Thème
- Couleurs centralisées dans `AppColors` (`lib/core/theme/app_theme.dart`)
- Polices : **Syne** (titres), **DM Sans** (corps) via `google_fonts`
- Support light/dark automatique

### Sync Offline-First
- Isar = source de vérité locale
- InsForge = source de vérité distante
- `SyncOperation` = file d'attente des opérations offline (CRUD local → push)
- Merge strategy : le server bat le local sur collision, sauf soft-delete
- Throttle : max 1 sync toutes les 5 minutes

### Constants
- Toutes les valeurs magiques dans `KasedConstants` (`lib/core/constants.dart`)
- Ex: `cotisationMontantParDefaut = 50.0`, `joursVerrouillageCulte = 30`

### InsForge API
- URL et clés via `--dart-define` à la compilation
- Headers : `Authorization: Bearer <key>`, `apikey: <key>`, `Prefer: return=representation`
- Bucket photos : `membres-photos`

## Boundaries

- **Jamais** de `print()` — utiliser `debugPrint()` ou le logging standard
- **Jamais** de secrets en dur — utiliser `--dart-define` ou `.env`
- **Toujours** exécuter `flutter analyze` avant de commiter (0 warning/error)
- **Toujours** générer les `.g.dart` avec `build_runner` après modification de modèles/providers
- **Toujours** centraliser les valeurs magiques dans `KasedConstants`
- **Jamais** modifier directement Isar sans passer par `LocalCache` ou `SyncManager`
- **Jamais** utiliser `setState` — utiliser Riverpod providers
- Les fichiers `.g.dart` sont exclus de l'analyse (`analysis_options.yaml`)

## Patterns Clés

### Widget de carte Kased
```dart
KasedCard(
  child: Column(children: [...]),
  onTap: () {},
)
```

### Statut cotisation (enum)
`StatutCotisation.paye | nonPaye | absent | enAvance`

### Screens principales
- `/dashboard` — vue globale, statistiques
- `/membres` — liste + ajout + détail
- `/cultes` — liste des cultes + saisie rapide des cotisations
- `/stats` — graphiques financiers
- `/retards` — membres en retard
- `/corbeille` — éléments soft-déleted (purge après 30 jours)
- `/profile` — paramètres utilisateur

## Tests

- Unitaires : `test/` — logique métier (CotisationLogic testable sans Flutter)
- Widgets : `widget_test/` — composants isolés
- Intégration : `integration_test/` — flux complets
- E2E : `e2e/` — tests bout-en-bout

## Points de Vigilance

1. **Auth flow** : Firebase est optionnel au démarrage. Si échec, l'app continue.
2. **OneSignal** : initialisation timeout 5s, échec ignoré.
3. **Corbeille** : soft-delete, pas hard-delete. Purge automatique après 30 jours.
4. **Cultes verrouillés** : après 30 jours, modification interdite.
5. **Montant par défaut** : 50 FCFA par culte manqué (dans `KasedConstants`).
6. **BUG FIX_SYNC_2026-08** : Quand un appel réseau direct succeed (create/update/delete), l'opération sync créée précédemment doit être supprimée avec `_cache.deleteSyncOp(syncOp.isarId)`. Sinon, le sync automatique (3s plus tard) réessaie et cause des doublons UUID.
   - Fix appliqué dans : `addMembre`, `updateMembre`, `ajouterPaiementAvance`, `deleteMembre`, `addCulte`, `deleteCulte`.
   - Ne PAS modifier les flux qui n'ont pas de `syncOp` avant l'appel réseau (`enregistrerPaiementPersonnel`, `marquerAbsent`, `payerPlusieursCultesEnAvance`, `bulkSetPaiements`).
