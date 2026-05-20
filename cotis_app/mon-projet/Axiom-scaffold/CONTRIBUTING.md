# Contributing to Axiom-Scaffold

Merci de votre intérêt pour contribuer à Axiom-Scaffold !

## 🎯 Principes

1. **Simplicité** : Garder le code simple et lisible
2. **Documentation** : Documenter toute nouvelle fonctionnalité
3. **Tests** : Ajouter des tests pour tout nouveau code
4. **Caveman** : Utiliser le mode caveman pour les communications

## 📋 Processus

### 1. Fork & Clone

```bash
git clone https://github.com/votre-username/axiom-scaffold.git
cd axiom-scaffold
```

### 2. Créer une Branche

```bash
git checkout -b feature/ma-fonctionnalite
```

### 3. Développer

- Suivre les règles dans `config/AGENTS.md`
- Respecter la constitution dans `specs/rules/constitution.md`
- Utiliser les templates dans `templates/`

### 4. Tester

```bash
npm test
npm run lint
npm run validate:specs
```

### 5. Commit

```bash
# Format caveman ultra
git commit -m "feat(scope): action - reason"
```

**Exemples** :
- `feat(skills): add axiom-deploy skill - automate deployment`
- `fix(caveman): correct token count - off by 1 error`
- `docs(readme): update installation steps - clarify npm command`

### 6. Push & PR

```bash
git push origin feature/ma-fonctionnalite
```

Créer une Pull Request avec :
- **Titre** : Format caveman (< 70 chars)
- **Description** : Quoi, pourquoi, comment (mode caveman full)
- **Tests** : Résultats des tests
- **Screenshots** : Si UI

## 🏗️ Structure

### Ajouter un Skill

1. Créer `skills/built-in/mon-skill.md`
2. Ajouter frontmatter YAML :

```yaml
---
id: mon-skill
triggers: ["mon-trigger", "alias"]
description: "Description du skill"
mode: both
category: custom
---
```

3. Enregistrer dans `skills/registry.json`

### Ajouter une Règle

1. Éditer `specs/rules/constitution.md`
2. Ajouter la règle avec justification
3. Mettre à jour `config/AGENTS.md` si nécessaire

### Ajouter un IDE

1. Éditer `config/ide-mapping.yaml`
2. Ajouter l'entrée avec :
   - `context_file`
   - `skills_dir`
   - `mcp_config`
   - `caveman_install`

## 🧪 Tests

### Unitaires

```bash
npm test
```

### E2E

```bash
npm run test:e2e
```

### Mutation

```bash
npm run test:mutation
```

### Sécurité

```bash
npm audit
npm run security:scan
```

## 📝 Documentation

### Markdown

- Utiliser le format caveman pour les docs techniques
- Garder les phrases courtes
- Ajouter des exemples de code

### Code

- JSDoc pour toutes les fonctions publiques
- Commentaires pour expliquer le "pourquoi"
- Exemples d'utilisation

## 🎨 Style

### Code

- ESLint + Prettier
- TypeScript strict
- Pas de `any`

### Commits

- Format : `type(scope): action - reason`
- Types : feat, fix, docs, style, refactor, test, chore
- Max 72 caractères

### PR

- Titre : Format caveman
- Description : Mode caveman full
- Max 25 lignes

## 🔒 Sécurité

### Règles

- Jamais de secrets dans le code
- Validation des entrées
- Prepared statements pour SQL
- Audit des dépendances

### Signaler une Vulnérabilité

Email : security@axiom-scaffold.dev

## 🤝 Code de Conduite

- Respectueux
- Constructif
- Inclusif
- Professionnel

## 📞 Support

- **Issues** : https://github.com/axiom-scaffold/axiom-scaffold/issues
- **Discussions** : https://github.com/axiom-scaffold/axiom-scaffold/discussions
- **Email** : contact@axiom-scaffold.dev

## 🎁 Reconnaissance

Les contributeurs sont listés dans [CONTRIBUTORS.md](CONTRIBUTORS.md).

---

**Merci de contribuer à Axiom-Scaffold !** 🚀
