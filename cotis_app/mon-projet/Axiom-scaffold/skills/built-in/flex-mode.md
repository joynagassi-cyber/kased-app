---
id: axiom-flex
triggers: ["flex", "flexible", "approbation"]
description: "Active le mode Flex (approbations avant actions critiques)"
mode: both
category: configuration
---

# Compétence : Mode Flex

## Objectif

Activer le mode Flex où l'agent demande approbation avant les actions critiques.

## Quand l'utiliser

- Par défaut (mode le plus sûr)
- Quand vous voulez garder le contrôle
- Pour des modifications sensibles

## Étapes

1. Exécuter le script :
   ```bash
   bash Axiom-scaffold/scripts/focus-mode.sh --flex
   ```
2. Le script modifie `Axiom-scaffold/config/axiom.config.yaml` :
   ```yaml
   mode: flex
   ```
3. Redémarre l'agent (si nécessaire)

## Résultat

- ✅ Mode Flex activé
- ✅ Agent demande approbation pour :
  - Créer un projet Linear
  - Modifier la stack technique
  - Modifier l'infrastructure
  - Supprimer des données
- ✅ Actions automatiques :
  - lint, test, format, build, validate

## Recommandation

Mode par défaut recommandé pour la sécurité.
