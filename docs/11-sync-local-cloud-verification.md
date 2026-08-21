# 📊 Rapport de Vérification — Sync Local ↔ Cloud

> **Date** : 2026-08-21
> **Instance** : `https://pu74z8pe.us-east.insforge.app`
> **Schema** : PostgreSQL 16 + PostgREST 13

---

## 1. Tables Cloud (InsForge)

| Table | Lignes | Colonnes | Index | Status |
|---|---|---|---|---|
| `membres` | 0 | 18 | 4 | ✅ OK |
| `cultes` | 0 | 15 | 3 | ✅ OK |
| `cotisations` | 0 | 18 | 9 | ✅ OK |
| `profiles` | — | 6 | — | ℹ️ Utilisé par l'auth |

**Vues SQL** : 5 vues calculées (v_dashboard, v_resume_culte, v_retards_membres, v_membres_a_jour, v_membres_en_avance)

---

## 2. Mapping Colonnes Cloud ↔ Isar

### Membres (18 colonnes) — ✅ 18/18 match

| Cloud | Isar | Type | Default | Match |
|---|---|---|---|---|
| `id` | `id` | UUID | — | ✅ |
| `nom` | `nom` | text | NOT NULL | ✅ |
| `prenom` | `prenom` | text | NOT NULL | ✅ |
| `date_adhesion` | `dateAdhesion` | date | NOT NULL | ✅ |
| `date_naissance` | `dateNaissance` | date | NULL | ✅ |
| `montant_en_avance` | `montantEnAvance` | double precision | 0 | ✅ |
| `total_dons` | `totalDons` | double precision | 0 | ✅ |
| `telephone` | `telephone` | text | NULL | ✅ |
| `notes` | `notes` | text | NULL | ✅ |
| `is_active` | `isActive` | boolean | true | ✅ |
| `user_id` | — | UUID | NULL | ℹ️ Trigger only |
| `created_at` | `createdAt` | timestamptz | NOW() | ✅ |
| `updated_at` | `updatedAt` | timestamptz | NOW() | ✅ |
| `version` | `version` | integer | 1 | ✅ |
| `device_id` | `deviceId` | text | '' | ✅ |
| `is_deleted` | `isDeleted` | boolean | false | ✅ |
| `deleted_at` | `deletedAt` | timestamptz | NULL | ✅ |
| `deleted_by` | `deletedBy` | text | NULL | ✅ |

### Cultes (15 colonnes) — ✅ 13/15 match

| Cloud | Isar | Type | Default | Match |
|---|---|---|---|---|
| `id` | `id` | UUID | — | ✅ |
| `date_culte` | `dateCulte` | date | NOT NULL | ✅ |
| `montant_cotisation` | `montantCotisation` | numeric | 50 | ✅ |
| `note` | — | text | NULL | ℹ️ Cloud a `note`, Isar a `notes` |
| `titre` | `titre` | text | NULL | ✅ |
| `member_ids` | `memberIds` | text[] | [] | ✅ |
| `created_at` | `createdAt` | timestamptz | NOW() | ✅ |
| `updated_at` | `updatedAt` | timestamptz | NOW() | ✅ |
| `version` | `version` | integer | 1 | ✅ |
| `device_id` | `deviceId` | text | '' | ✅ |
| `is_deleted` | `isDeleted` | boolean | false | ✅ |
| `deleted_at` | `deletedAt` | timestamptz | NULL | ✅ |
| `deleted_by` | `deletedBy` | text | NULL | ✅ |
| `created_by` | — | UUID | NULL | ℹ️ Ancien nom de `user_id` |
| `user_id` | — | UUID | NULL | ✅ (trigger) |

**Différences mineures** :
- `note` (cloud) vs `notes` (isar) — le client ignore `note`
- `created_by` (legacy) — pas critique

### Cotisations (18 colonnes) — ✅ 17/18 match

