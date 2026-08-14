-- Alignement backend ↔ base de données Kased
--
-- Contexte : les tables métier étaient protégées par des politiques RLS
-- « propriétaire » (auth.uid() = user_id) alors que l'application est une
-- application d'église partagée : chaque utilisateur ne voyait que les
-- lignes qu'il avait lui-même créées, tandis que les vues (v_dashboard,
-- v_retards_membres…) agrégeaient les lignes de TOUS les utilisateurs.
-- Résultat : dashboard non nul mais listes vides, cultes invisibles,
-- conflits sur cultes.date_culte (contrainte unique globale) impossibles à
-- diagnostiquer côté client.
--
-- Cette migration aligne le modèle sur l'usage réel : données partagées
-- entre tous les utilisateurs authentifiés, `user_id` conservé comme trace
-- d'audit (auteur de la ligne).

BEGIN;

-- ── 1. Lignes historiques orphelines ────────────────────────────────────────
-- Les lignes créées avant l'activation de RLS ont user_id NULL : elles
-- étaient invisibles pour tout le monde. On les rattache au premier compte
-- disponible pour conserver une trace d'auteur cohérente.
UPDATE cultes      SET user_id = COALESCE(created_by, (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)) WHERE user_id IS NULL;
UPDATE membres     SET user_id = (SELECT id FROM auth.users ORDER BY created_at LIMIT 1) WHERE user_id IS NULL;
UPDATE cotisations SET user_id = (SELECT id FROM auth.users ORDER BY created_at LIMIT 1) WHERE user_id IS NULL;
UPDATE profiles    SET user_id = id WHERE user_id IS NULL;

-- ── 2. RLS partagée entre utilisateurs authentifiés ─────────────────────────
DROP POLICY IF EXISTS membres_all_policy     ON membres;
DROP POLICY IF EXISTS cultes_all_policy      ON cultes;
DROP POLICY IF EXISTS cotisations_all_policy ON cotisations;

CREATE POLICY membres_shared_policy ON membres
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY cultes_shared_policy ON cultes
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY cotisations_shared_policy ON cotisations
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ── 3. Profils : lecture partagée, écriture limitée à soi-même ──────────────
-- La lecture de tous les profils est nécessaire pour cibler les autres
-- utilisateurs lors d'un envoi de notification push.
DROP POLICY IF EXISTS profiles_self_read_policy ON profiles;
DROP POLICY IF EXISTS profiles_insert_policy    ON profiles;

CREATE POLICY profiles_read_policy ON profiles
  FOR SELECT TO authenticated USING (true);

CREATE POLICY profiles_insert_policy ON profiles
  FOR INSERT TO authenticated
  WITH CHECK (( SELECT auth.uid()) IN (user_id, id));

CREATE POLICY profiles_update_policy ON profiles
  FOR UPDATE TO authenticated
  USING (( SELECT auth.uid()) IN (user_id, id))
  WITH CHECK (( SELECT auth.uid()) IN (user_id, id));

-- Le bridge Google insère { id, email } : user_id doit être rempli
-- automatiquement, sinon l'insertion viole la politique d'écriture.
DROP TRIGGER IF EXISTS trg_set_user_id_profiles ON profiles;
CREATE TRIGGER trg_set_user_id_profiles
  BEFORE INSERT ON profiles
  FOR EACH ROW EXECUTE FUNCTION set_user_id_on_insert();

-- ── 3b. Création automatique du profil à l'inscription ──────────────────────
-- Aucun profil n'existait pour les 9 comptes déjà inscrits : l'inscription
-- e-mail ne crée pas de profil et l'upsert du bridge Google était rejeté par
-- l'ancienne politique d'écriture. Sans profils, impossible de lister les
-- utilisateurs à notifier.
CREATE OR REPLACE FUNCTION public.creer_profil_nouvel_utilisateur()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, user_id, email)
  VALUES (NEW.id, NEW.id, NEW.email)
  ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_creer_profil_nouvel_utilisateur ON auth.users;
CREATE TRIGGER trg_creer_profil_nouvel_utilisateur
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.creer_profil_nouvel_utilisateur();

INSERT INTO public.profiles (id, user_id, email)
SELECT u.id, u.id, u.email FROM auth.users u
ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email;

-- ── 4. Vues alignées sur RLS ────────────────────────────────────────────────
-- Sans security_invoker, les vues s'exécutaient avec les droits de leur
-- propriétaire et contournaient RLS : c'est l'origine de l'incohérence
-- « dashboard rempli / listes vides ».
ALTER VIEW v_dashboard        SET (security_invoker = true);
ALTER VIEW v_resume_culte     SET (security_invoker = true);
ALTER VIEW v_retards_membres  SET (security_invoker = true);
ALTER VIEW v_membres_a_jour   SET (security_invoker = true);
ALTER VIEW v_membres_en_avance SET (security_invoker = true);

-- ── 5. Doublons de schéma sur membres ───────────────────────────────────────
-- idx_membres_is_actif et idx_membres_is_active sont identiques ; les deux
-- triggers updated_at appliquent la même écriture deux fois par UPDATE.
DROP INDEX IF EXISTS idx_membres_is_actif;
DROP TRIGGER IF EXISTS trg_membres_set_updated_at ON membres;

COMMIT;
