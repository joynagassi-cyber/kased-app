---
id: axiom-visualize
triggers: ["visualize", "visualiser", "graph", "graphe"]
description: "Régénère la visualisation interactive du graphe de connaissances"
mode: both
category: visualization
---

# Compétence : Mise à Jour de la Visualisation

## Objectif

Générer ou mettre à jour la visualisation interactive du super-graphe de connaissances.

## Quand l'utiliser

- Après une mise à jour de la mémoire
- Pour explorer visuellement le code
- Pour présenter l'architecture du projet

## Étapes

1. Exécuter le script de visualisation :
   ```bash
   bash Axiom-scaffold/scripts/build-visualizer.sh
   ```
2. Le script génère :
   - `Axiom-scaffold/workspace/graph/graph.html` (visualisation interactive)
   - Panneau d'activité Git
   - Statistiques du graphe

## Résultat

- ✅ Visualisation interactive disponible
- ✅ Ouvrir `graph.html` dans un navigateur
- ✅ Navigation par clusters, recherche, filtres

## Prérequis

- `entity-graph.json` doit exister (exécuter `/axiom-memory` d'abord)
