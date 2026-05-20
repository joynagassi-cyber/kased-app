#!/usr/bin/env bash
# Axiom-scaffold/scripts/test-workflow.sh
# Test complet du workflow Axiom

set -euo pipefail

AXIOM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPTS_DIR="$AXIOM_ROOT/Axiom-scaffold/scripts"

echo "🧪 Test du workflow Axiom complet..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PASSED=0
FAILED=0

# Fonction de test
test_script() {
    local script_name="$1"
    local script_path="$SCRIPTS_DIR/$script_name"
    
    echo ""
    echo "🔍 Test : $script_name"
    
    if [ ! -f "$script_path" ]; then
        echo "❌ Script non trouvé : $script_path"
        FAILED=$((FAILED + 1))
        return 1
    fi
    
    if bash "$script_path" > /dev/null 2>&1; then
        echo "✅ $script_name fonctionne"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo "❌ $script_name a échoué"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# Tests des scripts principaux
echo ""
echo "📋 Tests des scripts principaux..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Détection IDE
test_script "detect-ide.sh"

# 2. Injection contexte
test_script "inject-context.sh"

# 3. Vérification scripts
test_script "check-all.sh"

# 4. Quick scan
if [ -f "$SCRIPTS_DIR/quick-scan.sh" ]; then
    test_script "quick-scan.sh"
fi

# 5. Validation code
if [ -f "$SCRIPTS_DIR/validate-code.sh" ]; then
    test_script "validate-code.sh"
fi

# Résumé
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Résumé des tests :"
echo "   ✅ Réussis : $PASSED"
echo "   ❌ Échoués : $FAILED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $FAILED -gt 0 ]; then
    echo ""
    echo "⚠️  Certains tests ont échoué."
    exit 1
else
    echo ""
    echo "✅ Tous les tests sont passés !"
    exit 0
fi
