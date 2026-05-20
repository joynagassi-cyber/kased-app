#!/bin/bash
set -euo pipefail

echo "🔵 Vectorisation vers Pinecone"

# Vérifier si Python est disponible
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 requis mais non trouvé"
    exit 1
fi

# Vérifier si le script Python existe
if [ ! -f "scripts/pinecone_upload.py" ]; then
    echo "❌ scripts/pinecone_upload.py manquant"
    exit 1
fi

# Vérifier les variables d'environnement
if [ -z "${PINECONE_API_KEY:-}" ]; then
    echo "⚠️  PINECONE_API_KEY non défini dans .env"
    echo "   Vectorisation ignorée (configurez Pinecone pour activer)"
    exit 0
fi

# Exécuter le script Python
python3 scripts/pinecone_upload.py

echo "✅ Vectorisation Pinecone terminée"
