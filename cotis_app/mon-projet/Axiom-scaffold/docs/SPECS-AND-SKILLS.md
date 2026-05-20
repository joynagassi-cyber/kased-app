# Couche 2 — Spécifications & Compétences

## 🎯 Vue d'Ensemble

La **Couche 2** d'Axiom-Scaffold établit deux piliers fondamentaux pour le développement piloté par agents IA :

1. **Pilier A — Spécifications** : Documentation structurée, versionnable et validable
2. **Pilier B — Compétences (Skills)** : Modules de connaissances spécialisées chargés dynamiquement

Cette couche transforme l'agent d'un exécutant aveugle en un **architecte informé** capable de :
- Comprendre les contraintes et décisions architecturales
- Respecter les standards de code et de sécurité
- Charger les compétences nécessaires selon le contexte
- Valider automatiquement la conformité des spécifications

---

## 📋 Pilier A — Spécifications

### Objectif

Fournir une **source de vérité unique** pour :
- Les décisions architecturales (ADR)
- Les règles immuables (constitution)
- Les standards de code et sécurité
- Les contrats d'API (OpenAPI, GraphQL)
- Le glossaire métier

### Structure

```
specs/
├── architecture/
│   ├── overview.md              # Vue d'ensemble de l'architecture
│   └── decisions/
│       └── 001-template.md      # Template ADR
├── rules/
│   ├── constitution.md          # Règles IMMUABLES
│   ├── coding-standards.md      # Standards de code
│   └── security-policies.md     # Politiques de sécurité
├── technical/
│   └── api-contracts/
│       └── example-api.openapi.yaml  # Exemple OpenAPI 3.1
└── domain/
    └── glossaire.md             # Glossaire métier
```

### Types de Spécifications

#### 1. Architecture Decision Records (ADR)

**Localisation** : `specs/architecture/decisions/`

**Format** : Markdown avec frontmatter YAML

**Template** : `001-template.md`

**Exemple** :
```markdown
---
id: ADR-001
title: Utilisation de PostgreSQL pour la base de données
status: accepted
date: 2026-05-07
deciders: [Alice, Bob]
---

# ADR-001 : Utilisation de PostgreSQL

## Contexte
Nous avons besoin d'une base de données relationnelle...

## Décision
Nous utiliserons PostgreSQL 15+

## Conséquences
- ✅ ACID complet
- ✅ JSON natif
- ❌ Courbe d'apprentissage
```

#### 2. Constitution (Règles Immuables)

**Localisation** : `specs/rules/constitution.md`

**Caractéristiques** :
- ❌ **NON MODIFIABLE** par les agents
- ✅ Principes fondamentaux du projet
- ✅ Contraintes de sécurité
- ✅ Limites d'autonomie

**Exemple** :
```markdown
# Constitution du Projet

## Article 1 : Sécurité
- Aucun secret ne doit être commité
- Toute entrée utilisateur doit être validée
```

#### 3. Standards de Code

**Localisation** : `specs/rules/coding-standards.md`

**Contenu** :
- Conventions de nommage
- Structure des fichiers
- Patterns recommandés
- Anti-patterns interdits

#### 4. Contrats d'API

**Localisation** : `specs/technical/api-contracts/`

**Formats supportés** :
- OpenAPI 3.0/3.1 (`.yaml`, `.json`)
- GraphQL Schema (`.graphql`)
- AsyncAPI (`.yaml`)

**Validation automatique** : `scripts/validate-specs.js`

#### 5. Glossaire Métier

**Localisation** : `specs/domain/glossaire.md`

**Format** :
```markdown
# Glossaire

## Utilisateur
Personne physique ayant un compte sur la plateforme.

## Session
Période d'activité authentifiée d'un utilisateur.
```

---

## 🧩 Pilier B — Compétences (Skills)

### Objectif

Fournir des **modules de connaissances spécialisées** que l'agent charge dynamiquement selon :
- Les mots-clés de la tâche
- Le type de fichier manipulé
- Le contexte du projet

### Structure

```
skills/
├── registry.json            # Registre central des skills
├── general/
│   └── debugging.md         # Exemple : skill de debugging
├── devops/
│   └── .gitkeep
├── design/
│   └── .gitkeep
└── security/
    └── .gitkeep
```

### Format Canonique d'un Skill

Chaque skill est un fichier Markdown avec frontmatter YAML :

