# Couche 5 : Exécution Zero-Trust

## 1. Introduction

La Couche 5 d'**Axiom-Scaffold** est le **cœur battant** du système. Elle prend le relais après la phase de conception pour transformer une fonctionnalité en code fiable, testé et validé. Elle ne fait **jamais confiance au modèle** : chaque micro-tâche est isolée, exécutée, puis soumise à un **pipeline de validation déterministe** qui couvre la compilation, le linting, les tests unitaires, les tests de mutation, la sécurité et la non-régression visuelle. Seul le code qui passe **toutes** les étapes est fusionné dans la branche principale.

C'est ici que la promesse d'Axiom-Scaffold se réalise : un petit modèle de langage (3–7 milliards de paramètres), guidé par un échafaudage rigide, devient aussi fiable qu'un modèle 100 fois plus gros.

---

## 2. Objectifs Détaillés

1. **Décomposer** une fonctionnalité en micro-tâches atomiques (≤ 100 lignes de code, ≤ 500 tokens de contexte).
2. **Isoler** chaque micro-tâche dans un environnement temporaire (bac à sable) pour éviter toute corruption du code source principal.
3. **Générer** le code via un petit LLM, à partir d'un prompt minimal (fourni par la Couche 3).
4. **Valider** automatiquement chaque micro-tâche par un pipeline en six étapes : compilation, linting, tests unitaires, tests de mutation, scan de sécurité, tests de régression visuelle.
5. **Corriger** de manière ciblée en cas d'échec (maximum 3 tentatives), puis escalader à un humain si l'erreur persiste.
6. **Fusionner** immédiatement le code validé, en commitant avec un message traçant la micro-tâche.
7. **Mettre à jour** la mémoire du projet (ré-indexation GitNexus) et la visualisation (Couche 6) après chaque fusion.
8. **Apprendre** des patterns de succès ou d'échec pour enrichir la Couche 7.

---

## 3. Architecture

La Couche 5 s'articule autour de deux éléments centraux : un **orchestrateur de fonctionnalité** et un **exécuteur de micro-tâche**.

```
┌─────────────────────────────────────────────────────────────────┐
│                   COUCHE 5 – EXÉCUTION ZERO-TRUST               │
│                                                                  │
│  feature.yaml   ──→ Orchestrateur (decompose.sh)                │
│                          │                                       │
│                          ├→ task-001.yaml                       │
│                          ├→ task-002.yaml                       │
│                          └→ ...                                 │
│                                                                  │
│  Pour chaque task-XXX.yaml :                                    │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ Exécuteur de micro-tâche (execute-task.sh)               │ │
│  │                                                           │ │
│  │ 1. PRÉPARATION (workspace isolé, prompt)                 │ │
│  │ 2. GÉNÉRATION (appel au LLM avec le prompt minimal)      │ │
│  │ 3. VALIDATION (pipeline en 6 étapes)                     │ │
│  │ 4. CORRECTION (si échec, max 3 tentatives)               │ │
│  │ 5. FUSION (commit + merge dans la branche principale)    │ │
│  │ 6. RÉ-INDEXATION (GitNexus)                              │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

Tous les échanges se font via des fichiers **YAML** et des scripts **shell**, pour rester légers, sans dépendance lourde.

---

## 4. Arborescence

```
racine-du-projet/
├── features/
│   └── paiement-stripe/
│       ├── feature.yaml                # Description globale de la fonctionnalité
│       └── tasks/
│           ├── task-001.yaml
│           ├── task-002.yaml
│           └── ...
├── scripts/
│   ├── decompose-feature.sh            # Découpe une feature en micro-tâches YAML
│   ├── execute-task.sh                 # Exécute une micro-tâche (cœur de la couche)
│   └── validate-code.sh               # Pipeline de validation (appelé par execute-task)
├── tests/
│   ├── unit/                           # Tests unitaires (écrits avant le code)
│   ├── mutation/                       # Configuration Stryker
│   └── visual/                         # Tests de régression visuelle (Playwright)
├── .agent/
│   ├── task-template.yaml              # Template de micro-tâche
│   └── validation-pipeline.yaml        # Configuration du pipeline de validation
├── logs/
│   └── execution/                      # Logs d'exécution par tâche
└── docs/
    └── EXECUTION-ZERO-TRUST.md
