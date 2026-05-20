#!/bin/bash
set -euo pipefail

echo "🚀 Axiom-Scaffold Bootstrap"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Chemins
AXIOM_ROOT="Axiom-scaffold"
CONFIG_FILE="$AXIOM_ROOT/config/axiom.config.yaml"
ERROR_LOG="$AXIOM_ROOT/workspace/logs/bootstrap-errors.md"

# Créer les dossiers nécessaires
mkdir -p "$AXIOM_ROOT/workspace/logs"
mkdir -p "$AXIOM_ROOT/tools"
mkdir -p "$AXIOM_ROOT/proposals"
mkdir -p "$AXIOM_ROOT/skills/external"

# Fonction de logging des erreurs
log_error() {
    local message=$1
    echo "$(date -Iseconds) - ERROR: $message" >> "$ERROR_LOG"
    echo -e "${RED}❌ $message${NC}"
}

# Fonction de succès
log_success() {
    local message=$1
    echo -e "${GREEN}✅ $message${NC}"
}

# Fonction d'avertissement
log_warning() {
    local message=$1
    echo -e "${YELLOW}⚠️  $message${NC}"
}

# 1. Vérifier les dépendances système (jq, yq, curl)
echo "📦 Vérification des prérequis système..."
MISSING_PACKAGES=""
for pkg in jq curl; do
    if ! command -v $pkg &> /dev/null; then
        MISSING_PACKAGES="$MISSING_PACKAGES $pkg"
    fi
done

# yq est optionnel : juste un avertissement
if ! command -v yq &> /dev/null; then
    log_warning "yq non trouvé (optionnel). Les tâches YAML fonctionneront en mode fallback."
fi

if [ -n "$MISSING_PACKAGES" ]; then
    log_warning "Paquets manquants :$MISSING_PACKAGES"
    case "$OSTYPE" in
        linux-gnu*)
            sudo apt-get update && sudo apt-get install -y $MISSING_PACKAGES
            log_success "Paquets installés"
            ;;
        msys* | cygwin*)
            log_warning "Git Bash détecté – installez manuellement :$MISSING_PACKAGES"
            ;;
        *)
            log_warning "Système non supporté pour installation automatique. Installez manuellement :$MISSING_PACKAGES"
            ;;
    esac
fi
# 2. Vérifier Node.js
if ! command -v node &> /dev/null; then
    log_error "Node.js n'est pas installé"
    exit 1
fi
log_success "Node.js $(node --version)"

# 3. Vérifier npm
if ! command -v npm &> /dev/null; then
    log_error "npm n'est pas installé"
    exit 1
fi
log_success "npm $(npm --version)"

# 4. Installer les dépendances npm globales (GitNexus obligatoire)
echo ""
echo "📦 Installation de GitNexus..."
if npm install -g gitnexus; then
    log_success "GitNexus installé globalement"
else
    log_error "Échec installation GitNexus"
    exit 1
fi

# 5. Installation locale des dépendances du projet
echo ""
echo "📦 Installation des dépendances locales..."
if npm install; then
    log_success "Dépendances npm locales installées"
else
    log_error "Échec installation des dépendances locales"
    exit 1
fi

# 6. Python et GraphRAG
echo ""
echo "🐍 Configuration Python/GraphRAG..."
if command -v python &> /dev/null; then
    log_success "Python $(python --version)"
    if python -c "import graphrag" 2>/dev/null; then
        log_success "GraphRAG déjà installé"
    else
        echo "   Installation de GraphRAG via pip..."
        if pip install graphrag 2>&1 | tee -a "$ERROR_LOG"; then
            log_success "GraphRAG installé"
        else
            log_warning "GraphRAG non installé (optionnel). Tapez : pip install graphrag"
        fi
    fi
else
    log_warning "Python non trouvé (GraphRAG non disponible)"
fi

# 7. Graphify (copie depuis vendors ou clone)
echo ""
echo "🕸️ Installation de Graphify..."
if [ -d "vendors/graphify" ]; then
    cp -r vendors/graphify "$AXIOM_ROOT/skills/external/graphify"
    log_success "Graphify copié depuis vendors/"
elif [ ! -d "$AXIOM_ROOT/skills/external/graphify" ]; then
    git clone https://github.com/safishamsi/graphify.git "$AXIOM_ROOT/skills/external/graphify" 2>/dev/null && \
        log_success "Graphify cloné" || log_warning "Graphify non disponible"
fi

# 8. Caveman (copie depuis vendors ou clone)
echo ""
echo "🪨 Installation de Caveman..."
if [ -d "vendors/caveman" ]; then
    cp -r vendors/caveman "$AXIOM_ROOT/skills/external/caveman"
    log_success "Caveman copié depuis vendors/"
elif [ ! -d "$AXIOM_ROOT/skills/external/caveman" ]; then
    git clone https://github.com/JuliusBrussee/caveman.git "$AXIOM_ROOT/skills/external/caveman" 2>/dev/null && \
        log_success "Caveman cloné" || log_warning "Caveman non disponible"
fi

# 9. Playwright (navigateurs pour tests E2E)
echo ""
echo "🎭 Installation de Playwright..."
if npx playwright install; then
    log_success "Playwright installé"
else
    log_warning "Échec installation Playwright (tests E2E indisponibles)"
fi

# 10. Détection et configuration des IDE/CLI
echo ""
echo "🔧 Configuration des IDE/CLI..."
if [ -f "$AXIOM_ROOT/scripts/detect-ide.sh" ]; then
    bash "$AXIOM_ROOT/scripts/detect-ide.sh"
    log_success "IDE/CLI configurés"
else
    log_warning "Script detect-ide.sh non trouvé"
fi

# 11. Hooks Git (husky)
echo ""
echo "🔒 Configuration des hooks Git..."
if command -v npx &> /dev/null; then
    npx husky install && npx husky add .husky/pre-commit "npm test && npm run lint && npm audit --audit-level=high"
    log_success "Hooks Git activés"
else
    log_warning "Husky non disponible"
fi

# 12. Première indexation mémoire
echo ""
echo "🧠 Première indexation mémoire..."
if [ -f "$AXIOM_ROOT/scripts/index-memory.sh" ]; then
    bash "$AXIOM_ROOT/scripts/index-memory.sh"
    log_success "Mémoire indexée"
else
    log_warning "Script index-memory.sh non trouvé"
fi

# 13. Scan rapide final
echo ""
echo "🔍 Scan final du projet..."
if [ -f "$AXIOM_ROOT/scripts/quick-scan.sh" ]; then
    bash "$AXIOM_ROOT/scripts/quick-scan.sh"
    log_success "Scan terminé"
else
    log_warning "Script quick-scan.sh non trouvé"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ Bootstrap terminé !${NC}"
echo ""
echo "📚 Prochaines étapes :"
echo "   /axiom-scan → choisir section de travail"
echo "   /axiom-memory → mise à jour mémoire"
echo "   /axiom-visualize → générer graphique"
echo ""
echo "📖 Documentation : $AXIOM_ROOT/config/AGENTS.md"
echo "⚙️  Configuration : $AXIOM_ROOT/config/axiom.config.yaml"