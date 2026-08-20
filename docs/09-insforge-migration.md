# Migration du schéma InsForge — Kased App

## Problème
Les tables InsForge (`membres`, `cultes`, `cotisations`) manquent de colonnes que le modèle Flutter attend.

**Colonnes manquantes sur `membres` :**
- `montant_en_avance` (DOUBLE PRECISION)
- `total_dons` (DOUBLE PRECISION)
- `version` (INTEGER)
- `device_id` (TEXT)
- `is_deleted` (BOOLEAN)
- `deleted_at` (TIMESTAMPTZ)
- `deleted_by` (TEXT)

**Colonnes manquantes sur `cultes` :**
- `note` (TEXT)
- `version` (INTEGER)
- `device_id` (TEXT)
- `is_deleted` (BOOLEAN)
- `deleted_at` (TIMESTAMPTZ)
- `deleted_by` (TEXT)
- `member_ids` (TEXT[])

**Colonnes manquantes sur `cotisations` :**
- `version` (INTEGER)
- `device_id` (TEXT)
- `is_deleted` (BOOLEAN)
- `deleted_at` (TIMESTAMPTZ)
- `deleted_by` (TEXT)

---

## Solution : Migrer via l'interface InsForge

### Étape 1 : Accéder à l'admin InsForge
1. Ouvrir `https://pu74z8pe.us-east.insforge.app`
2. Se connecter avec le compte admin (celui qui a créé le projet)
3. Aller dans **Database** → **SQL Editor** (ou **Raw SQL**)

### Étape 2 : Exécuter la migration
Copier-coller le contenu de `scripts/migrate-insforge-schema.sql` dans l'éditeur SQL et exécuter.

Le script contient :
- `ALTER TABLE` pour ajouter les colonnes manquantes
- `CREATE INDEX` pour les performances
- `CREATE VIEW` pour les vues calculées (`v_dashboard`, `v_resume_culte`, etc.)
- `CREATE FUNCTION` pour les RPC (`toggle_paiement`, `creer_culte_avec_cotisations`, etc.)
- Triggers pour `user_id` automatique

### Étape 3 : Vérifier
```sql
-- Vérifier les colonnes de membres
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'membres' 
ORDER BY ordinal_position;

-- Vérifier les colonnes de cultes
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'cultes' 
ORDER BY ordinal_position;

-- Vérifier les colonnes de cotisations
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'cotisations' 
ORDER BY ordinal_position;
```

### Étape 4 : Tester
1. Rebuild l'APK (le code est déjà compatible)
2. S'inscrire/connecter
3. Créer un membre
4. Vérifier que la donnée apparaît dans InsForge

---

## Alternative : Recréer les tables

Si la migration ALTER échoue, supprimer les tables et les recréer :

