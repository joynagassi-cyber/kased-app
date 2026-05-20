---
id: axiom-task
triggers: ["task", "tâche", "micro-task"]
description: "Crée une micro-tâche standardisée depuis le template"
mode: both
category: planning
---

# Compétence : Créer une Micro-Tâche

## Objectif

Créer une micro-tâche standardisée (≤ 100 lignes de code) en utilisant le template.

## Quand l'utiliser

- Pour décomposer une feature en tâches atomiques
- Avant de commencer l'implémentation
- Pour documenter une tâche spécifique

## Étapes

1. Charger le template :
   ```
   Axiom-scaffold/templates/task-template.md
   ```
2. Remplir les sections :
   - **Titre** : Nom court de la tâche
   - **Description** : Que fait cette tâche ?
   - **Fichier cible** : Fichier à créer/modifier
   - **Tests associés** : Tests à écrire
   - **État** : TODO / IN_PROGRESS / DONE
3. Sauvegarder dans :
   ```
   Axiom-scaffold/workspace/features/<feature-id>/tasks/<task-id>.md
   ```

## Résultat

- ✅ Tâche documentée
- ✅ Scope clair (≤ 100 lignes)
- ✅ Testable et vérifiable

## Principe

Une tâche = un fichier = un commit = un test
