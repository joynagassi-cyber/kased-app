# Système de Compétences (Skills) — Axiom-Scaffold

## 📋 Vue d'ensemble

Le système de compétences d'Axiom-Scaffold permet à l'agent IA de travailler par **intentions** plutôt que par commandes brutes. Chaque skill orchestre des scripts shell déterministes pour accomplir une tâche complexe.

## 🎯 Philosophie

### Avant (commandes brutes)
```bash
# L'agent doit se souvenir de toutes ces commandes
bash scripts/bootstrap.sh
bash scripts/quick-scan.sh
node scripts/fuse-graph-deterministic.js
python scripts/pinecone_upload.py
bash scripts/build-visualizer.sh
```

### Après (skills)
```
/axiom-bootstrap    # Fait tout automatiquement
/memory             # Fusionne, indexe, visualise
```

**Avantages :**
- ✅ **Déterministe** : Chaque skill appelle toujours les mêmes scripts
- ✅ **Économie de tokens** : Pas besoin de répéter les commandes
- ✅ **Maintenable** : Un seul endroit pour modifier le comportement
- ✅ **Découvrable** : L'agent peut lister tous les skills disponibles

## 📁 Architecture

```
Axiom-scaffold/
├── skills/
│   ├── registry.json           # Catalogue de tous les skills
│   ├── built-in/               # Skills standards d'Axiom
│   │   ├── bootstrap.md
│   │   ├── quick-scan.md
│   │   ├── memory-update.md
│   │   ├── visualization-update.md
│   │   ├── stack-research.md
│   │   ├── linear-sync.md
│   │   ├── focus-mode.md
│   │   ├── flex-mode.md
│   │   ├── plan-template.md
│   │   ├── task-template.md
│   │   └── walkthrough-template.md
│   ├── custom/                 # Skills personnalisés du projet
│   └── generated/              # Skills générés automatiquement (Couche 7)
└── scripts/                    # Scripts shell orchestrés par les skills
    ├── bootstrap.sh
    ├── quick-scan.sh
    ├── index-memory.sh
    ├── build-visualizer.sh
    ├── stack-research.sh
    ├── linear-sync.sh
    ├── focus-mode.sh
    └── ...
```

## 🧩 Anatomie d'un Skill

Chaque skill est un fichier Markdown avec un frontmatter YAML :

```markdown
---
id: axiom-bootstrap
triggers: ["bootstrap", "init", "démarrer", "setup"]
description: "Initialise entièrement Axiom sur ce projet"
mode: both  # both, flex, ou focus
category: setup
---

# Compétence : Amorce Axiom

## Objectif
Lancer l'environnement Axiom : installer les dépendances, effectuer un scan rapide.

## Étapes
1. Vérifier que le dossier `Axiom-scaffold/` existe
2. Exécuter le script d'amorçage :
   ```bash
   bash Axiom-scaffold/scripts/bootstrap.sh
   ```
3. Exécuter le scan rapide :
   ```bash
   bash Axiom-scaffold/scripts/quick-scan.sh
   ```
4. Communiquer la carte des sections à l'utilisateur

## Résultat
- L'environnement est prêt
- La carte des sections est visible
- L'agent peut se concentrer sur la section choisie
```

### Champs du Frontmatter

| Champ         | Type               | Description                        |
| ------------- | ------------------ | ---------------------------------- |
| `id`          | string             | Identifiant unique du skill        |
| `triggers`    | array              | Liste des déclencheurs (mots-clés) |
| `description` | string             | Description courte du skill        |
| `mode`        | string             | `both`, `flex`, ou `focus`         |
| `category`    | string             | Catégorie du skill                 |
| `script`      | string (optionnel) | Script shell principal             |
| `template`    | string (optionnel) | Template Markdown à utiliser       |

## 🚀 Utilisation

### Activation par Déclencheur

```
/axiom-bootstrap    # Initialise Axiom
/scan               # Scanne le projet
/memory             # Met à jour la mémoire
/visualize          # Génère le graphe
/research           # Recherche les technos
/linear             # Synchronise Linear
/focus              # Active le mode Focus
/flex               # Active le mode Flex
/plan               # Crée un plan
/task               # Crée une tâche
/walkthrough        # Crée un walkthrough
```

### Activation par Intention

L'agent détecte automatiquement les intentions dans votre message :

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

## 📚 Skills Intégrés

### 1. axiom-bootstrap
**Déclencheurs :** `/bootstrap`, `/init`, `/démarrer`, `/setup`  
**Script :** `scripts/bootstrap.sh`  
**Description :** Initialise entièrement Axiom sur le projet

