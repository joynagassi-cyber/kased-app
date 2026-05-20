---
id: axiom-memory
triggers: ["memory", "index", "mémoire", "indexer"]
description: "Met à jour la mémoire universelle (fusion des graphes + Pinecone + Obsidian)"
mode: both
category: memory
---

# Compétence : Mise à Jour de la Mémoire

## Objectif

Indexer le code source et fusionner les graphes (GitNexus + Graphify + GraphRAG) pour créer le super-graphe de connaissances.

## Quand l'utiliser

- Après des modifications importantes du code
- Avant de commencer une nouvelle feature
- Pour mettre à jour la visualisation

## Étapes

1. Exécuter le script d'indexation :
   ```bash
   bash Axiom-scaffold/scripts/index-memory.sh
   ```
2. Le script exécute séquentiellement :
   - GitNexus (analyse structurelle)
   - Graphify (analyse sémantique)
   - GraphRAG (extraction documentaire)
   - Fusion déterministe
   - Layout avec seed fixe
   - Synchronisation Pinecone (optionnel)
   - Génération vault Obsidian

## Résultat

- ✅ `Axiom-scaffold/workspace/graph/entity-graph.json` mis à jour
- ✅ `Axiom-scaffold/workspace/graph/layout.json` généré
- ✅ Hash SHA256 sauvegardé
- ✅ Vault Obsidian synchronisé

## Durée

5-10 minutes selon la taille du projet
