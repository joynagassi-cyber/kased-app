---
id: axiom-bootstrap
triggers: ["bootstrap", "init", "démarrer", "setup"]
description: "Initialise entièrement Axiom sur ce projet (installation + scan rapide)"
mode: both
category: setup
---

# Compétence : Amorce Axiom

## Objectif

Lancer l'environnement Axiom : installer les dépendances, effectuer un scan rapide du code source, et préparer l'agent à travailler.

## Quand l'utiliser

- Première utilisation d'Axiom sur un projet
- Après un clone du projet
- Pour réinitialiser l'environnement

## Étapes

1. Vérifier que le dossier `Axiom-scaffold/` existe
2. Exécuter le script d'amorçage :
   ```bash
   bash Axiom-scaffold/scripts/bootstrap.sh
   ```
3. Le script installe automatiquement :
   - Dépendances npm
   - GraphRAG (si Python disponible)
   - GitNexus (optionnel)
4. Exécute automatiquement le scan rapide
5. Affiche la carte des sections détectées

## Résultat

- ✅ Environnement prêt
- ✅ Carte des sections visible dans `Axiom-scaffold/workspace/logs/project-map.md`
- ✅ Agent prêt à travailler

## Mode Flex

Demander à l'utilisateur quelle section travailler.

## Mode Focus

Choisir automatiquement la section la plus pertinente.
