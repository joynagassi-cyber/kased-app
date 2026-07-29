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
| `INSFORGE_URL` | URL de votre instance InsForge/PostgREST | ⚠️ Optionnel | `https://votre-instance.insforge.app` |
| `INSFORGE_ANON_KEY` | Key d'anoncé pour l'API InsForge | ⚠️ Optionnel | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` |
| `GOOGLE_WEB_CLIENT_ID` | ID du client web Google OAuth | ⚠️ Optionnel | `1234567890-abcd1234567890.apps.googleusercontent.com` |
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
