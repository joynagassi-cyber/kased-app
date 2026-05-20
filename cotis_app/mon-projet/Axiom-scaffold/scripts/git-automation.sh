#!/bin/bash
# git-automation.sh — Automatisation Git (commit, push, PR)
# Partie d'Axiom-Scaffold v2.0

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AXIOM_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$AXIOM_ROOT/config/axiom.config.yaml"
WORKSPACE_DIR="$AXIOM_ROOT/workspace"
LOGS_DIR="$WORKSPACE_DIR/logs"

echo "🔧 Automatisation Git..."

# Créer le dossier de logs si nécessaire
mkdir -p "$LOGS_DIR"

# Fonction pour extraire une valeur de la config YAML
get_config_value() {
    local key="$1"
    local default="$2"
    
    if [ -f "$CONFIG_FILE" ]; then
        local value=$(grep "^[[:space:]]*$key:" "$CONFIG_FILE" | sed 's/.*:[[:space:]]*//' | tr -d '"' | tr -d "'")
        if [ -n "$value" ]; then
            echo "$value"
        else
            echo "$default"
        fi
    else
        echo "$default"
    fi
}

# Lire la configuration Git
AUTO_PUSH=$(get_config_value "auto_push" "true")
AUTO_PR=$(get_config_value "auto_pr" "false")
BRANCH_PREFIX=$(get_config_value "branch_prefix" "axiom/")
COMMIT_TEMPLATE=$(get_config_value "commit_message_template" "{type}: {description}")

# Vérifier qu'on est dans un dépôt Git
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Pas un dépôt Git"
    exit 1
fi

# Vérifier s'il y a des changements
if git diff --quiet && git diff --cached --quiet; then
    echo "✅ Aucun changement à commiter"
    exit 0
fi

# Afficher les changements
echo ""
echo "📝 Changements détectés :"
git status --short
echo ""

# Demander le type de commit
echo "Type de commit :"
echo "  1) feat     - Nouvelle fonctionnalité"
echo "  2) fix      - Correction de bug"
echo "  3) docs     - Documentation"
echo "  4) style    - Formatage, style"
echo "  5) refactor - Refactoring"
echo "  6) test     - Tests"
echo "  7) chore    - Maintenance"
echo ""
read -p "Choisissez (1-7) [1]: " commit_type_choice
commit_type_choice=${commit_type_choice:-1}

case $commit_type_choice in
    1) commit_type="feat" ;;
    2) commit_type="fix" ;;
    3) commit_type="docs" ;;
    4) commit_type="style" ;;
    5) commit_type="refactor" ;;
    6) commit_type="test" ;;
    7) commit_type="chore" ;;
    *) commit_type="feat" ;;
esac

# Demander la description
read -p "Description du commit : " commit_description

if [ -z "$commit_description" ]; then
    echo "❌ Description requise"
    exit 1
fi

# Construire le message de commit
commit_message="${COMMIT_TEMPLATE/\{type\}/$commit_type}"
commit_message="${commit_message/\{description\}/$commit_description}"

# Stager tous les changements
echo ""
echo "📦 Staging des changements..."
git add -A

# Commiter
echo "💾 Commit : $commit_message"
git commit -m "$commit_message"

# Obtenir la branche courante
current_branch=$(git branch --show-current)

# Push si activé
if [ "$AUTO_PUSH" = "true" ]; then
    echo ""
    echo "🚀 Push vers origin/$current_branch..."
    
    # Vérifier si la branche existe sur le remote
    if git ls-remote --heads origin "$current_branch" | grep -q "$current_branch"; then
        git push origin "$current_branch"
    else
        git push -u origin "$current_branch"
    fi
    
    echo "✅ Push réussi"
else
    echo ""
    echo "⏸️  Auto-push désactivé (configurez auto_push: true dans axiom.config.yaml)"
    echo "   Pour pusher manuellement : git push origin $current_branch"
fi

# Créer une PR si activé
if [ "$AUTO_PR" = "true" ]; then
    echo ""
    echo "🔀 Création de la Pull Request..."
    
    # Vérifier si gh CLI est installé
    if command -v gh &> /dev/null; then
        # Créer la PR avec gh CLI
        gh pr create --title "$commit_message" --body "Créé automatiquement par Axiom-Scaffold" --base main
        echo "✅ Pull Request créée"
    else
        echo "⚠️  GitHub CLI (gh) non installé"
        echo "   Installez-le : https://cli.github.com/"
        echo "   Ou créez la PR manuellement sur GitHub"
    fi
else
    echo ""
    echo "⏸️  Auto-PR désactivé (configurez auto_pr: true dans axiom.config.yaml)"
fi

# Sauvegarder un log
{
    echo "=== Git Automation - $(date) ==="
    echo "Branch: $current_branch"
    echo "Commit: $commit_message"
    echo "Auto-push: $AUTO_PUSH"
    echo "Auto-PR: $AUTO_PR"
    echo ""
} >> "$LOGS_DIR/git-automation.log"

echo ""
echo "✅ Automatisation Git terminée"
echo "📊 Logs sauvegardés dans : $LOGS_DIR/git-automation.log"

exit 0
