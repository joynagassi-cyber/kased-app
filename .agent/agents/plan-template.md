---
id: axiom-plan
triggers: ["plan", "planifier", "implementation-plan"]
description: "Crée un plan d'implémentation structuré depuis le template"
mode: both
category: planning
---

# Compétence : Créer un Plan d'Implémentation

## Objectif

Créer un plan d'implémentation structuré pour une feature ou un MVP, en utilisant le template standardisé.

## Quand l'utiliser

- Au début d'une nouvelle feature
- Pour décomposer un MVP
- Avant de créer les tickets Linear

## Étapes

1. Charger le template :
   ```
   Axiom-scaffold/templates/plan-template.md
   ```
2. Remplir les sections :
   - **Objectif** : Que veut-on accomplir ?
   - **Technos** : Stack technique utilisée
   - **Fichiers modifiés** : Liste des fichiers à créer/modifier
   - **Dépendances** : Bibliothèques nécessaires
   - **Micro-tâches** : Décomposition en tâches ≤ 100 lignes
   - **Tests** : Stratégie de test
3. Sauvegarder dans :
   ```
   Axiom-scaffold/specs/implementation-plan.md
   ```

## Résultat

- ✅ Plan structuré et complet
- ✅ Prêt pour synchronisation Linear
- ✅ Économie de tokens (template compact)

## Mode Flex

Demander validation du plan avant de continuer.
