# PLAN D'IMPLÉMENTATION — KASED-APP OFFLINE/ONLINE
## 85 micro-tâches réparties en 5 phases

> ⏱️ Estimation : 6-8 heures de travail effectif
> 🎯 Objectif : Architecture offline-first robuste, sans perte de données

---

## PHASE 1 — FONDATIONS : Enrichissement des modèles Isar (18 tâches)

### 1.1 DeviceService (2 tâches)
- [ ] **1.1a** Créer `lib/core/sync/device_service.dart` — lit/ génère un UUID v4 persistant via SharedPreferences
- [ ] **1.1b** Ajouter `shared_preferences` dans `pubspec.yaml` si absent

### 1.2 Enrichir Membre (5 tâches)
- [ ] **1.2a** Ajouter champ `createdAt` (DateTime, requis)
- [ ] **1.2b** Ajouter champ `version` (int, défaut 1)
- [ ] **1.2c** Ajouter champ `deviceId` (String)
- [ ] **1.2d** Ajouter champ `isDeleted` (bool, défaut false)
- [ ] **1.2e** Ajouter champs `deletedAt` (DateTime?) et `deletedBy` (String?)

### 1.3 Enrichir Culte (5 tâches)
- [ ] **1.3a** Ajouter champ `createdAt` (DateTime, requis)
- [ ] **1.3b** Ajouter champ `version` (int, défaut 1)
- [ ] **1.3c** Ajouter champ `deviceId` (String)
- [ ] **1.3d** Ajouter champ `isDeleted` (bool, défaut false)
- [ ] **1.3e** Ajouter champs `deletedAt` (DateTime?) et `deletedBy` (String?)

### 1.4 Enrichir Cotisation (5 tâches)
- [ ] **1.4a** Ajouter champ `createdAt` (DateTime, requis)
- [ ] **1.4b** Ajouter champ `version` (int, défaut 1)
- [ ] **1.4c** Ajouter champ `deviceId` (String)
- [ ] **1.4d** Ajouter champ `isDeleted` (bool, défaut false)
- [ ] **1.4e** Ajouter champs `deletedAt` (DateTime?) et `deletedBy` (String?)

### 1.5 Enrichir SyncOperation (1 tâche)
- [ ] **1.5a** Ajouter operationId (String UUID), retryCount (int, défaut 0), isSynced (bool, défaut false), hasFailed (bool, défaut false), lastError (String?), deviceId (String)

---

## PHASE 2 — MUTATIONS ATOMIQUES + OUTBOX (20 tâches)

### 2.1 Refonte LocalCache interface (6 tâches)
- [ ] **2.1a** Ajouter `saveMembreWithSyncOp(SyncOperation)` (atomique)
- [ ] **2.1b** Ajouter `saveCulteWithSyncOp(SyncOperation)` (atomique)
- [ ] **2.1c** Ajouter `saveCotisationWithSyncOp(SyncOperation)` (atomique)
- [ ] **2.1d** Ajouter `softDeleteMembre(id)` avec SyncOp (atomique)
- [ ] **2.1e** Ajouter `softDeleteCulte(id)` avec SyncOp (atomique)
- [ ] **2.1f** Ajouter `restoreMembre(id)` / `restoreCulte(id)` avec SyncOp

### 2.2 Implémentation IsarLocalCache (6 tâches)
- [ ] **2.2a** Implémenter `saveMembreWithSyncOp` — writeTxn avec put(membre) + put(syncOp)
- [ ] **2.2b** Implémenter `saveCulteWithSyncOp` — idem
- [ ] **2.2c** Implémenter `saveCotisationWithSyncOp` — idem
- [ ] **2.2d** Implémenter `softDeleteMembre` — set isDeleted=true, put SyncOp DELETE
- [ ] **2.2e** Implémenter `softDeleteCulte` — idem
- [ ] **2.2f** Implémenter `restoreMembre` / `restoreCulte` — set isDeleted=false, put SyncOp RESTORE

### 2.3 Refonte app_data_provider.dart (8 tâches)
- [ ] **2.3a** `addMembre` : utiliser DeviceService + createdAt/version/deviceId + saveMembreWithSyncOp
- [ ] **2.3b** `updateMembre` : incrémenter version + updatedAt + saveMembreWithSyncOp
- [ ] **2.3c** `deleteMembre` : remplacer par softDelete + SyncOp DELETE (supprimer CorbeilleItem)
- [ ] **2.3d** `addCulte` : createdAt/version/deviceId + saveCulteWithSyncOp
- [ ] **2.3e** `updateCulte` : incrémenter version + updatedAt + saveCulteWithSyncOp
- [ ] **2.3f** `deleteCulte` : softDelete + SyncOp DELETE
- [ ] **2.3g** `togglePaiement` / `marquerAbsent` : incrémenter version + saveCotisationWithSyncOp
- [ ] **2.3h** `bulkSetPaiements` : batch avec SyncOp pour chaque cotisation

---

## PHASE 3 — SYNC SERVICE (24 tâches)

### 3.1 Création des fichiers de base (4 tâches)
- [ ] **3.1a** Créer `lib/core/sync/sync_service.dart` — classe singleton avec _isSyncing flag
- [ ] **3.1b** Créer `lib/core/sync/conflict_resolver.dart` — LWW par updatedAt + version
- [ ] **3.1c** Créer `lib/core/sync/connectivity_service.dart` — ping réel + watcher
- [ ] **3.1d** Créer `lib/core/sync/sync_status_provider.dart` — Riverpod StateProvider<SyncStatus>