```

---

## 5. Fonctionnement Détaillé

### 5.1 Décomposition d'une Fonctionnalité

Au démarrage d'une nouvelle fonctionnalité (ex : « paiement Stripe »), l'orchestrateur reçoit un fichier `feature.yaml` qui contient la description, les spécifications, le design validé (maquettes), et la liste des symboles concernés (extraits de la mémoire).

**`feature.yaml` (extrait) :**

```yaml
feature: paiement-stripe
description: |
  Implémente le flux de paiement par carte bancaire
  avec Stripe Checkout, webhook de confirmation,
  et page de succès/échec.

specs:
  - specs/technical/api-contracts/payment-api.openapi.yaml
  - specs/rules/constitution.md

design:
  screens:
    - design/screens/checkout.html
    - design/screens/success.html
    - design/screens/error.html
  design_system: design/design-system.json

target_symbols:
  - checkoutSession
  - stripeWebhook
  - paymentSuccessPage
  - paymentErrorPage
```

Le script `decompose-feature.sh` (appelé par l'humain ou par le WORKFLOW.md) analyse ce fichier, interroge la mémoire (Couche 1) pour obtenir le sous-graphe, et découpe la fonctionnalité en micro-tâches YAML.

**Règles de décomposition :**
- Chaque micro-tâche correspond à **une fonction, une classe ou un composant UI**.
- La taille maximale du fichier à créer/modifier est de **100 lignes**.
- Le contexte (prompt) ne doit pas dépasser **500 tokens**.
- Les dépendances entre micro-tâches sont explicitées pour permettre la parallélisation des tâches indépendantes.

**Exemple de micro-tâche YAML (`task-001.yaml`) :**

```yaml
task_id: task-001
feature: paiement-stripe
target_symbol: checkoutSession
description: |
  Crée la fonction checkoutSession qui appelle Stripe Checkout
  et retourne une URL de redirection.

signature: "async function checkoutSession(amount: number, currency: string): Promise<string>"

types: |
  interface StripeSessionResponse {
    url: string;
    sessionId: string;
  }

dependencies:
  - stripe-sdk
  - config/payment.ts

constraints:
  - specs/rules/constitution.md
  - specs/rules/security-policies.md

tests:
  - tests/unit/checkoutSession.test.ts
  - tests/visual/checkoutSession.spec.ts

