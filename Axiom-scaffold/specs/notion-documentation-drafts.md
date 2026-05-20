# 📚 BROUILLON DE LA DOCUMENTATION OFFICIELLE — KASED-APP

Ce fichier contient la version de référence rédigée de la documentation de **Kased-App**. Ce contenu sera poussé sur votre Notion dès que la connexion avec l'intégration **Antigravity** aura été établie sur votre page.

---

## 🏛️ Page 1 : Architecture & Modèle de Données

### 1. Structure de la Base de Données (PostgreSQL)

La base de données PostgreSQL de Kased-App utilise un modèle relationnel hautement performant où la logique métier est déportée au niveau de la base de données via des contraintes de clés étrangères, des déclencheurs (triggers) et des procédures stockées (fonctions SQL).

#### Table `membres`
Stocke les informations personnelles et administratives des membres de l'église.
```sql
CREATE TABLE membres (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    date_adhesion DATE NOT NULL DEFAULT CURRENT_DATE,
    date_naissance DATE,
    telephone VARCHAR(20),
    notes TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

#### Table `cultes`
Représente chaque réunion dominicale ou événement pour lequel des cotisations sont perçues.
```sql
CREATE TABLE cultes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date_culte DATE NOT NULL DEFAULT CURRENT_DATE,
    titre VARCHAR(200) NOT NULL,
    montant_cotisation NUMERIC(15, 2) NOT NULL CHECK (montant_cotisation >= 0),
    notes TEXT,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

#### Table `cotisations`
Table de jointure liant un membre à un culte avec son statut de paiement.
```sql
CREATE TABLE cotisations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    membre_id UUID NOT NULL REFERENCES membres(id) ON DELETE CASCADE,
    culte_id UUID NOT NULL REFERENCES cultes(id) ON DELETE CASCADE,
    statut statut_cotisation NOT NULL DEFAULT 'non_paye',
    montant NUMERIC(15, 2) NOT NULL DEFAULT 0 CHECK (montant >= 0),
    date_paiement TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_membre_culte UNIQUE (membre_id, culte_id)
);
```

---

### 2. Le Type Énuméré `statut_cotisation`

Pour garantir l'intégrité absolue des données de cotisation, nous utilisons un type énuméré PostgreSQL strict. Cela empêche l'insertion de statuts invalides ou erronés :

