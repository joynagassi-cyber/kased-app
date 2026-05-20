# Mémoire Universelle — Couche 1

## Introduction

La **Couche 1** d'Axiom-Scaffold est la **mémoire persistante et interrogeable** du système. Elle transforme le code source brut en un **super-graphe de connaissances** qui combine :

- **Précision structurelle** : AST, dépendances, appels de fonctions (GitNexus)
- **Richesse sémantique** : clusters fonctionnels, résumés IA, connexions surprenantes (Graphify)
- **Connaissances documentaires** : entités métier, règles, politiques extraites des documents (GraphRAG)
- **Recherche rapide** : embeddings vectoriels pour recherche sémantique (<100ms via Pinecone)
- **Documentation pérenne** : vault Obsidian pour navigation humaine

Sans cette mémoire, l'agent recommence chaque session de zéro. Avec elle, il dispose d'un **contexte profond et cumulatif** qui élimine les hallucinations en reliant le code aux spécifications et règles métier.

---

## Architecture

### Les 5 Briques

```
┌──────────────────────────────────────────────────────────────┐
│                   MÉMOIRE UNIVERSELLE                         │
│                                                              │
│  GitNexus ────► Super-Graphe Unifié ◄──── Graphify          │
│   (structure)         │              (sémantique)           │
│                       │                                      │
│                       ▼                                      │
│                   GraphRAG                                   │
│              (graphe documentaire)                           │
│          ┌───────────┴───────────┐                           │
│          ▼                       ▼                           │
│     Pinecone (chaud)       Obsidian (froid)                  │
│   (recherche <100ms)    (docs, wiki, canvas)                │
└──────────────────────────────────────────────────────────────┘
```

| Outil        | Rôle                                  | Type de données    |
| ------------ | ------------------------------------- | ------------------ |
| **GitNexus** | Graphe structurel (AST, appels, flux) | LadybugDB (locale) |
| **Graphify** | Graphe sémantique (clusters, résumés) | JSON + Markdown    |
| **GraphRAG** | Graphe documentaire (entités, règles) | Parquet + JSON     |
| **Pinecone** | Base vectorielle (mémoire chaude)     | Index de vecteurs  |
| **Obsidian** | Vault Markdown (mémoire froide)       | Fichiers `.md`     |

---

## Structure des Fichiers

```
racine-du-projet/
├── .gitnexus/                    # Index GitNexus (gitignoré)
│   ├── ladybug.db               # Base LadybugDB
│   └── config.json
│
├── graphrag_data/                # Données GraphRAG
│   ├── settings.yaml            # Configuration GraphRAG
│   ├── .env                     # Variables d'environnement
│   ├── input/                   # Documents à indexer
│   ├── output/                  # Résultats (Parquet)
│   └── cache/                   # Cache LLM
│
├── graph/                        # Graphes
│   ├── gitnexus-graph.json      # Graphe structurel
│   ├── graphify-graph.json      # Graphe sémantique
│   ├── doc-graph.json           # Graphe documentaire (GraphRAG)
│   ├── super-graph.json         # Graphe fusionné (source de vérité)
│   ├── entity-graph.json        # Graphe avec entités documentaires
│   └── graph-schema.md          # Schéma pour requêtes
│
├── scripts/                      # Scripts d'indexation
│   ├── index-memory.sh          # Lance l'indexation complète
│   ├── index-doc-graph.sh       # Indexation GraphRAG
│   ├── export-graphrag.py       # Export Parquet → JSON
│   ├── fuse-graphs.js           # Fusionne GitNexus + Graphify + GraphRAG
│   ├── sync-pinecone.sh         # Vectorise vers Pinecone
│   ├── pinecone_upload.py       # Upload Python vers Pinecone
│   └── generate-obsidian-notes.js  # Génère le vault Obsidian
│
├── vault/                        # Vault Obsidian
│   ├── 02-codebase/             # Notes par cluster
│   │   ├── _index.md            # Index des clusters
│   │   ├── authentication.md    # Cluster Auth
│   │   └── ...
│   ├── 03-decisions/            # ADR
│   └── README.md
│
└── logs/                         # Logs d'indexation
    ├── gitnexus.log
    ├── graphify.log
    ├── graphrag-index.log
    ├── fusion.log
    ├── pinecone.log
    └── obsidian.log
```

