# Couche 3 : Minimiseur de Contexte v2.0 (YAML + Shell)

## Vue d'Ensemble

La **Couche 3** d'Axiom-Scaffold fournit un système de minimisation de contexte **déclaratif** qui transforme une micro-tâche en un prompt ultra-concis (≤ 500 tokens) pour permettre à de petits modèles de langage de produire du code de qualité.

**Nouvelle approche** : Au lieu d'un module TypeScript complexe, la Couche 3 utilise maintenant :
- **YAML** pour la configuration (déclaratif, lisible, modifiable sans compilation)
- **Shell script** pour l'exécution (minimal, portable, sans dépendances lourdes)
- **Aucune dépendance Node.js** (fonctionne avec bash, yq optionnel, jq optionnel)

---

## Pourquoi YAML + Shell ?

### Problèmes de l'Approche TypeScript

| Aspect                     | TypeScript                        | YAML + Shell                           |
| :------------------------- | :-------------------------------- | :------------------------------------- |
| **Dépendances**            | Node.js, npm, TypeScript, modules | Bash, yq (optionnel), jq (optionnel)   |
| **Installation**           | `npm install` obligatoire         | Rien à installer (outils standard)     |
| **Modification**           | Il faut recompiler                | On édite le YAML                       |
| **Portabilité**            | Lié à l'écosystème Node.js        | Fonctionne partout (Linux, macOS, WSL) |
| **Compréhension par l'IA** | Difficile (code)                  | Triviale (déclaratif)                  |
| **Correction rapide**      | Nécessite un IDE                  | Un simple éditeur de texte suffit      |

### Avantages de YAML

- **Lisible par l'humain et par la machine**
- **Aucune dépendance lourde** : parser YAML intégré à Python, disponible en shell via `yq`, ou interprétable par le LLM
- **Déclaratif** : on décrit les règles, pas l'algorithme
- **Multi-langage** : le même fichier YAML peut être consommé par Python, Node.js, ou directement par l'agent IA

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│              MINIMISEUR DE CONTEXTE (YAML-driven)               │
│                                                                  │
│  minimizer-config.yaml        ← Configuration déclarative       │
│  minimize.sh                  ← Script shell (parse YAML,       │
│                                  assemble le prompt)             │
│                                                                  │
│  Entrée : MicroTâche (targetSymbol, description, testErrors)    │
│  Sortie : Prompt final (≤ 500 tokens)                           │
└─────────────────────────────────────────────────────────────────┘
```

### Composants

1. **`.agent/minimizer-config.yaml`** (Configuration)
   - Limites (tokens max, profondeur du graphe)
   - Sources de données (mémoire, specs, skills)
   - Format du prompt (sections, ordre)
   - Règles d'extraction
   - Règles de troncature

2. **`scripts/minimize.sh`** (Exécuteur)
   - Parse le YAML (avec yq ou fallback grep/sed)
   - Extrait les données de la tâche
   - Interroge la mémoire (jq sur super-graph.json)
   - Extrait les contraintes (grep dans specs)
   - Active les skills pertinents
   - Assemble le prompt
   - Tronque si nécessaire
   - Affiche le résultat

3. **`.agent/task-example.yaml`** (Exemple de Tâche)
   - Description d'une micro-tâche
   - Signature, types, tests échouants
   - Keywords pour activer les skills

---

## Configuration (minimizer-config.yaml)

### Structure Complète

```yaml
# Limites globales
limits:
  max_tokens: 500                  # Ne jamais dépasser
  max_depth: 2                     # Profondeur dans le graphe mémoire
  max_nodes: 10                    # Nombre max de nœuds du sous-graphe
  max_skill_summaries: 2           # Nombre max de skills injectés
  max_constraint_lines: 5          # Nombre max de règles de constitution
  token_estimate: "1 token ≈ 4 caractères"

# Sources de données
sources:
  memory:
    super_graph: "graph/super-graph.json"
    fallback_command: "npx gitnexus query --symbol ${TARGET_SYMBOL}"
  specs:
    constitution: "specs/rules/constitution.md"
    coding_standards: "specs/rules/coding-standards.md"
    security_policies: "specs/rules/security-policies.md"
  skills:
    registry: "skills/registry.json"
    summary_fields: ["objectif", "anti_patterns"]

