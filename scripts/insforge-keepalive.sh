#!/usr/bin/env bash
# Keepalive InsForge - Empêche la mise en veille de l'instance
#
# Usage:
#   INSFORGE_BASE_URL=https://pu74z8pe.us-east.insforge.app \
#   INSFORGE_ANON_KEY=anon_xxx \
#   ./scripts/insforge-keepalive.sh
#
# Ou avec les variables d'environnement du projet:
#   source .env && ./scripts/insforge-keepalive.sh

set -euo pipefail

INSFORGE_BASE_URL="${INSFORGE_BASE_URL:-https://pu74z8pe.us-east.insforge.app}"
INSFORGE_ANON_KEY="${INSFORGE_ANON_KEY:-}"

if [ -z "$INSFORGE_ANON_KEY" ]; then
  echo "❌ INSFORGE_ANON_KEY requis"
  exit 1
fi

# Ping toutes les 4 minutes (avant les 7 min d'inactivité)
PING_INTERVAL="${PING_INTERVAL:-240}"

echo "🔄 Keepalive InsForge"
echo "   URL: $INSFORGE_BASE_URL"
echo "   Interval: ${PING_INTERVAL}s"
echo "   Ctrl+C pour arrêter"
echo ""

while true; do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    "$INSFORGE_BASE_URL/api/health" \
    -H "apikey: $INSFORGE_ANON_KEY" \
    -H "Authorization: Bearer $INSFORGE_ANON_KEY" \
    --connect-timeout 10 \
    --max-time 15)

  if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Ping OK ($HTTP_CODE) - $(date '+%Y-%m-%d %H:%M:%S')"
  else
    echo "⚠️  Ping échoué ($HTTP_CODE) - $(date '+%Y-%m-%d %H:%M:%S')"
  fi

  sleep "$PING_INTERVAL"
done