---

## Fonctionnement Détaillé

### Étape 1 : Extraction Structurelle (GitNexus)

**Commande** : `npx gitnexus analyze --skills --embeddings`

GitNexus parse le dépôt avec Tree-sitter et produit un graphe **LadybugDB** :

- **Nœuds** : fichiers, classes, fonctions, méthodes, interfaces
- **Arêtes typées** : `IMPORTS`, `CALLS`, `EXTENDS`, `IMPLEMENTS`, `MEMBER_OF`
- **Score de confiance** : 0.0 à 1.0 pour chaque arête
- **Processus** : flux d'exécution depuis les points d'entrée

**Exemple de nœud GitNexus** :
```json
{
  "uid": "Function:validateEmail",
  "kind": "Function",
  "filePath": "src/auth/validate.ts",
  "startLine": 15,
  "signature": "function validateEmail(email: string): ValidationResult",
  "outgoing_calls": ["checkFormat", "isDisposable"],
  "incoming_calls": ["handleLogin", "registerUser"]
}
```

### Étape 2 : Enrichissement Sémantique (Graphify)

Graphify analyse le code et produit :

- `graph.json` : graphe avec clustering Leiden
- `GRAPH_REPORT.md` : résumé narratif par cluster
- `graph.html` : visualisation interactive

**Exemple de nœud Graphify** :
```json
{
  "name": "src/auth/validate.ts",
  "cluster": "Authentication",
  "clusterSummary": "Gère l'authentification : validation, hachage, tokens",
  "centralityScore": 0.82,
  "connections": {
    "surprising": [{
      "target": "src/billing/invoice.ts",
      "reason": "Appel indirect via helper partagé"
    }]
  }
}
```

### Étape 3 : Extraction Documentaire (GraphRAG)

**Commande** : `bash scripts/index-doc-graph.sh`

GraphRAG analyse tous les documents Markdown (docs/, specs/, ADR) et extrait :

- **Entités nommées** : concepts, règles, politiques, services, API
- **Relations typées** : REQUIRES, IMPLEMENTS, DEPENDS_ON, DESCRIBED_BY
- **Communautés** : clusters de concepts fortement liés
- **Résumés hiérarchiques** : synthèses à plusieurs niveaux de granularité

**Pipeline GraphRAG** :

1. **Chargement** : Copie des documents dans `graphrag_data/input/`
2. **Extraction** : LLM identifie entités et relations
3. **Clustering** : Algorithme de Leiden détecte les communautés
4. **Résumés** : LLM génère des synthèses par communauté
5. **Export** : Conversion Parquet → JSON

**Exemple d'entité GraphRAG** :
```json
{
  "id": "ent-002",
  "name": "Idempotency Key",
  "type": "policy",
  "description": "Clé d'idempotence obligatoire pour éviter les doubles paiements",
  "documents": ["docs/payment-guidelines.md", "specs/payment-api.md"],
  "community": "Payment Processing"
}
```

**Exemple de relation GraphRAG** :
```json
{
  "source": "Stripe",
  "target": "Idempotency Key",
  "type": "REQUIRES",
  "description": "Stripe Checkout nécessite une clé d'idempotence pour chaque requête",
  "confidence": 0.98
}
```

**Avantages de GraphRAG** :

- ✅ **Contexte métier** : Chaque fonction est liée aux règles qu'elle implémente
- ✅ **Anti-hallucination** : Les contraintes proviennent des documents officiels
- ✅ **Traçabilité** : Chaque règle est liée à sa source documentaire
- ✅ **Recherche sémantique** : Retrouver toutes les fonctions liées à une règle métier

### Étape 4 : Fusion des Graphes

Le script `fuse-graphs.js` :