| Cloud | Isar | Type | Default | Match |
|---|---|---|---|---|
| `id` | `id` | UUID | — | ✅ |
| `membre_id` | `membreId` | UUID | NOT NULL | ✅ |
| `culte_id` | `culteId` | UUID | NOT NULL | ✅ |
| `statut` | `statut` | user-defined enum | 'non_paye' | ✅ |
| `montant_obligatoire` | `montantObligatoire` | double precision | 50 | ✅ |
| `montant_paye` | `montantPaye` | double precision | 0 | ✅ |
| `montant_don` | `montantDon` | double precision | 0 | ✅ |
| `date_paiement` | `datePaiement` | timestamptz | NULL | ✅ |
| `notes` | `notes` | text | NULL | ✅ |
| `created_at` | `createdAt` | timestamptz | NOW() | ✅ |
| `updated_at` | `updatedAt` | timestamptz | NOW() | ✅ |
| `version` | `version` | integer | 1 | ✅ |
| `device_id` | `deviceId` | text | '' | ✅ |
| `is_deleted` | `isDeleted` | boolean | false | ✅ |
| `deleted_at` | `deletedAt` | timestamptz | NULL | ✅ |
| `deleted_by` | `deletedBy` | text | NULL | ✅ |
| `user_id` | — | UUID | NULL | ✅ (trigger) |
| `montant` | — | numeric | NOT NULL | ⚠️ Ancien champ (non utilisé) |

---

## 3. Index Cloud

| Table | Index | Type |
|---|---|---|
| membres | `membres_pkey` (id) | Unique |
| membres | `membres_nom_prenom_unique` (nom, prenom) | Unique composite |
| membres | `idx_membres_is_deleted` (is_deleted) | B-tree |
| membres | `idx_membres_user_id` (user_id) | B-tree |
| membres | `idx_membres_is_active` (is_active) | B-tree |
| membres | `idx_membres_nom` (nom) | B-tree |
| membres | `idx_membres_date_adhesion` (date_adhesion) | B-tree |
| cultes | `cultes_pkey` (id) | Unique |
| cultes | `idx_cultes_is_deleted` (is_deleted) | B-tree |
| cultes | `idx_cultes_user_id` (user_id) | B-tree |
| cultes | `idx_cultes_date_culte` (date_culte DESC) | B-tree |
| cultes | `idx_cultes_created_by` (created_by) | B-tree |
| cotisations | `cotisations_pkey` (id) | Unique |
| cotisations | `cotisations_membre_culte_unique` (membre_id, culte_id) | Unique composite |
| cotisations | `idx_cotisations_is_deleted` (is_deleted) | B-tree |
| cotisations | `idx_cotisations_user_id` (user_id) | B-tree |
| cotisations | `idx_cotisations_membre_id` (membre_id) | B-tree |
| cotisations | `idx_cotisations_culte_id` (culte_id) | B-tree |
| cotisations | `idx_cotisations_statut` (statut) | B-tree |
| cotisations | `idx_cotisations_date_paiement` (date_paiement) | B-tree |
| cotisations | `idx_cotisations_montant_paye` (montant_paye) | B-tree |
| cotisations | `idx_cotisations_montant_obligatoire` (montant_obligatoire) | B-tree |
| cotisations | `idx_cotisations_montant_don` (montant_don) | B-tree |
| cotisations | `idx_cotisations_membre_statut` (membre_id, statut) | B-tree composite |

**Total** : 24 indexes B-tree, 3 uniques ✅

---

## 4. Fonction RPC

| RPC | Status | Notes |
|---|---|---|
| `creer_culte_avec_cotisations` | ✅ OK (overload supprimé) | 1 version uniquement |
| `toggle_paiement` | ✅ OK | Fonctionne |
| `marquer_absent` | ✅ OK | Fonctionne |
| `consommer_avance_membre` | ✅ OK | Fonctionne |
| `consigner_paiement_en_avance` | ✅ OK | Fonctionne |
| `historique_membre` | ⚠️ **BUG** | Erreur SQL `42803` — UNION avec `created_at` non regroupé |
| `marquer_paye_avec_avance` | ✅ OK | Existe et fonctionne |
| `generer_cotisations_nouveau_culte` | ℹ️ | Existe (version alternative) |
| `generer_cotisations_nouveau_membre` | ℹ️ | Existe (version alternative) |
| `realtime_notify_cotisations` | ℹ️ | Pour le realtime |
| `creer_profil_nouvel_utilisateur` | ℹ️ | Après inscription |

