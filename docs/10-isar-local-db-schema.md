# 📊 Cartographie Complète — Base de Données Locale (Isar)

> **Version Isar** : `3.1.0+1`
> **Fichier principal** : [isar_local_cache.dart](cotis_app/lib/core/isar_local_cache.dart)
> **Interface** : `LocalCache` (abstraction)

---

## 1. Collections (Tables)

| Collection | Classe | Schema ID | Indexes |
|---|---|---|---|
| `membres` | [membre.dart](cotis_app/lib/models/membre.dart) | `6210858870183803143` | `id` (unique, hash) |
| `cultes` | [culte.dart](cotis_app/lib/models/culte.dart) | `-5204532789017716934` | `id` (unique), `memberIds` |
| `cotisations` | [cotisation.dart](cotis_app/lib/models/cotisation.dart) | `-3683500818952589794` | `id` (unique), `membreId`, `culteId`, composite `(membreId, culteId)` |
| `syncOperations` | [sync_operation.dart](cotis_app/lib/models/sync_operation.dart) | `564399705184180324` | `entityType`, `entityId`, `isSynced` (hash) |
| `corbeilleItems` | [corbeille_item.dart](cotis_app/lib/models/corbeille_item.dart) | `-5095119629384121403` | `entityId`, `entityType`, `deletedAt` (hash) |

---

## 2. Schéma Détaillé par Collection

### 2.1 Membres (`membres`)

```
Membre {
  isarId: Id                 // Auto-increment (clé interne Isar)
  id: String                 // UUID — clé métier (index unique hash)
  nom: String
  prenom: String
  dateAdhesion: DateTime
  dateNaissance: DateTime?
  montantEnAvance: Double    // Default: 0.0
  totalDons: Double          // Default: 0.0
  telephone: String?
  notes: String?
  isActive: Boolean          // Default: true
  updatedAt: DateTime?
  createdAt: DateTime        // Default: now()
  version: Int               // Default: 1 (optimistic locking)
  deviceId: String           // Default: ''
  isDeleted: Boolean         // Default: false (soft-delete)
  deletedAt: DateTime?
  deletedBy: String?
}
```

**Champs calculés (@ignore)** :
- `nomComplet` → `'$prenom $nom'.trim()`
- `initiales` → premières lettres du prénom et nom
- `anniversaireAujourdHui` → booléen
- `age` → int?

** sérialisation** :
- `toJson()` → map pour InsForge (snake_case)
- `fromJson(Map)` → reconstruction depuis InsForge

---

### 2.2 Cultes (`cultes`)

```
Culte {
  isarId: Id
  id: String                 // UUID — clé métier (index unique)
  dateCulte: DateTime
  titre: String?
  montantCotisation: Double  // Default: 50.0
  notes: String?
  updatedAt: DateTime?
  createdAt: DateTime
  version: Int               // Default: 1
  deviceId: String           // Default: ''
  isDeleted: Boolean         // Default: false
  deletedAt: DateTime?
  deletedBy: String?
  memberIds: List<String>    // IDs des membres au moment de la création
}
```

**Propriété calculée** :
- `dateFormatee` → `'   '` (placeholder)

---

### 2.3 Cotisations (`cotisations`)

```
Cotisation {
  isarId: Id
  id: String                 // UUID — clé métier (index unique)
  membreId: String           // FK → membres.id (index)
  culteId: String            // FK → cultes.id (index)
  statut: StatutCotisation   // Enum: nonPaye | paye | absent | enAvance
  montantObligatoire: Double // Default: 50.0
  montantPaye: Double        // Default: 0.0
  montantDon: Double         // Default: 0.0
  datePaiement: DateTime?
  notes: String?
  updatedAt: DateTime?
  createdAt: DateTime
  version: Int               // Default: 1
  deviceId: String           // Default: ''
  isDeleted: Boolean         // Default: false
  deletedAt: DateTime?
  deletedBy: String?
}
```

**Contrainte composite unique** :
- `uniqueKey` = `'$membreId\_$culteId'` (index composite)

**Champs calculés (@ignore)** :
- `estPaye` → `statut != absent && montantPaye >= montantObligatoire`
- `estEnRetard` → `statut != absent && montantPaye < montantObligatoire`

**Méthode `copyWith()`** : permet la mise à jour partielle avec incrément de version

---

### 2.4 Sync Operations (`syncOperations`)

```
SyncOperation {
  isarId: Id
  operationId: String        // UUID de l'opération
  type: String               // 'CREATE' | 'UPDATE' | 'DELETE' | 'RESTORE'

  @Index()
  entityType: String         // 'membre' | 'culte' | 'cotisation'

  @Index()
  entityId: String           // UUID de l'entité concernée

  payloadJson: String        // Données JSON complètes
  createdAt: DateTime
  updatedAt: DateTime?
  deviceId: String           // ID de l'appareil source

  @Index()
  isSynced: Boolean          // Default: false

  hasFailed: Boolean         // Default: false
  lastError: String?
}
```

---

### 2.5 Corbeille (`corbeilleItems`)

```
CorbeilleItem {
  isarId: Id
  entityId: String           // UUID de l'entité supprimée (index)
  entityType: String         // 'culte' | 'membre' (index)
  payloadJson: String        // Données JSON complètes (pour restauration)
  deletedAt: DateTime        // (index)
  updatedAt: DateTime?
}
```

---

> **Note** : `AppNotification` n'est plus une collection Isar. Il est persisté via `SharedPreferences`. Voir [notifications_provider.dart](cotis_app/lib/providers/notifications_provider.dart).

---

## 3. Enumerations

