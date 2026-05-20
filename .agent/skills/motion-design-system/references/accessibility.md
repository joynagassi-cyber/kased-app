# ♿ Accessibilité & Préférences Utilisateur

> **Principe** : Une animation qui n'est pas accessible n'est pas terminée. L'accessibilité est une contrainte de départ, pas un ajout en fin de projet.

---

## Règle 1 : `prefers-reduced-motion` — Obligatoire sur toute animation

Tout composant animé **doit** inclure une variante pour les utilisateurs ayant configuré une préférence de mouvement réduit.

### Implementation CSS (obligatoire)

```css
/* ✅ CORRECT : Inclure dans chaque composant animé */
.animated-element {
  transition: transform var(--motion-duration-standard) var(--motion-easing-standard),
              opacity var(--motion-duration-standard) var(--motion-easing-standard);
}

@media (prefers-reduced-motion: reduce) {
  .animated-element {
    transition: opacity var(--motion-duration-short) linear;
    /* Mouvement supprimé, fade maintenu */
  }
}

/* Règle globale en dernier recours (si composants non conformes) */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

### Implementation Flutter

```dart
// Vérifier la préférence système
import 'package:flutter/scheduler.dart';

bool get reduceMotion =>
    SchedulerBinding.instance.timeDilation != 1.0 ||
    MediaQuery.of(context).disableAnimations;

// Usage dans un widget
AnimatedOpacity(
  duration: reduceMotion
      ? Duration.zero
      : MotionDuration.standard,
  opacity: _visible ? 1.0 : 0.0,
  child: child,
)
```

```dart
// Wrapper réutilisable
class MotionAware extends StatelessWidget {
  final Widget Function(bool reduceMotion) builder;

  const MotionAware({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return builder(reduceMotion);
  }
}
```

---

## Règle 2 : Pas de clignotement > 3 flashs/seconde

**Standard WCAG 2.1 — Critère 2.3.1 (Niveau A)**

Tout contenu qui clignote plus de 3 fois par seconde peut déclencher des crises d'épilepsie.

| Situation | Limite |
|-----------|--------|
| Clignotement | ≤ 3 flashs/seconde |
| Flash "rouge général" | Strictement interdit |
| Animation `loading-skeleton` | ✅ OK (gradient lent ≠ flash) |
| `success-pulse` (1 oscillation) | ✅ OK |
| Animations en boucle rapide | ❌ Interdit |

**Test** : Si une animation se répète en boucle, sa fréquence doit être ≤ 3Hz (période ≥ 333ms).

```css
/* ❌ INTERDIT : Clignotement rapide */
@keyframes blink-fast {
  0%, 100% { opacity: 1; }
  50% { opacity: 0; }
}
.blink { animation: blink-fast 200ms infinite; } /* 5Hz → INTERDIT */

/* ✅ CORRECT : Respiration lente */
@keyframes breathe {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.6; }
}
.breathe { animation: breathe 2000ms ease-in-out infinite; } /* 0.5Hz → OK */
```

---

## Règle 3 : Le feedback ne doit pas être uniquement animé

L'animation est un **renforcement**, pas le seul indicateur d'état.

| Situation | ❌ Mauvais | ✅ Correct |
|-----------|-----------|-----------|
| Erreur formulaire | Seulement `error-shake` | Shake + bordure rouge + message textuel |
| Action réussie | Seulement `success-pulse` | Pulse + texte "Sauvegardé" + icône checkmark |
| Chargement | Seulement spinner animé | Spinner + texte "Chargement..." |

**Principe** : Si on coupe toutes les animations, l'interface doit rester **entièrement compréhensible**.

---

## Règle 4 : Focus clavier — Jamais supprimé

Les animations de `:focus` et `:focus-visible` ne doivent **jamais** être supprimées, même avec `prefers-reduced-motion`.

```css
/* ✅ CORRECT : Focus réduit mais toujours visible */
@media (prefers-reduced-motion: reduce) {
  .focusable:focus-visible {
    /* transition supprimée mais l'anneau reste visible */
    outline: 3px solid currentColor;
    outline-offset: 2px;
    transition: none;
  }
}

/* ❌ INTERDIT */
@media (prefers-reduced-motion: reduce) {
  * { outline: none; } /* JAMAIS */
}
```

---

## Règle 5 : Durée maximale des animations automatiques

Une animation qui se déclenche **sans interaction utilisateur** doit être limitée :

| Type | Durée max | Après |
|------|-----------|-------|
| Animation d'entrée (page load) | 600ms totaux | Stop |
| Animation en boucle | Infinie ✅ | Si lente (< 3Hz) |
| Carrousel auto | Doit avoir pause on hover | + bouton pause |
| Vidéo/GIF autoplay | ≤ 5 secondes | Puis pause ou loop lent |

---

## Règle 6 : Contraste suffisant pendant les animations

Pendant une transition (opacity intermédiaire), le ratio de contraste ne doit pas tomber sous 3:1.

**Exemple** : Un texte blanc sur fond bleu en `opacity: 0.5` peut devenir illisible. Tester les états intermédiaires.

---

## Checklist d'accessibilité (avant livraison)

- [ ] Chaque animation a une variante `prefers-reduced-motion`
- [ ] Aucune animation ne clignote > 3Hz
- [ ] Le feedback n'est pas uniquement visuel/animé (texte alternatif présent)
- [ ] Les états `:focus-visible` sont toujours visibles même avec motion réduit
- [ ] Les animations auto-déclenchées peuvent être mises en pause
- [ ] Le contraste reste lisible pendant les transitions intermédiaires
- [ ] Les animations Flutter respectent `MediaQuery.of(context).disableAnimations`

---

## Ressources normatives

| Standard | Critère | Niveau |
|----------|---------|--------|
| WCAG 2.1 | 2.3.1 — Pas plus de 3 flashs | A (obligatoire) |
| WCAG 2.1 | 2.2.2 — Pause, Stop, Masquer | A (obligatoire) |
| WCAG 2.1 | 1.4.3 — Contraste minimal | AA |
| iOS HIG | Respect de `reduceMotion` | Best practice |
| Material 3 | Motion accessibility | Best practice |
