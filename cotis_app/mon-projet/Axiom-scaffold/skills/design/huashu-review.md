---
title: "Huashu-Design Review"
domain: "design"
complexity: "advanced"
triggers: ["design", "review", "maquette", "mockup", "ui", "interface", "huashu"]
priority: 8
source: "axiom-scaffold"
---

# Skill : Huashu-Design Review

## Méta-données

- **Domaine** : Design
- **Complexité** : Avancé
- **Déclencheurs** : design, review, maquette, mockup, ui, interface, huashu
- **Source** : axiom-scaffold

---

## Objectif

Ce skill implémente la méthodologie Huashu-Design pour évaluer et améliorer les maquettes UI selon 5 dimensions critiques. L'objectif est d'atteindre un score minimum de 0.85/1.0 avant validation.

---

## Méthodologie Huashu-Design

### Les 5 Dimensions (5D)

#### 1. Layout (Hiérarchie Visuelle)
**Score: 0-10**

Critères d'évaluation:
- ✅ Hiérarchie claire (primaire, secondaire, tertiaire)
- ✅ Grille cohérente (8px, 16px, 24px, etc.)
- ✅ Espacement respirant (pas de surcharge)
- ✅ Alignement précis (pas de décalages)
- ✅ Proportions harmonieuses (ratio golden, rule of thirds)

**Scoring:**
- 10/10 : Hiérarchie parfaite, grille stricte, espacement optimal
- 7-9/10 : Bonne hiérarchie, quelques ajustements mineurs
- 4-6/10 : Hiérarchie présente mais incohérente
- 0-3/10 : Pas de hiérarchie claire, layout chaotique

#### 2. Typographie (Lisibilité)
**Score: 0-10**

Critères d'évaluation:
- ✅ Hiérarchie typographique (h1 > h2 > h3 > body > caption)
- ✅ Lisibilité (line-height, letter-spacing)
- ✅ Contraste suffisant (4.5:1 minimum)
- ✅ Cohérence des styles (pas de variations aléatoires)
- ✅ Responsive (tailles adaptées aux breakpoints)

**Scoring:**
- 10/10 : Hiérarchie parfaite, lisibilité optimale, cohérence totale
- 7-9/10 : Bonne typographie, quelques ajustements
- 4-6/10 : Lisible mais incohérent
- 0-3/10 : Illisible ou chaotique

#### 3. Couleur (Harmonie)
**Score: 0-10**

Critères d'évaluation:
- ✅ Palette limitée (3-5 couleurs principales)
- ✅ Contraste suffisant (WCAG AA minimum)
- ✅ Harmonie (couleurs complémentaires ou analogues)
- ✅ Saturation contrôlée (≤70% sauf exceptions)
- ✅ Conformité au design system

**Scoring:**
- 10/10 : Palette harmonieuse, contraste parfait, design system respecté
- 7-9/10 : Bonne palette, quelques ajustements
- 4-6/10 : Palette acceptable mais incohérente
- 0-3/10 : Palette chaotique ou contraste insuffisant

#### 4. Mouvement (Animations)
**Score: 0-10**

Critères d'évaluation:
- ✅ Animations subtiles (≤300ms)
- ✅ Easing naturel (cubic-bezier)
- ✅ Feedback immédiat (hover, focus, active)
- ✅ Pas d'animations infinies sans raison
- ✅ Respect de prefers-reduced-motion

**Scoring:**
- 10/10 : Animations subtiles, feedback parfait, accessible
- 7-9/10 : Bonnes animations, quelques ajustements
- 4-6/10 : Animations présentes mais excessives
- 0-3/10 : Pas d'animations ou animations gênantes

#### 5. Cohérence (Design System)
**Score: 0-10**

Critères d'évaluation:
- ✅ Respect du design system (tokens, composants)
- ✅ Patterns cohérents (boutons, inputs, cards)
- ✅ Accessibilité (ARIA, keyboard, screen readers)
- ✅ Responsive (mobile, tablet, desktop)
- ✅ Maintenabilité (code propre, commenté)

**Scoring:**
- 10/10 : Design system respecté à 100%, accessible, responsive
- 7-9/10 : Bonne cohérence, quelques écarts mineurs
- 4-6/10 : Cohérence partielle
- 0-3/10 : Pas de cohérence, design system ignoré

---

## Processus de Revue

### Étape 1 : Analyse Initiale

1. **Charger la maquette** (HTML/CSS)
2. **Identifier les éléments** (layout, typo, couleurs, animations)
3. **Vérifier la conformité** au design system

### Étape 2 : Scoring 5D