1. Charge les trois graphes (GitNexus, Graphify, GraphRAG)
2. Déduplique les nœuds par `filePath`
3. Fusionne les propriétés :
   - Structure (GitNexus) : dépendances, appels, flux
   - Sémantique (Graphify) : cluster, résumé, centralité
   - Documentaire (GraphRAG) : entités métier, règles, politiques
4. Lie les entités documentaires aux nœuds de code via heuristiques
5. Sauvegarde dans `graph/super-graph.json` et `graph/entity-graph.json`

**Algorithme de liaison entité-code** :

```javascript
// Pour chaque entité documentaire
for (const entity of docGraph.entities) {
  // Pour chaque nœud de code
  for (const node of codeNodes) {
    // Heuristiques de correspondance
    const nameMatch = nodeName.includes(entityName);
    const pathMatch = filePath.includes(entityName);
    const typeMatch = entity.type === 'module' || 'api' || 'service';
    
    if ((nameMatch || pathMatch) && typeMatch) {
      // Créer un lien
      node.documentEntities.push(entity);
    }
  }
}
```

**Exemple de nœud fusionné** :
```json
{
  "uid": "Function:validateEmail",
  "filePath": "src/auth/validate.ts",
  "signature": "function validateEmail(email: string): ValidationResult",
  "dependencies": ["checkFormat", "isDisposable"],
  "callers": ["handleLogin", "registerUser"],
  "cluster": "Authentication",
  "clusterSummary": "Gère l'authentification...",
  "centralityScore": 0.82,
  "surprisingConnections": ["src/billing/invoice.ts"],
  "documentEntities": [
    {
      "id": "ent-015",
      "name": "Email Validation",
      "type": "rule",
      "description": "Validation des emails selon RFC 5322",
      "community": "Authentication"
    }
  ]
}
```

### Étape 5 : Vectorisation (Pinecone)

Le script `pinecone_upload.py` :

1. Lit `super-graph.json`
2. Pour chaque nœud, génère un texte :
   ```
   validateEmail | Type: Function | function validateEmail(...) | Gère l'authentification... | Cluster: Authentication
   ```
3. Génère un embedding (384 dimensions)
4. Upload vers Pinecone avec métadonnées

**Recherche hybride** :
- Vectorielle (Pinecone) : recherche sémantique
- Texte (GitNexus) : recherche structurelle
- BM25 : recherche par nom de fichier

### Étape 6 : Génération Obsidian

Le script `generate-obsidian-notes.js` :

1. Lit `super-graph.json`
2. Groupe les nœuds par cluster
3. Génère une note Markdown par cluster :
   - Frontmatter YAML (tags, métadonnées)
   - Résumé du cluster
   - Liste des fichiers avec scores
   - Dépendances principales
   - Connexions surprenantes
4. Génère un index `_index.md`

**Exemple de note** :
```markdown
---
title: "Authentication"
tags: [codebase, cluster, authentication]
cluster: "Authentication"
nodeCount: 15
date: 2026-05-07
---

# Authentication

## Résumé

Gère l'authentification des utilisateurs : validation des entrées,
hachage des mots de passe, génération de tokens.

## Statistiques

- **Nombre de fichiers** : 15
- **Centralité moyenne** : 0.75

## Fichiers

- [[validateEmail]] `Function` (0.82)
- [[hashPassword]] `Function` (0.78)
- ...

## Dépendances principales

- `bcrypt`
- `jsonwebtoken`
- `validator`

## Connexions surprenantes

- ⚠️ [[src/billing/invoice.ts]]
```

---

## GraphRAG : Graphe Documentaire Détaillé

### Qu'est-ce que GraphRAG ?

**GraphRAG** (Graph Retrieval Augmented Generation) est un pipeline RAG développé par Microsoft qui remplace l'index vectoriel plat par un **graphe de connaissances**. Au lieu de simplement découper les documents en morceaux et de les comparer par similarité cosinus, il en extrait des **entités nommées**, les relie par des **relations typées**, détecte des **communautés** et produit des **résumés à plusieurs niveaux de granularité**.

### Pourquoi GraphRAG dans Axiom-Scaffold ?

