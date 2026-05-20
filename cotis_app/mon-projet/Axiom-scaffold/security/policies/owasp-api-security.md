# OWASP API Security Top 10 – Politiques Axiom-Scaffold

**Version** : 2023  
**Référence** : https://owasp.org/API-Security/  
**Statut** : Obligatoire

---

## API1:2023 – Broken Object Level Authorization (BOLA/IDOR)

### Risque
Accès non autorisé aux objets d'autres utilisateurs via manipulation d'identifiants.

### Contre-mesures obligatoires
- ✅ Vérifier l'autorisation pour chaque objet accédé
- ✅ Utiliser des identifiants non prédictibles (UUID v4)
- ✅ Implémenter une couche d'autorisation centralisée
- ✅ Ne jamais faire confiance aux identifiants fournis par le client

### Exemple sécurisé
```typescript
// ❌ DANGEREUX
app.get('/api/users/:id', (req, res) => {
  const user = db.getUser(req.params.id);
  res.json(user);
});

// ✅ SÉCURISÉ
app.get('/api/users/:id', authenticate, (req, res) => {
  const user = db.getUser(req.params.id);
  if (user.id !== req.user.id && !req.user.isAdmin) {
    return res.status(403).json({ error: 'Forbidden' });
  }
  res.json(user);
});
```

---

## API2:2023 – Broken Authentication

### Risque
Prise de contrôle de compte, usurpation d'identité.

### Contre-mesures obligatoires
- ✅ Implémenter un rate limiting strict (5 tentatives / 15 min)
- ✅ Utiliser des tokens JWT avec expiration courte (<15 min)
- ✅ Implémenter un refresh token avec rotation
- ✅ Forcer HTTPS pour tous les endpoints
- ✅ Invalider les tokens lors de la déconnexion
- ✅ Implémenter MFA pour les opérations sensibles

---

## API3:2023 – Broken Object Property Level Authorization

### Risque
Exposition ou modification de propriétés sensibles (mass assignment).

### Contre-mesures obligatoires
- ✅ Utiliser des schémas de validation stricts (Zod, Joi)
- ✅ Définir explicitement les propriétés autorisées
- ✅ Séparer les DTOs de lecture et d'écriture
- ✅ Ne jamais exposer de propriétés internes (password, salt, etc.)

### Exemple sécurisé
```typescript
// ❌ DANGEREUX
app.patch('/api/users/:id', (req, res) => {
  db.updateUser(req.params.id, req.body); // Mass assignment
});

// ✅ SÉCURISÉ
const UpdateUserSchema = z.object({
  name: z.string().max(100),
  email: z.string().email(),
  // isAdmin: NOT ALLOWED
});

app.patch('/api/users/:id', (req, res) => {
  const data = UpdateUserSchema.parse(req.body);
  db.updateUser(req.params.id, data);
});
```

---

## API4:2023 – Unrestricted Resource Consumption

### Risque
Déni de service, épuisement des ressources, coûts excessifs.

### Contre-mesures obligatoires
- ✅ Implémenter un rate limiting par IP et par token
- ✅ Limiter la taille des requêtes (body, headers, query params)
- ✅ Implémenter des timeouts sur toutes les opérations
- ✅ Limiter le nombre de résultats retournés (pagination obligatoire)
- ✅ Implémenter des quotas par utilisateur

### Configuration recommandée
```typescript
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // 100 requêtes par fenêtre
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api/', limiter);
app.use(express.json({ limit: '10kb' }));
```

---

## API5:2023 – Broken Function Level Authorization

### Risque
Accès non autorisé à des fonctions administratives.

### Contre-mesures obligatoires
- ✅ Vérifier les rôles pour chaque endpoint
- ✅ Implémenter un middleware d'autorisation centralisé
- ✅ Refuser par défaut (deny by default)
- ✅ Séparer les routes admin des routes utilisateur

### Exemple sécurisé
```typescript
const requireAdmin = (req, res, next) => {
  if (!req.user || !req.user.isAdmin) {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
};

app.delete('/api/users/:id', authenticate, requireAdmin, deleteUser);
```

---

