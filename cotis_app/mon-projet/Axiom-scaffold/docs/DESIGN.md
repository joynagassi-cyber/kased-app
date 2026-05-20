# Couche 4 : Design & Spécifications UI

## Vue d'Ensemble

La **Couche 4** d'Axiom-Scaffold fournit un système complet de design UI/UX avec :
- **Design System** : Tokens de design (couleurs, typographie, espacement)
- **Bibliothèques de Composants** : 12 bibliothèques UI supportées
- **Pipeline Automatisé** : Sélection, génération, validation, revue
- **Revue Huashu-Design** : Méthodologie 5D pour évaluer les maquettes
- **Validation Stricte** : Conformité au design system

---

## Architecture

```
design/
├── design-system.json          # Tokens de design (Style Dictionary)
├── screens/                    # Maquettes HTML/CSS
│   ├── login.html
│   ├── login.instructions.md
│   └── dashboard.html
├── a2ui/                       # Exports A2UI (déclaratif)
│   └── login.a2ui.json
├── review/                     # Rapports de revue
│   └── huashu-reports/
│       └── login-20260508-103000.json
└── figma-export.json           # Exports Figma

skills/design/
├── bibliotheques.json          # Base de données des bibliothèques UI
├── huashu-review.md            # Skill de revue 5D
└── README.md                   # Documentation des skills

scripts/
├── select-library.js           # Sélection de bibliothèque
├── validate-colors.js          # Validation des couleurs
└── design-pipeline.sh          # Pipeline complet
```

---

## Design System

### Structure

Le fichier `design/design-system.json` suit la spécification **Style Dictionary** :

```json
{
  "color": {
    "primary": {
      "50": { "value": "#e3f2fd", "saturation": 0.92, "luminance": 0.94 },
      "500": { "value": "#2196f3", "saturation": 0.79, "luminance": 0.54 }
    }
  },
  "typography": {
    "fontFamily": { "sans": { "value": "Inter, sans-serif" } },
    "fontSize": { "base": { "value": "16px" } }
  },
  "spacing": {
    "md": { "value": "24px" }
  }
}
```

### Catégories

#### 1. Couleurs
- **Primary** : Couleur principale (6 nuances : 50, 100, 200, 500, 700, 900)
- **Neutral** : Gris (7 nuances : 50, 100, 200, 300, 500, 700, 900)
- **Success** : Vert (3 nuances : 100, 500, 700)
- **Warning** : Orange (3 nuances : 100, 500, 700)
- **Error** : Rouge (3 nuances : 100, 500, 700)
- **Info** : Bleu (3 nuances : 100, 500, 700)

**Métadonnées** :
- `saturation` : Saturation HSL (max 70% sauf exceptions)
- `luminance` : Luminance relative (contraste WCAG)

#### 2. Typographie
- **Font Family** : Inter (sans-serif)
- **Font Sizes** : xs (12px), sm (14px), base (16px), lg (18px), xl (20px), 2xl (24px), 3xl (48px)
- **Font Weights** : normal (400), medium (500), semibold (600), bold (700)
- **Line Heights** : tight (1.25), snug (1.375), normal (1.5), relaxed (1.625), loose (2)

#### 3. Espacement
- **Grille de 8px** : xs (8px), sm (16px), md (24px), lg (32px), xl (48px), 2xl (64px), 3xl (96px)

#### 4. Ombres
- **sm** : 0 1px 2px rgba(0,0,0,0.05)
- **md** : 0 4px 6px rgba(0,0,0,0.1)
- **lg** : 0 10px 15px rgba(0,0,0,0.1)
- **xl** : 0 20px 25px rgba(0,0,0,0.1)

#### 5. Animations
- **Durées** : fast (150ms), normal (300ms), slow (500ms)
- **Easing** : ease-in, ease-out, ease-in-out

---

## Bibliothèques de Composants

### Liste Complète (12 bibliothèques)

