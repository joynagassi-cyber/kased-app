# Auto-Optimisation Continue — Couche -1

## Introduction

La **Couche -1** d'Axiom-Scaffold est le **laboratoire d'expérimentation autonome** du système. Elle permet à un agent IA d'améliorer automatiquement et en continu n'importe quel artefact du projet — code, requêtes, prompts, configurations, designs — en testant des hypothèses de manière isolée, mesurant les résultats avec une métrique stricte, et ne conservant que les changements bénéfiques.

### Principe du Cliquet

Seules les améliorations sont conservées. À chaque itération :
- ✅ **Score amélioré** → `git commit` (changement gardé)
- ❌ **Score dégradé** → `git reset --hard` (changement annulé)

---

## Le Pattern à Trois Fichiers

Toute expérience d'auto-optimisation repose sur **trois fichiers** :

```
experiments/exp-<nom>/
├── program.md          # Instructions, objectif, contraintes (écrit par l'humain)
├── evaluate.py         # Script de mesure, IMMUABLE (jamais modifié par l'agent)
└── candidate.py        # Code à améliorer (SEUL fichier éditable par l'agent)
```

### 1. `program.md` — Le Contrat de Recherche

Décrit :
- **L'objectif** : Quelle métrique optimiser ?
- **Les règles** : Quelles contraintes respecter ?
- **La boucle** : Comment itérer ?
- **L'instruction** : "Ne t'arrête jamais"

**Exemple** :
```markdown
# Programme d'Optimisation Autonome

## Objectif
Minimiser le temps d'exécution de `fonction_cible()` dans `candidate.py`.
Métrique : temps moyen sur 100 appels (en secondes).

## Règles
1. Seul `candidate.py` peut être modifié
2. Ne touche JAMAIS à `evaluate.py` ou `program.md`
3. Budget temps : 10 secondes max par expérience
4. Toute amélioration doit être fonctionnelle

## Boucle
1. Lis `candidate.py`
2. Propose UNE modification
3. Modifie `candidate.py`
4. Lance `python evaluate.py`
5. Si meilleur → commit, sinon → reset
6. Répète

## Ne t'arrête jamais
```

### 2. `evaluate.py` — Le Juge Impartial

Script Python qui :
1. Importe le code depuis `candidate.py`
2. Exécute la tâche avec des données de test
3. Mesure la métrique
4. Écrit le résultat dans `results.tsv`

**Caractéristiques** :
- ❌ **IMMUABLE** : l'agent ne peut JAMAIS le modifier
- ⏱️ **Timeout** : limite de temps pour éviter les boucles infinies
- 📊 **Traçabilité** : tous les résultats sont journalisés

**Exemple** :
```python
#!/usr/bin/env python3
import time
import statistics
from datetime import datetime
from candidate import fonction_cible

def mesure():
    donnees = list(range(1000, 0, -1))
    start = time.perf_counter()
    resultat = fonction_cible(donnees)
    return time.perf_counter() - start

if __name__ == "__main__":
    temps = [mesure() for _ in range(100)]
    moy = statistics.mean(temps)
    
    timestamp = datetime.now().isoformat()
    with open("results.tsv", "a") as f:
        f.write(f"{timestamp}\t{moy:.6f}\n")
    
    print(f"✅ Temps moyen: {moy:.6f}s")
```

### 3. `candidate.py` — Le Code à Optimiser

Le **seul fichier** que l'agent peut modifier.

**Exemple initial** :
```python
def fonction_cible(data):
    """Fonction à optimiser"""
    # Implémentation initiale (bubble sort - très lent)
    arr = data.copy()
    n = len(arr)
    for i in range(n):
        for j in range(0, n-i-1):
            if arr[j] > arr[j+1]:
                arr[j], arr[j+1] = arr[j+1], arr[j]
    return arr
```

L'agent va tester successivement :
- `list.sort()` → ✅ Beaucoup plus rapide → commit
- `sorted()` → ✅ Encore plus rapide → commit
- Tri par insertion → ❌ Plus lent → reset
- etc.

---

## Mécanisme de la Boucle

