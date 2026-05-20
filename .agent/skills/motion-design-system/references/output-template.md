# 📄 Template du Livrable — Motion Design System

> **Usage** : Ce fichier est le template que l'agent remplit pour chaque livraison d'un design system motion. Copier ce template, remplacer tous les `[PLACEHOLDER]` avec les valeurs du projet.

---

# Motion Design System — [NOM DU PRODUIT]

> **Version** : 1.0  
> **Date** : [DATE]  
> **Plateforme** : [Web / Flutter / React Native / All]  
> **Auteur** : Agent Motion Design System

---

## 🎯 Pilier 1 — Principes directeurs

*Principes adaptés à l'identité de [NOM DU PRODUIT] et à son audience [AUDIENCE].*

| Principe | Définition pour ce produit |
|----------|-----------------------------|
| **Utilité** | [Adapter : ex. "Chaque animation confirme une action de gestion de cotisations"] |
| **Fluidité** | [Adapter : ex. "Les transitions restent sous 400ms pour rester réactives sur mobile bas de gamme"] |
| **Naturel** | [Adapter : ex. "Courbes ease-out pour toutes les entrées, ease-in pour les sorties"] |
| **Cohérence** | [Adapter : ex. "Toutes les actions de formulaire utilisent les mêmes durées et easings"] |
| **Accessible** | [Adapter : ex. "Variante prefers-reduced-motion sur 100% des composants animés"] |
| **[Principe spécifique]** | [Ajouter si le contexte le justifie : ex. "Sobre" pour un outil B2B] |

---

## 🎨 Pilier 2 — Tokens de mouvement

### Durées

| Token | Valeur | Usage dans ce produit |
|-------|--------|-----------------------|
| `motion-duration-instant` | `[100ms]` | [ex. "Feedback tap sur boutons"] |
| `motion-duration-short` | `[150ms]` | [ex. "Hover, focus, micro-transitions"] |
| `motion-duration-standard` | `[250ms]` | [ex. "Apparition de cards, modals"] |
| `motion-duration-long` | `[400ms]` | [ex. "Navigation entre onglets"] |
| `motion-duration-deliberate` | `[500ms]` | [ex. "Écrans d'onboarding"] |

### Easings

| Token | Valeur | Usage |
|-------|--------|-------|
| `motion-easing-standard` | `cubic-bezier(0.2, 0.0, 0, 1.0)` | Mouvement par défaut |
| `motion-easing-decelerate` | `cubic-bezier(0.0, 0.0, 0.2, 1.0)` | Entrées d'éléments |
| `motion-easing-accelerate` | `cubic-bezier(0.4, 0.0, 1.0, 1.0)` | Sorties d'éléments |
| `motion-easing-emphasized` | `cubic-bezier(0.4, 0.0, 0.2, 1.0)` | Transitions de page |

### Décalages & Échelles

| Token | Valeur | Usage |
|-------|--------|-------|
| `motion-path-shift-sm` | `8px / 8.0 (Flutter)` | Apparitions légères |
| `motion-path-shift-md` | `24px / 24.0 (Flutter)` | Transitions écrans |
| `motion-scale-press` | `0.97` | Feedback tap |
| `motion-scale-success` | `1.05` | Confirmation action |
| `motion-stagger-standard` | `40ms` | Listes, grilles |

### Fichiers d'export

```dart
// [CHEMIN] lib/design_system/motion/motion_tokens.dart
// [Coller ici l'export Dart complet depuis tokens.md]
```

```css
/* [CHEMIN] src/styles/motion-tokens.css */
/* [Coller ici l'export CSS complet depuis tokens.md] */
```

---

## ⚡ Pilier 3 — Catalogue des micro-interactions

*Micro-interactions sélectionnées pour [NOM DU PRODUIT]. Chaque fiche est implémentée via les tokens ci-dessus.*

### [MICRO-INTERACTION 1] — ex. `appear-fade-slide`

| Champ | Valeur |
|-------|--------|
| **Déclencheur** | [ex. "Apparition d'une card de cotisation dans la liste"] |
| **Règle** | Opacity 0→1 + translateY 8px→0 |
| **Tokens** | `motion-duration-standard` · `motion-easing-decelerate` |
| **Variante réduite** | Opacity 0→1, pas de translation |
| **Implémenté dans** | [ex. `CotisationCard`, `MemberListItem`] |

### [MICRO-INTERACTION 2] — ex. `press-shrink`

