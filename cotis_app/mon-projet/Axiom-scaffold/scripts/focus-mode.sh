#!/bin/bash
# focus-mode.sh — Bascule entre les modes Focus et Flex
# Partie d'Axiom-Scaffold v2.0

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AXIOM_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$AXIOM_ROOT/config/axiom.config.yaml"

echo "⚙️  Gestion des modes Axiom..."

# Vérifier que le fichier de config existe
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Fichier de configuration non trouvé : $CONFIG_FILE"
    exit 1
fi

# Fonction pour obtenir le mode actuel
get_current_mode() {
    grep "^mode:" "$CONFIG_FILE" | sed 's/mode:[[:space:]]*//' | tr -d '"' | tr -d "'"
}

# Fonction pour changer le mode
set_mode() {
    local new_mode="$1"
    
    # Utiliser sed pour remplacer la ligne mode
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/^mode:.*/mode: $new_mode  # $2/" "$CONFIG_FILE"
    else
        # Linux
        sed -i "s/^mode:.*/mode: $new_mode  # $2/" "$CONFIG_FILE"
    fi
}

# Obtenir le mode actuel
current_mode=$(get_current_mode)

echo "Mode actuel : $current_mode"
echo ""

# Vérifier les arguments
if [ "$1" = "--flex" ] || [ "$1" = "flex" ]; then
    # Passer en mode Flex
    if [ "$current_mode" = "flex" ]; then
        echo "✅ Déjà en mode Flex"
        exit 0
    fi
    
    echo "🔄 Passage en mode Flex..."
    set_mode "flex" "avec approbations"
    echo "✅ Mode Flex activé"
    echo ""
    echo "📋 En mode Flex :"
    echo "   • L'agent demande approbation avant les actions critiques"
    echo "   • Actions automatiques : lint, test, format, build, validate"
    echo "   • Actions nécessitant approbation : modifications API, infrastructure, etc."
    
elif [ "$1" = "--focus" ] || [ "$1" = "focus" ] || [ -z "$1" ]; then
    # Passer en mode Focus (par défaut si aucun argument)
    if [ "$current_mode" = "focus" ]; then
        echo "✅ Déjà en mode Focus"
        exit 0
    fi
    
    echo "🔄 Passage en mode Focus..."
    set_mode "focus" "autonome complet"
    echo "✅ Mode Focus activé"
    echo ""
    echo "🚀 En mode Focus :"
    echo "   • L'agent travaille en autonomie totale"
    echo "   • Aucune interruption sauf pour les actions critiques"
    echo "   • Recommandé pour les tâches répétitives et bien définies"
    echo ""
    echo "⚠️  Certaines actions nécessitent toujours approbation :"
    echo "   • Modification de la constitution"
    echo "   • Modification d'API publique"
    echo "   • Suppression de base de données"
    echo "   • Modification d'infrastructure"
    
elif [ "$1" = "--status" ] || [ "$1" = "status" ]; then
    # Afficher le statut
    echo "📊 Statut du mode :"
    echo ""
    echo "Mode actuel : $current_mode"
    echo ""
    
    if [ "$current_mode" = "flex" ]; then
        echo "📋 Mode Flex (avec approbations)"
        echo "   • Actions automatiques : lint, test, format, build, validate"
        echo "   • Actions nécessitant approbation : modifications critiques"
    else
        echo "🚀 Mode Focus (autonome)"
        echo "   • Autonomie totale sauf actions critiques"
        echo "   • Recommandé pour tâches répétitives"
    fi
    
    echo ""
    echo "Pour changer de mode :"
    echo "   ./scripts/focus-mode.sh --focus   # Passer en Focus"
    echo "   ./scripts/focus-mode.sh --flex    # Passer en Flex"
    
else
    echo "❌ Argument invalide : $1"
    echo ""
    echo "Usage :"
    echo "   ./scripts/focus-mode.sh [--focus|--flex|--status]"
    echo ""
    echo "Options :"
    echo "   --focus   Passer en mode Focus (autonome)"
    echo "   --flex    Passer en mode Flex (avec approbations)"
    echo "   --status  Afficher le mode actuel"
    exit 1
fi

echo ""
echo "📝 Configuration mise à jour : $CONFIG_FILE"

exit 0
