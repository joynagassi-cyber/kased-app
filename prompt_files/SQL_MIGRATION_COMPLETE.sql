-- ============================================================
-- KASED-APP — SCRIPT COMPLET DE MIGRATION BASE DE DONNÉES
-- À EXÉCUTER SUR INSFORGE (PostgreSQL)
-- ============================================================
-- Date : 2026-08-14
-- Objectif : Créer toutes les tables, vues, fonctions et triggers
-- ============================================================

-- ============================================================
-- SECTION 1 : CORRECTION TABLE MEMBRES
-- ============================================================

-- Supprimer les colonnes liées à Google Auth si elles existent
ALTER TABLE membres
  DROP COLUMN IF EXISTS google_id,
  DROP COLUMN IF EXISTS photo_url,
  DROP COLUMN IF EXISTS email,
  DROP COLUMN IF EXISTS provider_id,
  DROP COLUMN IF EXISTS auth_user_id;

-- Ajouter les colonnes manquantes pour la gestion manuelle
ALTER TABLE membres
  ADD COLUMN IF NOT EXISTS nom          TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS prenom       TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS telephone    TEXT,
  ADD COLUMN IF NOT EXISTS date_adhesion DATE NOT NULL DEFAULT CURRENT_DATE,
  ADD COLUMN IF NOT EXISTS is_active    BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS notes        TEXT,
  ADD COLUMN IF NOT EXISTS created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- Contrainte unicité sur nom complet
ALTER TABLE membres
  DROP CONSTRAINT IF EXISTS membres_nom_prenom_unique;
ALTER TABLE membres
  ADD CONSTRAINT membres_nom_prenom_unique UNIQUE (nom, prenom);

-- Index pour les requêtes fréquentes
CREATE INDEX IF NOT EXISTS idx_membres_is_active      ON membres (is_active);
CREATE INDEX IF NOT EXISTS idx_membres_date_adhesion  ON membres (date_adhesion);
CREATE INDEX IF NOT EXISTS idx_membres_nom            ON membres (nom, prenom);

-- Contrainte CHECK sur date_adhesion
ALTER TABLE membres
  DROP CONSTRAINT IF EXISTS membres_date_adhesion_check;
ALTER TABLE membres
  ADD CONSTRAINT membres_date_adhesion_check
    CHECK (date_adhesion <= CURRENT_DATE);


-- ============================================================
-- SECTION 2 : TABLE CULTES
-- ============================================================

CREATE TABLE IF NOT EXISTS cultes (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date_culte          DATE NOT NULL,
  titre               TEXT,
  notes               TEXT,
  montant_cotisation  NUMERIC(10, 2) NOT NULL DEFAULT 50.00,
  created_by          UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT cultes_date_unique UNIQUE (date_culte)
);

-- Index
CREATE INDEX IF NOT EXISTS idx_cultes_date_culte  ON cultes (date_culte DESC);
CREATE INDEX IF NOT EXISTS idx_cultes_created_by  ON cultes (created_by);


-- ============================================================
-- SECTION 3 : TYPE ENUM STATUT COTISATION
-- ============================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'statut_cotisation') THEN
    CREATE TYPE statut_cotisation AS ENUM (
      'non_paye',   -- Culte passé, pas encore payé
      'paye',       -- Payé (le jour même ou en rattrapage)
      'absent',     -- Membre absent ce dimanche
      'en_avance'   -- Payé AVANT la date du culte
    );
  END IF;
END$$;


-- ============================================================
-- SECTION 4 : TABLE COTISATIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS cotisations (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  membre_id       UUID NOT NULL REFERENCES membres(id) ON DELETE CASCADE,
  culte_id        UUID NOT NULL REFERENCES cultes(id)  ON DELETE CASCADE,
  statut          statut_cotisation NOT NULL DEFAULT 'non_paye',
  montant         NUMERIC(10, 2) NOT NULL DEFAULT 50.00,
  date_paiement   TIMESTAMPTZ,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT cotisations_membre_culte_unique UNIQUE (membre_id, culte_id),
  CONSTRAINT cotisations_paiement_coherence CHECK (
    (statut IN ('paye', 'en_avance') AND date_paiement IS NOT NULL)
    OR
    (statut IN ('non_paye', 'absent') AND date_paiement IS NULL)
  )
);

