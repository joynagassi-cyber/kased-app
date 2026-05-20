# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/lang/fr/).

## [Non publié]

### Ajouté

- **Axiom Installer — Interactive Setup** (2026-05-09)
  - **Base**: Cloned from antfu/skills-npm
  - **Package** (1 fichier)
    - `package.json`: name=`axiom-scaffold-installer`, bins=`axiom-scaffold`+`axiom-install`, keywords=axiom+scaffold+skills
  - **Branding** (2 fichiers)
    - `src/constants.ts`: Axiom ASCII logo (6 lines), blue-green gradient colors (#39→#29), gitignore pattern=`Axiom-scaffold/skills/npm-*`
    - `src/cli.ts`: Axiom messages ("🔍 Scanning for Axiom skills", "🎯 Select AI coding tools", "🏗️  Install X Axiom skills")
  - **Documentation** (1 fichier)
    - `README.md`: Installation (global, npx, local), usage (interactive, CLI options), supported tools (24+), Axiom skills list, configuration, examples
  - **Fonctionnalités**
    - Auto-détection des outils IA (Claude Code, Cursor, Windsurf, Kiro, etc.)
    - Interface interactive (TUI avec clack/prompts)
    - Scan des packages npm pour skills Axiom
    - Création de symlinks vers répertoires des outils
    - Nettoyage des skills obsolètes
    - Mise à jour .gitignore automatique
    - Logo Axiom ASCII art avec dégradé bleu-vert
    - Messages personnalisés Axiom
  - **Commandes**
    - `axiom-scaffold` ou `axiom-install`: Mode interactif
    - `--agents <list>`: Spécifier les outils cibles
    - `--yes`: Skip confirmation
    - `--dry-run`: Simulation
    - `--force`: Forcer le reload
    - `--cleanup`: Nettoyer les skills obsolètes (défaut: true)
  - **Workflow**
    1. Scan node_modules pour skills Axiom
    2. Détection des outils IA installés
    3. Sélection interactive (ou --agents)
    4. Confirmation (ou --yes)
    5. Création symlinks
    6. Nettoyage skills obsolètes
    7. Mise à jour .gitignore
  - **Skills Axiom**
    - axiom-bootstrap: Initialiser Axiom
    - axiom-memory: Mettre à jour mémoire universelle
    - axiom-visualize: Générer graphe interactif
    - axiom-linear: Sync avec Linear
    - axiom-research: Recherche auto de technos
    - caveman-mode: Compression tokens (65-75%)

- **Système Caveman — Compression Maximale** (2026-05-09)
  - **Configuration YAML** (2 fichiers)
    - `config/caveman-rules.yaml` : Règles de compression (4 niveaux, règles par type de sortie, invariants, persistence)
    - `config/ide-mapping.yaml` : Cartographie de 24 IDE/CLI (Claude Code, Codex, Gemini, Cursor, Windsurf, Cline, Copilot, Kiro, etc.)
  - **Scripts** (2 fichiers)
    - `scripts/detect-ide.sh` : Détection automatique de l'IDE/CLI actif (bash)
    - `scripts/validate-caveman-config.js` : Validation de la configuration YAML (Node.js)
  - **Skill Caveman** (1 fichier)
    - `skills/built-in/caveman-mode.md` : Skill d'activation du mode Caveman (triggers: caveman, compact, ultra, lite, wenyan)
  - **Mise à Jour Skills Registry** (1 fichier)
    - `skills/registry.json` : Ajout du skill caveman-mode, catégorie "communication"
  - **Mise à Jour Constitution** (1 fichier)
    - `specs/rules/constitution.md` : Section "Communication Caveman (obligatoire)" ajoutée avec principes, règles, invariants, niveaux, commandes, exemples
  - **Mise à Jour AGENTS.md** (déjà présent)
    - `config/AGENTS.md` : Directive Caveman déjà présente dans la section navigation
  - **Mise à Jour package.json** (1 fichier)
    - Scripts npm : `caveman:detect`, `caveman:validate`
  - **Exemples de Rapports** (3 fichiers)
    - `reports/authentication/walkthrough.md` : Exemple en mode caveman full (8 étapes)
    - `reports/authentication/tasks.md` : Exemple en mode caveman ultra (8 tâches, 1 ligne chacune)
    - `reports/authentication/plan.md` : Exemple en mode caveman full (Goal, Files, Deps, Tests)
  - **Rapports de Complétion** (2 fichiers)
    - `reports/CAVEMAN_IMPLEMENTATION_COMPLETE.md` : Rapport détaillé de l'implémentation
    - `reports/CAVEMAN_SUMMARY.md` : Résumé en format caveman full
  - **Fonctionnalités**
    - 4 niveaux de compression : lite (professionnel), full (fragments, défaut), ultra (télégraphique), wenyan (chinois classique)
    - Règles par type de sortie : chat (≤6 lignes), docs (≤15 lignes/section), walkthrough (≤8 étapes), task (ultra), plan (≤25 lignes), commit (≤72 chars), code review
    - Invariants (jamais compressés) : code blocks, error messages, technical terms, security warnings, irreversible actions
    - Désactivation automatique : alertes sécurité, actions destructives
    - Persistance : actif pour toutes les réponses jusqu'à "stop caveman" ou "normal mode"
    - Économie de tokens : 65-75% sur sorties chat/docs/tasks, ~46% sur entrées (avec caveman-compress)
    - Support de 24 IDE/CLI : détection automatique et adaptation de la configuration
    - Structure de sortie : `Axiom-scaffold/reports/{feature}/` avec sous-dossiers (walkthroughs, tasks, plans, reviews)
    - Anti-patterns définis : pas de politesse, pas de remplissage, pas d'explication verbeuse
    - Validation automatique : script Node.js vérifie YAML structure, sections, niveaux, règles
  - **Commandes**
    - `/caveman lite` : Mode professionnel (garde articles et phrases complètes)
    - `/caveman full` : Mode par défaut (fragments, sans articles)
    - `/caveman ultra` : Mode télégraphique (abréviations, flèches)
    - `stop caveman` ou `normal mode` : Désactiver le mode caveman
- **Système de Compétences (Skills) — v2.0**
  - **Skills Intégrés** (11 fichiers)
    - `skills/built-in/bootstrap.md` : Initialisation complète d'Axiom
    - `skills/built-in/quick-scan.md` : Scan rapide du projet
    - `skills/built-in/memory-update.md` : Mise à jour de la mémoire universelle
    - `skills/built-in/visualization-update.md` : Régénération du graphe
    - `skills/built-in/stack-research.md` : Recherche automatique de technologies
    - `skills/built-in/linear-sync.md` : Synchronisation avec Linear
    - `skills/built-in/focus-mode.md` : Activation du mode Focus
    - `skills/built-in/flex-mode.md` : Activation du mode Flex
    - `skills/built-in/plan-template.md` : Création de plans d'implémentation
    - `skills/built-in/task-template.md` : Création de micro-tâches
    - `skills/built-in/walkthrough-template.md` : Création de walkthroughs
  - **Scripts Shell** (3 nouveaux fichiers)
    - `scripts/linear-sync.sh` : Synchronisation Linear (extraction tâches, API GraphQL)
    - `scripts/git-automation.sh` : Automatisation Git (commit, push, PR)
    - `scripts/focus-mode.sh` : Bascule entre modes Focus et Flex
  - **Registre et Documentation** (3 fichiers)
    - `skills/registry.json` : Catalogue complet des skills (11 skills, 40+ déclencheurs)
    - `docs/SKILLS-SYSTEM.md` : Documentation exhaustive (800+ lignes)
    - `reports/SKILLS_SYSTEM_COMPLETE.md` : Rapport de complétion
  - **Mise à Jour**
    - `config/AGENTS.md` : Section complète sur le système de skills
  - **Fonctionnalités**
    - Activation par déclencheurs (`/axiom-bootstrap`, `/scan`, `/memory`, etc.)
    - Activation par intention naturelle (détection automatique)
    - 9 catégories de skills (setup, analysis, memory, visualization, etc.)
    - Économie de ~80% de tokens (orchestration vs commandes brutes)
    - Déterminisme garanti (scripts shell standardisés)
    - Extensibilité (skills personnalisés et externes)
    - Support des modes Focus et Flex
    - Import de skills externes depuis Git
- **Système de Déterminisme Complet**
  - **Contrats et Schémas** (4 fichiers)
    - `.axiom/source-of-truth.yaml` : Contrat de fusion déterministe
    - `.axiom/schema/entity-graph.schema.json` : JSON Schema du graphe unifié
    - `.axiom/visualization-contract.yaml` : Contrat de visualisation (layout, seed)
    - `.axiom/schema/` : Dossier pour les schémas
  - **Scripts de Fusion et Layout** (3 fichiers)
    - `scripts/fuse-graph-deterministic.js` : Fusion déterministe GitNexus + Graphify + GraphRAG
    - `scripts/build-layout.js` : Génération de layout avec seed fixe (42)
    - `scripts/verify-determinism.sh` : Vérification automatique du déterminisme
  - **Documentation** (1 fichier)
    - `docs/DETERMINISM.md` : Documentation complète (3000+ mots)
    - `DETERMINISM_IMPLEMENTATION_COMPLETE.md` : Rapport de complétion
  - **Fonctionnalités**
    - Fusion déterministe avec priorités (structure > semantics > documentation)
    - Résolution automatique des conflits selon les règles
    - Validation contre JSON Schema
    - Calcul de hash SHA256 (clés triées, pas de timestamps)
    - Layout avec seed fixe pour reproductibilité
    - Vérification automatique du déterminisme
    - Commandes npm : memory:index, memory:verify, graph:fuse, graph:layout
- **GraphRAG — Graphe Documentaire (Couche 1)**
  - **Configuration GraphRAG** (3 fichiers)
    - `graphrag_data/settings.yaml` : Configuration complète (LLM, embeddings, extraction)
    - `graphrag_data/.env.example` : Template de variables d'environnement
    - `graphrag_data/README.md` : Documentation du dossier GraphRAG
  - **Scripts d'Indexation** (2 nouveaux fichiers)
    - `scripts/index-doc-graph.sh` : Indexation documentaire avec GraphRAG
    - `scripts/export-graphrag.py` : Export Parquet → JSON
  - **Scripts Mis à Jour** (2 fichiers)
    - `scripts/fuse-graphs.js` : Fusion GitNexus + Graphify + GraphRAG
    - `scripts/index-memory.sh` : Pipeline complet incluant GraphRAG
  - **Documentation** (4 fichiers)
    - `docs/MEMORY.md` : Section GraphRAG complète (2000+ mots)
    - `docs/payment-guidelines.md` : Document d'exemple pour tester GraphRAG
    - `QUICK_START_GRAPHRAG.md` : Guide de démarrage rapide
    - `GRAPHRAG_IMPLEMENTATION_COMPLETE.md` : Rapport de complétion
  - **Fonctionnalités**
    - Extraction automatique d'entités métier (organizations, policies, rules, modules, APIs)
    - Extraction de relations typées (REQUIRES, IMPLEMENTS, DEPENDS_ON, etc.)
    - Détection de communautés avec algorithme de Leiden
    - Génération de résumés hiérarchiques
    - Liaison automatique entité-code via heuristiques
    - Export multi-format (Parquet, JSON, GraphML)
- **Documentation de Tests et Validation**
  - `TESTING_VALIDATION_PLAN.md` : Plan complet de tests (24 tests, 4 phases)
  - `QUICK_START_TESTING.md` : Guide de démarrage rapide (30 minutes)
  - `SESSION_2026-05-09_TESTING_PREP.md` : Documentation de session

### Modifié
- `.gitignore` : Ajout des dossiers GraphRAG temporaires
- `docs/MEMORY.md` : Architecture mise à jour (5 briques au lieu de 4)
- `scripts/fuse-graphs.js` : Intégration du graphe documentaire
- `scripts/index-memory.sh` : Pipeline étendu à 6 étapes (au lieu de 5)

## [1.9.0] - 2026-05-08

### Ajouté
- **Couche 8 — Sécurité Chirurgicale** : implémentation complète
  - **Politiques de Sécurité** (6 fichiers)
    - `security/policies/owasp-top10-web.md` : OWASP Top 10 Web
    - `security/policies/owasp-api-security.md` : OWASP API Security Top 10
    - `security/policies/owasp-top10-mobile.md` : OWASP Mobile Top 10
    - `security/policies/owasp-agentic-top10.md` : OWASP Agentic AI Top 10
    - `security/policies/masvs-android.md` : MASVS Android
    - `security/policies/windows-hardening.md` : Durcissement Windows
  - **Skills de Sécurité** (1 fichier)
    - `security/skills/api-security.md` : Skill de sécurisation d'API
  - **Outils et Configuration** (2 fichiers)
    - `security/tools/sast-config.yml` : Configuration Semgrep
    - `security/tools/secrets-patterns.yml` : Patterns de détection de secrets
  - **Monitoring** (2 fichiers)
    - `security/monitoring/threat-intel.md` : Procédure de veille
    - `security/monitoring/incident-response.md` : Procédure de réponse aux incidents
  - **Gouvernance** (2 fichiers)
    - `security/governance/mcp-shield-config.json` : Configuration MCP Shield
    - `security/governance/agent-governance-policy.yaml` : Politique de gouvernance des agents
  - **Scripts** (1 fichier)
    - `scripts/security-scan.sh` : Script de scan de sécurité complet
  - **CI/CD** (1 fichier)
    - `.github/workflows/security.yml` : Workflow de sécurité automatisé
  - **Documentation** (1 fichier)
    - `docs/SECURITY.md` : Documentation complète de sécurité

### Modifié
- Mise à jour de `package.json` vers la version 1.9.0
- Mise à jour de `STATUS.md` avec la Couche 8
- Mise à jour de `README.md` avec la description de la Couche 8
- Mise à jour de `AGENTS.md` avec les commandes de sécurité

## [1.8.0] - 2026-05-08

### Ajouté
- **Couche 7 — Apprentissage & Skills Auto-Générés** : implémentation complète
  - **Structure de Répertoires** (4 répertoires)
    - `learning/events/` : Événements bruts (YAML)
    - `learning/patterns/` : Patterns extraits (JSON)
    - `learning/reports/` : Rapports d'apprentissage
    - `skills/generated/` : Skills auto-générés
  - **Templates** (140 lignes)
    - `learning/event-template.yaml` : Template d'événement
    - `learning/events/example-cycle-001.yaml` : Exemple d'événement
  - **Scripts d'Apprentissage** (630 lignes)
    - `scripts/learn.sh` : Pipeline d'apprentissage complet
    - `scripts/generate-skill.sh` : Génération automatique de skills
  - **Documentation** (1000 lignes)
    - `docs/LEARNING.md` : Documentation complète
  - **Intégration**
    - Mise à jour de `script/after-agent.sh` pour apprentissage automatique

### Fonctionnalités
- ✅ Capture automatique des événements de développement (succès, échecs, corrections)
- ✅ Détection de patterns récurrents par similarité de keywords (≥50% communs)
- ✅ Génération automatique de skills au format canonique (≥3 occurrences)
- ✅ Mise à jour automatique du registre des skills
- ✅ Mise à jour automatique de la constitution (≥5 occurrences)
- ✅ Génération de rapports d'apprentissage (statistiques, patterns, skills)
- ✅ Extraction automatique des anti-patterns (erreurs communes)
- ✅ Détermination automatique du domaine et de la complexité
- ✅ Marquage des événements traités (.done)
- ✅ Fonctionnement asynchrone après chaque cycle

### Principe
> Ne jamais corriger deux fois la même erreur. Si un bug survient et est corrigé, le système crée une règle ou un skill pour que l'agent ne le reproduise plus jamais.

## [1.7.0] - 2026-05-08

### Ajouté
- **Couche 6 — Visualisation Vivante** : implémentation complète
  - **Templates HTML** (930 lignes)
    - `templates/g6-excalidraw-template.html` : Template G6 + Excalidraw (<10k nœuds)
    - `templates/cosmos-template.html` : Template Cosmos.gl (≥10k nœuds, GPU)
  - **Script de Génération** (180 lignes)
    - `scripts/build-visualizer.sh` : Génère graph.html à partir du super-graphe
  - **Documentation** (1000 lignes)
    - `docs/VISUALIZATION.md` : Documentation complète
  - **Intégration**
    - Mise à jour de `script/after-agent.sh` pour régénération automatique

### Fonctionnalités
- ✅ Visualisation interactive du super-graphe (nœuds, arêtes, clusters)
- ✅ Navigation (zoom, déplacement, sélection)
- ✅ Recherche de symboles avec zoom automatique
- ✅ 3 layouts (force, dagre, radial)
- ✅ Focus sur clusters avec résumés IA
- ✅ Mode flux (animation des chemins entre nœuds)
- ✅ Annotations libres avec Excalidraw
- ✅ Sauvegarde en JSON Canvas (compatible Obsidian)
- ✅ Infobulles avec métadonnées complètes
- ✅ Statistiques en temps réel (nœuds, arêtes, clusters, FPS)
- ✅ Performance GPU avec Cosmos.gl (>30 FPS pour 1M nœuds)
- ✅ Fichier HTML autonome (pas de serveur requis)
- ✅ Régénération automatique après chaque modification

### Principe
> Rendre le code visible. Une représentation visuelle claire permet de comprendre l'architecture, identifier les dépendances, et naviguer dans la complexité.

## [1.6.0] - 2026-05-08

### Ajouté
- **Couche 5 — Exécution Zero-Trust** : implémentation complète
  - **Templates et Configuration** (300 lignes)
    - `.agent/task-template.yaml` : Template pour micro-tâches
    - `.agent/validation-pipeline.yaml` : Configuration du pipeline de validation (6 étapes)
    - `features/example-feature.yaml` : Exemple de feature (paiement Stripe)
  - **Scripts d'Exécution** (1350 lignes)
    - `scripts/decompose-feature.sh` : Décomposition de features en micro-tâches
    - `scripts/execute-task.sh` : Exécuteur principal (7 étapes)
    - `scripts/validate-code.sh` : Pipeline de validation (6 étapes)
  - **Documentation** (1200 lignes)
    - `docs/EXECUTION-ZERO-TRUST.md` : Documentation complète
  - **Répertoires**
    - `agent-workspaces/` : Workspaces isolés pour exécution
    - `logs/execution/` : Logs d'exécution et validation
    - `tests/unit/`, `tests/mutation/`, `tests/visual/` : Tests

### Fonctionnalités
- ✅ Décomposition automatique de features en micro-tâches atomiques
- ✅ Génération de prompts minimaux (≤ 500 tokens) via Couche 3
- ✅ Appel au LLM pour génération de code (API configurable)
- ✅ Validation déterministe en 6 étapes :
  1. Compilation (0 erreur)
  2. Linting (0 erreur)
  3. Tests unitaires (100% du code modifié)
  4. Tests de mutation (100% des mutants tués)
  5. Scan de sécurité (0 vulnérabilité high/critical)
  6. Régression visuelle (0 différence non intentionnelle)
- ✅ Boucle de correction automatique (max 3 tentatives)
- ✅ Fusion automatique dans `main` après validation
- ✅ Ré-indexation de la mémoire (Couche 1)
- ✅ Isolation stricte (git worktree)
- ✅ Traçabilité complète (prompts, réponses, logs, erreurs)
- ✅ Escalade humaine après 3 échecs

### Principe
> Ne jamais faire confiance au modèle. Tout code généré doit passer par un pipeline de validation déterministe avant d'être accepté.

## [1.5.0] - 2026-05-08

### Ajouté
- **Couche 4 — Design & Spécifications UI** : implémentation complète
  - **Design System** (450 lignes)
    - Tokens de couleurs (6 catégories, 25 nuances)
    - Tokens de typographie (7 tailles, 4 poids, 5 line-heights)
    - Tokens d'espacement (grille de 8px, 7 niveaux)
    - Tokens d'ombres (4 niveaux)
    - Tokens d'animations (3 durées, 3 easings)
    - Métadonnées (saturation, luminance)
    - Format Style Dictionary
  - **Bibliothèques de Composants** (380 lignes)
    - 12 bibliothèques UI supportées (React, SolidJS, Framework Agnostic)
    - Métadonnées complètes (technos, style, accessibilité, strengths, weaknesses)
    - Scores (accessibility, customization, performance, documentation)
    - Index par style et techno
  - **Scripts de Design** (540 lignes)
    - `select-library.js` : Sélection automatique de bibliothèque
    - `validate-colors.js` : Validation des couleurs contre le design system
    - `design-pipeline.sh` : Pipeline complet en 5 étapes
  - **Skills de Design** (700 lignes)
    - `huashu-review.md` : Méthodologie de revue 5D
    - `README.md` : Documentation des skills de design
  - Documentation complète dans `docs/DESIGN.md` (650 lignes)

### Modifié
- **Couche 3 — Minimiseur de Contexte** : refonte complète (v2.0)
  - **SUPPRESSION** de l'approche TypeScript (Node.js, npm, compilation)
  - **NOUVELLE APPROCHE** : YAML + Shell (déclaratif, portable, sans dépendances lourdes)
  - Configuration YAML `.agent/minimizer-config.yaml` (120 lignes)
  - Script shell `scripts/minimize.sh` (280 lignes)
  - Exemple de tâche `.agent/task-example.yaml` (30 lignes)
  - Documentation refaite `docs/CONTEXT-MINIMIZER.md` (550 lignes)
  - Exemples refaits `examples/README.md` (280 lignes)
  - **Suppression** de 6 fichiers TypeScript (~1310 lignes)
  - **Ajout** de 5 fichiers YAML + Shell (~1260 lignes)
  - **Gain** : Zéro dépendance Node.js, modification sans compilation, portable

### Fonctionnalités
- ✅ Sélection automatique de bibliothèque UI selon critères
- ✅ Validation stricte des couleurs (design system)
- ✅ Pipeline automatisé (sélection, génération, validation, revue)
- ✅ Revue Huashu-Design 5D (Layout, Typographie, Couleur, Mouvement, Cohérence)
- ✅ Score minimum requis : 0.85/1.0
- ✅ Itération jusqu'à validation
- ✅ Support de 12 bibliothèques UI
- ✅ Contraintes strictes (saturation ≤70%, contraste ≥4.5:1, animations ≤300ms)
- ✅ Accessibilité prioritaire (ARIA, keyboard, screen readers)
- ✅ **Minimiseur YAML + Shell** : zéro dépendance Node.js, portable, modifiable sans compilation
- ✅ **Fallbacks intelligents** : yq optionnel, jq optionnel, grep/sed en fallback

### Principe
> Un design system strict + une revue 5D rigoureuse = des maquettes UI de haute qualité, accessibles, et maintenables.
> Un petit modèle avec 500 tokens pertinents fait moins d'erreurs qu'un gros modèle noyé dans 100 000 tokens de code.

## [1.4.0] - 2026-05-07

### Ajouté
- **Couche 3 — Minimiseur de Contexte** : implémentation complète
  - Module principal `src/minimizer.ts` (650 lignes)
    - Extraction du sous-graphe depuis la mémoire (Couche 1)
    - Récupération des contraintes depuis les specs (Couche 2)
    - Activation des skills pertinents (Couche 2)
    - Assemblage du prompt avec limite stricte de 500 tokens
    - Troncature intelligente par priorité
    - Génération de prompts de correction ciblés
  - Tests complets `tests/minimizer.test.ts` (280 lignes)
  - Configuration `.agent/minimizer-config.json`
  - Script de test `scripts/context-test.js` (180 lignes)
  - Documentation complète `docs/CONTEXT-MINIMIZER.md` (550 lignes)

### Fonctionnalités
- ✅ Prompts ultra-concis (≤ 500 tokens)
- ✅ Extraction intelligente du contexte pertinent
- ✅ Activation automatique des skills
- ✅ Application des contraintes de la constitution
- ✅ Corrections chirurgicales en cas d'erreur
- ✅ Support des petits modèles (3-7B paramètres)
- ✅ Estimation de tokens (1 token ≈ 4 caractères)
- ✅ Troncature par priorité (TÂCHE > SIGNATURE > TESTS > RÈGLES > DÉPENDANCES > SKILLS)

### Principe
> Un petit modèle avec 500 tokens pertinents fait moins d'erreurs qu'un gros modèle noyé dans 100 000 tokens de code.

## [1.3.0] - 2026-05-07

### Ajouté
- **Couche 2 — Spécifications & Compétences** : implémentation complète
  - **Pilier A — Spécifications** (7 fichiers)
    - Architecture Decision Records (ADR) avec template
    - Constitution (règles IMMUABLES)
    - Standards de code
    - Politiques de sécurité
    - Contrats d'API (OpenAPI 3.1 complet)
    - Glossaire métier
  - **Pilier B — Skills** (6 fichiers)
    - Registre central (`skills/registry.json`)
    - Format canonique avec frontmatter YAML
    - Exemple complet : `debugging.md`
    - Répertoires : general/, devops/, design/, security/
  - **Scripts de Gestion** (4 fichiers)
    - `validate-specs.js` : validation OpenAPI, ADR, frontmatter
    - `validate-specs.sh` : wrapper bash
    - `import-skills.mjs` : import de skills externes
    - `import-skills.sh` : wrapper bash
  - Documentation complète dans `docs/SPECS-AND-SKILLS.md`
  - Intégration avec `after-agent.sh` pour validation automatique
  - Mise à jour de `AGENTS.md` avec références aux specs et skills

### Fonctionnalités
- ✅ Spécifications comme source de vérité unique
- ✅ Validation automatique (OpenAPI, liens, frontmatter)
- ✅ Skills chargés dynamiquement selon mots-clés
- ✅ Constitution immuable (protection contre modifications)
- ✅ Import de skills externes depuis Git
- ✅ ADR avec frontmatter YAML et statuts
- ✅ Contrats d'API OpenAPI 3.1 validés
- ✅ Intégration avec Couches 0, 1, -1

## [1.2.0] - 2026-05-07

### Ajouté
- **Couche 1 — Mémoire Universelle** : implémentation complète
  - Script `index-memory.sh` pour orchestration de l'indexation
  - Script `fuse-graphs.js` pour fusion GitNexus + Graphify
  - Script `pinecone_upload.py` pour vectorisation vers Pinecone
  - Script `generate-obsidian-notes.js` pour génération du vault
  - Documentation complète dans `docs/MEMORY.md`
  - Répertoires `graph/`, `vault/`, `logs/`
  - Intégration avec `after-agent.sh` pour ré-indexation automatique

### Fonctionnalités
- ✅ Super-graphe unifié (structure + sémantique)
- ✅ Vectorisation Pinecone (recherche sémantique <100ms)
- ✅ Vault Obsidian (documentation pérenne)
- ✅ Fusion GitNexus + Graphify
- ✅ Interrogation hybride (structure + sémantique + visuelle)
- ✅ Clustering fonctionnel avec résumés IA
- ✅ Scores de centralité et connexions surprenantes
- ✅ Génération automatique de notes Markdown par cluster

## [1.1.0] - 2026-05-07

### Ajouté
- **Couche -1 — Auto-Optimisation Continue** : implémentation complète
  - Script `start-experiment.sh` pour démarrer des expériences
  - Pattern à trois fichiers (program.md, evaluate.py, candidate.*)
  - Support de 5 types d'optimisation : performance, ui, sql, prompt, config
  - Mécanisme de cliquet basé sur Git
  - Isolation stricte dans des workspaces temporaires
  - Documentation complète dans `docs/AUTO-OPTIMIZATION.md`
  - Intégration avec AGENTS.md et WORKFLOW.md
  - Répertoire `experiments/` pour stocker les expériences

### Fonctionnalités
- ✅ Optimisation automatique de performance (code Python)
- ✅ Optimisation d'interface utilisateur (HTML)
- ✅ Optimisation de requêtes SQL
- ✅ Optimisation de prompts IA
- ✅ Optimisation de configurations
- ✅ Timeout de sécurité (10 secondes)
- ✅ Traçabilité complète (results.tsv)
- ✅ Historique Git des améliorations

## [1.0.0] - 2026-05-07

### Ajouté
- **Couche 0 — Harness Engineering** : implémentation complète
  - Script `bootstrap.sh` pour installation globale
  - Script `setup.sh` pour initialisation de projet
  - Hooks `after-agent.sh` et `on-error.sh`
  - Fichier `AGENTS.md` : carte de navigation pour agents IA
  - Fichier `WORKFLOW.md` : contrat d'orchestration
  - Constitution du projet (`.agent/constitution.md`)
  - Templates de plan et micro-tâche
  - Registre des skills (`skills/registry.json`)
  - Configuration ESLint, Prettier, MarkdownLint
  - Hooks Git avec Husky (pre-commit)
  - Pipeline CI/CD GitHub Actions
  - Configuration Jest avec seuils de couverture
  - Configuration TypeScript
  - README complet avec documentation
  - Fichiers `.gitignore` et `.env.example`

### Principes Implémentés
- ✅ Bootable : une commande pour tout installer
- ✅ Documenté : navigation claire pour les agents
- ✅ Outillé : 12 skills disponibles
- ✅ Vérifiable : tests, linting, audit automatiques
- ✅ Contraint : hooks Git et CI/CD

### Métriques de Qualité
- Couverture de tests : ≥ 80%
- Score de mutation : ≥ 70%
- Complexité cyclomatique : ≤ 10
- Taille des fichiers : ≤ 300 lignes

---
[Non publié]: https://github.com/your-org/your-repo/compare/v1.8.0...HEAD
[1.8.0]: https://github.com/your-org/your-repo/compare/v1.7.0...v1.8.0
[1.7.0]: https://github.com/your-org/your-repo/compare/v1.6.0...v1.7.0
[1.6.0]: https://github.com/your-org/your-repo/compare/v1.5.0...v1.6.0
[1.5.0]: https://github.com/your-org/your-repo/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/your-org/your-repo/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/your-org/your-repo/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/your-org/your-repo/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/your-org/your-repo/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/your-org/your-repo/releases/tag/v1.0.0
