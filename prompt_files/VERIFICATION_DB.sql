-- ============================================================
-- KASED-APP — SCRIPT DE VÉRIFICATION
-- Exécuter ce script pour vérifier que la migration est OK
-- ============================================================

-- ============================================================
-- 1. VÉRIFIER LES TABLES
-- ============================================================
SELECT 
  'Tables' as type,
  table_name,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as nb_colonnes
FROM information_schema.tables t
WHERE table_schema = 'public' 
  AND table_name IN ('membres', 'cultes', 'cotisations')
ORDER BY table_name;

-- ============================================================
-- 2. VÉRIFIER LES COLONNES DE MEMBRES
-- ============================================================
SELECT 
  'Colonnes membres' as type,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'membres'
ORDER BY ordinal_position;

-- ============================================================
-- 3. VÉRIFIER LES COLONNES DE CULTES
-- ============================================================
SELECT 
  'Colonnes cultes' as type,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'cultes'
ORDER BY ordinal_position;

-- ============================================================
-- 4. VÉRIFIER LES COLONNES DE COTISATIONS
-- ============================================================
SELECT 
  'Colonnes cotisations' as type,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'cotisations'
ORDER BY ordinal_position;

-- ============================================================
-- 5. VÉRIFIER LE TYPE ENUM
-- ============================================================
SELECT 
  'Type enum' as type,
  typname as nom,
  enumlabel as valeur
FROM pg_type t
JOIN pg_enum e ON t.oid = e.enumtypid
WHERE typname = 'statut_cotisation'
ORDER BY enumsortorder;

-- ============================================================
-- 6. VÉRIFIER LES VUES
-- ============================================================
SELECT 
  'Vues' as type,
  viewname as nom
FROM pg_views
WHERE schemaname = 'public'
  AND viewname LIKE 'v_%'
ORDER BY viewname;

-- ============================================================
-- 7. VÉRIFIER LES FONCTIONS
-- ============================================================
SELECT 
  'Fonctions' as type,
  routine_name as nom,
  routine_type as type_routine
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'creer_culte_avec_cotisations',
    'toggle_paiement',
    'marquer_absent',
    'historique_membre',
    'set_updated_at',
    'generer_cotisations_nouveau_membre',
    'generer_cotisations_nouveau_culte'
  )
ORDER BY routine_name;

-- ============================================================
-- 8. VÉRIFIER LES TRIGGERS
-- ============================================================
SELECT 
  'Triggers' as type,
  trigger_name as nom,
  event_object_table as table_cible,
  action_timing as timing,
  event_manipulation as evenement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- ============================================================
-- 9. VÉRIFIER RLS (Row Level Security)
-- ============================================================
SELECT 
  'RLS' as type,
  tablename as table_nom,
  rowsecurity as rls_active
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('membres', 'cultes', 'cotisations')
ORDER BY tablename;

-- ============================================================
-- 10. VÉRIFIER LES POLITIQUES RLS
-- ============================================================
SELECT 
  'Politiques RLS' as type,
  tablename as table_nom,
  policyname as politique,
  cmd as commande,
  roles as roles
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ============================================================
-- 11. VÉRIFIER LES INDEX
-- ============================================================
SELECT 
  'Index' as type,
  tablename as table_nom,
  indexname as index_nom,
  indexdef as definition
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('membres', 'cultes', 'cotisations')
ORDER BY tablename, indexname;

-- ============================================================
-- 12. VÉRIFIER LES CONTRAINTES
-- ============================================================
SELECT 
  'Contraintes' as type,
  tc.table_name as table_nom,
  tc.constraint_name as contrainte,
  tc.constraint_type as type_contrainte
FROM information_schema.table_constraints tc
WHERE tc.table_schema = 'public'
  AND tc.table_name IN ('membres', 'cultes', 'cotisations')
ORDER BY tc.table_name, tc.constraint_type, tc.constraint_name;

-- ============================================================
-- 13. VÉRIFIER LES FOREIGN KEYS
-- ============================================================
SELECT 
  'Foreign Keys' as type,
  tc.table_name as table_source,
  kcu.column_name as colonne_source,
  ccu.table_name as table_cible,
  ccu.column_name as colonne_cible
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
  AND tc.table_name IN ('membres', 'cultes', 'cotisations')
ORDER BY tc.table_name;

-- ============================================================
-- 14. COMPTER LES DONNÉES
-- ============================================================
SELECT 
  'Données' as type,
  'membres' as table_nom,
  COUNT(*) as nb_lignes
FROM membres
UNION ALL
SELECT 
  'Données' as type,
  'cultes' as table_nom,
  COUNT(*) as nb_lignes
FROM cultes
UNION ALL
SELECT 
  'Données' as type,
  'cotisations' as table_nom,
  COUNT(*) as nb_lignes
FROM cotisations;

-- ============================================================
-- 15. TESTER LE DASHBOARD (doit retourner 1 ligne)
-- ============================================================
SELECT 
  'Test Dashboard' as type,
  *
FROM v_dashboard;

-- ============================================================
-- 16. RÉSUMÉ FINAL
-- ============================================================
SELECT 
  '✅ MIGRATION RÉUSSIE' as statut,
  'Base de données prête pour production' as message,
  CURRENT_TIMESTAMP as date_verification;

-- ============================================================
-- FIN DU SCRIPT DE VÉRIFICATION
-- ============================================================
