---
id: caveman-mode
triggers: ["caveman", "compact", "ultra", "lite", "wenyan", "less tokens", "/caveman"]
description: "Active le mode de compression caveman pour économiser les tokens"
mode: both
category: communication
version: "1.0.0"
---

# Caveman Mode Skill

## Description

Active le mode de compression caveman pour toutes les sorties de l'agent (chat, fichiers, logs). Économise 65-75% des tokens sans perte de précision technique.

## Déclencheurs

- `caveman` ou `/caveman` : Active le mode par défaut (full)
- `/caveman lite` : Mode professionnel (garde articles et phrases complètes)
- `/caveman full` : Mode par défaut (fragments, sans articles)
- `/caveman ultra` : Mode télégraphique (abréviations, flèches)
- `/caveman wenyan` : Mode chinois classique (compression maximale)
- `stop caveman` ou `normal mode` : Désactive le mode caveman

## Comportement

### 1. Lecture de la configuration

Avant toute sortie, l'agent DOIT lire `Axiom-scaffold/config/caveman-rules.yaml` pour connaître :
- Les niveaux de compression (lite/full/ultra/wenyan)
- Les règles par type de sortie (chat, docs, walkthrough, task, plan, commit, review)
- Les invariants (code intact, erreurs exactes, alertes sécurité exclues)
- Les anti-patterns à éviter

### 2. Application des règles

#### Chat Response (mode full par défaut)
- Max 6 lignes
- Format : `[constat] [cause] [action]. [étape suivante].`
- Interdit : "Sure!", "I'd be happy to help", "Let me explain", etc.
- Exemple :
  ```
  Bug in auth middleware. Token expiry check use `<` not `<=`. Fix:
  
  // middleware/auth.js:42
  - if (token.exp < now) throw new Error('expired');
  + if (token.exp <= now) throw new Error('expired');
  
  Test: npm test auth
  ```

#### Documentation (mode lite)
- Garde sections : overview, usage, install, config, api, security
- Max 15 lignes par section
- Supprime : acknowledgments, philosophy, background_story, motivation_essay

#### Walkthrough (mode full)
- Format : `Step N: [action]. [result].`
- Max 8 étapes

#### Task File (mode ultra)
- Format : `TASK {id}: {goal} | File: {file} | Deps: {dep} | Status: {status}`
- Champs : id, goal, file, dep, status uniquement

#### Implementation Plan (mode full)
- Sections : Goal, Files, Deps, Tests
- Max 25 lignes total

#### Commit Message (mode ultra)
- Format : `{type}({scope}): {action} - {reason}`
- Max 72 caractères

#### Code Review (mode full)
- Format : `{file}:{line} - {severity_emoji} {finding}`
- Emojis : 🔴 critical, 🟡 warning, 🔵 info

### 3. Invariants (tous modes)

- **Code blocks** : jamais compressés, syntaxe complète
- **Error messages** : cités exactement, jamais paraphrasés
- **Technical terms** : jamais abrégés (noms de fonctions, API, fichiers)
- **Security warnings** : sortent automatiquement du mode caveman
- **Irreversible actions** : sortent automatiquement du mode caveman

### 4. Persistance

Le mode caveman reste actif **pour toutes les réponses** jusqu'à :
- `stop caveman`
- `normal mode`
- Alerte sécurité
- Confirmation d'action irréversible

### 5. Structure de sortie

Tous les fichiers générés vont dans :
```
Axiom-scaffold/reports/
├── {feature}/
│   ├── walkthrough.md
│   ├── tasks.md
│   ├── plan.md
│   └── reviews.md
```

## Exemples

### Avant caveman
```
Sure! I'd be happy to help you with that. Let me explain what's happening here.

The authentication middleware is currently checking if the token expiry time is less than the current time. However, this creates a race condition where tokens that expire at exactly the current second are still considered valid. This is a security issue because it extends the token lifetime by up to one second.

I recommend changing the comparison operator from `<` to `<=` to ensure that tokens expiring at the current second are properly rejected.

Here's the fix I propose:
```

### Après caveman (mode full)
```
Bug in auth middleware. Token expiry check use `<` not `<=`. Race condition: tokens valid 1s extra.

Fix: middleware/auth.js:42
- if (token.exp < now) throw new Error('expired');
+ if (token.exp <= now) throw new Error('expired');

Test: npm test auth
```

### Mode ultra
```
Auth bug → token check wrong
Fix: auth.js:42 `<` → `<=`
Test: npm test auth
```

## Anti-patterns

### Chat
- ❌ Écrire plus de 8 lignes
- ❌ Commencer par une formule de politesse
- ❌ Expliquer le contexte évident

### Files
- ❌ Dépasser le nombre max de lignes par section
- ❌ Ajouter des sections non listées

### Code
- ❌ Compresser le code
- ❌ Paraphraser les erreurs

## Économie de tokens

- **Chat** : 65-75% de réduction
- **Docs** : 50-60% de réduction
- **Fichiers d'entrée** (avec caveman-compress) : ~46% de réduction
- **Total projet** : économie massive sur projets longs

## Références

- Source : https://github.com/JuliusBrussee/caveman
- Licence : MIT
- Config : `Axiom-scaffold/config/caveman-rules.yaml`
- Mapping IDE : `Axiom-scaffold/config/ide-mapping.yaml`