Pour chaque dimension:
1. **Évaluer** selon les critères
2. **Attribuer un score** (0-10)
3. **Documenter** les points forts et faibles

### Étape 3 : Calcul du Score Total

```
Score Total = (Layout + Typographie + Couleur + Mouvement + Cohérence) / 50
```

**Seuil de validation : 0.85 (42.5/50)**

### Étape 4 : Feedback et Itération

Si score < 0.85:
1. **Lister les problèmes** par ordre de priorité
2. **Proposer des corrections** concrètes
3. **Itérer** jusqu'à score ≥ 0.85

---

## Format du Rapport

```json
{
  "screen": "login",
  "library": "Chakra UI",
  "framework": "react",
  "style": "modern",
  "mockupFile": "design/screens/login.html",
  "timestamp": "2026-05-08T10:30:00Z",
  "status": "completed",
  "iteration": 2,
  "scores": {
    "layout": 9,
    "typography": 8,
    "color": 10,
    "motion": 7,
    "coherence": 9,
    "total": 0.86
  },
  "feedback": [
    {
      "dimension": "motion",
      "issue": "Animations trop longues (500ms)",
      "recommendation": "Réduire à 300ms maximum",
      "priority": "high"
    }
  ],
  "strengths": [
    "Palette de couleurs harmonieuse",
    "Hiérarchie typographique claire",
    "Design system respecté"
  ],
  "weaknesses": [
    "Animations trop lentes"
  ],
  "approved": true
}
```

---

## Exemple de Revue

### Maquette : Login Screen

#### Analyse

**Layout (9/10)**
- ✅ Hiérarchie claire (logo > titre > formulaire > CTA)
- ✅ Grille de 8px respectée
- ✅ Espacement respirant
- ⚠️ Bouton CTA légèrement décalé (2px)

**Typographie (8/10)**
- ✅ Hiérarchie h1 > body > caption
- ✅ Line-height optimal (1.5)
- ✅ Contraste 7:1 (excellent)
- ⚠️ Taille du caption trop petite (10px → 12px)

**Couleur (10/10)**
- ✅ Palette limitée (primary, neutral, success)
- ✅ Contraste WCAG AAA
- ✅ Saturation ≤70%
- ✅ Design system respecté

**Mouvement (7/10)**
- ✅ Feedback hover/focus
- ✅ Easing cubic-bezier
- ⚠️ Durée trop longue (500ms → 300ms)
- ⚠️ Pas de prefers-reduced-motion

**Cohérence (9/10)**
- ✅ Composants Chakra UI
- ✅ ARIA labels présents
- ✅ Responsive
- ⚠️ Un input sans label visible

**Score Total : 43/50 = 0.86 ✅**

#### Feedback

**Corrections Prioritaires:**
1. Réduire durée animations à 300ms
2. Augmenter taille caption à 12px
3. Ajouter label visible sur input email
4. Corriger alignement bouton CTA

**Corrections Optionnelles:**
5. Ajouter prefers-reduced-motion

---

## Anti-patterns

### ❌ Ne Pas Faire

1. **Approuver sans atteindre 0.85** : Le seuil est strict
2. **Ignorer l'accessibilité** : ARIA, keyboard, screen readers
3. **Négliger le responsive** : Tester mobile, tablet, desktop
4. **Oublier le design system** : Toujours valider les tokens
5. **Scorer subjectivement** : Utiliser les critères objectifs

### ✅ Faire

1. **Être rigoureux** : Chaque dimension compte
2. **Documenter** : Feedback clair et actionnable
3. **Itérer** : Améliorer jusqu'à 0.85
4. **Valider** : Tester avec de vrais utilisateurs si possible
5. **Archiver** : Sauvegarder les rapports

---

## Outils Recommandés

### Validation
- **WAVE** : Accessibilité (https://wave.webaim.org)
- **Lighthouse** : Performance et accessibilité
- **Contrast Checker** : Contraste WCAG

### Design
- **Figma** : Maquettes haute-fidélité
- **Storybook** : Bibliothèque de composants
- **Chromatic** : Visual regression testing

---

## Intégration avec le Pipeline

```bash
# Lancer le pipeline complet
./scripts/design-pipeline.sh --framework react --style modern --screen login

# Le pipeline:
# 1. Sélectionne la bibliothèque
# 2. Génère les instructions
# 3. Valide les couleurs
# 4. Lance la revue Huashu-Design
# 5. Itère jusqu'à score ≥ 0.85
```

---

**Version** : 1.0.0  
**Dernière mise à jour** : 2026-05-08