# Format du prompt
prompt_template:
  sections:
    - order: 1
      name: "TASK"
      format: "// TÂCHE : Implémente {task.signature}"
      required: true
    - order: 2
      name: "SIGNATURE"
      format: "// SIGNATURE :\n{task.signature}"
      required: true
    # ... autres sections

# Règles d'extraction
extraction_rules:
  memory:
    keep_fields: ["name", "signature", "filePath"]
    discard_fields: ["body", "implementation", "docstring"]
  specs:
    constraint_prefixes: ["- ", "* ", "1. "]
    keywords_mapping:
      api: ["sécurité", "rate limit", "zod"]
      ui: ["accessibilité", "contraste", "responsive"]
  skills:
    summary_template: "// SKILL {name} : {objectif} | PIÈGES : {anti_patterns}"

# Règles de troncature
truncation:
  priority_order:
    - "SKILLS"        # Supprimer en premier
    - "DEPENDENCIES"
    - "FAILED_TESTS"
    - "TYPES"
  protected_sections: ["TASK", "SIGNATURE", "CONSTRAINTS"]
```

### Sections du Prompt

Le prompt est assemblé selon l'ordre défini dans `prompt_template.sections` :

1. **TASK** (requis) : Description de la tâche
2. **SIGNATURE** (requis) : Signature de la fonction/classe
3. **TYPES** (optionnel) : Types TypeScript associés
4. **FAILED_TESTS** (optionnel) : Tests qui échouent
5. **DEPENDENCIES** (optionnel) : Dépendances du graphe mémoire
6. **CONSTRAINTS** (requis) : Règles de la constitution
7. **SKILLS** (optionnel) : Skills activés

---

## Utilisation

### Commande de Base

```bash
./scripts/minimize.sh <targetSymbol> [taskFile.yaml]
```

### Exemples

```bash
# Avec le fichier d'exemple
./scripts/minimize.sh validateEmail .agent/task-example.yaml

# Avec un fichier custom
./scripts/minimize.sh myFunction .agent/my-task.yaml

# Le prompt est affiché sur stdout
# Les logs (tokens, warnings) sur stderr
```

### Sortie

```
// TÂCHE : Implémente validateEmail

// SIGNATURE :
function validateEmail(email: string): ValidationResult

// TYPES ASSOCIÉS :
interface ValidationResult {
  isValid: boolean;
  error?: 'MISSING_AT_SIGN' | 'INVALID_DOMAIN' | 'TOO_LONG' | 'EMPTY';
}

// TESTS ÉCHOUANTS :
Test 2: validateEmail("userdomain.com") 
  → attendu {isValid:false, error:"MISSING_AT_SIGN"}
  → reçu {isValid:true}

// DÉPENDANCES (signatures uniquement) :
  // Aucune dépendance trouvée dans le graphe

// RÈGLES :
  - Respecter la constitution du projet
  - Toujours valider les entrées utilisateur
  - Gérer les cas d'erreur explicitement

// SKILLS ACTIVÉS :
  // SKILL debugging : Méthodologie de débogage systématique
```

**Tokens estimés** : ~120 tokens

---

## Format de Micro-Tâche (task.yaml)

### Structure

```yaml
targetSymbol: "validateEmail"        # Nom de la fonction/classe

signature: |                         # Signature complète
  function validateEmail(email: string): ValidationResult

types: |                             # Types TypeScript associés
  interface ValidationResult {
    isValid: boolean;
    error?: 'MISSING_AT_SIGN' | 'INVALID_DOMAIN' | 'TOO_LONG' | 'EMPTY';
  }

failed_tests: |                      # Tests qui échouent
  Test 2: validateEmail("userdomain.com") 
    → attendu {isValid:false, error:"MISSING_AT_SIGN"}
    → reçu {isValid:true}

keywords:                            # Mots-clés pour activer les skills
  - validation
  - email
  - auth

description: |                       # Description de la tâche (optionnel)
  Implémenter la fonction validateEmail qui valide une adresse email.
