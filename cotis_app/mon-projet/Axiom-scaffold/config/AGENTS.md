# AGENTS.md — Axiom-Scaffold Agent Rules

**⚠️ RÈGLES ABSOLUES POUR TOUS LES AGENTS IA ⚠️**

Ce fichier définit les règles strictes que TOUT agent IA (Claude Code, Cursor, Windsurf, Codex, etc.) DOIT respecter lorsqu'il travaille avec Axiom-Scaffold.
## 🚨 Règle #1 : Confinement Total dans Axiom-scaffold/
**TOUS les fichiers créés par l'agent DOIVENT être dans `Axiom-scaffold/`.**
- ✅ **AUTORISÉ** : Écrire dans `Axiom-scaffold/workspace/`, `Axiom-scaffold/specs/`, etc.
- ❌ **INTERDIT** : Créer des fichiers à la racine du projet (sauf `src/`, `tests/`)
- ❌ **INTERDIT** : Disperser des fichiers de configuration partout
**Pourquoi ?** Pour garder le projet propre et permettre à l'agent de fonctionner dans n'importe quel projet sans polluer la structure existante.
## 🎯 Règle #2 : Utiliser les Templates Obligatoirement
Tous les artefacts DOIVENT utiliser les templates fournis dans `Axiom-scaffold/templates/` :
- **Plan d'implémentation** : `templates/plan-template.md`
- **Micro-tâche** : `templates/task-template.md`
- **Walkthrough** : `templates/walkthrough-template.md`

**Pourquoi ?** Pour économiser des milliers de tokens et garantir la cohérence.
## ⚙️ Règle #3 : Respecter le Mode (Focus / Flex)

Le mode est défini dans `Axiom-scaffold/config/axiom.config.yaml` :

- **Mode Flex** (par défaut) : Demander approbation avant les actions critiques
- **Mode Focus** : Travailler en autonomie totale

**Actions toujours automatiques** (même en flex) :
- lint, test, format, build, validate

**Actions nécessitant toujours approbation** (même en focus) :
- Modifier la constitution
- Modifier une API publique
- Supprimer une base de données
- Modifier l'infrastructure
- Créer un projet Linear

## 📋 Règle #4 : Consulter la Constitution Avant de Coder

Avant toute modification de code, l'agent DOIT consulter :

- `Axiom-scaffold/specs/rules/constitution.md`
- Les règles métier dans `Axiom-scaffold/specs/domain/`
- Les décisions d'architecture dans `Axiom-scaffold/specs/architecture/decisions/`

## 🔍 Règle #5 : Scan Rapide et Choix de Section

Pour les gros projets (>100k lignes), l'agent DOIT :

1. Exécuter `scripts/quick-scan.sh` pour obtenir une carte des sections
2. Demander à l'humain quelle section travailler
3. Ne charger que le sous-graphe de cette section

**Pourquoi ?** Pour garantir la réactivité même sur des projets de 20M de lignes.

## 📚 Règle #6 : Structure de Navigation

Bienvenue, agent IA. Voici ta carte de navigation dans Axiom-Scaffold.

## 📚 Règle #6 : Structure de Navigation

### Caveman Mode (obligatoire)

**⚠️ LIRE `config/caveman-rules.yaml` AVANT TOUTE ÉCRITURE (chat, fichiers, logs).**

Mode caveman full activé par défaut :
- Réponses ≤ 6 lignes
- Format : [constat] [cause] [action]
- Pas de politesse, pas de remplissage
- Code et erreurs intacts
- Économie : 65-75% tokens

Commandes :
- `/caveman lite` : professionnel
- `/caveman full` : par défaut (fragments)
- `/caveman ultra` : télégraphique
- `stop caveman` : désactiver

### Architecture et spécifications
- **Architecture générale** : `docs/ARCHITECTURE.md`
- **Mémoire universelle** : `docs/MEMORY.md`
- **Déterminisme** : `docs/DETERMINISM.md`
- **Auto-optimisation** : `docs/AUTO-OPTIMIZATION.md`
- **Spécifications & Skills** : `docs/SPECS-AND-SKILLS.md`
- **Minimiseur de contexte** : `docs/CONTEXT-MINIMIZER.md`
- **Design & UI** : `docs/DESIGN.md`
- **Exécution Zero-Trust** : `docs/EXECUTION-ZERO-TRUST.md`
- **Visualisation Vivante** : `docs/VISUALIZATION.md`
- **Apprentissage Auto-Généré** : `docs/LEARNING.md`
- **Sécurité Chirurgicale** : `docs/SECURITY.md`
- **Guide de style** : `docs/STYLE_GUIDE.md`