visual_test: false
retry_count: 0
previous_errors: []
status: "pending"
```

### 5.2 Exécution d'une Micro-Tâche

Le script **`execute-task.sh`** est le véritable cœur de la Couche 5. Il prend en entrée le fichier YAML de la micro-tâche et suit les étapes suivantes.

#### Étape 1 – Préparation du Workspace

- Crée un répertoire temporaire `agent-workspaces/task-001/`.
- Clone le dépôt principal dans ce répertoire (ou utilise un `git worktree`).
- Copie les fichiers de la micro-tâche et les contraintes.

#### Étape 2 – Génération du Prompt

- Appelle le minimiseur de contexte (Couche 3) avec la micro-tâche.
- Le minimiseur lit `graph/super-graph.json`, la constitution, le registre de skills, et produit un prompt ≤ 500 tokens.
- Ce prompt est enregistré dans `task-001-prompt.md` pour traçabilité.

#### Étape 3 – Appel au LLM

- Le prompt est envoyé au petit LLM (via CLI ou API).
- Le code généré est écrit dans le fichier source correspondant (ex : `src/payment/checkoutSession.ts`).

#### Étape 4 – Pipeline de Validation

Le script `validate-code.sh` exécute séquentiellement **six étapes**. La première qui échoue arrête le pipeline et déclenche la correction.

1. **Compilation** (`tsc --noEmit` ou équivalent selon le langage)  
   → Échec si erreur de type ou import manquant.

2. **Linting** (`eslint --max-warnings 0` ou `pylint`)  
   → Échec si violation des conventions (ex : `any` interdit, `console.log`).

3. **Tests unitaires** (`jest --coverage` ou `pytest --cov`)  
   → Échec si la couverture < 100 % (branches, fonctions, lignes) ou si un test ne passe pas.

4. **Tests de mutation** (`stryker run` ou `mutmut`)  
   → Échec si le score de mutation < 100 % (tous les mutants doivent être tués).

5. **Scan de sécurité**  
   - `npm audit --audit-level=high` ou `pip-audit`  
   - Détection de secrets (outil `detect-secrets` ou `git-secrets`)  
   - Vérification des en-têtes de sécurité si le code est une API.

6. **Tests de régression visuelle** (si la tâche implique une UI)  
   - Utilise **Playwright** pour capturer une capture d'écran de la page.  
   - Compare avec la maquette de référence (stockée dans `design/screens/`).  
   - Utilise **Pretext** pour mesurer les blocs de texte sans DOM et vérifier les débordements, 500× plus vite.  
   - Échec si différence visuelle > seuil (ex : 1 % de pixels différents) ou si un texte déborde.

#### Étape 5 – Correction (si échec)

- Le message d'erreur de l'étape échouée est capturé et **formaté** (pas de stack trace brute).
- Le minimiseur (Couche 3) construit un **prompt de correction** ultra-ciblé : uniquement l'erreur, le code actuel de la fonction, et les contraintes.
- Le LLM reçoit ce prompt et propose une correction.
- Le pipeline de validation est relancé.
- Maximum **3 tentatives**. Si après 3 tentatives la validation échoue encore, la tâche est **escaladée** à un humain (ticket Linear mis à jour avec les logs).

#### Étape 6 – Fusion (si succès)

- Dans le workspace temporaire, le fichier modifié est commité avec un message standardisé : `feat(paiement-stripe): implémente checkoutSession (task-001)`.
- Le commit est poussé vers une branche temporaire, puis une Pull Request est créée.
- La CI (GitHub Actions) relance une dernière fois le pipeline complet.
- Si tout passe, la PR est fusionnée automatiquement (merge).

#### Étape 7 – Ré-indexation et Nettoyage

- Le script appelle `npx gitnexus analyze` pour mettre à jour le super-graphe (Couche 1).
- Le workspace temporaire est supprimé.
- Les logs de succès sont transmis à la Couche 7 (Apprentissage).

---

## 6. Intégration avec les Autres Couches

- **Couche 0 (Harnais)** : `WORKFLOW.md` déclenche l'orchestrateur de fonctionnalité. Les hooks `after-agent.sh` appellent `scripts/decompose-feature.sh`.
- **Couche -1 (Auto-optimisation)** : avant l'exécution, une boucle d'optimisation peut être lancée en parallèle sur une fonction critique.
- **Couche 1 (Mémoire)** : le super-graphe est consulté pour extraire les dépendances ; il est mis à jour après chaque fusion.
- **Couche 2 (Spécifications)** : la constitution et les skills sont chargés comme contraintes ; le registre de skills guide les corrections.
- **Couche 3 (Minimiseur)** : chaque micro-tâche est convertie en prompt minimal ; les corrections sont ciblées.
- **Couche 4 (Design)** : les maquettes servent de référence pour les tests de régression visuelle.
- **Couche 6 (Visualisation)** : le graphe `graph.html` est régénéré après la mise à jour de la mémoire.
- **Couche 7 (Apprentissage)** : les succès et échecs sont capturés pour générer des skills.
- **Couche 8 (Sécurité)** : le pipeline de validation inclut un scan de sécurité (dépendances, secrets, en-têtes).

---

## 7. Utilisation

### 7.1 Décomposer une Fonctionnalité

```bash
# Créer un fichier feature.yaml
cp features/example-feature.yaml features/ma-feature/feature.yaml

# Éditer le fichier avec les symboles cibles
nano features/ma-feature/feature.yaml

