#!/usr/bin/env python3
"""
Vectorisation et upload vers Pinecone

Ce script lit le super-graphe, génère des embeddings pour chaque nœud,
et les upload vers Pinecone pour une recherche sémantique rapide.
"""

import json
import os
import sys
from datetime import datetime
from typing import List, Dict, Any

# Vérifier si pinecone-client est installé
try:
    import pinecone
    from pinecone import Pinecone, ServerlessSpec
except ImportError:
    print("⚠️  pinecone-client non installé")
    print("   Installation : pip install pinecone-client")
    sys.exit(0)

# Configuration
SUPER_GRAPH_PATH = "graph/super-graph.json"
INDEX_NAME = "axiom-memory"
BATCH_SIZE = 100
LOG_FILE = "logs/pinecone-sync.log"

def log(message: str):
    """Log un message dans le fichier et la console"""
    timestamp = datetime.now().isoformat()
    log_message = f"[{timestamp}] {message}"
    print(log_message)
    
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
    with open(LOG_FILE, "a") as f:
        f.write(log_message + "\n")

def load_super_graph() -> Dict[str, Any]:
    """Charge le super-graphe"""
    log("📊 Chargement du super-graphe...")
    
    if not os.path.exists(SUPER_GRAPH_PATH):
        log(f"❌ Fichier non trouvé : {SUPER_GRAPH_PATH}")
        sys.exit(1)
    
    with open(SUPER_GRAPH_PATH, "r") as f:
        graph = json.load(f)
    
    log(f"   ✅ {len(graph.get('nodes', []))} nœuds chargés")
    return graph

def generate_embedding_text(node: Dict[str, Any]) -> str:
    """Génère le texte à embedder pour un nœud"""
    parts = []
    
    # Nom du symbole
    if "name" in node:
        parts.append(node["name"])
    elif "uid" in node:
        parts.append(node["uid"])
    
    # Type
    if "kind" in node:
        parts.append(f"Type: {node['kind']}")
    
    # Signature
    if "signature" in node:
        parts.append(node["signature"])
    
    # Résumé du cluster
    if "clusterSummary" in node:
        parts.append(node["clusterSummary"])
    
    # Cluster
    if "cluster" in node:
        parts.append(f"Cluster: {node['cluster']}")
    
    return " | ".join(parts)

def generate_mock_embedding(text: str, dimension: int = 384) -> List[float]:
    """
    Génère un embedding factice (pour démo)
    
    En production, utiliser un vrai modèle :
    - sentence-transformers (local)
    - OpenAI embeddings API
    - Cohere embeddings API
    """
    import hashlib
    
    # Hash du texte pour générer un vecteur déterministe
    hash_obj = hashlib.sha256(text.encode())
    hash_bytes = hash_obj.digest()
    
    # Convertir en vecteur de floats normalisés
    vector = []
    for i in range(dimension):
        byte_val = hash_bytes[i % len(hash_bytes)]
        vector.append((byte_val / 255.0) * 2 - 1)  # Normaliser entre -1 et 1
    
    return vector

def init_pinecone() -> Any:
    """Initialise la connexion Pinecone"""
    log("🔵 Initialisation de Pinecone...")
    
    api_key = os.getenv("PINECONE_API_KEY")
    if not api_key:
        log("❌ PINECONE_API_KEY non défini")
        sys.exit(1)
    
    pc = Pinecone(api_key=api_key)
    
    # Créer l'index s'il n'existe pas
    if INDEX_NAME not in pc.list_indexes().names():
        log(f"   Création de l'index {INDEX_NAME}...")
        pc.create_index(
            name=INDEX_NAME,
            dimension=384,
            metric="cosine",
            spec=ServerlessSpec(cloud="aws", region="us-east-1")
        )
    
    index = pc.Index(INDEX_NAME)
    log(f"   ✅ Connecté à l'index {INDEX_NAME}")
    
    return index

def upload_to_pinecone(index: Any, nodes: List[Dict[str, Any]]):
    """Upload les nœuds vers Pinecone par batch"""
    log(f"📤 Upload de {len(nodes)} nœuds vers Pinecone...")
    
    vectors = []
    
    for i, node in enumerate(nodes):
        # Générer l'ID unique
        node_id = node.get("uid") or node.get("name") or f"node-{i}"
        
        # Générer le texte à embedder
        text = generate_embedding_text(node)
        
        # Générer l'embedding (mock pour démo)
        embedding = generate_mock_embedding(text)
        
        # Préparer les métadonnées
        metadata = {
            "name": node.get("name", ""),
            "kind": node.get("kind", ""),
            "filePath": node.get("filePath", ""),
            "cluster": node.get("cluster", ""),
            "centralityScore": node.get("centralityScore", 0.0),
            "text": text[:1000]  # Limiter la taille
        }
        
        vectors.append({
            "id": node_id,
            "values": embedding,
            "metadata": metadata
        })
        
        # Upload par batch
        if len(vectors) >= BATCH_SIZE:
            index.upsert(vectors=vectors)
            log(f"   ✅ Batch {i // BATCH_SIZE + 1} uploadé ({len(vectors)} vecteurs)")
            vectors = []
    
    # Upload du dernier batch
    if vectors:
        index.upsert(vectors=vectors)
        log(f"   ✅ Dernier batch uploadé ({len(vectors)} vecteurs)")
    
    log(f"✅ {len(nodes)} nœuds vectorisés et uploadés")

def main():
    log("🔵 Vectorisation vers Pinecone\n")
    
    try:
        # Charger le super-graphe
        graph = load_super_graph()
        nodes = graph.get("nodes", [])
        
        if not nodes:
            log("⚠️  Aucun nœud à vectoriser")
            return
        
        # Initialiser Pinecone
        index = init_pinecone()
        
        # Upload vers Pinecone
        upload_to_pinecone(index, nodes)
        
        log("\n✅ Vectorisation terminée avec succès")
        
    except Exception as e:
        log(f"\n❌ Erreur : {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