### Règles et contraintes
- **Configuration globale** : `config/axiom.config.yaml`
- **Caveman rules** : `config/caveman-rules.yaml` (LIRE AVANT TOUTE SORTIE)
- **IDE mapping** : `config/ide-mapping.yaml`
- **Constitution du projet** : `specs/rules/constitution.md`
- **Workflow d'orchestration** : `config/WORKFLOW.md`
- **Source of Truth** : `config/axiom/source-of-truth.yaml`
- **Contrat de visualisation** : `config/axiom/visualization-contract.yaml`

### Templates
- **Plan architectural** : `templates/plan-template.md`
- **Micro-tâche** : `templates/task-template.md`
- **Walkthrough** : `templates/walkthrough-template.md`

### Design
- **Design system** : `design/design-system.json`
- **Tokens de design** : `design/tokens/`
- **Composants** : `design/components/`

## 🧭 Workflow Axiom

### 1. Bootstrap (Première Fois)

```bash
axiom bootstrap
```

Ce script :
1. Installe toutes les dépendances (GitNexus, GraphRAG, Playwright)
2. Exécute un scan rapide du projet
3. Génère une carte des sections
4. Demande quelle section travailler

### 2. Recherche Initiale (Automatique)

L'agent lance automatiquement :
- Analyse de la section choisie (langages, frameworks)
- Recherche en ligne des meilleures bibliothèques et MCPs
- Génération de `tools/tech-stack.md` et `tools/mcp-registry.yaml`

### 3. Cycle de Travail

1. **Contexte** : Extraire le sous-graphe pertinent (GitNexus/Graphify/GraphRAG)
2. **Specs** : Écrire les spécifications dans `specs/`
3. **Plan** : Décomposer en micro-tâches (utiliser `templates/plan-template.md`)
4. **Linear** : Créer les tickets automatiquement (si activé)
5. **Design** : Générer et valider les maquettes (si UI)
6. **Implémentation** : Coder par micro-tâches (≤ 100 lignes)
7. **Tests** : Exécuter TOUS les tests
8. **Validation** : Vérifier le déterminisme
9. **Git** : Commit, push, PR (automatique selon config)
10. **Apprentissage** : Documenter les patterns découverts

## 🧠 Système de Compétences (Skills)

### Qu'est-ce qu'un skill ?

Un **skill** est une compétence spécialisée qui orchestre des scripts shell pour accomplir une tâche complexe. Au lieu d'exécuter des commandes brutes, l'agent active des skills via des déclencheurs (triggers) comme `/axiom-bootstrap` ou `/scan`.

### Comment activer un skill ?

**Méthode 1 : Déclencheur direct**
```
/axiom-bootstrap    # Initialise Axiom
/scan               # Scanne le projet
/memory             # Met à jour la mémoire
/visualize          # Génère le graphe
```

**Méthode 2 : Intention naturelle**
L'agent détecte automatiquement les intentions dans votre message :
- "initialise le projet" → active `axiom-bootstrap`
- "scanne le code" → active `axiom-scan`
- "mets à jour la mémoire" → active `axiom-memory`

### Skills disponibles

Consultez le registre complet : [skills/registry.json](../skills/registry.json)

| Skill                 | Déclencheurs           | Description                       | Script                 |
| --------------------- | ---------------------- | --------------------------------- | ---------------------- |
| **axiom-bootstrap**   | `/bootstrap`, `/init`  | Initialise Axiom sur le projet    | `bootstrap.sh`         |
| **axiom-scan**        | `/scan`, `/map`        | Scanne rapidement le projet       | `quick-scan.sh`        |
| **axiom-memory**      | `/memory`, `/index`    | Met à jour la mémoire universelle | `index-memory.sh`      |
| **axiom-visualize**   | `/visualize`, `/graph` | Régénère la visualisation         | `build-visualizer.sh`  |
| **axiom-research**    | `/research`, `/stack`  | Recherche les meilleures technos  | `stack-research.sh`    |
| **axiom-linear**      | `/linear`, `/tickets`  | Synchronise avec Linear           | `linear-sync.sh`       |
| **axiom-focus**       | `/focus`, `/auto`      | Active le mode Focus              | `focus-mode.sh`        |
| **axiom-flex**        | `/flex`                | Active le mode Flex               | `focus-mode.sh --flex` |
| **axiom-plan**        | `/plan`                | Crée un plan d'implémentation     | Template               |
| **axiom-task**        | `/task`                | Crée une micro-tâche              | Template               |
| **axiom-walkthrough** | `/walkthrough`         | Crée un walkthrough               | Template               |