# Décomposer en micro-tâches
./scripts/decompose-feature.sh features/ma-feature/feature.yaml
```

**Sortie** :
```
📋 Analyse de la fonctionnalité : ma-feature
✓ Fonctionnalité: ma-feature
ℹ Description: ...
ℹ Création des micro-tâches...
ℹ   Création de task-001 pour checkoutSession...
✓   Créé features/ma-feature/tasks/task-001.yaml
...
✅ Décomposition terminée
ℹ  Micro-tâches créées: 4
```

### 7.2 Exécuter une Micro-Tâche

```bash
# Exécuter la première tâche
./scripts/execute-task.sh features/ma-feature/tasks/task-001.yaml
```

**Sortie** :
```
═══════════════════════════════════════════════════════════
  AXIOM-SCAFFOLD — EXÉCUTION ZERO-TRUST
═══════════════════════════════════════════════════════════
ℹ  Tâche: task-001
ℹ  Feature: ma-feature
ℹ  Symbole: checkoutSession
═══════════════════════════════════════════════════════════

📦 Étape 1/7: Préparation du workspace
✓  Workspace prêt: agent-workspaces/task-001

📝 Étape 2/7: Génération du prompt minimal
✓  Prompt généré: prompt-20260508-103000.md

───────────────────────────────────────────────────────────
🎯 Tentative 1/3
───────────────────────────────────────────────────────────

🤖 Étape 3/7: Génération du code (LLM)
⚠  Placeholder: Appel au LLM à implémenter
...

🔍 Étape 4/7: Validation Zero-Trust
═══════════════════════════════════════════════════════════
  PIPELINE DE VALIDATION ZERO-TRUST
═══════════════════════════════════════════════════════════

🔨 Étape 1/6: Compilation
    ✅ Compilation

📏 Étape 2/6: Linting
    ✅ Linting

🧪 Étape 3/6: Tests unitaires (couverture 100%)
    ✅ Tests unitaires (100%)

🧬 Étape 4/6: Tests de mutation (score 100%)
    ✅ Tests de mutation (100%)

🔒 Étape 5/6: Scan de sécurité
    ✅ Sécurité

👁  Étape 6/6: Tests de régression visuelle
    ℹ  Tests visuels non requis pour cette tâche

═══════════════════════════════════════════════════════════
  ✅ TOUTES LES VALIDATIONS ONT RÉUSSI
═══════════════════════════════════════════════════════════

✅ Validation réussie !

🔀 Étape 5/7: Fusion du code
✓  Commit créé: feat(ma-feature): implémente checkoutSession (task-001)
✓  Branche poussée: auto-task-001-20260508-103000
✓  Pull Request créée
✓  Fusion programmée

🔄 Étape 6/7: Ré-indexation de la mémoire
✓  Mémoire mise à jour

🧹 Étape 7/7: Nettoyage
✓  Workspace nettoyé

═══════════════════════════════════════════════════════════
  ✅ SUCCÈS : task-001 fusionné avec succès
═══════════════════════════════════════════════════════════
```

---

## 8. Pipeline de Validation

### 8.1 Étapes

Le pipeline de validation est **déterministe** et **strict**. Chaque étape doit passer pour que le code soit fusionné.

| Étape                      | Outil                           | Seuil           | Échec si                         |
| :------------------------- | :------------------------------ | :-------------- | :------------------------------- |
| **1. Compilation**         | `tsc --noEmit`                  | 0 erreur        | Erreur TypeScript                |
| **2. Linting**             | `eslint --max-warnings 0`       | 0 warning       | Violation de convention          |
| **3. Tests unitaires**     | `jest --coverage`               | 100%            | Couverture < 100% ou test échoué |
| **4. Tests de mutation**   | `stryker run`                   | 100%            | Mutant survivant                 |
| **5. Sécurité**            | `npm audit` + détection secrets | 0 vulnérabilité | Vulnérabilité ou secret détecté  |
| **6. Régression visuelle** | `playwright test`               | < 1% diff       | Différence visuelle > 1%         |

### 8.2 Configuration

Le fichier `.agent/validation-pipeline.yaml` configure le pipeline :

```yaml
pipeline:
  steps:
    - order: 1
      name: "compilation"
      command: "tsc --noEmit"
      required: true
      timeout: 30
    
    - order: 2
      name: "linting"
      command: "eslint . --max-warnings 0"
      required: true
      timeout: 30
    
    # ... autres étapes

