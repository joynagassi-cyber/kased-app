# Context Packs — Kased App

Chaque pack contient les fichiers à charger avant de travailler sur une feature.
Objectif : < 2000 lignes de contexte par tâche.

---

## 📦 Pack Auth & Onboarding

**Quand :** Modifier le flux d'authentification, les écrans de connexion, ou la navigation.

**Fichiers à charger :**
| Fichier | Lignes | Pourquoi |
|---------|--------|----------|
| `providers/auth_provider.dart` | 450 | Provider Riverpod auth + token management |
| `services/auth_service.dart` | ~200 | Wrapper Google Sign-In |
| `core/router/app_router.dart` | 260 | Routes + auth guard + transitions |
| `screens/onboarding_screen.dart` | ~150 | Écran onboarding |
| `screens/login_screen.dart` | ~150 | Écran login |
| `screens/signup_screen.dart` | ~150 | Écran signup |
| `core/preferences/app_prefs.dart` | ~100 | Flags persistants |
| `widgets/custom_google_signin_button.dart` | ~100 | Bouton Google custom |
| `widgets/onesignal_verification_gate.dart` | ~150 | Gate OneSignal |

**Éviter :** Charger tous les écrans — se limiter aux modifiés.

---

## 📦 Pack Membres

**Quand :** Travailler sur l'ajout, modification, détail ou suppression de membres.

**Fichiers à charger :**
| Fichier | Lignes | Pourquoi |
|---------|--------|----------|
| `controllers/membre_controller.dart` | 450 | CRUD membres + paiements avance |
| `models/membre.dart` | ~80 | Modèle Isar + indices |
| `screens/membres/membres_screen.dart` | ~300 | Liste membres |
| `screens/membres/membre_detail_screen.dart` | 860 | Détail membre + historique |
| `screens/membres/add_membre_screen.dart` | ~250 | Formulaire ajout |
| `widgets/kased_avatar.dart` | ~50 | Avatar par email |
| `core/avatar_service.dart` | ~50 | Générateur avatar |
| `models/corbeille_item.dart` | ~60 | Pour suppression soft |

**Pattern à suivre :**
```dart
// Pattern CRUD MembreController
await _cache.addMembre(membre);  // local d'abord
await _api.createMembre(membre); // puis remote
// BUG FIX_SYNC_2026-08 : supprimer syncOp après succès remote
```

**Ne pas charger :** `cultes_screen.dart`, `stats_screen.dart` — hors sujet.

---

## 📦 Pack Cultes

**Quand :** Ajouter un culte, modifier une date, gérer le verrouillage.

**Fichiers à charger :**
| Fichier | Lignes | Pourquoi |
|---------|--------|----------|
| `controllers/culte_controller.dart` | 458 | CRUD cultes + verrouillage |
| `models/culte.dart` | ~80 | Modèle Isar |
| `screens/cultes/cultes_screen.dart` | 589 | Liste cultes |
| `screens/cultes/culte_detail_screen.dart` | 548 | Détail + cotisations |
| `core/logic/culte_lock.dart` | ~50 | Logique verrouillage |
| `widgets/batch_payment_dialog.dart` | 455 | Batch payment |

**Règle métier :** Modification interdite après 30 jours (`KasedConstants.joursVerrouillageCulte`)

**Exceptions :** `CulteNotFoundException`, `CulteLockedException`

---

## 📦 Pack Cotisations

**Quand :** Modifier le calcul des retards, les statuts, ou les paiements.

**Fichiers à charger :**
| Fichier | Lignes | Pourquoi |
|---------|--------|----------|
| `controllers/cotisation_controller.dart` | 450 | CRUD cotisations |
| `models/cotisation.dart` | ~80 | Modèle + enum `StatutCotisation` |
| `core/logic/cotisation_logic.dart` | ~100 | Logique pure (testable) |
| `widgets/batch_payment_dialog.dart` | 455 | Dialog batch payment |
| `widgets/paiement_personnel_dialog.dart` | ~150 | Dialog paiement unique |
| `widgets/edit_montant_dialog.dart` | ~100 | Modifier montant |

**Statuts :** `paye | nonPaye | absent | enAvance`

**Logique calcul :**
- `calculerNombreRetards()` — ignore cultes antérieurs à l'adhésion
- `calculerMontantDu()` — 50 FCFA par défaut
- `determinerStatut()` — enAvance si paiement avant culte

---

## 📦 Pack Sync

**Quand :** Modifier la synchronisation offline, le merge, ou la file d'attente.

**Fichiers à charger :**
| Fichier | Lignes | Pourquoi |
|---------|--------|----------|
| `core/sync/sync_manager.dart` | ~250 | Orchestrateur sync |
| `core/local_cache.dart` | ~400 | CRUD Isar + merge |
| `core/isar_local_cache.dart` | ~200 | Couche Isar |
| `models/sync_operation.dart` | ~60 | File d'attente |
| `core/sync/device_service.dart` | ~100 | Détection offline/online |
| `core/services/sync_service.dart` | ~150 | Orchestration |

**Règles critiques :**
- Anti-réentrance : un seul `runSync()` à la fois
- Throttle : 5 min entre syncs
- Retry exponentiel, max 5
- **BUG FIX_SYNC_2026-08 :** Après succès appel réseau, supprimer syncOp créée

