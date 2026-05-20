---
id: axiom-focus
triggers: ["focus", "autonome", "auto"]
description: "Active le mode Focus (autonomie totale, zéro interruption)"
mode: both
category: configuration
---

# Compétence : Mode Focus

## Objectif

Activer le mode Focus où l'agent travaille en totale autonomie sans demander d'approbation (sauf actions liste rouge).

## Quand l'utiliser

- Pour des tâches répétitives bien définies
- Quand vous faites confiance à l'agent
- Pour accélérer le développement

## Étapes

1. Exécuter le script :
   ```bash
   bash Axiom-scaffold/scripts/focus-mode.sh
   ```
2. Le script modifie `Axiom-scaffold/config/axiom.config.yaml` :
   ```yaml
   mode: focus
   ```
3. Redémarre l'agent (si nécessaire)

## Résultat

- ✅ Mode Focus activé
- ✅ Agent travaille en autonomie
- ✅ Approbation uniquement pour actions critiques :
  - Modifier la constitution
  - Modifier une API publique
  - Supprimer une base de données
  - Modifier l'infrastructure

## Avertissement

En mode Focus, l'agent prend des décisions sans validation. Utilisez avec précaution.