```

### Champs

- **targetSymbol** (requis) : Nom de la fonction/classe à implémenter
- **signature** (requis) : Signature complète avec types
- **types** (optionnel) : Interfaces, types, enums associés
- **failed_tests** (optionnel) : Tests qui échouent avec détails
- **keywords** (requis) : Mots-clés pour activer les skills
- **description** (optionnel) : Description détaillée

---

## Modification du Comportement

### Changer la Limite de Tokens

```yaml
limits:
  max_tokens: 300  # Au lieu de 500
```

### Ajouter Plus de Contraintes

```yaml
limits:
  max_constraint_lines: 10  # Au lieu de 5
```

### Modifier le Format du Prompt

```yaml
prompt_template:
  sections:
    - order: 1
      name: "TASK"
      format: "### TÂCHE : {task.signature}"  # Markdown au lieu de //
      required: true
```

### Changer l'Ordre de Troncature

```yaml
truncation:
  priority_order:
    - "TYPES"         # Supprimer les types en premier
    - "SKILLS"        # Puis les skills
    - "DEPENDENCIES"  # Puis les dépendances
    - "FAILED_TESTS"  # Garder les tests le plus longtemps possible
```

### Ajouter une Nouvelle Section

```yaml
prompt_template:
  sections:
    - order: 8
      name: "EXAMPLES"
      format: |
        // EXEMPLES :
        {task.examples}
      required: false
```

---

## Intégration avec les Autres Couches

### Couche 0 (Harness)

Le script `minimize.sh` est appelé depuis `WORKFLOW.md` ou `after-agent.sh` :

```bash
# Dans WORKFLOW.md
PROMPT=$(./scripts/minimize.sh "$TARGET_SYMBOL" "$TASK_FILE")
```

### Couche 1 (Mémoire)

Le minimiseur lit automatiquement `graph/super-graph.json` :

```bash
# Indexer la mémoire d'abord
./scripts/index-memory.sh

# Puis générer le prompt
./scripts/minimize.sh validateEmail .agent/task-example.yaml
```

### Couche 2 (Specs & Skills)

Le minimiseur lit automatiquement :
- `specs/rules/constitution.md` pour les contraintes
- `skills/registry.json` pour activer les skills pertinents

```bash
# Les skills sont activés automatiquement selon les keywords
# Exemple : keywords: [validation, email] → active le skill debugging
```

### Couche 5 (Exécution)

L'orchestrateur génère automatiquement `task.yaml` et appelle `minimize.sh` :

```bash
# L'orchestrateur fait :
# 1. Créer task.yaml depuis la micro-tâche
# 2. Appeler minimize.sh pour générer le prompt
# 3. Envoyer le prompt au LLM
# 4. Récupérer le code généré
# 5. Exécuter les tests
# 6. Si échec, générer un prompt de correction
```

---

## Dépendances

### Requises

- **Bash** : Shell POSIX (Linux, macOS, WSL)

### Optionnelles (avec fallback)

- **yq** : Parser YAML (si absent, utilise grep/sed)
- **jq** : Parser JSON (si absent, skip les dépendances du graphe)

### Installation

```bash
# Ubuntu/Debian
sudo apt install jq
sudo snap install yq

# macOS
brew install jq yq

# Windows (WSL)
sudo apt install jq
sudo snap install yq
```

### Fallback

Si `yq` ou `jq` ne sont pas installés, le script utilise des fallbacks simples :
- **yq** → `grep` + `sed` pour extraire les valeurs YAML
- **jq** → Skip les dépendances du graphe mémoire

---

## Troncature Intelligente

Si le prompt dépasse `max_tokens`, le script supprime les sections dans l'ordre de priorité :

1. **SKILLS** : Supprimer les skills en premier
2. **DEPENDENCIES** : Puis les dépendances éloignées
3. **FAILED_TESTS** : Puis les tests (garder au moins 1)
4. **TYPES** : Puis les types

Les sections **TASK**, **SIGNATURE** et **CONSTRAINTS** ne sont **jamais** tronquées.

### Exemple de Troncature

```bash
# Prompt initial : 600 tokens
# 1. Supprimer SKILLS → 550 tokens
# 2. Supprimer DEPENDENCIES → 480 tokens
# ✓ Prompt final : 480 tokens (< 500)
```

---

## Tests

### Test Manuel

```bash
# Tester avec l'exemple fourni
./scripts/minimize.sh validateEmail .agent/task-example.yaml

