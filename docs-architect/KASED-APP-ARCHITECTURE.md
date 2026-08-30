# Architecture Technique — Kased App

> **Version** : v1.1.9+7  
> **Date** : 2026-08-29  
> **Auteur** : Équipe Kased

---

## Table des Matières

1. [Vue d'Ensemble](#1-vue-densemble)
2. [Architecture Logicielle](#2-architecture-logicielle)
3. [Modèles de Données](#3-modèles-de-données)
4. [Gestion de l'État](#4-gestion-de-létat)
5. [Architecture Offline-First](#5-architecture-offline-first)
6. [Synchronisation Temps Réel](#6-synchronisation-temps-réel)
7. [Authentification](#7-authentification)
8. [Routing & Navigation](#8-routing--navigation)
9. [Interface Utilisateur](#9-interface-utilisateur)
10. [Monitoring & Observabilité](#10-monitoring--observabilité)
11. [Déploiement & Mise à Jour](#11-déploiement--mise-à-jour)
12. [Tests & Qualité](#12-tests--qualité)
13. [Appendices](#13-appendices)

---

## 1. Vue d'Ensemble

### 1.1 Contexte

Kased est une application mobile de gestion des cotisations pour les églises. Elle permet aux trésoriers de :

- Gérer les membres (ajout, modification, suppression)
- Enregistrer les cultes et les dates
- Suivre les paiements de cotisation (payé, absent, en avance)
- Visualiser les statistiques financières
- Identifier les membres en retard
- Exporter des rapports PDF

### 1.2 Technologies Principales

| Couche | Technologie | Version |
|--------|-------------|---------|
| Framework | Flutter | 3.x |
| Langage | Dart | 3.x |
| Gestion d'état | Riverpod | 2.6 |
| Navigation | GoRouter | 17 |
| Base locale | Isar | 3 |
| HTTP | Dio | 5.8 |
| WebSockets | Socket.IO | 3.0 |
| Backend | InsForge | — |
| Notifications | OneSignal | 5.5 |
| Auth | Google Sign-In | 6.2 |

### 1.3 Caractéristiques Clés

- **Offline-first** : Toutes les données sont stockées localement (Isar) et synchronisées avec le cloud
- **Temps réel** : Les changements sont propagés via Socket.IO (patchs locaux immédiats)
- **Multi-utilisateurs** : Chaque utilisateur a sa propre vue des données
- **Multi-appareil** : Synchronisation entre plusieurs appareils via le cloud
- **Auto-update** : Mises à jour automatiques via InsForge Storage / GitHub Releases
- **Notifications push** : Notifs locales et push via OneSignal

---

## 2. Architecture Logicielle

### 2.1 Architecture Globale

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           COUCHE PRÉSENTATION                            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│  │Dashboard │ │ Membres  │ │ Cultes   │ │  Stats   │ │ Retards  │    │
│  │  Screen  │ │  Screen  │ │  Screen  │ │  Screen  │ │  Screen  │    │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘    │
│       │            │            │            │            │            │
│  ┌────▼────────────▼────────────▼────────────▼────────────▼──────┐   │
│  │                    Widgets Réutilisables                        │   │
│  │  KasedCard · KasedAvatar · StatCard · EmptyState · Skeleton    │   │
│  └───────────────────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────────────────────┘
                              │
┌───────────────────────────────────────────────────────────────────────┐
│                         COUCHE ÉTAT (Riverpod)                         │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │                    KasedApp Provider                             │  │
│  │  ┌───────────────────────────────────────────────────────────┐  │  │
│  │  │                      KasedStore                            │  │  │
│  │  │  • AppState (membres, cultes, cotisations, dashboard)      │  │  │
│  │  │  • dispatch() — Actions → Handlers                         │  │  │
│  │  │  • onStateChanged callback                                  │  │  │
│  │  │  • connectRealtime() / disconnectRealtime()                │  │  │
│  │  └───────────────────────────────────────────────────────────┘  │  │
│  │                                                                  │  │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐               │  │
│  │  │Auth Provider│ │Theme Provider│ │ Update Prov.│               │  │
│  │  └─────────────┘ └─────────────┘ └─────────────┘               │  │
│  └─────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────┘
                              │
┌───────────────────────────────────────────────────────────────────────┐
│                        COUCHE MÉTIER (Store)                          │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌────────────┐  │
│  │MemberHandler │ │CulteHandler  │ │CotisationH.  │ │StatsService│  │
│  │              │ │              │ │              │ │            │  │
│  │createMember  │ │createCulte   │ │registerPay.  │ │getDashboard│  │
│  │updateMember  │ │updateCulte   │ │markAbsent    │ │loadRetards │  │
│  │deleteMember  │ │deleteCulte   │ │bulkSetPay.   │ │loadMembres │  │
│  └──────┬───────┘ └──────┬───────┘ └──────┬───────┘ └─────┬──────┘  │
│         │                │                │               │          │
│  ┌──────▼────────────────▼────────────────▼───────────────▼──────┐  │
│  │              NotificationCoordinator                          │  │
│  │  • Notifications système (locale)                             │  │
│  │  • Notifications in-app (via callback)                        │  │
│  │  • Planification anniversaires                                │  │
│  └───────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────┘
                              │
┌───────────────────────────────────────────────────────────────────────┐
│                      COUCHE DONNÉES & SYNC                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │
│  │IsarLocalCache│  │ SyncManager  │  │RealtimeSvc   │               │
│  │              │  │              │  │              │               │
│  │getAllMembres │  │runSync()     │  │Socket.IO     │               │
│  │saveMembre()  │  │pushOps()     │  │data_changed  │               │
│  │mergeFromCloud│  │fetchCloud()  │  │patch engine  │               │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘               │
│         │                 │                 │                        │
│  ┌──────▼─────────────────▼─────────────────▼──────────────────┐   │
│  │                        Isar DB (local)                        │   │
│  │  memb | cult | cotisa | sync_op | corbeille                  │   │
│  └─────────────────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────────────────────┘
                              │
┌───────────────────────────────────────────────────────────────────────┐
│                        COUCHE RÉSEAU                                   │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                    InsForgeService                              │  │
│  │  • Dio client avec intercepteurs (retry, 401, auth)            │  │
│  │  • CRUD membres, cultes, cotisations                           │  │
│  │  • RPC functions (toggle_paiement, marquer_absent, etc.)       │  │
│  │  • Upload photos (storage bucket)                              │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                  │                                   │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                      Google Auth Bridge                         │  │
│  │  • InsForge edge function (Deno)                               │  │
│  │  • Valide idToken Google → crée/authfie utilisateur             │  │
│  │  • Retourne access_token + refresh_token                        │  │
│  └────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │   InsForge Server │
                    │  (PostgreSQL +    │
                    │   PostgREST +     │
                    │   Edge Functions) │
                    └───────────────────┘
```

### 2.2 Structure du Projet

```
cotis_app/
├── lib/
│   ├── main.dart                    # Point d'entrée, init Firebase/OneSignal/Sentry
│   │
│   ├── core/
│   │   ├── insforge/                # Configuration + Service API InsForge
│   │   │   ├── insforge_config.dart
│   │   │   ├── insforge_service.dart
│   │   │   └── insforge_service_port.dart
│   │   ├── realtime/                # Synchronisation temps réel (Socket.IO)
│   │   │   ├── realtime_service.dart
│   │   │   ├── realtime_handler.dart
│   │   │   ├── realtime_patch_engine.dart
│   │   │   └── realtime_models.dart
│   │   ├── sync/                    # Gestion de la synchronisation offline
│   │   │   ├── sync_manager.dart
│   │   │   ├── sync_service.dart
│   │   │   └── device_service_port.dart
│   │   ├── router/                  # Navigation GoRouter
│   │   │   └── app_router.dart
│   │   ├── services/                # Services utilitaires
│   │   │   ├── notification_coordinator.dart
│   │   │   ├── onesignal_service.dart
│   │   │   ├── push_notify_service.dart
│   │   │   ├── stats_service.dart
│   │   │   └── sync_service.dart
│   │   ├── isar_local_cache.dart    # Implémentation Isar de LocalCache
│   │   ├── local_cache.dart         # Interface abstraction cache
│   │   ├── logic/                   # Logique métier pure
│   │   │   ├── cotisation_logic.dart
│   │   │   └── culte_lock.dart
│   │   ├── preferences/             # SharedPreferences (onboarding, config)
│   │   │   └── app_prefs.dart
│   │   ├── updates/                 # Système de mise à jour auto
│   │   │   ├── update_service.dart
│   │   │   ├── app_update_model.dart
│   │   │   └── update_config.dart
│   │   ├── theme/                   # Thème Material 3 (light/dark)
│   │   │   ├── app_theme.dart
│   │   │   └── motion_tokens.dart
│   │   ├── notifications/           # Notifications locales
│   │   │   └── notification_service.dart
│   │   ├── utils/                   # Utilitaires (UUID, storage)
│   │   │   ├── uuid.dart
│   │   │   └── storage_helper.dart
│   │   ├── constants.dart           # Valeurs magiques centralisées
│   │   └── export/                  # Services d'export (PDF, CSV)
│   │
│   ├── models/                      # Modèles Isar
│   │   ├── membre.dart
│   │   ├── culte.dart
│   │   ├── cotisation.dart
│   │   ├── sync_operation.dart
│   │   └── corbeille_item.dart
│   │
│   ├── providers/                   # Providers Riverpod
│   │   ├── kased_app_provider.dart  # Provider principal (adaptateur Store)
│   │   ├── auth_provider.dart       # Authentification
│   │   ├── isar_provider.dart       # Instance Isar
│   │   ├── theme_provider.dart      # Thème
│   │   ├── update_provider.dart     # Mises à jour
│   │   ├── notifications_provider.dart
│   │   └── onesignal_provider.dart
│   │
│   ├── store/                       # State management (Riverpod + actions)
│   │   ├── kased_store.dart         # Store centralisé
│   │   ├── kased_action.dart        # Hiérarchie d'actions (sealed classes)
│   │   ├── app_state.dart           # État global
│   │   ├── app_state_helpers.dart   # Helpers (tri, merge)
│   │   └── handlers/                # Handlers métier
│   │       ├── member_handler.dart
│   │       ├── culte_handler.dart
│   │       └── cotisation_handler.dart
│   │
│   ├── screens/                     # Écrans de l'application
│   │   ├── onboarding_screen.dart
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart
│   │   ├── membres/
│   │   │   ├── membres_screen.dart
│   │   │   ├── add_membre_screen.dart
│   │   │   ├── membre_detail_screen.dart
│   │   │   ├── membre_report_screen.dart
│   │   │   └── membres_en_avance_screen.dart
│   │   ├── cultes/
│   │   │   ├── cultes_screen.dart
│   │   │   ├── culte_detail_screen.dart
│   │   │   └── saisie_rapide_screen.dart
│   │   ├── stats/
│   │   │   └── stats_screen.dart
│   │   ├── retards/
│   │   │   └── retards_screen.dart
│   │   ├── corbeille/
│   │   │   └── corbeille_screen.dart
│   │   └── profile/
│   │       └── profile_screen.dart
│   │
│   ├── widgets/                     # Widgets réutilisables
│   │   ├── app_shell.dart           # Coquille principale (nav bar)
│   │   ├── app_drawer.dart          # Drawer latéral
│   │   ├── kased_card.dart          # Carte générique
│   │   ├── kased_avatar.dart        # Avatar membre
│   │   ├── stat_card.dart           # Carte statistique
│   │   ├── empty_state.dart         # État vide
│   │   ├── motion/                  # Animations
│   │   │   ├── skeleton_loading.dart
│   │   │   ├── animated_appear.dart
│   │   │   ├── animated_press.dart
│   │   │   └── motion_aware.dart
│   │   ├── membre_detail/           # Widgets détail membre
│   │   ├── dashboard/               # Widgets dashboard
│   │   ├── onboarding/              # Pages onboarding
│   │   └── ...
│   │
│   └── services/
│       └── auth_service.dart        # Service d'authentification
│
├── functions/
│   └── google-auth-bridge.js        # Fonction serveur InsForge (v7)
│
├── assets/
│   └── images/kased_logo.png
│
└── pubspec.yaml
```

### 2.3 Nombre de Fichiers

| Catégorie | Nombre |
|-----------|--------|
| Fichiers Dart (lib/) | 129 |
| Modèles | 5 |
| Providers | 8 |
| Écrans | 14 |
| Widgets | ~30 |
| Services | 8 |
| Handlers | 3 |

---

## 3. Modèles de Données

### 3.1 Schéma de Base de Données

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│     Membre      │     │      Culte      │     │   Cotisation    │
├─────────────────┤     ├─────────────────┤     ├─────────────────┤
│ isarId (PK)     │     │ isarId (PK)     │     │ isarId (PK)     │
│ id (UUID, unique)│    │ id (UUID, unique)│    │ id (UUID, unique)│
│ nom             │     │ dateCulte       │     │ membreId (FK)   │
│ prenom          │     │ titre           │     │ culteId (FK)    │
│ dateAdhesion    │     │ montantCotisation│    │ statut          │
│ dateNaissance   │     │ notes           │     │ montantOblig.   │
│ montantEnAvance │     │ memberIds []    │     │ montantPaye     │
│ totalDons       │     │ deviceId        │     │ montantDon      │
│ telephone       │     │ isDeleted       │     │ datePaiement    │
│ notes           │     │ deletedAt       │     │ notes           │
│ isActive        │     │ deletedBy       │     │ deviceId        │
│ updatedAt       │     │ version         │     │ isDeleted       │
│ createdAt       │     │ createdAt       │     │ deletedAt       │
│ version         │     │ updatedAt       │     │ deletedBy       │
│ deviceId        │     │                 │     │ version         │
│ isDeleted       │     │                 │     │ deviceId        │
│ deletedAt       │     │                 │     │ isDeleted       │
│ deletedBy       │     │                 │     │ deletedAt       │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                       │
         │            ┌──────────┴───────────────────────┤
         │            │                                  │
         │            │  ┌──────────────────────────┐    │
         │            │  │   SyncOperation          │    │
         │            │  ├──────────────────────────┤    │
         │            │  │ isarId (PK)              │    │
         │            │  │ operationId (UUID)       │    │
         │            │  │ type (CREATE/UPDATE/…)   │    │
         │            │  │ entityType               │    │
         │            │  │ entityId                 │    │
         │            │  │ payloadJson (JSON blob)  │    │
         │            │  │ createdAt                │    │
         │            │  │ deviceId                 │    │
         │            │  │ isSynced                 │    │
         │            │  │ hasFailed                │    │
         │            │  └──────────────────────────┘    │
         │            │                                  │
         │            │  ┌──────────────────────────┐    │
         │            │  │   CorbeilleItem          │    │
         │            │  ├──────────────────────────┤    │
         │            │  │ isarId (PK)              │    │
         │            │  │ entityType               │    │
         │            │  │ entityId                 │    │
         │            │  │ payloadJson               │    │
         │            │  │ deletedAt                │    │
         │            │  └──────────────────────────┘    │
         │            │                                  │
         └────────────┴──────────────────────────────────┘
```

### 3.2 Modèle Membre

**Fichier** : `lib/models/membre.dart`

| Champ | Type | Description |
|-------|------|-------------|
| `id` | `String` | UUID unique (clé métier) |
| `nom` | `String` | Nom de famille |
| `prenom` | `String` | Prénom |
| `dateAdhesion` | `DateTime` | Date d'adhésion |
| `dateNaissance` | `DateTime?` | Date de naissance |
| `montantEnAvance` | `double` | Somme payée d'avance |
| `totalDons` | `double` | Total des dons (excédents) |
| `telephone` | `String?` | Numéro de téléphone |
| `notes` | `String?` | Notes |
| `isActive` | `bool` | État actif/inactif |
| `deviceId` | `String` | ID de l'appareil créateur |
| `isDeleted` | `bool` | Soft delete flag |
| `deletedAt` | `DateTime?` | Date de suppression |
| `deletedBy` | `String?` | Appareil qui a supprimé |
| `version` | `int` | Version pour le merge |

**Champs calculés** (`@ignore`) :
- `nomComplet` : `"Prénom Nom"`
- `initiales` : Première lettre du prénom + nom
- `anniversaireAujourdHui` : Vrai si anniversaire aujourd'hui
- `age` : Âge calculé

### 3.3 Modèle Culte

**Fichier** : `lib/models/culte.dart`

| Champ | Type | Description |
|-------|------|-------------|
| `id` | `String` | UUID unique |
| `dateCulte` | `DateTime` | Date du culte |
| `titre` | `String?` | Titre optionnel |
| `montantCotisation` | `double` | Montant obligatoire (défaut: 50 FCFA) |
| `notes` | `String?` | Notes |
| `memberIds` | `List<String>` | Membres présents au culte |
| `deviceId` | `String` | Appareil créateur |
| `isDeleted` | `bool` | Soft delete flag |

### 3.4 Modèle Cotisation

**Fichier** : `lib/models/cotisation.dart`

| Champ | Type | Description |
|-------|------|-------------|
| `id` | `String` | UUID unique |
| `membreId` | `String` | Clé étrangère → Membre |
| `culteId` | `String` | Clé étrangère → Culte |
| `statut` | `StatutCotisation` | Enum: nonPaye, paye, absent, enAvance |
| `montantObligatoire` | `double` | Montant requis |
| `montantPaye` | `double` | Montant payé |
| `montantDon` | `double` | Don (excédent) |
| `datePaiement` | `DateTime?` | Date de paiement |
| `deviceId` | `String` | Appareil créateur |
| `isDeleted` | `bool` | Soft delete flag |

**StatutCotisation (enum)** :
- `nonPaye` — Culte passé, pas encore payé
- `paye` — Payé (le jour même ou en rattrapage)
- `absent` — Membre absent ce dimanche
- `enAvance` — Payé AVANT la date du culte

**Champs calculés** :
- `estPaye` : `statut != absent && montantPaye >= montantObligatoire`
- `estEnRetard` : `statut != absent && montantPaye < montantObligatoire`

### 3.5 Modèle SyncOperation

**Fichier** : `lib/models/sync_operation.dart`

| Champ | Type | Description |
|-------|------|-------------|
| `operationId` | `String` | UUID de l'opération |
| `type` | `String` | 'CREATE', 'UPDATE', 'DELETE', 'RESTORE' |
| `entityType` | `String` | 'membre', 'culte', 'cotisation' |
| `entityId` | `String` | UUID de l'entité |
| `payloadJson` | `String` | JSON de l'entité sérialisée |
| `createdAt` | `DateTime` | Timestamp de création |
| `deviceId` | `String` | Appareil source |
| `isSynced` | `bool` | True si sync réussi |
| `hasFailed` | `bool` | True si échecs multiples |

### 3.6 Modèle CorbeilleItem

**Fichier** : `lib/models/corbeille_item.dart`

| Champ | Type | Description |
|-------|------|-------------|
| `entityType` | `String` | Type d'entité supprimée |
| `entityId` | `String` | UUID de l'entité |
| `payloadJson` | `String` | Données complètes |
| `deletedAt` | `DateTime` | Date de suppression |

---

## 4. Gestion de l'État

### 4.1 Architecture Riverpod

```
┌─────────────────────────────────────────────────────────────────┐
│                        Main App                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  ProviderScope                           │   │
│  │                                                          │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │   │
│  │  │  Auth        │  │  Theme       │  │  Isar        │   │   │
│  │  │  Provider    │  │  Provider    │  │  Provider    │   │   │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘   │   │
│  │         │                 │                 │            │   │
│  │  ┌──────▼─────────────────▼─────────────────▼───────┐   │   │
│  │  │            KasedApp Provider (adaptateur)         │   │   │
│  │  │  • Initialise KasedStore                         │   │   │
│  │  │  • Watch connectivity                            │   │   │
│  │  │  • Auto-sync every 3s + on connectivity change   │   │   │
│  │  │  • Dispatch actions → Store                      │   │   │
│  │  └──────────────────────┬───────────────────────────┘   │   │
│  │                         │                               │   │
│  │  ┌──────────────────────▼───────────────────────────┐   │   │
│  │  │                  KasedStore                      │   │   │
│  │  │  • AppState (data)                               │   │   │
│  │  │  • dispatch() (actions)                          │   │   │
│  │  │  • onStateChanged callback                       │   │   │
│  │  │  • Handlers: Member, Culte, Cotisation           │   │   │
│  │  └───────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 Hiérarchie des Actions

**Fichier** : `lib/store/kased_action.dart`

Les actions utilisent les **sealed classes** de Dart 3 pour un typage exhaustif :

```
KasedAction (sealed)
├── MemberAction (sealed)
│   ├── CreateMember
│   ├── UpdateMember
│   ├── AddPaymentAdvance
│   ├── DeleteMember
│   └── RestoreMember
├── CulteAction (sealed)
│   ├── CreateCulte
│   ├── UpdateCulte
│   ├── DeleteCulte
│   └── RestoreCulte
├── CotisationAction (sealed)
│   ├── RegisterPayment
│   ├── MarkAbsent
│   ├── BulkSetPaiements
│   ├── TogglePaiement
│   └── PaySeveralCultesInAdvance
├── SyncAction (sealed)
│   ├── SyncData
│   └── LoadDashboard
├── CorbeilleAction (sealed)
│   ├── PermanentlyDelete
│   └── EmptyTrash
├── QueryAction (sealed)
│   ├── GetHistoriqueMembre
│   ├── GetCotisationsDuCulte
│   ├── GetRetardsMembres
│   └── GetMembresAJour
└── TrashAction (sealed)
    └── RestoreFromTrash
```

### 4.3 Flux de Données

```
┌─────────────────────────────────────────────────────────────────────┐
│                        UI (Screens/Widgets)                         │
│                                                                     │
│  ref.read(kasedAppProvider.notifier).dispatch(CreateMember(...))   │
└──────────────────────────┬──────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        KasedStore                                   │
│                                                                     │
│  dispatch(action) → switch(action) {                                │
│    case CreateMember: → _memberHandler.createMember(action)        │
│    case UpdateMember: → _memberHandler.updateMember(action)        │
│    ...                                                              │
│  }                                                                  │
│                                                                     │
│  → Met à jour _state (copyWith)                                    │
│  → Notifie via onStateChanged callback                             │
└──────────────────────────┬──────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        Handlers                                     │
│                                                                     │
│  MemberHandler:                                                    │
│  1. Génère UUID pour le nouveau membre                             │
│  2. Crée SyncOperation (CREATE)                                    │
│  3. Sauvegarde locale (Isar) + op sync                             │
│  4. Appelle API distante                                           │
│  5. Supprime l'op sync si succès                                   │
│  6. Envoie notification in-app + push                              │
└──────────────────────────┬──────────────────────────────────────────┘
                           │
           ┌───────────────┼───────────────┐
           ▼               ▼               ▼
    ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
    │   Isar DB   │ │  InsForge   │ │   OneSignal │
    │   (local)   │ │   (cloud)   │ │  (push)     │
    └─────────────┘ └─────────────┘ └─────────────┘
```

### 4.4 AppState

**Fichier** : `lib/store/app_state.dart`

```dart
class AppState {
  final List<Membre> membres;
  final List<Culte> cultes;
  final List<Cotisation> cotisations;
  final Map<String, dynamic>? dashboard;
  final List<Map<String, dynamic>> retardsMembres;
  final List<Map<String, dynamic>> membresAJour;
  final List<Map<String, dynamic>> historiqueMembre;
  final String? historiqueMembreId;
  final bool isLoading;
  final bool isOffline;
  final String? error;
}
```

---

## 5. Architecture Offline-First

### 5.1 Principe Fondamental

Kased suit le pattern **offline-first** : l'Isar local est la source de vérité principale. Les données cloud sont synchronisées en arrière-plan.

```
┌─────────────────────────────────────────────────────────────────┐
│                     Cycle de Synchronisation                     │
│                                                                 │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐  │
│  │  Local   │───▶│  Push    │───▶│  Fetch   │───▶│  Merge   │  │
│  │  (Isar)  │    │  (ops)   │    │  (cloud) │    │  (local) │  │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘  │
│       ▲                                         │                │
│       │                                         ▼                │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐  │
│  │  Local   │◀───│  Realtime│◀───│  Socket  │◀───│  Cloud   │  │
│  │  (Isar)  │    │  Patch   │    │  .IO     │    │  Events  │  │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 Flux de Synchronisation

```
1. OPÉRATION LOCALE
   ┌─────────────────────────────────────────┐
   │  Utilisateur crée un membre             │
   │  → CreateMember action                  │
   └────────────────┬────────────────────────┘
                    │
                    ▼
2. sauvegarde LOCALE + SYNC OP
   ┌─────────────────────────────────────────┐
   │  saveMembreWithSyncOp(membre, syncOp)   │
   │  → IsarTransaction (atomique)           │
   └────────────────┬────────────────────────┘
                    │
                    ▼
3. APPTEL RÉSEAU
   ┌─────────────────────────────────────────┐
   │  try { api.createMembre(payload) }       │
   │  → succès : deleteSyncOp(isarId)        │
   │  → échec : l'op reste en file          │
   └────────────────┬────────────────────────┘
                    │
                    ▼
4. SYNC PÉRIODIQUE (toutes les 5 min)
   ┌─────────────────────────────────────────┐
   │  SyncManager.runSync()                  │
   │  → getPendingSyncOps()                  │
   │  → Pour chaque op:                      │
   │    → _pushOperationWithRetry()          │
   │    → deleteSyncOp() si succès           │
   └────────────────┬────────────────────────┘
                    │
                    ▼
5. FETCH CLOUD + MERGE
   ┌─────────────────────────────────────────┐
   │  → getAllMembres() (cloud)              │
   │  → getAllCultes() (cloud)               │
   │  → getAllCotisations() (cloud)          │
   │  → mergeFromCloud()                     │
   │    • Pour chaque entité :                │
   │      • Garde la version la plus récente │
   │      • Protège les ops en attente       │
   └─────────────────────────────────────────┘
```

### 5.3 Merge Strategy

**Fichier** : `lib/core/isar_local_cache.dart` (lignes 180-304)

| Scénario | Comportement |
|----------|-------------|
| Local + Cloud都存在 | Garde la version avec `updatedAt` le plus récent |
| Seulement Local | Garde le local |
| Seulement Cloud | Garde le cloud |
| Local isDeleted | Éliminé (sauf si op en attente) |
| Op en attente | Garde le local (protégé) |

### 5.4 Retry Exponentiel

**Fichier** : `lib/core/sync/sync_manager.dart` (lignes 156-204)

```
Tentative 1 : immédiat
Tentative 2 : 1 seconde
Tentative 3 : 2 secondes
Tentative 4 : 4 secondes
Tentative 5 : 8 secondes
Après 5 échecs : op marquée hasFailed = true (non réessayée automatiquement)
```

---

## 6. Synchronisation Temps Réel

### 6.1 Architecture Socket.IO

```
┌─────────────────────────────────────────────────────────────────────┐
│                        RealtimeService                              │
│                                                                     │
│  Socket.IO Client                                                  │
│  ├── Connexion avec token JWT (query + headers)                    │
│  ├── Subscriptions :                                               │
│  │   ├── 'kased:all' (tous les événements)                         │
│  │   ├── 'kased:private' (privé utilisateur)                        │
│  │   ├── 'kased:membres'                                            │
│  │   ├── 'kased:cultes'                                             │
│  │   └── 'kased:cotisations'                                        │
│  ├── Heartbeat (30s) pour maintenir la présence                     │
│  └── Reconnexion auto (exponential backoff)                         │
│                                                                     │
└──────────────────────────┬──────────────────────────────────────────┘
                           │
                           │ 'data_changed' / 'kased:membres:changed'
                           │ 'kased:membres:deleted' / etc.
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       RealtimeHandler                               │
│                                                                     │
│  • Reçoit les événements du service                                │
│  • Déclenche le patch engine                                       │
│  • Programme un reload avec debounce (30s)                         │
│                                                                     │
└──────────────────────────┬──────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     RealtimePatchEngine                             │
│                                                                     │
│  apply(event):                                                     │
│  1. Timestamp guard (ignorer events périmés)                        │
│  2. Appliquer le patch :                                           │
│     • create/update → saveMembre/saveCulte/saveCotisation          │
│     • delete → deleteMembreById/deleteCulteById                    │
│  3. Notifier le handler (reload différé)                           │
│  4. Notifier le provider (mise à jour UI immédiate)                │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 6.2 Timeline d'Événement

```
T+0ms     : Événement reçu (Socket.IO)
T+0ms     : Timestamp guard vérifié
T+1ms     : Patch appliqué localement (Isar)
T+1ms     : onImmediateUpdate() appelé → UI mise à jour
T+30s     : Reload complet planifié (debounce)
```

### 6.3 Timestamp Guard

```
Si local.updatedAt > event.updatedAt → IGNORER (stale)
Si local.updatedAt < event.updatedAt → APPLIQUER
Si local.updatedAt == event.updatedAt → APPLIQUER (equality = same source)
```

---

## 7. Authentification

### 7.1 Flow d'Authentification

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Email/     │    │   Google     │    │   Bridge     │    │   InsForge   │
│   Password   │    │   Sign-In    │    │   (Deno)     │    │   (PG)       │
└──────┬───────┘    └──────┬───────┘    └──────┬───────┘    └──────┬───────┘
       │                   │                   │                   │
       │ POST /api/auth/   │ Google SDK        │ POST /functions/  │
       │ sessions          │ → idToken         │ google-auth-bridge│
       │                   │                   │ → idToken         │
       │                   │                   │                   │
       │                   │                   │ validate Google   │
       │                   │                   │ token (audience)  │
       │                   │                   │                   │
       │                   │                   │ POST /api/auth/   │
       │                   │                   │ sessions          │
       │                   │                   │ (login/signup)    │
       │                   │                   │                   │
       ▼                   ▼                   ▼                   ▼
    Token +             Token +            Token +            Stocké
    Refresh             AccessToken         AccessToken         en DB
    Token               +                   +
                        Provider: 'google'  Refresh
                        +                   Token
```

### 7.2 Google Auth Bridge (v7)

**Fichier** : `functions/google-auth-bridge.js`

```javascript
// Étapes du bridge :
// 1. Valider l'idToken Google (vérifier audience)
// 2. Extraire email, name, googleId
// 3. Essayer de login avec email + password dérivé
// 4. Si pas trouvé → create user avec provider: 'google'
// 5. Upsert profile avec google_id
// 6. Retourner token + provider: 'google'
```

**Validation d'audience** :
```javascript
const EXPECTED_CLIENT_ID = '535496831713-eqn2k8iasrmbfuk7r91nn43bnoenkma7.apps.googleusercontent.com';
if (googleData.aud !== EXPECTED_CLIENT_ID) {
  return 403; // Security validation failed
}
```

### 7.3 Gestion du Refresh Token

**Fichier** : `lib/providers/auth_provider.dart` (lignes 97-122)

```
┌─────────────────────────────────────────────────────────────────┐
│                    JWT Token Lifecycle                          │
│                                                                 │
│  Token valide (0-12 min) : Utiliser directement                │
│  Token expire bientôt (12-15 min) : Refresh proactif           │
│  Token expiré (>15 min) : Tenter refresh, sinon logout         │
│                                                                 │
│  Refresh proactif : Timer toutes les 2 minutes                  │
│  → Vérifie si token expire dans < 3 minutes                    │
│  → Si oui, appelle /api/auth/refresh                           │
│  → Stocke nouveau token dans FlutterSecureStorage              │
└─────────────────────────────────────────────────────────────────┘
```

### 7.4 Stockage des Tokens

```
┌─────────────────────────────────────────────────────────────────┐
│                  FlutterSecureStorage                           │
│  ┌─────────────────┬──────────────────────────────────────────┐ │
│  │ auth_token      │ JWT access token (encrypted)              │ │
│  │ refresh_token   │ JWT refresh token (encrypted)             │ │
│  │ user_email      │ Email de l'utilisateur                    │ │
│  │ user_name       │ Nom affiché                               │ │
│  └─────────────────┴──────────────────────────────────────────┘ │
│                                                                 │
│  Options Android : encryptedSharedPreferences = true            │
│  Pas d'authentification biométrique requise                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## 8. Routing & Navigation

### 8.1 Configuration GoRouter

**Fichier** : `lib/core/router/app_router.dart`

```dart
// Structure des routes :
/
├── /loading              (splash)
├── /onboarding           (onboarding 3 pages)
├── /login                (connexion email/mot de passe)
├── /signup               (inscription)
├── /dashboard            (accueil principal)
├── /membres              (liste membres)
│   ├── /membres/add      (ajout membre)
│   ├── /membres/en-avance (paiements avances)
│   └── /membres/:id      (détail membre)
│       └── /membres/:id/rapport (rapport PDF)
├── /cultes               (liste cultes)
│   └── /cultes/:id       (détail culte)
├── /stats                (graphiques)
├── /retards              (membres en retard)
├── /corbeille            (éléments supprimés)
└── /profile              (paramètres)
```

### 8.2 Guards d'Authentification

```dart
redirect: (context, state) {
  final auth = ref.read(authProvider);
  
  // Pendant le chargement initial
  if (auth.isLoading) return '/loading';
  
  // Utilisateur non authentifié
  if (!auth.isAuthenticated) {
    if (AppPrefs.hasSeenOnboarding) return '/login';
    return '/onboarding';
  }
  
  // Utilisateur authentifié sur route publique
  if (auth.isAuthenticated && isPublic) return '/dashboard';
  
  return null; // Accès autorisé
}
```

### 8.3 Transition de Pages

**FadeSlidePage** : Fade + translation horizontale de 4%
```dart
transitionsBuilder: (context, animation, secondaryAnimation, child) {
  return FadeTransition(
    opacity: animation,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.04, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: child,
    ),
  );
}
// Duration: 320ms
```

---

## 9. Interface Utilisateur

### 9.1 Design System

**Couleurs** (`lib/core/theme/app_theme.dart`)

| Rôle | Light | Dark |
|------|-------|------|
| Primary | `#2962FF` | `#2979FF` |
| Background | `#F8F9FE` | `#0B0F19` |
| Surface | `#FFFFFF` | `#131A2A` |
| Surface 2 | `#F0F4F8` | `#1E293B` |
| Border | `#E2E8F0` | `#334155` |
| Text Primary | `#0F172A` | `#F8FAFC` |
| Error | `#FF1744` | `#FF1744` |
| Success | `#00C853` | `#00C853` |

**Typography** :
- Titres : **Syne** (fontWeight: 700-800)
- Corps : **DM Sans** (fontWeight: 400-600)

### 9.2 Navigation Bottom

```
┌─────────────────────────────────────────────────────────────────┐
│  [Home] [People] [Church] [Chart] [Warning]                    │
│   Accueil  Membres  Cultes  Stats  Retards                     │
│                                                                 │
│  ● Glass-morphism (blur + transparency)                        │
│  ● Double shadow (elevated floating effect)                    │
│  ● Badge animé sur Retards si > 0                               │
└─────────────────────────────────────────────────────────────────┘
```

### 9.3 Skeleton Loading

**Fichier** : `lib/widgets/motion/skeleton_loading.dart`

- Animation shimmer : 3 secondes par cycle (visible)
- Contraste élevé pour dark/light mode
- Composants : `DashboardSkeleton`, `MembresListSkeleton`, `CulteDetailSkeleton`

---

## 10. Monitoring & Observabilité

### 10.1 Stack de Monitoring

| Service | Usage | Configuration |
|---------|-------|--------------|
| **Firebase Crashlytics** | Crashs Flutter/Dart | `FlutterError.onError` + `PlatformDispatcher.onError` |
| **Sentry** | Erreurs + tracing | DSN via `--dart-define=SENTRY_DSN` |
| **OneSignal** | Push notifications multi-utilisateurs | External ID = email |
| **Logger** | Debug avec `debugPrint` | Préfixe `[AUTH]`, `[REALTIME]`, etc. |

### 10.2 Logging Convention

```
[AUTH]          — Provider auth, login, logout, refresh
[REALTIME]      — Connexion Socket.IO, événements reçus
[PatchEngine]   — Appliquer patchs locaux
[Sync]          — Opérations de synchronisation
[InsForge]      — Appels API, erreurs 401
[UpdateService] — Vérification mises à jour
[FIREBASE]      — Initialisation Firebase
[ONESIGNAL]     — Initialisation OneSignal
```

### 10.3 Gestion des Erreurs 401

```dart
// Intercepteur Dio dans InsForgeService
_onError: (DioException error, ErrorInterceptorHandler handler) {
  if (error.response?.statusCode == 401) {
    // Tenter refresh silencieux
    final refreshed = await onUnauthorized!();
    if (refreshed) return; // Le provider se reconstruit automatiquement
  }
  handler.next(error); // Déconnexion si refresh échoue
}
```

---

## 11. Déploiement & Mise à Jour

### 11.1 Pipeline CI/CD

```
GitHub Actions (.github/workflows/build-release.yml)
│
├── Déclenchement : push sur main
├── Build APK ARM64
│   ├── flutter pub get
│   ├── flutter build apk --release
│   │   --dart-define=INSFORGE_BASE_URL=$BASE_URL
│   │   --dart-define=INSFORGE_ANON_KEY=$ANON_KEY
│   │   --dart-define=GOOGLE_SERVER_CLIENT_ID=$SERVER_CLIENT_ID
│   └── Upload asset
└── Création release GitHub
    ├── tag: v1.1.9+7
    └── asset: kased-v1.1.9+7.apk
```

### 11.2 Système de Mise à Jour Auto

**Fichier** : `lib/core/updates/update_service.dart`

```
1. checkForUpdate()
   ├── PackageInfo.fromPlatform() → version locale
   ├── GET https://api.github.com/repos/.../releases/latest
   ├── Parser tag_name → versionName + versionCode
   ├── Comparer avec version locale + lastSeenCode (SharedPreferences)
   └── Retourner AppUpdateCheckResult

2. downloadApk()
   ├── Permission management (Storage, ManageExternalStorage)
   ├── Download APK depuis GitHub
   └── Retourner chemin local

3. installApk()
   └── MethodChannel → Native install (apk_installer)
```

### 11.3 Workflow de Déploiement

```
1. Développer sur branche feature
2. PR → Code review
3. Merge sur main
4. CI/CD trigger (GitHub Actions)
5. Build APK + Upload asset
6. Release GitHub créée
7. L'app détecte la mise à jour (si versionCode > lastSeenCode)
8. Utilisateur est notifié (dialogue)
9. Installation auto ou manuelle
```

---

## 12. Tests & Qualité

### 12.1 Stratégie de Tests

| Type | Répertoire | Coverage |
|------|-----------|----------|
| Unitaires | `test/` | Logique métier (CotisationLogic) |
| Widgets | `widget_test/` | Composants isolés |
| Intégration | `integration_test/` | Flux complets |

### 12.2 Patterns de Test

```dart
// Mock des dépendances
final fakeCache = FakeLocalCache();
final fakeApi = FakeInsForgeService();
final fakeDeviceService = FakeDeviceService(deviceId: 'test-device');

// Test du handler
final handler = MemberHandler(
  cache: fakeCache,
  api: fakeApi,
  deviceService: fakeDeviceService,
  ...
);
```

### 12.3 Analyse Statique

```bash
flutter analyze          # 0 errors/warnings requis
flutter test             # Tests unitaires
flutter test integration_test/  # Tests d'intégration
```

---

## 13. Appendices

### 13.1 Glossaire

| Terme | Définition |
|-------|------------|
| **Culte** | Réunion de l'église (généralement dominicale) |
| **Cotisation** | Contribution financière obligatoire |
| **En avance** | Paiement effectué avant la date du culte |
| **Sync Operation** | Opération en attente de synchronisation cloud |
| **Soft Delete** | Suppression logique (marquée isDeleted) |
| **Patch** | Mise à jour incrementale des données |
| **Bridge** | Fonction serveur intermédiaire (Google Auth) |

### 13.2 API Endpoints InsForge

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/api/auth/sessions?client_type=mobile` | Login email/mot de passe |
| POST | `/api/auth/users?client_type=mobile` | Inscription |
| POST | `/api/auth/refresh?client_type=mobile` | Refresh token |
| GET | `/api/database/records/membres` | Liste membres |
| POST | `/api/database/records/membres` | Créer membre |
| PATCH | `/api/database/records/membres?id=eq.{id}` | Mettre à jour membre |
| DELETE | `/api/database/records/membres?id=eq.{id}` | Supprimer membre |
| GET | `/api/database/records/cultes` | Liste cultes |
| POST | `/api/database/records/cultes` | Créer culte |
| GET | `/api/database/records/cotisations` | Liste cotisations |
| POST | `/api/database/rpc/toggle_paiement` | Toggle paiement |
| POST | `/api/database/rpc/marquer_absent` | Marquer absent |
| GET | `/api/database/records/v_dashboard` | Stats dashboard |
| GET | `/api/database/records/v_retards_membres` | Membres en retard |
| GET | `/api/storage/object/membres-photos/{file}` | Upload photo |

### 13.3 Configuration CI/CD Secrets

| Secret | Usage | Exemple |
|--------|-------|---------|
| `INSFORGE_BASE_URL` | URL backend | `https://pu74z8pe.us-east.insforge.app` |
| `INSFORGE_ANON_KEY` | Clé API anon | `anon_xxxxx...` |
| `GOOGLE_SERVER_CLIENT_ID` | Client ID Android | `5354...7.apps.googleusercontent.com` |
| `GOOGLE_WEB_CLIENT_ID` | Client ID Web | `5354...ndo.apps.googleusercontent.com` |
| `SENTRY_DSN` | DSN Sentry | `https://xxxx@sentry.io/xxx` |
| `GH_TOKEN` | GitHub token | GITHUB_TOKEN (built-in) |

### 13.4 Dépendances Clés

| Dépendance | Version | Usage |
|-----------|---------|-------|
| `flutter_riverpod` | ^2.6.1 | State management |
| `go_router` | ^17.2.3 | Navigation |
| `isar` | ^3.1.0 | Base de données locale |
| `dio` | ^5.8.0 | HTTP client |
| `dio_retry_plus` | ^2.0.8 | Retry exponentiel |
| `socket_io_client` | ^3.0.0 | Temps réel |
| `google_sign_in` | 6.2.1 | Google Auth |
| `onesignal_flutter` | 5.5.2 | Push notifications |
| `firebase_core` | ^3.12.0 | Firebase SDK |
| `firebase_crashlytics` | ^4.3.0 | Crash reporting |
| `sentry_flutter` | ^8.7.0 | Error tracking |
| `flutter_secure_storage` | ^10.1.0 | Stockage sécurisé |
| `shared_preferences` | ^2.3.0 | Préférences légères |
| `fl_chart` | ^1.2.0 | Graphiques |
| `flutter_slidable` | ^4.0.3 | Swipe actions |
| `flutter_animate` | ^4.5.0 | Animations |
| `google_fonts` | ^8.1.0 | Typographie |

### 13.5 Fichiers Générés

Les fichiers `.g.dart` sont générés par `build_runner` et ne doivent pas être modifiés manuellement :

```
lib/core/insforge/insforge_service.g.dart
lib/core/realtime/realtime_handler.g.dart
lib/core/router/app_router.g.dart
lib/providers/auth_provider.g.dart
lib/providers/isar_provider.g.dart
lib/providers/kased_app_provider.g.dart
lib/providers/update_provider.g.dart
lib/services/auth_service.g.dart
lib/models/membre.g.dart
lib/models/culte.g.dart
lib/models/cotisation.g.dart
lib/models/sync_operation.g.dart
lib/models/corbeille_item.g.dart
```

### 13.6 Points de Vigilance

1. **Auth flow** : Firebase est optionnel au démarrage. Si échec, l'app continue.
2. **OneSignal** : Initialisation timeout 5s, échec ignoré.
3. **Corbeille** : Soft-delete, pas hard-delete. Purge automatique après 30 jours.
4. **Cultes verrouillés** : Après 30 jours, modification interdite.
5. **Montant par défaut** : 50 FCFA par culte (dans `KasedConstants`).
6. **BUG FIX_SYNC_2026-08** : Quand un appel réseau direct succeed, l'opération sync créée précédemment doit être supprimée avec `_cache.deleteSyncOp(syncOp.isarId)`.

---

*Document généré automatiquement à partir de l'analyse du codebase.*