```
┌─────────────────────────────────────────────────────────────┐
│  1. LECTURE DU PROGRAMME                                    │
│     L'agent lit program.md pour comprendre l'objectif.      │
│                          ↓                                  │
│  2. ÉVALUATION INITIALE                                     │
│     L'agent exécute evaluate.py pour obtenir la baseline    │
│                          ↓                                  │
│  3. PROPOSITION D'UNE MODIFICATION                          │
│     L'agent analyse candidate.py et propose UNE             │
│     modification (changement d'algorithme, structure…)      │
│                          ↓                                  │
│  4. MODIFICATION DE CANDIDATE.PY                            │
│     L'agent édite UNIQUEMENT candidate.py                   │
│                          ↓                                  │
│  5. RÉÉVALUATION                                            │
│     L'agent relance evaluate.py et lit le nouveau score     │
│                          ↓                                  │
│  6. DÉCISION (CLIQUET)                                      │
│     ┌── Score amélioré ? → git add + git commit            │
│     └── Score dégradé ?  → git reset --hard                │
│                          ↓                                  │
│  7. RÉPÉTITION INFINIE                                      │
│     L'agent recommence à l'étape 3, indéfiniment.          │
└─────────────────────────────────────────────────────────────┘
```

---

## Types d'Optimisation Supportés

Le pattern s'applique à **tous les artefacts** du projet :

### 1. Performance (Code)

**Objectif** : Minimiser le temps d'exécution  
**Candidat** : `candidate.py` (fonction à optimiser)  
**Métrique** : Temps moyen d'exécution  
**Stratégies** :
- Changement d'algorithme (bubble sort → quicksort)
- Structures de données (list → set, dict)
- Mémoïsation / cache
- Parallélisation
- Réduction de la complexité

### 2. Interface Utilisateur

**Objectif** : Maximiser le score d'accessibilité  
**Candidat** : `candidate.html` (page web)  
**Métrique** : Score Lighthouse (0-100)  
**Stratégies** :
- Améliorer le contraste des couleurs
- Utiliser des balises sémantiques (`<main>`, `<nav>`, `<header>`)
- Ajouter des attributs ARIA
- Optimiser les images
- Réduire le DOM

### 3. Requête SQL

**Objectif** : Minimiser le temps d'exécution  
**Candidat** : `candidate.sql` (requête)  
**Métrique** : Temps d'exécution  
**Stratégies** :
- Ajouter des index
- Réécrire les JOIN
- Utiliser des CTE (Common Table Expressions)
- Éviter les sous-requêtes corrélées
- Optimiser les WHERE

### 4. Prompt IA

**Objectif** : Maximiser la qualité des réponses  
**Candidat** : `candidate.txt` (prompt système)  
**Métrique** : Score de pertinence (0-100)  
**Stratégies** :
- Ajouter des exemples
- Clarifier les instructions
- Structurer avec des sections
- Ajouter des contraintes
- Reformuler

### 5. Configuration

**Objectif** : Minimiser le coût ou le temps  
**Candidat** : `candidate.yaml` (config Docker, Terraform)  
**Métrique** : Coût cloud, temps de déploiement  
**Stratégies** :
- Changement d'instance
- Ajustement du scaling
- Optimisation des ressources

### 6. Design System

**Objectif** : Maximiser l'harmonie visuelle  
**Candidat** : `candidate.css` (tokens)  
**Métrique** : Score d'harmonie, accessibilité  
**Stratégies** :
- Ajustement des couleurs
- Espacements cohérents
- Typographie optimisée

---

## Démarrage d'une Expérience

### Commande

```bash
./script/start-experiment.sh <nom-experience> [type]
```

**Types disponibles** :
- `performance` (défaut) : optimisation de performance
- `ui` : optimisation d'interface utilisateur
- `sql` : optimisation de requête SQL
- `prompt` : optimisation de prompt IA
- `config` : optimisation de configuration

### Exemple

```bash
# Optimiser une fonction de tri
./script/start-experiment.sh optimiser-tri performance

# Optimiser une page web
./script/start-experiment.sh ameliorer-landing ui

# Optimiser une requête SQL
./script/start-experiment.sh requete-users sql
```

### Ce qui se passe