-- Index
CREATE INDEX IF NOT EXISTS idx_cotisations_membre_id    ON cotisations (membre_id);
CREATE INDEX IF NOT EXISTS idx_cotisations_culte_id     ON cotisations (culte_id);
CREATE INDEX IF NOT EXISTS idx_cotisations_statut        ON cotisations (statut);
CREATE INDEX IF NOT EXISTS idx_cotisations_date_paiement ON cotisations (date_paiement);
CREATE INDEX IF NOT EXISTS idx_cotisations_membre_statut ON cotisations (membre_id, statut);


-- ============================================================
-- SECTION 5 : VUES CALCULÉES
-- ============================================================

-- Vue E1 : Résumé par culte
CREATE OR REPLACE VIEW v_resume_culte AS
SELECT
  c.id                                                        AS culte_id,
  c.date_culte,
  COALESCE(c.titre, 'Culte du ' || TO_CHAR(c.date_culte, 'DD/MM/YYYY')) AS titre,
  c.montant_cotisation,
  COUNT(co.id)                                                AS total_membres,
  COUNT(co.id) FILTER (WHERE co.statut IN ('paye','en_avance')) AS total_payes,
  COUNT(co.id) FILTER (WHERE co.statut = 'non_paye')         AS total_non_payes,
  COUNT(co.id) FILTER (WHERE co.statut = 'absent')           AS total_absents,
  COUNT(co.id) FILTER (WHERE co.statut = 'en_avance')        AS total_en_avance,
  SUM(co.montant) FILTER (WHERE co.statut IN ('paye','en_avance'))
                                                              AS montant_collecte,
  (COUNT(co.id) * c.montant_cotisation)                       AS montant_attendu
FROM cultes c
LEFT JOIN cotisations co ON co.culte_id = c.id
GROUP BY c.id, c.date_culte, c.titre, c.montant_cotisation
ORDER BY c.date_culte DESC;


-- Vue E2 : Retards par membre
CREATE OR REPLACE VIEW v_retards_membres AS
SELECT
  m.id                                                            AS membre_id,
  m.nom,
  m.prenom,
  m.date_adhesion,
  COUNT(DISTINCT c.id)                                            AS cultes_eligibles,
  COUNT(DISTINCT co.id) FILTER (WHERE co.statut IN ('paye','en_avance'))
                                                                  AS cultes_payes,
  COUNT(DISTINCT co.id) FILTER (WHERE co.statut = 'absent')      AS cultes_absents,
  (
    COUNT(DISTINCT c.id)
    - COUNT(DISTINCT co.id) FILTER (WHERE co.statut IN ('paye','en_avance'))
  )                                                               AS cultes_en_retard,
  (
    COUNT(DISTINCT c.id)
    - COUNT(DISTINCT co.id) FILTER (WHERE co.statut IN ('paye','en_avance'))
  ) * 50                                                          AS montant_du_fcfa
FROM membres m
JOIN cultes c ON c.date_culte >= m.date_adhesion
             AND c.date_culte <= CURRENT_DATE
LEFT JOIN cotisations co ON co.membre_id = m.id
                        AND co.culte_id = c.id
WHERE m.is_active = TRUE
GROUP BY m.id, m.nom, m.prenom, m.date_adhesion
HAVING (
  COUNT(DISTINCT c.id)
  - COUNT(DISTINCT co.id) FILTER (WHERE co.statut IN ('paye','en_avance'))
) > 0
ORDER BY montant_du_fcfa DESC;


