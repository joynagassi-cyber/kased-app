# ADR-0001 : Store séparé du Provider Riverpod

**Statut :** Proposed
**Date :** 2026-08-25
**Concernés :** AppDataProvider, controllers, screens

## Contexte

`AppDataProvider` fait 1 382 lignes avec 25 mutations `state = AsyncValue.data(...)` dispersées. Il fait simultanément :
- État global (AppState)
- Contrôleurs CRUD (Membre, Culte, Cotisation, Système)
- Logique métier (calculs, verrouillages, sync)
- Notifications (push + in-app)
- Synchronisation (SyncService)

Ce god module rend impossible le test unitaire de la logique métier.

## Décision

Extraire un store pur `KasedStore` avec interface `dispatch(Action) → void`. Le provider Riverpod devient un adaptateur fin (~80 lignes). Les contrôleurs deviennent des handlers internes au store.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  Screens (MembresScreen, DashboardScreen, ...)      │
│  ref.read(kasedAppProvider.notifier).dispatch(...)  │
└──────────────────────┬──────────────────────────────┘
                       │ dispatch(Action)
                       ▼
┌─────────────────────────────────────────────────────┐
│  KasedStore (pure Dart, ~400 lignes)               │
│  - state: AppState                                  │
│  - dispatch(Action) → void                          │
│  - _membreHandler, _culteHandler, _cotisationHandler│
│  - _syncHandler                                     │
└────────┬──────────┬──────────┬──────────┬──────────┘
         │          │          │          │
    ┌────▼────┐ ┌───▼────┐ ┌──▼─────┐ ┌──▼──────┐
    │ LocalCache│ │InsForge │ │SyncSvc │ │ NotifCo │
    └─────────┘ └────────┘ └────────┘ └─────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│  KasedApp (Riverpod Provider, ~80 lignes)          │
│  - build() → AsyncValue<AppState>                   │
│  - onInit → loadFromCache + sync deferred           │
│  - onDispose → store.dispose()                      │
└─────────────────────────────────────────────────────┘
```

## Conséquences

**Positives :**
- Store testable sans Flutter/Riverpod (dispatch + assert state)
- Handlers testables individuellement
- Provider fin et maintenable
- Seam clair : screens ↔ store via actions

**Négatives :**
- Migration progressive nécessaire (12 méthodes à déplacer)
- Changement d'interface pour tous les screens (`.ajouterPaiementAvance()` → `.dispatch(AddPaymentAdvance(...))`)

## Alternatives considérées

| Approche | Rejetée car |
|----------|-------------|
| ChangeNotifier | Couplage Flutter, pas de testabilité isolée |
| Stream-based | Complexité asynchrone inutile |
| Garder le provider | Ne résout pas le problème de 1 382 lignes |

## Liens

- Rapport d'analyse : `architecture-review-20260825.html`
- Contexte projet : `CONTEXT.md`
