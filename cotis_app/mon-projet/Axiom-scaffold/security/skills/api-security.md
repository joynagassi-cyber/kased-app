---
id: api-security
domain: security
triggers: [api, endpoint, rest, graphql, openapi, route, controller, handler]
priority: 9
version: 1.0.0
---

# Skill : Sécurisation d'API REST/GraphQL

## Objectif

Appliquer les bonnes pratiques de l'OWASP API Security Top 10 pour sécuriser les endpoints API.

## Contexte d'activation

Ce skill est activé automatiquement lorsque :
- Création ou modification d'un endpoint API
- Travail sur des routes/controllers
- Implémentation de handlers HTTP
- Définition de schémas OpenAPI/GraphQL

## Processus de sécurisation

### 1. Authentification et autorisation

#### Vérifications obligatoires
- ✅ Chaque endpoint sensible doit vérifier l'authentification
- ✅ Implémenter une vérification d'autorisation au niveau objet (BOLA/IDOR)
- ✅ Utiliser des tokens JWT avec expiration courte (<15 min)
- ✅ Implémenter un refresh token avec rotation

#### Exemple sécurisé
```typescript
// Middleware d'authentification
const authenticate = async (req, res, next) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  
  if (!token) {
    return res.status(401).json({ error: 'Authentication required' });
  }
  
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    req.user = await db.getUser(payload.userId);
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
};

// Middleware d'autorisation
const authorize = (resource: string) => {
  return async (req, res, next) => {
    const resourceId = req.params.id;
    const resource = await db.getResource(resourceId);
    
    if (resource.ownerId !== req.user.id && !req.user.isAdmin) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    
    next();
  };
};

// Utilisation
app.get('/api/documents/:id', authenticate, authorize('document'), getDocument);
```

### 2. Validation des entrées

#### Vérifications obligatoires
- ✅ Valider toutes les entrées avec un schéma strict (Zod, Joi, Yup)
- ✅ Utiliser des listes blanches (pas de listes noires)
- ✅ Limiter la taille des entrées
- ✅ Échapper les caractères spéciaux

#### Exemple sécurisé
```typescript
import { z } from 'zod';

const CreateUserSchema = z.object({
  name: z.string().min(1).max(100),
  email: z.string().email(),
  age: z.number().int().min(18).max(120),
  role: z.enum(['user', 'admin']), // Liste blanche
});

app.post('/api/users', authenticate, async (req, res) => {
  try {
    const data = CreateUserSchema.parse(req.body);
    const user = await db.createUser(data);
    res.json(user);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ errors: error.errors });
    }
    throw error;
  }
});
```

### 3. Rate Limiting

#### Vérifications obligatoires
- ✅ Implémenter un rate limiting par IP et par token
- ✅ Limiter les tentatives d'authentification (5 / 15 min)
- ✅ Limiter les requêtes par endpoint
- ✅ Retourner des en-têtes de rate limit

#### Exemple sécurisé
```typescript
import rateLimit from 'express-rate-limit';

// Rate limiting global
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // 100 requêtes par fenêtre
  standardHeaders: true,
  legacyHeaders: false,
  message: 'Too many requests, please try again later',
});

// Rate limiting pour l'authentification
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5, // 5 tentatives
  skipSuccessfulRequests: true,
});

app.use('/api/', globalLimiter);
app.post('/api/auth/login', authLimiter, login);
```

### 4. En-têtes de sécurité

#### Vérifications obligatoires
- ✅ Utiliser Helmet.js pour configurer les en-têtes
- ✅ Configurer CORS de manière restrictive
- ✅ Activer HSTS
- ✅ Configurer CSP

#### Exemple sécurisé
```typescript
import helmet from 'helmet';
import cors from 'cors';

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true,
  },
}));

const corsOptions = {
  origin: process.env.ALLOWED_ORIGINS?.split(',') || [],
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  maxAge: 86400,
};

app.use(cors(corsOptions));
```

### 5. Gestion des erreurs

#### Vérifications obligatoires
- ✅ Ne jamais exposer de stack trace en production
- ✅ Utiliser des messages d'erreur génériques
- ✅ Journaliser toutes les erreurs
- ✅ Retourner des codes HTTP appropriés

#### Exemple sécurisé
```typescript
// Middleware de gestion d'erreurs
app.use((err, req, res, next) => {
  // Journaliser l'erreur complète
  logger.error({
    error: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
    user: req.user?.id,
  });
  
  // Retourner une erreur générique en production
  if (process.env.NODE_ENV === 'production') {
    res.status(500).json({
      error: 'Internal server error',
      requestId: req.id,
    });
  } else {
    res.status(500).json({
      error: err.message,
      stack: err.stack,
    });
  }
});
```