-- Vue E3 : Membres à jour
CREATE OR REPLACE VIEW v_membres_a_jour AS
SELECT
  m.id,
  m.nom,
  m.prenom,
  m.date_adhesion,
  COUNT(DISTINCT c.id)                                              AS cultes_eligibles,
  COUNT(DISTINCT co.id) FILTER (WHERE co.statut IN ('paye','en_avance'))
                                                                    AS cultes_payes
FROM membres m
JOIN cultes c ON c.date_culte >= m.date_adhesion
             AND c.date_culte <= CURRENT_DATE
LEFT JOIN cotisations co ON co.membre_id = m.id
                        AND co.culte_id = c.id
WHERE m.is_active = TRUE
GROUP BY m.id, m.nom, m.prenom, m.date_adhesion
HAVING (
  COUNT(DISTINCT c.id)
  - COUNT(DISTINCT co.id) FILTER (WHERE co.statut IN ('paye','en_avance'))
) = 0
ORDER BY m.nom;


-- Vue E4 : Membres en avance
CREATE OR REPLACE VIEW v_membres_en_avance AS
SELECT
  m.id            AS membre_id,
  m.nom,
  m.prenom,
  COUNT(co.id)    AS paiements_anticipes,
  SUM(co.montant) AS montant_anticipe
FROM membres m
JOIN cotisations co ON co.membre_id = m.id
                   AND co.statut = 'en_avance'
JOIN cultes c ON c.id = co.culte_id
             AND c.date_culte > CURRENT_DATE
WHERE m.is_active = TRUE
GROUP BY m.id, m.nom, m.prenom
ORDER BY m.nom;


-- Vue E5 : Dashboard global
CREATE OR REPLACE VIEW v_dashboard AS
SELECT
  (SELECT COUNT(*) FROM membres WHERE is_active = TRUE)        AS total_membres_actifs,
  (SELECT COUNT(*) FROM cultes WHERE date_culte <= CURRENT_DATE) AS total_cultes,
  (SELECT COUNT(*) FROM v_retards_membres)                      AS membres_en_retard,
  (SELECT SUM(montant_du_fcfa) FROM v_retards_membres)          AS total_du_fcfa,
  (SELECT montant_collecte FROM v_resume_culte LIMIT 1)         AS dernier_culte_collecte,
  (SELECT date_culte FROM cultes ORDER BY date_culte DESC LIMIT 1) AS dernier_culte_date;


-- ============================================================
-- SECTION 6 : FONCTIONS SQL
-- ============================================================

