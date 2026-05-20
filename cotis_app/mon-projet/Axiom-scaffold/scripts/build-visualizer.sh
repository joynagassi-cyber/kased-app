#!/bin/bash
# Génère le fichier graph.html à partir du super-graphe
# Usage : ./build-visualizer.sh

set -euo pipefail

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fichiers
GRAPH_FILE="graph/super-graph.json"
CANVAS_FILE="design/canvas.json"
OUTPUT="graph.html"
TEMPLATES_DIR="templates"

# Fonction d'affichage
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Vérifier que le graphe existe
if [ ! -f "$GRAPH_FILE" ]; then
    log_error "Fichier $GRAPH_FILE introuvable."
    log_info "Lancez d'abord l'indexation mémoire : ./scripts/index-memory.sh"
    exit 1
fi

log_info "Génération du visualiseur à partir de $GRAPH_FILE..."

# Vérifier que jq est installé
if ! command -v jq &> /dev/null; then
    log_warning "jq n'est pas installé. Tentative de comptage basique..."
    # Comptage approximatif sans jq
    NODE_COUNT=$(grep -o '"id"' "$GRAPH_FILE" | wc -l)
else
    # Déterminer le nombre de nœuds (via jq)
    NODE_COUNT=$(jq '.nodes | length' "$GRAPH_FILE" 2>/dev/null || echo "0")
fi

log_info "Nombre de nœuds détectés : $NODE_COUNT"

# Sélectionner le template de moteur de rendu
if [ "$NODE_COUNT" -ge 10000 ]; then
    log_info "🔮 Utilisation de Cosmos.gl (GPU) pour $NODE_COUNT nœuds"
    TEMPLATE="$TEMPLATES_DIR/cosmos-template.html"
    
    if [ ! -f "$TEMPLATE" ]; then
        log_error "Template Cosmos.gl introuvable : $TEMPLATE"
        exit 1
    fi
else
    log_info "🎨 Utilisation de G6 + Excalidraw pour $NODE_COUNT nœuds"
    TEMPLATE="$TEMPLATES_DIR/g6-excalidraw-template.html"
    
    if [ ! -f "$TEMPLATE" ]; then
        log_error "Template G6 introuvable : $TEMPLATE"
        exit 1
    fi
fi

# Copier le template
cp "$TEMPLATE" "$OUTPUT"
log_success "Template copié"

# Lire le contenu du graphe
log_info "Injection des données du graphe..."
GRAPH_JSON=$(cat "$GRAPH_FILE")

# Échapper les caractères spéciaux pour sed
# Note: Pour une injection plus robuste, on utilise un script temporaire
TEMP_SCRIPT=$(mktemp)

cat > "$TEMP_SCRIPT" << 'EOF'
import json
import sys

# Lire le fichier HTML
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    html_content = f.read()

# Lire le graphe JSON
with open(sys.argv[2], 'r', encoding='utf-8') as f:
    graph_data = f.read()

# Lire le canvas JSON (ou utiliser {})
canvas_data = '{}'
try:
    with open(sys.argv[3], 'r', encoding='utf-8') as f:
        canvas_data = f.read()
except FileNotFoundError:
    pass

# Remplacer les placeholders
html_content = html_content.replace('__GRAPH_DATA__', graph_data)
html_content = html_content.replace('__CANVAS_DATA__', canvas_data)

# Écrire le résultat
with open(sys.argv[1], 'w', encoding='utf-8') as f:
    f.write(html_content)

print("✓ Données injectées avec succès")
EOF

# Vérifier si Python est disponible
if command -v python3 &> /dev/null; then
    python3 "$TEMP_SCRIPT" "$OUTPUT" "$GRAPH_FILE" "$CANVAS_FILE" 2>/dev/null || {
        log_warning "Injection Python échouée, utilisation de sed..."
        # Fallback avec sed (moins robuste mais fonctionne pour des petits graphes)
        
        # Créer un fichier temporaire avec le JSON échappé
        TEMP_GRAPH=$(mktemp)
        cat "$GRAPH_FILE" > "$TEMP_GRAPH"
        
        # Remplacer le placeholder (méthode simple)
        sed -i "s|__GRAPH_DATA__|$(cat $TEMP_GRAPH)|g" "$OUTPUT" 2>/dev/null || {
            log_error "Impossible d'injecter les données. Installez Python 3 ou jq."
            rm -f "$TEMP_SCRIPT" "$TEMP_GRAPH"
            exit 1
        }
        
        # Canvas data
        if [ -f "$CANVAS_FILE" ]; then
            TEMP_CANVAS=$(mktemp)
            cat "$CANVAS_FILE" > "$TEMP_CANVAS"
            sed -i "s|__CANVAS_DATA__|$(cat $TEMP_CANVAS)|g" "$OUTPUT"
            rm -f "$TEMP_CANVAS"
        else
            sed -i "s|__CANVAS_DATA__|{}|g" "$OUTPUT"
        fi
        
        rm -f "$TEMP_GRAPH"
    }
else
    log_error "Python 3 n'est pas installé. Impossible d'injecter les données."
    log_info "Installez Python 3 : apt-get install python3 (Linux) ou brew install python3 (macOS)"
    rm -f "$TEMP_SCRIPT"
    exit 1
fi

# Nettoyer
rm -f "$TEMP_SCRIPT"

# Vérifier la taille du fichier généré
FILE_SIZE=$(du -h "$OUTPUT" | cut -f1)
log_info "Taille du fichier généré : $FILE_SIZE"

if [ -f "$OUTPUT" ]; then
    log_success "✨ $OUTPUT généré avec succès !"
    log_info "Ouvrez-le dans un navigateur : file://$(pwd)/$OUTPUT"
    
    # Afficher des conseils selon la taille
    FILE_SIZE_BYTES=$(stat -f%z "$OUTPUT" 2>/dev/null || stat -c%s "$OUTPUT" 2>/dev/null || echo "0")
    
    if [ "$FILE_SIZE_BYTES" -gt 5242880 ]; then
        log_warning "Le fichier dépasse 5 Mo. Considérez la compression ou le filtrage des données."
    fi
    
    # Créer un fichier .gitignore si nécessaire
    if [ ! -f ".gitignore" ] || ! grep -q "graph.html" ".gitignore"; then
        log_info "Ajout de graph.html au .gitignore..."
        echo "" >> .gitignore
        echo "# Visualisation générée" >> .gitignore
        echo "graph.html" >> .gitignore
    fi
    
    log_success "🎉 Visualisation prête !"
    echo ""
    echo "📖 Utilisation :"
    echo "   - Ouvrez graph.html dans votre navigateur"
    echo "   - Utilisez la molette pour zoomer"
    echo "   - Cliquez-glissez pour déplacer"
    echo "   - Recherchez un symbole avec la barre de recherche"
    echo "   - Activez le mode annotation avec le bouton ✏️"
    echo ""
    
else
    log_error "Échec de la génération de $OUTPUT"
    exit 1
fi
