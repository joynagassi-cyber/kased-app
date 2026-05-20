-- ============================================================
-- KASED-APP — SCRIPTS SQL COMPLETS
-- Base : Supabase (PostgreSQL)
-- Auteur : généré pour Ok · kased-app
-- ============================================================
-- ORDRE D'EXÉCUTION :
--   1. SECTION A : Corriger la table membres (DROP colonnes Google)
--   2. SECTION B : Corriger/créer la table cultes
--   3. SECTION C : Créer la table cotisations (remplace paiement)
--   4. SECTION D : Type ENUM statut
--   5. SECTION E : Vues calculées (retards, résumés)
--   6. SECTION F : Fonctions utilitaires
--   7. SECTION G : RLS (Row Level Security)
--   8. SECTION H : Triggers automatiques
-- ============================================================


-- ============================================================
-- SECTION A — CORRECTION TABLE MEMBRES
-- Problème : table couplée à Google Auth (google_id, photo_url, etc.)
-- Solution : table autonome gérée manuellement par le secrétaire
-- ============================================================

-- Étape A1 : Supprimer les colonnes liées à Google Auth
-- (adapter les noms exacts selon ta table actuelle)
ALTER TABLE membres
  DROP COLUMN IF EXISTS google_id,
  DROP COLUMN IF EXISTS photo_url,
  DROP COLUMN IF EXISTS email,
  DROP COLUMN IF EXISTS provider_id,
  DROP COLUMN IF EXISTS auth_user_id;

-- Étape A2 : Ajouter les colonnes manquantes pour la gestion manuelle
ALTER TABLE membres
  ADD COLUMN IF NOT EXISTS nom          TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS prenom       TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS telephone    TEXT,
  ADD COLUMN IF NOT EXISTS date_adhesion DATE NOT NULL DEFAULT CURRENT_DATE,
  ADD COLUMN IF NOT EXISTS is_active    BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS notes        TEXT,
  ADD COLUMN IF NOT EXISTS created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- Étape A3 : Contrainte unicité sur nom complet (évite les doublons)
ALTER TABLE membres
  DROP CONSTRAINT IF EXISTS membres_nom_prenom_unique;
ALTER TABLE membres
  ADD CONSTRAINT membres_nom_prenom_unique UNIQUE (nom, prenom);

-- Étape A4 : Index pour les requêtes fréquentes
CREATE INDEX IF NOT EXISTS idx_membres_is_active      ON membres (is_active);
CREATE INDEX IF NOT EXISTS idx_membres_date_adhesion  ON membres (date_adhesion);
CREATE INDEX IF NOT EXISTS idx_membres_nom            ON membres (nom, prenom);

-- Étape A5 : Contrainte CHECK sur date_adhesion (ne peut pas être dans le futur)
ALTER TABLE membres
  DROP CONSTRAINT IF EXISTS membres_date_adhesion_check;
ALTER TABLE membres
  ADD CONSTRAINT membres_date_adhesion_check
    CHECK (date_adhesion <= CURRENT_DATE);

-- Vérification : structure finale attendue
-- id | nom | prenom | telephone | date_adhesion | is_active | notes | created_at | updated_at


-- ============================================================
-- SECTION B — TABLE CULTES (SÉANCES DU DIMANCHE)
-- ============================================================

CREATE TABLE IF NOT EXISTS cultes (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date_culte          DATE NOT NULL,
  titre               TEXT,                          -- ex: "Culte du 23 mars 2025"
  notes               TEXT,
  montant_cotisation  NUMERIC(10, 2) NOT NULL DEFAULT 50.00,  -- FCFA, modifiable
  created_by          UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Un seul culte par date (pas de doublon pour le même dimanche)
  CONSTRAINT cultes_date_unique UNIQUE (date_culte),

  -- Sécurité : date ne peut pas être dans le futur (optionnel, à commenter si besoin)
  -- CONSTRAINT cultes_date_check CHECK (date_culte <= CURRENT_DATE + INTERVAL '7 days')
);

-- Index
CREATE INDEX IF NOT EXISTS idx_cultes_date_culte  ON cultes (date_culte DESC);
CREATE INDEX IF NOT EXISTS idx_cultes_created_by  ON cultes (created_by);

-- Titre auto-généré si non fourni (trigger ci-dessous)


-- ============================================================
-- SECTION C — TYPE ENUM STATUT COTISATION
-- ============================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'statut_cotisation') THEN
    CREATE TYPE statut_cotisation AS ENUM (
      'non_paye',   -- Culte passé, pas encore payé (état par défaut)
      'paye',       -- Payé (le jour même ou en rattrapage)
      'absent',     -- Membre absent ce dimanche (noté explicitement)
      'en_avance'   -- Payé AVANT la date du culte (paiement anticipé)
    );
  END IF;
