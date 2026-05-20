# Couche 7 — Apprentissage & Skills Auto-Générés : Documentation Complète

**Version** : 1.0.0  
**Date** : 2026-05-08  
**Statut** : ✅ Implémenté

---

## 📋 Table des Matières

1. [Introduction](#introduction)
2. [Objectifs](#objectifs)
3. [Architecture](#architecture)
4. [Installation](#installation)
5. [Utilisation](#utilisation)
6. [Format des Événements](#format-des-événements)
7. [Détection de Patterns](#détection-de-patterns)
8. [Génération de Skills](#génération-de-skills)
9. [Mise à Jour de la Constitution](#mise-à-jour-de-la-constitution)
10. [Intégration](#intégration)
11. [Dépannage](#dépannage)

---

## 1. Introduction

La **Couche 7 (Apprentissage & Skills Auto-Générés)** est la **mémoire immunitaire** d'Axiom-Scaffold. Elle capture chaque succès, chaque échec, chaque correction, et les transforme en **connaissances réutilisables**.

### Principe Fondamental

> **Ne jamais corriger deux fois la même erreur.** Si un bug survient et est corrigé, le système crée une règle ou un skill pour que l'agent ne le reproduise plus jamais.

### Innovation Majeure

L'**apprentissage automatique sans intervention humaine** :
- Capture automatique des événements de développement
- Détection de patterns récurrents par similarité
- Génération automatique de skills (compétences agentiques)
- Mise à jour automatique de la constitution du projet

---

## 2. Objectifs

### Objectifs Principaux

1. **Capturer** tous les événements significatifs (succès, échecs, corrections)
2. **Structurer** ces événements dans un format standard (YAML)
3. **Analyser** les événements pour détecter des motifs récurrents
4. **Générer automatiquement** des skills lorsqu'un pattern est détecté (≥3 occurrences)
5. **Mettre à jour la constitution** pour les patterns très fréquents (≥5 occurrences)
6. **Enrichir le registre** pour que les skills soient automatiquement chargés
7. **Stocker l'historique** dans Obsidian pour traçabilité
8. **Fonctionner de manière asynchrone** après chaque cycle de développement

### Bénéfices

- **Amélioration continue** : Le système apprend de ses erreurs
- **Réduction des bugs** : Les erreurs ne se répètent pas
- **Montée en compétence** : Accumulation de connaissances
- **Traçabilité** : Historique complet des apprentissages
- **Autonomie** : Pas d'intervention humaine requise

---

## 3. Architecture

### Vue d'Ensemble

```
┌─────────────────────────────────────────────────────────────────┐
│          COUCHE 7 – APPRENTISSAGE & SKILLS AUTO-GÉNÉRÉS         │
│                                                                  │
│  Événements bruts (logs YAML)                                   │
│      │                                                           │
│      ▼                                                           │
│  1. CAPTURE (after-agent.sh)                                    │
│     - Succès (pattern, code final, tests)                       │
│     - Échecs (erreur, tentative, correction finale)             │
│     - Décisions (ADR informel)                                  │
│      │                                                           │
│      ▼                                                           │
│  2. ANALYSE (learn.sh)                                          │
│     - Extraire les keywords                                      │
│     - Rechercher des similarités (comparaison de keywords)      │
│     - Grouper par motifs récurrents                              │
│      │                                                           │
│      ▼                                                           │
│  3. GÉNÉRATION & MISE À JOUR (generate-skill.sh)               │
│     - Créer un SKILL.md dans skills/generated/                  │
│     - Mettre à jour skills/registry.json                        │
│     - Si ≥5 occurrences → enrichir constitution.md              │
│     - Stocker le rapport dans learning/reports/                 │
└─────────────────────────────────────────────────────────────────┘
```

### Composants

#### 1. Capture des Événements
- **Déclencheur** : `script/after-agent.sh` (Couche 0)
- **Format** : YAML structuré
- **Stockage** : `learning/events/`

#### 2. Analyse des Patterns
- **Script** : `scripts/learn.sh`
- **Méthode** : Comparaison de keywords (similarité textuelle)
- **Seuil** : ≥3 occurrences pour détecter un pattern

#### 3. Génération de Skills
- **Script** : `scripts/generate-skill.sh`
- **Format** : Markdown avec frontmatter YAML
- **Stockage** : `skills/generated/`

#### 4. Mise à Jour du Registre
- **Fichier** : `skills/registry.json`
- **Automatique** : Après chaque génération de skill

#### 5. Mise à Jour de la Constitution
- **Fichier** : `specs/rules/constitution.md`
- **Seuil** : ≥5 occurrences
- **Section** : "Règles auto-générées"

---

## 4. Installation

### Prérequis

- Couche 0 (Harness Engineering) installée
- Couche 1 (Mémoire Universelle) installée
- Couche 2 (Spécifications & Skills) installée
- Couche 5 (Exécution Zero-Trust) installée
- `yq` (optionnel, pour parser YAML)
- `jq` (requis, pour parser JSON)

### Installation

Aucune installation spécifique requise. Les scripts sont prêts à l'emploi.

### Vérification

```bash
# Vérifier que les répertoires existent
ls -lh learning/events learning/patterns learning/reports skills/generated

# Vérifier que les scripts existent
ls -lh scripts/learn.sh scripts/generate-skill.sh
```

---

## 5. Utilisation

### Workflow Automatique

Le système fonctionne automatiquement après chaque cycle de développement :

1. **Exécution d'une micro-tâche** (Couche 5)
2. **Génération d'un événement** YAML dans `learning/events/`
3. **Appel automatique** de `learn.sh` par `after-agent.sh`
4. **Analyse et génération** de skills si patterns détectés
5. **Mise à jour** du registre et de la constitution

### Workflow Manuel

```bash
# Analyser les événements manuellement
./scripts/learn.sh learning/events

# Générer un skill manuellement
./scripts/generate-skill.sh learning/patterns/email-validation.json learning/events/cycle-42.yaml
```

### Consultation des Résultats

```bash
# Voir les patterns détectés
ls -lh learning/patterns/

# Voir les skills générés
ls -lh skills/generated/

# Voir les rapports d'apprentissage
ls -lh learning/reports/

# Lire le dernier rapport
cat learning/reports/$(ls -t learning/reports/ | head -1)
```

---

## 6. Format des Événements

### Structure YAML

```yaml
# Identifiant unique du cycle
cycle_id: "cycle-042"

# Horodatage ISO 8601
timestamp: "2026-05-08T14:30:00Z"

# Feature parente
feature: "paiement-stripe"

# Identifiant de la micro-tâche
task_id: "task-001"

# Symbole cible (fonction, classe, module)
target_symbol: "validateEmail"

# Statut final : success | failure | corrected
status: "corrected"

# Nombre de tentatives
attempts: 2

# Log d'erreur (null si success)
error_log: |
  TypeError: Cannot read property 'includes' of undefined
  at validateEmail (src/utils/validation.ts:12:15)

# Correction appliquée (null si success ou failure)
correction_applied: |
  Ajout d'une vérification de nullité avant d'appeler includes()
  Remplacement de includes('@') par lastIndexOf('@')

# Snippet de code final (version validée)
final_code_snippet: |
  function validateEmail(email: string): ValidationResult {
    if (!email || email.length > 254) {
      return { isValid: false, error: 'TOO_LONG' };
    }
    const atIndex = email.lastIndexOf('@');
    if (atIndex === -1) {
      return { isValid: false, error: 'MISSING_AT_SIGN' };
    }
    return { isValid: true };
  }

# Nombre de tests passés
tests_passed: 12

# Mots-clés pour la détection de patterns
pattern_keywords:
  - email
  - validation
  - regex
  - validate

# Fichiers modifiés
files_modified:
  - src/utils/validation.ts
  - tests/utils/validation.test.ts

# Score d'impact (0-1)
impact_score: 0.75

# Temps d'exécution (secondes)
execution_time: 180

# Résultats de validation
validation_results:
  compilation: true
  linting: true
  unit_tests: true
  mutation_tests: true
  security_scan: true
  visual_regression: true
```

### Génération Automatique

Les événements sont générés automatiquement par la Couche 5 (Exécution Zero-Trust) à la fin de chaque micro-tâche.

---

## 7. Détection de Patterns

### Méthode de Détection

1. **Extraction des keywords** de chaque événement
2. **Comparaison** avec les événements précédents
3. **Calcul de similarité** : % de keywords en commun
4. **Seuil** : ≥50% de keywords en commun
5. **Groupement** : Si ≥3 événements similaires, pattern détecté

### Exemple

**Événement 1** :
- Keywords : `email`, `validation`, `regex`

**Événement 2** :
- Keywords : `email`, `validate`, `input`

**Événement 3** :
- Keywords : `email`, `validation`, `check`

**Similarité** :
- Événement 1 ↔ 2 : 2/3 = 67% ✅
- Événement 1 ↔ 3 : 2/3 = 67% ✅
- Événement 2 ↔ 3 : 2/3 = 67% ✅

**Pattern détecté** : `email-validation` (3 occurrences)

### Seuils

| Occurrences | Action                                     |
| ----------- | ------------------------------------------ |
| 1-2         | Aucune action (pas de pattern)             |
| 3-4         | Génération d'un skill                      |
| ≥5          | Génération d'un skill + règle constitution |

---

## 8. Génération de Skills

### Format du Skill

```markdown
---
id: email-validation
domain: validation
complexity: intermediate
triggers:
  - email
  - validation
  - regex
  - validate
source: auto-generated
generated_from: 4 occurrences
generated_at: 2026-05-08T14:30:00Z
example_event: cycle-042.yaml
---

# Skill : email-validation

## 📋 Objectif

Ce skill a été généré automatiquement à partir de **4 occurrences** d'un pattern récurrent.

**Symbole cible** : `validateEmail`

## 🔄 Processus

### Étapes recommandées

1. **Analyser le contexte** : Identifier les entrées et sorties attendues
2. **Valider les entrées** : Vérifier la nullité, le type, et les contraintes
3. **Implémenter la logique** : Suivre l'exemple de code ci-dessous
4. **Gérer les erreurs** : Retourner des résultats typés, éviter les exceptions
5. **Tester exhaustivement** : Couvrir tous les cas limites

## ⚠️ Anti-patterns

### Erreurs communes

- Ne pas vérifier la nullité avant d'accéder aux propriétés
- Utiliser `includes('@')` au lieu de `lastIndexOf('@')`
- Lancer des exceptions dans une fonction de validation

## 💻 Exemple de code

\`\`\`typescript
function validateEmail(email: string): ValidationResult {
  if (!email || email.length > 254) {
    return { isValid: false, error: 'TOO_LONG' };
  }
  const atIndex = email.lastIndexOf('@');
  if (atIndex === -1) {
    return { isValid: false, error: 'MISSING_AT_SIGN' };
  }
  return { isValid: true };
}
\`\`\`

## 📊 Historique

- **Généré automatiquement** le 2026-05-08 à partir de 4 occurrences
- **Pattern détecté** : email-validation
- **Keywords** : email, validation, regex, validate
```

### Chargement Automatique

Le skill est automatiquement ajouté au registre (`skills/registry.json`) et sera chargé par le minimiseur (Couche 3) lors des prochaines tâches similaires.

---

## 9. Mise à Jour de la Constitution

### Seuil de Déclenchement

Lorsqu'un pattern atteint **≥5 occurrences**, une règle est automatiquement ajoutée à la constitution.

### Format de la Règle

```markdown
## Règles auto-générées

Ces règles ont été générées automatiquement par la Couche 7 (Apprentissage) à partir de patterns récurrents.

- [2026-05-08] Pattern récurrent détecté : email-validation (5 occurrences). Utiliser le skill généré.
- [2026-05-09] Pattern récurrent détecté : sql-injection-prevention (6 occurrences). Utiliser le skill généré.
```

### Effet

Les agents respecteront ces règles lors des prochains cycles de développement. La constitution est **immuable** pour les agents (Couche 2), donc ces règles ne peuvent pas être contournées.

---

## 10. Intégration

### 10.1 Couche 0 (Harness Engineering)

**Intégration** : `script/after-agent.sh` appelle `learn.sh`

```bash
# 6. Apprentissage automatique
echo "   🧠 Apprentissage automatique..."
if [ -f "scripts/learn.sh" ]; then
    bash scripts/learn.sh learning/events > logs/learning.log 2>&1
fi
```

### 10.2 Couche 1 (Mémoire Universelle)

**Intégration future** : Vectorisation des événements avec Pinecone

- Recherche de similarité par vecteurs (plus précis que keywords)
- Clustering automatique des événements
- Détection de patterns complexes

### 10.3 Couche 2 (Spécifications & Skills)

**Intégration** : Skills générés dans `skills/generated/`

- Format canonique respecté (frontmatter YAML)
- Ajout automatique au registre
- Chargement automatique par le minimiseur

### 10.4 Couche 3 (Minimiseur de Contexte)

**Intégration** : Chargement automatique des skills

- Le minimiseur lit le registre
- Les skills auto-générés sont éligibles au chargement
- Activation basée sur les triggers (keywords)

### 10.5 Couche 5 (Exécution Zero-Trust)

**Intégration** : Génération automatique des événements

- Après chaque micro-tâche, un événement YAML est créé
- Stocké dans `learning/events/`
- Analysé par `learn.sh`

### 10.6 Couche 6 (Visualisation)

**Intégration future** : Badges sur les clusters

- Afficher le nombre de skills générés par cluster
- Visualiser les patterns récurrents
- Identifier les zones à risque

### 10.7 Couche 8 (Sécurité)

**Intégration future** : Skills de sécurité renforcés

- Détection de vulnérabilités récurrentes
- Génération de skills de sécurité
- Mise à jour automatique des politiques

---

## 11. Dépannage

### Problème : Aucun skill n'est généré

**Cause** : Pas assez d'événements similaires (seuil non atteint)

**Solution** :
```bash
# Vérifier le nombre d'événements
ls -lh learning/events/ | wc -l

# Vérifier les patterns détectés
cat learning/reports/$(ls -t learning/reports/ | head -1)

# Réduire le seuil temporairement (pour test)
# Éditer scripts/learn.sh et changer MIN_OCCURRENCES=3 à MIN_OCCURRENCES=2
```

### Problème : Les skills ne sont pas chargés

**Cause** : Le registre n'est pas à jour

**Solution** :
```bash
# Vérifier le registre
cat skills/registry.json | jq '.skills[] | select(.source == "auto-generated")'

# Régénérer le registre si nécessaire
./scripts/generate-skill.sh learning/patterns/<pattern>.json learning/events/<event>.yaml
```

### Problème : Les événements ne sont pas générés

**Cause** : La Couche 5 n'est pas configurée pour générer des événements

**Solution** :
```bash
# Vérifier que execute-task.sh génère des événements
# Ajouter à la fin de execute-task.sh :

# Générer un événement d'apprentissage
cat > "learning/events/$(date +%Y-%m-%d-%H%M%S)-cycle-$TASK_ID.yaml" << EOF
cycle_id: "cycle-$TASK_ID"
timestamp: "$(date -Iseconds)"
# ... autres champs
EOF
```

### Problème : Le script learn.sh échoue

**Cause** : `yq` ou `jq` n'est pas installé

**Solution** :
```bash
# Installer yq (optionnel)
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq

# Installer jq (requis)
sudo apt-get install jq  # Linux
brew install jq          # macOS
```

### Problème : Les patterns sont mal détectés

**Cause** : Les keywords ne sont pas assez spécifiques

**Solution** :
```bash
# Améliorer l'extraction des keywords
# Éditer la Couche 5 pour extraire des keywords plus pertinents
# Utiliser des techniques NLP (stemming, lemmatization)
```

---

## 📚 Ressources

### Documentation
- **[Couche 0 (Harness)](ARCHITECTURE.md)** : Déclenchement automatique
- **[Couche 1 (Mémoire)](MEMORY.md)** : Vectorisation future
- **[Couche 2 (Skills)](SPECS-AND-SKILLS.md)** : Format des skills
- **[Couche 3 (Minimiseur)](CONTEXT-MINIMIZER.md)** : Chargement des skills
- **[Couche 5 (Exécution)](EXECUTION-ZERO-TRUST.md)** : Génération des événements

### Exemples
- **`learning/event-template.yaml`** : Template d'événement
- **`skills/generated/`** : Skills auto-générés
- **`learning/reports/`** : Rapports d'apprentissage

### Scripts
- **`scripts/learn.sh`** : Pipeline d'apprentissage
- **`scripts/generate-skill.sh`** : Génération de skills

---

## 🎉 Conclusion

La **Couche 7 (Apprentissage & Skills Auto-Générés)** est la mémoire immunitaire d'Axiom-Scaffold.

**Vous pouvez maintenant** :
- ✅ Capturer automatiquement les événements de développement
- ✅ Détecter des patterns récurrents
- ✅ Générer automatiquement des skills
- ✅ Mettre à jour la constitution automatiquement
- ✅ Améliorer continuellement le système sans intervention humaine

**Principe fondamental respecté** : Ne jamais corriger deux fois la même erreur.

---

**Date** : 2026-05-08  
**Version** : 1.8.0  
**Auteur** : Axiom-Scaffold Team
