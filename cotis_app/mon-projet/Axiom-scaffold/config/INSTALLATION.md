# Guide d'Installation — Axiom-Scaffold

Ce guide vous accompagne dans l'installation complète d'Axiom-Scaffold, de l'installation globale à l'initialisation de votre premier projet.

## Prérequis

### Système d'Exploitation
- Linux (Ubuntu 20.04+, Debian 11+)
- macOS (11+)
- Windows (via WSL2)

### Logiciels Requis
- **Node.js** : version 18.x ou 20.x
- **Python** : version 3.9+
- **Git** : version 2.30+
- **Bash** : version 4.0+

### Vérification des Prérequis

```bash
# Vérifier Node.js
node --version  # Doit afficher v18.x ou v20.x

# Vérifier Python
python3 --version  # Doit afficher 3.9+

# Vérifier Git
git --version  # Doit afficher 2.30+

# Vérifier Bash
bash --version  # Doit afficher 4.0+
```

## Installation Globale (Une Seule Fois)

### Étape 1 : Cloner le Dépôt

```bash
# Cloner le dépôt Axiom-Scaffold
git clone https://github.com/your-org/axiom-scaffold.git
cd axiom-scaffold
```

### Étape 2 : Exécuter le Bootstrap

```bash
# Rendre le script exécutable (si nécessaire)
chmod +x script/bootstrap.sh

# Exécuter le bootstrap
./script/bootstrap.sh
```

**Ce script va :**
1. Installer Node.js (si absent)
2. Installer Python (si absent)
3. Installer les packages npm globaux (pnpm, eslint, prettier, markdownlint-cli, gitnexus)
4. Installer les packages Python globaux (pinecone-client)
5. Créer le répertoire `~/.axiom/skills/`
6. Cloner 18 dépôts de skills depuis GitHub
7. Installer Playwright et ses navigateurs

**Durée estimée** : 5-10 minutes (selon votre connexion internet)

### Étape 3 : Vérification

```bash
# Vérifier que les outils sont installés
node --version
npm --version
python3 --version
gitnexus --version

# Vérifier que les skills sont présents
ls ~/.axiom/skills/
```

Vous devriez voir 18 dossiers de skills.

## Initialisation d'un Nouveau Projet

### Étape 1 : Créer un Nouveau Répertoire

```bash
# Créer et entrer dans le répertoire du projet
mkdir mon-projet-axiom
cd mon-projet-axiom
```

### Étape 2 : Copier les Fichiers Template

```bash
# Copier les fichiers depuis le template Axiom
cp -r /chemin/vers/axiom-scaffold/* .
cp -r /chemin/vers/axiom-scaffold/.* . 2>/dev/null || true
```

Ou utiliser le script setup :

```bash
# Rendre le script exécutable
chmod +x script/setup.sh

# Exécuter le setup
./script/setup.sh
```

**Ce script va :**
1. Initialiser Git (si nécessaire)
2. Installer les dépendances npm
3. Installer les dépendances Python (si requirements.txt existe)
4. Configurer Husky (hooks Git)
5. Créer le hook pre-commit
6. Indexer le projet avec GitNexus
7. Générer le wiki
8. Créer les répertoires de travail

**Durée estimée** : 2-5 minutes

### Étape 3 : Configuration

#### Variables d'Environnement

```bash
# Copier le template
cp .env.example .env

# Éditer avec vos valeurs
nano .env
```

#### Personnalisation

Éditez les fichiers suivants selon vos besoins :
- `AGENTS.md` : Ajustez les liens vers votre documentation
- `WORKFLOW.md` : Configurez votre tracker (Linear, Jira, etc.)
- `.agent/constitution.md` : Définissez vos règles spécifiques
- `package.json` : Ajustez le nom, la description, etc.

### Étape 4 : Premier Commit

```bash
# Ajouter tous les fichiers
git add .

# Créer le commit initial
git commit -m "chore: initial commit with Axiom-Scaffold"

# Créer la branche develop
git checkout -b develop
```

## Vérification de l'Installation

### Tests

```bash
# Installer les dépendances (si pas déjà fait)
npm install

# Lancer les tests (devrait passer même sans tests)
npm test

# Lancer le linting
npm run lint

# Lancer l'audit de sécurité
npm audit
```

### Hooks Git

```bash
# Vérifier que le hook pre-commit existe
ls -la .husky/pre-commit

# Tester le hook (devrait exécuter les tests et le linting)
git commit --allow-empty -m "test: verify hooks"
```

### CI/CD

```bash
# Vérifier que le workflow CI existe
cat .github/workflows/ci.yml

# Pousser vers GitHub pour déclencher la CI
git remote add origin https://github.com/your-org/your-repo.git
git push -u origin main
```

## Dépannage

### Problème : `gitnexus: command not found`

**Solution** :
```bash
# Réinstaller gitnexus
npm install -g gitnexus

# Vérifier l'installation
which gitnexus
```

### Problème : `Permission denied` lors de l'exécution des scripts

**Solution** :
```bash
# Rendre tous les scripts exécutables
chmod +x script/*.sh
chmod +x .husky/pre-commit
```

### Problème : Échec du clonage des skills

**Solution** :
```bash
# Vérifier la connexion internet
ping github.com

# Réessayer manuellement
cd ~/.axiom/skills/
git clone https://github.com/alirezarezvani/claude-skills.git
```

### Problème : `npm audit` trouve des vulnérabilités

**Solution** :
```bash
# Tenter une correction automatique
npm audit fix

# Si des vulnérabilités persistent
npm audit fix --force

# Vérifier à nouveau
npm audit
```

### Problème : Tests échouent

**Solution** :
```bash
# Vérifier que Jest est installé
npm list jest

# Réinstaller les dépendances
rm -rf node_modules package-lock.json
npm install

# Relancer les tests
npm test
```

## Configuration Avancée

### Intégration avec Linear

```bash
# Ajouter votre clé API Linear dans .env
echo "LINEAR_API_KEY=your-key-here" >> .env
echo "LINEAR_TEAM_ID=your-team-id" >> .env
```

### Intégration avec Pinecone

```bash
# Ajouter vos credentials Pinecone dans .env
echo "PINECONE_API_KEY=your-key-here" >> .env
echo "PINECONE_ENVIRONMENT=your-env" >> .env
```

### Configuration de GitNexus

```bash
# Analyser le projet
npx gitnexus analyze --skills --embeddings

# Générer le wiki
npx gitnexus wiki

# Requête sur le graphe
npx gitnexus query "find all functions related to authentication"
```

## Prochaines Étapes

1. **Lire la documentation** : Consultez [AGENTS.md](AGENTS.md) et [README.md](README.md)
2. **Personnaliser** : Adaptez la constitution et les templates à votre projet
3. **Ajouter des skills** : Créez vos propres skills dans `skills/`
4. **Configurer l'orchestrateur** : Mettez en place Symphony ou votre orchestrateur
5. **Commencer à développer** : Créez votre première feature avec un agent IA

## Support

- **Documentation** : [README.md](README.md)
- **Architecture** : [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- **Style** : [docs/STYLE_GUIDE.md](docs/STYLE_GUIDE.md)
- **Issues** : [GitHub Issues](https://github.com/your-org/your-repo/issues)

---

**Bon développement avec Axiom-Scaffold !** 🚀