-- Fonction F1 : Créer un culte avec génération auto des cotisations
CREATE OR REPLACE FUNCTION creer_culte_avec_cotisations(
  p_date_culte          DATE,
  p_titre               TEXT DEFAULT NULL,
  p_montant_cotisation  NUMERIC DEFAULT 50.00
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
  v_culte_id UUID;
BEGIN
  -- Créer le culte
  INSERT INTO cultes (date_culte, titre, montant_cotisation, created_by)
  VALUES (
    p_date_culte,
    COALESCE(p_titre, 'Culte du ' || TO_CHAR(p_date_culte, 'DD/MM/YYYY')),
    p_montant_cotisation,
    auth.uid()
  )
  ON CONFLICT (date_culte) DO NOTHING
  RETURNING id INTO v_culte_id;

  -- Si le culte existait déjà, récupérer son id
  IF v_culte_id IS NULL THEN
    SELECT id INTO v_culte_id FROM cultes WHERE date_culte = p_date_culte;
  END IF;

  -- Générer une cotisation 'non_paye' pour chaque membre actif
  INSERT INTO cotisations (membre_id, culte_id, statut, montant)
  SELECT
    m.id,
    v_culte_id,
    'non_paye',
    p_montant_cotisation
  FROM membres m
  WHERE m.is_active = TRUE
  ON CONFLICT (membre_id, culte_id) DO NOTHING;

  RETURN v_culte_id;
END;
$$;


-- Fonction F2 : Toggle paiement
CREATE OR REPLACE FUNCTION toggle_paiement(
  p_membre_id UUID,
  p_culte_id  UUID
)
RETURNS cotisations
LANGUAGE plpgsql
AS $$
DECLARE
  v_cotisation cotisations;
  v_culte_date DATE;
BEGIN
  SELECT date_culte INTO v_culte_date FROM cultes WHERE id = p_culte_id;

  UPDATE cotisations
  SET
    statut        = CASE
                      WHEN statut IN ('paye', 'en_avance') THEN 'non_paye'
                      ELSE
                        CASE
                          WHEN NOW()::DATE < v_culte_date THEN 'en_avance'
                          ELSE 'paye'
                        END
                    END,
    date_paiement = CASE
                      WHEN statut IN ('paye', 'en_avance') THEN NULL
                      ELSE NOW()
                    END,
    updated_at    = NOW()
  WHERE membre_id = p_membre_id
    AND culte_id  = p_culte_id
  RETURNING * INTO v_cotisation;

  RETURN v_cotisation;
END;
$$;


-- Fonction F3 : Marquer absent
CREATE OR REPLACE FUNCTION marquer_absent(
  p_membre_id UUID,
  p_culte_id  UUID
)
RETURNS cotisations
LANGUAGE plpgsql
AS $$
DECLARE
  v_cotisation cotisations;
BEGIN
  UPDATE cotisations
  SET
    statut        = 'absent',
    date_paiement = NULL,
    updated_at    = NOW()
  WHERE membre_id = p_membre_id
    AND culte_id  = p_culte_id
  RETURNING * INTO v_cotisation;

  RETURN v_cotisation;
END;
$$;


-- Fonction F4 : Historique membre
CREATE OR REPLACE FUNCTION historique_membre(p_membre_id UUID)
RETURNS TABLE (
  culte_date    DATE,
  culte_titre   TEXT,
  statut        statut_cotisation,
  montant       NUMERIC,
  date_paiement TIMESTAMPTZ
)
LANGUAGE sql
AS $$
  SELECT
    c.date_culte,
    COALESCE(c.titre, 'Culte du ' || TO_CHAR(c.date_culte, 'DD/MM/YYYY')),
    co.statut,
    co.montant,
    co.date_paiement
  FROM cultes c
  LEFT JOIN cotisations co ON co.culte_id = c.id
                          AND co.membre_id = p_membre_id
  JOIN membres m ON m.id = p_membre_id
  WHERE c.date_culte >= m.date_adhesion
  ORDER BY c.date_culte DESC;
$$;


-- ============================================================
-- SECTION 7 : TRIGGERS
-- ============================================================

-- Trigger set_updated_at
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_membres_updated_at ON membres;
CREATE TRIGGER trg_membres_updated_at
  BEFORE UPDATE ON membres
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_cultes_updated_at ON cultes;
CREATE TRIGGER trg_cultes_updated_at
  BEFORE UPDATE ON cultes
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_cotisations_updated_at ON cotisations;
CREATE TRIGGER trg_cotisations_updated_at
  BEFORE UPDATE ON cotisations
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- Trigger génération cotisations nouveau membre
CREATE OR REPLACE FUNCTION generer_cotisations_nouveau_membre()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO cotisations (membre_id, culte_id, statut, montant)
  SELECT
    NEW.id,
    c.id,
    'non_paye',
    c.montant_cotisation
  FROM cultes c
  WHERE c.date_culte >= NEW.date_adhesion
  ON CONFLICT (membre_id, culte_id) DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_nouveau_membre_cotisations ON membres;
CREATE TRIGGER trg_nouveau_membre_cotisations
  AFTER INSERT ON membres
  FOR EACH ROW EXECUTE FUNCTION generer_cotisations_nouveau_membre();


-- Trigger génération cotisations nouveau culte
CREATE OR REPLACE FUNCTION generer_cotisations_nouveau_culte()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO cotisations (membre_id, culte_id, statut, montant)
  SELECT
    m.id,
    NEW.id,
    'non_paye',
    NEW.montant_cotisation
  FROM membres m
  WHERE m.is_active = TRUE
    AND m.date_adhesion <= NEW.date_culte
  ON CONFLICT (membre_id, culte_id) DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_nouveau_culte_cotisations ON cultes;
CREATE TRIGGER trg_nouveau_culte_cotisations
  AFTER INSERT ON cultes
  FOR EACH ROW EXECUTE FUNCTION generer_cotisations_nouveau_culte();


-- ============================================================
-- SECTION 8 : ROW LEVEL SECURITY (RLS)
-- ============================================================

-- Activer RLS sur toutes les tables
ALTER TABLE membres     ENABLE ROW LEVEL SECURITY;
ALTER TABLE cultes      ENABLE ROW LEVEL SECURITY;
ALTER TABLE cotisations ENABLE ROW LEVEL SECURITY;

-- Supprimer les anciennes politiques
DROP POLICY IF EXISTS membres_select_policy     ON membres;
DROP POLICY IF EXISTS membres_insert_policy     ON membres;
DROP POLICY IF EXISTS membres_update_policy     ON membres;
DROP POLICY IF EXISTS membres_delete_policy     ON membres;

DROP POLICY IF EXISTS cultes_select_policy      ON cultes;
DROP POLICY IF EXISTS cultes_insert_policy      ON cultes;
DROP POLICY IF EXISTS cultes_update_policy      ON cultes;

DROP POLICY IF EXISTS cotisations_select_policy ON cotisations;
DROP POLICY IF EXISTS cotisations_update_policy ON cotisations;

-- Créer les nouvelles politiques
CREATE POLICY membres_select_policy ON membres
  FOR SELECT TO authenticated USING (true);

CREATE POLICY membres_insert_policy ON membres
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY membres_update_policy ON membres
  FOR UPDATE TO authenticated USING (true);

CREATE POLICY membres_delete_policy ON membres
  FOR DELETE TO authenticated USING (true);

CREATE POLICY cultes_select_policy ON cultes
  FOR SELECT TO authenticated USING (true);

CREATE POLICY cultes_insert_policy ON cultes
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY cultes_update_policy ON cultes
  FOR UPDATE TO authenticated USING (auth.uid() = created_by OR created_by IS NULL);

CREATE POLICY cotisations_select_policy ON cotisations
  FOR SELECT TO authenticated USING (true);

CREATE POLICY cotisations_update_policy ON cotisations
  FOR UPDATE TO authenticated USING (true);


-- ============================================================
-- SECTION 9 : VÉRIFICATION
-- ============================================================

-- Vérifier les tables
SELECT 'Tables créées :' as info;
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' AND table_name IN ('membres', 'cultes', 'cotisations');

-- Vérifier les vues
SELECT 'Vues créées :' as info;
SELECT viewname as nom FROM pg_views
WHERE schemaname = 'public' AND viewname LIKE 'v_%';

-- Vérifier les fonctions
SELECT 'Fonctions créées :' as info;
SELECT routine_name as nom FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'creer_culte_avec_cotisations', 'toggle_paiement',
    'marquer_absent', 'historique_membre',
    'set_updated_at', 'generer_cotisations_nouveau_membre',
    'generer_cotisations_nouveau_culte'
  );

-- Vérifier les triggers
SELECT 'Triggers créés :' as info;
SELECT trigger_name as nom, event_object_table as table_cible
FROM information_schema.triggers WHERE trigger_schema = 'public';

-- Vérifier RLS
SELECT 'RLS activé :' as info;
SELECT tablename, rowsecurity FROM pg_tables
WHERE schemaname = 'public' AND tablename IN ('membres', 'cultes', 'cotisations');

-- Compter les données
SELECT 'Données actuelles :' as info;
SELECT 'membres' as table_nom, COUNT(*) as nb_lignes FROM membres
UNION ALL SELECT 'cultes', COUNT(*) FROM cultes
UNION ALL SELECT 'cotisations', COUNT(*) FROM cotisations;

-- Test dashboard
SELECT 'Test Dashboard :' as info;
SELECT * FROM v_dashboard;