## API6:2023 – Unrestricted Access to Sensitive Business Flows

### Risque
Automatisation abusive, scalping, manipulation de marché.

### Contre-mesures obligatoires
- ✅ Implémenter un CAPTCHA pour les flux sensibles
- ✅ Détecter les comportements anormaux (trop rapide, trop fréquent)
- ✅ Implémenter une friction computationnelle (proof-of-work)
- ✅ Limiter les actions par période (ex: 1 achat / minute)

---

## API7:2023 – Server Side Request Forgery (SSRF)

### Risque
Accès à des ressources internes, scan de ports, exfiltration.

### Contre-mesures obligatoires
- ✅ Valider et filtrer toutes les URL fournies par l'utilisateur
- ✅ Utiliser une liste blanche de domaines autorisés
- ✅ Bloquer l'accès aux plages IP privées
- ✅ Désactiver les redirections HTTP
- ✅ Utiliser un proxy sortant avec filtrage

### Exemple sécurisé
```typescript
const ALLOWED_DOMAINS = ['api.example.com', 'cdn.example.com'];

function isUrlSafe(url: string): boolean {
  const parsed = new URL(url);
  
  // Bloquer les IP privées
  if (/^(10|172\.(1[6-9]|2[0-9]|3[01])|192\.168)\./.test(parsed.hostname)) {
    return false;
  }
  
  // Vérifier la liste blanche
  return ALLOWED_DOMAINS.includes(parsed.hostname);
}
```

---

## API8:2023 – Security Misconfiguration

### Risque
Exposition de services, de messages d'erreur, de comptes par défaut.

### Contre-mesures obligatoires
- ✅ Désactiver les messages d'erreur détaillés en production
- ✅ Configurer les en-têtes de sécurité (CORS, CSP, HSTS)
- ✅ Désactiver les méthodes HTTP inutilisées (TRACE, OPTIONS)
- ✅ Configurer CORS de manière restrictive
- ✅ Utiliser Helmet.js pour Express

### Configuration CORS sécurisée
```typescript
const corsOptions = {
  origin: ['https://app.example.com'],
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  maxAge: 86400,
};

app.use(cors(corsOptions));
```

---

## API9:2023 – Improper Inventory Management

### Risque
Exposition d'anciennes versions vulnérables, endpoints non documentés.

### Contre-mesures obligatoires
- ✅ Maintenir un inventaire à jour de toutes les APIs
- ✅ Documenter toutes les APIs avec OpenAPI 3.1
- ✅ Désactiver les anciennes versions d'API
- ✅ Implémenter un versioning explicite (`/api/v1/`, `/api/v2/`)
- ✅ Surveiller les endpoints non documentés

---

## API10:2023 – Unsafe Consumption of APIs

### Risque
Injection via des APIs tierces, compromission de la chaîne d'approvisionnement.

### Contre-mesures obligatoires
- ✅ Valider toutes les réponses des APIs tierces
- ✅ Utiliser des timeouts sur les appels externes
- ✅ Implémenter un circuit breaker
- ✅ Ne jamais faire confiance aux données externes
- ✅ Vérifier les certificats TLS

### Exemple sécurisé
```typescript
const ResponseSchema = z.object({
  id: z.string().uuid(),
  name: z.string().max(100),
  email: z.string().email(),
});

async function fetchUser(id: string) {
  const response = await fetch(`https://api.third-party.com/users/${id}`, {
    timeout: 5000,
  });
  
  const data = await response.json();
  
  // Valider la réponse
  return ResponseSchema.parse(data);
}
```

---

## Validation et conformité

### Outils de vérification
- **SAST** : Semgrep avec règles OWASP API
- **DAST** : Strix, Pathfinder-AI, sqlmap-ai
- **Fuzzing** : Postman, REST Assured

### Tests obligatoires
- ✅ Test d'autorisation sur chaque endpoint
- ✅ Test de rate limiting
- ✅ Test de validation des entrées
- ✅ Test de gestion des erreurs
- ✅ Test de CORS

---

**Dernière mise à jour** : 2026-05-08  
**Responsable** : Équipe Sécurité Axiom-Scaffold
