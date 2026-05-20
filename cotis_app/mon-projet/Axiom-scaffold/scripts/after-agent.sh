#!/usr/bin/env bash
# Axiom-scaffold/scripts/after-agent.sh
# Hook exécuté après chaque session de développement

set -euo pipefail

AXIOM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPTS_DIR="$AXIOM_ROOT/Axiom-scaffold/scripts"

echo "🔄 Mise à jour post-développement..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Ré-indexer la mémoire
if [ -f "$SCRIPTS_DIR/index-memory.sh" ]; then
    echo "📚 Indexation de la mémoire..."
    bash "$SCRIPTS_DIR/index-memory.sh" || echo "⚠️  Erreur lors de l'indexation mémoire"
fi

# 2. Régénérer la visualisation
if [ -f "$SCRIPTS_DIR/build-visualizer.sh" ]; then
    echo "📊 Génération des visualisations..."
    bash "$SCRIPTS_DIR/build-visualizer.sh" || echo "⚠️  Erreur lors de la génération des visualisations"
fi

# 3. Capturer les apprentissages
if [ -f "$SCRIPTS_DIR/learn.sh" ]; then
    echo "🧠 Capture des apprentissages..."
    bash "$SCRIPTS_DIR/learn.sh" || echo "⚠️  Erreur lors de la capture des apprentissages"
fi

# 4. Valider le code
if [ -f "$SCRIPTS_DIR/validate-code.sh" ]; then
    echo "✅ Validation du code..."
    bash "$SCRIPTS_DIR/validate-code.sh" || echo "⚠️  Erreur lors de la validation du code"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Mise à jour terminée."
