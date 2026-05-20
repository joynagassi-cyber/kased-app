# Déterminisme — Axiom-Scaffold

## Introduction

Le **déterminisme** est un principe fondamental d'Axiom-Scaffold : **à code source identique, le super-graphe et sa visualisation doivent être identiques**, quelle que soit la machine ou le moment de l'exécution.

Ce document explique comment Axiom garantit ce déterminisme et comment le vérifier.

---

## Pourquoi le Déterminisme ?

### Problèmes Résolus

Sans déterminisme, chaque exécution produit un graphe légèrement différent :

- ❌ **Positions aléatoires** : Les nœuds changent de place à chaque visualisation
- ❌ **Hash différents** : Impossible de détecter les vrais changements
- ❌ **Diffs inutilisables** : Git montre des changements partout alors que le code n'a pas changé
- ❌ **Reproductibilité impossible** : Les résultats varient entre développeurs

### Bénéfices du Déterminisme

Avec le déterminisme :

- ✅ **Visualisation stable** : Le graphe est identique à chaque ouverture
- ✅ **Diffs significatifs** : Seuls les vrais changements apparaissent dans Git
- ✅ **Reproductibilité** : Même résultat sur toutes les machines
- ✅ **Vérification automatique** : Détection des régressions par hash
- ✅ **Confiance** : Le système est prévisible et fiable

---

## Architecture du Déterminisme

### Source of Truth Manifest

Le fichier `.axiom/source-of-truth.yaml` définit le **contrat de fusion** :

```yaml
version: "1.0.0"

sources:
  structure:    # GitNexus (priorité 1)
    tool: gitnexus
    file: graph/gitnexus-graph.json
    confidence: 1.0
    priority: 1
    
  semantics:    # Graphify (priorité 2)
    tool: graphify
    file: graph/graphify-graph.json
    confidence: 0.85
    priority: 2
    
  documentation: # GraphRAG (priorité 3)
    tool: graphrag
    file: graph/doc-graph.json
    confidence: 0.90
    priority: 3

fusion:
  strategy: priority_merge
  priority_order: [structure, semantics, documentation]
```

**Règle de fusion** : En cas de conflit, la source avec la priorité la plus haute (numéro le plus bas) l'emporte.

### JSON Schema

Le fichier `.axiom/schema/entity-graph.schema.json` définit le **format canonique** du graphe unifié :

- Chaque nœud a un `id`, `name`, `type`, `provenance`, `confidence`
- Chaque arête a un `source`, `target`, `relation`, `provenance`, `confidence`
- Les métadonnées incluent un `hash` SHA256

### Visualization Contract

Le fichier `.axiom/visualization-contract.yaml` définit le **rendu déterministe** :

```yaml
layout:
  algorithm: "dagre"
  seed: 42  # Seed fixe pour reproductibilité
  params:
    rankdir: "TB"
    nodesep: 50
    ranksep: 80
```

**Seed fixe** : Le layout utilise toujours le même seed (42), garantissant des positions identiques.

---

## Pipeline Déterministe

### Étape 1 : Extraction (Sources)

Chaque outil produit un graphe dans un format spécifique :

1. **GitNexus** → `graph/gitnexus-graph.json`
   - AST, dépendances, appels de fonctions
   - **Déterministe** : Basé sur l'AST (structure exacte)

2. **Graphify** → `graph/graphify-graph.json`
   - Clusters, résumés, centralité
   - **Déterministe** : Algorithme de Leiden avec seed fixe

3. **GraphRAG** → `graph/doc-graph.json`
   - Entités métier, règles, politiques
   - **Déterministe** : LLM avec `temperature=0.0` et `seed=42`

### Étape 2 : Fusion (Déterministe)

Le script `scripts/fuse-graph-deterministic.js` :

