# KASED-APP — PROMPT D'EXÉCUTION SQL (AGENT)

> Passe ce fichier à ton agent pour appliquer la migration de base de données.
> Il doit suivre les phases dans l'ordre et confirmer avant de passer à la suivante.

---

## ██ CONTEXTE

Application : kased-app (Supabase + Flutter)
Objectif : corriger la table `membres` (découplage de Google Auth) et créer les tables
`cotisations`, vues calculées, fonctions et triggers pour la gestion de cotisations d'église.

---

## ██ PROBLÈME À CORRIGER (CRITIQUE)

La table `membres` actuelle est couplée à Google Auth avec des colonnes du type :
`google_id`, `photo_url`, `email`, `auth_user_id`, etc.

Ce couplage est une erreur : les membres de l'église ne sont PAS des utilisateurs
de l'application. Le secrétaire est le seul utilisateur (via Google Auth).
Les membres sont des données manuelles saisies par le secrétaire.

---

## ██ PHASE 0 — AUDIT DE L'ÉTAT ACTUEL (AVANT TOUTE MODIFICATION)

```sql
-- Exécuter d'abord pour voir l'état réel des tables
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('membres', 'paiement', 'cultes')
ORDER BY table_name, ordinal_position;
```

Lister exactement les colonnes trouvées dans chaque table.
Identifier les colonnes liées à Google Auth dans `membres`.
NE PAS modifier quoi que ce soit en Phase 0.
Écrire "PHASE 0 VALIDÉE" avec la liste des colonnes trouvées.

---

## ██ PHASE 1 — CORRECTION TABLE MEMBRES

Adapter la Section A du fichier SQL selon les colonnes réelles trouvées en Phase 0.
Remplacer les noms de colonnes Google par les noms exacts dans la vraie table.

Exemple : si la table a `user_id` au lieu de `auth_user_id`, adapter le DROP COLUMN.

```sql
-- Vérifier après exécution :
SELECT column_name FROM information_schema.columns
WHERE table_name = 'membres' ORDER BY ordinal_position;
```

Résultat attendu : nom, prenom, telephone, date_adhesion, is_active, notes, created_at, updated_at
Plus aucune colonne liée à Google.
Écrire "PHASE 1 VALIDÉE" + liste des colonnes restantes.

---

## ██ PHASE 2 — CRÉER LE TYPE ENUM ET LES NOUVELLES TABLES

Exécuter dans cet ordre :
1. Section C (type enum `statut_cotisation`)
2. Section B (table `cultes` — vérifier si elle existe déjà et l'adapter)
3. Section D (table `cotisations`)

```sql
-- Vérifier après exécution :
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' ORDER BY table_name;

SELECT typname FROM pg_type WHERE typname = 'statut_cotisation';
```

Résultat attendu : membres, cultes, cotisations + type statut_cotisation présent.
Écrire "PHASE 2 VALIDÉE".

---

## ██ PHASE 3 — VUES ET FONCTIONS

Exécuter :
1. Section E (5 vues calculées)
2. Section F (4 fonctions utilitaires)

```sql
-- Vérifier les vues
SELECT viewname FROM pg_views WHERE schemaname = 'public';

-- Vérifier les fonctions
SELECT routine_name FROM information_schema.routines
WHERE routine_schema = 'public' AND routine_type = 'FUNCTION';
```

Résultat attendu :
Vues : v_resume_culte, v_retards_membres, v_membres_a_jour, v_membres_en_avance, v_dashboard
Fonctions : creer_culte_avec_cotisations, toggle_paiement, marquer_absent, historique_membre

Écrire "PHASE 3 VALIDÉE".

---

## ██ PHASE 4 — TRIGGERS ET RLS

Exécuter :
1. Section G (3 triggers)
2. Section H (RLS)

```sql
-- Vérifier les triggers
SELECT trigger_name, event_object_table FROM information_schema.triggers
WHERE trigger_schema = 'public';

-- Vérifier RLS activé
SELECT tablename, rowsecurity FROM pg_tables
WHERE schemaname = 'public';
```

Résultat attendu : 3 triggers présents, RLS = true sur les 3 tables.
Écrire "PHASE 4 VALIDÉE".

---

## ██ PHASE 5 — TEST FONCTIONNEL

Exécuter les données de test (Section I décommentée) :

```sql
-- Tester la création d'un culte avec cotisations auto
SELECT creer_culte_avec_cotisations(CURRENT_DATE, 'Culte test', 50);

-- Vérifier que les cotisations ont été générées
SELECT COUNT(*) FROM cotisations WHERE culte_id = (
  SELECT id FROM cultes WHERE date_culte = CURRENT_DATE
);

-- Tester toggle paiement pour le premier membre
SELECT toggle_paiement(
  (SELECT id FROM membres LIMIT 1),
  (SELECT id FROM cultes WHERE date_culte = CURRENT_DATE)
);

-- Vérifier le dashboard
SELECT * FROM v_dashboard;

-- Vérifier les retards
SELECT * FROM v_retards_membres;
```

Résultat attendu :
- Autant de cotisations que de membres actifs créées pour le culte du jour
- Toggle change le statut de 'non_paye' à 'paye'
- v_retards_membres vide si tous ont payé, ou listant les retardataires

Écrire "PHASE 5 VALIDÉE — BASE DE DONNÉES PRÊTE".

---

## ██ RÈGLES ANTI-RÉGRESSION

1. TOUJOURS vérifier l'état réel avant de DROP une colonne
2. UTILISER IF EXISTS / IF NOT EXISTS sur tout CREATE et DROP
3. ON CONFLICT DO NOTHING sur toutes les insertions de test
4. NE JAMAIS supprimer la table paiement existante sans confirmation explicite
   (elle peut contenir des données historiques à migrer)
5. Si une colonne existe déjà avec le bon type, passer la Phase sans rien faire

---

## ██ MIGRATION DES DONNÉES EXISTANTES (si table paiement contient des données)

Si la table `paiement` existante contient des données, exécuter cette migration AVANT
de la supprimer :

```sql
-- Vérifier d'abord le contenu de paiement
SELECT COUNT(*), column_name
FROM paiement, information_schema.columns
WHERE table_name = 'paiement'
GROUP BY column_name;

-- Migrer les données (adapter selon les vraies colonnes de paiement)
INSERT INTO cotisations (membre_id, culte_id, statut, montant, date_paiement)
SELECT
  p.membre_id,                          -- adapter si nom différent
  p.culte_id,                           -- adapter si nom différent
  CASE WHEN p.montant > 0 THEN 'paye'::statut_cotisation
       ELSE 'non_paye'::statut_cotisation END,
  COALESCE(p.montant, 50),
  p.created_at                          -- adapter si nom différent
FROM paiement p
ON CONFLICT (membre_id, culte_id) DO NOTHING;

-- Vérifier le count après migration
SELECT COUNT(*) FROM cotisations;
-- Doit être >= COUNT(*) FROM paiement

-- Seulement APRÈS validation, archiver l'ancienne table :
-- ALTER TABLE paiement RENAME TO paiement_archive;
```

---

*Fichier généré pour Ok · kased-app · Migration DB*
*Stack : Supabase PostgreSQL · Flutter/Dart*
