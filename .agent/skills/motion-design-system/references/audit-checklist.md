# 🔍 Grille d'Audit — Motion Design System

> **Usage** : Pour auditer une interface existante et détecter les violations des principes motion. Remplir chaque section, noter les violations, proposer des corrections.

---

## Informations du projet

```
Produit     : ___________________________
Plateforme  : [ Web / Flutter / iOS / Android ]
Date audit  : ___________________________
Auditeur    : ___________________________
```

---

## Section 1 : Valeurs de durée

| Vérification | ✅ OK | ⚠️ Avertissement | ❌ Violation |
|-------------|-------|-----------------|-------------|
| Toutes les durées sont dans la plage 100–500ms | | | |
| Aucune valeur en dur (ex: `0.3s`) dans le CSS/Dart | | | |
| Les durées utilisent des tokens nommés | | | |
| Les sorties sont ≤ aux entrées × 0.8 | | | |
| Aucune animation dépasse 600ms (hors onboarding) | | | |

**Violations trouvées** :
```
Fichier/Composant : _______________________
Ligne : ___
Problème : ________________________________
Correction proposée : ___________________
```

---

## Section 2 : Courbes d'easing

| Vérification | ✅ OK | ⚠️ Avertissement | ❌ Violation |
|-------------|-------|-----------------|-------------|
| Les entrées utilisent `easing-decelerate` ou `easing-standard` | | | |
| Les sorties utilisent `easing-accelerate` | | | |
| Pas de `linear` sur des mouvements organiques | | | |
| Pas de `ease` CSS sans justification (valeur pas dans les tokens) | | | |
| Le bounce est réservé aux célébrations (pas sur des actions critiques) | | | |

---

## Section 3 : Cohérence des tokens

| Vérification | ✅ OK | ⚠️ Avertissement | ❌ Violation |
|-------------|-------|-----------------|-------------|
| Un fichier `motion_tokens.dart` ou `tokens.css` existe | | | |
| Tous les composants animés importent les tokens | | | |
| Pas de valeurs dupliquées ou proches (ex: 248ms et 252ms) | | | |
| Les noms des tokens suivent la convention (`--motion-duration-*`) | | | |

---

## Section 4 : Micro-interactions

Passer en revue chaque action utilisateur :

| Action | Pattern utilisé | Token correct ? | Variante réduite ? | Score |
|--------|---------------|-----------------|-------------------|-------|
| Bouton principal (tap/click) | | | | /3 |
| Hover sur cards | | | | /3 |
| Apparition d'éléments | | | | /3 |
| Chargement de données | | | | /3 |
| Erreur de formulaire | | | | /3 |
| Succès d'action | | | | /3 |
| Navigation entre pages | | | | /3 |
| Focus clavier | | | | /3 |

**Score total** : ___/24

---

## Section 5 : Chorégraphie

| Vérification | ✅ OK | ⚠️ Avertissement | ❌ Violation |
|-------------|-------|-----------------|-------------|
| Les listes utilisent du staggering (30–50ms) | | | |
| Les éléments liés apparaissent simultanément | | | |
| Le parent s'anime avant l'enfant (15ms de décalage) | | | |
| Pas plus de 5 zones animées simultanément | | | |
| La direction du staggering est logique (top→down) | | | |

---

## Section 6 : Accessibilité

| Vérification | ✅ OK | ⚠️ Avertissement | ❌ Violation | WCAG |
|-------------|-------|-----------------|-------------|------|
| `prefers-reduced-motion` implémenté globalement | | | | 2.3.1 |
| `prefers-reduced-motion` sur chaque composant animé | | | | 2.3.1 |
| Aucun clignotement > 3Hz | | | | 2.3.1 |
| Focus visible même avec motion réduit | | | | 2.4.7 |
| Animations auto ≤ 5s ou avec bouton pause | | | | 2.2.2 |
| Feedback non exclusivement animé (texte présent) | | | | 1.3.3 |
| Flutter : `MediaQuery.disableAnimations` vérifié | | | | — |

---

## Section 7 : Performance

| Vérification | ✅ OK | ⚠️ Avertissement | ❌ Violation |
|-------------|-------|-----------------|-------------|
| Animations uniquement sur `transform` et `opacity` | | | |
| Pas d'animation sur `width`, `height`, `margin`, `padding` | | | |
| `will-change` utilisé avec parcimonie | | | |
| Flutter : `RepaintBoundary` sur éléments fréquemment animés | | | |
| 60fps maintenu sur device cible (profiler vérifié) | | | |

---

## Rapport de synthèse

### 🔴 Violations critiques (à corriger immédiatement)

```
1. ___________________________________________________
   Fichier : ___________ Correction : ________________

2. ___________________________________________________
   Fichier : ___________ Correction : ________________
```

### ⚠️ Avertissements (à corriger prochainement)

```
1. ___________________________________________________
2. ___________________________________________________
```

### ✅ Points positifs

```
1. ___________________________________________________
2. ___________________________________________________
```

### Score global

| Section | Score | Max |
|---------|-------|-----|
| Durées | | 15 |
| Easings | | 15 |
| Tokens | | 12 |
| Micro-interactions | | 24 |
| Chorégraphie | | 15 |
| Accessibilité | | 21 |
| Performance | | 15 |
| **TOTAL** | | **117** |

**Niveau** :
- 100–117 : 🟢 Excellent — production-ready
- 80–99  : 🟡 Bon — quelques ajustements mineurs
- 60–79  : 🟠 Moyen — révision recommandée avant release
- < 60   : 🔴 Critique — refonte du motion system requise

---

## Actions correctives prioritaires

```
PRIORITÉ 1 (cette semaine) :
□ ___________________________________________________

PRIORITÉ 2 (ce sprint) :
□ ___________________________________________________

PRIORITÉ 3 (roadmap) :
□ ___________________________________________________
```
