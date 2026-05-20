#!/usr/bin/env bash
# Axiom-scaffold/scripts/check-all.sh
# Vérifie que tous les scripts Axiom sont exécutables et sans erreur de syntaxe

set -euo pipefail

AXIOM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPTS_DIR="$AXIOM_ROOT/Axiom-scaffold/scripts"

echo "🔍 Vérification des scripts Axiom..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TOTAL=0
PASSED=0
FAILED=0
NOT_EXECUTABLE=0

for script in "$SCRIPTS_DIR"/*.sh; do
    if [ -f "$script" ]; then
        TOTAL=$((TOTAL + 1))
        SCRIPT_NAME=$(basename "$script")
        
        # Vérifier si exécutable
        if [ -x "$script" ]; then
            # Vérifier la syntaxe bash
            if bash -n "$script" 2>/dev/null; then
                echo "✅ $SCRIPT_NAME"
                PASSED=$((PASSED + 1))
            else
                echo "❌ $SCRIPT_NAME (erreur syntaxe)"
                FAILED=$((FAILED + 1))
                bash -n "$script" 2>&1 | head -5
            fi
        else
            echo "⚠️  $SCRIPT_NAME (non exécutable)"
            NOT_EXECUTABLE=$((NOT_EXECUTABLE + 1))
        fi
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Résumé :"
echo "   Total : $TOTAL scripts"
echo "   ✅ Valides : $PASSED"
echo "   ❌ Erreurs : $FAILED"
echo "   ⚠️  Non exécutables : $NOT_EXECUTABLE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $FAILED -gt 0 ] || [ $NOT_EXECUTABLE -gt 0 ]; then
    echo ""
    echo "⚠️  Certains scripts nécessitent des corrections."
    exit 1
else
    echo ""
    echo "✅ Tous les scripts sont valides !"
    exit 0
fi
