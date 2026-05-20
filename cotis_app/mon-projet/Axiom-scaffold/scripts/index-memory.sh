#!/bin/bash
set -euo pipefail

echo "🧠 Axiom Mémoire — Indexation du super-graphe"
echo ""

# Créer les répertoires nécessaires
mkdir -p graph
mkdir -p vault/02-codebase
mkdir -p vault/03-decisions
mkdir -p logs

# --- 1. Index GitNexus ---
echo "📊 Étape 1/5 : Indexation GitNexus..."
if command -v gitnexus &> /dev/null; then
    npx gitnexus analyze --skills --embeddings 2>&1 | tee logs/gitnexus.log
    echo "✅ GitNexus indexé"
else
    echo "⚠️  GitNexus non disponible, installation recommandée : npm install -g gitnexus"
    echo "   Création d'un graphe minimal..."
    # Créer un graphe minimal pour continuer
    cat > graph/gitnexus-graph.json << 'EOF'
{
  "nodes": [],
  "edges": [],
  "metadata": {
    "source": "fallback",
    "timestamp": "$(date -Iseconds)",
    "warning": "GitNexus not available"
  }
}
EOF
fi

# --- 2. Graphify (enrichissement sémantique) ---
echo ""
echo "🎨 Étape 2/6 : Enrichissement sémantique (Graphify)..."
if [ -f "scripts/run-graphify.mjs" ]; then
    node scripts/run-graphify.mjs 2>&1 | tee logs/graphify.log || echo "⚠️  Graphify a échoué, on continue"
    echo "✅ Graphify exécuté"
else
    echo "⚠️  Graphify non configuré (scripts/run-graphify.mjs absent)"
    echo "   Création d'un graphe sémantique minimal..."
    # Créer un graphe minimal pour continuer
    cat > graph/graphify-graph.json << 'EOF'
{
  "nodes": [],
  "clusters": [],
  "metadata": {
    "source": "fallback",
    "timestamp": "$(date -Iseconds)",
    "warning": "Graphify not available"
  }
}
EOF
fi

# --- 3. GraphRAG (graphe documentaire) ---
echo ""
echo "📄 Étape 3/6 : Indexation documentaire (GraphRAG)..."
if [ -f "scripts/index-doc-graph.sh" ]; then
    bash scripts/index-doc-graph.sh 2>&1 | tee logs/graphrag.log || echo "⚠️  GraphRAG a échoué, on continue"
    echo "✅ GraphRAG exécuté"
else
    echo "⚠️  scripts/index-doc-graph.sh absent, indexation documentaire ignorée"
    # Créer un graphe documentaire minimal pour continuer
    cat > graph/doc-graph.json << 'EOF'
{
  "entities": [],
  "relations": [],
  "communities": [],
  "metadata": {
    "source": "fallback",
    "timestamp": "$(date -Iseconds)",
    "warning": "GraphRAG not available"
  }
}
EOF
fi

# --- 4. Fusion des graphes ---
echo ""
echo "🔀 Étape 4/6 : Fusion des graphes..."
if [ -f "scripts/fuse-graphs.js" ]; then
    node scripts/fuse-graphs.js 2>&1 | tee logs/fusion.log
    echo "✅ Graphes fusionnés"
else
    echo "❌ scripts/fuse-graphs.js manquant"
    exit 1
fi

# --- 5. Vectorisation Pinecone ---
echo ""
echo "🔵 Étape 5/6 : Vectorisation vers Pinecone..."
if [ -f "scripts/sync-pinecone.sh" ]; then
    bash scripts/sync-pinecone.sh 2>&1 | tee logs/pinecone.log || echo "⚠️  Pinecone sync a échoué, on continue"
    echo "✅ Pinecone synchronisé"
else
    echo "⚠️  scripts/sync-pinecone.sh absent, vectorisation ignorée"
fi

# --- 6. Génération Obsidian ---
echo ""
echo "📝 Étape 6/6 : Génération du vault Obsidian..."
if [ -f "scripts/generate-obsidian-notes.js" ]; then
    node scripts/generate-obsidian-notes.js 2>&1 | tee logs/obsidian.log
    echo "✅ Vault Obsidian généré"
else
    echo "❌ scripts/generate-obsidian-notes.js manquant"
    exit 1
fi

# --- Résumé ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Mémoire indexée avec succès !"
echo ""
echo "📁 Fichiers générés :"
echo "   - graph/super-graph.json       (super-graphe unifié)"
echo "   - graph/entity-graph.json      (graphe avec entités documentaires)"
echo "   - graph/doc-graph.json         (graphe documentaire GraphRAG)"
echo "   - vault/02-codebase/           (notes Obsidian par cluster)"
echo "   - vault/02-codebase/_index.md  (index des clusters)"
echo "   - logs/                        (logs d'indexation)"
echo ""
echo "🔍 Pour interroger la mémoire :"
echo "   - npx gitnexus query \"<requête>\""
echo "   - Ouvrir vault/ dans Obsidian"
echo "   - Utiliser l'API Pinecone (si configuré)"
echo "   - Consulter graph/entity-graph.json pour les entités documentaires"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
