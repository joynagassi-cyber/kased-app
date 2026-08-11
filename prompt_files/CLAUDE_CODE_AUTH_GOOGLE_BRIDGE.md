# 🛠️ PROMPT CLAUDE CODE — RÉPARER L'AUTHENTIFICATION (EMAIL + GOOGLE) ET REDÉPLOYER LE BRIDGE GOOGLE

> 📄 **Document d'instructions à donner à Claude Code** (après avoir cloné le dépôt).
> Rôle : **agent développeur backend + Flutter**. Langue de travail : français.
> Durée estimée : 2 à 4 heures.

---

## 1. RÔLE ET MISSION

Tu es un développeur senior. Tu interviens sur **Kased** (app Flutter de gestion de cotisations d'église, paquet Android `com.kasedapp`), dont le backend est **InsForge** (BaaS : PostgreSQL + auth + fonctions serverless).

Ta mission, **dans cet ordre** :

1. **Vérifier** les corrections d'authentification déjà apportées au code Flutter (elles sont dans le dépôt, ne les défais pas).
2. **Réécrire proprement et redéployer** la fonction serveur `google-auth-bridge` sur InsForge (elle répond actuellement **404 DEPLOYMENT_NOT_FOUND** : le déploiement a été supprimé).
3. **Tester en local** que l'authentification **par email ET par Google** fonctionne réellement (curl contre le backend + `flutter test` + instructions de test manuel sur appareil).
4. Corriger tout problème restant découvert pendant ces tests.

⚠️ **Règle d'or : consulte la documentation officielle InsForge AVANT d'écrire ou modifier du code serveur** (voir §5). Ne code pas la fonction "de mémoire".

---

## 2. CONTEXTE TECHNIQUE (VÉRIFIÉ — ne pas réinventer)

### Stack
- **Frontend** : Flutter (`cotis_app/`), Riverpod, GoRouter, Dio, Isar (cache local) + cloud InsForge.
- **Backend** : InsForge BaaS.
  - **Base URL API** : `https://pu74z8pe.us-east.insforge.app`
  - **URL des fonctions** : `https://pu74z8pe.functions.insforge.app`
  - **Fonction à redéployer** : `google-auth-bridge` → `https://pu74z8pe.functions.insforge.app/google-auth-bridge`
- **Auth Google côté app** : package `google_sign_in 6.2.1`, avec `serverClientId` (Web Client ID) injecté au build via `--dart-define=GOOGLE_SERVER_CLIENT_ID`.

### Endpoints auth InsForge (vérifiés par curl)
| Opération | Méthode + endpoint | Body |
|---|---|---|
| Inscription email | `POST /api/auth/users?client_type=mobile` | `{"email", "password", "name"}` |
| Connexion email | `POST /api/auth/sessions?client_type=mobile` | `{"email", "password"}` |
| Refresh token | `POST /api/auth/refresh?client_type=mobile` | `{"refreshToken"}` |
| Profil | `PUT /api/auth/profile` | `{"name"}` (header `Authorization: Bearer <token>`) |

**🔴 Header obligatoire sur CHAQUE requête** : `apikey: <clé anon InsForge>` (et `Authorization: Bearer <clé anon>`). Sans le header `apikey`, InsForge répond **HTTP 401 `{"error":"AUTH_INVALID_CREDENTIALS","message":"No token provided"}`** — c'est exactement l'erreur affichée à l'inscription par email dans l'app.

### Réponse attendue des endpoints auth (format InsForge)
```json
{
  "access_token": "eyJ...",          // ou accessToken
  "refresh_token": "eyJ...",         // ou refreshToken
  "user": { "id": "uuid", "email": "…", "name": "…" }
}
```

### dart-defines du build (secrets, injectés par GitHub Actions)
- `INSFORGE_BASE_URL` = `https://pu74z8pe.us-east.insforge.app`
- `INSFORGE_ANON_KEY` = clé anon InsForge (le header `apikey`)
- `GOOGLE_SERVER_CLIENT_ID` = Web Client ID Google (format `…apps.googleusercontent.com`)

---

## 3. DIAGNOSTIC DÉJÀ ÉTABLI (à reprendre comme base, à re-vérifier)

### 3.1 Inscription / connexion email → « No token provided »
**Cause** : l'app n'envoyait pas le header `apikey` sur les requêtes email.
**Corrigé dans** : `cotis_app/lib/services/auth_service.dart` — le `Dio` envoie maintenant `apikey` + `Authorization: Bearer` (clé anon) sur toutes les requêtes auth, et une erreur claire est levée si la clé manque au build.

### 3.2 Connexion Google → `PlatformException(sign_in_failed, ApiException: 10)`
**Causes empilées** :
1. Le CI injectait `'placeholder'` comme `GOOGLE_SERVER_CLIENT_ID` quand le secret GitHub manquait → un `serverClientId` invalide fait échouer le sign-in natif avec `ApiException 10` (DEVELOPER_ERROR). **Corrigé** dans `auth_service.dart` (le client ID n'est utilisé que s'il est réellement valide) et dans `.github/workflows/build-release.yml` (le build échoue maintenant si les secrets manquent au lieu de construire un APK cassé).
2. **Le bridge est mort** : `https://pu74z8pe.functions.insforge.app/google-auth-bridge` répond **404 DEPLOYMENT_NOT_FOUND**. Même avec un sign-in Google réussi, l'auth échoue. → **C'est TA mission principale.**

### 3.3 Configuration Google Cloud à vérifier (hors code, à signaler à l'utilisateur)
- Projet Google Cloud / Firebase `kased-app` (n° projet **535496831713**), paquet Android `com.kasedapp`.
- Le **Web Client ID** utilisé doit exister dans ce projet et être un **client OAuth Web** (pas Android).
- L'empreinte **SHA-1** du keystore de signature de l'APK doit être enregistrée dans Firebase (Paramètres du projet → Applications Android). Sans cela, Google Sign-In échoue avec `ApiException 10` sur l'appareil.

---

## 4. FICHIERS DÉJÀ CORRIGÉS (à VÉRIFIER, pas à défaire)

| Fichier | Contenu de la correction |
|---|---|
| `cotis_app/lib/services/auth_service.dart` | Headers `apikey`/`Authorization` sur l'auth email ; `serverClientId` Google seulement si valide ; `forceCodeForRefreshToken: false` ; erreurs Google natives → messages lisibles (`GOOGLE_CONFIG_ERROR`, `GOOGLE_BRIDGE_MISSING`, `GOOGLE_NETWORK_ERROR`, `BRIDGE_TIMEOUT`) ; détection du 404 du bridge. |
| `cotis_app/lib/core/insforge/insforge_config.dart` | Plus aucun `StateError` en release ; getters `effectiveAnonKey` / `effectiveGoogleServerClientId` ; `buildHeaders()`. |
| `cotis_app/lib/widgets/google_auth_error.dart` | Helper de dialogues d'erreur Google en français. |
| `cotis_app/lib/screens/login_screen.dart` / `signup_screen.dart` | Utilisent l'helper d'erreurs partagé. |
| `.github/workflows/build-release.yml` | Échoue si `INSFORGE_URL`, `INSFORGE_ANON_KEY` ou `GOOGLE_WEB_CLIENT_ID` manquent. |
| `SECRETS_REQUIRED.md` | Secrets requis documentés. |
| `cotis_app/lib/core/notifications/notification_service.dart` | Fuseau horaire local défini, fallback alarme inexacte Android 14+. |

**Action** : ouvre ces fichiers, vérifie qu'ils sont cohérents et compilent (`flutter analyze`). Corrige les erreurs éventuelles sans changer les signatures publiques (les tests mockent `AuthService`).

---

## 5. MISSION 1 — VÉRIFIER LE FLUX D'AUTH DANS L'APP

1. Lis `cotis_app/lib/services/auth_service.dart`, `cotis_app/lib/providers/auth_provider.dart`, `cotis_app/lib/screens/login_screen.dart`, `cotis_app/lib/screens/signup_screen.dart`.
2. Vérifie que le flux est : (a) email → `signInWithEmail`/`signUp` → stockage du token ; (b) Google → `signInWithGoogle` → `idToken` → `POST https://pu74z8pe.functions.insforge.app/google-auth-bridge` avec `{"idToken": …}` → réponse `{access_token, refresh_token, user}`.
3. Lance `flutter analyze` et `flutter test` dans `cotis_app/`. Tout doit passer (ou être corrigé).

---

## 6. MISSION 2 (LE CŒUR) — RÉÉCRIRE ET REDÉPLOYER `google-auth-bridge`

### 6.0 AVANT d'écrire le code
- Consulte la **documentation officielle InsForge** : doc des **fonctions serverless** (création, déploiement, env vars, URL d'invocation) et doc **auth** (création d'utilisateur / session). Sur `insforge.app`, cherche `/sdks/functions/overview`, `/sdks/rest/overview` et le CLI (`npx @insforge/cli`). Il existe des outils MCP InsForge (`fetch-docs`, `create-function`, `update-function`, `run-raw-sql`) — utilise-les si disponibles.
- Identifie **comment la fonction va créer un utilisateur + une session InsForge** pour un compte Google. Deux options à arbitrer avec la doc :
  - **Option A** : l'API InsForge avec une **clé service/admin** (ex. `service_role` ou `admin_key`, à définir en env var de la fonction) permet de créer l'utilisateur et d'émettre une session.
  - **Option B** : la fonction génère elle-même un JWT de session avec le secret de projet.
  - Si un secret additionnel est nécessaire (clé service), **demande-le à l'utilisateur** (ne l'invente pas, ne le commit pas).

