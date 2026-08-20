-- Migration du schéma InsForge pour Kased App
-- Ce script ajoute les colonnes manquantes pour correspondre au modèle Flutter

-- ── Table membres ────────────────────────────────────────────────────────────
ALTER TABLE membres ADD COLUMN IF NOT EXISTS montant_en_avance DOUBLE PRECISION NOT NULL DEFAULT 0;
ALTER TABLE membres ADD COLUMN IF NOT EXISTS total_dons DOUBLE PRECISION NOT NULL DEFAULT 0;
ALTER TABLE membres ADD COLUMN IF NOT EXISTS version INTEGER NOT NULL DEFAULT 1;
ALTER TABLE membres ADD COLUMN IF NOT EXISTS device_id TEXT;
ALTER TABLE membres ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE membres ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE membres ADD COLUMN IF NOT EXISTS deleted_by TEXT;

-- Index pour la suppression soft
CREATE INDEX IF NOT EXISTS idx_membres_is_deleted ON membres(is_deleted);
CREATE INDEX IF NOT EXISTS idx_membres_user_id ON membres(user_id);

-- ── Table cultes ──────────────────────────────────────────────────────────────
ALTER TABLE cultes ADD COLUMN IF NOT EXISTS note TEXT;
ALTER TABLE cultes ADD COLUMN IF NOT EXISTS version INTEGER NOT NULL DEFAULT 1;
ALTER TABLE cultes ADD COLUMN IF NOT EXISTS device_id TEXT;
ALTER TABLE cultes ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE cultes ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE cultes ADD COLUMN IF NOT EXISTS deleted_by TEXT;
ALTER TABLE cultes ADD COLUMN IF NOT EXISTS member_ids TEXT[];

-- Index pour la suppression soft
CREATE INDEX IF NOT EXISTS idx_cultes_is_deleted ON cultes(is_deleted);
CREATE INDEX IF NOT EXISTS idx_cultes_user_id ON cultes(user_id);

