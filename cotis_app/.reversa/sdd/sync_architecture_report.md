══════════════════════════════════════════
RAPPORT DE DIAGNOSTIC — KASED-APP SYNC
══════════════════════════════════════════

## 1. INVENTAIRE DES MODÈLES ISAR

    ├── Membre (membre.dart)
    │   ├── id (String, unique, @Index)
    │   ├── nom, prenom, dateAdhesion
    │   ├── dateNaissance?, telephone?, notes?
    │   ├── isActive (bool, default true)
    │   ├── updatedAt (DateTime?)  ← ✅ AJOUTÉ récemment
    │   ├── createdAt       ← ❌ MANQUANT
    │   ├── version         ← ❌ MANQUANT
    │   ├── deviceId        ← ❌ MANQUANT
    │   ├── isDeleted       ← ❌ MANQUANT (utilise isActive à la place = soft delete partiel)
    │   ├── deletedAt       ← ❌ MANQUANT
    │   └── deletedBy       ← ❌ MANQUANT
    │
    ├── Culte (culte.dart)
    │   ├── id (String, unique, @Index)
    │   ├── dateCulte, titre?, montantCotisation (50.0), notes?
    │   ├── updatedAt (DateTime?)  ← ✅ AJOUTÉ récemment
    │   ├── createdAt       ← ❌ MANQUANT
    │   ├── version         ← ❌ MANQUANT
    │   ├── deviceId        ← ❌ MANQUANT
    │   ├── isDeleted       ← ❌ MANQUANT
    │   ├── deletedAt       ← ❌ MANQUANT
    │   └── deletedBy       ← ❌ MANQUANT
    │
    ├── Cotisation (cotisation.dart)
    │   ├── id (String, unique @Index), membreId (@Index), culteId (@Index)
    │   ├── statut (StatutCotisation enum: nonPaye/paye/absent/enAvance)
    │   ├── montant (50.0), datePaiement?, notes?
    │   ├── uniqueKey (composite @Index)
    │   ├── updatedAt (DateTime?)  ← ✅ AJOUTÉ récemment
    │   ├── createdAt       ← ❌ MANQUANT
    │   ├── version         ← ❌ MANQUANT
    │   ├── deviceId        ← ❌ MANQUANT
    │   ├── isDeleted       ← ❌ MANQUANT
    │   ├── deletedAt       ← ❌ MANQUANT
    │   └── deletedBy       ← ❌ MANQUANT
    │
    ├── Paiement (paiement.dart) ← Modèle redondant avec Cotisation
    │   ├── id (String, unique @Index), membreId (@Index), culteId (@Index)
    │   ├── datePaiement, montant (50.0)
    │   ├── uniqueKey (composite @Index)
    │   └── Aucun champ de sync ❌ (updatedAt, version, etc.)
    │
    ├── SyncOperation (sync_operation.dart) ← Existe mais INCOMPLET
    │   ├── isarId (autoIncrement), type, entityType, entityId
    │   ├── payloadJson (String), createdAt, updatedAt?
    │   ├── operationId     ← ❌ MANQUANT (pas de UUID unique)
    │   ├── retryCount      ← ❌ MANQUANT
    │   ├── isSynced        ← ❌ MANQUANT
    │   ├── hasFailed       ← ❌ MANQUANT
    │   ├── lastError       ← ❌ MANQUANT
    │   └── deviceId        ← ❌ MANQUANT
    │
    ├── CorbeilleItem (corbeille_item.dart) ← Modèle de corbeille dédié
    │   ├── entityId, entityType, payloadJson, deletedAt
    │   └── updatedAt (DateTime?)  ← ✅ AJOUTÉ récemment
    │
    └── AppNotification (app_notification.dart) ← NOUVEAU
        ├── id, titre, message, date, isLue, typeEvenement, entiteId
        └── Aucun champ de sync requis

## 2. COUCHE SYNC ACTUELLE

    ├── SyncService                    ← ❌ N'EXISTE PAS
    │   La logique de sync est noyée dans app_data_provider.dart
    │   sous forme de méthode syncData() avec 260 lignes de God method
    │
    ├── Queue de sync (Outbox)         ← ⚠️ PARTIEL
    │   Une SyncOperation est créée via _queueSyncOperation()
    │   MAIS :
    │   • Pas de retry count
    │   • Pas de marquage isSynced/hasFailed
    │   • Pas d'operationId unique
    │   • Pas de deviceId
    │   • Le flush se fait dans syncData() au milieu du pull cloud
    │
    ├── Retry/backoff                  ← ❌ ABSENT
    │   En cas d'échec, l'opération reste en queue mais
    │   ne sera retentée qu'au prochain syncData() complet
    │   (déclenché par connectivité ou manuel)
    │
    ├── Delta sync (last_sync_at)      ← ❌ ABSENT
    │   syncData() fetch TOUJOURS la totalité des données cloud
    │   via getAllMembres() / getCultes() / getCotisations()
    │   Aucun filtre "modifié depuis" n'est appliqué
    │
    ├── Résolution de conflits         ← ⚠️ PARTIEL
    │   mergeFromCloud() compare updatedAt (LWW basique)
    │   MAIS : pas de version field, pas de deviceId
    │
    ├── Watcher connectivité           ← ✅ EXISTANT
    │   Dans app_data_provider.build()
    │   Écoute Connectivity().onConnectivityChanged
    │   Déclenche syncData() si _shouldSync()
    │
    └── Ping réel (InternetAddress)    ← ❌ ABSENT
        connectivity_plus peut détecter "connecté au WiFi"
        même sans accès Internet réel

