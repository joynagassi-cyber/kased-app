# 🚀 Quick Start — Système de Compétences (Skills)

**Durée estimée** : 10 minutes  
**Prérequis** : Axiom-Scaffold installé

---

## 📋 Qu'est-ce qu'un Skill ?

Un **skill** est une compétence spécialisée qui orchestre des scripts shell pour accomplir une tâche complexe. Au lieu d'exécuter des commandes brutes, vous activez des skills via des déclencheurs comme `/axiom-bootstrap` ou `/scan`.

**Avantages :**
- ✅ **Économie de tokens** (~80%) : Plus besoin de répéter les commandes
- ✅ **Déterminisme** : Chaque skill appelle toujours les mêmes scripts
- ✅ **Maintenabilité** : Un seul endroit pour modifier le comportement
- ✅ **Découvrabilité** : Liste tous les skills disponibles

---

## 🎯 Skills Disponibles (11 skills)

| Skill                 | Déclencheur    | Description                        |
| --------------------- | -------------- | ---------------------------------- |
| **axiom-bootstrap**   | `/bootstrap`   | Initialise Axiom sur le projet     |
| **axiom-scan**        | `/scan`        | Scanne rapidement le projet        |
| **axiom-memory**      | `/memory`      | Met à jour la mémoire universelle  |
| **axiom-visualize**   | `/visualize`   | Régénère la visualisation          |
| **axiom-research**    | `/research`    | Recherche les meilleures technos   |
| **axiom-linear**      | `/linear`      | Synchronise avec Linear            |
| **axiom-focus**       | `/focus`       | Active le mode Focus (autonome)    |
| **axiom-flex**        | `/flex`        | Active le mode Flex (approbations) |
| **axiom-plan**        | `/plan`        | Crée un plan d'implémentation      |
| **axiom-task**        | `/task`        | Crée une micro-tâche               |
| **axiom-walkthrough** | `/walkthrough` | Crée un walkthrough                |

---

## 🚀 Test Rapide (5 minutes)

### 1. Initialiser Axiom

```
/axiom-bootstrap
```

**Ce qui se passe :**
1. Installation des dépendances (GitNexus, GraphRAG, Playwright)
2. Scan rapide du projet
3. Génération de la carte des sections
4. Demande de la section de travail

**Résultat attendu :**
- Fichier `Axiom-scaffold/workspace/logs/project-map.md` créé
- Liste des sections détectées affichée

### 2. Scanner le Projet

```
/scan
```

**Ce qui se passe :**
1. Analyse de la structure du projet
2. Détection des langages et frameworks
3. Identification des sections principales

**Résultat attendu :**
- Carte des sections mise à jour
- Statistiques affichées (nombre de fichiers, lignes, etc.)

### 3. Mettre à Jour la Mémoire

```
/memory
```

**Ce qui se passe :**
1. Exécution de GitNexus (graphe de structure)
2. Exécution de Graphify (graphe sémantique)
3. Exécution de GraphRAG (graphe documentaire)
4. Fusion des trois graphes
5. Upload vers Pinecone
6. Génération des notes Obsidian

**Résultat attendu :**
- Fichier `Axiom-scaffold/workspace/graph/super-graph.json` créé
- Notes Obsidian dans `Axiom-scaffold/workspace/vault/`
- Logs dans `Axiom-scaffold/workspace/logs/index-memory.log`

### 4. Visualiser le Graphe

```
/visualize
```

**Ce qui se passe :**
1. Lecture du super-graphe
2. Calcul du layout (déterministe, seed=42)
3. Génération de `graph.html`

**Résultat attendu :**
- Fichier `graph.html` créé à la racine
- Ouvrir dans un navigateur pour voir le graphe interactif

### 5. Créer un Plan

```
/plan
```

**Ce qui se passe :**
1. Lecture du template `templates/plan-template.md`
2. Remplissage avec le contexte actuel
3. Sauvegarde dans `specs/plans/`

**Résultat attendu :**
- Fichier de plan créé dans `Axiom-scaffold/specs/plans/`
- Plan structuré avec objectifs, contraintes, tâches

