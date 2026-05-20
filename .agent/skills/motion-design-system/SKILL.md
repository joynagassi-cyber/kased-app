---
name: motion-design-system
description: Conçoit les fondations d'un design system de motion design en 6 piliers (principes, tokens, micro-interactions, chorégraphie, accessibilité, documentation). Use when designing animation systems, motion tokens, micro-interactions, or auditing animations for Flutter, React, web. Intègre avec frontend-design, mobile-design, ui-ux-pro-max et huashu-design.
---

# 🎬 Motion Design System — Compétence Agent

> **Philosophie** : Toute animation a une raison fonctionnelle. Le mouvement guide, confirme, hiérarchise. Jamais décoratif. Toujours accessible.
> **Principe cardinal** : Les tokens avant tout. Aucune valeur magique en dur.

---

## 🔗 Intégration avec les autres compétences design

Cette compétence est le **socle** du motion design. Elle s'articule avec :

| Compétence | Rôle dans le pipeline |
|------------|----------------------|
| **[frontend-design](../frontend-design/SKILL.md)** | Principes UX → détermine QUAND animer |
| **[mobile-design](../mobile-design/SKILL.md)** | Contraintes tactiles → détermine les durées mobiles |
| **[ui-ux-pro-max](../ui-ux-pro-max/SKILL.md)** | Génère le design system → consomme les tokens motion |
| **[huashu-design](../huashu-design/SKILL.md)** | Prototypage HTML → implémente les micro-interactions |

### Pipeline d'exécution

```
1. frontend-design   → Contexte UX, audience, brand
2. motion-design-system (CE SKILL) → Tokens + règles
3. ui-ux-pro-max     → Design system complet
4. huashu-design     → Prototypes animés
```

---

## 🎯 Lecture sélective (OBLIGATOIRE)

| Fichier | Statut | Quand lire |
|---------|--------|------------|
| [tokens.md](references/tokens.md) | 🔴 **REQUIS** | Toujours — lexique des valeurs |
| [micro-interactions.md](references/micro-interactions.md) | 🔴 **REQUIS** | Toujours — catalogue des patterns |
| [choreography.md](references/choreography.md) | ⚪ Optionnel | Animations multiples / listes |
| [accessibility.md](references/accessibility.md) | 🔴 **REQUIS** | Toujours — prefers-reduced-motion |
| [flutter-impl.md](references/flutter-impl.md) | ⚪ Optionnel | Projet Flutter |
| [react-impl.md](references/react-impl.md) | ⚪ Optionnel | Projet React/Web |
| [audit-checklist.md](references/audit-checklist.md) | ⚪ Optionnel | Audit d'interface existante |

---

## ⚠️ STOP — Poser ces questions avant toute chose

Si le contexte est flou, **demander** :

| Aspect | Question |
|--------|----------|
| **Plateforme** | « Web, Flutter, React Native, ou les trois ? » |
| **Identité de marque** | « La marque est plutôt sobre/rapide/ludique/premium ? » |
| **Stack** | « CSS natif, Framer Motion, Flutter AnimationController, ou autre ? » |
| **Contraintes perf** | « Cible mobile bas de gamme ? 60fps obligatoire ? » |
| **Audit ou création** | « Créer ex nihilo ou auditer l'existant ? » |

---

## 🏗️ Les 6 Piliers — Exécution

Lors d'une demande « concevoir un design system motion », exécuter **dans cet ordre** :

### Étape 1 : Analyser le contexte

```
CHECKPOINT CONTEXTE :
- Produit        : [ type de produit ]
- Audience       : [ Gen Z / B2B / Seniors... ]
- Identité brand : [ sobre / expressif / premium ]
- Plateforme     : [ Web / Flutter / RN / all ]
- Stack tech     : [ CSS / Framer / Flutter / autre ]
```

Si non rempli → **STOP et demander**.

### Étape 2 : Pilier 1 — Principes directeurs

Formaliser 5 principes adaptés au contexte (voir template dans [references/tokens.md](references/tokens.md)) :

| Principe | Définition stricte |
|----------|--------------------|
| **Utilité** | Chaque animation a un rôle fonctionnel mesurable |
| **Fluidité** | Latence visuelle < 100ms, mouvement continu |
| **Naturel** | Courbes calquées sur la physique réelle |
| **Cohérence** | Mêmes paramètres pour actions de même niveau |
| **Accessible** | Variante `prefers-reduced-motion` pour toute animation |

> Adapter ces principes au brand : un produit ludique → ajouter « Expressivité ». Un outil B2B → renforcer « Efficacité ».

### Étape 3 : Pilier 2 — Tokens de mouvement

Lire [references/tokens.md](references/tokens.md) → dériver les tokens adaptés au projet.