### Catégories de skills

- **setup** : Installation et configuration initiale
- **analysis** : Analyse et scan du projet
- **memory** : Gestion de la mémoire et des graphes
- **visualization** : Visualisation et exploration
- **research** : Recherche automatique de technologies
- **project-management** : Gestion de projet et Linear
- **configuration** : Configuration d'Axiom
- **planning** : Planification et décomposition
- **documentation** : Documentation et guides

### Skills externes

Les skills sont des modules de compétences spécialisées chargés dynamiquement selon la tâche.

- **Registre complet** : [skills/registry.json](../skills/registry.json)
- **Répertoire local** : [skills/](../skills/)
- **Répertoire global** : `~/.axiom/skills/`

**Catégories de skills externes :**
- **Design** : web-design, design-system, huashu-review
- **Sécurité** : cybersecurity, prodsec, hack-skills
- **Architecture** : sysdesign, agentic-patterns
- **Code** : claude-code-skills, code-toolkit
- **Général** : garden-skills, ok-skills, debugging

Les skills externes sont activés automatiquement selon les mots-clés de votre tâche.

### Import de skills externes
```bash
# Importer un skill depuis GitHub
./scripts/import-skills.sh https://github.com/user/skill-repo.git
```

### Créer un skill personnalisé

1. Créez un fichier dans `skills/custom/mon-skill.md`
2. Ajoutez le frontmatter YAML :
```yaml
---
id: mon-skill
triggers: ["mon-trigger", "alias"]
description: "Description du skill"
mode: both  # both, flex, ou focus
category: custom
---
```
3. Décrivez les étapes en Markdown
4. Enregistrez-le dans `skills/registry.json`

## 🚀 Commandes Essentielles

## 🚀 Commandes essentielles

### Installation et configuration
```bash
# Installation globale (une seule fois par machine)
script/bootstrap.sh

# Initialisation d'un nouveau projet
script/setup.sh

# Démarrer une expérience d'auto-optimisation
script/start-experiment.sh <nom> [type]
```

### Développement
```bash
# Tests
npm test                    # Tests unitaires
npm run test:watch         # Tests en mode watch
npm run test:coverage      # Couverture de code

# Linting et formatage
npm run lint               # Vérification du code
npm run lint:fix           # Correction automatique
npm run format             # Formatage avec Prettier

# Build
npm run build              # Construction du projet
npm run build:watch        # Build en mode watch
```

### Vérification et sécurité
```bash
# Audit de sécurité
npm audit                  # Audit des dépendances
npm audit fix              # Correction automatique

# Validation des spécifications
npm run validate:specs     # Valider OpenAPI, ADR, skills

# Tests de mutation
npm run test:mutation      # Tests avec Stryker

# Tests end-to-end
npm run test:e2e           # Tests Playwright
npm run test:e2e:headed    # Tests avec interface
```

### Outils Axiom
```bash
# GitNexus (graphe de connaissances)
npx gitnexus analyze       # Analyse du dépôt
npx gitnexus wiki          # Génération du wiki
npx gitnexus query "..."   # Requête sur le graphe

# Mémoire
./scripts/index-memory.sh  # Indexer la mémoire

# Spécifications & Skills
npm run validate:specs     # Valider les specs
./scripts/import-skills.sh <url>  # Importer un skill

# Minimiseur de contexte
node scripts/context-test.js <symbol> [keywords...]  # Tester le minimiseur

# Design
./scripts/design-pipeline.sh --framework react --style modern --screen <nom>  # Pipeline complet
node scripts/select-library.js --framework react --style modern  # Sélection de bibliothèque
node scripts/validate-colors.js design/screens/<nom>.html  # Validation des couleurs

# Exécution Zero-Trust (Couche 5)
./scripts/decompose-feature.sh features/<nom>.yaml  # Décomposer une feature
./scripts/execute-task.sh features/<feature-id>/tasks/<task-id>.yaml  # Exécuter une micro-tâche
./scripts/validate-code.sh agent-workspaces/<task-id>  # Valider manuellement

# Visualisation (Couche 6)
./scripts/build-visualizer.sh  # Générer graph.html
open graph.html                # Ouvrir le visualiseur

# Apprentissage (Couche 7)
./scripts/learn.sh learning/events  # Analyser les événements
ls -lh skills/generated/            # Voir les skills générés
cat learning/reports/$(ls -t learning/reports/ | head -1)  # Dernier rapport

# Sécurité (Couche 8)
./scripts/security-scan.sh          # Scan de sécurité complet
npm audit --audit-level=high        # Audit des dépendances npm
pip-audit                           # Audit des dépendances Python
detect-secrets scan --baseline .secrets.baseline  # Détection de secrets
semgrep --config=p/owasp-top-ten .  # Analyse statique SAST
ls -lh security/reports/            # Voir les rapports de sécurité

# Hooks
script/after-agent.sh      # Post-traitement
script/on-error.sh         # Gestion d'erreur
```

