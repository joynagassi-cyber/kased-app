#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────────────
# Script utilitaire : encode les fichiers binaires en base64 pour les
# GitHub Secrets du workflow build-release.yml.
#
# Usage :
#   bash scripts/encode-secrets.sh
#   bash scripts/encode-secrets.sh /chemin/vers/upload-keystore.jks /chemin/vers/google-services.json
# ────────────────────────────────────────────────────────────────────────
set -euo pipefail

encode_file() {
  local label="$1"
  local path="$2"
  if [[ ! -f "$path" ]]; then
    echo "⚠️  $label : fichier introuvable ($path)"
    return
  fi
  echo ""
  echo "── $label ──────────────────────────────────────────────────────"
  echo "Copiez la ligne ci-dessous dans GitHub → Settings → Secrets → $label"  
  base64 -w0 "$path"
  echo ""
}

# ── Keystore ────────────────────────────────────────────────────────────
KEYSTORE="${1:-android/app/upload-keystore.jks}"
encode_file "UPLOAD_KEYSTORE_B64" "$KEYSTORE"

# ── google-services.json ─────────────────────────────────────────────────
GOOGLE_JSON="${2:-android/app/google-services.json}"
encode_file "GOOGLE_SERVICES_JSON_B64" "$GOOGLE_JSON"

echo ""
echo "──────────────────────────────────────────────────────────────────"
echo "✅ Terminé. Ajoutez également ces secrets GitHub (en clair) :"
echo ""
echo "   INSFORGE_URL           → https://votre-app.region.insforge.app"
echo "   INSFORGE_ANON_KEY      → eyJhbGciOiJIUzI1NiIs..."
echo "   GOOGLE_WEB_CLIENT_ID   → xxxxx.apps.googleusercontent.com"
echo "   KEYSTORE_PASSWORD      → <mot de passe du keystore>"
echo "   KEY_ALIAS              → <alias de la clé>"
echo "   KEY_PASSWORD           → <mot de passe de la clé>"
echo "   SENTRY_DSN             → https://xxxx.ingest.sentry.io/xxxx"
echo ""
