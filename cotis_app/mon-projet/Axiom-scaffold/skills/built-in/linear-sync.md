---
id: axiom-linear
triggers: ["linear", "tickets", "sync", "synchroniser"]
description: "Synchronise les tickets Linear avec le plan d'implémentation"
mode: both
category: project-management
---

# Compétence : Synchronisation Linear

## Objectif

Créer ou mettre à jour les tickets Linear à partir du plan d'implémentation, et synchroniser leur statut.

## Quand l'utiliser

- Après avoir créé un plan d'implémentation
- Pour mettre à jour le statut des tickets
- Pour créer un nouveau projet Linear

## Étapes

1. Vérifier que `Axiom-scaffold/specs/implementation-plan.md` existe
2. Exécuter le script de synchronisation :
   ```bash
   bash Axiom-scaffold/scripts/linear-sync.sh
   ```
3. Le script :
   - Lit le plan d'implémentation
   - Crée le projet Linear (si nécessaire)
   - Crée les tickets pour chaque tâche
   - Met à jour le statut des tickets existants
   - Documente dans `Axiom-scaffold/workspace/logs/linear-activity.md`

## Résultat

- ✅ Tickets Linear créés/mis à jour
- ✅ Statut synchronisé
- ✅ Activité documentée

## Prérequis

- MCP Linear configuré
- Variable `LINEAR_API_KEY` définie
- Plan d'implémentation existant

## Mode Flex

Demander confirmation avant de créer le projet Linear.