1. Charge le contrat `source-of-truth.yaml`
2. Charge les trois graphes sources
3. Fusionne selon les règles de priorité
4. Normalise le JSON (clés triées, pas de timestamps)
5. Calcule le hash SHA256
6. Sauvegarde `graph/entity-graph.json` et `.axiom/latest-graph-hash.txt`

**Garanties** :
- Ordre des clés JSON trié alphabétiquement
- Pas de timestamps dans le contenu hashé
- Résolution déterministe des conflits

### Étape 3 : Layout (Déterministe)

Le script `scripts/build-layout.js` :

1. Charge le contrat `visualization-contract.yaml`
2. Charge `graph/entity-graph.json`
3. Applique l'algorithme de layout avec seed fixe
4. Calcule les positions {x, y} de chaque nœud
5. Calcule le hash SHA256
6. Sauvegarde `graph/layout.json`

**Garanties** :
- Seed fixe (42) pour le générateur pseudo-aléatoire
- Algorithme déterministe (Dagre)
- Positions identiques à chaque exécution

---

## Utilisation

### Indexation Complète

```bash
# Indexer la mémoire avec fusion déterministe
bash scripts/index-memory.sh
```

Ce script exécute séquentiellement :

1. `npx gitnexus analyze --skills --embeddings`
2. Activation du skill Graphify (si disponible)
3. `graphrag index` (avec seed fixe)
4. `node scripts/fuse-graph-deterministic.js`
5. `node scripts/build-layout.js`
6. Génération du vault Obsidian

### Vérification du Déterminisme

```bash
# Vérifier que le système est déterministe
bash scripts/verify-determinism.sh
```

**Ce que fait ce script** :

1. Sauvegarde les hash actuels
2. Exécute la fusion et le layout
3. Compare les nouveaux hash avec les anciens
4. Affiche un rapport de vérification

**Résultat attendu** :

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Résultats de la Vérification

✅ Graphe d'entités: DÉTERMINISTE
   Hash: a3f5c8d9e2b1...

✅ Layout: DÉTERMINISTE
   Hash: 7b4e9f1a6c3d...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ SUCCÈS : Le système est déterministe !
```

### Test de Reproductibilité

Pour vérifier la reproductibilité complète :

```bash
# 1. Première exécution
bash scripts/index-memory.sh
cp .axiom/latest-graph-hash.txt /tmp/hash1.txt