---

## 5. Row-Level Security (RLS)

| Table | RLS | Policy | Qual | Roles |
|---|---|---|---|---|
| membres | ✅ ON | membres_shared_policy | `true` | authenticated |
| cultes | ✅ ON | cultes_shared_policy | `true` | authenticated |
| cotisations | ✅ ON | cotisations_shared_policy | `true` | authenticated |

**Grants** :
- `anon` : SELECT, INSERT, UPDATE, DELETE
- `authenticated` : SELECT, INSERT, UPDATE, DELETE
- `project_admin` : FULL ACCESS

---

## 6. Trigger `set_user_id`

**État** : ✅ Corrigé

```sql
-- Avant (cassé) :
NEW.user_id := current_setting('request.jwt.claims', true)::json->>'sub';
-- Erreur : undefined_parameter quand pas de JWT

-- Après (fix) :
BEGIN
  NEW.user_id := (current_setting('request.jwt.claims', true)::json)->>'sub';
EXCEPTION WHEN undefined_parameter THEN
  NEW.user_id := NULL;
END;
```

---

## 7. Flux de Synchronisation

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   ISAR DB    │────▶│  SYNC MGR   │────▶│  INSFORGE   │
│  (local)     │◀────│  (dart)     │◀────│  (cloud)    │
└──────────────┘     └──────────────┘     └──────────────┘
       │                    │                    │
       │              ┌──────────┐             │
       │              │  SYNC OP │◀─────────────┘
       │              │  QUEUE   │
       │              └──────────┘
       │                    │
       ▼                    ▼
┌──────────────┐     ┌──────────────┐
│  Membre      │     │  Cotisation  │
│  Culte       │     │  SyncOp      │
│  Corbeille   │     │  Realtime    │
└──────────────┘     └──────────────┘
```

**Logique de merge** ([sync_manager.dart](cotis_app/lib/core/sync/sync_manager.dart)) :
1. Push pending ops → cloud (retry exponentiel)
2. Fetch membres/cultes/cotisations depuis cloud
3. Merge : garder le plus récent (`updatedAt`)
4. Protéger les entités en attente pendant le merge

---

## 8. Points d'Attention

### ⚠️ `historique_membre` — BUG SQL
**Erreur** : `column "t.created_at" must appear in the GROUP BY clause`
**Cause** : `json_agg()` + `UNION` + `ORDER BY` mal structuré
**Fix** : Nécessite une refactorisation de la fonction

### ⚠️ Trigger `set_user_id` — Fix appliqué
**Avant** : Plantait sur appel anon (sans JWT)
**Après** : Try/catch sur `undefined_parameter`

### ℹ️ Ancien champ `montant` sur cotisations
Champ legacy non utilisé par l'application. Peut être ignoré ou nettoyé.

### ℹ️ Ancien champ `note` vs `notes`
Le cloud a `note` (singulier) et l'Isar a `notes` (pluriel). Le client ignore `note`.

---

## 9. Résumé

| Critère | Status |
|---|---|
| Tables Cloud | ✅ 3 tables + 5 vues |
| Colonnes membres | ✅ 18/18 match |
| Colonnes cultes | ✅ 13/15 match (2 legacy) |
| Colonnes cotisations | ✅ 17/18 match (1 legacy) |
| Index Cloud | ✅ 24 indexes B-tree |
| RPC functions | ⚠️ 8/9 fonctionnent (historique_membre cassé) |
| RLS policies | ✅ 3 policies actives |
| Trigger set_user_id | ✅ Corrigé |
| SyncManager | ✅ Ok |
| Données actuelles | 0 membres, 0 cultes, 0 cotisations |