| Bibliothèque     | Framework | Style      | Accessibilité | Score Total |
| ---------------- | --------- | ---------- | ------------- | ----------- |
| **Chakra UI**    | React     | Modern     | Excellent     | 35/40       |
| **Material UI**  | React     | Material   | Excellent     | 33/40       |
| **Geist UI**     | React     | Minimal    | Good          | 32/40       |
| **Gestalt**      | React     | Pinterest  | Excellent     | 33/40       |
| **Gluestack UI** | React/RN  | Universal  | Excellent     | 37/40       |
| **Kobalte**      | SolidJS   | Headless   | Excellent     | 38/40       |
| **Primer React** | React     | GitHub     | Excellent     | 34/40       |
| **Radix UI**     | React     | Headless   | Excellent     | 38/40       |
| **shadcn/ui**    | React     | Modern     | Excellent     | 38/40       |
| **Ant Design**   | React     | Enterprise | Good          | 27/40       |
| **Mantine**      | React     | Modern     | Excellent     | 36/40       |
| **DaisyUI**      | Tailwind  | Playful    | Good          | 34/40       |

### Critères de Sélection

Le script `select-library.js` utilise un système de scoring :

1. **Accessibilité** (poids: 3)
   - Excellent (≥9) : +30 points
   - Good (≥7) : +20 points
   - Moyen : +10 points

2. **Personnalisation** (poids: 2)
   - Excellent (≥9) : +20 points
   - Good (≥7) : +15 points
   - Moyen : +10 points

3. **Performance** (poids: 2 si --performance, sinon 1)
   - Excellent (≥9) : +20 points (×2 si --performance)
   - Good (≥7) : +15 points (×2 si --performance)
   - Moyen : +10 points (×2 si --performance)

4. **Documentation** (poids: 1)
   - Excellent (≥9) : +10 points
   - Good (≥7) : +7 points
   - Moyen : +5 points

5. **Bonus** : +10 points si le style correspond exactement

---

## Pipeline de Design

### Commande Complète

```bash
./scripts/design-pipeline.sh --framework react --style modern --screen login
```

### Étapes du Pipeline

#### 1. Sélection de la Bibliothèque UI

```bash
node scripts/select-library.js --framework react --style modern --accessibility excellent
```

**Sortie** :
```json
{
  "success": true,
  "selected": {
    "id": "chakra-ui",
    "name": "Chakra UI",
    "technos": ["react", "typescript"],
    "style": "modern",
    "accessibility": "excellent",
    "url": "https://chakra-ui.com",
    "score": 90,
    "scoreDetails": [
      "Accessibilité excellente (+30)",
      "Personnalisation excellente (+20)",
      "Performance bonne (+15)",
      "Documentation excellente (+10)",
      "Style correspondant (+10)"
    ]
  },
  "alternatives": [
    { "id": "mantine", "name": "Mantine", "score": 86 },
    { "id": "shadcn-ui", "name": "shadcn/ui", "score": 85 }
  ]
}
```

#### 2. Génération des Instructions

Le pipeline génère un fichier `design/screens/{screen}.instructions.md` :

```markdown
# Instructions de Maquette — login

## Bibliothèque Sélectionnée
- **Nom**: Chakra UI
- **URL**: https://chakra-ui.com
- **Framework**: react
- **Style**: modern

## Contraintes de Design
- Couleurs : UNIQUEMENT design-system.json
- Saturation max : 70% HSL
- Contraste min : 4.5:1
- Animations max : 300ms
- Accessibilité : excellent

## Composants Recommandés
Consulter la documentation Chakra UI...
```

#### 3. Génération de la Maquette

L'agent IA génère la maquette HTML/CSS en suivant les instructions.

**Exemple** : `design/screens/login.html`

```html
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <title>Login</title>
  <style>
    :root {
      --color-primary-500: #2196f3;
      --color-neutral-50: #fafafa;
      --spacing-md: 24px;
      --font-size-base: 16px;
    }
    /* ... */
  </style>
</head>
<body>
  <div class="login-container">
    <h1>Connexion</h1>
    <form>
      <input type="email" aria-label="Email" />
      <input type="password" aria-label="Mot de passe" />
      <button type="submit">Se connecter</button>
    </form>
  </div>
</body>
</html>
```

#### 4. Validation des Couleurs

```bash
node scripts/validate-colors.js design/screens/login.html
```