* **`non_paye`** : Le culte a eu lieu et le membre n'a pas encore payé sa cotisation.
* **`paye`** : Le membre a réglé sa cotisation (le dimanche même ou lors d'un rattrapage).
* **`absent`** : Le membre était absent ce dimanche-là. Aucune cotisation n'est due.
* **`en_avance`** : Le membre a payé sa cotisation en avance, avant même la tenue du culte.

```sql
CREATE TYPE statut_cotisation AS ENUM ('non_paye', 'paye', 'absent', 'en_avance');
```

---

### 3. Vues SQL Calculées en Temps Réel

Afin d'éviter des calculs lourds et lents côté client (Flutter) et d'assurer une source de vérité unique, la logique de synthèse est gérée par des Vues SQL indexées.

#### `v_dashboard` (Statistiques Globales)
Affiche les métriques clés de l'application sur l'écran d'accueil.
```sql
CREATE VIEW v_dashboard AS
SELECT 
    (SELECT COUNT(*) FROM membres WHERE is_active = TRUE) AS total_membres_actifs,
    (SELECT COUNT(*) FROM cultes) AS total_cultes,
    (SELECT COUNT(DISTINCT membre_id) FROM cotisations WHERE statut = 'non_paye') AS membres_en_retard,
    (SELECT COALESCE(SUM(montant), 0) FROM cotisations WHERE statut = 'paye' OR statut = 'en_avance') AS total_collecte_fcfa;
```

#### `v_retards_membres` (Suivi des Retards)
Identifie instantanément les membres ayant des impayés et calcule leur dette accumulée.
```sql
CREATE VIEW v_retards_membres AS
SELECT 
    m.id AS membre_id,
    m.nom,
    m.prenom,
    COUNT(c.id) AS nombre_retards,
    SUM(cu.montant_cotisation) AS total_du_fcfa
FROM membres m
JOIN cotisations c ON m.id = c.membre_id
JOIN cultes cu ON c.culte_id = cu.id
WHERE c.statut = 'non_paye' AND m.is_active = TRUE
GROUP BY m.id, m.nom, m.prenom;
```

---

### 4. Architecture de l'Application Flutter

L'application respecte les principes de l'architecture propre (Clean Architecture) orientée données réactives avec **Riverpod** :

```
 ┌─────────────────────────────────────────────────────────────┐
 │                         UI COUCHE                           │
 │     [Widgets] ──► [Screens (Dashboard, Cultes, Membres)]     │
 └──────────────────────────────┬──────────────────────────────┘
                                │ Watch / Read State
                                ▼
 ┌─────────────────────────────────────────────────────────────┐
 │                    STATE MANAGEMENT (Riverpod)              │
 │     [AppDataProvider]  ◄──►  [StatsProvider]                 │
 └──────────────────────────────┬──────────────────────────────┘
                                │ Fetch / Sync
                                ▼
 ┌──────────────────────────────┴──────────────────────────────┐
 │                      SERVICES & NETWORKING                  │
 │   [Isar Local Database]   ◄──►   [InsForge Service (Dio)]   │
 │   (Caching Hors-ligne)           (Appels API PostgREST)     │
 └─────────────────────────────────────────────────────────────┘
```

* **Local Database (Isar)** : Base de données locale NoSQL ultra-rapide fonctionnant comme cache. Elle stocke les données pour permettre à l'application de démarrer et de fonctionner instantanément, même sans connexion Internet.
* **Dio & InsForge Service** : Dio gère la communication HTTP REST vers le BaaS InsForge avec des politiques de relance automatique et un timeout global robuste.

---
---

## 🔐 Page 2 : Authentification & Sécurité

### 1. Authentification Google OAuth 2.0

Le secrétariat se connecte de manière hautement sécurisée via Google Sign-In. 
Le flux d'authentification s'articule comme suit :

1. L'utilisateur clique sur **"Se connecter avec Google"**.
2. L'application Flutter invoque le SDK natif Google.
3. Google renvoie un `idToken` et un `accessToken` sécurisés.
4. L'application transmet ces tokens à **InsForge Auth** pour valider et ouvrir une session JWT.
5. Le JWT est stocké localement de manière sécurisée et injecté dans les en-têtes HTTP de chaque requête subséquente : `Authorization: Bearer <JWT>`.

```dart
Future<AuthResult> signInWithGoogle() async {
  final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  if (googleUser == null) throw Exception("Connexion annulée par l'utilisateur.");
  
  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
  
  final response = await _dio.post('/api/auth/oauth/google', data: {
    'id_token': googleAuth.idToken,
    'access_token': googleAuth.accessToken,
  });
  
  return AuthResult.fromJson(response.data);
}
```

---

### 2. Inscription/Connexion par E-mail & Persistance

Pour les comptes administratifs secondaires, l'authentification s'effectue par e-mail et mot de passe.
La persistance de session est assurée par un gestionnaire sécurisé :
* Le token de rafraîchissement (Refresh Token) est sauvegardé dans le stockage sécurisé du téléphone (`flutter_secure_storage`).
* Au lancement de l'application, si un token de rafraîchissement est présent, une demande silencieuse de renouvellement du JWT est envoyée à InsForge afin d'éviter à l'utilisateur de devoir se reconnecter manuellement.

---

### 3. Résolution du Bug Critique de Timeout (Dio 60s)

#### Problème rencontré
Lors de l'inscription par e-mail, les utilisateurs rencontraient de manière systématique une erreur de timeout réseau de type `DioException [connection timeout]`. 

#### Cause racine
InsForge est configuré pour envoyer un e-mail de confirmation à l'utilisateur dès sa création. L'intégration de la passerelle SMTP d'envoi d'e-mail d'InsForge pouvait prendre jusqu'à 25-30 secondes pour achever l'envoi du mail. Le client Dio ayant un timeout par défaut fixé à 10-15 secondes, la requête HTTP était coupée prématurément par le client Flutter alors que le serveur InsForge était simplement en train de finaliser la transaction SMTP de confirmation.

#### Solution appliquée
Le timeout de connexion et de réception du client HTTP Dio a été étendu à **60 secondes** spécifiquement sur le service d'authentification pour tolérer les délais d'envoi d'e-mail des serveurs SMTP externes.

```dart
// Configuration du client Dio dans lib/services/insforge_service.dart
final BaseOptions options = BaseOptions(
  baseUrl: 'https://kased-app.region.insforge.app',
  connectTimeout: const Duration(seconds: 60), // Timeout étendu à 60s
  receiveTimeout: const Duration(seconds: 60), // Timeout étendu à 60s
);
```

---
---

## 💰 Page 3 : Gestion des Cotisations, Cultes & Membres

### 1. Cycle de Vie Automatisé d'un Membre (Triggers SQL)

Pour éviter d'avoir des incohérences de données (par exemple, un membre actif qui n'aurait pas de ligne de cotisation générée pour un culte passé), nous avons mis en place des **Triggers (déclencheurs) PostgreSQL**.