```markdown
---
id: debugging
name: Debugging Systématique
version: 1.0.0
category: general
triggers:
  - debug
  - bug
  - error
  - crash
  - exception
description: Méthodologie de debugging systématique
---

# Debugging Systématique

## Processus

### 1. Reproduire
- Isoler le cas minimal
- Documenter les étapes

### 2. Hypothèses
- Lister 3 hypothèses
- Tester la plus probable

### 3. Vérifier
- Ajouter des logs
- Utiliser un debugger

## Anti-Patterns

❌ Modifier au hasard
❌ Ignorer les logs
❌ Ne pas tester la correction

## Exemples

### Exemple 1 : NullPointerException
...
```

### Champs du Frontmatter

| Champ         | Type     | Obligatoire | Description                       |
| ------------- | -------- | ----------- | --------------------------------- |
| `id`          | string   | ✅           | Identifiant unique                |
| `name`        | string   | ✅           | Nom lisible                       |
| `version`     | string   | ✅           | Version sémantique                |
| `category`    | string   | ✅           | Catégorie (general, devops, etc.) |
| `triggers`    | string[] | ✅           | Mots-clés déclencheurs            |
| `description` | string   | ✅           | Description courte                |
| `author`      | string   | ❌           | Auteur du skill                   |
| `tags`        | string[] | ❌           | Tags supplémentaires              |
| `requires`    | string[] | ❌           | Dépendances (autres skills)       |

### Registre des Skills

**Localisation** : `skills/registry.json`

**Format** :
```json
{
  "version": "1.0.0",
  "skills": [
    {
      "id": "debugging",
      "name": "Debugging Systématique",
      "category": "general",
      "path": "skills/general/debugging.md",
      "triggers": ["debug", "bug", "error"],
      "version": "1.0.0"
    }
  ]
}
```

### Chargement Dynamique

L'agent charge automatiquement les skills pertinents selon :

1. **Mots-clés de la tâche** : si la tâche contient "debug", charge `debugging.md`
2. **Type de fichier** : si manipulation de `.sql`, charge `sql-optimization.md`
3. **Contexte du projet** : si projet React, charge `react-patterns.md`

**Exemple** :
```
Tâche : "Débugger l'erreur 500 sur /api/users"
→ Charge automatiquement : debugging.md, api-design.md, http-errors.md
```

---

## 🔧 Scripts de Gestion

### 1. Validation des Spécifications

**Script** : `scripts/validate-specs.js`

**Fonctionnalités** :
- ✅ Valide les schémas OpenAPI/GraphQL
- ✅ Vérifie les liens internes
- ✅ Valide le frontmatter YAML
- ✅ Détecte les ADR dupliqués
- ✅ Vérifie la constitution (immuabilité)

**Utilisation** :
```bash
# Valider toutes les specs
npm run validate:specs

# Ou directement
node scripts/validate-specs.js
```

**Sortie** :
```
✅ OpenAPI: example-api.openapi.yaml valide
✅ Frontmatter: 001-template.md valide
✅ Liens: aucun lien cassé
⚠️  ADR-003 : statut manquant
```

### 2. Import de Skills Externes

**Script** : `scripts/import-skills.mjs`

**Fonctionnalités** :
- ✅ Clone des dépôts de skills
- ✅ Valide le format canonique
- ✅ Met à jour le registre
- ✅ Gère les versions

**Utilisation** :
```bash
# Importer un skill depuis GitHub
./scripts/import-skills.sh https://github.com/user/skill-repo.git

# Ou directement
node scripts/import-skills.mjs https://github.com/user/skill-repo.git
```

**Exemple** :
```bash
./scripts/import-skills.sh https://github.com/axiom-skills/react-patterns.git
```

**Sortie** :
```
📦 Clonage de react-patterns...
✅ Skill valide : react-patterns v2.1.0
📝 Mise à jour du registre...
✅ Skill importé avec succès
```

---

## 🔄 Intégration avec les Autres Couches

### Couche 0 (Harness Engineering)

- Les specs sont **validées automatiquement** par le hook `pre-commit`
- Le script `after-agent.sh` appelle `validate-specs.sh`
- Les skills sont **référencés** dans `AGENTS.md`

### Couche 1 (Mémoire Universelle)

- Les specs sont **indexées** par GitNexus
- Les ADR sont **vectorisés** dans Pinecone
- Le glossaire est **intégré** au vault Obsidian

### Couche -1 (Auto-Optimisation)

- Les skills peuvent être **auto-optimisés** (expériences de type `prompt`)
- Les ADR documentent les **décisions d'optimisation**

---

## 📊 Métriques de Qualité