1. **Création du workspace** : `agent-workspaces/exp-<nom>-<timestamp>/`
2. **Initialisation Git** : dépôt Git local pour le cliquet
3. **Génération des fichiers** : `program.md`, `evaluate.py`, `candidate.*`
4. **Évaluation initiale** : mesure du score de base
5. **Instructions affichées** : guide pour l'agent IA

---

## Exemple Concret : Optimisation d'un Tri

### Étape 1 : Démarrage

```bash
./script/start-experiment.sh optimiser-tri performance
```

### Étape 2 : Fichiers Générés

**`program.md`** :
```markdown
# Programme d'Optimisation Autonome — Performance

## Objectif
Minimiser le temps d'exécution de la fonction cible dans `candidate.py`.
Métrique : temps moyen sur 100 appels (en secondes).

## Règles
1. Seul `candidate.py` peut être modifié
2. Ne touche JAMAIS à `evaluate.py` ou `program.md`
3. Budget temps : 10 secondes max
4. Toute amélioration doit être fonctionnelle

## Boucle
1. Lis `candidate.py`
2. Propose UNE modification
3. Modifie `candidate.py`
4. Lance `python evaluate.py`
5. Si meilleur → commit, sinon → reset
6. Répète

## Ne t'arrête jamais
```

**`evaluate.py`** :
```python
#!/usr/bin/env python3
import time
import statistics
from datetime import datetime
from candidate import fonction_cible

def mesure():
    donnees = list(range(1000, 0, -1))
    start = time.perf_counter()
    resultat = fonction_cible(donnees)
    elapsed = time.perf_counter() - start
    
    if resultat != sorted(donnees):
        raise ValueError("Résultat incorrect")
    
    return elapsed

if __name__ == "__main__":
    temps = [mesure() for _ in range(100)]
    moy = statistics.mean(temps)
    
    timestamp = datetime.now().isoformat()
    with open("results.tsv", "a") as f:
        f.write(f"{timestamp}\t{moy:.6f}\n")
    
    print(f"✅ Temps moyen: {moy:.6f}s")
```

**`candidate.py`** (version initiale) :
```python
def fonction_cible(data):
    """Fonction à optimiser - Tri"""
    # Implémentation initiale (bubble sort - très lent)
    arr = data.copy()
    n = len(arr)
    for i in range(n):
        for j in range(0, n-i-1):
            if arr[j] > arr[j+1]:
                arr[j], arr[j+1] = arr[j+1], arr[j]
    return arr
```

### Étape 3 : Boucle d'Optimisation

**Itération 1** : L'agent remplace par `list.sort()`
```python
def fonction_cible(data):
    arr = data.copy()
    arr.sort()
    return arr
```
→ ✅ **Temps : 0.000050s** (vs 0.150000s) → **Commit**

**Itération 2** : L'agent essaie `sorted()`
```python
def fonction_cible(data):
    return sorted(data)
```
→ ✅ **Temps : 0.000045s** → **Commit**

**Itération 3** : L'agent essaie un tri par insertion
```python
def fonction_cible(data):
    arr = data.copy()
    for i in range(1, len(arr)):
        key = arr[i]
        j = i-1
        while j >= 0 and key < arr[j]:
            arr[j+1] = arr[j]
            j -= 1
        arr[j+1] = key
    return arr
```
→ ❌ **Temps : 0.120000s** (plus lent) → **Reset**

**Itération 4** : L'agent essaie d'autres optimisations...

### Étape 4 : Résultats

Après 10 itérations, le meilleur résultat est conservé :
```python
def fonction_cible(data):
    return sorted(data)
```

**Amélioration** : 0.150000s → 0.000045s = **3333x plus rapide** ! 🚀

---

## Sécurité et Garde-fous

### 1. Timeout

Chaque évaluation a un **timeout de 10 secondes** :
```python
import signal

def timeout_handler(signum, frame):
    raise TimeoutError("Expérience trop longue")

signal.signal(signal.SIGALRM, timeout_handler)
signal.alarm(10)  # Timeout de 10 secondes
```

### 2. Bac à Sable

L'agent travaille dans un **workspace isolé** :
- `agent-workspaces/exp-<nom>/` (copie temporaire)
- Jamais sur le code source principal
- Peut être supprimé sans risque

