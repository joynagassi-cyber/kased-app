# Guide de Migration vers Axiom-Scaffold v2.0

## 🎉 Refonte Terminée !

La refonte complète d'Axiom-Scaffold v2.0 est maintenant **terminée**. Tous les fichiers du scaffolding ont été déplacés dans le dossier `Axiom-scaffold/`.

## 📁 Nouvelle Structure

```
projet/
├── Axiom-scaffold/          # ← TOUT LE SCAFFOLDING EST ICI
│   ├── config/             # Configuration et règles
│   ├── docs/               # Documentation complète
│   ├── scripts/            # Scripts d'automatisation
│   ├── templates/          # Templates anti-gaspillage
│   ├── skills/             # Compétences de l'agent
│   ├── specs/              # Spécifications
│   ├── security/           # Sécurité
│   ├── design/             # Design system
│   ├── tools/              # Stack technique et MCPs
│   ├── workspace/          # Espace de travail
│   ├── proposals/          # Propositions (mode Flex)
│   └── reports/            # Rapports et documentation
├── src/                    # Votre code source
├── tests/                  # Vos tests
├── package.json            # Dépendances
└── README.md               # Documentation utilisateur
```

## 🚀 Démarrage Rapide

### 1. Bootstrap (Première Fois)

```bash
bash Axiom-scaffold/scripts/bootstrap.sh
```

Ce script :
- ✅ Installe toutes les dépendances
- ✅ Scanne le projet
- ✅ Génère une carte des sections
- ✅ Configure l'environnement

### 2. Commandes Principales

```bash
# Indexer la mémoire
npm run memory:index

# Vérifier le déterminisme
npm run memory:verify

# Fusionner les graphes
npm run graph:fuse

# Générer le layout
npm run graph:layout
```

## 📚 Documentation

Toute la documentation est maintenant dans `Axiom-scaffold/` :

- **Guide de l'agent** : `Axiom-scaffold/config/AGENTS.md`
- **Configuration** : `Axiom-scaffold/config/axiom.config.yaml`
- **Workflow** : `Axiom-scaffold/config/WORKFLOW.md`
- **Architecture** : `Axiom-scaffold/docs/ARCHITECTURE.md`
- **Mémoire** : `Axiom-scaffold/docs/MEMORY.md`
- **Déterminisme** : `Axiom-scaffold/docs/DETERMINISM.md`
- **Rapport de refonte** : `Axiom-scaffold/reports/REFONTE_V2_COMPLETE.md`

## 🔄 Changements Principaux

### Fichiers Déplacés

| Ancien Chemin           | Nouveau Chemin                 |
| ----------------------- | ------------------------------ |
| `.agent/`               | `Axiom-scaffold/config/agent/` |
| `.axiom/`               | `Axiom-scaffold/config/axiom/` |
| `docs/`                 | `Axiom-scaffold/docs/`         |
| `scripts/`              | `Axiom-scaffold/scripts/`      |
| `templates/`            | `Axiom-scaffold/templates/`    |
| `skills/`               | `Axiom-scaffold/skills/`       |
| `specs/`                | `Axiom-scaffold/specs/`        |
| `security/`             | `Axiom-scaffold/security/`     |
| `design/`               | `Axiom-scaffold/design/`       |
| `graph/`, `logs/`, etc. | `Axiom-scaffold/workspace/`    |
| Rapports (*.md)         | `Axiom-scaffold/reports/`      |

### Nouveaux Fichiers

- `Axiom-scaffold/config/axiom.config.yaml` - Configuration globale
- `Axiom-scaffold/scripts/bootstrap.sh` - Script d'amorçage
- `Axiom-scaffold/scripts/quick-scan.sh` - Scan rapide
- `README.md` - Documentation utilisateur simplifiée

## ⚙️ Configuration

Le fichier `Axiom-scaffold/config/axiom.config.yaml` contrôle tout :

```yaml
mode: flex  # flex (avec approbations) ou focus (autonome)

integrations:
  linear:
    enabled: true
  git:
    auto_push: true
  mcp:
    auto_discover: true

logging:
  level: detailed
```

## 🤖 Pour les Agents IA

**⚠️ RÈGLES ABSOLUES ⚠️**

1. **Tous les fichiers Axiom dans `Axiom-scaffold/`**
2. **Utiliser les templates** (`templates/`)
3. **Respecter le mode** (Flex ou Focus)
4. **Consulter la constitution** avant toute modification
5. **Travailler par section** pour les gros projets

Lire `Axiom-scaffold/config/AGENTS.md` pour les instructions complètes.

## 📊 Modes de Fonctionnement

### Mode Flex (Par Défaut)

L'agent demande approbation avant les actions critiques.

### Mode Focus (Autonome)

L'agent travaille en totale autonomie.

Changer de mode : Éditer `Axiom-scaffold/config/axiom.config.yaml`

## 🔍 Scan et Sections

Pour les gros projets, Axiom travaille par **section** :

1. Scan rapide (< 5 min)
2. Choix de la section
3. Chargement du sous-graphe uniquement
4. Réactivité garantie

## ✅ Avantages de v2.0

- ✅ **Environnement hermétique** : Tout dans un seul dossier
- ✅ **Autonomie totale** : Une commande suffit
- ✅ **Déterminisme strict** : Hash vérifiables
- ✅ **Flexibilité** : Modes Focus/Flex
- ✅ **Passage à l'échelle** : Sections pour gros projets
- ✅ **Intégration facile** : S'intègre dans n'importe quel projet

## 🎓 Prochaines Étapes

1. Exécuter le bootstrap : `bash Axiom-scaffold/scripts/bootstrap.sh`
2. Choisir une section de travail
3. Commencer le développement
4. Laisser l'agent travailler en autonomie

## 📞 Support

- **Documentation complète** : `Axiom-scaffold/docs/`
- **Configuration** : `Axiom-scaffold/config/`
- **Rapports** : `Axiom-scaffold/reports/`

---

**Version** : 2.0.0  
**Date** : 2026-05-09  
**Statut** : ✅ **REFONTE COMPLÈTE**
