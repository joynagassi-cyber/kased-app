#!/bin/bash
set -euo pipefail

echo "🔍 Validation des spécifications"

# Vérifier que Node.js est disponible
if ! command -v node &> /dev/null; then
    echo "❌ Node.js requis mais non trouvé"
    exit 1
fi

# Vérifier que le script Node existe
if [ ! -f "scripts/validate-specs.js" ]; then
    echo "❌ scripts/validate-specs.js manquant"
    exit 1
fi

# Exécuter le script Node
node scripts/validate-specs.js

echo "✅ Validation des spécifications terminée"