## 📊 Métriques de qualité

### Seuils minimaux
- **Couverture de tests** : ≥ 80%
- **Score de mutation** : ≥ 70%
- **Complexité cyclomatique** : ≤ 10 par fonction
- **Taille des fichiers** : ≤ 300 lignes (sauf exceptions documentées)

### Vérifications automatiques
- ✅ Tests unitaires (Jest/Pytest)
- ✅ Linting (ESLint/Pylint)
- ✅ Formatage (Prettier/Black)
- ✅ Audit de sécurité (npm audit/safety)
- ✅ Tests de mutation (Stryker)
- ✅ Tests E2E (Playwright)

## 🔒 Sécurité

### Règles de sécurité
- **Jamais de secrets** dans le code ou les commits
- **Validation des entrées** systématique
- **Principe du moindre privilège** pour les accès
- **Audit régulier** des dépendances
- **Zero-Trust** : ne jamais faire confiance, toujours vérifier

### Politiques de sécurité
- **OWASP Top 10 Web** : `security/policies/owasp-top10-web.md`
- **OWASP API Security** : `security/policies/owasp-api-security.md`
- **OWASP Mobile Top 10** : `security/policies/owasp-top10-mobile.md`
- **OWASP Agentic AI Top 10** : `security/policies/owasp-agentic-top10.md`
- **MASVS Android** : `security/policies/masvs-android.md`
- **Windows Hardening** : `security/policies/windows-hardening.md`

### Outils de sécurité
- **SAST** : Semgrep (analyse statique)
- **SCA** : npm audit, pip-audit (scan des dépendances)
- **Secrets** : detect-secrets (détection de secrets)
- **DAST** : Strix, Pathfinder-AI (tests dynamiques)
- **MCP Shield** : Proxy de sécurité pour les outils MCP
- **Agent Governance** : Protection des agents IA

### Skills de sécurité
- **API Security** : `security/skills/api-security.md`
- **Web Security** : `security/skills/web-security.md` (à venir)
- **Mobile Security** : `security/skills/mobile-security.md` (à venir)
- **Cloud Security** : `security/skills/cloud-security.md` (à venir)
- **Agent Security** : `security/skills/agent-security.md` (à venir)

## 📝 Documentation

### Où documenter
- **Code** : commentaires JSDoc/docstrings
- **Architecture** : diagrammes dans `docs/`
- **API** : spécifications OpenAPI dans `specs/technical/api-contracts/`
- **Décisions** : ADR (Architecture Decision Records) dans `specs/architecture/decisions/`
- **Règles** : Constitution et standards dans `specs/rules/`
- **Métier** : Glossaire dans `specs/domain/`

### Format de documentation
- Utilise Markdown pour toute documentation
- Inclus des exemples de code
- Ajoute des diagrammes (Mermaid, PlantUML)
- Maintiens un changelog (CHANGELOG.md)

## 🎯 Résolution de problèmes

### En cas d'erreur
1. Consulte  les logs dans `logs/`
2. Vérifie le fichier d'erreur généré par `on-error.sh`
3. Consulte la documentation dans `docs/`
4. Cherche dans le graphe de connaissances (GitNexus)

### Ressources d'aide
- **Issues** : consulte les issues fermées similaires
- **Wiki** : généré automatiquement par GitNexus
- **Skills** : active un skill spécialisé si nécessaire

---

**Version** : 1.0.0  
**Dernière mise à jour** : 2026-05-07  
**Maintenu par** : Axiom-Scaffold Team