---

## 🎨 Activation par Intention

Vous pouvez aussi activer les skills par intention naturelle :

| Intention                                | Skill activé      |
| ---------------------------------------- | ----------------- |
| "initialise le projet"                   | `axiom-bootstrap` |
| "scanne le code"                         | `axiom-scan`      |
| "mets à jour la mémoire"                 | `axiom-memory`    |
| "génère le graphe"                       | `axiom-visualize` |
| "recherche les meilleures bibliothèques" | `axiom-research`  |
| "synchronise avec Linear"                | `axiom-linear`    |
| "passe en mode autonome"                 | `axiom-focus`     |
| "crée un plan d'implémentation"          | `axiom-plan`      |

---

## 🔧 Modes de Fonctionnement

### Mode Flex (par défaut)
```
/flex
```
- L'agent demande approbation avant les actions critiques
- Actions automatiques : lint, test, format, build, validate
- Recommandé pour les projets en production

### Mode Focus
```
/focus
```
- L'agent travaille en autonomie totale
- Aucune interruption sauf pour les actions critiques
- Recommandé pour les tâches répétitives

### Vérifier le Mode Actuel
```bash
bash Axiom-scaffold/scripts/focus-mode.sh --status
```

---

## 📚 Créer un Skill Personnalisé

### 1. Créer le Fichier

Créez `Axiom-scaffold/skills/custom/mon-skill.md` :

```markdown
---
id: mon-skill
triggers: ["mon-trigger", "alias"]
description: "Description de mon skill"
mode: both
category: custom
script: scripts/mon-script.sh
---

# Compétence : Mon Skill

## Objectif
Décrire ce que fait le skill.

## Étapes
1. Première étape
2. Deuxième étape
3. Troisième étape

## Résultat
Ce qui est produit à la fin.
```

### 2. Créer le Script

Créez `Axiom-scaffold/scripts/mon-script.sh` :

```bash
#!/bin/bash
set -e

echo "🚀 Mon script personnalisé..."

# Votre logique ici

echo "✅ Terminé"
```

### 3. Enregistrer le Skill

Ajoutez-le dans `Axiom-scaffold/skills/registry.json` :

```json
{
    "skills": {
        "custom": [
            {
                "id": "mon-skill",
                "file": "custom/mon-skill.md",
                "triggers": ["mon-trigger", "alias"],
                "description": "Description de mon skill",
                "category": "custom",
                "mode": "both",
                "script": "scripts/mon-script.sh"
            }
        ]
    }
}
```

### 4. Tester

```
/mon-trigger
```

---

## 🔍 Débogage

### Lister Tous les Skills

```bash
cat Axiom-scaffold/skills/registry.json | jq '.skills'
```

### Tester un Script Manuellement

```bash
# Lire le skill
cat Axiom-scaffold/skills/built-in/bootstrap.md

# Exécuter le script directement
bash Axiom-scaffold/scripts/bootstrap.sh
```

### Vérifier les Logs

```bash
# Logs généraux
cat Axiom-scaffold/workspace/logs/axiom.log

# Logs d'un script spécifique
cat Axiom-scaffold/workspace/logs/bootstrap.log
cat Axiom-scaffold/workspace/logs/linear-sync.log
```

---

## 📖 Documentation Complète

Pour plus de détails, consultez :
- **Documentation complète** : `Axiom-scaffold/docs/SKILLS-SYSTEM.md`
- **Configuration** : `Axiom-scaffold/config/AGENTS.md`
- **Registre** : `Axiom-scaffold/skills/registry.json`
- **Rapport de complétion** : `Axiom-scaffold/reports/SKILLS_SYSTEM_COMPLETE.md`

---

## 🎉 Prochaines Étapes

1. **Tester tous les skills** sur votre projet
2. **Créer des skills personnalisés** pour vos besoins spécifiques
3. **Importer des skills externes** depuis GitHub
4. **Contribuer** en partageant vos skills avec la communauté

---

**Version** : 2.0.0  
**Dernière mise à jour** : 2026-05-09  
**Maintenu par** : Axiom-Scaffold Team