**Ce qu'il fait :**
1. Installe toutes les dépendances (GitNexus, GraphRAG, Playwright)
2. Exécute un scan rapide du projet
3. Génère une carte des sections
4. Demande quelle section travailler

### 2. axiom-scan
**Déclencheurs :** `/scan`, `/scanner`, `/analyser`, `/map`  
**Script :** `scripts/quick-scan.sh`  
**Description :** Scanne rapidement le projet pour détecter les sections

**Ce qu'il fait :**
1. Analyse la structure du projet
2. Détecte les langages et frameworks
3. Identifie les sections principales
4. Génère `workspace/logs/project-map.md`

### 3. axiom-memory
**Déclencheurs :** `/memory`, `/index`, `/mémoire`, `/indexer`  
**Script :** `scripts/index-memory.sh`  
**Description :** Met à jour la mémoire universelle (fusion des graphes)

**Ce qu'il fait :**
1. Exécute GitNexus pour analyser le dépôt
2. Exécute Graphify pour analyser les documents
3. Exécute GraphRAG pour indexer les documents
4. Fusionne les trois graphes de manière déterministe
5. Upload vers Pinecone
6. Génère les notes Obsidian

### 4. axiom-visualize
**Déclencheurs :** `/visualize`, `/visualiser`, `/graph`, `/graphe`  
**Script :** `scripts/build-visualizer.sh`  
**Description :** Régénère la visualisation interactive du graphe

**Ce qu'il fait :**
1. Lit le graphe fusionné
2. Calcule le layout avec seed=42 (déterministe)
3. Génère `graph.html` avec D3.js
4. Génère le panneau d'activité

### 5. axiom-research
**Déclencheurs :** `/research`, `/recherche`, `/stack`, `/technos`  
**Script :** `scripts/stack-research.sh`  
**Description :** Recherche automatiquement les meilleures technologies et MCPs

**Ce qu'il fait :**
1. Analyse la section de travail
2. Détecte les langages et frameworks
3. Recherche en ligne les meilleures bibliothèques
4. Recherche les MCPs pertinents
5. Génère `tools/tech-stack.md` et `tools/mcp-registry.yaml`

### 6. axiom-linear
**Déclencheurs :** `/linear`, `/tickets`, `/sync`, `/synchroniser`  
**Script :** `scripts/linear-sync.sh`  
**Description :** Synchronise les tickets Linear avec le plan d'implémentation

**Ce qu'il fait :**
1. Lit les plans d'implémentation dans `specs/`
2. Extrait les tâches
3. Crée ou met à jour les tickets Linear
4. Synchronise les statuts

**Prérequis :**
- Variable d'environnement `LINEAR_API_KEY`
- Configuration `integrations.linear.enabled: true`

### 7. axiom-focus
**Déclencheurs :** `/focus`, `/autonome`, `/auto`  
**Script :** `scripts/focus-mode.sh`  
**Description :** Active le mode Focus (autonomie totale)

**Ce qu'il fait :**
1. Modifie `config/axiom.config.yaml`
2. Change `mode: flex` en `mode: focus`
3. L'agent travaille en autonomie totale

### 8. axiom-flex
**Déclencheurs :** `/flex`, `/flexible`, `/approbation`  
**Script :** `scripts/focus-mode.sh --flex`  
**Description :** Active le mode Flex (approbations avant actions critiques)

**Ce qu'il fait :**
1. Modifie `config/axiom.config.yaml`
2. Change `mode: focus` en `mode: flex`
3. L'agent demande approbation avant les actions critiques

### 9. axiom-plan
**Déclencheurs :** `/plan`, `/planifier`, `/implementation-plan`  
**Template :** `templates/plan-template.md`  
**Description :** Crée un plan d'implémentation structuré

**Ce qu'il fait :**
1. Lit le template `templates/plan-template.md`
2. Remplit les sections avec le contexte actuel
3. Sauvegarde dans `specs/plans/`

### 10. axiom-task
**Déclencheurs :** `/task`, `/tâche`, `/micro-task`  
**Template :** `templates/task-template.md`  
**Description :** Crée une micro-tâche standardisée

**Ce qu'il fait :**
1. Lit le template `templates/task-template.md`
2. Remplit les sections avec le contexte actuel
3. Sauvegarde dans `specs/tasks/`

### 11. axiom-walkthrough
**Déclencheurs :** `/walkthrough`, `/demo`, `/présentation`  
**Template :** `templates/walkthrough-template.md`  
**Description :** Crée un walkthrough documenté