### 3.2 SyncService: Push (8 tâches)
- [ ] **3.2a** `_pushLocalChanges()` — récupérer ops où isSynced=false, hasFailed=false
- [ ] **3.2b** `_sendWithRetry(SyncOperation)` — boucle retry avec backoff exponentiel (1s, 2s, 4s, 8s, 16s)
- [ ] **3.2c** Mapper entityType 'membre' → endpoints create/update/delete membre
- [ ] **3.2d** Mapper entityType 'culte' → endpoints create/update/delete culte
- [ ] **3.2e** Mapper entityType 'cotisation' → endpoints create/update cotisation
- [ ] **3.2f** Mapper operation 'RESTORE' → update + is_active:true / create
- [ ] **3.2g** Marquer isSynced=true après succès, hasFailed=true après maxRetries
- [ ] **3.2h** Mettre à jour syncStatusProvider (idle → syncing → idle/error)

### 3.3 SyncService: Pull (6 tâches)
- [ ] **3.3a** `_pullRemoteChanges()` — lire lastSyncAt depuis SharedPreferences
- [ ] **3.3b** Construire requête delta vers InsForge (filtrer par updated_at > lastSyncAt)
- [ ] **3.3c** Pour chaque changement distant, appliquer conflit LWW via ConflictResolver
- [ ] **3.3d** Persister les changements acceptés dans Isar
- [ ] **3.3e** Mettre à jour lastSyncAt après succès
- [ ] **3.3f** Gérer les DELETE distants (soft-delete local si distant plus récent)

### 3.4 SyncService: Intégration (6 tâches)
- [ ] **3.4a** `triggerSync()` — point d'entrée unique, appelé après chaque mutation locale
- [ ] **3.4b** Watcher connectivité dans `main.dart` → triggerSync() au retour en ligne
- [ ] **3.4c** `_hasRealConnectivity()` — InternetAddress.lookup('insforge.io')
- [ ] **3.4d** Initialisation au démarrage : sync différée de 5 secondes
- [ ] **3.4e** Nettoyage des vieilles SyncOperation réussies (> 7 jours)
- [ ] **3.4f** Supprimer l'ancienne logique syncData() de app_data_provider (remplacer par appel à SyncService)

---

## PHASE 4 — CORBEILLE ROBUSTE (15 tâches)

### 4.1 Ajustement de la corbeille (3 tâches)
- [ ] **4.1a** Lister les éléments supprimés via `getDeletedMembers()` et `getDeletedCultes()` (isDeleted=true)
- [ ] **4.1b** Unité de restauration : set isDeleted=false + SyncOp RESTORE
- [ ] **4.1c** Supprimer le modèle CorbeilleItem (les données sont dans isDeleted + payload)

### 4.2 Amélioration de l'écran existant (12 tâches)
- [ ] **4.2a** Remplacer `corbeilleProvider` par un provider filtrant `isDeleted == true`
- [ ] **4.2b** Restauration unitaire : restaurer via softDelete inverse
- [ ] **4.2c** Bouton "Tout restaurer" : boucle sur les IDs
- [ ] **4.2d** Checkboxes + sélection multiple (conserver l'existant)
- [ ] **4.2e** Tri par date de suppression (isDeletedAt)
- [ ] **4.2f** Tri par date de dernière modification (updatedAt)
- [ ] **4.2g** Affichage des jours restants avant purge automatique
- [ ] **4.2h** Icônes Material uniquement (vérifier aucun émoji)
- [ ] **4.2i** Ajouter purge automatique des éléments isDeleted=true vieux de >30 jours
- [ ] **4.2j** Ajouter compteur d'éléments dans l'AppBar
- [ ] **4.2k** Confirmation avant restauration groupée
- [ ] **4.2l** SnackBar avec résultat de la restauration

---

## PHASE 5 — SÉCURITÉ & ROBUSTESSE FINALE (8 tâches)

### 5.1 Providers filtrés (2 tâches)
- [ ] **5.1a** Ajouter `membersProvider` qui filtre `isDeleted == false`
- [ ] **5.1b** Ajouter `cultesProvider` et `cotisationsProvider` qui filtrent `isDeleted == false`

### 5.2 Sécurité (2 tâches)
- [ ] **5.2a** Vérifier que les tokens InsForge sont dans FlutterSecureStorage ✅ déjà fait
- [ ] **5.2b** Ne jamais logger les payload contenant des données personnelles

### 5.3 Indicateur UI (2 tâches)
- [ ] **5.3a** Ajouter `syncStatusProvider` dans le dashboard (icône sync rotation / check / error)
- [ ] **5.3b** Ajouter un `SyncIndicator` widget réutilisable

### 5.4 Finalisation (2 tâches)
- [ ] **5.4a** Exécuter `build_runner` pour regénérer les fichiers *.g.dart
- [ ] **5.4b** Exécuter `flutter analyze` + `flutter test` → tout doit passer

---

## CHECKLIST DE DÉPENDANCES ENTRE PHASES

```
Phase 1 ──────────────────┐
                          ▼
Phase 2 ────▶ Dépend de Phase 1 (modèles enrichis)
                          ▼
Phase 3 ────▶ Dépend de Phase 2 (SyncOperation créées par les mutations)
              Dépend de Phase 1 (champs updatedAt/version pour conflits)
                          ▼
Phase 4 ────▶ Dépend de Phase 1 (isDeleted sur tous les modèles)
              Dépend de Phase 2 (soft delete dans les mutations)
                          ▼
Phase 5 ────▶ Dépend de toutes les phases précédentes
```

## TOTAL : 85 micro-tâches
