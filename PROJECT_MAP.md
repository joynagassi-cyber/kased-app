# Project Map — Kased App

Index hiérarchique pour le contexte sélectif par feature.
Chargez uniquement la section pertinente avant chaque tâche.

---

## 🏠 Auth & Navigation

**Responsable :** `providers/auth_provider.dart` (450 lignes)

**Fichiers clés :**
- `services/auth_service.dart` — wrapper Google Sign-In
- `core/router/app_router.dart` (260 lignes) — routes + auth guard
- `screens/{onboarding,login,signup}.dart` — flux d'entrée
- `core/preferences/app_prefs.dart` — flags persistent (onboarding vu)

**Points d'attention :**
- `rootNavigatorKey` global pour dialogues overlay
- `FadeSlidePage` — transition 320ms + 4% slide horizontal
- Redirect : `/loading` → `/onboarding` ou `/login` ou `/dashboard`

---

## 👥 Membres

**Responsable :** `controllers/membre_controller.dart` (450 lignes)

**Fichiers clés :**
- `models/membre.dart` — modèle Isar (UUID, soft-delete)
- `screens/membres/membres_screen.dart` — liste
- `screens/membres/add_membre_screen.dart` — ajout
- `screens/membres/membre_detail_screen.dart` (860 lignes) — détail + historique
- `screens/membres/membre_report_screen.dart` — export PDF
- `widgets/kased_avatar.dart` — avatar par email
- `core/avatar_service.dart` — généré avatar

**Exceptions :** `MembreNotFoundException`

**BUG FIX_SYNC_2026-08 :** Appels réseau directs → supprimer syncOp après succès.

---

## ⛪ Cultes

**Responsable :** `controllers/culte_controller.dart` (458 lignes)

**Fichiers clés :**
- `models/culte.dart` — modèle Isar
- `screens/cultes/cultes_screen.dart` (589 lignes) — liste
- `screens/cultes/culte_detail_screen.dart` (548 lignes) — détail
- `screens/cultes/saisie_rapide_screen.dart` — batch payment
- `core/logic/culte_lock.dart` — verrouillage 30 jours

**Exceptions :** `CulteNotFoundException`, `CulteLockedException`

**Règle :** Modification interdite après 30 jours (`joursVerrouillageCulte`)

---

## 💰 Cotisations

**Responsable :** `controllers/cotisation_controller.dart` (450 lignes)

**Fichiers clés :**
- `models/cotisation.dart` — modèle Isar + enum `StatutCotisation`
- `core/logic/cotisation_logic.dart` — logique pure (testable)
- `widgets/batch_payment_dialog.dart` (455 lignes) — dialog batch
- `widgets/paiement_personnel_dialog.dart` — dialog paiement seul
- `widgets/edit_montant_dialog.dart` — modifier montant

**Statuts :** `paye | nonPaye | absent | enAvance`

**Logique calcul :**
- `calculerNombreRetards()` — ignore cultes antérieurs à l'adhésion
- `calculerMontantDu()` — 50 FCFA par défaut
- `determinerStatut()` — enAvance si paiement avant culte

---

## 🔄 Sync Offline

**Responsable :** `core/sync/sync_manager.dart`

**Fichiers clés :**
- `core/local_cache.dart` — CRUD Isar + merge
- `core/isar_local_cache.dart` — couche Isar
- `models/sync_operation.dart` — file d'attente
- `core/sync/device_service.dart` — détection offline/online
- `core/services/sync_service.dart` — orchestration

**Classe `SyncResult` :**
```dart
class SyncResult {
  bool success;
  int operationsPushed;
  int operationsFailed;
  int? membresRemote, cultesRemote, cotisationsRemote;
  String? error;
}
```

**Règles :**
- Anti-réentrance : un seul `runSync()` à la fois
- Throttle : 5 min minimum entre syncs
- Retry : exponentiel, max 5
- Merge : serveur bat local, sauf soft-delete