**Sortie** :
```json
{
  "success": true,
  "summary": {
    "totalFiles": 1,
    "validFiles": 1,
    "invalidFiles": 0
  },
  "files": [
    {
      "file": "login.html",
      "totalColors": 5,
      "authorizedCount": 5,
      "unauthorizedCount": 0,
      "unauthorized": [],
      "valid": true
    }
  ],
  "message": "✅ Toutes les couleurs sont conformes au design system"
}
```

#### 5. Revue Huashu-Design (5D)

Le skill `huashu-review.md` est activé pour évaluer la maquette selon 5 dimensions.

**Rapport** : `design/review/huashu-reports/login-20260508-103000.json`

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

#### 6. Itération

Si `scores.total < 0.85` :
1. Lire le feedback
2. Corriger les problèmes
3. Relancer la validation et la revue
4. Répéter jusqu'à `scores.total ≥ 0.85`

---

## Revue Huashu-Design (5D)

### Les 5 Dimensions

#### 1. Layout (Hiérarchie Visuelle)
**Score : 0-10**

Critères :
- ✅ Hiérarchie claire (primaire, secondaire, tertiaire)
- ✅ Grille cohérente (8px, 16px, 24px)
- ✅ Espacement respirant
- ✅ Alignement précis
- ✅ Proportions harmonieuses

#### 2. Typographie (Lisibilité)
**Score : 0-10**

Critères :
- ✅ Hiérarchie typographique (h1 > h2 > h3 > body > caption)
- ✅ Lisibilité (line-height, letter-spacing)
- ✅ Contraste suffisant (4.5:1 minimum)
- ✅ Cohérence des styles
- ✅ Responsive

#### 3. Couleur (Harmonie)
**Score : 0-10**

Critères :
- ✅ Palette limitée (3-5 couleurs principales)
- ✅ Contraste suffisant (WCAG AA minimum)
- ✅ Harmonie (complémentaires ou analogues)
- ✅ Saturation contrôlée (≤70%)
- ✅ Conformité au design system

#### 4. Mouvement (Animations)
**Score : 0-10**

Critères :
- ✅ Animations subtiles (≤300ms)
- ✅ Easing naturel (cubic-bezier)
- ✅ Feedback immédiat (hover, focus, active)
- ✅ Pas d'animations infinies sans raison
- ✅ Respect de prefers-reduced-motion

#### 5. Cohérence (Design System)
**Score : 0-10**

Critères :
- ✅ Respect du design system (tokens, composants)
- ✅ Patterns cohérents (boutons, inputs, cards)
- ✅ Accessibilité (ARIA, keyboard, screen readers)
- ✅ Responsive (mobile, tablet, desktop)
- ✅ Maintenabilité (code propre, commenté)

### Calcul du Score Total

```
Score Total = (Layout + Typographie + Couleur + Mouvement + Cohérence) / 50
```

**Seuil de validation : 0.85 (42.5/50)**

---

## Contraintes de Design

### Couleurs

- ✅ **Utiliser UNIQUEMENT** les couleurs du design system
- ✅ **Saturation maximale** : 70% en HSL (sauf annotation explicite)
- ✅ **Contraste minimum** : 4.5:1 pour texte normal (WCAG AA)
- ✅ **Contraste recommandé** : 7:1 (WCAG AAA)

### Typographie

- ✅ **Hiérarchie claire** : h1 > h2 > h3 > body > caption
- ✅ **Line-height** : 1.5 pour body, 1.2 pour headings
- ✅ **Letter-spacing** : -0.02em pour headings
- ✅ **Font-size minimum** : 12px (caption)

### Espacement

- ✅ **Grille de 8px stricte**
- ✅ **Espacement cohérent** : xs, sm, md, lg, xl
- ✅ **Pas de valeurs arbitraires** (ex: 13px, 27px)

### Animations

- ✅ **Durée maximale** : 300ms
- ✅ **Easing** : cubic-bezier uniquement (pas de linear)
- ✅ **Pas d'animations infinies** sans raison
- ✅ **Support de prefers-reduced-motion**

### Accessibilité

- ✅ **ARIA labels** sur tous les éléments interactifs
- ✅ **Navigation au clavier** complète (Tab, Enter, Esc)
- ✅ **Support des lecteurs d'écran**
- ✅ **Focus visible** (outline ou ring)
- ✅ **Contraste WCAG AA minimum** (AAA recommandé)