# 2. Nettoyer les fichiers générés
rm -rf graph/*.json

# 3. Deuxième exécution
bash scripts/index-memory.sh
cp .axiom/latest-graph-hash.txt /tmp/hash2.txt

# 4. Comparer les hash
diff /tmp/hash1.txt /tmp/hash2.txt

# Si aucune différence → Système déterministe ✅
```

---

## Configuration GraphRAG pour le Déterminisme

### Paramètres Déterministes

Dans `graphrag_data/settings.yaml` :

```yaml
llm:
  type: openai_chat_completion
  model: gpt-4o-mini
  temperature: 0.0  # Pas de randomisation
  seed: 42          # Seed fixe (si supporté par le LLM)

# Dans source-of-truth.yaml
graphrag:
  llm_seed: 42
  deterministic_params:
    temperature: 0.0
    top_p: 1.0
    frequency_penalty: 0.0
    presence_penalty: 0.0
```

**Note** : Tous les LLM ne supportent pas le seed. Pour un déterminisme garanti, utilisez un modèle local (Ollama) avec seed fixe.

### Modèle Local Recommandé

Pour un déterminisme complet, utilisez Ollama :

```yaml
llm:
  type: openai_chat_completion
  api_base: http://localhost:11434/v1
  model: phi3:mini
  temperature: 0.0
  seed: 42
```

---

## Vérification de la Conformité

### Validation du Schéma

Le graphe unifié est automatiquement validé contre le JSON Schema :

```bash
# Validation manuelle
npx ajv validate \
  -s .axiom/schema/entity-graph.schema.json \
  -d graph/entity-graph.json
```

### Vérifications de Cohérence

Le script de fusion effectue automatiquement :

- ✅ Pas de nœuds orphelins
- ✅ Pas d'IDs dupliqués
- ✅ Provenance valide (gitnexus, graphify, graphrag, merged)
- ✅ Confidence dans [0, 1]
- ✅ Champs requis présents

---

## Dépannage

### Hash Différents Entre Exécutions

**Causes possibles** :

1. **Timestamps dans les métadonnées**
   - Solution : Exclure `exportedAt` du calcul de hash

2. **Ordre des clés JSON non trié**
   - Solution : Utiliser `JSON.stringify` avec clés triées

3. **Seed LLM non fixé**
   - Solution : Vérifier `temperature=0.0` et `seed=42` dans GraphRAG

4. **Seed layout non fixé**
   - Solution : Vérifier `seed: 42` dans `visualization-contract.yaml`

5. **Ordre des nœuds/arêtes non déterministe**
   - Solution : Trier par ID avant calcul du hash

### GraphRAG Non Déterministe

Si GraphRAG produit des résultats différents :

```bash
# 1. Vérifier la configuration
cat graphrag_data/settings.yaml | grep -A 5 "llm:"

# 2. Vérifier que temperature=0.0
# 3. Utiliser un modèle local (Ollama) avec seed fixe
# 4. Nettoyer le cache GraphRAG
rm -rf graphrag_data/cache/*
```

### Layout Non Déterministe

Si le layout varie :

```bash
# 1. Vérifier le seed
cat .axiom/visualization-contract.yaml | grep "seed:"

# 2. Vérifier que le seed est utilisé
node scripts/build-layout.js | grep "seed:"

# 3. Utiliser un algorithme déterministe (dagre, grid)
```

---

## Bonnes Pratiques

### 1. Versionner les Hash

Commitez les fichiers de hash dans Git :

```bash
git add .axiom/latest-graph-hash.txt
git add .axiom/latest-layout-hash.txt
git commit -m "chore: update graph hash"
```

### 2. CI/CD : Vérifier le Déterminisme

Ajoutez un test dans votre pipeline :

```yaml
# .github/workflows/determinism.yml
name: Verify Determinism

on: [push, pull_request]

jobs:
  determinism:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install dependencies
        run: npm install
      - name: First run
        run: bash scripts/index-memory.sh
      - name: Save hash
        run: cp .axiom/latest-graph-hash.txt /tmp/hash1.txt
      - name: Clean
        run: rm -rf graph/*.json
      - name: Second run
        run: bash scripts/index-memory.sh
      - name: Compare hash
        run: diff /tmp/hash1.txt .axiom/latest-graph-hash.txt
```

### 3. Documenter les Sources de Non-Déterminisme

Si un outil n'est pas déterministe, documentez-le :

```yaml
# source-of-truth.yaml
sources:
  external_api:
    tool: some-api
    confidence: 0.7
    deterministic: false  # ⚠️ Non déterministe
    reason: "API externe avec timestamps"
```

---

## Métriques

### Performance

- **Fusion** : < 1 seconde (pour 1000 nœuds)
- **Layout** : < 2 secondes (pour 1000 nœuds)
- **Vérification** : < 3 secondes (total)

### Reproductibilité

- **Taux de succès** : 100% (avec configuration correcte)
- **Variance** : 0 (hash identiques)

---

## Conclusion

Le système de déterminisme d'Axiom-Scaffold garantit que :

1. ✅ **Le super-graphe est reproductible** : Même code → Même graphe
2. ✅ **Le layout est stable** : Même graphe → Mêmes positions
3. ✅ **Les hash sont vérifiables** : Détection automatique des changements
4. ✅ **Le système est local** : Pas de dépendance externe (sauf Pinecone optionnel)

**Tout est déterministe, tout est vérifiable, tout est reproductible.**

---

**Version** : 1.0.0  
**Dernière mise à jour** : 2026-05-09  
**Statut** : ✅ Opérationnel