**Problème résolu** : Le RAG classique répond souvent de manière fragmentaire, incapable de faire le lien entre des informations dispersées. Avec un graphe, l'agent peut suivre des chaînes de relations, découvrir des connexions indirectes et accéder à une **vue d'ensemble cohérente**.

**Bénéfices pour Axiom** :

1. **Documentation vivante** : Chaque fichier source est automatiquement associé aux spécifications, décisions d'architecture et règles métier qu'il implémente
2. **Compréhension métier immédiate** : Quand l'agent manipule `checkoutSession.ts`, il sait qu'il doit respecter la politique « PCI-DSS » et la règle « idempotency key obligatoire »
3. **Réduction drastique des hallucinations** : Toutes les contraintes sont extraites des documents officiels ; l'agent ne peut pas inventer de règle métier

### Installation et Configuration

#### 1. Installation de GraphRAG

```bash
# Installer GraphRAG
pip install graphrag

# Vérifier l'installation
graphrag --version
```

#### 2. Configuration

Le fichier `graphrag_data/settings.yaml` contient la configuration complète :

```yaml
# LLM Configuration
llm:
  type: openai_chat_completion
  model: gpt-4o-mini
  api_key: ${GRAPHRAG_API_KEY}
  
# Pour utiliser un modèle local (Ollama)
# llm:
#   type: openai_chat_completion
#   api_base: http://localhost:11434/v1
#   model: phi3:mini

# Embedding Configuration
embeddings:
  llm:
    type: openai_embedding
    model: text-embedding-3-small
    api_key: ${GRAPHRAG_API_KEY}

# Entity Extraction
entity_extraction:
  entity_types: [organization, person, geo, event, concept, 
                 technology, policy, rule, constraint, module, 
                 api, service]
  max_gleanings: 1
```

#### 3. Variables d'Environnement

Créer un fichier `graphrag_data/.env` :

```bash
# OpenAI API Key
GRAPHRAG_API_KEY=your-openai-api-key-here

# Alternative : Modèle local
# GRAPHRAG_API_BASE=http://localhost:11434/v1
# GRAPHRAG_MODEL=phi3:mini
```

### Pipeline d'Indexation GraphRAG

#### Étape 1 : Préparation des Documents

Le script `index-doc-graph.sh` copie automatiquement :

- `docs/*.md` : Documentation générale
- `specs/**/*.md` : Spécifications techniques
- `specs/architecture/decisions/*.md` : ADR (Architecture Decision Records)
- `specs/domain/*.md` : Règles métier
- `README.md` : Vue d'ensemble du projet

#### Étape 2 : Extraction des Entités et Relations

GraphRAG utilise un LLM pour analyser chaque document et identifier :

**Types d'entités** :
- `organization` : Stripe, AWS, GitHub
- `technology` : React, PostgreSQL, Redis
- `policy` : PCI-DSS, GDPR, Idempotency
- `rule` : Validation rules, Business rules
- `constraint` : Rate limits, Timeouts
- `module` : Authentication, Payment, Billing
- `api` : REST endpoints, GraphQL queries
- `service` : External services, Microservices

**Types de relations** :
- `REQUIRES` : A nécessite B
- `IMPLEMENTS` : A implémente B
- `DEPENDS_ON` : A dépend de B
- `DESCRIBED_BY` : A est décrit par B
- `PART_OF` : A fait partie de B
- `USES` : A utilise B

#### Étape 3 : Détection des Communautés

L'algorithme de **Leiden** regroupe les entités fortement connectées en communautés :

- **Niveau 0** (feuilles) : Sous-groupes spécifiques
- **Niveau 1** (intermédiaire) : Groupes fonctionnels
- **Niveau 2** (racine) : Domaines métier

**Exemple** :
```
Communauté "Payment Processing"
├── Sous-communauté "Stripe Integration"
│   ├── Stripe
│   ├── Checkout Session
│   └── Idempotency Key
└── Sous-communauté "Refund Management"
    ├── Refund Policy
    ├── Refund Workflow
    └── Notification
```

