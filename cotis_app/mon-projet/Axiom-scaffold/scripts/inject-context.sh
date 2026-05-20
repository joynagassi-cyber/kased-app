#!/usr/bin/env bash
# Axiom-scaffold/scripts/inject-context.sh
# Injecte le contexte Axiom dans les fichiers de configuration IDE/CLI

set -euo pipefail

AXIOM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_DIR="$AXIOM_ROOT/Axiom-scaffold/config"

echo "💉 Injection du contexte Axiom..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Fonction pour injecter le contexte Axiom
inject_axiom_context() {
    local target_file="$1"
    local marker="<!-- AXIOM-START -->"
    
    if [ -f "$target_file" ]; then
        if ! grep -q "$marker" "$target_file" 2>/dev/null; then
            echo "" >> "$target_file"
            echo "$marker" >> "$target_file"
            cat "$CONFIG_DIR/AGENTS.md" >> "$target_file"
            echo "<!-- AXIOM-END -->" >> "$target_file"
            echo "✅ Contexte injecté dans $target_file"
        else
            echo "⏭️  Contexte déjà présent dans $target_file"
        fi
    else
        # Créer le fichier avec le contexte
        echo "$marker" > "$target_file"
        cat "$CONFIG_DIR/AGENTS.md" >> "$target_file"
        echo "<!-- AXIOM-END -->" >> "$target_file"
        echo "✅ Fichier créé : $target_file"
    fi
}

# Détecter l'IDE et injecter le contexte
IDE_INFO=$(bash "$AXIOM_ROOT/Axiom-scaffold/scripts/detect-ide.sh")
TOOL=$(echo "$IDE_INFO" | grep "^tool:" | cut -d' ' -f2)
CONTEXT_FILE=$(echo "$IDE_INFO" | grep "^context_file:" | cut -d' ' -f2)

echo "🔍 IDE détecté : $TOOL"
echo "📄 Fichier contexte : $CONTEXT_FILE"
echo ""

# Injecter le contexte
if [ -n "$CONTEXT_FILE" ]; then
    # Créer les dossiers parents si nécessaire
    mkdir -p "$(dirname "$CONTEXT_FILE")"
    
    # Injecter le contexte
    inject_axiom_context "$CONTEXT_FILE"
fi

# Créer les dossiers spécifiques selon l'IDE
case "$TOOL" in
    claude_code)
        mkdir -p "$HOME/.claude/skills"
        mkdir -p ".claude/skills"
        echo "📁 Dossiers Claude Code créés"
        ;;
    cursor)
        mkdir -p ".cursor/rules"
        mkdir -p ".cursor/skills"
        echo "📁 Dossiers Cursor créés"
        ;;
    windsurf)
        mkdir -p ".windsurf/rules"
        mkdir -p ".windsurf/skills"
        echo "📁 Dossiers Windsurf créés"
        ;;
    kiro)
        mkdir -p ".kiro/steering"
        mkdir -p ".kiro/skills"
        echo "📁 Dossiers Kiro créés"
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Injection terminée"
