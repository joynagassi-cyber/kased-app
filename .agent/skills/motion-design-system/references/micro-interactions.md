# 🎯 Catalogue des Micro-Interactions Universelles

> **Règle** : Chaque fiche utilise exclusivement des tokens définis dans `tokens.md`. Aucune valeur en dur.

---

## Comment lire une fiche

| Champ | Signification |
|-------|--------------|
| **Déclencheur** | Événement utilisateur qui lance l'animation |
| **Règle** | Comportement précis à appliquer |
| **Feedback visuel** | Ce que l'utilisateur perçoit |
| **Tokens** | Valeurs à utiliser (issus de `tokens.md`) |
| **Variante réduite** | Comportement si `prefers-reduced-motion: reduce` |

---

## 01 · `hover-elevate` — Survol d'un élément interactif

| Champ | Valeur |
|-------|--------|
| **Déclencheur** | `mouseenter` / `:hover` |
| **Règle** | Translation Y négative + ombre portée renforcée |
| **Feedback visuel** | L'élément "flotte" légèrement au-dessus |
| **Tokens** | `duration-short` · `easing-standard` · `scale-hover` |
| **Variante réduite** | Changement de couleur uniquement (pas de déplacement) |

```css
.card {
  transition: transform var(--motion-duration-short) var(--motion-easing-standard),
              box-shadow var(--motion-duration-short) var(--motion-easing-standard);
}
.card:hover {
  transform: translateY(calc(-1 * var(--motion-path-shift-xs)));
  box-shadow: 0 8px 24px rgba(0,0,0,0.12);
}
```

---

## 02 · `press-shrink` — Pression / Tap

| Champ | Valeur |
|-------|--------|
| **Déclencheur** | `mousedown` / `:active` / tap mobile |
| **Règle** | Réduction d'échelle immédiate à 97%, retour à 100% au relâchement |
| **Feedback visuel** | L'élément "s'enfonce" physiquement |
| **Tokens** | `duration-instant` · `easing-accelerate` · `scale-press` |
| **Variante réduite** | Changement d'opacité (0.7) sans scale |

```css
.button:active {
  transform: scale(var(--motion-scale-press));
  transition: transform var(--motion-duration-instant) var(--motion-easing-accelerate);
}
```

**Flutter** :
```dart
GestureDetector(
  onTapDown: (_) => setState(() => _pressed = true),
  onTapUp: (_) => setState(() => _pressed = false),
  child: AnimatedScale(
    scale: _pressed ? MotionScale.press : 1.0,
    duration: MotionDuration.instant,
    curve: MotionCurve.accelerate,
    child: widget,
  ),
)
```

---

## 03 · `appear-fade-slide` — Apparition d'un élément

| Champ | Valeur |
|-------|--------|
| **Déclencheur** | Montage du composant / apparition dans le viewport |
| **Règle** | Opacité 0→1 + décalage Y 8px→0px simultanément |
| **Feedback visuel** | L'élément glisse doucement vers sa position finale |
| **Tokens** | `duration-standard` · `easing-decelerate` · `path-shift-sm` |
| **Variante réduite** | Opacité 0→1 uniquement (pas de déplacement) |

```css
@keyframes appear-fade-slide {
  from {
    opacity: 0;
    transform: translateY(var(--motion-path-shift-sm));
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
.appear {
  animation: appear-fade-slide var(--motion-duration-standard) var(--motion-easing-decelerate) forwards;
}
```

---

## 04 · `dismiss-fade-slide` — Disparition d'un élément

| Champ | Valeur |
|-------|--------|
| **Déclencheur** | Démontage / fermeture |
| **Règle** | Sortie = entrée × 0.7 durée + `easing-accelerate` |
| **Feedback visuel** | L'élément s'éloigne légèrement et disparaît |
| **Tokens** | `duration-short` (= standard × 0.7) · `easing-accelerate` |
| **Variante réduite** | Opacité 1→0 uniquement |

> ⚠️ **Règle absolue** : La sortie est TOUJOURS plus rapide que l'entrée.

---

## 05 · `loading-skeleton` — Chargement de contenu

| Champ | Valeur |
|-------|--------|
| **Déclencheur** | État de chargement (data fetching) |
| **Règle** | Gradient animé sur formes grises en boucle infinie |
| **Feedback visuel** | Shimmer de gauche à droite sur des placeholders |
| **Tokens** | `duration-long` · boucle infinie |
| **Variante réduite** | Fond gris statique sans animation |

```css
@keyframes shimmer {
  0% { background-position: -200% center; }
  100% { background-position: 200% center; }
}
.skeleton {
  background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
  background-size: 200% 100%;
  animation: shimmer var(--motion-duration-long) linear infinite;
}
```

---

## 06 · `success-pulse` — Confirmation d'action

| Champ | Valeur |
|-------|--------|
| **Déclencheur** | Action réussie (formulaire soumis, paiement OK) |
| **Règle** | Scale 1 → 1.05 → 1 en une seule oscillation |
| **Feedback visuel** | L'élément "respire" une fois pour confirmer |
| **Tokens** | `duration-standard` · `easing-emphasized` · `scale-success` |
| **Variante réduite** | Changement de couleur (vert) sans scale |