## 3. FLUX CRITIQUES — ÉTAT ACTUEL

    ├── Offline → Online (création membre)
    │   ┌─ 1. Membre créé localement (Isar put)
    │   ├─ 2. Tentative API : si échec → queue SyncOperation
    │   ├─ 3. Retour connectivité : syncData() flush queue
    │   ├─ 4. Puis fetch cloud complet → mergeFromCloud()
    │   └─ ✅ FONCTIONNEL après correctifs récents
    │
    ├── Validation paiement
    │   ┌─ 1. togglePaiement() : mise à jour optimiste locale
    │   ├─ 2. Tentative API : si échec → queue SyncOperation
    │   ├─ 3. Si cotisation inexistante → création automatique
    │   └─ ✅ FONCTIONNEL après correctifs récents
    │
    ├── Suppression
    │   ┌─ deleteMembre / deleteCulte
    │   ├─ Sauvegarde dans CorbeilleItem (payload JSON complet)
    │   ├─ Puis suppression PHYSIQUE de Isar (deleteAll)
    │   └─ 🔴 VIOLATION : delete physique = isDeleted toujours false
    │       La restauration dépend entièrement du CorbeilleItem
    │
    └── Démarrage app
        ┌─ 1. Isar chargé en premier (local-first ✅)
        ├─ 2. Sync différée de 3 secondes
        └─ ✅ BONNE APPROCHE

## 4. LISTE DES FICHIERS À CRÉER

    ┌─ lib/core/sync/sync_service.dart        ← Service de sync centralisé
    ├─ lib/core/sync/device_service.dart      ← UUID d'appareil persistant
    ├─ lib/core/sync/sync_status_provider.dart ← État de sync pour l'UI
    ├─ lib/core/sync/connectivity_service.dart ← Ping réel + watcher
    └─ lib/core/sync/conflict_resolver.dart   ← Logique LWW + merge

## 5. LISTE DES FICHIERS À MODIFIER

    ┌─ models/membre.dart        → Ajouter createdAt, version, deviceId, isDeleted, deletedAt, deletedBy
    ├─ models/culte.dart         → Ajouter createdAt, version, deviceId, isDeleted, deletedAt, deletedBy
    ├─ models/cotisation.dart    → Ajouter createdAt, version, deviceId, isDeleted, deletedAt, deletedBy
    ├─ models/paiement.dart      → Ajouter createdAt, updatedAt, version, deviceId, isDeleted
    ├─ models/sync_operation.dart→ Ajouter operationId, retryCount, isSynced, hasFailed, lastError, deviceId
    ├─ models/corbeille_item.dart→ Déjà partiellement équipé
    ├─ core/isar_local_cache.dart→ Refondre pour writeTxn atomique + création SyncOp
    ├─ core/local_cache.dart     → Ajouter méthodes pour sync
    ├─ providers/app_data_provider.dart → Extraire syncData() vers SyncService
    └─ lib/main.dart             → Initialiser SyncService + watcher connectivité

## 6. RISQUES IDENTIFIÉS

    🔴 P0 — Delete physique (membre.dart:48, culte.dart:55 dans isar_local_cache)
        deleteAll() est appelé sans passer par isDeleted=true
        → Données perdues si CorbeilleItem est purgé

    🔴 P0 — Pas de version field sur les entités
        → En cas de conflit simultané (deux appareils modifient en même temps),
        impossible de déterminer l'ordre. updatedAt a une résolution secondes.

    🟠 P1 — SyncOperation sans retryCount
        → Une opération échouée reste en queue indéfiniment et
        sera retentée éternellement à chaque sync

    🟠 P1 — Pas de delta sync
        → getAllMembres() charge TOUS les membres à chaque sync
        → Problématique avec 1000+ membres

    🟠 P1 — SharedPreferences non utilisé pour lastSyncAt
        → (non implémenté du tout)

    🟡 P2 — Paiement modèle redondant
        → Paiement et Cotisation coexistent avec des champs similaires

    🟡 P2 — app_data_provider.dart God class (960+ lignes)
        → Logique métier + sync + UI mélangée
