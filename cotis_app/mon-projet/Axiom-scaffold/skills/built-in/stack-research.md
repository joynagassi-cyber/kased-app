---
id: axiom-research
triggers: ["research", "recherche", "stack", "technos"]
description: "Recherche automatiquement les meilleures technologies, bibliothèques et MCPs pour le projet"
mode: both
category: research
---

# Compétence : Recherche de Stack Technique

## Objectif

Analyser le projet et rechercher automatiquement les meilleures technologies, bibliothèques, et serveurs MCP adaptés.

## Quand l'utiliser

- Au début d'un nouveau projet
- Avant de choisir une stack technique
- Pour découvrir de nouveaux outils

## Étapes

1. Exécuter le script de recherche :
   ```bash
   bash Axiom-scaffold/scripts/stack-research.sh
   ```
2. Le script :
   - Analyse la section de travail (langages, frameworks)
   - Recherche en ligne (via Autoresearch) les meilleures bibliothèques
   - Identifie les serveurs MCP pertinents
   - Génère deux documents :
     - `Axiom-scaffold/tools/tech-stack.md` : Stack recommandée
     - `Axiom-scaffold/tools/mcp-registry.yaml` : Configuration MCP

## Résultat

- ✅ Stack technique documentée
- ✅ MCPs configurés et prêts à l'emploi
- ✅ Justification des choix

## Mode Flex

Demander validation de la stack avant de l'adopter.

## Mode Focus

Adopter automatiquement la stack recommandée.