thresholds:
  coverage:
    branches: 100
    functions: 100
    lines: 100
    statements: 100
  
  mutation:
    score: 100
  
  security:
    max_vulnerabilities: 0
```

---

## 9. Correction et Escalade

### 9.1 Correction Automatique

En cas d'échec de validation, le système tente une correction automatique :

1. **Capture de l'erreur** : Le message d'erreur est extrait et formaté
2. **Prompt de correction** : Le minimiseur génère un prompt ciblé avec l'erreur
3. **Nouvelle tentative** : Le LLM propose une correction
4. **Re-validation** : Le pipeline est relancé

Maximum **3 tentatives** par micro-tâche.

### 9.2 Escalade Humaine

Après 3 échecs, la tâche est **escaladée** :

1. **Statut** : `status: "escalated"` dans le fichier task.yaml
2. **Logs** : Tous les logs sont sauvegardés dans `logs/execution/<task_id>/`
3. **Notification** : Ticket créé (Linear, GitHub Issues, Slack)
4. **Rapport** : Rapport d'escalade avec toutes les tentatives

**Format du rapport** :
```
🚨 Escalade requise pour la tâche task-001

Symbole: checkoutSession
Feature: paiement-stripe
Tentatives: 3/3

Dernière erreur:
TypeError: Cannot read property 'amount' of undefined

Logs complets: logs/execution/task-001/
```

---

## 10. Traçabilité

Tous les échanges sont tracés pour permettre l'audit et l'apprentissage :

### 10.1 Logs Sauvegardés

```
logs/execution/task-001/
├── worktree.log                    # Création du workspace
├── minimizer.log                   # Génération du prompt
├── validation-attempt-1.log        # Première tentative de validation
├── error-attempt-1.txt             # Erreur de la première tentative
├── minimizer-correction-1.log      # Prompt de correction
├── validation-attempt-2.log        # Deuxième tentative
├── commit.log                      # Commit Git
├── push.log                        # Push vers la branche
├── pr-create.log                   # Création de la PR
├── pr-merge.log                    # Fusion de la PR
└── reindex.log                     # Ré-indexation de la mémoire
```

### 10.2 Prompts Sauvegardés

```
agent-workspaces/task-001/
├── prompt-20260508-103000.md       # Prompt initial
├── prompt-correction-1-20260508-103000.md  # Prompt de correction 1
└── prompt-correction-2-20260508-103000.md  # Prompt de correction 2
```

---

## 11. Principe Fondamental

> **Zero-Trust : Ne jamais faire confiance au modèle.**

Chaque ligne de code générée par le LLM est **validée** par un pipeline déterministe. Seul le code qui passe **toutes** les étapes est fusionné.

Ce principe garantit que :
- ✅ Le code compile sans erreur
- ✅ Le code respecte les conventions
- ✅ Le code est testé à 100%
- ✅ Le code résiste aux mutations
- ✅ Le code est sécurisé
- ✅ Le code ne régresse pas visuellement

**Résultat** : Un petit modèle (3-7B) devient aussi fiable qu'un modèle 100× plus gros.

---

## 12. Commandes Utiles

```bash
# Décomposer une feature
./scripts/decompose-feature.sh features/ma-feature/feature.yaml

# Exécuter une tâche
./scripts/execute-task.sh features/ma-feature/tasks/task-001.yaml

# Valider manuellement
./scripts/validate-code.sh task.yaml

# Voir les logs
cat logs/execution/task-001/validation-attempt-1.log

# Voir le prompt
cat agent-workspaces/task-001/prompt-20260508-103000.md
```

---

**Version** : 1.0.0  
**Dernière mise à jour** : 2026-05-08  
**Auteur** : Axiom-Scaffold Team
