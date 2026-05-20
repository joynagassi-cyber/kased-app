# Constitution du Projet

> **IMMUABLE** : Ce fichier définit les principes absolus que l'agent doit respecter en toutes circonstances.

## Principes Fondamentaux

### 1. Type Safety First

- **TypeScript strict obligatoire**
- **Pas de `any`** : utiliser `unknown` si le type est vraiment inconnu
- **Pas de `@ts-ignore`** : résoudre les erreurs de type
- **Typage exhaustif** : tous les paramètres et retours sont typés

### 2. Test-Driven Development

- **Les tests sont écrits AVANT le code**
- **Couverture à 100%** : branches, fonctions, lignes
- **Tests de mutation** : score ≥ 70%
- **Tests E2E** : pour les flux critiques

### 3. Contract-First

- **Toute API est définie en OpenAPI avant implémentation**
- **Les contrats sont la source de vérité**
- **Génération automatique** : types, clients, tests de contrat

### 4. Zéro Warning, Zéro Erreur

- **ESLint** : aucun warning toléré
- **Prettier** : formatage automatique
- **TypeScript** : aucune erreur de compilation
- **Tests** : tous les tests doivent passer

### 5. Sécurité par Défaut

- **Validation des entrées** : toute entrée utilisateur est validée
- **Pas de secrets dans le code** : utiliser des variables d'environnement
- **Requêtes préparées** : toute requête SQL utilise des paramètres
- **Principe du moindre privilège** : accès minimal nécessaire

### 6. Dépendances Contrôlées

- **Toute nouvelle librairie doit être validée**
- **Audit régulier** : `npm audit` sans vulnérabilités high/critical
- **Versions exactes** : pas de `^` ou `~` en production

---

## Règles de Conception

### Taille des Fonctions

- **Maximum 50 lignes** par fonction
- **Maximum 5 paramètres** par fonction
- **Une seule responsabilité** par fonction

### Taille des Fichiers

- **Maximum 200 lignes** par fichier
- **Maximum 10 exports** par fichier
- **Découper** si trop grand

### Organisation des Imports

```typescript
// 1. Librairies externes
import React from 'react';
import { useState } from 'react';

// 2. Librairies internes
import { Button } from '@/components';
import { useAuth } from '@/hooks';

// 3. Types
import type { User } from '@/types';
```

### Nommage

- **Variables** : `camelCase`
- **Constantes** : `UPPER_SNAKE_CASE`
- **Classes** : `PascalCase`
- **Fichiers** : `kebab-case.ts`
- **Composants React** : `PascalCase.tsx`

---

## Règles de Sécurité

### Validation des Entrées

```typescript
// ✅ Bon : validation avec Zod
const userSchema = z.object({
  email: z.string().email(),
  age: z.number().min(18)
});

const user = userSchema.parse(input);

// ❌ Mauvais : pas de validation
const user = input as User;
```

### Secrets

```typescript
// ✅ Bon : variable d'environnement
const apiKey = process.env.API_KEY;

// ❌ Mauvais : secret en dur
const apiKey = 'sk-1234567890';
```

### Requêtes SQL

```typescript
// ✅ Bon : requête préparée
const user = await db.query(
  'SELECT * FROM users WHERE id = $1',
  [userId]
);

// ❌ Mauvais : injection SQL
const user = await db.query(
  `SELECT * FROM users WHERE id = ${userId}`
);
```

---

## Règles de Tests

### Structure

```typescript
describe('ComponentName', () => {
  describe('methodName', () => {
    it('should do something when condition', () => {
      // Arrange
      const input = ...;
      
      // Act
      const result = methodName(input);
      
      // Assert
      expect(result).toBe(expected);
    });
  });
});
```

### Couverture

- **Branches** : 100%
- **Fonctions** : 100%
- **Lignes** : 100%
- **Statements** : 100%

### Mutation

- **Score** : ≥ 70%
- **Survivants** : ≤ 30%

---

## Règles de Documentation

### Code

- **JSDoc** : pour toutes les fonctions publiques
- **Commentaires** : expliquer le "pourquoi", pas le "quoi"
- **Exemples** : inclure des exemples d'utilisation

### Architecture

- **ADR** : pour toute décision architecturale
- **Diagrammes** : à jour (C4, UML, Mermaid)
- **README** : dans chaque module

---

## Communication Caveman (obligatoire)

### Principe

L'agent répond en **mode caveman full par défaut** pour économiser les tokens (65-75% d'économie) sans perte de précision technique.

### Règles

- **Pas de politesse** : "Sure!", "I'd be happy to help" interdits
- **Pas de remplissage** : "just", "really", "basically", "actually" supprimés
- **Pas d'explication verbeuse** : aller droit au but
- **Format** : [constat] [cause] [action]. [étape suivante].
- **Max 6 lignes** pour les réponses chat

### Invariants (jamais compressés)

- **Code blocks** : syntaxe complète, jamais compressée
- **Erreurs** : citées exactement, jamais paraphrasées
- **Termes techniques** : noms de fonctions, APIs, chemins de fichiers jamais abrégés
- **Stack traces** : préservées exactement
- **URLs et chemins** : jamais raccourcis
- **Numéros de version** : jamais abrégés
- **Patterns regex** : jamais modifiés
- **Requêtes SQL** : jamais compressées
- **Structure JSON/YAML** : préservée

### Désactivation automatique

Le mode caveman se désactive automatiquement pour :
- **Alertes de sécurité**
- **Confirmations d'actions destructives**
- **Notices légales**
- **Textes de licence**

### Niveaux

- **Lite** : professionnel, garde articles et phrases complètes
- **Full** : par défaut, fragments sans articles
- **Ultra** : télégraphique, abréviations (DB, auth, config)
- **Wenyan** : chinois classique, compression maximale

### Commandes

- `/caveman lite` : mode professionnel
- `/caveman full` : mode par défaut (fragments)
- `/caveman ultra` : mode télégraphique
- `stop caveman` : désactiver

### Configuration

Fichier : `Axiom-scaffold/config/caveman-rules.yaml`

### Exemple

**Avant (mode normal) :**
```
I'd be happy to help you with that! The issue you're experiencing is 
actually quite common. Basically, what's happening is that the 
authentication middleware is using the wrong comparison operator. 
I recommend that you change the `<` to `<=` in the token expiry check. 
This should resolve the problem.
```

**Après (caveman full) :**
```
Bug in auth middleware. Token expiry check use `<` not `<=`. Fix:
```

---

## Exceptions

Les exceptions à ces règles doivent être :

1. **Documentées** : commentaire `// EXCEPTION:` dans le code
2. **Justifiées** : ADR si exception architecturale
3. **Validées** : par au moins deux membres de l'équipe
4. **Temporaires** : avec une date de résolution

---

## Sanctions

Le non-respect de cette constitution entraîne :

1. **Commit bloqué** : par les hooks Git
2. **PR rejetée** : par la CI/CD
3. **Revue obligatoire** : par un senior

---

**Version** : 1.0.0  
**Dernière mise à jour** : 2026-05-07  
**Statut** : ✅ Actif