Dès qu'un nouveau membre est inséré dans la table `membres` :
1. Le trigger `trg_nouveau_membre_cotisations` se déclenche immédiatement après l'INSERT.
2. Il parcourt l'ensemble des cultes historiques enregistrés dans la table `cultes`.
3. Il crée automatiquement une ligne dans la table `cotisations` pour chaque culte historique avec le statut `non_paye` et un montant de 0 FCFA.

Cela garantit que l'historique financier de chaque membre est instantanément complet et à jour dès sa création.

```sql
CREATE OR REPLACE FUNCTION generer_cotisations_nouveau_membre()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO cotisations (membre_id, culte_id, statut, montant)
    SELECT NEW.id, id, 'non_paye', 0
    FROM cultes;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_nouveau_membre_cotisations
AFTER INSERT ON membres
FOR EACH ROW
EXECUTE FUNCTION generer_cotisations_nouveau_membre();
```

---

### 2. Création Automatisée d'un Culte via Fonction RPC SQL

Plutôt que d'effectuer des dizaines de requêtes d'insertion individuelles à partir du téléphone (ce qui consommerait de la bande passante et risquerait de planter en cas de mauvaise connexion), tout le processus est condensé dans une fonction SQL stockée unique, appelée en un seul appel RPC : `creer_culte_avec_cotisations`.

Cette fonction effectue les actions suivantes de manière transactionnelle :
1. Insère le nouveau culte dans la table `cultes`.
2. Identifie tous les membres actifs (`is_active = TRUE`).
3. Insère en masse (Bulk Insert) une cotisation à l'état `non_paye` pour chacun de ces membres actifs liée à ce nouveau culte.

```sql
CREATE OR REPLACE FUNCTION creer_culte_avec_cotisations(
    p_date_culte DATE,
    p_titre VARCHAR(200),
    p_montant_cot. NUMERIC
) RETURNS UUID AS $$
DECLARE
    v_culte_id UUID;
BEGIN
    -- 1. Insertion du culte
    INSERT INTO cultes (date_culte, titre, montant_cotisation)
    VALUES (p_date_culte, p_titre, p_montant_cot.)
    RETURNING id INTO v_culte_id;

    -- 2. Génération des cotisations pour tous les membres actifs
    INSERT INTO cotisations (membre_id, culte_id, statut, montant)
    SELECT id, v_culte_id, 'non_paye', 0
    FROM membres
    WHERE is_active = TRUE;

    RETURN v_culte_id;
END;
$$ LANGUAGE plpgsql;
```

---

### 3. Logique Instantanée du Bouton de Paiement (Toggle RPC)

Pour marquer un paiement ou l'annuler d'un seul clic sur l'application, nous faisons appel à la fonction hautement optimisée `toggle_paiement`. Cette dernière s'assure de l'intégrité des statuts et met à jour instantanément la base de données :

