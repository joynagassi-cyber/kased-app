# Constitution du Projet

> **Note** : Ce fichier définit les règles fondamentales du projet. Toute modification doit être validée par l'équipe.

## Principes Fondamentaux

### 1. Zero-Trust
- Aucune confiance implicite dans le code ou les données
- Validation systématique des entrées
- Vérification à chaque étape

### 2. Déterminisme
- Les tests doivent être reproductibles
- Pas de dépendances à l'état global
- Isolation des effets de bord

### 3. Traçabilité
- Chaque décision doit être documentée
- Les commits doivent être atomiques et explicites
- Les ADR (Architecture Decision Records) pour les choix importants

### 4. Minimalisme
- Pas de code mort
- Pas de dépendances inutiles
- Simplicité avant optimisation prématurée

## Règles de Code

### Structure
- Maximum 300 lignes par fichier (sauf exceptions documentées)
- Maximum 100 lignes par fonction
- Complexité cyclomatique ≤ 10

### Nommage
- Variables : `camelCase` (JavaScript/TypeScript) ou `snake_case` (Python)
- Constantes : `UPPER_SNAKE_CASE`
- Classes : `PascalCase`
- Fichiers : `kebab-case.ext`

### Documentation
- JSDoc pour toutes les fonctions publiques (JavaScript/TypeScript)
- Docstrings pour toutes les fonctions (Python)
- README.md dans chaque dossier de module

## Règles de Tests

### Couverture
- Minimum 80% de couverture de code
- Minimum 70% de score de mutation
- Tests E2E pour les flux critiques

### Organisation
- Tests unitaires à côté du code source
- Tests d'intégration dans `tests/integration/`
- Tests E2E dans `tests/e2e/`

### Conventions
- Nommage : `describe('ComponentName', () => { it('should...', () => {}) })`
- Arrange-Act-Assert pattern
- Pas de logique complexe dans les tests

## Règles de Sécurité

### Secrets
- ❌ Jamais de secrets dans le code
- ✅ Variables d'environnement pour les credentials
- ✅ Utilisation de `.env.example` comme template

### Dépendances
- Audit régulier avec `npm audit` ou `pip-audit`
- Mise à jour des dépendances critiques sous 48h
- Pas de dépendances avec vulnérabilités high/critical

### Validation
- Validation des entrées utilisateur
- Sanitization des données
- Protection contre les injections (SQL, XSS, etc.)

## Règles de Git

### Commits
- Messages en anglais (ou français selon le projet)
- Format : `type(scope): message`
  - Types : `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
  - Exemple : `feat(auth): add JWT token validation`

### Branches
- `main` : production
- `develop` : développement
- `feature/*` : nouvelles fonctionnalités
- `fix/*` : corrections de bugs
- `hotfix/*` : corrections urgentes en production

### Pull Requests
- Titre clair et concis
- Description détaillée avec contexte
- Lien vers le ticket (Linear, Jira, etc.)
- Au moins une revue avant merge

## Règles d'Architecture

### Séparation des Responsabilités
- Couche présentation séparée de la logique métier
- Logique métier séparée de l'accès aux données
- Pas de couplage fort entre modules

### Dépendances
- Dépendances unidirectionnelles
- Pas de dépendances circulaires
- Injection de dépendances pour la testabilité

### API
- RESTful ou GraphQL selon le contexte
- Versioning explicite (v1, v2, etc.)
- Documentation OpenAPI/Swagger

## Règles de Performance

### Optimisation
- Mesurer avant d'optimiser
- Pas d'optimisation prématurée
- Profiling pour identifier les goulots

### Ressources
- Pas de fuites mémoire
- Gestion appropriée des connexions
- Pagination pour les grandes listes

## Règles de Documentation

### Code
- Commentaires pour expliquer le "pourquoi", pas le "quoi"
- Documentation des APIs publiques
- Exemples d'utilisation

### Architecture
- Diagrammes à jour (C4, UML, etc.)
- ADR pour les décisions importantes
- CHANGELOG.md maintenu

## Exceptions

Les exceptions à ces règles doivent être :
1. Documentées dans le code avec un commentaire `// EXCEPTION:`
2. Justifiées dans un ADR si l'exception est architecturale
3. Validées par au moins deux membres de l'équipe

## Mise à Jour

Cette constitution peut être modifiée par :
1. Proposition via Pull Request
2. Discussion en équipe
3. Vote à la majorité
4. Documentation dans un ADR

---

**Version** : 1.0.0  
**Dernière mise à jour** : 2026-05-07  
**Statut** : Actif