#### Étape 4 : Génération des Résumés

Pour chaque communauté, GraphRAG génère :

- **Résumé court** : 1-2 phrases
- **Résumé détaillé** : 1 paragraphe
- **Findings** : Points clés et insights

**Exemple de résumé** :
```
Communauté : Payment Processing

Résumé : Ce cluster couvre les règles liées aux transactions de paiement,
à la sécurité PCI-DSS et à l'intégration Stripe. Il inclut les politiques
d'idempotence, les workflows de remboursement et les webhooks.

Findings :
- Idempotency key obligatoire pour toutes les requêtes Stripe
- Conformité PCI-DSS requise
- Délai de remboursement : 30 jours maximum
- Taux de succès cible : > 95%
```

#### Étape 5 : Export vers JSON

Le script `export-graphrag.py` convertit les fichiers Parquet en JSON :

```json
{
  "entities": [
    {
      "id": "ent-001",
      "name": "Stripe",
      "type": "service",
      "description": "Passerelle de paiement...",
      "documents": ["docs/payment-guidelines.md"],
      "community": "Payment Processing",
      "degree": 15
    }
  ],
  "relations": [
    {
      "source": "Stripe",
      "target": "Idempotency Key",
      "type": "REQUIRES",
      "description": "Stripe nécessite une clé d'idempotence",
      "confidence": 0.98
    }
  ],
  "communities": [
    {
      "id": "comm-01",
      "title": "Payment Processing",
      "summary": "Règles de paiement et intégration Stripe",
      "level": 1,
      "size": 12
    }
  ]
}
```

### Liaison Entité-Code

Le script `fuse-graphs.js` lie automatiquement les entités documentaires aux nœuds de code :

**Heuristiques de correspondance** :

1. **Correspondance de nom** : `checkoutSession.ts` ↔ entité "Checkout Session"
2. **Correspondance de chemin** : `src/payment/` ↔ entité "Payment Processing"
3. **Type compatible** : Fichier de type `module` ↔ entité de type `module`
4. **Mentions dans les commentaires** : JSDoc `@see docs/payment.md` ↔ entités du document

**Résultat** : Chaque nœud de code a une propriété `documentEntities` :

```json
{
  "filePath": "src/payment/checkoutSession.ts",
  "documentEntities": [
    {
      "id": "ent-002",
      "name": "Idempotency Key",
      "type": "policy",
      "description": "Clé d'idempotence obligatoire...",
      "community": "Payment Processing"
    },
    {
      "id": "ent-005",
      "name": "PCI-DSS",
      "type": "policy",
      "description": "Conformité PCI-DSS requise...",
      "community": "Security"
    }
  ]
}
```

### Utilisation de GraphRAG

#### 1. Indexation Documentaire

```bash
# Indexer les documents
bash scripts/index-doc-graph.sh

# Résultat :
# - graphrag_data/output/ : Données Parquet
# - graph/doc-graph.json : Graphe JSON
# - logs/graphrag-index.log : Logs
```

#### 2. Recherche Locale (Question Pointue)

GraphRAG peut répondre à des questions spécifiques en parcourant le graphe :

```bash
# Exemple : Quels sont les prérequis de sécurité pour createSession() ?
# → GraphRAG extrait les entités liées à "createSession"
# → Parcourt leurs voisines (PCI-DSS, Idempotency Key)
# → Compose un prompt avec toutes ces informations
```

#### 3. Recherche Globale (Vue d'Ensemble)

GraphRAG peut produire une synthèse en utilisant les résumés de communautés :

```bash
# Exemple : Comment notre système gère-t-il les paiements ?
# → GraphRAG utilise le résumé de la communauté "Payment Processing"
# → Répond sans détailler chaque document
```

### Bénéfices Directs pour la Lutte contre les Hallucinations

1. **Contexte métier intégré** : Quand l'agent doit modifier `checkoutSession.ts`, le minimiseur de contexte injecte automatiquement « Règle : idempotency key obligatoire (source : spec payment-api) ». L'agent ne peut pas l'ignorer.

