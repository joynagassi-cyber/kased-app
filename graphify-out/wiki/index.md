# Wiki du Projet — Kased App

Navigatez par module plutôt que par fichiers bruts.

---

## Navigation

| Module | Fichiers clés |
|--------|--------------|
| [[Authentification]] | `providers/auth_provider.dart`, `services/auth_service.dart`, `screens/{onboarding,login,signup}.dart`, `core/router/app_router.dart` |
| [[Membres]] | `controllers/membre_controller.dart`, `models/membre.dart`, `screens/membres/`, `widgets/kased_avatar.dart` |
| [[Cultes]] | `controllers/culte_controller.dart`, `models/culte.dart`, `screens/cultes/`, `core/logic/culte_lock.dart` |
| [[Cotisations]] | `controllers/cotisation_controller.dart`, `models/cotisation.dart`, `core/logic/cotisation_logic.dart`, `core/logic/culte_lock.dart` |
| [[Sync Offline]] | `core/sync/sync_manager.dart`, `core/local_cache.dart`, `models/sync_operation.dart` |
| [[Données locales]] | `core/isar_local_cache.dart`, `providers/isar_provider.dart`, `models/*.g.dart` |
| [[Backend API]] | `core/insforge/insforge_service.dart`, `core/insforge/insforge_config.dart` |
| [[Thème & UI]] | `core/theme/app_theme.dart`, `core/theme/motion_tokens.dart`, `widgets/kased_card.dart`, `widgets/empty_state.dart` |
| [[Notifications]] | `core/services/push_notify_service.dart`, `core/services/onesignal_service.dart`, `core/notifications/notification_service.dart` |
| [[Stats]] | `providers/stats_graphiques_provider.dart`, `screens/stats/stats_screen.dart`, `core/services/stats_service.dart` |
| [[Corbeille]] | `models/corbeille_item.dart`, `screens/corbeille/corbeille_screen.dart`, `core/logic/culte_lock.dart` |
| [[Export]] | `core/export/cotisation_export_service.dart`, `core/pdf/member_report_pdf_service.dart`, `core/pdf/registre_pdf_service.dart` |
| [[Temps réel]] | `core/realtime/`, `core/realtime/presence_service.dart` |
| [[Préférences]] | `core/preferences/app_prefs.dart` |

---

## [[Authentification]]

**Concepts :**
- Google Sign-In via bridge InsForge (`google-auth-bridge-v8`)
- Firebase Auth en fallback
- Token stocké dans `SharedPreferences` → injecté dans les headers InsForge
- Navigation : `/onboarding` → `/login` → `/dashboard`
- Guard : `authProvider` (Riverpod) contrôle le `redirect` du router

**Points d'attention :**
- Le token InsForge est récupéré après le Google Auth, pas avant
- `AuthService` est un wrapper — la logique métier est dans `auth_provider.dart`
- Timeout Google : 120s (`KasedConstants.googleTimeout`)

---

## [[Membres]]

**Concepts :**
- UUID comme clé métier (stockée dans `Membre.id`)
- Soft-delete via `CorbeilleItem` (déplacement, pas suppression)
- Date d'adhésion calcule les retards (ignorer cultes antérieurs)
- Avatar généré depuis l'email (`AvatarService`)

**Modèle `Membre` :**
```dart
@collection
class Membre {
  Id isarId = Isar.autoIncrement;
  @Index(unique: true)
  late String id;          // UUID → clé InsForge
  late String nom;
  late String prenom;
  DateTime? dateNaissance;
  double montantEnAvance = 0.0;
  bool isActive = true;
  bool isDeleted = false;
  DateTime? deletedAt;
  @ignore String get nomComplet => '$prenom $nom'.trim();
}
```

**Écrans :**
- `/membres` → `MembresScreen`
- `/membres/add` → `AddMembreScreen`
- `/membres/:id` → `MembreDetailScreen`
- `/membres/:id/rapport` → `MembreReportScreen`

---

## [[Cultes]]

**Concepts :**
- Un culte a une date et génère des cotisations pour tous les membres actifs
- Verrouillage après 30 jours (`joursVerrouillageCulte`)
- Saisie rapide : batch payment sur plusieurs membres
- Paiement personnel : dialog dédié

**Modèle `Culte` :**
```dart
@collection
class Culte {
  late String id;
  late DateTime dateCulte;
  late double montantCotisation; // par défaut 50 FCFA
  bool isDeleted = false;
  DateTime? deletedAt;
}
```

**Écrans :**
- `/cultes` → `CultesScreen`
- `/cultes/:id` → `CulteDetailScreen`
- Saisie rapide : `SaisieRapideScreen` (dialog overlay)

---

## [[Cotisations]]

**Concepts :**
- Statut : `paye | nonPaye | absent | enAvance`
- Calcul retards : `CotisationLogic.calculerNombreRetards()` (pur, sans Flutter)
- Montant par défaut : 50 FCFA (`KasedConstants.cotisationMontantParDefaut`)
- Paiement en avance : `ajouterPaiementAvance()` sur `MembreController`

