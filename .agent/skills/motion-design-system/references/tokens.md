# 🎨 Lexique des Tokens de Mouvement

> **Règle** : Aucune valeur de durée, courbe ou décalage ne doit apparaître en dur dans le code. Tout référence un token de ce lexique.

---

## Tokens de durée

| Token | Valeur | Usage |
|-------|--------|-------|
| `--motion-duration-instant` | `100ms` | Feedback immédiat (press, tap) |
| `--motion-duration-short` | `150ms` | Micro-interactions légères (hover, focus) |
| `--motion-duration-standard` | `250ms` | Transitions d'état, apparitions simples |
| `--motion-duration-long` | `400ms` | Transitions de page, modals, drawers |
| `--motion-duration-deliberate` | `500ms` | Onboarding, célébrations, états vides |

**Règle mobile** : Sur Flutter/mobile, réduire de 20% (device moins puissant).
Exemple : `standard` = 200ms sur mobile.

---

## Tokens d'easing

| Token | Valeur CSS | Usage | Logique |
|-------|-----------|-------|---------|
| `--motion-easing-standard` | `cubic-bezier(0.2, 0.0, 0, 1.0)` | Mouvement par défaut | Décélération naturelle |
| `--motion-easing-decelerate` | `cubic-bezier(0.0, 0.0, 0.2, 1.0)` | **Entrée** d'éléments | Freine à l'arrivée |
| `--motion-easing-accelerate` | `cubic-bezier(0.4, 0.0, 1.0, 1.0)` | **Sortie** d'éléments | Accélère en partant |
| `--motion-easing-emphasized` | `cubic-bezier(0.4, 0.0, 0.2, 1.0)` | Transitions importantes | In-out équilibré |
| `--motion-easing-bounce` | `cubic-bezier(0.34, 1.56, 0.64, 1.0)` | Célébrations, jeux | Légère élasticité |
| `--motion-easing-spring` | `spring(1, 100, 10, 0)` | Glissements, drag | Physique réelle |

**Règle mnémotechnique** :
- Élément **entre** → `easing-decelerate` (freine en arrivant)
- Élément **sort** → `easing-accelerate` (accélère en partant)
- Transition **d'état** → `easing-standard`

---

## Tokens de transformation

| Token | Valeur | Usage |
|-------|--------|-------|
| `--motion-path-shift-xs` | `4px` | Feedback hover léger |
| `--motion-path-shift-sm` | `8px` | Apparition d'éléments UI |
| `--motion-path-shift-md` | `24px` | Entrée de composants |
| `--motion-path-shift-lg` | `48px` | Transitions de pages/sections |
| `--motion-scale-press` | `0.97` | Feedback de pression |
| `--motion-scale-hover` | `1.02` | Élévation au survol |
| `--motion-scale-success` | `1.05` | Confirmation/succès |
| `--motion-opacity-fade` | `0` | Disparition complète |
| `--motion-opacity-ghost` | `0.5` | État désactivé/chargement |

---

## Tokens de staggering (chorégraphie)

| Token | Valeur | Usage |
|-------|--------|-------|
| `--motion-stagger-tight` | `20ms` | Listes longues (> 8 items) |
| `--motion-stagger-standard` | `40ms` | Listes normales (3–8 items) |
| `--motion-stagger-loose` | `60ms` | Peu d'éléments (≤ 3) |
| `--motion-delay-child` | `15ms` | Délai parent → enfant |

---

## Export CSS complet