**Règle d'or** : Aucune valeur magique en dur. Toute durée, courbe ou décalage → token.

### Étape 4 : Pilier 3 — Micro-interactions

Lire [references/micro-interactions.md](references/micro-interactions.md) → sélectionner les patterns pertinents.

**Règle** : Chaque fiche référence obligatoirement des tokens du Pilier 2.

### Étape 5 : Pilier 4 — Chorégraphie

Si animations multiples → lire [references/choreography.md](references/choreography.md).

Règles minimales :
- Staggering listes : 30–50ms entre items
- Parent avant enfant : 10–20ms de décalage
- Sortie = entrée × 0.7 en durée + ease-in

### Étape 6 : Pilier 5 — Accessibilité

Lire [references/accessibility.md](references/accessibility.md) → **systématiquement** inclure variante réduite.

### Étape 7 : Pilier 6 — Livrable

Générer le document de sortie (voir format dans [references/output-template.md](references/output-template.md)).

---

## 🤖 Algorithme d'exécution

```
REÇOIT : "concevoir un motion design system pour [produit]"

1. ANALYSER le contexte (Étape 1)
   └── Si flou → STOP, poser max 3 questions

2. REMPLIR les 6 piliers (Étapes 2-7)
   └── Chaque pilier référence des tokens existants

3. GÉNÉRER le livrable markdown
   └── Format : references/output-template.md

4. PROPOSER les tests de cohérence
   └── Vérifier : chaque micro-interaction utilise des tokens ?
   └── Vérifier : toutes les animations ont une variante réduite ?
   └── Vérifier : les durées sont-elles dans la plage 100–500ms ?

5. SI plateforme Flutter → lire references/flutter-impl.md
   SI plateforme React  → lire references/react-impl.md
```

---

## ❌ Anti-patterns (INTERDIT)

| Anti-pattern | Pourquoi interdit | Alternative |
|-------------|-------------------|-------------|
| Valeur de durée en dur (`0.3s`) | Non réutilisable, incohérent | Token `--motion-duration-standard` |
| Animation purement décorative | Charge cognitive inutile | Supprimer ou justifier fonctionnellement |
| Même durée pour entrée et sortie | Sortie doit être plus rapide | Sortie = entrée × 0.7 |
| Pas de `prefers-reduced-motion` | Exclusion des utilisateurs sensibles | Obligatoire sur toute animation |
| Staggering > 80ms par item | Paraît lent sur listes longues | 30–50ms max |
| Bounce/spring sur actions critiques | Distrait dans des contextes pro | Réserver aux moments de célébration |
| Animations > 500ms sans interaction utilisateur | Frustrant, bloque la perception | Découper ou réduire |

---

## 📋 Checklist de cohérence (post-création)

Avant de livrer, valider :

- [ ] Chaque micro-interaction référence un token (pas de valeur en dur)
- [ ] Toute animation a une variante `prefers-reduced-motion`
- [ ] Les durées sont dans la plage recommandée (100–500ms)
- [ ] Les sorties sont plus rapides que les entrées
- [ ] Le staggering respecte 30–50ms entre items
- [ ] Pas de clignotement > 3 flashs/seconde
- [ ] Les animations critiques (feedback d'erreur) fonctionnent sans animation

---

## 🧩 Extensions futures de cette compétence

| Compétence future | Ce qu'elle fera |
|-------------------|-----------------|
| **motion-audit** | Analyser une interface existante → détecter violations |
| **motion-components** | Implémenter des composants animés React/Flutter |
| **motion-prototype** | Générer des prototypes Huashu-Design depuis les tokens |
| **motion-codegen** | Générer automatiquement hooks + styles depuis les tokens |

---

## 📚 Fichiers de référence

| Fichier | Contenu |
|---------|---------|
| [references/tokens.md](references/tokens.md) | Lexique complet des tokens CSS/JSON/Dart |
| [references/micro-interactions.md](references/micro-interactions.md) | Catalogue des 12 patterns universels |
| [references/choreography.md](references/choreography.md) | Règles d'orchestration multi-animations |
| [references/accessibility.md](references/accessibility.md) | Prefers-reduced-motion + WCAG 2.1 |
| [references/flutter-impl.md](references/flutter-impl.md) | Implémentation Flutter (AnimationController, Curves) |
| [references/react-impl.md](references/react-impl.md) | Implémentation React (Framer Motion, CSS vars) |
| [references/output-template.md](references/output-template.md) | Template du livrable final |
| [references/audit-checklist.md](references/audit-checklist.md) | Grille d'audit d'interface existante |

---

> **Règle ultime** : Le mouvement doit sembler inévitable — comme si les éléments avaient toujours voulu aller là où ils vont.
