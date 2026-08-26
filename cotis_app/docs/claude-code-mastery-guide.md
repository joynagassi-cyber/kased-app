# Claude Code — De Débutant à Power User
## Le guide pratique pour maîtriser l'agent AI le plus puissant

---

## Table des matières

1. [Introduction](#introduction)
2. [Premiers pas](#premiers-pas)
3. [Commandes essentielles](#commandes-essentielles)
4. [Techniques intermédiaires](#techniques-intermédiaires)
5. [Patterns avancés](#patterns-avancés)
6. [Workflows réels](#workflows-réels)
7. [Pièges à éviter](#pièges-à-éviter)
8. [Ressources](#ressources)

---

## Introduction

Claude Code est un agent AI qui s'intègre directement dans votre terminal. Contrairement à ChatGPT classique, il peut :

- **Lire et écrire** dans votre projet
- **Exécuter** des commandes
- **Comprendre** votre codebase entière
- **Travailler** de façon autonome sur des tâches complexes

Ce guide vous apprend à en tirer le maximum, étape par étape.

---

## Premiers pas

### Installation

```bash
# Via npm
npm install -g @anthropic-ai/claude-code

# Ou via pip (Python)
pip install anthropic-claude-code
```

### Première session

```bash
# Démarrer dans votre projet
cd /chemin/vers/votre/projet
claude

# Spécifier un modèle
claude --model sonnet-4
```

### Votre premier prompt

```
# ❌ Mauvais — trop vague
"Améliore mon code"

# ✅ Bon — spécifique et contextualisé
"Review le fichier src/auth.py. Identifie les problèmes de sécurité (OWASP Top 10) et propose des corrections. Score chaque issue de 1 à 10."
```

---

## Commandes essentielles

### Navigation

| Commande | Usage |
|----------|-------|
| `/help` | Affiche l'aide |
| `/clear` | Vide le contexte |
| `/memory` | Voir/modifier la mémoire |
| `/cost` | Afficher le coût de la session |
| `/tokens` | Voir l'utilisation des tokens |
| `/compact` | Réduire le contexte (garde l'essentiel) |
| `/exit` ou `Ctrl+C` | Quitter |

### Interaction

| Commande | Usage |
|----------|-------|
| `! <commande>` | Exécuter une commande shell |
| `::name::` | Nommer un message (pour référence) |
| `@file` | Attacher un fichier au prompt |
| `@/path/to/dir` | Attacher un répertoire entier |

### Slash commands utiles

```bash
# Demander un rating à votre prompt
"rate that prompt"

# Vérifier votre progression
"how am I doing"

# Demander des alternatives
"give me 3 options with tradeoffs"
```

---

## Techniques intermédiaires

### 1. Le Contexte Proactif

Claude Code voit votre projet, mais vous pouvez guider son attention :

```
# ❌ Espérer qu'il trouve le bon fichier
"Fix the bug"

# ✅ Guider explicitement
"Le bug est dans lib/core/auth/auth_service.dart, ligne 142.
L'erreur est un null safety issue. Corrige et explique."
```

### 2. Le Rôle (Role Prompting)

Assigner un rôle calibre l'expertise :

```
# Pour du code
"You are a senior Flutter engineer. Review this StatefulWidget
for performance issues. Focus on rebuild waste and state management."

# Pour du writing
"You are a technical writer. Rewrite this documentation to be
clearer, shorter, and more actionable. Target: developers with
2+ years experience."

# Pour de la recherche
"You are a research analyst. Compare these 3 approaches for
offline-first architecture. Score each on: complexity, performance,
maintenance."
```

### 3. Few-Shot (Montrer, ne pas dire)

2-3 exemples battent 10 paragraphes d'instructions :

```
"Voici 3 exemples de commits que je aime :

1. 'fix: resolve null safety issue in auth provider'
2. 'feat: add offline sync for member payments'
3. 'refactor: extract database layer from service'

Génère 5 messages de commit pour ces changements :
- J'ai corrigé un bug dans le calcul des retards
- J'ai ajouté un nouveau écran de statistiques
- J'ai refactorisé le provider d'authentification"
```

### 4. Pensée étape par étape

```
"Think through this step by step before answering:
1. Analyse la structure du projet
2. Identifie les dépendances critiques
3. Propose une solution avec tradeoffs
4. Donne le code final"
```

### 5. Itération, pas réinitialisation

```
# Au lieu de recommencer :
"Ton dernier code est bon mais :
- Réduis de 30%
- Ajoute des commentaires en français
- Gère le cas où la connexion tombe en cours de sync"
```

---

## Patterns avancés

### Pattern 1 : Chain of Thought Structuré

```
<task>Implémenter un système de mise à jour auto</task>
<constraints>
- InsForge Storage pour les APKs
- Pas de Play Store
- Version code comparaison
- Installation automatique
</constraints>
<output>
- 3 fichiers min (modèle, service, UI)
- Documentation obligatoire
- Tests unitaires
</output>
```

### Pattern 2 : Auto-Critique

```
"Score ce code de 1 à 10 sur :
- Lisibilité
- Performance
- Sécurité
- Maintenabilité

Ensuite, réécris la version la plus faible."
```

### Pattern 3 : Adversarial Review

```
"Agis comme un code reviewer sceptique.
Trouve les 3 plus gros problèmes de ce PR et
explique comment tu les attaquerais."
```

### Pattern 4 : Split & Conquer

```
"Phase 1 : Crée la structure des fichiers
Phase 2 : Implémente le modèle de données
Phase 3 : Ajoute le service API
Phase 4 : Intègre dans l'UI
Phase 5 : Write the tests"
```

### Pattern 5 : Constrained Generation

```
"Écris une fonction Dart qui :
- Prend un String et retourne un Future<bool>
- Utilise async/await
- Ne dépasse pas 50 lignes
- Include 3 lignes de commentaires max"
```

---

## Workflows réels

### Workflow 1 : Debug rapide

```
"J'ai cette erreur :
[COLLER L'ERREUR]

Fichier concerné : lib/core/auth.dart (ligne 45)
Contexte : L'erreur survient quand l'utilisateur est offline.
Trouve la cause racine et propose 2 solutions."
```

### Workflow 2 : Refactor

```
"Refactor ce service pour :
1. Extraire l'interface du repo
2. Séparer la logique métier de l'I/O
3. Rendre les méthodes testables

Garde la même API publique.
Show the diff."
```

### Workflow 3 : Code Review

```
"Review ce PR comme un senior engineer :
- Security : OWASP Top 10
- Performance : complexity analysis
- Architecture : SOLID principles
- Testing : coverage gaps

Score each category. Give specific line references."
```

### Workflow 4 : Documentation

```
"Generate documentation for this API endpoint :
- Description en français
- Parameters table
- Response schema
- Error codes
- 2 usage examples

Output in Markdown format."
```

### Workflow 5 : Test Generation

```
"Write unit tests for this service :
- Happy path (3 tests)
- Error cases (2 tests)
- Edge cases (1 test)
- Mock the dependencies

Use Mockito pattern. Follow given-when-then."
```

### Workflow 6 : Architecture Decision

```
"Compare these 2 approaches for state management :
1. Provider + Riverpod
2. Bloc + Cubit

Score each on :
- Learning curve
- Boilerplate
- Testing ease
- Scalability

Recommend one with reasoning."
```

---

## Pièges à éviter

### ❌ Erreur 1 : Prompt trop vague

```
"Fix this"
→ Résultat : Claude devine, souvent mal.

✅ "Fix the null safety error on line 42 of auth_provider.dart"
```

### ❌ Erreur 2 : Répéter le contexte

```
"Comme je t'ai dit dans mon dernier message..."
→ Claude voit tout l'historique, pas besoin de rappeler.

✅ Allons droit au but : "Now add error handling"
```

### ❌ Erreur 3 : Trop de choses en une fois

```
"Fix the auth bug, add unit tests, update docs, and refactor the provider"
→ Risque de quality drop sur chaque tâche.

✅ Split in phases :
Phase 1 : Fix the auth bug
Phase 2 : Add unit tests
Phase 3 : Update docs
```

### ❌ Erreur 4 : Ignorer les tokens

```
Longues sessions sans /compact
→ Contexte trop gros, réponse plus lente, coût plus élevé.

✅ /compact quand le contexte dépasse 50% du limit
```

### ❌ Erreur 5 : Ne pas itérer

```
Première réponse acceptée sans critique
→ Souvent perfectible.

✅ "Score this 1-10, then improve the weakest part"
```

---

## Ressources

### Commandes rapides

```bash
# Aide
/help

# Nettoyage contexte
/compact

# Coût session
/cost

# Quitter
/exit
```

### Patterns à mémoriser

| Situation | Pattern |
|-----------|---------|
| Debug | Contexte + erreur + localisation |
| Feature | Constraints + output + examples |
| Review | Rôle + criteria + scoring |
| Refactor | Input + output + invariants |
| Docs | Audience + format + depth |

### Prochains niveaux

1. **Intermediate** : Maîtriser les patterns ci-dessus
2. **Advanced** : Créer des skills personnalisés
3. **Expert** : Chain multi-agents, MCP tools, automation

---

## Conclusion

La différence entre débutant et power user :

| Débutant | Power User |
|----------|-----------|
| Pose des questions vagues | Donne du contexte précis |
| Accepte la première réponse | Itère et affine |
| Fait tout en une fois | Découpe en phases |
| Ne lit pas le code généré | Review et critique |
| Répète le contexte | Fait confiance à l'historique |

**Rappel :** Claude Code est un partenaire, pas un outil. Plus vous êtes précis, plus il est puissant.

---

*Guide créé pour le livre "Code avec Claude" — Edition 2026*