### StatutCotisation
| Valeur | Signification |
|---|---|
| `nonPaye` | Culte passé, pas encore payé |
| `paye` | Payé (jour même ou rattrapage) |
| `absent` | Membre absent ce dimanche |
| `enAvance` | Payé AVANT la date du culte |

---

## 4. Index et Contraintes

| Collection | Index | Type | Unique |
|---|---|---|---|
| membres | `id` | Hash | ✅ |
| cultes | `id` | Hash | ✅ |
| cultes | `memberIds` | Rang | ❌ |
| cotisations | `id` | Hash | ✅ |
| cotisations | `membreId` | Rang | ❌ |
| cotisations | `culteId` | Rang | ❌ |
| cotisations | `membreId + culteId` | Composite | ✅ |
| syncOperations | `entityType` | Hash | ❌ |
| syncOperations | `entityId` | Hash | ❌ |
| syncOperations | `isSynced` | Hash | ❌ |
| corbeilleItems | `entityId` | Hash | ❌ |
| corbeilleItems | `entityType` | Hash | ❌ |
| corbeilleItems | `deletedAt` | Hash | ❌ |

---

## 5. Relations Logiques

```
┌──────────────┐       ┌──────────────┐       ┌─────────────────┐
│   MEMBRES    │──────▶│  COTISATIONS │◀──────│     CULTES      │
│  (membres)   │  1:N  │  (cotisations)│  N:1  │   (cultes)      │
└──────────────┘       └──────────────┘       └─────────────────┘
      │                                                       │
      │                                                       │
      ▼                                                       ▼
┌──────────────┐       ┌─────────────────┐       ┌─────────────────┐
│ CORBEILLE    │       │  SYNC_OPERATIONS │       │ APP_NOTIFICATION│
│  (corbeille) │       │   (syncOps)     │       │  (notifications)│
└──────────────┘       └─────────────────┘       └─────────────────┘
```

---

## 6. Cycle de Vie des Données

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  CRÉATION   │────▶│  SYNC LOCAL │────▶│  SYNC CLOUD │────▶│  CONFLICT   │
│  (local)    │     │  (Isar)     │     │  (InsForge) │     │  (merge)    │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
       │                                                   │
       │                                                   ▼
       │                                            ┌─────────────┐
       │            ┌─────────────┐                │  RESTAURATION │
       └───────────▶│  SOFT-DELETE│                │   (corbeille) │
                    │  (isDeleted)│                └─────────────┘
                    └─────────────┘
                          │
                          ▼
                    ┌─────────────┐
                    │  PURGE 30j  │
                    │  (auto)     │
                    └─────────────┘
```

---

## 7. Stratégie de Sync

### Merge (Local ↔ Cloud)
| Scénario | Comportement |
|---|---|
| Local = new, Cloud = new | **Conflit** → garder le plus récent (`updatedAt`) |
| Local = deleted, Cloud = updated | **Privilégier cloud** (sauf si syncOp en attente) |
| Local = updated, Cloud = unchanged | **Privilégier local** |
| Opération en attente | **Ignorer le merge** pour cette entité |

### SyncOperation
- Créée AVANT l'appel réseau
- Supprimée après succès (pas de retry automatique)
- Champ `retryCount` non utilisé pour le retry — suppression manuelle

---

## 8. Fichiers Générés (.g.dart)

| Fichier | Lignes | Dépendances |
|---|---|---|
| [membre.g.dart](cotis_app/lib/models/membre.g.dart) | ~2170 | Schema + Queries + ByIndex |
| [culte.g.dart](cotis_app/lib/models/culte.g.dart) | ~1800 | Schema + Queries |
| [cotisation.g.dart](cotis_app/lib/models/cotisation.g.dart) | ~2000 | Schema + Queries + Enum |
| [sync_operation.g.dart](cotis_app/lib/models/sync_operation.g.dart) | ~2020 | Schema + Queries |
| [corbeille_item.g.dart](cotis_app/lib/models/corbeille_item.g.dart) | ~1145 | Schema + Queries |
| [app_notification.g.dart](cotis_app/lib/models/app_notification.g.dart) | ~1510 | Schema + Queries |

> ⚠️ Les `.g.dart` sont générés par `dart run build_runner build --delete-conflicting-outputs`

---

## 9. Architecture d'Accès

```
┌─────────────────────────────────────────────────────────────┐
│                     Providers (Riverpod)                    │
│  app_data_provider.dart  │  auth_provider.dart             │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                   IsarLocalCache                            │
│  (cotis_app/lib/core/isar_local_cache.dart)                │
│  - Interface LocalCache                                    │
│  - Toutes les opérations CRUD                              │
│  - Transactions atomiques (writeTxn)                       │
│  - Merge local/cloud                                       │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                        Isar DB                              │
│  - 6 collections                                           │
│  - Index hash sur `id` (UUID)                              │
│  - Recherche par index ou filter                           │
└─────────────────────────────────────────────────────────────┘
```

---

## 10. Points de Vigilance

1. **Soft-delete** : `isDeleted = true` ne supprime pas de Isar — nécessite nettoyage manuel
2. **Corbeille** : purge après 30 jours via `purgeOldCorbeilleItems()` — index sur `deletedAt` pour les performances
3. **SyncOperation** : pas de retry auto — suppression manuelle après succès — index sur `entityType`, `entityId`, `isSynced`
4. **Version** : champ `version` pour optimistic locking (non utilisé dans le merge)
5. **deviceId** : présent sur toutes les collections principales (traçabilité)
6. **AppNotification** : n'est plus une collection Isar — persisté via `SharedPreferences` (pas de `.g.dart` généré)