| Champ | Valeur |
|-------|--------|
| **Déclencheur** | [ex. "Tap sur bouton de paiement ou bouton primaire"] |
| **Règle** | Scale 1.0 → 0.97 au tap, retour à 1.0 |
| **Tokens** | `motion-duration-instant` · `motion-easing-accelerate` · `motion-scale-press` |
| **Variante réduite** | Opacity 0.7 pendant le tap, sans scale |
| **Implémenté dans** | [ex. `PrimaryButton`, `ActionButton`] |

### [MICRO-INTERACTION 3]

*[Dupliquer ce bloc pour chaque pattern retenu. Minimum 3, maximum 8 pour un premier livrable.]*

---

## 🎼 Pilier 4 — Règles de chorégraphie

*Règles d'orchestration spécifiques aux écrans de [NOM DU PRODUIT].*

### Staggering des listes

```
Délai entre items : [40ms] (stagger-standard)
Direction : Top → Bottom
Plafond : [10] items max en animation simultanée
```

### Séquence d'entrée de page — Écran [NOM ÉCRAN]

```
t=0ms    : [élément hero, ex. titre de la page]
t=40ms   : [contenu principal, ex. liste de cotisations]
t=80ms   : [éléments secondaires, ex. statistiques]
t=120ms  : [éléments décoratifs, ex. badges, icônes]
```

### Règles de sortie

```
Durée sortie = durée entrée × 0.7
Easing sortie = motion-easing-accelerate (toujours)
```

---

## ♿ Pilier 5 — Accessibilité

### Implémentation globale

```dart
// Flutter — dans chaque widget animé
final reduceMotion = MediaQuery.of(context).disableAnimations;
```

```css
/* Web — règle globale */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

### Variantes réduites par composant

| Composant | Animation normale | Variante réduite |
|-----------|------------------|-----------------|
| `[Composant 1]` | Slide + fade | Fade uniquement |
| `[Composant 2]` | Scale press | Opacity 0.7 |
| `[Composant 3]` | Stagger list | Apparition simultanée |

### Conformité WCAG

- [ ] 2.3.1 — Aucun clignotement > 3Hz
- [ ] 2.2.2 — Animations auto pausables
- [ ] 2.4.7 — Focus toujours visible

---

## 📋 Pilier 6 — Documentation et gouvernance

### Charte de motion (résumé)

> [2–3 phrases résumant l'identité motion du produit. Ex. : "KASED-APP utilise un motion sobre et fonctionnel. Chaque animation confirme une action ou guide l'œil vers l'étape suivante. Aucune animation décorative."]

### Composants implémentés

| Composant | Pattern | Statut |
|-----------|---------|--------|
| `[PrimaryButton]` | `press-shrink` | ✅ Prêt |
| `[CotisationCard]` | `appear-fade-slide` | ✅ Prêt |
| `[MemberList]` | `animated-stagger` | 🚧 En cours |
| `[PageRouter]` | `page-transition` | ⬜ À faire |

### Process de contribution

Pour proposer une nouvelle animation :

1. **Décrire** le cas d'usage et pourquoi les tokens existants ne suffisent pas
2. **Proposer** le token ou le pattern dans `motion_tokens.dart`
3. **Implémenter** avec variante `prefers-reduced-motion`
4. **Soumettre** en PR avec screenshot ou video before/after
5. **Valider** via la grille `audit-checklist.md` (score ≥ 80%)

---

## ✅ Tests de cohérence

Résultats de la validation automatique :

| Test | Statut |
|------|--------|
| Toutes les micro-interactions référencent des tokens | ✅ / ❌ |
| Toutes les animations ont une variante réduite | ✅ / ❌ |
| Durées dans la plage 100–500ms | ✅ / ❌ |
| Sorties < entrées en durée | ✅ / ❌ |
| Staggering ≤ 60ms par item | ✅ / ❌ |
| Aucun clignotement > 3Hz | ✅ / ❌ |

---

## 🧩 Extensions prévues

| Extension | Priorité | Dépend de |
|-----------|----------|-----------|
| Audit des animations existantes | Haute | Ce livrable |
| Composants animés Flutter complets | Haute | `flutter-impl.md` |
| Prototypes Huashu-Design | Moyenne | Tokens validés |
| Génération automatique de code | Basse | Implémentation stable |

---

*Livrable généré par la compétence `motion-design-system` v1.0*  
*Pour auditer ce system : utiliser `audit-checklist.md`*  
*Pour implémenter : lire `flutter-impl.md` ou `react-impl.md`*
