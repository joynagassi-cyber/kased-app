#!/bin/bash
set -euo pipefail

echo "📄 GraphRAG — Indexation documentaire"
echo ""

# Vérifier que GraphRAG est installé
if ! command -v graphrag &> /dev/null; then
    echo "❌ GraphRAG n'est pas installé"
    echo "   Installation : pip install graphrag"
    exit 1
fi

# Créer les répertoires nécessaires
mkdir -p graphrag_data/input
mkdir -p graphrag_data/output
mkdir -p graph
mkdir -p logs

# Nettoyer l'input précédent
echo "🧹 Nettoyage de l'input précédent..."
rm -rf graphrag_data/input/*

# Copier les documents à indexer
echo "📋 Copie des documents..."

# Copier tous les fichiers Markdown de docs/
if [ -d "docs" ]; then
    cp docs/*.md graphrag_data/input/ 2>/dev/null || true
    echo "   ✓ docs/*.md copiés"
fi

# Copier les spécifications
if [ -d "specs" ]; then
    find specs -name "*.md" -exec cp {} graphrag_data/input/ \; 2>/dev/null || true
    echo "   ✓ specs/**/*.md copiés"
fi

# Copier les ADR (Architecture Decision Records)
if [ -d "specs/architecture/decisions" ]; then
    find specs/architecture/decisions -name "*.md" -exec cp {} graphrag_data/input/ \; 2>/dev/null || true
    echo "   ✓ ADR copiés"
fi

# Copier les règles métier
if [ -d "specs/domain" ]; then
    find specs/domain -name "*.md" -exec cp {} graphrag_data/input/ \; 2>/dev/null || true
    echo "   ✓ Règles métier copiées"
fi

# Copier le README principal
if [ -f "README.md" ]; then
    cp README.md graphrag_data/input/
    echo "   ✓ README.md copié"
fi

# Compter les fichiers
FILE_COUNT=$(find graphrag_data/input -name "*.md" | wc -l)
echo ""
echo "📊 $FILE_COUNT fichiers Markdown à indexer"
echo ""

# Vérifier la configuration
if [ ! -f "graphrag_data/settings.yaml" ]; then
    echo "❌ Fichier de configuration manquant : graphrag_data/settings.yaml"
    exit 1
fi

# Vérifier la clé API
if [ -z "${GRAPHRAG_API_KEY:-}" ]; then
    echo "⚠️  Variable GRAPHRAG_API_KEY non définie"
    echo "   Assurez-vous d'avoir configuré votre clé API dans .env"
    echo "   ou utilisez un modèle local (Ollama)"
fi

# Lancer l'indexation
echo "🚀 Lancement de l'indexation GraphRAG..."
echo "   (Cela peut prendre plusieurs minutes selon le nombre de documents)"
echo ""

cd graphrag_data

# Indexation avec mise à jour incrémentale
if graphrag index --update 2>&1 | tee ../logs/graphrag-index.log; then
    echo ""
    echo "✅ Indexation GraphRAG terminée"
else
    echo ""
    echo "❌ Erreur lors de l'indexation GraphRAG"
    echo "   Consultez logs/graphrag-index.log pour plus de détails"
    cd ..
    exit 1
fi

cd ..

# Exporter le graphe au format JSON
echo ""
echo "📤 Export du graphe documentaire..."

# Vérifier si le fichier GraphML existe
if [ -f "graphrag_data/output/create_final_nodes.parquet" ]; then
    # Utiliser un script Python pour convertir Parquet -> JSON
    if [ -f "scripts/export-graphrag.py" ]; then
        python3 scripts/export-graphrag.py
        echo "   ✓ Graphe exporté vers graph/doc-graph.json"
    else
        echo "   ⚠️  Script d'export manquant (scripts/export-graphrag.py)"
        echo "   Création d'un graphe minimal..."
        cat > graph/doc-graph.json << EOF
{
  "entities": [],
  "relations": [],
  "communities": [],
  "metadata": {
    "source": "graphrag",
    "timestamp": "$(date -Iseconds)",
    "status": "export_pending"
  }
}
EOF
    fi
else
    echo "   ⚠️  Fichiers de sortie GraphRAG non trouvés"
    echo "   Création d'un graphe minimal..."
    cat > graph/doc-graph.json << EOF
{
  "entities": [],
  "relations": [],
  "communities": [],
  "metadata": {
    "source": "graphrag",
    "timestamp": "$(date -Iseconds)",
    "status": "no_output"
  }
}
EOF
fi

# Afficher les statistiques
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Statistiques GraphRAG"
echo ""

if [ -f "graph/doc-graph.json" ]; then
    ENTITY_COUNT=$(cat graph/doc-graph.json | grep -o '"id"' | wc -l || echo "0")
    echo "   • Entités extraites : $ENTITY_COUNT"
    echo "   • Fichier : graph/doc-graph.json"
fi

echo ""
echo "📁 Fichiers générés :"
echo "   - graphrag_data/output/          (données GraphRAG)"
echo "   - graph/doc-graph.json           (graphe documentaire)"
echo "   - logs/graphrag-index.log        (logs d'indexation)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
