# Standards de Codage

## Conventions de Nommage

### Variables

```typescript
// ✅ Bon
const userName = 'John';
const isActive = true;
const itemCount = 10;

// ❌ Mauvais
const un = 'John';
const active = true;
const count = 10;
```

### Fonctions

```typescript
// ✅ Bon : verbe + nom
function getUserById(id: string): User { ... }
function calculateTotal(items: Item[]): number { ... }
function validateEmail(email: string): boolean { ... }

// ❌ Mauvais
function user(id: string): User { ... }
function total(items: Item[]): number { ... }
function email(email: string): boolean { ... }
```

### Classes

```typescript
// ✅ Bon : nom
class UserService { ... }
class PaymentProcessor { ... }
class EmailValidator { ... }

// ❌ Mauvais
class UserServiceClass { ... }
class ProcessPayment { ... }
class ValidateEmail { ... }
```

### Constantes

```typescript
// ✅ Bon
const MAX_RETRY_COUNT = 3;
const API_BASE_URL = 'https://api.example.com';
const DEFAULT_TIMEOUT = 5000;

// ❌ Mauvais
const maxRetryCount = 3;
const apiBaseUrl = 'https://api.example.com';
const defaultTimeout = 5000;
```

---

## Structure des Fichiers

### Organisation

```
src/
├── components/       # Composants UI
├── services/         # Logique métier
├── repositories/     # Accès aux données
├── models/           # Modèles de données
├── utils/            # Utilitaires
├── types/            # Types TypeScript
├── hooks/            # Hooks React (si applicable)
└── index.ts          # Point d'entrée
```

### Imports

```typescript
// ✅ Bon : ordre et groupement
import React, { useState, useEffect } from 'react';
import { Button, Input } from '@/components';
import { useAuth } from '@/hooks';
import type { User } from '@/types';

// ❌ Mauvais : désordre
import type { User } from '@/types';
import React from 'react';
import { useAuth } from '@/hooks';
import { Button } from '@/components';
```

---

## Formatage

### Indentation

- **2 espaces** (pas de tabs)
- **Cohérent** dans tout le projet

### Longueur de Ligne

- **Maximum 100 caractères**
- **Découper** si trop long

### Accolades

```typescript
// ✅ Bon : accolades sur la même ligne
if (condition) {
  doSomething();
}

// ❌ Mauvais : accolades sur une nouvelle ligne
if (condition)
{
  doSomething();
}
```

### Espaces

```typescript
// ✅ Bon : espaces autour des opérateurs
const sum = a + b;
const isValid = x > 0 && y < 10;

// ❌ Mauvais : pas d'espaces
const sum=a+b;
const isValid=x>0&&y<10;
```

---

## Commentaires

### JSDoc

```typescript
/**
 * Calcule la somme de deux nombres
 * 
 * @param a - Premier nombre
 * @param b - Deuxième nombre
 * @returns La somme de a et b
 * 
 * @example
 * const result = add(2, 3); // 5
 */
function add(a: number, b: number): number {
  return a + b;
}
```

### Commentaires Inline

```typescript
// ✅ Bon : explique le "pourquoi"
// On utilise un délai de 100ms pour éviter le rate limiting
await delay(100);

// ❌ Mauvais : explique le "quoi" (évident)
// Attendre 100ms
await delay(100);
```

---

## Gestion d'Erreurs

### Try-Catch

```typescript
// ✅ Bon : erreurs typées
try {
  const user = await getUser(id);
  return user;
} catch (error) {
  if (error instanceof UserNotFoundError) {
    logger.warn(`User not found: ${id}`);
    return null;
  }
  throw error;
}

// ❌ Mauvais : erreurs génériques
try {
  const user = await getUser(id);
  return user;
} catch (error) {
  console.log('Error');
  return null;
}
```

### Erreurs Personnalisées

```typescript
// ✅ Bon : erreurs typées
class UserNotFoundError extends Error {
  constructor(userId: string) {
    super(`User not found: ${userId}`);
    this.name = 'UserNotFoundError';
  }
}

throw new UserNotFoundError(id);

// ❌ Mauvais : erreurs génériques
throw new Error('Not found');
```

---

## Async/Await

```typescript
// ✅ Bon : async/await
async function fetchData() {
  try {
    const response = await fetch(url);
    const data = await response.json();
    return data;
  } catch (error) {
    logger.error('Failed to fetch data', error);
    throw error;
  }
}

// ❌ Mauvais : callbacks
function fetchData(callback) {
  fetch(url, (error, response) => {
    if (error) {
      callback(error);
    } else {
      response.json((error, data) => {
        if (error) {
          callback(error);
        } else {
          callback(null, data);
        }
      });
    }
  });
}
```

---

## Performance

### Éviter les Boucles Imbriquées

```typescript
// ✅ Bon : O(n)
const userMap = new Map(users.map(u => [u.id, u]));
const enrichedOrders = orders.map(o => ({
  ...o,
  user: userMap.get(o.userId)
}));

// ❌ Mauvais : O(n²)
const enrichedOrders = orders.map(o => ({
  ...o,
  user: users.find(u => u.id === o.userId)
}));
```

### Mémoïsation

```typescript
// ✅ Bon : mémoïsation
const memoizedExpensiveFunction = memoize(expensiveFunction);

// ❌ Mauvais : recalcul à chaque fois
const result = expensiveFunction(input);
```

---

**Version** : 1.0.0  
**Dernière mise à jour** : 2026-05-07