**Ce qu'il fait :**
1. Lit le template `templates/walkthrough-template.md`
2. Remplit les sections avec le contexte actuel
3. Sauvegarde dans `docs/walkthroughs/`

## 🎨 Créer un Skill Personnalisé

### Étape 1 : Créer le fichier

Créez `skills/custom/mon-skill.md` :

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

### Étape 2 : Créer le script (si nécessaire)

Créez `scripts/mon-script.sh` :

```bash
#!/bin/bash
set -e

echo "🚀 Mon script personnalisé..."

# Votre logique ici

echo "✅ Terminé"
```

### Étape 3 : Enregistrer le skill

Ajoutez-le dans `skills/registry.json` :

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

### Étape 4 : Tester

```
/mon-trigger
```

## 🔧 Modes de Fonctionnement

### Mode Flex (par défaut)
- L'agent demande approbation avant les actions critiques
- Actions automatiques : lint, test, format, build, validate
- Actions nécessitant approbation : modifications API, infrastructure, etc.

### Mode Focus
- L'agent travaille en autonomie totale
- Aucune interruption sauf pour les actions critiques
- Recommandé pour les tâches répétitives et bien définies

### Actions toujours automatiques (même en Flex)
- lint
- test
- format
- build
- validate
- playwright

### Actions nécessitant toujours approbation (même en Focus)
- Modifier la constitution
- Modifier une API publique
- Supprimer une base de données
- Modifier l'infrastructure
- Créer un projet Linear
- Modifier le tech stack

## 📊 Catégories de Skills

| Catégorie            | Description                            | Exemples                     |
| -------------------- | -------------------------------------- | ---------------------------- |
| `setup`              | Installation et configuration initiale | bootstrap                    |
| `analysis`           | Analyse et scan du projet              | quick-scan                   |
| `memory`             | Gestion de la mémoire et des graphes   | memory-update                |
| `visualization`      | Visualisation et exploration           | visualization-update         |
| `research`           | Recherche automatique de technologies  | stack-research               |
| `project-management` | Gestion de projet et Linear            | linear-sync                  |
| `configuration`      | Configuration d'Axiom                  | focus-mode, flex-mode        |
| `planning`           | Planification et décomposition         | plan-template, task-template |
| `documentation`      | Documentation et guides                | walkthrough-template         |
| `custom`             | Skills personnalisés du projet         | (vos skills)                 |
| `generated`          | Skills générés automatiquement         | (Couche 7)                   |

## 🌐 Skills Externes

Axiom peut importer des skills depuis des dépôts externes :

```bash
# Importer un skill depuis GitHub
./scripts/import-skills.sh https://github.com/user/skill-repo.git

# Importer depuis un dépôt local
./scripts/import-skills.sh /path/to/skill-repo
```

**Skills externes populaires :**
- **web-design** : Design de sites web
- **design-system** : Systèmes de design
- **huashu-review** : Revue de design
- **cybersecurity** : Sécurité informatique
- **prodsec** : Sécurité produit
- **hack-skills** : Hacking éthique
- **sysdesign** : Architecture système
- **agentic-patterns** : Patterns agentiques
- **claude-code-skills** : Skills Claude
- **code-toolkit** : Boîte à outils code
- **garden-skills** : Skills généraux
- **ok-skills** : Skills OK
- **debugging** : Débogage

## 🔍 Débogage

### Lister tous les skills disponibles

```bash
cat skills/registry.json | jq '.skills'
```

### Tester un skill manuellement

```bash
# Lire le skill
cat skills/built-in/bootstrap.md

# Exécuter le script directement
bash scripts/bootstrap.sh
```

### Vérifier les logs

```bash
# Logs généraux
cat workspace/logs/axiom.log

# Logs d'un script spécifique
cat workspace/logs/bootstrap.log
cat workspace/logs/linear-sync.log
cat workspace/logs/git-automation.log
```

## 📈 Métriques

Le système de skills permet de :
- **Économiser ~80% de tokens** en évitant de répéter les commandes
- **Garantir le déterminisme** en appelant toujours les mêmes scripts
- **Améliorer la maintenabilité** en centralisant la logique
- **Faciliter la découverte** en listant tous les skills disponibles

## 🚀 Prochaines Étapes

1. **Couche 7 (Apprentissage)** : Génération automatique de skills
2. **Couche 8 (Sécurité)** : Skills de sécurité chirurgicale
3. **Marketplace** : Partage de skills entre projets
4. **Versioning** : Gestion des versions de skills
5. **Tests** : Tests automatisés des skills

---

**Version** : 2.0.0  
**Dernière mise à jour** : 2026-05-09  
**Maintenu par** : Axiom-Scaffold Team