```css
@keyframes success-pulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(var(--motion-scale-success)); }
}
.success {
  animation: success-pulse var(--motion-duration-standard) var(--motion-easing-emphasized) 1;
}
```

---

## 07 · `error-shake` — Erreur de validation

| Champ | Valeur |
|-------|--------|
| **Déclencheur** | Validation échouée, input invalide |
| **Règle** | Translation X ±4px, 3 oscillations, damping naturel |
| **Feedback visuel** | Tremblement horizontal d'un champ ou bouton |
| **Tokens** | `duration-instant` par oscillation · courbe linéaire |
| **Variante réduite** | Bordure rouge + texte d'erreur, sans shake |

```css
@keyframes error-shake {
  0%, 100% { transform: translateX(0); }
  20% { transform: translateX(calc(-1 * var(--motion-path-shift-xs))); }
  40% { transform: translateX(var(--motion-path-shift-xs)); }
  60% { transform: translateX(calc(-1 * var(--motion-path-shift-xs) * 0.6)); }
  80% { transform: translateX(calc(var(--motion-path-shift-xs) * 0.3)); }
}
.error {
  animation: error-shake 400ms linear 1;
}
```

---

## 08 · `focus-ring` — Focus clavier

| Champ | Valeur |
|-------|--------|
| **Déclencheur** | `:focus-visible` (navigation clavier) |
| **Règle** | Anneau visible progressif (expand depuis l'intérieur) |
| **Feedback visuel** | Contour coloré s'agrandit autour de l'élément |
| **Tokens** | `duration-short` · `easing-standard` |
| **Variante réduite** | Anneau statique (pas d'animation mais toujours visible) |

```css
.focusable:focus-visible {
  outline: 2px solid currentColor;
  outline-offset: 2px;
  transition: outline-offset var(--motion-duration-short) var(--motion-easing-standard);
}
```

---

## 09 · `expand-collapse` — Accordéon / Collapse

| Champ | Valeur |
|-------|--------|
| **Déclencheur** | Clic sur un header d'accordéon |
| **Règle** | Hauteur 0 → auto avec clip, rotation icône 0→180° |
| **Feedback visuel** | Contenu glisse vers le bas, icône pivote |
| **Tokens** | `duration-standard` · `easing-decelerate` (ouverture) · `easing-accelerate` (fermeture) |
| **Variante réduite** | Toggle instantané sans animation de hauteur |

**Flutter** :
```dart
AnimatedCrossFade(
  firstChild: const SizedBox.shrink(),
  secondChild: content,
  crossFadeState: _isOpen
      ? CrossFadeState.showSecond
      : CrossFadeState.showFirst,
  duration: MotionDuration.standard,
  firstCurve: MotionCurve.accelerate,
  secondCurve: MotionCurve.decelerate,
)
```

---

## 10 · `page-transition` — Transition de page/écran

| Champ | Valeur |
|-------|--------|
| **Déclencheur** | Navigation entre deux routes |
| **Règle** | Nouvelle page glisse depuis la droite (forward) ou gauche (back) |
| **Feedback visuel** | Glissement horizontal avec légère opacité en entrée |
| **Tokens** | `duration-long` · `easing-emphasized` · `path-shift-md` |
| **Variante réduite** | Cross-fade simple sans glissement |

**Flutter** :
```dart
PageRouteBuilder(
  transitionDuration: MotionDuration.long,
  pageBuilder: (_, __, ___) => const NewPage(),
  transitionsBuilder: (_, animation, __, child) {
    return SlideTransition(
      position: Tween(
        begin: const Offset(1.0, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: MotionCurve.emphasized,
      )),
      child: child,
    );
  },
)
```

---

## 11 · `toast-notification` — Notification éphémère

| Champ | Valeur |
|-------|--------|
| **Déclencheur** | Événement système (sauvegarde, erreur réseau) |
| **Règle** | Entre par le bas (Y 48px→0), attend 3s, sort par le haut |
| **Feedback visuel** | Apparition douce, disparition automatique |
| **Tokens** | `duration-standard` (entrée) · `duration-short` (sortie) · `easing-decelerate`/`accelerate` |
| **Variante réduite** | Apparition et disparition instantanées |

---

## 12 · `drag-feedback` — Glissement / Drag

| Champ | Valeur |
|-------|--------|
| **Déclencheur** | `dragstart` / drag en cours |
| **Règle** | Scale 1.05 + ombre portée pendant le drag, retour à 1 au drop |
| **Feedback visuel** | L'élément "se soulève" et suit le doigt |
| **Tokens** | `duration-instant` (soulèvement) · `easing-bounce` (retour) · `scale-success` |
| **Variante réduite** | Changer la couleur de fond sans élévation |

---

## Matrice de sélection rapide

| Situation | Pattern recommandé |
|-----------|-------------------|
| Élément apparaît dans la page | `appear-fade-slide` |
| Élément disparaît | `dismiss-fade-slide` |
| Bouton cliqué | `press-shrink` |
| Données en cours de chargement | `loading-skeleton` |
| Action réussie | `success-pulse` |
| Erreur de formulaire | `error-shake` |
| Navigation vers une autre page | `page-transition` |
| Survol d'une carte | `hover-elevate` |
| Focus clavier | `focus-ring` |
| Section accordéon | `expand-collapse` |
| Message système | `toast-notification` |
| Réorganisation par glissement | `drag-feedback` |