---

## Exports

### A2UI (Déclaratif)

Format JSON déclaratif pour générer du code à partir de la maquette.

**Exemple** : `design/a2ui/login.a2ui.json`

```json
{
  "screen": "login",
  "components": [
    {
      "type": "Container",
      "props": { "maxWidth": "md", "padding": "lg" },
      "children": [
        {
          "type": "Heading",
          "props": { "level": 1, "text": "Connexion" }
        },
        {
          "type": "Form",
          "children": [
            {
              "type": "Input",
              "props": { "type": "email", "label": "Email", "required": true }
            },
            {
              "type": "Input",
              "props": { "type": "password", "label": "Mot de passe", "required": true }
            },
            {
              "type": "Button",
              "props": { "type": "submit", "variant": "primary", "text": "Se connecter" }
            }
          ]
        }
      ]
    }
  ]
}
```

### Figma

Export des tokens de design vers Figma.

**Fichier** : `design/figma-export.json`

```json
{
  "version": "1.0.0",
  "colors": {
    "primary/500": "#2196f3",
    "neutral/50": "#fafafa"
  },
  "typography": {
    "base": { "fontSize": 16, "fontFamily": "Inter" }
  },
  "spacing": {
    "md": 24
  }
}
```

---

## Ajouter une Nouvelle Bibliothèque

### 1. Éditer `skills/design/bibliotheques.json`

```json
{
  "id": "nouvelle-lib",
  "name": "Nouvelle Lib",
  "technos": ["react", "typescript"],
  "style": "modern",
  "accessibility": "excellent",
  "strengths": [
    "Point fort 1",
    "Point fort 2"
  ],
  "weaknesses": [
    "Point faible 1"
  ],
  "url": "https://nouvelle-lib.com",
  "score": {
    "accessibility": 9,
    "customization": 8,
    "performance": 9,
    "documentation": 8
  }
}
```

### 2. Mettre à jour les index

```json
{
  "styleCategories": {
    "modern": ["chakra-ui", "nouvelle-lib"]
  },
  "technoIndex": {
    "react": ["chakra-ui", "nouvelle-lib"]
  }
}
```

---

## Commandes Utiles

### Sélection de Bibliothèque

```bash
# Sélection basique
node scripts/select-library.js --framework react --style modern

# Avec accessibilité
node scripts/select-library.js --framework react --style modern --accessibility excellent

# Avec priorité performance
node scripts/select-library.js --framework react --style modern --performance
```

### Validation des Couleurs

```bash
# Un fichier
node scripts/validate-colors.js design/screens/login.html

# Plusieurs fichiers
node scripts/validate-colors.js design/screens/*.html
```

### Pipeline Complet

```bash
# Pipeline complet
./scripts/design-pipeline.sh --framework react --style modern --screen login

# Avec accessibilité spécifique
./scripts/design-pipeline.sh --framework react --style modern --screen dashboard --accessibility good
```

---

## Intégration avec les Autres Couches

### Couche 0 (Harness)
- Scripts exécutables (`chmod +x`)
- Hooks Git (validation avant commit)
- CI/CD (validation dans le pipeline)

### Couche 1 (Mémoire)
- Indexation des maquettes dans le graphe
- Recherche de patterns de design
- Historique des revues

### Couche 2 (Spécifications)
- Design system comme spécification
- Skills de design chargés dynamiquement
- Validation des contraintes

### Couche 3 (Minimiseur)
- Extraction du contexte de design
- Prompts optimisés pour génération de maquettes

---

## Métriques de Qualité

### Seuils

- **Score Huashu-Design** : ≥ 0.85
- **Contraste WCAG** : ≥ 4.5:1 (AA) ou ≥ 7:1 (AAA)
- **Saturation** : ≤ 70% HSL
- **Durée animations** : ≤ 300ms
- **Accessibilité** : Excellent ou Good

### Validation

- ✅ Toutes les couleurs dans le design system
- ✅ Tous les tokens de typographie respectés
- ✅ Grille de 8px stricte
- ✅ ARIA labels présents
- ✅ Navigation au clavier fonctionnelle

---

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
**Auteur** : Axiom-Scaffold Team