END$$;


-- ============================================================
-- SECTION D — TABLE COTISATIONS
-- (remplace ou complète la table paiement existante)
-- Principe : 1 ligne par membre × par culte
-- ============================================================

CREATE TABLE IF NOT EXISTS cotisations (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  membre_id       UUID NOT NULL REFERENCES membres(id) ON DELETE CASCADE,
  culte_id        UUID NOT NULL REFERENCES cultes(id)  ON DELETE CASCADE,
  statut          statut_cotisation NOT NULL DEFAULT 'non_paye',
  montant         NUMERIC(10, 2) NOT NULL DEFAULT 50.00,
  date_paiement   TIMESTAMPTZ,         -- NULL si pas encore payé
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Un membre ne peut avoir qu'une seule cotisation par culte
  CONSTRAINT cotisations_membre_culte_unique UNIQUE (membre_id, culte_id),

  -- Cohérence : si statut = 'paye' ou 'en_avance', date_paiement doit être renseignée
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

-- Index composite pour les requêtes de retard (très fréquentes)
CREATE INDEX IF NOT EXISTS idx_cotisations_membre_statut ON cotisations (membre_id, statut);


-- ============================================================
-- SECTION E — VUES CALCULÉES
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- Vue E1 : Résumé par culte
-- → Pour chaque dimanche : combien ont payé, combien manquent, total collecté
-- ────────────────────────────────────────────────────────────
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


-- ────────────────────────────────────────────────────────────
-- Vue E2 : Retards par membre
-- → Pour chaque membre actif : combien de dimanches manqués × 50F
-- Logique :
--   cultes_eligibles = tous les cultes depuis date_adhesion du membre
--   payes            = cotisations avec statut IN ('paye','en_avance')
--   retard           = cultes_eligibles - payes
--   montant_du       = retard × montant moyen de cotisation
-- ────────────────────────────────────────────────────────────
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


-- ────────────────────────────────────────────────────────────
-- Vue E3 : Membres à jour (aucun retard)
-- ────────────────────────────────────────────────────────────
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


-- ────────────────────────────────────────────────────────────
-- Vue E4 : Membres en avance sur les paiements
-- Un membre est "en avance" s'il a payé pour des cultes futurs
-- ────────────────────────────────────────────────────────────
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


-- ────────────────────────────────────────────────────────────
-- Vue E5 : Tableau de bord global (1 ligne = stats générales)
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_dashboard AS
SELECT
  (SELECT COUNT(*) FROM membres WHERE is_active = TRUE)        AS total_membres_actifs,
  (SELECT COUNT(*) FROM cultes WHERE date_culte <= CURRENT_DATE) AS total_cultes,
  (SELECT COUNT(*) FROM v_retards_membres)                      AS membres_en_retard,
  (SELECT SUM(montant_du_fcfa) FROM v_retards_membres)          AS total_du_fcfa,
  (SELECT montant_collecte FROM v_resume_culte LIMIT 1)         AS dernier_culte_collecte,
  (SELECT date_culte FROM cultes ORDER BY date_culte DESC LIMIT 1) AS dernier_culte_date;


-- ============================================================
-- SECTION F — FONCTIONS UTILITAIRES
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- Fonction F1 : Créer un culte et générer automatiquement
-- une cotisation 'non_paye' pour chaque membre actif
-- ────────────────────────────────────────────────────────────
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
  -- qui n'en a pas encore pour ce culte
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


-- ────────────────────────────────────────────────────────────
-- Fonction F2 : Marquer/démarquer un paiement (toggle)
-- → Appelée quand le secrétaire tape sur "Payer 50F"
-- ────────────────────────────────────────────────────────────
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


-- ────────────────────────────────────────────────────────────
-- Fonction F3 : Marquer un membre comme absent pour un culte
-- ────────────────────────────────────────────────────────────
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


-- ────────────────────────────────────────────────────────────
-- Fonction F4 : Historique complet d'un membre
-- → Pour afficher la fiche d'un membre avec tous ses paiements
-- ────────────────────────────────────────────────────────────
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
-- SECTION G — TRIGGERS AUTOMATIQUES
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- Trigger G1 : updated_at automatique sur membres
-- ────────────────────────────────────────────────────────────
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


-- ────────────────────────────────────────────────────────────
-- Trigger G2 : Quand un nouveau membre est ajouté,
-- générer ses cotisations 'non_paye' pour tous les cultes
-- passés depuis sa date d'adhésion (rattrapage historique)
-- ────────────────────────────────────────────────────────────
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


-- ────────────────────────────────────────────────────────────
-- Trigger G3 : Quand un nouveau culte est créé,
-- générer automatiquement les cotisations pour tous les membres actifs
-- (sécurité si on insère un culte sans passer par la fonction F1)
-- ────────────────────────────────────────────────────────────
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
-- SECTION H — ROW LEVEL SECURITY (RLS)
-- Le secrétaire est authentifié via Google Auth (auth.users)
-- Les membres sont des données de l'église, pas des comptes
-- ============================================================

-- Activer RLS sur toutes les tables
ALTER TABLE membres     ENABLE ROW LEVEL SECURITY;
ALTER TABLE cultes      ENABLE ROW LEVEL SECURITY;
ALTER TABLE cotisations ENABLE ROW LEVEL SECURITY;

-- Supprimer les anciennes politiques si elles existent
DROP POLICY IF EXISTS membres_select_policy     ON membres;
DROP POLICY IF EXISTS membres_insert_policy     ON membres;
DROP POLICY IF EXISTS membres_update_policy     ON membres;
DROP POLICY IF EXISTS membres_delete_policy     ON membres;

DROP POLICY IF EXISTS cultes_select_policy      ON cultes;
DROP POLICY IF EXISTS cultes_insert_policy      ON cultes;
DROP POLICY IF EXISTS cultes_update_policy      ON cultes;

DROP POLICY IF EXISTS cotisations_select_policy ON cotisations;
DROP POLICY IF EXISTS cotisations_update_policy ON cotisations;

-- Politique : seul un utilisateur authentifié (le secrétaire) peut tout faire
-- (si l'app est monoposte, c'est suffisant)

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
-- SECTION I — DONNÉES DE TEST (optionnel, commenter en prod)
-- ============================================================

/*
-- Insérer des membres de test
INSERT INTO membres (nom, prenom, telephone, date_adhesion) VALUES
  ('Koffi',    'Marie',       '+229 97 00 00 01', '2025-01-05'),
  ('Ahounou',  'Paul',        '+229 97 00 00 02', '2025-01-05'),
  ('Agbo',     'Bernadette',  '+229 97 00 00 03', '2025-01-12'),
  ('Dossou',   'Samuel',      '+229 97 00 00 04', '2025-02-02'),
  ('Hounsou',  'Cécile',      '+229 97 00 00 05', '2025-01-05'),
  ('Mensah',   'Jean',        '+229 97 00 00 06', '2024-12-01')
ON CONFLICT DO NOTHING;

-- Créer 3 cultes passés (les triggers généreront les cotisations auto)
SELECT creer_culte_avec_cotisations('2025-03-02');
SELECT creer_culte_avec_cotisations('2025-03-09');
SELECT creer_culte_avec_cotisations('2025-03-16');

-- Marquer quelques paiements
-- (récupérer les UUIDs depuis la DB ou utiliser une sous-requête)
UPDATE cotisations
SET statut = 'paye', date_paiement = NOW()
WHERE membre_id = (SELECT id FROM membres WHERE nom='Koffi' AND prenom='Marie')
  AND culte_id IN (SELECT id FROM cultes WHERE date_culte IN ('2025-03-02','2025-03-09'));

-- Vérifier les retards
SELECT * FROM v_retards_membres;
*/


-- ============================================================
-- SECTION J — REQUÊTES UTILES POUR L'APP (référence Flutter)
-- ============================================================

-- Q1 : Tous les membres actifs triés alphabétiquement
-- SELECT * FROM membres WHERE is_active = TRUE ORDER BY nom, prenom;

-- Q2 : Cotisations d'un culte avec infos membres (pour l'écran séance)
-- SELECT m.nom, m.prenom, co.statut, co.date_paiement
-- FROM cotisations co
-- JOIN membres m ON m.id = co.membre_id
-- WHERE co.culte_id = '<UUID_CULTE>'
-- ORDER BY m.nom, m.prenom;

-- Q3 : Tous les retards triés par montant dû
-- SELECT * FROM v_retards_membres;

-- Q4 : Dashboard
-- SELECT * FROM v_dashboard;

-- Q5 : Résumé du dernier culte
-- SELECT * FROM v_resume_culte LIMIT 1;

-- Q6 : Historique d'un membre
-- SELECT * FROM historique_membre('<UUID_MEMBRE>');

-- Q7 : Créer la séance du dimanche aujourd'hui
-- SELECT creer_culte_avec_cotisations(CURRENT_DATE);

-- Q8 : Toggle paiement (tap secrétaire)
-- SELECT toggle_paiement('<UUID_MEMBRE>', '<UUID_CULTE>');


-- ============================================================
-- FIN DU SCRIPT
-- ============================================================