**Modèle `Cotisation` :**
```dart
@collection
class Cotisation {
  late String id;
  late String culteId;
  late String membreId;
  late StatutCotisation statut;
  double montant = 50.0;
  DateTime? datePaiement;
}
```

---

## [[Sync Offline]]

**Architecture :**
```
Isar (local, source de vérité)
    ↓ ajouterSyncOp()
SyncOperation queue
    ↓ SyncManager.runSync()
InsForge (remote)
    ↓ mergeFromCloud()
Isar (updated)
```

**Règles :**
- Throttle : max 1 sync / 5 min (`KasedConstants.syncThrottle`)
- Retry exponentiel : max 5 tentatives (`KasedConstants.syncMaxRetries`)
- Merge : le serveur bat le local sur collision, sauf soft-delete
- BUG FIX_SYNC_2026-08 : supprimer l'opération sync après appel réseau direct réussi

**Fichiers clés :**
- `core/sync/sync_manager.dart` — orchestrateur
- `core/local_cache.dart` — CRUD Isar + merge
- `models/sync_operation.dart` — file d'attente

---

## [[Données locales]]

**Modèle Isar :**
```dart
@collection
class Membre { ... }   // + membre.g.dart (généré)
@collection
class Culte { ... }    // + culte.g.dart
@collection
class Cotisation { ... } // + cotisation.g.dart
@collection
class SyncOperation { ... } // + sync_operation.g.dart
@collection
class CorbeilleItem { ... } // + corbeille_item.g.dart
```

**Règles :**
- Toujours `part 'nom.g.dart'` après l'import Isar
- UUID comme clé métier, `isarId` pour l'ID interne
- Champs calculés avec `@ignore`
- Générer après modification : `dart run build_runner build --delete-conflicting-outputs`
- Ne jamais modifier Isar directement — passer par `LocalCache` ou `SyncManager`

---

## [[Backend API]]

**InsForge (PostgreSQL + PostgREST) :**
- URL : `https://pu74z8pe.us-east.insforge.app` (override via `--dart-define=INSFORGE_BASE_URL`)
- Clé anonyme : `anon_75c09927...` (override via `--dart-define=INSFORGE_ANON_KEY`)
- Bucket photos : `membres-photos`

**Headers :**
```dart
{
  'Authorization': 'Bearer <key>',
  'apikey': '<key>',
  'Content-Type': 'application/json',
  'Prefer': 'return=representation',
}
```

**Fonctions serveur (slug) :**
- `google-auth-bridge-v8` — authentification Google
- `push-notify` — notifications push

**Pagination :** taille par défaut 200 (`KasedConstants.defaultPageSize`)

---

## [[Thème & UI]]

**Palette :**
- Police titres : **Syne**
- Police corps : **DM Sans**
- Support light/dark automatique (`AppTheme`)

**Composants réutilisables :**
- `KasedCard` — carte standard avec onTap
- `KasedAvatar` — avatar généré depuis email
- `EmptyState` — état vide avec icône
- `StatCard` — carte statistique (stats screen)
- `KasedGradientCard` — carte avec dégradé
- `KasedStatusBadge` — badge de statut cotisation

**Animations :**
- Transitions : `FadeSlidePage` (fade + 4% slide horizontal, 320ms)
- Motion : `AnimatedAppear`, `AnimatedPress`, `SkeletonLoading`
- Tokens : `motion_tokens.dart` — durées et courbes unifiées

---

## [[Notifications]]

**Architecture :**
- OneSignal SDK pour les push
- `PushNotifyService` — orchestrateur
- `NotificationService` — gestion des notifications locales
- `NotificationCoordinator` — coordination entre push et UI
- Vérification OneSignal à l'ouverture (gate `OneSignalVerificationGate`)

---

## [[Stats]]

**Services :**
- `StatsService` — calculs (total cotisations, retards, averages)
- `StatsGraphiquesProvider` — données pour FL Chart
- Écran : `/stats` → `StatsScreen`

---

## [[Corbeille]]

**Concepts :**
- Soft-delete uniquement (jamais hard-delete)
- Éléments déplacés vers `CorbeilleItem` avec `deletedAt`
- Purge automatique après 30 jours (`joursAvantPurgeCorbeille`)
- Écran : `/corbeille` → `CorbeilleScreen`

---

## [[Export]]

**Formats :**
- PDF : `MemberReportPdfService`, `RegistrePdfService`, `PdfService`
- CSV : `CotisationExportService`
- Partage : `_saveAndShare()` — partage system sheet

---

## [[Temps réel]]

**Architecture :**
- `PresenceService` — suivi de présence des appareils
- `RealtimeService` — connexion WebSocket
- `RealtimeHandler` — gestion des événements
- Modèles : `DevicePresence`, `PresenceState`, `RealtimeEvent`

---

## Valeurs magiques

Toutes centralisées dans `core/constants.dart` (`KasedConstants`) :
- `cotisationMontantParDefaut = 50.0`
- `joursAvantPurgeCorbeille = 30`
- `joursVerrouillageCulte = 30`
- `syncThrottle = Duration(minutes: 5)`
- `syncMaxRetries = 5`
- `defaultPageSize = 200`
- `googleTimeout = Duration(seconds: 120)`