### Spécifications

- ✅ **Couverture** : 100% des endpoints documentés (OpenAPI)
- ✅ **Validité** : 0 erreur de validation
- ✅ **Liens** : 0 lien cassé
- ✅ **Frontmatter** : 100% des ADR avec frontmatter valide

### Skills

- ✅ **Format** : 100% des skills avec frontmatter valide
- ✅ **Triggers** : ≥ 3 mots-clés par skill
- ✅ **Exemples** : ≥ 2 exemples par skill
- ✅ **Anti-patterns** : ≥ 3 anti-patterns documentés

---

## 🚀 Workflow Complet

### 1. Créer une Nouvelle Spécification

```bash
# Créer un ADR
cp specs/architecture/decisions/001-template.md \
   specs/architecture/decisions/042-use-redis.md

# Éditer le fichier
nano specs/architecture/decisions/042-use-redis.md

# Valider
npm run validate:specs

# Commiter
git add specs/architecture/decisions/042-use-redis.md
git commit -m "docs(adr): add ADR-042 for Redis usage"
```

### 2. Importer un Skill Externe

```bash
# Importer
./scripts/import-skills.sh https://github.com/axiom-skills/sql-optimization.git

# Vérifier le registre
cat skills/registry.json

# Tester le chargement
# (l'agent chargera automatiquement le skill si la tâche contient "sql")
```

### 3. Modifier la Constitution

```bash
# ⚠️ ATTENTION : la constitution est IMMUABLE
# Toute modification doit être approuvée par un humain

# Éditer (avec précaution)
nano specs/rules/constitution.md

# Valider
npm run validate:specs

# Commiter avec justification
git add specs/rules/constitution.md
git commit -m "docs(constitution): add Article 5 - Data Privacy

BREAKING CHANGE: New immutable rule added.
Approved by: Alice, Bob
Refs: LEGAL-123"
```

---

## 🎯 Cas d'Usage

### Cas 1 : Développer une Nouvelle API

1. **Spécifier** : créer `specs/technical/api-contracts/users-api.openapi.yaml`
2. **Valider** : `npm run validate:specs`
3. **Implémenter** : l'agent lit le contrat OpenAPI et génère le code
4. **Vérifier** : les tests valident la conformité au contrat

### Cas 2 : Débugger une Erreur

1. **Tâche** : "Débugger l'erreur 500 sur /api/users"
2. **Chargement automatique** : l'agent charge `debugging.md`
3. **Application** : l'agent suit le processus du skill
4. **Documentation** : l'agent documente la solution dans un ADR

### Cas 3 : Refactoring Sécurisé

1. **Consultation** : l'agent lit `specs/rules/security-policies.md`
2. **Vérification** : l'agent vérifie la conformité du code existant
3. **Refactoring** : l'agent applique les corrections
4. **Validation** : `npm run validate:specs` + tests de sécurité

---

## 🔒 Sécurité

### Règles

- ❌ **Jamais de secrets** dans les specs (utiliser `.env`)
- ✅ **Constitution immuable** : toute modification nécessite approbation humaine
- ✅ **Validation automatique** : hook `pre-commit` bloque les specs invalides
- ✅ **Versioning** : toutes les specs sont versionnées dans Git

### Outils

- `validate-specs.js` : validation automatique
- `git-secrets` : détection de secrets
- `pre-commit` : blocage des commits invalides

---

## 📚 Ressources

### Documentation

- [OpenAPI Specification](https://spec.openapis.org/oas/latest.html)
- [GraphQL Schema Language](https://graphql.org/learn/schema/)
- [Architecture Decision Records](https://adr.github.io/)

### Exemples

- `specs/technical/api-contracts/example-api.openapi.yaml` : exemple complet OpenAPI 3.1
- `specs/architecture/decisions/001-template.md` : template ADR
- `skills/general/debugging.md` : exemple de skill

---

## 🎉 Conclusion

La **Couche 2** transforme Axiom-Scaffold en un environnement où :

- ✅ Les **spécifications sont la source de vérité**
- ✅ Les **skills sont chargés dynamiquement**
- ✅ La **validation est automatique**
- ✅ La **documentation est vivante**

L'agent n'est plus un simple exécutant, mais un **architecte informé** capable de :
- Comprendre les contraintes
- Respecter les standards
- Charger les compétences nécessaires
- Valider automatiquement son travail

---

**Version** : 1.0.0  
**Date** : 2026-05-07  
**Auteur** : Axiom-Scaffold Team