**BUG FIX_SYNC_2026-08 :** Après succès appel réseau direct, supprimer syncOp créée précédemment avec `_cache.deleteSyncOp(syncOp.isarId)`.

---

## 📊 Stats

**Responsable :** `providers/stats_graphiques_provider.dart`

**Fichiers clés :**
- `core/services/stats_service.dart` — calculs
- `screens/stats/stats_screen.dart` (517 lignes) — graphiques FL Chart
- `widgets/stat_card.dart` — carte KPI

**Indicateurs :**
- Total cotisations reçues
- Total en retard
- Membre le plus en retard
- Taux de recouvrement

---

## 🗑️ Corbeille

**Responsable :** `screens/corbeille/corbeille_screen.dart` (595 lignes)

**Fichiers clés :**
- `models/corbeille_item.dart` — entité Corbeille
- `core/logic/culte_lock.dart` — purge automatique 30 jours

**Règle :** Purge après 30 jours, jamais de hard-delete.

---

## 🔔 Notifications

**Responsable :** `core/services/push_notify_service.dart`

**Fichiers clés :**
- `core/services/onesignal_service.dart` — wrapper OneSignal
- `core/notifications/notification_service.dart` — notifications locales
- `core/services/notification_coordinator.dart` — coordination
- `widgets/onesignal_verification_gate.dart` — gate d'ouverture

---

## 📤 Export

**Responsable :** `core/export/`, `core/pdf/`

**Fichiers clés :**
- `core/export/cotisation_export_service.dart` — CSV
- `core/pdf/member_report_pdf_service.dart` (485 lignes) — PDF membre
- `core/pdf/registre_pdf_service.dart` — PDF registre global
- `core/pdf/pdf_service.dart` — utilitaires PDF

---

## 🌐 Temps réel

**Responsable :** `core/realtime/`

**Fichiers clés :**
- `core/realtime/presence_service.dart` — suivi présence
- `core/realtime/realtime_service.dart` — WebSocket
- `core/realtime/realtime_handler.dart` — events
- `core/realtime/realtime_models.dart` — modèles

---

## 🎨 Thème & Widgets

**Fichiers clés :**
- `core/theme/app_theme.dart` (21 edges) — couleurs, polices, light/dark
- `core/theme/motion_tokens.dart` — durées/courbes unifiées
- `widgets/kased_card.dart` — carte réutilisable
- `widgets/empty_state.dart` — état vide
- `widgets/kased_status_badge.dart` — badge statut
- `widgets/kased_gradient_card.dart` — carte dégradé
- `widgets/app_drawer.dart` — navigation latérale
- `widgets/app_shell.dart` — shell avec bottom nav

**Animations :**
- `widgets/motion/animated_appear.dart`
- `widgets/motion/animated_press.dart`
- `widgets/motion/skeleton_loading.dart`
- `widgets/spring_button.dart`
- `widgets/spring_nav_icon.dart`

---

## 🔧 Core utilities

- `core/constants.dart` — toutes les valeurs magiques
- `core/insforge/insforge_config.dart` — config API
- `core/insforge/insforge_service.dart` (450 lignes) — appels HTTP
- `core/utils/uuid.dart` — génération UUID
- `core/utils/storage_helper.dart` — helpers stockage
- `core/preferences/app_prefs.dart` — SharedPreferences
- `core/services/stats_service.dart` — calculs stats
- `controllers/system_controller.dart` — contrôleur système

---

## Pattern de navigation

```
/onboarding       → première visite
/login            → retour utilisateur
/signup           → inscription
/dashboard        → vue globale (stats + accès rapides)
/membres          → liste membres
  /membres/add    → ajouter
  /membres/:id    → détail
    /membres/:id/rapport → export PDF
/cultes           → liste cultes
  /cultes/:id     → détail + cotisations
/stats            → graphiques
/retards          → membres en retard
/corbeille        → éléments supprimés
/profile          → paramètres
```

Transition : `FadeSlidePage` (fade + 4% slide, 320ms)