```css
:root {
  /* Durées */
  --motion-duration-instant: 100ms;
  --motion-duration-short: 150ms;
  --motion-duration-standard: 250ms;
  --motion-duration-long: 400ms;
  --motion-duration-deliberate: 500ms;

  /* Easings */
  --motion-easing-standard: cubic-bezier(0.2, 0.0, 0, 1.0);
  --motion-easing-decelerate: cubic-bezier(0.0, 0.0, 0.2, 1.0);
  --motion-easing-accelerate: cubic-bezier(0.4, 0.0, 1.0, 1.0);
  --motion-easing-emphasized: cubic-bezier(0.4, 0.0, 0.2, 1.0);
  --motion-easing-bounce: cubic-bezier(0.34, 1.56, 0.64, 1.0);

  /* Décalages */
  --motion-path-shift-xs: 4px;
  --motion-path-shift-sm: 8px;
  --motion-path-shift-md: 24px;
  --motion-path-shift-lg: 48px;

  /* Échelles */
  --motion-scale-press: 0.97;
  --motion-scale-hover: 1.02;
  --motion-scale-success: 1.05;

  /* Opacités */
  --motion-opacity-fade: 0;
  --motion-opacity-ghost: 0.5;

  /* Staggering */
  --motion-stagger-tight: 20ms;
  --motion-stagger-standard: 40ms;
  --motion-stagger-loose: 60ms;
  --motion-delay-child: 15ms;
}
```

---

## Export JSON (design tokens spec)

```json
{
  "motion": {
    "duration": {
      "instant": { "value": "100ms", "type": "duration" },
      "short": { "value": "150ms", "type": "duration" },
      "standard": { "value": "250ms", "type": "duration" },
      "long": { "value": "400ms", "type": "duration" },
      "deliberate": { "value": "500ms", "type": "duration" }
    },
    "easing": {
      "standard": { "value": "cubic-bezier(0.2, 0.0, 0, 1.0)", "type": "cubicBezier" },
      "decelerate": { "value": "cubic-bezier(0.0, 0.0, 0.2, 1.0)", "type": "cubicBezier" },
      "accelerate": { "value": "cubic-bezier(0.4, 0.0, 1.0, 1.0)", "type": "cubicBezier" },
      "emphasized": { "value": "cubic-bezier(0.4, 0.0, 0.2, 1.0)", "type": "cubicBezier" },
      "bounce": { "value": "cubic-bezier(0.34, 1.56, 0.64, 1.0)", "type": "cubicBezier" }
    },
    "scale": {
      "press": { "value": 0.97, "type": "number" },
      "hover": { "value": 1.02, "type": "number" },
      "success": { "value": 1.05, "type": "number" }
    }
  }
}
```

---

## Équivalents Flutter (Dart)

```dart
// lib/design_system/motion_tokens.dart

abstract class MotionDuration {
  static const instant   = Duration(milliseconds: 100);
  static const short     = Duration(milliseconds: 150);
  static const standard  = Duration(milliseconds: 250);
  static const long      = Duration(milliseconds: 400);
  static const deliberate = Duration(milliseconds: 500);
}

abstract class MotionCurve {
  static const standard    = Curves.easeOut;
  static const decelerate  = Curves.easeOutCubic;
  static const accelerate  = Curves.easeInCubic;
  static const emphasized  = Curves.easeInOut;
  // Bounce custom
  static final bounce = CubicBezier(0.34, 1.56, 0.64, 1.0);
}

abstract class MotionScale {
  static const press   = 0.97;
  static const hover   = 1.02;
  static const success = 1.05;
}

abstract class MotionOffset {
  static const shiftSm = Offset(0, 8);
  static const shiftMd = Offset(0, 24);
  static const shiftLg = Offset(0, 48);
}

abstract class MotionStagger {
  static const tight    = Duration(milliseconds: 20);
  static const standard = Duration(milliseconds: 40);
  static const loose    = Duration(milliseconds: 60);
}
```

---

## Règles d'ajout d'un nouveau token

Pour ajouter un token non prévu :

1. **Justifier** : Quel cas d'usage précis ne peut pas être couvert par un token existant ?
2. **Nommer** : Respecter la convention `--motion-[catégorie]-[nom]`
3. **Documenter** : Ajouter la ligne dans ce fichier avec usage
4. **Valider** : Vérifier la cohérence avec les valeurs existantes (pas d'écart incohérent)
5. **Exporter** : Mettre à jour CSS, JSON et Dart en même temps