### 3. Pas d'Accès Réseau

L'agent ne peut pas :
- Télécharger de bibliothèques externes
- Faire des requêtes HTTP
- Accéder à des ressources externes

### 4. Traçabilité

Chaque tentative est **journalisée** dans `results.tsv` :
```
timestamp                   score       std
2026-05-07T10:30:00        0.150000    0.002000
2026-05-07T10:30:15        0.000050    0.000001
2026-05-07T10:30:30        0.000045    0.000001
```

### 5. Immuabilité de l'Évaluateur

Le fichier `evaluate.py` est **sacré** :
- L'agent ne peut JAMAIS le modifier
- Garantit l'objectivité de la mesure
- Évite la triche

---

## Intégration avec les Autres Couches

### Couche 0 (Harness Engineering)

- **Isolation** : Le workspace est créé par les scripts du Harnais
- **Hooks** : `after-agent.sh` peut capturer les résultats
- **Logs** : `on-error.sh` gère les erreurs d'expérience

### Couche 1 (Mémoire)

- **Historique** : Les commits Git sont stockés dans Obsidian
- **Patterns** : Les optimisations récurrentes sont capturées
- **Apprentissage** : Les échecs documentés enrichissent la base

### Couche 5 (Exécution)

- **Validation** : Si l'expérience réussit, une PR est créée
- **Zero-Trust** : La pipeline CI/CD doit passer avant fusion
- **Tests** : Les tests existants valident le changement

### Couche 7 (Apprentissage)

- **Skills** : Les patterns d'optimisation deviennent des skills
- **Constitution** : Les règles apprises enrichissent la constitution
- **Wiki** : Les expériences sont documentées dans le wiki

---

## Commandes Utiles

### Démarrer une Expérience

```bash
./script/start-experiment.sh <nom> [type]
```

### Voir les Résultats

```bash
cd agent-workspaces/exp-<nom>-<timestamp>
cat results.tsv
```

### Voir l'Historique Git

```bash
cd agent-workspaces/exp-<nom>-<timestamp>
git log --oneline
```

### Comparer les Versions

```bash
cd agent-workspaces/exp-<nom>-<timestamp>
git diff HEAD~1 HEAD candidate.py
```

### Nettoyer les Workspaces

```bash
rm -rf agent-workspaces/exp-*
```

---

## Bonnes Pratiques

### Pour l'Humain

1. **Définir une métrique claire** : Un seul nombre, automatisable
2. **Écrire un évaluateur robuste** : Avec timeout et validation
3. **Fournir des données de test réalistes** : Représentatives du cas d'usage
4. **Documenter les contraintes** : Dans `program.md`

### Pour l'Agent

1. **Une modification à la fois** : Ne pas tout changer d'un coup
2. **Lire l'historique** : Consulter `results.tsv` avant de proposer
3. **Valider fonctionnellement** : S'assurer que le code fonctionne
4. **Documenter les commits** : Messages clairs et descriptifs

---

## Limitations

### Actuelles

- Pas d'optimisation multi-objectifs (une seule métrique)
- Pas de parallélisation des expériences
- Pas d'apprentissage par renforcement (exploration aléatoire)

### Futures Améliorations

- **Multi-objectifs** : Optimiser temps ET mémoire
- **Parallélisation** : Lancer plusieurs expériences en parallèle
- **RL** : Utiliser l'apprentissage par renforcement pour explorer
- **Visualisation** : Graphes d'évolution du score

---

## Conclusion

La **Couche -1 (Auto-Optimisation Continue)** permet à Axiom-Scaffold d'**améliorer automatiquement** n'importe quel artefact du projet. En combinant :
- Un **pattern simple** (3 fichiers)
- Un **mécanisme de cliquet** (Git)
- Une **isolation stricte** (bac à sable)
- Une **métrique objective** (évaluateur immuable)

Elle transforme l'agent IA en un **chercheur autonome** qui explore l'espace des solutions pendant que l'humain est absent.

**Prochaine étape** : Lancer votre première expérience ! 🚀

---

**Version** : 1.0.0  
**Dernière mise à jour** : 2026-05-07  
**Statut** : ✅ Opérationnel
