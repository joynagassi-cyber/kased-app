# 🔐 Secrets GitHub Requís pour CI/CD

Pour que le workflow de build et release fonctionne correctement, vous devez configurez les secrets suivants dans votre dépôt GitHub:

## Accéder aux Secrets

1. Allez sur votre dépôt sur GitHub
2. Cliquez sur **Settings** (en haut à droite)
3. Dans le menu gauche: **Secrets and variables** → **Actions**
4. Cliquez sur **New repository secret**

## List des Secrets

| Nom | Description | Requis | Exemple/Valeur |
|-----|-------------|--------|----------------|
| `INSFORGE_URL` | URL de votre instance InsForge/PostgREST | ✅ Requis (sinon le build échoue) | `https://votre-instance.insforge.app` |
| `INSFORGE_ANON_KEY` | Clé anon pour l'API InsForge — sans elle, l'inscription email répond « No token provided » | ✅ Requis (sinon le build échoue) | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` |
| `GOOGLE_WEB_CLIENT_ID` | ID du client **Web** Google OAuth (utilisé comme `GOOGLE_SERVER_CLIENT_ID`) — sans lui (ou avec une valeur invalide), Google Sign-In échoue avec `ApiException 10` | ✅ Requis (sinon le build échoue) | `1234567890-abcd1234567890.apps.googleusercontent.com` |
| `GOOGLE_AUTH_BRIDGE_URL` | URL de la fonction Deno InsForge pour valider le token Google | ✅ Requis | `https://votre-instance.function2.insforge.app/google-auth-bridge` |
| `SENTRY_DSN` | URL DSN pour Sentry (tracking d'erreurs) | ❌ Optionnel | `https://key@o123.ingest.sentry.io/123` |
| `UPLOAD_KEYSTORE_B64` | Keystore Android encodé en base64 (pour signer l'APK production) | ❌ Optionnel | `MIIG...` (output de `base64 keystore.jks`) |
| `KEY_ALIAS` | Alias de la key dans le keystore | ❌ Si `UPLOAD_KEYSTORE_B64` est set | `my-key-alias` |
| `KEY_PASSWORD` | Password de la key spécifique | ❌ Si `UPLOAD_KEYSTORE_B64` est set | `your-key-password` |
| `KEYSTORE_PASSWORD` | Password du keystore complet | ❌ Si `UPLOAD_KEYSTORE_B64` est set | `your-keystore-password` |
| `GOOGLE_SERVICES_JSON_B64` | `google-services.json` encodé en base64 (pour Firebase) | ❌ Si vous utilisez Firebase | `ewoJImY6ICI...` |

## ⚠️ Important - Sécurité

- **NE JAMAIS** commiter ces secrets dans le code (pas dans `.github/workflows/build-release.yml` ni aucun autre fichier)
- Les secrets sont chiffrés et sécurisés par GitHub
- Si un secret est compromis, régénérez-le immédiatement et mettez à jour dans GitHub Secrets
- Pour créer votre keystore Android (si vous n'en avez pas déjà):

```bash
# Generate a new keystore (keep this secure!)
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias my-key-alias

# Encode to base64 for GitHub Secret
base64 upload-keystore.jks
```

## Vérification des Secrets

Après avoir configurés les secrets, vous pouvez vérifier que le workflow CI les envoie correctement en exécutant manuellement un build via GitHub Actions et en regardant les logs (les secrets seront masqués dans les logs pour des raisons de sécurité).

## Configuration Google Cloud Console (étapes manuelles)

### 1. Créer un projet Google Cloud
- Aller sur [Google Cloud Console](https://console.cloud.google.com/)
- Créer un nouveau projet (nom: `kased-app`)

### 2. Activer les APIs
- API OAuth 2.0
- API Google Sign-In

### 3. Créer les credentials OAuth 2.0

#### Type: Web application
- Nom: `Kased Web Client`
- URI de redirection autorisé: `https://pu74z8pe.function2.insforge.app/google-auth-bridge`

#### Type: iOS (optionnel)
- Bundle ID: `com.kasedapp`

### 4. Ajouter les empreintes SHA-1
Dans la section "Credentials" → "OAuth 2.0 client IDs" → "Android configuration":
- Package name: `com.kasedapp`
- SHA-1 certificate fingerprint: `08:82:10:E3:C3:D2:CD:E5:C6:46:76:FC:07:79:BC:D4:FF:D7:F8:B4`

### 5. Configurer les secrets GitHub
Ajouter les secrets dans Settings → Secrets and variables → Actions:
- `INSFORGE_URL`: votre URL InsForge
- `INSFORGE_ANON_KEY`: clé anon InsForge
- `GOOGLE_WEB_CLIENT_ID`: Client ID Web OAuth
- `GOOGLE_AUTH_BRIDGE_URL`: URL du bridge Google Auth
- `UPLOAD_KEYSTORE_B64`: keystore encodé (optionnel)
- `GOOGLE_SERVICES_JSON_B64`: google-services.json encodé (optionnel)

### 6. Générer google-services.json
1. Aller sur [Firebase Console](https://console.firebase.google.com/)
2. Créer un projet (nom: `kased-app`)
3. Ajouter une app Android avec package name: `com.kasedapp`
4. Télécharger `google-services.json`
5. Encoder en base64:
   ```bash
   base64 -w0 google-services.json
   ```
6. Ajouter comme secret GitHub `GOOGLE_SERVICES_JSON_B64`