### 6. Journalisation

#### Vérifications obligatoires
- ✅ Journaliser tous les événements de sécurité
- ✅ Utiliser un format structuré (JSON)
- ✅ Inclure un identifiant de requête
- ✅ Ne jamais journaliser de secrets

#### Exemple sécurisé
```typescript
import winston from 'winston';

const logger = winston.createLogger({
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'security.log' }),
  ],
});

// Journaliser les tentatives d'authentification
app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body;
  
  try {
    const user = await authenticate(email, password);
    
    logger.info({
      event: 'login_success',
      userId: user.id,
      email: user.email,
      ip: req.ip,
      userAgent: req.headers['user-agent'],
    });
    
    res.json({ token: generateToken(user) });
  } catch (error) {
    logger.warn({
      event: 'login_failure',
      email: email,
      ip: req.ip,
      userAgent: req.headers['user-agent'],
    });
    
    res.status(401).json({ error: 'Invalid credentials' });
  }
});
```

### 7. Protection SSRF

#### Vérifications obligatoires
- ✅ Valider toutes les URL fournies par l'utilisateur
- ✅ Utiliser une liste blanche de domaines
- ✅ Bloquer les plages IP privées
- ✅ Désactiver les redirections

#### Exemple sécurisé
```typescript
const ALLOWED_DOMAINS = ['api.example.com', 'cdn.example.com'];
const PRIVATE_IP_RANGES = [
  /^10\./,
  /^172\.(1[6-9]|2[0-9]|3[01])\./,
  /^192\.168\./,
  /^127\./,
  /^169\.254\./,
];

function isUrlSafe(url: string): boolean {
  try {
    const parsed = new URL(url);
    
    // Vérifier le protocole
    if (!['http:', 'https:'].includes(parsed.protocol)) {
      return false;
    }
    
    // Bloquer les IP privées
    if (PRIVATE_IP_RANGES.some(regex => regex.test(parsed.hostname))) {
      return false;
    }
    
    // Vérifier la liste blanche
    return ALLOWED_DOMAINS.includes(parsed.hostname);
  } catch {
    return false;
  }
}

app.post('/api/fetch', authenticate, async (req, res) => {
  const { url } = req.body;
  
  if (!isUrlSafe(url)) {
    return res.status(400).json({ error: 'Invalid URL' });
  }
  
  const response = await fetch(url, {
    redirect: 'manual', // Désactiver les redirections
    timeout: 5000,
  });
  
  res.json(await response.json());
});
```

## Anti-patterns à éviter

### ❌ Faire confiance aux entrées utilisateur
```typescript
// DANGEREUX
app.get('/api/users/:id', (req, res) => {
  const user = db.query(`SELECT * FROM users WHERE id = ${req.params.id}`);
  res.json(user);
});
```

### ❌ Pas de rate limiting
```typescript
// DANGEREUX
app.post('/api/auth/login', login); // Permet le brute force
```

### ❌ Exposer des stack traces
```typescript
// DANGEREUX
app.use((err, req, res, next) => {
  res.status(500).json({ error: err.stack });
});
```

### ❌ Pas de validation d'autorisation
```typescript
// DANGEREUX - IDOR/BOLA
app.get('/api/documents/:id', authenticate, (req, res) => {
  const doc = db.getDocument(req.params.id);
  res.json(doc); // N'importe quel utilisateur authentifié peut accéder
});
```

## Checklist de sécurité API

Avant de considérer un endpoint comme sécurisé :

- [ ] Authentification implémentée
- [ ] Autorisation au niveau objet vérifiée
- [ ] Validation des entrées avec schéma strict
- [ ] Rate limiting configuré
- [ ] En-têtes de sécurité configurés
- [ ] CORS configuré de manière restrictive
- [ ] Gestion d'erreurs sécurisée (pas de stack trace)
- [ ] Journalisation des événements de sécurité
- [ ] Protection SSRF si applicable
- [ ] Tests de sécurité écrits

## Outils de validation

- **SAST** : Semgrep avec règles OWASP API
- **DAST** : Strix, Pathfinder-AI
- **Fuzzing** : Postman, REST Assured
- **Pentest** : sqlmap-ai, Burp Suite

## Références

- [OWASP API Security Top 10](https://owasp.org/API-Security/)
- [OWASP REST Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/REST_Security_Cheat_Sheet.html)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)

---

**Version** : 1.0.0  
**Dernière mise à jour** : 2026-05-08  
**Auteur** : Équipe Sécurité Axiom-Scaffold