```sql
-- 1. Supprimer les tables existantes (DONNÉES PERDUES)
DROP TABLE IF EXISTS cotisations CASCADE;
DROP TABLE IF EXISTS cultes CASCADE;
DROP TABLE IF EXISTS membres CASCADE;

-- 2. Recréer avec le bon schéma
CREATE TABLE membres (
  id UUID PRIMARY KEY,
  nom TEXT NOT NULL,
  prenom TEXT NOT NULL,
  date_adhesion DATE NOT NULL,
  date_naissance DATE,
  montant_en_avance DOUBLE PRECISION NOT NULL DEFAULT 0,
  total_dons DOUBLE PRECISION NOT NULL DEFAULT 0,
  telephone TEXT,
  notes TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  version INTEGER NOT NULL DEFAULT 1,
  device_id TEXT,
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  deleted_at TIMESTAMPTZ,
  deleted_by TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  user_id UUID REFERENCES auth.users(id)
);

CREATE TABLE cultes (
  id UUID PRIMARY KEY,
  titre TEXT,
  date_culte DATE NOT NULL,
  montant_cotisation DOUBLE PRECISION NOT NULL DEFAULT 50,
  note TEXT,
  version INTEGER NOT NULL DEFAULT 1,
  device_id TEXT,
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  deleted_at TIMESTAMPTZ,
  deleted_by TEXT,
  member_ids TEXT[],
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  user_id UUID REFERENCES auth.users(id)
);

CREATE TABLE cotisations (
  id UUID PRIMARY KEY,
  membre_id UUID REFERENCES membres(id),
  culte_id UUID REFERENCES cultes(id),
  statut TEXT NOT NULL DEFAULT 'non_paye',
  montant_obligatoire DOUBLE PRECISION NOT NULL DEFAULT 50,
  montant_paye DOUBLE PRECISION NOT NULL DEFAULT 0,
  montant_don DOUBLE PRECISION NOT NULL DEFAULT 0,
  date_paiement TIMESTAMPTZ,
  notes TEXT,
  version INTEGER NOT NULL DEFAULT 1,
  device_id TEXT,
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  deleted_at TIMESTAMPTZ,
  deleted_by TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  user_id UUID REFERENCES auth.users(id)
);

-- Index
CREATE INDEX idx_membres_user_id ON membres(user_id);
CREATE INDEX idx_membres_is_deleted ON membres(is_deleted);
CREATE INDEX idx_cultes_user_id ON cultes(user_id);
CREATE INDEX idx_cultes_is_deleted ON cultes(is_deleted);
CREATE INDEX idx_cotisations_membre_id ON cotisations(membre_id);
CREATE INDEX idx_cotisations_culte_id ON cotisations(culte_id);
CREATE INDEX idx_cotisations_user_id ON cotisations(user_id);
CREATE INDEX idx_cotisations_is_deleted ON cotisations(is_deleted);

-- Contrainte unique
ALTER TABLE membres ADD CONSTRAINT membres_nom_prenom_unique UNIQUE (nom, prenom);
```

---

## Problèmes secondaires à vérifier

### 1. Refresh token — timer toutes les 5 min
Le code est déjà implémenté dans `auth_provider.dart`. Vérifier que le timer tourne :
- Ajouter `debugPrint('[AUTH] Refresh timer actif')` dans `_startRefreshTimer()`
- Vérifier les logs Flutter : `[AUTH] Refresh proactif du token (grace period)`

### 2. Google Sign-In — page de consentement
Si le flux bypass la page de consentement :
- Vérifier que `serverClientId` dans `google-services.json` correspond au Web Client ID
- Vérifier que l'empreinte SHA-1 de l'APK signé est enregistrée dans Google Cloud Console
- Ajouter `prompt=consent` dans les scopes Google si besoin

### 3. Boutons annuler dans les dialogues
Vérifier que les `AlertDialog` ont un bouton `TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Annuler'))`.

---

## Commandes de test

```bash
# Tester l'inscription
curl -X POST "https://pu74z8pe.us-east.insforge.app/api/auth/users?client_type=mobile" \
  -H "Content-Type: application/json" \
  -H "apikey: anon_75c09927569e3aab8c78e8bf1a69c194bb41e0f231366e46911ffb14dca8881d" \
  -H "Authorization: Bearer anon_75c09927569e3aab8c78e8bf1a69c194bb41e0f231366e46911ffb14dca8881d" \
  -d '{"email":"test@kased.dev","password":"test123456","name":"Test"}'

# Tester la connexion
curl -X POST "https://pu74z8pe.us-east.insforge.app/api/auth/sessions?client_type=mobile" \
  -H "Content-Type: application/json" \
  -H "apikey: anon_75c09927569e3aab8c78e8bf1a69c194bb41e0f231366e46911ffb14dca8881d" \
  -H "Authorization: Bearer anon_75c09927569e3aab8c78e8bf1a69c194bb41e0f231366e46911ffb14dca8881d" \
  -d '{"email":"test@kased.dev","password":"test123456"}'

# Tester le refresh
# (utiliser le refreshToken de la réponse précédente)
curl -X POST "https://pu74z8pe.us-east.insforge.app/api/auth/refresh?client_type=mobile" \
  -H "Content-Type: application/json" \
  -H "apikey: anon_75c09927569e3aab8c78e8bf1a69c194bb41e0f231366e46911ffb14dca8881d" \
  -H "Authorization: Bearer anon_75c09927569e3aab8c78e8bf1a69c194bb41e0f231366e46911ffb14dca8881d" \
  -d '{"refreshToken":"<refresh_token>"}'
```
