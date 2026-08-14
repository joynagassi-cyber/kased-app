# Google Sign-In — diagnostic et procédure de correction

## Cause racine identifiée

`cotis_app/android/app/google-services.json` ne contient **aucun client OAuth
Android** (`client_type: 1`) : uniquement le client Web (`client_type: 3`).

```json
"oauth_client": [
  { "client_id": "535496831713-4ol3...apps.googleusercontent.com", "client_type": 3 }
]
```

Sur Android, `google_sign_in` exige un client OAuth **Android** dont
l'empreinte `certificate_hash` (SHA-1) correspond au certificat qui a signé
l'APK installé — même quand on demande un `idToken` via `serverClientId`.
Sans lui, l'appel natif échoue immédiatement avec
`PlatformException(sign_in_failed, ApiException: 10 DEVELOPER_ERROR)`, avant
tout appel réseau. C'est cohérent avec le symptôme observé : la connexion
Google échoue alors que le bridge InsForge répond correctement.

Le reste de la chaîne est vérifié et fonctionnel :

| Élément | État |
|---|---|
| Fonction `google-auth-bridge` déployée | OK (`/functions/google-auth-bridge`) |
| `EXPECTED_CLIENT_ID` du bridge ↔ client Web de `google-services.json` | identiques |
| Validation d'audience côté bridge | OK (401/403 sur token invalide) |
| Création de compte + session InsForge | OK |
| Création du profil (`profiles`) | corrigée (voir plus bas) |

## Ce qui a été corrigé dans ce dépôt

1. **URL du bridge** : l'app utilise désormais l'URL canonique documentée par
   InsForge, `{baseUrl}/functions/google-auth-bridge`, au lieu du domaine
   `function2` codé en dur ; un `--dart-define` vide ne casse plus la config
   (repli sur les valeurs de production au lieu d'une URL vide).
2. **Bridge** : l'upsert de profil visait `/api/profiles` (endpoint
   inexistant) → corrigé en `/api/database/records/profiles`. Un trigger
   `auth.users → profiles` sert désormais de filet de sécurité.
3. **CI** : le build échoue maintenant explicitement si `UPLOAD_KEYSTORE_B64`
   ou `GOOGLE_AUTH_BRIDGE_URL` manque (avant : APK signé en debug
   silencieusement → SHA-1 inconnu de Firebase → `ApiException: 10`), et un
   script vérifie la cohérence SHA-1 ↔ `google-services.json` :
   `scripts/verifier-google-signin.py`.

## Ce qui reste à faire côté consoles Google (non automatisable)

1. Récupérer le SHA-1 du keystore de release :

   ```bash
   keytool -list -v -keystore upload-keystore.jks -alias <KEY_ALIAS>
   ```

   Et celui du keystore de debug pour tester en local :

   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey \
     -storepass android -keypass android
   ```

2. Firebase Console → *Paramètres du projet* → application `com.kasedapp` →
   **Ajouter une empreinte** → coller les deux SHA-1 (release + debug).
   Si l'app est distribuée via Google Play, ajouter aussi le SHA-1 du
   certificat *Play App Signing* (Play Console → Intégrité de l'application).

3. Retélécharger `google-services.json`, remplacer
   `cotis_app/android/app/google-services.json`, et mettre à jour le secret
   GitHub `GOOGLE_SERVICES_JSON_B64` :

   ```bash
   base64 -w0 google-services.json
   ```

4. Vérifier localement avant de pousser :

   ```bash
   python3 scripts/verifier-google-signin.py \
     --google-services cotis_app/android/app/google-services.json \
     --web-client-id 535496831713-4ol3svlekn919034dp509bbi6i9j0ndo.apps.googleusercontent.com
   ```

5. Secrets GitHub attendus par le workflow :
   `INSFORGE_URL`, `INSFORGE_ANON_KEY`, `GOOGLE_WEB_CLIENT_ID`,
   `GOOGLE_AUTH_BRIDGE_URL` (=
   `https://pu74z8pe.us-east.insforge.app/functions/google-auth-bridge`),
   `GOOGLE_SERVICES_JSON_B64`, `UPLOAD_KEYSTORE_B64`, `KEY_ALIAS`,
   `KEY_PASSWORD`, `KEYSTORE_PASSWORD`.
