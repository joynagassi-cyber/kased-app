#!/bin/bash
set -euo pipefail

echo "📚 Import des skills externes"

# Vérifier que Node.js est disponible
if ! command -v node &> /dev/null; then
    echo "❌ Node.js requis mais non trouvé"
    exit 1
fi

# Vérifier que le script Node existe
if [ ! -f "scripts/import-skills.mjs" ]; then
    echo "❌ scripts/import-skills.mjs manquant"
    exit 1
fi

# Exécuter le script Node
node scripts/import-skills.mjs

echo "✅ Import des skills terminé"
