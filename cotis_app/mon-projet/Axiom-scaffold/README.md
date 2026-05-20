# Axiom-Scaffold

> **Framework de développement agentique autonome** — Guide l'agent IA de A à Z

## 🚀 Vue d'ensemble

Axiom-Scaffold est un système complet qui transforme n'importe quel projet en environnement de développement agentique structuré. Il fournit configuration, documentation, outils et workflows pour permettre aux agents IA de travailler de manière autonome et déterministe.

## 📁 Structure

```
Axiom-scaffold/
├── config/              # Configuration et règles
│   ├── AGENTS.md       # Guide principal pour agents IA
│   ├── axiom.config.yaml
│   ├── caveman-rules.yaml
│   └── ide-mapping.yaml
├── docs/                # Documentation complète
│   ├── ARCHITECTURE.md
│   ├── CAVEMAN.md
│   ├── SKILLS-SYSTEM.md
│   └── ...
├── scripts/             # Scripts d'automatisation
├── skills/              # Compétences de l'agent
│   ├── built-in/
│   └── registry.json
├── specs/               # Spécifications
│   ├── rules/
│   ├── domain/
│   └── architecture/
├── installers/          # Installateurs
│   └── axiom-installer/
└── reports/             # Rapports et changelog
    ├── CHANGELOG.md
    └── README.md
```

## ✨ Fonctionnalités

### 🤖 Pour les Agents IA

- **Configuration centralisée** : Toutes les règles dans `config/AGENTS.md`
- **Mode Caveman** : Compression 65-75% des tokens
- **Skills système** : 12+ compétences intégrées
- **Détection IDE** : Support de 24 outils (Claude Code, Cursor, Windsurf, Kiro, etc.)
- **Déterminisme** : Hash vérifiables, reproductibilité garantie

### 🛠️ Pour les Développeurs

- **Templates anti-gaspillage** : Plans, tâches, walkthroughs
- **Modes Focus/Flex** : Autonomie totale ou avec approbations
- **Intégrations** : Linear, Git, MCP
- **Sécurité** : OWASP Top 10, zero-trust, audit automatique

## 🎯 Démarrage Rapide

### Installation

```bash
# Cloner dans votre projet
git clone https://github.com/axiom-scaffold/axiom-scaffold.git Axiom-scaffold

# Ou via npm (quand publié)
npx axiom-scaffold init
```

### Configuration

```bash
# Éditer la configuration
vim Axiom-scaffold/config/axiom.config.yaml

# Choisir le mode
mode: flex  # ou focus pour autonomie totale
```

### Utilisation

L'agent lit automatiquement `Axiom-scaffold/config/AGENTS.md` et suit les règles définies.

## 📚 Documentation

| Document                                  | Description                    |
| ----------------------------------------- | ------------------------------ |
| [AGENTS.md](config/AGENTS.md)             | Guide principal pour agents IA |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md)   | Architecture du système        |
| [CAVEMAN.md](docs/CAVEMAN.md)             | Mode de compression            |
| [SKILLS-SYSTEM.md](docs/SKILLS-SYSTEM.md) | Système de compétences         |
| [CHANGELOG.md](reports/CHANGELOG.md)      | Historique des modifications   |

## 🔧 Configuration

### Mode Focus vs Flex

**Mode Flex** (par défaut) :
- Demande approbation avant actions critiques
- Idéal pour découverte et exploration

**Mode Focus** :
- Autonomie totale
- Idéal pour tâches répétitives et implémentation

### Caveman Mode

Compression automatique des réponses :

```
/caveman full    # Mode par défaut (fragments)
/caveman lite    # Mode professionnel
/caveman ultra   # Mode télégraphique
stop caveman     # Désactiver
```

**Économie** : 65-75% de tokens

## 🎨 Skills Intégrés

| Skill           | Déclencheur  | Description           |
| --------------- | ------------ | --------------------- |
| axiom-bootstrap | `/bootstrap` | Initialise Axiom      |
| axiom-memory    | `/memory`    | Met à jour la mémoire |
| axiom-visualize | `/visualize` | Génère le graphe      |
| axiom-linear    | `/linear`    | Sync avec Linear      |
| axiom-research  | `/research`  | Recherche technos     |
| caveman-mode    | `/caveman`   | Compression tokens    |

[Voir tous les skills](skills/registry.json)

## 🔒 Sécurité

- **OWASP Top 10** : Web, API, Mobile, Agentic AI
- **Zero-Trust** : Validation à chaque étape
- **Audit automatique** : npm audit, semgrep, detect-secrets
- **Secrets** : Jamais dans le code

[Voir les politiques](specs/rules/constitution.md)

## 🌐 Support IDE/CLI

24 outils supportés :

- **CLI** : Claude Code, Codex, Gemini CLI, Aider, Warp
- **IDE** : Cursor, Windsurf, Cline, Kiro, Zed, Continue, Cody
- **Cloud** : Devin, Replit Agent, Amazon Q

[Voir la cartographie complète](config/ide-mapping.yaml)

## 📦 Installer Interactif

```bash
# Installer l'installateur Axiom
npm install -g axiom-scaffold-installer

# Lancer l'installation interactive
axiom-scaffold
```

[Voir la documentation](installers/axiom-installer/README.md)

## 🤝 Contribution

Contributions bienvenues ! Voir [CONTRIBUTING.md](CONTRIBUTING.md).

## 📄 Licence

MIT © Axiom-Scaffold Team

## 🔗 Liens

- **Documentation** : [docs/](docs/)
- **Configuration** : [config/](config/)
- **Skills** : [skills/](skills/)
- **Changelog** : [reports/CHANGELOG.md](reports/CHANGELOG.md)

---

**Version** : 2.0.0  
**Dernière mise à jour** : 2026-05-09  
**Statut** : ✅ Production Ready