-- ── Table cotisations ────────────────────────────────────────────────────────
-- Le champ 'montant' existe déjà (c'est le montant payé)
ALTER TABLE cotisations ADD COLUMN IF NOT EXISTS version INTEGER NOT NULL DEFAULT 1;
ALTER TABLE cotisations ADD COLUMN IF NOT EXISTS device_id TEXT;
ALTER TABLE cotisations ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE cotisations ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE cotisations ADD COLUMN IF NOT EXISTS deleted_by TEXT;

-- Index pour la suppression soft
CREATE INDEX IF NOT EXISTS idx_cotisations_is_deleted ON cotisations(is_deleted);
CREATE INDEX IF NOT EXISTS idx_cotisations_user_id ON cotisations(user_id);
CREATE INDEX IF NOT EXISTS idx_cotisations_culte_id ON cotisations(culte_id);
CREATE INDEX IF NOT EXISTS idx_cotisations_membre_id ON cotisations(membre_id);

-- ── Vue v_dashboard (si elle n'existe pas) ───────────────────────────────────
CREATE OR REPLACE VIEW v_dashboard AS
SELECT
  COUNT(DISTINCT m.id) AS total_membres,
  COUNT(DISTINCT c.id) AS total_cultes,
  COALESCE(SUM(CASE WHEN c.statut = 'paye' THEN c.montant_paye ELSE 0 END), 0) AS total_collecte,
  COUNT(DISTINCT CASE WHEN c.statut = 'non_paye' THEN c.id END) AS membres_en_retard,
  COALESCE(SUM(CASE WHEN c.statut = 'non_paye' THEN c.montant_obligatoire ELSE 0 END), 0) AS total_du,
  COUNT(DISTINCT CASE WHEN c.statut = 'en_avance' THEN c.id END) AS membres_en_avance,
  COALESCE(SUM(CASE WHEN c.statut = 'en_avance' THEN c.montant_paye ELSE 0 END), 0) AS montant_en_avance
FROM membres m
LEFT JOIN cotisations c ON c.membre_id = m.id AND c.is_deleted = false
WHERE m.is_deleted = false;

-- ── Vue v_resume_culte ───────────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_resume_culte AS
SELECT
  c.id,
  c.titre,
  c.date_culte,
  c.montant_cotisation,
  COUNT(cm.id) AS total_membres,
  COUNT(CASE WHEN cc.statut = 'paye' THEN 1 END) AS nb_paye,
  COUNT(CASE WHEN cc.statut = 'non_paye' THEN 1 END) AS nb_non_paye,
  COUNT(CASE WHEN cc.statut = 'en_avance' THEN 1 END) AS nb_en_avance,
  COUNT(CASE WHEN cc.statut = 'absent' THEN 1 END) AS nb_absent,
  COALESCE(SUM(cc.montant_paye), 0) AS total_collecte
FROM cultes c
LEFT JOIN membres cm ON cm.is_deleted = false
LEFT JOIN cotisations cc ON cc.culte_id = c.id AND cc.is_deleted = false
WHERE c.is_deleted = false
GROUP BY c.id, c.titre, c.date_culte, c.montant_cotisation
ORDER BY c.date_culte DESC;

-- ── Vue v_retards_membres ────────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_retards_membres AS
SELECT
  m.id,
  m.nom,
  m.prenom,
  COUNT(c.id) AS nb_retards,
  COALESCE(SUM(c.montant_obligatoire - c.montant_paye), 0) AS montant_du
FROM membres m
JOIN cultes c ON c.is_deleted = false
JOIN cotisations co ON co.culte_id = c.id AND co.membre_id = m.id AND co.statut = 'non_paye' AND co.is_deleted = false
WHERE m.is_deleted = false
GROUP BY m.id, m.nom, m.prenom
ORDER BY montant_du DESC;

-- ── Vue v_membres_a_jour ─────────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_membres_a_jour AS
SELECT
  m.id,
  m.nom,
  m.prenom,
  m.montant_en_avance,
  COUNT(c.id) AS nb_cultes_payes
FROM membres m
LEFT JOIN cotisations c ON c.membre_id = m.id AND c.statut = 'paye' AND c.is_deleted = false
LEFT JOIN cultes cu ON cu.id = c.culte_id AND cu.is_deleted = false
WHERE m.is_deleted = false
GROUP BY m.id, m.nom, m.prenom, m.montant_en_avance
ORDER BY m.nom ASC;

-- ── Vue v_membres_en_avance ──────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_membres_en_avance AS
SELECT
  m.id,
  m.nom,
  m.prenom,
  m.montant_en_avance
FROM membres m
WHERE m.is_deleted = false AND m.montant_en_avance > 0
ORDER BY m.montant_en_avance DESC;

-- ── RPC toggle_paiement ──────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION toggle_paiement(p_membre_id UUID, p_culte_id UUID)
RETURNS JSON AS $$
DECLARE
  cotisation RECORD;
  culte RECORD;
BEGIN
  SELECT * FROM cultes WHERE id = p_culte_id AND is_deleted = false LIMIT 1 INTO culte;
  IF NOT FOUND THEN
    RETURN json_build_object('error', 'Culte non trouvé');
  END IF;

  SELECT * FROM cotisations
  WHERE membre_id = p_membre_id AND culte_id = p_culte_id AND is_deleted = false
  LIMIT 1 INTO cotisation;

  IF FOUND THEN
    UPDATE cotisations SET
      statut = CASE WHEN statut = 'paye' THEN 'non_paye' ELSE 'paye' END,
      montant_paye = CASE WHEN statut = 'paye' THEN 0 ELSE culte.montant_cotisation END,
      updated_at = NOW()
    WHERE id = cotisation.id;
    RETURN to_json(cotisation);
  ELSE
    RETURN json_build_object('error', 'Cotisation non trouvée');
  END IF;
END;
$$ LANGUAGE plpgsql;

-- ── RPC creer_culte_avec_cotisations ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION creer_culte_avec_cotisations(
  p_date_culte DATE,
  p_titre TEXT DEFAULT NULL,
  p_montant_cotisation DOUBLE PRECISION DEFAULT 50.0
) RETURNS UUID AS $$
DECLARE
  new_culte_id UUID;
  new_culte RECORD;
  membre RECORD;
  new_cotisation RECORD;
BEGIN
  -- Créer le culte
  INSERT INTO cultes (id, titre, date_culte, montant_cotisation, user_id, created_at, updated_at, is_deleted)
  VALUES (gen_random_uuid(), p_titre, p_date_culte, p_montant_cotisation,
          (SELECT user_id FROM membres WHERE id = p_membre_id LIMIT 1),
          NOW(), NOW(), false)
  RETURNING * INTO new_culte;

  new_culte_id := new_culte.id;

  -- Créer une cotisation pour chaque membre actif
  FOR membre IN SELECT id FROM membres WHERE is_deleted = false LOOP
    INSERT INTO cotisations (
      id, membre_id, culte_id, statut, montant_obligatoire, montant_paye, montant_don,
      created_at, updated_at, is_deleted
    ) VALUES (
      gen_random_uuid(), membre.id, new_culte_id, 'non_paye', p_montant_cotisation, 0, 0,
      NOW(), NOW(), false
    ) RETURNING * INTO new_cotisation;
  END LOOP;

  RETURN new_culte_id;
END;
$$ LANGUAGE plpgsql;

-- ── RPC marquer_absent ───────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION marquer_absent(p_membre_id UUID, p_culte_id UUID)
RETURNS JSON AS $$
DECLARE
  cotisation RECORD;
BEGIN
  SELECT * FROM cotisations
  WHERE membre_id = p_membre_id AND culte_id = p_culte_id AND is_deleted = false
  LIMIT 1 INTO cotisation;

  IF FOUND THEN
    UPDATE cotisations SET
      statut = 'absent',
      montant_paye = 0,
      updated_at = NOW()
    WHERE id = cotisation.id;
    RETURN to_json(cotisation);
  ELSE
    RETURN json_build_object('error', 'Cotisation non trouvée');
  END IF;
END;
$$ LANGUAGE plpgsql;

-- ── RPC consommer_avance_membre ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION consommer_avance_membre(p_membre_id UUID, p_montant DOUBLE PRECISION)
RETURNS JSON AS $$
DECLARE
  membre RECORD;
BEGIN
  SELECT * FROM membres WHERE id = p_membre_id AND is_deleted = false LIMIT 1 INTO membre;

  IF FOUND THEN
    IF membre.montant_en_avance >= p_montant THEN
      UPDATE membres SET
        montant_en_avance = montant_en_avance - p_montant,
        updated_at = NOW()
      WHERE id = p_membre_id;
      RETURN json_build_object('success', true, 'nouveau_solde', membre.montant_en_avance - p_montant);
    ELSE
      RETURN json_build_object('error', 'Montant en avance insuffisant');
    END IF;
  ELSE
    RETURN json_build_object('error', 'Membre non trouvé');
  END IF;
END;
$$ LANGUAGE plpgsql;

-- ── RPC consigner_paiement_en_avance ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION consigner_paiement_en_avance(
  p_membre_id UUID,
  p_culte_ids UUID[],
  p_montant_total DOUBLE PRECISION
) RETURNS JSON AS $$
DECLARE
  membre RECORD;
  culte RECORD;
  cotisation RECORD;
  montant_par_culte DOUBLE PRECISION;
BEGIN
  SELECT * FROM membres WHERE id = p_membre_id AND is_deleted = false LIMIT 1 INTO membre;
  IF NOT FOUND THEN
    RETURN json_build_object('error', 'Membre non trouvé');
  END IF;

  montant_par_culte := p_montant_total / array_length(p_culte_ids, 1);

  -- Créditer le membre
  UPDATE membres SET
    montant_en_avance = montant_en_avance + p_montant_total,
    updated_at = NOW()
  WHERE id = p_membre_id;

  -- Créer les cotisations en avance
  FOREACH culte IN ARRAY p_culte_ids LOOP
    SELECT * FROM cultes WHERE id = culte AND is_deleted = false LIMIT 1 INTO culte;
    IF FOUND THEN
      INSERT INTO cotisations (
        id, membre_id, culte_id, statut, montant_obligatoire, montant_paye, montant_don,
        created_at, updated_at, is_deleted
      ) VALUES (
        gen_random_uuid(), p_membre_id, culte.id, 'en_avance', culte.montant_cotisation,
        montant_par_culte, 0, NOW(), NOW(), false
      );
    END IF;
  END LOOP;

  RETURN json_build_object('success', true, 'montant_credite', p_montant_total);
END;
$$ LANGUAGE plpgsql;

-- ── RPC historique_membre ────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION historique_membre(p_membre_id UUID)
RETURNS JSON AS $$
BEGIN
  RETURN (
    SELECT json_agg(row_to_json(t))
    FROM (
      SELECT
        'cotisation' AS type,
        c.id,
        c.statut,
        c.montant_paye,
        c.montant_obligatoire,
        c.montant_don,
        c.date_paiement,
        cu.titre AS culte_titre,
        cu.date_culte,
        c.created_at
      FROM cotisations c
      JOIN cultes cu ON cu.id = c.culte_id
      WHERE c.membre_id = p_membre_id AND c.is_deleted = false
      UNION ALL
      SELECT
        'membre' AS type,
        m.id,
        NULL AS statut,
        m.montant_en_avance AS montant_paye,
        NULL AS montant_obligatoire,
        m.total_dons AS montant_don,
        NULL AS date_paiement,
        NULL AS culte_titre,
        m.date_adhesion AS date_culte,
        m.created_at
      FROM membres m
      WHERE m.id = p_membre_id AND m.is_deleted = false
      LIMIT 1
    ) t
    ORDER BY t.created_at DESC
  );
END;
$$ LANGUAGE plpgsql;

-- ── Trigger pour user_id automatique ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION set_user_id()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.user_id IS NULL THEN
    NEW.user_id := current_setting('request.jwt.claims', true)::json->>'sub';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_set_user_id_membres ON membres;
CREATE TRIGGER trigger_set_user_id_membres
  BEFORE INSERT ON membres
  FOR EACH ROW EXECUTE FUNCTION set_user_id();

DROP TRIGGER IF EXISTS trigger_set_user_id_cultes ON cultes;
CREATE TRIGGER trigger_set_user_id_cultes
  BEFORE INSERT ON cultes
  FOR EACH ROW EXECUTE FUNCTION set_user_id();

DROP TRIGGER IF EXISTS trigger_set_user_id_cotisations ON cotisations;
CREATE TRIGGER trigger_set_user_id_cotisations
  BEFORE INSERT ON cotisations
  FOR EACH ROW EXECUTE FUNCTION set_user_id();
