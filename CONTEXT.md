# Kased App — Contexte du Projet

## Glossaire du Domaine (Ubiquitous Language)

| Terme | Définition |
|-------|-----------|
| **Membre** | Personne inscrite à l'association, avec son historique de cotisations |
| **Culte** | Réunion dominicale avec date, titre et montant de cotisation |
| **Cotisation** | Paiement dû par un membre pour un culte donné, avec un statut (`paye`, `nonPaye`, `absent`, `enAvance`) |
| **Paiement en avance** | Somme versée avant un culte, créditée sur le membre pour être consumée lors des cultes futurs |
| **Retard** | Culte passé non payé et non absent ; le montant dû = `montantObligatoire - montantPaye` |
| **Sync** | Synchronisation offline-first : Isar (local) ↔ InsForge (cloud) via `SyncOperation` |
| **Verrouillage** | Un culte ne peut être modifié que dans les 30 jours suivant sa date |
| **Corbeille** | Soft-delete : les éléments supprimés sont déplacés ici, purge après 30 jours |
| **Dashboard** | Vue globale : collecte totale, membres en retard, prochain culte, actions rapides |

## Décisions Architecturales (ADR)

### ADR-0001 : Store séparé du Provider Riverpod

**Date :** 2026-08-25
**Statut :** Proposed

**Contexte :**
`AppDataProvider` (1 382 lignes) contient à la fois l'état global, la logique métier, les appels réseau et les mutations d'état. 25 mutations `state = AsyncValue.data(...)` dispersées rendent le code impossible à tester unitairement.

**Décision :**
Extraire un store pur (`KasedStore`) avec interface `dispatch(Action)` → `AppState`. Le provider Riverpod devient un adaptateur fin (~80 lignes). Les contrôleurs deviennent des handlers d'actions.

**Architecture cible :**
```
Screens
  └── dispatch(Action)
        └── KasedStore
              ├── _membreHandler
              ├── _culteHandler
              ├── _cotisationHandler
              └── _syncHandler
                    └── dispatch → state = newState
```

**Conséquences :**
- Le store est testable sans Flutter ni Riverpod
- Chaque handler a une interface claire : `handleXxx(ActionXxx) → void`
- Les mutations d'état sont centralisées dans le reducer
- Le provider Riverpod reste le seul point d'entrée pour les screens

**Alternatives rejetées :**
- ChangeNotifier : couplage fort à Flutter, pas de testabilité isolée
- Stream-based : complexité asynchrone inutile pour les tests
- Monolithique (garder le provider) : ne résout pas le problème de 1 382 lignes

### ADR-0002 : Actions domain-driven (3 sealed hierarchies)

**Date :** 2026-08-25
**Statut :** Proposed

**Décision :**
Les actions sont organisées par domain avec des sealed classes :
- `MemberAction` — CreateMember, UpdateMember, AddPaymentAdvance, DeleteMember, RestoreMember
- `CulteAction` — CreateCulte, UpdateCulte, DeleteCulte, RestoreCulte
- `CotisationAction` — RegisterPayment, MarkAbsent, BulkSetPaiements, TogglePaiement
- `SyncAction` — SyncData, LoadDashboard
- `CorbeilleAction` — PermanentlyDelete, EmptyTrash

**Conséquences :**
- Chaque handler gère un subset d'actions
- Testing par domain : tests unitaires sur les handlers indépendamment
- Interface小而明确 pour chaque seam

### ADR-0003 : AppState plat avec helpers purs

**Date :** 2026-08-25
**Statut :** Proposed

**Décision :**
Garder `AppState` plat (membres, cultes, cotisations, dashboard, isLoading, isOffline, error). Extraire les transformations (tri, merge, filtrage) dans des fonctions pures helpers (`sortMembres`, `mergeCotisations`, `filterActifs`).

**Conséquences :**
- Pas de getters calculés (pas de création de listes à chaque accès)
- Helpers testables isolément
- AppState reste un value object simple

## Dépendances du Domaine

```
KasedStore
  ├── LocalCache (Isar)          — lecture/écriture locale
  ├── InsForgeService            — appels réseau
  ├── SyncService                — orchestration sync
  ├── StatsService               — calculs statistiques
  ├── NotificationCoordinator    — notifications push + in-app
  └── DeviceServicePort          — identifiant appareil

Handlers (internes au store)
  ├── MembreHandler              — MemberAction → AppState
  ├── CulteHandler               — CulteAction → AppState
  ├── CotisationHandler          — CotisationAction → AppState
  └── SyncHandler                — SyncAction → AppState

Moteurs (implémentation interne)
  ├── MembreController (révisé)  — logique métier membre (sans callback)
  ├── CulteController (révisé)   — logique métier culte
  └── CotisationController (révisé) — logique métier cotisation
```

## Contraintes Métiér (invariants)

1. **Verrouillage culte** :Modification interdite > 30 jours après la date du culte
2. **Montant minimum** : Un paiement doit être ≥ `montantObligatoire`
3. **Statut enAvance** : Déterminé par `CotisationLogic.determinerStatut()` — paiement avant la date du culte
4. **Consommation avance** : Le montant en avance est consommé automatiquement lors d'un paiement complet (don = 0)
5. **Purge corbeille** : Éléments > 30 jours dans la corbeille sont supprimés définitivement
6. **Sync throttle** : Max 1 sync toutes les 5 minutes
7. **Sync retry** : Max 5 tentatives exponentielles par opération

## Boundary (règles de non-ingérence)

- Jamais de `print()` — utiliser `debugPrint()`
- Jamais de secrets en dur — utiliser `--dart-define`
- Toujours `flutter analyze` avant commit (0 error/warning)
- Toujours générer les `.g.dart` après modification de modèles/providers
- Les `.g.dart` sont exclus de l'analyse
