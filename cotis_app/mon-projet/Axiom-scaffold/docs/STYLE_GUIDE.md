# Guide de Style — Axiom-Scaffold

## Principes Généraux

### 1. Clarté avant Concision
Le code doit être compréhensible au premier coup d'œil.

### 2. Cohérence
Suivre les conventions établies dans le projet.

### 3. Simplicité
Éviter la complexité inutile.

## JavaScript / TypeScript

### Nommage

#### Variables et Fonctions
```typescript
// ✅ Bon
const userName = 'John';
const getUserById = (id: string) => { ... };

// ❌ Mauvais
const un = 'John';
const getUsr = (i: string) => { ... };
```

#### Classes et Interfaces
```typescript
// ✅ Bon
class UserService { ... }
interface UserRepository { ... }

// ❌ Mauvais
class userservice { ... }
interface user_repository { ... }
```

#### Constantes
```typescript
// ✅ Bon
const MAX_RETRY_COUNT = 3;
const API_BASE_URL = 'https://api.example.com';

// ❌ Mauvais
const maxRetryCount = 3;
const apiBaseUrl = 'https://api.example.com';
```

### Fonctions

#### Taille
- Maximum 100 lignes par fonction
- Si plus long, découper en sous-fonctions

#### Paramètres
```typescript
// ✅ Bon : objet pour > 3 paramètres
interface CreateUserParams {
  name: string;
  email: string;
  age: number;
  address: string;
}

const createUser = (params: CreateUserParams) => { ... };

// ❌ Mauvais : trop de paramètres
const createUser = (name: string, email: string, age: number, address: string) => { ... };
```

#### Retour
```typescript
// ✅ Bon : type de retour explicite
const getUser = (id: string): Promise<User> => { ... };

// ❌ Mauvais : type de retour implicite
const getUser = (id: string) => { ... };
```

### Commentaires

#### JSDoc
```typescript
/**
 * Récupère un utilisateur par son ID
 * 
 * @param id - L'identifiant unique de l'utilisateur
 * @returns Une promesse contenant l'utilisateur
 * @throws {UserNotFoundError} Si l'utilisateur n'existe pas
 * 
 * @example
 * const user = await getUser('123');
 * console.log(user.name);
 */
const getUser = async (id: string): Promise<User> => {
  // ...
};
```

#### Commentaires Inline
```typescript
// ✅ Bon : explique le "pourquoi"
// On utilise un délai de 100ms pour éviter le rate limiting
await delay(100);

// ❌ Mauvais : explique le "quoi" (évident)
// Attendre 100ms
await delay(100);
```

### Gestion d'Erreurs

```typescript
// ✅ Bon : erreurs typées
class UserNotFoundError extends Error {
  constructor(userId: string) {
    super(`User not found: ${userId}`);
    this.name = 'UserNotFoundError';
  }
}

const getUser = async (id: string): Promise<User> => {
  const user = await db.findUser(id);
  if (!user) {
    throw new UserNotFoundError(id);
  }
  return user;
};

// ❌ Mauvais : erreurs génériques
const getUser = async (id: string): Promise<User> => {
  const user = await db.findUser(id);
  if (!user) {
    throw new Error('Not found');
  }
  return user;
};
```

### Async/Await

```typescript
// ✅ Bon : async/await
const fetchData = async () => {
  try {
    const response = await fetch(url);
    const data = await response.json();
    return data;
  } catch (error) {
    logger.error('Failed to fetch data', error);
    throw error;
  }
};

// ❌ Mauvais : callbacks imbriqués
const fetchData = (callback) => {
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
};
```

## Tests

### Structure

```typescript
describe('UserService', () => {
  describe('getUser', () => {
    it('should return user when user exists', async () => {
      // Arrange
      const userId = '123';
      const expectedUser = { id: userId, name: 'John' };
      mockDb.findUser.mockResolvedValue(expectedUser);

      // Act
      const result = await userService.getUser(userId);

      // Assert
      expect(result).toEqual(expectedUser);
    });

    it('should throw UserNotFoundError when user does not exist', async () => {
      // Arrange
      const userId = '999';
      mockDb.findUser.mockResolvedValue(null);

      // Act & Assert
      await expect(userService.getUser(userId)).rejects.toThrow(UserNotFoundError);
    });
  });
});
```

### Nommage

```typescript
// ✅ Bon : descriptif
it('should return 401 when token is expired', () => { ... });

// ❌ Mauvais : vague
it('should work', () => { ... });
```

## Markdown

### Titres

```markdown
# Titre Principal (H1) - Un seul par document

## Section (H2)

### Sous-section (H3)

#### Sous-sous-section (H4)
```

### Listes

```markdown
<!-- ✅ Bon : cohérent -->
- Item 1
- Item 2
- Item 3

<!-- ❌ Mauvais : incohérent -->
- Item 1
* Item 2
+ Item 3
```

### Code

````markdown
<!-- ✅ Bon : langage spécifié -->
```typescript
const hello = 'world';
```

<!-- ❌ Mauvais : pas de langage -->
```
const hello = 'world';
```
````

### Liens

```markdown
<!-- ✅ Bon : descriptif -->
Voir la [documentation de l'API](docs/API.md)

<!-- ❌ Mauvais : générique -->
Cliquez [ici](docs/API.md)
```

## Git

### Messages de Commit

```bash
# Format
type(scope): message court (≤ 50 caractères)

Description détaillée si nécessaire (≤ 72 caractères par ligne)

Refs: TICKET-123
```

#### Types
- `feat` : nouvelle fonctionnalité
- `fix` : correction de bug
- `docs` : documentation
- `style` : formatage, point-virgules manquants, etc.
- `refactor` : refactoring sans changement de comportement
- `test` : ajout ou modification de tests
- `chore` : tâches de maintenance

#### Exemples

```bash
# ✅ Bon
feat(auth): add JWT token validation

Implement middleware to validate JWT tokens on protected routes.
Add unit tests for token validation logic.

Refs: AX-123

# ❌ Mauvais
update stuff
```

## Fichiers

### Taille
- Maximum 300 lignes par fichier
- Si plus long, découper en modules

### Organisation

```
src/
├── controllers/     # Contrôleurs HTTP
├── services/        # Logique métier
├── repositories/    # Accès aux données
├── models/          # Modèles de données
├── utils/           # Utilitaires
├── types/           # Types TypeScript
└── index.ts         # Point d'entrée
```

## Sécurité

### Secrets

```typescript
// ✅ Bon : variables d'environnement
const apiKey = process.env.API_KEY;

// ❌ Mauvais : secrets en dur
const apiKey = 'sk-1234567890abcdef';
```

### Validation

```typescript
// ✅ Bon : validation des entrées
const createUser = (data: unknown) => {
  const validated = userSchema.parse(data);
  return db.createUser(validated);
};

// ❌ Mauvais : pas de validation
const createUser = (data: any) => {
  return db.createUser(data);
};
```

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

## Accessibilité

### HTML Sémantique

```html
<!-- ✅ Bon -->
<button onClick={handleClick}>Cliquez ici</button>

<!-- ❌ Mauvais -->
<div onClick={handleClick}>Cliquez ici</div>
```

### Attributs ARIA

```html
<!-- ✅ Bon -->
<button aria-label="Fermer le modal" onClick={close}>
  <Icon name="close" />
</button>

<!-- ❌ Mauvais -->
<button onClick={close}>
  <Icon name="close" />
</button>
```

---

**Version** : 1.0.0  
**Dernière mise à jour** : 2026-05-07
