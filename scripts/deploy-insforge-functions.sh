#!/usr/bin/env bash
# Déploie les fonctions edge InsForge de Kased.
#
# Les clés sont injectées dans le code via sed avant le déploiement :
#   - __INSFORGE_ANON_KEY__     → INSFORGE_ANON_KEY (clé anon InsForge)
#   - __ONESIGNAL_REST_API_KEY__ → ONESIGNAL_REST_API_KEY
#
# Usage :
#   INSFORGE_ANON_KEY=xxx ONESIGNAL_REST_API_KEY=yyy ./scripts/deploy-insforge-functions.sh
set -euo pipefail

BASE_URL="${INSFORGE_BASE_URL:-https://pu74z8pe.us-east.insforge.app}"
: "${INSFORGE_ANON_KEY:?INSFORGE_ANON_KEY requis (console InsForge → API keys → clé anon)}"
# ONESIGNAL_REST_API_KEY est optionnel — nécessaire uniquement pour push-notify
: "${ONESIGNAL_REST_API_KEY:-}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

deploy() {
  local slug="$1" file="$2"
  local code
  code="$(python3 - "$file" <<'PY'
import json, sys
print(json.dumps(open(sys.argv[1]).read()))
PY
)"
  local payload
  payload="$(printf '{"name":"%s","slug":"%s","status":"active","code":%s}' "$slug" "$slug" "$code")"

  local status
  status="$(curl -s -o "$TMP/out" -w '%{http_code}' -X PUT "$BASE_URL/api/functions/$slug" \
    -H "Authorization: Bearer $INSFORGE_ANON_KEY" \
    -H 'Content-Type: application/json' -d "$payload")"
  if [ "$status" = "404" ]; then
    status="$(curl -s -o "$TMP/out" -w '%{http_code}' -X POST "$BASE_URL/api/functions" \
      -H "Authorization: Bearer $INSFORGE_ANON_KEY" \
      -H 'Content-Type: application/json' -d "$payload")"
  fi
  echo "$slug → HTTP $status"
  [ "${status:0:1}" = "2" ] || { cat "$TMP/out"; exit 1; }
}

sed "s|__ONESIGNAL_REST_API_KEY__|$ONESIGNAL_REST_API_KEY|" \
  "$ROOT/cotis_app/functions/push-notify.js" > "$TMP/push-notify.js"

sed "s|__INSFORGE_ANON_KEY__|$INSFORGE_ANON_KEY|" \
  "$ROOT/cotis_app/functions/google-auth-bridge.js" > "$TMP/google-auth-bridge.js"

deploy push-notify "$TMP/push-notify.js"
deploy google-auth-bridge "$TMP/google-auth-bridge.js"

echo "OK — fonctions déployées sur $BASE_URL/functions/<slug>"
