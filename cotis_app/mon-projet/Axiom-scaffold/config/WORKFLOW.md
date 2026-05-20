---
tracker: linear
poll_interval_seconds: 30
concurrency:
  max_sessions: 5
workspace:
  root: "./agent-workspaces"
hooks:
  after_agent: "script/after-agent.sh"
  on_error: "script/on-error.sh"
---

# Mission pour le ticket {{issue.title}}

## Contexte

**Ticket** : {{issue.id}}  
**Titre** : {{issue.title}}  
**Description** : {{issue.description}}  
**Priorité** : {{issue.priority}}  
**Labels** : {{issue.labels}}

## Instructions

### 0. Auto-Optimisation (Optionnel)

Si la tâche implique une optimisation de performance, UI, SQL, ou prompt :

```bash
# Lancer une expérience d'auto-optimisation
script/start-experiment.sh <nom-optimisation> <type>

# Types: performance, ui, sql, prompt, config
```

Voir [docs/AUTO-OPTIMIZATION.md](docs/AUTO-OPTIMIZATION.md) pour plus de détails.

### 1. Prise de connaissance

- Lis attentivement la description du ticket : {{issue.description}}
- Identifie les fichiers et composants concernés
- Consulte `AGENTS.md` pour localiser la documentation pertinente

### 2. Cycle Axiom

Suis rigoureusement le cycle Axiom en 6 étapes :

#### 🔍 Recherche (si nécessaire)

- Utilise les skills d'auto-research pour comprendre le contexte
- Consulte la documentation existante dans `docs/`
- Recherche les patterns similaires dans le graphe de connaissances (GitNexus)

#### 📊 Contexte

- Extrais le sous-graphe pertinent avec GitNexus
- Identifie les dépendances et les impacts
- Liste les fichiers à modifier (scope)

#### 🎨 Design (si UI)

- **Sélectionne une bibliothèque UI** : `./scripts/design-pipeline.sh --framework react --style modern --screen <nom>`
- **Génère une maquette** conforme au design system
- **Valide les couleurs** : `node scripts/validate-colors.js design/screens/<nom>.html`
- **Revue Huashu-Design (5D)** : Active le skill `huashu-review.md`
- **Itère jusqu'à score ≥ 0.85** : Corrige selon le feedback
- **Obtiens une validation** avant implémentation

#### 💻 Implémentation

- Découpe la tâche en micro-tâches de ≤ 100 lignes
- Implémente chaque micro-tâche séquentiellement
- Valide chaque lot avec les tests
- Commit après chaque micro-tâche validée

**Option automatique (Couche 5)** :
```bash
# Décomposer une feature en micro-tâches
./scripts/decompose-feature.sh features/<nom>.yaml

# Exécuter une micro-tâche avec validation automatique
./scripts/execute-task.sh features/<feature-id>/tasks/<task-id>.yaml
```

Le système d'exécution zero-trust :
1. Crée un workspace isolé (git worktree)
2. Génère un prompt minimal (≤ 500 tokens)
3. Appelle le LLM pour générer le code
4. Valide avec un pipeline strict (6 étapes)
5. Corrige automatiquement si échec (max 3×)
6. Fusionne dans `main` si validation OK
7. Ré-indexe la mémoire

Voir [docs/EXECUTION-ZERO-TRUST.md](docs/EXECUTION-ZERO-TRUST.md) pour plus de détails.

#### ✅ Vérification

- Exécute TOUS les tests (unitaires, intégration, E2E)
- Lance les vérifications de sécurité (audit)
- Capture une preuve vidéo avec Playwright
- Vérifie la couverture de code (≥ 80%)

#### 📚 Apprentissage

- Documente les patterns découverts
- Mets à jour le wiki si nécessaire
- Ajoute des commentaires explicatifs dans le code
- Crée un ADR (Architecture Decision Record) si décision importante

### 3. Mise à jour du ticket

Une fois la mission terminée :

- Mets à jour le statut du ticket
- Ajoute un résumé des modifications
- Attache la preuve vidéo Playwright
- Liste les fichiers modifiés
- Documente les décisions prises

## Contraintes

### Règles absolues

- ❌ **Ne jamais modifier** les fichiers hors scope
- ❌ **Ne jamais commit** sans avoir lancé les tests
- ❌ **Ne jamais ignorer** les erreurs de lint
- ❌ **Ne jamais exposer** de secrets ou credentials
- ✅ **Toujours respecter** la constitution du projet

### Limites de contexte

- Maximum **500 tokens** par micro-tâche
- Maximum **100 lignes** de code par commit
- Maximum **5 fichiers** modifiés par micro-tâche

### Qualité minimale

- Couverture de tests : **≥ 80%**
- Score de mutation : **≥ 70%**
- Complexité cyclomatique : **≤ 10** par fonction
- Pas de vulnérabilités de sécurité (niveau high ou critical)

## Commandes disponibles

### Tests
```bash
npm test                    # Tests unitaires
npm run test:coverage       # Avec couverture
npm run test:mutation       # Tests de mutation
npm run test:e2e            # Tests end-to-end
```

### Vérifications
```bash
npm run lint                # Linting
npm run format              # Formatage
npm audit                   # Audit de sécurité
```

### Build
```bash
npm run build               # Construction
npm run build:watch         # Build en mode watch
```

## Gestion des erreurs

En cas d'erreur :

1. Le hook `on-error.sh` est automatiquement exécuté
2. L'erreur est loggée dans `logs/errors/`
3. Le ticket est mis à jour avec le statut d'erreur
4. Une notification est envoyée (si configurée)

**Ne pas abandonner** : analyse l'erreur, consulte la documentation, active un skill spécialisé si nécessaire.

## Résultat attendu

À la fin de cette mission :

- ✅ Tous les tests passent
- ✅ Le code est linté et formaté
- ✅ Aucune vulnérabilité de sécurité
- ✅ La couverture de code est ≥ 80%
- ✅ Une preuve vidéo Playwright est disponible
- ✅ Le ticket est mis à jour avec un résumé
- ✅ Les patterns découverts sont documentés

## Support

- **Documentation** : `AGENTS.md`
- **Constitution** : `.agent/constitution.md`
- **Skills** : `skills/registry.json`
- **Logs** : `logs/`

---

**Bonne mission, agent !** 🚀
