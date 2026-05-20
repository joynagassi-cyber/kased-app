---
id: axiom-scan
triggers: ["scan", "scanner", "analyser", "map"]
description: "Scanne rapidement le projet pour détecter les sections et générer une carte"
mode: both
category: analysis
---

# Compétence : Scan Rapide

## Objectif

Analyser rapidement la structure du projet pour identifier les sections de travail et générer une carte navigable.

## Quand l'utiliser

- Après des modifications importantes de structure
- Pour mettre à jour la carte des sections
- Avant de choisir une nouvelle section de travail

## Étapes

1. Exécuter le script de scan :
   ```bash
   bash Axiom-scaffold/scripts/quick-scan.sh
   ```
2. Le script analyse :
   - Dossiers principaux (src/, tests/, lib/, etc.)
   - Langages détectés
   - Frameworks utilisés
   - Statistiques (fichiers, lignes)
3. Génère `Axiom-scaffold/workspace/logs/project-map.md`

## Résultat

- ✅ Carte des sections mise à jour
- ✅ Statistiques du projet
- ✅ Recommandations (petit/moyen/gros projet)

## Durée

< 5 minutes même sur de gros projets
