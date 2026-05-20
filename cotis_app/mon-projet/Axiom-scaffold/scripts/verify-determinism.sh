#!/bin/bash
set -euo pipefail

echo "🔍 Vérification du Déterminisme — Axiom-Scaffold"
echo ""

# Chemins
HASH_FILE=".axiom/latest-graph-hash.txt"
LAYOUT_HASH_FILE=".axiom/latest-layout-hash.txt"
ENTITY_GRAPH="graph/entity-graph.json"
LAYOUT_FILE="graph/layout.json"

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour calculer le hash d'un fichier JSON (normalisé)
calculate_json_hash() {
    local file=$1
    if [ ! -f "$file" ]; then
        echo ""
        return
    fi
    
    # Normaliser le JSON (trier les clés, supprimer les espaces)
    cat "$file" | jq -S -c '.' | sha256sum | awk '{print $1}'
}

# 1. Sauvegarder les hash actuels (si existants)
echo "📋 Sauvegarde des hash actuels..."
if [ -f "$HASH_FILE" ]; then
    OLD_GRAPH_HASH=$(cat "$HASH_FILE")
    echo "   ✓ Hash graphe précédent: ${OLD_GRAPH_HASH:0:16}..."
else
    OLD_GRAPH_HASH=""
    echo "   ℹ️  Pas de hash précédent (première exécution)"
fi

if [ -f "$LAYOUT_HASH_FILE" ]; then
    OLD_LAYOUT_HASH=$(cat "$LAYOUT_HASH_FILE")
    echo "   ✓ Hash layout précédent: ${OLD_LAYOUT_HASH:0:16}..."
else
    OLD_LAYOUT_HASH=""
    echo "   ℹ️  Pas de hash layout précédent"
fi

# 2. Exécuter la fusion
echo ""
echo "🔀 Exécution de la fusion déterministe..."
if node scripts/fuse-graph-deterministic.js; then
    echo "   ✅ Fusion terminée"
else
    echo -e "   ${RED}❌ Échec de la fusion${NC}"
    exit 1
fi

# 3. Exécuter le layout
echo ""
echo "📐 Génération du layout déterministe..."
if node scripts/build-layout.js; then
    echo "   ✅ Layout généré"
else
    echo -e "   ${YELLOW}⚠️  Échec du layout (non bloquant)${NC}"
fi

# 4. Calculer les nouveaux hash
echo ""
echo "🔐 Calcul des nouveaux hash..."

if [ -f "$ENTITY_GRAPH" ]; then
    NEW_GRAPH_HASH=$(cat "$HASH_FILE" 2>/dev/null || echo "")
    if [ -z "$NEW_GRAPH_HASH" ]; then
        # Fallback : calculer depuis le fichier
        NEW_GRAPH_HASH=$(calculate_json_hash "$ENTITY_GRAPH")
    fi
    echo "   ✓ Hash graphe actuel: ${NEW_GRAPH_HASH:0:16}..."
else
    echo -e "   ${RED}❌ Fichier $ENTITY_GRAPH introuvable${NC}"
    exit 1
fi

if [ -f "$LAYOUT_FILE" ]; then
    NEW_LAYOUT_HASH=$(jq -r '.metadata.hash' "$LAYOUT_FILE" 2>/dev/null || echo "")
    if [ -z "$NEW_LAYOUT_HASH" ]; then
        NEW_LAYOUT_HASH=$(calculate_json_hash "$LAYOUT_FILE")
    fi
    
    # Sauvegarder le hash du layout
    mkdir -p "$(dirname "$LAYOUT_HASH_FILE")"
    echo "$NEW_LAYOUT_HASH" > "$LAYOUT_HASH_FILE"
    
    echo "   ✓ Hash layout actuel: ${NEW_LAYOUT_HASH:0:16}..."
else
    echo "   ℹ️  Pas de fichier layout"
    NEW_LAYOUT_HASH=""
fi

# 5. Comparer les hash
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Résultats de la Vérification"
echo ""

DETERMINISTIC=true

# Vérifier le graphe
if [ -z "$OLD_GRAPH_HASH" ]; then
    echo -e "${YELLOW}📄 Graphe d'entités:${NC} Première exécution"
    echo "   Hash: $NEW_GRAPH_HASH"
elif [ "$OLD_GRAPH_HASH" = "$NEW_GRAPH_HASH" ]; then
    echo -e "${GREEN}✅ Graphe d'entités:${NC} DÉTERMINISTE"
    echo "   Hash: $NEW_GRAPH_HASH"
else
    echo -e "${RED}❌ Graphe d'entités:${NC} NON DÉTERMINISTE"
    echo "   Ancien: $OLD_GRAPH_HASH"
    echo "   Nouveau: $NEW_GRAPH_HASH"
    DETERMINISTIC=false
fi

echo ""

# Vérifier le layout
if [ -z "$OLD_LAYOUT_HASH" ]; then
    echo -e "${YELLOW}📐 Layout:${NC} Première exécution"
    echo "   Hash: $NEW_LAYOUT_HASH"
elif [ -z "$NEW_LAYOUT_HASH" ]; then
    echo -e "${YELLOW}📐 Layout:${NC} Non généré"
elif [ "$OLD_LAYOUT_HASH" = "$NEW_LAYOUT_HASH" ]; then
    echo -e "${GREEN}✅ Layout:${NC} DÉTERMINISTE"
    echo "   Hash: $NEW_LAYOUT_HASH"
else
    echo -e "${RED}❌ Layout:${NC} NON DÉTERMINISTE"
    echo "   Ancien: $OLD_LAYOUT_HASH"
    echo "   Nouveau: $NEW_LAYOUT_HASH"
    DETERMINISTIC=false
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 6. Conclusion
if [ "$DETERMINISTIC" = true ]; then
    echo -e "${GREEN}✅ SUCCÈS : Le système est déterministe !${NC}"
    echo ""
    echo "Les hash sont identiques entre les exécutions."
    echo "Le graphe et le layout sont reproductibles."
    exit 0
else
    echo -e "${RED}❌ ÉCHEC : Le système n'est pas déterministe${NC}"
    echo ""
    echo "Les hash diffèrent entre les exécutions."
    echo "Vérifiez les sources de non-déterminisme :"
    echo "  • Timestamps dans les métadonnées"
    echo "  • Ordre non trié des clés JSON"
    echo "  • Seed LLM non fixé (GraphRAG)"
    echo "  • Seed layout non fixé"
    exit 1
fi