# Vérifier que :
# - Le prompt est généré
# - Les tokens sont < 500
# - Les sections sont présentes
```

### Test avec Graphe Mémoire

```bash
# Créer un graphe de test
mkdir -p graph
echo '{"nodes":[{"name":"validateEmail","signature":"function validateEmail(email: string): ValidationResult","dependencies":[]}]}' > graph/super-graph.json

# Tester
./scripts/minimize.sh validateEmail .agent/task-example.yaml
```

### Test de Troncature

```bash
# Créer une tâche avec beaucoup de contenu
cat > .agent/task-large.yaml << 'EOF'
targetSymbol: "complexFunction"
signature: |
  function complexFunction(a: string, b: number, c: boolean, d: object): Result
types: |
  interface Result {
    field1: string;
    field2: number;
    field3: boolean;
    field4: object;
    field5: string[];
    field6: Map<string, number>;
    field7: Set<boolean>;
    field8: Promise<void>;
  }
failed_tests: |
  Test 1: complexFunction("a", 1, true, {}) → ...
  Test 2: complexFunction("b", 2, false, {}) → ...
  Test 3: complexFunction("c", 3, true, {}) → ...
keywords:
  - complex
  - validation
EOF

# Tester la troncature
./scripts/minimize.sh complexFunction .agent/task-large.yaml
```

---

## Troubleshooting

### Erreur : "yq: command not found"

Le script utilise un fallback simple avec grep/sed. Pas de problème.

### Erreur : "jq: command not found"

Les dépendances du graphe seront skippées. Installer jq pour les activer :

```bash
sudo apt install jq  # Ubuntu/Debian
brew install jq      # macOS
```

### Prompt Trop Long

Modifier `.agent/minimizer-config.yaml` :

```yaml
limits:
  max_tokens: 300  # Réduire la limite
  max_constraint_lines: 3  # Moins de contraintes
```

### Skills Non Activés

Vérifier que :
1. `skills/registry.json` existe
2. Les keywords dans `task.yaml` matchent les triggers des skills
3. Les fichiers de skills existent

### Script Non Exécutable

```bash
# Rendre le script exécutable
chmod +x scripts/minimize.sh

# Ou sur Windows
attrib +x scripts/minimize.sh
```

---

## Principe Fondamental

> **Un petit modèle avec 500 tokens pertinents fait moins d'erreurs qu'un gros modèle noyé dans 100 000 tokens de code.**

Le minimiseur extrait **uniquement** ce qui est nécessaire :
- La signature de la fonction
- Les types associés
- Les tests qui échouent
- Les dépendances directes
- Les règles de la constitution
- Les skills pertinents

Tout le reste est **éliminé** pour maximiser le signal et minimiser le bruit.

---

## Avantages de l'Approche YAML + Shell

### 1. Zéro Dépendance Lourde

Pas besoin de Node.js, npm, TypeScript, ou modules. Juste bash et des outils standard.

### 2. Modification Sans Compilation

Éditer `.agent/minimizer-config.yaml` et c'est tout. Pas de `npm run build`.

### 3. Portable

Fonctionne sur Linux, macOS, WSL, et même dans des environnements restreints.

### 4. Compréhensible par l'IA

Le LLM peut lire et interpréter directement le YAML pour comprendre le comportement.

### 5. Maintenable

Un ingénieur peut modifier le comportement en éditant simplement le YAML, sans toucher au script shell.

---

## Commandes Utiles

```bash
# Générer un prompt
./scripts/minimize.sh validateEmail .agent/task-example.yaml

# Rediriger vers un fichier
./scripts/minimize.sh validateEmail .agent/task-example.yaml > prompt.txt

# Voir uniquement les logs
./scripts/minimize.sh validateEmail .agent/task-example.yaml 2>&1 >/dev/null

# Compter les tokens
./scripts/minimize.sh validateEmail .agent/task-example.yaml 2>&1 | grep "Tokens estimés"
```

---

**Version** : 2.0.0 (YAML + Shell)  
**Dernière mise à jour** : 2026-05-08  
**Auteur** : Axiom-Scaffold Team
