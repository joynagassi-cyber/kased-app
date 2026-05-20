# 🎼 Règles de Chorégraphie — Orchestration Multi-Animations

> **Objectif** : Quand plusieurs éléments s'animent simultanément, l'ordre et le timing créent une narration visuelle. Sans règles, c'est le chaos. Avec les bonnes règles, l'interface semble vivante et intelligente.

---

## Principe fondamental : Attention unitaire

> L'œil ne peut suivre qu'**un seul point focal à la fois**. La chorégraphie consiste à **piloter cet œil** d'un point à l'autre, dans un ordre logique.

---

## Règle 1 : Staggering (décalage progressif)

Pour des listes, grilles, ou groupes d'éléments similaires :

| Contexte | Délai par item | Token |
|----------|---------------|-------|
| Liste longue (> 8 items) | 20ms | `stagger-tight` |
| Liste normale (3–8 items) | 40ms | `stagger-standard` |
| Peu d'éléments (≤ 3) | 60ms | `stagger-loose` |

**Règle** : Le staggering s'applique **de haut en bas** (ou de gauche à droite en grille). Jamais dans un ordre aléatoire.

**Plafond** : Sur une liste de 10 items avec `stagger-standard` (40ms), le dernier item attend 400ms — c'est le maximum acceptable. Au-delà, réduire à `stagger-tight`.

```css
/* Staggering CSS avec custom properties */
.list-item:nth-child(1) { animation-delay: 0ms; }
.list-item:nth-child(2) { animation-delay: var(--motion-stagger-standard); }
.list-item:nth-child(3) { animation-delay: calc(var(--motion-stagger-standard) * 2); }
/* ... */
```

**Flutter** :
```dart
ListView.builder(
  itemBuilder: (context, index) => AnimationConfiguration.staggeredList(
    position: index,
    delay: MotionStagger.standard,
    child: SlideAnimation(
      verticalOffset: 24,
      child: FadeInAnimation(child: item),
    ),
  ),
)
```

---

## Règle 2 : Grouping (groupement cohérent)

Les éléments **fonctionnellement liés** apparaissent **simultanément**, pas en séquence :

✅ **Correct** : Un bouton et son label s'animent ensemble
✅ **Correct** : Un card header et son image apparaissent en même temps
❌ **Interdit** : Le bouton apparaît, puis 200ms après son label arrive

**Identification des groupes** : Un groupe = des éléments qu'on ne peut pas utiliser séparément.

---

## Règle 3 : Hiérarchie parent–enfant

Quand un conteneur contient des éléments enfants :

1. **Parent** s'anime en premier (ex : la card apparaît)
2. **Enfants** suivent après `--motion-delay-child` (15ms)

```
t=0ms    : Card (parent) commence à apparaître
t=15ms   : Titre (enfant) commence à apparaître
t=15ms   : Image (enfant) commence à apparaître
t=55ms   : Bouton (enfant) commence à apparaître (= 15ms + 1 stagger)
```

Ce micro-décalage crée une sensation de **profondeur structurelle** sans être perceptible consciemment.

---

## Règle 4 : Priorité d'attention (hero first)

Sur un écran avec plusieurs animations simultanées, définir une **hiérarchie d'attention** :

| Niveau | Timing | Exemple |
|--------|--------|---------|
| **Hero** (0) | t=0ms | Titre principal, CTA primaire |
| **Principal** (1) | t=+stagger×1 | Contenu principal, image |
| **Secondaire** (2) | t=+stagger×2 | Métadonnées, labels |
| **Décoratif** (3) | t=+stagger×3 | Icônes, badges, avatars secondaires |

**Règle** : Ne jamais animer le décoratif avant le hero.

---

## Règle 5 : Sorties plus rapides que les entrées

| Phase | Durée | Easing |
|-------|-------|--------|
| Entrée | `duration-standard` (250ms) | `easing-decelerate` |
| Sortie | `duration-short` (150ms) | `easing-accelerate` |

**Logique** : L'utilisateur a **demandé** que l'élément parte. Il ne doit pas attendre. La sortie rapide = respect du temps utilisateur.

**Exception** : Les modals et drawers importants peuvent sortir à la même vitesse qu'ils sont entrés (pour éviter un sentiment d'arrachement brutal).

---

## Règle 6 : Pas d'animation simultanée sur + de 5 éléments distincts

Si plus de 5 zones de la page s'animent en même temps, l'utilisateur est **débordé** et ne suit plus rien.

**Solution** : Regrouper les animations en séquences, ou réduire le scope de la transition.

---

## Patterns de chorégraphie courants

### Pattern A : Entrée de page

```
t=0ms    : Navbar (hero)
t=40ms   : Hero section (image + titre simultanément)
t=80ms   : Contenu principal
t=120ms  : Sidebar / éléments secondaires
t=160ms  : Footer / éléments décoratifs
```

### Pattern B : Modal / Drawer

```
t=0ms    : Overlay (fond sombre, opacity 0→0.5)
t=50ms   : Conteneur du modal (scale 0.95→1 + opacity)
t=80ms   : Titre du modal
t=110ms  : Contenu
t=140ms  : Boutons d'action (CTA primaire et secondaire simultanément)
```

### Pattern C : Liste avec actions

```
t=0ms    : Cadre de la liste
t=0ms    : Item 1 (en même temps que le cadre)
t=40ms   : Item 2
t=80ms   : Item 3
...
(stagger-standard entre chaque item)
```

### Pattern D : Formulaire avec erreurs

```
t=0ms    : error-shake sur le champ invalide
t=0ms    : Message d'erreur (appear-fade-slide)
t=100ms  : Focus automatique sur le champ (pas d'animation, juste :focus-visible)
```

---

## Interruptions et annulations

Quand l'utilisateur interrompt une animation en cours :

1. **Stopper immédiatement** — Ne jamais forcer la fin d'une animation
2. **Repartir depuis l'état actuel** — Pas de retour à l'état initial
3. **Respecter la durée originale** — Ne pas accélérer pour "rattraper"

```dart
// Flutter : AnimationController gère naturellement l'interruption
controller.animateTo(
  targetValue,
  duration: MotionDuration.standard,
  curve: MotionCurve.standard,
); // Si appelé pendant une animation en cours → part depuis la position actuelle
```

---

## Anti-patterns de chorégraphie

| Anti-pattern | Problème | Solution |
|-------------|---------|---------|
| Tout en même temps | Chaos visuel, zéro hiérarchie | Appliquer staggering + grouping |
| Séquence trop longue | Attente frustrante | Réduire stagger ou paralléliser |
| Sortie plus lente que l'entrée | L'UI paraît lente | Appliquer la règle ×0.7 |
| Staggering aléatoire | Désorientation, pas de logique | Toujours top-down ou left-right |
| Plus de 5 zones simultanées | Surcharge cognitive | Découper en phases |
