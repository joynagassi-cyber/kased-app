# Skills Design — Axiom-Scaffold

Ce répertoire contient les skills spécialisés pour le design UI/UX dans Axiom-Scaffold.

## Skills Disponibles

### 1. Huashu-Design Review
**Fichier** : `huashu-review.md`  
**Triggers** : design, review, maquette, mockup, ui, interface, huashu

Méthodologie de revue 5D pour évaluer et améliorer les maquettes UI :
- **Layout** : Hiérarchie visuelle, grille, espacement
- **Typographie** : Lisibilité, hiérarchie, contraste
- **Couleur** : Harmonie, contraste, design system
- **Mouvement** : Animations, feedback, accessibilité
- **Cohérence** : Design system, patterns, responsive

**Score minimum requis** : 0.85/1.0

## Bibliothèques de Composants Supportées

Le fichier `bibliotheques.json` contient 12 bibliothèques UI :

### React
- **Chakra UI** : Modern, accessibilité excellente
- **Material UI** : Material Design, composants riches
- **Geist UI** : Minimal, style Vercel
- **Gestalt** : Design system Pinterest
- **Gluestack UI** : Universal (web + mobile)
- **Primer React** : Design system GitHub
- **Radix UI** : Headless, accessibilité parfaite
- **shadcn/ui** : Composants copiables, Tailwind
- **Ant Design** : Enterprise, composants riches
- **Mantine** : Modern, documentation excellente

### SolidJS
- **Kobalte** : Headless, performance exceptionnelle

### Framework Agnostic
- **DaisyUI** : Tailwind CSS, thèmes prédéfinis

## Scripts Disponibles

### 1. select-library.js
Sélectionne la meilleure bibliothèque selon les critères.

```bash
node scripts/select-library.js --framework react --style modern
node scripts/select-library.js --framework solid --style minimal
node scripts/select-library.js --framework react --style modern --accessibility excellent
```

**Critères de scoring** :
- Accessibilité (poids: 3)
- Personnalisation (poids: 2)
- Performance (poids: 2 si --performance, sinon 1)
- Documentation (poids: 1)

### 2. validate-colors.js
Valide que toutes les couleurs d'une maquette sont dans le design system.

```bash
node scripts/validate-colors.js design/screens/login.html
node scripts/validate-colors.js design/screens/*.html
```

**Validation** :
- Extrait les couleurs hex (#RGB, #RRGGBB, #RRGGBBAA)
- Compare avec `design/design-system.json`
- Retourne les couleurs non autorisées

### 3. design-pipeline.sh
Pipeline complet de design automatisé.

```bash
./scripts/design-pipeline.sh --framework react --style modern --screen login
```

**Étapes** :
1. Sélection de la bibliothèque UI
2. Génération des instructions de maquette
3. Validation des couleurs
4. Revue Huashu-Design (5D)
5. Itération jusqu'à score > 0.85

## Design System

Le fichier `design/design-system.json` contient les tokens de design :

### Couleurs
- **Primary** : Couleur principale (6 nuances)
- **Neutral** : Gris (7 nuances)
- **Success** : Vert (3 nuances)
- **Warning** : Orange (3 nuances)
- **Error** : Rouge (3 nuances)
- **Info** : Bleu (3 nuances)

### Typographie
- **Font Family** : Inter (sans-serif)
- **Font Sizes** : xs (12px) → 3xl (48px)
- **Font Weights** : normal (400), medium (500), semibold (600), bold (700)
- **Line Heights** : tight (1.25) → loose (2)

### Espacement
- **Grille de 8px** : xs (8px) → 3xl (96px)

### Ombres
- **4 niveaux** : sm, md, lg, xl

### Animations
- **Durées** : fast (150ms), normal (300ms), slow (500ms)
- **Easing** : ease-in, ease-out, ease-in-out

## Contraintes de Design

### Couleurs
- ✅ Utiliser UNIQUEMENT les couleurs du design system
- ✅ Saturation maximale : 70% en HSL (sauf annotation)
- ✅ Contraste minimum : 4.5:1 pour texte normal (WCAG AA)

### Typographie
- ✅ Hiérarchie claire (h1 > h2 > h3 > body > caption)
- ✅ Line-height : 1.5 pour body, 1.2 pour headings
- ✅ Letter-spacing : -0.02em pour headings

### Espacement
- ✅ Grille de 8px stricte
- ✅ Espacement cohérent (xs, sm, md, lg, xl)

### Animations
- ✅ Durée maximale : 300ms
- ✅ Easing : cubic-bezier uniquement
- ✅ Pas d'animations infinies sans raison
- ✅ Support de prefers-reduced-motion

### Accessibilité
- ✅ ARIA labels sur tous les éléments interactifs
- ✅ Navigation au clavier complète
- ✅ Support des lecteurs d'écran
- ✅ Contraste WCAG AA minimum (AAA recommandé)

## Workflow de Design

### 1. Initialisation
```bash
# Lancer le pipeline
./scripts/design-pipeline.sh --framework react --style modern --screen login
```

### 2. Génération de la Maquette
- Lire les instructions générées (`design/screens/login.instructions.md`)
- Générer la maquette HTML/CSS
- Sauvegarder dans `design/screens/login.html`

### 3. Validation
```bash
# Valider les couleurs
node scripts/validate-colors.js design/screens/login.html
```

### 4. Revue Huashu-Design
- Activer le skill `huashu-review.md`
- Évaluer selon les 5 dimensions
- Générer le rapport dans `design/review/huashu-reports/`

### 5. Itération
- Si score < 0.85 : corriger et recommencer
- Si score ≥ 0.85 : approuver et passer à l'implémentation

### 6. Export (Optionnel)
- Export A2UI : `design/a2ui/login.a2ui.json`
- Export Figma : `design/figma-export.json`

## Ajouter une Nouvelle Bibliothèque

1. Éditer `skills/design/bibliotheques.json`
2. Ajouter l'entrée avec les champs requis :
   - `id` : Identifiant unique
   - `name` : Nom de la bibliothèque
   - `technos` : Technologies supportées
   - `style` : Style de design
   - `accessibility` : Niveau d'accessibilité
   - `strengths` : Points forts
   - `weaknesses` : Points faibles
   - `url` : Documentation
   - `score` : Scores (accessibility, customization, performance, documentation)

3. Mettre à jour les index :
   - `styleCategories` : Ajouter le style si nouveau
   - `technoIndex` : Ajouter la techno si nouvelle

## Ressources

### Documentation
- **WCAG 2.1** : https://www.w3.org/WAI/WCAG21/quickref/
- **ARIA** : https://www.w3.org/WAI/ARIA/apg/
- **Style Dictionary** : https://amzn.github.io/style-dictionary/

### Outils
- **WAVE** : https://wave.webaim.org (accessibilité)
- **Contrast Checker** : https://webaim.org/resources/contrastchecker/
- **Lighthouse** : https://developers.google.com/web/tools/lighthouse

### Inspiration
- **Dribbble** : https://dribbble.com
- **Behance** : https://www.behance.net
- **Awwwards** : https://www.awwwards.com

---

**Version** : 1.0.0  
**Dernière mise à jour** : 2026-05-08