**Ne pas charger :** Tous les écrans — le sync est purement backend.

---

## 📦 Pack Stats & Graphiques

**Quand :** Modifier les statistiques, les graphiques, ou les KPIs.

**Fichiers à charger：**
| Fichier | Lignes | Pourquoi |
|---------|--------|----------|
| `providers/stats_graphiques_provider.dart` | ~200 | Provider graphiques |
| `core/services/stats_service.dart` | ~150 | Calculs stats |
| `screens/stats/stats_screen.dart` | 517 | Écran stats |
| `widgets/stat_card.dart` | ~80 | Carte KPI |

**Bibliothèque :** FL Chart (`fl_chart`)

---

## 📦 Pack Corbeille

**Quand :** Modifier le soft-delete ou la purge automatique.

**Fichiers à charger：**
| Fichier | Lignes | Pourquoi |
|---------|--------|----------|
| `models/corbeille_item.dart` | ~60 | Modèle Corbeille |
| `screens/corbeille/corbeille_screen.dart` | 595 | Écran corbeille |
| `core/logic/culte_lock.dart` | ~50 | Purge 30 jours |

**Règle :** Purge après 30 jours, jamais de hard-delete.

---

## 📦 Pack Notifications

**Quand：** Modifier les push notifications ou les alertes.

**Fichiers à charger：**
| Fichier | Lignes | Pourquoi |
|---------|--------|----------|
| `core/services/push_notify_service.dart` | ~200 | Orchestrateur |
| `core/services/onesignal_service.dart` | ~150 | Wrapper OneSignal |
| `core/notifications/notification_service.dart` | ~150 | Notifications locales |
| `core/services/notification_coordinator.dart` | ~100 | Coordination |
| `widgets/onesignal_verification_gate.dart` | ~150 | Gate |

---

## 📦 Pack Export

**Quand：** Modifier les exports PDF ou CSV.

**Fichiers à charger：**
| Fichier | Lignes | Pourquoi |
|---------|--------|----------|
| `core/export/cotisation_export_service.dart` | ~200 | Export CSV |
| `core/pdf/member_report_pdf_service.dart` | 485 | PDF membre |
| `core/pdf/registre_pdf_service.dart` | ~200 | PDF registre |
| `core/pdf/pdf_service.dart` | ~150 | Utilitaires PDF |
| `screens/membres/membre_report_screen.dart` | 448 | Écran rapport |

---

## 📦 Pack Thème & UI

**Quand：** Modifier le design, les couleurs, les animations.

**Fichiers à charger：**
| Fichier | Lignes | Pourquoi |
|---------|--------|----------|
| `core/theme/app_theme.dart` | ~250 | Thème light/dark |
| `core/theme/motion_tokens.dart` | ~80 | Tokens animation |
| `widgets/kased_card.dart` | ~80 | Carte réutilisable |
| `widgets/empty_state.dart` | ~50 | État vide |
| `widgets/kased_status_badge.dart` | ~50 | Badge statut |
| `widgets/app_shell.dart` | ~150 | Shell + bottom nav |

**Polices :** Syne (titres), DM Sans (corps)

---

## 📦 Pack Temps réel

**Quand：** Modifier le suivi de présence ou les WebSockets.

**Fichiers à charger：**
| Fichier | Lignes | Pourquoi |
|---------|--------|----------|
| `core/realtime/presence_service.dart` | ~100 | Presence |
| `core/realtime/realtime_service.dart` | ~150 | WebSocket |
| `core/realtime/realtime_handler.dart` | ~100 | Events |
| `core/realtime/realtime_models.dart` | ~80 | Modèles |

---

## 📦 Pack Inscription / Signup

**Quand：** Modifier le flux d'inscription.

**Fichiers à charger：**
| Fichier | Lignes | Pourquoi |
|---------|--------|----------|
| `screens/signup_screen.dart` | ~150 | Écran signup |
| `providers/auth_provider.dart` | 450 | Provider auth |
| `core/router/app_router.dart` | 260 | Redirection post-signup |
| `core/preferences/app_prefs.dart` | ~100 | Marquer onboarding vu |

---

## 📦 Pack Saisie Rapide

**Quand：** Modifier le batch payment ou la saisie rapide des cotisations.

**Fichiers à charger：**
| Fichier | Lignes | Pourquoi |
|---------|--------|----------|
| `screens/cultes/saisie_rapide_screen.dart` | ~200 | Écran saisie |
| `widgets/batch_payment_dialog.dart` | 455 | Dialog batch |
| `controllers/cotisation_controller.dart` | 450 | Logique paiement |
| `core/logic/cotisation_logic.dart` | ~100 | Calculs |

---

## Règles de sélection

1. **Max 8-10 fichiers par pack** — au-delà, le contexte devient bruit
2. **Toujours charger le contrôleur + le modèle** — c'est le cœur métier
3. **Écran → 1 seul fichier** — pas besoin de charger tous les écrans
4. **Ne jamais charger les `.g.dart`** — ils sont générés et immuable
5. **Vérifier `CLAUDE.md`** — les règles globales s'appliquent toujours