### 6.1 Spécification fonctionnelle du bridge
Endpoint unique : `POST /google-auth-bridge` (format InsForge fonction : une seule entrée, pas de sous-chemins).

**Entrée :**
```json
{ "idToken": "<Google ID token JWT>" }
```

**Traitement attendu :**
1. **Vérifier le `idToken` Google** : signature (certificats Google), audience `aud` == Web Client ID (`GOOGLE_WEB_CLIENT_ID` passé en env var de la fonction), `iss` == `https://accounts.google.com`, expiration. Utiliser la bibliothèque standard (`google-auth-library` côté Node, ou l'équivalent). **Ne jamais faire confiance à un token non vérifié.**
2. **Extraire** `email` (+ `name`/`picture` si présents).
3. **Trouver ou créer l'utilisateur** dans InsForge (par email) via l'API auth (option A ou B du §6.0). Gérer le cas **`ACCOUNT_EXISTS_WITH_PASSWORD`** : l'utilisateur a déjà un compte email/mot de passe → renvoyer une erreur claire `{"error":"ACCOUNT_EXISTS_WITH_PASSWORD"}` (l'app sait l'afficher).
4. **Créer une session InsForge** et renvoyer :
```json
{
  "access_token": "…",
  "refresh_token": "…",
  "user": { "id": "…", "email": "…", "name": "…" }
}
```
5. **Logs** : journaliser chaque étape (token reçu, email, statut) sans jamais logger le token.

**Erreurs à renvoyer proprement (JSON + code HTTP) :**
- `400` token manquant / malformé
- `401` token Google invalide ou expiré (message `INVALID_GOOGLE_TOKEN`)
- `409`/`400` compte existant avec mot de passe (`ACCOUNT_EXISTS_WITH_PASSWORD`)
- `500` erreur interne (avec log)

### 6.2 Référence d'implémentation (à ADAPTER à la doc InsForge)
```typescript
// Sketch TypeScript — vérifie la forme exacte des fonctions InsForge dans la doc !
import { OAuth2Client } from 'google-auth-library';

const GOOGLE_WEB_CLIENT_ID = Deno.env.get('GOOGLE_WEB_CLIENT_ID') // ou process.env selon le runtime

export default async function handler(req: Request): Promise<Response> {
  try {
    const body = await req.json();
    const idToken = body?.idToken;
    if (!idToken) return json({ error: 'MISSING_ID_TOKEN' }, 400);

    // 1) Vérification du token Google
    const client = new OAuth2Client(GOOGLE_WEB_CLIENT_ID);
    const ticket = await client.verifyIdToken({ idToken, audience: GOOGLE_WEB_CLIENT_ID });
    const payload = ticket.getPayload();
    if (!payload?.email) return json({ error: 'INVALID_GOOGLE_TOKEN' }, 401);

    // 2) Trouver/créer l'utilisateur + session InsForge
    //    → SUIVRE LA DOC INSFORGE (clé service / API auth)
    //    → gérer ACCOUNT_EXISTS_WITH_PASSWORD

    // 3) Réponse attendue par l'app
    return json({
      access_token: session.accessToken,
      refresh_token: session.refreshToken,
      user: { id: user.id, email: user.email, name: user.name },
    }, 200);
  } catch (e) {
    console.error('google-auth-bridge error', e);
    return json({ error: 'INTERNAL', message: 'Erreur interne du serveur' }, 500);
  }
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
```

### 6.3 Déploiement
1. Déploie la fonction `google-auth-bridge` sur InsForge (CLI ou MCP `create-function`/`update-function`) pour qu'elle soit servie sur `https://pu74z8pe.functions.insforge.app/google-auth-bridge`.
2. Définis les **env vars** de la fonction : `GOOGLE_WEB_CLIENT_ID` (et la clé service si nécessaire). **Jamais en clair dans le code.**
3. **Vérifie le déploiement** avec curl :
```bash
# Doit répondre 400 (token manquant) et NON 404 :
curl -sS -X POST 'https://pu74z8pe.functions.insforge.app/google-auth-bridge' \
  -H 'Content-Type: application/json' -d '{}'

# Token invalide → 401 :
curl -sS -X POST 'https://pu74z8pe.functions.insforge.app/google-auth-bridge' \
  -H 'Content-Type: application/json' -d '{"idToken":"faux.jwt.token"}'
```
4. Teste avec un **vrai** idToken (généré via le flux OAuth Google en local, voir Mission 3).

---

## 7. MISSION 3 — TESTS LOCAUX (EMAIL + GOOGLE)

### 7.1 Tests automatisés
```bash
cd cotis_app
flutter pub get
flutter analyze          # 0 erreur
flutter test             # tous les tests verts (auth_provider_test, login_screen_test…)
```

### 7.2 Test backend email (sans l'app)
```bash
# Inscription (doit retourner 200/201 avec tokens) :
curl -sS -X POST 'https://pu74z8pe.us-east.insforge.app/api/auth/users?client_type=mobile' \
  -H 'Content-Type: application/json' \
  -H 'apikey: <CLÉ_ANON>' \
  -H 'Authorization: Bearer <CLÉ_ANON>' \
  -d '{"email":"test-claude@exemple.com","password":"test1234","name":"Test"}' | head -c 400

# Connexion :
curl -sS -X POST 'https://pu74z8pe.us-east.insforge.app/api/auth/sessions?client_type=mobile' \
  -H 'Content-Type: application/json' -H 'apikey: <CLÉ_ANON>' \
  -d '{"email":"test-claude@exemple.com","password":"test1234"}' | head -c 400
```
> La clé anon est un secret : demande-la à l'utilisateur (ou lis `dart_defines.example.txt` pour le nom des variables), ne la committe pas.

### 7.3 Test Google sur appareil (nécessite l'utilisateur)
1. Vérifier avec l'utilisateur que le **SHA-1** du keystore et le **Web Client ID** sont enregistrés dans Firebase/Google Cloud (projet `kased-app`, paquet `com.kasedapp`).
2. Build avec les vraies clés :
```bash
cd cotis_app
flutter build apk --release \
  --dart-define=INSFORGE_BASE_URL=https://pu74z8pe.us-east.insforge.app \
  --dart-define=INSFORGE_ANON_KEY=<CLÉ_ANON> \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<WEB_CLIENT_ID>
```
3. Installer sur un appareil Android réel, tester : inscription email, connexion email, « Continuer avec Google » (choisir un compte, valider), déconnexion.

### 7.4 Test du flux Google complet (sans téléphone, si possible)
Le plus simple est de générer un idToken via un client OAuth (ex. `gcloud auth application-default login` ou un petit script avec la lib Google) puis de l'envoyer au bridge. Sinon, s'assurer que le bridge est testé avec un token réel pendant le test appareil.

---

## 8. CRITÈRES D'ACCEPTATION (checklist finale)

- [ ] `flutter analyze` → 0 erreur ; `flutter test` → tout vert.
- [ ] `POST /api/auth/users` (inscription email) avec header `apikey` → 200/201 avec tokens (plus de « No token provided »).
- [ ] `POST /api/auth/sessions` (connexion email) → 200 avec tokens.
- [ ] `POST https://pu74z8pe.functions.insforge.app/google-auth-bridge` → ne répond plus 404 ; répond 400 sur body vide ; 401 sur token invalide ; 200 avec `{access_token, refresh_token, user}` sur token Google réel.
- [ ] L'app buildée avec les vraies dart-defines se connecte par email.
- [ ] L'app se connecte par Google sur un appareil (SHA-1 + Web Client ID valides) et arrive au dashboard.
- [ ] Erreur `ACCOUNT_EXISTS_WITH_PASSWORD` gérée proprement (message lisible, pas de crash).
- [ ] Aucun secret dans le code commité (clés via env vars des fonctions / dart-defines / secrets GitHub).

---

## 9. LIMITES / RÈGLES DE CONDUITE

- **Toujours** consulter la doc InsForge avant d'écrire du code serveur (pas de code « de mémoire »).
- Ne pas modifier les tests existants pour les faire passer « en triche » ; corriger le code.
- Ne pas committer de secrets (clé anon, clé service, Web Client ID).
- Ne pas toucher aux fonctionnalités hors auth/notifications (membres, cultes, cotisations) sauf si un bug bloquant lié s'y trouve.
- Si un secret manque (clé anon, clé service du bridge), **demander à l'utilisateur** plutôt que deviner.
- En cas de doute sur une décision d'architecture du bridge (Option A vs B), expliquer les deux options à l'utilisateur et le laisser choisir avant d'implémenter.

---

*Document généré le 10/08/2026 — à fournir tel quel à Claude Code après `git clone` du dépôt.*