```sql
CREATE OR REPLACE FUNCTION toggle_paiement(
    p_membre_id UUID,
    p_culte_id UUID
) RETURNS VOID AS $$
DECLARE
    v_statut statut_cotisation;
    v_montant_cot. NUMERIC;
BEGIN
    -- Récupération du montant attendu du culte
    SELECT montant_cotisation INTO v_montant_cot.
    FROM cultes WHERE id = p_culte_id;

    -- Récupération du statut actuel
    SELECT statut INTO v_statut
    FROM cotisations
    WHERE membre_id = p_membre_id AND culte_id = p_culte_id;

    -- Logique de basculement du statut de cotisation
    IF v_statut = 'non_paye' OR v_statut = 'absent' THEN
        UPDATE cotisations
        SET statut = 'paye', montant = v_montant_cot., date_paiement = CURRENT_TIMESTAMP
        WHERE membre_id = p_membre_id AND culte_id = p_culte_id;
    ELSE
        UPDATE cotisations
        SET statut = 'non_paye', montant = 0, date_paiement = NULL
        WHERE membre_id = p_membre_id AND culte_id = p_culte_id;
    END IF;
END;
$$ LANGUAGE plpgsql;
```

---
---

## 🛡️ Page 4 : Guide de Débogage & Assurance Qualité

### 1. La Règle d'Or de l'Assurance Qualité

> [!CAUTION]
> **DIRECTIVE ABSOLUE : PAS D'HYPOTHÈSES À L'AVEUGLE SUR LES PLANTAGES !**
> Lorsque l'application rencontre un crash (fermeture subite, écran figé, freeze ou redémarrage inopiné), il est formellement interdit de modifier le code au hasard ou de formuler des hypothèses sans preuves matérielles. 
> La seule et unique méthodologie acceptable consiste à brancher l'application à un outil de log en direct (émulateur ou terminal de débogage physique) pour capturer la trace d'erreur exacte (Stack Trace).

---

### 2. Débogage sur Appareil Physique (Méthode Pas-à-Pas)

Pour capturer les erreurs de production qui ne se produisent que sur mobile :

#### Étape A : Activer le mode Développeur sur le Téléphone
1. Allez dans les **Paramètres** de votre téléphone Android.
2. Allez dans **À propos du téléphone** -> **Informations sur le logiciel**.
3. Tapotez **7 fois** consécutives sur le champ **Numéro de build**. Un message affichera *"Vous êtes maintenant développeur !"*.
4. Retournez au menu principal des paramètres, un nouvel onglet **Options de développement** est apparu. Entrez-y et activez l'option **Débogage USB**.

#### Étape B : Connecter et Lancer le Diagnostic
1. Connectez le téléphone à votre PC via un câble USB de bonne qualité.
2. Ouvrez une invite de commandes ou votre terminal de projet et tapez la commande suivante pour vérifier que l'appareil est bien détecté par Flutter :
   ```powershell
   flutter devices
   ```
3. Lancez l'application en mode débogage actif :
   ```powershell
   flutter run
   ```
4. Gardez le terminal ouvert. Reproduisez précisément l'action qui provoque le plantage ou le crash sur votre téléphone.
5. Copiez l'intégralité de la **Stack Trace rouge** qui apparaît instantanément dans la console pour identifier la ligne exacte de code qui a généré l'exception.

---

### 3. Débogage sur Émulateur

Si vous n'avez pas d'appareil physique sous la main, l'utilisation d'un émulateur Android (via Android Studio) ou iOS (via Simulator sur macOS) permet un débogage rapide et performant.

1. Démarrez votre émulateur à partir de votre IDE ou via la commande de gestion d'Android SDK.
2. Lancer la compilation de débogage :
   ```powershell
   flutter run -d emulator
   ```
3. Le débogueur Flutter intègre également l'outil **Dart DevTools**. Vous pouvez appuyer sur la touche `v` dans votre terminal de débogage pour ouvrir l'inspecteur de performance, de mémoire, et de réseau dans votre navigateur. Cela permet de pister les fuites de mémoire (Memory Leaks) et les requêtes réseau lentes qui bloquent l'application.

---

### 4. Tests Automatisés E2E (Playwright)

Pour valider que nos interfaces web ou nos API backend InsForge ne subissent aucune régression, nous utilisons **Playwright** pour automatiser les scénarios de test.

#### Lancer les tests end-to-end
```powershell
npx playwright test
```

#### Ouvrir le rapport de test interactif visuel
```powershell
npx playwright show-report
```
Playwright enregistre automatiquement des captures d'écran et des vidéos de chaque scénario testé, facilitant grandement la détection visuelle d'éléments cassés ou mal alignés.