2. **Détection de conflits** : Si une modification proposée entre en conflit avec une règle documentée (ex : suppression d'un appel à Stripe), l'analyse d'impact peut vérifier la présence d'une relation `IMPLEMENTS_POLICY` et lever une alerte.

3. **Recherche sémantique** : Grâce aux embeddings des entités documentaires, l'agent peut retrouver instantanément toutes les fonctions liées à une règle métier, même si les mots exacts diffèrent.

4. **Génération automatique de skills** : La Couche 7 peut extraire des entités récurrentes (ex : "idempotency key appliquée à 5 fonctions") pour créer un skill dédié.

### Maintenance et Mise à Jour

#### Mise à Jour Incrémentale

```bash
# Réindexer après ajout de documents
bash scripts/index-doc-graph.sh

# GraphRAG détecte automatiquement les nouveaux documents
# et met à jour le graphe de manière incrémentale
```

#### Nettoyage

```bash
# Supprimer le cache GraphRAG
rm -rf graphrag_data/cache/*

# Réinitialiser complètement
rm -rf graphrag_data/output/*
bash scripts/index-doc-graph.sh
```

#### Monitoring

```bash
# Vérifier les statistiques
cat graph/doc-graph.json | jq '.metadata'

# Exemple de sortie :
# {
#   "source": "graphrag",
#   "timestamp": "2026-05-09T14:30:00Z",
#   "entity_count": 45,
#   "relation_count": 78,
#   "community_count": 8
# }
```

---

## Utilisation

### Indexation Complète

```bash
# Indexer la mémoire (GitNexus + Graphify + Fusion + Pinecone + Obsidian)
./scripts/index-memory.sh
```

**Durée** : 2-10 minutes selon la taille du projet

**Résultat** :
- `graph/super-graph.json` : graphe unifié
- Index Pinecone `axiom-memory` : vecteurs
- `vault/` : notes Obsidian

### Interrogation de la Mémoire

#### 1. Via GitNexus (MCP)

```bash
# Recherche de contexte
npx gitnexus query "validateEmail"

# Analyse d'impact
npx gitnexus impact "src/auth/validate.ts"

# Extraction de sous-graphe
npx gitnexus context --name "validateEmail"
```

#### 2. Via Pinecone (API)

```python
import pinecone

pc = Pinecone(api_key="...")
index = pc.Index("axiom-memory")

# Recherche sémantique
results = index.query(
    vector=embedding,
    top_k=10,
    include_metadata=True
)
```

#### 3. Via Obsidian (Navigation)

```bash
# Ouvrir le vault dans Obsidian
open vault/
```

Naviguez visuellement entre les clusters avec les wikilinks `[[...]]`.

---

## Intégration avec les Autres Couches

### Couche 0 (Harness Engineering)

- **Bootstrap** : `bootstrap.sh` installe GitNexus et Pinecone
- **Hooks** : `after-agent.sh` appelle `index-memory.sh` après modifications

### Couche 2 (Spécifications)

- Les specs (OpenAPI, GraphQL) sont stockées comme nœuds documentaires dans le super-graphe

### Couche 3 (Minimiseur)

- Interroge la mémoire pour extraire le sous-graphe pertinent (≤ 500 tokens)

### Couche 4 (Design)

- Les tokens de design sont enregistrés dans le vault Obsidian

### Couche 5 (Exécution)

- L'analyse d'impact avant modification utilise `gitnexus impact`

### Couche 6 (Visualisation)

- Le super-graphe est la source du fichier `graph.html`

### Couche 7 (Apprentissage)

- Les patterns sont stockés dans Obsidian et vectorisés dans Pinecone

### Couche 8 (Sécurité)

- Les vulnérabilités détectées deviennent des annotations dans le super-graphe

---

## Configuration

### Variables d'Environnement

Ajoutez dans `.env` :

```bash
# Pinecone
PINECONE_API_KEY=your-api-key-here
PINECONE_ENVIRONMENT=us-east-1

# GraphRAG
GRAPHRAG_API_KEY=your-openai-api-key-here  # Pour LLM et embeddings

# Embedding (optionnel)
AXIOM_EMBEDDING_API=openai  # ou 'local' pour sentence-transformers
OPENAI_API_KEY=your-openai-key  # si AXIOM_EMBEDDING_API=openai
```

### Installation des Dépendances

```bash
# GitNexus
npm install -g gitnexus

# GraphRAG
pip install graphrag pandas pyarrow

# Pinecone
pip install pinecone-client

# Embeddings locaux (optionnel)
pip install sentence-transformers
```
# GitNexus
npm install -g gitnexus

# Pinecone
pip install pinecone-client

# Embeddings locaux (optionnel)
pip install sentence-transformers
```

---

## Commandes Utiles

### Indexation

```bash
# Indexation complète
./scripts/index-memory.sh

# Indexation partielle
npx gitnexus analyze
node scripts/fuse-graphs.js
node scripts/generate-obsidian-notes.js
```

### Requêtes

```bash
# Recherche de symbole
npx gitnexus query "validateEmail"

# Contexte d'un fichier
npx gitnexus context --file "src/auth/validate.ts"

# Impact d'une modification
npx gitnexus impact "src/auth/validate.ts"
```

### Maintenance

```bash
# Nettoyer les logs
rm -rf logs/*.log

# Réinitialiser l'index Pinecone
python3 scripts/pinecone_reset.py

# Régénérer le vault Obsidian
node scripts/generate-obsidian-notes.js
```

---

## Dépannage

### GitNexus non disponible

```bash
# Installer GitNexus
npm install -g gitnexus

# Vérifier l'installation
gitnexus --version
```

### Pinecone : erreur d'authentification

```bash
# Vérifier la clé API
echo $PINECONE_API_KEY

# Configurer dans .env
echo "PINECONE_API_KEY=your-key" >> .env
```

### Graphify non disponible

Graphify est optionnel. Si absent, le système fonctionne avec GitNexus seul.

### Vault Obsidian vide

```bash
# Régénérer le vault
node scripts/generate-obsidian-notes.js

# Vérifier le super-graphe
cat graph/super-graph.json | jq '.nodes | length'
```

---

## Bonnes Pratiques

### Pour l'Indexation

1. **Indexer régulièrement** : après chaque PR mergée
2. **Vérifier les logs** : consulter `logs/` en cas d'erreur
3. **Nettoyer les anciens graphes** : supprimer les fichiers obsolètes

### Pour les Requêtes

1. **Commencer par GitNexus** : recherche structurelle précise
2. **Utiliser Pinecone** : recherche sémantique floue
3. **Naviguer dans Obsidian** : exploration visuelle

### Pour la Maintenance

1. **Sauvegarder le vault** : versionner `vault/` dans Git
2. **Monitorer Pinecone** : surveiller l'usage et les coûts
3. **Documenter les clusters** : enrichir manuellement les notes Obsidian

---

## Métriques

### Performance

- **Indexation** : 2-10 minutes (selon taille du projet)
- **Recherche vectorielle** : <100ms (Pinecone)
- **Recherche structurelle** : <50ms (GitNexus)

### Stockage

- **Super-graphe** : ~1-10 MB (JSON)
- **Index Pinecone** : ~100 KB par 1000 nœuds
- **Vault Obsidian** : ~1-5 MB (Markdown)

---

## Conclusion

La **Couche 1 (Mémoire Universelle)** transforme Axiom-Scaffold en un système avec **mémoire persistante**. L'agent dispose maintenant d'un **contexte profond et cumulatif** qui lui permet de :

- ✅ Comprendre la structure du code
- ✅ Identifier les clusters fonctionnels
- ✅ Rechercher rapidement des symboles
- ✅ Analyser l'impact des modifications
- ✅ Naviguer visuellement dans le code

**Prochaine étape** : Couche 2 (Spécifications) 🚀

---

**Version** : 1.0.0  
**Dernière mise à jour** : 2026-05-07  
**Statut** : ✅ Opérationnel
